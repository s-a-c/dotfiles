#!/usr/bin/env zsh
# 340-neovim-environment.zsh - Neovim ecosystem integration (Hybrid alias gating)
# (Renumbered from 300- to free 300–330 range for Phase 4 productivity modules.)
# Phase 5 (Neovim Ecosystem)
# Compliant with AGENT.md policy (checksum acknowledgement handled at higher layer)

# PURPOSE:
#   Provide editor defaults (EDITOR/VISUAL/GIT_EDITOR) and expose profile-specific
#   Neovim launch aliases ONLY when corresponding configuration directories exist,
#   while also offering a generic `nvprofile` launcher for exploratory use.

# HYBRID GATING STRATEGY:
#   - Existing-only aliases: defined only if $XDG_CONFIG_HOME/nvim-<Profile> exists.
#   - Generic dispatcher: `nvprofile <ProfileTail> [args]` attempts NVIM_APPNAME=nvim-<ProfileTail>.
#   - Prevents alias clutter + accidental creation of blank profile trees.

# RESERVED PROFILE NAMES (checked): Lazyman, Kickstart, Lazyvim, Mini, NvChad

# SAFETY / NOUNSET:
#   - All variable expansions guarded with ${var:-}
#   - Functions are namespaced (zf::) except user-facing `nvprofile`.

# VALIDATION (Manual):
#   alias | grep -E 'nvim-|lmvim|ksnvim|lznvim|minvim|nvnvim'
#   nvprofile Lazyman :checkhealth  # if profile exists
#   echo $EDITOR

if [[ "${ZF_DISABLE_NVIM:-0}" == 1 ]]; then
  return 0
fi

export EDITOR="nvim"
export VISUAL="nvim"
export GIT_EDITOR="nvim"

_zf_nv_xdg_cfg="${XDG_CONFIG_HOME:-$HOME/.config}"

zf::nvim_alias_if_exists() {
  local prof_dir="$1" alname="$2"
  [[ -z "$prof_dir" || -z "$alname" ]] && return 0
  local full="${_zf_nv_xdg_cfg}/${prof_dir}"
  if [[ -d "$full" ]]; then
    alias "$alname"="NVIM_APPNAME=${prof_dir} nvim"
  fi
}

zf::nvim_alias_if_exists nvim-Lazyman   lmvim
zf::nvim_alias_if_exists nvim-Kickstart ksnvim
zf::nvim_alias_if_exists nvim-Lazyvim   lznvim
zf::nvim_alias_if_exists nvim-Mini      minvim
zf::nvim_alias_if_exists nvim-NvChad    nvnvim

nvprofile() {
  local tail="$1"; shift || true
  if [[ -z "$tail" ]]; then
    print -u2 'Usage: nvprofile <ProfileTail e.g. Lazyman|Kickstart> [args]'
    return 2
  fi
  local prof="nvim-${tail}"
  local dir="${_zf_nv_xdg_cfg}/${prof}"
  if [[ -d "$dir" ]]; then
    NVIM_APPNAME="$prof" nvim "$@"
  else
    print -u2 "nvprofile: profile $prof not found (${dir})"
    return 1
  fi
}

# Bob (Neovim version manager) integration (Decisions: D6A optional env sourcing, D18A unalias guard)
if [[ -d "${HOME}/.local/share/bob" ]]; then
  # Marker: path presence
  _ZF_BOB_PATH=1
  export PATH="${HOME}/.local/share/bob:$PATH"

  # Resolve potential conflicting user alias named 'bob' (e.g. Laravel Sail) before invoking binary
  if (( ${+aliases[bob]} )); then
    unalias bob 2>/dev/null || true
    _ZF_BOB_ALIAS_CLEARED=1
  else
    _ZF_BOB_ALIAS_CLEARED=0
  fi

  # Standard bob config path (do not overwrite if user already set BOB_CONFIG)
  : "${BOB_CONFIG:=${XDG_CONFIG_HOME:-${HOME}/.config}/bob/config.json}"
  export BOB_CONFIG

  # Optional env script sourcing (guarded; skip if user opts out)
  _ZF_BOB_ENV_SOURCED=0
  if [[ "${ZF_DISABLE_BOB_ENV_SOURCE:-0}" != 1 ]]; then
    _bob_env_file="${XDG_DATA_HOME:-${HOME}/.local/share}/bob/env/env.sh"
    if [[ -f "${_bob_env_file}" ]]; then
      # shellcheck disable=SC1090
      source "${_bob_env_file}" 2>/dev/null || true
      _ZF_BOB_ENV_SOURCED=1
    fi
    unset _bob_env_file
  fi

  export _ZF_BOB_PATH _ZF_BOB_ALIAS_CLEARED _ZF_BOB_ENV_SOURCED
fi

if [[ -r "${_zf_nv_xdg_cfg}/nvim-Lazyman/.lazymanrc" ]]; then
  source "${_zf_nv_xdg_cfg}/nvim-Lazyman/.lazymanrc"
fi
if [[ -r "${_zf_nv_xdg_cfg}/nvim-Lazyman/.nvimsbind" ]]; then
  # Only source if file does not rely on bash-only 'bind' in a pure zsh context.
  if ! command -v bind >/dev/null 2>&1; then
    bind() { return 0; }
    _ZF_NVIM_BIND_SHIM=1
  fi
  source "${_zf_nv_xdg_cfg}/nvim-Lazyman/.nvimsbind"
  if [[ -n "${_ZF_NVIM_BIND_SHIM:-}" ]]; then
    unset -f bind 2>/dev/null || true
    unset _ZF_NVIM_BIND_SHIM 2>/dev/null || true
  fi
fi

if [[ "${ZF_NEOVIM_DEBUG:-0}" == 1 ]]; then
  zf::debug "# [neovim-env] EDITOR=$EDITOR profiles=$(alias | grep -E 'nvim-|lmvim|ksnvim|lznvim|minvim|nvnvim' | wc -l)"
fi

unset _zf_nv_xdg_cfg
