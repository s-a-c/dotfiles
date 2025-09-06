# ZSH Configuration Redesign – Implementation Plan (v2.0)
Date: 2025-01-03
Status: Stage 1 Complete - Testing Infrastructure Ready

## 0. Overview
Goal: Refactor pre- & post-plugin phases for performance (≥20% overall startup reduction), maintainability (strict module taxonomy), integrity (async validation), and minimalism (8 pre-plugin, 11 post-plugin files). All migration actions reversible via tagged backups & checksum/inventory enforcement.

**New**: Organized into discrete stages with git repository management and comprehensive testing infrastructure.

## 1. Stage-Based Implementation Matrix

Legend Priority: ⬛ Critical | 🔶 High | 🔵 Medium | ⚪ Low
Progress Symbols: ⬜ Not Started | ◐ In Progress | ✅ Done | 🚫 Blocked | 🎯 Ready

---

## STAGE 1: Foundation & Testing Infrastructure ✅ COMPLETE

### 1.1 Infrastructure Setup
| ID | Task | Priority | Status | Sub-tasks | Validation |
|----|------|----------|--------|-----------|-----------|
| S1.1 | Inventory & Skeleton Creation | ⬛ | ✅ | S1.1.1-S1.1.4 | Structure + drift tests |
| S1.2 | Testing Infrastructure | ⬛ | ✅ | S1.2.1-S1.2.7 | Test execution success |
| S1.3 | Enhanced Tools | 🔶 | ✅ | S1.3.1-S1.3.4 | Tool verification |
| S1.4 | Documentation Foundation | 🔶 | ✅ | S1.4.1-S1.4.3 | Doc consistency |
| S1.5 | CI/CD Infrastructure | 🔵 | ✅ | S1.5.1-S1.5.2 | Workflow validation |
| S1.6 | Stage 1 Repository Management | ⬛ | ✅ | S1.6.1-S1.6.5 | Git status clean |

#### S1.1 Inventory & Skeleton Creation
| Sub-ID | Sub-task | Status | Output |
|--------|----------|--------|--------|
| S1.1.1 | Pre-plugin inventory freeze | ✅ | preplugin-inventory.txt |
| S1.1.2 | Post-plugin inventory freeze | ✅ | postplugin-inventory.txt |
| S1.1.3 | Disabled modules inventory | ✅ | postplugin-disabled-inventory.txt |
| S1.1.4 | Legacy checksums snapshot | ✅ | legacy-checksums.sha256 |

#### S1.2 Testing Infrastructure
| Sub-ID | Sub-task | Status | Output |
|--------|----------|--------|--------|
| S1.2.1 | Design tests (sentinels) | ✅ | test-redesign-sentinels.zsh |
| S1.2.2 | Integration tests (compinit) | ✅ | test-postplugin-compinit-single-run.zsh |
| S1.2.3 | Security tests (async) | ✅ | test-async-state-machine.zsh, test-async-initial-state.zsh |
| S1.2.4 | Unit tests (lazy framework) | ✅ | test-lazy-framework.zsh |
| S1.2.5 | Feature tests (SSH agent) | ✅ | test-preplugin-ssh-agent-skeleton.zsh |
| S1.2.6 | Performance tests (segments) | ✅ | test-segment-regression.zsh |
| S1.2.7 | Test runner enhancement | ✅ | Enhanced run-all-tests.zsh |

#### S1.3 Enhanced Tools
| Sub-ID | Sub-task | Status | Output |
|--------|----------|--------|--------|
| S1.3.1 | Promotion guard enhancement | ✅ | Enhanced promotion-guard.zsh |
| S1.3.2 | Performance capture segments | ✅ | Enhanced perf-capture.zsh |
| S1.3.3 | Checksum verification | ✅ | verify-legacy-checksums.zsh |
| S1.3.4 | Implementation verification | ✅ | verify-implementation.zsh |

#### S1.4 Documentation Foundation
| Sub-ID | Sub-task | Status | Output |
|--------|----------|--------|--------|
| S1.4.1 | README updates | ✅ | Updated docs/redesign/README.md |
| S1.4.2 | Progress documentation | ✅ | IMPLEMENTATION_PROGRESS.md |
| S1.4.3 | Checksum header update | ✅ | Updated legacy-checksums.sha256 |

#### S1.5 CI/CD Infrastructure
| Sub-ID | Sub-task | Status | Output |
|--------|----------|--------|--------|
| S1.5.1 | GitHub Actions workflow | ✅ | structure-badge.yml |
| S1.5.2 | Workflow directories | ✅ | .github/workflows/ |

#### S1.6 Stage 1 Repository Management
| Sub-ID | Sub-task | Status | Commands |
|--------|----------|--------|----------|
| S1.6.1 | Add all new files | ✅ | `git add tests/ .github/ docs/redesign/IMPLEMENTATION_PROGRESS.md verify-implementation.zsh` |
| S1.6.2 | Add enhanced tools | ✅ | `git add tools/promotion-guard.zsh tools/perf-capture.zsh` |
| S1.6.3 | Add documentation updates | ✅ | `git add docs/redesign/README.md docs/redesign/planning/` |
| S1.6.4 | Commit stage 1 completion | ✅ | `git commit -m "feat: Stage 1 complete - comprehensive testing infrastructure"` |
| S1.6.5 | Tag stage 1 baseline | ✅ | `git tag -a refactor-stage1-complete -m "Stage 1: Testing infrastructure and foundation ready"` |

