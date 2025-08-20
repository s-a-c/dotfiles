# Core ZSH Options - Essential shell behavior
# This file configures shell options for optimal performance and usability
# Load time target: <10ms

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
}

# Completion system options
setopt COMPLETE_IN_WORD          # Complete from both ends of a word
setopt ALWAYS_TO_END             # Move cursor to the end of a completed word
setopt PATH_DIRS                 # Perform path search even on command names with slashes
setopt AUTO_MENU                 # Show completion menu on successive tab press
setopt AUTO_LIST                 # Automatically list choices on ambiguous completion
setopt AUTO_PARAM_SLASH          # Add trailing slash to directory completions
setopt EXTENDED_GLOB             # Enable extended globbing
setopt GLOB_COMPLETE             # Generate glob matches for completion

# Disable slow completion options
unsetopt MENU_COMPLETE           # Don't autoselect first completion
unsetopt AUTO_REMOVE_SLASH       # Don't remove trailing slash automatically

# Navigation options
setopt AUTO_CD                   # Change directory without cd command
setopt AUTO_PUSHD                # Make cd push old directory onto stack
setopt PUSHD_IGNORE_DUPS         # Don't push duplicate directories
setopt PUSHD_MINUS               # Exchanges meanings of +/- for pushd
setopt PUSHD_SILENT              # Don't print directory stack after pushd/popd

# Command correction and expansion
setopt CORRECT                   # Try to correct spelling of commands
unsetopt CORRECT_ALL             # Don't correct arguments (too aggressive)
setopt HASH_LIST_ALL             # Hash entire command path first time
setopt COMPLETE_ALIASES          # Complete aliases

# Job control
setopt AUTO_RESUME               # Resume jobs on exact command match
setopt LONG_LIST_JOBS            # List jobs in long format
setopt NOTIFY                    # Report job status immediately
unsetopt BG_NICE                 # Don't run background jobs at lower priority
unsetopt HUP                     # Don't send HUP signal to jobs on shell exit

# Input/Output
setopt ALIASES                   # Enable aliases
setopt CLOBBER                   # Allow output redirection to overwrite files
unsetopt FLOWCONTROL             # Disable start/stop characters (Ctrl-S/Ctrl-Q)
setopt INTERACTIVE_COMMENTS      # Allow comments in interactive mode
setopt RC_QUOTES                 # Allow 'Henry''s Garage' instead of 'Henry'\''s Garage'
setopt COMBINING_CHARS           # Combine zero-length punctuation characters

# Performance optimizations
setopt NO_BEEP                   # Disable beeping
setopt NO_NOMATCH                # Don't error on failed glob matches
setopt NUMERIC_GLOB_SORT         # Sort globs numerically

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [00-core] Shell options configured" >&2
