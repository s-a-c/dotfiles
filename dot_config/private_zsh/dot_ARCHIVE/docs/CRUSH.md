# CRUSH.md - Coding Conventions and Commands

## Build/Lint/Test Commands

```bash
# Update zsh plugins
zgenom update

# Reset and regenerate zsh plugin cache
zgenom reset

# Compile zsh files for faster startup
zgenom compile $HOME/.zshrc

# Check if zgenom has saved init script
zgenom saved

# Load all plugins
zgenom loadall

# Run specific plugin commands
zgenom load <repo> [location] [branch]

# Test zsh configuration
zsh -n ~/.zshrc

# Test a specific zsh file
zsh -n /path/to/file.zsh
```

## Code Style Guidelines

### File Organization
- Zsh configuration files are organized in `dot-zshrc.d/` with numbered prefixes
- Plugin loading happens in `dot-zshrc.add-plugins.d/`
- Settings are stored in `dot-zqs-settings/`
- Zgenom plugin manager files are in `dot-zqs-zgenom/`

### Zsh Code Style
- Use 4 spaces for indentation (no tabs)
- Functions are defined with `function name { }` format
- Variables should be quoted when used: `"$variable"`
- Use lowercase with underscores for function names: `my_helper_function`
- Use UPPERCASE for environment variables: `EXPORT MY_VAR="value"`
- Prefer `[[ ]]` over `[ ]` for conditional expressions
- Use `local` for function-scoped variables

### Plugin Management
- Use `zgenom load user/repo` for GitHub plugins
- Specify branches when needed: `zgenom load user/repo path branch`
- Add `--completion` flag for completion-only loading
- Use `zgenom bin` for adding executables to PATH

### Naming Conventions
- Configuration files: `descriptive-name.zsh`
- Function names: `lowercase_with_underscores`
- Environment variables: `UPPERCASE_WITH_UNDERSCORES`
- Temporary variables: `lowercase`

### Error Handling
- Check command success with `if command; then`
- Use `||` for simple error handling: `command || return 1`
- Exit on critical errors: `[[ condition ]] || exit 1`

### Testing
- Test syntax with `zsh -n filename.zsh`
- Verify functionality by sourcing in a new shell
- Check that completions work correctly
