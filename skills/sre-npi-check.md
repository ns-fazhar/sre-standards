---
name: sre-npi-check
description: Check service for new feature introduction patterns
version: 3.0.0
category: sre_npi
auto-generated: true
---

# SRE NPI (New Product Introduction) Check Skill

**Version**: 3.0.0
**Last Updated**: 2026-04-15
**Category**: NPI (New Product Introduction)

## Purpose

Patterns to validate new features and changes before production release

This skill checks for **5 patterns** in this category.

## Usage

When invoked, analyze the codebase and check for the following patterns:

---

### 1. 🔴 SQL Injection Prevention (CRITICAL)

**Pattern ID**: `sql_injection_risk`  
**Priority**: 1  
**Source**: OWASP Top 10 - Security vulnerability  

**Description**: Never use string concatenation for SQL queries - always use parameterized queries

**Impact**:
- CRITICAL SECURITY VULNERABILITY - data breach risk
- Attackers can read, modify, or delete any data
- Potential for privilege escalation
- Compliance violations (PCI-DSS, SOC2)
- Reputation damage and legal liability


**Fix**: Use parameterized queries with placeholders

**Example**:
```
# Python - SQLAlchemy/psycopg2
# ❌ DANGEROUS - SQL Injection risk
user_id = request.args.get('user_id')
query = f"SELECT * FROM users WHERE id = {user_id}"
cursor.execute(query)

# ❌ DANGEROUS - String concatenation
email = request.args.get('email')
query = "SELECT * FROM users WHERE email = '" + email + "'"
cursor.execute(query)

# ✅ SAFE - Parameterized query
user_id = request.args.get('user_id')
query = "SELECT * FROM users WHERE id = %s"
cursor.execute(query, (user_id,))

# ✅ SAFE - ORM
user = User.query.filter_by(id=user_id).first()

# Go - database/sql
// ❌ DANGEROUS - SQL Injection risk
userID := r.URL.Query().Get("user_id")
query := "SELECT * FROM users WHERE id = " + userID
rows, _ := db.Query(query)

// ❌ DANGEROUS - fmt.Sprintf
email := r.URL.Query().Get("email")
query := fmt.Sprintf("SELECT * FROM users WHERE email = '%s'", email)
rows, _ := db.Query(query)

// ✅ SAFE - Parameterized query
userID := r.URL.Query().Get("user_id")
query := "SELECT * FROM users WHERE id = $1"
rows, _ := db.Query(query, userID)

// ✅ SAFE - Named parameters
query := "SELECT * FROM users WHERE email = :email AND status = :status"
rows, _ := db.Query(query,
    sql.Named("email", email),
    sql.Named("status", "active"),
)

```

**References**:
- https://owasp.org/www-community/attacks/SQL_Injection
- https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html

---

### 2. 🟡 Test Coverage for New Code (WARNING)

**Pattern ID**: `missing_tests`  
**Priority**: 2  
**Source**: Code quality gate  

**Description**: All new code must have corresponding unit tests

**Impact**:
- No safety net for regressions
- Difficult to refactor safely
- Hidden bugs reach production
- Increased debugging time
- Lower code quality over time


**Fix**: Create test files for all new code with meaningful test coverage

**Example**:
```
# Python - pytest structure
# File: app/services/payment.py
# Test: tests/services/test_payment.py

# tests/services/test_payment.py
import pytest
from app.services.payment import PaymentService

class TestPaymentService:
    def test_process_payment_success(self):
        service = PaymentService()
        result = service.process_payment({
            'amount': 100,
            'currency': 'USD',
            'payment_method': 'card'
        })
        assert result['status'] == 'success'

    def test_process_payment_invalid_amount(self):
        service = PaymentService()
        with pytest.raises(ValueError):
            service.process_payment({'amount': -100})

# Go - testing structure
// File: services/payment.go
// Test: services/payment_test.go

// services/payment_test.go
package services

import (
    "testing"
)

func TestProcessPayment_Success(t *testing.T) {
    service := NewPaymentService()
    result, err := service.ProcessPayment(PaymentRequest{
        Amount:   100,
        Currency: "USD",
        Method:   "card",
    })

    if err != nil {
        t.Fatalf("expected no error, got %v", err)
    }

    if result.Status != "success" {
        t.Errorf("expected status success, got %s", result.Status)
    }
}

func TestProcessPayment_InvalidAmount(t *testing.T) {
    service := NewPaymentService()
    _, err := service.ProcessPayment(PaymentRequest{
        Amount: -100,
    })

    if err == nil {
        t.Error("expected error for negative amount")
    }
}

```