---

## STAGE 2: Pre-Plugin Content Migration 🎯 READY TO START

### 2.1 Pre-Plugin Core Implementation
| ID | Task | Priority | Status | Sub-tasks | Validation |
|----|------|----------|--------|-----------|-----------|
| S2.1 | Path Safety Consolidation | ⬛ | 🎯 | S2.1.1-S2.1.5 | Syntax + timing tests |
| S2.2 | FZF Initialization | 🔶 | ⬜ | S2.2.1-S2.2.4 | No external calls |
| S2.3 | Lazy Framework Implementation | 🔶 | ⬜ | S2.3.1-S2.3.6 | Unit test suite |
| S2.4 | Node Runtime Stubs | 🔵 | ⬜ | S2.4.1-S2.4.4 | First-call loading |
| S2.5 | Integration Wrappers | 🔵 | ⬜ | S2.5.1-S2.5.5 | Idempotent behavior |
| S2.6 | SSH Agent Consolidation | 🔵 | ⬜ | S2.6.1-S2.6.4 | No duplicate processes |

#### S2.1 Path Safety Consolidation
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S2.1.1 | Analyze legacy scripts | ⬜ | Review 00_00, 00_01, 00_05 logic |
| S2.1.2 | Extract common patterns | ⬜ | PATH deduplication, safety checks |
| S2.1.3 | Implement unified logic | ⬜ | Single 00-path-safety.zsh |
| S2.1.4 | Add performance timing | ⬜ | Ensure <5ms execution |
| S2.1.5 | Validate with tests | ⬜ | PATH integrity + syntax tests |

#### S2.2 FZF Initialization
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S2.2.1 | Identify minimal bindings | ⬜ | Essential keybindings only |
| S2.2.2 | Defer heavy initialization | ⬜ | Lazy load on first use |
| S2.2.3 | Implement 05-fzf-init.zsh | ⬜ | Lightweight stub |
| S2.2.4 | Test interaction patterns | ⬜ | No startup delays |

#### S2.3 Lazy Framework Implementation
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S2.3.1 | Design dispatcher architecture | ⬜ | Function registry + replacement |
| S2.3.2 | Implement registry system | ⬜ | Command -> loader mapping |
| S2.3.3 | Create dispatcher logic | ⬜ | First-call loading mechanism |
| S2.3.4 | Add error handling | ⬜ | Graceful loader failures |
| S2.3.5 | Implement 10-lazy-framework.zsh | ⬜ | Core framework |
| S2.3.6 | Validate with unit tests | ⬜ | test-lazy-framework.zsh |

#### S2.4 Node Runtime Stubs
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S2.4.1 | Create nvm lazy stub | ⬜ | Defer nvm loading |
| S2.4.2 | Create npm lazy stub | ⬜ | Defer npm setup |
| S2.4.3 | Implement 15-node-runtime-env.zsh | ⬜ | Lazy wrapper integration |
| S2.4.4 | Test first-call behavior | ⬜ | Single initialization |

#### S2.5 Integration Wrappers
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S2.5.1 | Direnv lazy wrapper | ⬜ | Defer direnv hook |
| S2.5.2 | Git integration wrapper | ⬜ | Lazy git completions |
| S2.5.3 | GitHub Copilot wrapper | ⬜ | Defer copilot init |
| S2.5.4 | Implement 25-lazy-integrations.zsh | ⬜ | Unified wrappers |
| S2.5.5 | Test idempotent behavior | ⬜ | Multiple call safety |

#### S2.6 SSH Agent Consolidation
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S2.6.1 | Merge agent management logic | ⬜ | Single agent detection |
| S2.6.2 | Implement socket checking | ⬜ | Avoid duplicate spawns |
| S2.6.3 | Create 30-ssh-agent.zsh | ⬜ | Consolidated implementation |
| S2.6.4 | Test with feature tests | ⬜ | test-preplugin-ssh-agent-skeleton.zsh |

### 2.2 Stage 2 Testing & Validation
| ID | Task | Priority | Status | Sub-tasks | Validation |
|----|------|----------|--------|-----------|-----------|
| S2.7 | Pre-plugin Performance Baseline | 🔶 | ⬜ | S2.7.1-S2.7.3 | Timing capture |
| S2.8 | Integration Testing | 🔶 | ⬜ | S2.8.1-S2.8.4 | Full pre-plugin validation |
| S2.9 | Regression Testing | 🔶 | ⬜ | S2.9.1-S2.9.3 | Performance gates |

#### S2.7 Pre-plugin Performance Baseline
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S2.7.1 | Capture segment timing | ⬜ | Pre-plugin execution time |
| S2.7.2 | Generate baseline metrics | ⬜ | preplugin-baseline.json |
| S2.7.3 | Set regression thresholds | ⬜ | <20% of total startup |

#### S2.8 Integration Testing
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S2.8.1 | Test toggle functionality | ⬜ | ZSH_ENABLE_PREPLUGIN_REDESIGN |
| S2.8.2 | Validate lazy loading | ⬜ | First-call behavior |
| S2.8.3 | Check PATH integrity | ⬜ | No broken paths |
| S2.8.4 | Verify agent management | ⬜ | SSH agent functionality |

