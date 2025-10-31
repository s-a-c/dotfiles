#!/usr/bin/env python3
"""
Complete documentation fixes
- Remove HTML anchors from titles
- Fix zsh -c to zsh -i -c
- Add language tags to all code fences
- Fix remaining Mermaid contrast issues
- Add file:// prefix to absolute paths
- Fix markdown spacing (MD rules)
- Ensure ALL TOCs are collapsible
"""

import re
import sys
from pathlib import Path

# High-contrast color mappings (comprehensive)
COLOR_FIXES = [
    # Any remaining light colors without proper styling
    (r'style\s+(\w+)\s+fill:#e1f5ff,stroke:#333,stroke-width:(\d+)px', r'style \1 fill:#0066cc,stroke:#fff,stroke-width:\2px,color:#fff'),
    (r'style\s+(\w+)\s+fill:#e1f5ff,stroke:#333$', r'style \1 fill:#0066cc,stroke:#fff,stroke-width:2px,color:#fff'),
    (r'style\s+(\w+)\s+fill:#fff3cd,stroke:#333,stroke-width:(\d+)px', r'style \1 fill:#cc7a00,stroke:#000,stroke-width:\2px,color:#fff'),
    (r'style\s+(\w+)\s+fill:#fff3cd,stroke:#333$', r'style \1 fill:#cc7a00,stroke:#000,stroke-width:2px,color:#fff'),
    (r'style\s+(\w+)\s+fill:#d4edda,stroke:#333,stroke-width:(\d+)px', r'style \1 fill:#006600,stroke:#fff,stroke-width:\2px,color:#fff'),
    (r'style\s+(\w+)\s+fill:#d4edda,stroke:#333$', r'style \1 fill:#006600,stroke:#fff,stroke-width:2px,color:#fff'),
    (r'style\s+(\w+)\s+fill:#cce5ff,stroke:#333,stroke-width:(\d+)px', r'style \1 fill:#0080ff,stroke:#fff,stroke-width:\2px,color:#fff'),
    (r'style\s+(\w+)\s+fill:#cce5ff,stroke:#333$', r'style \1 fill:#0080ff,stroke:#fff,stroke-width:2px,color:#fff'),
    (r'style\s+(\w+)\s+fill:#f8d7da,stroke:#333,stroke-width:(\d+)px', r'style \1 fill:#cc0066,stroke:#fff,stroke-width:\2px,color:#fff'),
    (r'style\s+(\w+)\s+fill:#f8d7da,stroke:#333$', r'style \1 fill:#cc0066,stroke:#fff,stroke-width:2px,color:#fff'),
    (r'style\s+(\w+)\s+fill:#e7f3ff,stroke:#333,stroke-width:(\d+)px', r'style \1 fill:#6600cc,stroke:#fff,stroke-width:\2px,color:#fff'),
    (r'style\s+(\w+)\s+fill:#e7f3ff,stroke:#333$', r'style \1 fill:#6600cc,stroke:#fff,stroke-width:2px,color:#fff'),
    (r'style\s+(\w+)\s+fill:#ffeaa7,stroke:#333,stroke-width:(\d+)px', r'style \1 fill:#cc6600,stroke:#000,stroke-width:\2px,color:#fff'),
    (r'style\s+(\w+)\s+fill:#ffeaa7,stroke:#333$', r'style \1 fill:#cc6600,stroke:#000,stroke-width:2px,color:#fff'),
    (r'style\s+(\w+)\s+fill:#d1ecf1,stroke:#333$', r'style \1 fill:#0099cc,stroke:#fff,stroke-width:2px,color:#fff'),
    (r'style\s+(\w+)\s+fill:#d1f2eb,stroke:#333,stroke-width:(\d+)px', r'style \1 fill:#008066,stroke:#fff,stroke-width:\2px,color:#fff'),
    (r'style\s+(\w+)\s+fill:#d1f2eb,stroke:#333$', r'style \1 fill:#008066,stroke:#fff,stroke-width:2px,color:#fff'),
    (r'style\s+(\w+)\s+fill:#ffd6e0,stroke:#333,stroke-width:(\d+)px', r'style \1 fill:#cc0066,stroke:#fff,stroke-width:\2px,color:#fff'),
]

def fix_title_anchors(content):
    """Remove HTML anchors from title (H1), keep just markdown"""
    # Pattern: # <a id="..."></a>Title → # Title
    content = re.sub(r'^# <a id="[^"]+"></a>(.+)$', r'# \1', content, flags=re.MULTILINE)
    return content

def fix_zsh_commands(content):
    """Change zsh -c to zsh -i -c for interactive shell testing"""
    # Only for .zshrc testing (not .zshenv or scripts)
    content = re.sub(r'zsh -c "source ~/\.zshrc', r'zsh -i -c "source ~/.zshrc', content)
    content = re.sub(r'zsh -c "source ~/\.config/zsh/\.zshrc', r'zsh -i -c "source ~/.config/zsh/.zshrc', content)
    # Generic zsh -c for interactive testing
    content = re.sub(r'zsh -c "source ~/.config/zsh/\.zshrc\.d', r'zsh -i -c "source ~/.config/zsh/.zshrc.d', content)
    return content

