#!/bin/bash
# Zero-Secrets Deployment Setup Script
# Initializes local environment for secure deployment

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
cat << "EOF"
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║     Synthia 3.0 - Railway Zero-Secrets Bootstrapper           ║
║                                                                ║
║     Universal Meta-Prompt for Repo-Agnostic                   ║
║     Zero-Secrets Deployment                                   ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
EOF

echo ""
echo -e "${BLUE}This script will help you set up Synthia 3.0 for deployment${NC}"
echo -e "${BLUE}with the Zero-Secrets architecture.${NC}"
echo ""
echo "Press Enter to continue..."
read

# Check prerequisites
echo ""
echo -e "${CYAN}Step 1: Checking Prerequisites${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check for required files
if [ ! -f ".agents" ]; then
    echo -e "${RED}✗${NC} .agents file not found"
    exit 1
fi
echo -e "${GREEN}✓${NC} .agents file found"

if [ ! -f "railway.toml" ]; then
    echo -e "${RED}✗${NC} railway.toml not found"
    exit 1
fi
echo -e "${GREEN}✓${NC} railway.toml found"

if [ ! -f "maintenance.html" ]; then
    echo -e "${RED}✗${NC} maintenance.html not found"
    exit 1
fi
echo -e "${GREEN}✓${NC} maintenance.html found"

if [ ! -f "DEPLOYMENT.md" ]; then
    echo -e "${RED}✗${NC} DEPLOYMENT.md not found"
    exit 1
fi
echo -e "${GREEN}✓${NC} DEPLOYMENT.md found"

# Check for Node.js
if command -v node &> /dev/null; then
    node_version=$(node --version)
    echo -e "${GREEN}✓${NC} Node.js installed: $node_version"
else
    echo -e "${YELLOW}⚠${NC} Node.js not found (optional for local development)"
fi

# Check for Docker
if command -v docker &> /dev/null; then
    docker_version=$(docker --version)
    echo -e "${GREEN}✓${NC} Docker installed: $docker_version"
else
    echo -e "${YELLOW}⚠${NC} Docker not found (required for local deployment)"
fi

# Initialize master secrets file
echo ""
echo -e "${CYAN}Step 2: Initialize Master Secrets${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "master.secrets.json" ]; then
    echo -e "${YELLOW}⚠${NC} master.secrets.json already exists"
    read -p "Overwrite? (y/n): " overwrite
    if [ "$overwrite" != "y" ]; then
        echo "Keeping existing master.secrets.json"
    else
        cp master.secrets.json.template master.secrets.json
        echo -e "${GREEN}✓${NC} master.secrets.json created from template"
    fi
else
    cp master.secrets.json.template master.secrets.json
    echo -e "${GREEN}✓${NC} master.secrets.json created from template"
fi

# Create local .env if doesn't exist
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "${GREEN}✓${NC} .env created from .env.example"
    else
        cat > .env << 'ENVEOF'
STORAGE_PATH=data/database.sqlite
WORKSPACE_DIR=workspace
RUNTIME_TYPE=local-docker
ENABLE_KNOWLEDGE=ON
NODE_ENV=development
PORT=8080
MODEL_PROVIDER=ollama
OLLAMA_MODEL=llama3
ENVEOF
        echo -e "${GREEN}✓${NC} .env created with defaults"
    fi
else
    echo -e "${GREEN}✓${NC} .env already exists"
fi

# Review architecture
echo ""
echo -e "${CYAN}Step 3: Zero-Secrets Architecture Overview${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "The Zero-Secrets architecture includes:"
echo ""
echo -e "${GREEN}✓${NC} ${BLUE}.agents${NC} - Machine-readable secret inventory"
echo -e "${GREEN}✓${NC} ${BLUE}master.secrets.json${NC} - Local secret storage (never committed)"
echo -e "${GREEN}✓${NC} ${BLUE}railway.toml${NC} - Railway deployment config with cost guards"
echo -e "${GREEN}✓${NC} ${BLUE}maintenance.html${NC} - Fallback page for exceeded limits"
echo -e "${GREEN}✓${NC} ${BLUE}COOLIFY_SUPPORT.md${NC} - Alternative deployment platform"
echo -e "${GREEN}✓${NC} ${BLUE}COOLIFY_MIGRATION.md${NC} - Migration checklist"
echo -e "${GREEN}✓${NC} ${BLUE}DEPLOYMENT.md${NC} - Complete deployment guide"
echo ""

