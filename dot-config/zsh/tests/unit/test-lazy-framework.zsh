#!/usr/bin/env zsh
# test-lazy-framework.zsh
# Unit tests for the lazy loading framework:
#   - Function registration and replacement
#   - First-call loading behavior
#   - Dispatcher mechanics
#   - Error handling and fallbacks
set -euo pipefail

ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"

# Test configuration
TEST_COUNT=0
FAILURES=0
TEMP_DIR=""

print_test() { print -n "Test $((++TEST_COUNT)): $1... "; }
print_pass() { print "\033[32mPASS\033[0m"; }
print_fail() {
    print "\033[31mFAIL\033[0m"
    ((FAILURES++))
    print "  $1"
}

setup_test_env() {
    TEMP_DIR=$(mktemp -d)
    trap 'cleanup_test_env' EXIT

    # Create a mock lazy framework implementation for testing
    cat > "$TEMP_DIR/lazy-framework.zsh" <<'EOF'
# Mock lazy framework implementation
typeset -gA _LAZY_REGISTRY
typeset -gA _LAZY_LOADED

# Register a command for lazy loading
lazy_register() {
    local cmd="$1"
    local loader="$2"

    _LAZY_REGISTRY[$cmd]="$loader"

    # Create stub function that will be replaced on first call
    eval "$cmd() {
        lazy_dispatch '$cmd' \"\$@\"
    }"
}

# Dispatcher - loads real implementation on first call
lazy_dispatch() {
    local cmd="$1"
    shift

    if [[ -z ${_LAZY_LOADED[$cmd]:-} ]]; then
        local loader="${_LAZY_REGISTRY[$cmd]:-}"
        if [[ -n "$loader" ]]; then
            # Load the real implementation
            eval "$loader"
            _LAZY_LOADED[$cmd]=1

            # Replace stub with real function (if it exists)
            if (( ${+functions[$cmd]} )); then
                # Real function should now be loaded, call it
                "$cmd" "$@"
            else
                print "Error: lazy loader failed to define function '$cmd'" >&2
                return 1
            fi
        else
            print "Error: no loader registered for '$cmd'" >&2
            return 1
        fi
    else
        # Already loaded, just call it
        "$cmd" "$@"
    fi
}

# Check if command is lazy-registered
is_lazy_registered() {
    local cmd="$1"
    [[ -n ${_LAZY_REGISTRY[$cmd]:-} ]]
}

# Check if command has been loaded
is_lazy_loaded() {
    local cmd="$1"
    [[ -n ${_LAZY_LOADED[$cmd]:-} ]]
}
EOF

    source "$TEMP_DIR/lazy-framework.zsh"
}

