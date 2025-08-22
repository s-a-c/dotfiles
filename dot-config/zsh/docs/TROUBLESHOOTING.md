# ZSH Configuration Troubleshooting Guide

## Table of Contents

1. [Quick Diagnostics](#quick-diagnostics)
2. [Common Issues](#common-issues)
3. [Performance Problems](#performance-problems)
4. [Plugin Issues](#plugin-issues)
5. [Context Problems](#context-problems)
6. [Security Issues](#security-issues)
7. [Advanced Debugging](#advanced-debugging)

## Quick Diagnostics

### First Steps for Any Issue
```bash
# 1. Check configuration validity
config-validate

# 2. Run security audit
security-check

# 3. Check performance
profile-fast

# 4. View system status
context-status
cache-status
```

### Emergency Recovery
If your shell is completely broken:
```bash
# Use basic shell
/bin/zsh

# Disable custom config temporarily
export ZDOTDIR=""
zsh

# Or use backup if available
cp ~/.config/zsh/.zshrc.backup ~/.config/zsh/.zshrc
```

## Common Issues

### Issue: "Command not found" errors during startup

**Symptoms:**
```
/path/to/script:123: command not found: date
/path/to/script:456: command not found: sed
```

**Cause:** Basic system commands not in PATH during early loading

**Solution:**
```bash
# Check PATH
echo $PATH

# Ensure basic commands are available
export PATH="/usr/bin:/bin:$PATH"

# Reload configuration
source ~/.zshrc
```

**Prevention:** The system now includes automatic PATH fixes for this issue.

### Issue: Slow shell startup

**Symptoms:**
- Shell takes >5 seconds to start
- Noticeable delay when opening new terminals

**Diagnosis:**
```bash
# Measure current performance
profile-fast

# Enable debug mode to see what's loading
ZSH_DEBUG=true zsh -i -c exit

# Check for problematic plugins
list-plugins detailed
```

**Solutions:**
```bash
# 1. Enable async loading
export ZSH_ENABLE_ASYNC=true

# 2. Enable compilation
export ZSH_ENABLE_COMPILATION=true

# 3. Clean cache
cache-rebuild

# 4. Check for plugin conflicts
security-check
```

### Issue: Aliases or functions not working

**Symptoms:**
- Custom aliases return "command not found"
- Functions don't execute

**Diagnosis:**
```bash
# Check if aliases are defined
alias | grep your-alias

# Check if functions are defined
declare -f your-function

# Check load order
echo $fpath
```

**Solutions:**
```bash
# 1. Check alias file
cat ~/.config/zsh/.zsh_aliases

# 2. Reload configuration
source ~/.zshrc

# 3. Check for conflicts
which your-command
```

### Issue: Environment variables not set

**Symptoms:**
- Expected environment variables are empty
- Tools can't find configuration

**Diagnosis:**
```bash
# Check current environment
env | grep VARIABLE_NAME

# Check if sanitization is removing variables
ZSH_ENABLE_SANITIZATION=false
source ~/.zshrc
```

**Solutions:**
```bash
# 1. Check .zshenv
cat ~/.config/zsh/.zshenv

# 2. Disable sanitization if needed
export ZSH_ENABLE_SANITIZATION=false

# 3. Add to local config
echo 'export YOUR_VAR="value"' >> ~/.config/zsh/.zshrc.local
```

## Performance Problems

### Startup Time Too Slow

**Target:** <3 seconds for optimized configuration

**Diagnosis Steps:**
```bash
# 1. Measure baseline
profile

# 2. Check individual components
ZSH_DEBUG=true zsh -i -c exit 2>&1 | grep "Loading"

# 3. Check cache status
cache-status

# 4. Profile with iterations
profile-startup 10 2
```

**Optimization Steps:**
```bash
# 1. Enable all performance features
export ZSH_ENABLE_ASYNC=true
export ZSH_ENABLE_COMPILATION=true

# 2. Rebuild cache
cache-rebuild

# 3. Check plugin load times
list-plugins detailed

# 4. Disable problematic plugins temporarily
# Edit ~/.config/zsh/.zshrc.d/20-plugins/01-plugin-metadata.zsh
```

### Memory Usage Issues

**Symptoms:**
- High memory usage
- System slowdown

**Diagnosis:**
```bash
# Check ZSH memory usage
ps aux | grep zsh

# Check loaded functions
declare -f | wc -l

# Check variables
set | wc -l
```

**Solutions:**
```bash
# 1. Clean up unused functions
unfunction unused_function

# 2. Unset temporary variables
unset TEMP_VAR

# 3. Restart shell periodically
exec zsh
```

## Plugin Issues

### Plugin Not Loading

**Symptoms:**
- Plugin commands not available
- Plugin features not working

**Diagnosis:**
```bash
# Check plugin status
list-plugins detailed

# Check plugin metadata
get_plugin_metadata plugin-name

# Check dependencies
validate_plugin_dependencies plugin-name
```

**Solutions:**
```bash
# 1. Re-register plugin
register_plugin "plugin-name" "source" "type"

# 2. Check dependencies
list-plugins detailed | grep -A5 plugin-name

# 3. Resolve conflicts
check_plugin_conflicts plugin-name

# 4. Reload plugin system
source ~/.config/zsh/.zshrc.d/20-plugins/01-plugin-metadata.zsh
```

### Plugin Conflicts

**Symptoms:**
- Commands not working as expected
- Error messages about conflicts

**Diagnosis:**
```bash
# Check for conflicts
security-check

# List all plugins
list-plugins detailed

# Check specific plugin
check_plugin_conflicts plugin-name
```

**Solutions:**
```bash
# 1. Set conflict resolution mode
export ZSH_PLUGIN_CONFLICT_RESOLUTION="warn"  # or "ignore"

# 2. Disable conflicting plugin
# Edit plugin configuration

# 3. Resolve manually
# Check which plugins provide the same functionality
```

### Plugin Dependencies Missing

**Symptoms:**
- Plugin fails to load
- Dependency warnings

**Diagnosis:**
```bash
# Check dependencies
validate_plugin_dependencies plugin-name

# Check what's missing
list-plugins detailed | grep -A10 plugin-name
```

**Solutions:**
```bash
# 1. Install missing dependencies
# Follow plugin documentation

# 2. Disable strict dependencies
export ZSH_PLUGIN_STRICT_DEPENDENCIES=false

# 3. Register dependencies
register_plugin "dependency-name" "source" "type"
```

## Context Problems

### Context Not Switching

**Symptoms:**
- Context-specific aliases not available
- No context messages when changing directories

**Diagnosis:**
```bash
# Check context status
context-status

# Enable debug mode
export ZSH_CONTEXT_DEBUG=true
cd /path/to/project

# Check context detection
_detect_directory_context "$PWD"
```

**Solutions:**
```bash
# 1. Enable context awareness
export ZSH_CONTEXT_ENABLE=true

# 2. Reload context system
context-reload

# 3. Check context configurations
ls ~/.config/zsh/.context-configs/

# 4. Create missing context
context-create project-type
```

### Context Configuration Not Loading

**Symptoms:**
- Context detected but configuration not applied
- Context-specific commands not available

**Diagnosis:**
```bash
# Check context configs
_find_context_configs "$PWD"

# Check file permissions
ls -la ~/.config/zsh/.context-configs/

# Test manual loading
source ~/.config/zsh/.context-configs/git.zsh
```

**Solutions:**
```bash
# 1. Fix file permissions
chmod +x ~/.config/zsh/.context-configs/*.zsh

# 2. Check file syntax
zsh -n ~/.config/zsh/.context-configs/git.zsh

# 3. Recreate configuration
context-create git
```

## Security Issues

### Security Audit Failures

**Symptoms:**
- Security warnings during startup
- Failed security checks

**Diagnosis:**
```bash
# Run full security audit
security-check

# Check specific issues
_audit_file_permissions
_audit_environment_variables
```

**Solutions:**
```bash
# 1. Fix file permissions
chmod 644 ~/.config/zsh/.zshrc
chmod 755 ~/.config/zsh/.zshrc.d

# 2. Clean environment
env-sanitize

# 3. Review sensitive variables
env | grep -i "key\|token\|pass"
```

### Environment Sanitization Issues

**Symptoms:**
- Required environment variables missing
- Tools can't find configuration

**Diagnosis:**
```bash
# Check what's being sanitized
ZSH_ENABLE_SANITIZATION=true
_sanitize_environment

# Check sensitive variable detection
_is_sensitive_variable "YOUR_VAR"
```

**Solutions:**
```bash
# 1. Disable sanitization temporarily
export ZSH_ENABLE_SANITIZATION=false

# 2. Whitelist variables
# Edit sanitization configuration

# 3. Use local configuration
echo 'export SAFE_VAR="value"' >> ~/.config/zsh/.zshrc.local
```

## Advanced Debugging

### Enable Debug Mode

**Full Debug:**
```bash
export ZSH_DEBUG=true
export ZSH_CONTEXT_DEBUG=true
zsh -i -c exit
```

**Component-Specific Debug:**
```bash
# Plugin system
export ZSH_PLUGIN_DEBUG=true

# Context system
export ZSH_CONTEXT_DEBUG=true

# Cache system
export ZSH_CACHE_DEBUG=true
```

### Log Analysis

**Check Logs:**
```bash
# Recent logs
ls -la ~/.config/zsh/logs/$(date +%Y-%m-%d)/

# Security logs
tail -f ~/.config/zsh/logs/*/security-audit.log

# Performance logs
tail -f ~/.config/zsh/logs/*/startup-performance.log
```

### System Information

**Collect Debug Information:**
```bash
# System info
uname -a
zsh --version
echo $ZSH_VERSION

# Configuration info
config-validate
security-check
cache-status
context-status

# Performance info
profile-fast
```

### Reset to Defaults

**Complete Reset:**
```bash
# Backup current config
cp -r ~/.config/zsh ~/.config/zsh.backup

# Reset cache
cache-rebuild

# Reset context
context-reload

# Reload everything
exec zsh
```

## Getting Help

### Built-in Help
```bash
help                    # General help
config-validate --help  # Command-specific help
```

### Log Files
- Configuration: `~/.config/zsh/logs/*/config-validation.log`
- Security: `~/.config/zsh/logs/*/security-audit.log`
- Performance: `~/.config/zsh/logs/*/startup-performance.log`
- Context: `~/.config/zsh/logs/*/context-config.log`

### Emergency Contacts
- Configuration files: `~/.config/zsh/docs/`
- Test suite: `~/.config/zsh/tests/`
- Implementation plan: `~/.config/zsh/docs/zsh-improvement-implementation-plan-*.md`

---

**Most issues can be resolved with the diagnostic commands above. When in doubt, run `config-validate` and `security-check` first.**
