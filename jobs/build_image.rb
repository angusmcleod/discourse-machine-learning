module Jobs
  class BuildModelImage < Jobs::Base
    sidekiq_options timeout: 1000

    def execute(args)
      Excon.defaults[:write_timeout] = 1000
      Excon.defaults[:read_timeout] = 1000

      model_label = args[:model_label]
      model = DiscourseMachineLearning::Model.new(model_label)
      namespace = model.conf["namespace"]
      path = model.conf["path"]

      model.update_status(DiscourseMachineLearning::Model.statuses[:building])

      if path == 'hub'
        Docker::Image.create('fromImage' => namespace) do |v|
          puts v
        end
      else
        Docker::Image.build_from_dir(path, {'t' => namespace})  do |v|
          if (log = JSON.parse(v)) && log.has_key?("stream")
            puts log["stream"]
          end
        end
      end

      model.update_status
    end
  end
end
