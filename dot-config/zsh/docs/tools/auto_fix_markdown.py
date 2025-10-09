#!/usr/bin/env python3
"""
Auto-fix common Markdown style issues across docs/
- Ensure blank lines around headings and lists
- Add language tags to unlabeled fenced code blocks when heuristics indicate shell scripts
- Convert emphasized-as-heading lines like `**foo.sh**` to small headings
- Insert '## Top' when `[Top](#top)` is referenced but no top heading exists

This script writes backups (*.fix.bak) before changing files.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]  # repo root
DOCS = ROOT / 'docs'

md_files = [p for p in DOCS.rglob('*.md') if '.ARCHIVE' not in p.parts]

heading_re = re.compile(r'^(#{1,6})\s*(.*)')
emph_heading_re = re.compile(r'^\*\*(.+?)\*\*\s*$')
code_fence_re = re.compile(r'^```\s*$')
list_item_re = re.compile(r'^[\s]*([-+*]|\d+\.)\s+')

changed = []
for p in md_files:
    s = p.read_text(encoding='utf-8')
    orig = s
    lines = s.splitlines()
    out = []
    i = 0
    # Pre-scan headers to know if # Top present
    has_top = any(re.match(r'^#{1,6}\s+Top\s*$', ln) for ln in lines)
    contains_top_ref = any('[Top](#top)' in ln or '[Top](#Top)' in ln for ln in lines)
    if contains_top_ref and not has_top:
        # Insert '## Top' after first H1 or at top
        inserted = False
        for idx, ln in enumerate(lines):
            if idx == 0 and ln.startswith('# '):
                lines.insert(1, '')
                lines.insert(2, '## Top')
                lines.insert(3, '')
                inserted = True
                break
        if not inserted:
            lines.insert(0, '# ' + p.stem)
            lines.insert(1, '')
            lines.insert(2, '## Top')
            lines.insert(3, '')
    # Process lines applying fixes
    while i < len(lines):
        ln = lines[i]
        # Convert emphasized headings **foo** -> '#### foo'
        m = emph_heading_re.match(ln)
        if m:
            out.append('#### ' + m.group(1).strip())
            i += 1
            continue
        # Ensure blank line before a heading (but not at start)
        m = heading_re.match(ln)
        if m:
            if out and out[-1].strip() != '':
                out.append('')
            out.append(ln)
            # ensure a blank line after heading
            if i+1 < len(lines) and lines[i+1].strip() != '':
                out.append('')
            i += 1
            continue
        # Ensure blank line before list start
        if list_item_re.match(ln):
            if out and out[-1].strip() != '':
                out.append('')
            out.append(ln)
            # ensure blank line after list block end (look ahead)
            j = i+1
            while j < len(lines) and (list_item_re.match(lines[j]) or lines[j].strip()==""):
                out.append(lines[j])
                j += 1
            if j < len(lines) and lines[j].strip() != '':
                out.append('')
            i = j
            continue
        # Code fence handling: add language when fence present
        if code_fence_re.match(ln):
            # look ahead to next non-empty line to guess language
            j = i+1
            while j < len(lines) and lines[j].strip() == '':
                j += 1
            lang = ''
            if j < len(lines):
                nxt = lines[j]
                # heuristic: shebang or bash-like commands
                if nxt.startswith('#!') or 'set -e' in nxt or 'zsh' in nxt or 'bash' in nxt or 'exec zsh' in nxt:
                    lang = 'bash'
                # heuristic: mermaid diagrams start with 'graph' or 'sequence' etc
                if nxt.strip().startswith('graph') or nxt.strip().startswith('sequence') or nxt.strip().startswith('mermaid'):
                    lang = 'mermaid'
                if nxt.strip().startswith('|') and '---' in nxt:
                    lang = 'text'
            if lang:
                out.append('```' + lang)
            else:
                out.append(ln)
            i += 1
            continue
        out.append(ln)
        i += 1
    new = '\n'.join(out) + '\n'
    if new != orig:
        bak = p.with_suffix(p.suffix + '.fix.bak')
        p.write_text(new, encoding='utf-8')
        bak.write_text(orig, encoding='utf-8')
        changed.append(str(p))

print('Modified', len(changed), 'files')
for c in changed:
    print(' -', c)