# Choose deployment target
echo ""
echo -e "${CYAN}Step 4: Choose Deployment Target${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1) Railway (Quick start, auto-provisioning, free tier)"
echo "2) Coolify (Self-hosted, cost-effective, full control)"
echo "3) Google Cloud Run (Enterprise, global scale)"
echo "4) Local Docker (Development, testing)"
echo "5) Skip deployment setup"
echo ""
read -p "Select option (1-5): " deploy_choice

case $deploy_choice in
    1)
        echo ""
        echo -e "${BLUE}Railway Deployment Selected${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Install Railway CLI: npm install -g @railway/cli"
        echo "2. Run deployment: ./scripts/railway/deploy.sh"
        echo "3. Monitor usage: ./scripts/railway/check-usage.sh"
        echo ""
        read -p "Open DEPLOYMENT.md for detailed instructions? (y/n): " open_doc
        if [ "$open_doc" = "y" ]; then
            if command -v less &> /dev/null; then
                less DEPLOYMENT.md
            else
                cat DEPLOYMENT.md
            fi
        fi
        ;;
    2)
        echo ""
        echo -e "${BLUE}Coolify Deployment Selected${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Provision VPS (Hostinger, DigitalOcean, etc.)"
        echo "2. Install Coolify: curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash"
        echo "3. Follow guide: COOLIFY_SUPPORT.md"
        echo ""
        read -p "Open COOLIFY_SUPPORT.md? (y/n): " open_coolify
        if [ "$open_coolify" = "y" ]; then
            if command -v less &> /dev/null; then
                less COOLIFY_SUPPORT.md
            else
                cat COOLIFY_SUPPORT.md
            fi
        fi
        ;;
    3)
        echo ""
        echo -e "${BLUE}Google Cloud Run Selected${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Set up Google Cloud project"
        echo "2. Authenticate: gcloud auth login"
        echo "3. Follow guide: DEPLOYMENT.md (Cloud Run section)"
        echo ""
        ;;
    4)
        echo ""
        echo -e "${BLUE}Local Docker Deployment${NC}"
        echo ""
        echo "Starting local environment..."
        if command -v docker &> /dev/null; then
            echo "Running: docker compose up -d"
            docker compose up -d
            echo ""
            echo -e "${GREEN}✓${NC} Services starting..."
            echo ""
            echo "Access application at: http://localhost:8080"
            echo "Health check: curl http://localhost:8080/healthz"
            echo ""
            echo "View logs: docker compose logs -f backend"
            echo "Stop services: docker compose down"
        else
            echo -e "${RED}✗${NC} Docker not installed"
            echo "Install Docker Desktop from: https://www.docker.com/products/docker-desktop"
        fi
        ;;
    5)
        echo ""
        echo "Skipping deployment setup"
        ;;
    *)
        echo "Invalid option"
        ;;
esac

# Display success message
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Your repository is now configured for Zero-Secrets deployment."
echo ""
echo -e "${BLUE}Important Files:${NC}"
echo "  📄 .agents - Secret inventory (committed)"
echo "  🔐 master.secrets.json - Your secrets (NOT committed)"
echo "  🚀 railway.toml - Railway config (committed)"
echo "  📖 DEPLOYMENT.md - Full deployment guide"
echo ""
echo -e "${YELLOW}Security Reminder:${NC}"
echo "  ⚠ NEVER commit master.secrets.json"
echo "  ⚠ NEVER commit .env with real secrets"
echo "  ⚠ Always use environment variables for secrets"
echo ""
echo -e "${BLUE}Cost Protection:${NC}"
echo "  💰 Resource limits configured in railway.toml"
echo "  📊 Monitor usage: ./scripts/railway/check-usage.sh"
echo "  🛑 Maintenance mode: ./scripts/railway/deploy-maintenance.sh"
echo ""
echo -e "${CYAN}Next Steps:${NC}"
echo "  1. Edit master.secrets.json with your actual secrets"
echo "  2. Choose deployment platform and follow guide"
echo "  3. Deploy and verify health check"
echo "  4. Monitor usage and costs"
echo ""
echo "For help: cat DEPLOYMENT.md | less"
echo ""