#### S2.9 Regression Testing
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S2.9.1 | Run performance tests | ⬜ | Segment regression validation |
| S2.9.2 | Check legacy compatibility | ⬜ | No functional breaks |
| S2.9.3 | Validate promotion guard | ⬜ | All gates pass |

### 2.3 Stage 2 Repository Management
| ID | Task | Priority | Status | Sub-tasks |
|----|------|----------|--------|-----------|
| S2.10 | Stage 2 Git Management | ⬛ | ⬜ | S2.10.1-S2.10.6 |

#### S2.10 Stage 2 Git Management
| Sub-ID | Sub-task | Status | Commands |
|--------|----------|--------|----------|
| S2.10.1 | Add pre-plugin content | ⬜ | `git add .zshrc.pre-plugins.d.REDESIGN/` |
| S2.10.2 | Add updated tests | ⬜ | `git add tests/` |
| S2.10.3 | Add performance baselines | ⬜ | `git add docs/redesign/metrics/preplugin-baseline.json` |
| S2.10.4 | Commit stage 2 completion | ⬜ | `git commit -m "feat: Stage 2 complete - pre-plugin content migration"` |
| S2.10.5 | Tag stage 2 milestone | ⬜ | `git tag -a refactor-stage2-preplugin -m "Stage 2: Pre-plugin redesign complete"` |
| S2.10.6 | Push stage 2 | ⬜ | `git push origin main && git push origin --tags` |

---

## STAGE 3: Post-Plugin Core Implementation 🎯 PENDING STAGE 2

### 3.1 Core Modules (00, 05, 10)
| ID | Task | Priority | Status | Sub-tasks | Validation |
|----|------|----------|--------|-----------|-----------|
| S3.1 | Security Integrity Module | ⬛ | ⬜ | S3.1.1-S3.1.4 | Async state validation |
| S3.2 | Interactive Options Module | 🔶 | ⬜ | S3.2.1-S3.2.4 | Option consistency |
| S3.3 | Core Functions Module | 🔶 | ⬜ | S3.3.1-S3.3.5 | Function availability |

#### S3.1 Security Integrity Module (00-security-integrity.zsh)
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S3.1.1 | Implement baseline fingerprint | ⬜ | Light hash initialization |
| S3.1.2 | Add async scan scheduling | ⬜ | Queue for deferred execution |
| S3.1.3 | Create security state markers | ⬜ | Log async state transitions |
| S3.1.4 | Validate with async tests | ⬜ | test-async-state-machine.zsh |

#### S3.2 Interactive Options Module (05-interactive-options.zsh)
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S3.2.1 | Consolidate setopt commands | ⬜ | Essential shell options |
| S3.2.2 | Add zstyle configurations | ⬜ | Completion styling |
| S3.2.3 | Ensure option precedence | ⬜ | No conflicts with plugins |
| S3.2.4 | Test option interactions | ⬜ | Compatibility validation |

#### S3.3 Core Functions Module (10-core-functions.zsh)
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S3.3.1 | Extract user-visible helpers | ⬜ | Common utility functions |
| S3.3.2 | Create wrapper functions | ⬜ | Command enhancements |
| S3.3.3 | Add debug/logging helpers | ⬜ | Consistent logging |
| S3.3.4 | Implement function guards | ⬜ | Prevent overwrites |
| S3.3.5 | Test function availability | ⬜ | Unit test coverage |

### 3.2 Stage 3 Repository Management
| ID | Task | Priority | Status | Sub-tasks |
|----|------|----------|--------|-----------|
| S3.4 | Stage 3 Git Management | ⬛ | ⬜ | S3.4.1-S3.4.6 |

#### S3.4 Stage 3 Git Management
| Sub-ID | Sub-task | Status | Commands |
|--------|----------|--------|----------|
| S3.4.1 | Add core modules | ⬜ | `git add .zshrc.d.REDESIGN/0*-*.zsh` |
| S3.4.2 | Add related tests | ⬜ | `git add tests/unit/ tests/security/` |
| S3.4.3 | Update documentation | ⬜ | `git add docs/redesign/` |
| S3.4.4 | Commit core completion | ⬜ | `git commit -m "feat: Stage 3 complete - post-plugin core modules"` |
| S3.4.5 | Tag core milestone | ⬜ | `git tag -a refactor-stage3-core -m "Stage 3: Post-plugin core modules complete"` |
| S3.4.6 | Push stage 3 | ⬜ | `git push origin main && git push origin --tags` |

---

## STAGE 4: Post-Plugin Features & Environment 🎯 PENDING STAGE 3

### 4.1 Feature Modules (20, 30, 40)
| ID | Task | Priority | Status | Sub-tasks | Validation |
|----|------|----------|--------|-----------|-----------|
| S4.1 | Essential Plugins Module | 🔶 | ⬜ | S4.1.1-S4.1.5 | Plugin functionality |
| S4.2 | Development Environment | 🔶 | ⬜ | S4.2.1-S4.2.6 | Dev tool availability |
| S4.3 | Aliases & Keybindings | 🔵 | ⬜ | S4.3.1-S4.3.4 | Binding consistency |

#### S4.1 Essential Plugins Module (20-essential-plugins.zsh)
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S4.1.1 | Identify critical plugins | ⬜ | Must-have plugin functionality |
| S4.1.2 | Create plugin metadata | ⬜ | Version tracking |
| S4.1.3 | Add plugin-specific config | ⬜ | Essential configurations |
| S4.1.4 | Implement plugin guards | ⬜ | Availability checks |
| S4.1.5 | Test plugin integration | ⬜ | Feature parity validation |

