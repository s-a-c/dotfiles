#!/usr/bin/env zsh
# Git and VCS Configuration - POST-PLUGIN PHASE
# Git-specific configurations and integrations from refactored zsh setup
# This file consolidates Git, diff tools, and version control configurations

[[ "$ZSH_DEBUG" == "1" ]] && {
        zf::debug "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
    zf::debug "# [git-config] Setting up Git and VCS configurations"
}

## [git.diff-so-fancy] - Enhanced Git diff output
{
    zf::debug "# [git.diff-so-fancy]"

    # Configure git to use diff-so-fancy for all diff output
    if command -v diff-so-fancy >/dev/null 2>&1; then
        git config --global core.pager "diff-so-fancy | less --tabs=4 -RF" 2>/dev/null || true
        git config --global interactive.diffFilter "diff-so-fancy --patch" 2>/dev/null || true

        # Improved colors for diff-so-fancy
        git config --global color.ui true 2>/dev/null || true
        git config --global color.diff-highlight.oldNormal "red bold" 2>/dev/null || true
        git config --global color.diff-highlight.oldHighlight "red bold 52" 2>/dev/null || true
        git config --global color.diff-highlight.newNormal "green bold" 2>/dev/null || true
        git config --global color.diff-highlight.newHighlight "green bold 22" 2>/dev/null || true
        git config --global color.diff.meta "11" 2>/dev/null || true
        git config --global color.diff.frag "magenta bold" 2>/dev/null || true
        git config --global color.diff.func "146 bold" 2>/dev/null || true
        git config --global color.diff.commit "yellow bold" 2>/dev/null || true
        git config --global color.diff.old "red bold" 2>/dev/null || true
        git config --global color.diff.new "green bold" 2>/dev/null || true
        git config --global color.diff.whitespace "red reverse" 2>/dev/null || true

        zf::debug "# [git.diff-so-fancy] Configured diff-so-fancy"
    else
        zf::debug "# [git.diff-so-fancy] diff-so-fancy not found, skipping"
    fi
}

## [git.aliases] - Useful Git aliases
{
    zf::debug "# [git.aliases]"

    # Only set aliases if git is available
    if command -v git >/dev/null 2>&1; then
        # Log aliases
        git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit" 2>/dev/null || true
        git config --global alias.lga "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --all" 2>/dev/null || true

        # Status aliases
        git config --global alias.st "status --short --branch" 2>/dev/null || true
        git config --global alias.ss "status" 2>/dev/null || true

        # Branch aliases
        git config --global alias.br "branch" 2>/dev/null || true
        git config --global alias.co "checkout" 2>/dev/null || true
        git config --global alias.cb "checkout -b" 2>/dev/null || true

        # Commit aliases
        git config --global alias.ci "commit" 2>/dev/null || true
        git config --global alias.ca "commit --amend" 2>/dev/null || true
        git config --global alias.cm "commit -m" 2>/dev/null || true

        # Diff aliases
        git config --global alias.df "diff" 2>/dev/null || true
        git config --global alias.dc "diff --cached" 2>/dev/null || true

        # Push/pull aliases
        git config --global alias.ps "push" 2>/dev/null || true
        git config --global alias.pl "pull" 2>/dev/null || true
        git config --global alias.pf "push --force-with-lease" 2>/dev/null || true

        # Stash aliases
        git config --global alias.sl "stash list" 2>/dev/null || true
        git config --global alias.sa "stash apply" 2>/dev/null || true
        git config --global alias.ss "stash save" 2>/dev/null || true

        zf::debug "# [git.aliases] Git aliases configured"
    fi
}

## [git.configuration] - Core Git configuration
{
    zf::debug "# [git.configuration]"

    if command -v git >/dev/null 2>&1; then
        # Core settings
        git config --global init.defaultBranch main 2>/dev/null || true
        git config --global pull.rebase false 2>/dev/null || true
        git config --global push.default simple 2>/dev/null || true
        git config --global core.autocrlf input 2>/dev/null || true
        git config --global core.safecrlf true 2>/dev/null || true

        # Performance settings
        git config --global core.preloadindex true 2>/dev/null || true
        git config --global core.fscache true 2>/dev/null || true
        git config --global gc.auto 256 2>/dev/null || true

        # Editor and merge tool (use system defaults if not set)
        if [[ -z "$(git config --global --get core.editor)" ]]; then
            if command -v nvim >/dev/null 2>&1; then
                git config --global core.editor nvim 2>/dev/null || true
            elif command -v vim >/dev/null 2>&1; then
                git config --global core.editor vim 2>/dev/null || true
            fi
        fi

        zf::debug "# [git.configuration] Core Git settings applied"
    fi
}

