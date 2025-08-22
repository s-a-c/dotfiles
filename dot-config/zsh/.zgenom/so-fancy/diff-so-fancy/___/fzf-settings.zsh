# FZF settings for diff-so-fancy plugin
# This file is used by the diff-so-fancy plugin to set up FZF

# Check if FZF is installed
if command -v fzf > /dev/null 2>&1; then
  export FZF_DEFAULT_OPTS="--ansi --preview-window 'right:60%' --layout reverse --margin=1,4"
  
  # Add diff-so-fancy as a preview command for git diffs when available
  if command -v diff-so-fancy > /dev/null 2>&1; then
    export FZF_DIFF_PREVIEW_COMMAND="git diff --color=always -- {} | diff-so-fancy"
  fi
fi
