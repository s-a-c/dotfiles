#!/usr/bin/env zsh

# Test to ensure all *.REDESIGN files have a sentinel guard.

# Source the test runner
# Use resilient path resolution (avoids brittle ${0:A:h})
if typeset -f zf::script_dir >/dev/null 2>&1; then
  . "$(zf::script_dir "${(%):-%N}")/../run-all-tests.zsh"
else
  . "${(%):-%N:h}/../run-all-tests.zsh"
fi

# Fallback helpers if the runner didn't define them
if ! typeset -f print_success >/dev/null 2>&1; then
  print_success() { print "$@"; }
fi
if ! typeset -f print_failure >/dev/null 2>&1; then
  print_failure() { print "$@"; }
fi

# --- Test Setup ---

# Create a temporary directory for our test files
local temp_dir
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT

# Create dummy redesign directories
mkdir -p "$temp_dir/.zshrc.pre-plugins.d.REDESIGN"
mkdir -p "$temp_dir/.zshrc.d.REDESIGN"

# --- Test Cases ---

# Test case 1: A file with a valid sentinel
cat > "$temp_dir/.zshrc.pre-plugins.d.REDESIGN/00-valid.zsh" <<'EOF'
# Some comments
_LOADED_PRE_PLUGIN_00_VALID=1
# Some other code
EOF

# Test case 2: A file missing a sentinel
cat > "$temp_dir/.zshrc.pre-plugins.d.REDESIGN/10-invalid.zsh" <<'EOF'
# No sentinel here
echo "This file is missing a sentinel"
EOF

# Test case 3: A file in the post-plugin directory with a valid sentinel
cat > "$temp_dir/.zshrc.d.REDESIGN/20-valid-post.zsh" <<'EOF'
# Post-plugin file
_LOADED_POST_PLUGIN_20_VALID_POST=1
# Some more code
EOF

# Test case 4: A file in the post-plugin directory missing a sentinel
cat > "$temp_dir/.zshrc.d.REDESIGN/30-invalid-post.zsh" <<'EOF'
# Another invalid file
echo "This one is also missing a sentinel"
EOF

# --- Test Runner ---

local test_count=0
local failures=0

# Function to run a single test
run_sentinel_test() {
    local dir_to_scan=$1
    local expected_failures=$2
    local test_name=$3

    ((test_count++))
    print -n "Running test: $test_name... "

    local missing_sentinels
    missing_sentinels=$(
        find "$dir_to_scan" -name '*.zsh' -print0 | while IFS= read -r -d '' file; do
            local filename
            filename=$(basename "$file" .zsh)
            local sentinel_var
            sentinel_var="_LOADED_$(echo "$filename" | tr '[:lower:]-' '[:upper:]_')"

            if ! grep -q "$sentinel_var=1" "$file"; then
                echo "$file"
            fi
        done
    )

    local failure_count
    failure_count=$(echo "$missing_sentinels" | wc -l | tr -d ' ')

    if [[ $failure_count -eq $expected_failures ]]; then
        print_success "PASS"
    else
        print_failure "FAIL"
        print "    Expected $expected_failures files missing sentinels, but found $failure_count."
        if [[ -n "$missing_sentinels" ]]; then
            print "    Files missing sentinels:"
            print "$missing_sentinels" | sed 's/^/        /'
        fi
        ((failures++))
    fi
}

# Run tests on our dummy files
run_sentinel_test "$temp_dir/.zshrc.pre-plugins.d.REDESIGN" 1 "Pre-plugin directory scan"
run_sentinel_test "$temp_dir/.zshrc.d.REDESIGN" 1 "Post-plugin directory scan"

# Now, run the test on the actual project directories
# We expect 0 failures here
local zdotdir="${ZDOTDIR:-$HOME/.config/zsh}"
run_sentinel_test "$zdotdir/.zshrc.pre-plugins.d.REDESIGN" 0 "Actual pre-plugin directory"
run_sentinel_test "$zdotdir/.zshrc.d.REDESIGN" 0 "Actual post-plugin directory"


# --- Final Results ---

print "\nSentinel Guard Test Summary:"
if [[ $failures -eq 0 ]]; then
    print_success "All $test_count tests passed!"
    exit 0
else
    print_failure "$failures/$test_count tests failed."
    exit 1
fi
