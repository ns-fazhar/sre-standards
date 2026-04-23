# SRE Standards - Central Control Repository

**Version**: 4.0.0  
**Owner**: SRE Team  
**Purpose**: Single source of truth for SRE standards - Update once, distribute everywhere

---

## 🎯 What Is This?

**SRE Standards** is a **centralized control repository** that defines, generates, and distributes SRE checks to all services across the organization. 

Think of it as a **broadcast tower** 📡:
- SRE Team updates standards **once** in this repo
- All service repos automatically get updates via `@main` references
- **Zero file copying, zero drift, zero maintenance for developers**

### Key Innovation: Zero-Sync Distribution

```
┌─────────────────────────────────────────────────────────────┐
│                    sre-standards (Central)                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  1 YAML file → Auto-generates:                       │  │
│  │     • Shell scripts for CI/CD                        │  │
│  │     • GitHub Actions workflows                       │  │
│  │     • Claude AI skills                               │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              │ Referenced via @main
                              │
        ┌─────────────────────┼─────────────────────┐
        ↓                     ↓                     ↓
  ┌──────────┐          ┌──────────┐          ┌──────────┐
  │ Service  │          │ Service  │          │ Service  │
  │    A     │          │    B     │          │    C     │
  └──────────┘          └──────────┘          └──────────┘
  1 workflow file       1 workflow file       1 workflow file
  (never changes)       (never changes)       (never changes)
```

**No manual sync required** - services always pull latest checks from central repo.

---

## 📊 For Service Owners (Developers)

### Quick Start: 3 Steps to Enable SRE Checks

#### Step 1: Add ONE Workflow File

Create `.github/workflows/sre-checks.yml` in your service repo:

```yaml
name: SRE Checks

on:
  pull_request:
    branches: [main, develop]

jobs:
  sre-standard-checks:
    permissions:
      contents: read
      pull-requests: write
    uses: ns-fazhar/sre-standards/.github/workflows/sre-standard-checks.yml@main
    with:
      fail_on_issues: false  # Set true to block PRs with critical issues
```

**That's it!** This file never needs updating - it references central repo `@main`.

#### Step 2: Add NPI Workflow (Optional - For Feature Validation)

Create `.github/workflows/npi-checks.yml`:

```yaml
name: NPI Checks (On-Demand)

on:
  workflow_dispatch:
    inputs:
      base_branch:
        description: 'Base branch to compare against'
        default: 'main'
        type: string

jobs:
  npi-validation:
    permissions:
      contents: read
      pull-requests: write
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Fetch base branch
        run: |
          git fetch origin "${{ inputs.base_branch }}:${{ inputs.base_branch }}"
      - uses: actions/checkout@v4
        with:
          repository: ns-fazhar/sre-standards
          path: .sre-standards
          ref: main
      - name: Run NPI checks
        run: .sre-standards/generated/check-npi-top5.sh
```

#### Step 3: Commit and Push

```bash
git add .github/workflows/
git commit -m "Add SRE standard checks"
git push
```

### What You Get Automatically

On **every PR**, GitHub Actions runs **3 checks in parallel**:

1. **🔧 SRE Checks (Reliability & Resilience)**
   - HTTP timeouts, circuit breakers, resource leaks, retries, health endpoints

2. **⚙️ Operability**
   - No hardcoded secrets, graceful shutdown, Dockerfile, config validation

3. **📊 Observability**  
   - Prometheus metrics, SUMO logging, request tracking, metrics endpoint

**Results**: ONE consolidated PR comment with summary + collapsible details per check.

### On-Demand Feature Validation

For **new features** on feature branches, run **NPI checks** manually:

4. **🚀 NPI (New Product Introduction)**
   - SQL injection prevention, feature flags, migrations, breaking changes, test coverage
   - Run via: GitHub Actions UI → "NPI Checks (On-Demand)" → Select feature branch

---

## 🛠️ For SRE Team: How to Control Standards

### Repository Structure

