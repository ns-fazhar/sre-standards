#!/usr/bin/env python3
"""
Generate skills and scripts from SRE Top 5 pattern YAML files
Processes the consolidated sre-top5-patterns.yaml file
"""

import yaml
import sys
from pathlib import Path
from typing import Dict, List

TOP5_CATEGORIES = {
    'sre_checks': {
        'name': 'SRE Checks (Reliability & Resilience)',
        'skill_name': 'sre-checks-top5',
        'script_name': 'check-sre-top5.sh',
        'description': 'Top 5 reliability and resilience patterns - prevent outages'
    },
    'operability': {
        'name': 'Operability',
        'skill_name': 'operability-top5',
        'script_name': 'check-operability-top5.sh',
        'description': 'Top 5 operability patterns - ensure maintainable services'
    },
    'observability': {
        'name': 'Observability',
        'skill_name': 'observability-top5',
        'script_name': 'check-observability-top5.sh',
        'description': 'Top 5 observability patterns - visibility into service health'
    },
    'npi': {
        'name': 'NPI (New Product Introduction)',
        'skill_name': 'npi-top5',
        'script_name': 'check-npi-top5.sh',
        'description': 'Top 5 NPI patterns - validate new features safely'
    }
}

def load_yaml(file_path: Path) -> Dict:
    """Load YAML file"""
    with open(file_path, 'r') as f:
        return yaml.safe_load(f)

def load_top5_patterns(base_dir: Path) -> Dict:
    """Load Top 5 pattern definitions"""
    pattern_file = base_dir / 'mappings' / 'sre-top5-patterns.yaml'
    if not pattern_file.exists():
        print(f"❌ Error: {pattern_file} not found")
        sys.exit(1)
    return load_yaml(pattern_file)

def load_enabled_top5(base_dir: Path) -> Dict:
    """Load enabled Top 5 patterns configuration"""
    enabled_file = base_dir / 'mappings' / 'enabled-patterns.yaml'
    config = load_yaml(enabled_file)

    # Extract Top 5 sections
    return {
        'sre_checks': config.get('sre_checks', []),
        'operability': config.get('operability', []),
        'observability': config.get('observability', []),
        'npi': config.get('npi', [])
    }

def generate_skill_markdown(category_key: str, patterns_data: Dict, enabled_patterns: List[str], output_file: Path):
    """Generate Claude skill markdown for Top 5 category"""

    category_info = TOP5_CATEGORIES[category_key]
    metadata = patterns_data['metadata']
    category_data = patterns_data[category_key]
    all_patterns = category_data['patterns']

    # Filter to only enabled patterns
    enabled_pattern_data = [p for p in all_patterns if p['id'] in enabled_patterns]

    if not enabled_pattern_data:
        print(f"⚠️  No enabled patterns for {category_key}, skipping skill generation")
        return

    # Check if NPI category (branch-based)
    is_npi = category_key == 'npi'
    branch_requirement = category_data.get('branch_requirement', None)
    branch_compare = category_data.get('branch_compare', 'main')
    usage_note = category_data.get('usage_note', '')

    doc = f"""---
name: {category_info['skill_name']}
description: {category_info['description']}
version: {metadata['version']}
category: top5_{category_key}
auto-generated: true
languages: {', '.join(metadata['languages_supported'])}
"""

    if is_npi:
        doc += f"""branch_requirement: {branch_requirement}
branch_compare: {branch_compare}
"""

    doc += f"""---

# SRE Top 5: {category_info['name']}

**Version**: {metadata['version']}
**Last Updated**: {metadata['last_updated']}
**Languages**: {', '.join(metadata['languages_supported'])}

## Purpose

{category_data['category_description']}

**Confidence Level**: {category_data['confidence_level']}

This skill checks for the **Top {len(enabled_pattern_data)} most critical patterns** in this category.

"""

    if is_npi:
        doc += f"""## ⚠️ Branch Requirement

**NPI checks must be run on feature branches**, comparing changes against `{branch_compare}`.

{usage_note}

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

"""

    doc += f"""## Usage

When invoked, analyze the codebase and check for the following patterns:

---

"""

    # Add each enabled pattern
    for idx, pattern in enumerate(enabled_pattern_data, 1):
        severity_emoji = "🔴" if pattern['severity'] == 'critical' else "🟡" if pattern['severity'] == 'blocking' else "⚠️" if pattern['severity'] == 'warning' else "ℹ️"
        severity_label = pattern['severity'].upper()

        doc += f"### {idx}. {severity_emoji} {pattern['name']} ({severity_label})\n\n"
        doc += f"**Pattern ID**: `{pattern['id']}`  \n"
        doc += f"**Priority**: {pattern['priority']}  \n"
        doc += f"**Confidence**: {pattern['confidence']}%  \n"
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
🔍 SRE Top 5: {category_info['name']} Results

