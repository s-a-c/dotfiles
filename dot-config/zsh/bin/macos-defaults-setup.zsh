#!/opt/homebrew/bin/zsh
#=============================================================================
# File: macos-defaults-setup.zsh
# Purpose: 1.1 Configure macOS system defaults in a deferred, non-startup manner
# Dependencies: macOS (Darwin), defaults command
# Author: Configuration management system
# Last Modified: 2025-08-20
#=============================================================================

# 1.1.1 Load Source/Execute Detection Utilities (if available)
{
    DETECTION_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00-core/01-source-execute-detection.zsh"
    if [ -r "$DETECTION_SCRIPT" ]; then
        # Ensure library runs in normal mode
        export ZSH_SOURCE_EXECUTE_TESTING=false
        source "$DETECTION_SCRIPT"
    fi
}

# 1.2 Working Directory Management - Save current working directory
export ORIGINAL_CWD="$(pwd)"

# 1.3 Comprehensive Logging Setup
_setup_logging() {
    local log_date=$(date -u +%Y-%m-%d)
    local log_time=$(date -u +%H-%M-%S)
    export LOG_DIR="/Users/s-a-c/.config/zsh/logs/$log_date"
    export LOG_FILE="$LOG_DIR/macos-defaults-setup_$log_time.log"
    
    # Create log directory
    mkdir -p "$LOG_DIR"
    
    echo "==============================================================================  "
    echo "macOS Defaults Setup Script Execution"
    echo "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "Log file: $LOG_FILE"
    echo "=============================================================================="
}

# 1.4 macOS System Defaults Configuration
_apply_macos_defaults() {
    echo ""
    echo "🍎 Applying macOS system defaults..."
    
    # Export current defaults for backup/comparison
    echo "📥 Backing up current defaults..."
    defaults read > "${ZDOTDIR:-$HOME}/saved_macos_defaults.plist"
    
    echo "⚙️  Setting macOS defaults..."
    
    # Global settings
    defaults write -g NSWindowShouldDragOnGesture YES
    
    # Desktop Services
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    
    # Dock settings
    defaults write com.apple.dock "mru-spaces" -bool "false"
    defaults write com.apple.dock autohide -bool true
    
    # Finder settings
    defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
    defaults write com.apple.Finder AppleShowAllFiles -bool true
    defaults write com.apple.finder DisableAllAnimations -bool true
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
    defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
    defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
    defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false
    defaults write com.apple.finder ShowStatusBar -bool false
    
    # Security and LaunchServices
    defaults write com.apple.LaunchServices LSQuarantine -bool false
    
    # Mail settings
    defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false
    
    # Network Browser
    defaults write com.apple.NetworkBrowser BrowseAllInterfaces 1
    
    # Safari settings
    defaults write com.apple.Safari AutoOpenSafeDownloads -bool false
    defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true
    defaults write com.apple.Safari IncludeDevelopMenu -bool true
    defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
    
    # Screen capture settings
    defaults write com.apple.screencapture disable-shadow -bool true
    defaults write com.apple.screencapture location -string "$HOME/Desktop"
    defaults write com.apple.screencapture type -string "png"
    
    # Spaces
    defaults write com.apple.spaces spans-displays -bool false
    
    # Time Machine
    defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool YES
    
    # Global Domain settings
    defaults write NSGlobalDomain _HIHideMenuBar -bool true
    defaults write NSGlobalDomain AppleAccentColor -int 1
    defaults write NSGlobalDomain AppleHighlightColor -string "0.65098 0.85490 0.58431"
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
    defaults write NSGlobalDomain KeyRepeat -int 1
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
    defaults write NSGlobalDomain WebKitDeveloperExtras -bool true
    
    # Fix for MX Master 3S (requires sudo - skip if not available)
    echo "🖱️  Applying MX Master 3S Bluetooth fix (requires sudo)..."
    if sudo -n true 2>/dev/null; then
        sudo defaults write /Library/Preferences/com.apple.airport.bt.plist bluetoothCoexMgmt Hybrid
        echo "   ✅ MX Master 3S fix applied successfully"
    else
        echo "   ⚠️  Skipping MX Master 3S fix - sudo not available or requires password"
    fi
    
    echo "✅ macOS defaults configuration complete!"
}

# 1.5 Cleanup and Working Directory Restoration
_cleanup() {
    echo ""
    echo "🧹 Cleaning up..."
    
    # Restore original working directory
    if [[ -n "$ORIGINAL_CWD" ]]; then
        cd "$ORIGINAL_CWD" || {
            echo "⚠️  Warning: Could not restore original directory: $ORIGINAL_CWD" >&2
            exit 1
        }
    fi
    
    echo "✅ macOS defaults setup completed successfully at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "=============================================================================="
}

# 1.6 Main execution function
main() {
    # Verify we're on macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        echo "❌ Error: This script is only for macOS systems" >&2
        exit 1
    fi
    
    # Setup logging variables
    local log_date=$(date -u +%Y-%m-%d)
    local log_time=$(date -u +%H-%M-%S)
    local log_dir="/Users/s-a-c/.config/zsh/logs/$log_date"
    local log_file="$log_dir/macos-defaults-setup_$log_time.log"
    
    # Create log directory
    mkdir -p "$log_dir"
    
    # Use tee for logging instead of exec to avoid shell conflicts
    {
        _setup_logging
        _apply_macos_defaults
        _cleanup
    } 2>&1 | tee -a "$log_file"
}

# Execute main function using context-aware runner if available
if typeset -f context_run_main >/dev/null 2>&1; then
    context_run_main "main" "$@"
else
    if [[ "${0##*/}" == "macos-defaults-setup.zsh" ]]; then
        main "$@"
    fi
fi
