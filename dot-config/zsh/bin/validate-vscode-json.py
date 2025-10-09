#!/usr/bin/env python3
"""
VSCode Settings JSON Validator and Fixer
Helps identify and fix JSON syntax errors in VSCode settings
"""

import json
import sys
import re
from pathlib import Path

def find_json_error(content):
    """Try to find where the JSON error is"""
    lines = content.split('\n')
    
    # Common issues
    issues = []
    
    for i, line in enumerate(lines, 1):
        # Trailing commas before closing braces/brackets
        if re.search(r',\s*[}\]]', line):
            issues.append(f"Line {i}: Trailing comma before closing brace/bracket")
        
        # Missing commas between properties
        if i < len(lines):
            current = line.strip()
            next_line = lines[i].strip() if i < len(lines) else ""
            if (current.endswith('}') or current.endswith(']')) and \
               (next_line.startswith('"') and not current.endswith(',')):
                issues.append(f"Line {i}: Possible missing comma after closing brace/bracket")
    
    return issues

def try_fix_common_issues(content):
    """Attempt to fix common JSON issues"""
    # Remove trailing commas before closing braces/brackets
    content = re.sub(r',(\s*[}\]])', r'\1', content)
    
    # Remove comments (VSCode allows them, but standard JSON doesn't)
    content = re.sub(r'//.*$', '', content, flags=re.MULTILINE)
    content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
    
    return content

def main():
    if len(sys.argv) < 2:
        settings_file = Path.home() / "Library/Application Support/Code - Insiders/User/settings.json"
    else:
        settings_file = Path(sys.argv[1])
    
    if not settings_file.exists():
        print(f"❌ File not found: {settings_file}")
        sys.exit(1)
    
    print(f"📄 Validating: {settings_file}")
    print()
    
    # Read the file
    content = settings_file.read_text()
    
    # Try to parse as-is
    try:
        data = json.loads(content)
        print("✅ JSON is valid!")
        print(f"   Found {len(data)} top-level settings")
        sys.exit(0)
    except json.JSONDecodeError as e:
        print(f"❌ JSON Error: {e.msg}")
        print(f"   Line {e.lineno}, Column {e.colno}")
        print()
        
        # Show the problematic line
        lines = content.split('\n')
        if e.lineno <= len(lines):
            print("Problematic line:")
            print(f"  {e.lineno}: {lines[e.lineno - 1]}")
            if e.lineno > 1:
                print(f"  {e.lineno - 1}: {lines[e.lineno - 2]}")
            if e.lineno < len(lines):
                print(f"  {e.lineno + 1}: {lines[e.lineno]}")
        print()
    
    # Find common issues
    issues = find_json_error(content)
    if issues:
        print("🔍 Potential issues found:")
        for issue in issues:
            print(f"   • {issue}")
        print()
    
    # Try to fix
    print("🔧 Attempting automatic fix...")
    fixed_content = try_fix_common_issues(content)
    
    try:
        data = json.loads(fixed_content)
        print("✅ Auto-fix successful!")
        print()
        
        # Ask to save
        response = input("Save fixed version? (y/N): ").strip().lower()
        if response == 'y':
            # Backup original
            backup_file = settings_file.with_suffix('.json.broken')
            settings_file.rename(backup_file)
            print(f"   Backed up broken file to: {backup_file}")
            
            # Write fixed version
            settings_file.write_text(json.dumps(data, indent=2) + '\n')
            print(f"   ✅ Saved fixed version to: {settings_file}")
        else:
            print("   Skipped saving")
    except json.JSONDecodeError as e:
        print(f"❌ Auto-fix failed: {e.msg}")
        print()
        print("Manual fix required. Common issues:")
        print("  • Trailing commas before } or ]")
        print("  • Missing commas between properties")
        print("  • Unescaped quotes in strings")
        print("  • Comments (use // or /* */ - VSCode allows them but they break standard JSON parsers)")
        print()
        print("Recommendation:")
        print("  1. Open the file in VSCode")
        print("  2. VSCode will highlight the syntax error")
        print("  3. Fix the error manually")
        print("  4. Run this script again to verify")
        sys.exit(1)

if __name__ == '__main__':
    main()

