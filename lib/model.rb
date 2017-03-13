require 'docker'

module DiscourseMachineLearning
  class Model
    include ActiveModel::SerializerSupport

    attr_reader :label
    attr_accessor :conf, :type, :namespace, :status, :run_label, :train_cmd, :mount_dir

    MODEL_DIR = "#{Rails.root}/plugins/discourse-machine-learning/ml_models/"

    def initialize(label)
      @label = label
      @conf = YAML.load(File.read(File.join(MODEL_DIR, @label, 'conf.yml')))
      @type = @conf["type"]
      @namespace = @conf["namespace"]
      @train_cmd = @conf["train_cmd"]
      @test_cmd = @conf["test_cmd"]
      @mount_dir = @conf["mount_dir"]
      @run_label = Model.get_run_label(label)
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
      status = status || get_status
      msg = {
        label: @label,
        status: status
      }
      MessageBus.publish("/admin/ml/model", msg)
    end

    def self.set_run_label(label, run_label)
      PluginStore.set("discourse-machine-learning", "#{label}_run", run_label)
      MessageBus.publish("/admin/ml/model", { label: label, run_label: run_label })
    end

    def self.get_run_label(label)
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

    def build_image
      model_label = params[:model_label]
      if !Docker::Image.exist?(Model.new(model_label).namespace)
        Jobs.enqueue(:build_model_image, model_label: model_label)
      end
      render json: success_json
    end

    def remove_image
      model_label = params[:model_label]
      model = Model.new(model_label)
      image = Docker::Image.get(model.namespace)
      image.remove(:force => true)
      model.update_status()
      render json: success_json
    end
  end

  class ModelSerializer < ::ApplicationSerializer
    attributes :label, :type, :namespace, :run_label, :status
  end
end
