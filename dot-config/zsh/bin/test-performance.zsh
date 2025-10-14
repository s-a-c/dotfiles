#!/usr/bin/env zsh
# Performance test script for zsh configuration
# Tests startup time and basic functionality after optimization

echo "🧪 ZSH Configuration Performance Test"
echo "====================================="
echo

# Test 1: Startup Time
echo "📊 Testing startup time..."
echo "Running 5 startup tests..."

total_time=0
for i in {1..5}; do
    start_time=$(date +%s%N)
    zsh -i -c 'exit' 2>/dev/null
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds
<<<<<<< HEAD
        zf::debug "  Test $i: ${duration}ms"
=======
        zsh_debug_echo "  Test $i: ${duration}ms"
>>>>>>> origin/develop
    total_time=$((total_time + duration))
done

average_time=$((total_time / 5))
echo "  Average startup time: ${average_time}ms"
echo

# Test 2: Function Conflicts
echo "🔍 Testing for function conflicts..."
conflicts=$(zsh -c "functions | grep -E '(safe_source|main|_sanitize)' | wc -l" 2>/dev/null)
if [[ $conflicts -eq 0 ]]; then
<<<<<<< HEAD
        zf::debug "  ✅ No function conflicts detected"
else
        zf::debug "  ⚠️  $conflicts potential function conflicts found"
=======
        zsh_debug_echo "  ✅ No function conflicts detected"
else
        zsh_debug_echo "  ⚠️  $conflicts potential function conflicts found"
>>>>>>> origin/develop
    zsh -c "functions | grep -E '(safe_source|main|_sanitize)'" 2>/dev/null
fi
echo

# Test 3: Plugin Loading
echo "🔌 Testing plugin functionality..."
<<<<<<< HEAD
plugin_test=$(zsh -i -c 'echo "Plugins loaded: $(echo ${#zsh_loaded_plugins[@]} 2>/dev/null || zf::debug "unknown")"' 2>/dev/null)
=======
plugin_test=$(zsh -i -c 'echo "Plugins loaded: $(echo ${#zsh_loaded_plugins[@]} 2>/dev/null || zsh_debug_echo "unknown")"' 2>/dev/null)
>>>>>>> origin/develop
echo "  $plugin_test"
echo

# Test 4: Git Config Caching
echo "🔧 Testing git config caching..."
if [[ -f ~/.config/zsh/.cache/git-config-cache ]]; then
<<<<<<< HEAD
    cache_age=$(( $(date +%s) - $(stat -f %m ~/.config/zsh/.cache/git-config-cache 2>/dev/null || zf::debug 0) ))
        zf::debug "  ✅ Git config cache exists (${cache_age}s old)"
else
        zf::debug "  ⚠️  Git config cache not found"
=======
    cache_age=$(( $(date +%s) - $(stat -f %m ~/.config/zsh/.cache/git-config-cache 2>/dev/null || zsh_debug_echo 0) ))
        zsh_debug_echo "  ✅ Git config cache exists (${cache_age}s old)"
else
        zsh_debug_echo "  ⚠️  Git config cache not found"
>>>>>>> origin/develop
fi
echo

# Test 5: PATH Integrity
echo "🛤️  Testing PATH integrity..."
path_entries=$(echo $PATH | tr ':' '\n' | wc -l)
unique_entries=$(echo $PATH | tr ':' '\n' | sort -u | wc -l)
echo "  PATH entries: $path_entries total, $unique_entries unique"
if [[ $path_entries -eq $unique_entries ]]; then
<<<<<<< HEAD
        zf::debug "  ✅ No duplicate PATH entries"
else
    duplicates=$((path_entries - unique_entries))
        zf::debug "  ⚠️  $duplicates duplicate PATH entries found"
=======
        zsh_debug_echo "  ✅ No duplicate PATH entries"
else
    duplicates=$((path_entries - unique_entries))
        zsh_debug_echo "  ⚠️  $duplicates duplicate PATH entries found"
>>>>>>> origin/develop
fi
echo

# Test 6: Error Check
echo "🚨 Testing for startup errors..."
error_output=$(zsh -i -c 'exit' 2>&1 | grep -i error | head -3)
if [[ -z "$error_output" ]]; then
<<<<<<< HEAD
        zf::debug "  ✅ No startup errors detected"
else
        zf::debug "  ⚠️  Startup errors found:"
        zf::debug "$error_output" | sed 's/^/    /'
=======
        zsh_debug_echo "  ✅ No startup errors detected"
else
        zsh_debug_echo "  ⚠️  Startup errors found:"
        zsh_debug_echo "$error_output" | sed 's/^/    /'
>>>>>>> origin/develop
fi
echo

# Summary
echo "📋 Performance Test Summary"
echo "=========================="
echo "Startup Time: ${average_time}ms"

# Performance rating
if [[ $average_time -lt 1000 ]]; then
    rating="🚀 Excellent"
elif [[ $average_time -lt 2000 ]]; then
    rating="✅ Good"
elif [[ $average_time -lt 3000 ]]; then
    rating="⚠️  Fair"
else
    rating="🐌 Needs Improvement"
fi

echo "Performance: $rating"
echo

# Recommendations
if [[ $average_time -gt 2000 ]]; then
<<<<<<< HEAD
        zf::debug "💡 Recommendations for further optimization:"
        zf::debug "   - Consider lazy loading more plugins"
        zf::debug "   - Check for slow-loading modules"
        zf::debug "   - Review plugin necessity"
=======
        zsh_debug_echo "💡 Recommendations for further optimization:"
        zsh_debug_echo "   - Consider lazy loading more plugins"
        zsh_debug_echo "   - Check for slow-loading modules"
        zsh_debug_echo "   - Review plugin necessity"
>>>>>>> origin/develop
    echo
fi

echo "✅ Performance test completed!"
