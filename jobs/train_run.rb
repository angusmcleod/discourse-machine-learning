module Jobs
  class TrainRun < ::Jobs::Base
    sidekiq_options timeout: 1000

    def execute(args)
      Excon.defaults[:write_timeout] = 1000
      Excon.defaults[:read_timeout] = 1000

      model_label = args[:model_label]
      dataset_label = args[:dataset_label]
      model = DiscourseMachineLearning::Model.new(model_label)
      
      puts "MODEL: #{model.inspect}"

      container = DiscourseMachineLearning::Container.create(model_label, dataset_label)
      
      puts "CONTAINER: #{container.inspect}"
      
      container.exec(["bash", "-c", model.train_cmd]) { |stream, chunk|
        puts "#{stream}: #{chunk}"
        if chunk && chunk.include?("OUTPUT_DIR")
          run_label = DiscourseMachineLearning::Run.get_latest(model_label)
          DiscourseMachineLearning::Run.on_start(run_label, model_label, dataset_label)
        end
      }

      DiscourseMachineLearning::Run.on_complete(model_label)
    end
  end
end
