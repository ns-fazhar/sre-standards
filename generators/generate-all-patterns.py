#!/usr/bin/env python3
"""
Generate skills and scripts from SRE pattern YAML files
Supports multiple categories: reliability, observability, operability, NPI
"""

import yaml
import sys
from pathlib import Path
from typing import Dict, List

CATEGORIES = {
    'sre_reliability_resilience': {
        'name': 'Reliability & Resilience',
        'skill_name': 'sre-reliability-resilience-check',
        'script_name': 'check-reliability-resilience.sh',
        'description': 'Check service for reliability and resilience patterns'
    },
    'sre_observability': {
        'name': 'Observability',
        'skill_name': 'sre-observability-check',
        'script_name': 'check-observability.sh',
        'description': 'Check service for observability patterns'
    },
    'sre_operability': {
        'name': 'Operability',
        'skill_name': 'sre-operability-check',
        'script_name': 'check-operability.sh',
        'description': 'Check service for operability patterns'
    },
    'sre_npi': {
        'name': 'NPI (New Product Introduction)',
        'skill_name': 'sre-npi-check',
        'script_name': 'check-npi.sh',
        'description': 'Check service for new feature introduction patterns'
    }
}

def load_yaml(file_path: Path) -> Dict:
    """Load YAML file"""
    with open(file_path, 'r') as f:
        return yaml.safe_load(f)

def load_patterns_for_category(base_dir: Path, category: str) -> Dict:
    """Load pattern definitions for a specific category"""
    # Convert underscores to hyphens for filename
    category_filename = category.replace('_', '-')
    pattern_file = base_dir / 'mappings' / f'{category_filename}-patterns.yaml'
    if not pattern_file.exists():
        print(f"⚠️  Warning: {pattern_file} not found, skipping")
        return None
    return load_yaml(pattern_file)

def load_enabled_patterns(base_dir: Path) -> Dict:
    """Load enabled patterns configuration"""
    enabled_file = base_dir / 'mappings' / 'enabled-patterns.yaml'
    return load_yaml(enabled_file)

def generate_skill_markdown(category_key: str, patterns_data: Dict, enabled_patterns: List[str], output_file: Path):
    """Generate Claude skill markdown for a category"""

    category_info = CATEGORIES[category_key]
    metadata = patterns_data['metadata']
    all_patterns = patterns_data['patterns']

    # Filter to only enabled patterns
    enabled_pattern_data = [p for p in all_patterns if p['id'] in enabled_patterns]

    if not enabled_pattern_data:
        print(f"⚠️  No enabled patterns for {category_key}, skipping skill generation")
        return

    doc = f"""# SRE {category_info['name']} Check Skill

**Version**: {metadata['version']}
**Last Updated**: {metadata['last_updated']}
**Category**: {category_info['name']}

## Purpose

{metadata['description']}

This skill checks for **{len(enabled_pattern_data)} patterns** in this category.

## Usage

When invoked, analyze the codebase and check for the following patterns:

---

"""

    # Add each enabled pattern
    for idx, pattern in enumerate(enabled_pattern_data, 1):
        severity_emoji = "🔴" if pattern['severity'] == 'critical' else "🟡" if pattern['severity'] == 'warning' else "ℹ️"
        severity_label = pattern['severity'].upper()

        doc += f"### {idx}. {severity_emoji} {pattern['name']} ({severity_label})\n\n"
        doc += f"**Pattern ID**: `{pattern['id']}`  \n"
        doc += f"**Priority**: {pattern['priority']}  \n"
        doc += f"**Source**: {pattern['source']}  \n\n"

        doc += f"**Description**: {pattern['guidance']['description']}\n\n"

        # Impact
        if isinstance(pattern['guidance']['impact'], str):
            doc += f"**Impact**:\n{pattern['guidance']['impact']}\n\n"

        # Fix
        doc += f"**Fix**: {pattern['guidance']['fix']}\n\n"

        # Example
        if 'example' in pattern['guidance']:
            doc += f"**Example**:\n```\n{pattern['guidance']['example']}\n```\n\n"

        # References
        if 'references' in pattern['guidance']:
            doc += "**References**:\n"
            for ref in pattern['guidance']['references']:
                doc += f"- {ref}\n"
            doc += "\n"

        doc += "---\n\n"

    # Output format section
    doc += f"""
## Output Format

Provide a structured assessment:

### ✅ Summary
- Overall status: PASS / WARN / FAIL
- Patterns checked: {len(enabled_pattern_data)}
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
🔍 SRE {category_info['name']} Check Results

✅ SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Patterns Checked: {len(enabled_pattern_data)}
Status: ⚠️  WARN - 1 critical issue, 2 warnings found

🔴 CRITICAL ISSUES (1)

1. [{pattern['name']}] SQL Injection Risk
   File: handlers/user_handler.py:45
   Issue: String concatenation in SQL query
   Fix: Use parameterized query with placeholders

   ❌ BAD:
   query = f"SELECT * FROM users WHERE id = {{user_id}}"

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

- This skill is auto-generated from `mappings/{category_key}-patterns.yaml`
- Enabled patterns controlled by `mappings/enabled-patterns.yaml`
- To update: modify YAML and run `make generate`
"""

    # Write skill file
    output_file.parent.mkdir(parents=True, exist_ok=True)
    with open(output_file, 'w') as f:
        f.write(doc)

    print(f"✅ Generated skill: {output_file.name}")

