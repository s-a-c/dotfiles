#!/usr/bin/env zsh
# iTerm2 Shell Integration - macOS Specific
# This file provides iTerm2 terminal integration features including prompt marking,
# command execution tracking, and state reporting for enhanced terminal functionality
# Dependencies: iTerm2 terminal (macOS only - gracefully degrades if not present)
# Load Order: 025 - macOS UI integrations (after basic prompt, before UI enhancements)

[[ "$ZSH_DEBUG" == "1" ]] && {
        zsh_debug_echo "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
    zsh_debug_echo "# [iterm2-shell-integration] Starting iTerm2 shell integration (macOS)"
}

# Only proceed if this is an interactive shell and we're on macOS
if [[ -o interactive ]] && [[ "$(uname -s)" == "Darwin" ]]; then
    # Check if iTerm2 integration should be enabled
    # Skip if already installed, or if terminal is incompatible
    if [ "${ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX-}""$TERM" != "tmux-256color" -a \
         "${ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX-}""$TERM" != "screen" -a \
         "${ITERM_SHELL_INTEGRATION_INSTALLED-}" = "" -a \
         "$TERM" != linux -a \
         "$TERM" != dumb ]; then

        ITERM_SHELL_INTEGRATION_INSTALLED=Yes
        ITERM2_SHOULD_DECORATE_PROMPT="1"

        # Indicates start of command output. Runs just before command executes.
        iterm2_before_cmd_executes() {
            if [ "$TERM_PROGRAM" = "iTerm.app" ]; then
                printf "\033]133;C;\r\007"
            else
                printf "\033]133;C;\007"
            fi
        }

        iterm2_set_user_var() {
            printf "\033]1337;SetUserVar=%s=%s\007" "$1" $(printf "%s" "$2" | base64 | tr -d '\n')
        }

        # Users can write their own version of this method. It should call
        # iterm2_set_user_var but not produce any other output.
        # e.g., iterm2_set_user_var currentDirectory $PWD
        # Accessible in iTerm2 (in a badge now, elsewhere in the future) as
        # \(user.currentDirectory).
        whence -v iterm2_print_user_vars > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            iterm2_print_user_vars() {
                true
            }
        fi

        iterm2_print_state_data() {
            local _iterm2_hostname="${iterm2_hostname-}"
            if [ -z "${iterm2_hostname:-}" ]; then
                _iterm2_hostname=$(hostname -f 2>/dev/null)
            fi
            printf "\033]1337;RemoteHost=%s@%s\007" "$USER" "${_iterm2_hostname-}"
            printf "\033]1337;CurrentDir=%s\007" "$PWD"
            iterm2_print_user_vars
        }

        # Report return code of command; runs after command finishes but before prompt
        iterm2_after_cmd_executes() {
            printf "\033]133;D;%s\007" "$STATUS"
            iterm2_print_state_data
        }

        # Mark start of prompt
        iterm2_prompt_mark() {
            printf "\033]133;A\007"
        }

        # Mark end of prompt
        iterm2_prompt_end() {
            printf "\033]133;B\007"
        }

        # Decorate the prompt with iTerm2 escape sequences
        iterm2_decorate_prompt() {
            # This should be a raw PS1 without iTerm2's stuff. It could be changed during command
            # execution.
            ITERM2_PRECMD_PS1="$PS1"
            ITERM2_SHOULD_DECORATE_PROMPT=""

            # Add our escape sequences just before the prompt is shown.
            # Use ITERM2_SQUELCH_MARK for people who can't modify PS1 directly, like powerlevel9k users.
            local PREFIX=""
            if [[ $PS1 == *"$(iterm2_prompt_mark)"* ]]; then
                PREFIX=""
            elif [[ "${ITERM2_SQUELCH_MARK-}" != "" ]]; then
                PREFIX=""
            else
                PREFIX="%{$(iterm2_prompt_mark)%}"
            fi
            PS1="$PREFIX$PS1%{$(iterm2_prompt_end)%}"
            ITERM2_DECORATED_PS1="$PS1"
        }

        iterm2_precmd() {
            local STATUS="$?"
            if [ -z "${ITERM2_SHOULD_DECORATE_PROMPT-}" ]; then
                # You pressed ^C while entering a command (iterm2_preexec did not run)
                iterm2_before_cmd_executes
                if [ "$PS1" != "${ITERM2_DECORATED_PS1-}" ]; then
                    # PS1 changed, perhaps in another precmd. See issue 9938.
                    ITERM2_SHOULD_DECORATE_PROMPT="1"
                fi
            fi

            iterm2_after_cmd_executes "$STATUS"

            if [ -n "$ITERM2_SHOULD_DECORATE_PROMPT" ]; then
                iterm2_decorate_prompt
            fi
        }

        # This is not run if you press ^C while entering a command.
        iterm2_preexec() {
            # Set PS1 back to its raw value prior to executing the command.
            PS1="$ITERM2_PRECMD_PS1"
            ITERM2_SHOULD_DECORATE_PROMPT="1"
            iterm2_before_cmd_executes
        }

        # If hostname -f is slow on your system set iterm2_hostname prior to
        # sourcing this script. We know it is fast on macOS so we don't cache
        # it. That lets us handle the hostname changing like when you attach
        # to a VPN.
        if [ -z "${iterm2_hostname-}" ]; then
            if [ "$(uname)" != "Darwin" ]; then
                iterm2_hostname=$(hostname -f 2>/dev/null)
                # Some flavors of BSD (i.e. NetBSD and OpenBSD) don't have the -f option.
                if [ $? -ne 0 ]; then
                    iterm2_hostname=$(hostname)
                fi
            fi
        fi

        # Register the hooks with ZSH
        [[ -z ${precmd_functions-} ]] && precmd_functions=()
        precmd_functions=($precmd_functions iterm2_precmd)

        [[ -z ${preexec_functions-} ]] && preexec_functions=()
        preexec_functions=($preexec_functions iterm2_preexec)

        # Initialize the integration
        iterm2_print_state_data
        printf "\033]1337;ShellIntegrationVersion=14;shell=zsh\007"

        zsh_debug_echo "# [iterm2-shell-integration] iTerm2 integration initialized (macOS)"
    else
        zsh_debug_echo "# [iterm2-shell-integration] Skipping - not compatible or already installed"
    fi
else
    zsh_debug_echo "# [iterm2-shell-integration] Skipping - non-interactive shell or not macOS"
fi

zsh_debug_echo "# [iterm2-shell-integration] iTerm2 shell integration complete (macOS)"
