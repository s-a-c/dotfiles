#!/usr/bin/env python3
"""
Reorganize .zshenv.01 environment variables into logical sections.

Preserves all functionality while improving organization and readability.
"""

import re
from pathlib import Path
from typing import List, Tuple

# Section definitions with keywords
SECTIONS = {
    'core': {
        'title': 'Core Shell Environment',
        'desc': 'ZDOTDIR, XDG_ variables, PATH, essential shell configuration',
        'keywords': ['ZDOTDIR', 'XDG_', 'PATH', 'SHELL', 'TERM', 'LANG', 'LC_'],
    },
    'dev_tools': {
        'title': 'Development Tools',
        'desc': 'PHP, Node, Python, Go, Rust, Composer, UV, Herd environments',
        'keywords': ['PHP', 'NODE', 'NVM', 'PYTHON', 'UV_', 'GO', 'RUST', 'CARGO', 'COMPOSER', 'HERD', 'NPM', 'PNPM', 'BUN'],
    },
    'terminal': {
        'title': 'Terminal & UI',
        'desc': 'Terminal emulator settings, colors, prompt, display configuration',
        'keywords': ['TERM_PROGRAM', 'POWERLEVEL', 'STARSHIP', 'P10K', 'COLOR', 'CLICOLOR', 'LS_COLORS'],
    },
    'performance': {
        'title': 'Performance & Monitoring',
        'desc': 'Log rotation, performance tracking, debugging, session management',
        'keywords': ['ZSH_LOG', 'ZSH_DEBUG', 'ZSH_SESSION', 'ZSH_CACHE', 'PERFORMANCE', 'MONITOR', 'SEGMENT'],
    },
    'security': {
        'title': 'Security & Safety',
        'desc': 'Permission settings, safety flags, trust anchors',
        'keywords': ['SECURE', 'SAFE', 'TRUST', 'GPG', 'SSH'],
    },
    'apps': {
        'title': 'Application Integration',
        'desc': 'Tool-specific variables (Herd, LM Studio, FZF, Ripgrep, etc.)',
        'keywords': ['HERD', 'LMSTUDIO', 'FZF', 'RIPGREP', 'DESK', 'EDITOR', 'VISUAL', 'PAGER', 'BROWSER'],
    },
    'zsh_config': {
        'title': 'ZSH Configuration',
        'desc': 'ZSH-specific settings, feature toggles, plugin configuration',
        'keywords': ['ZF_', 'ZSH_', 'DISABLE_', 'ENABLE_', 'SUPPRESS_'],
    },
}

def classify_line(line: str) -> str:
    """Classify a line into a section based on keywords."""
    line_upper = line.upper()

    # Check each section's keywords
    for section_id, section_data in SECTIONS.items():
        for keyword in section_data['keywords']:
            if keyword in line_upper:
                return section_id

    # Default to zsh_config
    return 'zsh_config'

def parse_zshenv(filepath: Path) -> Tuple[List[str], List[Tuple[str, List[str]]]]:
    """Parse .zshenv.01 into header and sections."""
    with open(filepath, 'r') as f:
        lines = f.readlines()

    # Find where environment variables start (after initial PATH setup)
    # Look for the first major section after PATH init
    env_start = 0
    for i, line in enumerate(lines):
        # Find "# === " section markers or first major export block
        if i > 100 and (line.strip().startswith('# ===') or
                       (line.strip().startswith('export ') and i > 50)):
            env_start = i
            break

    if env_start == 0:
        # Fallback: find first export after line 100
        for i, line in enumerate(lines[100:], 100):
            if line.strip().startswith('export '):
                env_start = i
                break

    # Header is everything before env_start
    header = lines[:env_start]

    # Parse rest into blocks (groups of related lines)
    blocks = []
    current_block = []

    for line in lines[env_start:]:
        stripped = line.strip()

        # Empty line ends a block
        if not stripped:
            if current_block:
                blocks.append(current_block)
                current_block = []
            continue

        current_block.append(line)

    # Add final block
    if current_block:
        blocks.append(current_block)

    # Classify blocks
    classified = {section_id: [] for section_id in SECTIONS.keys()}
    classified['_uncategorized'] = []

    for block in blocks:
        # Classify by first meaningful line
        section_id = None
        for line in block:
            if 'export ' in line or '#' in line:
                section_id = classify_line(line)
                break

        if section_id:
            classified[section_id].append(block)
        else:
            classified['_uncategorized'].append(block)

    return header, classified

def build_organized_content(header: List[str], classified: dict) -> str:
    """Build reorganized file content."""
    content = []

    # Add header
    content.extend(header)

    # Add organized sections
    for section_id in SECTIONS.keys():
        blocks = classified.get(section_id, [])
        if not blocks:
            continue

        section = SECTIONS[section_id]

        # Section header
        content.append('\n')
        content.append('# ' + '=' * 78 + '\n')
        content.append(f'# {section["title"].upper()}\n')
        content.append('# ' + '=' * 78 + '\n')
        content.append(f'# {section["desc"]}\n')
        content.append('\n')

        # Add blocks
        for block in blocks:
            content.extend(block)
            content.append('\n')

    # Add uncategorized if any
    if classified.get('_uncategorized'):
        content.append('\n')
        content.append('# ' + '=' * 78 + '\n')
        content.append('# UNCATEGORIZED\n')
        content.append('# ' + '=' * 78 + '\n')
        content.append('\n')
        for block in classified['_uncategorized']:
            content.extend(block)
            content.append('\n')

    return ''.join(content)

def main():
    """Reorganize .zshenv.01."""
    filepath = Path.cwd() / '.zshenv.01'

    if not filepath.exists():
        print(f"Error: {filepath} not found")
        return 1

    print(f"📖 Reading {filepath}...")
    header, classified = parse_zshenv(filepath)

    print(f"📊 Analysis:")
    print(f"  Header: {len(header)} lines")
    for section_id, section_data in SECTIONS.items():
        block_count = len(classified.get(section_id, []))
        if block_count > 0:
            print(f"  {section_data['title']}: {block_count} blocks")

    uncategorized = len(classified.get('_uncategorized', []))
    if uncategorized > 0:
        print(f"  Uncategorized: {uncategorized} blocks")

    print(f"\n🔧 Reorganizing...")
    new_content = build_organized_content(header, classified)

    # Backup original
    backup_path = filepath.with_suffix('.01.backup-reorg')
    print(f"💾 Backing up to {backup_path.name}...")
    with open(backup_path, 'w') as f:
        with open(filepath, 'r') as orig:
            f.write(orig.read())

    # Write new version
    print(f"✍️  Writing reorganized file...")
    with open(filepath, 'w') as f:
        f.write(new_content)

    print(f"\n✅ Done!")
    print(f"   Original backed up to: {backup_path.name}")
    print(f"   Test with: zsh -f -c 'source {filepath} && echo OK'")

    return 0

if __name__ == '__main__':
    exit(main())
