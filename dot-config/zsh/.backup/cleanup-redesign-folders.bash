#!/usr/bin/env bash
set -euo pipefail

echo "=== CLEANING UP REDESIGN FOLDERS ==="
echo "Moving backup files and non-executable files to appropriate locations..."
echo ""

# Create backup directories if they don't exist
mkdir -p .zshrc.d.REDESIGN/.archive
mkdir -p .zshrc.pre-plugins.d.REDESIGN/.archive

echo "🧹 Post-plugin REDESIGN cleanup..."

# Move backup files to archive
if ls .zshrc.d.REDESIGN/*.sentinel-backup.* >/dev/null 2>&1; then
    echo "  Moving sentinel backup files to archive..."
    mv .zshrc.d.REDESIGN/*.sentinel-backup.* .zshrc.d.REDESIGN/.archive/ 2>/dev/null || true
fi

# Move duplicate files (keeping the active ones)
duplicates_post=(
    "00-security-integrity.zsh"  # Keep the main one, archive duplicates
    "05-interactive-options.zsh" # These seem to be older versions
    "10-core-functions.zsh"
    "20-essential-plugins.zsh"
    "30-development-env.zsh"
    "40-runtime-optimization.zsh"
    "60-ui-prompt.zsh"
    "70-shim-removal.zsh"
    "96-deferred-dispatch.zsh"
    "97-idle-trigger.zsh"
)

# Keep main modules, move older duplicates to archive
for dup in "${duplicates_post[@]}"; do
    if [[ -f ".zshrc.d.REDESIGN/$dup" ]]; then
        echo "  Moving $dup to archive (appears to be older version)"
        mv ".zshrc.d.REDESIGN/$dup" ".zshrc.d.REDESIGN/.archive/" 2>/dev/null || true
    fi
done

echo "🧹 Pre-plugin REDESIGN cleanup..."

# Move duplicate/older pre-plugin files
duplicates_pre=(
    "05-fzf-init.zsh"           # Older version, keep 10-fzf-initialization.zsh
    "10-lazy-framework.zsh"     # Older version, keep 15-lazy-framework.zsh
    "15-node-runtime-env.zsh"   # Older version, keep 20-node-runtime.zsh
    "20-macos-defaults-deferred.zsh" # Older version, keep 25-macos-integration.zsh
    "25-lazy-integrations.zsh"  # Older version, keep 30-development-integrations.zsh
    "30-ssh-agent.zsh"         # Older version, keep 35-ssh-and-security.zsh
    "40-pre-plugin-reserved.zsh" # Duplicate, keep the 80- version
)

for dup in "${duplicates_pre[@]}"; do
    if [[ -f ".zshrc.pre-plugins.d.REDESIGN/$dup" ]]; then
        echo "  Moving $dup to archive (appears to be older version)"
        mv ".zshrc.pre-plugins.d.REDESIGN/$dup" ".zshrc.pre-plugins.d.REDESIGN/.archive/" 2>/dev/null || true
    fi
done

echo ""
echo "🔍 Current active modules after cleanup:"

echo ""
echo "Pre-plugin modules:"
ls -1 .zshrc.pre-plugins.d.REDESIGN/*.zsh | sort

echo ""
echo "Post-plugin modules:"
ls -1 .zshrc.d.REDESIGN/*.zsh | sort

echo ""
echo "📁 Archived files:"
echo "Pre-plugin archives: $(ls -1 .zshrc.pre-plugins.d.REDESIGN/.archive/ 2>/dev/null | wc -l) files"
echo "Post-plugin archives: $(ls -1 .zshrc.d.REDESIGN/.archive/ 2>/dev/null | wc -l) files"

echo ""
echo "✅ REDESIGN folder cleanup complete!"
echo ""
echo "Active module summary:"
echo "- Pre-plugin: $(ls -1 .zshrc.pre-plugins.d.REDESIGN/*.zsh 2>/dev/null | wc -l) modules"
echo "- Post-plugin: $(ls -1 .zshrc.d.REDESIGN/*.zsh 2>/dev/null | wc -l) modules"