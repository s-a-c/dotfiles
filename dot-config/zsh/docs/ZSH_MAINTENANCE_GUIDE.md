# Zsh Configuration Maintenance Guide
## Optimization, Debugging & Best Practices

### Quick Fix Implementation

To implement the fixes immediately:

```bash
# Backup current configuration
cp ~/.config/zsh/.zshenv ~/.config/zsh/.zshenv.backup.$(date +%Y%m%d)

# Apply the fixed configuration
cp ~/.config/zsh/.zshenv.fixed ~/.config/zsh/.zshenv
cp ~/.config/zsh/.zshrc.d/010-post-plugins.zsh ~/.config/zsh/.zshrc.d/010-post-plugins.zsh.orig.bad

# Secure the old credentials file (DO NOT delete - extract keys first)
chmod 000 ~/.config/zsh/.zshrc.pre-plugins.d/dot-_zshenv.zsh
mv ~/.config/zsh/.zshrc.pre-plugins.d/dot-_zshenv.zsh ~/.config/zsh/.zshrc.pre-plugins.d/dot-_zshenv.zsh.INSECURE

# Test the configuration
zsh -n ~/.config/zsh/.zshenv
&& echo "✓ .zshenv syntax OK"
|| echo "✗ .zshenv syntax error"
```

### Security Setup (Critical - Do This First)

1. **Extract and Secure API Keys:**
```bash
# Create secure environment directory
mkdir -p ~/.config/zsh/.env
chmod 700 ~/.config/zsh/.env

# Create API keys file (extract from the old insecure file)
cat > ~/.config/zsh/.env/api-keys.env << 'EOF'
# API Keys - Keep this file secure!
# Add your actual keys here
ANTHROPIC_API_KEY=your-actual-key-here
GITHUB_TOKEN=your-actual-token-here
OPENAI_API_KEY=your-actual-key-here
# ... add other keys as needed
EOF

# Secure the file
chmod 600 ~/.config/zsh/.env/api-keys.env

# Add to gitignore
echo "/.env/" >> ~/.config/zsh/.gitignore
```

2. **Create Development Environment File:**
```bash
cat > ~/.config/zsh/.env/development.env << 'EOF'
# Development-specific environment variables
DEVSENSE_PHP_LS_LICENSE=your-license-here
LM_STUDIO_API_BASE=http://localhost:1234/v1
LM_STUDIO_API_KEY=dummy-api-key
EOF
chmod 600 ~/.config/zsh/.env/development.env
```

### Performance Optimization

#### Startup Time Benchmarking
```bash
# Measure current startup time
time zsh -i -c exit

# Profile with zprof (detailed breakdown)
echo "zmodload zsh/zprof" > ~/.config/zsh/.zqs-zprof-enabled
zsh -i -c "zprof | head -20"
rm ~/.config/zsh/.zqs-zprof-enabled

# Measure only plugin loading time
time zsh -i -c "echo 'Startup complete'" 2>/dev/null
```

#### Optimization Strategies

1. **Lazy Loading Plugins:**
```bash
# Add to ~/.config/zsh/.zshrc.d/lazy-loading.zsh
nvm() { unfunction nvm; source ~/.nvm/nvm.sh; nvm "$@"; }
pyenv() { unfunction pyenv; eval "$(command pyenv init -)"; pyenv "$@"; }
```

2. **Conditional Plugin Loading:**
```bash
# Only load plugins if their commands will be used
[[ -d ~/Projects ]] && zgenom load developer-plugin
[[ $(pwd) =~ /work/ ]] && zgenom load work-specific-plugin
```

3. **Cache Completion Loading:**
```bash
# Add to .zshrc before plugin loading
export SKIP_GLOBAL_COMPINIT=1  # Skip system compinit
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C  # Skip security check for speed
fi
```

### Debugging Commands

#### Startup Debugging
```bash
# Debug mode - shows what files are being loaded
touch ~/.config/zsh/.zqs-debug-mode
zsh -i -c exit
rm ~/.config/zsh/.zqs-debug-mode

# Trace all sourced files
zsh -x -i -c exit 2>&1 | grep -E "(source|\.)"

# Check for missing files/commands
zsh -x -i -c exit 2>&1 | grep -i "not found\|no such file"
```

#### Plugin Debugging
```bash
# List loaded zgenom plugins
zgenom list

# Reset zgenom cache if plugins misbehave
zgenom reset

# Check plugin loading order
ls -la ~/.config/zsh/.zgenom/

# Test individual plugin
zgenom load username/plugin-name
```

#### PATH Debugging
```bash
# Show PATH components
echo $PATH | tr ':' '\n' | nl

# Find duplicate PATH entries
echo $PATH | tr ':' '\n' | sort | uniq -d

# Check PATH function availability
type _path_prepend _path_append _path_remove
```

