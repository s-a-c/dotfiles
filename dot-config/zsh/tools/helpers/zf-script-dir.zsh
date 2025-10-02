# zf::script_dir
#
# Purpose:
#   Reliable helper to determine the directory containing a calling script or
#   sourced file. Handles:
#     - scripts executed directly
#     - files sourced via `source` / `.` in zsh
#     - functions when zsh sets funcfiletrace
#     - symlink resolution (best-effort)
#     - relative paths
#
# Usage:
#   - `zf::script_dir`                -> prints the best-effort directory and returns 0
#   - `dir=$(zf::script_dir)`         -> capture output
#   - `zf::script_dir <path>`         -> resolve given path and print its directory
#   - `zf::script_dir --quiet`        -> same but no extra diagnostics
#   - `zf::script_dir --abs <path>`   -> print absolute directory (same as default)
#
# Implementation notes:
#   - Uses a small realpath helper that prefers `readlink -f`/`realpath`/python fallback.
#   - Uses zsh-specific expansion `(${(%):-%N})` to detect the current filename in diverse contexts.
#   - Falls back through `funcfiletrace`, `$0`, and PWD as last resort.
#   - Intentionally conservative: never fails the calling process; returns PWD when unknown.
#
# Copyright: repository helper. Keep small and portable.

zf::script_dir() {
  emulate -L zsh
  setopt localoptions sh_word_split 2>/dev/null || true

  local QUIET=0
  local INPUT_PATH=""
  local SHOW_ABS=1

  # Parse simple flags (only support --quiet and --help for now)
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --quiet|-q) QUIET=1; shift;;
      --help|-h)
        if [[ $QUIET -eq 0 ]]; then
          cat <<'USAGE'
zf::script_dir [--quiet] [path]

Prints the directory containing the script or file. If a path is provided,
resolves that path (symlinks when possible) and prints its directory.

Examples:
  zf::script_dir
  dir=$(zf::script_dir)
  zf::script_dir ./some/relative/file.zsh

