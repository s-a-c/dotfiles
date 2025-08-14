source "/Users/s-a-c/.local/share/sheldon/repos/github.com/romkatv/zsh-defer/zsh-defer.plugin.zsh"

zsh-defer source "/Users/s-a-c/.local/share/sheldon/repos/github.com/ael-code/zsh-colored-man-pages/colored-man-pages.plugin.zsh"
source "/Users/s-a-c/.local/share/sheldon/repos/github.com/zpm-zsh/colors/colors.plugin.zsh"

autoload -Uz add-zsh-hook
zsh-defer source "/Users/s-a-c/.local/share/sheldon/repos/github.com/hlissner/zsh-autopair/zsh-autopair.plugin.zsh"
add-zsh-hook preexec autopair-preexec
typeset -gA AUTOPAIR_PAIRS
#export AUTOPAIR_PAIRS+=('<' '>')
AUTOPAIR_PAIRS += (
  '<' '>' # HTML tags
  '(' ')' # Parentheses
  '[' ']' # Brackets
  '{' '}' # Braces
  '"' '"' # Double quotes
  "'" "'" # Single quotes
  '`' '`' # Backticks
)
zsh-defer source "/Users/s-a-c/.local/share/sheldon/repos/github.com/chriskempson/base16-shell/base16-shell.plugin.zsh"
zsh-defer source "/Users/s-a-c/.local/share/sheldon/repos/github.com/b4b4r07/enhancd/init.sh"
zsh-defer source "/Users/s-a-c/.local/share/sheldon/repos/github.com/zdharma-continuum/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
autoload -Uz add-zsh-hook
zsh-defer source "/Users/s-a-c/.local/share/sheldon/repos/github.com/Aloxaf/fzf-tab/fzf-tab.plugin.zsh"
add-zsh-hook precmd fzf-tab-precmd
add-zsh-hook zle-line-init fzf-tab-line-init
add-zsh-hook zle-keymap-select fzf-tab-keymap-select
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
# NOTE: don't use escape sequences (like '%F{red}%d%f') here, fzf-tab will ignore them
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# custom fzf flags
# NOTE: fzf-tab does not follow FZF_DEFAULT_OPTS by default
#zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept
# To make fzf-tab follow FZF_DEFAULT_OPTS.
# NOTE: This may lead to unexpected behavior since some flags break this plugin. See Aloxaf/fzf-tab#455.
zstyle ':fzf-tab:*' use-fzf-default-opts yes
# switch group using `<` and `>`
#zstyle ':fzf-tab:*' switch-group '<' '>'
autoload -Uz add-zsh-hook
zsh-defer source "/Users/s-a-c/.local/share/sheldon/repos/github.com/unixorn/fzf-zsh-plugin/fzf-zsh-plugin.plugin.zsh"
add-zsh-hook precmd fzf-zsh-precmd
add-zsh-hook zle-line-init fzf-zsh-line-init
add-zsh-hook zle-keymap-select fzf-zsh-keymap-select
zsh-defer source "/Users/s-a-c/.local/share/sheldon/repos/github.com/agkozak/zhooks/zhooks.plugin.zsh"
zsh-defer source "/Users/s-a-c/.local/share/sheldon/repos/github.com/olets/zsh-abbr/zsh-abbr.plugin.zsh"
source "/Users/s-a-c/.local/share/sheldon/repos/github.com/mafredri/zsh-async/async.plugin.zsh"

zsh-defer source "/Users/s-a-c/.local/share/sheldon/repos/github.com/marlonrichert/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
zsh-defer source "/Users/s-a-c/.local/share/sheldon/repos/github.com/zsh-users/zsh-autosuggestions/zsh-autosuggestions.zsh"
zsh-defer source "/Users/s-a-c/.local/share/sheldon/repos/github.com/olets/zsh-autosuggestions-abbreviations-strategy/zsh-autosuggestions-abbreviations-strategy.plugin.zsh"
zsh-defer source "/Users/s-a-c/.local/share/sheldon/repos/github.com/zsh-users/zsh-completions/zsh-completions.plugin.zsh"
zsh-defer source "/Users/s-a-c/.local/share/sheldon/repos/github.com/zpm-zsh/history-search-multi-word/history-search-multi-word.plugin.zsh"
zsh-defer source "/Users/s-a-c/.local/share/sheldon/repos/github.com/zsh-users/zsh-history-substring-search/zsh-history-substring-search.plugin.zsh"
zsh-defer source "/Users/s-a-c/.local/share/sheldon/repos/github.com/zsh-hooks/zsh-hooks/zsh-hooks.plugin.zsh"
zsh-defer source "/Users/s-a-c/.local/share/sheldon/repos/github.com/psprint/zsh-navigation-tools/zsh-navigation-tools.plugin.zsh"
zsh-defer source "/Users/s-a-c/.local/share/sheldon/repos/github.com/chisui/zsh-nix-shell/nix-shell.plugin.zsh"
zsh-defer source "/Users/s-a-c/.local/share/sheldon/repos/github.com/MichaelAquilina/zsh-you-should-use/zsh-you-should-use.plugin.zsh"
zsh-defer source "/Users/s-a-c/.local/share/sheldon/repos/github.com/z-shell/zsh-zoxide/zsh-zoxide.plugin.zsh"
