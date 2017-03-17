module DiscourseMachineLearning
  class Dataset
    include ActiveModel::SerializerSupport

    attr_reader :label
    attr_accessor :model_label, :train_link, :test_link, :train_size, :test_size

    DATA_DIR = "#{Rails.root}/plugins/discourse-machine-learning/public/"

    def initialize(label, model_label)
      @label = label
      @model_label = model_label
      @train_path = File.join(DATA_DIR, model_label, label, 'train.txt')
      @test_path = File.join(DATA_DIR, model_label, label, 'test.txt')
      public_link = "#{Discourse.base_url}/plugins/discourse-machine-learning/#{model_label}/#{label}"
      @train_link = UrlHelper.schemaless "#{public_link}/train.txt"
      @test_link = UrlHelper.schemaless "#{public_link}/test.txt"
      @train_size = File.size(@train_path)
      @test_size = File.size(@test_path)
    end

    def self.all
      datasets = []
      model_labels = Dir.glob(File.join(DATA_DIR, "*")).map { |model| File.basename(model) }
      model_labels.each { |model_label|
        model_datasets = Dir.glob(File.join(DATA_DIR, model_label, "*")).map { |set| Dataset.new(File.basename(set), model_label)}
        datasets.concat model_datasets
      }
      datasets
    end

    def remove
      FileUtils.rm_rf("#{DATA_DIR}/#{@model_label}/#{@label}")
    end

    def after_create_hook
      upload_to_s3 if SiteSetting.enable_ml_data_backups?
    end

    def after_remove_hook
      remove_from_s3 if SiteSetting.enable_ml_data_backups? && !SiteSetting.s3_disable_cleanup?
    end

    def s3_bucket
      return @s3_bucket if @s3_bucket
      raise Discourse::SiteSettingMissing.new("s3_ml_data_bucket") if SiteSetting.s3_ml_data_bucket.blank?
      @s3_bucket = SiteSetting.s3_ml_data_bucket.downcase
    end

    def s3
      require "s3_helper" unless defined? S3Helper
      @s3_helper ||= S3Helper.new(s3_bucket)
    end

    def upload_to_s3
      return unless s3
      File.open(@train_path) do |file|
        s3.upload(file, "#{@label}_train.txt")
      end
      File.open(@test_path) do |file|
        s3.upload(file, "#{@label}_test.txt")
      end
    end

    def remove_from_s3
      return unless s3
      s3.remove(@filename)
    end
  end

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

  class DatasetSerializer < ::ApplicationSerializer
    attributes :label, :model_label, :train_link, :test_link, :train_size, :test_size
  end
end
