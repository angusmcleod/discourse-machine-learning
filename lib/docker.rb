module DiscourseMachineLearning
  class DockerHelper
    def self.build_image(model)
      Excon.defaults[:write_timeout] = 1000
      Excon.defaults[:read_timeout] = 1000
      namespace = model.namespace
      source = model.source
      model_root = File.join(Rails.root, 'plugins/discourse-machine-learning/ml_models')
      model_host_dir = File.join(model_root, model.label)
      model_mount_dir = model.mount_dir

      if source == 'hub'
        Docker::Image.create('fromImage' => namespace) do |v|
          puts v
        end
      end

      if source == 'local'
        Docker::Image.build_from_dir(model_host_dir, {'t' => namespace})  do |v|
          if (log = JSON.parse(v)) && log.has_key?("stream")
            puts log["stream"]
          end
        end
      end
    end

    def self.get_container(model, dataset_label=nil)
      begin
        container = Docker::Container.get(model.label)
      rescue
        Excon.defaults[:write_timeout] = 1000
        Excon.defaults[:read_timeout] = 1000

        model_root = File.join(Rails.root, 'plugins/discourse-machine-learning/ml_models')
        model_host_dir = File.join(model_root, model.label)
        model_mount_dir = model.mount_dir

        volumes = { :model_mount_dir => { model_host_dir => 'rw' } }
        binds = [ "/#{model_host_dir}:/#{model_mount_dir}" ]

        if dataset_label
          dataset_root = File.join(Rails.root, 'public/plugins/discourse-machine-learning')
          dataset_host_dir = File.join(dataset_root, model.label, dataset_label)
          dataset_mount_dir = File.join(model.mount_dir, "data")
          volumes[:dataset_mount_dir] = { dataset_host_dir => 'rw' }
          binds.push("/#{dataset_host_dir}:/#{dataset_mount_dir}")
        end

        container = Docker::Container.create(
          'name' => @label,
          'Image' => model.namespace,
          'Volumes' => volumes
        )
        container.start('Binds' => binds)
      end

      container
    end
  end
end