#### S4.2 Development Environment (30-development-env.zsh)
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S4.2.1 | Go environment setup | ⬜ | GOPATH, GOROOT configuration |
| S4.2.2 | Rust environment setup | ⬜ | Cargo path integration |
| S4.2.3 | Python environment setup | ⬜ | Virtual env management |
| S4.2.4 | Java environment setup | ⬜ | JAVA_HOME configuration |
| S4.2.5 | Docker integration | ⬜ | Container dev support |
| S4.2.6 | Test dev tool paths | ⬜ | Availability validation |

#### S4.3 Aliases & Keybindings (40-aliases-keybindings.zsh)
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S4.3.1 | Consolidate aliases | ⬜ | Common command shortcuts |
| S4.3.2 | Add keybinding customizations | ⬜ | Essential key mappings |
| S4.3.3 | Ensure no conflicts | ⬜ | Plugin compatibility |
| S4.3.4 | Test binding functionality | ⬜ | Interactive validation |

### 4.2 Stage 4 Repository Management
| ID | Task | Priority | Status | Sub-tasks |
|----|------|----------|--------|-----------|
| S4.4 | Stage 4 Git Management | ⬛ | ⬜ | S4.4.1-S4.4.6 |

#### S4.4 Stage 4 Git Management
| Sub-ID | Sub-task | Status | Commands |
|--------|----------|--------|----------|
| S4.4.1 | Add feature modules | ⬜ | `git add .zshrc.d.REDESIGN/2*-*.zsh .zshrc.d.REDESIGN/3*-*.zsh .zshrc.d.REDESIGN/4*-*.zsh` |
| S4.4.2 | Add feature tests | ⬜ | `git add tests/feature/ tests/integration/` |
| S4.4.3 | Update dev environment docs | ⬜ | `git add docs/redesign/` |
| S4.4.4 | Commit feature completion | ⬜ | `git commit -m "feat: Stage 4 complete - post-plugin feature modules"` |
| S4.4.5 | Tag feature milestone | ⬜ | `git tag -a refactor-stage4-features -m "Stage 4: Post-plugin feature modules complete"` |
| S4.4.6 | Push stage 4 | ⬜ | `git push origin main && git push origin --tags` |

---

## STAGE 5: UI, Performance & Validation 🎯 PENDING STAGE 4

### 5.1 UI & System Modules (50, 60, 70, 80, 90)
| ID | Task | Priority | Status | Sub-tasks | Validation |
|----|------|----------|--------|-----------|-----------|
| S5.1 | Completion & History Module | 🔶 | ⬜ | S5.1.1-S5.1.5 | Single compinit |
| S5.2 | UI & Prompt Module | 🔵 | ⬜ | S5.2.1-S5.2.4 | Prompt isolation |
| S5.3 | Performance Monitoring | 🔵 | ⬜ | S5.3.1-S5.3.4 | Timing hooks |
| S5.4 | Security Validation | 🔵 | ⬜ | S5.4.1-S5.4.5 | Async validation |
| S5.5 | Splash Module | ⚪ | ⬜ | S5.5.1-S5.5.3 | Optional display |

#### S5.1 Completion & History (50-completion-history.zsh)
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S5.1.1 | Implement single compinit | ⬜ | _COMPINIT_DONE guard |
| S5.1.2 | Configure completion styles | ⬜ | Performance-optimized |
| S5.1.3 | Set history parameters | ⬜ | Size and persistence |
| S5.1.4 | Add completion caching | ⬜ | Faster subsequent loads |
| S5.1.5 | Test with compinit validation | ⬜ | test-postplugin-compinit-single-run.zsh |

#### S5.2 UI & Prompt (60-ui-prompt.zsh)
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S5.2.1 | Configure p10k theme | ⬜ | Prompt customization |
| S5.2.2 | Set color preferences | ⬜ | Terminal color config |
| S5.2.3 | Add prompt isolation | ⬜ | No plugin interference |
| S5.2.4 | Test prompt rendering | ⬜ | Visual validation |

#### S5.3 Performance Monitoring (70-performance-monitoring.zsh)
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S5.3.1 | Add precmd timing hooks | ⬜ | Startup time capture |
| S5.3.2 | Implement segment logging | ⬜ | Pre/post plugin timing |
| S5.3.3 | Create performance helpers | ⬜ | Debug timing commands |
| S5.3.4 | Test timing accuracy | ⬜ | Performance validation |

#### S5.4 Security Validation (80-security-validation.zsh)
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S5.4.1 | Implement deferred hash engine | ⬜ | Post-prompt scanning |
| S5.4.2 | Add plugin integrity checks | ⬜ | Hash comparison |
| S5.4.3 | Create security commands | ⬜ | plugin_security_status |
| S5.4.4 | Add async state management | ⬜ | Non-blocking execution |
| S5.4.5 | Test with async validation | ⬜ | test-async-state-machine.zsh |

#### S5.5 Splash Module (90-splash.zsh)
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S5.5.1 | Create minimal splash | ⬜ | Version and status info |
| S5.5.2 | Add disable flag | ⬜ | ZSH_DISABLE_SPLASH |
| S5.5.3 | Test optional behavior | ⬜ | Enable/disable validation |

