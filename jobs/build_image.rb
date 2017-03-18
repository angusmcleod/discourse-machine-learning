module Jobs
  class BuildImage < Jobs::Base
    sidekiq_options timeout: 1000

    def execute(args)
      model_label = args[:model_label]
      model = DiscourseMachineLearning::Model.new(model_label)
      model.update_status(DiscourseMachineLearning::Model.statuses[:building])

      DiscourseMachineLearning::DockerHelper.build_image(model)

      model.update_status
    end
  end
end
