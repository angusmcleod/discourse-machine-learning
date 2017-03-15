module Jobs
  class BuildImage < Jobs::Base
    sidekiq_options timeout: 1000

    def execute(args)
      Excon.defaults[:write_timeout] = 1000
      Excon.defaults[:read_timeout] = 1000

      model_label = args[:model_label]
      model = DiscourseMachineLearning::Model.new(model_label)
      namespace = model.namespace
      source = model.source

      model_root = File.join(Rails.root, 'plugins/discourse-machine-learning/ml_models')
      model_host_dir = File.join(model_root, model.label)
      model_mount_dir = model.mount_dir

      model.update_status(DiscourseMachineLearning::Model.statuses[:building])

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

      model.update_status
    end
  end
end
