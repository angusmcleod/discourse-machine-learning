require 'docker'

module DiscourseMachineLearning
  class Model
    include ActiveModel::SerializerSupport

    attr_reader :label
    attr_accessor :conf, :type, :namespace, :status, :run_label, :train_cmd, :test_cmd, :mount_dir

    MODEL_DIR = "#{Rails.root}/plugins/discourse-machine-learning/ml_models/"

    def initialize(label)
      @label = label
      @conf = YAML.load(File.read(File.join(MODEL_DIR, @label, 'conf.yml')))
      @source = @conf["source"]
      @type = @conf["type"]
      @namespace = @conf["namespace"]
      @train_cmd = @conf["train_cmd"]
      @test_cmd = @conf["test_cmd"]
      @mount_dir = @conf["mount_dir"]
      @run_label = Model.get_run(label)
      @input = Model.get_input(label)
      @status = get_static_status
      ## how to store checkpoints? Need new table in db
    end

    def self.statuses
      @statuses ||= Enum.new(no_image: 1,
                             building: 2,
                             built: 3)
    end

    def get_static_status
      if Docker::Image.exist?(@namespace)
        Model.statuses[:built]
      else
        Model.statuses[:no_image]
      end
    end

    def update_status(status=nil)
      status = status || get_static_status
      msg = {
        label: @label,
        status: status
      }
      MessageBus.publish("/admin/ml/models", msg)
    end

    def update_run(run_label)
      Model.set_run(@label, run_label)
      msg = {
        label: @label,
        run_label: run_label
      }
      MessageBus.publish("/admin/ml/models", msg)
    end

    def update_input(input_label)
      Model.set_input(@label, input_label)
      msg = {
        label: @label,
        input_label: input_label
      }
      MessageBus.publish("/admin/ml/models", msg)
    end

    def self.set_input(label, input_label)
      PluginStore.set("discourse-machine-learning", "#{label}_input", input_label)
    end

    def self.get_input(label)
      PluginStore.get("discourse-machine-learning", "#{label}_input")
    end

    def self.set_run(label, run_label)
      PluginStore.set("discourse-machine-learning", "#{label}_run", run_label)
    end

    def self.get_run(label)
      PluginStore.get("discourse-machine-learning", "#{label}_run")
    end

    def on_eval_complete(label, output)
      output = output('OUTPUT').last
      print (output)
    end

    def self.all
      Dir.glob(File.join(MODEL_DIR, "*")).map { |model| Model.new(File.basename(model)) }
    end
  end

  class ModelController < ::ApplicationController
    def index
      render_serialized(Model.all, ModelSerializer)
    end

    def build_image
      model_label = params[:model_label]
      if !Docker::Image.exist?(Model.new(model_label).namespace)
        Jobs.enqueue(:build_image, model_label: model_label)
      end
      render json: success_json
    end

    def remove_image
      model_label = params[:model_label]
      model = Model.new(model_label)
      image = Docker::Image.get(model.namespace)
      begin
        image.remove(:force => true)
      rescue Exception => e
        return render json: failed_json.merge(message: e), status: 400
      end
      model.update_status()
      render json: success_json
    end

    def set_run
      model_label = params[:model_label]
      run_label = params[:run_label]
      Model.new(model_label).update_run(run_label)
      render json: success_json
    end

    def set_input
      model_label = params[:model_label]
      input_label = params[:input_label]
      Model.new(model_label).update_input(input_label)
      render json: success_json
    end

    def eval
      label = params[:label]
      input = params[:input]
      if Docker::Image.exist?(DiscourseMachineLearning::Model.new(model_label).namespace)
        Jobs.enqueue(:eval_model, label: label, input: input)
      else
        return render json: failed_json.merge(message: I18n.t("ml.model.no_image", model_label: model_label))
      end
      render json: success_json
    end
  end

  class ModelSerializer < ::ApplicationSerializer
    attributes :label, :type, :namespace, :run_label, :status
  end
end
