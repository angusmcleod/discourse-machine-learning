module DiscourseMachineLearning
  class RunController < ::ApplicationController
    def index
      render_serialized(Run.all, RunSerializer)
    end

    def train
      model_label = params[:model_label]
      dataset_label = params[:dataset_label]
      
      Run.on_init(model_label, dataset_label)
      
      model = DiscourseMachineLearning::Model.new(model_label)
      image = DiscourseMachineLearning::Image.new(model.image_name)
      
      if image.ready
        Jobs.enqueue(:train_run, model_label: model_label, dataset_label: dataset_label)
        render json: success_json
      else
        render json: failed_json.merge(message: I18n.t("ml.model.no_image", model_label: model_label))
      end
    end

    def test
      label = params[:label]
      model_label = params[:model_label]
      model = DiscourseMachineLearning::Model.new(model_label)
      image = DiscourseMachineLearning::Image.new(model.image_name)

      if image.ready
        Jobs.enqueue(:test_run, label: label, model_label: model_label)
        render json: success_json
      else
        render json: failed_json.merge(message: I18n.t("ml.model.no_image", model_label: model_label))
      end
    end

    def destroy
      label = params[:label]
      model_label = params[:model_label]
      if run = Run.new(label, model_label)
        run.remove
        model = DiscourseMachineLearning::Model.new(model_label)
        if model.run_label == label
          Model.update_run(label, '')
        end

        MessageBus.publish("/admin/ml/runs", {
          action: 'remove',
          label: params[:label]
        })
        render nothing: true
      else
        render nothing: true, status: 404
      end
    end
  end
end