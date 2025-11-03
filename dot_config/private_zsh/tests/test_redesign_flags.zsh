#!/usr/bin/env bash
# Test redesign flags after .zshenv update

echo "=== Testing Redesign Flags After .zshenv Update ==="
echo

cd ${HOME}/.config/zsh

# Test 1: Check flags are set correctly by sourcing .zshenv directly
echo "=== Test 1: Direct .zshenv sourcing ==="
unset ZSH_ENABLE_PREPLUGIN_REDESIGN ZSH_ENABLE_POSTPLUGIN_REDESIGN
ZDOTDIR="$PWD" bash -c 'source .zshenv && echo "PREPLUGIN: ${ZSH_ENABLE_PREPLUGIN_REDESIGN:-UNSET}" && echo "POSTPLUGIN: ${ZSH_ENABLE_POSTPLUGIN_REDESIGN:-UNSET}"'

echo

# Test 2: Test with pre-set values
echo "=== Test 2: Pre-set values override ==="
ZDOTDIR="$PWD" ZSH_ENABLE_PREPLUGIN_REDESIGN=0 ZSH_ENABLE_POSTPLUGIN_REDESIGN=1 bash -c 'source .zshenv && echo "PREPLUGIN: ${ZSH_ENABLE_PREPLUGIN_REDESIGN:-UNSET}" && echo "POSTPLUGIN: ${ZSH_ENABLE_POSTPLUGIN_REDESIGN:-UNSET}"'

echo

# Test 3: Test invalid values normalization
echo "=== Test 3: Invalid values normalization ==="
ZDOTDIR="$PWD" ZSH_ENABLE_PREPLUGIN_REDESIGN=yes ZSH_ENABLE_POSTPLUGIN_REDESIGN=true bash -c 'source .zshenv && echo "PREPLUGIN: ${ZSH_ENABLE_PREPLUGIN_REDESIGN:-UNSET}" && echo "POSTPLUGIN: ${ZSH_ENABLE_POSTPLUGIN_REDESIGN:-UNSET}"'

echo

# Test 4: Test in actual ZSH startup
echo "=== Test 4: ZSH Startup Flag Check ==="
ZDOTDIR="$PWD" timeout 10s zsh -i -c 'echo "In ZSH - PREPLUGIN: $ZSH_ENABLE_PREPLUGIN_REDESIGN" && echo "In ZSH - POSTPLUGIN: $ZSH_ENABLE_POSTPLUGIN_REDESIGN" && exit' 2>/dev/null

echo
echo "=== Flag Testing Complete ==="
