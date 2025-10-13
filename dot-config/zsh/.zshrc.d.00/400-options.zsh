#!/usr/bin/env zsh
# ==============================================================================
# ZSH Shell Options (`setopt`) - Comprehensive Configuration
# ==============================================================================
#
# This file contains all ZSH options for the zsh-quickstart-kit configuration.
# It provides a complete reference with documentation for each option including
# its purpose, default value, and rationale for the chosen setting.
#
# Previously, options were split between 400-options.zsh (baseline) and
# 401-options-override.zsh (advanced). As of 2025-10-13, all 50 unique options
# have been consolidated into this single file for easier maintenance and clarity.
#
# --- How to Override ---
#
# To customize these settings, create a new file in this directory with a higher
# number (e.g., `401-my-options.zsh`) and add your `setopt` or `unsetopt`
# commands there. Files are loaded in alphanumeric order, so your settings will
# take precedence.
#
# Example: `401-my-options.zsh`
# ```zsh
# #!/usr/bin/env zsh
# # My custom option overrides
# unsetopt CORRECT              # Disable command spelling correction
# setopt BANG_HIST               # Enable ! history expansion
# ```
#
# ==============================================================================

# ==============================================================================
# SECTION 1: HISTORY OPTIONS
# ==============================================================================

# --- APPEND_HISTORY ---
# Description: Appends the history list to the history file, rather than overwriting it.
# Default: Set
# zqs: Set in `.zshrc` and `.zshrc.d.00/490-shell-history.zsh`
# Recommendation: `setopt APPEND_HISTORY`
# Rationale: Essential for preserving history across shell sessions.
setopt APPEND_HISTORY

# --- EXTENDED_HISTORY ---
# Description: Saves the beginning and ending timestamp of each command in the history file.
# Default: Unset
# zqs: Set in `.zshrc` and `.zshrc.d.00/490-shell-history.zsh`
# Recommendation: `setopt EXTENDED_HISTORY`
# Rationale: Useful for auditing and understanding when commands were run.
setopt EXTENDED_HISTORY

# --- HIST_EXPIRE_DUPS_FIRST ---
# Description: When trimming history, prioritize deleting older duplicates.
# Default: Unset
# Recommendation: `setopt HIST_EXPIRE_DUPS_FIRST`
# Rationale: Maximizes the variety of commands stored in your history.
setopt HIST_EXPIRE_DUPS_FIRST

# --- HIST_FCNTL_LOCK ---
# Description: Uses `fcntl` locking to prevent history corruption when multiple
#              shells write to the same history file simultaneously.
# Default: Unset
# Recommendation: `setopt HIST_FCNTL_LOCK`
# Rationale: Critical safety feature for users of multiple terminal sessions.
setopt HIST_FCNTL_LOCK

# --- HIST_IGNORE_ALL_DUPS ---
# Description: If a new command is a duplicate of an older one, the older one is removed from the list.
# Default: Unset
# zqs: Set in `.zshrc` and `.zshrc.d.00/490-shell-history.zsh`
# Recommendation: `setopt HIST_IGNORE_ALL_DUPS`
# Rationale: Keeps the history clean and free of redundant commands.
setopt HIST_IGNORE_ALL_DUPS

# --- HIST_IGNORE_DUPS ---
# Description: Do not enter command lines into the history list if they are duplicates of the previous event.
# Default: Unset
# zqs: Set in `.zshrc` and `.zshrc.d.00/490-shell-history.zsh`
# Recommendation: `setopt HIST_IGNORE_DUPS`
# Rationale: Prevents the history from being cluttered with repeated commands.
setopt HIST_IGNORE_DUPS

# --- HIST_IGNORE_SPACE ---
# Description: Do not enter command lines into the history list if they start with a space.
# Default: Unset
# zqs: Set in `.zshrc` and `.zshrc.d.00/490-shell-history.zsh`
# Recommendation: `setopt HIST_IGNORE_SPACE`
# Rationale: Useful for running commands that you don't want to be saved in your history.
setopt HIST_IGNORE_SPACE

