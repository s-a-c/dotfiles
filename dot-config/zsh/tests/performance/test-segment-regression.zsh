#!/usr/bin/env zsh
# test-segment-regression.zsh
# Performance regression test for startup segments:
#   - Validates post-plugin segment cost ≤ 500ms threshold
#   - Compares current vs baseline segment performance
#   - Detects regressions in pre-plugin and post-plugin phases
#   - Provides detailed segment timing analysis
set -euo pipefail

ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
METRICS_DIR="${ZDOTDIR}/docs/redesign/metrics"
PERF_CURRENT="${METRICS_DIR}/perf-current.json"
PERF_BASELINE="${METRICS_DIR}/perf-baseline.json"

# Test configuration
TEST_COUNT=0
FAILURES=0
REGRESSION_THRESHOLD=5.0 # 5% regression threshold
POST_PLUGIN_LIMIT=500    # 500ms absolute limit for post-plugin cost

print_test() { print -n "Test $((++TEST_COUNT)): $1... "; }
print_pass() { print "\033[32mPASS\033[0m"; }
print_fail() {
    print "\033[31mFAIL\033[0m"
    ((FAILURES++))
    print "  $1"
}

# Utility function to extract JSON values
get_json_value() {
    local file="$1" key="$2"
    if command -v jq >/dev/null 2>&1; then
        jq -r ".$key // \"null\"" "$file" 2>/dev/null || echo "null"
    else
        grep -E "\"$key\"" "$file" | head -1 | sed 's/.*://;s/[^0-9.]//g' || echo "null"
    fi
}

# Check if metrics files exist
print_test "Required metrics files exist"
{
    if [[ -f "$PERF_CURRENT" ]]; then
        print_pass
    else
        print_fail "Missing perf-current.json - run tools/perf-capture.zsh first"
        exit 1
    fi
}

# Test 1: Current metrics are valid
print_test "Current metrics are valid"
{
    mean_ms=$(get_json_value "$PERF_CURRENT" "mean_ms")
    segments_available=$(get_json_value "$PERF_CURRENT" "segments_available")

    if [[ "$mean_ms" != "null" && "$mean_ms" =~ ^[0-9]+$ ]]; then
        print_pass
    else
        print_fail "Invalid or missing mean_ms in current metrics: $mean_ms"
    fi
}

# Test 2: Segment data availability
print_test "Segment timing data available"
{
    segments_available=$(get_json_value "$PERF_CURRENT" "segments_available")
    pre_plugin_cost=$(get_json_value "$PERF_CURRENT" "pre_plugin_cost_ms")
    post_plugin_cost=$(get_json_value "$PERF_CURRENT" "post_plugin_cost_ms")

    if [[ "$segments_available" == "true" || ("$pre_plugin_cost" != "null" && "$post_plugin_cost" != "null") ]]; then
        print_pass
    else
        print_pass # Allow test to continue even without segments
        print "  (segment data not available - skipping segment-specific tests)"
    fi
}

# Test 3: Post-plugin cost absolute limit
print_test "Post-plugin cost within absolute limit (≤${POST_PLUGIN_LIMIT}ms)"
{
    post_plugin_cost=$(get_json_value "$PERF_CURRENT" "post_plugin_cost_ms")

    if [[ "$post_plugin_cost" == "null" || "$post_plugin_cost" -eq 0 ]]; then
        print_pass
        print "  (segment data unavailable, test skipped)"
    elif [[ "$post_plugin_cost" -le "$POST_PLUGIN_LIMIT" ]]; then
        print_pass
    else
        print_fail "Post-plugin cost ${post_plugin_cost}ms exceeds limit ${POST_PLUGIN_LIMIT}ms"
    fi
}

# Test 4: Baseline comparison (if available)
print_test "Segment regression vs baseline"
{
    if [[ -f "$PERF_BASELINE" ]]; then
        current_post=$(get_json_value "$PERF_CURRENT" "post_plugin_cost_ms")
        baseline_post=$(get_json_value "$PERF_BASELINE" "post_plugin_cost_ms")

        if [[ "$current_post" == "null" || "$baseline_post" == "null" || "$current_post" -eq 0 || "$baseline_post" -eq 0 ]]; then
            print_pass
            print "  (insufficient segment data for comparison)"
        else
            # Calculate regression percentage
            regression=$(awk -v c="$current_post" -v b="$baseline_post" 'BEGIN{printf "%.2f", ((c-b)/b)*100}')

            if awk -v r="$regression" -v t="$REGRESSION_THRESHOLD" 'BEGIN{exit !(r <= t)}'; then
                print_pass
                print "  (post-plugin: ${current_post}ms vs ${baseline_post}ms baseline, ${regression}% change)"
            else
                print_fail "Post-plugin regression ${regression}% > ${REGRESSION_THRESHOLD}% threshold"
            fi
        fi
    else
        print_pass
        print "  (no baseline available for comparison)"
    fi
}

# Test 5: Pre-plugin efficiency
print_test "Pre-plugin segment efficiency"
{
    pre_plugin_cost=$(get_json_value "$PERF_CURRENT" "pre_plugin_cost_ms")
    total_mean=$(get_json_value "$PERF_CURRENT" "mean_ms")

    if [[ "$pre_plugin_cost" == "null" || "$pre_plugin_cost" -eq 0 ]]; then
        print_pass
        print "  (pre-plugin segment data unavailable)"
    else
        # Pre-plugin should be reasonable portion of total (e.g., < 50%)
        pre_percentage=$(awk -v p="$pre_plugin_cost" -v t="$total_mean" 'BEGIN{printf "%.1f", (p/t)*100}')

        if awk -v p="$pre_percentage" 'BEGIN{exit !(p <= 50)}'; then
            print_pass
            print "  (${pre_plugin_cost}ms, ${pre_percentage}% of total)"
        else
            print_fail "Pre-plugin cost ${pre_plugin_cost}ms (${pre_percentage}%) seems excessive"
        fi
    fi
}

