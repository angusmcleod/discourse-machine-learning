# name: discourse-machine-learning
# about: Allows the user to create dockerized machine learning models for use in Discourse
# version: 0.1
# authors: Angus McLeod

register_asset 'stylesheets/ml.scss', :desktop

gem 'docker-api', '1.33.2'

after_initialize do
  load File.expand_path('../jobs/build_model_image.rb', __FILE__)
  load File.expand_path("../lib/data.rb", __FILE__)
  load File.expand_path("../lib/models.rb", __FILE__)

  require_dependency "application_controller"
  module ::DiscourseMachineLearning
    class Engine < ::Rails::Engine
      engine_name "discourse_machine_learning"
      isolate_namespace DiscourseMachineLearning
    end
  end

  require_dependency "admin_constraint"
  Discourse::Application.routes.append do
    namespace :admin, constraints: AdminConstraint.new do
      mount ::DiscourseMachineLearning::Engine, at: "ml"
    end
  end

  DiscourseMachineLearning::Engine.routes.draw do
    post "build-model-image" => "models#build_image"
    post "remove-model-image" => "models#remove_image"
    post "train" => "models#train"
    post "eval" => "models#eval"
    post "run" => "models#run"
    get "models" => "models#index"
  end
end
