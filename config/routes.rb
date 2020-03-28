require_dependency "admin_constraint"
Discourse::Application.routes.append do
  namespace :admin, constraints: AdminConstraint.new do
    mount ::DiscourseMachineLearning::Engine, at: "ml"
  end
end

DiscourseMachineLearning::Engine.routes.draw do
  get    "images"                               => "image#index"
  post   "images/build"                         => "image#build"
  post   "images/remove"                        => "image#remove"
  get    "models"                               => "model#index"
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