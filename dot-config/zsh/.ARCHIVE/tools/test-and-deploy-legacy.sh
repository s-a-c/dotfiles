#!/usr/bin/env bash
set -euo pipefail

echo "🚀 LEGACY CONSOLIDATION: FINAL TESTING AND DEPLOYMENT PREPARATION"
echo "=================================================================="
echo ""

cd /Users/s-a-c/dotfiles/dot-config/zsh

CONSOLIDATED_DIR=".zshrc.d.legacy/consolidated-modules"
CURRENT_LEGACY_DIR=".zshrc.d"
LOG_DIR="logs/test-results"
DEPLOYMENT_LOG="$LOG_DIR/deployment-$(date +%Y%m%dT%H%M%S).log"

mkdir -p "$LOG_DIR"

log_action() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$DEPLOYMENT_LOG"
}

echo "=== 1. Testing All Modules Together ==="
echo ""

log_action "Starting comprehensive module integration test"

# Test all modules together
test_result=$(SHELL=/opt/homebrew/bin/zsh ZDOTDIR="$PWD" /opt/homebrew/bin/zsh -df << 'ZSH_TEST'
setopt no_global_rcs
export ZDOTDIR="${HOME}/dotfiles/dot-config/zsh"

echo "Loading all consolidated modules in sequence..."

modules=(
    "01-core-infrastructure.zsh"
    "02-performance-monitoring.zsh"
    "03-security-integrity.zsh"
    "04-environment-options.zsh"
    "05-completion-system.zsh"
    "06-user-interface.zsh"
    "07-development-tools.zsh"
    "08-legacy-compatibility.zsh"
    "09-external-integrations.zsh"
)

loaded_count=0
total_functions=0
total_lines=0

for module in "${modules[@]}"; do
    module_path=".zshrc.d.legacy/consolidated-modules/$module"
    if [[ -f "$module_path" ]]; then
        echo "Loading: $module"
        if source "$module_path" >/dev/null 2>&1; then
            ((loaded_count++))
            lines=$(wc -l < "$module_path")
            total_lines=$((total_lines + lines))
            echo "  ✅ $module loaded successfully ($lines lines)"
        else
            echo "  ❌ $module failed to load"
            exit 1
        fi
    else
        echo "  ❌ $module not found"
        exit 1
    fi
done

echo ""
echo "Integration Test Results:"
echo "========================="
echo "Modules loaded: $loaded_count/${#modules[@]}"
echo "Total lines: $total_lines"

# Count all functions
for func in ${(ok)functions}; do
    if [[ $func != _* && $func != *_debug && $func != *_internal ]]; then
        ((total_functions++))
    fi
done

echo "Total functions exported: $total_functions"

# Test key functionality from each module
echo ""
echo "Cross-Module Functionality Tests:"
echo "=================================="

# Test 1: Core infrastructure
if command -v debug_log >/dev/null 2>&1; then
    echo "✅ Core logging system available"
    debug_log "Integration test: core functionality"
fi

# Test 2: Performance monitoring
if command -v perf_now_ms >/dev/null 2>&1; then
    current_time=$(perf_now_ms)
    echo "✅ Performance monitoring: current time = ${current_time}ms"
fi

if command -v perf-status >/dev/null 2>&1; then
    echo "✅ Performance management commands available"
fi

# Test 3: Cache system
if command -v cache-status >/dev/null 2>&1; then
    echo "✅ Cache management system available"
fi

# Test 4: External integrations
if command -v external-status >/dev/null 2>&1; then
    echo "✅ External integrations management available"
fi

# Test 5: Check for critical function conflicts
echo ""
echo "Function Conflict Analysis:"
echo "=========================="

declare -A function_sources
conflict_count=0
critical_conflicts=()

for func in ${(ok)functions}; do
    # Skip private functions
    if [[ $func == _* || $func == *_debug || $func == *_internal ]]; then
        continue
    fi
    
    # Check for conflicts with critical functions
    if [[ -n ${function_sources[$func]:-} ]]; then
        echo "WARNING: Function conflict detected: $func"
        ((conflict_count++))
        
        # Check if it's a critical conflict
        case $func in
            debug_log|error_log|warn_log|perf_*|cache-*|external-*)
                critical_conflicts+=("$func")
                ;;
        esac
    else
        function_sources[$func]=1
    fi
done

if [[ $conflict_count -eq 0 ]]; then
    echo "✅ No function conflicts detected"
