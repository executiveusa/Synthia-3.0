# Coolify Deployment Support for Synthia 3.0

This document provides infrastructure placeholders and deployment notes for running Synthia 3.0 on Coolify with optional Hostinger VPN integration.

## Overview

Coolify is a self-hosted alternative to platforms like Railway and Vercel. It provides:
- Docker-based deployments
- Built-in PostgreSQL provisioning
- Automatic SSL/TLS certificates
- Private networking capabilities
- Cost-effective hosting on VPS providers

## Prerequisites

- Coolify instance (v4.0+)
- VPS with at least 2GB RAM, 2 CPU cores
- Docker and Docker Compose installed
- Domain name with DNS access (optional)
- Hostinger VPN tunnel (optional, for private networking)

## Deployment Architecture

```
┌─────────────────────────────────────────────┐
│         Coolify Control Plane               │
│  (coolify.example.com)                      │
└─────────────────┬───────────────────────────┘
                  │
    ┌─────────────┴─────────────┐
    │                           │
    ▼                           ▼
┌─────────────────┐    ┌─────────────────────┐
│  Synthia App    │    │  PostgreSQL         │
│  Container      │───▶│  Database           │
│  (Port 8080)    │    │  (Port 5432)        │
└─────────────────┘    └─────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────┐
│       Ollama Service (Optional)             │
│       (Port 11434)                          │
└─────────────────────────────────────────────┘
```

## Configuration Files

### 1. Docker Compose for Coolify

Coolify uses Docker Compose or Docker images. Here's the recommended configuration:

```yaml
# coolify-docker-compose.yml
version: '3.8'

services:
  synthia-backend:
    image: synthia-backend:latest
    build:
      context: .
      dockerfile: Dockerfile.backend
    environment:
      - NODE_ENV=production
      - PORT=8080
      - DATABASE_URL=${DATABASE_URL}
      - MODEL_PROVIDER=${MODEL_PROVIDER:-openrouter}
      - OPENROUTER_API_KEY=${OPENROUTER_API_KEY}
      - OTLP_ENDPOINT=${OTLP_ENDPOINT}
    ports:
      - "8080:8080"
    depends_on:
      - postgres
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    networks:
      - synthia-network

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-synthia}
      POSTGRES_USER: ${POSTGRES_USER:-postgres}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres-data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: unless-stopped
    networks:
      - synthia-network

  ollama:
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
    volumes:
      - ollama-data:/root/.ollama
    restart: unless-stopped
    networks:
      - synthia-network

volumes:
  postgres-data:
  ollama-data:

networks:
  synthia-network:
    driver: bridge
```

### 2. Coolify Environment Variables

In Coolify dashboard, configure these environment variables:

**Required:**
- `DATABASE_URL`: `postgres://postgres:<password>@postgres:5432/synthia`
- `POSTGRES_PASSWORD`: Generate a strong password
- `NODE_ENV`: `production`
- `PORT`: `8080`

**Optional (AI Providers):**
- `MODEL_PROVIDER`: `openrouter` or `ollama` or `gemini`
- `OPENROUTER_API_KEY`: Your OpenRouter API key
- `GEMINI_API_KEY`: Your Google Gemini API key
- `ANTHROPIC_API_KEY`: Your Anthropic Claude API key

**Optional (Features):**
- `OTLP_ENDPOINT`: OpenTelemetry collector endpoint
- `OAUTH_CLIENT_ID`: OAuth client ID for authentication
- `OAUTH_CLIENT_SECRET`: OAuth client secret
- `JWT_AUDIENCE`: JWT token audience
- `JWT_ISSUER`: JWT token issuer

### 3. Build Settings

**Build Command:**
```bash
cd backend && npm install && npm run build
```

**Start Command:**
```bash
cd backend && npm start
```

**Base Directory:** `/` (root of repository)

**Port:** `8080`

## Hostinger VPN Integration

If you're using Hostinger VPS with private networking:

### Step 1: Set Up VPN Tunnel

1. Install WireGuard or OpenVPN on your Hostinger VPS:
```bash
apt-get update
apt-get install wireguard-tools
```

2. Configure WireGuard:
```bash
# Generate keys
wg genkey | tee privatekey | wg pubkey > publickey

# Create /etc/wireguard/wg0.conf
[Interface]
PrivateKey = <your-private-key>
Address = 10.0.0.1/24
ListenPort = 51820

[Peer]
PublicKey = <peer-public-key>
AllowedIPs = 10.0.0.2/32
Endpoint = <peer-endpoint>:51820
```

