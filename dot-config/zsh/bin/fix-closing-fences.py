#!/usr/bin/env python3
"""
Fix code fence issues:
1. Remove language tags from CLOSING code fences
2. Ensure ALL code fences start in column 1 (no indentation)
"""

import re
import sys
from pathlib import Path

def fix_code_fences(content):
    """
    Fix code fences:
    - Remove tags from closing fences
    - Move all fences to column 1
    """
    lines = content.split('\n')
    new_lines = []
    in_code_block = False

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Check if this is a code fence
        if stripped.startswith('```'):
            if not in_code_block:
                # Opening fence - keep tag, but move to column 1
                new_lines.append(stripped)
                in_code_block = True
            else:
                # Closing fence - remove any tag and move to column 1
                new_lines.append('```')
                in_code_block = False
        else:
            new_lines.append(line)

    return '\n'.join(new_lines)

def process_file(filepath):
    """Process a single markdown file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        original_content = content

        # Fix code fences
        content = fix_code_fences(content)

        # Check if modified
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            return True

        return False

    except Exception as e:
        print(f"  ⚠️  Error processing {filepath.name}: {e}")
        return False

def main():
    docs_dir = Path(__file__).parent.parent / 'docs' / '010-zsh-configuration'

    if not docs_dir.exists():
        print(f"❌ Error: Documentation directory not found: {docs_dir}")
        sys.exit(1)

    print("🔧 Fix Code Fences (Tags & Indentation)")
    print("=" * 60)
    print(f"📁 Target: {docs_dir}")
    print()

    # Find all markdown files
    md_files = list(docs_dir.rglob('*.md'))

    total_files = len(md_files)
    files_modified = 0

    print(f"📄 Processing {total_files} markdown files...")
    print()

    for md_file in sorted(md_files):
        relative_path = md_file.relative_to(docs_dir)

        if process_file(md_file):
            files_modified += 1
            print(f"  ✅ Fixed: {relative_path}")

    print()
    print("✅ Code Fence Fixes Complete")
    print("=" * 60)
    print(f"Total files: {total_files}")
    print(f"Files modified: {files_modified}")
    print()
    print("✨ Fixed:")
    print("   ✅ Removed language tags from closing code fences")
    print("   ✅ All code fences now start in column 1")
    print("   ✅ Opening fences keep their language tags")
    print()

if __name__ == '__main__':
    main()
