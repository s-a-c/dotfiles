#!/bin/bash
#
# PHP Link Validation Wrapper Script
# 
# Provides convenient access to the PHP link validation and rectification tools
# with common presets and simplified command-line interface.
#
# Usage:
#   ./validate-links.sh [command] [options]
#
# Commands:
#   validate    - Run link validation (default)
#   fix         - Run link rectification
#   test        - Run test suite
#   help        - Show help information
#

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALIDATOR="$SCRIPT_DIR/link-validator.php"
RECTIFIER="$SCRIPT_DIR/link-rectifier.php"
TEST_SUITE="$SCRIPT_DIR/run-tests.php"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if PHP is available
check_php() {
    if ! command -v php &> /dev/null; then
        log_error "PHP is not installed or not in PATH"
        exit 1
    fi
    
    local php_version=$(php -r "echo PHP_VERSION;")
    local major_version=$(echo "$php_version" | cut -d. -f1)
    local minor_version=$(echo "$php_version" | cut -d. -f2)
    
    if [ "$major_version" -lt 8 ] || ([ "$major_version" -eq 8 ] && [ "$minor_version" -lt 4 ]); then
        log_warning "PHP 8.4+ recommended, found $php_version"
    fi
}

# Show help information
show_help() {
    cat << 'EOF'
🔗 PHP Link Validation Tools

USAGE:
    ./validate-links.sh [command] [options]

COMMANDS:
    validate [target]       Validate links in documentation
    fix [target]           Fix broken links with interactive mode
    fix-auto [target]      Fix broken links automatically
    preview [target]       Preview link fixes without applying
    test                   Run test suite
    rollback [timestamp]   Rollback to previous backup
    help                   Show this help message

TARGETS:
    docs/                  Validate docs directory (default)
    file.md               Validate specific file
    .                     Validate current directory

EXAMPLES:
    # Basic validation
    ./validate-links.sh validate docs/
    
    # Quick validation (internal links only)
    ./validate-links.sh validate-quick docs/
    
    # Fix broken links interactively
    ./validate-links.sh fix docs/
    
    # Preview fixes without applying
    ./validate-links.sh preview docs/
    
    # Run comprehensive validation with external links
    ./validate-links.sh validate-full docs/
    
    # Fix links automatically (batch mode)
    ./validate-links.sh fix-auto docs/
    
    # Rollback to previous backup
    ./validate-links.sh rollback 2024-01-15-14-30-00

PRESETS:
    validate-quick         Internal and anchor links only
    validate-full          All links including external
    validate-ci            CI/CD mode with JSON output
    fix-safe              Interactive fixing with high threshold
    fix-aggressive        Automatic fixing with lower threshold

For advanced options, use the PHP tools directly:
    php .ai/tools/link-validator.php --help
    php .ai/tools/link-rectifier.php --help

EOF
}

# Validate command
cmd_validate() {
    local target="${1:-docs/}"
    local preset="${2:-default}"
    
    log_info "Validating links in: $target"
    
    case "$preset" in
        "quick")
            php "$VALIDATOR" "$target" --scope=internal,anchor --max-broken=10
            ;;
        "full")
            php "$VALIDATOR" "$target" --check-external --timeout=60 --max-broken=5
            ;;
        "ci")
            php "$VALIDATOR" "$target" --quiet --format=json --max-broken=5 --output=.ai/reports/validation-$(date +%Y%m%d-%H%M%S).json
            ;;
        *)
            php "$VALIDATOR" "$target" --scope=internal,anchor,cross-reference --max-broken=10
            ;;
    esac
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log_success "Link validation passed"
    elif [ $exit_code -eq 1 ]; then
        log_warning "Link validation found issues"
    else
        log_error "Link validation failed with system error"
    fi
    
    return $exit_code
}

# Fix command
cmd_fix() {
    local target="${1:-docs/}"
    local mode="${2:-interactive}"
    
    log_info "Fixing links in: $target"
    
    case "$mode" in
        "auto"|"batch")
            php "$RECTIFIER" "$target" --batch --similarity-threshold=0.8
            ;;
        "safe")
            php "$RECTIFIER" "$target" --interactive --similarity-threshold=0.9
            ;;
        "aggressive")
            php "$RECTIFIER" "$target" --batch --similarity-threshold=0.6
            ;;
        *)
            php "$RECTIFIER" "$target" --interactive --similarity-threshold=0.8
            ;;
    esac
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log_success "Link fixing completed successfully"
    else
        log_error "Link fixing failed"
    fi
    
    return $exit_code
}

# Preview command
cmd_preview() {
    local target="${1:-docs/}"
    
    log_info "Previewing link fixes for: $target"
    php "$RECTIFIER" "$target" --dry-run --similarity-threshold=0.8
}

# Test command
cmd_test() {
    log_info "Running test suite..."
    php "$TEST_SUITE"
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log_success "All tests passed"
    else
        log_error "Some tests failed"
    fi
    
    return $exit_code
}

# Rollback command
cmd_rollback() {
    local timestamp="$1"
    
    if [ -z "$timestamp" ]; then
        log_error "Rollback timestamp required (format: YYYY-MM-DD-HH-MM-SS)"
        log_info "Available backups:"
        ls -la .ai/backups/ 2>/dev/null || log_warning "No backups found"
        return 1
    fi
    
    log_info "Rolling back to: $timestamp"
    php "$RECTIFIER" --rollback="$timestamp"
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log_success "Rollback completed successfully"
    else
        log_error "Rollback failed"
    fi
    
    return $exit_code
}

# Main script logic
main() {
    check_php
    
    local command="${1:-validate}"
    shift || true
    
    case "$command" in
        "validate")
            cmd_validate "$@"
            ;;
        "validate-quick")
            cmd_validate "${1:-docs/}" "quick"
            ;;
        "validate-full")
            cmd_validate "${1:-docs/}" "full"
            ;;
        "validate-ci")
            cmd_validate "${1:-docs/}" "ci"
            ;;
        "fix")
            cmd_fix "$@"
            ;;
        "fix-auto"|"fix-batch")
            cmd_fix "${1:-docs/}" "auto"
            ;;
        "fix-safe")
            cmd_fix "${1:-docs/}" "safe"
            ;;
        "fix-aggressive")
            cmd_fix "${1:-docs/}" "aggressive"
            ;;
        "preview")
            cmd_preview "$@"
            ;;
        "test")
            cmd_test
            ;;
        "rollback")
            cmd_rollback "$@"
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