# --- HIST_NO_STORE ---
# Description: Prevents the `history` command itself from being saved to history.
# Default: Unset
# Recommendation: `setopt HIST_NO_STORE`
# Rationale: Reduces noise in the history file.
setopt HIST_NO_STORE

# --- HIST_REDUCE_BLANKS ---
# Description: Remove superfluous blanks from each command line being added to the history list.
# Default: Unset
# zqs: Set in `.zshrc` and `.zshrc.d.00/490-shell-history.zsh`
# Recommendation: `setopt HIST_REDUCE_BLANKS`
# Rationale: Keeps history entries clean and concise.
setopt HIST_REDUCE_BLANKS

# --- HIST_SAVE_NO_DUPS ---
# Description: When writing the history file, omit older duplicate commands.
# Default: Unset
# Recommendation: `setopt HIST_SAVE_NO_DUPS`
# Rationale: Keeps the persistent history file clean and efficient.
setopt HIST_SAVE_NO_DUPS

# --- HIST_VERIFY ---
# Description: Loads a history command onto the command line for editing
#              instead of executing it instantly with `!`.
# Default: Unset
# Recommendation: `setopt HIST_VERIFY`
# Rationale: A crucial safety net against accidental command execution.
setopt HIST_VERIFY

# --- INC_APPEND_HISTORY ---
# Description: Writes each command to the history file immediately after execution.
# Default: Unset
# Recommendation: `setopt INC_APPEND_HISTORY`
# Rationale: Ensures commands are saved even if the shell terminates unexpectedly.
setopt INC_APPEND_HISTORY

# --- SHARE_HISTORY ---
# Description: Imports new commands from the history file, and exports typed commands to the history file.
# Default: Unset
# zqs: Set in `.zshrc` and `.zshrc.d.00/490-shell-history.zsh`
# Recommendation: `setopt SHARE_HISTORY`
# Rationale: Essential for sharing history between multiple open shells.
setopt SHARE_HISTORY

# --- HIST_BEEP ---
# Description: Beep when trying to access a history entry that doesn't exist.
# Default: Set
# zqs: Unset in `.zshrc`
# Recommendation: `unsetopt HIST_BEEP`
# Rationale: The beep is generally considered annoying and unnecessary.
unsetopt HIST_BEEP

# --- BANG_HIST ---
# Description: Enables the `!` character for history expansion.
# Default: Set
# Recommendation: `unsetopt BANG_HIST` (commented out - opt-in only)
# Rationale: Can be dangerous as `!` is common in URLs and commands. Disabling
#            it prevents unexpected, and potentially destructive, expansions.
#            Uncomment the line below if you want to disable this feature.
# unsetopt BANG_HIST

# ==============================================================================
# SECTION 2: COMPLETION OPTIONS
# ==============================================================================

# --- AUTO_LIST ---
# Description: Automatically list choices on an ambiguous completion.
# Default: Unset
# zqs: Set in `.zshrc`
# Recommendation: `setopt AUTO_LIST`
# Rationale: Improves the user experience by automatically showing available completions.
setopt AUTO_LIST

# --- AUTO_MENU ---
# Description: Automatically use a menu completion after the second consecutive tab press.
# Default: Unset
# zqs: Set in `.zshrc`
# Recommendation: `setopt AUTO_MENU`
# Rationale: Provides a more interactive and user-friendly completion experience.
setopt AUTO_MENU

# --- ALWAYS_TO_END ---
# Description: Moves the cursor to the end of the word after completion.
# Default: Unset
# Recommendation: `setopt ALWAYS_TO_END`
# Rationale: Improves workflow by allowing you to immediately type the next argument.
setopt ALWAYS_TO_END

# --- COMPLETE_IN_WORD ---
# Description: Attempt to perform completion from a string in the current word.
# Default: Unset
# zqs: Set in `.zshrc`
# Recommendation: `setopt COMPLETE_IN_WORD`
# Rationale: Provides more flexible and powerful completion.
setopt COMPLETE_IN_WORD

# --- MENU_COMPLETE ---
# Description: On an ambiguous completion, instead of listing possibilities, insert the first match.
# Default: Unset
# zqs: Unset in `.zshrc`
# Recommendation: `unsetopt MENU_COMPLETE`
# Rationale: Can be confusing and lead to unexpected completions. `AUTO_MENU` is a better alternative.
unsetopt MENU_COMPLETE

