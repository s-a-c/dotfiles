#!/usr/bin/env zsh
# LEGACY STUB: 65-development-integrations.zsh (migrated to 190-development-integrations.zsh)
return 0
export _LOADED_DEV_INTEGRATIONS_REDESIGN=1

# Use direct zf:: debug calls
zf::debug "[DEV-INTEGRATIONS] Loading development integrations (v2.0.0)"

# ==============================================================================
# SECTION 1: DIRENV INTEGRATION
# ==============================================================================

# direnv setup with lazy loading support (now using zf:: namespace)
_load_direnv() {
    zf::dev_load_direnv "$@"
}

# Register direnv for lazy loading or load immediately
if command -v direnv >/dev/null 2>&1; then
    if command -v lazy_register >/dev/null 2>&1; then
        lazy_register direnv _load_direnv
        zf::debug "[DEV-INTEGRATIONS] direnv registered for lazy loading"
    else
        # Fallback: load direnv immediately
        zf::debug "[DEV-INTEGRATIONS] Lazy framework not available, loading direnv immediately"
        _load_direnv direnv
    fi
else
    zf::debug "[DEV-INTEGRATIONS] direnv not available"
fi

# ==============================================================================
# SECTION 2: GIT CONFIGURATION AND ENHANCEMENTS
# ==============================================================================

# Git environment configuration
export GIT_EDITOR="${GIT_EDITOR:-${EDITOR:-vim}}"
export GIT_PAGER="${GIT_PAGER:-${PAGER:-less}}"

# Git performance settings
export GIT_OPTIONAL_LOCKS="${GIT_OPTIONAL_LOCKS:-0}"  # Disable optional locks for performance

# Enhanced git status for prompt (if not using a plugin that provides this)
if [[ -z "${ZSH_THEME_GIT_PROMPT_PREFIX:-}" ]]; then
    # Basic git prompt support for non-theme environments
    autoload -Uz vcs_info
    precmd_functions+=(vcs_info)
    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' formats ' (%b)'
    zstyle ':vcs_info:*' actionformats ' (%b|%a)'
    zf::debug "[DEV-INTEGRATIONS] Basic git vcs_info configured"
fi

# Git alias safety - prevent common mistakes
if command -v git >/dev/null 2>&1; then
    # Create safe git wrapper functions (if not already aliased)
    if ! alias git >/dev/null 2>&1; then
        # Add git configuration validation
        _safe_git() {
            # Check for git repo before certain operations
            case "$1" in
                push|pull|fetch)
                    if ! zf::safe_git rev-parse --git-dir >/dev/null 2>&1; then
                        echo "Error: Not in a git repository" >&2
                        return 1
                    fi
                    ;;
            esac
            zf::safe_git "$@"
        }

        # Only alias if we want safe git (controlled by environment variable)
        if [[ "${GIT_SAFE_MODE:-0}" == "1" ]]; then
            alias git=_safe_git
            zf::debug "[DEV-INTEGRATIONS] Safe git wrapper enabled"
        fi
    fi

    zf::debug "[DEV-INTEGRATIONS] Git configuration applied"
fi

# ==============================================================================
# SECTION 3: GITHUB COPILOT INTEGRATION
# ==============================================================================

# GitHub Copilot CLI integration
_load_github_copilot() {
    local cmd="$1"
    zf::debug "[DEV-INTEGRATIONS] Loading GitHub Copilot for command: $cmd"

    # Check for GitHub CLI with copilot extension
    if command -v gh >/dev/null 2>&1; then
        # Check if copilot extension is installed
        if gh extension list 2>/dev/null | grep -q "github/gh-copilot"; then
            # Set up copilot aliases
            alias ghcs='gh copilot suggest'
            alias ghce='gh copilot explain'
            zf::debug "[DEV-INTEGRATIONS] GitHub Copilot CLI aliases configured"
            return 0
        else
            zf::debug "[DEV-INTEGRATIONS] GitHub Copilot extension not installed"
            return 1
        fi
    else
        zf::debug "[DEV-INTEGRATIONS] GitHub CLI not found"
        return 1
    fi
}