✅ SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Patterns Checked: {len(enabled_pattern_data)}
Status: ⚠️  WARN - 1 critical issue, 2 warnings found

🔴 CRITICAL ISSUES (1)

1. [SQL Injection Prevention] String concatenation in query
   File: handlers/user_handler.py:45
   Issue: Using f-string in SQL query
   Fix: Use parameterized query with placeholders

   ❌ BAD:
   query = f"SELECT * FROM users WHERE id = {{user_id}}"

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
"""

    # Write skill file
    output_file.parent.mkdir(parents=True, exist_ok=True)
    with open(output_file, 'w') as f:
        f.write(doc)

    print(f"✅ Generated skill: {output_file.name}")

def generate_check_script(category_key: str, patterns_data: Dict, enabled_patterns: List[str], output_file: Path):
    """Generate bash check script for Top 5 category"""

    category_info = TOP5_CATEGORIES[category_key]
    metadata = patterns_data['metadata']
    category_data = patterns_data[category_key]
    all_patterns = category_data['patterns']

    # Filter to only enabled patterns
    enabled_pattern_data = [p for p in all_patterns if p['id'] in enabled_patterns]

    if not enabled_pattern_data:
        print(f"⚠️  No enabled patterns for {category_key}, skipping script generation")
        return

    # Check if this is NPI category (branch-based checks)
    is_npi = category_key == 'npi'
    branch_requirement = category_data.get('branch_requirement', None)
    branch_compare = category_data.get('branch_compare', 'main')

    script = f"""#!/bin/bash
# Auto-generated from sre-top5-patterns.yaml v{metadata['version']}
# DO NOT EDIT MANUALLY - Regenerate with: make generate
# Category: {category_info['name']}
# Patterns: Top {len(enabled_pattern_data)} most critical
# Languages: {', '.join(metadata['languages_supported'])}
"""

    if is_npi:
        script += f"""# Branch Requirement: Feature branch (compares against {branch_compare})
"""

    script += f"""
set -e

# Colors
RED='\\033[0;31m'
YELLOW='\\033[1;33m'
GREEN='\\033[0;32m'
BLUE='\\033[0;34m'
CYAN='\\033[0;36m'
BOLD='\\033[1m'
NC='\\033[0m'

"""

    # Add branch detection for NPI
    if is_npi:
        script += f"""# Branch Detection (NPI requires feature branch)
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
BASE_BRANCH="${{BASE_BRANCH:-{branch_compare}}}"

echo -e "${{BOLD}}${{BLUE}}🔍 SRE Top 5: {category_info['name']} (v{metadata['version']})${{NC}}"
echo -e "${{CYAN}}{category_data['category_description']}${{NC}}"
echo -e "${{CYAN}}Confidence: {category_data['confidence_level']}${{NC}}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${{BOLD}}Branch Context:${{NC}}"
echo "  Current Branch: ${{CYAN}}$CURRENT_BRANCH${{NC}}"
echo "  Comparing Against: ${{CYAN}}$BASE_BRANCH${{NC}}"
echo ""

# Validate we're on a feature branch
if [ "$CURRENT_BRANCH" = "{branch_compare}" ] || [ "$CURRENT_BRANCH" = "master" ]; then
    echo -e "${{YELLOW}}⚠️  WARNING: NPI checks should run on feature branches, not $CURRENT_BRANCH${{NC}}"
    echo ""
    echo "Usage: Switch to your feature branch first, or set BASE_BRANCH:"
    echo "  git checkout feature/my-new-feature"
    echo "  ./{output_file.name}"
    echo ""
    echo "Or specify base branch:"
    echo "  BASE_BRANCH=main ./{output_file.name}"
    echo ""
fi

