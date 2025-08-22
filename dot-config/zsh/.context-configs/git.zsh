#!/opt/homebrew/bin/zsh
# Context-Aware Configuration: Git Repositories
# Automatically loaded when entering Git repository directories

# Set Git project environment
export PROJECT_TYPE="git"

# Get repository information
if command -v git >/dev/null 2>&1; then
    export GIT_REPO_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "unknown")
    export GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    export GIT_REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "none")
fi

# Enhanced Git aliases for repository context
alias gs="git status"
alias ga="git add"
alias gaa="git add ."
alias gc="git commit"
alias gcm="git commit -m"
alias gca="git commit --amend"
alias gp="git push"
alias gpl="git pull"
alias gf="git fetch"
alias gb="git branch"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gm="git merge"
alias gr="git rebase"
alias gl="git log --oneline -10"
alias gd="git diff"
alias gdc="git diff --cached"
alias gst="git stash"
alias gstp="git stash pop"

# Repository-specific shortcuts
alias root="cd \$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
alias main="git checkout \$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo 'main')"

# Branch management
alias branches="git branch -a"
alias clean-branches="git branch --merged | grep -v '\\*\\|main\\|master\\|develop' | xargs -n 1 git branch -d"

# Commit helpers
alias amend="git commit --amend --no-edit"
alias fixup="git commit --fixup"
alias wip="git add . && git commit -m 'WIP: work in progress'"
alias unwip="git reset HEAD~1"

# Log and history
alias history="git log --oneline --graph --decorate --all -20"
alias contributors="git shortlog -sn"
alias changes="git log --oneline --since='1 week ago'"

# Diff and show
alias show="git show"
alias blame="git blame"
alias conflicts="git diff --name-only --diff-filter=U"

# Remote operations
alias sync="git fetch --all && git pull"
alias push-force="git push --force-with-lease"

# Working directory status
alias modified="git ls-files -m"
alias untracked="git ls-files --others --exclude-standard"
alias ignored="git ls-files --ignored --exclude-standard"

echo "📁 Git context loaded (repo: ${GIT_REPO_NAME:-unknown}, branch: ${GIT_BRANCH:-unknown})"
