---
name: npi-top5
description: Top 5 NPI patterns - validate new features safely
version: 1.0.0
category: top5_npi
auto-generated: true
languages: python, go, java, scala
branch_requirement: feature_branch
branch_compare: main
---

# SRE Top 5: NPI (New Product Introduction)

**Version**: 1.0.0
**Last Updated**: 2026-04-23
**Languages**: python, go, java, scala

## Purpose

Patterns to validate new features and changes before production release

**Confidence Level**: High (82-99% across patterns)

This skill checks for the **Top 5 most critical patterns** in this category.

## ⚠️ Branch Requirement

**NPI checks must be run on feature branches**, comparing changes against `main`.

NPI checks must be run on feature branches, comparing changes against main branch

### Usage Examples

```bash
# Switch to feature branch
git checkout feature/new-payment-flow

# Run NPI checks (compares against main)
./generated/check-npi-top5.sh

# Or specify a different base branch
BASE_BRANCH=develop ./generated/check-npi-top5.sh
```

### Why Feature Branches?

NPI (New Product Introduction) checks validate:
- New code files (not existing code)
- New database migrations
- New API endpoints
- New dependencies
- New features with feature flags

These checks only make sense when comparing a feature branch against the baseline (main).

## Usage

When invoked, analyze the codebase and check for the following patterns:

---

### 1. 🔴 SQL Injection Prevention (CRITICAL)

**Pattern ID**: `sql_injection`  
**Priority**: 1  
**Confidence**: 99%%  
**Source**: OWASP Top 10 - Security vulnerability  

**Description**: Never use string concatenation for SQL queries - always use parameterized queries

**Impact**:
- CRITICAL SECURITY VULNERABILITY - data breach risk
- Attackers can read, modify, or delete any data
- Potential for privilege escalation
- Compliance violations (PCI-DSS, SOC2, GDPR)
- Reputation damage and legal liability


**Fix**: Use parameterized queries with placeholders

**Example**:
```
# Python
# ❌ DANGEROUS - SQL Injection risk
user_id = request.args.get('user_id')
query = f"SELECT * FROM users WHERE id = {user_id}"
cursor.execute(query)

# ✅ SAFE - Parameterized query
user_id = request.args.get('user_id')
query = "SELECT * FROM users WHERE id = %s"
cursor.execute(query, (user_id,))

# ✅ SAFE - ORM
user = User.query.filter_by(id=user_id).first()

# Go
// ❌ DANGEROUS
query := "SELECT * FROM users WHERE id = " + userID
rows, _ := db.Query(query)

// ✅ SAFE - Parameterized
query := "SELECT * FROM users WHERE id = $1"
rows, _ := db.Query(query, userID)

# Java
// ❌ DANGEROUS
String query = "SELECT * FROM users WHERE id = " + userId;
stmt.executeQuery(query);

// ✅ SAFE - PreparedStatement
String query = "SELECT * FROM users WHERE id = ?";
PreparedStatement stmt = conn.prepareStatement(query);
stmt.setInt(1, userId);
ResultSet rs = stmt.executeQuery();

```

**References**:
- https://owasp.org/www-community/attacks/SQL_Injection
- https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html

---

### 2. ⚠️ Feature Flag for New Features (WARNING)

**Pattern ID**: `feature_flag_detection`  
**Priority**: 2  
**Confidence**: 85%%  
**Source**: NPI CSV Row 54 - Safe rollout requirement  

**Description**: New features must be protected with feature flags for safe rollout

**Impact**:
- Cannot roll back without redeployment
- All-or-nothing deployment (no gradual rollout)
- No ability to disable feature in production emergency
- Cannot test in production with subset of users
- Difficult to isolate issues to specific feature
- Blast radius control impossible


**Fix**: Wrap new features in feature flags (LaunchDarkly, Unleash, Togglz)

**Example**:
```
# Python - LaunchDarkly
from ldclient import get as ld_client

@app.route('/api/new-checkout', methods=['POST'])
def new_checkout():
    user = get_current_user()

    if not ld_client().variation('new-checkout-flow', user, False):
        return old_checkout()

    return process_new_checkout(request.json)

# Go - Unleash
import "github.com/Unleash/unleash-client-go/v3"

func newCheckoutHandler(w http.ResponseWriter, r *http.Request) {
    enabled := unleash.IsEnabled("new-checkout-flow")
    if !enabled {
        oldCheckoutHandler(w, r)
        return
    }
    processNewCheckout(w, r)
}

# Java - Togglz
@PostMapping("/api/new-checkout")
public ResponseEntity<?> newCheckout(@RequestBody CheckoutRequest req) {
    if (!MyFeatures.NEW_CHECKOUT_FLOW.isActive()) {
        return oldCheckout(req);
    }
    return processNewCheckout(req);
}

# Scala - FF4S
import io.laserdisc.ff4s._

def newCheckout: IO[Response] = {
    client.boolVariation("new-checkout-flow", user, false).flatMap {
        case true => processNewCheckout
        case false => oldCheckout
    }
}

```

**References**:
- https://launchdarkly.com/blog/what-are-feature-flags/
- https://www.getunleash.io/
- https://www.togglz.org/

---

### 3. ⚠️ Database Schema Changes with Migration (WARNING)

**Pattern ID**: `database_migrations`  
**Priority**: 3  
**Confidence**: 88%%  
**Source**: NPI CSV Row 26 - Data consistency  

