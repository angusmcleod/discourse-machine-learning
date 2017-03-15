module Jobs
  class EvalModel < Jobs::Base
    sidekiq_options timeout: 1000

    def execute(args)
      Excon.defaults[:write_timeout] = 1000
      Excon.defaults[:read_timeout] = 1000

      label = args[:label]
      input = args[:input]
      run = DiscourseMachineLearning::Run.new(label)
      model = DiscourseMachineLearning::Model.new(run.model_label)

      eval_cmd = model.eval_cmd % { :input => input }

      model_root = File.join(Rails.root, 'plugins/discourse-machine-learning/ml_models')
      model_host_dir = File.join(model_root, model.label)
      model_mount_dir = model.mount_dir

      container = Docker::Container.create(
        'Image' => model.namespace,
        'Volumes' => {
          model_mount_dir => { model_host_dir => 'rw' }
        }
      )

      container.start('Binds' => [
        "/#{model_host_dir}:/#{model_mount_dir}"
      ])

      container.exec(["bash", "-c", eval_cmd]) { |stream, chunk|
        puts "#{stream}: #{chunk}"
        if chunk.include? "OUTPUT"
          DiscourseMachineLearning::Run.on_eval_complete(label, chunk)
        end
      }

      DiscourseMachineLearning::Run.on_complete(model_label)
    end
  end
end
