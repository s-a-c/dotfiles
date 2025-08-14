# Fixed Post-Plugin Configuration
# This file is sourced after plugins are loaded
# Contains aliases, functions, options, key bindings, and tool integrations

# Set file type and editor options for this file
# vim: ft=zsh sw=4 ts=4 et nu rnu ai si

[[ -n "$ZSH_DEBUG" ]] && printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2

## [plugins]    ## Plugin Integrations
{
    [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins]" >&2

    ## [plugins.evalcache]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.evalcache]" >&2

        _evalcache_config() {
            # Configuration for evalcache plugin
            # Cache commonly used tools for faster shell startup
            if command -v _evalcache >/dev/null 2>&1; then
                if command -v atuin >/dev/null 2>&1; then
                    _evalcache atuin init zsh
                fi

            if command -v starship >/dev/null 2>&1; then
                _evalcache starship init zsh --print-full-init >/dev/null 2>&1
            fi

                if command -v zoxide >/dev/null 2>&1; then
                    _evalcache zoxide init zsh
                fi

                if command -v thefuck >/dev/null 2>&1; then
                    _evalcache thefuck --alias
                fi
            fi
        }

        # Defer the configuration to speed up startup
        autoload -Uz add-zsh-hook

        _evalcache_run_once() {
             _evalcache_config
            add-zsh-hook -d precmd _evalcache_run_once
        }

        add-zsh-hook precmd _evalcache_run_once
    }

    ## [plugins.zsh-abbr]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.zsh-abbr]" >&2

        if command -v abbr >/dev/null 2>&1; then
            # Silent abbreviation addition function
            abbr_add_silent() {
                abbr add "$@" >/dev/null 2>&1
            }

            # Add common abbreviations
            add_common_abbreviations() {
                # Git abbreviations
                abbr_add_silent g="git"
                abbr_add_silent gs="git status"
                abbr_add_silent ga="git add"
                abbr_add_silent gc="git commit"
                abbr_add_silent gp="git push"
                abbr_add_silent gl="git pull"
                abbr_add_silent gco="git checkout"
                abbr_add_silent gb="git branch"
                abbr_add_silent gd="git diff"

                # System abbreviations
                abbr_add_silent ll="ls -la"
                abbr_add_silent la="ls -la"
                abbr_add_silent ..="cd .."
                abbr_add_silent ...="cd ../.."

                # Docker abbreviations
                abbr_add_silent d="docker"
                abbr_add_silent dc="docker-compose"
                abbr_add_silent dps="docker ps"

                # Global abbreviations (expand anywhere on line)
                abbr_add_silent --global G="| grep"
                abbr_add_silent --global L="| less"
                abbr_add_silent --global H="| head"
                abbr_add_silent --global T="| tail"
                abbr_add_silent --global W="| wc -l"
                abbr_add_silent --global S="| sort"
            }

            # Function to convert existing aliases to abbreviations
            convert_aliases_to_abbr() {
                local alias_name alias_value

                # Get all current aliases
                alias_output="${(@f)$(alias)}"
                for alias_line in $alias_output; do
                    # Parse alias line: alias_name='alias_value'
                    if [[ $alias_line =~ "^([^=]+)='(.*)'\$" ]]; then
                        alias_name="${match[1]}"
                        alias_value="${match[2]}"

                        # Skip certain aliases that shouldn't be converted
                        case "$alias_name" in
                            _*|compdef*|which-command*) continue ;;
                        esac

                        # Add as abbreviation (regular scope by default)
                        abbr add "$alias_name=$alias_value"

                        # Optionally remove the original alias
                        # unalias "$alias_name" 2>/dev/null || true
                    fi
                done

                echo "Converted aliases to abbreviations. Run 'abbr list' to see them."
            }

            # Function to import aliases from a specific source
            import_aliases_to_abbr() {
                local source_file="${1:-$HOME/.aliases}"

                if [[ -f "$source_file" ]]; then
                    # Source the file to load aliases
                    source "$source_file"

                    # Convert loaded aliases
                    convert_aliases_to_abbr
                else
                    echo "Alias file not found: $source_file"
                    return 1
                fi
            }

            # Smart space function - only expands abbreviations when appropriate (Fix 4)
            smart_space() {
                # Check if we're at the end of a potential abbreviation
                if [[ $LBUFFER =~ [[:space:]]([[:alnum:]_-]+)$ ]] || [[ $LBUFFER =~ ^([[:alnum:]_-]+)$ ]]; then
                    local potential_abbr="${match[1]}"

                    # Check if it's actually a defined abbreviation
                    if abbr list | grep -q "^${potential_abbr}="; then
                        zle abbr-expand
                    else
                        zle self-insert
                    fi
                else
                    zle self-insert
                fi
            }

            # Register widgets with error handling for syntax highlighting compatibility
            _register_abbr_widgets() {
                # Register the smart_space widget first
                zle -N smart_space 2>/dev/null || {
                    # If registration fails, create a fallback
                    smart_space() { zle self-insert; }
                    zle -N smart_space 2>/dev/null || true
                }

                # Register other abbreviation widgets
                zle -N abbr-expand 2>/dev/null || true
                zle -N abbr-expand-and-space 2>/dev/null || true
                zle -N abbr-expand-and-accept 2>/dev/null || true
                zle -N abbr-expand-and-insert 2>/dev/null || true
            }

            # Ensure widgets are registered after shell initialization
            #autoload -Uz add-zsh-hook
            #add-zsh-hook precmd _register_abbr_widgets
            # Register widgets immediately instead of deferring
            _register_abbr_widgets

            # Key Bindings for abbreviation expansion (Fix 1 + Fix 4 applied)
            {
                # bindkey " "  abbr-expand                  # Space expands abbreviations (DISABLED - Fix 1)
                bindkey " " smart_space                     # Smart space expands when appropriate (Fix 4)
                bindkey "^E" abbr-expand                    # Ctrl-E expands abbreviations
                bindkey "^A" abbr-expand-and-insert         # Ctrl-A expands and inserts

                # Vi mode bindings
                # bindkey -M viins " "  abbr-expand-and-insert    # Space expands and inserts in vi insert mode (DISABLED - Fix 1)
                bindkey -M viins " " smart_space            # Smart space in vi insert mode (Fix 4)
                bindkey -M viins "^ " magic-space           # Ctrl-Space for literal space (no expansion)
                bindkey -M viins "^M" abbr-expand-and-accept    # Enter expands and accepts command

                # Additional useful bindings
                bindkey -M viins "^[;" abbr-expand-and-space    # Alt-; expands and adds space
                bindkey -M vicmd "A"  abbr-expand-and-insert    # A in vi command mode

                # Emacs mode bindings
                # bindkey -M emacs " "  abbr-expand               # Space in emacs mode (DISABLED - Fix 1)
                bindkey -M emacs " " smart_space            # Smart space in emacs mode (Fix 4)
                bindkey -M emacs "^[;" abbr-expand-and-space    # Alt-; in emacs mode
            }

            # Auto-convert existing aliases on first run (optional)
            if [[ ! -f "${ABBR_USER_ABBREVIATIONS_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh-abbr/user-abbreviations}" ]] && (( $+aliases )); then
                echo "First run detected. Converting existing aliases to abbreviations..."
                convert_aliases_to_abbr
            fi

            # Integration with other plugins
            # zsh-autosuggestions integration
            if [[ -n "$ZSH_AUTOSUGGEST_STRATEGY" ]]; then
                # Add abbreviations to autosuggestion strategy
                ZSH_AUTOSUGGEST_STRATEGY=(abbreviations $ZSH_AUTOSUGGEST_STRATEGY)
            fi

            # Oh My Zsh compatibility
            if [[ -n "$ZSH" ]]; then
                # Ensure compatibility with Oh My Zsh
                export ABBR_SET_EXPANSION_CURSOR=1
            fi

            # Add common abbreviations
            add_common_abbreviations

            # Clean up the functions
            unset -f add_common_abbreviations convert_aliases_to_abbr import_aliases_to_abbr
        fi
    }

    ## [plugins.carapace]   ## Carapace completion system
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.carapace]" >&2
        if command -v carapace >/dev/null 2>&1; then
            export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
            zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
            builtin source <(carapace _carapace)
        fi
    }

    ## [plugins.fast-syntax-highlighting]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.fast-syntax-highlighting]" >&2

        if command -v fast-theme >/dev/null 2>&1; then
            # Suppress all output from fast-theme (both stdout and stderr)
            fast-theme q-jmnemonic >/dev/null 2>&1 || true
        fi
    }
}