def generate_check_script(category_key: str, patterns_data: Dict, enabled_patterns: List[str], output_file: Path):
    """Generate bash check script for a category"""

    category_info = CATEGORIES[category_key]
    metadata = patterns_data['metadata']
    all_patterns = patterns_data['patterns']

    # Filter to only enabled patterns
    enabled_pattern_data = [p for p in all_patterns if p['id'] in enabled_patterns]

    if not enabled_pattern_data:
        print(f"⚠️  No enabled patterns for {category_key}, skipping script generation")
        return

    script = f"""#!/bin/bash
# Auto-generated from {category_key}-patterns.yaml v{metadata['version']}
# DO NOT EDIT MANUALLY - Regenerate with: make generate
# Category: {category_info['name']}
# Patterns: {len(enabled_pattern_data)} enabled

set -e

# Colors
RED='\\033[0;31m'
YELLOW='\\033[1;33m'
GREEN='\\033[0;32m'
BLUE='\\033[0;34m'
CYAN='\\033[0;36m'
BOLD='\\033[1m'
NC='\\033[0m'

echo -e "${{BOLD}}${{BLUE}}🔍 SRE {category_info['name']} Check (v{metadata['version']})${{NC}}"
echo -e "${{CYAN}}{metadata['description']}${{NC}}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CRITICAL=0
WARNINGS=0
INFO=0

"""

    # Generate checks for each enabled pattern
    for pattern in enabled_pattern_data:
        pattern_id = pattern['id']
        name = pattern['name']
        severity = pattern['severity']
        description = pattern['guidance']['description']
        fix_msg = pattern['guidance']['fix']

        script += f"""# ========================================
# Pattern: {name}
# ID: {pattern_id}
# Severity: {severity}
# ========================================
echo -n "Checking {name}... "

"""

        # Generate detection logic based on pattern type
        detection_rules = pattern.get('detection', [])

        if not detection_rules:
            script += f"""echo -e "${{YELLOW}}⚠${{NC}}"
echo "  ℹ️  Manual check required: {description}"
echo ""
"""
            continue

        # For now, generate simple grep-based checks
        # TODO: Implement more sophisticated detection logic
        first_rule = detection_rules[0] if isinstance(detection_rules, list) else detection_rules

        if 'pattern' in first_rule:
            pattern_regex = first_rule['pattern']
            # Escape double quotes for bash
            pattern_regex = pattern_regex.replace('"', '\\"')
            file_types = first_rule.get('file_types', ['*.py', '*.go', '*.js'])
            exclude_pattern = first_rule.get('exclude', '')
            if exclude_pattern:
                exclude_pattern = exclude_pattern.replace('"', '\\"')
            invert = first_rule.get('invert', False)

            file_includes = ' '.join([f'--include="{ft}"' for ft in file_types])

            if invert:
                # Pattern should NOT be found
                script += f"""if grep -rq "{pattern_regex}" . {file_includes} 2>/dev/null; then
    echo -e "${{GREEN}}✓${{NC}}"
else
"""
            else:
                # Pattern SHOULD be found
                script += f"""if grep -rq "{pattern_regex}" . {file_includes} 2>/dev/null; then
"""
                if exclude_pattern:
                    script += f"""    # Check if exclude pattern also exists
    if grep -rq "{exclude_pattern}" . {file_includes} 2>/dev/null; then
        echo -e "${{GREEN}}✓${{NC}}"
    else
"""
                else:
                    script += f"""    echo -e "${{GREEN}}✓${{NC}}"
else
"""

            # Failure case
            if severity == 'critical':
                script += f"""    echo -e "${{RED}}✗${{NC}}"
    echo "  🔴 CRITICAL: {description}"
    echo "     Fix: {fix_msg}"
    echo ""
    CRITICAL=$((CRITICAL + 1))
"""
            elif severity == 'warning':
                script += f"""    echo -e "${{YELLOW}}⚠${{NC}}"
    echo "  🟡 WARNING: {description}"
    echo "     Fix: {fix_msg}"
    echo ""
    WARNINGS=$((WARNINGS + 1))
"""
            else:  # info
                script += f"""    echo -e "${{CYAN}}ℹ${{NC}}"
    echo "  ℹ️  INFO: {description}"
    echo "     Recommendation: {fix_msg}"
    echo ""
    INFO=$((INFO + 1))
"""

            if exclude_pattern:
                script += """    fi
"""
            script += """fi

"""

        elif 'file_exists' in first_rule:
            files = first_rule['file_exists']
            files_list = files if isinstance(files, list) else [files]
            invert = first_rule.get('invert', False)

            conditions = []
            for f in files_list:
                conditions.append(f'-f "{f}"')

            condition_str = ' -o '.join(conditions)

            if invert:
                script += f"""if [ {condition_str} ]; then
    echo -e "${{RED}}✗${{NC}}"
    echo "  🔴 WARNING: {description}"
    echo ""
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${{GREEN}}✓${{NC}}"
fi

"""
            else:
                script += f"""if [ {condition_str} ]; then
    echo -e "${{GREEN}}✓${{NC}}"
else
    echo -e "${{YELLOW}}⚠${{NC}}"
    echo "  🟡 WARNING: {description}"
    echo "     Fix: {fix_msg}"
    echo ""
    WARNINGS=$((WARNINGS + 1))
fi

"""

    # Summary section
    script += """
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $CRITICAL -eq 0 ] && [ $WARNINGS -eq 0 ] && [ $INFO -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✅ ALL CHECKS PASSED!${NC}"
    echo ""
    exit 0
elif [ $CRITICAL -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${CYAN}${BOLD}ℹ️  PASSED WITH INFO${NC}"
    echo ""
    echo "Found $INFO informational item(s)."
    exit 0
elif [ $CRITICAL -eq 0 ]; then
    echo -e "${YELLOW}${BOLD}⚠️  PASSED WITH WARNINGS${NC}"
    echo ""
    echo "Found $WARNINGS warning(s) and $INFO info item(s)."
    echo ""
    echo "💡 Consider addressing warnings before production."
    exit 0
else
    echo -e "${RED}${BOLD}❌ CHECKS FAILED${NC}"
    echo ""
    echo "Found $CRITICAL critical issue(s), $WARNINGS warning(s), and $INFO info item(s)."
    echo ""
    echo "🔴 Critical issues must be fixed before production deployment."
    exit 1
fi
"""

    # Write script
    output_file.parent.mkdir(parents=True, exist_ok=True)
    with open(output_file, 'w') as f:
        f.write(script)

    # Make executable
    output_file.chmod(0o755)

    print(f"✅ Generated script: {output_file.name}")

