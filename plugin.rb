# name: discourse-machine-learning
# about: Allows the user to create dockerized machine learning models for use in Discourse
# version: 0.2.0
# authors: Angus McLeod

register_asset 'stylesheets/ml.scss', :desktop

gem 'docker-api', '1.34.2'

after_initialize do
  %w[
    ../lib/engine.rb
    ../lib/container.rb
    ../lib/dataset.rb
    ../lib/docker.rb
    ../lib/model.rb
    ../lib/run.rb
    ../app/controllers/dataset_controller.rb
    ../app/controllers/image_controller.rb
    ../app/controllers/model_controller.rb
    ../app/controllers/run_controller.rb
    ../app/serializers/data_serializer.rb
    ../app/serializers/dataset_serializer.rb
    ../app/serializers/image_serializer.rb
    ../app/serializers/model_serializer.rb
    ../app/serializers/run_serializer.rb
    ../config/routes.rb
    ../jobs/build_image.rb
    ../jobs/test_run.rb
    ../jobs/train_run.rb
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end
end
