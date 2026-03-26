#!/usr/bin/env python3
"""
Generate shell scripts from check-patterns.yaml
Converts YAML check definitions into executable bash scripts
"""

import yaml
import sys
from pathlib import Path

def load_patterns(yaml_file):
    """Load check patterns from YAML"""
    with open(yaml_file, 'r') as f:
        return yaml.safe_load(f)

def generate_operability_check(patterns, output_file):
    """Generate quick operability check script"""

    version = patterns['metadata']['version']
    checks = patterns['checks']

    script = f"""#!/bin/bash
# Auto-generated from check-patterns.yaml v{version}
# DO NOT EDIT MANUALLY - Regenerate with: make generate

set -e

# Colors
RED='\\033[0;31m'
YELLOW='\\033[1;33m'
GREEN='\\033[0;32m'
BLUE='\\033[0;34m'
BOLD='\\033[1m'
NC='\\033[0m'

echo -e "${{BOLD}}${{BLUE}}🔍 SRE Operability Check (v{version})${{NC}}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ISSUES=0
WARNINGS=0

"""

    for check in checks:
        check_id = check['id']
        name = check['name']
        severity = check['severity']
        automation = check.get('automation', {})

        # Skip if no automation defined
        if not automation:
            continue

        pattern = automation.get('pattern', '')
        file_types = automation.get('file_types', [])
        file_exists = automation.get('file_exists')
        path_exists = automation.get('path_exists')

        # Generate check
        script += f"# Check: {name}\n"
        script += f'echo -n "Checking {name.lower()}... "\n'

        if file_exists:
            # Check for file existence
            files = file_exists if isinstance(file_exists, list) else [file_exists]
            condition = ' -o '.join([f'-f "{f}"' for f in files])
            script += f'if [ {condition} ]; then\n'
        elif path_exists:
            # Check for directory existence
            paths = path_exists if isinstance(path_exists, list) else [path_exists]
            condition = ' -o '.join([f'-d "{p}"' for p in paths])
            script += f'if [ {condition} ]; then\n'
        elif pattern:
            # Grep for pattern
            file_patterns = ' '.join([f'--include="{ft}"' for ft in file_types])
            script += f'if grep -rq "{pattern}" . {file_patterns} 2>/dev/null; then\n'
        else:
            continue

        # Success case
        script += f'    echo -e "${{GREEN}}✓${{NC}}"\n'
        script += 'else\n'

        # Failure case
        if severity == 'blocking':
            script += f'    echo -e "${{RED}}✗${{NC}}"\n'
            script += f'    echo "  ❌ BLOCKING: {check["guidance"]["description"]}"\n'
            script += f'    echo "     Fix: {check["guidance"]["fix"]}"\n'
            script += '    echo ""\n'
            script += '    ISSUES=$((ISSUES + 1))\n'
        else:
            script += f'    echo -e "${{YELLOW}}⚠${{NC}}"\n'
            script += f'    echo "  ⚠️  WARNING: {check["guidance"]["description"]}"\n'
            script += '    echo ""\n'
            script += '    WARNINGS=$((WARNINGS + 1))\n'

        script += 'fi\n\n'

    # Summary
    script += """
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $ISSUES -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✅ ALL CHECKS PASSED!${NC}"
    echo ""
    exit 0
elif [ $ISSUES -eq 0 ]; then
    echo -e "${YELLOW}${BOLD}⚠️  PASSED WITH WARNINGS${NC}"
    echo ""
    echo "Found $WARNINGS warning(s), but no blocking issues."
    exit 0
else
    echo -e "${RED}${BOLD}❌ CHECKS FAILED${NC}"
    echo ""
    echo "Found $ISSUES blocking issue(s) and $WARNINGS warning(s)."
    echo ""
    echo "⛔ Please fix blocking issues before deploying to production."
    exit 1
fi
"""

    # Write script
    output_path = Path(output_file)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w') as f:
        f.write(script)

    # Make executable
    output_path.chmod(0o755)

    print(f"✅ Generated {output_file}")

def generate_skill_doc(patterns, output_file):
    """Generate Claude skill markdown from patterns"""

    version = patterns['metadata']['version']
    checks = patterns['checks']

    doc = f"""---
name: operability-check
description: Check if service meets SRE operability requirements
version: {version}
auto-generated: true
---

# SRE Operability Check Skill

Version: {version}
Last updated: {patterns['metadata']['last_updated']}

## Purpose

This skill checks if a service meets production readiness requirements across:
- **Observability**: Can we monitor it?
- **Reliability**: Will it fail safely?
- **Deployment**: Can we deploy it safely?
- **Security**: Is it secure?
- **Documentation**: Can someone else operate it?

## Usage

When invoked, analyze the codebase and check for the following requirements:

"""

    # Group by category
    categories = {}
    for check in checks:
        cat = check['category']
        if cat not in categories:
            categories[cat] = []
        categories[cat].append(check)

    for category, checks_in_cat in categories.items():
        doc += f"\n### {category.title()}\n\n"

        for check in checks_in_cat:
            severity_icon = "🔴" if check['severity'] == 'blocking' else "🟡"
            doc += f"**{severity_icon} {check['name']}** ({'BLOCKING' if check['severity'] == 'blocking' else 'WARNING'})\n\n"
            doc += f"{check['guidance']['description']}\n\n"
            doc += f"**Impact**: {check['guidance']['impact']}\n\n" if isinstance(check['guidance']['impact'], str) else ""
            doc += f"**Fix**: {check['guidance']['fix']}\n\n"

            if 'example' in check['guidance']:
                doc += f"**Example**:\n```python\n{check['guidance']['example']}\n```\n\n"

            doc += "---\n\n"

    doc += """
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
"""

    with open(output_file, 'w') as f:
        f.write(doc)

    print(f"✅ Generated {output_file}")

def main():
    # Load patterns
    patterns_file = Path(__file__).parent.parent / 'mappings' / 'check-patterns.yaml'
    patterns = load_patterns(patterns_file)

    # Generate outputs
    base_dir = Path(__file__).parent.parent

    # Generate shell scripts
    generate_operability_check(
        patterns,
        base_dir / 'generated' / 'check-operability.sh'
    )

    # Generate skill documentation
    generate_skill_doc(
        patterns,
        base_dir / 'skills' / 'operability-check.md'
    )

    print(f"\n✅ All files generated from check-patterns.yaml v{patterns['metadata']['version']}")

if __name__ == '__main__':
    main()
