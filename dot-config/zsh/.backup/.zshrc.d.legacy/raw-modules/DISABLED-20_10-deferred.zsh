#!/usr/bin/env zsh
# Deferred Plugins - Lazy loading for non-essential functionality
# FIXED: Re-enabled after solving path issues
# This file sets up lazy loading for plugins that aren't needed immediately
# Load time target: <50ms (setup only, actual loading deferred)

# Conditionally disable verbose output during normal startup
if [[ -z "$ZSH_DEBUG_VERBOSE" ]]; then
    setopt NO_VERBOSE
    setopt NO_XTRACE
fi

[[ "$ZSH_DEBUG" == "1" ]] && {
        zf::debug "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
}

# Only proceed if zgenom is available
if ! command -v zgenom >/dev/null 2>&1; then
    zf::debug "# [deferred-plugins] Zgenom not available, skipping lazy loading setup"
    return 0
fi

# Plugin lazy loading registry
typeset -gA _LAZY_PLUGIN_REGISTRY
typeset -gA _LAZY_COMMAND_MAP
typeset -gA _LAZY_PLUGIN_LOADED

# Define plugins for lazy loading with their trigger commands
setup_lazy_plugins() {
    # Abbreviation system - REMOVED from deferred loading (loaded immediately via zgenom)

    # FZF integration - defer until fzf commands used
    _LAZY_PLUGIN_REGISTRY[fzf-zsh]="unixorn/fzf-zsh-plugin"
    _LAZY_COMMAND_MAP[fzf]="fzf-zsh"
    _LAZY_COMMAND_MAP[fzf-tmux]="fzf-zsh"

    # Development tool plugins
    _LAZY_PLUGIN_REGISTRY[docker-plugin]="ohmyzsh/ohmyzsh plugins/docker"
    _LAZY_COMMAND_MAP[docker-compose]="docker-plugin"
    _LAZY_COMMAND_MAP[docker-machine]="docker-plugin"

    _LAZY_PLUGIN_REGISTRY[golang-plugin]="ohmyzsh/ohmyzsh plugins/golang"
    _LAZY_COMMAND_MAP[go]="golang-plugin"

    _LAZY_PLUGIN_REGISTRY[node-plugin]="ohmyzsh/ohmyzsh plugins/node"
    _LAZY_COMMAND_MAP[npm]="node-plugin"
    _LAZY_COMMAND_MAP[yarn]="node-plugin"

    _LAZY_PLUGIN_REGISTRY[python-plugin]="ohmyzsh/ohmyzsh plugins/python"
    _LAZY_COMMAND_MAP[python]="python-plugin"
    _LAZY_COMMAND_MAP[pip]="python-plugin"

    # Git enhancement tools
    _LAZY_PLUGIN_REGISTRY[git-extras]="unixorn/git-extra-commands"
    _LAZY_COMMAND_MAP[git-flow]="git-extras"
    _LAZY_COMMAND_MAP[git-standup]="git-extras"

    # Utility plugins
    _LAZY_PLUGIN_REGISTRY[sysadmin-util]="skx/sysadmin-util"
    _LAZY_COMMAND_MAP[multi-ping]="sysadmin-util"
    _LAZY_COMMAND_MAP[timeout3]="sysadmin-util"

    zf::debug "# [deferred-plugins] Lazy plugin registry configured"
}

# Create lazy loading function for a plugin
create_lazy_loader() {
    local plugin_key="$1"
    local plugin_spec="$2"

    # Create the lazy loading function
    {
        eval "
        lazy_load_${plugin_key//-/_}() {
            [[ -n \"\$ZSH_DEBUG\" ]] && zf::debug \"# [lazy-load] Loading plugin: $plugin_spec\"

            # Mark as loaded to prevent double-loading
            _LAZY_PLUGIN_LOADED[$plugin_key]=1

            # Load the plugin
            zgenom load '$plugin_spec'
            zgenom save  # Update the cache

            # Source the plugin immediately if possible
            local plugin_dir=\"\$ZGENOM_DIR/\${plugin_spec//\//-}\"
            if [[ -d \"\$plugin_dir\" ]]; then
                for script in \"\$plugin_dir\"/*.plugin.zsh \"\$plugin_dir\"/*.zsh; do
                    [[ -f \"\$script\" ]] && source \"\$script\"
                done
            fi

            return 0
        }
        "
    } 2>/dev/null

    # Export function silently
    {
        typeset -gf "lazy_load_${plugin_key//-/_}"
    } >/dev/null 2>&1
}

# Create command placeholders that trigger lazy loading
create_command_placeholders() {
    for cmd in "${(@k)_LAZY_COMMAND_MAP}"; do
        local plugin_key="${_LAZY_COMMAND_MAP[$cmd]}"

        # Skip if command already exists (real command available)
        command -v "$cmd" >/dev/null 2>&1 && continue

        # Create placeholder function
        {
            eval "
            $cmd() {
                # Remove this placeholder
                unfunction '$cmd' 2>/dev/null

                # Load the plugin
                lazy_load_${plugin_key//-/_}

                # Try to execute the real command
                if command -v '$cmd' >/dev/null 2>&1; then
                    '$cmd' \"\$@\"
                else
                    zf::debug 'Command $cmd not available after loading plugin'
                    return 1
                fi
            }
            "
        } 2>/dev/null

        zf::debug "# [deferred-plugins] Created lazy placeholder: $cmd"
    done
}

# Initialize the lazy loading system
init_lazy_loading() {
    setup_lazy_plugins

    # Create lazy loaders for all registered plugins
    for plugin_key in "${(@k)_LAZY_PLUGIN_REGISTRY}"; do
        local plugin_spec="${_LAZY_PLUGIN_REGISTRY[$plugin_key]}"
        create_lazy_loader "$plugin_key" "$plugin_spec"
    done

    # Create command placeholders
    create_command_placeholders

    zf::debug "# [deferred-plugins] Lazy loading system initialized"
}

# Manual plugin loading function
load_lazy_plugin() {
    local plugin_name="$1"

    if [[ -n "${_LAZY_PLUGIN_REGISTRY[$plugin_name]}" ]]; then
        "lazy_load_${plugin_name//-/_}"
    else
        zf::debug "Unknown lazy plugin: $plugin_name"
        zf::debug "Available plugins: ${(@k)_LAZY_PLUGIN_REGISTRY}"
        return 1
    fi
}

# Load all lazy plugins (for debugging/manual loading)
load_all_lazy_plugins() {
    zf::debug "# [deferred-plugins] Loading all lazy plugins..."

    for plugin_key in "${(@k)_LAZY_PLUGIN_REGISTRY}"; do
        [[ -z "${_LAZY_PLUGIN_LOADED[$plugin_key]}" ]] && "lazy_load_${plugin_key//-/_}"
    done
}

# Export functions for global use
{
    typeset -gf load_lazy_plugin load_all_lazy_plugins
} >/dev/null 2>&1

# Initialize the system
init_lazy_loading

zf::debug "# [20-plugins] Deferred plugin loading configured"
