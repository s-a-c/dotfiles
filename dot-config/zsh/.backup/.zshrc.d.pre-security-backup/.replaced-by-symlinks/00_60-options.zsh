#!/usr/bin/env zsh
# ZSH Options Configuration - INTERACTIVE SHELLS ONLY
# This file contains options that only apply to interactive shells
# Universal options (globbing, basic history, etc.) are in .zshenv

# === Interactive History Options ===
# These options enhance interactive history behavior but may not apply to non-interactive shells

# Prevent multiple loading
[[ -n "${_LOADED_00_60_OPTIONS:-}" ]] && return 0

setopt HIST_EXPIRE_DUPS_FIRST   # Remove duplicates first when trimming history
setopt HIST_IGNORE_ALL_DUPS     # Don't record duplicates in history (supersedes hist_ignore_dups)
setopt HIST_SAVE_NO_DUPS        # Don't save duplicates to history file
setopt INC_APPEND_HISTORY       # Add commands to history immediately (interactive)
setopt SHARE_HISTORY            # Share history between all interactive sessions
unsetopt HIST_BEEP              # Don't beep on history errors

# === Directory Navigation (Interactive) ===
setopt AUTO_CD                  # cd to directory if command is directory name
setopt PUSHD_IGNORE_DUPS        # Don't push same directory twice

# === Completion Options (Interactive Only) ===
setopt ALWAYS_TO_END            # Move cursor to end after completion
setopt AUTO_LIST                # Automatically list choices on ambiguous completion
setopt AUTO_MENU                # Show completion menu on successive tab press
setopt AUTO_PARAM_SLASH         # Add trailing slash for directory parameters
setopt COMPLETE_IN_WORD         # Complete from both ends of word
unsetopt MENU_COMPLETE          # Don't autoselect first completion entry

# === Interactive Shell Features ===
setopt INTERACTIVE_COMMENTS     # Allow comments in interactive shell

# === COMPREHENSIVE INTERACTIVE ZSH OPTIONS REFERENCE ===
# Additional options suitable for interactive shells - commented with defaults
# Uncomment and modify as needed for your specific interactive shell requirements

# === Advanced History Options (Interactive) ===
# setopt BANG_HIST              # (default: on) Treat ! specially during expansion
# setopt HIST_ALLOW_CLOBBER     # (default: off) Allow clobbering during history expansion
# setopt HIST_FCNTL_LOCK        # (default: off) Use fcntl for history file locking
# setopt HIST_FIND_NO_DUPS      # (default: off) Don't display duplicates when searching
# setopt HIST_LEX_WORDS         # (default: off) Use shell lexical analysis for history
# setopt HIST_NO_FUNCTIONS      # (default: off) Don't store function definitions in history
# setopt HIST_NO_STORE          # (default: off) Don't store history/fc commands
# setopt HIST_SUBST_PATTERN     # (default: off) Support extended patterns in history substitution

# === Completion and ZLE (Interactive Only) ===
# setopt AUTO_CONTINUE          # (default: off) Send CONT to disowned jobs when shell exits
# setopt AUTO_NAME_DIRS         # (default: off) Parameters become directory names
# setopt AUTO_PARAM_KEYS        # (default: on) Remove trailing chars that don't match
# setopt AUTO_REMOVE_SLASH      # (default: on) Remove trailing slash when not needed
# setopt BASH_AUTO_LIST         # (default: off) List choices after first ambiguous completion
# setopt COMPLETE_ALIASES       # (default: off) Complete aliases as well as their expansions
# setopt GLOB_COMPLETE          # (default: off) Generate glob patterns for completion
# setopt HASH_LIST_ALL          # (default: on) Hash entire command path on first execution
# setopt LIST_AMBIGUOUS         # (default: on) List choices on ambiguous completion
# setopt LIST_BEEP              # (default: on) Beep when completion list is displayed
# setopt LIST_PACKED            # (default: off) Pack completion lists to use less space
# setopt LIST_ROWS_FIRST        # (default: off) List completions in rows rather than columns
# setopt LIST_TYPES             # (default: on) Show types of files in completion lists
# setopt REC_EXACT              # (default: off) Recognize exact matches even if ambiguous

# === Command Line Editing (ZLE) Options ===
# setopt BEEP                   # (default: on) Beep on error in ZLE
# setopt COMBINING_CHARS        # (default: on) Combine zero-width characters with base chars
# setopt EMACS                  # (default: off unless -o vi) Use emacs-style line editing
# setopt OVERSTRIKE             # (default: off) Use overstrike mode instead of insert
# setopt SINGLE_LINE_ZLE        # (default: off) Use single line ZLE for editing
# setopt VI                     # (default: off unless -o emacs) Use vi-style line editing
# setopt ZLE                    # (default: on unless -o vi) Use ZLE for line editing

# === Directory Stack and Navigation ===
# setopt AUTO_PUSHD             # (default: off) Make cd push old directory onto directory stack
# setopt CDABLE_VARS            # (default: off) cd to parameter if directory doesn't exist
# setopt CHASE_DOTS             # (default: off) Resolve .. in cd paths
# setopt CHASE_LINKS            # (default: off) Resolve symbolic links in cd
# setopt POSIX_CD               # (default: off) Use POSIX behavior for cd builtin
# setopt PUSHD_MINUS            # (default: off) Exchange meanings of +/- for pushd
# setopt PUSHD_SILENT           # (default: off) Don't print directory stack after pushd/popd
# setopt PUSHD_TO_HOME          # (default: off) pushd with no arguments goes to $HOME

