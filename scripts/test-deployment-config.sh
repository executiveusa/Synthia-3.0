#!/bin/bash
# Test script to validate deployment configuration files

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Testing Deployment Configuration Files${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Track test results
tests_passed=0
tests_failed=0

# Helper function to run tests
test_file() {
    local file=$1
    local description=$2
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $description exists"
        ((tests_passed++))
        return 0
    else
        echo -e "${RED}✗${NC} $description missing: $file"
        ((tests_failed++))
        return 1
    fi
}

test_executable() {
    local file=$1
    local description=$2
    
    if [ -x "$file" ]; then
        echo -e "${GREEN}✓${NC} $description is executable"
        ((tests_passed++))
        return 0
    else
        echo -e "${RED}✗${NC} $description not executable: $file"
        ((tests_failed++))
        return 1
    fi
}

test_json() {
    local file=$1
    local description=$2
    
    if python3 -m json.tool "$file" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $description is valid JSON"
        ((tests_passed++))
        return 0
    else
        echo -e "${RED}✗${NC} $description has invalid JSON: $file"
        ((tests_failed++))
        return 1
    fi
}

# Test 1: Core configuration files exist
echo "Test Suite 1: Core Configuration Files"
echo "────────────────────────────────────────"
test_file ".agents" ".agents file"
test_file "master.secrets.json.template" "master.secrets.json.template"
test_file "railway.toml" "railway.toml"
test_file "maintenance.html" "maintenance.html"
test_file "coolify-docker-compose.yml" "coolify-docker-compose.yml"
echo ""

# Test 2: Documentation files exist
echo "Test Suite 2: Documentation Files"
echo "────────────────────────────────────────"
test_file "DEPLOYMENT.md" "DEPLOYMENT.md"
test_file "RAILWAY_ZERO_SECRETS.md" "RAILWAY_ZERO_SECRETS.md"
test_file "COOLIFY_SUPPORT.md" "COOLIFY_SUPPORT.md"
test_file "COOLIFY_MIGRATION.md" "COOLIFY_MIGRATION.md"
echo ""

# Test 3: Scripts exist and are executable
echo "Test Suite 3: Deployment Scripts"
echo "────────────────────────────────────────"
test_file "scripts/setup-zero-secrets.sh" "setup-zero-secrets.sh"
test_executable "scripts/setup-zero-secrets.sh" "setup-zero-secrets.sh"

test_file "scripts/railway/deploy.sh" "railway/deploy.sh"
test_executable "scripts/railway/deploy.sh" "railway/deploy.sh"

test_file "scripts/railway/check-usage.sh" "railway/check-usage.sh"
test_executable "scripts/railway/check-usage.sh" "railway/check-usage.sh"

test_file "scripts/railway/deploy-maintenance.sh" "railway/deploy-maintenance.sh"
test_executable "scripts/railway/deploy-maintenance.sh" "railway/deploy-maintenance.sh"
echo ""

# Test 4: JSON validation
echo "Test Suite 4: JSON Validation"
echo "────────────────────────────────────────"
test_json ".agents" ".agents"
test_json "master.secrets.json.template" "master.secrets.json.template"
echo ""

# Test 5: .agents file structure
echo "Test Suite 5: .agents File Structure"
echo "────────────────────────────────────────"

if python3 -c "
import json, sys
with open('.agents') as f:
    data = json.load(f)
    
required_keys = ['project', 'core', 'required_secrets', 'optional_secrets', 'schema']
missing = [k for k in required_keys if k not in data]

if missing:
    print(f'Missing keys: {missing}')
    sys.exit(1)

print(f'✓ Project: {data[\"project\"]}')
print(f'✓ Core variables: {len(data[\"core\"])}')
print(f'✓ Required secrets: {len(data[\"required_secrets\"])}')
print(f'✓ Optional secrets: {len(data[\"optional_secrets\"])}')
print(f'✓ Schema present: {\"schema\" in data}')
" 2>&1; then
    echo -e "${GREEN}✓${NC} .agents structure is valid"
    ((tests_passed+=5))
else
    echo -e "${RED}✗${NC} .agents structure is invalid"
    ((tests_failed+=5))
fi
echo ""

# Test 6: Railway.toml sections
echo "Test Suite 6: railway.toml Structure"
echo "────────────────────────────────────────"

required_sections=("[build]" "[deploy]" "[deploy.env]")
for section in "${required_sections[@]}"; do
    if grep -q "^$section" railway.toml; then
        echo -e "${GREEN}✓${NC} railway.toml has $section"
        ((tests_passed++))
    else
        echo -e "${RED}✗${NC} railway.toml missing $section"
        ((tests_failed++))
    fi
done
echo ""

# Test 7: Maintenance HTML structure
echo "Test Suite 7: maintenance.html Structure"
echo "────────────────────────────────────────"

html_elements=("<title>" "<h1>" "<body>" "</html>")
for element in "${html_elements[@]}"; do
    if grep -q "$element" maintenance.html; then
        echo -e "${GREEN}✓${NC} maintenance.html has $element"
        ((tests_passed++))
    else
        echo -e "${RED}✗${NC} maintenance.html missing $element"
        ((tests_failed++))
    fi
done
echo ""

# Test 8: .gitignore entries
echo "Test Suite 8: .gitignore Security"
echo "────────────────────────────────────────"

if grep -q "master.secrets.json" .gitignore; then
    echo -e "${GREEN}✓${NC} master.secrets.json is in .gitignore"
    ((tests_passed++))
else
    echo -e "${RED}✗${NC} master.secrets.json NOT in .gitignore (SECURITY RISK!)"
    ((tests_failed++))
fi

if [ -f "master.secrets.json" ]; then
    echo -e "${YELLOW}⚠${NC} WARNING: master.secrets.json exists (should be template only)"
fi
echo ""

# Test 9: Documentation content checks
echo "Test Suite 9: Documentation Quality"
echo "────────────────────────────────────────"

docs=("DEPLOYMENT.md" "RAILWAY_ZERO_SECRETS.md" "COOLIFY_SUPPORT.md" "COOLIFY_MIGRATION.md")
for doc in "${docs[@]}"; do
    word_count=$(wc -w < "$doc")
    if [ "$word_count" -gt 100 ]; then
        echo -e "${GREEN}✓${NC} $doc has substantial content ($word_count words)"
        ((tests_passed++))
    else
        echo -e "${RED}✗${NC} $doc is too short ($word_count words)"
        ((tests_failed++))
    fi
done
echo ""

# Test 10: Script syntax validation
echo "Test Suite 10: Script Syntax"
echo "────────────────────────────────────────"

scripts=(
    "scripts/setup-zero-secrets.sh"
    "scripts/railway/deploy.sh"
    "scripts/railway/check-usage.sh"
    "scripts/railway/deploy-maintenance.sh"
)

for script in "${scripts[@]}"; do
    if bash -n "$script" 2>&1; then
        echo -e "${GREEN}✓${NC} $(basename $script) has valid bash syntax"
        ((tests_passed++))
    else
        echo -e "${RED}✗${NC} $(basename $script) has syntax errors"
        ((tests_failed++))
    fi
done
echo ""

# Final summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}Test Summary${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Tests Passed: ${GREEN}$tests_passed${NC}"
echo -e "Tests Failed: ${RED}$tests_failed${NC}"
echo ""

if [ $tests_failed -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    echo "Deployment configuration is ready."
    echo ""
    echo "Next steps:"
    echo "  1. Run: ./scripts/setup-zero-secrets.sh"
    echo "  2. Deploy: ./scripts/railway/deploy.sh"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    echo ""
    echo "Please fix the issues above before deploying."
    exit 1
fi
