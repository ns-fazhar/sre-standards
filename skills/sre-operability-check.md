---
name: sre-operability-check
description: Check service for operability patterns
version: 3.0.0
category: sre_operability
auto-generated: true
---

# SRE Operability Check Skill

**Version**: 3.0.0
**Last Updated**: 2026-04-15
**Category**: Operability

## Purpose

Patterns to ensure services can be operated, debugged, and maintained

This skill checks for **5 patterns** in this category.

## Usage

When invoked, analyze the codebase and check for the following patterns:

---

### 1. 🔴 No Hardcoded Secrets (CRITICAL)

**Pattern ID**: `secrets_management`  
**Priority**: 1  
**Source**: Security compliance requirement  

**Description**: Never hardcode secrets, passwords, or API keys in source code

**Impact**:
- CRITICAL SECURITY RISK - credentials exposed in git history
- Potential data breach if code is leaked
- Compliance violations (PCI-DSS, SOC2, GDPR)
- Credential rotation requires code changes and deployment
- Cannot use different secrets for dev/staging/prod


**Fix**: Use environment variables or secret management systems (Vault, AWS Secrets Manager)

**Example**:
```
# ❌ BAD - Hardcoded secrets
API_KEY = "sk_live_abc123xyz789"
DB_PASSWORD = "MyP@ssw0rd123"
AWS_SECRET = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"

# ✅ GOOD - Environment variables
import os

API_KEY = os.getenv('STRIPE_API_KEY')
DB_PASSWORD = os.getenv('DB_PASSWORD')
AWS_SECRET = os.getenv('AWS_SECRET_ACCESS_KEY')

if not API_KEY:
    raise ValueError("STRIPE_API_KEY environment variable not set")

# ✅ BETTER - Secrets manager
import boto3

def get_secret(secret_name):
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response['SecretString'])

secrets = get_secret('prod/myservice/credentials')
API_KEY = secrets['stripe_api_key']
DB_PASSWORD = secrets['db_password']

# Go - Environment variables
apiKey := os.Getenv("STRIPE_API_KEY")
if apiKey == "" {
    log.Fatal("STRIPE_API_KEY environment variable not set")
}

```

**References**:
- https://12factor.net/config
- https://docs.aws.amazon.com/secretsmanager/

---

### 2. 🟡 Graceful Shutdown (WARNING)

**Pattern ID**: `no_graceful_shutdown`  
**Priority**: 2  
**Source**: NPI Row 55 - Operational concerns  

**Description**: Service must handle SIGTERM gracefully to avoid dropping in-flight requests

**Impact**:
- In-flight requests dropped during deployment
- Database transactions incomplete
- WebSocket connections abruptly closed
- Poor user experience during rolling updates
- Failed requests during pod termination


**Fix**: Implement signal handlers to gracefully drain connections before shutdown

**Example**:
```
# Python - Flask with graceful shutdown
import signal
import sys

class GracefulShutdown:
    def __init__(self):
        self.shutdown_requested = False
        signal.signal(signal.SIGTERM, self.request_shutdown)
        signal.signal(signal.SIGINT, self.request_shutdown)

    def request_shutdown(self, signum, frame):
        logger.info("Shutdown signal received, draining connections...")
        self.shutdown_requested = True

shutdown_handler = GracefulShutdown()

def run_server():
    app.run(host='0.0.0.0', port=8080)

# Go - HTTP server with graceful shutdown
package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"
)

func main() {
    server := &http.Server{
        Addr:    ":8080",
        Handler: router,
    }

    // Start server in goroutine
    go func() {
        if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatalf("Server failed: %v", err)
        }
    }()

    // Wait for interrupt signal
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    log.Println("Shutting down server gracefully...")

    // Give in-flight requests 30 seconds to complete
    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()

    if err := server.Shutdown(ctx); err != nil {
        log.Fatal("Server forced to shutdown:", err)
    }

    log.Println("Server exited")
}

# Kubernetes - configure terminationGracePeriodSeconds
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      terminationGracePeriodSeconds: 30  # Match shutdown timeout
      containers:
      - name: myservice
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 5"]  # Allow load balancer to deregister

```

**References**:
- https://cloud.google.com/blog/products/containers-kubernetes/kubernetes-best-practices-terminating-with-grace

---

### 3. ℹ️ Environment Variables Documented (INFO)

**Pattern ID**: `env_vars_undocumented`  
**Priority**: 3  
**Source**: Onboarding and operational clarity  

**Description**: All environment variables must be documented in .env.example or README

**Impact**:
- New developers cannot run the service locally
- Missing configuration causes runtime errors
- Difficult onboarding experience
- Deployment failures in new environments
- Unclear configuration requirements


**Fix**: Create .env.example with all required environment variables and descriptions

