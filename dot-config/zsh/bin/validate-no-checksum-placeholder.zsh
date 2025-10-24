#!/usr/bin/env zsh
# Validator: ensure no v<checksum-pending-runtime> placeholders remain in tree (excluding helper logic file)
set -euo pipefail
root_dir="${ZDOTDIR:-$HOME}/."
# Limit to this repo directory explicitly (adjust if executed elsewhere)
repo_root="${HOME}/dotfiles/dot-config/zsh"
cd "$repo_root"

# Grep for placeholder
matches=$(grep -R "v<checksum-pending-runtime>" . || true)
if [[ -n $matches ]]; then
  echo "FAIL: Found placeholder occurrences:" >&2
  echo "$matches" >&2
  exit 1
fi

echo "OK: No checksum placeholder occurrences found"
exit 0
