#!/opt/homebrew/bin/zsh
# 02-guidelines-checksum.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#     Earliest practical point (after PATH safety start marker) to compute and export
#     the composite policy GUIDELINES_CHECKSUM required by orchestration policy
#     (see AGENT.md). Ensures:
#         - Integrity / compliance headers authored later can embed the correct checksum.
#         - perf / integrity tooling can include checksum in manifests & logs.
#
# FEATURES:
#     - Attempts to source segment-lib.zsh for unified helpers (optional; silent if absent).
#     - Exports GUIDELINES_CHECKSUM (if not already set) using:
#             1. tools/guidelines-checksum.sh (authoritative)
#             2. Fallback inline hashing (master + sorted modules)
#     - Emits POLICY line to $PERF_SEGMENT_LOG (once) for correlation:
#             POLICY checksum=<sha256>
#
# SAFETY:
#     - Read-only operations; no mutation outside exported GUIDELINES_CHECKSUM and
#         sentinel _LOADED_02_GUIDELINES_CHECKSUM.
#     - Silent degradation if hashing utilities unavailable (leaves checksum unset).
#
# ENV DEPENDENCIES:
#     - ZDOTDIR (preferred base)
#     - PERF_SEGMENT_LOG (optional; emission only if writable)
#
# EXIT / FLOW:
#     - This file should not exit or return non-zero; always continue startup.
#
# FUTURE EXTENSIONS:
#     - Attach lastModified metadata (mtime master/modules) into an exported JSON blob.
#     - Validate drift vs previously recorded baseline (promotion guard hook).
#
# ------------------------------------------------------------------------------

# Guard against re-sourcing
[[ -n ${_LOADED_02_GUIDELINES_CHECKSUM:-} ]] && return
_LOADED_02_GUIDELINES_CHECKSUM=1

typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }

# Attempt to source segment-lib early (provides _zsh_perf_export_guidelines_checksum)
# We do this BEFORE computing fallback so that, if available, its logic wins.
__gl_base="${ZDOTDIR:-$HOME/.config/zsh}"
if [[ -r "${__gl_base}/tools/segment-lib.zsh" ]]; then
    # shellcheck disable=SC1090
    source "${__gl_base}/tools/segment-lib.zsh" 2>/dev/null || true
fi

# If segment-lib already exported checksum we are done
if [[ -z ${GUIDELINES_CHECKSUM:-} ]]; then
    # Primary authoritative script path
    __guidelines_script="${__gl_base}/tools/guidelines-checksum.sh"
    if [[ -x "${__guidelines_script}" ]]; then
        GUIDELINES_CHECKSUM="$("${__guidelines_script}" 2>/dev/null | head -1 | tr -d '[:space:]')" || true
    fi
fi

# Inline fallback (only if still unset)
if [[ -z ${GUIDELINES_CHECKSUM:-} ]]; then
    __ai_root="$(builtin cd -q "${__gl_base}/../ai" 2>/dev/null && pwd || echo "")"
    __master="${__ai_root}/guidelines.md"
    __modules_dir="${__ai_root}/guidelines"

    if [[ -f "${__master}" && -d "${__modules_dir}" ]]; then
        # Pick hashing tool
        __hasher=""
        if command -v shasum >/dev/null 2>&1; then
            __hasher="shasum -a 256"
        elif command -v sha256sum >/dev/null 2>&1; then
            __hasher="sha256sum"
        elif command -v openssl >/dev/null 2>&1; then
            __hasher="openssl dgst -sha256"
        fi

        if [[ -n $__hasher ]]; then
            if [[ $__hasher == "openssl dgst -sha256" ]]; then
                GUIDELINES_CHECKSUM="$(
                    ( cat "${__master}"; find "${__modules_dir}" -type f -print | LC_ALL=C sort | xargs cat ) \
                        | openssl dgst -sha256 2>/dev/null | awk '{print $2}'
                )" || true
            else
                GUIDELINES_CHECKSUM="$(
                    ( cat "${__master}"; find "${__modules_dir}" -type f -print | LC_ALL=C sort | xargs cat ) \
                        | ${=__hasher} 2>/dev/null | awk '{print $1}'
                )" || true
            fi
        fi
    fi
fi

# Export if we have it
[[ -n ${GUIDELINES_CHECKSUM:-} ]] && export GUIDELINES_CHECKSUM

# Emit POLICY marker once (avoid duplicates if later modules also emit)
if [[ -n ${GUIDELINES_CHECKSUM:-} && -n ${PERF_SEGMENT_LOG:-} && -w ${PERF_SEGMENT_LOG:-/dev/null} ]]; then
    if [[ -z ${_POLICY_MARKER_EMITTED:-} ]]; then
        print "POLICY checksum=${GUIDELINES_CHECKSUM}" >>"${PERF_SEGMENT_LOG}" 2>/dev/null || true
        _POLICY_MARKER_EMITTED=1
        export _POLICY_MARKER_EMITTED
    fi
fi

zsh_debug_echo "# [policy] guidelines checksum module loaded checksum=${GUIDELINES_CHECKSUM:-unset}"

# Cleanup internal temps
unset __gl_base __guidelines_script __ai_root __master __modules_dir __hasher

# End 02-guidelines-checksum.zsh
