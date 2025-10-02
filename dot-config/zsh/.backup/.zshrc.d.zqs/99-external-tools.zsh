#!/usr/bin/env zsh
# 99-external-tools.zsh - External tool PATH additions for ZQS
# Part of the migration to symlinked ZQS .zshrc

# =================================================================================
# === External Tool Additions ===
# =================================================================================

# To disable external tool loading, set: export SKIP_EXTERNAL_TOOLS=1
if [[ "${SKIP_EXTERNAL_TOOLS:-0}" == "1" ]]; then
    zf::debug "# [post-plugin-ext] External tools loading disabled (SKIP_EXTERNAL_TOOLS=1)"
    return 0
fi

# Added by LM Studio CLI (lms)
if [[ -d "/Users/s-a-c/.lmstudio/bin" ]]; then
    export PATH="$PATH:/Users/s-a-c/.lmstudio/bin"
    zf::debug "# [post-plugin-ext] Added LM Studio CLI to PATH"
fi
# End of LM Studio CLI section

zf::debug "# [post-plugin-ext] External tools loaded"
