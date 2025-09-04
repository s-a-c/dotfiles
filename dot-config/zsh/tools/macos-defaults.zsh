#!/usr/bin/env zsh
# macOS Defaults Configuration
# UPDATED: Consistent with .zshenv configuration

# Source .zshenv to ensure consistent environment variables
[[ -f "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv" ]] && source "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv"

# Use zsh_debug_echo from .zshenv if available
if declare -f zsh_debug_echo >/dev/null 2>&1; then
    zsh_debug_echo "# [macos-defaults] Starting macOS defaults configuration"
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

if [[ "$(uname)" == "Darwin" ]]; then
    # macOS Settings
        zsh_debug_echo "Changing macOS defaults..."
    defaults write -g NSWindowShouldDragOnGesture YES
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.dock "mru-spaces" -bool "false"
    defaults write com.apple.dock autohide -bool true
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
    defaults write com.apple.LaunchServices LSQuarantine -bool false
    defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false
    defaults write com.apple.NetworkBrowser BrowseAllInterfaces 1
    defaults write com.apple.Safari AutoOpenSafeDownloads -bool false
    defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true
    defaults write com.apple.Safari IncludeDevelopMenu -bool true
    defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
    defaults write com.apple.screencapture disable-shadow -bool true
    defaults write com.apple.screencapture location -string "$HOME/Desktop"
    defaults write com.apple.screencapture type -string "png"
    defaults write com.apple.spaces spans-displays -bool false
    defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool YES
    defaults write NSGlobalDomain _HIHideMenuBar -bool true
    defaults write NSGlobalDomain AppleAccentColor -int 1
    defaults write NSGlobalDomain AppleHighlightColor -string "0.65098 0.85490 0.58431"
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
    defaults write NSGlobalDomain KeyRepeat -int 1
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
    defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

    ## Fix for MX Master 3S
    sudo defaults write /Library/Preferences/com.apple.airport.bt.plist bluetoothCoexMgmt Hybrid
    :
elif [[ "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
    ## Do something under GNU/Linux platform
    :
    elif [[ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]]; then
    ## Do something under 32 bits Windows NT platform
    :
elif [[ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]]; then
    ## Do something under 64 bits Windows NT platform
    :
fi
