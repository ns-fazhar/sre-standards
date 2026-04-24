# SRE Standards - Pattern-Based Checks v3.0.0

**Last Updated**: 2026-04-15  
**Status**: ✅ Production Ready

## Overview

Central control repository for SRE pattern enforcement across all services. This system provides **20 high-confidence pre-commit checks** organized into 4 categories:

- 🛡️ **Reliability & Resilience** (5 patterns) - Prevent outages
- 📊 **Observability** (5 patterns) - Ensure visibility  
- ⚙️ **Operability** (5 patterns) - Enable operations
- 🚀 **NPI** (5 patterns) - Validate new features

## Quick Start

### For SRE Team (You)

```bash
# 1. Edit pattern definitions
vim mappings/sre-reliability-resilience-patterns.yaml

# 2. Enable/disable patterns
vim mappings/enabled-patterns.yaml

# 3. Generate skills and scripts
make generate

# 4. Commit and push
git add .
git commit -m "Update SRE patterns"
git push

# All services instantly get updates via @main reference
```

### For Development Teams

Services reference this repo directly - no manual sync needed!

```yaml
# .github/workflows/sre-checks.yml
- name: Run SRE Checks
  run: |
    curl -sL https://raw.githubusercontent.com/ns-fazhar/sre-standards/main/generated/check-reliability-resilience.sh | bash
    curl -sL https://raw.githubusercontent.com/ns-fazhar/sre-standards/main/generated/check-observability.sh | bash
```

## File Structure

```
sre-standards/
├── mappings/
│   ├── enabled-patterns.yaml                      # YOUR CONTROL PANEL
│   ├── sre-reliability-resilience-patterns.yaml  # Pattern definitions
│   ├── sre-observability-patterns.yaml
│   ├── sre-operability-patterns.yaml
│   └── sre-npi-patterns.yaml
│
├── skills/                                        # Auto-generated Claude skills
│   ├── sre-reliability-resilience-check.md
│   ├── sre-observability-check.md
│   ├── sre-operability-check.md
│   └── sre-npi-check.md
│
├── generated/                                     # Auto-generated scripts
│   ├── check-reliability-resilience.sh
│   ├── check-observability.sh
│   ├── check-operability.sh
│   └── check-npi.sh
│
└── generators/
    └── generate-all-patterns.py                   # Generator script
```

## 20 Enabled Patterns

### 🛡️ Reliability & Resilience (5)

| Pattern | Severity | Description |
|---------|----------|-------------|
| `timeout_protection` | warning | HTTP/DB calls must have timeouts |
| `panic_recovery` | warning | Goroutines must have defer recover() |
| `resource_not_closed` | warning | Connections/files must be closed |
| `circuit_breaker` | warning | External calls need circuit breakers |
| `missing_health_endpoint` | warning | Must have /health and /ready endpoints |

### 📊 Observability (5)

| Pattern | Severity | Description |
|---------|----------|-------------|
| `metrics_instrumentation` | warning | Critical paths must export metrics |
| `central_logging` | warning | Errors must be logged |
| `duration_metrics` | warning | Track request latency |
| `request_id_propagation` | info | Propagate request IDs |
| `missing_metrics_endpoint` | warning | Must expose /metrics endpoint |

### ⚙️ Operability (5)

| Pattern | Severity | Description |
|---------|----------|-------------|
| `secrets_management` | critical | No hardcoded secrets |
| `no_graceful_shutdown` | warning | Handle SIGTERM gracefully |
| `env_vars_undocumented` | info | Document environment variables |
| `missing_dockerfile` | warning | Dockerfile must exist |
| `config_not_validated` | info | Validate config at startup |

### 🚀 NPI (5)

| Pattern | Severity | Description |
|---------|----------|-------------|
| `sql_injection_risk` | critical | No string concatenation in SQL |
| `missing_tests` | warning | New code must have tests |
| `api_breaking_changes` | warning | Detect breaking API changes |
| `new_dependency_unapproved` | info | Review new dependencies |
| `schema_without_migration` | warning | Schema changes need migrations |

## Pattern Sources

All patterns derived from:
- **Service Maturity Scorecard** patterns (`/Users/fazhar/work/sms2.0_patterns.txt`)
- **NPI Design Sign-off** checklist (`/Users/fazhar/work/SRE NPI Checklists - Design Sign-off.csv`)
- Production reliability best practices
- OWASP Top 10 security guidelines

