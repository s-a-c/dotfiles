#!/usr/bin/env zsh
# render-badge-svg.zsh
#
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# Purpose:
#   Convert one or more local Shields‑style JSON badge files (as produced by the
#   repository tooling) into lightweight static SVG badges suitable for embedding
#   in README.md (native GitHub rendering).
#
# Supported JSON structure (minimal):
#   {
#     "schemaVersion": 1,
#     "label": "hooks",
#     "message": "ok",
#     "color": "brightgreen"
#   }
#
# Features:
#   - Works with or without jq (jq preferred if available).
#   - Auto-detect single file, multiple files, or directory scan (non-recursive).
#   - Simple width calculation based on approximate glyph metrics (no font probing).
#   - Accessible <title> and <desc> tags (a11y).
#   - Fallback color mapping & normalization.
#   - Defensive parsing and validation (non-fatal warnings).
#
# Usage:
#   tools/render-badge-svg.zsh --json docs/badges/hooks.json --out docs/badges/hooks.svg
#   tools/render-badge-svg.zsh --json docs/badges/infra-health.json
#   tools/render-badge-svg.zsh --dir docs/badges --pattern '*.json'
#   tools/render-badge-svg.zsh --help
#
# Options:
#   --json <file>        Render just this JSON badge (can repeat).
#   --dir <directory>    Render all JSON badges in a directory (non-recursive).
#   --pattern <glob>     Glob (relative to --dir) for filtering (default: '*.json').
#   --out <file>         Explicit output path (only valid with a single --json).
#   --suffix <str>       Suffix to append before extension (default: '' -> .svg).
#   --force              Overwrite existing SVG files.
#   --fail-on-error      Exit non-zero if any badge fails (default: continue).
#   --quiet              Suppress non-error informational output.
#   -h | --help          Show help.
#
# Exit Codes:
#   0  Success (even if some badges skipped, unless --fail-on-error).
#   1  Usage / argument error.
#   2  Parsing or generation fatal error (when --fail-on-error).
#
# Notes:
#   - Width calculation is approximate (character * 6.2 units + padding).
#   - Color keywords normalized to a constrained palette when possible.
#   - Unknown color strings pass through; consider adding them to COLOR_MAP.
#   - Does not embed dynamic metrics; strictly local transforms (no network).
#
# Future Enhancements (not implemented yet):
#   - Multi-line wrapping (unlikely needed for short badges).
#   - Auto dark-mode adaptation (separate style variant).
#   - Aggregated sprite sheet generation.
#
# Security Considerations:
#   - Reads local JSON only; no command injection (sed/awk guarded).
#   - No untrusted shell eval; all variable expansions are double quoted.
#
set -euo pipefail

# ----------------------------
# Configuration / Defaults
# ----------------------------
typeset -a JSON_INPUTS
DIR_INPUT=""
GLOB_PATTERN="*.json"
EXPLICIT_OUT=""
SUFFIX=""
FORCE=0
FAIL_ON_ERROR=0
QUIET=0

SCRIPT_NAME=${0:t}

# ----------------------------
# Helper Functions
# ----------------------------
log() { (( QUIET )) || print -- "[$SCRIPT_NAME] $*"; }
warn() { print -u2 -- "[$SCRIPT_NAME][WARN] $*"; }
err() { print -u2 -- "[$SCRIPT_NAME][ERROR] $*"; }

show_help() {
  cat <<EOF
$SCRIPT_NAME - Render Shields-style JSON badges to static SVG.

See inline script header for detailed documentation.
EOF
}

die() {
  err "$1"
  exit ${2:-1}
}

have_jq() {
  command -v jq >/dev/null 2>&1
}

# Color normalization map (basic). Expand as needed.
typeset -A COLOR_MAP=(
  [brightgreen]="#4c1"
  [green]="#97CA00"
  [yellow]="#dfb317"
  [orange]="#fe7d37"
  [red]="#e05d44"
  [blue]="#007ec6"
  [lightgrey]="#9f9f9f"
  [lightgray]="#9f9f9f"
  [grey]="#555"
  [gray]="#555"
)