def fix_code_fences(content):
    """Add language tags to code fences without them"""
    lines = content.split('\n')
    new_lines = []

    for i, line in enumerate(lines):
        # Find code fences without language
        if line.strip() == '```':
            # Check if previous line suggests language
            prev_line = lines[i-1] if i > 0 else ''

            # Determine language from context
            lang = 'text'
            if 'bash' in prev_line.lower() or 'shell' in prev_line.lower() or 'command' in prev_line.lower():
                lang = 'bash'
            elif 'output' in prev_line.lower() or 'result' in prev_line.lower():
                lang = 'text'
            elif 'log' in prev_line.lower():
                lang = 'log'

            new_lines.append(f'```{lang}')
        else:
            new_lines.append(line)

    return '\n'.join(new_lines)

def fix_mermaid_colors(content):
    """Fix all remaining Mermaid diagram colors"""
    for pattern, replacement in COLOR_FIXES:
        content = re.sub(pattern, replacement, content)
    return content

def fix_absolute_links(content):
    """Add file:// prefix to absolute paths"""
    # Pattern: ](/Users/... → (file:///Users/...
    content = re.sub(r'\]\(/Users/', r'](file:///Users/', content)
    return content

def fix_toc_collapsible(content):
    """Ensure ALL TOCs are wrapped in <details>"""
    lines = content.split('\n')
    new_lines = []
    in_toc = False
    toc_has_details = False
    i = 0

    while i < len(lines):
        line = lines[i]

        # Find TOC heading
        if re.match(r'^## (📋 )?Table of Contents', line):
            in_toc = True
            new_lines.append(line)
            new_lines.append('')

            # Check if next few lines have <details>
            toc_has_details = False
            for j in range(i+1, min(i+3, len(lines))):
                if '<details>' in lines[j]:
                    toc_has_details = True
                    break

            # If no details, add them
            if not toc_has_details:
                new_lines.append('<details>')
                new_lines.append('<summary>Expand Table of Contents</summary>')
                new_lines.append('')

            i += 1
            continue

        # If in TOC and see closing tag or next section
        if in_toc:
            if '</details>' in line:
                in_toc = False
                if not toc_has_details:
                    # We added it, now close properly
                    pass
                new_lines.append(line)
                i += 1
                continue

            # If we hit next section without closing, add closing
            if line.startswith('---') or (line.startswith('##') and 'Table of Contents' not in line):
                if not toc_has_details:
                    new_lines.append('')
                    new_lines.append('</details>')
                    new_lines.append('')
                in_toc = False
                new_lines.append(line)
                i += 1
                continue

        new_lines.append(line)
        i += 1

    return '\n'.join(new_lines)

def fix_markdown_spacing(content):
    """Fix spacing around headings, lists, code fences (MD rules)"""
    lines = content.split('\n')
    new_lines = []

    for i, line in enumerate(lines):
        prev_line = lines[i-1] if i > 0 else ''
        next_line = lines[i+1] if i < len(lines)-1 else ''

        # Add blank line before heading (except first line or after blank)
        if line.startswith('#') and i > 0 and prev_line.strip() != '':
            if not prev_line.startswith('#'):
                new_lines.append('')

        # Add blank line before list (if previous line has content)
        if line.startswith(('-', '*', '1.')) and prev_line.strip() != '' and not prev_line.startswith(('-', '*', '#')):
            if '```' not in prev_line:
                new_lines.append('')

        # Add blank line before code fence
        if line.strip().startswith('```') and prev_line.strip() != '':
            if not prev_line.strip().startswith('```'):
                new_lines.append('')

        new_lines.append(line)

        # Add blank line after heading
        if line.startswith('#') and next_line.strip() != '' and not next_line.startswith('#'):
            if not next_line.strip().startswith(('---', '<')):
                new_lines.append('')

        # Add blank line after code fence closing
        if line.strip() == '```' and next_line.strip() != '' and not next_line.startswith('#'):
            if '```' not in next_line and not next_line.strip().startswith(('---', '<')):
                new_lines.append('')

    return '\n'.join(new_lines)

def process_file(filepath):
    """Process a single markdown file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        original_content = content

        # Apply all fixes
        content = fix_title_anchors(content)
        content = fix_zsh_commands(content)
        content = fix_code_fences(content)
        content = fix_mermaid_colors(content)
        content = fix_absolute_links(content)
        content = fix_toc_collapsible(content)
        content = fix_markdown_spacing(content)

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

    print("🔧 Complete Documentation Fixes")
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
    print("✅ Complete Fixes Applied")
    print("=" * 60)
    print(f"Total files: {total_files}")
    print(f"Files modified: {files_modified}")
    print()
    print("✨ Fixes Applied:")
    print("   ✅ Removed HTML anchors from titles")
    print("   ✅ Changed zsh -c to zsh -i -c (interactive)")
    print("   ✅ Added language tags to all code fences")
    print("   ✅ Fixed Mermaid diagram contrast (comprehensive)")
    print("   ✅ Added file:// prefix to absolute links")
    print("   ✅ Made all TOCs collapsible")
    print("   ✅ Fixed markdown spacing (MD rules)")
    print()
    print("Next:")
    print("  cd docs/010-zsh-configuration")
    print("  git diff --stat")
    print()

if __name__ == '__main__':
    main()
