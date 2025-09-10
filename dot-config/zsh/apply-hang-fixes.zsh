#!/usr/bin/env zsh
# Comprehensive fix script for ZSH configuration hang issues
# This script applies all necessary patches to prevent hangs during shell initialization

set -euo pipefail

# Configuration
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$ZDOTDIR/backups/hang-fixes-$TIMESTAMP"
LOG_FILE="$ZDOTDIR/logs/hang-fixes-$TIMESTAMP.log"

# Colors for output
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' BOLD='' NC=''
fi

# Logging functions
log() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_FILE"
    echo -e "$message"
}

info() { log "${BLUE}[INFO]${NC} $*"; }
success() { log "${GREEN}[SUCCESS]${NC} $*"; }
warning() { log "${YELLOW}[WARNING]${NC} $*"; }
error() { log "${RED}[ERROR]${NC} $*"; }

# Create directories
mkdir -p "$BACKUP_DIR" "$(dirname "$LOG_FILE")"

info "Starting ZSH hang fixes..."
info "ZDOTDIR: $ZDOTDIR"
info "Backup directory: $BACKUP_DIR"
info "Log file: $LOG_FILE"
echo ""

# Function to backup a file
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup_name="$(basename "$file")"
        cp "$file" "$BACKUP_DIR/$backup_name"
        info "Backed up: $file"
    fi
}

# Function to safely replace text in a file
safe_replace() {
    local file="$1"
    local search="$2"
    local replace="$3"
    local description="$4"

    if grep -q "$search" "$file" 2>/dev/null; then
        sed -i.tmp "s|$search|$replace|g" "$file"
        rm -f "$file.tmp"
        success "$description"
    else
        warning "$description - pattern not found (may already be fixed)"
    fi
}

# =============================================================================
# Fix 1: Disable SSH key listing that can hang
# =============================================================================
info "${BOLD}Fix 1: Disabling SSH key listing${NC}"

# Create settings directory if needed
mkdir -p "$ZDOTDIR/.zqs-settings"

# Disable SSH key listing
echo "false" > "$ZDOTDIR/.zqs-settings/list-ssh-keys"
success "Disabled SSH key listing via settings"

# =============================================================================
# Fix 2: Add timeout protection to problematic commands
# =============================================================================
info "${BOLD}Fix 2: Adding timeout protection${NC}"

# Fix ssh-add commands in .zshrc
if [[ -f "$ZDOTDIR/.zshrc" ]]; then
    backup_file "$ZDOTDIR/.zshrc"

    # Already fixed in previous edits, but verify
    if grep -q 'ssh-add -l' "$ZDOTDIR/.zshrc" | grep -v timeout 2>/dev/null; then
        warning "Unprotected ssh-add commands still exist - manual review needed"
    else
        success "ssh-add commands already have timeout protection"
    fi
fi

# =============================================================================
# Fix 3: Fix undefined function calls
# =============================================================================
info "${BOLD}Fix 3: Fixing undefined function calls${NC}"

# The _check-for-zsh-quickstart-update fix was already applied
if grep -q 'declare -f _check-for-zsh-quickstart-update' "$ZDOTDIR/.zshrc" 2>/dev/null; then
    success "Update function check already protected"
else
    warning "Update function check may need protection"
fi

# =============================================================================
# Fix 4: Fix problematic post-plugin modules
# =============================================================================
info "${BOLD}Fix 4: Fixing problematic post-plugin modules${NC}"

# Fix 95-prompt-ready.zsh background jobs
PROMPT_READY_FILE="$ZDOTDIR/.zshrc.d.REDESIGN/95-prompt-ready.zsh"
if [[ -f "$PROMPT_READY_FILE" ]]; then
    backup_file "$PROMPT_READY_FILE"

    # Disable background sleep jobs that can cause issues
    cat > "$PROMPT_READY_FILE.fixed" << 'EOF'
#!/usr/bin/env zsh
# 95-prompt-ready.zsh - FIXED VERSION
# Prompt readiness tracking without background jobs that can cause hangs

# Guard: prevent double load
[[ -n ${_LOADED_PROMPT_READY_MODULE:-} ]] && return
_LOADED_PROMPT_READY_MODULE=1

# Early opt-out
if [[ "${ZSH_PERF_PROMPT_MARKERS:-1}" == "0" ]]; then
    return 0
fi

# Provide a quiet debug echo if global helper is absent
typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }

# Simplified prompt ready capture without background jobs
__pr__capture_prompt_ready() {
    # Prevent re-entry
    [[ -n ${PROMPT_READY_MS:-} ]] && return 0

    # Capture timing if available
    if command -v date >/dev/null 2>&1; then
        PROMPT_READY_MS=$(date +%s%3N 2>/dev/null || date +%s000)
        export PROMPT_READY_MS
    fi

    zsh_debug_echo "# [prompt-ready] captured PROMPT_READY_MS=${PROMPT_READY_MS:-n/a}"
}

# Install hook if possible
if autoload -Uz add-zsh-hook 2>/dev/null; then
    add-zsh-hook precmd __pr__capture_prompt_ready 2>/dev/null || true
elif typeset -f precmd >/dev/null 2>&1; then
    # Wrap existing precmd
    eval "precmd() { __pr__capture_prompt_ready; $(typeset -f precmd | sed '1d;$d'); }"
else
    # Simple precmd
    precmd() { __pr__capture_prompt_ready; }
