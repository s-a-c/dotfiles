#!/usr/bin/env zsh
# Coverage wrapper script
set -euo pipefail

COVERAGE_DIR="$(dirname "$0")"
source "$COVERAGE_DIR/../tools/setup-coverage.zsh"

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <test-script> [args...]"
    exit 1
fi

coverage_run_test "$@"
