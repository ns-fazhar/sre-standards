#!/bin/bash
# Auto-generated from check-patterns.yaml v2.1.0
# DO NOT EDIT MANUALLY - Regenerate with: make generate

set -e

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${BLUE}🔍 SRE Operability Check (v2.1.0)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ISSUES=0
WARNINGS=0

# Check: Readiness Endpoint
echo -n "Checking readiness endpoint... "
if grep -rq "/ready|/readiness" . --include="*.py" --include="*.go" --include="*.js" --include="*.java" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "  ❌ BLOCKING: Service must have /ready endpoint for Kubernetes readiness probes"
    echo "     Fix: Add readiness endpoint that checks all dependencies (DB, cache, APIs)"
    echo ""
    ISSUES=$((ISSUES + 1))
fi

# Check: Health Endpoint
echo -n "Checking health endpoint... "
if grep -rq "/health" . --include="*.py" --include="*.go" --include="*.js" --include="*.java" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
    echo "  ⚠️  WARNING: Basic health/liveness check endpoint"
    echo ""
    WARNINGS=$((WARNINGS + 1))
fi

# Check: Metrics Endpoint
echo -n "Checking metrics endpoint... "
if grep -rq "/metrics|prometheus" . --include="*.py" --include="*.go" --include="*.js" --include="*.java" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
    echo "  ⚠️  WARNING: Prometheus-compatible metrics endpoint"
    echo ""
    WARNINGS=$((WARNINGS + 1))
fi

# Check: Structured Logging
echo -n "Checking structured logging... "
if grep -rq "json|structlog|JSON|logrus" . --include="*.py" --include="*.go" --include="*.js" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
    echo "  ⚠️  WARNING: Use structured (JSON) logging for easy parsing"
    echo ""
    WARNINGS=$((WARNINGS + 1))
fi

# Check: HTTP Timeouts
echo -n "Checking http timeouts... "
if grep -rq "timeout=" . --include="*.py" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "  ❌ BLOCKING: All HTTP calls must have timeout parameters"
    echo "     Fix: Add timeout parameter to all HTTP calls"
    echo ""
    ISSUES=$((ISSUES + 1))
fi

# Check: Circuit Breaker
echo -n "Checking circuit breaker... "
if grep -rq "circuit|breaker|CircuitBreaker|Hystrix" . --include="*.py" --include="*.go" --include="*.js" --include="*.java" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "  ❌ BLOCKING: Protect against cascading failures with circuit breaker pattern"
    echo "     Fix: Implement circuit breaker for external service calls"
    echo ""
    ISSUES=$((ISSUES + 1))
fi

# Check: Error Handling
echo -n "Checking error handling... "
if grep -rq "try:|except |catch\(|error" . --include="*.py" --include="*.go" --include="*.js" --include="*.java" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
    echo "  ⚠️  WARNING: Proper error handling to prevent crashes"
    echo ""
    WARNINGS=$((WARNINGS + 1))
fi

# Check: Dockerfile
echo -n "Checking dockerfile... "
if [ -f "Dockerfile" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
    echo "  ⚠️  WARNING: Service should have Dockerfile for containerization"
    echo ""
    WARNINGS=$((WARNINGS + 1))
fi

# Check: Kubernetes Manifests
echo -n "Checking kubernetes manifests... "
if [ -d "k8s/" -o -d "kubernetes/" -o -d "deploy/" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
    echo "  ⚠️  WARNING: K8s deployment manifests in repository"
    echo ""
    WARNINGS=$((WARNINGS + 1))
fi

# Check: Dependency Management
echo -n "Checking dependency management... "
if [ -f "requirements.txt" -o -f "package.json" -o -f "go.mod" -o -f "pom.xml" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
    echo "  ⚠️  WARNING: Dependencies should be declared and version-pinned"
    echo ""
    WARNINGS=$((WARNINGS + 1))
fi

# Check: No Hardcoded Secrets
echo -n "Checking no hardcoded secrets... "
if grep -rq "password.*=.*['"][^'"]+['"]|api_key.*=.*['"][^'"]+['"]" . --include="*.py" --include="*.go" --include="*.js" --include="*.java" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "  ❌ BLOCKING: No hardcoded passwords or API keys"
    echo "     Fix: Use environment variables or secret management"
    echo ""
    ISSUES=$((ISSUES + 1))
fi

# Check: README
echo -n "Checking readme... "
if [ -f "README.md" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
    echo "  ⚠️  WARNING: Service must have README documentation"
    echo ""
    WARNINGS=$((WARNINGS + 1))
fi

# Check: Runbook
echo -n "Checking runbook... "
if [ -f "RUNBOOK.md" -o -f "docs/runbook.md" -o -f "OPERATIONS.md" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "  ❌ BLOCKING: Operational runbook for on-call engineers"
    echo "     Fix: Create RUNBOOK.md with troubleshooting steps"
    echo ""
    ISSUES=$((ISSUES + 1))
fi


echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $ISSUES -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✅ ALL CHECKS PASSED!${NC}"
    echo ""
    exit 0
elif [ $ISSUES -eq 0 ]; then
    echo -e "${YELLOW}${BOLD}⚠️  PASSED WITH WARNINGS${NC}"
    echo ""
    echo "Found $WARNINGS warning(s), but no blocking issues."
    exit 0
else
    echo -e "${RED}${BOLD}❌ CHECKS FAILED${NC}"
    echo ""
    echo "Found $ISSUES blocking issue(s) and $WARNINGS warning(s)."
    echo ""
    echo "⛔ Please fix blocking issues before deploying to production."
    exit 1
fi
