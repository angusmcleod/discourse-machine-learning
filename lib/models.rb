require 'docker'

module DiscourseMachineLearning

  class MlModel
    attr_reader :name,
    attr_accessor :train_cmd, :image, :current_run, :current_data

    DIR = "#{Rails.root}/plugins/discourse-machine-learning/ml_models"

    def initialize(name)
      @name = name
    end

    def self.conf(name)
      return @conf if @conf

      @lock.synchronize do
        @conf ||= YAML.load(File.read(File.join(DIR, name, 'conf.yml')))
      end
    end

    def self.all
      Dir.glob(File.join(DIR)).map { |model| MlModel.create(File.basename(model))}
    end

    def self.create(name, version='latest')
      MlModel.new(name).tap do |m|
        m.image = @conf.namespace
        m.train_cmd = @conf.cmd(version)
        m.current_run =
        m.current_data =
      end
    end
  end

  class MlModelController < ::ApplicationController

    def index
      format.json do
        render_serialized(MlModel.all, MlModelSerializer)
      end
    end
    def train
      name = params[:model_name]
      model = MlModel.create(name)
      container = Docker::Container.create(
        'Image' => model.image,
        'Cmd' => [model.train_cmd],
        'Volumes' => {
          File.join(Rails.root, 'public', 'plugins', 'discourse-machine-learning', 'data', name) => { '/data' => 'rw' }
        }
      )
      container.tap(&:start) { |stream, chunk|
        if stream == :stdout
          puts "#{chunk}"
        end
      }
      ## get checkpoint from docker container when training complete
    end

    def eval
      ## get checkpoint
      ## run eval with checkpoint in docker container
      ## get result
    end

    def run
      ## get input
      ## run input on model
      ## get output
    end
  end

  class MlModelSerializer < ApplicationSerializer
    attributes :name, :status, :current_run, :current_data
  end
end
