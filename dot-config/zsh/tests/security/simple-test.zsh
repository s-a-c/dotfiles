#!/usr/bin/env zsh
#=============================================================================
# File: simple-test.zsh
# Purpose: Simple focused test for environment sanitization
#=============================================================================

# Set up test environment
export ZSH_ENV_TESTING="true"
export ZSH_ENV_SECURITY_LEVEL="WARN"
export ZSH_ENV_SECURITY_LOG="/tmp/simple-test-env.log"
export ZSH_ENV_SECURE_UMASK="022"

echo "🧪 Running Simple Environment Sanitization Test"

# Source the sanitization script
if ! source "$HOME/.config/zsh/.zshrc.pre-plugins.d/05-environment-sanitization.zsh"; then
    echo "❌ Failed to source sanitization script"
    exit 1
fi

echo "✅ Script sourced successfully"

# Test 1: Basic PATH validation
echo "🔍 Test 1: PATH validation..."
if _validate_path_security "/usr/bin:/bin" >/dev/null 2>&1; then
    echo "✅ Secure PATH validation passed"
else
    echo "❌ Secure PATH validation failed"
fi

if ! _validate_path_security ".:/usr/bin:/bin" >/dev/null 2>&1; then
    echo "✅ Insecure PATH validation correctly failed"
else
    echo "❌ Insecure PATH validation should have failed"
fi

# Test 2: PATH sanitization
echo "🔍 Test 2: PATH sanitization..."
sanitized="$(_sanitize_path ".:/usr/bin:/tmp:/bin")"
if [[ "$sanitized" == *"/usr/bin"* && "$sanitized" != *"."* && "$sanitized" != *"/tmp"* ]]; then
    echo "✅ PATH sanitization working correctly"
else
    echo "❌ PATH sanitization failed: $sanitized"
fi

# Test 3: Sensitive variable detection
echo "🔍 Test 3: Sensitive variable detection..."
export TEST_PASSWORD="secret123"
export TEST_NORMAL="normal_value"

sensitive_vars="$(_find_sensitive_variables)"
if echo "$sensitive_vars" | grep -q "TEST_PASSWORD" && ! echo "$sensitive_vars" | grep -q "TEST_NORMAL"; then
    echo "✅ Sensitive variable detection working"
else
    echo "❌ Sensitive variable detection failed"
    echo "Found: $sensitive_vars"
fi

unset TEST_PASSWORD TEST_NORMAL

# Test 4: Main sanitization function
echo "🔍 Test 4: Main sanitization function..."
if _sanitize_environment >/dev/null 2>&1; then
    echo "✅ Main sanitization function works"
else
    echo "❌ Main sanitization function failed"
fi

echo "🎉 Simple test completed"
