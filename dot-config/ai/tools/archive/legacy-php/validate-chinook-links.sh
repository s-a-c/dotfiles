#!/bin/bash
# validate-chinook-links.sh - Chinook Link Validation Wrapper
# 
# This script provides a convenient interface for running the Chinook
# documentation link validation system with proper error handling and reporting.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VALIDATOR_SCRIPT="$SCRIPT_DIR/chinook-link-validator.py"
REPORTS_DIR="$PROJECT_ROOT/.ai/reports/chinook/2025-07-16/sprint-5"

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print header
print_header() {
    echo
    print_status $BLUE "🔗 Chinook Documentation Link Validation"
    print_status $BLUE "========================================"
    echo
}

# Function to check prerequisites
check_prerequisites() {
    print_status $BLUE "🔍 Checking prerequisites..."
    
    # Check if Python 3 is available
    if ! command -v python3 &> /dev/null; then
        print_status $RED "❌ Python 3 is required but not installed"
        exit 1
    fi
    
    # Check if validator script exists
    if [ ! -f "$VALIDATOR_SCRIPT" ]; then
        print_status $RED "❌ Validator script not found: $VALIDATOR_SCRIPT"
        exit 1
    fi
    
    # Check if chinook directory exists
    if [ ! -d "$PROJECT_ROOT/.ai/guides/chinook" ]; then
        print_status $RED "❌ Chinook documentation directory not found"
        exit 1
    fi
    
    print_status $GREEN "✅ Prerequisites check passed"
}

# Function to create reports directory
setup_reports() {
    print_status $BLUE "📁 Setting up reports directory..."
    
    mkdir -p "$REPORTS_DIR"
    
    if [ -d "$REPORTS_DIR" ]; then
        print_status $GREEN "✅ Reports directory ready: $REPORTS_DIR"
    else
        print_status $RED "❌ Failed to create reports directory"
        exit 1
    fi
}

# Function to run validation
run_validation() {
    print_status $BLUE "🚀 Running link validation..."
    echo
    
    cd "$PROJECT_ROOT"
    
    # Run the Python validator
    if python3 "$VALIDATOR_SCRIPT"; then
        print_status $GREEN "✅ All links are valid!"
        return 0
    else
        print_status $RED "❌ Broken links found!"
        return 1
    fi
}

# Function to display results
show_results() {
    local validation_result=$1
    
    echo
    print_status $BLUE "📊 Validation Results"
    print_status $BLUE "===================="
    
    # Check if report file exists
    local report_file="$REPORTS_DIR/link-validation-report.md"
    if [ -f "$report_file" ]; then
        print_status $BLUE "📄 Detailed report saved to:"
        echo "   $report_file"
        echo
        
        # Show summary from report
        if grep -q "Success Rate:" "$report_file"; then
            local success_rate=$(grep "Success Rate:" "$report_file" | cut -d' ' -f3)
            print_status $BLUE "📈 Success Rate: $success_rate"
        fi
        
        if grep -q "Broken Links:" "$report_file"; then
            local broken_count=$(grep "❌ \*\*Broken Links\*\*:" "$report_file" | grep -o '[0-9]\+' | head -1)
            if [ "$broken_count" -gt 0 ]; then
                print_status $YELLOW "⚠️  Found $broken_count broken links"
                echo
                print_status $YELLOW "🔧 To view broken links:"
                echo "   cat $report_file"
            fi
        fi
    else
        print_status $YELLOW "⚠️  Report file not found"
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --verbose  Enable verbose output"
    echo "  -q, --quiet    Suppress non-error output"
    echo
    echo "Examples:"
    echo "  $0                 # Run standard validation"
    echo "  $0 --verbose       # Run with detailed output"
    echo "  $0 --quiet         # Run silently (errors only)"
    echo
}

# Main execution function
main() {
    local verbose=false
    local quiet=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -q|--quiet)
                quiet=true
                shift
                ;;
            *)
                print_status $RED "❌ Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Suppress output if quiet mode
    if [ "$quiet" = true ]; then
        exec > /dev/null 2>&1
    fi
    
    # Show header unless quiet
    if [ "$quiet" = false ]; then
        print_header
    fi
    
    # Run validation process
    check_prerequisites
    setup_reports
    
    if run_validation; then
        if [ "$quiet" = false ]; then
            show_results 0
            echo
            print_status $GREEN "🎉 Link validation completed successfully!"
        fi
        exit 0
    else
        if [ "$quiet" = false ]; then
            show_results 1
            echo
            print_status $RED "💥 Link validation failed!"
            echo
            print_status $YELLOW "🔧 Next steps:"
            echo "   1. Review the broken links in the report"
            echo "   2. Fix file paths or create missing files"
            echo "   3. Update anchor references"
            echo "   4. Re-run this script to verify fixes"
        fi
        exit 1
    fi
}

# Execute main function with all arguments
main "$@"
