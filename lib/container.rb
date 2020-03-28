module DiscourseMachineLearning
  class Container
    def self.ready(model_label)
      begin
        container = Docker::Container.get(model_label)
        
        if ["Created", "Running"].include?(container.info["State"]["Status"])
          true
        else
          container.delete(:force => true)
          false
        end
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
        
        puts "MODEL: #{model.inspect}"

        container = Docker::Container.create(
          'name' => model.label,
          'Image' => model.image_name,
          'Volumes' => volumes
        )
        
        puts "CONTAINER: #{container.inspect}"
        
        container.start('Binds' => binds)
      end

      container
    end
  end
end