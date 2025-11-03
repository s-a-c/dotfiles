#!/usr/bin/env zsh
# Compute composite sha256 checksum of guidelines sources.
# Sources: main guidelines.md + all files under guidelines/ (stable sorted)
set -euo pipefail
base_dir="${HOME}/.config/ai"
main_file="$base_dir/guidelines.md"
extra_dir="$base_dir/guidelines"

if [[ ! -f $main_file ]]; then
  echo "missing-guidelines"
  exit 0
fi

# Build ordered list
local -a files
files=($main_file)
if [[ -d $extra_dir ]]; then
  while IFS= read -r -d '' f; do files+="$f"; done < <(find "$extra_dir" -type f -maxdepth 5 -print0 | sort -z)
fi

# Concatenate and hash
{
  for f in "$files[@]"; do
    printf '--- %s ---\n' "$f"
    cat "$f"
  done
} | shasum -a 256 | awk '{print $1}'
