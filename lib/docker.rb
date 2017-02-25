require 'docker'

module DiscourseMachineLearning
  class DockerController < ::ApplicationController

    def build_image
      name = params[:name]
      if !Docker::Image.exist?(name)
        Jobs.enqueue(:build_image, name: name, path: @path[name])
      end
      render json: success_json
    end

    def update_status(name, status)
      msg = {
        status: status
      }
      MessageBus.publish("/admin/ml/#{name}/status", msg)
    end
  end
end