```
sre-standards/
├── mappings/
│   └── sre-top5-patterns.yaml       ← SINGLE SOURCE OF TRUTH
├── generated/                       ← Auto-generated (don't edit)
│   ├── check-sre-top5.sh
│   ├── check-operability-top5.sh
│   ├── check-observability-top5.sh
│   └── check-npi-top5.sh
├── skills/                          ← Auto-generated (don't edit)
│   ├── sre-checks-top5.md
│   ├── operability-top5.md
│   ├── observability-top5.md
│   └── npi-top5.md
├── .github/workflows/               ← Reusable workflows
│   ├── sre-standard-checks.yml      ← Services reference this @main
│   └── npi-checks-manual.yml        ← Template for services
├── generators/
│   └── generate-top5-patterns.py    ← Generator script
└── VERSION                          ← Current version
```

### How to Update Standards (4 Steps)

#### 1. Edit the Pattern File

```bash
cd sre-standards
vim mappings/sre-top5-patterns.yaml
```

Add or modify a check:

```yaml
sre_checks:
  patterns:
    - id: rate-limiting
      name: "Rate Limiting"
      severity: blocking
      confidence: high
      
      automation:
        pattern: 'rate_limit|RateLimiter|@ratelimit'
        languages:
          python: 'flask_limiter|ratelimit'
          go: 'golang.org/x/time/rate'
          java: 'RateLimiter|Bucket4j'
      
      guidance:
        description: "Prevent DoS attacks with rate limiting"
        impact: "Without rate limiting, services are vulnerable to abuse"
        fix: "Add rate limiting middleware to all public endpoints"
        example: |
          # Python (Flask)
          from flask_limiter import Limiter
          limiter = Limiter(app, default_limits=["100/hour"])
```

#### 2. Generate Scripts and Skills

```bash
make generate
```

Output:
```
✅ Generated generated/check-sre-top5.sh
✅ Generated generated/check-operability-top5.sh
✅ Generated generated/check-observability-top5.sh
✅ Generated generated/check-npi-top5.sh
✅ Generated skills/sre-checks-top5.md
✅ Generated skills/operability-top5.md
✅ Generated skills/observability-top5.md
✅ Generated skills/npi-top5.md
```

#### 3. Test Locally

```bash
# Test against sample service
cd ../payment-service
make sre-check-all
```

#### 4. Commit and Push

```bash
git add mappings/ generated/ skills/
git commit -m "Add rate limiting check to SRE standards"
git push
```

**🎉 Done!** All services automatically get the new check on their next PR.

### Why This Works

- Services reference `sre-standards/.github/workflows/sre-standard-checks.yml@main`
- The workflow always pulls latest scripts from `@main`
- No need to update 50+ service repos individually
- Changes propagate instantly

---

## 📋 Current Checks (v4.0.0)

### 🔧 SRE Checks (Reliability & Resilience) - 5 Patterns
| Pattern | Severity | Languages |
|---------|----------|-----------|
| HTTP Timeout Protection | ✅ Blocking | Python, Go, Java, Scala |
| Circuit Breaker | ✅ Blocking | Python, Go, Java, Scala |
| Resource Leak Prevention | ⚠️ Warning | Python, Go, Java |
| Retry with Exponential Backoff | ⚠️ Warning | Python, Go, Java, Scala |
| Health & Readiness Endpoints | ✅ Blocking | All |

### ⚙️ Operability - 5 Patterns
| Pattern | Severity | Languages |
|---------|----------|-----------|
| No Hardcoded Secrets | 🔴 Critical | All |
| Graceful Shutdown | ✅ Blocking | Python, Go, Java |
| Environment Variables Documented | ℹ️ Info | All |
| Dockerfile Present | ✅ Blocking | All |
| Configuration Validation | ⚠️ Warning | Python, Go, Java |

### 📊 Observability - 5 Patterns
| Pattern | Severity | Stack |
|---------|----------|-------|
| Prometheus Metrics Instrumentation | ✅ Blocking | Prometheus |
| Metrics Endpoint | ⚠️ Warning | Prometheus |
| Central Error Logging | ✅ Blocking | SUMO Logic |
| Request Duration Tracking | ⚠️ Warning | Prometheus |
| Request ID Propagation | ⚠️ Warning | All |