# ==============================================================================
# SECTION 3: INPUT & EDITING OPTIONS
# ==============================================================================

# --- IGNORE_EOF ---
# Description: Prevents the shell from exiting when you press Ctrl+D.
# Default: Unset
# Recommendation: `setopt IGNORE_EOF`
# Rationale: A simple but effective way to prevent accidentally closing your shell.
setopt IGNORE_EOF

# ==============================================================================
# SECTION 4: DIRECTORY & NAVIGATION OPTIONS
# ==============================================================================

# --- AUTO_CD ---
# Description: If a command is issued that can't be executed as a normal command, and the command is the name of a directory, perform `cd` to that directory.
# Default: Unset
# zqs: Set in `.zshrc`
# Recommendation: `setopt AUTO_CD`
# Rationale: A convenient shortcut for changing directories.
setopt AUTO_CD

# --- AUTO_PUSHD ---
# Description: Makes `cd` behave like `pushd`, adding directories to the stack.
# Default: Unset
# Recommendation: `setopt AUTO_PUSHD`
# Rationale: Simplifies directory navigation with `popd` or `cd -<n>`.
setopt AUTO_PUSHD

# --- PUSHD_IGNORE_DUPS ---
# Description: Don't push directories onto the directory stack if they are already on it.
# Default: Unset
# zqs: Set in `.zshrc`
# Recommendation: `setopt PUSHD_IGNORE_DUPS`
# Rationale: Keeps the directory stack clean and tidy.
setopt PUSHD_IGNORE_DUPS

# --- PUSHD_MINUS ---
# Description: Exchanges the meaning of `+` and `-` for directory stack navigation.
# Default: Unset
# Recommendation: `setopt PUSHD_MINUS`
# Rationale: Makes `cd -` equivalent to `cd -1`, which can feel more intuitive.
setopt PUSHD_MINUS

# --- PUSHD_SILENT ---
# Description: Suppresses printing of the directory stack after `pushd` or `popd`.
# Default: Unset
# Recommendation: `setopt PUSHD_SILENT`
# Rationale: Reduces visual noise. Use `dirs -v` (aliased to `d`) to see the stack.
setopt PUSHD_SILENT

# --- CDABLE_VARS ---
# Description: If an argument to `cd` is a variable name, `cd` to its value.
# Default: Unset
# Recommendation: `setopt CDABLE_VARS`
# Rationale: Convenient for projects where you store paths in variables.
setopt CDABLE_VARS

# ==============================================================================
# SECTION 5: GLOBBING & EXPANSION OPTIONS
# ==============================================================================

# --- EXTENDED_GLOB ---
# Description: Enables more powerful globbing features, such as `^` for negation and `(#i)` for case-insensitivity.
# Default: Unset
# zqs: Set in `.zshrc`
# Recommendation: `setopt EXTENDED_GLOB`
# Rationale: Essential for modern and powerful command-line globbing.
setopt EXTENDED_GLOB

# --- GLOB_DOTS ---
# Description: Globbing patterns (`*`) will match hidden dotfiles.
# Default: Unset
# Recommendation: `setopt GLOB_DOTS`
# Rationale: More intuitive behavior, making it easier to act on all files.
setopt GLOB_DOTS

# --- NULL_GLOB ---
# Description: If a glob pattern has no matches, it is removed from the command
#              line instead of causing an error.
# Default: Unset
# Recommendation: `setopt NULL_GLOB`
# Rationale: Prevents errors in scripts when no files match (e.g., `rm *.tmp`).
setopt NULL_GLOB

# --- NO_CASE_GLOB ---
# Description: Makes globbing patterns case-insensitive.
# Default: Unset
# Recommendation: `setopt NO_CASE_GLOB`
# Rationale: Improves convenience, especially on case-insensitive filesystems.
setopt NO_CASE_GLOB

