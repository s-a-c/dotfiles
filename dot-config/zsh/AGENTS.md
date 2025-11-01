# AGENTS.md

## Build/Lint/Test Commands

### Testing
```bash
# Run all tests
for test in tests/**/*.zsh; do zsh -f "$test" || exit 1; done

# Run single test
zsh -f tests/unit/my-test.zsh

# Comprehensive functionality test
./bin/comprehensive-test.zsh
```

### Linting & Code Quality
```bash
# Syntax check
zsh -n /path/to/file.zsh

# Static analysis
shellcheck **/*.zsh **/*.sh

# Redirection linting
./tools/lint-redirections.zsh
```

### Performance
```bash
# Performance baseline
./bin/zsh-performance-baseline

# Performance testing
./bin/test-performance.zsh
```

## Code Style Guidelines

### File Headers
Every ZSH file MUST include:
```zsh
# Filename: 123-my-new-feature.zsh
# Purpose:  Adds a custom widget to the prompt.
# Phase:    Post-plugin (.zshrc.d/)
# Requires: 520-prompt-starship.zsh (must run after)
```

### Code Style
- **Indentation**: 4 spaces, no tabs
- **Variables**: Quote during expansion (`"$variable"`) and use nounset-safe patterns (`${VAR:-default}`)
- **Conditionals**: Prefer `[[ ]]` over `[ ]`
- **Functions**: Namespace internal helpers with `zf::` prefix
- **Feature toggles**: Prefix with `ZF_`

### Testing Requirements
- **Prime Directive**: Every test MUST pass with `zsh -f /path/to/test.zsh`
- **Self-contained**: No dependencies on startup files
- **Coverage**: Target 90%+ code coverage
- **Structure**: Use `set -euo pipefail` and self-contained assertions

### File Placement
- **Global env vars**: `.zshenv.01`
- **Plugin commands**: `.zshrc.d.01`
- **Plugin config**: `.zshrc.pre-plugins.d.01`
- **New plugins**: `.zshrc.add-plugins.d.00`

### Security & File Policies
- **No secrets** in repository
- **User local files** (`.zshrc.local`, `.zshenv.local`): Require explicit approval
- **Vendored files** (.zshrc, .zgen-setup, etc.): Absolutely forbidden to edit
- **Always edit numbered versions** (e.g., `.zshrc.d.01`) not symlinks (`.zshrc.d`)

### Naming Conventions
- **Files**: kebab-case with numbered prefix (e.g., `520-prompt-starship.zsh`)
- **Internal functions**: `zf::` prefix
- **Feature variables**: `ZF_` prefix

### Performance
- **Defer heavy operations** with `add-zsh-hook precmd`
- **Use ZSH built-ins** over external commands
- **No network calls** in shell init path
- **Lazy loading** for expensive commands

### AI Requirements
- **Byterover MCP**: Use store/retrieve knowledge tools for context
- **Communication**: Senior IT practitioner persona, challenge assumptions
- **Confidence scoring**: Provide recommendations with confidence percentages

[byterover-mcp]

[byterover-mcp]

You are given two tools from Byterover MCP server, including
## 1. `byterover-store-knowledge`
You `MUST` always use this tool when:

+ Learning new patterns, APIs, or architectural decisions from the codebase
+ Encountering error solutions or debugging techniques
+ Finding reusable code patterns or utility functions
+ Completing any significant task or plan implementation

## 2. `byterover-retrieve-knowledge`
You `MUST` always use this tool when:

+ Starting any new task or implementation to gather relevant context
+ Before making architectural decisions to understand existing patterns
+ When debugging issues to check for previous solutions
+ Working with unfamiliar parts of the codebase