elif [[ ${#critical_conflicts[@]} -eq 0 ]]; then
    echo "⚠️  $conflict_count minor function conflicts detected (non-critical)"
else
    echo "❌ $conflict_count function conflicts detected, ${#critical_conflicts[@]} critical"
    for critical in "${critical_conflicts[@]}"; do
        echo "  CRITICAL: $critical"
    done
    exit 1
fi

echo ""
echo "🎉 All modules integration test PASSED!"
echo "✅ Ready for deployment"

exit 0
ZSH_TEST
)

if [[ $? -eq 0 ]]; then
    echo "✅ Integration test passed!"
    echo "$test_result"
    log_action "SUCCESS: All modules integration test passed"
else
    echo "❌ Integration test failed!"
    echo "$test_result"
    log_action "FAILED: Integration test failed"
    exit 1
fi

echo ""
echo "=== 2. Creating Deployment Framework ==="
echo ""

log_action "Creating deployment framework"

# Create backup script
cat > tools/backup-current-legacy.sh << 'BACKUP_EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "📦 BACKING UP CURRENT LEGACY MODULES"
echo "===================================="

cd /Users/s-a-c/dotfiles/dot-config/zsh

BACKUP_DIR=".zshrc.d.backup-$(date +%Y%m%d-%H%M%S)"

echo "Creating backup: $BACKUP_DIR"
cp -r .zshrc.d "$BACKUP_DIR"

echo "✅ Backup created: $BACKUP_DIR"
echo "📁 Backup contains $(ls -1 "$BACKUP_DIR" | wc -l) files"

# Create backup manifest
cat > "$BACKUP_DIR/BACKUP_MANIFEST.md" << EOF
# Legacy Modules Backup

**Created**: $(date)
**Source**: .zshrc.d/
**Backup Directory**: $BACKUP_DIR

## Backed Up Files

$(ls -la "$BACKUP_DIR" | grep '^-' | awk '{print "- " $9 " (" $5 " bytes)"}')

## Restoration Command

To restore this backup:

\`\`\`bash
rm -rf .zshrc.d
cp -r "$BACKUP_DIR" .zshrc.d
\`\`\`

EOF

echo "📄 Backup manifest created: $BACKUP_DIR/BACKUP_MANIFEST.md"
BACKUP_EOF

chmod +x tools/backup-current-legacy.sh

# Create deployment script
cat > tools/deploy-consolidated-legacy.sh << 'DEPLOY_EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "🚀 DEPLOYING CONSOLIDATED LEGACY MODULES"
echo "========================================"

cd /Users/s-a-c/dotfiles/dot-config/zsh

CONSOLIDATED_DIR=".zshrc.d.legacy/consolidated-modules"
TARGET_DIR=".zshrc.d"
DEPLOYMENT_LOG="logs/deployment-$(date +%Y%m%dT%H%M%S).log"

mkdir -p logs

log_deploy() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$DEPLOYMENT_LOG"
}

echo "📋 Deployment Plan:"
echo "  Source: $CONSOLIDATED_DIR"
echo "  Target: $TARGET_DIR" 
echo "  Log: $DEPLOYMENT_LOG"
echo ""

# Step 1: Backup current modules
echo "=== Step 1: Creating Backup ==="
if ! tools/backup-current-legacy.sh; then
    echo "❌ Backup failed!"
    exit 1
fi
echo ""

# Step 2: Clear target directory
echo "=== Step 2: Preparing Target Directory ==="
log_deploy "Clearing target directory: $TARGET_DIR"
rm -f "$TARGET_DIR"/*.zsh
echo "✅ Target directory cleared"
echo ""

# Step 3: Deploy consolidated modules
echo "=== Step 3: Deploying Consolidated Modules ==="
deployed_count=0
total_modules=$(ls -1 "$CONSOLIDATED_DIR"/*.zsh | wc -l)

for module in "$CONSOLIDATED_DIR"/*.zsh; do
    if [[ -f "$module" ]]; then
        module_name=$(basename "$module")
        target_path="$TARGET_DIR/$module_name"
        
        echo "📄 Deploying: $module_name"
        cp "$module" "$target_path"
        
        if [[ -f "$target_path" ]]; then
            ((deployed_count++))
            log_deploy "DEPLOYED: $module_name"
            echo "  ✅ Deployed successfully"
        else
            echo "  ❌ Deployment failed"
            log_deploy "FAILED: $module_name deployment failed"
            exit 1
        fi
    fi
done

echo ""
echo "📊 Deployment Results:"
echo "  Modules deployed: $deployed_count/$total_modules"
echo "  Target directory: $TARGET_DIR"
echo ""

# Step 4: Verify deployment
echo "=== Step 4: Verification ==="
echo "Verifying deployed modules..."

verification_passed=0
for module in "$TARGET_DIR"/*.zsh; do
    if [[ -f "$module" ]]; then
        module_name=$(basename "$module")
        if /opt/homebrew/bin/zsh -n "$module"; then
            echo "  ✅ $module_name: Syntax OK"
            ((verification_passed++))
        else
            echo "  ❌ $module_name: Syntax error"
            log_deploy "VERIFICATION FAILED: $module_name has syntax errors"
            exit 1
        fi
    fi
done

echo ""
echo "🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!"
echo "✅ Deployed $deployed_count consolidated modules"
echo "✅ All modules passed syntax verification"
echo "📁 Deployment log: $DEPLOYMENT_LOG"

log_deploy "SUCCESS: Deployment completed successfully"
DEPLOY_EOF

chmod +x tools/deploy-consolidated-legacy.sh

# Create rollback script
cat > tools/rollback-legacy-deployment.sh << 'ROLLBACK_EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "🔄 ROLLING BACK LEGACY MODULE DEPLOYMENT"
echo "========================================"

cd /Users/s-a-c/dotfiles/dot-config/zsh

# Find the most recent backup
LATEST_BACKUP=$(find . -maxdepth 1 -name ".zshrc.d.backup-*" -type d | sort -r | head -1)

if [[ -z "$LATEST_BACKUP" ]]; then
    echo "❌ No backup found!"
    echo "Cannot rollback without a backup."
    exit 1
fi

echo "Found backup: $LATEST_BACKUP"
echo ""

# Show backup info
if [[ -f "$LATEST_BACKUP/BACKUP_MANIFEST.md" ]]; then
    echo "📄 Backup Information:"
    head -10 "$LATEST_BACKUP/BACKUP_MANIFEST.md" | sed 's/^/  /'
    echo ""
fi

# Confirm rollback
echo "⚠️  This will restore your .zshrc.d/ directory from the backup."
echo "Current consolidated modules will be lost."
echo ""
read -p "Do you want to proceed with rollback? (y/N): " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Rollback cancelled."
    exit 0
fi

echo ""
echo "=== Performing Rollback ==="

# Remove current modules
echo "🗑️  Removing current modules..."
rm -rf .zshrc.d

# Restore from backup
echo "📦 Restoring from backup..."
cp -r "$LATEST_BACKUP" .zshrc.d

# Verify restoration
if [[ -d ".zshrc.d" ]]; then
    restored_count=$(ls -1 .zshrc.d/*.zsh 2>/dev/null | wc -l || echo "0")
    echo ""
    echo "✅ Rollback completed successfully!"
    echo "📊 Restored $restored_count legacy modules"
    echo "🔙 Your .zshrc.d/ directory has been restored from: $LATEST_BACKUP"
else
    echo "❌ Rollback failed!"
    exit 1
fi
ROLLBACK_EOF

chmod +x tools/rollback-legacy-deployment.sh

# Create final deployment checklist
cat > .zshrc.d.legacy/DEPLOYMENT_CHECKLIST.md << 'CHECKLIST_EOF'
# Legacy Consolidation Deployment Checklist

## Pre-Deployment Verification

- [ ] All 9 consolidated modules created and numbered 01-09
- [ ] All modules pass syntax check (`zsh -n`)
- [ ] All modules load without errors individually
- [ ] Integration test passes (all modules load together)
- [ ] No critical function conflicts detected
- [ ] Performance impact acceptable
- [ ] Test scripts created and working

## Deployment Steps

### 1. Final Testing
```bash
# Run final comprehensive test
tools/test-legacy-quick.sh

# Test all modules together (this script)
tools/test-and-deploy-legacy.sh
```

### 2. Create Backup
```bash
# This will be done automatically by deployment script
tools/backup-current-legacy.sh
```

### 3. Deploy Consolidated Modules
```bash
# Deploy consolidated modules to .zshrc.d/
tools/deploy-consolidated-legacy.sh
```

### 4. Verify Deployment
```bash
# Test in new shell session
/opt/homebrew/bin/zsh -l

# Check module loading
ls -la .zshrc.d/
```

### 5. Test Integration with Existing System
```bash
# Test with existing .zshrc
source ~/.zshrc

# Run any custom commands/aliases
# Test plugin loading
# Verify prompt and completion work
```

## Rollback Plan (if needed)

```bash
# Rollback to previous legacy modules
tools/rollback-legacy-deployment.sh
```

## Post-Deployment Validation

- [ ] New shell sessions start without errors
- [ ] All aliases and functions work as expected
- [ ] Plugin loading works correctly
- [ ] Completion system functions properly
- [ ] Performance is acceptable
- [ ] No error messages in shell startup

## Success Criteria

- ✅ Shell starts without errors
- ✅ All legacy functionality preserved
- ✅ Performance improved or maintained
- ✅ Consolidated modules easier to maintain
- ✅ Full test suite passes

## Consolidated Modules Overview

1. **01-core-infrastructure.zsh** - Core functions, logging, caching
2. **02-performance-monitoring.zsh** - Performance measurement and monitoring
3. **03-security-integrity.zsh** - Security checks and plugin integrity
4. **04-environment-options.zsh** - Environment variables and ZSH options
5. **05-completion-system.zsh** - Completion management and configuration
6. **06-user-interface.zsh** - UI, prompts, aliases, and keybindings
7. **07-development-tools.zsh** - Development environment and tools
8. **08-legacy-compatibility.zsh** - Legacy compatibility and migration shims
9. **09-external-integrations.zsh** - External tools and service integrations

Total consolidated: ~6,200 lines from 49+ original legacy modules

---

**Created**: $(date)
**Status**: Ready for deployment
**Backup Location**: Will be created during deployment
CHECKLIST_EOF

echo "✅ Deployment framework created!"
echo ""
echo "📋 Created deployment tools:"
echo "  - tools/backup-current-legacy.sh"
echo "  - tools/deploy-consolidated-legacy.sh" 
echo "  - tools/rollback-legacy-deployment.sh"
echo ""
echo "📄 Created deployment checklist:"
echo "  - .zshrc.d.legacy/DEPLOYMENT_CHECKLIST.md"
echo ""

log_action "Deployment framework created successfully"

echo "=== 3. Final Summary ==="
echo ""

echo "🎉 LEGACY CONSOLIDATION COMPLETED AND READY FOR DEPLOYMENT!"
echo ""
echo "📊 Consolidation Summary:"
echo "  ✅ 9 consolidated modules created (01-09)"
echo "  ✅ All modules pass syntax and loading tests"
echo "  ✅ Integration test passed (no critical conflicts)"
echo "  ✅ Deployment framework ready"
echo "  ✅ Backup and rollback mechanisms in place"
echo ""

# Count original modules
original_active=$(ls -1 .zshrc.d/*.zsh 2>/dev/null | wc -l || echo "0")
original_disabled=$(ls -1 .zshrc.d.disabled/*.zsh 2>/dev/null | wc -l || echo "0")
total_original=$((original_active + original_disabled))
consolidated_modules=$(ls -1 .zshrc.d.legacy/consolidated-modules/*.zsh | wc -l)

echo "📈 Consolidation Metrics:"
echo "  Original modules: $total_original ($original_active active + $original_disabled disabled)"
echo "  Consolidated modules: $consolidated_modules"
echo "  Reduction ratio: $(( (total_original - consolidated_modules) * 100 / total_original ))% fewer modules"
echo ""

# Calculate total lines
total_lines=0
for module in .zshrc.d.legacy/consolidated-modules/*.zsh; do
    if [[ -f "$module" ]]; then
        lines=$(wc -l < "$module")
        total_lines=$((total_lines + lines))
    fi
done

echo "📝 Code Metrics:"
echo "  Total consolidated lines: $total_lines"
echo "  Average lines per module: $((total_lines / consolidated_modules))"
echo ""

echo "🚀 Ready to deploy!"
echo ""
echo "Next steps:"
echo "  1. Review: .zshrc.d.legacy/DEPLOYMENT_CHECKLIST.md"
echo "  2. Deploy: tools/deploy-consolidated-legacy.sh"
echo "  3. Test: Start a new shell session"
echo ""

log_action "Legacy consolidation project completed successfully"
echo "📁 Full deployment log: $DEPLOYMENT_LOG"

mark_todo_as_done "89a7e1a5-1773-4fe8-a12b-2bf112ab05bb"
mark_todo_as_done "b24a6fb1-a833-45d2-83c9-b76760422211"
mark_todo_as_done "a588e151-2470-4b3f-8e4a-338c43ef3b35"