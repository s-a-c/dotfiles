#!/usr/bin/env zsh
# test-fixes.zsh - Verification script for ZSH startup issues resolution
# Purpose: Test all implemented fixes and validate functionality

echo "🔍 ZSH Startup Issues Resolution - Verification Script"
echo "=================================================="

# Test colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_test() {
    local test_name="$1"
    local result="$2"
    echo -e "${BLUE}Testing:${NC} $test_name"
    if [[ "$result" == "PASS" ]]; then
        echo -e "  ${GREEN}✅ PASS${NC}"
    else
        echo -e "  ${RED}❌ FAIL${NC}"
        return 1
    fi
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}🎉 $1${NC}"
}

print_error() {
    echo -e "${RED}🚨 $1${NC}"
}

echo
echo "Phase 1: NPM Configuration Validation"
echo "====================================="

# Test 1: NPM before configuration
npm_before=$(npm config get before 2>/dev/null || echo "error")
if [[ "$npm_before" == "null" ]]; then
    print_test "NPM 'before' configuration is set to null" "PASS"
else
    print_test "NPM 'before' configuration is set to null" "FAIL"
    print_error "Current value: $npm_before"
fi

# Test 2: Check for corrupted configurations
corrupted_configs=()
for config in prefix globalconfig userconfig; do
    current_value=$(npm config get "$config" 2>/dev/null || echo "undefined")
    if [[ "$current_value" == *".iterm2"* ]] || [[ "$current_value" == *".zshrc"* ]]; then
        corrupted_configs+=("$config")
    fi
done

