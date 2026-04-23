---
name: sre-reliability-resilience-check
description: Check service for reliability and resilience patterns
version: 3.0.0
category: sre_reliability_resilience
auto-generated: true
---

# SRE Reliability & Resilience Check Skill

**Version**: 3.0.0
**Last Updated**: 2026-04-15
**Category**: Reliability & Resilience

## Purpose

Patterns to prevent outages and ensure resilient service behavior

This skill checks for **5 patterns** in this category.

## Usage

When invoked, analyze the codebase and check for the following patterns:

---

### 1. 🟡 Timeout Protection (WARNING)

**Pattern ID**: `timeout_protection`  
**Priority**: 1  
**Source**: Service Maturity Pattern #13  

**Description**: All external calls (HTTP, gRPC, database) must have timeout protection

**Impact**:
- Service can hang indefinitely waiting for responses
- Thread/goroutine pool exhaustion under load
- Cascading failures across microservices
- Unable to meet SLOs during dependency slowdowns


**Fix**: Add timeout parameter to all external calls

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

# Go - Database with context
// ✅ GOOD - Context with timeout
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()
rows, err := db.QueryContext(ctx, query, args...)

```

**References**:
- https://requests.readthedocs.io/en/latest/user/advanced/#timeouts
- https://pkg.go.dev/net/http#Client

---

### 2. 🟡 Panic Recovery in Goroutines (WARNING)

**Pattern ID**: `panic_recovery`  
**Priority**: 2  
**Source**: Production reliability best practice  

**Description**: All goroutines must have defer recover() to prevent service crashes

**Impact**:
- A panic in ANY goroutine crashes the ENTIRE service
- No graceful degradation - complete service failure
- Lost in-flight requests and connections
- Difficult to debug root cause without recovery logging


**Fix**: Add defer recover() with logging at the start of every goroutine

**Example**:
```
// ❌ BAD - No recovery
go func() {
    processData(item) // If this panics, entire service crashes
}()

// ✅ GOOD - With recovery
go func() {
    defer func() {
        if r := recover(); r != nil {
            log.Error().
                Interface("panic", r).
                Str("stack", string(debug.Stack())).
                Msg("Recovered from panic in goroutine")
        }
    }()
    processData(item)
}()

// ✅ BETTER - Reusable recovery middleware
func withRecover(fn func()) {
    go func() {
        defer func() {
            if r := recover(); r != nil {
                log.Error().
                    Interface("panic", r).
                    Str("stack", string(debug.Stack())).
                    Msg("Recovered from panic")
            }
        }()
        fn()
    }()
}

// Usage
withRecover(func() {
    processData(item)
})

```

**References**:
- https://go.dev/blog/defer-panic-and-recover

---

### 3. 🟡 Resource Leak Prevention (WARNING)

**Pattern ID**: `resource_not_closed`  
**Priority**: 3  
**Source**: Production reliability best practice  

**Description**: All resources (connections, files, HTTP responses) must be properly closed

**Impact**:
- Connection pool exhaustion (cannot open new connections)
- File descriptor leaks (hitting OS limits)
- Memory leaks from unclosed HTTP response bodies
- Service degradation over time, requiring restarts


**Fix**: Use defer in Go or context managers in Python to ensure resources are closed

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

# Go - Database
// ❌ BAD - Rows not closed
rows, err := db.Query(query)
for rows.Next() {
    // process
}

// ✅ GOOD - Rows closed with defer
rows, err := db.Query(query)
if err != nil {
    return err
}
defer rows.Close()
for rows.Next() {
    // process
}

# Python - Files
# ❌ BAD - File not closed
f = open('file.txt', 'r')
data = f.read()

# ✅ GOOD - Context manager ensures close
with open('file.txt', 'r') as f:
    data = f.read()

```

**References**:
- https://go.dev/doc/effective_go#defer

---

### 4. 🟡 Circuit Breaker for External Services (WARNING)

**Pattern ID**: `circuit_breaker`  
**Priority**: 4  
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

# Configure circuit breaker
payment_breaker = CircuitBreaker(
    fail_max=5,              # Open circuit after 5 failures
    timeout_duration=60,     # Try again after 60 seconds
    reset_timeout=30         # Half-open after 30 seconds
)

@payment_breaker
def call_payment_gateway(data):
    response = requests.post(
        PAYMENT_API_URL,
        json=data,
        timeout=10
    )
    return response.json()

# Go - gobreaker
import "github.com/sony/gobreaker"

cb := gobreaker.NewCircuitBreaker(gobreaker.Settings{
    Name:        "payment-api",
    MaxRequests: 3,
    Interval:    time.Minute,
    Timeout:     time.Minute,
    ReadyToTrip: func(counts gobreaker.Counts) bool {
        return counts.ConsecutiveFailures > 5
    },
})

// Use circuit breaker
result, err := cb.Execute(func() (interface{}, error) {
    return http.Get(paymentAPIURL)
})

```

**References**:
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://github.com/sony/gobreaker

---

### 5. 🟡 Health & Readiness Endpoints (WARNING)

**Pattern ID**: `missing_health_endpoint`  
**Priority**: 5  
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
    """Readiness probe - can the service handle traffic?"""
    try:
        # Check dependencies
        db.execute("SELECT 1")
        cache.ping()

        return jsonify({"status": "ready"}), 200
    except Exception as e:
        logger.error(f"Readiness check failed: {e}")
        return jsonify({"status": "not ready", "error": str(e)}), 503

# Go - HTTP
func healthHandler(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    w.Write([]byte(`{"status":"ok"}`))
}

func readyHandler(w http.ResponseWriter, r *http.Request) {
    // Check database
    ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
    defer cancel()

    if err := db.PingContext(ctx); err != nil {
        w.WriteHeader(http.StatusServiceUnavailable)
        w.Write([]byte(`{"status":"not ready"}`))
        return
    }

    w.WriteHeader(http.StatusOK)
    w.Write([]byte(`{"status":"ready"}`))
}

# Kubernetes manifest
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5

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
🔍 SRE Reliability & Resilience Check Results

✅ SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Patterns Checked: 5
Status: ⚠️  WARN - 1 critical issue, 2 warnings found

🔴 CRITICAL ISSUES (1)

1. [Health & Readiness Endpoints] SQL Injection Risk
   File: handlers/user_handler.py:45
   Issue: String concatenation in SQL query
   Fix: Use parameterized query with placeholders

   ❌ BAD:
   query = f"SELECT * FROM users WHERE id = {user_id}"

   ✅ GOOD:
   query = "SELECT * FROM users WHERE id = %s"
   cursor.execute(query, (user_id,))

🟡 WARNINGS (2)

1. [Timeout Protection] Missing timeout on HTTP call
   File: services/payment_service.py:78
   Fix: Add timeout=10 parameter to requests.post()

2. [Central Logging] Error returned without logging
   File: handlers/checkout.go:123
   Fix: Add log.Error() before returning error

📋 NEXT STEPS
1. Fix critical SQL injection issue immediately
2. Add timeouts to external API calls
3. Implement structured logging for errors
4. Re-run check to verify fixes
```

## Notes

- This skill is auto-generated from `mappings/sre_reliability_resilience-patterns.yaml`
- Enabled patterns controlled by `mappings/enabled-patterns.yaml`
- To update: modify YAML and run `make generate`