**References**:
- https://docs.pytest.org/
- https://go.dev/doc/tutorial/add-a-test

---

### 3. 🟡 API Breaking Changes Detection (WARNING)

**Pattern ID**: `api_breaking_changes`  
**Priority**: 3  
**Source**: NPI Row 33 - Backwards compatibility  

**Description**: API changes must maintain backwards compatibility or be versioned

**Impact**:
- Breaks existing clients and integrations
- Customer applications fail immediately
- Mobile apps become unusable (cannot force update)
- Lost revenue and customer trust
- Emergency rollback required


**Fix**: Use API versioning or deprecation strategy instead of breaking changes

**Example**:
```
# ❌ BAD - Breaking change (removed field)
# Before
{
    "user_id": 123,
    "email": "user@example.com",
    "full_name": "John Doe"  # REMOVED - breaks clients
}

# After
{
    "user_id": 123,
    "email": "user@example.com"
}

# ✅ GOOD - Deprecation (keep old field)
{
    "user_id": 123,
    "email": "user@example.com",
    "full_name": "John Doe",      # Deprecated but still present
    "first_name": "John",          # New field
    "last_name": "Doe"             # New field
}

# ✅ BETTER - API versioning
# /v1/users - old format (deprecated but functional)
# /v2/users - new format

# Python - API versioning
@app.route('/v1/users/<int:user_id>')
def get_user_v1(user_id):
    user = User.query.get(user_id)
    return jsonify({
        'user_id': user.id,
        'email': user.email,
        'full_name': f"{user.first_name} {user.last_name}"  # Legacy format
    })

@app.route('/v2/users/<int:user_id>')
def get_user_v2(user_id):
    user = User.query.get(user_id)
    return jsonify({
        'user_id': user.id,
        'email': user.email,
        'first_name': user.first_name,
        'last_name': user.last_name
    })

# Database migrations - Add columns, never remove
# ❌ BAD
ALTER TABLE users DROP COLUMN full_name;

# ✅ GOOD - Add new columns, deprecate old
ALTER TABLE users ADD COLUMN first_name VARCHAR(100);
ALTER TABLE users ADD COLUMN last_name VARCHAR(100);
-- Keep full_name for backwards compatibility
-- Mark as deprecated in documentation

```

**References**:
- https://www.troyhunt.com/your-api-versioning-is-wrong-which-is/
- https://stripe.com/blog/api-versioning

---

### 4. ℹ️ New Dependencies Review (INFO)

**Pattern ID**: `new_dependency_unapproved`  
**Priority**: 4  
**Source**: Supply chain security, license compliance  

**Description**: New dependencies must be reviewed for security vulnerabilities and license compliance

**Impact**:
- Supply chain security risks (malicious packages)
- Known vulnerabilities in dependencies
- License compliance issues (GPL, copyleft)
- Increased attack surface
- Dependency bloat and maintenance burden


**Fix**: Review new dependencies for security, licensing, and necessity