if [[ ${#corrupted_configs[@]} -eq 0 ]]; then
    print_test "No corrupted NPM configurations found" "PASS"
else
    print_test "No corrupted NPM configurations found" "FAIL"
    print_error "Corrupted configs: ${corrupted_configs[*]}"
fi

echo
echo "Phase 2: Atuin Daemon and Log Management"
echo "========================================="

# Test 3: Atuin log directory exists
atuin_cache="${XDG_CACHE_HOME:-$HOME/.cache}/atuin"
if [[ -d "$atuin_cache" ]]; then
    print_test "Atuin cache directory exists" "PASS"
else
    print_test "Atuin cache directory exists" "FAIL"
    print_error "Missing: $atuin_cache"
fi

# Test 4: Atuin daemon status
if command -v atuin >/dev/null 2>&1; then
    print_test "Atuin command is available" "PASS"

    # Check if daemon is running
    if pgrep -u "$UID" -f 'atuin.*daemon' >/dev/null 2>&1; then
        print_test "Atuin daemon is running" "PASS"
    else
        print_info "Atuin daemon is not currently running (this is normal if not started)"
    fi

    # Test log file creation
    atuin_log="$atuin_cache/daemon.log"
    if [[ -f "$atuin_log" ]] || touch "$atuin_log" 2>/dev/null; then
        print_test "Atuin log file can be created/exists" "PASS"
    else
        print_test "Atuin log file can be created/exists" "FAIL"
        print_error "Cannot create: $atuin_log"
    fi
else
    print_test "Atuin command is available" "FAIL"
    print_info "Atuin is not installed - skipping related tests"
fi

echo
echo "Phase 3: NVM Environment Setup"
echo "=============================="

# Test 5: NVM directory detection
if [[ -n "${NVM_DIR:-}" ]]; then
    print_test "NVM_DIR is set" "PASS"
    print_info "NVM_DIR: $NVM_DIR"

    if [[ -d "$NVM_DIR" ]]; then
        print_test "NVM directory exists" "PASS"

        if [[ -f "$NVM_DIR/nvm.sh" ]]; then
            print_test "NVM script is available" "PASS"
        else
            print_test "NVM script is available" "FAIL"
            print_error "Missing: $NVM_DIR/nvm.sh"
        fi
    else
        print_test "NVM directory exists" "FAIL"
        print_error "Directory not found: $NVM_DIR"
    fi
else
    print_test "NVM_DIR is set" "FAIL"
    print_error "NVM_DIR is not set"
fi

# Test 6: Laravel Herd detection
herd_nvm_dir="${HOME}/Library/Application Support/Herd/config/nvm"
if [[ -n "${_ZF_HERD_NVM:-}" ]]; then
    print_test "Herd NVM environment marker is set" "PASS"
    print_info "Running in Laravel Herd environment"
elif [[ -d "$herd_nvm_dir" ]]; then
    print_test "Herd NVM environment marker is set" "FAIL"
    print_info "Herd is installed but environment marker not set"
else
    print_info "Laravel Herd not detected (this is normal if not installed)"
fi

echo
echo "Phase 4: Package Manager Safety"
echo "==============================="

# Test 7: Package manager detection function
if typeset -f zf::detect_pkg_manager >/dev/null 2>&1; then
    print_test "Package manager detection function exists" "PASS"

    # Test detection
    detected_pm=$(zf::detect_pkg_manager 2>/dev/null || echo "error")
    if [[ "$detected_pm" != "error" ]]; then
        print_test "Package manager detection works" "PASS"
        print_info "Detected: $detected_pm"
    else
        print_test "Package manager detection works" "FAIL"
    fi
else
    print_test "Package manager detection function exists" "FAIL"
fi

# Test 8: Project validation in dotfiles directory
if [[ "$PWD" == "${HOME}/dotfiles" ]]; then
    if [[ ! -f "package.json" ]]; then
        print_test "Correctly detected no package.json in dotfiles" "PASS"
        print_info "Package manager safety should warn in this directory"
    else
        print_test "Correctly detected no package.json in dotfiles" "FAIL"
    fi
fi

echo
echo "Phase 5: Environment Markers"
echo "============================"

# Test 9: Check for environment markers
markers=(
    "_ZF_NVM_PRESETUP"
    "_ZF_HERD_NVM"
    "_ZF_NVM_DETECTED"
    "_ZF_EARLY_NODE_COMPLETE"
    "_ZF_HERD_DETECTED"
    "_ZF_NPM_VALIDATION_COMPLETE"
)

for marker in "${markers[@]}"; do
    if [[ -n "${(P)marker:-}" ]]; then
        print_test "Environment marker $marker is set" "PASS"
    else
        print_test "Environment marker $marker is set" "FAIL"
    fi
done

echo
echo "Phase 6: Node.js Runtime Paths"
echo "=============================="

# Test 10: Check for alternative runtimes
runtimes=("bun" "deno" "pnpm")
for runtime in "${runtimes[@]}"; do
    if command -v "$runtime" >/dev/null 2>&1; then
        print_test "$runtime command is available" "PASS"

        # Check if it's in PATH
        runtime_path=$(command -v "$runtime" 2>/dev/null)
        print_info "$runtime path: $runtime_path"
    else
        print_test "$runtime command is available" "FAIL"
        print_info "$runtime is not installed (this is normal)"
    fi
done

echo
echo "Phase 7: Configuration File Validation"
echo "====================================="

# Test 11: Check if our files exist
config_files=(
    "${HOME}/dotfiles/dot-config/zsh/.zshrc.pre-plugins.d.00/080-early-node-runtimes.zsh"
    "${HOME}/dotfiles/dot-config/zsh/.zshrc.d/500-shell-history.zsh"
    "${HOME}/dotfiles/dot-config/zsh/.zshrc.d/510-npm-config-validator.zsh"
    "${HOME}/dotfiles/dot-config/zsh/.zshrc.d.00/400-aliases.zsh"
    "${HOME}/dotfiles/dot-config/zsh/.zshrc.d.00/530-nvm-post-augmentation.zsh"
    "${HOME}/dotfiles/dot-config/zsh/.zshrc.add-plugins.d.00/220-dev-node.zsh"
)

for file in "${config_files[@]}"; do
    filename=$(basename "$file")
    if [[ -f "$file" ]]; then
        print_test "Configuration file $filename exists" "PASS"
    else
        print_test "Configuration file $filename exists" "FAIL"
        print_error "Missing: $file"
    fi
done

echo
echo "Summary"
echo "======="

# Count total tests (this is approximate since we don't track exact count)
echo "Verification completed. Check the results above."
echo
print_info "If you see any FAIL results, review the corresponding section above."
echo
print_success "Key improvements implemented:"
echo "  • Atuin daemon log file creation with fallback mechanisms"
echo "  • Laravel Herd-aware NVM environment setup"
echo "  • NPM configuration validation and automatic repair"
echo "  • Package manager safety guards and project validation"
echo "  • Enhanced error handling and debugging information"
echo
print_info "To apply changes to your current shell session:"
echo "  source ~/.zshrc"
echo
print_info "To see all environment markers:"
echo "  env | grep '_ZF_"
echo
echo "✨ Implementation complete! Your ZSH startup should now be clean and enhanced."
