#!/bin/bash
# Auto-generated from sre-top5-patterns.yaml v1.0.0
# DO NOT EDIT MANUALLY - Regenerate with: make generate
# Category: Operability
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

echo -e "${BOLD}${BLUE}🔍 SRE Top 5: Operability (v1.0.0)${NC}"
echo -e "${CYAN}Patterns to ensure services can be operated, debugged, and maintained${NC}"
echo -e "${CYAN}Confidence: High (75-99% across patterns)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CRITICAL=0
WARNINGS=0
INFO=0

# ========================================
# Pattern: No Hardcoded Secrets (99%% confidence)
# ID: no_hardcoded_secrets
# Severity: critical
# ========================================
echo -n "[1/5] Checking No Hardcoded Secrets... "

if grep -rq "(password|api_key|secret|token|aws_access_key|private_key)\s*=\s*['\"]([a-zA-Z0-9+/=]{20,})['\"]" . --include="*.py" --include="*.go" --include="*.js" --include="*.java" --include="*.scala" --include="*.yaml" --include="*.yml" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "  🔴 CRITICAL: Never hardcode secrets, passwords, or API keys in source code"
    echo "     Fix: Use environment variables or secret management systems (Vault, AWS Secrets Manager)"
    echo ""
    CRITICAL=$((CRITICAL + 1))
fi

# ========================================
# Pattern: Graceful Shutdown (85%% confidence)
# ID: graceful_shutdown
# Severity: warning
# ========================================
echo -n "[2/5] Checking Graceful Shutdown... "

if grep -rq "func main\(\)" . --include="*.go" 2>/dev/null; then
    # Check if exclude pattern also exists (good case)
    if grep -rq "signal\.Notify|syscall\.SIGTERM|syscall\.SIGINT" . --include="*.go" 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
    echo -e "${YELLOW}⚠${NC}"
    echo "  🟡 WARNING: Service must handle SIGTERM gracefully to avoid dropping in-flight requests"
    echo "     Fix: Implement signal handlers to gracefully drain connections before shutdown"
    echo ""
    WARNINGS=$((WARNINGS + 1))
    fi
fi

# ========================================
# Pattern: Environment Variables Documented (75%% confidence)
# ID: env_vars_documented
# Severity: info
# ========================================
echo -n "[3/5] Checking Environment Variables Documented... "

if grep -rq "os\.getenv\(|os\.environ\[|os\.environ\.get\(" . --include="*.py" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${CYAN}ℹ${NC}"
    echo "  ℹ️  INFO: All environment variables must be documented in .env.example or README"
    echo "     Recommendation: Create .env.example with all required environment variables and descriptions"
    echo ""
    INFO=$((INFO + 1))
fi

# ========================================
# Pattern: Dockerfile Present (88%% confidence)
# ID: dockerfile_present
# Severity: warning
# ========================================
echo -n "[4/5] Checking Dockerfile Present... "

if [ -f "Dockerfile" ]; then
    echo -e "${YELLOW}⚠${NC}"
    echo "  🟡 WARNING: Service must have Dockerfile for containerization and Kubernetes deployment"
    echo ""
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓${NC}"
fi

# ========================================
# Pattern: Configuration Validation (78%% confidence)
# ID: config_validation
# Severity: info
# ========================================
echo -n "[5/5] Checking Configuration Validation... "

if grep -rq "yaml\.load\(|json\.load\(|configparser\." . --include="*.py" 2>/dev/null; then
    # Check if exclude pattern also exists (good case)
    if grep -rq "validate|schema|pydantic|marshmallow" . --include="*.py" 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
    echo -e "${CYAN}ℹ${NC}"
    echo "  ℹ️  INFO: Validate configuration at startup to fail fast on invalid config"
    echo "     Recommendation: Add validation schema and validate config at startup"
    echo ""
    INFO=$((INFO + 1))
    fi
fi


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
