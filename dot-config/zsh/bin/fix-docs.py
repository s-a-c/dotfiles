#!/usr/bin/env python3
"""
Fix documentation issues across all markdown files
- Mermaid diagram high-contrast colors
- Heading numbering (except Title and TOC)
- Folder link corrections
- Markdown linting fixes
"""

import re
import sys
from pathlib import Path

# High-contrast color mappings
COLOR_MAP = {
    # Light colors → Dark colors with white text
    r'fill:#e1f5ff(?!,)': 'fill:#0066cc,stroke:#fff,stroke-width:2px,color:#fff',
    r'fill:#e1f5ff,stroke:#333,stroke-width:(\d+)px': r'fill:#0066cc,stroke:#fff,stroke-width:\1px,color:#fff',
    r'fill:#fff3cd(?!,)': 'fill:#cc7a00,stroke:#000,stroke-width:2px,color:#fff',
    r'fill:#fff3cd,stroke:#333,stroke-width:(\d+)px': r'fill:#cc7a00,stroke:#000,stroke-width:\1px,color:#fff',
    r'fill:#d4edda(?!,)': 'fill:#006600,stroke:#fff,stroke-width:2px,color:#fff',
    r'fill:#d4edda,stroke:#333,stroke-width:(\d+)px': r'fill:#006600,stroke:#fff,stroke-width:\1px,color:#fff',
    r'fill:#cce5ff(?!,)': 'fill:#0080ff,stroke:#fff,stroke-width:2px,color:#fff',
    r'fill:#cce5ff,stroke:#333,stroke-width:(\d+)px': r'fill:#0080ff,stroke:#fff,stroke-width:\1px,color:#fff',
    r'fill:#f8d7da(?!,)': 'fill:#cc0066,stroke:#fff,stroke-width:2px,color:#fff',
    r'fill:#f8d7da,stroke:#333,stroke-width:(\d+)px': r'fill:#cc0066,stroke:#fff,stroke-width:\1px,color:#fff',
    r'fill:#e7f3ff(?!,)': 'fill:#6600cc,stroke:#fff,stroke-width:2px,color:#fff',
    r'fill:#e7f3ff,stroke:#333,stroke-width:(\d+)px': r'fill:#6600cc,stroke:#fff,stroke-width:\1px,color:#fff',
    r'fill:#ffeaa7(?!,)': 'fill:#cc6600,stroke:#000,stroke-width:2px,color:#fff',
    r'fill:#ffeaa7,stroke:#333,stroke-width:(\d+)px': r'fill:#cc6600,stroke:#000,stroke-width:\1px,color:#fff',
    r'fill:#d1ecf1(?!,)': 'fill:#0099cc,stroke:#fff,stroke-width:2px,color:#fff',
    r'fill:#d1ecf1,stroke:#333': 'fill:#0099cc,stroke:#fff,stroke-width:2px,color:#fff',
    r'fill:#d1f2eb(?!,)': 'fill:#008066,stroke:#fff,stroke-width:2px,color:#fff',
    r'fill:#d1f2eb,stroke:#333': 'fill:#008066,stroke:#fff,stroke-width:2px,color:#fff',
    r'fill:#d1f2eb,stroke:#333,stroke-width:(\d+)px': r'fill:#008066,stroke:#fff,stroke-width:\1px,color:#fff',
    r'fill:#ffd6e0(?!,)': 'fill:#cc0066,stroke:#fff,stroke-width:2px,color:#fff',
    r'fill:#ffd6e0,stroke:#333,stroke-width:(\d+)px': r'fill:#cc0066,stroke:#fff,stroke-width:\1px,color:#fff',
}

# Folder link fixes
FOLDER_LINKS = {
    r'\]\(140-reference/\)': '](140-reference/000-index.md)',
    r'\]\(150-diagrams/\)': '](150-diagrams/000-index.md)',
}

def fix_mermaid_colors(content):
    """Replace light colors with high-contrast colors in Mermaid diagrams"""
    for old_pattern, new_value in COLOR_MAP.items():
        content = re.sub(old_pattern, new_value, content)
    return content

def fix_folder_links(content):
    """Fix folder links to point to 000-index.md"""
    for old_pattern, new_value in FOLDER_LINKS.items():
        content = re.sub(old_pattern, new_value, content)
    return content

def fix_heading_numbering(content, filepath):
    """Add numbers to headings (except Title and TOC)"""
    lines = content.split('\n')
    new_lines = []

    toc_mode = False
    after_toc = False
    section_number = 0
    subsection_counters = {}

    for i, line in enumerate(lines):
        # Skip title (first # heading or with <a id>)
        if i < 5 and line.startswith('# '):
            new_lines.append(line)
            continue

        # Detect TOC section
        if re.match(r'^## (📋 )?Table of Contents', line):
            toc_mode = True
            new_lines.append(line)
            continue

        # Check if we're past TOC
        if toc_mode and line.strip() == '</details>':
            toc_mode = False
            after_toc = True
            new_lines.append(line)
            continue

        # Don't modify lines inside TOC
        if toc_mode:
            new_lines.append(line)
            continue

        # Number H2 headings after TOC (if not already numbered)
        if after_toc and line.startswith('## ') and not re.match(r'^## \d+\.', line):
            # Skip if it's already numbered or if it's navigation/special sections
            if re.match(r'^## \d+\.', line) or 'Navigation' in line or line.startswith('## 🔗'):
                new_lines.append(line)
                continue

            section_number += 1
            subsection_counters = {}  # Reset subsection counters

            # Add section number
            # Pattern: ## 🎯 Title → ## section_number. Title
            match = re.match(r'^## (.*)', line)
            if match:
                title = match.group(1)
                new_line = f'## {section_number}. {title}'
                new_lines.append(new_line)
                continue

        # Number H3 headings (if parent section is numbered)
        if section_number > 0 and line.startswith('### ') and not re.match(r'^### \d+\.', line):
            # Get or increment subsection counter for current section
            if section_number not in subsection_counters:
                subsection_counters[section_number] = 0

            subsection_counters[section_number] += 1
            subsection = subsection_counters[section_number]

            # Add subsection number
            match = re.match(r'^### (.*)', line)
            if match:
                title = match.group(1)
                new_line = f'### {section_number}.{subsection}. {title}'
                new_lines.append(new_line)
                continue

        new_lines.append(line)

    return '\n'.join(new_lines)

def process_file(filepath):
    """Process a single markdown file"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # Fix Mermaid colors
    content = fix_mermaid_colors(content)

    # Fix folder links
    content = fix_folder_links(content)

    # Fix heading numbering
    content = fix_heading_numbering(content, filepath)

    # Check if file was modified
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True

    return False

def main():
    docs_dir = Path(__file__).parent.parent / 'docs' / '010-zsh-configuration'

    if not docs_dir.exists():
        print(f"❌ Error: Documentation directory not found: {docs_dir}")
        sys.exit(1)

    print("🔧 Documentation Correction Script (Python)")
    print("=" * 50)
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
    print("✅ Batch Processing Complete")
    print("=" * 50)
    print(f"Total files: {total_files}")
    print(f"Files modified: {files_modified}")
    print()
    print("✨ Fixed:")
    print("   ✅ Mermaid diagram high-contrast colors")
    print("   ✅ Folder links to 000-index.md")
    print("   ✅ Heading numbering (except Title and TOC)")
    print()
    print("Next steps:")
    print("  cd docs/010-zsh-configuration")
    print("  git diff  # Review changes")
    print("  # Manually verify Mermaid diagrams render correctly")
    print()

if __name__ == '__main__':
    main()
