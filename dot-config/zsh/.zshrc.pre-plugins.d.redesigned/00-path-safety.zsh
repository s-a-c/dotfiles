# 00-path-safety.zsh (Pre-Plugin Redesign Skeleton)
[[ -n ${_LOADED_PRE_PATH_SAFETY:-} ]] && return
_LOADED_PRE_PATH_SAFETY=1

# PURPOSE: Minimal early PATH normalization & safety guards (skeleton placeholder)
# NOTE: Real migration will merge logic from 00_00 / 00_01 / 00_05 legacy scripts.

path=(${path:#/usr/local/sbin} /usr/local/sbin $path)
# Deduplicate PATH entries (simple first-appearance filter)
typeset -A _seen_path
_new_path=()
for p in $path; do
    [[ -z ${_seen_path[$p]:-} ]] && { _seen_path[$p]=1; _new_path+=$p; }
done
path=($_new_path)
unset _seen_path _new_path p

zsh_debug_echo "# [pre-plugin] 00-path-safety skeleton loaded"
