#!/usr/bin/env zsh
# Safe Zgenom Cache Recreation Script
# This script safely recreates the zgenom cache while preserving plugin integrity

set -euo pipefail

echo "🔄 Starting safe zgenom cache recreation..."

# Store current directory
ORIGINAL_DIR="$(pwd)"

# Set up environment
export ZDOTDIR="${ZDOTDIR:-${HOME}/.config/zsh}"
export ZGEN_DIR="${ZGEN_DIR:-${HOME}/.zgenom}"

echo "📁 Using ZDOTDIR: $ZDOTDIR"
echo "📁 Using ZGEN_DIR: $ZGEN_DIR"

# Backup existing cache if it exists
if [[ -f "$ZGEN_DIR/init.zsh" ]]; then
    BACKUP_DIR="$ZDOTDIR/cache-backup-$(date +%Y%m%d_%H%M%S)"
<<<<<<< HEAD
        zf::debug "💾 Backing up existing cache to: $BACKUP_DIR"
=======
        zsh_debug_echo "💾 Backing up existing cache to: $BACKUP_DIR"
>>>>>>> origin/develop
    mkdir -p "$BACKUP_DIR"
    cp -r "$ZGEN_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true
fi

# Clean existing cache
echo "🧹 Cleaning existing cache..."
rm -rf "$ZGEN_DIR/init.zsh" "$ZGEN_DIR/sources" "$ZGEN_DIR"/*-completion "$ZGEN_DIR/init.zsh.zwc" 2>/dev/null || true

# Clean completion dump files - these can become stale and cause issues
echo "🧹 Cleaning completion dump files..."
rm -rf "$ZDOTDIR"/.zcompdump* "$HOME"/.zcompdump* "${ZSH_CACHE_DIR:-$HOME/.cache/zsh}"/.zcompdump* 2>/dev/null || true

# Clean any other completion-related cache files
echo "🧹 Cleaning additional completion caches..."
rm -rf "$ZDOTDIR/.completions" "$ZDOTDIR/.zsh/cache" "$HOME/.zsh/cache" 2>/dev/null || true

# Ensure zgenom is available
ZGENOM_SOURCE_FILE="$ZDOTDIR/.zqs-zgenom/zgenom.zsh"
if [[ ! -f "$ZGENOM_SOURCE_FILE" ]]; then
<<<<<<< HEAD
        zf::debug "❌ Zgenom not found at: $ZGENOM_SOURCE_FILE"
        zf::debug "   Run this first to install zgenom:"
        zf::debug "   cd $ZDOTDIR && git clone https://github.com/jandamm/zgenom.git .zqs-zgenom"
=======
        zsh_debug_echo "❌ Zgenom not found at: $ZGENOM_SOURCE_FILE"
        zsh_debug_echo "   Run this first to install zgenom:"
        zsh_debug_echo "   cd $ZDOTDIR && git clone https://github.com/jandamm/zgenom.git .zqs-zgenom"
>>>>>>> origin/develop
    exit 1
fi

echo "✅ Zgenom found at: $ZGENOM_SOURCE_FILE"

# Source zgenom
echo "📥 Loading zgenom..."
source "$ZGENOM_SOURCE_FILE"

# Check if zgenom functions are available
if ! command -v zgenom >/dev/null 2>&1; then
<<<<<<< HEAD
        zf::debug "❌ Zgenom functions not available after sourcing"
=======
        zsh_debug_echo "❌ Zgenom functions not available after sourcing"
>>>>>>> origin/develop
    exit 1
fi

echo "✅ Zgenom functions loaded successfully"

# Force regeneration by ensuring zgenom thinks no cache exists
echo "🔄 Forcing cache regeneration..."

# Source the setup script to trigger cache recreation
if [[ -f "$ZDOTDIR/.zgen-setup" ]]; then
<<<<<<< HEAD
        zf::debug "📥 Loading plugin configuration from .zgen-setup..."
    source "$ZDOTDIR/.zgen-setup"
else
        zf::debug "❌ .zgen-setup not found at: $ZDOTDIR/.zgen-setup"
=======
        zsh_debug_echo "📥 Loading plugin configuration from .zgen-setup..."
    source "$ZDOTDIR/.zgen-setup"
else
        zsh_debug_echo "❌ .zgen-setup not found at: $ZDOTDIR/.zgen-setup"
>>>>>>> origin/develop
    exit 1
fi

# Verify cache was created
if [[ -f "$ZGEN_DIR/init.zsh" ]]; then
<<<<<<< HEAD
        zf::debug "✅ Cache successfully recreated"
        zf::debug "📊 Cache stats:"
        zf::debug "   Size: $(du -sh "$ZGEN_DIR/init.zsh" | cut -f1)"
        zf::debug "   Lines: $(wc -l < "$ZGEN_DIR/init.zsh")"
        zf::debug "   Plugins loaded: $(grep -c "zsh_loaded_plugins+=" "$ZGEN_DIR/init.zsh" 2>/dev/null || zf::debug "unknown")"
else
        zf::debug "❌ Cache recreation failed - init.zsh not created"
=======
        zsh_debug_echo "✅ Cache successfully recreated"
        zsh_debug_echo "📊 Cache stats:"
        zsh_debug_echo "   Size: $(du -sh "$ZGEN_DIR/init.zsh" | cut -f1)"
        zsh_debug_echo "   Lines: $(wc -l < "$ZGEN_DIR/init.zsh")"
        zsh_debug_echo "   Plugins loaded: $(grep -c "zsh_loaded_plugins+=" "$ZGEN_DIR/init.zsh" 2>/dev/null || zsh_debug_echo "unknown")"
else
        zsh_debug_echo "❌ Cache recreation failed - init.zsh not created"
>>>>>>> origin/develop
    exit 1
fi

# Restore original directory
cd "$ORIGINAL_DIR" 2>/dev/null || {
<<<<<<< HEAD
        zf::debug "⚠️  Warning: Could not restore original directory: $ORIGINAL_DIR"
=======
        zsh_debug_echo "⚠️  Warning: Could not restore original directory: $ORIGINAL_DIR"
>>>>>>> origin/develop
}

echo "🎉 Zgenom cache recreation completed successfully!"
echo ""
echo "Next steps:"
echo "1. Test the new cache: exec zsh"
echo "2. Check for any plugin loading errors"
echo "3. Verify all expected plugins are loaded"
