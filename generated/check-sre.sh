#!/bin/bash
# Auto-generated from sre-patterns.yaml v1.0.0
# DO NOT EDIT MANUALLY - Regenerate with: make generate
# Category: SRE Checks (Reliability & Resilience)
# Patterns: 5 critical checks
# Languages: python, go, java, scala, javascript, typescript

set -e

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${BLUE}🔍 SRE Critical: SRE Checks (Reliability & Resilience) (v1.0.0)${NC}"
echo -e "${CYAN}Critical patterns to prevent outages and ensure resilient service behavior${NC}"
echo -e "${CYAN}Confidence: High (85-95% across patterns)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CRITICAL=0
WARNINGS=0
INFO=0

# ========================================
# Pattern: HTTP Timeout Protection (95%% confidence)
# ID: http_timeouts
# Severity: blocking
# ========================================
echo -n "[1/5] Checking HTTP Timeout Protection... "

MATCHES=$(grep -rHn "requests\.(get|post|put|delete|patch)\([^)]*\)" . --include="*.py" 2>/dev/null || true)
if [ -n "$MATCHES" ]; then
    # Check if exclude pattern also exists (good case)
    EXCLUDES=$(echo "$MATCHES" | while IFS=: read -r file line content; do
        grep -q "timeout\s*=" "$file" 2>/dev/null && echo "$file:$line:$content"
    done)
    if [ -n "$EXCLUDES" ]; then
        echo -e "${GREEN}✓${NC}"
    else
    echo -e "${RED}✗${NC}"
    echo "  🔴 BLOCKING: All HTTP calls must have timeout parameters to prevent indefinite hangs"
    echo "     Fix: Add timeout parameter to all HTTP calls"
    echo ""
    echo "     Files missing proper implementation:"
    echo "$MATCHES" | while IFS=: read -r file line content; do
        echo "       - ${CYAN}$file:$line${NC} → ${RED}$(echo "$content" | xargs)${NC}"
    done
    echo ""
    CRITICAL=$((CRITICAL + 1))
    fi
fi

# ========================================
# Pattern: Circuit Breaker for External Services (90%% confidence)
# ID: circuit_breaker
# Severity: blocking
# ========================================
echo -n "[2/5] Checking Circuit Breaker for External Services... "

MATCHES=$(grep -rHn "requests\.(get|post)" . --include="*.py" 2>/dev/null || true)
if [ -n "$MATCHES" ]; then
    # Check if exclude pattern also exists (good case)
    EXCLUDES=$(echo "$MATCHES" | while IFS=: read -r file line content; do
        grep -q "CircuitBreaker|pybreaker" "$file" 2>/dev/null && echo "$file:$line:$content"
    done)
    if [ -n "$EXCLUDES" ]; then
        echo -e "${GREEN}✓${NC}"
    else
    echo -e "${RED}✗${NC}"
    echo "  🔴 BLOCKING: External service calls must be protected with circuit breaker pattern"
    echo "     Fix: Wrap external service calls with circuit breaker library"
    echo ""
    echo "     Files missing proper implementation:"
    echo "$MATCHES" | while IFS=: read -r file line content; do
        echo "       - ${CYAN}$file:$line${NC} → ${RED}$(echo "$content" | xargs)${NC}"
    done
    echo ""
    CRITICAL=$((CRITICAL + 1))
    fi
fi

# ========================================
# Pattern: Resource Leak Prevention (85%% confidence)
# ID: resource_leak
# Severity: warning
# ========================================
echo -n "[3/5] Checking Resource Leak Prevention... "

MATCHES=$(grep -rHn "\.Get\(|\.Post\(|\.Do\(" . --include="*.go" 2>/dev/null || true)
if [ -n "$MATCHES" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
    echo "  🟡 WARNING: All resources (connections, files, HTTP responses) must be properly closed"
    echo "     Fix: Use defer (Go), context managers (Python), try-with-resources (Java)"
    echo ""
    WARNINGS=$((WARNINGS + 1))
fi

# ========================================
# Pattern: Retry Logic with Exponential Backoff (88%% confidence)
# ID: retry_exponential_backoff
# Severity: warning
# ========================================
echo -n "[4/5] Checking Retry Logic with Exponential Backoff... "

MATCHES=$(grep -rHn "requests\.(get|post|put|delete)" . --include="*.py" 2>/dev/null || true)
if [ -n "$MATCHES" ]; then
    # Check if exclude pattern also exists (good case)
    EXCLUDES=$(echo "$MATCHES" | while IFS=: read -r file line content; do
        grep -q "@retry|tenacity|backoff" "$file" 2>/dev/null && echo "$file:$line:$content"
    done)
    if [ -n "$EXCLUDES" ]; then
        echo -e "${GREEN}✓${NC}"
    else
    echo -e "${YELLOW}⚠${NC}"
    echo "  🟡 WARNING: External service calls should implement retry logic with exponential backoff"
    echo "     Fix: Implement retry with exponential backoff and jitter"
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
# Pattern: Health & Readiness Endpoints (90%% confidence)
# ID: health_readiness
# Severity: warning
# ========================================
echo -n "[5/5] Checking Health & Readiness Endpoints... "

MATCHES=$(grep -rHn "/health|/ready|/readiness|/healthz|/livez" . --include="*.py" --include="*.go" --include="*.js" --include="*.java" --include="*.scala" 2>/dev/null || true)
if [ -n "$MATCHES" ]; then
    echo -e "${YELLOW}⚠${NC}"
    echo "  🟡 WARNING: Service must expose /health and /ready endpoints for Kubernetes probes"
    echo "     Fix: Add /health (liveness) and /ready (readiness) endpoints"
    echo ""
    echo "     Violations found:"
    echo "$MATCHES" | while IFS=: read -r file line content; do
        echo "       - ${CYAN}$file:$line${NC} → ${YELLOW}$(echo "$content" | xargs)${NC}"
    done
    echo ""
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓${NC}"
fi


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