**Description**: All database schema changes must have corresponding migration files

**Impact**:
- Schema drift between environments
- Deployment failures due to missing tables/columns
- Data inconsistency across instances
- Cannot rollback changes safely
- Manual database fixes required in production
- GDPR/data sovereignty compliance issues


**Fix**: Create migration file for every schema change

**Example**:
```
# Python - Alembic
# Step 1: Modify model
class User(Base):
    first_name = Column(String)  # NEW FIELD

# Step 2: Generate migration
alembic revision --autogenerate -m "Add first_name to users"

# Step 3: Review migration
def upgrade():
    op.add_column('users', sa.Column('first_name', sa.String()))

def downgrade():
    op.drop_column('users', 'first_name')

# Go - golang-migrate
migrate create -ext sql -dir db/migrations -seq add_first_name

# 000001_add_first_name.up.sql
ALTER TABLE users ADD COLUMN first_name VARCHAR(100);

# 000001_add_first_name.down.sql
ALTER TABLE users DROP COLUMN first_name;

# Java - Flyway
# V1__add_first_name.sql
ALTER TABLE users ADD COLUMN first_name VARCHAR(100);

# Safe migration (zero-downtime):
# Step 1: Add column (nullable)
ALTER TABLE users ADD COLUMN new_field VARCHAR(100);
# Step 2: Backfill data
UPDATE users SET new_field = old_field WHERE new_field IS NULL;
# Step 3: Make NOT NULL (separate migration)
ALTER TABLE users ALTER COLUMN new_field SET NOT NULL;

```

**References**:
- https://alembic.sqlalchemy.org/
- https://github.com/golang-migrate/migrate
- https://flywaydb.org/

---

### 4. ⚠️ API Breaking Changes Detection (WARNING)

**Pattern ID**: `api_breaking_changes`  
**Priority**: 4  
**Confidence**: 82%%  
**Source**: NPI CSV Row 33 - Backwards compatibility  

**Description**: API changes must maintain backwards compatibility or be versioned

**Impact**:
- Breaks existing clients and integrations
- Customer applications fail immediately
- Mobile apps become unusable (cannot force update)
- Lost revenue and customer trust
- Emergency rollback required
- Upstream/downstream component failures


**Fix**: Use API versioning or deprecation strategy instead of breaking changes

**Example**:
```
# ❌ BAD - Breaking change (removed field)
{
    "user_id": 123,
    "email": "user@example.com"
    # "full_name" REMOVED - breaks clients
}

# ✅ GOOD - Deprecation (keep old field)
{
    "user_id": 123,
    "email": "user@example.com",
    "full_name": "John Doe",      # Deprecated but present
    "first_name": "John",
    "last_name": "Doe"
}

# ✅ BETTER - API versioning
# /v1/users - old format (deprecated but functional)
# /v2/users - new format

# Python
@app.route('/v1/users/<int:user_id>')
def get_user_v1(user_id):
    return jsonify({'full_name': f"{user.first_name} {user.last_name}"})

@app.route('/v2/users/<int:user_id>')
def get_user_v2(user_id):
    return jsonify({'first_name': user.first_name, 'last_name': user.last_name})

# Database migrations - Add columns, never remove
# ❌ BAD
ALTER TABLE users DROP COLUMN full_name;

# ✅ GOOD - Add new, deprecate old
ALTER TABLE users ADD COLUMN first_name VARCHAR(100);
ALTER TABLE users ADD COLUMN last_name VARCHAR(100);
-- Keep full_name for backwards compatibility

```

**References**:
- https://www.troyhunt.com/your-api-versioning-is-wrong-which-is/
- https://stripe.com/blog/api-versioning

---

### 5. ⚠️ Test Coverage for New Code (WARNING)

**Pattern ID**: `test_coverage`  
**Priority**: 5  
**Confidence**: 85%%  
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
# Python - pytest
# File: app/services/payment.py
# Test: tests/services/test_payment.py

class TestPaymentService:
    def test_process_payment_success(self):
        service = PaymentService()
        result = service.process_payment({'amount': 100})
        assert result['status'] == 'success'

    def test_process_payment_invalid_amount(self):
        service = PaymentService()
        with pytest.raises(ValueError):
            service.process_payment({'amount': -100})

# Go
// File: services/payment.go
// Test: services/payment_test.go

func TestProcessPayment_Success(t *testing.T) {
    service := NewPaymentService()
    result, err := service.ProcessPayment(100)
    if err != nil {
        t.Fatalf("expected no error, got %v", err)
    }
    assert.Equal(t, "success", result.Status)
}

# Java - JUnit
// File: com/example/service/PaymentService.java
// Test: com/example/service/PaymentServiceTest.java

@Test
public void testProcessPayment_Success() {
    PaymentService service = new PaymentService();
    PaymentResult result = service.processPayment(100);
    assertEquals("success", result.getStatus());
}

@Test(expected = IllegalArgumentException.class)
public void testProcessPayment_InvalidAmount() {
    PaymentService service = new PaymentService();
    service.processPayment(-100);
}

```

**References**:
- https://docs.pytest.org/
- https://go.dev/doc/tutorial/add-a-test
- https://junit.org/junit5/

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
🔍 SRE Top 5: NPI (New Product Introduction) Results

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