# === Interactive Prompt and Display ===
# setopt ALWAYS_LAST_PROMPT     # (default: off) Always go to last line of prompt
# setopt PROMPT_BANG            # (default: on) Perform ! expansion in prompts
# setopt PROMPT_PERCENT         # (default: on) Perform % expansion in prompts
# setopt PROMPT_SP              # (default: on) Preserve partial lines at prompt
# setopt PROMPT_SUBST           # (default: off) Perform parameter expansion in prompts
# setopt TRANSIENT_RPROMPT      # (default: off) Remove RPROMPT from previous lines

# === Interactive Job Control ===
# setopt AUTO_CONTINUE          # (default: off) Send CONT to disowned jobs when shell exits
# setopt AUTO_RESUME            # (default: off) Resume job on fg/bg without %
# setopt BG_NICE                # (default: on) Run background jobs at lower priority
# setopt CHECK_JOBS             # (default: on) Warn about running jobs on shell exit
# setopt CHECK_RUNNING_JOBS     # (default: on) Check for running jobs, not just suspended
# setopt HUP                    # (default: on) Send HUP to running jobs when shell exits
# setopt LONG_LIST_JOBS         # (default: off) List jobs in long format by default
# setopt MONITOR                # (default: on) Enable job control
# setopt NOTIFY                 # (default: on) Report job status immediately
# setopt POSIX_JOBS             # (default: off) Use POSIX job control

# === Interactive Input/Output ===
# setopt CLOBBER                # (default: on) Allow > redirection to overwrite files
# setopt CORRECT                # (default: off) Correct spelling for commands
# setopt CORRECT_ALL            # (default: off) Try to correct all arguments in line
# setopt DVORAK                 # (default: off) Use Dvorak keyboard layout for line editor
# setopt FLOW_CONTROL           # (default: on) Enable output flow control via start/stop chars
# setopt IGNORE_EOF             # (default: off) Don't exit on EOF (Ctrl-D)
# setopt INTERACTIVE            # (default: auto) Shell is interactive
# setopt MAIL_WARNING           # (default: off) Warn if mail file has been accessed
# setopt NO_CLOBBER             # (default: off) Don't overwrite files with > redirection
# setopt PRINT_EXIT_VALUE       # (default: off) Print exit value if non-zero
# setopt RC_QUOTES              # (default: off) Allow '' to represent single quote in strings
# setopt RM_STAR_SILENT         # (default: off) Don't query user before rm * is executed
# setopt RM_STAR_WAIT           # (default: off) Wait 10 seconds before rm * can proceed
# setopt SUN_KEYBOARD_HACK      # (default: off) Ignore invalid characters from Sun keyboards

# === Interactive Aliases and Functions ===
# setopt ALIASES                # (default: on) Enable alias expansion
# setopt GLOBAL_EXPORT          # (default: off) Export all parameters
# setopt GLOBAL_RCS             # (default: on) Source global startup files
# setopt RCS                    # (default: on) Source startup files

# === Interactive Error Handling ===
# setopt BAD_PATTERN            # (default: on) Print error for malformed patterns
# setopt NOMATCH                # (default: on) Print error if glob doesn't match
# setopt NULL_GLOB              # (default: off) Remove unmatched globs instead of error
# setopt WARN_CREATE_GLOBAL     # (default: off) Warn when creating global parameter in function

# === Miscellaneous Interactive Options ===
# setopt HASH_CMDS              # (default: on) Hash commands as they are executed
# setopt HASH_DIRS              # (default: on) Hash directories containing commands
# setopt INTERACTIVE_COMMENTS   # (default: off) Allow comments in interactive shell
# setopt LOGIN                  # (default: auto) Shell is a login shell
# setopt MENU_COMPLETE          # (default: off) Insert first match immediately
# setopt PRIVILEGED             # (default: auto) Shell runs with elevated privileges
# setopt RESTRICTED             # (default: off) Shell runs in restricted mode
# setopt SHIN_STDIN             # (default: auto) Commands are read from standard input
# setopt SINGLE_COMMAND         # (default: off) Exit after reading and executing one command

# === Keyboard and Input Method Options ===
# setopt MULTIBYTE              # (default: on) Enable multibyte character support
# setopt BRACE_CCL              # (default: off) Expand {a-z} in brace expansion
# setopt DOT_GLOB               # (default: off) Leading dots in filename glob patterns
# setopt EXTENDED_GLOB          # (default: off) Enable extended globbing patterns
# setopt GLOB_ASSIGN            # (default: off) Glob the right side of assignments
# setopt GLOB_DOTS              # (default: off) Don't require leading . to be matched explicitly
# setopt GLOB_STAR_SHORT        # (default: off) ** is equivalent to **/*
# setopt MARK_DIRS              # (default: on) Add trailing / to directory names from glob
# setopt NUMERIC_GLOB_SORT      # (default: off) Sort numeric filenames numerically

# Note: Universal options (EXTENDED_GLOB, NULLGLOB, NOMATCH, CORRECT, CORRECTALL,
# basic history options) are now in .zshenv and apply to all shell types

# Mark as loaded
readonly _LOADED_00_60_OPTIONS=1
