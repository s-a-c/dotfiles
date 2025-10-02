#!/usr/bin/env zsh
# docs-link-lint.zsh
# Purpose: Verify that all relative markdown links in ./docs resolve to existing files.
# Exits non-zero if any missing targets are found.
# Usage: tools/docs-link-lint.zsh [--verbose]
set -euo pipefail
setopt extendedglob null_glob

VERBOSE=0
if [[ ${1:-} == --verbose ]]; then VERBOSE=1; fi

DOCS_DIR="docs"
[[ -d $DOCS_DIR ]] || {     zf::debug "[docs-link-lint] ERROR: docs directory not found" ; exit 2; }

# Collect markdown files using find for portability
md_files=($(command find "$DOCS_DIR" -type f -name '*.md' -print))
if (( ! ${#md_files} )); then
      zf::debug "[docs-link-lint] No markdown files found"
  exit 0
fi

missing=()
checked=0

# Regex rough pattern for markdown links: [text](target)
# We'll parse each file line by line to avoid code block false positives minimally.
for f in $md_files; do
  while IFS= read -r line; do
    # Skip fenced code blocks start/end indicators by heuristic (do not parse inside) - simple toggle
    if [[ $line == '```'* ]]; then
      in_code=$(( ${in_code:-0} ^ 1 ))
      continue
    fi
    (( ${in_code:-0} )) && continue

    # Extract links (excluding images starting with ![ )
    if [[ $line == *"]("* ]]; then
      # Use grep -o with process substitution for robustness
      for link in $(print -r -- "$line" | grep -Eo '\[[^]]+\]\([^()]+\)'); do
        [[ $link == '!'* ]] && continue
        # Extract substring between first '(' and last ')' safely
        target=${link#*\(}
        target=${target%)}
        # Ignore pure anchors and external links
        if [[ $target == http://* || $target == https://* || $target == mailto:* || $target == \#* ]]; then
          continue
        fi
        # Split anchor fragment if present
        base_file=${target%%#*}
        # Normalize relative path (no attempt to resolve .. beyond simple path)
        if [[ -z $base_file ]]; then
          continue
        fi
        if [[ ! -f $DOCS_DIR/$base_file && ! -f $base_file ]]; then
          missing+="$f:$target"
        fi
        ((checked++))
        (( VERBOSE )) &&     zf::debug "[docs-link-lint] $f => $target"
      done
    fi
  done < "$f"
  unset in_code
done

if (( ${#missing} )); then
      zf::debug "[docs-link-lint] Missing link targets (${#missing}):"
  for m in $missing; do     zf::debug "  - $m" ; done
      zf::debug "[docs-link-lint] Checked $checked links"
  exit 1
fi

echo "[docs-link-lint] All $checked links OK (files scanned: ${#md_files})"
