module Jobs
  class BuildImage < ::Jobs::Base
    sidekiq_options timeout: 1000

    def execute(args)
      model_label = args[:model_label]
      model = DiscourseMachineLearning::Model.new(model_label)
      image.update_status(DiscourseMachineLearning::Model.statuses[:building])

      DiscourseMachineLearning::Image.build(model.label)

      image.update_status
    end
  end
end