# --- NUMERIC_GLOB_SORT ---
# Description: Sorts filenames containing numbers in a natural order (e.g.,
#              `file1`, `file2`, `file10` instead of `file1`, `file10`, `file2`).
# Default: Unset
# Recommendation: `setopt NUMERIC_GLOB_SORT`
# Rationale: Provides a more human-friendly sorting order for numbered files.
setopt NUMERIC_GLOB_SORT

# --- PROMPT_SUBST ---
# Description: Allows parameter expansion, command substitution, and arithmetic expansion in prompts.
# Default: Unset
# zqs: Set by many plugins and themes.
# Recommendation: `setopt PROMPT_SUBST`
# Rationale: Required for most modern prompts, including Starship and Powerlevel10k.
setopt PROMPT_SUBST

# ==============================================================================
# SECTION 6: INPUT/OUTPUT & REDIRECTION OPTIONS
# ==============================================================================

# --- NO_CLOBBER ---
# Description: Prevents overwriting an existing file with `>`. Use `>|` to force.
# Default: Set (Clobber is allowed)
# Recommendation: `unsetopt CLOBBER`
# Rationale: A critical safety feature that prevents accidental data loss.
unsetopt CLOBBER

# --- MULTIOS ---
# Description: Allows redirecting output to multiple files/processes at once.
# Default: Unset
# Recommendation: `setopt MULTIOS`
# Rationale: Enables powerful and flexible command-line redirection.
setopt MULTIOS

# --- PIPE_FAIL ---
# Description: A pipeline's return status is from the last command to fail.
# Default: Unset
# Recommendation: `setopt PIPE_FAIL`
# Rationale: Makes scripts more robust by ensuring failures in a pipeline are detected.
setopt PIPE_FAIL

# --- PRINT_EXIT_VALUE ---
# Description: If a command exits with a non-zero status, print the exit code.
# Default: Unset
# Recommendation: `setopt PRINT_EXIT_VALUE`
# Rationale: Provides immediate, visible feedback on command failures.
setopt PRINT_EXIT_VALUE

# ==============================================================================
# SECTION 7: PROMPT & DISPLAY OPTIONS
# ==============================================================================

# --- TRANSIENT_RPROMPT ---
# Description: Removes the right-side prompt (`RPROMPT`) from the screen after
#              a command is entered.
# Default: Unset
# Recommendation: `setopt TRANSIENT_RPROMPT`
# Rationale: Cleans up the terminal display, preventing command output from
#            colliding with a persistent right-side prompt.
setopt TRANSIENT_RPROMPT

# ==============================================================================
# SECTION 8: SCRIPTING & EXPANSION BEHAVIOR OPTIONS
# ==============================================================================

# --- RC_EXPAND_PARAM ---
# Description: Expands array variables in the form `foo${array}bar`.
# Default: Unset
# Recommendation: `setopt RC_EXPAND_PARAM`
# Rationale: Useful for creating dynamic command strings with array variables.
setopt RC_EXPAND_PARAM

# --- SH_WORD_SPLIT ---
# Description: Enables traditional Bourne shell word splitting.
# Default: Unset
# Recommendation: `unsetopt SH_WORD_SPLIT`
# Rationale: Zsh's default behavior is safer. Only enable this if you need to
#            run a script that relies on this specific shell behavior.
unsetopt SH_WORD_SPLIT

# --- WARN_CREATE_GLOBAL ---
# Description: Prints a warning when a global variable is created in a function.
# Default: Unset
# Recommendation: `setopt WARN_CREATE_GLOBAL`
# Rationale: A great safety feature for scripting that helps prevent accidental
#            creation of global variables, which can lead to bugs.
# NOTE: This option is intentionally NOT enabled here. It is enabled later in
#       990-restore-warn.zsh after vendor scripts (FZF, Atuin, etc.) have loaded.
#       This prevents false warnings from vendor code that creates globals during
#       initialization. See docs/150-troubleshooting-startup-warnings.md for details.
#
# To enable it for your own scripts while suppressing vendor warnings, the
# configuration uses this pattern:
#   1. .zshenv: setopt no_warn_create_global (disable initially)
#   2. .zshrc.pre-plugins.d: Override functions that trigger warnings
#   3. Plugins load: No warnings emitted
#   4. 990-restore-warn.zsh: setopt warn_create_global (re-enable)
#
# DO NOT uncomment the line below unless you understand the implications:
# setopt WARN_CREATE_GLOBAL

