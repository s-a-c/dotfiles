#!/usr/bin/env zsh
# Zsh Configuration Health Check
# UPDATED: Consistent with .zshenv configuration

# Source .zshenv to ensure consistent environment variables
[[ -f "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv" ]] && source "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv"

FAILURES=()

# Use zsh_debug_echo from .zshenv if available
if declare -f zsh_debug_echo >/dev/null 2>&1; then
    zsh_debug_echo "# [health-check] Starting health check with .zshenv integration"
    # Check for numbered files using ZDOTDIR
    if [[ -f "${ZDOTDIR}/2" ]] || [[ -f "${ZDOTDIR}/3" ]]; then
        zsh_debug_echo "Warning: Numbered files detected - check for redirection typos"
    fi
else
    [[ "$ZSH_DEBUG" == "1" ]] && {
            zsh_debug_echo "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
        if [[ -f "${ZDOTDIR:-$HOME}/2" ]] || [[ -f "${ZDOTDIR:-$HOME}/3" ]]; then
                zsh_debug_echo "Warning: Numbered files detected - check for redirection typos"
        fi
    }
fi

echo "🔍 Zsh Configuration Health Check"
echo "================================"

# Use ZDOTDIR from .zshenv for consistent paths
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"

# Check syntax of main files using ZDOTDIR
for file in "${ZDOTDIR}"/{.zshenv,.zshrc} "${ZDOTDIR}"/.zshrc.d/*.zsh; do
    if [[ -f "$file" ]]; then
        if zsh -n "$file" 2>/dev/null; then
                zsh_debug_echo "✅ $file - Syntax OK"
        else
                zsh_debug_echo "❌ $file - Syntax Error"; FAILURES+="syntax:$file"
        fi
    fi
done

# Check for exposed credentials using ZDOTDIR
if grep -r "sk-" "${ZDOTDIR}/" --exclude-dir=.env 2>/dev/null; then
        zsh_debug_echo "⚠️  Possible exposed API keys found!"; FAILURES+="secrets"
else
        zsh_debug_echo "✅ No exposed API keys detected"
fi

# Check PATH sanity
if     zsh_debug_echo $PATH | grep -q "/usr/bin"; then
        zsh_debug_echo "✅ System PATH includes /usr/bin"
else
        zsh_debug_echo "❌ System PATH missing /usr/bin"; FAILURES+="path:usrbin"
fi

# Check zgenom setup using ZGEN_DIR from .zshenv
if [[ -n "$ZGEN_DIR" && -d "$ZGEN_DIR" ]]; then
        zsh_debug_echo "✅ zgenom directory exists: $ZGEN_DIR"
else
        zsh_debug_echo "⚠️  zgenom directory not found at ${ZGEN_DIR:-'(not set)'}"; FAILURES+="zgenom:missing"
fi

# Check ZSH_COMPDUMP from .zshenv
if [[ -n "$ZSH_COMPDUMP" ]]; then
    if [[ -f "$ZSH_COMPDUMP" ]]; then
            zsh_debug_echo "✅ Completion dump exists: $ZSH_COMPDUMP"
    else
            zsh_debug_echo "⚠️  Completion dump missing: $ZSH_COMPDUMP"; FAILURES+="completion:missing"
    fi
else
        zsh_debug_echo "⚠️  ZSH_COMPDUMP not set"; FAILURES+="completion:notset"
fi

# Check startup time (single run heuristic)
startup_time=$(time zsh -i -c exit 2>&1 | grep real | awk '{print $2}')
echo "⏱️  Startup time: $startup_time"

# Use safe_date from .zshenv if available
if declare -f safe_date >/dev/null 2>&1; then
        zsh_debug_echo "✅ safe_date function available"
        zsh_debug_echo "📅 Current time: $(safe_date)"
else
        zsh_debug_echo "⚠️  safe_date function not available"; FAILURES+="functions:safe_date"
fi

# Summary
if [[ ${#FAILURES} -eq 0 ]]; then
        zsh_debug_echo "🎉 All health checks passed!"
else
        zsh_debug_echo "❌ Health check failures: ${FAILURES[*]}"
    exit 1
fi

echo "\n💡 Recommendations:
- Run 'zsh tools/health-check.zsh' monthly
- Keep startup time under 2 seconds (optimize after completion/styling phases)
- Update plugins quarterly: 'zgenom update'
- Backup config before major changes
- Address any Docs link failures promptly (broken links degrade navigability)
"
