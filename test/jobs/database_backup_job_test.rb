require "test_helper"
require "aws-sdk-s3"
require "ostruct"

class FakeS3Client
  attr_reader :puts, :lists, :deletes

  def initialize(raise_on_put: false)
    @puts = []
    @lists = []
    @deletes = []
    @raise_on_put = raise_on_put
    @list_response = OpenStruct.new(contents: [])
  end

  def stub_list_response(response)
    @list_response = response
  end

  def put_object(**args)
    raise Aws::S3::Errors::ServiceError.new(nil, "Connection failed") if @raise_on_put
    @puts << args
  end

  def list_objects_v2(**args)
    @lists << args
    @list_response
  end

  def delete_objects(**args)
    @deletes << args
  end
end

class DatabaseBackupJobTest < ActiveJob::TestCase
  setup do
    @backup_dir = Rails.root.join("tmp")
    FileUtils.mkdir_p(@backup_dir)

    @credentials = OpenStruct.new(
      key_id: "test-key-id",
      application_key: "test-app-key",
      bucket: "thriftbot-backups",
      endpoint: "https://s3.us-east-005.backblazeb2.com",
      region: "us-east-005"
    )
  end

  test "creates a valid sqlite3 backup and uploads to S3" do
    fake_client = FakeS3Client.new
    job = build_job_with_fake_client(fake_client)

    job.perform_now

    assert_equal 1, fake_client.puts.size, "Should upload one file"
    assert_match %r{^backups/thriftbot_\d{8}_\d{6}\.sqlite3$}, fake_client.puts.first[:key]
    assert_equal "thriftbot-backups", fake_client.puts.first[:bucket]
  end

  test "prunes backups older than retention period" do
    old_backup = OpenStruct.new(key: "backups/thriftbot_20240101_030000.sqlite3", last_modified: 30.days.ago)
    recent_backup = OpenStruct.new(key: "backups/thriftbot_recent.sqlite3", last_modified: 1.day.ago)

    fake_client = FakeS3Client.new
    fake_client.stub_list_response(OpenStruct.new(contents: [ old_backup, recent_backup ]))

    job = build_job_with_fake_client(fake_client)
    job.perform_now

    assert_equal 1, fake_client.deletes.size, "Should delete old backups"
    deleted_keys = fake_client.deletes.first[:delete][:objects].map { |o| o[:key] }
    assert_includes deleted_keys, old_backup.key
    refute_includes deleted_keys, recent_backup.key
  end

  test "cleans up temp file even on upload error" do
    fake_client = FakeS3Client.new(raise_on_put: true)
    job = build_job_with_fake_client(fake_client)

    # retry_on catches the S3 error and re-enqueues, so perform_now won't raise.
    # The ensure block in perform should still clean up the temp file.
    job.perform_now

    leftover = Dir.glob(Rails.root.join("tmp", "thriftbot_*.sqlite3"))
    assert_empty leftover, "Temp backup files should be cleaned up"
  end

  private

  def build_job_with_fake_client(fake_client)
    job = DatabaseBackupJob.new
    credentials = @credentials

    job.define_singleton_method(:s3_client) { fake_client }
    job.define_singleton_method(:credentials) { credentials }

    job
  end
end
