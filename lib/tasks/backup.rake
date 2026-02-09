namespace :db do
  desc "Run an immediate database backup to Backblaze B2"
  task backup: :environment do
    puts "Starting database backup..."
    DatabaseBackupJob.perform_now
    puts "Backup complete!"
  end

  desc "List available backups on Backblaze B2"
  task backup_list: :environment do
    require "aws-sdk-s3"

    credentials = Rails.application.credentials.backblaze
    client = Aws::S3::Client.new(
      endpoint: credentials.endpoint,
      region: credentials.region,
      access_key_id: credentials.key_id,
      secret_access_key: credentials.application_key,
      force_path_style: true
    )

    response = client.list_objects_v2(bucket: credentials.bucket, prefix: "backups/")

    if response.contents.blank?
      puts "No backups found."
    else
      puts "Available backups:"
      puts "-" * 70
      printf "%-40s %12s %s\n", "Filename", "Size", "Date"
      puts "-" * 70
      response.contents.sort_by(&:last_modified).reverse.each do |obj|
        filename = obj.key.sub("backups/", "")
        size_mb = (obj.size / 1_048_576.0).round(2)
        date = obj.last_modified.strftime("%Y-%m-%d %H:%M:%S UTC")
        printf "%-40s %10.2f MB %s\n", filename, size_mb, date
      end
      puts "-" * 70
      puts "Total: #{response.contents.size} backup(s)"
    end
  end

  desc "Download a backup from Backblaze B2 (usage: rails db:restore[filename])"
  task :restore, [ :filename ] => :environment do |_t, args|
    require "aws-sdk-s3"

    filename = args[:filename]
    if filename.blank?
      puts "Usage: bin/rails db:restore[thriftbot_20250101_030000.sqlite3]"
      puts "Run 'bin/rails db:backup_list' to see available backups."
      exit 1
    end

    credentials = Rails.application.credentials.backblaze
    client = Aws::S3::Client.new(
      endpoint: credentials.endpoint,
      region: credentials.region,
      access_key_id: credentials.key_id,
      secret_access_key: credentials.application_key,
      force_path_style: true
    )

    key = "backups/#{filename}"
    dest = Rails.root.join("tmp", filename)

    puts "Downloading #{filename}..."
    client.get_object(
      bucket: credentials.bucket,
      key: key,
      response_target: dest.to_s
    )

    puts "Downloaded to: #{dest}"
    puts ""
    puts "To restore, stop the app and replace the database:"
    puts "  1. bin/kamal app stop"
    puts "  2. cp #{dest} storage/production.sqlite3"
    puts "  3. bin/kamal app start"
  end
end
