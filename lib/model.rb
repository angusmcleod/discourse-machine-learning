require 'docker'

module DiscourseMachineLearning
  class Model
    include ActiveModel::SerializerSupport

    attr_reader :label, :image_name, :type, :train_cmd, :test_cmd, :mount_dir
    attr_accessor :run_label, :image_status, :run_status, :status

    MODEL_DIR = "#{Rails.root}/plugins/discourse-machine-learning/models/"

    def initialize(label)
      @label = label
      conf = YAML.load(File.read(File.join(MODEL_DIR, @label, 'conf.yml')))
      conf.each do |key, value|
        self.instance_variable_set("@#{key}".to_sym, value)
      end
      @image_ready = DiscourseMachineLearning::Image.is_ready?(@image_name)

      if @type == Model.types[:standard]
        @run_label = Model.get_run(label)
        @run_ready = DiscourseMachineLearning::Run.is_ready?(@run_label)
      end

      @status = ready ? Model.statuses[:ready] : Model.statuses[:not_ready]
    end

    def ready
      @image_ready && (@type == Model.statuses[:pre_trained] || @run_ready) && container_ready
    end

    def conatiner_ready
      DiscourseMachineLearning::Container.ready(model_label)
    end

    def self.statuses
      @statuses ||= Enum.new(ready: 1,
                             not_ready: 2)
    end

    def self.types
      @types ||= Enum.new(standard: 1,
                          pre_trained: 2)
    end

    def self.get_dataset(label)
      PluginStore.get("discourse-machine-learning", "#{label}_dataset")
    end

    def eval(input)
      checkpoint_dir = File.join(@mount_dir, 'runs', @run_label, '/checkpoints')
      eval_cmd = @eval_cmd % { :checkpoint_dir => checkpoint_dir, :input => "#{input}" }
      output = ''
      run = DiscourseMachineLearning::Run.new(@run_label)

      container = DiscourseMachineLearning::Container.create(@label, run.dataset_label)
      container.exec(["bash", "-c", eval_cmd]) { |stream, chunk|
        puts "#{stream}: #{chunk}"
        if chunk.include? "OUTPUT"
          output = chunk('OUTPUT: ').last
        end
      }

      output
    end

    def self.update_run(model_label, run_label)
      Model.set_run(model_label, run_label)
      msg = {
        label: model_label,
        run_label: run_label
      }
      MessageBus.publish("/admin/ml/models", msg)
    end

    def self.set_run(label, run_label)
      PluginStore.set("discourse-machine-learning", "#{label}_run", run_label)
    end

    def self.get_run(label)
      PluginStore.get("discourse-machine-learning", "#{label}_run")
    end

    def self.all
      Dir.glob(File.join(MODEL_DIR, "*")).map { |model| Model.new(File.basename(model)) }
    end
  end

  class ModelController < ::ApplicationController
    def index
      render_serialized(Model.all, ModelSerializer)
    end

    def set_run
      Model.update_run(params[:model_label], params[:run_label])
      render json: success_json
    end

    def eval
      label = params[:label]
      input = params[:input]
      model = Model.new(model_label)
      image = DiscourseMachineLearning::Image.new(model.image_name)
      if image.ready
        model.eval(input)
      else
        return render json: failed_json.merge(message: I18n.t("ml.model.no_image", model_label: model_label))
      end
      render json: success_json
    end
  end

  class ModelSerializer < ::ApplicationSerializer
    attributes :label, :type, :image_name, :image_status, :run_label, :run_status, :status
  end
end
