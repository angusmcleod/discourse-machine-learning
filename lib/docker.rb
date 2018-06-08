module DiscourseMachineLearning
  class Image
    include ActiveModel::SerializerSupport

    attr_reader :name
    attr_accessor :status

    def initialize(name)
      @name = name
      @status = Image.get_status(name)
    end

    def update_status(status=nil)
      status = status || get_status
      msg = {
        name: @name,
        status: status
      }
      MessageBus.publish("/admin/ml/images", msg)
    end

    def ready
      DiscourseMachineLearning::Image.ready(@name)
    end

    def self.statuses
      @statuses ||= Enum.new(none: 1,
                             building: 2,
                             built: 3)
    end

    def self.exists(name)
      Docker::Image.exist?(name)
    end

    def self.get(name)
      Docker::Image.get(name)
    end

    def self.all
      images = []
      Docker::Image.all.each { |image|
        images.push(Image.new(image.json["RepoTags"][0]))
      }
      images
    end

    def self.get_status(name)
      if Image.exists(name)
        Image.statuses[:built]
      else
        Image.statuses[:none]
      end
    end

    def self.ready(name)
      Image.get_status(name) == Image.statuses[:built]
    end

    def self.build(model_label)
      Excon.defaults[:write_timeout] = 1000
      Excon.defaults[:read_timeout] = 1000

      model = DiscourseMachineLearning::Model.new(model_label)
      image_name = model.image_name
      source = model.source
      model_root = File.join(Rails.root, 'plugins/discourse-machine-learning/models')
      model_host_dir = File.join(model_root, model.label)
      model_mount_dir = model.mount_dir

      if source == 'hub'
        Docker::Image.create('fromImage' => image_name) do |v|
          puts v
        end
      end

      if source == 'local'
        Docker::Image.build_from_dir(model_host_dir, {'t' => image_name})  do |v|
          if (log = JSON.parse(v)) && log.has_key?("stream")
            puts log["stream"]
          end
        end
      end
    end
  end

  class ImageController < ::ApplicationController
    def index
      render_serialized(Image.all, ImageSerializer)
    end

    def build
      name = params[:name]

      if !Image.exists(name)
        Jobs.enqueue(:build_image, name: name)
      end
      render json: success_json
    end

    def remove
      name = params[:name]

      if Image.exists(name)
        image = Image.get(name)
        image.remove(:force => true)
      end

      if !Image.exists(name)
        MessageBus.publish("/admin/ml/images", { name: name, action: "remove" })
      end

      render json: success_json
    end
  end

  class ImageSerializer < ::ApplicationSerializer
    attributes :name, :status
  end

  class Container
    def self.ready(model_label)
      begin
        Docker::Container.get(model_label)
      rescue
        false
      end
    end

    def self.create(model_label, dataset_label=nil)
      container = Container.ready(model_label)

      if !container
        Excon.defaults[:write_timeout] = 1000
        Excon.defaults[:read_timeout] = 1000

        model = DiscourseMachineLearning::Model.new(model_label)
        model_root = File.join(Rails.root, 'plugins/discourse-machine-learning/models')
        model_host_dir = File.join(model_root, model.label)
        model_mount_dir = model.mount_dir

        volumes = { model_mount_dir => { model_host_dir => 'rw' } }
        binds = [ "/#{model_host_dir}:/#{model_mount_dir}" ]

        if dataset_label
          dataset_root = File.join(Rails.root, 'public/plugins/discourse-machine-learning')
          dataset_host_dir = File.join(dataset_root, model.label, dataset_label)
          dataset_mount_dir = File.join(model.mount_dir, "data")
          volumes[dataset_mount_dir] = { dataset_host_dir => 'rw' }
          binds.push("/#{dataset_host_dir}:/#{dataset_mount_dir}")
        end

        container = Docker::Container.create(
          'name' => model.label,
          'Image' => model.image_name,
          'Volumes' => volumes
        )
        container.start('Binds' => binds)
      end

      container
    end
  end
end
