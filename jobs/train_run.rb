module Jobs
  class TrainRun < Jobs::Base
    sidekiq_options timeout: 1000

    def execute(args)
      Excon.defaults[:write_timeout] = 1000
      Excon.defaults[:read_timeout] = 1000

      model_label = args[:model_label]
      dataset_label = args[:dataset_label]
      model = DiscourseMachineLearning::Model.new(model_label)

      model_root = File.join(Rails.root, 'plugins/discourse-machine-learning/ml_models')
      model_host_dir = File.join(model_root, model_label)
      model_mount_dir = model.mount_dir

      dataset_root = File.join(Rails.root, 'public/plugins/discourse-machine-learning')
      dataset_host_dir = File.join(dataset_root, model_label, dataset_label)
      dataset_mount_dir = File.join(model.mount_dir, "data")

      container = Docker::Container.create(
        'Image' => model.namespace,
        'Volumes' => {
          dataset_mount_dir => { dataset_host_dir => 'rw' },
          model_mount_dir => { model_host_dir => 'rw' }
        }
      )

      container.start('Binds' => [
        "/#{dataset_host_dir}:/#{dataset_mount_dir}",
        "/#{model_host_dir}:/#{model_mount_dir}"
      ])

      container.exec(["bash", "-c", model.train_cmd]) { |stream, chunk|
        puts "#{stream}: #{chunk}"
        if chunk.include? "OUTPUT_DIR"
          run_label = DiscourseMachineLearning::Run.get_latest(model_label)
          DiscourseMachineLearning::Run.on_start(run_label, model_label, dataset_label)
        end
      }

      DiscourseMachineLearning::Run.on_complete(model_label)
    end
  end
end
