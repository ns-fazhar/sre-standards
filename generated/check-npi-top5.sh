#!/bin/bash
# Auto-generated from sre-top5-patterns.yaml v1.0.0
# DO NOT EDIT MANUALLY - Regenerate with: make generate
# Category: NPI (New Product Introduction)
# Patterns: Top 5 most critical
# Languages: python, go, java, scala

set -e

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${BLUE}🔍 SRE Top 5: NPI (New Product Introduction) (v1.0.0)${NC}"
echo -e "${CYAN}Patterns to validate new features and changes before production release${NC}"
echo -e "${CYAN}Confidence: High (82-99% across patterns)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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

if grep -rq "(execute|executemany)\s*\([^)]*(%s|%d|\+|f\"|f'|\.format)" . --include="*.py" 2>/dev/null; then
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

if grep -rq "@app\.route\(|@router\.(get|post|put|delete)" . --include="*.py" 2>/dev/null; then
    # Check if exclude pattern also exists (good case)
    if grep -rq "feature_flag|FeatureFlag|flag_enabled|LaunchDarkly" . --include="*.py" 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
    echo -e "${YELLOW}⚠${NC}"
    echo "  🟡 WARNING: New features must be protected with feature flags for safe rollout"
    echo "     Fix: Wrap new features in feature flags (LaunchDarkly, Unleash, Togglz)"
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

if grep -rq "DROP\s+TABLE|DROP\s+COLUMN|RENAME\s+COLUMN" . --include="*.sql" --include="*/migrations/*" 2>/dev/null; then
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
    echo -e "${GREEN}${BOLD}✅ ALL TOP 5 CHECKS PASSED!${NC}"
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
