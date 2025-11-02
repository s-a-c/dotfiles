#!/usr/bin/env bash
# Test harness to compare eval vs source for Starship initialization

echo "=== Starship Eval vs Source Test Harness ==="
echo

cd ${HOME}/dotfiles/dot-config/zsh

# Test 1: Check if starship init generates output
echo "=== Test 1: Starship Init Output Check ==="
if command -v starship >/dev/null 2>&1; then
    echo "Starship available: yes"
    starship_output=$(starship init zsh 2>/dev/null)
    echo "Starship init output length: ${#starship_output} characters"
    echo "First 200 chars: ${starship_output:0:200}..."
else
    echo "Starship not available"
    exit 1
fi

echo

# Test 2: Test eval method in isolated ZSH
echo "=== Test 2: Eval Method Test ==="
timeout 10s bash -c '
ZDOTDIR="${HOME}/dotfiles/dot-config/zsh"
export ZDOTDIR
echo "Testing eval method..."
zsh -c "
unset STARSHIP_SHELL
echo \"Before eval: STARSHIP_SHELL=\${STARSHIP_SHELL:-not_set}\"
eval \"\$(starship init zsh)\"
echo \"After eval: STARSHIP_SHELL=\${STARSHIP_SHELL:-not_set}\"
echo \"PS1 length: \${#PS1}\"
echo \"PROMPT length: \${#PROMPT}\"
exit
" 2>&1
'

echo

# Test 3: Test source method with temp file
echo "=== Test 3: Source Method Test ==="
temp_starship_file=$(mktemp)
starship init zsh > "$temp_starship_file" 2>/dev/null

timeout 10s bash -c "
ZDOTDIR=\"${HOME}/dotfiles/dot-config/zsh\"
export ZDOTDIR
echo \"Testing source method...\"
zsh -c \"
unset STARSHIP_SHELL
echo \\\"Before source: STARSHIP_SHELL=\\\${STARSHIP_SHELL:-not_set}\\\"
source $temp_starship_file
echo \\\"After source: STARSHIP_SHELL=\\\${STARSHIP_SHELL:-not_set}\\\"
echo \\\"PS1 length: \\\${#PS1}\\\"
echo \\\"PROMPT length: \\\${#PROMPT}\\\"
exit
\\\" 2>&1
"

rm -f "$temp_starship_file"

echo

# Test 4: Test in full ZSH environment with debug
echo "=== Test 4: Full Environment Test ==="
timeout 15s bash -c '
ZDOTDIR="${HOME}/dotfiles/dot-config/zsh"
export ZDOTDIR
export ZSH_DEBUG=1
echo "Testing in full ZSH environment..."
zsh -i -c "
echo \"=== Starship Status in Full Environment ===\"
echo \"Starship command available: \$(command -v starship >/dev/null && echo yes || echo no)\"
echo \"STARSHIP_SHELL: \${STARSHIP_SHELL:-not_set}\"
echo \"STARSHIP_CONFIG: \${STARSHIP_CONFIG:-not_set}\"
echo \"PS1 starts with: \${PS1:0:50}...\"
echo \"PROMPT starts with: \${PROMPT:0:50}...\"

echo
echo \"=== Manual Starship Test ===\"
# Test manual initialization
unset STARSHIP_SHELL PROMPT PS1
eval \\\"\\\$(starship init zsh)\\\"
echo \"Manual eval result - STARSHIP_SHELL: \${STARSHIP_SHELL:-not_set}\"
exit
" 2>&1 | grep -E "(starship|Starship|STARSHIP|Manual|===)"
'

echo
echo "=== Test Complete ==="
