#!/usr/bin/env zsh
# 05-emergency-zle-repair.zsh
# Emergency ZLE system repair - forces ZLE reinitialization after plugin loading

# Only run in interactive mode
[[ -o interactive ]] || return 0

# Debug helper
_zle_repair_debug() {
    [[ -n "${ZSH_DEBUG:-}" ]] && echo "[ZLE-REPAIR] $1" >&2 || true
}

_zle_repair_debug "Emergency ZLE repair starting..."

# Force ZLE module reload
zmodload -u zsh/zle 2>/dev/null || true
zmodload zsh/zle 2>/dev/null || true

# Reinitialize ZLE system
autoload -Uz zle 2>/dev/null || true

# Test if ZLE is working
_test_zle_function() {
    echo "zle test"
}

# Try to register a test widget
if zle -N _test_zle_function 2>/dev/null; then
    _zle_repair_debug "✅ ZLE system is functional"
    zle -D _test_zle_function 2>/dev/null || true
else
    _zle_repair_debug "❌ ZLE system still broken - attempting deep repair"
    
    # Deep repair: completely reinitialize ZLE
    unset ZLE_VERSION 2>/dev/null || true
    unset widgets 2>/dev/null || true
    
    # Force reload all ZLE-related modules
    zmodload -u zsh/zle zsh/complist zsh/parameter 2>/dev/null || true
    zmodload zsh/zle zsh/complist zsh/parameter 2>/dev/null || true
    
    # Reinitialize basic ZLE
    autoload -Uz zle 2>/dev/null || true
    bindkey -e 2>/dev/null || true
    
    # Test again
    if zle -N _test_zle_function 2>/dev/null; then
        _zle_repair_debug "✅ Deep repair successful"
        zle -D _test_zle_function 2>/dev/null || true
    else
        _zle_repair_debug "❌ Deep repair failed - ZLE system critically damaged"
    fi
fi

# Clean up
unfunction _test_zle_function 2>/dev/null || true
unfunction _zle_repair_debug 2>/dev/null || true

_zle_repair_debug "Emergency ZLE repair complete"
