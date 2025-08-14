# Migration Guide: Python to PHP Link Validation Tools

## 🎯 Overview

This guide provides step-by-step instructions for migrating from the existing Python-based link validation tools to the new PHP-based system while maintaining compatibility and ensuring a smooth transition.

## 📋 Pre-Migration Checklist

### System Requirements
- [ ] **PHP 8.4+** installed and accessible via command line
- [ ] **File system permissions** for reading documentation and writing reports
- [ ] **Network access** for external link validation (if used)
- [ ] **Backup strategy** for existing validation reports and configurations

### Compatibility Verification
```bash
# Check PHP version
php --version

# Verify PHP extensions (should be available by default)
php -m | grep -E "(json|pcre|fileinfo)"

# Test basic functionality
php .ai/tools/run-tests.php
```

## 🔄 Migration Phases

### Phase 1: Installation and Testing (Week 1)

#### 1.1 Install PHP Tools
The PHP tools are already installed in your `.ai/tools/` directory:
```bash
# Verify installation
ls -la .ai/tools/link-validator.php
ls -la .ai/tools/link-rectifier.php
ls -la .ai/tools/LinkValidator/
ls -la .ai/tools/LinkRectifier/
```

#### 1.2 Make Scripts Executable
```bash
chmod +x .ai/tools/link-validator.php
chmod +x .ai/tools/link-rectifier.php
```

#### 1.3 Run Parallel Validation
Test both systems on the same documentation to verify compatibility:

```bash
# Run existing Python validation
python3 .ai/tools/chinook_link_integrity_audit.py

# Run new PHP validation
php .ai/tools/link-validator.php docs/ --format=json --output=.ai/reports/php-validation.json

# Compare results
diff .ai/reports/automated/validation_detailed_*.json .ai/reports/php-validation.json
```

#### 1.4 Validate Anchor Generation
Ensure the GitHub anchor generation algorithm produces identical results:

```bash
# Test anchor generation compatibility
php -r "
require_once '.ai/tools/LinkValidator/Core/GitHubAnchorGenerator.php';
\$gen = new LinkValidator\Core\GitHubAnchorGenerator();
\$tests = \$gen->runTests();
echo 'Anchor tests: ' . \$tests['passed'] . ' passed, ' . \$tests['failed'] . ' failed\n';
if (\$tests['failed'] > 0) {
    foreach (\$tests['failures'] as \$failure) {
        echo 'FAIL: ' . \$failure . \"\n\";
    }
}
"
```

### Phase 2: Configuration Migration (Week 2)

#### 2.1 Create PHP Configuration File
Convert your existing Python configuration to PHP format:

```bash
# Create .link-validator.json in project root
cat > .link-validator.json << 'EOF'
{
  "scope": ["internal", "anchor", "cross-reference"],
  "max_broken": 10,
  "exclude_patterns": [
    "*.backup.md",
    "temp/*",
    "node_modules/*",
    ".git/*"
  ],
  "check_external": false,
  "timeout": 30,
  "max_depth": 5,
  "include_hidden": false,
  "case_sensitive": false,
  "format": "console",
  "report_directory": ".ai/reports/automated",
  "history_retention_days": 30
}
EOF
```

#### 2.2 Set Environment Variables (Optional)
For CI/CD integration:

```bash
# Add to your CI/CD environment
export LINK_VALIDATOR_SCOPE="internal,anchor"
export LINK_VALIDATOR_MAX_BROKEN=10
export LINK_VALIDATOR_CHECK_EXTERNAL=false
export LINK_VALIDATOR_FORMAT=json
```

#### 2.3 Test Configuration Loading
```bash
# Test with configuration file
php .ai/tools/link-validator.php docs/ --config=.link-validator.json --dry-run

# Test with environment variables
LINK_VALIDATOR_SCOPE=internal,anchor php .ai/tools/link-validator.php docs/ --dry-run
```

### Phase 3: CI/CD Integration (Week 3)

#### 3.1 Update CI/CD Scripts
Replace Python commands with PHP equivalents:

**Before (Python):**
```bash
# In your CI/CD pipeline
python3 .ai/tools/automated_link_validation.py --ci
python3 .ai/tools/chinook_link_integrity_audit.py
```

**After (PHP):**
```bash
# In your CI/CD pipeline
php .ai/tools/link-validator.php docs/ --max-broken=5 --quiet --format=json
php .ai/tools/link-validator.php docs/ --scope=internal,anchor --max-broken=10
```

#### 3.2 Update Shell Scripts
Modify existing shell scripts to use PHP tools:

**Update `.ai/tools/validate-chinook-links.sh`:**
```bash
#!/bin/bash
# Updated to use PHP tools

echo "🔗 Running PHP Link Validation..."

# Run validation with PHP
php .ai/tools/link-validator.php docs/ \
    --scope=internal,anchor,cross-reference \
    --max-broken=10 \
    --format=json \
    --output=.ai/reports/automated/validation_detailed_$(date +%Y%m%d_%H%M%S).json

# Check exit code
if [ $? -eq 0 ]; then
    echo "✅ Link validation passed"
else
    echo "❌ Link validation failed"
    exit 1
fi
```

#### 3.3 Verify Exit Codes
Ensure your CI/CD system handles the standardized exit codes:

- **0**: Success - all links valid or within threshold
- **1**: Validation failures - broken links exceed threshold
- **2**: System errors - file access, network, or runtime errors
- **3**: Configuration errors - invalid arguments or config

