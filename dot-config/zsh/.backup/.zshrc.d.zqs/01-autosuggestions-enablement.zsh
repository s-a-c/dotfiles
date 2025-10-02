#!/usr/bin/env zsh
# 01-emergency-zle-fix.zsh - Emergency ZLE widget repair for ZQS
# Part of the migration to symlinked ZQS .zshrc

# =============================================================================
# AUTOSUGGESTIONS RE-ENABLEMENT (POST-PLUGIN PHASE)
# =============================================================================
# Re-enable zsh-autosuggestions after ZLE is fully initialized
# Pre-plugin phase disabled it to prevent widget binding errors during plugin loading

if [[ -o interactive ]] && [[ -n "${_AUTOSUGGESTIONS_DISABLED_BY_TIMING:-}" ]]; then
    zf::debug "# [post-plugin-ext] Re-enabling autosuggestions after plugin loading"

    # Clean re-enablement function
    _reenable_autosuggestions_after_prompt() {
        # Only run once
        if [[ -n "${_AUTOSUGGESTIONS_REENABLED:-}" ]]; then
            return 0
        fi

        # Mark as re-enabled
        export _AUTOSUGGESTIONS_REENABLED=1

        # Remove this function from precmd after first run
        precmd_functions=(${precmd_functions:#_reenable_autosuggestions_after_prompt})

        # FORCE ZLE ENABLEMENT FIRST
        # The core issue is that ZLE option is disabled, preventing all widget functionality
        zf::debug "# [post-plugin-ext] Forcing ZLE enablement..."

        # Try multiple approaches to enable ZLE
        setopt ZLE 2>/dev/null || true
        zmodload zsh/zle 2>/dev/null || true
        autoload -U zle 2>/dev/null || true

        # Force initialize ZLE even if it seems enabled
        zle -I 2>/dev/null || true

        # Check if ZLE is now functional
        if [[ -o zle ]] && (( $(zle -la 2>/dev/null | wc -l) > 0 )); then
            zf::debug "# [post-plugin-ext] ZLE is functional with $(zle -la 2>/dev/null | wc -l) widgets"
            _zle_functional=1
        else
            zf::debug "# [post-plugin-ext] ZLE is still not functional (option: $([[ -o zle ]] && echo yes || echo no), widgets: $(zle -la 2>/dev/null | wc -l))"
            _zle_functional=0
        fi

        # SMART WIDGET BINDING: Override with ZLE-ready check
        # This allows binding when ZLE is ready, prevents errors when it's not
        _zsh_autosuggest_bind_widget() {
            # Only proceed if ZLE is functional
            if [[ $_zle_functional -eq 1 ]] && [[ -o zle ]] && (( $(zle -la 2>/dev/null | wc -l) > 0 )); then
                # Call the original binding function if available
                if declare -f _zsh_autosuggest_bind_widget_orig >/dev/null 2>&1; then
                    _zsh_autosuggest_bind_widget_orig "$@"
                    return $?
                else
                    # Basic widget binding - create simple forwarding widgets
                    local widget="$1"
                    local original_widget="$2"
                    local suggested_widget="$3"

                    # Only bind if the original widget exists
                    if [[ -n "${widgets[$original_widget]:-}" ]] && [[ "$widget" != "$original_widget" ]]; then
                        zle -N "$widget" "$suggested_widget" 2>/dev/null && return 0
                    fi
                    return 0
                fi
            else
                # ZLE not ready - ignore silently to prevent errors
                zf::debug "# [post-plugin-ext] Skipping widget binding for $1 (ZLE not functional)"
                return 0
            fi
        }

        # Re-enable autosuggestions now that we have safe bindings
        unset ZSH_AUTOSUGGEST_DISABLE
        unset DISABLE_AUTO_SUGGESTIONS
        unset _AUTOSUGGESTIONS_DISABLED_BY_TIMING

        # Mark that we've overridden the widget binding function
        export _ZSH_AUTOSUGGEST_WIDGET_BINDING_OVERRIDDEN=1

        # Configure autosuggestions options safely without binding widgets
        if declare -f _zsh_autosuggest_start >/dev/null 2>&1; then
            # Don't call _zsh_autosuggest_start directly - it would try to bind widgets
            # Instead, just set up the suggestions highlight style
            ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"
            # ZSH_AUTOSUGGEST_STRATEGY is already an array, don't re-export it
            # Just ensure it contains 'history' if not already set
            if [[ ${#ZSH_AUTOSUGGEST_STRATEGY[@]} -eq 0 ]]; then
                ZSH_AUTOSUGGEST_STRATEGY=(history)
            fi

            # Now trigger the autosuggestions start manually with safe widget binding
            if declare -f _zsh_autosuggest_start >/dev/null 2>&1; then
                _zsh_autosuggest_start
            fi

            zf::debug "# [post-plugin-ext] Autosuggestions fully enabled with safe binding override"
        else
            zf::debug "# [post-plugin-ext] Autosuggestions enabled but plugin functions not found"
        fi
    }

    # Hook into precmd to re-enable after first prompt (when ZLE is ready)
    precmd_functions+=(_reenable_autosuggestions_after_prompt)

elif [[ -o interactive ]]; then
    zf::debug "# [post-plugin-ext] Autosuggestions not disabled by timing control, no action needed"
else
    zf::debug "# [post-plugin-ext] Non-interactive shell, autosuggestions not needed"
fi

# Re-enable gitstatus
unset GITSTATUS_DISABLE

zf::debug "# [post-plugin-ext] autosuggestions enablement logic applied"