**Example**:
```
# .env.example
# Copy this to .env and fill in actual values

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=myservice
DB_USER=postgres
DB_PASSWORD=changeme

# External APIs
STRIPE_API_KEY=sk_test_...
SENDGRID_API_KEY=SG....

# Service Configuration
PORT=8080
LOG_LEVEL=info
ENVIRONMENT=development

# Optional - defaults provided if not set
REDIS_URL=redis://localhost:6379
MAX_WORKERS=4

# README.md
## Configuration

Copy `.env.example` to `.env` and configure:

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DB_HOST` | Yes | - | PostgreSQL host |
| `DB_PASSWORD` | Yes | - | Database password |
| `STRIPE_API_KEY` | Yes | - | Stripe API key (get from dashboard) |
| `PORT` | No | 8080 | HTTP server port |
| `LOG_LEVEL` | No | info | Logging level (debug/info/warn/error) |

```

**References**:
- https://12factor.net/config

---

### 4. 🟡 Dockerfile Present (WARNING)

**Pattern ID**: `missing_dockerfile`  
**Priority**: 4  
**Source**: Containerization standard  

**Description**: Service must have Dockerfile for containerization and Kubernetes deployment

**Impact**:
- Cannot deploy to Kubernetes
- Inconsistent runtime environments
- Manual deployment process required
- Cannot use CI/CD pipelines
- Dev/prod parity issues


**Fix**: Create Dockerfile with best practices (multi-stage, non-root user, security)

**Example**:
```
# Python - Multi-stage Dockerfile
# Build stage
FROM python:3.11-slim as builder

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Runtime stage
FROM python:3.11-slim

# Create non-root user
RUN useradd -m -u 1000 appuser

WORKDIR /app

# Copy installed dependencies from builder
COPY --from=builder /root/.local /home/appuser/.local

# Copy application code
COPY --chown=appuser:appuser . .

# Switch to non-root user
USER appuser

# Update PATH
ENV PATH=/home/appuser/.local/bin:$PATH

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import requests; requests.get('http://localhost:8080/health')"

CMD ["python", "app.py"]

# Go - Multi-stage Dockerfile
# Build stage
FROM golang:1.21 as builder

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source
COPY . .

# Build binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Runtime stage
FROM alpine:latest

# Install ca-certificates for HTTPS
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy binary from builder
COPY --from=builder /app/main .

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

CMD ["./main"]

```

**References**:
- https://docs.docker.com/develop/develop-images/dockerfile_best-practices/

---

### 5. ℹ️ Configuration Validation (INFO)

**Pattern ID**: `config_not_validated`  
**Priority**: 5  
**Source**: Runtime error prevention  

**Description**: Validate configuration at startup to fail fast on invalid config

**Impact**:
- Runtime errors from invalid configuration
- Service starts but fails during operation
- Difficult to debug config issues
- Delayed error detection (after deployment)
- Unclear configuration requirements


**Fix**: Add validation schema and validate config at startup

**Example**:
```
# Python - Pydantic for validation
from pydantic import BaseSettings, Field, validator

class Config(BaseSettings):
    # Database
    db_host: str
    db_port: int = Field(ge=1, le=65535)
    db_name: str

    # API Keys (validated format)
    stripe_api_key: str = Field(regex=r'^sk_(test|live)_[A-Za-z0-9]+$')

    # Timeout (must be positive)
    request_timeout: int = Field(default=30, ge=1, le=300)

    @validator('db_host')
    def validate_db_host(cls, v):
        if not v:
            raise ValueError('db_host cannot be empty')
        return v

    class Config:
        env_file = '.env'

# Load and validate
try:
    config = Config()
    print(f"✅ Configuration valid: {config}")
except Exception as e:
    print(f"❌ Configuration error: {e}")
    sys.exit(1)

# Go - go-playground/validator
import "github.com/go-playground/validator/v10"

type Config struct {
    DBHost          string `validate:"required,hostname"`
    DBPort          int    `validate:"required,min=1,max=65535"`
    DBName          string `validate:"required"`
    StripeAPIKey    string `validate:"required,startswith=sk_"`
    RequestTimeout  int    `validate:"min=1,max=300"`
}

func LoadConfig() (*Config, error) {
    config := &Config{}

    // Load from env/file
    // ... load logic ...

    // Validate
    validate := validator.New()
    if err := validate.Struct(config); err != nil {
        return nil, fmt.Errorf("config validation failed: %w", err)
    }

    return config, nil
}

func main() {
    config, err := LoadConfig()
    if err != nil {
        log.Fatalf("Configuration error: %v", err)
    }
    log.Printf("✅ Configuration loaded successfully")
}

```

**References**:
- https://pydantic-docs.helpmanual.io/
- https://github.com/go-playground/validator

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
🔍 SRE Operability Check Results

✅ SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Patterns Checked: 5
Status: ⚠️  WARN - 1 critical issue, 2 warnings found

🔴 CRITICAL ISSUES (1)

1. [Configuration Validation] SQL Injection Risk
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

- This skill is auto-generated from `mappings/sre_operability-patterns.yaml`
- Enabled patterns controlled by `mappings/enabled-patterns.yaml`
- To update: modify YAML and run `make generate`
