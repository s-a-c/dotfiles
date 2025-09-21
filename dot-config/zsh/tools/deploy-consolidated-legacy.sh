#!/opt/homebrew/bin/zsh
# Deploy consolidated legacy modules as symlinks in .zshrc.d
# This replaces all existing modules with consolidated versions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZDOTDIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONSOLIDATED_DIR="$ZDOTDIR/.zshrc.d.legacy/consolidated-modules"
TARGET_DIR="$ZDOTDIR/.zshrc.d"
BACKUP_DIR="$TARGET_DIR/.deployment-backup-$(date +%Y%m%d-%H%M%S)"

echo "🚀 Deploying Consolidated Legacy Modules"
echo "========================================"
echo "Source: $CONSOLIDATED_DIR"
echo "Target: $TARGET_DIR"
echo "Backup: $BACKUP_DIR"
echo

# Verify source directory exists
if [[ ! -d "$CONSOLIDATED_DIR" ]]; then
    echo "❌ Error: Consolidated modules directory not found: $CONSOLIDATED_DIR"
    exit 1
fi

# Check if consolidated modules exist
CONSOLIDATED_MODULES=($(ls "$CONSOLIDATED_DIR"/*.zsh 2>/dev/null || true))
if [[ ${#CONSOLIDATED_MODULES[@]} -eq 0 ]]; then
    echo "❌ Error: No consolidated modules found in $CONSOLIDATED_DIR"
    exit 1
fi

echo "📋 Found ${#CONSOLIDATED_MODULES[@]} consolidated modules:"
for module in "${CONSOLIDATED_MODULES[@]}"; do
    echo "  - $(basename "$module")"
done
echo

# Create backup directory
echo "💾 Creating backup of existing modules..."
mkdir -p "$BACKUP_DIR"

# Backup existing modules (excluding already created backups and symlinks pointing to consolidated modules)
cd "$TARGET_DIR"
for file in *; do
    if [[ -e "$file" && "$file" != ".deployment-backup-"* && "$file" != ".backups" && "$file" != ".replaced-by-symlinks" ]]; then
        # Check if it's already a symlink to consolidated modules
        if [[ -L "$file" ]] && [[ "$(readlink "$file")" == *"consolidated-modules"* ]]; then
            echo "  Skipping existing consolidated symlink: $file"
            continue
        fi
        
        echo "  Backing up: $file"
        if [[ -d "$file" ]]; then
            cp -r "$file" "$BACKUP_DIR/"
        else
            cp "$file" "$BACKUP_DIR/"
        fi
    fi
done

echo "✅ Backup complete: $BACKUP_DIR"
echo

# Create deployment manifest
MANIFEST_FILE="$BACKUP_DIR/DEPLOYMENT_MANIFEST.md"
cat > "$MANIFEST_FILE" << 'MANIFEST_EOF'
# Legacy Module Consolidation Deployment

## Deployment Information
- **Date**: $(date)
- **Source**: .zshrc.d.legacy/consolidated-modules/
- **Target**: .zshrc.d/
- **Backup**: This directory

## Consolidated Modules Deployed
MANIFEST_EOF

for module in "${CONSOLIDATED_MODULES[@]}"; do
    module_name="$(basename "$module")"
    echo "- $module_name" >> "$MANIFEST_FILE"
done

cat >> "$MANIFEST_FILE" << 'MANIFEST_EOF'

## Rollback Instructions
To rollback this deployment:
1. `cd .zshrc.d`
2. `rm *.zsh` (removes symlinks)
3. `cp -r .deployment-backup-*/. .` (restores originals)
4. `rm -rf .deployment-backup-*` (cleanup)

## Verification
After deployment, verify with:
```bash
tools/test-legacy-quick.sh
```
MANIFEST_EOF

echo "📝 Created deployment manifest: $MANIFEST_FILE"
echo

# Remove existing modules (but preserve directories and non-zsh files)
echo "🧹 Removing existing modules from target directory..."
cd "$TARGET_DIR"
for file in *.zsh; do
    if [[ -e "$file" ]]; then
        echo "  Removing: $file"
        rm "$file"
    fi
done

# Create symlinks to consolidated modules
echo "🔗 Creating symlinks to consolidated modules..."
for module in "${CONSOLIDATED_MODULES[@]}"; do
    module_name="$(basename "$module")"
    relative_path="../.zshrc.d.legacy/consolidated-modules/$module_name"
    
    echo "  Linking: $module_name -> $relative_path"
    ln -sf "$relative_path" "$TARGET_DIR/$module_name"
done

echo "✅ Symlinks created successfully!"
echo

# Verify deployment
echo "🔍 Verifying deployment..."
cd "$TARGET_DIR"
LINK_COUNT=0
for link in *.zsh; do
    if [[ -L "$link" ]]; then
        target="$(readlink "$link")"
        if [[ -e "$target" ]]; then
            echo "  ✅ $link -> $target"
            ((LINK_COUNT++))
        else
            echo "  ❌ $link -> $target (BROKEN)"
        fi
    else
        echo "  ❌ $link (NOT A SYMLINK)"
    fi
done

echo
echo "📊 Deployment Summary:"
echo "  - Consolidated modules: ${#CONSOLIDATED_MODULES[@]}"
echo "  - Successfully linked: $LINK_COUNT"
echo "  - Backup location: $BACKUP_DIR"
echo

if [[ $LINK_COUNT -eq ${#CONSOLIDATED_MODULES[@]} ]]; then
    echo "🎉 DEPLOYMENT SUCCESSFUL!"
    echo
    echo "Next steps:"
    echo "1. Test the configuration: tools/test-legacy-quick.sh"
    echo "2. Try a new shell session to verify everything works"
    echo "3. If issues occur, rollback using instructions in:"
    echo "   $MANIFEST_FILE"
else
    echo "❌ DEPLOYMENT INCOMPLETE!"
    echo "Some modules may not have been linked correctly."
    echo "Check the verification output above."
    exit 1
fi