### 5.2 Stage 5 Repository Management
| ID | Task | Priority | Status | Sub-tasks |
|----|------|----------|--------|-----------|
| S5.6 | Stage 5 Git Management | ⬛ | ⬜ | S5.6.1-S5.6.6 |

#### S5.6 Stage 5 Git Management
| Sub-ID | Sub-task | Status | Commands |
|--------|----------|--------|----------|
| S5.6.1 | Add UI/system modules | ⬜ | `git add .zshrc.d.REDESIGN/5*-*.zsh .zshrc.d.REDESIGN/6*-*.zsh .zshrc.d.REDESIGN/7*-*.zsh .zshrc.d.REDESIGN/8*-*.zsh .zshrc.d.REDESIGN/9*-*.zsh` |
| S5.6.2 | Add performance tests | ⬜ | `git add tests/performance/ tests/security/` |
| S5.6.3 | Add timing baselines | ⬜ | `git add docs/redesign/metrics/` |
| S5.6.4 | Commit UI completion | ⬜ | `git commit -m "feat: Stage 5 complete - UI, performance, and validation modules"` |
| S5.6.5 | Tag UI milestone | ⬜ | `git tag -a refactor-stage5-ui-perf -m "Stage 5: UI and performance modules complete"` |
| S5.6.6 | Push stage 5 | ⬜ | `git push origin main && git push origin --tags` |

---

## STAGE 6: Performance Validation & Promotion 🎯 PENDING STAGE 5

### 6.1 Performance Analysis
| ID | Task | Priority | Status | Sub-tasks | Validation |
|----|------|----------|--------|-----------|-----------|
| S6.1 | Comprehensive Baseline | ⬛ | ⬜ | S6.1.1-S6.1.4 | Performance gates |
| S6.2 | A/B Testing | 🔶 | ⬜ | S6.2.1-S6.2.5 | Comparative analysis |
| S6.3 | Regression Validation | 🔶 | ⬜ | S6.3.1-S6.3.4 | Threshold compliance |

#### S6.1 Comprehensive Baseline
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S6.1.1 | Capture full startup metrics | ⬜ | Complete redesign timing |
| S6.1.2 | Generate segment analysis | ⬜ | Pre/post plugin costs |
| S6.1.3 | Compare with legacy baseline | ⬜ | Performance improvement |
| S6.1.4 | Validate 20% improvement | ⬜ | Gate compliance |

#### S6.2 A/B Testing
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S6.2.1 | Test toggle off/on performance | ⬜ | Legacy vs redesign |
| S6.2.2 | Measure memory usage | ⬜ | RSS comparison |
| S6.2.3 | Test cold vs warm starts | ⬜ | Caching effectiveness |
| S6.2.4 | Validate async deferral | ⬜ | Non-blocking verification |
| S6.2.5 | Generate A/B report | ⬜ | perf-postplugin-ab.json |

#### S6.3 Regression Validation
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S6.3.1 | Run all performance tests | ⬜ | Comprehensive validation |
| S6.3.2 | Check promotion guard | ⬜ | All gates pass |
| S6.3.3 | Validate async integrity | ⬜ | State machine compliance |
| S6.3.4 | Confirm functionality parity | ⬜ | No feature loss |

### 6.2 Promotion Readiness
| ID | Task | Priority | Status | Sub-tasks | Validation |
|----|------|----------|--------|-----------|-----------|
| S6.4 | Final Validation | ⬛ | ⬜ | S6.4.1-S6.4.5 | Promotion guard pass |
| S6.5 | Documentation Completion | 🔶 | ⬜ | S6.5.1-S6.5.3 | Doc consistency |
| S6.6 | Promotion Execution | ⬛ | ⬜ | S6.6.1-S6.6.4 | Toggle defaults |

#### S6.4 Final Validation
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S6.4.1 | Run comprehensive test suite | ⬜ | All test categories pass |
| S6.4.2 | Execute promotion guard | ⬜ | All criteria satisfied |
| S6.4.3 | Validate checksum integrity | ⬜ | Legacy unchanged |
| S6.4.4 | Confirm async state compliance | ⬜ | Deferred execution verified |
| S6.4.5 | Check structure consistency | ⬜ | No violations detected |

#### S6.5 Documentation Completion
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S6.5.1 | Update final report | ⬜ | Performance metrics included |
| S6.5.2 | Generate completion badges | ⬜ | Success indicators |
| S6.5.3 | Archive planning documents | ⬜ | Mark as completed |

#### S6.6 Promotion Execution
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S6.6.1 | Enable redesign toggles by default | ⬜ | ZSH_ENABLE_*_REDESIGN=1 |
| S6.6.2 | Generate new checksum baseline | ⬜ | tools/generate-legacy-checksums.zsh |
| S6.6.3 | Archive legacy directories | ⬜ | *.legacy.YYYYMMDD backup |
| S6.6.4 | Update system defaults | ⬜ | Remove toggle guards |

### 6.3 Stage 6 Repository Management
| ID | Task | Priority | Status | Sub-tasks |
|----|------|----------|--------|-----------|
| S6.7 | Stage 6 Git Management | ⬛ | ⬜ | S6.7.1-S6.7.7 |

