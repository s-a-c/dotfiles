#!/usr/bin/env zsh
# Advanced diagnostic script to pinpoint exact hang location in .zshrc
# Uses fine-grained tracing and timeout protection

set -u

# Configuration
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
ZSHRC_FILE="$ZDOTDIR/.zshrc"
TRACE_LOG="/tmp/zsh-trace-$(date +%Y%m%d-%H%M%S).log"

# Colors
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' NC=''
fi

echo -e "${BLUE}=== Advanced ZSH Hang Diagnostics ===${NC}"
echo "ZDOTDIR: $ZDOTDIR"
echo "Trace log: $TRACE_LOG"
echo ""

# Test 1: Check line-by-line execution
echo -e "${YELLOW}Test 1: Line-by-line execution trace${NC}"
echo "Executing .zshrc with detailed tracing..."

# Create a wrapper script that adds markers
cat > /tmp/trace-wrapper.zsh << 'EOF'
#!/usr/bin/env zsh
set -x  # Enable tracing

# Disable plugins for testing
export NO_ZGENOM=1
export SKIP_PLUGINS=1
export PERF_CAPTURE_FAST=1

# Add trace markers
TRACE_COUNTER=0
trace_mark() {
    ((TRACE_COUNTER++))
    echo "TRACE[$TRACE_COUNTER]: $1" >&2
}

# Override problematic commands
alias ssh-add='echo "[MOCK] ssh-add"'
ssh-add() { echo "[MOCK] ssh-add $@"; }

# Source with markers
trace_mark "Starting .zshrc"
source "$1" 2>&1 | while IFS= read -r line; do
    echo "$line"
    # Add periodic markers
    if [[ $((RANDOM % 10)) -eq 0 ]]; then
        echo "ALIVE: $(date +%H:%M:%S.%N)" >&2
    fi
done
trace_mark "Completed .zshrc"
EOF

chmod +x /tmp/trace-wrapper.zsh

# Run with timeout and capture output
echo "Running with 3-second timeout..."
if timeout 3 /tmp/trace-wrapper.zsh "$ZSHRC_FILE" > "$TRACE_LOG" 2>&1; then
    echo -e "${GREEN}✓ Completed successfully${NC}"
else
    EXIT_CODE=$?
    if [[ $EXIT_CODE -eq 124 ]]; then
        echo -e "${RED}✗ TIMEOUT after 3 seconds${NC}"
        echo ""
        echo "Last 20 lines before timeout:"
        tail -20 "$TRACE_LOG" | sed 's/^/  /'
    else
        echo -e "${RED}✗ Failed with exit code $EXIT_CODE${NC}"
    fi
fi

echo ""
echo -e "${YELLOW}Test 2: Binary search for hang location${NC}"

# Extract .zshrc into sections
total_lines=$(wc -l < "$ZSHRC_FILE")
echo "Total lines in .zshrc: $total_lines"

