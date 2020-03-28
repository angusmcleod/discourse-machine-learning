module DiscourseMachineLearning
  class ImageController < ::ApplicationController
    def index
      render_serialized(Image.all, ImageSerializer)
    end

    def build
      name = params[:name]

      if !Image.exists(name)
        Jobs.enqueue(:build_image, name: name)
      end
      render json: success_json
    end

    def remove
      name = params[:name]

      if Image.exists(name)
        image = Image.get(name)
        image.remove(:force => true)
      end

      if !Image.exists(name)
        MessageBus.publish("/admin/ml/images", { name: name, action: "remove" })
      end

      render json: success_json
    end
  end
end