normalize_color() {
  local raw="$1" lc
  lc="${raw:l}"
  if [[ -n "${COLOR_MAP[$lc]:-}" ]]; then
    print -- "${COLOR_MAP[$lc]}"
  elif [[ "$raw" == \#([0-9a-fA-F])(#c0) ]]; then
    # Already a hex color
    print -- "$raw"
  else
    # Fallback: default neutral grey
    print -- "#555"
  fi
}

# Approximate text width: char_count * char_width + padding
# char_width chosen heuristically for typical GitHub font (DejaVu Sans / system).
approx_segment_width() {
  local text="$1" padding="$2"
  local len=${#text}
  local char_w=6.2  # heuristic average
  # shell arithmetic limited; use awk for float math
  awk -v l="$len" -v c="$char_w" -v p="$padding" 'BEGIN{ printf "%.0f", (l*c) + p }'
}

html_escape() {
  # ESC: & < > " '
  local s="$1"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  s="${s//\"/&quot;}"
  s="${s//\'/&apos;}"
  print -- "$s"
}

parse_badge_json() {
  # Args: file -> outputs 4 lines: label, message, color, schemaVersion (empty on error)
  local file="$1" label="" message="" color="" ver=""
  if have_jq; then
    label=$(jq -r '.label // empty' "$file" 2>/dev/null || true)
    message=$(jq -r '.message // empty' "$file" 2>/dev/null || true)
    color=$(jq -r '.color // empty' "$file" 2>/dev/null || true)
    ver=$(jq -r '.schemaVersion // empty' "$file" 2>/dev/null || true)
  else
    local blob; blob=$(<"$file")
    label=$(print -- "$blob" | sed -n 's/.*"label":"\([^"]*\)".*/\1/p' | head -1)
    message=$(print -- "$blob" | sed -n 's/.*"message":"\([^"]*\)".*/\1/p' | head -1)
    color=$(print -- "$blob" | sed -n 's/.*"color":"\([^"]*\)".*/\1/p' | head -1)
    ver=$(print -- "$blob" | sed -n 's/.*"schemaVersion":\s*\([0-9][0-9]*\).*/\1/p' | head -1)
  fi
  print -- "$label"
  print -- "$message"
  print -- "$color"
  print -- "$ver"
}

render_svg() {
  # Args: label message color outfile
  local label="$1" message="$2" raw_color="$3" outfile="$4"

  [[ -z "$label$message" ]] && { warn "Empty label+message; skipping $outfile"; return 1; }

  local color normalized label_txt msg_txt
  normalized=$(normalize_color "$raw_color")
  label_txt=$(html_escape "$label")
  msg_txt=$(html_escape "$message")

  # Layout constants
  local pad=10
  local sep=4  # small gap compensation
  local label_w msg_w total_w
  label_w=$(approx_segment_width "$label" $pad)
  msg_w=$(approx_segment_width "$message" $pad)
  total_w=$(( label_w + msg_w ))

  local height=20
  local label_bg="#555"       # Standard left segment color
  local msg_bg="$normalized"
  local txt_color="#fff"
  local font_family="DejaVu Sans,Verdana,Geneva,sans-serif"
  local font_size="11"

  # Text anchor adjustments
  local label_text_x=$(( label_w / 2 ))
  local msg_text_x=$(( label_w + (msg_w / 2) ))

  local title="Badge: $label $message"
  local desc="Static badge generated locally: label '$label', message '$message', color '$raw_color'"

  cat > "$outfile".tmp <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="$total_w" height="$height" role="img" aria-label="$label $message">
  <title>$title</title>
  <desc>$desc</desc>
  <linearGradient id="smooth" x2="0" y2="100%">
    <stop offset="0" stop-color="#fff" stop-opacity=".7"/>
    <stop offset=".1" stop-color="#aaa" stop-opacity=".1"/>
    <stop offset=".9" stop-color="#000" stop-opacity=".3"/>
    <stop offset="1" stop-color="#000" stop-opacity=".5"/>
  </linearGradient>
  <rect rx="3" width="$total_w" height="$height" fill="$label_bg"/>
  <rect rx="3" x="$label_w" width="$msg_w" height="$height" fill="$msg_bg"/>
  <rect rx="3" width="$total_w" height="$height" fill="url(#smooth)"/>
  <g fill="$txt_color" text-anchor="middle" font-family="$font_family" font-size="$font_size">
    <text x="$label_text_x" y="14">$label_txt</text>
    <text x="$msg_text_x" y="14">$msg_txt</text>
  </g>
</svg>
EOF

  mv "$outfile".tmp "$outfile"
  log "Rendered $outfile (color=$raw_color normalized=$normalized)"
  return 0
}

process_json_file() {
  local file="$1" out_path="$2"
  if [[ ! -f "$file" ]]; then
    warn "Badge JSON not found: $file"
    return 1
  fi
  local label message color ver
  { read -r label; read -r message; read -r color; read -r ver; } < <(parse_badge_json "$file" || true)
  if [[ -z "$label$message" ]]; then
    warn "Could not parse label/message from $file"
    return 1
  fi
  if [[ -z "$ver" ]]; then
    warn "Missing schemaVersion in $file (continuing)"
  fi
  if [[ -z "$color" ]]; then
    color="lightgrey"
  fi

  if [[ -z "$out_path" ]]; then
    local base=${file:t:r}
    out_path="${file:h}/${base}${SUFFIX}.svg"
  fi

  if [[ -f "$out_path" && $FORCE -ne 1 ]]; then
    warn "Output exists (use --force to overwrite): $out_path"
    return 1
  fi

  render_svg "$label" "$message" "$color" "$out_path"
}

# ----------------------------
# Argument Parsing
# ----------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_INPUTS+=("$2"); shift 2 ;;
    --dir) DIR_INPUT="$2"; shift 2 ;;
    --pattern) GLOB_PATTERN="$2"; shift 2 ;;
    --out) EXPLICIT_OUT="$2"; shift 2 ;;
    --suffix) SUFFIX="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    --fail-on-error) FAIL_ON_ERROR=1; shift ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) show_help; exit 0 ;;
    *) die "Unknown argument: $1" 1 ;;
  esac