**Example**:
```
# Steps to review new dependency:

# 1. Check for known vulnerabilities
# Python
pip install safety
safety check

# Go
go install golang.org/x/vuln/cmd/govulncheck@latest
govulncheck ./...

# JavaScript
npm audit
npm audit fix

# 2. Check license compatibility
# Python
pip install pip-licenses
pip-licenses

# Go
go install github.com/google/go-licenses@latest
go-licenses csv ./...

# JavaScript
npx license-checker --summary

# 3. Evaluate necessity
- Is this dependency actively maintained?
- Last commit date?
- Number of dependencies it brings?
- Can we implement this ourselves (small utility)?
- Do we already have a similar dependency?

# 4. Pin versions (security best practice)
# Python requirements.txt
requests==2.31.0  # Pinned version
# NOT: requests>=2.0  # Too broad

# Go go.mod
require github.com/gin-gonic/gin v1.9.1  // Pinned

# JavaScript package.json
{
  "dependencies": {
    "express": "4.18.2"  // Exact version
  }
}

# 5. Document why dependency is needed
# Add comment in requirements.txt or docs
requests==2.31.0  # HTTP client for payment gateway integration
pyjwt==2.8.0      # JWT token validation for auth

```

**References**:
- https://owasp.org/www-project-dependency-check/
- https://snyk.io/learn/npm-security-best-practices/

---

### 5. 🟡 Database Schema Changes with Migration (WARNING)

**Pattern ID**: `schema_without_migration`  
**Priority**: 5  
**Source**: NPI Row 26 - Data consistency  

**Description**: All database schema changes must have corresponding migration files

**Impact**:
- Schema drift between environments
- Deployment failures due to missing tables/columns
- Data inconsistency across instances
- Cannot rollback changes safely
- Manual database fixes required in production


**Fix**: Create migration file for every schema change

**Example**:
```
# Python - Alembic migration
# Step 1: Modify model
# models.py
class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True)
    email = Column(String, nullable=False)
    first_name = Column(String)  # NEW FIELD
    last_name = Column(String)   # NEW FIELD

# Step 2: Generate migration
alembic revision --autogenerate -m "Add first_name and last_name to users"

# Step 3: Review generated migration
# migrations/versions/abc123_add_names.py
def upgrade():
    op.add_column('users', sa.Column('first_name', sa.String(), nullable=True))
    op.add_column('users', sa.Column('last_name', sa.String(), nullable=True))

def downgrade():
    op.drop_column('users', 'last_name')
    op.drop_column('users', 'first_name')

# Go - golang-migrate
# Create migration files
migrate create -ext sql -dir db/migrations -seq add_user_names

# db/migrations/000001_add_user_names.up.sql
ALTER TABLE users ADD COLUMN first_name VARCHAR(100);
ALTER TABLE users ADD COLUMN last_name VARCHAR(100);

# db/migrations/000001_add_user_names.down.sql
ALTER TABLE users DROP COLUMN last_name;
ALTER TABLE users DROP COLUMN first_name;

# Apply migration
migrate -path db/migrations -database postgres://localhost/mydb up

# Best practices:
# 1. Always create both up and down migrations
# 2. Test migrations on staging before production
# 3. Make migrations backwards compatible when possible
# 4. Add new columns as nullable initially
# 5. Never modify old migrations (create new ones)

# Safe migration pattern (zero-downtime):
# Step 1: Add new column (nullable)
ALTER TABLE users ADD COLUMN new_field VARCHAR(100);

# Step 2: Backfill data (if needed)
UPDATE users SET new_field = old_field WHERE new_field IS NULL;

# Step 3: Make NOT NULL (in separate migration after deploy)
ALTER TABLE users ALTER COLUMN new_field SET NOT NULL;

# Step 4: Remove old column (in separate migration after validation)
ALTER TABLE users DROP COLUMN old_field;

```

**References**:
- https://alembic.sqlalchemy.org/
- https://github.com/golang-migrate/migrate

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
🔍 SRE NPI (New Product Introduction) Check Results

✅ SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Patterns Checked: 5
Status: ⚠️  WARN - 1 critical issue, 2 warnings found

🔴 CRITICAL ISSUES (1)

1. [Database Schema Changes with Migration] SQL Injection Risk
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

- This skill is auto-generated from `mappings/sre_npi-patterns.yaml`
- Enabled patterns controlled by `mappings/enabled-patterns.yaml`
- To update: modify YAML and run `make generate`
