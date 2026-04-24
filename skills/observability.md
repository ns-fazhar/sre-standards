---
name: observability
description: Critical observability patterns - visibility into service health
version: 1.0.0
category: critical_observability
auto-generated: true
languages: python, go, java, scala, javascript, typescript
---

# SRE Critical: Observability

**Version**: 1.0.0
**Last Updated**: 2026-04-24
**Languages**: python, go, java, scala, javascript, typescript

## Purpose

Patterns to ensure visibility into service health and performance

**Confidence Level**: High (80-92% across patterns)

This skill checks for **5 critical patterns** in this category.

## Usage

When invoked, analyze the codebase and check for the following patterns:

---

### 1. ⚠️ Prometheus Metrics Instrumentation (WARNING)

**Pattern ID**: `metrics_instrumentation`  
**Priority**: 1  
**Confidence**: 92%%  
**Source**: Service Maturity Pattern #19 - SLI metrics  

**Description**: Critical service paths must export Prometheus metrics for SLI tracking

**Impact**:
- Cannot measure service performance or SLOs
- No visibility into request rates, latency, errors
- Unable to create meaningful alerts
- Debugging production issues requires guesswork
- Cannot identify performance regressions


**Fix**: Add Prometheus counters and histograms to all critical paths

**Example**:
```
# Python - prometheus_client
from prometheus_client import Counter, Histogram

request_count = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

request_duration = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency',
    ['method', 'endpoint']
)

@app.route('/checkout', methods=['POST'])
@request_duration.labels(method='POST', endpoint='checkout').time()
def checkout():
    try:
        result = process_checkout(request.json)
        request_count.labels(method='POST', endpoint='checkout', status='success').inc()
        return jsonify(result), 200
    except Exception as e:
        request_count.labels(method='POST', endpoint='checkout', status='error').inc()
        raise

# Go - prometheus
var (
    httpRequestsTotal = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_requests_total",
            Help: "Total HTTP requests",
        },
        []string{"method", "endpoint", "status"},
    )

    httpDuration = promauto.NewHistogramVec(
        prometheus.HistogramOpts{
            Name: "http_request_duration_seconds",
            Help: "HTTP request latency",
        },
        []string{"method", "endpoint"},
    )
)

func checkoutHandler(w http.ResponseWriter, r *http.Request) {
    timer := prometheus.NewTimer(httpDuration.WithLabelValues("POST", "/checkout"))
    defer timer.ObserveDuration()

    err := processCheckout(r.Body)
    if err != nil {
        httpRequestsTotal.WithLabelValues("POST", "/checkout", "error").Inc()
        http.Error(w, err.Error(), 500)
        return
    }
    httpRequestsTotal.WithLabelValues("POST", "/checkout", "success").Inc()
}

# Java - Micrometer
@RestController
public class CheckoutController {
    private final MeterRegistry registry;
    private final Counter requestCounter;
    private final Timer requestTimer;

    @PostMapping("/checkout")
    public ResponseEntity<?> checkout(@RequestBody CheckoutRequest req) {
        return requestTimer.record(() -> {
            try {
                var result = processCheckout(req);
                requestCounter.increment();
                return ResponseEntity.ok(result);
            } catch (Exception e) {
                registry.counter("http_requests_total",
                    "method", "POST",
                    "endpoint", "/checkout",
                    "status", "error").increment();
                throw e;
            }
        });
    }
}

```

**References**:
- https://prometheus.io/docs/practices/instrumentation/
- https://github.com/prometheus/client_python
- https://micrometer.io/docs

---

### 2. ⚠️ Metrics Endpoint (WARNING)

**Pattern ID**: `metrics_endpoint`  
**Priority**: 2  
**Confidence**: 90%%  
**Source**: Prometheus scraping requirement  

**Description**: Service must expose /metrics endpoint for Prometheus to scrape

**Impact**:
- Prometheus cannot collect metrics from service
- No monitoring dashboards or alerts possible
- Service invisible to observability platform
- Cannot track SLOs or performance


**Fix**: Expose /metrics endpoint with Prometheus client library