## [git.hooks] - Git hook helpers
{
    zf::debug "# [git.hooks]"

    # Function to set up common Git hooks
    setup_git_hooks() {
        local repo_root
        repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"

        if [[ -z "$repo_root" ]]; then
            zf::debug "Error: Not in a Git repository"
            return 1
        fi

        local hooks_dir="$repo_root/.git/hooks"

        # Pre-commit hook template
        if [[ ! -f "$hooks_dir/pre-commit" ]]; then
            cat > "$hooks_dir/pre-commit" << 'EOF'
#!/bin/sh
# Pre-commit hook

# Check for syntax errors
if command -v shellcheck >/dev/null 2>&1; then
    find . -name "*.sh" -exec shellcheck {} \;
fi

# Check for trailing whitespace
if git diff --check --cached; then
    zf::debug "Error: Trailing whitespace found"
    exit 1
fi
EOF
            chmod +x "$hooks_dir/pre-commit"
            zf::debug "Pre-commit hook installed"
        fi

        # Commit-msg hook template
        if [[ ! -f "$hooks_dir/commit-msg" ]]; then
            cat > "$hooks_dir/commit-msg" << 'EOF'
#!/bin/sh
# Commit message hook

# Check commit message length
commit_regex='^.{1,50}$'

if ! grep -qE "$commit_regex" "$1"; then
    zf::debug "Invalid commit message format"
    zf::debug "First line should be 50 characters or less"
    exit 1
fi
EOF
            chmod +x "$hooks_dir/commit-msg"
            zf::debug "Commit-msg hook installed"
        fi
    }
}

## [git.worktree] - Git worktree helpers
{
    zf::debug "# [git.worktree]"

    # Quick worktree creation
    git-worktree-create() {
        if [[ $# -lt 1 ]]; then
            zf::debug "Usage: gwt <branch-name> [path]"
            zf::debug "Creates a new git worktree for the given branch"
            return 1
        fi

        local branch="$1"
        local path="${2:-../$(basename $(pwd))-$branch}"

        git worktree add "$path" "$branch"
        zf::debug "Worktree created at: $path"
    }

    # List worktrees
    gwtl() {
        git worktree list
    }

    # Remove worktree
    gwtr() {
        if [[ $# -lt 1 ]]; then
            zf::debug "Usage: gwtr <path>"
            return 1
        fi
        git worktree remove "$1"
    }
}

## [git.integration] - Integration with other tools
{
    zf::debug "# [git.integration]"

    # GitHub CLI integration
    if command -v gh >/dev/null 2>&1; then
        # Quick PR creation
        # Commented out to avoid conflict with alias
        # gpr() {
        #     local title="${1:-$(git log -1 --pretty=%s)}"
        #     gh pr create --title "$title" --body "$(git log -1 --pretty=%B)"
        # }

        # Quick issue creation
        gissue() {
            if [[ -z "$1" ]]; then
                zf::debug "Usage: gissue <title> [body]"
                return 1
            fi
            gh issue create --title "$1" --body "${2:-}"
        }
    fi

    # Git + FZF integration
    if command -v fzf >/dev/null 2>&1; then
        # Interactive branch checkout
        gcob() {
            local branch
            branch=$(git branch --all | grep -v HEAD | sed 's/^[ *]*//' | sed 's/^remotes\///' | sort -u | fzf --prompt="Checkout branch: ")
            if [[ -n "$branch" ]]; then
                git checkout "$branch"
            fi
        }

        # Interactive commit browser
        glf() {
            git log --oneline --color=always | fzf --ansi --preview 'git show --color=always {1}' --preview-window=right:60%
        }
    fi
}

zf::debug "# [git-config] ✅ Git and VCS configurations applied"