### Phase 4: Team Training (Week 4)

#### 4.1 Developer Training
Train team members on new CLI interface:

```bash
# Basic validation
php .ai/tools/link-validator.php docs/

# Advanced validation with options
php .ai/tools/link-validator.php docs/ \
    --scope=internal,anchor \
    --exclude="*.backup.md,temp/*" \
    --max-depth=3 \
    --verbose

# Link fixing (new capability)
php .ai/tools/link-rectifier.php docs/ --dry-run
php .ai/tools/link-rectifier.php docs/ --interactive
```

#### 4.2 Create Team Documentation
Document common workflows for your team:

```markdown
# Team Link Validation Workflows

## Daily Development
```bash
# Quick validation during development
php .ai/tools/link-validator.php docs/ --scope=internal,anchor
```

## Pre-commit Validation
```bash
# Comprehensive validation before committing
php .ai/tools/link-validator.php docs/ --max-broken=0 --verbose
```

## Fixing Broken Links
```bash
# Preview fixes
php .ai/tools/link-rectifier.php docs/ --dry-run

# Apply fixes interactively
php .ai/tools/link-rectifier.php docs/ --interactive

# Rollback if needed
php .ai/tools/link-rectifier.php --rollback=2024-01-15-14-30-00
```
```

### Phase 5: Full Migration (Week 5)

#### 5.1 Remove Python Dependencies
Once PHP tools are fully validated:

```bash
# Archive Python tools (don't delete immediately)
mkdir .ai/tools/archive/
mv .ai/tools/chinook_link_integrity_audit.py .ai/tools/archive/
mv .ai/tools/automated_link_validation.py .ai/tools/archive/
mv .ai/tools/link_integrity_analysis.py .ai/tools/archive/

# Update .gitignore if needed
echo ".ai/tools/archive/" >> .gitignore
```

#### 5.2 Update Documentation
Update project documentation to reference PHP tools:

```markdown
# Update README.md or similar
## Link Validation

To validate links in the documentation:

```bash
# Validate all links
php .ai/tools/link-validator.php docs/

# Fix broken links
php .ai/tools/link-rectifier.php docs/ --interactive
```

For CI/CD integration, see `.ai/tools/README.md`.
```

#### 5.3 Establish Maintenance Procedures
Set up regular maintenance tasks:

```bash
# Add to cron or CI/CD for cleanup
# Clean up old backups (keep 30 days)
find .ai/backups/ -type d -mtime +30 -exec rm -rf {} \;

# Clean up old reports (keep 90 days)
find .ai/reports/automated/ -name "*.json" -mtime +90 -delete
find .ai/reports/automated/ -name "*.md" -mtime +90 -delete
```

## 🔧 Command Mapping Reference

### Validation Commands

| Python Command | PHP Equivalent | Notes |
|----------------|----------------|-------|
| `python3 .ai/tools/chinook_link_integrity_audit.py` | `php .ai/tools/link-validator.php docs/` | Basic validation |
| `python3 .ai/tools/automated_link_validation.py --ci` | `php .ai/tools/link-validator.php docs/ --quiet --max-broken=5` | CI/CD mode |
| `python3 .ai/tools/link_integrity_analysis.py` | `php .ai/tools/link-validator.php docs/ --format=html --output=report.html` | Detailed analysis |

### New Capabilities (PHP Only)

| Feature | PHP Command | Description |
|---------|-------------|-------------|
| Link Fixing | `php .ai/tools/link-rectifier.php docs/ --interactive` | Interactive link fixing |
| Dry Run | `php .ai/tools/link-rectifier.php docs/ --dry-run` | Preview changes |
| Backup/Rollback | `php .ai/tools/link-rectifier.php --rollback=TIMESTAMP` | Restore previous state |
| Configuration | `php .ai/tools/link-validator.php --config=.link-validator.json` | JSON configuration |

## 🚨 Troubleshooting

### Common Issues

#### "No valid files found to process"
```bash
# Check file permissions and extensions
ls -la docs/
php .ai/tools/link-validator.php docs/ --include-hidden --verbose
```

#### "Cannot create backup directory"
```bash
# Check permissions
ls -la .ai/
mkdir -p .ai/backups/
chmod 755 .ai/backups/
```

#### "External link validation timeout"
```bash
# Increase timeout or skip external links
php .ai/tools/link-validator.php docs/ --timeout=60
php .ai/tools/link-validator.php docs/ --scope=internal,anchor
```

### Getting Help

```bash
# Show detailed help
php .ai/tools/link-validator.php --help
php .ai/tools/link-rectifier.php --help

# Enable debug mode
php .ai/tools/link-validator.php docs/ --debug
```

## ✅ Migration Checklist

- [ ] PHP 8.4+ installed and tested
- [ ] PHP tools executable and functional
- [ ] Parallel validation results match
- [ ] Configuration file created and tested
- [ ] CI/CD pipelines updated
- [ ] Team trained on new commands
- [ ] Documentation updated
- [ ] Python tools archived
- [ ] Maintenance procedures established

## 📞 Support

If you encounter issues during migration:

1. **Check the test suite**: `php .ai/tools/run-tests.php`
2. **Enable debug mode**: Add `--debug` to any command
3. **Review logs**: Check `.ai/reports/automated/` for detailed reports
4. **Consult documentation**: See `.ai/tools/README.md` for comprehensive examples

The migration should be smooth and provide immediate benefits including enhanced security, better performance, and new link fixing capabilities.