# Register GitHub Copilot for lazy loading
if command -v gh >/dev/null 2>&1; then
    if command -v lazy_register >/dev/null 2>&1; then
        lazy_register gh-copilot _load_github_copilot
        lazy_register ghcs _load_github_copilot
        lazy_register ghce _load_github_copilot
        zf::debug "[DEV-INTEGRATIONS] GitHub Copilot registered for lazy loading"
    else
        # Fallback: load immediately if available
        _load_github_copilot gh-copilot
    fi
fi

# ==============================================================================
# SECTION 4: DEVELOPMENT ENVIRONMENT DETECTION
# ==============================================================================

# Detect common development environments
_detect_dev_env() {
    local -A dev_indicators=(
        [".git"]="git"
        [".gitignore"]="git"
        ["package.json"]="node"
        ["Cargo.toml"]="rust"
        ["go.mod"]="go"
        ["requirements.txt"]="python"
        ["Pipfile"]="python"
        ["pyproject.toml"]="python"
        ["Gemfile"]="ruby"
        ["composer.json"]="php"
        ["pom.xml"]="java"
        ["build.gradle"]="java"
        ["Dockerfile"]="docker"
        ["docker-compose.yml"]="docker"
        [".env"]="dotenv"
    )

    local detected_envs=()
    local current_dir="$PWD"

    # Check current and parent directories for development indicators
    while [[ "$current_dir" != "/" ]]; do
        for indicator in "${(@k)dev_indicators}"; do
            if [[ -e "$current_dir/$indicator" ]]; then
                local env_type="${dev_indicators[$indicator]}"
                if [[ ! " ${detected_envs[*]} " =~ " $env_type " ]]; then
                    detected_envs+=("$env_type")
                fi
            fi
        done
        current_dir="${current_dir%/*}"
        [[ "$current_dir" == "" ]] && break
    done

    if [[ ${#detected_envs[@]} -gt 0 ]]; then
        export DEV_ENV_DETECTED="${(j:,:)detected_envs}"
        zf::debug "[DEV-INTEGRATIONS] Detected development environments: $DEV_ENV_DETECTED"
    else
        unset DEV_ENV_DETECTED
    fi
}

# Run development environment detection (lightweight) using zf:: namespace
export DEV_ENV_DETECTED="$(zf::dev_detect_env)"
if [[ -n "$DEV_ENV_DETECTED" ]]; then
    zf::debug "[DEV-INTEGRATIONS] Detected development environments: $DEV_ENV_DETECTED"
fi

# ==============================================================================
# SECTION 5: DOCKER INTEGRATION
# ==============================================================================

# Docker environment setup
if command -v docker >/dev/null 2>&1; then
    # Docker performance settings
    export DOCKER_BUILDKIT="${DOCKER_BUILDKIT:-1}"
    export COMPOSE_DOCKER_CLI_BUILD="${COMPOSE_DOCKER_CLI_BUILD:-1}"

    zf::debug "[DEV-INTEGRATIONS] Docker environment configured"
fi

# Docker Compose integration
if command -v docker-compose >/dev/null 2>&1 || command -v docker >/dev/null 2>&1; then
    # Prefer `docker compose` (newer) over `docker-compose` (legacy)
    if docker compose version >/dev/null 2>&1; then
        alias dc='docker compose'
        alias dcu='docker compose up'
        alias dcd='docker compose down'
        alias dcl='docker compose logs'
        zf::debug "[DEV-INTEGRATIONS] Docker Compose (modern) aliases configured"
    elif command -v docker-compose >/dev/null 2>&1; then
        alias dc='docker-compose'
        alias dcu='docker-compose up'
        alias dcd='docker-compose down'
        alias dcl='docker-compose logs'
        zf::debug "[DEV-INTEGRATIONS] Docker Compose (legacy) aliases configured"
    fi
fi

# ==============================================================================
# SECTION 6: KUBERNETES INTEGRATION
# ==============================================================================

# Kubernetes tools integration
if command -v kubectl >/dev/null 2>&1; then
    # kubectl aliases moved to post-plugin to prevent conflicts with plugin loading
    # All kubectl aliases (including k, kg, kd, ka, kdel) will be set post-plugin
    export ZSH_KUBECTL_AVAILABLE=1

    # kubectl completion (lazy loaded)
    _load_kubectl_completion() {
        if command -v kubectl >/dev/null 2>&1; then
            source <(kubectl completion zsh)
            zf::debug "[DEV-INTEGRATIONS] kubectl completion loaded"
        fi
    }

    if command -v lazy_register >/dev/null 2>&1; then
        lazy_register kubectl-completion _load_kubectl_completion
    fi

    zf::debug "[DEV-INTEGRATIONS] Kubernetes aliases configured"
fi

# ==============================================================================
# SECTION 7: CLOUD PROVIDER CLI INTEGRATIONS
# ==============================================================================

# AWS CLI integration
if command -v aws >/dev/null 2>&1; then
    # AWS CLI completion (lazy loaded)
    _load_aws_completion() {
        if command -v aws_completer >/dev/null 2>&1; then
            complete -C aws_completer aws
            zf::debug "[DEV-INTEGRATIONS] AWS CLI completion loaded"
        fi
    }

    if command -v lazy_register >/dev/null 2>&1; then
        lazy_register aws-completion _load_aws_completion
    fi
fi

# Google Cloud SDK integration
if [[ -d "$HOME/google-cloud-sdk" ]]; then
    # Add gcloud to PATH if not already present
    if [[ ":$PATH:" != *":$HOME/google-cloud-sdk/bin:"* ]]; then
        export PATH="$PATH:$HOME/google-cloud-sdk/bin"
        zf::debug "[DEV-INTEGRATIONS] Added Google Cloud SDK to PATH"
    fi
fi

# ==============================================================================
# SECTION 8: VERSION MANAGERS INTEGRATION
# ==============================================================================

# pyenv integration
if command -v pyenv >/dev/null 2>&1; then
    _load_pyenv() {
        eval "$(pyenv init -)"
        if command -v pyenv-virtualenv-init >/dev/null 2>&1; then
            eval "$(pyenv virtualenv-init -)"
        fi
        zf::debug "[DEV-INTEGRATIONS] pyenv loaded"
    }

    if command -v lazy_register >/dev/null 2>&1; then
        lazy_register pyenv _load_pyenv
    fi
fi

# rbenv integration
if command -v rbenv >/dev/null 2>&1; then
    _load_rbenv() {
        eval "$(rbenv init -)"
        zf::debug "[DEV-INTEGRATIONS] rbenv loaded"
    }

    if command -v lazy_register >/dev/null 2>&1; then
        lazy_register rbenv _load_rbenv
    fi
fi

# ==============================================================================
# SECTION 9: EDITOR INTEGRATION
# ==============================================================================

# Enhanced editor detection and configuration
if [[ -z "${EDITOR:-}" ]]; then
    # Detect best available editor
    for editor in nvim vim code subl nano; do
        if command -v "$editor" >/dev/null 2>&1; then
            export EDITOR="$editor"
            export VISUAL="$editor"
            zf::debug "[DEV-INTEGRATIONS] Set EDITOR to: $editor"
            break
        fi
    done
fi

# VS Code integration
if command -v code >/dev/null 2>&1; then
    # VS Code helper aliases
    alias c='code .'
    alias code-insiders='code-insiders'
    zf::debug "[DEV-INTEGRATIONS] VS Code aliases configured"
fi

# ==============================================================================
# MODULE COMPLETION
# ==============================================================================

export DEV_INTEGRATIONS_VERSION="2.0.0"
export DEV_INTEGRATIONS_LOADED_AT="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'unknown')"

zf::debug "[DEV-INTEGRATIONS] Development integrations ready"

# ==============================================================================
# NAMESPACE MIGRATION COMPLETE
# ==============================================================================
# All functions migrated to zf:: namespace. Use zf::dev_* functions directly.

# Mark namespace migration complete
export _DEV_INTEGRATIONS_NAMESPACE_MIGRATED=1

# Legacy functions removed - using zf:: namespace directly

# ==============================================================================
# END OF DEVELOPMENT INTEGRATIONS MODULE
# ==============================================================================
