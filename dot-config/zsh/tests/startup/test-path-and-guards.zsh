#!/usr/bin/env bash
set -euo pipefail
export ZDOTDIR="$PWD"
out=$(timeout 15s zsh -i -c '
  echo "OK:date=$(command -v date && echo yes || echo no)"
  echo "OK:rg=$(command -v rg && echo yes || echo no)"
  echo "OK:pre=$(print -r -- ${ZSH_ENABLE_PREPLUGIN_REDESIGN-})"
  echo "OK:post=$(print -r -- ${ZSH_ENABLE_POSTPLUGIN_REDESIGN-UNSET})"
  echo "OK:widgets_avail=$(( ${+widgets} ))"
  echo "OK:RPS1=$(( ${+parameters[RPS1]} ))"
  echo "OK:aws_fn=$(( ${+functions[aws_prompt_info]} ))"
  echo "OK:path_vs_base=$(( ${#path} >= ${#ZQS_BASELINE_path} ))"
  exit
' 2>&1)
echo "$out"
echo ""
echo "=== VALIDATION ==="
grep -q "OK:date=.*date" <<< "$out" && echo "✅ date command available" || echo "❌ date command missing"
grep -q "OK:rg=.*rg" <<< "$out" && echo "✅ rg command available" || echo "ℹ️  rg not installed; check PATH or install ripgrep"
grep -q "OK:pre=1" <<< "$out" && echo "✅ pre-plugin redesign enabled" || echo "❌ pre-plugin redesign not enabled"
grep -q "OK:post=0" <<< "$out" && echo "✅ post-plugin redesign disabled" || echo "❌ post-plugin redesign not disabled"
grep -q "OK:RPS1=1" <<< "$out" && echo "✅ RPS1 variable initialized" || echo "❌ RPS1 variable not initialized"
grep -q "OK:path_vs_base=1" <<< "$out" && echo "✅ PATH baseline preserved" || echo "❌ PATH baseline reduced"

echo ""
if grep -q "widgets\[.*\]: parameter not set" <<< "$out"; then
    echo "⚠️  Widget parameter errors still present"
else
    echo "✅ No widget parameter errors"
fi

if grep -q "command not found:" <<< "$out"; then
    echo "⚠️  Some 'command not found' errors still present (check legacy modules)"
else
    echo "✅ No command not found errors"
fi

if grep -q "Insecure world writable dir" <<< "$out"; then
    echo "⚠️  Ruby security warnings still present"
else
    echo "✅ No Ruby security warnings"
fi