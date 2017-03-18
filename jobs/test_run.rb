module Jobs
  class TestRun < Jobs::Base
    sidekiq_options timeout: 1000

    def execute(args)
      Excon.defaults[:write_timeout] = 1000
      Excon.defaults[:read_timeout] = 1000

      label = args[:label]
      model_label = args[:model_label]
      run = DiscourseMachineLearning::Run.new(label, model_label)
      model = DiscourseMachineLearning::Model.new(model_label)

      run.on_test_start()

      checkpoint_dir = File.join(model.mount_dir, 'runs', label, '/checkpoints')
      test_cmd = model.test_cmd % { :checkpoint_dir => checkpoint_dir }

      container = DiscourseMachineLearning::DockerHelper.get_container(model, run.dataset_label)
      container.exec(["bash", "-c", test_cmd]) { |stream, chunk|
        puts "#{stream}: #{chunk}"
        if chunk.include? "ACCURACY"
          run.on_test_complete(chunk)
        end
      }
    end
  end
end
