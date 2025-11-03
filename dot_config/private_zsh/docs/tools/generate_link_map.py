#!/usr/bin/env python3
"""
Generate a link-existence map for docs/ (excluding docs/.ARCHIVE).
Writes docs/reports/link-existence-map.json
"""
import os
import re
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]  # repo root (zsh)
DOCS = ROOT / 'docs'
REPORTS = DOCS / 'reports'
REPORTS.mkdir(parents=True, exist_ok=True)

link_re = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")
header_re = re.compile(r"^\s*(#{1,6})\s+(.*)$")

def slugify(text):
    # approximate GitHub slug behavior for anchors
    s = text.strip().lower()
    s = re.sub(r"[^a-z0-9 _-]", "", s)
    s = re.sub(r"[ _]+", "-", s)
    return s

map_out = {
    'generated': None,
    'files_scanned': [],
}

from datetime import datetime
map_out['generated'] = datetime.utcnow().isoformat() + 'Z'

for root, dirs, files in os.walk(DOCS):
    # skip .ARCHIVE directories explicitly
    if '.ARCHIVE' in root.split(os.sep):
        continue
    for fname in files:
        if not fname.endswith('.md'):
            continue
        fpath = Path(root) / fname
        rel = str(fpath.relative_to(ROOT))
        map_out['files_scanned'].append(rel)
        text = fpath.read_text(encoding='utf-8')
        # gather headers for anchor checks
        headers = []
        for line in text.splitlines():
            m = header_re.match(line)
            if m:
                headers.append(slugify(m.group(2)))
        links = []
        for m in link_re.finditer(text):
            link_text, target = m.group(1), m.group(2)
            entry = {'text': link_text, 'target': target}
            if target.startswith('http://') or target.startswith('https://'):
                entry.update({'type': 'external', 'status': 'external-not-checked'})
            elif target.startswith('/'):
                # absolute path inside repo
                abs_path = (ROOT / target.lstrip('/')).resolve()
                exists = abs_path.exists()
                entry.update({'type': 'absolute-repo-path', 'status': 'exists' if exists else 'missing', 'resolved': str(abs_path)})
            elif target.startswith('#'):
                anchor = target.lstrip('#')
                entry.update({'type': 'anchor', 'status': 'exists' if slugify(anchor) in headers else 'missing'})
            else:
                # relative path or relative anchor in file
                if '#' in target:
                    rel_path_part, anchor = target.split('#', 1)
                else:
                    rel_path_part, anchor = target, None
                resolved = (fpath.parent / rel_path_part).resolve()
                # normalize for README links that omit .md
                if resolved.is_file():
                    exists = True
                else:
                    # try appending .md
                    alt = resolved.with_suffix('.md')
                    if alt.is_file():
                        resolved = alt
                        exists = True
                    else:
                        exists = False
                entry.update({'type': 'relative', 'status': 'exists' if exists else 'missing', 'resolved': str(resolved)})
                if anchor:
                    # check anchor in target resolved file
                    if exists:
                        target_text = Path(resolved).read_text(encoding='utf-8')
                        target_headers = [slugify(h) for h in header_re.findall(target_text)]
                        entry['anchor_status'] = 'exists' if slugify(anchor) in target_headers else 'missing'
                    else:
                        entry['anchor_status'] = 'unknown (target missing)'
            links.append(entry)
        map_out.setdefault('link_existence', []).append({'source': rel, 'links': links})

# write JSON
out_file = REPORTS / 'link-existence-map.json'
out_file.write_text(json.dumps(map_out, indent=2, ensure_ascii=False))
print('Wrote', out_file)
