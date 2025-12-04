#!/bin/bash
# Railway Zero-Secrets Deployment Script
# Automatically deploys Synthia 3.0 to Railway with cost protection

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Synthia 3.0 Railway Zero-Secrets Deployer${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo -e "${RED}Error: Railway CLI not found${NC}"
    echo "Install it with: npm install -g @railway/cli"
    echo "Or: curl -fsSL https://railway.app/install.sh | sh"
    exit 1
fi

echo -e "${GREEN}✓${NC} Railway CLI found"

# Check if logged in
if ! railway whoami &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} Not logged in to Railway"
    echo "Logging in..."
    railway login
fi

echo -e "${GREEN}✓${NC} Logged in to Railway"

# Check if project exists
if [ ! -f "railway.toml" ]; then
    echo -e "${RED}Error: railway.toml not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Configuration file found"

# Initialize or link project
if ! railway status &> /dev/null; then
    echo -e "${YELLOW}No Railway project linked${NC}"
    read -p "Create new project or link existing? (new/link): " choice
    
    if [ "$choice" = "new" ]; then
        read -p "Enter project name (default: synthia-3.0): " project_name
        project_name=${project_name:-synthia-3.0}
        railway init --name "$project_name"
        echo -e "${GREEN}✓${NC} Project created"
    else
        railway link
        echo -e "${GREEN}✓${NC} Project linked"
    fi
fi

# Check for required environment variables
echo ""
echo "Checking environment variables..."

required_vars=(
    "DATABASE_URL"
)

optional_vars=(
    "MODEL_PROVIDER"
    "OPENROUTER_API_KEY"
    "GEMINI_API_KEY"
    "NODE_ENV"
    "PORT"
)

# Get current variables
current_vars=$(railway variables 2>/dev/null || echo "")

missing_required=()
for var in "${required_vars[@]}"; do
    if ! echo "$current_vars" | grep -q "^$var="; then
        missing_required+=("$var")
    fi
done

# Report on variables
if [ ${#missing_required[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠ Missing required variables:${NC}"
    for var in "${missing_required[@]}"; do
        echo "  - $var"
    done
    
    # Check if PostgreSQL plugin is available
    echo ""
    echo -e "${BLUE}Tip: Add PostgreSQL plugin to automatically provision DATABASE_URL${NC}"
    read -p "Add PostgreSQL plugin now? (y/n): " add_postgres
    
    if [ "$add_postgres" = "y" ]; then
        railway add --plugin postgres
        echo -e "${GREEN}✓${NC} PostgreSQL plugin added"
    else
        echo -e "${YELLOW}Please set DATABASE_URL manually:${NC}"
        echo "  railway variables set DATABASE_URL=<your-database-url>"
        exit 1
    fi
else
    echo -e "${GREEN}✓${NC} All required variables present"
fi

# Set default variables if not present
echo ""
echo "Setting default variables..."

if ! echo "$current_vars" | grep -q "^MODEL_PROVIDER="; then
    railway variables set MODEL_PROVIDER=openrouter
    echo -e "${GREEN}✓${NC} MODEL_PROVIDER set to openrouter"
fi

if ! echo "$current_vars" | grep -q "^NODE_ENV="; then
    railway variables set NODE_ENV=production
    echo -e "${GREEN}✓${NC} NODE_ENV set to production"
fi

if ! echo "$current_vars" | grep -q "^PORT="; then
    railway variables set PORT=8080
    echo -e "${GREEN}✓${NC} PORT set to 8080"
fi

# Cost protection check
echo ""
echo -e "${BLUE}Cost Protection Checks${NC}"
echo "Verifying Railway free tier settings..."

# Check usage (if possible)
usage_output=$(railway usage 2>/dev/null || echo "Usage data unavailable")
echo "$usage_output"

if echo "$usage_output" | grep -q "exceeded"; then
    echo -e "${RED}⚠ WARNING: Free tier usage limit exceeded!${NC}"
    echo "Consider:"
    echo "  1. Deploying maintenance mode (./scripts/railway/deploy-maintenance.sh)"
    echo "  2. Migrating to Coolify (see COOLIFY_MIGRATION.md)"
    echo "  3. Upgrading Railway plan"
    echo ""
    read -p "Continue anyway? (y/n): " continue_deploy
    if [ "$continue_deploy" != "y" ]; then
        exit 1
    fi
fi

# Deploy
echo ""
echo -e "${BLUE}Deploying to Railway...${NC}"
railway up --detach

echo ""
echo -e "${GREEN}✓ Deployment initiated${NC}"
echo ""
echo "Monitor deployment:"
echo "  railway logs"
echo ""
echo "Check status:"
echo "  railway status"
echo ""
echo "Get URL:"
echo "  railway domain"
echo ""

# Wait for deployment
echo "Waiting for deployment to complete..."
sleep 5

# Try to get deployment status
if railway status &> /dev/null; then
    echo ""
    railway status
fi

# Try to get URL
url=$(railway domain 2>/dev/null || echo "")
if [ -n "$url" ]; then
    echo ""
    echo -e "${GREEN}Deployment URL:${NC} https://$url"
    echo ""
    echo "Health check: https://$url/healthz"
fi

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Deployment Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Verify health: curl https://$url/healthz"
echo "  2. Monitor logs: railway logs --follow"
echo "  3. Add optional secrets for enhanced features"
echo "  4. Review cost protection in railway.toml"
echo ""
