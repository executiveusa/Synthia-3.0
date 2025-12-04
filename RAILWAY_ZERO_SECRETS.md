# Railway Zero-Secrets Bootstrapper for Synthia 3.0

## What is the Zero-Secrets Architecture?

The Railway Zero-Secrets Bootstrapper is an autonomous deployment system that enables **any Git repository** to be deployed to Railway (or other platforms) with **guaranteed first-deploy success** and **zero secrets committed to the repository**.

### Core Principles

1. **First Deploy Always Works**: Minimal configuration ensures successful initial deployment
2. **Secrets Never Committed**: All sensitive data stays local or in environment variables
3. **Cost Protection Built-In**: Automatic guardrails prevent runaway spend
4. **Platform Agnostic**: Works with Railway, Coolify, Google Cloud Run, or local Docker
5. **Progressive Enhancement**: Start minimal, add features as needed

## Quick Start

### 1. Initialize Zero-Secrets System

```bash
# Run the setup wizard
./scripts/setup-zero-secrets.sh
```

This will:
- ✓ Verify all deployment files exist
- ✓ Create local `master.secrets.json` from template
- ✓ Initialize `.env` for local development
- ✓ Guide you through deployment options

### 2. Deploy to Railway

```bash
# One-command deployment
./scripts/railway/deploy.sh
```

This automatically:
- ✓ Installs and configures Railway CLI
- ✓ Creates/links Railway project
- ✓ Adds PostgreSQL plugin
- ✓ Sets required environment variables
- ✓ Deploys application
- ✓ Displays public URL

### 3. Verify Deployment

```bash
# Check health
curl https://your-app.railway.app/healthz

# Expected response:
# {"status":"ok","mode":"openrouter"}
```

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Your Repository                          │
│                                                             │
│  ┌────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │  .agents   │  │ railway.toml │  │ maintenance.html │   │
│  │            │  │              │  │                  │   │
│  │ Secrets    │  │ Cost guards  │  │ Fallback page    │   │
│  │ inventory  │  │ Resource     │  │ Free-tier        │   │
│  │            │  │ limits       │  │ exceeded mode    │   │
│  └────────────┘  └──────────────┘  └──────────────────┘   │
│                                                             │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ Deploy
                        ▼
    ┌───────────────────────────────────────────────┐
    │           Railway Platform                    │
    │                                               │
    │  ┌──────────────┐      ┌─────────────────┐  │
    │  │  Synthia     │◄─────│  PostgreSQL     │  │
    │  │  Backend     │      │  Plugin         │  │
    │  │              │      │                 │  │
    │  │  PORT: 8080  │      │  AUTO-INJECTED  │  │
    │  └──────────────┘      └─────────────────┘  │
    │         │                                    │
    │         │ Health: /healthz                   │
    │         ▼                                    │
    │  [Public URL]                                │
    └───────────────────────────────────────────────┘
          │
          │ If limits exceeded
          ▼
    ┌───────────────────────────────────────────────┐
    │     Automatic Maintenance Mode                │
    │                                               │
    │  maintenance.html deployed as static site     │
    │  Main service suspended                       │
    │  Migration to Coolify prepared                │
    └───────────────────────────────────────────────┘
```

## Key Files Explained

### `.agents` - Secret Inventory

Machine-readable JSON file documenting all secrets:

```json
{
  "project": "Synthia-3.0",
  "core": [...],              // Required environment variables
  "ai_providers": [...],      // AI API keys (optional)
  "optional_integrations": [...],  // Third-party services
  "required_secrets": ["DATABASE_URL"],
  "optional_secrets": ["OPENROUTER_API_KEY", ...],
  "integration_stubs": {...}  // How to disable integrations
}
```

**Purpose**: Enables separate agents to inject secrets without modifying code.

### `master.secrets.json` - Local Secret Storage

**⚠️ NEVER COMMITTED TO GIT** (in `.gitignore`)

Stores all your secrets locally:

```json
{
  "projects": {
    "synthia-3.0": {
      "environments": {
        "development": { /* local secrets */ },
        "production": { /* production secrets */ },
        "railway": { /* Railway-specific secrets */ }
      }
    }
  }
}
```

**Purpose**: Single source of truth for all secrets across all environments.

### `railway.toml` - Deployment Configuration

Railway deployment config with cost protection:

```toml
[build]
builder = "nixpacks"
buildCommand = "cd backend && npm install && npm run build"

