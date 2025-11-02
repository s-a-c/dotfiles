# dotfiles

**Compliant with** [AI-GUIDELINES.md](AI-GUIDELINES.md) | **AI Agent Instructions**: [AGENTS.md](AGENTS.md)

<details>
<summary>Expand Table of Contents</summary>

- [dotfiles](#dotfiles)
  - [1. Goal badges](#1-goal-badges)
    - [1.1. Badge legend](#11-badge-legend)
  - [2. Developer maintenance](#2-developer-maintenance)
    - [2.1. Makefile targets](#21-makefile-targets)
    - [2.2. Maintenance script](#22-maintenance-script)
    - [2.3. Notes](#23-notes)
  - [3. Overview](#3-overview)
    - [3.1. ZSH Performance \& Badge Refresh](#31-zsh-performance--badge-refresh)
  - [4. Status Badges](#4-status-badges)
  - [5. Git Submodules](#5-git-submodules)
    - [Submodule Management Commands](#submodule-management-commands)
  - [6. ZSH Redesign – Stage Dashboard](#6-zsh-redesign--stage-dashboard)
  - [7. Contents](#7-contents)
  - [8. Secret Management \& Scanning](#8-secret-management--scanning)
    - [8.1. Preventive Ignore Rules](#81-preventive-ignore-rules)
    - [8.2. CI Secret Scanning (`secretScan` workflow)](#82-ci-secret-scanning-secretscan-workflow)
    - [8.3. Local Pre-Commit Hook](#83-local-pre-commit-hook)
    - [8.4. Manual Local Scan Examples](#84-manual-local-scan-examples)
    - [8.5. History Rewrite (If Secrets Entered History)](#85-history-rewrite-if-secrets-entered-history)
    - [8.6. Redaction (Optional)](#86-redaction-optional)
  - [9. Development Workflow Notes](#9-development-workflow-notes)
  - [10. Extending Scanning](#10-extending-scanning)
  - [11. Contributing](#11-contributing)
  - [12. License](#12-license)
  - [13. Quick Reference Commands](#13-quick-reference-commands)
  - [14. AI Guidelines \& Orchestration Policy](#14-ai-guidelines--orchestration-policy)
    - [14.1. For AI Agents](#141-for-ai-agents)
    - [14.2. Key Principles](#142-key-principles)
    - [14.3. Guidelines Structure](#143-guidelines-structure)
  - [15. Acknowledgements](#15-acknowledgements)

</details>

---

## 1. Goal badges

The GOAL system exposes two shields.io endpoint badges that are published to gh-pages and auto-resolved in this README after the first publish:

- Goal-state (flat): https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/&lt;org&gt;/&lt;repo&gt;/gh-pages/badges/goal-state.json
- Summary-goal (compact): https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/&lt;org&gt;/&lt;repo&gt;/gh-pages/badges/summary-goal.json

These placeholders are automatically replaced with your real <org>/<repo> by CI after gh-pages has the badge files.

### 1.1. Badge legend

- Goal-state JSON fields:
  - governance: clean | warning | failing
  - ci: strict | lenient
  - streak: building | stable
  - explore: sandbox
- Summary-goal message format:
  - gov:<state> | ci:<state> | streak:<state> | explore:<state> [ | drift:<msg> | struct:<msg> ]
  - Suffixes are appended when supporting badges exist:
    - drift: taken from perf-drift badge message (e.g., 2 warn (+7.1% max))
    - struct: taken from structure badge message (e.g., 2 violations)
- Severity → color mapping (collapsed across all signals):
  - brightgreen: OK
  - blue: info/minor (e.g., lenient CI or building streak)
  - yellow: warning (e.g., governance warning or drift/structure warn)
  - red: failing (e.g., governance failing or drift/structure fail)
- Resilience:
  - If perf-drift.json or structure.json are missing, the summary-goal badge renders without suffixes and severity is not raised.

## 2. Developer maintenance

This repository includes a scoped pre-commit workflow and helper scripts to keep things tidy and fast.

- Scoped pre-commit config: `dot-config/zsh/zsh-quickstart-kit/.pre-commit-config.yaml`
  - Scope: only checks files under `dot-config/zsh`, `tools`, and `tests`.
- Heavy tests gating:
  - Local commits skip the zsh kit’s heavy unit/integration/security tests and quick perf run by default.
  - Set `ZSH_KIT_RUN_FULL_TESTS=1` (or run in CI) to enable them during pre-commit.

### 2.1. Makefile targets

Use these convenience targets from the repo root:

- `make precommit-install` — Install pre-commit hooks locally.
- `make precommit-run` — Run scoped pre-commit checks over all files.
- `make precommit-normalize` — Normalize executable bits to match shebangs, ensure newline at EOF, then run the scoped checks.
- `make broken-symlinks-list` — List all broken symlinks in the repository.
- `make broken-symlinks-remove` — Remove all broken symlinks that are tracked by git.
- `make perf-update` — Run N=5 fast-harness capture and update variance/governance/perf badges.
- `make fmt` — Alias for `precommit-normalize`.
- `make check` — Alias for `precommit-run`.

### 2.2. Maintenance script

- `tools/maintenance/normalize-exec-bits.sh`
  - Adds `+x` to files that begin with `#!` (shebang) and removes `+x` from files that don’t.
  - Updates both the working tree and the git index so pre-commit shebang checks pass consistently.
  - Example:
    - `tools/maintenance/normalize-exec-bits.sh` (default scope: `dot-config/zsh`, `tools`, `tests`)
    - `tools/maintenance/normalize-exec-bits.sh --dry-run` (preview only)

### 2.3. Notes

- CLI plugin directories (e.g., Docker) are ignored via `.gitignore` pattern: `**/cli-plugins/`
- To run pre-commit manually with the scoped config:
  - `pre-commit run --all-files -c dot-config/zsh/zsh-quickstart-kit/.pre-commit-config.yaml`

## 3. Overview

Personal dotfiles repository providing comprehensive management of the entire `~/.config` directory structure. Configurations for 60+ tools including ZSH, Neovim, Tmux, Emacs, Git, Docker, Kitty, Wezterm, Hammerspoon, Karabiner, and many more are managed through GNU Stow for symlink-based deployment.

**Active Development**: ZSH configuration redesign (Stage 3 of 7) with automated performance monitoring, variance guards, and comprehensive testing framework.

This repository follows the guidelines specified in [AI-GUIDELINES.md](AI-GUIDELINES.md). For AI agent instructions, see [AGENTS.md](AGENTS.md).

### 3.1. ZSH Performance & Badge Refresh

For ZSH configuration performance monitoring and badge updates:

- **Automated**: Badges are refreshed nightly via CI workflow
- **Manual refresh**: `make perf-update` (runs N=5 capture and updates all badges)
- **Direct script**: `cd dot-config/zsh && ZDOTDIR=$(pwd) tools/update-variance-and-badges.zsh`

If badges look stale, use the manual refresh command above. The variance guard is currently active with streak 3/3, maintaining performance stability monitoring.

## 4. Status Badges

(Generated by CI; JSON shield specs live under docs/badges/)

- Goal-state (flat): https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/&lt;org&gt;/&lt;repo&gt;/gh-pages/badges/goal-state.json
- Summary-goal (compact): https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/&lt;org&gt;/&lt;repo&gt;/gh-pages/badges/summary-goal.json

- Hooks: ![hooks status](https://s-a-c.github.io/dotfiles/badges/hooks.svg)
- Infra Health: ![infra health](https://s-a-c.github.io/dotfiles/badges/infra-health.svg)
  - Placeholder until infra-health badge generation script synthesizes perf + structure + hooks (planned).
  - Expected future states: green (all good), yellow (degradation), red (critical failure).
- Performance: ![performance](https://s-a-c.github.io/dotfiles/badges/perf.svg)
  - Green: Startup ≤10% delta vs baseline (currently 334ms)
  - Yellow: Startup >10% but ≤25% delta (investigation recommended)
  - Red: Startup >25% delta (CI failure in enforce mode)
- Structure: ![structure](https://s-a-c.github.io/dotfiles/badges/structure.svg)
- Security: ![security](https://s-a-c.github.io/dotfiles/badges/security.svg)

## 5. Git Submodules

This repository uses git submodules for external dependencies:

| Submodule | Path | Repository | Version/Branch | Purpose |
|-----------|------|------------|----------------|---------|
| **tmux-starter** | `dot-config/alexandersix/tmux-starter` | [alexandersix/tmux-starter](https://github.com/alexandersix/tmux-starter.git) | v0.2.1 | Tmux starter configuration |
| **nix-darwin** | `dot-config/nix-darwin` | [s-a-c/nix-darwin](https://github.com/s-a-c/nix-darwin.git) | main | Personal Nix-darwin configuration fork |
| **zsh-quickstart-kit** | `dot-config/zsh/zsh-quickstart-kit` | [unixorn/zsh-quickstart-kit](https://github.com/unixorn/zsh-quickstart-kit) | 1.0.1-382-g1b1f14b | ZSH framework with plugins and configuration |

### Submodule Management Commands

```bash
# Initialize and update all submodules
git submodule update --init --recursive

# Update submodules to latest upstream commits
git submodule update --remote

# Check submodule status
git submodule status --recursive
```

**Note**: `dot-config/ai` is defined in `.gitmodules` but is tracked as a symlink to an external Obsidian vault (`../../nc/Documents/notes/obsidian/s-a-c/ai`) rather than an initialized submodule.

## 6. ZSH Redesign – Stage Dashboard

| Stage | Name | Status | Tag | Key Metrics / Notes |
|-------|------|--------|-----|---------------------|
| 1 | Foundation | ✅ | refactor-stage1-complete | Structure + perf scaffolding established |
| 2 | Pre-Plugin Migration | ✅ | refactor-stage2-preplugin | Pre-plugin baseline: mean=35ms stdev=11ms (N=5) |
| 3 | Post-Plugin Core | ⏳ | (pending) | Planning security-integrity, interactive opts, core functions |
| 4–5 | Feature / UI & Async | (future) | — | Plugins, async scheduling, completion gating |
| 6–7 | Promotion / Archive | (future) | — | Promotion guard, archival policy |

Stage 2 complete: pre-plugin modules (00–30) finalized; baseline locked; pre-plugin regression guard tightened to +7% (target +5% after additional low-variance sample sets). Stage 3 will add security/option core, helper namespace (`zf::`), and verify/apply PATH append fix.

## 7. Contents

- Consolidated `.gitignore` tuned for multi-language/editor noise and secret/material exclusion
- Automated secret scanning GitHub Action (`.github/workflows/secret-scan.yml`)
- Local pre-commit secret scan hook (`.githooks/pre-commit.d/secret-scan`)
- History rewrite plan (`SECRET_HISTORY_REWRITE_PLAN.md`)
- Gitleaks baseline configuration (`.github/gitleaks.toml`)

## 8. Secret Management & Scanning

### 8.1. Preventive Ignore Rules

Any directory named `.env` (and common secret file extensions) are ignored:

```log
.env
.env.*
*.env
.env/
```

Plus explicit ignore for `dot-config/zsh/.env/` and typical key/cert/state files (e.g. `*.pem`, `terraform.tfstate*`, `*.tfvars`).

### 8.2. CI Secret Scanning (`secretScan` workflow)

Runs on:

- Pull Requests (opened, synchronize, reopen, ready_for_review)
- Pushes to `main` / `master`
- Manual dispatch

Uses `gitleaks` with baseline config at `.github/gitleaks.toml`.
Failure blocks merges when potential secrets are detected.

Adjust sensitivity by editing `.github/gitleaks.toml`; add narrow allowlist patterns instead of broad file/path wildcards to minimize false negatives.

### 8.3. Local Pre-Commit Hook

Path: `.githooks/pre-commit.d/secret-scan`

Enables fast feedback before pushing:

```sh
git config core.hooksPath .githooks
```

Optional environment variables:

- `SECRET_SCAN_VERBOSE=1` for debug
- `SECRET_SCAN_MAX_FINDINGS=20` to raise limit
- `SECRET_SCAN_ALLOW_REGEXES='EXAMPLE,DUMMY'` comma-separated suppression
- `SECRET_SCAN_DISABLE_GITLEAKS=1` to force fallback heuristic scanner
- `SKIP_SECRET_SCAN=1` (discouraged) bypasses the hook

### 8.4. Manual Local Scan Examples

Full repo scan (HEAD):

```sh
gitleaks detect --redact --config .github/gitleaks.toml
```

Diff-only (against main):

```sh
git fetch origin main
gitleaks detect --redact --config .github/gitleaks.toml --log-opts="origin/main..HEAD"
```

### 8.5. History Rewrite (If Secrets Entered History)

Follow `SECRET_HISTORY_REWRITE_PLAN.md` for a surgical rewrite using:

```sh
git filter-repo --force --invert-paths \
  --path dot-config/zsh/.env/api-keys.env \
  --path dot-config/zsh/.env/development.env \
  --path dot-config/zsh/.env/
```

Then:

```sh
git push --force-with-lease origin main
```

And instruct collaborators to reset:

```sh
git fetch origin
git checkout main
git reset --hard origin/main
git clean -fd
```

### 8.6. Redaction (Optional)

Populate `replacements.txt` with literal or `regex:` patterns and run:

```sh
git filter-repo --force --replace-text replacements.txt
```

Prefer deletion over redaction for environment files unless historical retention is required.

## 9. Development Workflow Notes

1. Create/edit configs under `dot-config/`
2. Stow (example):

   ```sh
   stow --target=$HOME zsh
   ```

3. Commit changes (hook scans automatically)
4. Push; GitHub Action enforces secondary scan

## 10. Extending Scanning

Potential future enhancements:

- SARIF upload for GitHub Advanced Security
- Adding entropy threshold tuning in baseline config
- Language-specific rule additions (e.g., Terraform provider creds)

## 11. Contributing

Changes should preserve:

- Principle of least privilege in CI
- Minimal false positive surface (tight allowlists)
- Clear audit trails in rewrite/secret-related docs

## 12. License

See `LICENSE` (if present).

## 13. Quick Reference Commands

Rotate & rewrite:

```sh
git clone --mirror <url> mirror.git
pip install git-filter-repo
git filter-repo --force --invert-paths --path dot-config/zsh/.env/
git push --force-with-lease origin main
```

Validate purge:

```sh
git grep -F 'API_KEY=' || echo 'Not found'
git log -- dot-config/zsh/.env/ | head -1 || echo 'Directory removed'
```

## 14. AI Guidelines & Orchestration Policy

This repository follows a comprehensive set of AI guidelines to ensure consistent, high-quality AI-assisted development.

### 14.1. For AI Agents

AI agents working on this project **MUST**:

1. **Read and comply** with [AI-GUIDELINES.md](AI-GUIDELINES.md)
2. **Follow instructions** in [AGENTS.md](AGENTS.md)
3. **Use Byterover MCP tools**:
   - `byterover-retrieve-knowledge`: Before starting tasks, making decisions, or debugging
   - `byterover-store-knowledge`: When learning patterns, solutions, or completing tasks

### 14.2. Key Principles

- **Clarity First**: All work should be suitable for junior developers to understand
- **Challenge Assumptions**: AI agents should ask clarifying questions and point out inconsistencies
- **No Sycophancy**: Direct, objective communication with dry humor
- **Security**: Never commit secrets; automated scanning enforces this
- **Quality**: 90% minimum test coverage required

### 14.3. Guidelines Structure

Detailed, technology-specific guidelines are organized in:

- `dot-config/ai/AI-GUIDELINES/Documentation/` - Documentation standards
- `dot-config/ai/AI-GUIDELINES/PHP-Laravel/` - PHP & Laravel development
- `dot-config/ai/AI-GUIDELINES/Shell-CLI/` - Shell & CLI operations
- `dot-config/ai/AI-GUIDELINES/Workflows/` - Development workflows

See [AI-GUIDELINES/000-index.md](dot-config/ai/AI-GUIDELINES/000-index.md) for complete navigation.

## 15. Acknowledgements

Security automation aligns with documented security standards (authentication, logging, incident response) in the guidelines referenced above.