# Check if base branch exists
if ! git rev-parse --verify "$BASE_BRANCH" >/dev/null 2>&1; then
    echo -e "${{RED}}❌ Error: Base branch '$BASE_BRANCH' not found${{NC}}"
    echo ""
    echo "Available branches:"
    git branch -a | head -10
    exit 1
fi

echo -e "${{BOLD}}Analyzing changes in this branch:${{NC}}"
CHANGED_FILES=$(git diff --name-only $BASE_BRANCH..HEAD 2>/dev/null | wc -l | tr -d ' ')
NEW_FILES=$(git diff --name-only --diff-filter=A $BASE_BRANCH..HEAD 2>/dev/null | wc -l | tr -d ' ')
MODIFIED_FILES=$(git diff --name-only --diff-filter=M $BASE_BRANCH..HEAD 2>/dev/null | wc -l | tr -d ' ')

echo "  Changed Files: ${{CHANGED_FILES}} (${{NEW_FILES}} new, ${{MODIFIED_FILES}} modified)"
echo ""

if [ "$CHANGED_FILES" -eq 0 ]; then
    echo -e "${{YELLOW}}⚠️  No changes detected between $BASE_BRANCH and $CURRENT_BRANCH${{NC}}"
    echo ""
    echo "This could mean:"
    echo "  - You're already on $BASE_BRANCH"
    echo "  - Your branch is up-to-date with $BASE_BRANCH"
    echo "  - You need to commit your changes first"
    echo ""
    exit 0
fi

echo -e "${{BOLD}}Running NPI Checks on Changed Files:${{NC}}"
echo ""

"""
    else:
        script += f"""echo -e "${{BOLD}}${{BLUE}}🔍 SRE Top 5: {category_info['name']} (v{metadata['version']})${{NC}}"
echo -e "${{CYAN}}{category_data['category_description']}${{NC}}"
echo -e "${{CYAN}}Confidence: {category_data['confidence_level']}${{NC}}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

"""

    script += f"""CRITICAL=0
WARNINGS=0
INFO=0

"""

    # Generate checks for each enabled pattern
    for pattern in enabled_pattern_data:
        pattern_id = pattern['id']
        name = pattern['name']
        severity = pattern['severity']
        confidence = pattern['confidence']
        description = pattern['guidance']['description']
        fix_msg = pattern['guidance']['fix']

        script += f"""# ========================================
# Pattern: {name} ({confidence}% confidence)
# ID: {pattern_id}
# Severity: {severity}
# ========================================
echo -n "[{pattern['priority']}/{len(enabled_pattern_data)}] Checking {name}... "

"""

        # Generate detection logic based on pattern type
        detection_rules = pattern.get('detection', [])

        if not detection_rules:
            script += f"""echo -e "${{YELLOW}}⚠${{NC}}"
echo "  ℹ️  Manual check required: {description}"
echo ""
"""
            continue

        # For now, generate simple grep-based checks for first detection rule
        first_rule = detection_rules[0] if isinstance(detection_rules, list) else detection_rules

        if 'pattern' in first_rule:
            pattern_regex = first_rule['pattern']
            # Escape for bash
            pattern_regex = pattern_regex.replace('"', '\\"').replace('$', '\\$')
            file_types = first_rule.get('file_types', ['*.py', '*.go', '*.js', '*.java', '*.scala'])
            exclude_pattern = first_rule.get('exclude', '')
            if exclude_pattern:
                exclude_pattern = exclude_pattern.replace('"', '\\"').replace('$', '\\$')
            invert = first_rule.get('invert', False)

            file_includes = ' '.join([f'--include="{ft}"' for ft in file_types])

            # For NPI checks, only search in changed files
            if is_npi:
                search_target = '$(git diff --name-only $BASE_BRANCH..HEAD)'
                # Pre-compute file extension regex pattern (avoid backslash in f-string)
                ext_pattern = '|'.join([ft.replace('*.', '\\.') for ft in file_types])
            else:
                search_target = '.'
                ext_pattern = ''

            if invert:
                # Pattern should NOT be found
                if is_npi:
                    script += f"""if git diff --name-only $BASE_BRANCH..HEAD | xargs -I {{}} grep -H "{pattern_regex}" {{}} 2>/dev/null | grep -E '({ext_pattern})' >/dev/null 2>&1; then