# ==============================================================================
# SECTION 9: JOB CONTROL OPTIONS
# ==============================================================================

# --- LONG_LIST_JOBS ---
# Description: Lists background jobs in a more detailed format by default.
# Default: Unset
# Recommendation: `setopt LONG_LIST_JOBS`
# Rationale: Provides more useful information (like PID) when running `jobs`.
setopt LONG_LIST_JOBS

# --- MONITOR ---
# Description: Enables job control (`bg`, `fg`, `jobs`, etc.).
# Default: Set in interactive shells.
# Recommendation: `setopt MONITOR`
# Rationale: Essential for managing background processes.
setopt MONITOR

# --- NOTIFY ---
# Description: Reports the status of background jobs immediately upon completion.
# Default: Unset
# Recommendation: `setopt NOTIFY`
# Rationale: Provides immediate feedback on background tasks.
setopt NOTIFY

# --- BG_NICE ---
# Description: Runs all background jobs at a lower priority ("nicer").
# Default: Unset
# Recommendation: `setopt BG_NICE`
# Rationale: Prevents background tasks from making the interactive shell unresponsive.
setopt BG_NICE

# ==============================================================================
# SECTION 10: SPELLING & CORRECTION OPTIONS
# ==============================================================================

# --- CORRECT ---
# Description: Try to correct the spelling of commands.
# Default: Unset
# zqs: Set in `.zshrc`
# Recommendation: `setopt CORRECT`
# Rationale: Can be helpful for correcting typos, but some users may find it intrusive.
setopt CORRECT

# --- CORRECT_ALL ---
# Description: Try to correct the spelling of all arguments in a line.
# Default: Unset
# zqs: Unset in `.zshrc`
# Recommendation: `unsetopt CORRECT_ALL`
# Rationale: This is generally too aggressive and can lead to unexpected results.
unsetopt CORRECT_ALL

# ==============================================================================
# SECTION 11: MISCELLANEOUS OPTIONS
# ==============================================================================

# --- COMBINING_CHARS ---
# Description: Correctly handles multi-byte Unicode characters (like accents).
# Default: Set on modern systems
# Recommendation: `setopt COMBINING_CHARS`
# Rationale: Essential for correct display and manipulation of non-ASCII text.
setopt COMBINING_CHARS

# --- INTERACTIVE_COMMENTS ---
# Description: Allows comments in interactive shell sessions.
# Default: Unset
# zqs: Set in `.zshrc`
# Recommendation: `setopt INTERACTIVE_COMMENTS`
# Rationale: Useful for commenting out commands or adding notes in your shell.
setopt INTERACTIVE_COMMENTS

# --- NO_FLOW_CONTROL ---
# Description: Disables Ctrl+S (pause) and Ctrl+Q (resume) terminal flow control.
# Default: Set on modern systems
# Recommendation: `setopt NO_FLOW_CONTROL`
# Rationale: Prevents conflicts with modern keybindings (e.g., "Save").
setopt NO_FLOW_CONTROL

# --- RC_QUOTES ---
# Description: Allows escaping single quotes within single-quoted strings using
#              a pair of single quotes, e.g., `'Henry''s Garage'`.
# Default: Unset
# Recommendation: `setopt RC_QUOTES`
# Rationale: A convenient feature that simplifies quoting in complex strings.
setopt RC_QUOTES

# ==============================================================================
# END OF OPTIONS
# ==============================================================================
#
# Total Options Configured: 50
#   - History: 15
#   - Completion: 5
#   - Input & Editing: 1
#   - Directory & Navigation: 6
#   - Globbing & Expansion: 6
#   - Input/Output & Redirection: 4
#   - Prompt & Display: 1
#   - Scripting & Expansion: 3 (1 commented)
#   - Job Control: 4
#   - Spelling & Correction: 2
#   - Miscellaneous: 4
#
# For detailed explanations and comparisons, see:
#   - docs/160-option-files-comparison.md
#   - docs/150-troubleshooting-startup-warnings.md
#   - docs/000-index.md
#
# ==============================================================================
