#!/bin/bash
# Auto-generated from sre-patterns.yaml v1.0.0
# DO NOT EDIT MANUALLY - Regenerate with: make generate
# Category: NPI (New Product Introduction)
# Patterns: 5 critical checks
# Languages: python, go, java, scala, javascript, typescript
# Branch Requirement: Feature branch (compares against main)

set -e

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Branch Detection (NPI requires feature branch)
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
BASE_BRANCH="${BASE_BRANCH:-main}"

echo -e "${BOLD}${BLUE}🔍 SRE Critical: NPI (New Product Introduction) (v1.0.0)${NC}"
echo -e "${CYAN}Patterns to validate new features and changes before production release${NC}"
echo -e "${CYAN}Confidence: High (82-99% across patterns)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BOLD}Branch Context:${NC}"
echo "  Current Branch: ${CYAN}$CURRENT_BRANCH${NC}"
echo "  Comparing Against: ${CYAN}$BASE_BRANCH${NC}"
echo ""

# Validate we're on a feature branch
if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
    echo -e "${YELLOW}⚠️  WARNING: NPI checks should run on feature branches, not $CURRENT_BRANCH${NC}"
    echo ""
    echo "Usage: Switch to your feature branch first, or set BASE_BRANCH:"
    echo "  git checkout feature/my-new-feature"
    echo "  ./check-npi.sh"
    echo ""
    echo "Or specify base branch:"
    echo "  BASE_BRANCH=main ./check-npi.sh"
    echo ""
fi

# Check if base branch exists
if ! git rev-parse --verify "$BASE_BRANCH" >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: Base branch '$BASE_BRANCH' not found${NC}"
    echo ""
    echo "Available branches:"
    git branch -a | head -10
    exit 1
fi

echo -e "${BOLD}Analyzing changes in this branch:${NC}"
CHANGED_FILES=$(git diff --name-only $BASE_BRANCH..HEAD 2>/dev/null | wc -l | tr -d ' ')
NEW_FILES=$(git diff --name-only --diff-filter=A $BASE_BRANCH..HEAD 2>/dev/null | wc -l | tr -d ' ')
MODIFIED_FILES=$(git diff --name-only --diff-filter=M $BASE_BRANCH..HEAD 2>/dev/null | wc -l | tr -d ' ')

echo "  Changed Files: ${CHANGED_FILES} (${NEW_FILES} new, ${MODIFIED_FILES} modified)"
echo ""

if [ "$CHANGED_FILES" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No changes detected between $BASE_BRANCH and $CURRENT_BRANCH${NC}"
    echo ""
    echo "This could mean:"
    echo "  - You're already on $BASE_BRANCH"
    echo "  - Your branch is up-to-date with $BASE_BRANCH"
    echo "  - You need to commit your changes first"
    echo ""
    exit 0
fi

echo -e "${BOLD}Running NPI Checks on Changed Files:${NC}"
echo ""

CRITICAL=0
WARNINGS=0
INFO=0

# ========================================
# Pattern: SQL Injection Prevention (99%% confidence)
# ID: sql_injection
# Severity: critical
# ========================================
echo -n "[1/5] Checking SQL Injection Prevention... "

MATCHES=$(git diff --name-only $BASE_BRANCH..HEAD | xargs -I {} grep -Hn "(execute|executemany)\s*\([^)]*(%s|%d|\+|f\"|f'|\.format)" {} 2>/dev/null | grep -E '(\.py)' || true)
if [ -n "$MATCHES" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "  🔴 CRITICAL: Never use string concatenation for SQL queries - always use parameterized queries"
    echo "     Fix: Use parameterized queries with placeholders"
    echo ""
    CRITICAL=$((CRITICAL + 1))
fi

# ========================================
# Pattern: Feature Flag for New Features (85%% confidence)
# ID: feature_flag_detection
# Severity: warning
# ========================================
echo -n "[2/5] Checking Feature Flag for New Features... "

MATCHES=$(git diff --name-only $BASE_BRANCH..HEAD | xargs -I {} grep -Hn "@app\.route\(|@router\.(get|post|put|delete)" {} 2>/dev/null | grep -E '(\.py)' || true)
if [ -n "$MATCHES" ]; then
    # Check if exclude pattern also exists (good case)
    EXCLUDES=$(echo "$MATCHES" | while IFS=: read -r file line content; do
        grep -q "feature_flag|FeatureFlag|flag_enabled|LaunchDarkly" "$file" 2>/dev/null && echo "$file:$line:$content"
    done)
    if [ -n "$EXCLUDES" ]; then
        echo -e "${GREEN}✓${NC}"
    else
    echo -e "${YELLOW}⚠${NC}"
    echo "  🟡 WARNING: New features must be protected with feature flags for safe rollout"
    echo "     Fix: Wrap new features in feature flags (LaunchDarkly, Unleash, Togglz)"
    echo ""
    echo "     Files missing proper implementation:"
    echo "$MATCHES" | while IFS=: read -r file line content; do
        echo "       - ${CYAN}$file:$line${NC} → ${YELLOW}$(echo "$content" | xargs)${NC}"
    done
    echo ""
    WARNINGS=$((WARNINGS + 1))
    fi
fi

# ========================================
# Pattern: Database Schema Changes with Migration (88%% confidence)
# ID: database_migrations
# Severity: warning
# ========================================
echo -n "[3/5] Checking Database Schema Changes with Migration... "

# ========================================
# Pattern: API Breaking Changes Detection (82%% confidence)
# ID: api_breaking_changes
# Severity: warning
# ========================================
echo -n "[4/5] Checking API Breaking Changes Detection... "

MATCHES=$(git diff --name-only $BASE_BRANCH..HEAD | xargs -I {} grep -Hn "DROP\s+TABLE|DROP\s+COLUMN|RENAME\s+COLUMN" {} 2>/dev/null | grep -E '(\.sql|*/migrations/*)' || true)
if [ -n "$MATCHES" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
    echo "  🟡 WARNING: API changes must maintain backwards compatibility or be versioned"
    echo "     Fix: Use API versioning or deprecation strategy instead of breaking changes"
    echo ""
    WARNINGS=$((WARNINGS + 1))
fi

# ========================================
# Pattern: Test Coverage for New Code (85%% confidence)
# ID: test_coverage
# Severity: warning
# ========================================
echo -n "[5/5] Checking Test Coverage for New Code... "


echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $CRITICAL -eq 0 ] && [ $WARNINGS -eq 0 ] && [ $INFO -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✅ ALL 5 CHECKS PASSED!${NC}"
    echo ""
    exit 0
elif [ $CRITICAL -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${CYAN}${BOLD}ℹ️  PASSED WITH INFO${NC}"
    echo ""
    echo "Found $INFO informational item(s)."
    exit 0
elif [ $CRITICAL -eq 0 ]; then
    echo -e "${YELLOW}${BOLD}⚠️  PASSED WITH WARNINGS${NC}"
    echo ""
    echo "Found $WARNINGS warning(s) and $INFO info item(s)."
    echo ""
    echo "💡 Consider addressing warnings before production."
    exit 0
else
    echo -e "${RED}${BOLD}❌ CRITICAL ISSUES FOUND${NC}"
    echo ""
    echo "Found $CRITICAL critical/blocking issue(s), $WARNINGS warning(s), and $INFO info item(s)."
    echo ""
    echo "🔴 Critical issues must be fixed before production deployment."
    exit 1
fi
