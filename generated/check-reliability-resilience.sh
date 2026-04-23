#!/bin/bash
# Auto-generated from sre_reliability_resilience-patterns.yaml v3.0.0
# DO NOT EDIT MANUALLY - Regenerate with: make generate
# Category: Reliability & Resilience
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

echo -e "${BOLD}${BLUE}🔍 SRE Reliability & Resilience Check (v3.0.0)${NC}"
echo -e "${CYAN}Patterns to prevent outages and ensure resilient service behavior${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CRITICAL=0
WARNINGS=0
INFO=0

# ========================================
# Pattern: Timeout Protection
# ID: timeout_protection
# Severity: warning
# ========================================
echo -n "Checking Timeout Protection... "

if grep -rq "requests\.(get|post|put|delete|patch)\([^)]*\)" . --include="*.py" 2>/dev/null; then
    # Check if exclude pattern also exists
    if grep -rq "timeout\s*=" . --include="*.py" 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
    echo -e "${YELLOW}⚠${NC}"
    echo "  🟡 WARNING: All external calls (HTTP, gRPC, database) must have timeout protection"
    echo "     Fix: Add timeout parameter to all external calls"
    echo ""
    WARNINGS=$((WARNINGS + 1))
    fi
fi

# ========================================
# Pattern: Panic Recovery in Goroutines
# ID: panic_recovery
# Severity: warning
# ========================================
echo -n "Checking Panic Recovery in Goroutines... "

if grep -rq "go\s+(func\(|[a-zA-Z])" . --include="*.go" 2>/dev/null; then
    # Check if exclude pattern also exists
    if grep -rq "defer\s+recover\(\)" . --include="*.go" 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
    echo -e "${YELLOW}⚠${NC}"
    echo "  🟡 WARNING: All goroutines must have defer recover() to prevent service crashes"
    echo "     Fix: Add defer recover() with logging at the start of every goroutine"
    echo ""
    WARNINGS=$((WARNINGS + 1))
    fi
fi

# ========================================
# Pattern: Resource Leak Prevention
# ID: resource_not_closed
# Severity: warning
# ========================================
echo -n "Checking Resource Leak Prevention... "

if grep -rq "\.Get\(|\.Post\(|\.Do\(" . --include="*.go" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
    echo "  🟡 WARNING: All resources (connections, files, HTTP responses) must be properly closed"
    echo "     Fix: Use defer in Go or context managers in Python to ensure resources are closed"
    echo ""
    WARNINGS=$((WARNINGS + 1))
fi

# ========================================
# Pattern: Circuit Breaker for External Services
# ID: circuit_breaker
# Severity: warning
# ========================================
echo -n "Checking Circuit Breaker for External Services... "

if grep -rq "http\.Client|grpc\.Dial" . --include="*.go" 2>/dev/null; then
    # Check if exclude pattern also exists
    if grep -rq "hystrix|circuitbreaker|gobreaker" . --include="*.go" 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
    echo -e "${YELLOW}⚠${NC}"
    echo "  🟡 WARNING: External service calls must be protected with circuit breaker pattern"
    echo "     Fix: Wrap external service calls with circuit breaker library"
    echo ""
    WARNINGS=$((WARNINGS + 1))
    fi
fi

# ========================================
# Pattern: Health & Readiness Endpoints
# ID: missing_health_endpoint
# Severity: warning
# ========================================
echo -n "Checking Health & Readiness Endpoints... "

if grep -rq "/health|/ready|/readiness|/healthz|/livez" . --include="*.py" --include="*.go" --include="*.js" --include="*.java" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
    echo "  🟡 WARNING: Service must expose /health and /ready endpoints for Kubernetes probes"
    echo "     Fix: Add /health (liveness) and /ready (readiness) endpoints"
    echo ""
    WARNINGS=$((WARNINGS + 1))
fi


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
