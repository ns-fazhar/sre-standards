#!/bin/bash
# Auto-generated from sre-patterns.yaml v1.0.0
# DO NOT EDIT MANUALLY - Regenerate with: make generate
# Category: Observability
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

echo -e "${BOLD}${BLUE}🔍 SRE Critical: Observability (v1.0.0)${NC}"
echo -e "${CYAN}Patterns to ensure visibility into service health and performance${NC}"
echo -e "${CYAN}Confidence: High (80-92% across patterns)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CRITICAL=0
WARNINGS=0
INFO=0

# ========================================
# Pattern: Prometheus Metrics Instrumentation (92%% confidence)
# ID: metrics_instrumentation
# Severity: warning
# ========================================
echo -n "[1/5] Checking Prometheus Metrics Instrumentation... "

MATCHES=$(grep -rHnE "@app\.route\(|@router\.(get|post|put|delete)" . --include="*.py" 2>/dev/null || true)
if [ -n "$MATCHES" ]; then
    # Check if exclude pattern also exists (good case)
    BAD_MATCHES=""
    while IFS=: read -r file line content; do
        if ! grep -q "\.inc\(\)|\.observe\(\)|prometheus|@metrics" "$file" 2>/dev/null; then
            BAD_MATCHES="${BAD_MATCHES}$file:$line:$content"$'\n'
        fi
    done <<< "$MATCHES"
    if [ -z "$BAD_MATCHES" ]; then
        echo -e "${GREEN}✓${NC}"
    else
    echo -e "${YELLOW}⚠${NC}"
    echo "  🟡 WARNING: Critical service paths must export Prometheus metrics for SLI tracking"
    echo "     Fix: Add Prometheus counters and histograms to all critical paths"
    echo ""
    echo "     Files missing proper implementation:"
    while IFS=: read -r file line content; do
        [ -z "$file" ] && continue
        echo "       - ${CYAN}$file:$line${NC} → ${YELLOW}$(echo "$content" | xargs)${NC}"
    done <<< "$BAD_MATCHES"
    echo ""
    WARNINGS=$((WARNINGS + 1))
    fi
fi

# ========================================
# Pattern: Metrics Endpoint (90%% confidence)
# ID: metrics_endpoint
# Severity: warning
# ========================================
echo -n "[2/5] Checking Metrics Endpoint... "

MATCHES=$(grep -rHn "/metrics" . --include="*.py" --include="*.go" --include="*.js" --include="*.java" --include="*.scala" 2>/dev/null || true)
if [ -n "$MATCHES" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
    echo "  🟡 WARNING: Service must expose /metrics endpoint for Prometheus to scrape"
    echo "     Fix: Expose /metrics endpoint with Prometheus client library"
    echo ""
    WARNINGS=$((WARNINGS + 1))
fi

# ========================================
# Pattern: Central Error Logging (87%% confidence)
# ID: central_logging
# Severity: warning
# ========================================
echo -n "[3/5] Checking Central Error Logging... "

MATCHES=$(grep -rHnE "raise\s+\w+Error|return.*Exception" . --include="*.py" 2>/dev/null || true)
if [ -n "$MATCHES" ]; then
    # Check if exclude pattern also exists (good case)
    BAD_MATCHES=""
    while IFS=: read -r file line content; do
        if ! grep -q "log\.|logger\.|logging\." "$file" 2>/dev/null; then
            BAD_MATCHES="${BAD_MATCHES}$file:$line:$content"$'\n'
        fi
    done <<< "$MATCHES"
    if [ -z "$BAD_MATCHES" ]; then
        echo -e "${GREEN}✓${NC}"
    else
    echo -e "${YELLOW}⚠${NC}"
    echo "  🟡 WARNING: All errors must be centrally logged to SUMO Logic before being returned or raised"
    echo "     Fix: Add structured logging for all error paths (automatically sent to SUMO Logic)"
    echo ""
    echo "     Files missing proper implementation:"
    while IFS=: read -r file line content; do
        [ -z "$file" ] && continue
        echo "       - ${CYAN}$file:$line${NC} → ${YELLOW}$(echo "$content" | xargs)${NC}"
    done <<< "$BAD_MATCHES"
    echo ""
    WARNINGS=$((WARNINGS + 1))
    fi
fi

# ========================================
# Pattern: Request Duration Tracking (85%% confidence)
# ID: duration_metrics
# Severity: warning
# ========================================
echo -n "[4/5] Checking Request Duration Tracking... "

MATCHES=$(grep -rHnE "@app\.route\(" . --include="*.py" 2>/dev/null || true)
if [ -n "$MATCHES" ]; then
    # Check if exclude pattern also exists (good case)
    BAD_MATCHES=""
    while IFS=: read -r file line content; do
        if ! grep -q "Histogram|\.observe\(|\.time\(\)" "$file" 2>/dev/null; then
            BAD_MATCHES="${BAD_MATCHES}$file:$line:$content"$'\n'
        fi
    done <<< "$MATCHES"
    if [ -z "$BAD_MATCHES" ]; then
        echo -e "${GREEN}✓${NC}"
    else
    echo -e "${YELLOW}⚠${NC}"
    echo "  🟡 WARNING: All HTTP endpoints must track request duration for latency SLOs"
    echo "     Fix: Add Prometheus Histogram to track request duration"
    echo ""
    echo "     Files missing proper implementation:"
    while IFS=: read -r file line content; do
        [ -z "$file" ] && continue
        echo "       - ${CYAN}$file:$line${NC} → ${YELLOW}$(echo "$content" | xargs)${NC}"
    done <<< "$BAD_MATCHES"
    echo ""
    WARNINGS=$((WARNINGS + 1))
    fi
fi

# ========================================
# Pattern: Request ID Propagation (80%% confidence)
# ID: request_id_propagation
# Severity: info
# ========================================
echo -n "[5/5] Checking Request ID Propagation... "

MATCHES=$(grep -rHnE "requests\.(get|post|put|delete)" . --include="*.py" 2>/dev/null || true)
if [ -n "$MATCHES" ]; then
    # Check if exclude pattern also exists (good case)
    BAD_MATCHES=""
    while IFS=: read -r file line content; do
        if ! grep -q "X-Request-ID|request_id|correlation_id|trace_id" "$file" 2>/dev/null; then
            BAD_MATCHES="${BAD_MATCHES}$file:$line:$content"$'\n'
        fi
    done <<< "$MATCHES"
    if [ -z "$BAD_MATCHES" ]; then
        echo -e "${GREEN}✓${NC}"
    else
    echo -e "${CYAN}ℹ${NC}"
    echo "  ℹ️  INFO: Propagate request IDs across service boundaries for distributed tracing"
    echo "     Recommendation: Extract request ID from incoming requests and propagate to outgoing calls"
    echo ""
    INFO=$((INFO + 1))
    fi
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
