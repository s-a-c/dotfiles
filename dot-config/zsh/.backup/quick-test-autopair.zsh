#!/usr/bin/env zsh
echo "🧪 Quick Autopair Test"
echo "===================="

echo "Checking environment:"
echo "  ZSH_ENABLE_PREPLUGIN_REDESIGN: ${ZSH_ENABLE_PREPLUGIN_REDESIGN:-NOT_SET}"
echo "  ZSH_AUTOPAIR_MODULE_LOADED: ${ZSH_AUTOPAIR_MODULE_LOADED:-NOT_SET}" 
echo "  SIMPLE_AUTOPAIR_PAIRS: $([[ -n "${SIMPLE_AUTOPAIR_PAIRS+x}" ]] && echo "defined (${#SIMPLE_AUTOPAIR_PAIRS[@]} pairs)" || echo "NOT_DEFINED")"

if [[ -n "${SIMPLE_AUTOPAIR_PAIRS+x}" ]]; then
    echo "  Configured pairs: ${(@k)SIMPLE_AUTOPAIR_PAIRS}"
fi

echo
echo "Widget check:"
for widget in simple-autopair-insert simple-autopair-close simple-autopair-delete; do
    if [[ -n "${widgets[$widget]:-}" ]]; then
        echo "  $widget: ✅ registered"
    else
        echo "  $widget: ❌ missing"
    fi
done

echo
echo "Testing angle brackets specifically:"
if [[ "${SIMPLE_AUTOPAIR_PAIRS['<']:-}" == ">" ]]; then
    echo "  ✅ < → > configured correctly"
else
    echo "  ❌ < → > not configured"
fi