module Jobs
  class BuildImage < Jobs::Base
    sidekiq_options timeout: 1000

    def execute(args)
      Excon.defaults[:write_timeout] = 1000
      Excon.defaults[:read_timeout] = 1000

      if args.image.namespace
        Docker::Image.create('fromImage' => args.image.path) do |v|
          if (log = JSON.parse(v)) && log.has_key?("stream")
            puts log["stream"]
          end
        end
      else
        Docker::Image.build_from_dir(args.image.path, {'t' => args.image.tag})  do |v|
          if (log = JSON.parse(v)) && log.has_key?("stream")
            puts log["stream"]
          end
        end
      end

      status = true
      DiscourseMachineLearning::MachineLearningController.update_status(args.image.tag, status)
    end
  end
end
