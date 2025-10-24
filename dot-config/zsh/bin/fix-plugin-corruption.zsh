#!/usr/bin/env zsh
# Comprehensive fix for zgenom plugin path corruption

echo "🔧 Fixing zgenom plugin path corruption..."

# Step 1: Completely remove corrupted zgenom cache
echo "📂 Removing corrupted zgenom cache..."
if [[ -d ~/.config/zsh/.zgenom ]]; then
    rm -rf ~/.config/zsh/.zgenom
        zf::debug "✅ Corrupted zgenom cache removed"
fi

# Step 2: Remove any stale zgenom source installations
echo "📂 Cleaning zgenom source installations..."
if [[ -d ~/.config/zsh/.zqs-zgenom ]]; then
    rm -rf ~/.config/zsh/.zqs-zgenom
        zf::debug "✅ Zgenom source cleaned"
fi

# Step 3: Fix the zgen-setup file to prevent the plugin corruption
echo "🔧 Temporarily disabling problematic plugins..."

# Create a temporary simplified .zgen-setup that excludes problematic plugins
ZGEN_SETUP_PATH="${HOME}/dotfiles/dot-config/zsh/zsh-quickstart-kit/zsh/.zgen-setup"
ZGEN_SETUP_BACKUP="${ZGEN_SETUP_PATH}.backup.$(date +%Y%m%d_%H%M%S)"

if [[ -f "$ZGEN_SETUP_PATH" ]]; then
    cp "$ZGEN_SETUP_PATH" "$ZGEN_SETUP_BACKUP"
        zf::debug "✅ Backed up original .zgen-setup to $ZGEN_SETUP_BACKUP"

    # Create a minimal .zgen-setup that loads only essential, working plugins
    cat > "$ZGEN_SETUP_PATH" << 'EOF'
#!/usr/bin/env zsh
# Minimal .zgen-setup - only essential, working plugins

# Clone zgenom if you haven't already
if [[ -z "$ZGENOM_PARENT_DIR" ]]; then
  ZGENOM_PARENT_DIR=$HOME
  ZGENOM_SOURCE_FILE=$ZGENOM_PARENT_DIR/.zqs-zgenom/zgenom.zsh

  # Set ZGENOM_SOURCE_FILE to the old directory if it already exists
  if [[ -f "$ZGENOM_PARENT_DIR/zgenom/zgenom.zsh" ]] ; then
    ZGENOM_SOURCE_FILE=$ZGENOM_PARENT_DIR/zgenom/zgenom.zsh
  fi
fi

# zgenom stores the clones plugins & themes in $ZGEN_DIR when it
# is set. Otherwise it stuffs everything in the source tree, which
# is unclean.
ZGEN_DIR=${ZGEN_DIR:-$HOME/.zgenom}

if [[ ! -f "$ZGENOM_SOURCE_FILE" ]] ; then
  if [[ ! -d "$ZGENOM_PARENT_DIR" ]]; then
    mkdir -p "$ZGENOM_PARENT_DIR"
  fi
  pushd $ZGENOM_PARENT_DIR
  git clone https://github.com/jandamm/zgenom.git .zqs-zgenom
  popd
fi

if [[ ! -f "$ZGENOM_SOURCE_FILE" ]] ; then
      zf::debug "Can't find zgenom.zsh"
else
  source "$ZGENOM_SOURCE_FILE"
fi

unset ZGENOM_PARENT_DIR ZGENOM_SOURCE_FILE

load-minimal-plugin-list() {
      zf::debug "Creating minimal zgenom configuration..."
  ZGEN_LOADED=()
  ZGEN_COMPLETIONS=()

  # Load Oh-My-ZSH framework
  zgenom oh-my-zsh

  # Essential syntax highlighting (load first)
  zgenom load zdharma-continuum/fast-syntax-highlighting

  # History substring search (load after syntax highlighting)
  zgenom load zsh-users/zsh-history-substring-search

  # Set keystrokes for substring searching
  zmodload zsh/terminfo
  bindkey "$terminfo[kcuu1]" history-substring-search-up
  bindkey "$terminfo[kcud1]" history-substring-search-down

  # Essential Oh-My-ZSH plugins (known to work)
  zgenom oh-my-zsh plugins/git
  zgenom oh-my-zsh plugins/colored-man-pages

  # macOS specific plugins
  if [[ $(uname -s) == "Darwin" ]]; then
    zgenom oh-my-zsh plugins/macos
    if (( $+commands[brew] )); then
      zgenom oh-my-zsh plugins/brew
    fi
  fi

  # k plugin with our fix (essential for directory listings)
  zgenom load supercrabtree/k

  # Simple prompt (p10k without complex configuration)
  zgenom load romkatv/powerlevel10k powerlevel10k

  # Save it all to init script
  zgenom save
}

setup-zgen-repos() {
  load-minimal-plugin-list
}

# Check file modification times for zgenom regeneration
if [[ $(uname | grep -ci -e Darwin -e BSD) = 1 ]]; then
  # macOS version
  get_file_modification_time() {
    modified_time=$(stat -f %m "$1" 2> /dev/null) || modified_time=0
        zf::debug "${modified_time}"
  }
elif [[ $(uname | grep -ci Linux) = 1 ]]; then
  # Linux version
  get_file_modification_time() {
    modified_time=$(stat -c %Y "$1" 2> /dev/null) || modified_time=0
        zf::debug "${modified_time}"
  }
else
  # Unknown OS - fallback
  get_file_modification_time() {
        zf::debug "0"
  }
fi

# Load the minimal configuration
setup-zgen-repos
EOF

        zf::debug "✅ Created minimal .zgen-setup configuration"
else
        zf::debug "❌ Could not find .zgen-setup file at $ZGEN_SETUP_PATH"
fi

# Step 4: Create a clean shell startup test
echo "🧪 Testing clean shell startup..."
TEST_OUTPUT=$(/opt/homebrew/bin/zsh -i -c 'echo "SUCCESS: Shell started and became interactive"; exit 0' 2>&1)
TEST_EXIT_CODE=$?

if [[ $TEST_EXIT_CODE -eq 0 ]]; then
        zf::debug "✅ Clean shell startup test passed"
        zf::debug "🎯 Your shell should now work properly!"
else
        zf::debug "❌ Shell startup test failed with exit code: $TEST_EXIT_CODE"
        zf::debug "Output: $TEST_OUTPUT"
fi

echo ""
echo "🎯 Next steps:"
echo "1. Start a new zsh session: /opt/homebrew/bin/zsh"
echo "2. Let the minimal zgenom configuration load (faster now)"
echo "3. Test basic functionality: 'k' for directory listing"
echo "4. If everything works, we can gradually re-enable more plugins"
echo ""
echo "💡 To restore full plugin configuration later:"
echo "   cp $ZGEN_SETUP_BACKUP $ZGEN_SETUP_PATH"
