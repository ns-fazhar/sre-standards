.PHONY: all generate test clean validate

all: generate

# Generate scripts and skills from pattern YAML files
generate:
	@echo "🔄 Generating from pattern YAML files..."
	@python3 generators/generate-all-patterns.py
	@echo ""
	@echo "🔄 Generating Top 5 patterns..."
	@python3 generators/generate-top5-patterns.py

# Validate YAML syntax
validate:
	@echo "✓ Validating check-patterns.yaml..."
	@python3 -c "import yaml; yaml.safe_load(open('mappings/check-patterns.yaml'))"
	@echo "✅ YAML is valid"

# Test generated scripts
test:
	@echo "🧪 Testing generated scripts..."
	@if [ -d "../sre-checks-demo" ]; then \
		cd ../sre-checks-demo && ../sre-standards/generated/check-operability.sh; \
	else \
		echo "⚠️  No test service found. Create a sample service to test."; \
	fi

# Clean generated files
clean:
	@echo "🧹 Cleaning generated files..."
	@rm -f generated/*.sh
	@echo "✅ Cleaned"

# Show current version
version:
	@echo "SRE Standards Version: $$(cat VERSION)"

# Bump version
bump-minor:
	@echo "📌 Bumping minor version..."
	@CURRENT=$$(cat VERSION); \
	MAJOR=$$(echo $$CURRENT | cut -d. -f1); \
	MINOR=$$(echo $$CURRENT | cut -d. -f2); \
	PATCH=$$(echo $$CURRENT | cut -d. -f3); \
	NEW_MINOR=$$((MINOR + 1)); \
	echo "$$MAJOR.$$NEW_MINOR.0" > VERSION; \
	echo "Version bumped: $$CURRENT → $$(cat VERSION)"

bump-patch:
	@echo "📌 Bumping patch version..."
	@CURRENT=$$(cat VERSION); \
	MAJOR=$$(echo $$CURRENT | cut -d. -f1); \
	MINOR=$$(echo $$CURRENT | cut -d. -f2); \
	PATCH=$$(echo $$CURRENT | cut -d. -f3); \
	NEW_PATCH=$$((PATCH + 1)); \
	echo "$$MAJOR.$$MINOR.$$NEW_PATCH" > VERSION; \
	echo "Version bumped: $$CURRENT → $$(cat VERSION)"

# Help
help:
	@echo "SRE Standards - Central Control Repo"
	@echo ""
	@echo "Usage:"
	@echo "  make generate      Generate scripts and skills from YAML"
	@echo "  make validate      Validate YAML syntax"
	@echo "  make test          Test generated scripts"
	@echo "  make clean         Remove generated files"
	@echo "  make version       Show current version"
	@echo "  make bump-minor    Bump minor version (x.Y.z)"
	@echo "  make bump-patch    Bump patch version (x.y.Z)"