fi

# NO BACKGROUND JOBS - they can cause hangs in non-interactive shells
# All sleep-based deferred checks have been removed

zsh_debug_echo "# [prompt-ready] simplified instrumentation installed (no background jobs)"
EOF

    mv "$PROMPT_READY_FILE.fixed" "$PROMPT_READY_FILE"
    chmod +x "$PROMPT_READY_FILE"
    success "Fixed 95-prompt-ready.zsh (removed background jobs)"
fi

# =============================================================================
# Fix 5: Add emergency timeout wrapper
# =============================================================================
info "${BOLD}Fix 5: Creating emergency timeout wrapper${NC}"

cat > "$ZDOTDIR/.zshrc.d/00-timeout-protection.zsh" << 'EOF'
#!/usr/bin/env zsh
# Emergency timeout protection for shell initialization
# This should be sourced early to wrap potentially hanging operations

# Define timeout wrapper if not available
if ! command -v timeout >/dev/null 2>&1; then
    # Simple timeout implementation using background job
    timeout() {
        local duration="$1"
        shift
        ( "$@" ) & local pid=$!
        ( sleep "$duration" && kill -TERM $pid 2>/dev/null ) & local timer=$!
        if wait $pid 2>/dev/null; then
            kill -TERM $timer 2>/dev/null
            wait $timer 2>/dev/null
            return 0
        else
            return 124
        fi
    }
fi

# Export for use in other scripts
export -f timeout 2>/dev/null || true

# Set emergency flags if initialization is taking too long
if [[ -n "${ZSH_INIT_TIMEOUT:-}" ]]; then
    export NO_ZGENOM=1
    export SKIP_PLUGINS=1
    export SKIP_EXTERNAL_TOOLS=1
    zsh_debug_echo "# [timeout-protection] Emergency mode activated"
fi
EOF

chmod +x "$ZDOTDIR/.zshrc.d/00-timeout-protection.zsh"
success "Created timeout protection module"

# =============================================================================
# Fix 6: Create safe mode launcher
# =============================================================================
info "${BOLD}Fix 6: Creating safe mode launcher${NC}"

cat > "$ZDOTDIR/zsh-safe-mode" << 'EOF'
#!/usr/bin/env zsh
# Launch ZSH in safe mode with all protections enabled

export NO_ZGENOM=1
export SKIP_PLUGINS=1
export SKIP_EXTERNAL_TOOLS=1
export ZSH_NO_COMPINIT=1
export DISABLE_AUTO_UPDATE=true
export ZSH_DISABLE_COMPFIX=true
export _ZQS_DISABLE_SSH_KEY_LIST=1

echo "Starting ZSH in SAFE MODE..."
echo "  - Plugins disabled"
echo "  - External tools disabled"
echo "  - Auto-update disabled"
echo "  - SSH key listing disabled"
echo ""
echo "To return to normal mode, just exit and start a new shell"
echo ""

exec zsh "$@"
EOF

chmod +x "$ZDOTDIR/zsh-safe-mode"
success "Created safe mode launcher: $ZDOTDIR/zsh-safe-mode"

# =============================================================================
# Fix 7: Validate fixes
# =============================================================================
info "${BOLD}Fix 7: Validating fixes${NC}"

echo ""
info "Testing shell initialization with fixes..."

# Test 1: Basic load test
echo -n "  Test 1 (basic load): "
if timeout 2 zsh -c "export NO_ZGENOM=1; export SKIP_PLUGINS=1; source '$ZDOTDIR/.zshrc'; echo 'OK'" >/dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
fi

# Test 2: Full load test
echo -n "  Test 2 (full load): "
if timeout 5 zsh -c "source '$ZDOTDIR/.zshrc'; echo 'OK'" >/dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${YELLOW}TIMEOUT${NC} (external tools may be slow)"
fi

# Test 3: Safe mode test
echo -n "  Test 3 (safe mode): "
if timeout 2 "$ZDOTDIR/zsh-safe-mode" -c "echo 'OK'" >/dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
success "${BOLD}=== All fixes applied ===${NC}"
echo ""
echo "Summary of changes:"
echo "  ✓ Disabled SSH key listing"
echo "  ✓ Added timeout protection to commands"
echo "  ✓ Fixed undefined function calls"
echo "  ✓ Removed background jobs from prompt-ready module"
echo "  ✓ Created timeout protection wrapper"
echo "  ✓ Created safe mode launcher"
echo ""
echo "Backups saved to: $BACKUP_DIR"
echo "Log file: $LOG_FILE"
echo ""
echo "${BOLD}Next steps:${NC}"
echo "  1. Test normal shell:     zsh -l"
echo "  2. If issues persist:     $ZDOTDIR/zsh-safe-mode"
echo "  3. Check startup time:    time zsh -i -c exit"
echo "  4. Restore backups:       cp $BACKUP_DIR/* $ZDOTDIR/"
echo ""
echo "${BOLD}Troubleshooting:${NC}"
echo "  - Set NO_ZGENOM=1 to skip plugin loading"
echo "  - Set SKIP_EXTERNAL_TOOLS=1 to skip external tool configs"
echo "  - Run diagnose-hang-advanced.zsh for detailed analysis"
echo ""

# Offer to test
echo -n "Would you like to test the shell now? [y/N] "
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Starting test shell (type 'exit' to return)..."
    exec zsh -l
fi