[deploy]
startCommand = "cd backend && npm start"
numReplicas = 1  # Cost protection: single replica

[deploy.resources]
# Minimal resource allocation
# Stays within free tier limits
```

**Purpose**: Ensures deployments stay cost-efficient.

### `maintenance.html` - Fallback Page

Beautiful static page deployed when:
- Free tier limits reached
- Service needs maintenance
- Migration in progress

**Purpose**: User-friendly message instead of 502 errors.

### Deployment Scripts

Located in `scripts/railway/`:

- **`deploy.sh`**: One-command Railway deployment
- **`check-usage.sh`**: Monitor Railway usage and costs
- **`deploy-maintenance.sh`**: Switch to maintenance mode

## Cost Protection System

### Built-in Guardrails

1. **Resource Limits**: Minimal CPU/memory allocation
2. **Single Replica**: Prevents horizontal scaling costs
3. **Usage Monitoring**: Automated checking scripts
4. **Auto-Shutdown**: Maintenance mode when limits hit

### Monitoring Usage

```bash
# Check current usage
./scripts/railway/check-usage.sh

# Set up daily monitoring
crontab -e
# Add: 0 9 * * * cd /path/to/Synthia-3.0 && ./scripts/railway/check-usage.sh
```

### When Free Tier is Exceeded

```bash
# 1. Deploy maintenance page
./scripts/railway/deploy-maintenance.sh

# 2. Consider migration
less COOLIFY_MIGRATION.md

# 3. Or upgrade Railway plan
railway upgrade
```

## Deployment Workflows

### Railway → Production (Free Tier)

```bash
# 1. Initialize
./scripts/setup-zero-secrets.sh

# 2. Deploy
./scripts/railway/deploy.sh

# 3. Verify
curl https://your-app.railway.app/healthz

# 4. Monitor
./scripts/railway/check-usage.sh
```

**Cost**: $0/month (within free tier limits)

### Railway → Coolify (Cost Optimization)

When Railway limits are reached:

```bash
# 1. Follow migration checklist
less COOLIFY_MIGRATION.md

# 2. Set up Coolify on VPS
# See COOLIFY_SUPPORT.md

# 3. Export Railway database
railway run pg_dump > backup.sql

# 4. Deploy to Coolify
# Via Coolify dashboard

# 5. Import database
# Via Coolify console

# 6. Update DNS
# Point to new IP

# 7. Decommission Railway
railway down
```

**Cost**: ~$5-7/month (VPS + more resources)

### Local Development

```bash
# 1. Initialize
./scripts/setup-zero-secrets.sh

# 2. Choose option 4 (Local Docker)

# 3. Verify
curl http://localhost:8080/healthz

# 4. Develop
docker compose logs -f backend
```

**Cost**: $0 (uses local hardware)

## Secret Management Best Practices

### ✅ DO

- Store secrets in `master.secrets.json` locally
- Use environment variables in deployment platforms
- Reference `.agents` file for required variables
- Keep `master.secrets.json` in `.gitignore`
- Use strong, unique passwords for each environment
- Rotate secrets regularly (every 90 days)

### ❌ DON'T

- Commit secrets to Git
- Share `master.secrets.json` via Slack/email
- Use production secrets in development
- Reuse passwords across environments
- Store secrets in plaintext files in the repo
- Include API keys in code comments

## Adding New Secrets

### Step 1: Update `.agents`

```json
{
  "optional_integrations": [
    {
      "name": "NEW_API_KEY",
      "description": "New service API key",
      "type": "secret",
      "required": false,
      "category": "optional-integration",
      "security_level": "high",
      "stub_value": "",
      "disable_integration": "Remove new service integration"
    }
  ]
}
```

### Step 2: Add to `master.secrets.json`

```json
{
  "projects": {
    "synthia-3.0": {
      "optional_secrets": {
        "NEW_API_KEY": "<<YOUR_API_KEY>>"
      }
    }
  }
}
```

### Step 3: Deploy

```bash
# Railway
railway variables set NEW_API_KEY=your-key
railway up