#### S6.7 Stage 6 Git Management
| Sub-ID | Sub-task | Status | Commands |
|--------|----------|--------|----------|
| S6.7.1 | Add performance reports | ⬜ | `git add docs/redesign/metrics/perf-postplugin-ab.json` |
| S6.7.2 | Add final documentation | ⬜ | `git add docs/redesign/final-report.md` |
| S6.7.3 | Add promotion artifacts | ⬜ | `git add tools/generate-legacy-checksums.zsh` |
| S6.7.4 | Commit promotion readiness | ⬜ | `git commit -m "feat: Stage 6 complete - promotion ready"` |
| S6.7.5 | Tag promotion milestone | ⬜ | `git tag -a refactor-stage6-promotion-ready -m "Stage 6: Ready for promotion"` |
| S6.7.6 | Execute promotion | ⬜ | Update default toggles, archive legacy |
| S6.7.7 | Final promotion tag | ⬜ | `git tag -a refactor-promotion-complete -m "Redesign promotion complete"` |

---

## STAGE 7: Post-Promotion Cleanup 🎯 PENDING STAGE 6

### 7.1 System Cleanup
| ID | Task | Priority | Status | Sub-tasks | Validation |
|----|------|----------|--------|-----------|-----------|
| S7.1 | Legacy Directory Management | 🔶 | ⬜ | S7.1.1-S7.1.4 | Clean git status |
| S7.2 | Toggle Cleanup | 🔵 | ⬜ | S7.2.1-S7.2.3 | Simplified codebase |
| S7.3 | Documentation Finalization | 🔵 | ⬜ | S7.3.1-S7.3.4 | Updated references |

#### S7.1 Legacy Directory Management
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S7.1.1 | Archive legacy directories | ⬜ | Move to *.legacy.YYYYMMDD |
| S7.1.2 | Update .gitignore | ⬜ | Exclude legacy archives |
| S7.1.3 | Clean obsolete inventories | ⬜ | Remove drift tests |
| S7.1.4 | Verify clean state | ⬜ | No uncommitted changes |

#### S7.2 Toggle Cleanup
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S7.2.1 | Remove redesign toggles | ⬜ | ZSH_ENABLE_*_REDESIGN |
| S7.2.2 | Simplify conditional logic | ⬜ | Direct sourcing |
| S7.2.3 | Update configuration docs | ⬜ | Remove toggle references |

#### S7.3 Documentation Finalization
| Sub-ID | Sub-task | Status | Details |
|--------|----------|--------|---------|
| S7.3.1 | Mark implementation complete | ⬜ | Update status badges |
| S7.3.2 | Archive planning documents | ⬜ | Move to completed/ |
| S7.3.3 | Update README references | ⬜ | Point to new structure |
| S7.3.4 | Generate completion report | ⬜ | Final metrics summary |

### 7.2 Stage 7 Repository Management
| ID | Task | Priority | Status | Sub-tasks |
|----|------|----------|--------|-----------|
| S7.4 | Stage 7 Git Management | ⬛ | ⬜ | S7.4.1-S7.4.6 |

#### S7.4 Stage 7 Git Management
| Sub-ID | Sub-task | Status | Commands |
|--------|----------|--------|----------|
| S7.4.1 | Add cleanup changes | ⬜ | `git add .zshrc .gitignore` |
| S7.4.2 | Add final documentation | ⬜ | `git add docs/` |
| S7.4.3 | Remove obsolete files | ⬜ | `git rm docs/redesign/planning/*.md` (move to completed/) |
| S7.4.4 | Commit cleanup | ⬜ | `git commit -m "chore: Post-promotion cleanup and finalization"` |
| S7.4.5 | Tag final completion | ⬜ | `git tag -a refactor-complete -m "ZSH redesign project complete"` |
| S7.4.6 | Push final state | ⬜ | `git push origin main && git push origin --tags` |

---

## 2. Cross-Stage Dependencies & Critical Path

### 2.1 Dependency Matrix
| Stage | Depends On | Blocking | Critical Path |
|-------|------------|----------|---------------|
| Stage 1 | None | Stage 2+ | ✅ Complete |
| Stage 2 | Stage 1 | Stage 3+ | 🎯 Ready |
| Stage 3 | Stage 2 | Stage 4+ | ⬜ Pending |
| Stage 4 | Stage 3 | Stage 5+ | ⬜ Pending |
| Stage 5 | Stage 4 | Stage 6+ | ⬜ Pending |
| Stage 6 | Stage 5 | Stage 7 | ⬜ Pending |
| Stage 7 | Stage 6 | None | ⬜ Pending |

### 2.2 Parallel Work Opportunities
| Work Stream | Stages | Can Run In Parallel |
|-------------|--------|-------------------|
| Documentation | All | ✅ Ongoing updates |
| Testing | All | ✅ Test development |
| Performance Analysis | 2-6 | ✅ Baseline updates |
| Security Validation | 3-6 | ✅ Async development |

---

## 3. Enhanced Safety Controls

### 3.1 Stage-Level Safety Gates
| Stage | Safety Check | Tool/Test | Fail Action |
|-------|--------------|-----------|-------------|
| All | Drift Detection | test-*-drift.zsh | Halt & restore |
| All | Checksum Integrity | verify-legacy-checksums.zsh | Abort changes |
| All | Structure Validation | test-redesign-sentinels.zsh | Fix violations |
| 2+ | Performance Gate | test-segment-regression.zsh | Revert & optimize |
| 3+ | Async Compliance | test-async-state-machine.zsh | Fix state logic |
| 5+ | Compinit Single-Run | test-postplugin-compinit-single-run.zsh | Debug duplicates |
| 6 | Promotion Guard | promotion-guard.zsh | Block promotion |

