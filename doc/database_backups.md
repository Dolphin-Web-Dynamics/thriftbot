# Database Backups

Thriftbot uses automated daily backups of its SQLite production database to [Backblaze B2](https://www.backblaze.com/cloud-storage) cloud storage. Backups run on the existing Solid Queue infrastructure with zero additional monthly cost (B2 free tier: 10 GB).

---

## Architecture Overview

```mermaid
graph LR
  subgraph Hetzner VPS
    PU[Puma + Solid Queue]
    DB[(SQLite<br/>production.sqlite3)]
    TMP[tmp/ snapshot]
  end

  subgraph Backblaze B2
    BK[thriftbot-backups<br/>bucket]
  end

  PU -- "3 AM daily" --> JOB[[DatabaseBackupJob]]
  JOB -- "sqlite3 .backup" --> DB
  DB -- consistent snapshot --> TMP
  TMP -- "S3 PUT via aws-sdk-s3" --> BK
  JOB -- "prune > 7 days" --> BK
```

## Backup Lifecycle

```mermaid
sequenceDiagram
    participant SQ as Solid Queue
    participant Job as DatabaseBackupJob
    participant SQLite as SQLite DB
    participant Disk as tmp/
    participant B2 as Backblaze B2

    SQ->>Job: Enqueue at 3:00 AM
    activate Job

    Job->>SQLite: sqlite3 .backup
    SQLite-->>Disk: thriftbot_YYYYMMDD_HHMMSS.sqlite3

    Job->>Disk: Open backup file
    Disk-->>Job: File handle
    Job->>B2: PUT backups/thriftbot_YYYYMMDD_HHMMSS.sqlite3
    B2-->>Job: 200 OK

    Job->>B2: LIST backups/*
    B2-->>Job: Object list with timestamps
    Job->>B2: DELETE objects older than 7 days
    B2-->>Job: 200 OK

    Job->>Disk: rm tmp/thriftbot_*.sqlite3
    deactivate Job

    Note over Job,Disk: ensure block deletes temp file<br/>even if upload fails
```

## Retention Policy

```mermaid
gantt
    title 7-Day Rolling Backup Window
    dateFormat  YYYY-MM-DD
    axisFormat  %a %m/%d

    section Retained
    Day 1 backup  :active, d1, 2026-02-02, 1d
    Day 2 backup  :active, d2, 2026-02-03, 1d
    Day 3 backup  :active, d3, 2026-02-04, 1d
    Day 4 backup  :active, d4, 2026-02-05, 1d
    Day 5 backup  :active, d5, 2026-02-06, 1d
    Day 6 backup  :active, d6, 2026-02-07, 1d
    Day 7 backup  :active, d7, 2026-02-08, 1d

    section Pruned
    Day 8+ backups :done, d8, 2026-01-25, 7d
```

- **Schedule:** Every day at 3:00 AM (server time)
- **Retention:** 7 days (configurable via `DatabaseBackupJob::RETENTION_DAYS`)
- **Restore points:** Up to 7 at any given time
- **Pruning:** Old backups are deleted automatically after each new backup uploads

---

## How It Works

### 1. Consistent Snapshot

The job uses SQLite's built-in `.backup` command, which creates an atomic, consistent copy of the database — safe to run while the app is reading and writing:

```ruby
system("sqlite3", db_path.to_s, ".backup '#{backup_path}'", exception: true)
```

This is **not** a file copy. SQLite's backup API handles WAL checkpointing and page-level locking internally, guaranteeing a valid database file.

### 2. Upload to Backblaze B2

The snapshot is uploaded to B2 using the S3-compatible API (`aws-sdk-s3` gem). The gem is lazy-loaded (`require: false` in Gemfile, `require "aws-sdk-s3"` inside `perform`) so it only occupies memory when the job actually runs.

```
Bucket:  thriftbot-backups
Key:     backups/thriftbot_20260209_030000.sqlite3
```

### 3. Prune Old Backups

After uploading, the job lists all objects in the `backups/` prefix and deletes any older than 7 days via a single batch `DELETE` call.

### 4. Cleanup

An `ensure` block guarantees the local temp file is removed regardless of success or failure.

### 5. Error Handling

Transient S3 errors trigger automatic retries:

```ruby
retry_on Aws::S3::Errors::ServiceError, wait: :polynomially_longer, attempts: 3
```

This gives 3 attempts with increasing wait times (3s, 18s, 83s) before the job is discarded.

---

## File Map

| File | Purpose |
|------|---------|
| `app/jobs/database_backup_job.rb` | The backup job: snapshot, upload, prune |
| `config/recurring.yml` | Solid Queue schedule (daily at 3 AM) |
| `lib/tasks/backup.rake` | Rake tasks for manual operations |
| `config/deploy.yml` | Kamal `backup` alias |
| `test/jobs/database_backup_job_test.rb` | Job tests |

---

## Credentials

Stored in Rails encrypted credentials (`config/credentials.yml.enc`), decrypted at runtime by `RAILS_MASTER_KEY`:

```yaml
backblaze:
  key_id: "..."          # B2 application key ID (scoped to bucket)
  application_key: "..." # B2 application key secret
  bucket: "thriftbot-backups"
  endpoint: "https://s3.us-west-004.backblazeb2.com"
  region: "us-west-004"
```

The application key is scoped to the `thriftbot-backups` bucket only, with these capabilities: `deleteFiles`, `listBuckets`, `listFiles`, `readBuckets`, `readFiles`, `writeFiles`.

No additional Kamal secrets are needed — everything flows through the existing `RAILS_MASTER_KEY`.

```mermaid
graph TD
    MK[RAILS_MASTER_KEY] -->|decrypts| CRED[credentials.yml.enc]
    CRED -->|backblaze.key_id| S3[Aws::S3::Client]
    CRED -->|backblaze.application_key| S3
    CRED -->|backblaze.endpoint| S3
    CRED -->|backblaze.region| S3
    CRED -->|backblaze.bucket| S3
    S3 -->|S3 API| B2[Backblaze B2]
```

---

## Usage

### Automatic (production)

Runs automatically via Solid Queue. No action needed after deployment.

Check the Solid Queue dashboard or Rails logs for:
```
Database backup completed: thriftbot_20260209_030000.sqlite3
```

### Manual Backup

**Local:**
```bash
bin/rails db:backup
```

**Production (via Kamal):**
```bash
bin/kamal backup
```

### List Backups

**Local:**
```bash
bin/rails db:backup_list
```

**Production:**
```bash
bin/kamal app exec "bin/rails db:backup_list"
```

Example output:
```
Available backups:
----------------------------------------------------------------------
Filename                                         Size Date
----------------------------------------------------------------------
thriftbot_20260209_030000.sqlite3              2.28 MB 2026-02-09 03:00:00 UTC
thriftbot_20260208_030000.sqlite3              2.25 MB 2026-02-08 03:00:00 UTC
----------------------------------------------------------------------
Total: 2 backup(s)
```

### Restore from Backup

**1. Download the backup:**
```bash
bin/rails db:restore[thriftbot_20260209_030000.sqlite3]
```

**2. Stop the app, swap the database, restart:**
```bash
bin/kamal app stop
# Copy the downloaded file into the storage volume
bin/kamal app exec "cp tmp/thriftbot_20260209_030000.sqlite3 storage/production.sqlite3"
bin/kamal app start
```

---

## Monitoring

### Verify backups are running

```bash
# Check the latest backup in B2
bin/kamal app exec "bin/rails db:backup_list"

# Check Solid Queue logs for the job
bin/kamal logs | grep "Database backup"
```

### What to look for

| Signal | Meaning |
|--------|---------|
| `Database backup completed: thriftbot_*.sqlite3` | Backup succeeded |
| `Uploaded ... to B2 (N bytes)` | Upload confirmed with file size |
| `Pruned N backup(s) older than 7 days` | Old backups cleaned up |
| `Aws::S3::Errors::ServiceError` in logs | Upload failed (will retry up to 3 times) |

### If backups stop working

1. Check credentials are still valid: `bin/rails credentials:show` (look for `backblaze:` section)
2. Check B2 key hasn't expired: log in to [Backblaze B2 Console](https://secure.backblaze.com/b2_buckets.htm)
3. Check Solid Queue is processing jobs: look at `solid_queue_jobs` table for failed entries
4. Run a manual backup to see the error: `bin/kamal backup`

---

## Cost

| Resource | Cost |
|----------|------|
| Backblaze B2 storage (free tier) | $0.00/mo (up to 10 GB) |
| Solid Queue (runs in Puma process) | $0.00/mo (no extra server) |
| `aws-sdk-s3` gem | Free, open source |
| **Total** | **$0.00/mo** |

At ~2.3 MB per backup and 7-day retention, storage usage is approximately **16 MB** — well within the 10 GB free tier.
