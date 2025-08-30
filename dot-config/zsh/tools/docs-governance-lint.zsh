#!/usr/bin/env zsh
# docs-governance-lint.zsh
# Purpose: Enforce documentation governance rules for redesign docs.
# Rules:
#   1. Every markdown file under docs/redesign must contain a navigation footer block
#      including tokens: "Navigation:" AND "Back to Index".
#   2. Footer should also expose at least one of "Previous:" or "Next" (can be placeholder).
#   3. If a Cross-Link Map (header contains "Cross-Link") exists, table rows must use markdown links `[text](path.md)` for .md references.
#   4. Basic link presence sanity is delegated to docs-link-lint, but we warn if raw `.md` tokens appear unlinked inside a Cross-Link table.
# --check (default) only reports; --fix attempts to append a standard footer if missing (does NOT auto-link tables).
# Exit codes: 0=OK, 1=violations (or unfixable), 2=script misuse.
set -euo pipefail
setopt extendedglob null_glob

MODE=check
if [[ ${1:-} == --fix ]]; then MODE=fix; fi
if [[ ${1:-} == --help ]]; then
    echo "Usage: $0 [--check|--fix]"; exit 0
fi

BASE_DIR=${0:A:h:h}
DOC_ROOT="$BASE_DIR/docs/redesign"
[[ -d $DOC_ROOT ]] || { echo "[docs-gov] ERROR: redesign docs directory not found" >&2; exit 2; }

violations=()
fixed=()

standard_footer() {
  cat <<'EOF'
---
**Navigation:** [← Previous: README](README.md) | [Next: Back to Index →](README.md) | [Top](#) | [Back to Index](README.md)
EOF
}

for f in "$DOC_ROOT"/**/*.md(.N); do
  rel=${f#$DOC_ROOT/}
  # Skip badge directories or archived copies
  if [[ $rel == badges/* ]]; then continue; fi
  content=$(<"$f")
  has_nav=0
  has_back=0
  has_prevnext=0
  [[ $content == *"Navigation:"* ]] && has_nav=1
  [[ $content == *"Back to Index"* ]] && has_back=1
  ([[ $content == *"Previous:"* ]] || [[ $content == *"Next"* ]]) && has_prevnext=1
  if (( ! has_nav || ! has_back || ! has_prevnext )); then
    if [[ $MODE == fix ]]; then
      {
        print -- "$content"
        print -- ""
        standard_footer
      } > "$f.tmp.docs-gov" && mv "$f.tmp.docs-gov" "$f"
      fixed+="$rel"
    else
      violations+="$rel:missing_footer(nav=$has_nav back=$has_back prevnext=$has_prevnext)"
    fi
  fi
  # Cross-Link Map validation
  if grep -qi '^## .*Cross-Link' <<<"$content"; then
    # Extract table block (first table after header)
    table=$(print -r -- "$content" | awk '/^## /{h=$0} /Cross-Link/{cl=1} cl && /^\|/{print} cl && !/^\|/ && NR>1 && prev==1{exit} {prev=(/^[|]/?1:0)}')
    if [[ -n $table ]]; then
      # Look for any .md token lacking preceding '[' within same cell
      raw_md=$(print -r -- "$table" | grep -Eo '[^\[][^ |()]*\.md' || true)
      if [[ -n $raw_md ]]; then
        violations+="$rel:cross_link_table_unlinked_md"
      fi
      # Require at least one proper markdown link pattern
      if ! grep -q '\[[^]]\+\](.*\.md)' <<<"$table" && ! grep -q '\[[^]]\+\]([^)]*\.md)' <<<"$table"; then
        violations+="$rel:cross_link_table_no_markdown_links"
      fi
    fi
  fi
  # Basic link presence sanity (ensure relative README link reachable)
  if [[ $content == *"Back to Index"* && $content != *"README.md"* ]]; then
    # Accept; deeper validation is handled by docs-link-lint
    :
  fi
done

if (( ${#violations} )); then
  echo "[docs-gov] Violations detected (${#violations}):" >&2
  for v in $violations; do echo "  - $v" >&2; done
  exit 1
fi

if (( ${#fixed} )); then
  echo "[docs-gov] Auto-fixed ${#fixed} files:" >&2
  for f in $fixed; do echo "  - $f" >&2; done
fi

echo "[docs-gov] All documentation governance rules satisfied"
