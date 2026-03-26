# SRE Standards - Central Control Repository

**Version**: 2.1.0
**Owner**: SRE Team
**Purpose**: Single source of truth for SRE checks, skills, and standards

## 🎯 Overview

This repository contains:
- **Check patterns** (YAML) - Single source of truth
- **Generated scripts** - Auto-generated shell scripts for CI/CD
- **Skills** - Claude AI instructions for interactive development
- **Reusable workflows** - GitHub Actions that services can use

## 📁 Structure

```
sre-standards/
├── mappings/
│   └── check-patterns.yaml          ← EDIT THIS to add/modify checks
├── generated/
│   └── check-operability.sh         ← Auto-generated, don't edit
├── skills/
│   └── operability-check.md         ← Auto-generated, don't edit
├── .github/workflows/
│   └── sre-checks-reusable.yml      ← Used by service repos
├── generators/
│   └── generate-scripts.py          ← Generator tool
├── Makefile                         ← Your main commands
└── VERSION                          ← Current version
```

## 🔧 For SRE Team: How to Update Checks

### 1. Edit the Source of Truth

```bash
vim mappings/check-patterns.yaml

# Add a new check:
- id: rate-limiting
  name: "Rate Limiting"
  category: reliability
  severity: blocking
  automation:
    pattern: "rate_limit|RateLimiter"
    file_types: ["*.py", "*.go"]
  guidance:
    description: "Prevent DoS attacks with rate limiting"
    fix: "Add rate limiting middleware"
    example: |
      from flask_limiter import Limiter
      limiter = Limiter(app, default_limits=["100 per hour"])
```

### 2. Generate Scripts and Skills

```bash
make generate

# Output:
# ✅ Generated generated/check-operability.sh
# ✅ Generated skills/operability-check.md
```

### 3. Test

```bash
make test

# Or test manually:
cd ../some-service
../sre-standards/generated/check-operability.sh
```

### 4. Commit and Push

```bash
git add .
git commit -m "Add rate limiting check"
git push

# All services using this repo will automatically get the update!
```

## 📊 For Engineering Teams: How to Use

### Option 1: GitHub Actions (Recommended)

Add to your service repo:

```yaml
# .github/workflows/sre-checks.yml
name: SRE Checks

on: [pull_request]

jobs:
  sre:
    uses: ns-fazhar/sre-standards/.github/workflows/sre-checks-reusable.yml@main
    with:
      fail_on_issues: false  # Set true to block PRs with issues
```

**That's it!** Your PRs will automatically get SRE checks.

### Option 2: Local Development with Claude

```bash
# One-time install
curl -fsSL https://raw.githubusercontent.com/ns-fazhar/sre-standards/main/install.sh | bash

# Use in your service
cd my-service
claude code
> /operability-check

# Update to latest
sre-sync
```

### Option 3: Makefile Integration

```makefile
# your-service/Makefile
sre-check:
	@curl -fsSL https://raw.githubusercontent.com/ns-fazhar/sre-standards/main/generated/check-operability.sh | bash

# Or if you have local copy:
sre-check-local:
	@../sre-standards/generated/check-operability.sh
```

## 📈 Current Checks (v2.1.0)

### Observability
- ✅ Readiness endpoint (`/ready`)
- ✅ Health endpoint (`/health`)
- ⚠️ Metrics endpoint (`/metrics`)
- ⚠️ Structured logging (JSON)

### Reliability
- ✅ HTTP timeouts on all calls
- ✅ Circuit breaker pattern
- ⚠️ Error handling

### Deployment
- ⚠️ Dockerfile
- ⚠️ Kubernetes manifests

### Security
- ⚠️ Dependency management
- ✅ No hardcoded secrets

### Documentation
- ⚠️ README
- ✅ Runbook

Legend: ✅ = Blocking | ⚠️ = Warning

## 🔄 How It Works

```
┌─────────────────────────────────────────────────┐
│ 1. SRE updates check-patterns.yaml             │
│    (Add new check, change severity, etc.)      │
└────────────────┬────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────┐
│ 2. Run: make generate                          │
│    → Generates shell scripts                   │
│    → Generates Claude skills                   │
└────────────────┬────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────┐
│ 3. Commit and push                             │
└────────────────┬────────────────────────────────┘
                 │
        ┌────────┴────────┐
        ↓                 ↓
┌──────────────┐  ┌──────────────┐
│ GitHub       │  │ Developers   │
│ Actions      │  │ run          │
│ (automatic)  │  │ sre-sync     │
└──────────────┘  └──────────────┘
```

## 🎓 Examples

### Adding a New Check

```yaml
# mappings/check-patterns.yaml
checks:
  - id: my-new-check
    name: "My New Check"
    category: reliability
    severity: blocking

    automation:
      pattern: "my_pattern"
      file_types: ["*.py"]

    guidance:
      description: "What this check does"
      impact: "Why it matters"
      fix: "How to fix it"
      example: "Code example"
```

```bash
make generate
make test
git commit -am "Add my new check"
git push
```

### Changing Severity

```yaml
# Change from warning to blocking
- id: metrics-endpoint
  severity: blocking  # was: warning
```

```bash
make generate
git commit -am "Escalate metrics check to blocking"
git push
```

### Updating Check Logic

```yaml
# Update pattern
- id: http-timeouts
  automation:
    pattern: "timeout=|Timeout:"  # Added Timeout: for Go
```

## 🔒 Governance

- **CODEOWNERS**: `@sre-team` must approve all changes
- **Branch Protection**: PRs required, tests must pass
- **Versioning**: Semantic versioning (major.minor.patch)
- **Changelog**: Document all changes

## 📞 Support

- **Questions**: #sre-standards Slack channel
- **Issues**: GitHub Issues in this repo
- **Docs**: [Full documentation](./docs/)

## 🚀 Quick Commands

```bash
# For SREs
make generate     # Generate from YAML
make validate     # Check YAML syntax
make test         # Test generated scripts
make version      # Show current version
make bump-minor   # Increment version

# For Developers
sre-sync          # Update to latest
make sre-check    # Run checks locally
```

---

**Maintained by**: SRE Team
**Last updated**: 2026-03-26
**Version**: 2.1.0