3. Start WireGuard:
```bash
wg-quick up wg0
systemctl enable wg-quick@wg0
```

### Step 2: Configure Coolify for Private Network

In Coolify, set these additional environment variables:

```bash
# Private network configuration
PRIVATE_NETWORK_ENABLED=true
VPN_INTERFACE=wg0
INTERNAL_DATABASE_HOST=10.0.0.2
```

### Step 3: Update Connection Strings

Modify `DATABASE_URL` to use private IP:
```
DATABASE_URL=postgres://postgres:password@10.0.0.2:5432/synthia
```

## Resource Allocation

For cost-effective deployment:

- **Minimum:** 1 CPU, 1GB RAM, 20GB SSD
- **Recommended:** 2 CPU, 2GB RAM, 40GB SSD
- **With Ollama:** 4 CPU, 8GB RAM, 80GB SSD

### Cost Comparison

| Provider | Instance Type | Monthly Cost |
|----------|---------------|--------------|
| Railway (Free) | Shared | $0 (limited) |
| Railway (Pro) | 512MB RAM | ~$5-10 |
| Coolify (Hostinger) | VPS-1 (2GB) | ~$5-7 |
| Coolify (Hostinger) | VPS-2 (4GB) | ~$10-15 |
| Coolify (DigitalOcean) | Basic (2GB) | $12 |
| Google Cloud Run | Shared | Pay-per-use |

## Deployment Steps

### Via Coolify Dashboard

1. **Create New Project**
   - Name: `Synthia-3.0`
   - Type: `Docker Compose`

2. **Connect Repository**
   - Repository: `https://github.com/executiveusa/Synthia-3.0`
   - Branch: `main`
   - Build Context: `/`

3. **Configure Build**
   - Dockerfile: `Dockerfile.backend`
   - Build Args: None required
   - Auto-deploy: Enabled

4. **Set Environment Variables**
   - Add all required secrets from `.agents` file
   - Generate strong passwords for databases

5. **Configure Domains**
   - Add custom domain (optional)
   - Enable automatic SSL

6. **Deploy**
   - Click "Deploy" button
   - Monitor logs for successful startup
   - Verify health check at `/healthz`

### Via CLI (Advanced)

```bash
# Install Coolify CLI
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

# Login
coolify login

# Create application
coolify app create \
  --name synthia-backend \
  --repository https://github.com/executiveusa/Synthia-3.0 \
  --dockerfile Dockerfile.backend

# Set environment variables
coolify env set synthia-backend DATABASE_URL="postgres://..."
coolify env set synthia-backend MODEL_PROVIDER="openrouter"

# Deploy
coolify deploy synthia-backend
```

## Monitoring and Maintenance

### Health Checks

Coolify automatically monitors:
- HTTP health endpoint: `/healthz`
- Container status
- Resource usage

### Logs

Access logs via:
```bash
coolify logs synthia-backend --follow
```

Or via Coolify dashboard: Project → Logs

### Backups

Automated PostgreSQL backups:
```bash
# Configure in Coolify dashboard
# Settings → Backups → Enable
# Frequency: Daily
# Retention: 7 days
```

## Troubleshooting

### Common Issues

**Database Connection Errors:**
```bash
# Check PostgreSQL container
docker ps | grep postgres
docker logs <postgres-container-id>

# Test connection
docker exec -it <postgres-container> psql -U postgres -d synthia
```

**Port Conflicts:**
```bash
# Check port usage
netstat -tuln | grep 8080

# Change port in Coolify environment
PORT=8081
```

**Out of Memory:**
```bash
# Check container stats
docker stats

# Increase swap space
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
```

## Migration from Railway

See `COOLIFY_MIGRATION.md` for detailed migration steps.

## Security Best Practices

1. **Use Strong Passwords**: Generate random passwords for all services
2. **Enable Firewall**: Block all ports except 80, 443, and 22
3. **Regular Updates**: Keep Coolify and containers updated
4. **Backup Strategy**: Configure automated backups
5. **Private Networking**: Use VPN for sensitive services
6. **SSL/TLS**: Enable automatic HTTPS certificates

## Support

- **Coolify Documentation**: https://coolify.io/docs
- **Hostinger Support**: https://www.hostinger.com/tutorials/vps
- **Synthia Issues**: https://github.com/executiveusa/Synthia-3.0/issues

---

**Note:** This document contains placeholder configurations. Activate these features only when instructed and after proper security review.