**Example**:
```
# Python - Flask
from prometheus_client import make_wsgi_app
from werkzeug.middleware.dispatcher import DispatcherMiddleware

app.wsgi_app = DispatcherMiddleware(app.wsgi_app, {
    '/metrics': make_wsgi_app()
})

# Go - promhttp
import "github.com/prometheus/client_golang/prometheus/promhttp"

func main() {
    http.Handle("/metrics", promhttp.Handler())
    http.ListenAndServe(":8080", nil)
}

# Java - Spring Boot Actuator
# application.properties
management.endpoints.web.exposure.include=health,metrics,prometheus
management.metrics.export.prometheus.enabled=true

# Kubernetes ServiceMonitor
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: myservice
spec:
  selector:
    matchLabels:
      app: myservice
  endpoints:
  - port: http
    path: /metrics
    interval: 30s

```

**References**:
- https://prometheus.io/docs/instrumenting/exporters/

---

### 3. ⚠️ Central Error Logging (WARNING)

**Pattern ID**: `central_logging`  
**Priority**: 3  
**Confidence**: 87%%  
**Source**: Service Maturity Pattern #21  

**Description**: All errors must be centrally logged to SUMO Logic before being returned or raised

**Impact**:
- Cannot debug production issues without logs in SUMO
- Missing context about failure scenarios
- Incomplete error tracking and metrics
- Increased MTTR (Mean Time To Resolution)
- Lost incident forensics data


**Fix**: Add structured logging for all error paths (automatically sent to SUMO Logic)

**Example**:
```
# Python - structlog (sends to SUMO Logic)
import structlog
logger = structlog.get_logger()

try:
    result = payment_gateway.charge(data)
except PaymentGatewayError as e:
    logger.error(
        "payment_gateway_failure",
        error=str(e),
        payment_id=data.get('id'),
        amount=data.get('amount'),
        user_id=data.get('user_id')
    )
    raise

# Go - zap (sends to SUMO Logic)
import "go.uber.org/zap"

result, err := paymentGateway.Charge(ctx, data)
if err != nil {
    logger.Error("payment gateway failure",
        zap.Error(err),
        zap.String("payment_id", data.ID),
        zap.Float64("amount", data.Amount),
    )
    return err
}

# Java - SLF4J with structured logging (sends to SUMO Logic)
try {
    result = paymentGateway.charge(data);
} catch (PaymentGatewayException e) {
    logger.error("Payment gateway failure: paymentId={}, amount={}, error={}",
        data.getId(), data.getAmount(), e.getMessage(), e);
    throw e;
}

```

**References**:
- https://www.structlog.org/
- https://github.com/uber-go/zap

---

### 4. ⚠️ Request Duration Tracking (WARNING)

**Pattern ID**: `duration_metrics`  
**Priority**: 4  
**Confidence**: 85%%  
**Source**: SLO tracking requirement  

**Description**: All HTTP endpoints must track request duration for latency SLOs

**Impact**:
- Cannot measure P50, P95, P99 latency
- Unable to detect performance regressions
- No SLO tracking for customer-facing endpoints
- Missing data for capacity planning


**Fix**: Add Prometheus Histogram to track request duration

**Example**:
```
# Python - Histogram with decorator
from prometheus_client import Histogram

request_latency = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency',
    ['method', 'endpoint'],
    buckets=(0.01, 0.05, 0.1, 0.5, 1.0, 2.5, 5.0, 10.0)
)

@app.route('/api/search')
@request_latency.labels(method='GET', endpoint='/api/search').time()
def search():
    return jsonify(perform_search(request.args))

# Go - Histogram with timer
httpDuration := promauto.NewHistogramVec(
    prometheus.HistogramOpts{
        Name: "http_request_duration_seconds",
        Help: "HTTP request latency",
        Buckets: prometheus.DefBuckets,
    },
    []string{"method", "endpoint"},
)

func searchHandler(w http.ResponseWriter, r *http.Request) {
    timer := prometheus.NewTimer(httpDuration.WithLabelValues("GET", "/api/search"))
    defer timer.ObserveDuration()

    results := performSearch(r.URL.Query())
    json.NewEncoder(w).Encode(results)
}

# Java - Micrometer Timer
@GetMapping("/api/search")
@Timed(value = "http.request.duration", percentiles = {0.5, 0.95, 0.99})
public List<Result> search(@RequestParam String query) {
    return performSearch(query);
}

```

