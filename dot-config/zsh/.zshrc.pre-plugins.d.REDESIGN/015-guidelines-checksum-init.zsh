#!/usr/bin/env zsh
# 015-GUIDELINES-CHECKSUM-INIT.ZSH
# Initializes GUIDELINES_CHECKSUM for acknowledgement headers.
# Must run after path safety (000) but before any modules that emit headers.
[[ -n ${_ZQS_GUIDELINES_CHECKSUM_INIT_DONE:-} ]] && return 0
_ZQS_GUIDELINES_CHECKSUM_INIT_DONE=1

: ${GUIDELINES_BASE_DIR:=/Users/s-a-c/dotfiles/dot-config/ai}
local checksum_script="${ZDOTDIR:-$HOME}/.zshrc.pre-plugins.d.REDESIGN/../bin/guidelines-checksum.zsh"

if [[ -x "$checksum_script" ]]; then
  local cs
  cs=$("$checksum_script" 2>/dev/null || true)
  if [[ -n $cs ]]; then
    export GUIDELINES_CHECKSUM="$cs"
  fi
fi

# Helper to patch a file's placeholder in-place (optional manual usage)
zf::ack_patch_placeholder() {
  local file="$1"
  [[ -n ${GUIDELINES_CHECKSUM:-} ]] || return 0
  [[ -w "$file" ]] || return 0
  grep -q 'v<checksum-pending-runtime>' "$file" || return 0
  sed -i '' "s/v<checksum-pending-runtime>/v${GUIDELINES_CHECKSUM}/" "$file" 2>/dev/null || true
}

return 0
