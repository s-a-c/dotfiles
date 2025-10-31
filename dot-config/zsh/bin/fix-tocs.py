#!/usr/bin/env python3
"""
Update TOCs to match numbered headings
Extracts actual headings from document and regenerates TOC
"""

import re
import sys
from pathlib import Path

def generate_anchor(heading_text):
    """Generate GitHub-compatible anchor from heading text"""
    # Remove markdown formatting, emoji, numbers
    # GitHub anchor algorithm:
    # 1. Lowercase
    # 2. Replace spaces with hyphens
    # 3. Remove non-alphanumeric except hyphens
    # 4. & becomes --

    anchor = heading_text.lower()
    anchor = re.sub(r'[^\w\s-]', '', anchor)  # Remove special chars (keeps emoji ranges but they'll be removed)
    anchor = re.sub(r'[\U00010000-\U0010ffff]', '', anchor)  # Remove emoji
    anchor = re.sub(r'\s+', '-', anchor)  # Spaces to hyphens
    anchor = re.sub(r'&', '--', anchor)  # Ampersands
    anchor = re.sub(r'-+', '-', anchor)  # Multiple hyphens to single
    anchor = anchor.strip('-')  # Trim hyphens

    return anchor

def extract_headings(content):
    """Extract all H2 and H3 headings from content"""
    headings = []
    lines = content.split('\n')

    in_toc = False
    past_toc = False

    for line in lines:
        # Detect TOC
        if re.match(r'^## (📋 )?Table of Contents', line):
            in_toc = True
            continue

        if in_toc and '</details>' in line:
            in_toc = False
            past_toc = True
            continue

        # Skip TOC content
        if in_toc:
            continue

        # Only process headings after TOC
        if not past_toc:
            continue

        # Extract H2 headings
        h2_match = re.match(r'^## (.+)$', line)
        if h2_match:
            title = h2_match.group(1)
            # Skip Navigation section
            if 'Navigation' not in title:
                anchor = generate_anchor(title)
                headings.append({
                    'level': 2,
                    'title': title,
                    'anchor': anchor,
                    'original': line
                })
                continue

        # Extract H3 headings
        h3_match = re.match(r'^### (.+)$', line)
        if h3_match:
            title = h3_match.group(1)
            anchor = generate_anchor(title)
            headings.append({
                'level': 3,
                'title': title,
                'anchor': anchor,
                'original': line
            })

    return headings

def generate_toc(headings):
    """Generate TOC markdown from headings"""
    toc_lines = []

    for heading in headings:
        indent = '  ' * (heading['level'] - 2)  # H2 = no indent, H3 = 2 spaces
        # Clean title of emoji for TOC (keep numbers)
        clean_title = re.sub(r'[\U00010000-\U0010ffff]', '', heading['title']).strip()
        # Remove multiple spaces
        clean_title = re.sub(r'\s+', ' ', clean_title)

        toc_line = f"{indent}- [{clean_title}](#{heading['anchor']})"
        toc_lines.append(toc_line)

    return toc_lines

def update_toc(content):
    """Replace TOC content with regenerated version"""
    headings = extract_headings(content)

    if not headings:
        return content  # No headings found, skip

    toc_content = generate_toc(headings)

    # Find TOC section and replace content
    lines = content.split('\n')
    new_lines = []
    in_toc = False
    toc_replaced = False

    for i, line in enumerate(lines):
        if re.match(r'^## (📋 )?Table of Contents', line):
            in_toc = True
            new_lines.append(line)
            new_lines.append('')
            new_lines.append('<details>')
            new_lines.append('<summary>Expand Table of Contents</summary>')
            new_lines.append('')
            new_lines.extend(toc_content)
            new_lines.append('')
            new_lines.append('</details>')
            toc_replaced = True
            continue

        if in_toc:
            if '</details>' in line:
                in_toc = False
            continue

        new_lines.append(line)

    return '\n'.join(new_lines)

def process_file(filepath):
    """Process a single markdown file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        original_content = content

        # Update TOC
        content = update_toc(content)

        # Check if file was modified
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

    print("📚 TOC Update Script")
    print("=" * 50)
    print(f"📁 Target: {docs_dir}")
    print()

    # Find all markdown files (exclude reference and diagram indexes as they're simpler)
    md_files = []
    for pattern in ['*.md']:
        md_files.extend(docs_dir.glob(pattern))

    total_files = len(md_files)
    files_modified = 0

    print(f"📄 Processing {total_files} markdown files...")
    print()

    for md_file in sorted(md_files):
        if process_file(md_file):
            files_modified += 1
            print(f"  ✅ Updated TOC: {md_file.name}")

    print()
    print("✅ TOC Update Complete")
    print("=" * 50)
    print(f"Total files: {total_files}")
    print(f"TOCs updated: {files_modified}")
    print()

if __name__ == '__main__':
    main()
