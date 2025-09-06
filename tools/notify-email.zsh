#!/usr/bin/env zsh
# Unified notification helper. Prefers neomutt; falls back to mail; else stdout.
# Usage: ALERT_EMAIL=addr ./tools/notify-email.zsh "Subject" [/path/to/body]
set -euo pipefail
subject=${1:-"[zsh-refactor] Notification"}
body_path=${2:-"-"}
if [[ "$body_path" != "-" && -f "$body_path" ]]; then
  body=$(<"$body_path")
else
  body=$(cat || echo "No body provided.")
fi
email=${ALERT_EMAIL:-}
if [[ -n $email ]]; then
  if command -v neomutt >/dev/null 2>&1; then
    print -r -- "$body" | neomutt -s "$subject" -- "$email" || true
    exit 0
  elif command -v mail >/dev/null 2>&1; then
    print -r -- "$body" | mail -s "$subject" "$email" || true
    exit 0
  fi
fi
# Fallback
print -r -- "[notify-email] $subject" >&2
print -r -- "$body"