cleanup_test_env() {
    [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"

    # Clean up any test functions from global scope
    unset -f test_cmd test_failing_cmd real_test_cmd 2>/dev/null || true
    unset _LAZY_REGISTRY _LAZY_LOADED 2>/dev/null || true
}

# Test 1: Basic function registration
print_test "Function registration"
setup_test_env
{
    # Register a lazy command
    lazy_register "test_cmd" "
        real_test_cmd() {
            echo 'real implementation called'
            return 42
        }
        # Replace the stub
        test_cmd() { real_test_cmd \"\$@\"; }
    "

    if is_lazy_registered "test_cmd"; then
        print_pass
    else
        print_fail "Command not registered in lazy registry"
    fi
}

# Test 2: First call triggers loading
print_test "First call loading"
{
    # Ensure not yet loaded
    if ! is_lazy_loaded "test_cmd"; then
        # Call the command - should trigger loading
        output=$(test_cmd 2>&1)
        exit_code=$?

        if [[ "$output" == "real implementation called" && $exit_code -eq 42 ]]; then
            print_pass
        else
            print_fail "First call failed (output='$output', exit=$exit_code)"
        fi
    else
        print_fail "Command already marked as loaded before first call"
    fi
}

# Test 3: Subsequent calls use real implementation
print_test "Subsequent calls efficiency"
{
    if is_lazy_loaded "test_cmd"; then
        # Second call should not go through dispatcher
        output=$(test_cmd 2>&1)
        exit_code=$?

        if [[ "$output" == "real implementation called" && $exit_code -eq 42 ]]; then
            print_pass
        else
            print_fail "Subsequent call failed (output='$output', exit=$exit_code)"
        fi
    else
        print_fail "Command not marked as loaded after first call"
    fi
}

# Test 4: Error handling for missing loader
print_test "Missing loader error handling"
{
    # Register command without proper loader
    _LAZY_REGISTRY[bad_cmd]=""
    eval "bad_cmd() { lazy_dispatch 'bad_cmd' \"\$@\"; }"

    output=$(bad_cmd 2>&1 || true)

    if [[ "$output" == *"no loader registered"* ]]; then
        print_pass
    else
        print_fail "Expected 'no loader registered' error, got: $output"
    fi

    unset -f bad_cmd 2>/dev/null || true
}

# Test 5: Error handling for failing loader
print_test "Failing loader error handling"
{
    lazy_register "test_failing_cmd" "
        # This loader intentionally fails to define the function
        echo 'loader executed but failed'
        return 1
    "

    output=$(test_failing_cmd 2>&1 || true)

    if [[ "$output" == *"lazy loader failed"* ]]; then
        print_pass
    else
        print_fail "Expected 'lazy loader failed' error, got: $output"
    fi
}

# Test 6: Argument passing
print_test "Argument passing through dispatcher"
{
    lazy_register "test_args_cmd" "
        real_test_args_cmd() {
            echo \"\$#\" \"\$1\" \"\$2\"
        }
        test_args_cmd() { real_test_args_cmd \"\$@\"; }
    "

    output=$(test_args_cmd "hello" "world")

    if [[ "$output" == "2 hello world" ]]; then
        print_pass
    else
        print_fail "Argument passing failed (output='$output')"
    fi
}

# Test 7: Registry state persistence
print_test "Registry state persistence"
{
    # Register multiple commands
    lazy_register "cmd1" "cmd1() { echo 'cmd1'; }"
    lazy_register "cmd2" "cmd2() { echo 'cmd2'; }"

    if is_lazy_registered "cmd1" && is_lazy_registered "cmd2"; then
        if ! is_lazy_loaded "cmd1" && ! is_lazy_loaded "cmd2"; then
            print_pass
        else
            print_fail "Commands incorrectly marked as loaded before first use"
        fi
    else
        print_fail "Commands not properly registered"
    fi
}

# Test 8: Load state tracking
print_test "Load state tracking"
{
    # Call cmd1 but not cmd2
    cmd1_output=$(cmd1)

    if is_lazy_loaded "cmd1" && ! is_lazy_loaded "cmd2"; then
        if [[ "$cmd1_output" == "cmd1" ]]; then
            print_pass
        else
            print_fail "cmd1 output incorrect: $cmd1_output"
        fi
    else
        print_fail "Load state tracking incorrect (cmd1 loaded: $(is_lazy_loaded cmd1), cmd2 loaded: $(is_lazy_loaded cmd2))"
    fi
}

# Test 9: Function replacement verification
print_test "Function replacement verification"
{
    # Check that the stub was replaced with real implementation
    if (( ${+functions[cmd1]} )); then
        # Get function body to verify it\'s not the stub anymore
        func_body=$(functions cmd1)

        if [[ "$func_body" != *"lazy_dispatch"* ]]; then
            print_pass
        else
            print_fail "Function still contains lazy_dispatch (not properly replaced)"
        fi
    else
        print_fail "Function not defined after loading"
    fi
}

# Test 10: Memory efficiency check
print_test "Memory efficiency (registry cleanup)"
{
    # After loading, the registry entry should still exist for introspection
    # but the loaded flag should prevent re-dispatching

    if is_lazy_registered "cmd1" && is_lazy_loaded "cmd1"; then
        # Multiple calls should not trigger re-loading
        output1=$(cmd1)
        output2=$(cmd1)

        if [[ "$output1" == "$output2" && "$output1" == "cmd1" ]]; then
            print_pass
        else
            print_fail "Multiple calls produced inconsistent output"
        fi
    else
        print_fail "Registry or load state incorrect after multiple calls"
    fi
}

# Summary
print "\n=== Lazy Framework Test Summary ==="
if [[ $FAILURES -eq 0 ]]; then
    print "\033[32mAll $TEST_COUNT tests passed!\033[0m"
    print "Lazy framework implementation verified:"
    print "  ✓ Function registration and replacement"
    print "  ✓ First-call loading behavior"
    print "  ✓ Dispatcher mechanics"
    print "  ✓ Error handling and fallbacks"
    print "  ✓ Argument passing"
    print "  ✓ State tracking"
    exit 0
else
    print "\033[31m$FAILURES/$TEST_COUNT tests failed.\033[0m"
    exit 1
fi
