module DiscourseMachineLearning
  class Run
    include ActiveModel::SerializerSupport

    attr_reader :label, :model_label, :dataset_label
    attr_accessor :status, :accuracy

    MODEL_DIR = "#{Rails.root}/plugins/discourse-machine-learning/ml_models/"

    def initialize(label, model_label)
      @label = label
      @model_label = model_label
      @dataset_label = Run.get_dataset(label)
      @status = Run.get_status(label) || Run.statuses[:undetermined]
      @checkpoint = Run.get_checkpoint(label)
      @accuracy = Run.get_accuracy(label)
    end

    def self.all
      runs = []
      model_labels = Dir.glob(File.join(MODEL_DIR, "*")).map { |model| File.basename(model) }
      model_labels.each { |model_label|
        model_runs = Dir.glob(File.join(MODEL_DIR, model_label, 'runs', "*")).map { |run|
          Run.new(File.basename(run), model_label)
        }
        runs.concat model_runs
      }
      runs
    end

    def remove
      FileUtils.rm_rf("#{MODEL_DIR}/#{@model_label}/runs/#{@label}")
    end

    def self.statuses
      @statuses ||= Enum.new(undetermined: 0,
                             initializing: 1,
                             training: 2,
                             trained: 3,
                             testing: 4,
                             tested: 5)
    end

    def self.set_status(label, status)
      PluginStore.set("discourse-machine-learning", "#{label}_status", status)
    end

    def self.get_status(label)
      PluginStore.get("discourse-machine-learning", "#{label}_status")
    end

    def self.set_dataset(label, dataset_label)
      PluginStore.set("discourse-machine-learning", "#{label}_dataset", dataset_label)
    end

    def self.get_dataset(label)
      PluginStore.get("discourse-machine-learning", "#{label}_dataset")
    end

    def self.set_checkpoint(label, checkpoint)
      PluginStore.set("discourse-machine-learning", "#{label}_checkpoint", checkpoint)
    end

    def self.get_checkpoint(label)
      PluginStore.get("discourse-machine-learning", "#{label}_checkpoint")
    end

    def self.set_accuracy(label, accuracy)
      PluginStore.set("discourse-machine-learning", "#{label}_accuracy", accuracy)
    end

    def self.get_accuracy(label)
      PluginStore.get("discourse-machine-learning", "#{label}_accuracy")
    end

    def self.on_init(model_label, dataset_label)
      sleep 2
      msg = {
        placeholder: true,
        label: I18n.t('ml.run.initializing'),
        model_label: model_label,
        dataset_label: dataset_label,
        status: Run.statuses[:initializing]
      }
      MessageBus.publish("/admin/ml/runs", msg)
    end

    def self.on_start(run_label, model_label, dataset_label)
      Run.set_status(run_label, Run.statuses[:training])
      Run.set_dataset(run_label, dataset_label)
      Model.new(model_label).update_run_label(run_label)
      MessageBus.publish("/admin/ml/runs", { new_run: true })
    end

    def self.on_complete(model_label)
      run = Run.new(get_latest(model_label), model_label)
      Run.set_status(run.label, Run.statuses[:trained])
      MessageBus.publish("/admin/ml/runs", { label: label, status: Run.statuses[:trained] })
      Run.set_checkpoint(run.label, get_checkpoint_from_file(run.label, model_label))
      DiscourseMachineLearning::Model.set_run(model_label, run.label)
    end

    def on_test_start
      Run.set_status(@label, Run.statuses[:testing])
      MessageBus.publish("/admin/ml/runs", { label: label, status: Run.statuses[:testing]})
    end

    def on_test_complete(output)
      accuracy = output.partition('ACCURACY:').last
      Run.set_status(@label, Run.statuses[:tested])
      Run.set_accuracy(@label, accuracy)
      MessageBus.publish("/admin/ml/runs", { label: label, accuracy: accuracy, status: Run.statuses[:tested] })
    end

    def self.get_checkpoint_from_file(label, model_label)
      checkpoint_line = File.open(File.join(MODEL_DIR, model_label, 'runs', label, 'checkpoints', 'checkpoint'), &:readline)
      checkpoint_line.split()[1]
    end

    def self.get_latest(model_label)
      run_path = Dir.glob("#{MODEL_DIR}/#{model_label}/runs/*/").max_by {|f| File.mtime(f)}
      File.basename(run_path)
    end
  end

  class RunController < ::ApplicationController
    def index
      render_serialized(Run.all, RunSerializer)
    end

    def train
      model_label = params[:model_label]
      dataset_label = params[:dataset_label]
      Run.on_init(model_label, dataset_label)
      if Docker::Image.exist?(DiscourseMachineLearning::Model.new(model_label).namespace)
        Jobs.enqueue(:train_run, model_label: model_label, dataset_label: dataset_label)
      else
        render json: failed_json.merge(message: I18n.t("ml.model.no_image", model_label: model_label))
      end
      render json: success_json
    end

    def test
      label = params[:label]
      model_label = params[:model_label]
      if Docker::Image.exist?(DiscourseMachineLearning::Model.new(model_label).namespace)
        Jobs.enqueue(:test_run, label: label, model_label: model_label)
      else
        render json: failed_json.merge(message: I18n.t("ml.model.no_image", model_label: model_label))
      end
      render json: success_json
    end

    def destroy
      label = params[:label]
      model_label = params[:model_label]
      if run = Run.new(label, model_label)
        run.remove
        model = DiscourseMachineLearning::Model.new(model_label)
        if model.run_label == label
          model.update_run_label(label)
        end

        MessageBus.publish("/admin/ml/runs", {
          action: 'remove',
          label: params[:label]
        })
        render nothing: true
      else
        render nothing: true, status: 404
      end
    end
  end

  class RunSerializer < ::ApplicationSerializer
    attributes :label, :model_label, :dataset_label, :accuracy, :status
  end
end
