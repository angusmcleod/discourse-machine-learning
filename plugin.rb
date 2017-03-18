# name: discourse-machine-learning
# about: Allows the user to create dockerized machine learning models for use in Discourse
# version: 0.1
# authors: Angus McLeod

register_asset 'stylesheets/ml.scss', :desktop

gem 'docker-api', '1.33.2'

after_initialize do
  load File.expand_path('../jobs/build_image.rb', __FILE__)
  load File.expand_path('../jobs/train_run.rb', __FILE__)
  load File.expand_path('../jobs/test_run.rb', __FILE__)
  load File.expand_path("../lib/dataset.rb", __FILE__)
  load File.expand_path("../lib/docker.rb", __FILE__)
  load File.expand_path("../lib/input.rb", __FILE__)
  load File.expand_path("../lib/model.rb", __FILE__)
  load File.expand_path("../lib/run.rb", __FILE__)

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
    get    "inputs"                               => "input#index"
    get    "models"                               => "model#index"
    post   "models/build-image"                   => "model#build_image"
    post   "models/remove-image"                  => "model#remove_image"
    post   "models/set-run"                       => "model#set_run"
    post   "models/set-input"                     => "model#set_input"
    post   "models/eval"                          => "model#eval"
    get    "runs"                                 => "run#index"
    post   "runs/train"                           => "run#train"
    post   "runs/test"                            => "run#test"
    delete "runs/:model_label/:label"             => "run#destroy"
    get    "datasets"                             => "dataset#index"
    post   "datasets/:model_label/:label/:type"   => "dataset#upload"
    delete "datasets/:model_label/:label"         => "dataset#destroy"
  end
end
