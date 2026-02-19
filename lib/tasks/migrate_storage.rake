namespace :storage do
  desc "Migrate Active Storage blobs from local disk to Cloudflare R2"
  task migrate_to_r2: :environment do
    require "aws-sdk-s3"

    r2_service = ActiveStorage::Blob.services.fetch(:cloudflare_r2)
    total = ActiveStorage::Blob.count
    migrated = 0
    skipped = 0
    failed = 0

    puts "Starting migration of #{total} blobs to Cloudflare R2..."

    ActiveStorage::Blob.find_each do |blob|
      if r2_service.exist?(blob.key)
        skipped += 1
        puts "  [SKIP] #{blob.key} (already exists on R2)"
        next
      end

      local_path = ActiveStorage::Blob.service.path_for(blob.key)
      unless File.exist?(local_path)
        failed += 1
        puts "  [FAIL] #{blob.key} (local file not found at #{local_path})"
        next
      end

      begin
        File.open(local_path, "rb") do |file|
          r2_service.upload(blob.key, file, checksum: blob.checksum,
            content_type: blob.content_type)
        end
        migrated += 1
        puts "  [OK]   #{blob.key} (#{(blob.byte_size / 1024.0).round(1)} KB)"
      rescue => e
        failed += 1
        puts "  [FAIL] #{blob.key}: #{e.message}"
      end
    end

    puts "\nMigration complete: #{migrated} migrated, #{skipped} skipped, #{failed} failed (#{total} total)"
  end

  desc "Verify all Active Storage blobs exist on Cloudflare R2"
  task verify_r2: :environment do
    require "aws-sdk-s3"

    r2_service = ActiveStorage::Blob.services.fetch(:cloudflare_r2)
    total = ActiveStorage::Blob.count
    present = 0
    missing = 0

    puts "Verifying #{total} blobs on Cloudflare R2..."

    ActiveStorage::Blob.find_each do |blob|
      if r2_service.exist?(blob.key)
        present += 1
      else
        missing += 1
        puts "  [MISSING] #{blob.key} (#{blob.filename})"
      end
    end

    puts "\nVerification complete: #{present} present, #{missing} missing (#{total} total)"
    exit(1) if missing > 0
  end
end
