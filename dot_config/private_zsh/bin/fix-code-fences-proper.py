#!/usr/bin/env python3
"""
Fix code fences properly - only add language tags to OPENING fences
"""

import re
import sys
from pathlib import Path

def fix_code_fences_properly(content):
    """Add language tags to opening code fences only (not closing)"""
    lines = content.split('\n')
    new_lines = []
    in_code_block = False

    for i, line in enumerate(lines):
        # Check if this is a code fence line
        if line.strip().startswith('```'):
            # If we're not in a code block, this is an opening fence
            if not in_code_block:
                # Check if it already has a language tag
                if line.strip() == '```':
                    # No language tag - need to determine appropriate one
                    prev_line = lines[i-1] if i > 0 else ''
                    next_line = lines[i+1] if i < len(lines)-1 else ''

                    # Determine language from context
                    lang = 'text'

                    # Check for shell/bash indicators
                    if any(indicator in prev_line.lower() for indicator in ['bash', 'shell', 'command', 'terminal']):
                        lang = 'bash'
                    elif any(indicator in prev_line.lower() for indicator in ['output', 'result', 'example']):
                        lang = 'text'
                    elif 'log' in prev_line.lower():
                        lang = 'log'
                    # Check next line for shell indicators
                    elif next_line.strip().startswith(('#', '$', 'cd ', 'ls ', 'rm ', 'mkdir ', 'zsh ', 'source ')):
                        lang = 'bash'
                    # Check for other common patterns
                    elif next_line.strip().startswith('function ') or 'typeset' in next_line:
                        lang = 'bash'
                    elif next_line.strip().startswith('mermaid'):
                        # Don't add language tag - mermaid is already specified
                        new_lines.append(line)
                        in_code_block = True
                        continue

                    new_lines.append(f'```{lang}')
                    in_code_block = True
                else:
                    # Already has language tag
                    new_lines.append(line)
                    in_code_block = True
            else:
                # This is a closing fence - DON'T modify it
                new_lines.append(line)
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

        # Fix code fences properly
        content = fix_code_fences_properly(content)

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

    print("🔧 Fix Code Fences (Opening Fences Only)")
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
    print("   ✅ Added language tags to OPENING fences only")
    print("   ❌ Did NOT modify closing fences")
    print()

if __name__ == '__main__':
    main()
