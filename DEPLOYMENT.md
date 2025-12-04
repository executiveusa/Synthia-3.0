# Synthia 3.0 - Universal Deployment Guide

## Railway Zero-Secrets Deployment System

This guide explains how to deploy Synthia 3.0 using the Railway Zero-Secrets Bootstrapper architecture, which ensures your first deployment boots successfully with minimal configuration.

## 🎯 Deployment Philosophy

The Zero-Secrets architecture follows these principles:

1. **First Deploy Always Works**: Minimal configuration, maximum compatibility
2. **Gradual Enhancement**: Start with basic features, add integrations later
3. **Cost Protection**: Built-in guardrails prevent unexpected charges
4. **Easy Migration**: Move between platforms without vendor lock-in
5. **Security First**: Secrets managed locally, never committed to git

## 📋 Deployment Options

### Option 1: Railway (Recommended for Getting Started)

**Best For:** Quick deployment, automatic infrastructure, free tier available

**Pros:**
- Zero configuration needed
- Automatic PostgreSQL provisioning
- Built-in SSL/TLS
- Free tier available

**Cons:**
- Usage limits on free tier
- Less control over infrastructure
- Can get expensive at scale

[Jump to Railway Setup](#railway-deployment)

### Option 2: Coolify (Recommended for Production)

**Best For:** Cost-conscious deployments, full control, private networking

**Pros:**
- Self-hosted, full control
- No usage limits
- Private VPN support
- ~50% cost savings vs Railway
- Unlimited deployments

**Cons:**
- Requires VPS setup
- More manual configuration
- Need to manage infrastructure

[Jump to Coolify Setup](#coolify-deployment)

### Option 3: Google Cloud Run

**Best For:** Enterprise deployments, global scale, GCP integration

**Pros:**
- Fully managed
- Global CDN
- Auto-scaling
- Pay-per-use pricing

**Cons:**
- More complex setup
- Requires GCP account
- Can be expensive

[Jump to Cloud Run Setup](#google-cloud-run-deployment)

### Option 4: Local Docker

**Best For:** Development, testing, air-gapped environments

**Pros:**
- Fully local
- Complete privacy
- No internet required (with Ollama)

**Cons:**
- Manual setup
- Not production-ready
- Requires Docker

[Jump to Local Setup](#local-docker-deployment)

---

## Railway Deployment

### Prerequisites

- GitHub account
- Railway account (free tier available)
- Git installed locally

### Step 1: Prepare Repository

1. Clone or fork the repository:
   ```bash
   git clone https://github.com/executiveusa/Synthia-3.0.git
   cd Synthia-3.0
   ```

2. Review the `.agents` file to understand required secrets:
   ```bash
   cat .agents
   ```

3. Review Railway configuration:
   ```bash
   cat railway.toml
   ```

### Step 2: Install Railway CLI

```bash
# macOS/Linux
curl -fsSL https://railway.app/install.sh | sh

# npm (cross-platform)
npm install -g @railway/cli

# Verify installation
railway --version
```

### Step 3: Deploy with Zero-Secrets Script

Use the automated deployment script:

```bash
./scripts/railway/deploy.sh
```

This script will:
- Check Railway CLI installation
- Login to Railway (if needed)
- Create or link Railway project
- Add PostgreSQL plugin automatically
- Set default environment variables
- Deploy the application
- Display deployment URL

### Step 4: Verify Deployment

```bash
# Get deployment URL
railway domain

# Check health
curl https://your-app.railway.app/healthz

# Monitor logs
railway logs --follow
```

Expected health check response:
```json
{"status":"ok","mode":"openrouter"}
```

### Step 5: Add Optional Integrations

Add API keys for enhanced features:

```bash
# OpenRouter (for better AI models)
railway variables set OPENROUTER_API_KEY=sk-or-v1-...

# Gemini (alternative AI provider)
railway variables set GEMINI_API_KEY=AIza...

# Observability
railway variables set OTLP_ENDPOINT=https://your-collector.com/v1/traces

# Redeploy to apply changes
railway up
```

### Cost Protection

The deployment includes automatic cost protection:

- **Resource Limits**: Minimal CPU/memory allocation
- **Single Replica**: Prevents scaling costs
- **Usage Monitoring**: Run `./scripts/railway/check-usage.sh`
- **Auto-Shutdown**: Maintenance mode when limits reached

Check usage regularly:
```bash
./scripts/railway/check-usage.sh
```

If free tier is exceeded:
```bash
# Deploy maintenance page
./scripts/railway/deploy-maintenance.sh

# Consider migrating to Coolify
# See COOLIFY_MIGRATION.md
```

---

## Coolify Deployment

### Prerequisites

- VPS with 2GB RAM, 2 CPU cores minimum
- Coolify installed (v4.0+)
- Domain name (optional but recommended)

### Step 1: Provision VPS

Recommended providers:
- **Hostinger VPS:** $5-7/month (VPS-1 plan)
- **DigitalOcean:** $12/month (Basic Droplet)
- **Hetzner:** €4.5/month (CX21)
- **Linode:** $12/month (Nanode)

### Step 2: Install Coolify

```bash
# SSH into your VPS
ssh root@your-vps-ip

# Install Coolify
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

# Access Coolify dashboard
# Navigate to: http://your-vps-ip:8000
```

### Step 3: Configure Application

1. **Create New Application**
   - Type: Docker Compose
   - Repository: https://github.com/executiveusa/Synthia-3.0
   - Branch: main

2. **Add PostgreSQL Service**
   - Add Resource → PostgreSQL
   - Note the connection string

3. **Set Environment Variables**
   ```
   NODE_ENV=production
   PORT=8080
   DATABASE_URL=postgres://postgres:password@postgres:5432/synthia
   MODEL_PROVIDER=openrouter
   OPENROUTER_API_KEY=your-key-here
   ```

4. **Configure Build**
   - Build context: `/`
   - Dockerfile: `Dockerfile.backend`
   - Start command: `cd backend && npm start`

5. **Deploy**
   - Click "Deploy"
   - Monitor logs for successful startup

### Step 4: Configure Domain (Optional)

1. Add domain in Coolify settings
2. Point DNS A record to VPS IP
3. Enable automatic SSL

### Step 5: Hostinger VPN (Optional)

For private networking between services:

```bash
# Install WireGuard
apt-get update && apt-get install wireguard-tools

# Follow setup in COOLIFY_SUPPORT.md
```

See [COOLIFY_SUPPORT.md](./COOLIFY_SUPPORT.md) for detailed instructions.

---

## Google Cloud Run Deployment

### Prerequisites

- Google Cloud account
- `gcloud` CLI installed
- Docker installed

### Step 1: Authenticate

```bash
gcloud auth login
gcloud config set project your-project-id
```

### Step 2: Build and Push Image

```bash
# Build Docker image
docker build -f Dockerfile.backend -t gcr.io/your-project/synthia-backend:latest .

# Push to Google Container Registry
docker push gcr.io/your-project/synthia-backend:latest
```

### Step 3: Deploy to Cloud Run

```bash
gcloud run deploy synthia-backend \
  --image gcr.io/your-project/synthia-backend:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars NODE_ENV=production,MODEL_PROVIDER=openrouter \
  --set-env-vars DATABASE_URL=postgres://... \
  --set-env-vars OPENROUTER_API_KEY=sk-or-v1-...
```

### Step 4: Verify

```bash
# Get service URL
gcloud run services describe synthia-backend --region us-central1 --format 'value(status.url)'

# Test health endpoint
curl https://synthia-backend-xxx.run.app/healthz
```

---

## Local Docker Deployment

### Prerequisites

- Docker Desktop (Mac/Windows) or Docker Engine (Linux)
- 4GB RAM minimum
- 20GB disk space

### Step 1: Clone Repository

```bash
git clone https://github.com/executiveusa/Synthia-3.0.git
cd Synthia-3.0
```

### Step 2: Configure Environment

```bash
# Copy example environment
cp .env.example .env

# Edit with your preferences
nano .env
```

Minimal `.env`:
```bash
NODE_ENV=development
PORT=8080
DATABASE_URL=postgres://postgres:postgres@postgres:5432/synthia
MODEL_PROVIDER=ollama
OLLAMA_MODEL=llama3
STORAGE_PATH=data/database.sqlite
WORKSPACE_DIR=workspace
RUNTIME_TYPE=local-docker
ENABLE_KNOWLEDGE=ON
```

### Step 3: Start Services

```bash
# Start all services
docker compose up -d

# Pull Ollama model (first time only)
docker exec -it synthia-ollama ollama pull llama3

# Check status
docker compose ps
```

### Step 4: Verify

```bash
# Check health
curl http://localhost:8080/healthz

# View logs
docker compose logs -f backend
```

---

## Secret Management

### Master Secrets File

The `master.secrets.json` file stores all your secrets locally:

```bash
# Copy template
cp master.secrets.json.template master.secrets.json

# Edit with real values
nano master.secrets.json

# NEVER commit to git!
# Already in .gitignore
```

### .agents File

The `.agents` file documents all required and optional secrets:

```bash
# View secret inventory
cat .agents | jq '.required_secrets'

# View optional integrations
cat .agents | jq '.optional_secrets'

# View integration stubs
cat .agents | jq '.integration_stubs'
```

### Adding Secrets

**Railway:**
```bash
railway variables set KEY=value
```

**Coolify:**
- Dashboard → Environment Variables → Add

**Google Cloud Run:**
```bash
gcloud run services update synthia-backend \
  --set-env-vars KEY=value
```

**Local:**
```bash
# Add to .env file
echo "KEY=value" >> .env
docker compose restart
```

---

## Monitoring and Maintenance

### Health Checks

All deployments expose `/healthz`:

```bash
curl https://your-deployment-url/healthz
```

Expected response:
```json
{
  "status": "ok",
  "mode": "openrouter"
}
```

### Cost Monitoring

For Railway:
```bash
# Check usage
./scripts/railway/check-usage.sh

# Monitor continuously (run daily)
crontab -e
# Add: 0 9 * * * cd /path/to/Synthia-3.0 && ./scripts/railway/check-usage.sh
```

### Maintenance Mode

When issues occur:

```bash
# Deploy maintenance page
./scripts/railway/deploy-maintenance.sh
```

This deploys `maintenance.html` as a static site while you fix issues.

### Logs

**Railway:**
```bash
railway logs --follow
```

**Coolify:**
```bash
coolify logs synthia-backend --follow
# Or via dashboard
```

**Google Cloud Run:**
```bash
gcloud run services logs read synthia-backend
```

**Local Docker:**
```bash
docker compose logs -f backend
```

---

## Migration Between Platforms

### Railway → Coolify

Follow the comprehensive checklist in [COOLIFY_MIGRATION.md](./COOLIFY_MIGRATION.md).

Quick steps:
1. Export Railway database
2. Set up Coolify project
3. Import database
4. Update DNS
5. Verify deployment
6. Decommission Railway

### Cost Comparison

| Platform | Monthly Cost | RAM | CPU | Storage |
|----------|--------------|-----|-----|---------|
| Railway Free | $0 | Shared | Shared | Ephemeral |
| Railway Starter | $5 | 512MB | 0.5 | Limited |
| Coolify (Hostinger) | $5-7 | 2GB | 2 cores | 40GB |
| Cloud Run | Variable | Auto | Auto | Pay-per-use |
| Local Docker | $0 | Your hardware | | |

---

## Troubleshooting

### Deployment Fails

**Check logs:**
```bash
railway logs  # or coolify logs, etc.
```

**Common issues:**
- Missing DATABASE_URL: Add PostgreSQL plugin
- Build timeout: Increase timeout in platform settings
- OOM errors: Upgrade instance size

### Database Connection Errors

**Verify connection string:**
```bash
# Should start with postgres://
railway variables | grep DATABASE_URL
```

**Test connection:**
```bash
psql $DATABASE_URL -c "SELECT 1"
```

### Health Check Fails

**Check if port is correct:**
```bash
# Should be 8080
railway variables | grep PORT
```

**Test locally:**
```bash
docker build -f Dockerfile.backend -t test .
docker run -p 8080:8080 -e DATABASE_URL=... test
curl http://localhost:8080/healthz
```

### High Memory Usage

**Optimize Node.js:**
```bash
# Add to start command
node --max-old-space-size=512 dist/index.js
```

**Use Ollama externally:**
```bash
# Don't run Ollama on Railway
# Use cloud AI providers instead
MODEL_PROVIDER=openrouter
```

---

## Best Practices

1. **Start with Railway**: Quick setup, perfect for development
2. **Monitor Usage**: Run check-usage.sh daily
3. **Migrate to Coolify**: When Railway limits are reached
4. **Use Ollama Locally**: Don't run on Railway (too resource-intensive)
5. **Separate Concerns**: Database on managed service, app on compute
6. **Automate Backups**: Daily database dumps
7. **Version Control**: Tag releases, document changes
8. **Security**: Never commit secrets, use environment variables
9. **Test Locally**: Always test with Docker Compose first
10. **Document Changes**: Update .agents file when adding integrations

---

## Support

- **Documentation**: https://github.com/executiveusa/Synthia-3.0
- **Issues**: https://github.com/executiveusa/Synthia-3.0/issues
- **Email**: feedback@lemonai.ai
- **Community**: https://discord.com/invite/gjEXg4UBR4

---

## Quick Reference

### Railway
```bash
# Deploy
./scripts/railway/deploy.sh

# Check usage
./scripts/railway/check-usage.sh

# Maintenance mode
./scripts/railway/deploy-maintenance.sh
```

### Coolify
```bash
# See COOLIFY_SUPPORT.md
```

### Local
```bash
# Start
docker compose up -d

# Stop
docker compose down

# Logs
docker compose logs -f
```

---

**Last Updated:** Auto-generated during Railway Zero-Secrets Deployment setup
**Version:** 1.0
