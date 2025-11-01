# Environment Variables Reference

**Complete Variable Catalog** | **70+ Configuration Options**

---

## 📋 Variable Categories

<details>
<summary>Expand Table of Contents</summary>

- [Visual & Splash Variables](#visual--splash-variables)
- [Health & Instrumentation](#health--instrumentation)
- [Debug & Diagnostics](#debug--diagnostics)
- [Security & Integrity](#security--integrity)
- [Plugin & Environment Management](#plugin--environment-management)
- [Path & Cleanup](#path--cleanup)
- [XDG Base Directories](#xdg-base-directories)
- [Terminal Detection](#terminal-detection)
- [System Paths](#system-paths)

</details>

---

## 🎨 Visual & Splash Variables

| Variable | Type | Default | Purpose |
|----------|------|---------|---------|
| `ZSH_DISABLE_SPLASH` | 0\|1 | `0` | Disable splash screen entirely |
| `FORCE_SPLASH` | 0\|1 | `1` | Force splash even in minimal mode |
| `ZSH_MINIMAL` | 0\|1 | `0` | Minimal visual/interactive footprint |
| `ZSH_DISABLE_FASTFETCH` | 0\|1 | `0` | Disable fastfetch banner |
| `ZSH_DISABLE_COLORSCRIPT` | 0\|1 | `0` | Disable colorscript |
| `ZSH_DISABLE_LOLCAT` | 0\|1 | `0` | Disable lolcat style colorization |
| `ZSH_DISABLE_STARSHIP` | 0\|1 | `0` | Disable Starship prompt |
| `ZSH_DISABLE_TIPS` | 0\|1 | `0` | Disable tips/help panels |

**Examples**:

```bash

# Disable splash for this session

ZSH_DISABLE_SPLASH=1 zsh

# Permanent disable (in .zshenv.local)

export ZSH_DISABLE_SPLASH=1

```

---

## 📊 Health & Instrumentation

| Variable | Type | Default | Purpose |
|----------|------|---------|---------|
| `ZSH_ENABLE_HEALTH_CHECK` | 0\|1 | `0` | Enable health summary logic |
| `ZSH_PERF_TRACK` | 0\|1 | `0` | Enable performance segment tracking |
| `PERF_SEGMENT_LOG` | path | unset | Explicit perf log path |
| `PERF_SEGMENT_TRACE` | 0\|1 | `0` | Verbose segment trace markers |
| `PERF_CAPTURE_FAST` | 0\|1 | `0` | Use reduced capture path |
| `ZF_WITH_TIMING_EMIT` | auto\|0\|1 | `auto` | Emit high level timing summary |
| `PERF_HARNESS_MINIMAL` | 0\|1 | `0` | Minimal harness instrumentation mode |
| `PERF_HARNESS_TIMEOUT_SEC` | int | `0` | Watchdog timeout (disabled) |

**Examples**:

```bash

# Enable detailed performance tracking

export ZSH_PERF_TRACK=1
export PERF_SEGMENT_LOG=~/zsh-perf.log
export PERF_SEGMENT_TRACE=1

# Start shell and review

zsh
cat ~/zsh-perf.log

```

---

## 🔍 Debug & Diagnostics

| Variable | Type | Default | Purpose |
|----------|------|---------|---------|
| `ZSH_DEBUG` | 0\|1 | `0` | Enable early debug logging |
| `ZSH_FORCE_XTRACE` | 0\|1 | `0` | Allow xtrace if already active |
| `ZSH_DEBUG_KEEP_DEBUG` | 0\|1 | `0` | Preserve $DEBUG var when debugging |
| `ZSH_DEBUG_PS4_FORMAT` | string | unset | Custom PS4 when debug active |
| `DEBUG_ZSH_REDESIGN` | 0\|1 | `0` | Additional redesign oriented logs |

**Examples**:

```bash

# Full debug mode

export ZSH_DEBUG=1
export ZSH_FORCE_XTRACE=1
zsh -x

```

---

## 🔒 Security & Integrity

| Variable | Type | Default | Purpose |
|----------|------|---------|---------|
| `ZSH_SEC_DISABLE_AUTO_DEDUP` | 0\|1 | `0` | Disable auto PATH dedupe attempts |
| `ZSH_INTERACTIVE_OPTIONS_STRICT` | 0\|1 | `0` | Enforce stricter interactive opts |
| `_ZQS_NOUNSET_WAS_ON` | 0\|1 | - | Internal: Track nounset state |
| `_ZQS_NOUNSET_DISABLED_FOR_OMZ` | 0\|1 | - | Internal: Nounset disabled for plugins |

---

## 🔌 Plugin & Environment Management

| Variable | Type | Default | Purpose |
|----------|------|---------|---------|
| `ZSH_ENABLE_ABBR` | 0\|1 | `1` | Enable abbreviation subsystem |
| `ZSH_AUTOSUGGEST_SSH_DISABLE` | 0\|1 | `0` | Disable autosuggest inside SSH |
| `ZSH_ENABLE_NVM_PLUGINS` | 0\|1 | `1` | Enable NVM related plugin path logic |
| `ZSH_NODE_LAZY` | 0\|1 | `1` | Lazy node version/path activation |
| `ZGEN_AUTOLOAD_COMPINIT` | 0\|1 | `0` | Auto run compinit (0 = manual control) |
| `ZF_DISABLE_AUTO_UPDATES` | 0\|1 | `1` | Disable auto-updates for frameworks |
| `ZQS_COMPAT` | 0\|1 | `0` | Enable quickstart compatibility shims |

---

## 🛣️ Path & Cleanup

| Variable | Type | Default | Purpose |
|----------|------|---------|---------|
| `PATH_CLEANUP` | 0\|1 | `1` | Enable PATH normalization |
| `ZDOTDIR` | path | `~/.config/zsh` | ZSH configuration directory |
| `ZSH_CACHE_DIR` | path | `$ZDOTDIR/.cache` | Cache directory |
| `ZSH_LOG_DIR` | path | `$XDG_STATE_HOME/zsh/logs` | Log directory |

---

## 📁 XDG Base Directories

| Variable | Default | Purpose |
|----------|---------|---------|
| `XDG_CONFIG_HOME` | `~/.config` | User configuration files |
| `XDG_DATA_HOME` | `~/.local/share` | User data files |
| `XDG_CACHE_HOME` | `~/.cache` | User cache files |
| `XDG_STATE_HOME` | `~/.local/state` | User state files |
| `XDG_BIN_HOME` | `~/.local/bin` | User executables (extended) |

---

## 💻 Terminal Detection

| Variable | Set By | Possible Values |
|----------|--------|-----------------|
| `TERM_PROGRAM` | `.zshenv.01` | `Alacritty`, `Apple_Terminal`, `iTerm.app`, `ghostty`, `WezTerm`, `kitty`, `warp` |
| `TERM` | System | `xterm-256color`, `screen-256color`, etc. |

**Usage**:

```bash

# Check current terminal

echo $TERM_PROGRAM

# Conditional based on terminal

if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
    # iTerm2-specific config
fi

```

---

## 🎯 Starship-Specific

| Variable | Purpose |
|----------|---------|
| `STARSHIP_CONFIG` | Path to starship.toml configuration |
| `STARSHIP_CMD_STATUS` | Last command status (for prompt) |
| `STARSHIP_PIPE_STATUS` | Pipeline status (for prompt) |
| `ZSH_STARSHIP_SUPPRESS_AUTOINIT` | Suppress auto-initialization |
| `POWERLEVEL10K_DISABLE_CONFIGURATION_WIZARD` | Disable P10k wizard (Starship-first) |

---

## 🔧 Developer-Specific

| Variable | Purpose | Set By |
|----------|---------|--------|
| `NVM_DIR` | Node Version Manager directory | nvm plugin |
| `PHP_HERD_HOME` | Herd PHP installation | herd plugin |
| `PYTHONUSERBASE` | Python user packages | Python config |
| `CARGO_HOME` | Rust cargo directory | Rust config |
| `GOPATH` | Go workspace | Go config |

---

**Navigation:** [← Reference Index](000-index.md) | [Top ↑](#environment-variables) | [Helper Functions →](020-helper-functions.md)

---

*Compliant with AI-GUIDELINES.md (v1.0 2025-10-30)*
