# ZSH Configuration Feature Catalog

## Table of Contents

<details>
<summary>Click to expand</summary>


</details>

---


---


**Date:** 2025-10-11

This document provides a comprehensive catalog of the features and functionality of the zsh configuration, presented in a tabular format.

| Feature Area | Feature / Tool | Provided By | Configuration File(s) | Load Phase |
| :--- | :--- | :--- | :--- | :--- |
| **Core** | **Plugin Management** | `zgenom` | `.zshrc` (loads `.zgen-setup`) | Plugin |
| | **Modular Loading** | Shell Script | `.zshenv`, `.zshrc` | Pre/Post-plugin |
| | **Performance Monitoring** | Shell Script | `.zshenv`, `.zshrc.pre-plugins.d.00/050-segment-management.zsh` | Pre-plugin |
| | **Security (nounset)** | Shell Script | `.zshrc.pre-plugins.d.00/010-shell-safety-nounset.zsh` | Pre-plugin |
| | **XDG Compliance** | Shell Script | `.zshenv`, `.zshrc.pre-plugins.d.00/020-xdg-extensions.zsh` | Pre-plugin |
| | **Debug Logging** | Shell Script | `.zshenv` | Pre-plugin |
| | **Log Rotation** | Shell Script | `.zshrc.pre-plugins.d.00/040-log-rotation.zsh` | Pre-plugin |
| **Prompt** | **Starship** | Plugin: `starship/starship` | `.zshrc.d.00/520-prompt-starship.zsh` | Post-plugin |
| | **Powerlevel10k** | Plugin: `romkatv/powerlevel10k` | `.p10k.zsh`, `.zshrc` | Plugin/Post-plugin |
| **Completions**| **zsh-completions** | Plugin: `zsh-users/zsh-completions` | `.zshrc.add-plugins.d.00/200-perf-core.zsh` | Plugin |
| | **fzf-tab** | Plugin: `Aloxaf/fzf-tab` | `.zshrc.add-plugins.d.00/270-productivity-fzf.zsh` | Plugin |
| | **Carapace** | Plugin: `rsteube/carapace-bin` | `.zshrc.add-plugins.d.00/200-perf-core.zsh` | Plugin |
| | **Bun Completions** | Shell Script | `.zshrc` | Post-plugin |
| | **Styling** | Shell Script | `.zshrc.d.00/420-completion-styles.zsh` | Post-plugin |
| **Development**| **Herd (PHP)** | Shell Script | `.zshrc` | Post-plugin |
| | **NVM (Node.js)** | Plugin: `lukechilds/zsh-nvm` | `.zshenv`, `.zshrc.add-plugins.d.00/220-dev-node.zsh`, `.zshrc.d.00/510-nvm-post-augmentation.zsh` | Pre/Post-plugin |
| | **UV (Python)** | Plugin: `williamboman/uv.zsh` | `.zshrc.add-plugins.d.00/240-dev-python-uv.zsh` | Plugin |
| | **Bun (JavaScript)** | Shell Script | `.zshrc` | Post-plugin |
| | **GitHub CLI** | Plugin: `cli/cli` | `.zshrc.add-plugins.d.00/250-dev-github.zsh` | Plugin |
| | **CodeQL** | Shell Script | `.zshrc.pre-plugins.d.00/080-dev-codeql.zsh` | Pre-plugin |
| | **Neovim Helpers** | Shell Script | `.zshrc.d.00/430-neovim-environment.zsh`, `.zshrc.d.00/450-neovim-helpers.zsh` | Post-plugin |
| **Productivity**| **fzf** | Plugin: `junegunn/fzf` | `.zshrc.add-plugins.d.00/270-productivity-fzf.zsh`, `.zshrc.d.00/500-fzf.zsh` | Plugin/Post-plugin |
| | **zsh-z (zoxide-like)** | Plugin: `agkozak/zsh-z` | `.zshrc.add-plugins.d.00/260-productivity-nav.zsh` | Plugin |
| | **zsh-abbr** | Plugin: `olets/zsh-abbr` | `.zshrc.add-plugins.d.00/290-abbr.zsh` | Plugin |
| | **Brew Abbreviations** | Plugin: `g-plane/zsh-yarn-autocompletions` | `.zshrc.add-plugins.d.00/300-brew-abbr.zsh` | Plugin |
| | **Autopair** | Plugin: `hlissner/zsh-autopair` | `.zshrc.add-plugins.d.00/280-autopair.zsh` | Plugin |
| | **Forgit (fzf git)** | Plugin: `wfxr/forgit` | `.zshrc.add-plugins.d.00/270-productivity-fzf.zsh` | Plugin |
| **Shell UX** | **Autosuggestions** | Plugin: `zsh-users/zsh-autosuggestions` | `.zshrc.add-plugins.d.00/200-perf-core.zsh` | Plugin |
| | **Syntax Highlighting**| Plugin: `zsh-users/zsh-syntax-highlighting`| `.zshrc.add-plugins.d.00/200-perf-core.zsh` | Plugin |
| | **History Substring Search**| Plugin: `zsh-users/zsh-history-substring-search`| `.zshrc.add-plugins.d.00/200-perf-core.zsh` | Plugin |
| | **Consolidated Aliases** | Shell Script | `.zshrc.d.00/530-user-interface.zsh` | Post-plugin |
| | **Consolidated Keybindings**| Shell Script | `.zshrc.d.00/530-user-interface.zsh` | Post-plugin |
| | **Terminal Integration** | Shell Script | `.zshrc.d.00/460-terminal-integration.zsh` | Post-plugin |
| | **Shell History** | Shell Script | `.zshenv`, `.zshrc.d.00/480-shell-history.zsh` | Pre/Post-plugin |
| | **Navigation Helpers** | Shell Script | `.zshrc.d.00/490-navigation.zsh` | Post-plugin |

---

**Navigation:** [Top ↑](#zsh-configuration-feature-catalog)

---

*Last updated: 2025-10-13*
