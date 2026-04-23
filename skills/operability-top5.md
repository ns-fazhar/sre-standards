---
name: operability-top5
description: Top 5 operability patterns - ensure maintainable services
version: 1.0.0
category: top5_operability
auto-generated: true
languages: python, go, java, scala
---

# SRE Top 5: Operability

**Version**: 1.0.0
**Last Updated**: 2026-04-23
**Languages**: python, go, java, scala

## Purpose

Patterns to ensure services can be operated, debugged, and maintained

**Confidence Level**: High (75-99% across patterns)

This skill checks for the **Top 5 most critical patterns** in this category.

## Usage

When invoked, analyze the codebase and check for the following patterns:

---

### 1. 🔴 No Hardcoded Secrets (CRITICAL)

**Pattern ID**: `no_hardcoded_secrets`  
**Priority**: 1  
**Confidence**: 99%%  
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

# Go - Environment variables
apiKey := os.Getenv("STRIPE_API_KEY")
if apiKey == "" {
    log.Fatal("STRIPE_API_KEY environment variable not set")
}

# Java - Environment variables
String apiKey = System.getenv("STRIPE_API_KEY");
if (apiKey == null) {
    throw new IllegalStateException("STRIPE_API_KEY not set");
}

```

**References**:
- https://12factor.net/config
- https://docs.aws.amazon.com/secretsmanager/
- https://www.vaultproject.io/

---

### 2. ⚠️ Graceful Shutdown (WARNING)

**Pattern ID**: `graceful_shutdown`  
**Priority**: 2  
**Confidence**: 85%%  
**Source**: Operational concerns - avoid dropped requests  

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
# Python - Flask
import signal
import sys

shutdown_requested = False

def shutdown_handler(signum, frame):
    global shutdown_requested
    logger.info("Shutdown signal received, draining connections...")
    shutdown_requested = True
    sys.exit(0)

signal.signal(signal.SIGTERM, shutdown_handler)
signal.signal(signal.SIGINT, shutdown_handler)

# Go - HTTP server
quit := make(chan os.Signal, 1)
signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
<-quit

log.Println("Shutting down server gracefully...")
ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
defer cancel()

if err := server.Shutdown(ctx); err != nil {
    log.Fatal("Server forced shutdown:", err)
}

# Java - Spring Boot (built-in graceful shutdown)
# application.properties
server.shutdown=graceful
spring.lifecycle.timeout-per-shutdown-phase=30s

# Or manual shutdown hook
Runtime.getRuntime().addShutdownHook(new Thread(() -> {
    logger.info("Shutdown hook triggered");
    // Drain connections
}));

```

**References**:
- https://cloud.google.com/blog/products/containers-kubernetes/kubernetes-best-practices-terminating-with-grace

---

### 3. ℹ️ Environment Variables Documented (INFO)

**Pattern ID**: `env_vars_documented`  
**Priority**: 3  
**Confidence**: 75%%  
**Source**: Onboarding and operational clarity  

**Description**: All environment variables must be documented in .env.example or README

**Impact**:
- New developers cannot run service locally
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

# README.md - Configuration table
## Configuration

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DB_HOST` | Yes | - | PostgreSQL host |
| `DB_PASSWORD` | Yes | - | Database password |
| `STRIPE_API_KEY` | Yes | - | Stripe API key |
| `PORT` | No | 8080 | HTTP server port |
| `LOG_LEVEL` | No | info | Logging level |

```

**References**:
- https://12factor.net/config

---

### 4. ⚠️ Dockerfile Present (WARNING)

**Pattern ID**: `dockerfile_present`  
**Priority**: 4  
**Confidence**: 88%%  
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
FROM python:3.11-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

FROM python:3.11-slim
RUN useradd -m -u 1000 appuser
WORKDIR /app
COPY --from=builder /root/.local /home/appuser/.local
COPY --chown=appuser:appuser . .
USER appuser
ENV PATH=/home/appuser/.local/bin:$PATH
EXPOSE 8080
HEALTHCHECK --interval=30s CMD python -c "import requests; requests.get('http://localhost:8080/health')"
CMD ["python", "app.py"]

# Go - Multi-stage Dockerfile
FROM golang:1.21 as builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/main .
EXPOSE 8080
CMD ["./main"]

# Java - Multi-stage Dockerfile
FROM maven:3.8-openjdk-17 as builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package -DskipTests

FROM openjdk:17-slim
COPY --from=builder /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]

```

**References**:
- https://docs.docker.com/develop/develop-images/dockerfile_best-practices/

---

### 5. ℹ️ Configuration Validation (INFO)

**Pattern ID**: `config_validation`  
**Priority**: 5  
**Confidence**: 78%%  
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
# Python - Pydantic
from pydantic import BaseSettings, Field, validator

class Config(BaseSettings):
    db_host: str
    db_port: int = Field(ge=1, le=65535)
    stripe_api_key: str = Field(regex=r'^sk_(test|live)_')
    request_timeout: int = Field(default=30, ge=1, le=300)

    @validator('db_host')
    def validate_db_host(cls, v):
        if not v:
            raise ValueError('db_host cannot be empty')
        return v

try:
    config = Config()
except Exception as e:
    print(f"❌ Configuration error: {e}")
    sys.exit(1)

# Go - go-playground/validator
import "github.com/go-playground/validator/v10"

type Config struct {
    DBHost         string `validate:"required,hostname"`
    DBPort         int    `validate:"required,min=1,max=65535"`
    StripeAPIKey   string `validate:"required,startswith=sk_"`
    RequestTimeout int    `validate:"min=1,max=300"`
}

validate := validator.New()
if err := validate.Struct(config); err != nil {
    log.Fatalf("Config validation failed: %v", err)
}

# Java - Spring Boot Validation
@ConfigurationProperties(prefix = "app")
@Validated
public class AppConfig {
    @NotBlank
    private String dbHost;

    @Min(1) @Max(65535)
    private int dbPort;

    @Pattern(regexp = "^sk_(test|live)_.*")
    private String stripeApiKey;
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
🔍 SRE Top 5: Operability Results

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
