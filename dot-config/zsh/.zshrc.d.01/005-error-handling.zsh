#!/usr/bin/env zsh
# Filename: 005-error-handling.zsh
# Purpose:  Enhanced error message system with context and solution suggestions (P4.1)
# Phase:    Post-plugin (.zshrc.d/)

# Ensure this loads early to be available for other modules
[[ -n ${_ZF_ERROR_HANDLING_DONE:-} ]] && return 0
_ZF_ERROR_HANDLING_DONE=1

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# ==============================================================================
# Enhanced Error Messaging Functions
# ==============================================================================

# Display enhanced error with emoji, context, and suggestions
zf::error() {
    local message="$1"
    local context="${2:-}"
    local suggestion="${3:-}"
    local doc_link="${4:-}"
    
    echo "❌ Error: $message" >&2
    
    if [[ -n "$context" ]]; then
        echo "   Context: $context" >&2
    fi
    
    if [[ -n "$suggestion" ]]; then
        echo "   💡 Try: $suggestion" >&2
    fi
    
    if [[ -n "$doc_link" ]]; then
        echo "   📖 See: $doc_link" >&2
    fi
}

# Display warning with emoji
zf::warn() {
    local message="$1"
    local suggestion="${2:-}"
    
    echo "⚠️  Warning: $message" >&2
    
    if [[ -n "$suggestion" ]]; then
        echo "   💡 Suggestion: $suggestion" >&2
    fi
}

# Display info message
zf::info() {
    local message="$1"
    echo "ℹ️  Info: $message" >&2
}

# Display success message
zf::success() {
    local message="$1"
    echo "✅ Success: $message" >&2
}

# Plugin-specific error handler
zf::plugin_error() {
    local plugin_name="$1"
    local error_type="${2:-failed to load}"
    
    zf::error "Plugin '$plugin_name' $error_type" \
        "Plugin may not be installed or zgenom cache may be stale" \
        "zgenom reset && source ~/.zshrc" \
        "docs/130-troubleshooting.md#plugin-problems"
}

# Command not found enhanced handler
zf::command_not_found_error() {
    local command="$1"
    local package_hint="${2:-}"
    
    if [[ -n "$package_hint" ]]; then
        zf::error "Command '$command' not found" \
            "$package_hint may need to be installed" \
            "brew install $package_hint  # or your package manager" \
            ""
    else
        zf::error "Command '$command' not found" \
            "Required dependency may be missing" \
            "Check if package is installed: which $command" \
            ""
    fi
}

# Permission error handler
zf::permission_error() {
    local file_or_dir="$1"
    local operation="${2:-access}"
    
    zf::error "Permission denied: $operation $file_or_dir" \
        "File/directory permissions may be too restrictive" \
        "chmod 755 $(dirname $file_or_dir) && chmod 644 $file_or_dir" \
        ""
}

# Path error handler
zf::path_error() {
    local path="$1"
    local expected="${2:-file}"
    
    zf::error "Path not found: $path" \
        "Expected $expected does not exist" \
        "Verify path spelling and existence: ls -la $(dirname $path)" \
        ""
}

# Make all error functions readonly
readonly -f zf::error 2>/dev/null || true
readonly -f zf::warn 2>/dev/null || true
readonly -f zf::info 2>/dev/null || true
readonly -f zf::success 2>/dev/null || true
readonly -f zf::plugin_error 2>/dev/null || true
readonly -f zf::command_not_found_error 2>/dev/null || true
readonly -f zf::permission_error 2>/dev/null || true
readonly -f zf::path_error 2>/dev/null || true

zf::debug "# [error-handling] Enhanced error messaging system loaded"

return 0

