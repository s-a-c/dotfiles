##
## This file is sourced by zsh upon start-up. It should contain commands to set
## up aliases, functions, options, key bindings, etc.
##

# vim: ft=zsh sw=4 ts=4 et nu rnu ai si

[[ -n "$ZSH_DEBUG" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
    # Add this check to detect errant file creation:
    if [[ -f "${ZDOTDIR:-$HOME}/2" ]] || [[ -f "${ZDOTDIR:-$HOME}/3" ]]; then
        echo "Warning: Numbered files detected - check for redirection typos" >&2
    fi
}

## [setopt]
{
    ## History
    setopt EXTENDED_HISTORY     ## Write history in :start:elapsed;command format
    setopt HIST_BEEP            ## Beep when accessing nonexistent history
    setopt HIST_EXPIRE_DUPS_FIRST  ## Expire duplicates first when trimming history
    setopt HIST_FIND_NO_DUPS    ## Ignore duplicates when searching history
    setopt HIST_IGNORE_DUPS     ## Ignore consecutive duplicates
    setopt HIST_IGNORE_ALL_DUPS ## Remove older duplicate commands from history
    setopt HIST_IGNORE_SPACE    ## Ignore commands that start with space
    setopt HIST_NO_STORE        ## Don't store history commands in history
    setopt HIST_REDUCE_BLANKS   ## Remove superfluous blanks from commands
    setopt HIST_SAVE_NO_DUPS    ## Don't save duplicate commands
    setopt HIST_VERIFY          ## Show history expansion before running
    setopt INC_APPEND_HISTORY   ## Write to history file immediately
    setopt SHARE_HISTORY        ## Share history between sessions

    ## Completion
    setopt ALWAYS_TO_END        ## Move cursor to end of completion
    setopt AUTO_LIST            ## Automatically list choices on ambiguous completion
    setopt AUTO_MENU            ## Use menu completion after second consecutive request
    setopt AUTO_PARAM_KEYS      ## Remove trailing characters when completion ends
    setopt AUTO_PARAM_SLASH     ## Add trailing slash for directory completions
    setopt AUTO_REMOVE_SLASH    ## Remove trailing slash when necessary
    setopt COMPLETE_ALIASES     ## Complete aliases
    setopt COMPLETE_IN_WORD     ## Complete from both ends of word
    setopt GLOB_COMPLETE        ## Generate glob patterns as completions
    setopt HASH_LIST_ALL        ## Hash command path on first completion attempt
    setopt LIST_AMBIGUOUS       ## List completions on exact matches too
    setopt LIST_BEEP            ## Beep on ambiguous completions
    setopt LIST_PACKED          ## Use compact completion lists
    setopt LIST_TYPES           ## Show file types in completion lists
    setopt MENU_COMPLETE        ## Insert first match immediately
    setopt REC_EXACT            ## Recognize exact matches even if they are ambiguous

    ## Expansion and Globbing
    setopt BAD_PATTERN          ## Report errors for malformed glob patterns
    setopt BARE_GLOB_QUAL       ## Allow bare glob qualifiers
    setopt BRACE_CCL            ## Allow brace character class list expansion
    setopt CASE_GLOB            ## Make globbing case sensitive
    setopt CSH_NULL_GLOB        ## Report error for unmatched globs instead of passing literally
    setopt EQUALS               ## Perform = filename expansion
    setopt EXTENDED_GLOB        ## Use extended globbing syntax
    setopt GLOB                 ## Perform filename expansion
    setopt GLOB_DOTS            ## Include dotfiles in glob results
    setopt GLOB_STAR_SHORT      ## Allow **/ as shorthand for **/*
    setopt HIST_SUBST_PATTERN   ## Support substitutions in history expansion
    setopt MAGIC_EQUAL_SUBST    ## Perform filename expansion on unquoted arguments to =
    setopt MARK_DIRS            ## Add trailing slash to directory names from glob expansion
    setopt MULTIBYTE            ## Support multibyte characters
    setopt NOMATCH              ## Report error for unmatched patterns
    setopt NULL_GLOB            ## Remove unmatched patterns instead of reporting error
    setopt NUMERIC_GLOB_SORT    ## Sort filenames numerically when possible
    setopt RC_EXPAND_PARAM      ## Array expansion with parameters
    setopt SH_GLOB              ## Disable extended globbing when in sh compatibility mode
    setopt UNSET                ## Treat unset parameters as empty

    ## Input/Output
    setopt ALIASES              ## Enable alias expansion
    setopt CLOBBER              ## Allow > redirection to overwrite existing files
    setopt CORRECT              ## Try to correct spelling of commands
    setopt CORRECT_ALL          ## Try to correct spelling of all arguments
    setopt FLOW_CONTROL         ## Enable flow control
    setopt IGNORE_EOF           ## Ignore EOF character (Ctrl+D)
    setopt INTERACTIVE_COMMENTS ## Allow comments in interactive shells
    setopt HASH_CMDS            ## Hash commands to speed up subsequent invocations
    setopt HASH_DIRS            ## Hash directories for cd command
    setopt MAIL_WARNING         ## Warn about new mail in mailboxes
    setopt PATH_DIRS            ## Search PATH for subdirectory commands
    setopt PRINT_EIGHT_BIT      ## Allow high-bit characters in filenames
    setopt RC_QUOTES            ## Allow '' to represent a single quote within single quotes
    setopt RM_STAR_SILENT       ## Don't ask for confirmation when using rm *
    setopt SHORT_LOOPS          ## Allow short forms of for, repeat, select, if, and function constructs

    ## Job Control
    setopt AUTO_CONTINUE        ## Automatically resume stopped jobs when they get a SIGCONT
    setopt AUTO_RESUME          ## Resume jobs with simple command names
    setopt BG_NICE              ## Run background jobs with lower priority
    setopt CHECK_JOBS           ## Report status of jobs before exiting
    setopt HUP                  ## Send HUP signal to jobs when shell exits
    setopt LONG_LIST_JOBS       ## List jobs in long format
    setopt MONITOR              ## Enable job control
    setopt NOTIFY               ## Report job status immediately

    ## Prompting
    setopt PROMPT_BANG          ## Perform history expansion in prompts
    setopt PROMPT_PERCENT       ## Perform % expansion in prompts
    setopt PROMPT_SUBST         ## Perform parameter/command/arithmetic expansion in prompts
    setopt TRANSIENT_RPROMPT    ## Remove right prompt from previous lines

    ## Scripts and Functions
    setopt C_BASES              ## Output hexadecimal/octal in C format
    setopt C_PRECEDENCES        ## Use C operator precedence rules
    setopt NO_DEBUG_BEFORE_CMD  ## Run DEBUG trap before each command
    setopt ERR_EXIT             ## Exit immediately on error
    setopt ERR_RETURN           ## Return from function/script on error
    setopt EVAL_LINENO          ## Set $LINENO in eval
    setopt EXEC                 ## Execute commands (set to debug)
    setopt FUNCTION_ARGZERO     ## Set $0 to function name when calling functions
    setopt LOCAL_OPTIONS        ## Make options local to functions
    setopt LOCAL_TRAPS          ## Make traps local to functions
    setopt MULTI_FUNC_DEF       ## Allow multiple function definitions in single command
    setopt MULTIOS              ## Allow multiple redirections
    setopt OCTAL_ZEROES         ## Interpret leading zeroes in arithmetic as octal
    setopt PIPE_FAIL            ## Return exit code of last failed command in pipeline
    setopt NO_SOURCE_TRACE      ## Show line numbers when sourcing files
    setopt TYPESET_SILENT       ## Don't complain about attempts to create readonly variables
    setopt WARN_CREATE_GLOBAL   ## Warn when creating global variables from functions
    setopt NO_XTRACE            ## Show commands and arguments as they are
    # executed

    ## Zle
    setopt BEEP                 ## Beep on error in line editor
    setopt COMBINING_CHARS      ## Combine zero-length punctuation characters with base character
    setopt EMACS                ## Use emacs key bindings (conflicts with VI)
    setopt OVERSTRIKE           ## Use overstrike mode instead of insert mode
    setopt SINGLE_LINE_ZLE      ## Use single line for line editor
    #setopt VI                  ## Use vi key bindings (conflicts with EMACS)
    setopt ZLE                  ## Use zsh line editor

    ## Directory Navigation
    setopt AUTO_CD              ## Change to directory without typing cd
    setopt AUTO_PUSHD           ## Automatically push directories onto stack
    setopt CDABLE_VARS          ## Use named directories for cd
    setopt CHASE_DOTS           ## Resolve .. in cd path
    setopt CHASE_LINKS          ## Follow symbolic links in cd
    setopt POSIX_CD             ## Use POSIX semantics for cd
    setopt PUSHD_IGNORE_DUPS    ## Don't push duplicate directories
    setopt PUSHD_MINUS          ## Exchange meaning of + and - for popd/pushd
    setopt PUSHD_SILENT         ## Don't print directory stack after pushd/popd
    setopt PUSHD_TO_HOME        ## pushd with no arguments acts like pushd $HOME
}