## How It Works

### 1. Central Control (Your Power)

Edit `mappings/enabled-patterns.yaml`:

```yaml
sre_reliability_resilience_checks:
  - timeout_protection
  - panic_recovery
  # - circuit_breaker  # Disable by commenting out
```

### 2. Auto-Generation

```bash
make generate
```

This creates:
- **4 Claude skills** - For AI-powered code review
- **4 bash scripts** - For automated PR checks

### 3. Zero-Sync Distribution

Services reference scripts via URL:
```bash
curl https://raw.githubusercontent.com/ns-fazhar/sre-standards/main/generated/check-observability.sh | bash
```

**Result**: Update once, enforced everywhere instantly!

## Usage Examples

### As Claude Skill

```bash
# In any service repo
claude
> /sre-reliability-resilience-check
> /sre-observability-check
```

Claude will analyze the codebase and report findings.

### As GitHub Action

```yaml
# .github/workflows/pr-checks.yml
name: SRE Pattern Checks

on: [pull_request]

jobs:
  sre-checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Reliability Check
        run: |
          curl -sL https://raw.githubusercontent.com/ns-fazhar/sre-standards/main/generated/check-reliability-resilience.sh | bash

      - name: Observability Check
        run: |
          curl -sL https://raw.githubusercontent.com/ns-fazhar/sre-standards/main/generated/check-observability.sh | bash

      - name: Operability Check
        run: |
          curl -sL https://raw.githubusercontent.com/ns-fazhar/sre-standards/main/generated/check-operability.sh | bash

      - name: NPI Check
        run: |
          curl -sL https://raw.githubusercontent.com/ns-fazhar/sre-standards/main/generated/check-npi.sh | bash
```

### As Pre-Commit Hook

```bash
# .git/hooks/pre-commit
#!/bin/bash
bash <(curl -sL https://raw.githubusercontent.com/ns-fazhar/sre-standards/main/generated/check-reliability-resilience.sh)
```

## Output Format

```bash
🔍 SRE Reliability & Resilience Check (v3.0.0)
Patterns to prevent outages and ensure resilient service behavior
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Checking Timeout Protection... 🟡⚠
  🟡 WARNING: All external calls must have timeout protection
     Fix: Add timeout parameter to all external calls

Checking Panic Recovery... ✓
Checking Resource Leak Prevention... 🟡⚠
  🟡 WARNING: Resources must be properly closed
     Fix: Use defer or context managers

Checking Circuit Breaker... ✓
Checking Health Endpoints... ✓

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  PASSED WITH WARNINGS

Found 2 warning(s) and 0 info item(s).

💡 Consider addressing warnings before production.
```

## Future Patterns (Coming Soon)

See `mappings/enabled-patterns.yaml` for 18 additional patterns ready to enable:

- `unbounded_channels`
- `retry_with_backoff`
- `feature_flag_presence`
- `rate_limiting`
- `deprecated_components`
- And more...

## Maintenance

### Adding a New Pattern

1. Edit pattern definition file:
```yaml
# mappings/sre-reliability-resilience-patterns.yaml
- id: new_pattern_id
  name: "New Pattern"
  severity: warning
  priority: 6
  source: "Your source"
  detection:
    - language: python
      pattern: 'some_regex'
      file_types: ["*.py"]
  guidance:
    description: "What to check"
    impact: "Why it matters"
    fix: "How to fix"
    example: "Code example"
```

2. Enable the pattern:
```yaml
# mappings/enabled-patterns.yaml
sre_reliability_resilience_checks:
  - new_pattern_id  # Add here
```

3. Regenerate:
```bash
make generate
```

### Disabling a Pattern

Comment it out in `enabled-patterns.yaml`:
```yaml
sre_reliability_resilience_checks:
  - timeout_protection
  # - panic_recovery  # Temporarily disabled
```

## Version History

- **v3.0.0** (2026-04-15) - Pattern-based system with 20 checks across 4 categories
- **v2.1.0** (2026-03-26) - Original operability checks
- **v1.0.0** (2026-03-10) - Initial release

## Contact

**Owner**: SRE Team  
**Maintainer**: fazhar@company.com  
**Repository**: https://github.com/ns-fazhar/sre-standards