"""
                else:
                    script += f"""if grep -rq "{pattern_regex}" {search_target} {file_includes} 2>/dev/null; then
"""
                # Failure - pattern found when it shouldn't be
                if severity in ['critical', 'blocking']:
                    script += f"""    echo -e "${{RED}}✗${{NC}}"
    echo "  🔴 {severity.upper()}: {description}"
    echo "     Fix: {fix_msg}"
    echo ""
    CRITICAL=$((CRITICAL + 1))
"""
                else:
                    script += f"""    echo -e "${{YELLOW}}⚠${{NC}}"
    echo "  🟡 WARNING: {description}"
    echo "     Fix: {fix_msg}"
    echo ""
    WARNINGS=$((WARNINGS + 1))
"""
                script += f"""else
    echo -e "${{GREEN}}✓${{NC}}"
fi

"""
            else:
                # Pattern SHOULD be found
                if is_npi:
                    script += f"""if git diff --name-only $BASE_BRANCH..HEAD | xargs -I {{}} grep -H "{pattern_regex}" {{}} 2>/dev/null | grep -E '({ext_pattern})' >/dev/null 2>&1; then
"""
                else:
                    script += f"""if grep -rq "{pattern_regex}" {search_target} {file_includes} 2>/dev/null; then
"""
                if exclude_pattern:
                    if is_npi:
                        script += f"""    # Check if exclude pattern also exists (good case)
    if git diff --name-only $BASE_BRANCH..HEAD | xargs -I {{}} grep -H "{exclude_pattern}" {{}} 2>/dev/null | grep -E '({ext_pattern})' >/dev/null 2>&1; then
        echo -e "${{GREEN}}✓${{NC}}"
    else
"""
                    else:
                        script += f"""    # Check if exclude pattern also exists (good case)
    if grep -rq "{exclude_pattern}" {search_target} {file_includes} 2>/dev/null; then
        echo -e "${{GREEN}}✓${{NC}}"
    else
"""
                else:
                    script += f"""    echo -e "${{GREEN}}✓${{NC}}"
else
"""

                # Failure case - pattern not found
                if severity in ['critical', 'blocking']:
                    script += f"""    echo -e "${{RED}}✗${{NC}}"
    echo "  🔴 {severity.upper()}: {description}"
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
    echo -e "${{YELLOW}}⚠${{NC}}"
    echo "  🟡 WARNING: {description}"
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
    script += f"""
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $CRITICAL -eq 0 ] && [ $WARNINGS -eq 0 ] && [ $INFO -eq 0 ]; then
    echo -e "${{GREEN}}${{BOLD}}✅ ALL TOP {len(enabled_pattern_data)} CHECKS PASSED!${{NC}}"
    echo ""
    exit 0
elif [ $CRITICAL -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${{CYAN}}${{BOLD}}ℹ️  PASSED WITH INFO${{NC}}"
    echo ""
    echo "Found $INFO informational item(s)."
    exit 0
elif [ $CRITICAL -eq 0 ]; then
    echo -e "${{YELLOW}}${{BOLD}}⚠️  PASSED WITH WARNINGS${{NC}}"
    echo ""
    echo "Found $WARNINGS warning(s) and $INFO info item(s)."
    echo ""
    echo "💡 Consider addressing warnings before production."
    exit 0
else
    echo -e "${{RED}}${{BOLD}}❌ CRITICAL ISSUES FOUND${{NC}}"
    echo ""
    echo "Found $CRITICAL critical/blocking issue(s), $WARNINGS warning(s), and $INFO info item(s)."
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

    # Load Top 5 pattern definitions
    patterns_data = load_top5_patterns(base_dir)

    # Load enabled patterns
    enabled_config = load_enabled_top5(base_dir)

    print(f"🔄 Generating Top 5 skills and scripts...\n")

    # Process each category
    for category_key, category_info in TOP5_CATEGORIES.items():
        print(f"📦 Processing {category_info['name']}...")

        # Get enabled patterns for this category
        enabled_patterns = enabled_config.get(category_key, [])
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

    print(f"✅ All Top 5 files generated successfully!")
    print(f"\n📁 Output:")
    print(f"   Skills: skills/*-top5.md")
    print(f"   Scripts: generated/check-*-top5.sh")

if __name__ == '__main__':
    main()
