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
end
