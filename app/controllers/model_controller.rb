module DiscourseMachineLearning
  class ModelController < ::ApplicationController
    def index
      render_serialized(Model.all, ModelSerializer)
    end

    def set_run
      Model.update_run(params[:model_label], params[:run_label])
      render json: success_json
    end

    def eval
      label = params[:label]
      input = params[:input]

      model = Model.new(model_label)

      image = Image.new(model.image_name)

      if image.ready
        model.eval(input)
        render json: success_json
      else
        render json: failed_json.merge(message: I18n.t("ml.model.no_image", model_label: model_label))
      end
    end
  end
end