### 3.2 Rollback Procedures (Enhanced)
| Rollback Type | Trigger | Commands | Recovery Time |
|---------------|---------|----------|---------------|
| Stage Rollback | Stage gate failure | `git checkout refactor-stage$(N-1)-*` | ~1 minute |
| Feature Rollback | Single module issue | Disable redesign toggle | ~30 seconds |
| Emergency Rollback | Critical system failure | `git checkout refactor-baseline` | ~2 minutes |
| Partial Rollback | Module-specific issue | Revert specific module only | ~1 minute |

### 3.3 Automated Safety Checks
| Check Type | Frequency | Command | Threshold |
|------------|-----------|---------|-----------|
| Structure | Pre-commit | `tests/run-all-tests.zsh --design-only` | 0 failures |
| Performance | Post-content | `tests/run-all-tests.zsh --performance-only` | ≤5% regression |
| Integration | Pre-stage-close | `tests/run-all-tests.zsh` | ≤2% failure rate |
| Security | Continuous | `tests/run-all-tests.zsh --security-only` | 0 failures |

---

## 4. Performance Tracking Matrix

### 4.1 Stage Performance Targets
| Stage | Target Improvement | Measurement | Baseline | Goal |
|-------|-------------------|-------------|----------|------|
| Stage 1 | Infrastructure | Test execution time | N/A | <60s full suite |
| Stage 2 | Pre-plugin | Segment timing | Legacy pre-plugin | -10% vs legacy |
| Stage 3 | Core load | Module load time | Legacy core | -15% vs legacy |
| Stage 4 | Feature load | Feature init time | Legacy features | -20% vs legacy |
| Stage 5 | UI load | Prompt ready time | Legacy UI | -25% vs legacy |
| Stage 6 | Overall | Total startup | 4772ms baseline | ≤3817ms (20% improvement) |

### 4.2 Segment Cost Budgets
| Module Category | Time Budget | Current Legacy | Target Redesign |
|-----------------|-------------|----------------|-----------------|
| Pre-plugin total | 400ms | ~500ms | ≤400ms |
| Core modules (00-10) | 200ms | ~300ms | ≤200ms |
| Feature modules (20-40) | 300ms | ~400ms | ≤300ms |
| UI modules (50-60) | 200ms | ~300ms | ≤200ms |
| Monitoring (70-80) | 100ms | ~150ms | ≤100ms |
| Async overhead | 50ms | N/A | ≤50ms |

---

## 5. Testing Strategy Integration

### 5.1 Test Category Mapping to Stages
| Test Category | Primary Stages | Secondary Stages | Key Validations |
|---------------|----------------|------------------|-----------------|
| Design | 1 | All | Sentinel compliance |
| Unit | 2, 3 | 4, 5 | Component functionality |
| Integration | 3, 4, 5 | 6 | Cross-component interaction |
| Feature | 2, 4 | 5, 6 | User-facing functionality |
| Security | 3, 5 | 6 | Async state integrity |
| Performance | 2, 6 | 3, 4, 5 | Timing regression |

### 5.2 Stage-Specific Test Requirements
| Stage | Required Tests | Optional Tests | Gate Tests |
|-------|----------------|----------------|------------|
| 1 | Design, Unit (basic) | None | Structure validation |
| 2 | Unit, Feature, Performance | Integration | Performance gate |
| 3 | Unit, Integration, Security | Performance | Security compliance |
| 4 | Feature, Integration | Performance | Feature parity |
| 5 | Integration, Security, Performance | All | Compinit validation |
| 6 | All categories | None | Promotion guard |
| 7 | Integration (final) | None | System stability |

---

## 6. Risk Management Matrix (Enhanced)

### 6.1 Stage-Specific Risks
| Stage | Primary Risks | Likelihood | Impact | Mitigation |
|-------|---------------|------------|--------|-------------|
| 2 | Path corruption | Medium | High | Comprehensive PATH testing |
| 2 | Lazy loading failures | Medium | Medium | Fallback to direct loading |
| 3 | Security vulnerabilities | Low | High | Async state validation |
| 3 | Function conflicts | Medium | Medium | Namespace isolation |
| 4 | Plugin incompatibilities | High | Medium | Plugin-specific testing |
| 4 | Development env breaks | Medium | High | Tool availability tests |
| 5 | UI rendering issues | Medium | Low | Visual regression tests |
| 5 | Performance degradation | Medium | High | Continuous monitoring |
| 6 | Promotion failures | Low | High | Comprehensive validation |

### 6.2 Cross-Stage Risks
| Risk | Affected Stages | Detection Method | Recovery Plan |
|------|-----------------|------------------|---------------|
| Cumulative performance loss | 2-5 | Segment tracking | Incremental optimization |
| Integration conflicts | 3-5 | Cross-component tests | Module isolation |
| Test infrastructure failure | All | Test suite validation | Infrastructure rebuild |
| Documentation drift | All | Link validation | Documentation sync |

---

## 7. Success Metrics & KPIs

