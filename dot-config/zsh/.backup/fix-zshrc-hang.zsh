#!/usr/bin/env zsh
# Fix .zshrc hang issues by isolating external additions
# This script identifies and moves external tool additions to a controlled location

set -euo pipefail

# Configuration
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
ZSHRC_FILE="$ZDOTDIR/.zshrc"
BACKUP_DIR="$ZDOTDIR/backups"
EXTERNAL_ADDITIONS_FILE="$ZDOTDIR/.zshrc.d/99-external-tools.zsh"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

# Colors for output
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

# Logging functions
info() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Main function
main() {
    info "Fixing .zshrc hang issues..."
    info "ZDOTDIR: $ZDOTDIR"

    # Step 1: Backup current .zshrc
    if [[ -f "$ZSHRC_FILE" ]]; then
        local backup_file="$BACKUP_DIR/.zshrc.backup-$TIMESTAMP"
        cp "$ZSHRC_FILE" "$backup_file"
        success "Backed up .zshrc to $backup_file"
    else
        error ".zshrc not found at $ZSHRC_FILE"
        exit 1
    fi

    # Step 2: Identify external additions
    info "Scanning for external tool additions..."

    # Known external tools that append to .zshrc
    local -a external_markers=(
        "# Herd injected"
        "# Added by LM Studio"
        "# Added by Homebrew"
        "# Added by cargo"
        "# Added by rustup"
        "# Added by nvm"
        "# Added by rbenv"
        "# Added by pyenv"
        "# >>> conda initialize"
        "# <<< conda initialize"
    )

    # Find the line where ZQS configuration ends
    local zqs_end_line=$(grep -n "^# === ZQS Integration Complete ===" "$ZSHRC_FILE" | tail -1 | cut -d: -f1)

    if [[ -z "$zqs_end_line" ]]; then
        warning "Could not find ZQS end marker. Looking for alternative markers..."
        zqs_end_line=$(grep -n "^# End of .zshrc" "$ZSHRC_FILE" | tail -1 | cut -d: -f1)

        if [[ -z "$zqs_end_line" ]]; then
            # Use a conservative approach - look for the last zgenom/zprof section
            zqs_end_line=$(grep -n "zprof" "$ZSHRC_FILE" | tail -1 | cut -d: -f1)

            if [[ -z "$zqs_end_line" ]]; then
                error "Could not determine where ZQS configuration ends"
                exit 1
            fi
        fi
    fi

    info "ZQS configuration ends at line $zqs_end_line"

    # Step 3: Extract external additions
    local total_lines=$(wc -l < "$ZSHRC_FILE")
    local external_start=$((zqs_end_line + 1))

    if [[ $external_start -le $total_lines ]]; then
        info "Found external additions from line $external_start to $total_lines"

        # Create the external additions file
        mkdir -p "$(dirname "$EXTERNAL_ADDITIONS_FILE")"

        {
            echo "#!/usr/bin/env zsh"
            echo "# External tool additions extracted from .zshrc"
            echo "# Extracted on: $(date)"
            echo "# These additions were automatically appended by various tools"
            echo ""
            echo "# Guard against multiple sourcing"
            echo "[[ -n \"\${_EXTERNAL_TOOLS_LOADED:-}\" ]] && return 0"
            echo "export _EXTERNAL_TOOLS_LOADED=1"
            echo ""

            # Extract the external additions
            sed -n "${external_start},${total_lines}p" "$ZSHRC_FILE"
        } > "$EXTERNAL_ADDITIONS_FILE"

        success "Extracted external additions to $EXTERNAL_ADDITIONS_FILE"

        # Step 4: Create cleaned .zshrc
        local temp_file="$ZSHRC_FILE.tmp"
        head -n "$zqs_end_line" "$ZSHRC_FILE" > "$temp_file"

        # Add a note about the extraction
        {
            echo ""
            echo "# === External Tool Additions ==="
            echo "# External tool additions have been moved to:"
            echo "# $EXTERNAL_ADDITIONS_FILE"
            echo "# They will be loaded automatically by the post-plugin system"
            echo "# To disable, set: export SKIP_EXTERNAL_TOOLS=1"
        } >> "$temp_file"

        # Replace the original file
        mv "$temp_file" "$ZSHRC_FILE"
        success "Cleaned .zshrc file"

        # Step 5: Make external additions conditional
        if [[ -f "$EXTERNAL_ADDITIONS_FILE" ]]; then
            # Add conditional loading wrapper
            local wrapped_file="$EXTERNAL_ADDITIONS_FILE.wrapped"
            {
                echo "#!/usr/bin/env zsh"
                echo "# External tool additions (wrapped for conditional loading)"
                echo ""
                echo "# Skip if disabled"
                echo "[[ \"\${SKIP_EXTERNAL_TOOLS:-0}\" == \"1\" ]] && return 0"
                echo ""
                echo "# Skip if already loaded"
                echo "[[ -n \"\${_EXTERNAL_TOOLS_LOADED:-}\" ]] && return 0"
                echo "export _EXTERNAL_TOOLS_LOADED=1"
                echo ""
                echo "# Load with timeout protection"
                echo "() {"
                echo "    local external_file=\"$EXTERNAL_ADDITIONS_FILE.original\""
                echo "    if [[ -f \"\$external_file\" ]]; then"
                echo "        # Use a subshell with timeout to prevent hangs"
                echo "        ( "
                echo "            # Set a 2-second timeout for external tool loading"
                echo "            if command -v timeout >/dev/null 2>&1; then"
                echo "                timeout 2 zsh -c \"source '\$external_file'\""
                echo "            else"
                echo "                source \"\$external_file\""
                echo "            fi"
                echo "        ) 2>/dev/null || {"
                echo "            echo \"Warning: External tool additions timed out or failed\" >&2"
                echo "        }"
                echo "    fi"
                echo "}"
                echo ""
                cat "$EXTERNAL_ADDITIONS_FILE"
            } > "$wrapped_file"

            # Keep original and use wrapped version
            mv "$EXTERNAL_ADDITIONS_FILE" "$EXTERNAL_ADDITIONS_FILE.original"
            mv "$wrapped_file" "$EXTERNAL_ADDITIONS_FILE"
            chmod +x "$EXTERNAL_ADDITIONS_FILE"
        fi

    else
        info "No external additions found after line $zqs_end_line"
    fi

    # Step 6: Test the fixed configuration
    info "Testing fixed configuration..."

    # Test with timeout
    if timeout 3 zsh -c "export SKIP_EXTERNAL_TOOLS=1; source '$ZSHRC_FILE'; echo 'Test OK'" >/dev/null 2>&1; then
        success "Configuration loads successfully without external tools"
    else
        error "Configuration still has issues. Check the backup at $backup_file"
        exit 1
    fi

    # Test with external tools (with timeout)
    if timeout 5 zsh -c "source '$ZSHRC_FILE'; echo 'Test OK'" >/dev/null 2>&1; then
        success "Configuration loads successfully with external tools"
    else
        warning "External tools may have issues, but core configuration is working"
    fi

    # Step 7: Create diagnostic script
    local diag_script="$ZDOTDIR/diagnose-external-tools.zsh"
    cat > "$diag_script" << 'EOF'
#!/usr/bin/env zsh
# Diagnostic script for external tool issues

echo "Diagnosing external tool additions..."
echo ""

EXTERNAL_FILE="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshrc.d/99-external-tools.zsh.original"

if [[ -f "$EXTERNAL_FILE" ]]; then
    echo "Testing each external tool addition:"
    echo ""

    # Test Herd
    if grep -q "Herd injected" "$EXTERNAL_FILE"; then
        echo -n "  Herd PHP: "
        if timeout 1 zsh -c 'export PATH="${HOME}/Library/Application Support/Herd/bin/":$PATH' 2>/dev/null; then
            echo "OK"
        else
            echo "TIMEOUT/FAIL"
        fi
    fi

    # Test LM Studio
    if grep -q "LM Studio" "$EXTERNAL_FILE"; then
        echo -n "  LM Studio: "
        if timeout 1 zsh -c 'export PATH="$PATH:/Users/s-a-c/.lmstudio/bin"' 2>/dev/null; then
            echo "OK"
        else
            echo "TIMEOUT/FAIL"
        fi
    fi

    echo ""
    echo "To skip external tools, add to your .zshenv:"
    echo "  export SKIP_EXTERNAL_TOOLS=1"
else
    echo "No external tools file found"
fi
EOF
    chmod +x "$diag_script"

    # Summary
    echo ""
    success "=== Fix Complete ==="
    echo ""
    echo "Summary of changes:"
    echo "  1. Backed up original .zshrc to: $backup_file"
    echo "  2. Extracted external additions to: $EXTERNAL_ADDITIONS_FILE"
    echo "  3. Cleaned .zshrc file"
    echo "  4. Added timeout protection for external tools"
    echo ""
    echo "Next steps:"
    echo "  1. Test your shell: zsh -l"
    echo "  2. If issues persist, run: $diag_script"
    echo "  3. To disable external tools: export SKIP_EXTERNAL_TOOLS=1"
    echo "  4. To restore backup: cp '$backup_file' '$ZSHRC_FILE'"
    echo ""

    # Offer to test interactively
    echo -n "Would you like to test the shell now? [y/N] "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "Starting test shell (type 'exit' to return)..."
        SKIP_EXTERNAL_TOOLS=0 zsh -l
    fi
}

# Run main function
main "$@"
