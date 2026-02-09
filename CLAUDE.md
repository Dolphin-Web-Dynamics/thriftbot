## ClaudeOnRails Configuration

You are working on Thriftbot, a Rails application. Review the ClaudeOnRails context file at @.claude-on-rails/context.md

## Project Overview

Thriftbot is a thrift store inventory management app built with Rails 8.1.2 / Ruby 4.0.1.

## Infrastructure

- **Domain**: thriftbot.smelltherosessecondhand.com (DNS in AWS Route53)
- **Server**: Hetzner cpx11 (2 vCPU, 2GB RAM, Ashburn US East) — $4.99/mo
- **Server IP**: 178.156.251.188
- **Container Registry**: Docker Hub (`kanto2022/thriftbot`)
- **SSL**: Let's Encrypt via kamal-proxy (auto-renewing)
- **Database**: SQLite (stored in persistent Docker volume `thriftbot_storage`)
- **Deployment**: Kamal 2 with remote builder (builds on the Hetzner server)

## Deployment

### CI/CD (GitHub Actions)
Push to `main` triggers two workflows:
- `ci.yml` — tests, linting, security scans (brakeman, bundler-audit, importmap audit)
- `deploy.yml` — builds image on Hetzner, pushes to Docker Hub, deploys via Kamal

### Manual Deploy
```bash
KAMAL_REGISTRY_PASSWORD="<docker-hub-pat>" ADMIN_PASSWORD="<password>" kamal deploy
```

### Secrets

| Secret | Where Stored | Purpose |
|--------|-------------|---------|
| `KAMAL_REGISTRY_PASSWORD` | GitHub Actions secret + local env | Docker Hub PAT for pushing/pulling images |
| `ADMIN_PASSWORD` | GitHub Actions secret + local env | Admin login password, injected into container |
| `RAILS_MASTER_KEY` | `config/master.key` (gitignored) + `.kamal/secrets` | Decrypts Rails credentials |
| `SSH_PRIVATE_KEY` | GitHub Actions secret | SSH access to Hetzner server for deploy |

Secrets flow: GitHub Actions secret → Kamal → container environment variable. Never stored in Docker Hub.

## Git Workflow

**Never commit features or bug fixes directly to `main`.** Always use a feature branch and open a pull request.

### Before Starting Any Work
1. Pull the latest from `main` to make sure you're up to date with origin:
   ```bash
   git checkout main
   git pull origin main
   ```
2. Create a new branch for your work:
   ```bash
   git checkout -b your-branch-name
   ```
3. When ready, use the `/commit-push-pr` skill to commit, push, and open a PR in one step.

### Branch Naming
- Features: `feature/short-description`
- Bug fixes: `fix/short-description`
- Chores/docs: `chore/short-description`

## GitHub

- **Repo**: Dolphin-Web-Dynamics/thriftbot
- **Admin email**: tiredbutokrn@gmail.com
