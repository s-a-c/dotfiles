#!/usr/bin/env zsh
# Comprehensive zsh startup debugging script
# This will trace exactly where the shell is failing
# UPDATED: Consistent with .zshenv and ZDOTDIR structure

# Source .zshenv to ensure consistent environment
[[ -f "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv" ]] && source "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv"

echo "🔍 Setting up comprehensive zsh startup debugging..."

# Use consistent paths from .zshenv
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
ZSHRC_FILE="$ZDOTDIR/.zshrc"

# Create a debugging wrapper for .zshrc
cat > "${ZSHRC_FILE}.debug" << 'EOF'
#!/usr/bin/env zsh
# Debug wrapper for zsh startup - traces every step

# Enable comprehensive debugging
set -x
setopt XTRACE
setopt VERBOSE

# Use ZSH_LOG_DIR from .zshenv, with fallback
DEBUG_LOG="${ZSH_LOG_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/zsh}/startup-debug-$(safe_date "+%Y%m%d_%H%M%S" 2>/dev/null || date "+%Y%m%d_%H%M%S").log"
mkdir -p "$(dirname "$DEBUG_LOG")"

# Redirect all debug output to log file
exec 2> >(tee -a "$DEBUG_LOG")

echo "=== ZSH STARTUP DEBUG SESSION START ===" >&2
echo "Timestamp: $(safe_date 2>/dev/null || date)" >&2
echo "ZSH Version: $ZSH_VERSION" >&2
echo "Shell: $0" >&2
echo "Arguments: $@" >&2
echo "PWD: $PWD" >&2
echo "HOME: $HOME" >&2
echo "USER: $USER" >&2
echo "ZDOTDIR: $ZDOTDIR" >&2
echo "ZSH_CACHE_DIR: $ZSH_CACHE_DIR" >&2
echo "ZSH_LOG_DIR: $ZSH_LOG_DIR" >&2
echo "========================================" >&2

# Function to trace file sourcing
trace_source() {
    local file="$1"
        zf::debug ">>> ATTEMPTING TO SOURCE: $file"
    if [[ -f "$file" ]]; then
            zf::debug ">>> FILE EXISTS: $file"
            zf::debug ">>> FILE SIZE: $(wc -c < "$file") bytes"
            zf::debug ">>> FILE PERMISSIONS: $(ls -la "$file")"
        source "$file"
        local exit_code=$?
            zf::debug ">>> SOURCE COMPLETED: $file (exit code: $exit_code)"
        return $exit_code
    else
            zf::debug ">>> FILE NOT FOUND: $file"
        return 1
    fi
}

# Source .zshenv first (should already be loaded)
echo ">>> SOURCING .zshenv" >&2
trace_source "${ZDOTDIR}/.zshenv"

# Now attempt to source the original .zshrc step by step
echo ">>> SOURCING ORIGINAL .zshrc" >&2
trace_source "${ZDOTDIR}/.zshrc.original"

echo "=== ZSH STARTUP DEBUG SESSION END ===" >&2
EOF

# Backup original .zshrc
if [[ -f "$ZSHRC_FILE" ]]; then
    cp "$ZSHRC_FILE" "${ZSHRC_FILE}.original"
        zf::debug "✅ Backed up original .zshrc to ${ZSHRC_FILE}.original"
fi

# Replace .zshrc with debug version
cp "${ZSHRC_FILE}.debug" "$ZSHRC_FILE"

echo "✅ Created debug .zshrc at $ZSHRC_FILE"
echo ""
echo "🎯 Next steps:"
echo "1. Start a new zsh session to trigger debug tracing"
echo "2. Check the debug log at: ${ZSH_LOG_DIR}/startup-debug-*.log"
echo "3. Run 'restore-original-zshrc' to restore normal operation"
echo ""
echo "💡 The debug log will show exactly where startup fails"

# Create restore function in current session
cat >> "${ZSHRC_FILE}.debug" << 'EOF'

# Function to restore original configuration
restore-original-zshrc() {
    if [[ -f "${ZDOTDIR}/.zshrc.original" ]]; then
        cp "${ZDOTDIR}/.zshrc.original" "${ZDOTDIR}/.zshrc"
            zf::debug "✅ Restored original .zshrc"
            zf::debug "💡 Start a new shell session to use normal configuration"
    else
            zf::debug "❌ No original .zshrc backup found"
        return 1
    fi
}
EOF
