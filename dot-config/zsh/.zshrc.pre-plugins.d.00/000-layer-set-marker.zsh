#!/usr/bin/env zsh
# 000-layer-set-marker.zsh
# Layer Set Marker (Version 00)
#
# Purpose:
#   Establish the active "layer set" identifier for the unified ZSH configuration.
#   This file is sourced first within the pre-plugins layer directory (.zshrc.pre-plugins.d.00)
#   and provides a stable variable for:
#     - Test harness introspection
#     - CI artifact tagging
#     - Future multi-version orchestration (promotion / staging plans)
#
# Policy Alignment:
#   - Single canonical configuration track (no “legacy” runtime mode).
#   - Versioned directory sets: *.00 (active), future *.01 (staging), etc.
#   - Symlinks (.zshrc.pre-plugins.d, .zshrc.add-plugins.d, .zshrc.d) always point
#     to the currently active versioned directories.
#
# Exported:
#   _ZF_LAYER_SET=00
#
# Notes:
#   - If a prior layer (e.g. .zshenv) has already exported _ZF_LAYER_SET with a
#     different value, we retain the first declaration (immutability per session)
#     but emit a debug notice (if zf::debug exists) for forensic clarity.
#   - This file is intentionally minimal: no external commands, no dynamic logic.
#
# Nounset Safety:
#   - All parameter references guarded.
#
# Idempotency Guard:
[[ -n ${_ZF_LAYER_SET_MARKER_DONE:-} ]] && return 0
_ZF_LAYER_SET_MARKER_DONE=1

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# Desired active layer set
__zf_desired_layer_set="00"

if [[ -n ${_ZF_LAYER_SET:-} ]]; then
  if [[ "${_ZF_LAYER_SET}" != "${__zf_desired_layer_set}" ]]; then
    zf::debug "# [layer-set] WARNING: pre-existing _ZF_LAYER_SET='${_ZF_LAYER_SET}' differs from expected '${__zf_desired_layer_set}' (retaining original)"
  else
    zf::debug "# [layer-set] _ZF_LAYER_SET already set to '${_ZF_LAYER_SET}'"
  fi
else
  export _ZF_LAYER_SET="${__zf_desired_layer_set}"
  zf::debug "# [layer-set] Initialized _ZF_LAYER_SET='${_ZF_LAYER_SET}'"
fi

unset __zf_desired_layer_set
return 0