**References**:
- https://prometheus.io/docs/practices/histograms/

---

### 5. ℹ️ Request ID Propagation (INFO)

**Pattern ID**: `request_id_propagation`  
**Priority**: 5  
**Confidence**: 80%%  
**Source**: Distributed tracing requirement  

**Description**: Propagate request IDs across service boundaries for distributed tracing

**Impact**:
- Cannot trace requests across microservices
- Difficult to correlate logs from different services
- Incomplete debugging for multi-service workflows
- Lost transaction context in distributed systems


**Fix**: Extract request ID from incoming requests and propagate to outgoing calls

**Example**:
```
# Python - Flask middleware
import uuid
from flask import request, g

@app.before_request
def before_request():
    g.request_id = request.headers.get('X-Request-ID', str(uuid.uuid4()))

def call_external_service(url, data):
    headers = {
        'X-Request-ID': g.request_id,
        'Content-Type': 'application/json'
    }
    return requests.post(url, json=data, headers=headers, timeout=10)

# Go - middleware
func requestIDMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        requestID := r.Header.Get("X-Request-ID")
        if requestID == "" {
            requestID = uuid.New().String()
        }
        ctx := context.WithValue(r.Context(), "request_id", requestID)
        w.Header().Set("X-Request-ID", requestID)
        next.ServeHTTP(w, r.WithContext(ctx))
    })
}

# Java - Spring Boot Interceptor
@Component
public class RequestIdInterceptor implements HandlerInterceptor {
    @Override
    public boolean preHandle(HttpServletRequest request,
                            HttpServletResponse response, Object handler) {
        String requestId = request.getHeader("X-Request-ID");
        if (requestId == null) {
            requestId = UUID.randomUUID().toString();
        }
        MDC.put("requestId", requestId);
        response.setHeader("X-Request-ID", requestId);
        return true;
    }
}

```

**References**:
- https://www.w3.org/TR/trace-context/

---


## Output Format

Provide a structured assessment:

### ✅ Summary
- Overall status: PASS / WARN / FAIL
- Patterns checked: 5
- Issues found: X critical, Y warnings, Z info

### 🔴 Critical Issues
List any critical severity findings with:
- Pattern name and ID
- File path and line number
- Specific issue description
- Recommended fix

### 🟡 Warnings
List any warning severity findings with same details

### ℹ️ Informational
List any info severity findings

### 📋 Next Steps
- Specific actions to take
- Priority order

## Example Output

```
🔍 SRE Critical: Observability Results

✅ SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Patterns Checked: 5
Status: ⚠️  WARN - 1 critical issue, 2 warnings found

🔴 CRITICAL ISSUES (1)

1. [SQL Injection Prevention] String concatenation in query
   File: handlers/user_handler.py:45
   Issue: Using f-string in SQL query
   Fix: Use parameterized query with placeholders

   ❌ BAD:
   query = f"SELECT * FROM users WHERE id = {user_id}"

   ✅ GOOD:
   query = "SELECT * FROM users WHERE id = %s"
   cursor.execute(query, (user_id,))

🟡 WARNINGS (2)

1. [HTTP Timeouts] Missing timeout on HTTP call
   File: services/payment_service.py:78
   Fix: Add timeout=10 parameter to requests.post()

2. [Metrics Instrumentation] Endpoint without Prometheus metrics
   File: handlers/checkout.py:42
   Fix: Add @request_duration.labels().time() decorator

📋 NEXT STEPS
1. Fix critical SQL injection issue immediately (Security risk)
2. Add timeouts to all external API calls (Reliability)
3. Instrument endpoints with Prometheus metrics (Observability)
4. Re-run check to verify fixes
```

## Notes

- This skill is auto-generated from `mappings/sre-patterns.yaml`
- Enabled patterns controlled by `mappings/enabled-patterns.yaml`
- To update: modify YAML and run `make generate`
- Multi-language support: Python, Go, Java, Scala
- Observability stack: Prometheus (metrics), SUMO Logic (logging)
