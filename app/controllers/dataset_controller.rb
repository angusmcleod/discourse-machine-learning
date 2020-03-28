module DiscourseMachineLearning
  class DatasetController < ::ApplicationController
    DATA_DIR = "#{Rails.root}/plugins/discourse-machine-learning/public/"

    def index
      render_serialized(Dataset.all, DatasetSerializer)
    end

    def upload
      file = params[:file] || params[:files].first
      type = params[:type]
      filename = type + '.txt'
      file_path = "#{DATA_DIR}/#{params[:model_label]}/#{params[:label]}/#{filename}"

      FileUtils.mkdir_p(Pathname.new(file_path).dirname)
      File.open(file_path, "wb") { |f| f << file.read }

      MessageBus.publish("/uploads/txt", { url: file_path }.as_json, user_ids: [current_user.id])
      render json: success_json
    end

    def destroy
      if dataset = Dataset.new(params[:label], params[:model_label])
        dataset.remove
        MessageBus.publish("/admin/ml/datasets", {
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