# name: discourse-machine-learning
# about: Allows the user to create dockerized machine learning models for use in Discourse
# version: 0.1
# authors: Angus McLeod

gem 'docker-api', '1.33.2'

after_initialize do
  require 'docker'
  load File.expand_path('../jobs/build_image.rb', __FILE__)

  $IMAGES = {
    tf: {
      namespace: 'tensorflow/tensorflow',
      tag: 'tensorflow:latest'
    },
    tf_syntaxnet: {
      path: "/plugins/discourse-machine-learning/models/tf-syntaxnet",
      tag: 'syntaxnet:latest'
    }
  }

  module ::DiscourseMachineLearning
    class Engine < ::Rails::Engine
      engine_name "discourse_machine_learning"
      isolate_namespace DiscourseMachineLearning
    end
  end

  Discourse::Application.routes.append do
    mount ::DiscourseMachineLearning::Engine, at: "ml"
  end

  require_dependency "admin_constraint"
  DiscourseMachineLearning::Engine.routes.draw do
    post "/build-image" => "ml#build_image", constraints: AdminConstraint.new
  end

  require_dependency "application_controller"
  class DiscourseMachineLearning::MachineLearningController < ::ApplicationController
    def build_image
      image = $IMAGES[params[:name]]
      if !Docker::Image.exist?(image.tag)
        Jobs.enqueue(:build_image, image)
      end
      render json: success_json
    end

    def update_status(status, label)
      $redis.set `#{label}_image`, status
      channel = "/admin/image-status"
      msg = { label: label, status: status }
      MessageBus.publish(channel, msg)
    end
  end
end
