---
name: operability-check
description: Check if service meets SRE operability requirements
version: 2.1.0
auto-generated: true
---

# SRE Operability Check Skill

Version: 2.1.0
Last updated: 2026-03-26

## Purpose

This skill checks if a service meets production readiness requirements across:
- **Observability**: Can we monitor it?
- **Reliability**: Will it fail safely?
- **Deployment**: Can we deploy it safely?
- **Security**: Is it secure?
- **Documentation**: Can someone else operate it?

## Usage

When invoked, analyze the codebase and check for the following requirements:


### Observability

**🔴 Readiness Endpoint** (BLOCKING)

Service must have /ready endpoint for Kubernetes readiness probes

**Impact**: - Kubernetes cannot verify if service dependencies are ready
- May route traffic to unhealthy pods during startup
- Cascading failures during rolling deployments


**Fix**: Add readiness endpoint that checks all dependencies (DB, cache, APIs)

**Example**:
```python
@app.route('/ready')
def readiness():
    \"\"\"Check if service and dependencies are ready\"\"\"
    try:
        # Check database
        db.execute("SELECT 1")

        # Check cache
        cache.ping()

        # Check critical APIs
        requests.get("https://api.example.com/health", timeout=5)

        return jsonify({"status": "ready"}), 200
    except Exception as e:
        logger.error(f"Readiness check failed: {e}")
        return jsonify({"status": "not ready", "error": str(e)}), 503

```

---

**🟡 Health Endpoint** (WARNING)

Basic health/liveness check endpoint

**Impact**: Load balancers and K8s cannot verify service is alive

**Fix**: Add /health endpoint for liveness probes

**Example**:
```python
@app.route('/health')
def health():
    return jsonify({"status": "ok"}), 200

```

---

**🟡 Metrics Endpoint** (WARNING)

Prometheus-compatible metrics endpoint

**Impact**: No visibility into service performance, cannot create alerts

**Fix**: Add /metrics endpoint exposing Prometheus metrics

**Example**:
```python
# Python
from prometheus_flask_exporter import PrometheusMetrics
metrics = PrometheusMetrics(app)

# Go
import "github.com/prometheus/client_golang/prometheus/promhttp"
http.Handle("/metrics", promhttp.Handler())

```

---

**🟡 Structured Logging** (WARNING)

Use structured (JSON) logging for easy parsing

**Impact**: Difficult to search/filter logs in production

**Fix**: Use structured logging library

**Example**:
```python
# Python
from pythonjsonlogger import jsonlogger
handler = logging.StreamHandler()
handler.setFormatter(jsonlogger.JsonFormatter())

```

---


### Reliability

**🔴 HTTP Timeouts** (BLOCKING)

All HTTP calls must have timeout parameters

**Impact**: - Service can hang indefinitely waiting for responses
- Thread pool exhaustion
- Cascading failures across microservices


**Fix**: Add timeout parameter to all HTTP calls

**Example**:
```python
# ❌ BAD - No timeout
response = requests.post(url, json=data)

# ✅ GOOD - With timeout
response = requests.post(url, json=data, timeout=30)

# ✅ BETTER - Separate connect/read timeouts
response = requests.post(url, json=data, timeout=(5, 30))

```

---

**🔴 Circuit Breaker** (BLOCKING)

Protect against cascading failures with circuit breaker pattern

**Impact**: - Repeated calls to failing services waste resources
- No automatic recovery mechanism
- Cascading failures across services


**Fix**: Implement circuit breaker for external service calls

**Example**:
```python
# Python
from pybreaker import CircuitBreaker

payment_breaker = CircuitBreaker(
    fail_max=5,           # Open after 5 failures
    timeout_duration=60   # Try again after 60 seconds
)

@payment_breaker
def call_payment_gateway(data):
    return requests.post(url, json=data, timeout=30)

```

---

**🟡 Error Handling** (WARNING)

Proper error handling to prevent crashes

**Impact**: Unhandled exceptions crash the service

**Fix**: Add try/catch blocks around critical operations

---


### Deployment

**🟡 Dockerfile** (WARNING)

Service should have Dockerfile for containerization

**Impact**: Cannot deploy to Kubernetes

**Fix**: Create Dockerfile with proper base image and security

---

**🟡 Kubernetes Manifests** (WARNING)

K8s deployment manifests in repository

**Impact**: Deployment configuration not version controlled

**Fix**: Add K8s manifests to repository

---


### Security

**🟡 Dependency Management** (WARNING)

Dependencies should be declared and version-pinned

**Impact**: Cannot track or update vulnerable dependencies

**Fix**: Create requirements.txt or equivalent

---

**🔴 No Hardcoded Secrets** (BLOCKING)

No hardcoded passwords or API keys

**Impact**: Security breach if code is exposed

**Fix**: Use environment variables or secret management

---


### Documentation

**🟡 README** (WARNING)

Service must have README documentation

**Impact**: New team members cannot understand the service

**Fix**: Create README.md with setup and usage instructions

---

**🔴 Runbook** (BLOCKING)

Operational runbook for on-call engineers

**Impact**: On-call cannot respond to incidents effectively

**Fix**: Create RUNBOOK.md with troubleshooting steps

**Example**:
```python
# Service Runbook

## Common Issues

### High Latency
- Check: Database connections
- Action: Scale up replicas
- Dashboard: grafana.com/d/service-latency

### 500 Errors
- Check: External API health
- Action: Enable circuit breaker
- Logs: kubectl logs -l app=myservice

```

---


## Output Format

Provide a clear assessment with:

1. **Summary**: Overall verdict (GO/NO-GO)
2. **Blocking Issues**: Must-fix items with file:line references
3. **Warnings**: Recommended improvements
4. **Next Steps**: Specific actions to take

## Example Output

```
🔍 SRE Operability Check Results

❌ NO-GO - Found 3 blocking issues

BLOCKING ISSUES:
1. No readiness endpoint found
   → Add @app.route('/ready') in app.py

2. HTTP calls without timeouts (app.py:30)
   → Add timeout=30 to requests.post()

3. No circuit breaker for external calls
   → Install pybreaker and wrap payment gateway calls

WARNINGS:
- No /metrics endpoint (consider adding Prometheus metrics)
- README exists but no runbook found

NEXT STEPS:
1. Fix blocking issues above
2. Re-run check to verify
3. Consider addressing warnings before production
```
