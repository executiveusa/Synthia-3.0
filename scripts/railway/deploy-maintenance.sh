#!/bin/bash
# Railway Maintenance Mode Deployment
# Deploys static maintenance page when free tier is exceeded

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Railway Maintenance Mode Deployer${NC}"
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
    railway login
fi

echo -e "${GREEN}✓${NC} Railway CLI ready"

# Check if maintenance.html exists
if [ ! -f "maintenance.html" ]; then
    echo -e "${RED}Error: maintenance.html not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Maintenance page found"

# Create temporary deployment directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "Creating maintenance deployment package..."

# Copy maintenance page
cp maintenance.html "$TEMP_DIR/index.html"

# Create minimal package.json for static serving
cat > "$TEMP_DIR/package.json" << 'EOF'
{
  "name": "synthia-maintenance",
  "version": "1.0.0",
  "scripts": {
    "start": "npx serve -s . -l 8080"
  },
  "dependencies": {
    "serve": "^14.2.0"
  }
}
EOF

# Create Procfile
echo "web: npm start" > "$TEMP_DIR/Procfile"

echo -e "${GREEN}✓${NC} Maintenance package created"

# Backup current deployment
echo ""
echo "This will replace your current deployment with maintenance mode."
echo -e "${YELLOW}⚠ WARNING: Your application will be unavailable${NC}"
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cancelled"
    exit 0
fi

# Deploy maintenance mode
echo ""
echo "Deploying maintenance mode..."

cd "$TEMP_DIR"
railway up --detach

echo ""
echo -e "${GREEN}✓ Maintenance mode deployed${NC}"
echo ""
echo "The maintenance page is now live at your Railway URL."
echo ""
echo "To restore the application:"
echo "  1. Fix the issues causing maintenance mode"
echo "  2. Run: railway up (from main project directory)"
echo "  3. Or migrate to Coolify: see COOLIFY_MIGRATION.md"
echo ""

# Log the event
echo "$(date): Maintenance mode deployed" >> railway-maintenance.log

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Maintenance Mode Active${NC}"
echo -e "${BLUE}================================================${NC}"