### 7.1 Primary Success Metrics
| Metric | Baseline | Target | Measurement Method |
|--------|----------|--------|--------------------|
| Startup Time | 4772ms | ≤3817ms | perf-capture.zsh |
| Pre-plugin Cost | ~500ms | ≤400ms | Segment timing |
| Post-plugin Cost | ~780ms | ≤500ms | Segment timing |
| Test Coverage | 67 tests | 100+ tests | Test count |
| Documentation Coverage | 15 docs | 20+ docs | Doc inventory |

### 7.2 Quality Metrics
| Quality Aspect | Measurement | Target |
|----------------|-------------|---------|
| Code Maintainability | Module count | 19 total (8+11) |
| Test Reliability | Flaky test rate | <2% |
| Performance Consistency | Timing stddev | <5% |
| Documentation Currency | Outdated link rate | <1% |
| Security Posture | Async validation | 100% pass rate |

### 7.3 Operational Metrics
| Operational Aspect | Baseline | Target |
|--------------------|----------|---------|
| Stage Completion Time | N/A | ≤2 weeks per stage |
| Rollback Frequency | N/A | <1 per stage |
| Test Execution Time | ~5 minutes | <3 minutes |
| CI/CD Pipeline Success | N/A | >95% |

---

## 8. Tools & Automation

### 8.1 Enhanced Toolchain
| Tool | Purpose | Stage Usage | Automation Level |
|------|---------|-------------|------------------|
| verify-implementation.zsh | Quick validation | All | Manual trigger |
| promotion-guard.zsh | Gate validation | 6 | Automated |
| perf-capture.zsh | Performance measurement | 2-6 | Semi-automated |
| run-all-tests.zsh | Comprehensive testing | All | Automated |
| structure-badge.yml | CI/CD validation | All | Fully automated |

### 8.2 Stage Automation Scripts (Planned)
| Script | Purpose | Usage |
|--------|---------|-------|
| stage-runner.zsh | Execute stage workflow | `./stage-runner.zsh 2` |
| stage-validator.zsh | Validate stage completion | `./stage-validator.zsh 2` |
| rollback-manager.zsh | Manage rollbacks | `./rollback-manager.zsh 2` |
| metrics-collector.zsh | Gather stage metrics | `./metrics-collector.zsh` |

---

## 9. Commit Message Standards

### 9.1 Stage Commit Formats
| Stage | Commit Type | Format |
|-------|-------------|---------|
| 1 | Infrastructure | `feat: Stage 1 - <component> infrastructure` |
| 2 | Pre-plugin | `feat(pre-plugin): <module> implementation` |
| 3 | Core | `feat(post-plugin): core <module> implementation` |
| 4 | Features | `feat(post-plugin): feature <module> implementation` |
| 5 | UI/Perf | `feat(post-plugin): UI/performance <module>` |
| 6 | Promotion | `feat: promotion ready - <validation>` |
| 7 | Cleanup | `chore: post-promotion <cleanup-type>` |

### 9.2 Specialized Commit Types
| Type | Usage | Example |
|------|-------|---------|
| `perf:` | Performance improvements | `perf(pre-plugin): optimize lazy loading dispatcher` |
| `test:` | Test additions/fixes | `test(security): add async state validation tests` |
| `docs:` | Documentation updates | `docs(plan): update implementation progress` |
| `refactor:` | Code restructuring | `refactor(post-plugin): consolidate option handling` |
| `fix:` | Bug fixes | `fix(pre-plugin): resolve PATH deduplication issue` |

---

## 10. Final Integration Checklist

### 10.1 Pre-Promotion Verification
- [ ] All 7 stages completed
- [ ] All tests passing (100+ test cases)
- [ ] Performance targets met (≥20% improvement)
- [ ] Security validation complete
- [ ] Documentation current and consistent
- [ ] Rollback procedures verified
- [ ] Legacy compatibility confirmed

### 10.2 Post-Promotion Validation
- [ ] System startup functional
- [ ] All user workflows operational
- [ ] Performance improvements realized
- [ ] No functionality regressions
- [ ] Documentation updated
- [ ] Legacy archives created
- [ ] Toggle cleanup completed

---

## 11. Appendices

### A. Quick Reference Commands
```bash
# Stage validation
./verify-implementation.zsh

# Test specific categories
tests/run-all-tests.zsh --design-only
tests/run-all-tests.zsh --performance-only

# Performance measurement
tools/perf-capture.zsh

# Promotion readiness
tools/promotion-guard.zsh

# Rollback (if needed)
git checkout refactor-stage$(N)-*
```

### B. Emergency Contacts & Escalation
| Issue Type | Contact Method | Response Time |
|------------|----------------|---------------|
| Critical system failure | GitHub issue | Immediate |
| Performance regression | Performance team | 4 hours |
| Security concern | Security team | 2 hours |
| Documentation issues | Tech writing | 24 hours |

### C. Stage Completion Artifacts
Each stage produces specific artifacts stored in `docs/redesign/artifacts/stage-N/`:
- Stage metrics (`stage-N-metrics.json`)
- Test results (`stage-N-test-results.log`)
- Performance baselines (`stage-N-performance.json`)
- Documentation snapshots (`stage-N-docs-snapshot.md`)

---

**Document Status**: Stage 1 Complete - Ready for Stage 2 Execution
**Last Updated**: 2025-01-03
**Version**: 2.0 (Stage-based implementation)

[Back to Documentation Index](../README.md) | [Testing Strategy](testing-strategy.md) | [Gating Flags](gating-flags.md)
