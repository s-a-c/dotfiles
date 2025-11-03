#!/usr/bin/env zsh
# test-guidelines-checksum-present.zsh
# Compliant with [${HOME}/.config/ai/guidelines.md](${HOME}/.config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Validate that perf-current.json includes a valid guidelines_checksum field,
#   and that the value matches the freshly computed composite checksum of
#   guidelines.md + all files under guidelines/** (path‑sorted).
#
# INVARIANTS CHECKED:
#   I1: perf-current.json exists
#   I2: guidelines_checksum key present
#   I3: Value is a 64‑char lowercase hex SHA-256
#   I4: Recomputed checksum matches stored value
#
# EXIT CODES:
#   0: All invariants satisfied
#   1: Hard failure (missing file, missing field, mismatch, invalid format)
#
# NOTES:
#   - Uses tools/guidelines-checksum.sh if available (authoritative).
#   - Falls back to inline hashing (shasum | sha256sum | openssl) if script missing.
#   - Silent if hashing tools unavailable (returns failure with message).
#
# OUTPUT:
#   PASS / FAIL lines + diagnostic reasons.

set -euo pipefail

ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
METRICS_DIR_PRIMARY="${ZDOTDIR}/docs/redesignv2/artifacts/metrics"
METRICS_DIR_FALLBACK="${ZDOTDIR}/docs/redesign/metrics"
PERF_FILE=""

if [[ -f "${METRICS_DIR_PRIMARY}/perf-current.json" ]]; then
  PERF_FILE="${METRICS_DIR_PRIMARY}/perf-current.json"
elif [[ -f "${METRICS_DIR_FALLBACK}/perf-current.json" ]]; then
  PERF_FILE="${METRICS_DIR_FALLBACK}/perf-current.json"
fi

color_green=$'\033[32m'
color_red=$'\033[31m'
color_reset=$'\033[0m'

fail() {
  print "${color_red}FAIL${color_reset}: $*"
  exit 1
}

pass() {
  print "${color_green}PASS${color_reset}: $*"
}

# I1: File exists
[[ -n "${PERF_FILE}" && -f "${PERF_FILE}" ]] || fail "perf-current.json not found in redesignv2 or redesign metrics directories"

# Extract guidelines_checksum value (robust to spacing)
guidelines_line=$(grep -E '"guidelines_checksum"' "${PERF_FILE}" || true)
[[ -n "${guidelines_line}" ]] || fail "guidelines_checksum key missing (I2)"

# naive extraction: "guidelines_checksum": "hash" or "guidelines_checksum":null
checksum_value=$(printf "%s" "${guidelines_line}" | sed -n 's/.*"guidelines_checksum"[[:space:]]*:[[:space:]]*"\([0-9a-f]\{64\}\)".*/\1/p')

[[ -n "${checksum_value}" ]] || fail "guidelines_checksum not a valid 64-char hex string (I3)"

# Recompute expected checksum
compute_expected_checksum() {
  local script="${ZDOTDIR}/tools/guidelines-checksum.sh"
  if [[ -x "${script}" ]]; then
    "${script}" 2>/dev/null | head -1 | tr -d '[:space:]'
    return 0
  fi

  # Inline fallback
  local ai_root
  ai_root="$(builtin cd -q "${ZDOTDIR}/../ai" 2>/dev/null && pwd || true)"
  [[ -d "${ai_root}" ]] || return 1
  local master="${ai_root}/guidelines.md"
  local modules="${ai_root}/guidelines"
  [[ -f "${master}" && -d "${modules}" ]] || return 1

  local hasher=""
  if command -v shasum >/dev/null 2>&1; then
    hasher="shasum -a 256"
  elif command -v sha256sum >/dev/null 2>&1; then
    hasher="sha256sum"
  elif command -v openssl >/dev/null 2>&1; then
    hasher="openssl dgst -sha256"
  else
    return 1
  fi

  if [[ "${hasher}" == "openssl dgst -sha256" ]]; then
    ( cat "${master}"; find "${modules}" -type f -print | LC_ALL=C sort | xargs cat ) \
      | openssl dgst -sha256 2>/dev/null | awk '{print $2}'
  else
    ( cat "${master}"; find "${modules}" -type f -print | LC_ALL=C sort | xargs cat ) \
      | ${=hasher} 2>/dev/null | awk '{print $1}'
  fi
}

expected_checksum=$(compute_expected_checksum || true)
[[ -n "${expected_checksum}" ]] || fail "Unable to recompute expected checksum (hash utilities or sources missing)"

# I4: Match
if [[ "${checksum_value}" != "${expected_checksum}" ]]; then
  printf "%s\n" "perf-current.json guidelines_checksum mismatch" \
                "  expected: ${expected_checksum}" \
                "  found:    ${checksum_value}"
  fail "Checksum mismatch (I4)"
fi

pass "guidelines_checksum present and valid (I1–I4) value=${checksum_value}"
exit 0
