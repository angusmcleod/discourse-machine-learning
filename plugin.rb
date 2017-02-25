# name: discourse-machine-learning
# about: Allows the user to create dockerized machine learning models for use in Discourse
# version: 0.1
# authors: Angus McLeod

gem 'docker-api', '1.33.2'

after_initialize do
  load File.expand_path('../jobs/build_image.rb', __FILE__)
  load File.expand_path("../lib/docker.rb", __FILE__)
  load File.expand_path("../lib/data.rb", __FILE__)
  load File.expand_path("../lib/models.rb", __FILE__)

  require_dependency "application_controller"
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
    namespace :admin, constraints: AdminConstraint.new do
      post "/ml/build-image" => "ml/docker#build_image"
      post "/ml/train" => "ml/models#train"
      post "/ml/eval" => "ml/models#eval"
      post "/ml/run" => "ml/models#run"
  end
end
