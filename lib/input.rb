module DiscourseMachineLearning
  class Input
    include ActiveModel::SerializerSupport

    attr_reader :label

    DATA_DIR = "#{Rails.root}/plugins/discourse-machine-learning/public/"

    def initialize(label, model_label)
      @label = label
      @model_label = model_label
    end

    def self.all
      PluginStore.get('discourse-machine-learning', 'inputs') || []
    end
  end

  class InputController < ::ApplicationController
    def index
      render_serialized(Input.all, InputSerializer)
    end
  end

  class InputSerializer < ::ApplicationSerializer
    attributes :label
  end
end