### 🚀 NPI (New Product Introduction) - 5 Patterns
| Pattern | Severity | Languages |
|---------|----------|-----------|
| SQL Injection Prevention | 🔴 Critical | Python, Go, Java, Scala |
| Feature Flag for New Features | ✅ Blocking | All |
| Database Schema Changes with Migration | ✅ Blocking | All |
| API Breaking Changes Detection | ⚠️ Warning | All |
| Test Coverage for New Code | ⚠️ Warning | All |

**Legend**: 🔴 Critical | ✅ Blocking | ⚠️ Warning | ℹ️ Info

---

## 🎯 Execution Model

### Automatic on ALL PRs (3 Checks)
- Target: **Entire codebase**
- Runs: Every PR automatically
- Results: ONE consolidated PR comment

```
PR Created → 3 Parallel Checks → 1 Consolidated Comment
              ├─ SRE Checks
              ├─ Operability  
              └─ Observability
```

### On-Demand (1 Check)
- Target: **Changed files only**
- Runs: Manual trigger via GitHub Actions UI
- Best for: Feature branch validation before merge

```
Manual Trigger → NPI Checks → Changed files vs. main branch
```

---

## 🔄 Zero-Sync Benefits

### For Developers
✅ **One-time setup** - Add 1 workflow file, never update it  
✅ **Always current** - Automatically uses latest standards  
✅ **No maintenance** - SRE team handles all updates  
✅ **Fast feedback** - Results in PR comments within 1 minute  
✅ **Local testing** - Run same checks via Makefile before pushing

### For SRE Team
✅ **Single source of truth** - 1 YAML file controls all checks  
✅ **Instant distribution** - Update once, affects all services immediately  
✅ **Version control** - All changes tracked in git  
✅ **Easy rollback** - Revert commit to undo changes  
✅ **No coordination overhead** - No need to update 50+ service repos

---

## 📖 Local Development

### Add Makefile Targets (Optional)

```makefile
# Run all checks locally before pushing
sre-check-all:
	@curl -fsSL https://raw.githubusercontent.com/ns-fazhar/sre-standards/main/generated/check-sre-top5.sh | bash
	@curl -fsSL https://raw.githubusercontent.com/ns-fazhar/sre-standards/main/generated/check-operability-top5.sh | bash
	@curl -fsSL https://raw.githubusercontent.com/ns-fazhar/sre-standards/main/generated/check-observability-top5.sh | bash

# Individual checks
sre-check:
	@curl -fsSL https://raw.githubusercontent.com/ns-fazhar/sre-standards/main/generated/check-sre-top5.sh | bash

operability-check:
	@curl -fsSL https://raw.githubusercontent.com/ns-fazhar/sre-standards/main/generated/check-operability-top5.sh | bash

observability-check:
	@curl -fsSL https://raw.githubusercontent.com/ns-fazhar/sre-standards/main/generated/check-observability-top5.sh | bash

npi-check:
	@curl -fsSL https://raw.githubusercontent.com/ns-fazhar/sre-standards/main/generated/check-npi-top5.sh | bash
```

Usage:
```bash
make sre-check-all  # Before committing
make npi-check      # On feature branches
```

---

## 📞 Support

- **Questions**: #sre-standards Slack channel
- **Issues**: [GitHub Issues](https://github.com/ns-fazhar/sre-standards/issues)
- **Documentation**: This README + inline comments in workflow files

---

## 🚀 Quick Reference

### For Developers
```bash
# 1. Add workflow file (one-time)
curl -o .github/workflows/sre-checks.yml \
  https://raw.githubusercontent.com/ns-fazhar/sre-standards/main/templates/service-sre-checks.yml

# 2. Commit and push
git add .github/workflows/sre-checks.yml
git commit -m "Enable SRE standard checks"
git push

# 3. Done! PR checks now run automatically
```

### For SRE Team
```bash
# 1. Edit standards
vim mappings/sre-top5-patterns.yaml

# 2. Generate scripts
make generate

# 3. Test and push
make test
git add .
git commit -m "Update SRE standards"
git push

# 4. All services get updates automatically
```

---

**Maintained by**: SRE Team  
**Version**: 4.0.0  
**Last Updated**: 2026-04-23
