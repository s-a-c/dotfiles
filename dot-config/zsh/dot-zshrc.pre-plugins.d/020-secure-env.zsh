# Secure Environment Variables Configuration
# This file replaces ~/.config/.zshenv.zsh with secure credential management
#
# SECURITY NOTICE: The original file contained exposed API keys
# This implementation uses environment files and proper security practices

[[ -n "$ZSH_DEBUG" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
    # Add this check to detect errant file creation:
    if [[ -f "${ZDOTDIR:-$HOME}/2" ]] || [[ -f "${ZDOTDIR:-$HOME}/3" ]]; then
        echo "Warning: Numbered files detected - check for redirection typos" >&2
    fi
}

# Function to securely load environment variables from a file
load_env_file() {
    local env_file="$1"
    if [[ -r "$env_file" ]]; then
        # Only export variables that aren't already set
        local key value
        while IFS='=' read -r key value; do
            # Skip comments, empty lines, and JSON content
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            [[ "$key" =~ ^[[:space:]]*[\{\}\[\],] ]] && continue
            [[ "$key" =~ [\":\{\}] ]] && continue

            # Skip lines that don't contain '=' (not KEY=VALUE format)
            [[ "$key" != *"="* ]] && continue

            # Remove quotes from value if present
            value=${value//\"/}
            value=${value//\'/}

            # Validate key format (alphanumeric and underscore only)
            [[ ! "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] && continue

            # Export if not already set and value is not empty
            if [[ -z "${(P)key}" && -n "$value" ]]; then
                export "$key"="$value"
            fi
        done < "$env_file"
    fi
}

# Load environment variables from secure files
# These files should be created manually and added to .gitignore
local ENV_DIR="${ZDOTDIR:-${HOME}/.config/zsh}/.env"

# Create .env directory if it doesn't exist
[[ ! -d "$ENV_DIR" ]] && mkdir -p "$ENV_DIR"

# Load API keys from separate files (create these manually)
load_env_file "${ENV_DIR}/api-keys.env"
load_env_file "${ENV_DIR}/development.env"
load_env_file "${ENV_DIR}/local.env"

# Declare expected environment variables for type safety
# This prevents typos and documents what variables are expected
typeset -x \
    ANTHROPIC_API_KEY \
    ATLASSIAN_API_KEY \
    DEVSENSE_PHP_LS_LICENSE \
    FLUXUI_PRO_KEY \
    GEMINI_API_KEY \
    GH_TOKEN \
    GH_TOKEN_DB4RNR \
    GH_TOKEN_S_A_C \
    GITHUB_TOKEN \
    GOOGLE_AI_API_KEY \
    GROQ_API_KEY \
    LM_STUDIO_API_BASE \
    LM_STUDIO_API_KEY \
    OPENAI_API_KEY \
    OPENROUTER_API_KEY \
    QDRANT_GCP_SAC \
    SEMGREP_APP_TOKEN \
    SPATIE_COMMENT_KEY \
    TAVILY_API_KEY \
    TURSO_AUTH_TOKEN \
    WORKOS_API_KEY \
    WORKOS_CLIENT_ID

# Set defaults for local development
export LM_STUDIO_API_KEY="${LM_STUDIO_API_KEY:-dummy-api-key}"
export LM_STUDIO_API_BASE="${LM_STUDIO_API_BASE:-http://localhost:1234/v1}"

# Clean up function
unset -f load_env_file
unset ENV_DIR

# Instructions for setting up secure environment files:
#
# 1. Create the following files in ~/.config/zsh/.env/:
#    - api-keys.env (for API keys)
#    - development.env (for development settings)
#    - local.env (for local overrides)
#
# 2. Add your credentials in KEY=VALUE format:
#    OPENAI_API_KEY=sk-your-key-here
#    GITHUB_TOKEN=ghp_your-token-here
#
# 3. Secure the files:
#    chmod 600 ~/.config/zsh/.env/*.env
#
# 4. Add to .gitignore:
#    echo "/.env/" >> ~/.config/zsh/.gitignore
#
# 5. For team sharing, create template files:
#    api-keys.env.template with empty values
