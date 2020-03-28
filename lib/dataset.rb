module DiscourseMachineLearning
  DATA_DIR = "#{Rails.root}/plugins/discourse-machine-learning/public/"

  class Data
    include ActiveModel::SerializerSupport

    attr_reader :filename, :link, :size

    def initialize(filename, set_label, model_label)
      @filename = filename
      @link = UrlHelper.schemaless "#{Discourse.base_url}/plugins/discourse-machine-learning/#{model_label}/#{set_label}/#{filename}"
      @size = File.size(File.join(DATA_DIR, model_label, set_label, filename))
    end
  end

  class Dataset
    include ActiveModel::SerializerSupport

    attr_reader :label, :model_label
    attr_accessor :data

    def initialize(label, model_label)
      @label = label
      @model_label = model_label
    end

    def data
      @data ||= Dir.glob(File.join(DATA_DIR, @model_label, @label, "*")).map do |path|
        Data.new(File.basename(path), @label, @model_label)
      end
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

    def self.all
      datasets = []

      Dir.glob(File.join(DATA_DIR, "*")).map { |path| File.basename(path) }.each do |model_label|
        Dir.glob(File.join(DATA_DIR, model_label, "*")).map { |path| File.basename(path) }.each do |set_label|
          datasets.push(Dataset.new(set_label, model_label))
        end
      end

      datasets
    end
  end
end