def main():
    base_dir = Path(__file__).parent.parent

    # Load enabled patterns
    enabled_config = load_enabled_patterns(base_dir)

    print(f"🔄 Generating skills and scripts from pattern definitions...\n")

    # Process each category
    for category_key, category_info in CATEGORIES.items():
        print(f"📦 Processing {category_info['name']}...")

        # Load pattern definitions
        patterns_data = load_patterns_for_category(base_dir, category_key)
        if not patterns_data:
            continue

        # Get enabled patterns for this category
        enabled_patterns = enabled_config.get(f"{category_key}_checks", [])
        if not enabled_patterns:
            print(f"  ⚠️  No patterns enabled for {category_key}")
            continue

        print(f"  ✓ {len(enabled_patterns)} patterns enabled")

        # Generate skill
        skill_file = base_dir / 'skills' / f"{category_info['skill_name']}.md"
        generate_skill_markdown(category_key, patterns_data, enabled_patterns, skill_file)

        # Generate script
        script_file = base_dir / 'generated' / category_info['script_name']
        generate_check_script(category_key, patterns_data, enabled_patterns, script_file)

        print("")

    print(f"✅ All files generated successfully!")
    print(f"\n📁 Output:")
    print(f"   Skills: skills/*.md")
    print(f"   Scripts: generated/*.sh")

if __name__ == '__main__':
    main()