USAGE
        fi
        return 0
        ;;
      --) shift; break;;
      --abs) SHOW_ABS=1; shift;;
      --no-abs) SHOW_ABS=0; shift;;
      *)
        # treat first non-flag as input path
        if [[ -z "$INPUT_PATH" ]]; then INPUT_PATH="$1"; shift; else break; fi
        ;;
    esac
  done

  # Internal: portable realpath-like resolver
  _zf_realpath() {
    local target="$1"
    # Empty -> nothing
    if [[ -z "$target" ]]; then
      printf '%s' ""
      return 1
    fi

    # If target already absolute and we can canonicalize, prefer readlink -f
    if command -v readlink >/dev/null 2>&1 && readlink -f / >/dev/null 2>&1 2>/dev/null; then
      # readlink -f handles non-existent intermediate symlinks differently across platforms;
      # we attempt it and if it fails fallback to other methods.
      local rl
      rl=$(readlink -f -- "$target" 2>/dev/null) && { printf '%s' "$rl"; return 0; } || true
    fi

    if command -v realpath >/dev/null 2>&1; then
      local rp
      rp=$(realpath -- "$target" 2>/dev/null) && { printf '%s' "$rp"; return 0; } || true
    fi

    if command -v python3 >/dev/null 2>&1; then
      # Use python realpath if available
      python3 - <<PY 2>/dev/null
import os,sys
try:
    print(os.path.realpath(sys.argv[1]))
except Exception:
    sys.exit(1)
PY
      # python prints to stdout; return its exit status
      local _rc=$?
      (( _rc == 0 )) && return 0 || true
    fi

    # Minimal POSIX fallback:
    # If the target exists, cd to its dirname and print $(pwd -P)/basename.
    if [[ -e "$target" ]]; then
      local d bn
      d=${target%/*}
      bn=${target##*/}
      if [[ "$d" == "$target" ]]; then
        # no slash in target -> file in current directory
        d="."
      fi
      (cd -- "$d" 2>/dev/null && printf '%s/%s' "$(pwd -P)" "$bn") 2>/dev/null && return 0
    fi

    # If nothing else, try to normalize relative path against PWD
    if [[ "$target" != /* ]]; then
      printf '%s' "$(pwd -P)/$target"
    else
      printf '%s' "$target"
    fi
    return 0
  }

  # Helper: choose best candidate filename for the calling context
  _zf_detect_caller_file() {
    local candidate=""

    # 1) Prefer zsh native expansion: (%):-%N yields the current script name when sourced/run.
    #    It can be "(eval)" or "-" in some contexts; guard against those.
    local zsh_name
    zsh_name=${(%):-%N}
    if [[ -n "$zsh_name" && "$zsh_name" != "(eval)" && "$zsh_name" != "-" ]]; then
      candidate="$zsh_name"
    fi

    # 2) If a function was involved, zsh provides funcfiletrace entries like "file:line"
    #    The most recent trace is funcfiletrace[1] for the current frame.
    if [[ -z "$candidate" && -n "${funcfiletrace[1]:-}" ]]; then
      # Extract the file portion before the first colon
      candidate="${funcfiletrace[1]%%:*}"
    fi

    # 3) Fallback to $0 (script name / shell invocation)
    if [[ -z "$candidate" || "$candidate" == "zsh" || "$candidate" == "-zsh" ]]; then
      candidate="${0:-}"
    fi

    # 4) If candidate is empty or special, fall back to PWD
    if [[ -z "$candidate" || "$candidate" == "-" ]]; then
      printf '%s' ""
      return 1
    fi

    printf '%s' "$candidate"
    return 0
  }

  # Determine the file to resolve
  local file_to_resolve=""
  if [[ -n "$INPUT_PATH" ]]; then
    file_to_resolve="$INPUT_PATH"
  else
    # try to detect caller
    file_to_resolve="$(_zf_detect_caller_file)" || file_to_resolve=""
  fi

  # Normalize cases where file is like 'func[1]' or contains colons/line info
  # Strip anything after the first colon (often 'file:line')
  if [[ -n "$file_to_resolve" && "$file_to_resolve" == *:* ]]; then
    file_to_resolve="${file_to_resolve%%:*}"
  fi

  # If still empty, prefer $0 if available
  if [[ -z "$file_to_resolve" && -n "${0:-}" ]]; then
    file_to_resolve="$0"
  fi

  # Now compute absolute path for the candidate and extract its directory
  local resolved=""
  if [[ -n "$file_to_resolve" ]]; then
    resolved="$(_zf_realpath "$file_to_resolve" 2>/dev/null || true)"
  fi

  # If resolved is empty but file_to_resolve was provided as relative or non-existent,
  # attempt to produce a normalized absolute directory by using dirname with PWD.
  local dirpath=""
  if [[ -n "$resolved" ]]; then
    # If path points to something like "-", consider as unknown
    if [[ "$resolved" == "-" || "$resolved" == "" ]]; then
      dirpath=""
    else
      # If resolved ends with a slash or is a directory, take it directly
      if [[ -d "$resolved" ]]; then
        dirpath="$resolved"
      else
        dirpath="${resolved%/*}"
        # If no slash was present, then it's in the current directory
        if [[ "$dirpath" == "$resolved" ]]; then
          dirpath="$(pwd -P)"
        fi
      fi
    fi
  fi

  # If everything failed, fallback to using dirname of input path or PWD
  if [[ -z "$dirpath" && -n "$file_to_resolve" ]]; then
    # try naive dirname
    local naive_dir="${file_to_resolve%/*}"
    if [[ "$naive_dir" == "$file_to_resolve" || -z "$naive_dir" ]]; then
      # no slash in input path -> file in current dir
      dirpath="$(pwd -P)"
    else
      # make absolute
      if [[ "$naive_dir" = /* ]]; then
        dirpath="$naive_dir"
      else
        dirpath="$(pwd -P)/$naive_dir"
      fi
    fi
  fi

  # Final fallback: PWD
  if [[ -z "$dirpath" ]]; then
    dirpath="$(pwd -P)"
  fi

  # Canonicalize final dir path if possible (resolve symlinks)
  if command -v readlink >/dev/null 2>&1 && readlink -f / >/dev/null 2>&1 2>/dev/null; then
    local final
    final=$(readlink -f -- "$dirpath" 2>/dev/null) || final="$dirpath"
    dirpath="$final"
  else
    # try python or realpath
    if command -v realpath >/dev/null 2>&1; then
      dirpath="$(realpath -- "$dirpath" 2>/dev/null || printf '%s' "$dirpath")"
    elif command -v python3 >/dev/null 2>&1; then
      dirpath="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' -- "$dirpath" 2>/dev/null || printf '%s' "$dirpath")"
    fi
  fi

  # Print result
  if [[ $QUIET -eq 0 ]]; then
    printf '%s\n' "$dirpath"
  else
    # even in quiet mode we print just the path (quiet suppresses diagnostics only)
    printf '%s\n' "$dirpath"
  fi

  return 0
}

# Export a shorthand name for compatibility
# Some scripts might call zf::script_dir directly; provide zf_script_dir without colons too.
zf_script_dir() { zf::script_dir "$@"; }
