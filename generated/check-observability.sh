#!/bin/bash
# Auto-generated from sre_observability-patterns.yaml v3.0.0
# DO NOT EDIT MANUALLY - Regenerate with: make generate
# Category: Observability
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

echo -e "${BOLD}${BLUE}🔍 SRE Observability Check (v3.0.0)${NC}"
echo -e "${CYAN}Patterns to ensure visibility into service health and performance${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CRITICAL=0
WARNINGS=0
INFO=0

# ========================================
# Pattern: Metrics Instrumentation
# ID: metrics_instrumentation
# Severity: warning
# ========================================
echo -n "Checking Metrics Instrumentation... "

if grep -rq "@app\.route\(|@router\.(get|post|put|delete)" . --include="*.py" 2>/dev/null; then
    # Check if exclude pattern also exists
    if grep -rq "\.inc\(\)|\.observe\(\)|\.histogram\(|prometheus" . --include="*.py" 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
    echo -e "${YELLOW}⚠${NC}"
    echo "  🟡 WARNING: Critical service paths must export Prometheus metrics for SLI tracking"
    echo "     Fix: Add Prometheus counters and histograms to all critical paths"
    echo ""
    WARNINGS=$((WARNINGS + 1))
    fi
fi

# ========================================
# Pattern: Central Error Logging
# ID: central_logging
# Severity: warning
# ========================================
echo -n "Checking Central Error Logging... "

if grep -rq "return.*Exception|raise\s+\w+Error" . --include="*.py" 2>/dev/null; then
    # Check if exclude pattern also exists
    if grep -rq "log\.|logger\.|logging\." . --include="*.py" 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
    echo -e "${YELLOW}⚠${NC}"
    echo "  🟡 WARNING: All errors must be centrally logged before being returned or raised"
    echo "     Fix: Add structured logging for all error paths"
    echo ""
    WARNINGS=$((WARNINGS + 1))
    fi
fi

# ========================================
# Pattern: Request Duration Tracking
# ID: duration_metrics
# Severity: warning
# ========================================
echo -n "Checking Request Duration Tracking... "

if grep -rq "@app\.route\(" . --include="*.py" 2>/dev/null; then
    # Check if exclude pattern also exists
    if grep -rq "Histogram|\.observe\(|\.time\(\)" . --include="*.py" 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
    echo -e "${YELLOW}⚠${NC}"
    echo "  🟡 WARNING: All HTTP endpoints must track request duration for latency SLOs"
    echo "     Fix: Add Prometheus Histogram to track request duration"
    echo ""
    WARNINGS=$((WARNINGS + 1))
    fi
fi

# ========================================
# Pattern: Request ID Propagation
# ID: request_id_propagation
# Severity: info
# ========================================
echo -n "Checking Request ID Propagation... "

if grep -rq "requests\.(get|post|put|delete)" . --include="*.py" 2>/dev/null; then
    # Check if exclude pattern also exists
    if grep -rq "X-Request-ID|request_id|correlation_id" . --include="*.py" 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
    echo -e "${CYAN}ℹ${NC}"
    echo "  ℹ️  INFO: Propagate request IDs across service boundaries for distributed tracing"
    echo "     Recommendation: Extract request ID from incoming requests and propagate to outgoing calls"
    echo ""
    INFO=$((INFO + 1))
    fi
fi

# ========================================
# Pattern: Metrics Endpoint
# ID: missing_metrics_endpoint
# Severity: warning
# ========================================
echo -n "Checking Metrics Endpoint... "

if grep -rq "/metrics" . --include="*.py" --include="*.go" --include="*.js" --include="*.java" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
    echo "  🟡 WARNING: Service must expose /metrics endpoint for Prometheus to scrape"
    echo "     Fix: Expose /metrics endpoint with Prometheus client library"
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