# Coolify
# Add in dashboard → Environment Variables

# Local
echo "NEW_API_KEY=your-key" >> .env
docker compose restart
```

## Multi-Environment Setup

### Development (Local)

```bash
# .env
NODE_ENV=development
PORT=8080
DATABASE_URL=postgres://postgres:postgres@localhost:5432/synthia
MODEL_PROVIDER=ollama
```

### Staging (Railway)

```bash
# Railway variables
NODE_ENV=production
PORT=8080
DATABASE_URL=<railway-postgres-url>
MODEL_PROVIDER=openrouter
OPENROUTER_API_KEY=<staging-key>
```

### Production (Coolify)

```bash
# Coolify environment
NODE_ENV=production
PORT=8080
DATABASE_URL=<production-db-url>
MODEL_PROVIDER=openrouter
OPENROUTER_API_KEY=<production-key>
OTLP_ENDPOINT=<observability-endpoint>
```

## Troubleshooting

### "Railway project not linked"

```bash
railway link
# Or create new:
railway init --name synthia-3.0
```

### "DATABASE_URL not set"

```bash
# Add PostgreSQL plugin
railway add --plugin postgres

# Or set manually
railway variables set DATABASE_URL=postgres://...
```

### "Health check fails"

```bash
# Check logs
railway logs --follow

# Verify environment
railway variables

# Test locally first
docker compose up
curl http://localhost:8080/healthz
```

### "Out of memory"

```bash
# Check usage
./scripts/railway/check-usage.sh

# Options:
# 1. Optimize code
# 2. Deploy maintenance mode
# 3. Migrate to Coolify (more RAM)
# 4. Upgrade Railway plan
```

## Migration Paths

### Railway Free → Railway Paid

```bash
railway upgrade
# Select plan
# Update railway.toml if needed
```

**When**: You want to stay on Railway but need more resources.

### Railway → Coolify

See [COOLIFY_MIGRATION.md](./COOLIFY_MIGRATION.md)

**When**: Cost optimization needed, want full control.

### Railway → Google Cloud Run

See [DEPLOYMENT.md](./DEPLOYMENT.md) - Cloud Run section

**When**: Enterprise requirements, global scale needed.

### Local → Any Platform

Follow deployment guide for target platform in [DEPLOYMENT.md](./DEPLOYMENT.md)

**When**: Ready to move from development to production.

## Advanced Features

### Hostinger VPN Integration

For private networking with Coolify:

```bash
# Install WireGuard on VPS
apt-get install wireguard-tools

# Configure tunnel
# See COOLIFY_SUPPORT.md for full setup
```

**Use Case**: Secure communication between services, private database access.

### Custom Domain

**Railway:**
```bash
railway domain add your-domain.com
# Update DNS records as shown
```

**Coolify:**
```
Add domain in Coolify dashboard
Enable automatic SSL
```

### Automated Backups

**Railway:**
```bash
# Database backups
railway run pg_dump > backup-$(date +%Y%m%d).sql

# Automated (cron):
0 2 * * * cd /path/to/project && railway run pg_dump > backup-$(date +\%Y\%m\%d).sql
```

**Coolify:**
```
Enable in Settings → Backups
Frequency: Daily
Retention: 7 days
```

## Support & Resources

- **Full Guide**: [DEPLOYMENT.md](./DEPLOYMENT.md)
- **Coolify Setup**: [COOLIFY_SUPPORT.md](./COOLIFY_SUPPORT.md)
- **Migration**: [COOLIFY_MIGRATION.md](./COOLIFY_MIGRATION.md)
- **Issues**: https://github.com/executiveusa/Synthia-3.0/issues
- **Email**: feedback@lemonai.ai

## Success Metrics

Zero-Secrets deployment is successful when:

- [x] First deploy completes without errors
- [x] Health check returns 200 OK
- [x] No secrets committed to Git
- [x] Cost stays within limits
- [x] Maintenance mode works if needed
- [x] Can migrate between platforms seamlessly

---

**Version**: 1.0  
**Last Updated**: Auto-generated during setup  
**Status**: Production Ready  
