---
name: sre-checks-top5
description: Top 5 reliability and resilience patterns - prevent outages
version: 1.0.0
category: top5_sre_checks
auto-generated: true
languages: python, go, java, scala
---

# SRE Top 5: SRE Checks (Reliability & Resilience)

**Version**: 1.0.0
**Last Updated**: 2026-04-23
**Languages**: python, go, java, scala

## Purpose

Critical patterns to prevent outages and ensure resilient service behavior

**Confidence Level**: High (85-95% across patterns)

This skill checks for the **Top 5 most critical patterns** in this category.

## Usage

When invoked, analyze the codebase and check for the following patterns:

---

### 1. 🟡 HTTP Timeout Protection (BLOCKING)

**Pattern ID**: `http_timeouts`  
**Priority**: 1  
**Confidence**: 95%%  
**Source**: Service Maturity Pattern #13 - Cascading failures  

**Description**: All HTTP calls must have timeout parameters to prevent indefinite hangs

**Impact**:
- Service can hang indefinitely waiting for responses
- Thread/goroutine pool exhaustion under load
- Cascading failures across microservices
- Unable to meet SLOs during dependency slowdowns


**Fix**: Add timeout parameter to all HTTP calls

**Example**:
```
# Python - requests
# ❌ BAD - No timeout
response = requests.post(url, json=data)

# ✅ GOOD - With timeout
response = requests.post(url, json=data, timeout=10)

# ✅ BETTER - Separate connect/read timeouts
response = requests.post(url, json=data, timeout=(3, 10))

# Go - http.Client
// ❌ BAD - No timeout
client := &http.Client{}

// ✅ GOOD - With timeout
client := &http.Client{
    Timeout: 10 * time.Second,
}

# Java - RestTemplate
// ❌ BAD - No timeout
RestTemplate restTemplate = new RestTemplate();

// ✅ GOOD - With timeout
HttpComponentsClientHttpRequestFactory factory =
    new HttpComponentsClientHttpRequestFactory();
factory.setConnectTimeout(3000);
factory.setReadTimeout(10000);
RestTemplate restTemplate = new RestTemplate(factory);

# Scala - sttp
// ✅ GOOD - With timeout
val request = basicRequest
  .get(uri"$url")
  .readTimeout(10.seconds)
  .response(asString)

```

**References**:
- https://requests.readthedocs.io/en/latest/user/advanced/#timeouts
- https://pkg.go.dev/net/http#Client

---

### 2. 🟡 Circuit Breaker for External Services (BLOCKING)

**Pattern ID**: `circuit_breaker`  
**Priority**: 2  
**Confidence**: 90%%  
**Source**: Service Maturity Pattern #12 - Cascading failures  

**Description**: External service calls must be protected with circuit breaker pattern

**Impact**:
- Cascading failures when external service degrades
- Wasted resources on calls to failing services
- No automatic recovery mechanism
- Increased latency as timeouts accumulate
- Inability to isolate and contain failures


**Fix**: Wrap external service calls with circuit breaker library

**Example**:
```
# Python - pybreaker
from pybreaker import CircuitBreaker

payment_breaker = CircuitBreaker(
    fail_max=5,              # Open after 5 failures
    timeout_duration=60,     # Try again after 60 seconds
)

@payment_breaker
def call_payment_gateway(data):
    return requests.post(PAYMENT_API_URL, json=data, timeout=10)

# Go - gobreaker
import "github.com/sony/gobreaker"

cb := gobreaker.NewCircuitBreaker(gobreaker.Settings{
    Name:        "payment-api",
    MaxRequests: 3,
    Timeout:     time.Minute,
    ReadyToTrip: func(counts gobreaker.Counts) bool {
        return counts.ConsecutiveFailures > 5
    },
})

result, err := cb.Execute(func() (interface{}, error) {
    return http.Get(paymentAPIURL)
})

# Java - Resilience4j
import io.github.resilience4j.circuitbreaker.CircuitBreaker;

CircuitBreaker circuitBreaker = CircuitBreaker.of("paymentService",
    CircuitBreakerConfig.custom()
        .failureRateThreshold(50)
        .waitDurationInOpenState(Duration.ofSeconds(60))
        .build());

Supplier<String> decoratedSupplier = CircuitBreaker
    .decorateSupplier(circuitBreaker, () -> callPaymentGateway(data));

# Scala - Akka Circuit Breaker
val breaker = new CircuitBreaker(
    scheduler,
    maxFailures = 5,
    callTimeout = 10.seconds,
    resetTimeout = 1.minute
)

breaker.withCircuitBreaker(callPaymentGateway(data))

```

**References**:
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://github.com/sony/gobreaker
- https://resilience4j.readme.io/docs/circuitbreaker

---

### 3. ⚠️ Resource Leak Prevention (WARNING)

**Pattern ID**: `resource_leak`  
**Priority**: 3  
**Confidence**: 85%%  
**Source**: Production reliability best practice  

**Description**: All resources (connections, files, HTTP responses) must be properly closed

**Impact**:
- Connection pool exhaustion (cannot open new connections)
- File descriptor leaks (hitting OS limits)
- Memory leaks from unclosed HTTP response bodies
- Service degradation over time, requiring restarts


