# Reference Documentation Index

**Quick Lookup & API Reference** | **All Levels**

---

## 📚 Reference Collection

| Document | Description |
|----------|-------------|
| [010-environment-variables.md](010-environment-variables.md) | Complete environment variable reference (70+ vars) |
| [020-helper-functions.md](020-helper-functions.md) | Core helper functions API (`zf::*` namespace) |
| [030-available-plugins.md](030-available-plugins.md) | Plugin catalog with descriptions |
| [040-tool-scripts.md](040-tool-scripts.md) | Utility scripts reference (`bin/`, `tools/`) |

---

## 🎯 Quick Lookup

### Common Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `ZDOTDIR` | ZSH config directory | `~/.config/zsh` |
| `ZSH_DISABLE_SPLASH` | Disable splash screen | `0` |
| `ZSH_PERF_TRACK` | Enable performance tracking | `0` |
| `ZSH_DEBUG` | Debug mode | `0` |

### Common Helper Functions

| Function | Purpose |
|----------|---------|
| `zf::path_prepend` | Safely add to beginning of PATH |
| `zf::debug` | Conditional debug logging |
| `zf::segment` | Performance tracking |
| `zf::has_command` | Check command availability |

### Common Commands

| Command | Purpose |
|---------|---------|
| `zsh-healthcheck` | Run system health check |
| `zsh-performance-baseline` | Show performance metrics |
| `zgenom list` | List loaded plugins |
| `zgenom reset` | Rebuild plugin cache |

---

**Navigation:** [← Troubleshooting](../130-troubleshooting.md) | [Top ↑](#reference-index) | [Environment Variables →](010-environment-variables.md)

---

*Compliant with AI-GUIDELINES.md (v1.0 2025-10-30)*
