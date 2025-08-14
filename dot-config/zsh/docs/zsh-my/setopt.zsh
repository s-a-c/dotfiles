
## [setopt] ## {{{
## [setopt.cd]
setopt AUTO_CD                      ## Use cd by typing directory name if it's not a command.
setopt AUTO_PUSHD                   ## Make cd push the old directory onto the directory stack.
setopt CDABLE_VARS                  ## Change directory to a path stored in a variable.
setopt CD_SILENT                    ## Do not print the directory stack after pushd or popd.
setopt NO_CHASE_DOTS                ## Do not treat `.' specially.
setopt NO_CHASE_LINKS               ## Do not treat symlinks specially.
setopt NO_POSIX_CD                  ## Do not make cd, chdir and pushd commands more compatible with the POSIX standard.
setopt PUSHD_IGNORE_DUPS            ## Don't push multiple copies directory onto the directory stack.
setopt PUSHD_MINUS                  ## Swap the meaning of cd +1 and cd -1 to the opposite.
setopt NO_PUSHD_SILENT              ## Don't print the directory stack after pushd or popd.
setopt PUSHD_TO_HOME                ## Push to home directory when no argument is given to pushd.
## [setopt.completions]
setopt ALWAYS_LAST_PROMPT           ## Move Cursor To The End Of The Line Before Displaying The Prompt.
setopt ALWAYS_TO_END                ## Move Cursor To The End Of A Completed Word.
setopt AUTO_LIST                    ## Automatically List Choices On Ambiguous Completion.
setopt AUTO_MENU                    ## Show Completion Menu On A Successive Tab Press.
setopt AUTO_NAME_DIRS               ## Automatically Insert A '/' After A Directory Name.
setopt AUTO_PARAM_KEYS              ## Automatically Insert The Key For A Parameter.
setopt AUTO_PARAM_SLASH             ## If Completed Parameter Is A Directory, Add A Trailing Slash.
setopt AUTO_REMOVE_SLASH            ## Remove A Trailing Slash From Completed Directory Names.
setopt BASH_AUTO_LIST               ## Do Automatically List Choices On Ambiguous Completion.
setopt COMPLETE_ALIASES             ## Do Not Complete Alias Names.
setopt COMPLETE_IN_WORD             ## Complete From Both Ends Of A Word.
setopt GLOB_COMPLETE                ## Perform Globbing On The Results Of Tab Completion.
setopt HASH_LIST_ALL                ## List All Possible Completions.
setopt LIST_AMBIGUOUS               ## List All Possible Completions.
setopt LIST_BEEP                    ## Beep When Completion Ambiguous.
setopt LIST_PACKED                  ## List Packed Directories First.
setopt LIST_TYPES                   ## List The Type Of File When Completing.
setopt MENU_COMPLETE                ## Do Not Autoselect The First Completion Entry.
setopt REC_EXACT                    ## Perform Recursive Exact Matching.
## [setopt.glob]
setopt BAD_PATTERN                  ## Treat Bad Patterns As Errors.
setopt BARE_GLOB_QUAL               ## Do Not Qualify Bare Glob Patterns.
setopt BRACE_CCL                    ## Allow Brace Character Class List Expansion.
setopt NO_CASE_MATCH                ## Do Not Perform Case-Insensitive Matching.
setopt NO_CASE_PATHS                ## Do Not Perform Case-Insensitive Matching On Filenames.
setopt CSH_NULL_GLOB                ## Do Not Treat Null Glob Patterns As Errors.
setopt EQUALS                       ## Perform Equality Globbing.
setopt EXTENDED_GLOB                ## Use Extended Globbing.
setopt NO_FORCE_FLOAT               ## Do Not Force Floating Point Numbers.
setopt GLOB                         ## Perform Globbing On The Results Of Tab Completion.
setopt GLOB_ASSIGN                  ## Perform Globbing On The Results Of Parameter Assignment.
setopt GLOB_DOTS                    ## Glob Dotfiles As Well.
setopt GLOB_STAR_SHORT              ## Use Shorter Globbing Syntax.
setopt GLOB_SUBST                   ## Perform Globbing On The Results Of Parameter Substitution.
setopt HIST_SUBST_PATTERN           ## Perform History Substitution On Patterns.
setopt NO_IGNORE_BRACES             ## Do Not Ignore Braces In Globbing.
setopt NO_IGNORE_CLOSE_BRACES       ## Do Not Ignore Close Braces In Globbing.
setopt NO_KSH_GLOB                  ## Use KSH-Style Globbing.
setopt MAGIC_EQUAL_SUBST            ## Perform Magic Equals Substitution.
setopt MARK_DIRS                    ## Mark Directories With A Trailing Slash.
setopt MULTIBYTE                    ## Use Multibyte Character Sets.
setopt NO_NOMATCH                   ## Do Not Treat Failed Patterns As Errors.
setopt NULL_GLOB                    ## Do Not Treat Null Glob Patterns As Errors.
setopt NUMERIC_GLOB_SORT            ## Perform Numeric Glob Sorting.
setopt RC_EXPAND_PARAM              ## Perform Parameter Expansion On The Results Of Command Substitution.
setopt NO_REMATCH_PCRE              ## Do Not Perform PCRE Regular Expression Matching.
setopt SH_GLOB                      ## Use SH-Style Globbing.
setopt UNSET                        ## Treat Unset Parameters As Errors.
setopt NO_WARN_CREATE_GLOBAL        ## Warn When Creating Global Aliases.
setopt NO_WARN_NESTED_VAR           ## Warn When Nesting Variables.
## [setopt.history]
setopt APPEND_HISTORY               ## Allow multiple sessions to append to one Zsh command history.
setopt BANG_HIST                    ## Treat the '!' character, especially during Expansion.
setopt EXTENDED_HISTORY             ## Show Timestamp In History.
setopt NO_HIST_ALLOW_CLOBBER        ## Do Not Allow History File To Be Clobbered.
setopt HIST_BEEP                    ## Beep When Accessing Non-Existent History.
setopt HIST_EXPIRE_DUPS_FIRST       ## Expire A Duplicate Event First When Trimming History.
setopt HIST_FCNTL_LOCK              ## Use Fcntl Locks To Lock The History File.
setopt HIST_FIND_NO_DUPS            ## Do Not Display A Previously Found Event.
setopt HIST_IGNORE_ALL_DUPS         ## Remove older duplicate entries from history.
setopt HIST_IGNORE_DUPS             ## Do not record an event that was just recorded again.
setopt HIST_IGNORE_SPACE            ## Do Not Record An Event Starting With A Space.
setopt HIST_LEX_WORDS               ## Add Words To The History List After Lexing.
setopt NO_HIST_NO_FUNCTIONS         ## Do Record Functions In The History.
setopt HIST_NO_STORE                ## Do Not Store The History File.
setopt HIST_REDUCE_BLANKS           ## Remove superfluous blanks from history items.
setopt HIST_SAVE_BY_COPY            ## Save The History By Copying.
setopt HIST_SAVE_NO_DUPS            ## Do not write a duplicate event to the history file.
setopt HIST_VERIFY                  ## Do Not Execute Immediately Upon History Expansion.
setopt NO_INC_APPEND_HISTORY        ## Write to the history file immediately, not when the shell exits.
setopt NO_INC_APPEND_HISTORY_TIME   ## Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY                ## Share history between different instances of the shell.
## [setopt.initialisation]
setopt ALL_EXPORT                   ## Export All Variables.
setopt GLOBAL_EXPORT                ## Export All Variables.
setopt GLOBAL_RCS                   ## Do Source Global Zsh Configuration Files.
setopt RCS                          ## Do Source Zsh Configuration Files.
## [setopt.io]
setopt ALIASES                      ## Allow Aliases To Be Resolved In Non-Interactive Shells.
setopt NO_CLOBBER                   ## Do Not Overwrite Existing Files With Redirection.
setopt CLOBBER_EMPTY                ## Overwrite Existing Files With Redirection.
setopt CORRECT                      ## Try To Correct The Spelling Of Commands.
setopt NO_CORRECT_ALL               ## Try To Correct The Spelling Of All Arguments In A Line.
setopt NO_DVORAK                    ## Do Not Use Dvorak Keyboard Layout.
setopt FLOW_CONTROL                 ## Enable Start/Stop Characters In Shell Editor.
setopt IGNORE_EOF                   ## Ignore EOF Characters.
setopt INTERACTIVE_COMMENTS         ## Allow Comments In Interactive Shells.
setopt HASH_CMDS                    ## Cache Command Locations.
setopt HASH_DIRS                    ## Cache Directory Locations.
setopt NO_HASH_EXECUTABLES_ONLY     ## Cache Executable Locations.
setopt PATH_DIRS                    ## Perform Path Search Even On Command Names With Slashes.
setopt PATH_SCRIPT                  ## Perform Path Search On Scripts.
setopt PRINT_EIGHT_BIT              ## Print Eight-Bit Characters.
setopt PRINT_EXIT_VALUE             ## Print Exit Value Of Last Command.
setopt RC_QUOTES                    ## Allow 'Henry''s Garage' Instead Of 'Henry'\''s Garage'.
setopt RM_STAR_WAIT                 ## Wait For Completion Of Background Processes.
setopt SHORT_LOOPS                  ## Use Short Loops In For And While Constructs.
setopt NO_SUN_KEYBOARD_HACK         ## Do Not Use Sun Keyboard Hack.
## [setopt.Jobs]
setopt AUTO_CONTINUE                ## Attempt To Resume Existing Job Before Creating A New Process.
setopt AUTO_RESUME                  ## Attempt To Resume Existing Job Before Creating A New Process.
setopt NO_BG_NICE                   ## Don't Run All Background Jobs At A Lower Priority.
setopt CHECK_JOBS                   ## Don't Report On Jobs When Shell Exit.
setopt CHECK_RUNNING_JOBS           ## Don't Report On Running Jobs When Shell Exit.
setopt NO_HUP                       ## Don't Kill Jobs On Shell Exit.
setopt LONG_LIST_JOBS               ## List Jobs In The Long Format By Default.
setopt MONITOR                      ## Enable Job Monitoring.
setopt NOTIFY                       ## Report Status Of Background Jobs Immediately.
setopt NO_POSIX_JOBS                ## Use POSIX Job Control.
## [setopt.prompt]
setopt PROMPT_BANG                  ## Include '!' In The Prompt When The Shell Is Not In The Foreground.
setopt PROMPT_CR                    ## Include A Carriage Return In The Prompt.
setopt PROMPT_SP                    ## Include A Space In The Prompt.
setopt PROMPT_SUBST                 ## Substitution Of Parameters Inside The Prompt Each Time The Prompt Is Drawn.
setopt TRANSIENT_RPROMPT            ## Do Not Clear The Right Prompt When Accepting A Line.
## [setopt.script]
setopt NO_ALIAS_FUNC_DEF            ## Do Not Allow Alias Definitions To Be Function Definitions.
setopt NO_C_BASES                   ## Do Not Use C-Style Backslash Escapes.
setopt C_PRECEDENCES                ## Use C-Style Precedences.
setopt DEBUG_BEFORE_CMD             ## Debug Before Executing Each Command.
setopt NO_ERR_EXIT                  ## Exit On Error.
setopt NO_ERR_RETURN                ## Return On Error.
setopt EVAL_LINENO                  ## Evaluate $LINENO.
setopt EXEC                         ## Execute Command Substitution.
setopt FUNCTION_ARGZERO             ## Set $0 To The Function Name.
setopt LOCAL_LOOPS                  ## Use Local Loops In For And While Constructs.
setopt LOCAL_OPTIONS                ## Use Local Options.
setopt NO_MULTI_FUNC_DEF            ## Do Not Allow Multiple Function Definitions.
setopt MULTIOS                      ## Implicit Tees Or Cats When Multiple Redirections Are Attempted.
setopt NO_OCTAL_ZEROES              ## Do Not Use Octal Zeroes.
setopt PIPE_FAIL                    ## Fail On Pipelines.
setopt NO_SOURCE_TRACE              ## Do Not Trace Source Files.
setopt TYPESET_SILENT               ## Do Silence Typeset.
setopt TYPESET_TO_UNSET             ## Typeset To Unset.
setopt NO_VERBOSE                   ## Do Not Print Command Before Executing.
setopt NO_XTRACE                    ## Do Not Trace Commands.
## [setopt.shell-emulation]
setopt APPEND_CREATE                ## Append To The History File, Don't Overwrite It.
setopt NO_BASH_REMATCH              ## Do Not Perform Bash-Style Regular Expression Matching.
setopt NO_BSD_ECHO                  ## Do Not Use BSD Echo.
setopt NO_CONTINUE_ON_ERROR         ## Do Not Continue On Error.
setopt NO_CSH_JUNKIE_HISTORY        ## Do Not Use Csh-Style History.
setopt NO_CSH_JUNKIE_LOOPS          ## Do Not Use Csh-Style Loops.
setopt NO_CSH_JUNKIE_QUOTES         ## Do Not Use Csh-Style Quotes.
setopt NO_CSH_NULLCMD               ## Do Not Use Csh-Style Null Command.
setopt NO_KSH_ARRAYS                ## Do Not Use Ksh-Style Arrays.
setopt NO_KSH_AUTOLOAD              ## Do Not Use Ksh-Style Autoload.
setopt NO_KSH_OPTION_PRINT          ## Do Not Use Ksh-Style Option Print.
setopt NO_KSH_TYPESET               ## Do Not Use Ksh-Style Typeset.
setopt NO_KSH_ZERO_SUBSCRIPT        ## Do Not Use Ksh-Style Subscript Zero.
setopt NO_POSIX_ALIASES             ## Do Not Use POSIX Aliases.
setopt NO_POSIX_ARGZERO             ## Do Not Use POSIX $0.
setopt NO_POSIX_BUILTINS            ## Do Not Use POSIX Builtins.
setopt NO_POSIX_IDENTIFIERS         ## Do Not Use POSIX Identifiers.
setopt NO_POSIX_STRINGS             ## Do Not Use POSIX Strings.
setopt NO_POSIX_TRAPS               ## Do Not Use POSIX Traps.
setopt NO_SH_FILE_EXPANSION         ## Do Not Use SH-Style File Expansion.
setopt NO_SH_NULLCMD                ## Do Not Use SH-Style Null Command.
setopt NO_SH_OPTION_LETTERS         ## Do Not Use SH-Style Option Letters.
setopt NO_SH_WORD_SPLIT             ## Do Not Use SH-Style Word Splitting.
setopt NO_TRAPS_ASYNC               ## Do Not Use Asynchronous Traps.
## [setopt.shell.state]
setopt INTERACTIVE                  ## Enable Interactive Shell Features.
setopt LOGIN                        ## Enable Login Shell Features.
## [setopt.zle]
setopt COMBINING_CHARS              ## Combine Zero-Length Punctuation Characters ( Accents ) With The Base Character.
setopt ZLE                          ## Enable Zsh Line Editor.
## }}}  ## [setopt]
