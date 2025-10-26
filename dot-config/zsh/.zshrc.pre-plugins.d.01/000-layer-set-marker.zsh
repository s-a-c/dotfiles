#!/usr/bin/env zsh
# 000-layer-set-marker.zsh
# Layer Set Marker (Version 01)
#
# Establishes the active "layer set" identifier for the unified ZSH configuration.
# This provides a stable variable for testing, CI, and future orchestration.
#
# Policy:
#   - Single canonical configuration track.
#   - Versioned directory sets (*.00, *.01, etc.).
#   - Symlinks point to the active versioned directories.
#
# Exported: _ZF_LAYER_SET
#
# Nounset Safety: All parameter references are guarded.

# Idempotency Guard
[[ -n ${_ZF_LAYER_SET_MARKER_DONE:-} ]] && return 0
_ZF_LAYER_SET_MARKER_DONE=1

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# Desired active layer set for this version
__zf_desired_layer_set="01"

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
