#!/usr/bin/env zsh
# 150-MACOS-DEFAULTS-DEFERRED.ZSH (inlined from legacy 45-macos-defaults-deferred.zsh)
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}
[[ -n ${_LOADED_20_MACOS_DEFAULTS_DEFERRED:-} ]] && return 0
[[ -n ${_LOADED_PRE_MACOS_DEFAULTS_DEFERRED:-} ]] && return 0
_LOADED_PRE_MACOS_DEFAULTS_DEFERRED=1
: ${ZSH_MACOS_DEFAULTS_DEFERRED_ENABLE:=1}
: ${ZSH_MACOS_DEFAULTS_AUDIT_MODE:=shadow}
: ${ZSH_MACOS_DEFAULTS_ASYNC:=1}
_macos_defaults_audit_run() { [[ -n ${_MACOS_DEFAULTS_AUDIT_RAN:-} ]] && return 0; _MACOS_DEFAULTS_AUDIT_RAN=1; zf::debug "# [macos-defaults] run (mode=${ZSH_MACOS_DEFAULTS_AUDIT_MODE})"; if ((ZSH_MACOS_DEFAULTS_ASYNC)) && typeset -f _zsh_async_enqueue >/dev/null 2>&1; then _zsh_async_enqueue macos_defaults_audit "echo '# [macos-defaults] async shadow task'; true"; fi; typeset -f add-zsh-hook >/dev/null 2>&1 && add-zsh-hook -d precmd _macos_defaults_audit_run 2>/dev/null || true; }
_macos_defaults_audit_queue() { ((ZSH_MACOS_DEFAULTS_DEFERRED_ENABLE)) || { zf::debug "# [macos-defaults] disabled"; return 0; }; if [[ -z ${_MACOS_DEFAULTS_AUDIT_HOOKED:-} ]]; then _MACOS_DEFAULTS_AUDIT_HOOKED=1; if typeset -f add-zsh-hook >/dev/null 2>&1; then add-zsh-hook precmd _macos_defaults_audit_run; else typeset -ga precmd_functions; precmd_functions+=(_macos_defaults_audit_run); fi; zf::debug "# [macos-defaults] deferred audit hook registered"; fi }
if [[ ${OSTYPE} == darwin* ]] && [[ "$TERM_PROGRAM" != WarpTerminal ]]; then _macos_defaults_audit_queue; zf::debug "# [pre-plugin] macOS defaults audit queued"; else [[ "$TERM_PROGRAM" == WarpTerminal ]] && zf::debug "# [pre-plugin] macOS defaults skipped (Warp)" || zf::debug "# [pre-plugin] macOS defaults skipped (non-macos)"; fi
readonly _LOADED_20_MACOS_DEFAULTS_DEFERRED=1
return 0
