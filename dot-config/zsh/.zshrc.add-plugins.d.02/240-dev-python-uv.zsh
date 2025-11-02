#!/usr/bin/env zsh
# Filename: 240-dev-python-uv.zsh
# Purpose:  Provide lightweight, nounset-safe integration for the `uv` Python packaging / project manager and its companion `uvx` wrapper: - Adds generated Zsh completion files (preferred) or eval-based fallback - Sets explicit presence markers for diagnostics / smoke tests Features: - Idempotent (safe to source multiple times) - Skippable via ZF_DISABLE_UV_COMPLETIONS=1 - Attempts several generation syntaxes for future-proofing: uv generate-shell-completion zsh uv --generate-shell-completion zsh uv completion zsh (fallback / hypothetical) - Writes completion files to: ${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions - Ensures that completion directory is in $fpath (front) BEFORE compinit
# Phase:    Plugin activation (.zshrc.add-plugins.d/)
# Toggles:  ZF_DISABLE_UV_COMPLETIONS

# ------------------------------------------------------------------------------

# Skip if user explicitly disabled this feature
if [[ "${ZF_DISABLE_UV_COMPLETIONS:-0}" == 1 ]]; then
  return 0
fi

# Idempotency guard
[[ -n ${_ZF_UV_COMPLETION_DONE:-} ]] && return 0
_ZF_UV_COMPLETION_DONE=1

# Minimal debug shim if framework not yet loaded
# zf::debug is now globally available from .zshenv.00

# Presence markers default
: "${_ZF_UV:=0}"
: "${_ZF_UVX:=0}"
: "${_ZF_UV_COMPLETION_MODE:=none}"

# Detect binaries (command -v is nounset-safe here)
if command -v uv >/dev/null 2>&1; then
  _ZF_UV=1
else
  _ZF_UV=0
fi
if command -v uvx >/dev/null 2>&1; then
  _ZF_UVX=1
else
  _ZF_UVX=0
fi

# If neither tool present, we exit early (still marking module as sourced)
if [[ $_ZF_UV -eq 0 && $_ZF_UVX -eq 0 ]]; then
  zf::debug "# [dev-python-uv] neither uv nor uvx detected – skipping"
  return 0
fi

# Determine cache dir for completions
: "${XDG_CACHE_HOME:=${HOME}/.cache}"
_uv_cache_dir="${XDG_CACHE_HOME}/zsh/completions"
_uv_tmp_file=""
_uv_out=""

# Ensure completion directory (ignore mkdir failure silently)
if [[ ! -d "${_uv_cache_dir}" ]]; then
  mkdir -p "${_uv_cache_dir}" 2>/dev/null || true
fi

# Ensure completion directory is in $fpath (prepend if absent) *before compinit*
# (Use colon boundary test to avoid partial path collisions)
_fpath_joined=":${(j.:.)fpath}:"
if [[ "${_fpath_joined}" != *":${_uv_cache_dir}:"* ]]; then
  fpath=("${_uv_cache_dir}" "${fpath[@]}")
  zf::debug "# [dev-python-uv] added completion dir to fpath: ${_uv_cache_dir}"
fi
unset _fpath_joined

# Helper: attempt a generation command, capturing stdout
_zf_uv_try_generate() {
  local cmd=("$@")
  local data
  if data="$("${cmd[@]}" 2>/dev/null)"; then
    if [[ -n "${data}" ]]; then
      print -- "${data}"
      return 0
    fi
  fi
  return 1
}

# Try multiple generation syntaxes (some forms speculative for forward compatibility)
_uv_generation_attempted=0
if [[ $_ZF_UV -eq 1 ]]; then
  for _candidate in \
    "uv generate-shell-completion zsh" \
    "uv --generate-shell-completion zsh" \
    "uv completion zsh"
  do
    _uv_generation_attempted=1
    # Split candidate into array safely
    local _arr
    _arr=(${=~_candidate})
    if _uv_out="$(_zf_uv_try_generate "${_arr[@]}")"; then
      zf::debug "# [dev-python-uv] completion generation succeeded via: ${_candidate}"
      break
    fi
    _uv_out=""
  done
fi

# If uv generation failed but uvx exists, we can *optionally* try a uvx generation
if [[ -z "${_uv_out}" && $_ZF_UVX -eq 1 ]]; then
  for _candidate in \
    "uvx --generate-shell-completion zsh" \
    "uvx generate-shell-completion zsh"
  do
    local _arr
    _arr=(${=~_candidate})
    if _uv_out="$(_zf_uv_try_generate "${_arr[@]}")"; then
      zf::debug "# [dev-python-uv] uvx completion generation succeeded via: ${_candidate}"
      break
    fi
    _uv_out=""
  done
fi

# Decide on storage vs eval
if [[ -n "${_uv_out}" ]]; then
  # Does the output look like a standard completion file (contains #compdef or compdef uv)?
  if [[ "${_uv_out}" == *"#compdef"* ]] || [[ "${_uv_out}" == *"compdef uv"* ]]; then
    _uv_tmp_file="${_uv_cache_dir}/_uv"
    {
      print -- "${_uv_out}"
    } > "${_uv_tmp_file}" 2>/dev/null || {
      # Fallback: attempt eval if write fails
      if eval "${_uv_out}" 2>/dev/null; then
        _ZF_UV_COMPLETION_MODE="eval"
        zf::debug "# [dev-python-uv] fallback eval-based completion loaded (file write failed)"
      else
        zf::debug "# [dev-python-uv] completion generation output unusable (write+eval failed)"
      fi
    }
    if [[ -f "${_uv_tmp_file}" ]]; then
      _ZF_UV_COMPLETION_MODE="file"
      zf::debug "# [dev-python-uv] completion script written: ${_uv_tmp_file}"
    fi
  else
    # Not a classic compdef script – attempt eval
    if eval "${_uv_out}" 2>/dev/null; then
      _ZF_UV_COMPLETION_MODE="eval"
      zf::debug "# [dev-python-uv] evaluated inline completion (no #compdef signature)"
    else
      zf::debug "# [dev-python-uv] generated output did not evaluate cleanly"
    fi
  fi
else
  if [[ $_ZF_UV -eq 1 ]]; then
    if [[ ${_uv_generation_attempted} -eq 1 ]]; then
      zf::debug "# [dev-python-uv] no usable completion output from generation attempts"
    else
      zf::debug "# [dev-python-uv] generation not attempted (unexpected state)"
    fi
  fi
fi

# Provide a lightweight marker function for diagnostics
# zf::uv_completion_status() - moved to .zshenv.00 for global availability

# Cleanup local temporaries (keep marker vars)
unset _uv_cache_dir _uv_tmp_file _uv_out _candidate _uv_generation_attempted

zf::debug "# [dev-python-uv] integration complete (uv=${_ZF_UV} uvx=${_ZF_UVX} mode=${_ZF_UV_COMPLETION_MODE})"

return 0
