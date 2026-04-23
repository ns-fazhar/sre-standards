#!/bin/bash
# Auto-generated from sre_npi-patterns.yaml v3.0.0
# DO NOT EDIT MANUALLY - Regenerate with: make generate
# Category: NPI (New Product Introduction)
# Patterns: 5 enabled

set -e

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${BLUE}🔍 SRE NPI (New Product Introduction) Check (v3.0.0)${NC}"
echo -e "${CYAN}Patterns to validate new features and changes before production release${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CRITICAL=0
WARNINGS=0
INFO=0

# ========================================
# Pattern: SQL Injection Prevention
# ID: sql_injection_risk
# Severity: critical
# ========================================
echo -n "Checking SQL Injection Prevention... "

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
# Pattern: Test Coverage for New Code
# ID: missing_tests
# Severity: warning
# ========================================
echo -n "Checking Test Coverage for New Code... "

# ========================================
# Pattern: API Breaking Changes Detection
# ID: api_breaking_changes
# Severity: warning
# ========================================
echo -n "Checking API Breaking Changes Detection... "

if grep -rq "DELETE.*FROM|DROP\s+TABLE|DROP\s+COLUMN|RENAME\s+COLUMN" . --include="*.sql" --include="*/migrations/*" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
    echo "  🟡 WARNING: API changes must maintain backwards compatibility or be versioned"
    echo "     Fix: Use API versioning or deprecation strategy instead of breaking changes"
    echo ""
    WARNINGS=$((WARNINGS + 1))
fi

# ========================================
# Pattern: New Dependencies Review
# ID: new_dependency_unapproved
# Severity: info
# ========================================
echo -n "Checking New Dependencies Review... "

# ========================================
# Pattern: Database Schema Changes with Migration
# ID: schema_without_migration
# Severity: warning
# ========================================
echo -n "Checking Database Schema Changes with Migration... "


echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $CRITICAL -eq 0 ] && [ $WARNINGS -eq 0 ] && [ $INFO -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✅ ALL CHECKS PASSED!${NC}"
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
    echo -e "${RED}${BOLD}❌ CHECKS FAILED${NC}"
    echo ""
    echo "Found $CRITICAL critical issue(s), $WARNINGS warning(s), and $INFO info item(s)."
    echo ""
    echo "🔴 Critical issues must be fixed before production deployment."
    exit 1
fi