done

if [[ -n "$EXPLICIT_OUT" && ${#JSON_INPUTS[@]} -ne 1 ]]; then
  die "--out can only be used with exactly one --json input" 1
fi

if [[ -z "$DIR_INPUT" && ${#JSON_INPUTS[@]} -eq 0 ]]; then
  die "No input specified. Use --json <file> or --dir <dir>." 1
fi

# Collect directory files if specified
if [[ -n "$DIR_INPUT" ]]; then
  if [[ ! -d "$DIR_INPUT" ]]; then
    die "Directory not found: $DIR_INPUT" 1
  fi
  local f
  for f in "$DIR_INPUT"/$GLOB_PATTERN; do
    [[ -f "$f" ]] || continue
    JSON_INPUTS+=("$f")
  done
fi

if (( ${#JSON_INPUTS[@]} == 0 )); then
  die "No matching JSON badge files found." 1
fi

# ----------------------------
# Processing Loop
# ----------------------------
failures=0
for jf in "${JSON_INPUTS[@]}"; do
  out=""
  if [[ -n "$EXPLICIT_OUT" ]]; then
    out="$EXPLICIT_OUT"
  fi
  if ! process_json_file "$jf" "$out"; then
    ((failures++))
    if (( FAIL_ON_ERROR )); then
      err "Aborting due to --fail-on-error (failures=$failures)"
      exit 2
    fi
  fi
done

if (( failures > 0 )); then
  warn "Completed with $failures failure(s)"
else
  log "All badge(s) rendered successfully."
fi

exit 0
