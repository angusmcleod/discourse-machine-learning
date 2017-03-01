require 'docker'

module DiscourseMachineLearning
  class Models
    include ActiveModel::SerializerSupport

    attr_reader :label
    attr_accessor :conf, :namespace, :status

    DIR = "#{Rails.root}/plugins/discourse-machine-learning/ml_models/"

    def initialize(label)
      @label = label
      @conf = YAML.load(File.read(File.join(DIR, @label, 'conf.yml')))
      @namespace = @conf["namespace"]
      @status = get_status
    end

    def self.statuses
      @statuses ||= Enum.new(no_image: 1,
                             image_building: 2,
                             image_built: 3,
                             container_building: 4,
                             container_running: 5)
    end

    def get_status
      if Docker::Image.exist?(@namespace)
        begin
          container = Docker::Container.get(@namespace)
          Models.statuses[:container_running]
        rescue
          Models.statuses[:image_built]
        end
      else
        Models.statuses[:no_image]
      end
    end

    def update_status(status=nil)
      status = status || get_status
      msg = { status: status }
      MessageBus.publish("/admin/ml/models/#{@label}/status", msg)
    end

    def self.all
      Dir.glob(File.join(DIR, "*")).map { |model| Models.new(File.basename(model)) }
    end
  end

  class ModelsController < ::ApplicationController
    def index
      render_serialized(Models.all, ModelsSerializer)
    end

    def build_image
      label = params[:label]
      if !Docker::Image.exist?(Models.new(label).namespace)
        Jobs.enqueue(:build_model_image, label: label)
      end
      render json: success_json
    end

    def remove_image
      label = params[:label]
      model = Models.new(label)
      image = Docker::Image.get(model.namespace)
      image.remove(:force => true)
      model.update_status()
      render json: success_json
    end

    def train
      name = params[:model_name]
      model = Models.create(name)
      container = Docker::Container.create(
        'Image' => model.image,
        'Cmd' => [model.train_cmd],
        'Volumes' => {
          File.join(Rails.root, 'public', 'plugins', 'discourse-machine-learning', 'data', name) => { '/data' => 'rw' }
        }
      )
      container.tap(&:start).attach { |stream, chunk| puts "#{stream}: #{chunk}" }
      ## get checkpoint from docker container when training complete
    end

    def eval
      ## get checkpoint
      ## run eval with checkpoint in docker container
      ## get result
    end

    def run
      ## get input
      ## run input on model
      ## get output
    end
  end

  class ModelsSerializer < ActiveModel::Serializer
    attributes :label, :namespace, :status
  end
end