**Fix**: Use defer (Go), context managers (Python), try-with-resources (Java)

**Example**:
```
# Go - HTTP Response
// ❌ BAD - Body not closed
resp, err := http.Get(url)
body, _ := ioutil.ReadAll(resp.Body)

// ✅ GOOD - Body closed with defer
resp, err := http.Get(url)
if err != nil {
    return err
}
defer resp.Body.Close()
body, _ := ioutil.ReadAll(resp.Body)

# Python - Files
# ❌ BAD - File not closed
f = open('file.txt', 'r')
data = f.read()

# ✅ GOOD - Context manager ensures close
with open('file.txt', 'r') as f:
    data = f.read()

# Java - Files
// ❌ BAD - Resource not closed
FileInputStream fis = new FileInputStream("file.txt");
int data = fis.read();

// ✅ GOOD - Try-with-resources
try (FileInputStream fis = new FileInputStream("file.txt")) {
    int data = fis.read();
}

# Scala - Using (Scala 2.13+)
// ✅ GOOD - Using ensures close
Using(Source.fromFile("file.txt")) { source =>
    source.getLines().toList
}

```

**References**:
- https://go.dev/doc/effective_go#defer
- https://docs.oracle.com/javase/tutorial/essential/exceptions/tryResourceClose.html

---

### 4. ⚠️ Retry Logic with Exponential Backoff (WARNING)

**Pattern ID**: `retry_exponential_backoff`  
**Priority**: 4  
**Confidence**: 88%%  
**Source**: Resilience best practice - Transient failure handling  

**Description**: External service calls should implement retry logic with exponential backoff

**Impact**:
- Transient failures become permanent failures
- No automatic recovery from temporary network issues
- Thundering herd problem (all clients retry simultaneously)
- Poor user experience for recoverable errors


**Fix**: Implement retry with exponential backoff and jitter

**Example**:
```
# Python - tenacity
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=1, max=10)
)
def call_external_api(data):
    return requests.post(url, json=data, timeout=10)

# Go - with backoff
import "github.com/cenkalti/backoff/v4"

operation := func() error {
    resp, err := http.Get(url)
    if err != nil {
        return err
    }
    defer resp.Body.Close()
    return nil
}

err := backoff.Retry(operation, backoff.NewExponentialBackOff())

# Java - Spring Retry
@Retryable(
    value = {RestClientException.class},
    maxAttempts = 3,
    backoff = @Backoff(delay = 1000, multiplier = 2)
)
public String callExternalApi(Data data) {
    return restTemplate.postForObject(url, data, String.class);
}

# Scala - cats-retry
import retry._

retryingOnSomeErrors(
    policy = RetryPolicies.exponentialBackoff[IO](1.second),
    isWorthRetrying = _.isInstanceOf[IOException]
) {
    callExternalApi(data)
}

```

**References**:
- https://github.com/jd/tenacity
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/

---

### 5. ⚠️ Health & Readiness Endpoints (WARNING)

**Pattern ID**: `health_readiness`  
**Priority**: 5  
**Confidence**: 90%%  
**Source**: Kubernetes operational requirement  

**Description**: Service must expose /health and /ready endpoints for Kubernetes probes

**Impact**:
- Kubernetes cannot verify service health
- Traffic routed to unhealthy pods
- Failed deployments not detected automatically
- Manual intervention required during rollouts
- Increased MTTR (Mean Time To Recovery)


**Fix**: Add /health (liveness) and /ready (readiness) endpoints

**Example**:
```
# Python - Flask
@app.route('/health')
def health():
    """Liveness probe - is the service running?"""
    return jsonify({"status": "ok"}), 200

@app.route('/ready')
def readiness():
    """Readiness probe - can service handle traffic?"""
    try:
        db.execute("SELECT 1")
        cache.ping()
        return jsonify({"status": "ready"}), 200
    except Exception as e:
        return jsonify({"status": "not ready"}), 503

# Go - HTTP
func healthHandler(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    w.Write([]byte(`{"status":"ok"}`))
}

func readyHandler(w http.ResponseWriter, r *http.Request) {
    ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
    defer cancel()

    if err := db.PingContext(ctx); err != nil {
        w.WriteHeader(http.StatusServiceUnavailable)
        return
    }
    w.WriteHeader(http.StatusOK)
}

# Java - Spring Boot
@RestController
public class HealthController {
    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        return ResponseEntity.ok(Map.of("status", "ok"));
    }

    @GetMapping("/ready")
    public ResponseEntity<Map<String, String>> ready() {
        try {
            jdbcTemplate.queryForObject("SELECT 1", Integer.class);
            return ResponseEntity.ok(Map.of("status", "ready"));
        } catch (Exception e) {
            return ResponseEntity.status(503)
                .body(Map.of("status", "not ready"));
        }
    }
}

```

**References**:
- https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

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
🔍 SRE Top 5: SRE Checks (Reliability & Resilience) Results

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

- This skill is auto-generated from `mappings/sre-top5-patterns.yaml`
- Enabled patterns controlled by `mappings/enabled-patterns.yaml`
- To update: modify YAML and run `make generate`
- Multi-language support: Python, Go, Java, Scala
- Observability stack: Prometheus (metrics), SUMO Logic (logging)