#### Environment Variable Debugging
```bash
# Check if environment variables are properly loaded
printenv | grep -E "(API_KEY|TOKEN)" | wc -l

# Test secure environment loading
source ~/.config/zsh/.zshrc.pre-plugins.d/005-secure-env.zsh
echo "Keys loaded: $(printenv | grep -E '(API_KEY|TOKEN)' | wc -l)"
```

### Health Check Script

Create `~/.config/zsh/health-check.zsh`:
```bash
#!/usr/bin/env zsh
# Zsh Configuration Health Check

echo "🔍 Zsh Configuration Health Check"
echo "================================"

# Check syntax of main files
for file in ~/.config/zsh/{.zshenv,.zshrc} ~/.config/zsh/.zshrc.d/*.zsh; do
    if [[ -f "$file" ]]; then
        if zsh -n "$file" 2>/dev/null; then
            echo "✅ $file - Syntax OK"
        else
            echo "❌ $file - Syntax Error"
        fi
    fi
done

# Check for exposed credentials
if grep -r "sk-" ~/.config/zsh/ --exclude-dir=.env 2>/dev/null; then
    echo "⚠️  Possible exposed API keys found!"
else
    echo "✅ No exposed API keys detected"
fi

# Check PATH sanity
if echo $PATH | grep -q "/usr/bin"; then
    echo "✅ System PATH includes /usr/bin"
else
    echo "❌ System PATH missing /usr/bin"
fi

# Check zgenom setup
if [[ -n "$ZGEN_DIR" && -d "$ZGEN_DIR" ]]; then
    echo "✅ zgenom directory exists: $ZGEN_DIR"
else
    echo "⚠️  zgenom directory not found"
fi

# Check startup time
startup_time=$(time zsh -i -c exit 2>&1 | grep real | awk '{print $2}')
echo "⏱️  Startup time: $startup_time"

echo "
💡 Recommendations:
- Run 'zsh health-check.zsh' monthly
- Keep startup time under 2 seconds
- Update plugins quarterly: 'zgenom update'
- Backup config before major changes
"
```

### Maintenance Schedule

#### Weekly
- Monitor startup performance
- Check for new plugin updates
- Review error logs

#### Monthly  
- Run health check script
- Clean plugin cache: `zgenom reset`
- Update core plugins: `zgenom update`

#### Quarterly
- Review and optimize plugin list
- Update zsh-quickstart-kit
- Security audit of configuration

### Prevention Best Practices

#### Configuration Management
1. **Version Control Integration:**
```bash
# Initialize git in zsh config directory
cd ~/.config/zsh
git init
echo "/.env/" >> .gitignore
echo ".zgenom/" >> .gitignore
git add .
git commit -m "Initial zsh configuration"
```

2. **Backup Strategy:**
```bash
# Create automated backup script
cat > ~/.config/zsh/backup-config.sh << 'EOF'
#!/bin/bash
backup_dir="$HOME/.config/zsh-backups/$(date +%Y-%m-%d)"
mkdir -p "$backup_dir"
cp -r ~/.config/zsh/{.zshenv,.zshrc,.zshrc.d,.zshrc.pre-plugins.d} "$backup_dir/"
echo "Backup created: $backup_dir"
EOF
chmod +x ~/.config/zsh/backup-config.sh
```

3. **Testing New Changes:**
```bash
# Test configuration in a subshell
zsh --rcs ~/.config/zsh/.zshrc.testing

# Use separate environment for testing
ZDOTDIR=/tmp/zsh-test zsh
```

#### Plugin Management Best Practices
1. Pin plugin versions for stability
2. Test plugins in isolation before adding
3. Document plugin purposes and configurations
4. Regular cleanup of unused plugins

#### Security Maintenance
1. Rotate API keys regularly
2. Audit file permissions monthly
3. Monitor for credential leaks in logs
4. Use separate keys for development/production

### Troubleshooting Common Issues

#### Slow Startup
```bash
# Profile and identify bottlenecks
zmodload zsh/zprof
# ... start new shell ...
zprof | head -10
```

#### Plugin Conflicts
```bash
# Disable plugins one by one to isolate
zgenom list | while read plugin; do
    echo "Testing without: $plugin"
    # Comment out in config and test
done
```

#### PATH Issues
```bash
# Reset PATH and rebuild
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
source ~/.config/zsh/.zshenv
echo $PATH
```

#### Permission Problems
```bash
# Fix zsh config permissions
find ~/.config/zsh -type f -exec chmod 644 {} \;
find ~/.config/zsh -type d -exec chmod 755 {} \;
chmod 600 ~/.config/zsh/.env/*
```

### Emergency Recovery

If zsh becomes unusable:
```bash
# Switch to bash temporarily
bash

# Reset to minimal configuration
mv ~/.config/zsh ~/.config/zsh.broken
mkdir ~/.config/zsh
echo 'export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"' > ~/.config/zsh/.zshenv

# Gradually restore from backup
# ... then debug the issues
```