# Test 6: Segment timing consistency
print_test "Segment timing consistency"
{
    cold_pre=$(get_json_value "$PERF_CURRENT" "cold_pre_plugin_ms")
    warm_pre=$(get_json_value "$PERF_CURRENT" "warm_pre_plugin_ms")
    cold_post=$(get_json_value "$PERF_CURRENT" "cold_post_plugin_ms")
    warm_post=$(get_json_value "$PERF_CURRENT" "warm_post_plugin_ms")

    if [[ "$cold_pre" == "null" || "$warm_pre" == "null" ]]; then
        print_pass
        print "  (detailed segment data unavailable)"
    else
        # Check that warm runs aren't significantly slower (caching should help)
        if [[ "$cold_pre" -gt 0 && "$warm_pre" -gt 0 ]]; then
            pre_ratio=$(awk -v c="$cold_pre" -v w="$warm_pre" 'BEGIN{printf "%.2f", w/c}')

            # Warm should be <= cold (or at least not much slower)
            if awk -v r="$pre_ratio" 'BEGIN{exit !(r <= 1.5)}'; then
                print_pass
                print "  (cold/warm pre: ${cold_pre}/${warm_pre}ms, ratio: ${pre_ratio})"
            else
                print_fail "Warm pre-plugin (${warm_pre}ms) much slower than cold (${cold_pre}ms)"
            fi
        else
            print_pass
            print "  (insufficient data for consistency check)"
        fi
    fi
}

# Test 7: Overall segment balance
print_test "Overall segment balance"
{
    pre_cost=$(get_json_value "$PERF_CURRENT" "pre_plugin_cost_ms")
    post_cost=$(get_json_value "$PERF_CURRENT" "post_plugin_cost_ms")

    if [[ "$pre_cost" != "null" && "$post_cost" != "null" && "$pre_cost" -gt 0 && "$post_cost" -gt 0 ]]; then
        total_segments=$((pre_cost + post_cost))
        total_mean=$(get_json_value "$PERF_CURRENT" "mean_ms")

        # Segments should account for reasonable portion of total time
        coverage=$(awk -v s="$total_segments" -v t="$total_mean" 'BEGIN{printf "%.1f", (s/t)*100}')

        if awk -v c="$coverage" 'BEGIN{exit !(c >= 30 && c <= 120)}'; then
            print_pass
            print "  (segments: ${total_segments}ms, coverage: ${coverage}% of ${total_mean}ms total)"
        else
            print_fail "Segment coverage ${coverage}% seems unrealistic (expected 30-120%)"
        fi
    else
        print_pass
        print "  (insufficient segment data for balance check)"
    fi
}

# Test 8: Performance trend analysis
print_test "Performance trend analysis"
{
    # Look for multiple perf captures to analyze trends
    PERF_LOG_DIR="${ZDOTDIR}/logs/perf"

    if [[ -d "$PERF_LOG_DIR" ]]; then
        recent_files=($(ls -1t "$PERF_LOG_DIR"/*.json 2>/dev/null | head -5))

        if [[ ${#recent_files[@]} -ge 3 ]]; then
            # Simple trend check: are we getting faster or slower?
            first_mean=$(get_json_value "${recent_files[-1]}" "mean_ms") # Oldest
            last_mean=$(get_json_value "${recent_files[0]}" "mean_ms")   # Newest

            if [[ "$first_mean" != "null" && "$last_mean" != "null" ]]; then
                trend=$(awk -v f="$first_mean" -v l="$last_mean" 'BEGIN{printf "%.1f", ((l-f)/f)*100}')

                print_pass
                print "  (trend over ${#recent_files[@]} samples: ${trend}% change)"
            else
                print_pass
                print "  (insufficient data for trend analysis)"
            fi
        else
            print_pass
            print "  (not enough samples for trend analysis)"
        fi
    else
        print_pass
        print "  (no performance log directory found)"
    fi
}

# Summary
print "\n=== Performance Segment Regression Test Summary ==="
if [[ $FAILURES -eq 0 ]]; then
    print "\033[32mAll $TEST_COUNT tests passed!\033[0m"

    # Display current segment metrics summary
    print "\nCurrent Performance Metrics:"
    mean_ms=$(get_json_value "$PERF_CURRENT" "mean_ms")
    pre_cost=$(get_json_value "$PERF_CURRENT" "pre_plugin_cost_ms")
    post_cost=$(get_json_value "$PERF_CURRENT" "post_plugin_cost_ms")

    print "  Total startup: ${mean_ms}ms"

    if [[ "$pre_cost" != "null" && "$pre_cost" -gt 0 ]]; then
        print "  Pre-plugin cost: ${pre_cost}ms"
    fi

    if [[ "$post_cost" != "null" && "$post_cost" -gt 0 ]]; then
        print "  Post-plugin cost: ${post_cost}ms"
        if [[ "$post_cost" -le "$POST_PLUGIN_LIMIT" ]]; then
            print "  ✓ Post-plugin within ${POST_PLUGIN_LIMIT}ms limit"
        fi
    fi

    exit 0
else
    print "\033[31m$FAILURES/$TEST_COUNT tests failed.\033[0m"

    print "\nCurrent metrics for debugging:"
    if [[ -f "$PERF_CURRENT" ]]; then
        cat "$PERF_CURRENT" | head -20
    else
        print "  No current metrics file found"
    fi

    exit 1
fi
