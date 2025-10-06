# 3. Versioned Configuration Management Strategy

## Table of Contents

1. [Overview](#1-overview)
2. [Architecture Evolution](#2-architecture-evolution)
   1. [Basic Architecture vs. Versioned Architecture](#21-basic-architecture-vs-versioned-architecture)
3. [Configuration Lifecycle](#3-configuration-lifecycle)
   1. [Development to Production Pipeline](#31-development-to-production-pipeline)
   2. [Version Management Strategy](#32-version-management-strategy)
4. [Implementation Details](#4-implementation-details)
   1. [Directory Structure](#41-directory-structure)
   2. [Configuration Management Scripts](#42-configuration-management-scripts)
5. [Advanced Configuration Management](#5-advanced-configuration-management)
   1. [Configuration Diff Tool](#51-configuration-diff-tool)
   2. [Configuration Merge Tool](#52-configuration-merge-tool)
6. [Zgenom Integration with Versioned Configurations](#6-zgenom-integration-with-versioned-configurations)
   1. [Shared Zgenom Strategy](#61-shared-zgenom-strategy)
   2. [Zgenom Cache Management](#62-zgenom-cache-management)
7. [Deployment Workflow](#7-deployment-workflow)
   1. [Standard Deployment Process](#71-standard-deployment-process)
   2. [Emergency Rollback](#72-emergency-rollback)
8. [Configuration Metadata](#8-configuration-metadata)
   1. [Version Tracking](#81-version-tracking)
   2. [Change Log](#82-change-log)
9. [Benefits of Versioned Approach](#9-benefits-of-versioned-approach)
   1. [Advantages](#91-advantages)
   2. [Trade-offs](#92-trade-offs)
10. [Migration Strategy](#10-migration-strategy)

## 1. Overview

This document outlines a versioned configuration management strategy that extends the basic `.00/.dev` approach to support multiple stable configuration versions with a clear promotion path from development to production.

## 2. Architecture Evolution

### 2.1 Basic Architecture vs. Versioned Architecture

#### Basic Architecture (Original)

```
.zshenv → .zshenv.active → .zshenv.00/.dev
.zshrc.pre-plugins.d → .zshrc.pre-plugins.d.active → .zshrc.pre-plugins.d.00/.dev
.zshrc.add-plugins.d → .zshrc.add-plugins.d.active → .zshrc.add-plugins.d.00/.dev
.zshrc.d → .zshrc.d.active → .zshrc.d.00/.dev
```

#### Versioned Architecture (Enhanced)

```
.zshenv → .zshenv.active → .zshenv.00/.01/.02/.dev
.zshrc.pre-plugins.d → .zshrc.pre-plugins.d.active → .zshrc.pre-plugins.d.00/.01/.02/.dev
.zshrc.add-plugins.d → .zshrc.add-plugins.d.active → .zshrc.add-plugins.d.00/.01/.02/.dev
.zshrc.d → .zshrc.d.active → .zshrc.d.00/.01/.02/.dev
```

## 3. Configuration Lifecycle

### 3.1 Development to Production Pipeline

```
.dev → .01 → .02 → .03 → ... → .00 (current stable)
```

#### Flow Description

1. **Development Phase (`.dev`)**
   - Experimental changes and new features
   - Safe testing environment
   - Isolated from production configurations

2. **Staging Phase (`.01`, `.02`, etc.)**
   - Tested configurations ready for deployment
   - Multiple versions can coexist
   - Gradual promotion path

3. **Production Phase (`.00`)**
   - Current stable configuration
   - Proven and tested
   - Default fallback position

### 3.2 Version Management Strategy

#### Semantic Versioning for Configurations

- `.00` - Current stable production version
- `.01` - Previous production version (rollback target)
- `.02` - Older production version (archive)
- `.dev` - Active development version

#### Version Promotion Workflow

```bash
# Step 1: Development complete in .dev
./config-status.sh  # Shows: Active: .dev

# Step 2: Promote .dev to .01 (new staging version)
./bin/promote-config.sh dev 01

# Step 3: Test .01 configuration
./bin/switch-to-config.sh 01
./bin/validate-config.sh 01

# Step 4: If .01 is stable, promote to .00 (production)
./bin/promote-config.sh 01 00

# Step 5: Archive old .00 to .02
./bin/promote-config.sh 00 02
```

## 4. Implementation Details

### 4.1 Directory Structure

```
.zshenv.00          # Current stable
.zshenv.01          # Previous stable (rollback)
.zshenv.02          # Archive
.zshenv.dev         # Development

.zshrc.pre-plugins.d.00/
.zshrc.pre-plugins.d.01/
.zshrc.pre-plugins.d.02/
.zshrc.pre-plugins.d.dev/

.zshrc.add-plugins.d.00/
.zshrc.add-plugins.d.01/
.zshrc.add-plugins.d.02/
.zshrc.add-plugins.d.dev/

.zshrc.d.00/
.zshrc.d.01/
.zshrc.d.02/
.zshrc.d.dev/
```

### 4.2 Configuration Management Scripts

#### promote-config.sh

```bash
#!/bin/bash
# bin/promote-config.sh - Promote configuration from one version to another

set -euo pipefail

SOURCE_VERSION="${1:-dev}"
TARGET_VERSION="${2:-01}"

# Validate source exists
if [[ ! -f ".zshenv.${SOURCE_VERSION}" ]]; then
    echo "❌ Source configuration .zshenv.${SOURCE_VERSION} not found"
    exit 1
fi

# Check if target already exists
if [[ -f ".zshenv.${TARGET_VERSION}" ]]; then
    echo "⚠️  Target configuration .zshenv.${TARGET_VERSION} already exists"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Promotion cancelled"
        exit 1
    fi
fi

# Backup existing target if it exists
if [[ -f ".zshenv.${TARGET_VERSION}" ]]; then
    backup_name=".zshenv.${TARGET_VERSION}.backup.$(date +%Y%m%d_%H%M%S)"
    cp -a ".zshenv.${TARGET_VERSION}" "$backup_name"
    echo "📦 Backed up existing .zshenv.${TARGET_VERSION} to $backup_name"
fi

# Promote configuration
echo "🚀 Promoting .zshenv.${SOURCE_VERSION} → .zshenv.${TARGET_VERSION}"

# Copy all configuration components
cp -a ".zshenv.${SOURCE_VERSION}" ".zshenv.${TARGET_VERSION}"
cp -a ".zshrc.pre-plugins.d.${SOURCE_VERSION}" ".zshrc.pre-plugins.d.${TARGET_VERSION}"
cp -a ".zshrc.add-plugins.d.${SOURCE_VERSION}" ".zshrc.add-plugins.d.${TARGET_VERSION}"
cp -a ".zshrc.d.${SOURCE_VERSION}" ".zshrc.d.${TARGET_VERSION}"

# Update version metadata
echo "# Promoted from ${SOURCE_VERSION} on $(date)" > ".version.${TARGET_VERSION}.md"
echo "- Source: ${SOURCE_VERSION}" >> ".version.${TARGET_VERSION}.md"
echo "- Target: ${TARGET_VERSION}" >> ".version.${TARGET_VERSION}.md"
echo "- Timestamp: $(date)" >> ".version.${TARGET_VERSION}.md"

echo "✅ Configuration promoted successfully"
echo "💡 Use './bin/switch-to-config.sh ${TARGET_VERSION}' to activate"
```

#### switch-to-config.sh

```bash
#!/bin/bash
# bin/switch-to-config.sh - Switch to specific configuration version

set -euo pipefail

TARGET_VERSION="${1:-00}"

# Validate target exists
if [[ ! -f ".zshenv.${TARGET_VERSION}" ]]; then
    echo "❌ Configuration .zshenv.${TARGET_VERSION} not found"
    echo "Available configurations:"
    ls -1 .zshenv.* | grep -E '\.(00|01|02|dev)$' | sed 's/\.zshenv\.//'
    exit 1
fi

# Pre-switch validation
echo "🔍 Validating configuration ${TARGET_VERSION}..."
if ! ./bin/validate-config.sh "${TARGET_VERSION}"; then
    echo "❌ Configuration validation failed"
    exit 1
fi

# Switch symlinks
echo "🔄 Switching to configuration ${TARGET_VERSION}..."

ln -sf ".zshenv.${TARGET_VERSION}" ".zshenv.active"
ln -sf ".zshrc.pre-plugins.d.${TARGET_VERSION}" ".zshrc.pre-plugins.d.active"
ln -sf ".zshrc.add-plugins.d.${TARGET_VERSION}" ".zshrc.add-plugins.d.active"
ln -sf ".zshrc.d.${TARGET_VERSION}" ".zshrc.d.active"

# Clear zgenom cache to force rebuild
rm -f .zgenom/init.zsh

echo "✅ Switched to configuration ${TARGET_VERSION}"
echo "💡 Run 'exec zsh' to apply changes"

# Post-switch verification
if ./bin/verify-switch.sh "${TARGET_VERSION}"; then
    echo "✅ Configuration switch verified"
else
    echo "⚠️  Configuration switch verification failed - check logs"
fi
```

#### list-configs.sh

```bash
#!/bin/bash
# bin/list-configs.sh - List all available configurations

echo "📋 Available Configurations:"
echo

# Get all configuration versions
configs=(
    "dev:Development"
    "00:Current Stable"
    "01:Previous Stable"
    "02:Archive"
)

for config_info in "${configs[@]}"; do
    IFS=':' read -r version description <<< "$config_info"

    if [[ -f ".zshenv.${version}" ]]; then
        # Check if this is the active configuration
        if [[ -L ".zshenv.active" && "$(readlink .zshenv.active)" == ".zshenv.${version}" ]]; then
            status="🟢 ACTIVE"
        else
            status="⚪ Available"
        fi

        # Get modification time
        if [[ -f ".zshenv.${version}" ]]; then
            mtime=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" ".zshenv.${version}")
        else
            mtime="Unknown"
        fi

        printf "%-3s %-15s %-10s %s\n" "${version}" "${description}" "${status}" "${mtime}"
    fi
done

echo
echo "Use './bin/switch-to-config.sh <version>' to switch configurations"
```

## 5. Advanced Configuration Management

### 5.1 Configuration Diff Tool

```bash
#!/bin/bash
# bin/diff-configs.sh - Compare two configurations

set -euo pipefail

VERSION1="${1:-00}"
VERSION2="${2:-dev}"

echo "🔍 Comparing configurations: ${VERSION1} vs ${VERSION2}"
echo

# Compare file lists
echo "📁 File differences:"
diff -r ".zshrc.pre-plugins.d.${VERSION1}" ".zshrc.pre-plugins.d.${VERSION2}" || true
diff -r ".zshrc.add-plugins.d.${VERSION1}" ".zshrc.add-plugins.d.${VERSION2}" || true
diff -r ".zshrc.d.${VERSION1}" ".zshrc.d.${VERSION2}" || true

echo
echo "📝 Content differences:"
for component in "zshenv" "zshrc.pre-plugins.d" "zshrc.add-plugins.d" "zshrc.d"; do
    if [[ -e ".${component}.${VERSION1}" && -e ".${component}.${VERSION2}" ]]; then
        echo "--- ${component}.${VERSION1}"
        echo "+++ ${component}.${VERSION2}"
        if [[ -d ".${component}.${VERSION1}" ]]; then
            # Directory comparison
            diff -u ".${component}.${VERSION1}" ".${component}.${VERSION2}" || true
        else
            # File comparison
            diff -u ".${component}.${VERSION1}" ".${component}.${VERSION2}" || true
        fi
        echo
    fi
done
```

### 5.2 Configuration Merge Tool

```bash
#!/bin/bash
# bin/merge-configs.sh - Merge changes from one configuration to another

set -euo pipefail

SOURCE="${1:-dev}"
TARGET="${2:-01}"

echo "🔀 Merging changes from ${SOURCE} to ${TARGET}"
echo

# Create backup of target
backup_name=".zshenv.${TARGET}.backup.$(date +%Y%m%d_%H%M%S)"
cp -a ".zshenv.${TARGET}" "$backup_name"
echo "📦 Backed up ${TARGET} to $backup_name"

# Perform three-way merge if base exists
if [[ -f ".zshenv.00" && "$TARGET" != "00" ]]; then
    echo "🔄 Performing three-way merge (00 ← ${SOURCE} → ${TARGET})"

    # This would use a more sophisticated merge strategy
    # For now, we'll copy and note conflicts
    cp -a ".zshenv.${SOURCE}" ".zshenv.${TARGET}"
    cp -a ".zshrc.pre-plugins.d.${SOURCE}" ".zshrc.pre-plugins.d.${TARGET}"
    cp -a ".zshrc.add-plugins.d.${SOURCE}" ".zshrc.add-plugins.d.${TARGET}"
    cp -a ".zshrc.d.${SOURCE}" ".zshrc.d.${TARGET}"

    echo "⚠️  Manual merge review recommended"
else
    echo "📋 Copying ${SOURCE} to ${TARGET}"
    cp -a ".zshenv.${SOURCE}" ".zshenv.${TARGET}"
    cp -a ".zshrc.pre-plugins.d.${SOURCE}" ".zshrc.pre-plugins.d.${TARGET}"
    cp -a ".zshrc.add-plugins.d.${SOURCE}" ".zshrc.add-plugins.d.${TARGET}"
    cp -a ".zshrc.d.${SOURCE}" ".zshrc.d.${TARGET}"
fi

echo "✅ Merge completed"
echo "💡 Review changes with './bin/diff-configs.sh ${TARGET} ${SOURCE}'"
```

## 6. Zgenom Integration with Versioned Configurations

### 6.1 Shared Zgenom Strategy

Since `.zgenom` is vendored, it remains shared across all configurations:

```bash
# Shared plugin directory
.zgenom/ (vendored plugins - shared across all versions)

# Configuration-specific init files
.zgenom.init.00
.zgenom.init.01
.zgenom.init.dev

# Zgenom setup in .zshenv
ZGENOM_INIT_FILE="${ZDOTDIR}/.zgenom.init.${ZSH_CONFIG_MODE:-00}"
```

### 6.2 Zgenom Cache Management

```bash
# In each configuration version's .zshenv
export ZGENOM_INIT_FILE="${ZDOTDIR}/.zgenom.init.${ZSH_CONFIG_MODE:-00}"

# Clear cache when switching configurations
rm -f "${ZDOTDIR}/.zgenom/init.zsh"
```

## 7. Deployment Workflow

### 7.1 Standard Deployment Process

```bash
# 1. Development complete
./bin/validate-config.sh dev

# 2. Promote to staging
./bin/promote-config.sh dev 01

# 3. Test staging configuration
./bin/switch-to-config.sh 01
./bin/test-configuration.sh 01

# 4. Deploy to production
./bin/switch-to-config.sh 00  # Switch back to current stable
./bin/promote-config.sh 01 00  # Promote staging to production

# 5. Archive old production
./bin/promote-config.sh 00 02  # Archive old production

# 6. Switch to new production
./bin/switch-to-config.sh 00
```

### 7.2 Emergency Rollback

```bash
# Quick rollback to previous stable
./bin/switch-to-config.sh 01

# If 01 is also problematic, rollback to archive
./bin/switch-to-config.sh 02

# Emergency rollback to development (if needed)
./bin/switch-to-config.sh dev
```

## 8. Configuration Metadata

### 8.1 Version Tracking

Each configuration version maintains metadata:

```markdown
# .version.01.md

## Configuration Version 01

**Source:** dev
**Promoted:** 2024-01-15 14:30:00
**Changes:**
- Added new FZF integration
- Updated PHP development tools
- Performance optimizations

**Testing Status:** ✅ Passed
**Deployment Status:** ✅ Production Ready
```

### 8.2 Change Log

```markdown
# CHANGELOG.md

## [0.1.0] - 2024-01-15

### Added

- Versioned configuration management
- Configuration promotion scripts
- Enhanced testing framework

### Changed

- Improved symlink architecture
- Updated zgenom integration

## [0.0.0] - 2024-01-01

### Added

- Initial layered configuration system
- Basic .00/.dev separation
```

## 9. Benefits of Versioned Approach

### 9.1 Advantages

1. **Safe Deployment Path**: Clear promotion from dev → staging → production
2. **Rollback Capability**: Multiple rollback targets available
3. **Configuration History**: Track changes over time
4. **Parallel Testing**: Multiple versions can coexist
5. **Gradual Migration**: No forced upgrades
6. **Disaster Recovery**: Multiple recovery points

### 9.2 Trade-offs

1. **Increased Complexity**: More configuration versions to manage
2. **Storage Overhead**: Multiple configuration copies
3. **Maintenance Overhead**: Keeping versions synchronized
4. **Testing Complexity**: Need to test multiple versions

## 10. Migration Strategy

### From Basic to Versioned Architecture

```bash
# Step 1: Backup current setup
cp -a .zshenv.00 .zshenv.backup
cp -a .zshrc.*.d.00 .zshrc.*.d.backup

# Step 2: Create version management scripts
# (Install all the bin/ scripts)

# Step 3: Initialize version tracking
echo "# Initial configuration" > .version.00.md
echo "- Created: $(date)" >> .version.00.md

# Step 4: Test version switching
./bin/switch-to-config.sh 00
./bin/list-configs.sh
```

## Conclusion

The versioned configuration management strategy provides a robust, production-ready approach to configuration management that supports safe deployment, easy rollback, and comprehensive change tracking. This approach is particularly valuable for critical shell configurations where stability and reliability are paramount.

The strategy maintains the simplicity of the basic layered approach while adding enterprise-grade configuration management capabilities.

---

## Navigation

- [Previous](020-symlink-architecture.md) - Symlink architecture analysis
- [Next](040-implementation-guide.md) - Implementation guide
- [Top](#top) - Back to top

---

*Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v<checksum>*
