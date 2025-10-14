#!/usr/bin/env zsh
# Zsh Cache Clearing Script
# Use this to force a completely clean Zsh reload after configuration changes
# UPDATED: Consistent with .zshenv configuration

# Source .zshenv to ensure consistent environment variables
[[ -f "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv" ]] && source "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv"

echo "🧹 Clearing all Zsh caches and compiled files..."

# Use ZDOTDIR from .zshenv with fallback
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"

# Clear completion dumps using ZSH_COMPDUMP from .zshenv
if [[ -n "$ZSH_COMPDUMP" ]]; then
    rm -f "${ZSH_COMPDUMP}"* 2>/dev/null
<<<<<<< HEAD
        zf::debug "✅ Completion dumps cleared (${ZSH_COMPDUMP}*)"
else
    # Fallback to ZDOTDIR if ZSH_COMPDUMP not set
    rm -f "${ZDOTDIR}"/.zcompdump* 2>/dev/null
        zf::debug "✅ Completion dumps cleared (${ZDOTDIR}/.zcompdump*)"
=======
        zsh_debug_echo "✅ Completion dumps cleared (${ZSH_COMPDUMP}*)"
else
    # Fallback to ZDOTDIR if ZSH_COMPDUMP not set
    rm -f "${ZDOTDIR}"/.zcompdump* 2>/dev/null
        zsh_debug_echo "✅ Completion dumps cleared (${ZDOTDIR}/.zcompdump*)"
>>>>>>> origin/develop
fi

# Clear compiled Zsh files using ZDOTDIR
find "${ZDOTDIR}" -name "*.zwc" -delete 2>/dev/null
echo "✅ Zsh compiled files cleared"

# Clear zgenom caches using ZGEN_DIR from .zshenv
if [[ -n "$ZGEN_DIR" && -d "$ZGEN_DIR" ]]; then
    rm -f "${ZGEN_DIR}/sources.zsh" 2>/dev/null
    rm -rf "${ZGEN_DIR}"/**/**.zwc 2>/dev/null
<<<<<<< HEAD
        zf::debug "✅ Zgenom caches cleared (${ZGEN_DIR})"
=======
        zsh_debug_echo "✅ Zgenom caches cleared (${ZGEN_DIR})"
>>>>>>> origin/develop
else
    # Fallback to ZDOTDIR/.zgenom
    rm -f "${ZDOTDIR}/.zgenom/sources.zsh" 2>/dev/null
    rm -rf "${ZDOTDIR}/.zgenom"/**/**.zwc 2>/dev/null
<<<<<<< HEAD
        zf::debug "✅ Zgenom caches cleared (${ZDOTDIR}/.zgenom)"
=======
        zsh_debug_echo "✅ Zgenom caches cleared (${ZDOTDIR}/.zgenom)"
>>>>>>> origin/develop
fi

# Clear .ng system files and caches using ZDOTDIR
rm -f "${ZDOTDIR}"/.ng-* 2>/dev/null
echo "✅ NG cache files cleared"

# Clear command hash and rehash
hash -df 2>/dev/null
rehash 2>/dev/null
echo "✅ Command hash cleared and rehashed"

# Unload problematic functions from memory
unfunction select_intelligent_ng_fallback 2>/dev/null
unfunction execute_ng_fallback_strategy 2>/dev/null
unfunction check_ng_prevention_readiness 2>/dev/null
unfunction validate_ng_prevention_effectiveness 2>/dev/null
unfunction initialize_ng_failure_patterns 2>/dev/null
unfunction analyze_ng_system_patterns 2>/dev/null
echo "✅ NG functions unloaded from memory"

# Clear any plugin manager caches using has_command from .zshenv if available
if declare -f has_command >/dev/null 2>&1; then
    if has_command zgenom; then
<<<<<<< HEAD
            zf::debug "🔄 Resetting zgenom..."
        zgenom reset >/dev/null 2>&1
            zf::debug "✅ Zgenom reset complete"
    fi
else
    if command -v zgenom >/dev/null 2>&1; then
            zf::debug "🔄 Resetting zgenom..."
        zgenom reset >/dev/null 2>&1
            zf::debug "✅ Zgenom reset complete"
=======
            zsh_debug_echo "🔄 Resetting zgenom..."
        zgenom reset >/dev/null 2>&1
            zsh_debug_echo "✅ Zgenom reset complete"
    fi
else
    if command -v zgenom >/dev/null 2>&1; then
            zsh_debug_echo "🔄 Resetting zgenom..."
        zgenom reset >/dev/null 2>&1
            zsh_debug_echo "✅ Zgenom reset complete"
>>>>>>> origin/develop
    fi
fi

echo ""
echo "🎉 Cache clearing complete!"
echo "💡 Now open a fresh terminal tab or run 'exec zsh' to test"
echo ""
