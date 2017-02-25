module Jobs
  class BuildImage < Jobs::Base
    sidekiq_options timeout: 1000

    def execute(args)
      Excon.defaults[:write_timeout] = 1000
      Excon.defaults[:read_timeout] = 1000
      name = args[:name]
      path = args[:path]

      if path == 'hub'
        Docker::Image.create('fromImage' => name) do |v|
          puts v
        end
      else
        Docker::Image.build_from_dir(path, {'t' => name})  do |v|
          if (log = JSON.parse(v)) && log.has_key?("stream")
            puts log["stream"]
          end
        end
      end

      status = Docker::Image.exist?(name)
      DiscourseMachineLearning::MlController.update_status(name, status)
    end
  end
end
