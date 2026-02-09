class DatabaseBackupJob < ApplicationJob
  queue_as :default

  retry_on Aws::S3::Errors::ServiceError, wait: :polynomially_longer, attempts: 3 if defined?(Aws)

  RETENTION_DAYS = 7

  def perform
    require "aws-sdk-s3"

    db_path = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: "primary").database
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    backup_filename = "thriftbot_#{timestamp}.sqlite3"
    backup_path = Rails.root.join("tmp", backup_filename)

    create_backup(db_path, backup_path)
    upload_to_b2(backup_path, backup_filename)
    prune_old_backups

    Rails.logger.info "Database backup completed: #{backup_filename}"
  ensure
    FileUtils.rm_f(backup_path) if backup_path
  end

  private

  def create_backup(db_path, backup_path)
    FileUtils.mkdir_p(File.dirname(backup_path))
    system("sqlite3", db_path.to_s, ".backup '#{backup_path}'", exception: true)
  end

  def upload_to_b2(backup_path, filename)
    key = "backups/#{filename}"
    File.open(backup_path, "rb") do |file|
      s3_client.put_object(
        bucket: bucket_name,
        key: key,
        body: file
      )
    end
    Rails.logger.info "Uploaded #{filename} to B2 (#{File.size(backup_path)} bytes)"
  end

  def prune_old_backups
    cutoff = RETENTION_DAYS.days.ago
    response = s3_client.list_objects_v2(bucket: bucket_name, prefix: "backups/")

    return unless response.contents

    old_objects = response.contents.select { |obj| obj.last_modified < cutoff }
    return if old_objects.empty?

    s3_client.delete_objects(
      bucket: bucket_name,
      delete: {
        objects: old_objects.map { |obj| { key: obj.key } }
      }
    )
    Rails.logger.info "Pruned #{old_objects.size} backup(s) older than #{RETENTION_DAYS} days"
  end

  def s3_client
    @s3_client ||= Aws::S3::Client.new(
      endpoint: credentials.endpoint,
      region: credentials.region,
      access_key_id: credentials.key_id,
      secret_access_key: credentials.application_key,
      force_path_style: true
    )
  end

  def bucket_name
    credentials.bucket
  end

  def credentials
    @credentials ||= Rails.application.credentials.backblaze
  end
end