# Function to test a range
test_range() {
    local start=$1
    local end=$2
    local temp_file="/tmp/zshrc-test-$$"

    # Create test file with range
    {
        echo "#!/usr/bin/env zsh"
        echo "# Testing lines $start-$end"
        echo "export NO_ZGENOM=1"
        echo "export SKIP_PLUGINS=1"
        head -n "$end" "$ZSHRC_FILE" | tail -n $((end - start + 1))
        echo "echo 'COMPLETED'"
    } > "$temp_file"

    # Test with timeout
    if timeout 1 zsh "$temp_file" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Binary search for problematic section
echo "Performing binary search for problematic section..."
low=1
high=$total_lines
problem_start=0
problem_end=0

while [[ $low -le $high ]]; do
    mid=$(( (low + high) / 2 ))

    echo -n "Testing lines 1-$mid... "
    if test_range 1 "$mid"; then
        echo -e "${GREEN}OK${NC}"
        low=$((mid + 1))
    else
        echo -e "${RED}HANG${NC}"
        problem_end=$mid
        high=$((mid - 1))
    fi
done

if [[ $problem_end -gt 0 ]]; then
    # Narrow down further
    echo ""
    echo -e "${YELLOW}Narrowing down to specific line...${NC}"

    start=$((problem_end - 10))
    [[ $start -lt 1 ]] && start=1
    end=$((problem_end + 10))
    [[ $end -gt $total_lines ]] && end=$total_lines

    for line in $(seq $start $end); do
        echo -n "Line $line: "
        if test_range 1 "$line"; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${RED}HANG${NC} - Problem found!"
            echo ""
            echo "Problematic line:"
            sed -n "${line}p" "$ZSHRC_FILE" | sed 's/^/  /'
            problem_start=$line
            break
        fi
    done
fi

echo ""
echo -e "${YELLOW}Test 3: Check specific known problematic commands${NC}"

# Test specific commands that might hang
problematic_commands=(
    "ssh-add -l"
    "ssh-add -L"
    "gpg-agent"
    "keychain"
    "_check-for-zsh-quickstart-update"
    "compinit"
    "git rev-parse"
    "brew"
    "nvm"
    "rbenv"
    "pyenv"
)

for cmd in "${problematic_commands[@]}"; do
    echo -n "Checking for '$cmd'... "
    if grep -q "$cmd" "$ZSHRC_FILE"; then
        echo -e "${YELLOW}FOUND${NC}"
        grep -n "$cmd" "$ZSHRC_FILE" | head -3 | sed 's/^/  Line /'
    else
        echo "not found"
    fi
done

echo ""
echo -e "${YELLOW}Test 4: Check for blocking reads or waits${NC}"

# Look for potentially blocking operations
echo "Checking for blocking operations..."
blocking_patterns=(
    "read -r"
    "read -p"
    "wait"
    "sleep"
    "while.*do$"
    "for.*do$"
    "select.*in"
    "vared"
)

for pattern in "${blocking_patterns[@]}"; do
    if grep -E "$pattern" "$ZSHRC_FILE" >/dev/null 2>&1; then
        echo -e "${YELLOW}Found pattern: $pattern${NC}"
        grep -nE "$pattern" "$ZSHRC_FILE" | head -3 | sed 's/^/  Line /'
    fi
done

echo ""
echo -e "${YELLOW}Test 5: Test with all safety flags${NC}"

# Test with maximum safety
echo "Testing with all safety flags enabled..."
SAFETY_ENV=(
    "NO_ZGENOM=1"
    "SKIP_PLUGINS=1"
    "PERF_CAPTURE_FAST=1"
    "SKIP_EXTERNAL_TOOLS=1"
    "ZSH_NO_COMPINIT=1"
    "DISABLE_AUTO_UPDATE=true"
    "ZSH_DISABLE_COMPFIX=true"
)

env_string="${SAFETY_ENV[@]}"
if timeout 2 zsh -c "export $env_string; source '$ZSHRC_FILE'; echo 'OK'" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Loads with safety flags${NC}"
else
    echo -e "${RED}✗ Still hangs with safety flags${NC}"
fi

echo ""
echo -e "${BLUE}=== Summary ===${NC}"
echo ""

if [[ $problem_start -gt 0 ]]; then
    echo -e "${RED}Problem detected at line $problem_start${NC}"
    echo "Context (5 lines before and after):"
    sed -n "$((problem_start-5)),$((problem_start+5))p" "$ZSHRC_FILE" | \
        awk -v prob=$problem_start -v start=$((problem_start-5)) \
        '{
            line_num = NR + start - 1
            if (line_num == prob) {
                printf "\033[1;31m%4d: %s\033[0m\n", line_num, $0
            } else {
                printf "%4d: %s\n", line_num, $0
            }
        }'
else
    echo -e "${GREEN}No specific problem line identified${NC}"
fi

echo ""
echo "Diagnostics complete. Full trace log: $TRACE_LOG"
echo ""
echo "Recommended fixes:"
echo "1. Add timeout protection to any ssh-add commands"
echo "2. Disable SSH key listing: _zqs-set-setting list-ssh-keys false"
echo "3. Set SKIP_EXTERNAL_TOOLS=1 in .zshenv"
echo "4. Check for any interactive prompts in sourced files"

# Cleanup
rm -f /tmp/trace-wrapper.zsh /tmp/zshrc-test-*
