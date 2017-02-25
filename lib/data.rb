module DiscourseMachineLearning
  class MlData < ::Backup

    def self.all
      Dir.glob(File.join(MlData.base_directory, "*.{txt}"))
         .sort_by { |file| File.mtime(file) }
         .reverse
         .map { |data_file| MlData.create_from_modelname(File.basename(data_file)) }
    end

    def self.[](model, version)
      path = File.join(MlData.base_directory, model, version)
      if File.exists?(path)
        MlData.create_from_file(model, version)
      else
        nil
      end
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
      File.open(@path) do |file|
        s3.upload(file, @filename)
      end
    end

    def remove_from_s3
      return unless s3
      s3.remove(@filename)
    end

    def self.base_directory
      base_directory = File.join(Rails.root, "public", "plugins", "discourse-machine-learning", "data")
      FileUtils.mkdir_p(base_directory) unless Dir.exists?(base_directory)
      base_directory
    end

    def self.create_from_file(model, version)
      MlData.new(model + version).tap do |f|
        f.path = File.join(MlData.base_directory, model, version)
        f.link = UrlHelper.schemaless "#{Discourse.base_url}/admin/ml/#{model}"
        f.size = File.size(f.path)
      end
    end
  end

  class MlDataController < ::ApplicationController

  end
end
