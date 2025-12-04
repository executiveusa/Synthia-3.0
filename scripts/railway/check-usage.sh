#!/bin/bash
# Railway Usage Monitoring Script
# Checks Railway usage and alerts if approaching free tier limits

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Railway Usage Monitor${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo -e "${RED}Error: Railway CLI not found${NC}"
    exit 1
fi

# Check if logged in
if ! railway whoami &> /dev/null; then
    echo -e "${RED}Error: Not logged in to Railway${NC}"
    exit 1
fi

# Get current user info
user_info=$(railway whoami)
echo -e "Account: ${GREEN}$user_info${NC}"
echo ""

# Get project info
if ! railway status &> /dev/null; then
    echo -e "${RED}Error: No Railway project linked${NC}"
    echo "Run: railway link"
    exit 1
fi

project_info=$(railway status 2>/dev/null || echo "Project information unavailable")
echo "Project Status:"
echo "$project_info"
echo ""

# Try to get usage information
echo "Fetching usage data..."
usage_data=$(railway usage 2>/dev/null || echo "")

if [ -z "$usage_data" ]; then
    echo -e "${YELLOW}⚠ Usage data unavailable${NC}"
    echo "Railway CLI may not support usage command or project may be on free tier"
else
    echo "$usage_data"
fi
echo ""

# Free tier limits (approximate)
FREE_TIER_GB=1
FREE_TIER_HOURS=500
ALERT_THRESHOLD=80  # Alert at 80% usage

echo -e "${BLUE}Free Tier Limits (Approximate):${NC}"
echo "  - Execution Time: $FREE_TIER_HOURS hours/month"
echo "  - Memory: $FREE_TIER_GB GB"
echo "  - Bandwidth: 100 GB/month"
echo ""

# Check if we can get metrics
if command -v railway metrics &> /dev/null; then
    echo "Current Metrics:"
    railway metrics || echo "Metrics unavailable"
    echo ""
fi

# Cost protection recommendations
echo -e "${BLUE}Cost Protection Recommendations:${NC}"
echo ""

# Check current environment
current_env=$(railway variables 2>/dev/null | grep NODE_ENV || echo "NODE_ENV=unknown")
echo "Current environment: $current_env"

if echo "$current_env" | grep -q "development"; then
    echo -e "${YELLOW}⚠ Warning: Running in development mode${NC}"
    echo "  Recommendation: Set NODE_ENV=production"
fi
echo ""

# Check resource configuration
echo "Checking resource configuration..."
if [ -f "railway.toml" ]; then
    echo -e "${GREEN}✓${NC} railway.toml found"
    
    if grep -q "numReplicas = 1" railway.toml; then
        echo -e "${GREEN}✓${NC} Single replica configured (cost-efficient)"
    else
        echo -e "${YELLOW}⚠${NC} Multiple replicas may increase costs"
    fi
else
    echo -e "${YELLOW}⚠${NC} railway.toml not found - using Railway defaults"
fi
echo ""

# Check for expensive services
echo "Checking for resource-intensive configurations..."

expensive_services=false

# Check for Ollama (memory intensive)
if railway variables 2>/dev/null | grep -q "OLLAMA"; then
    echo -e "${YELLOW}⚠${NC} Ollama detected - requires significant memory"
    echo "  Consider using cloud AI providers on Railway"
    expensive_services=true
fi

# Check for large databases
if railway variables 2>/dev/null | grep -q "DATABASE_URL"; then
    echo -e "${GREEN}✓${NC} Database configured"
    echo "  Monitor database size and query performance"
fi

if [ "$expensive_services" = true ]; then
    echo ""
    echo -e "${YELLOW}Recommendation: Consider Coolify for resource-intensive workloads${NC}"
    echo "See: COOLIFY_MIGRATION.md"
fi

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Monitoring Actions${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo "To monitor usage continuously:"
echo "  1. Set up Railway webhooks for usage alerts"
echo "  2. Run this script periodically (e.g., daily cron)"
echo "  3. Monitor Railway dashboard: https://railway.app/dashboard"
echo ""
echo "If free tier is exceeded:"
echo "  1. Deploy maintenance mode: ./scripts/railway/deploy-maintenance.sh"
echo "  2. Migrate to Coolify: See COOLIFY_MIGRATION.md"
echo "  3. Upgrade Railway plan: railway upgrade"
echo ""

# Save report
report_file="railway-usage-$(date +%Y%m%d-%H%M%S).log"
{
    echo "Railway Usage Report"
    echo "Generated: $(date)"
    echo ""
    echo "User: $user_info"
    echo ""
    echo "Project Status:"
    echo "$project_info"
    echo ""
    echo "Usage Data:"
    echo "$usage_data"
} > "$report_file"

echo "Report saved: $report_file"
echo ""
