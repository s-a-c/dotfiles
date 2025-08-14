# Changelog

All notable changes to the validate-links package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-07-20

### Added

#### **Core Features**
- ✅ **Complete Link Validation Engine** - Validates internal, anchor, cross-reference, and external links
- ✅ **GitHub-Compatible Anchor Generation** - Uses the same algorithm as GitHub for heading anchors
- ✅ **Multi-Format Support** - Markdown, HTML, and text-based file validation
- ✅ **Advanced Filtering** - Scope control, directory depth, pattern matching, hidden file handling

#### **Enhanced CLI Interface**
- ✅ **New `--fix` Argument** - Enable automatic link remediation after validation
- ✅ **Enhanced `--dry-run` Mode** - Preview validation scope and fixing actions
- ✅ **Dual Termination Conditions** - `--max-files` and `--max-broken` work independently
- ✅ **Comprehensive Progress Tracking** - Real-time validation progress with verbose mode

#### **Behavior Logic**
- ✅ **Without `--fix`**: Only validation performed (backward compatible)
- ✅ **With `--fix`**: Validation first, then automatic link fixing
- ✅ **With `--fix --dry-run`**: Preview what fixes would be applied
- ✅ **With `--dry-run` only**: Show validation scope preview

#### **Performance Optimization**
- ✅ **Early Termination Logic** - Stop after N files or broken links for CI/CD efficiency
- ✅ **Memory Efficient Processing** - Optimized for large documentation sets
- ✅ **Statistics Collection** - Pre-validation analysis for scope planning
- ✅ **Concurrent Processing** - Parallel external link validation

#### **Comprehensive Reporting**
- ✅ **Multiple Output Formats** - Console, JSON, Markdown, HTML
- ✅ **Colored Console Output** - Enhanced readability with status indicators
- ✅ **Detailed Statistics** - Success rates, execution time, file counts
- ✅ **CI/CD Integration** - Machine-readable JSON output with proper exit codes

#### **Security & Validation**
- ✅ **Path Security Validation** - Prevents directory traversal attacks
- ✅ **Input Sanitization** - Comprehensive security measures
- ✅ **Safe File Operations** - Secure file access with permission checking
- ✅ **Environment Safety Checks** - Validates execution environment

#### **Package Structure**
- ✅ **Standalone Composer Package** - `s-a-c/validate-links`
- ✅ **PSR-4 Autoloading** - `SAC\ValidateLinks` namespace
- ✅ **Single Executable Entry Point** - `validate-links` (no file extension)
- ✅ **Proper Shebang Line** - Direct execution support

#### **Testing Infrastructure**
- ✅ **Comprehensive Test Suite** - Using Pest testing framework
- ✅ **Configuration Error Regression Tests** - Prevents the original `notification_webhook` error
- ✅ **Unit Tests** - Core functionality validation
- ✅ **Integration Tests** - End-to-end workflow testing
- ✅ **Performance Tests** - Scalability and benchmark testing

#### **Documentation**
- ✅ **Complete README** - Installation, usage, examples, CI/CD integration
- ✅ **API Documentation** - Comprehensive class and method documentation
- ✅ **Test Suite Documentation** - Testing infrastructure and usage
- ✅ **Configuration Examples** - JSON config files and environment variables

### Changed

#### **Architecture Refactoring**
- 🔄 **Namespace Migration** - From `LinkValidator\` to `SAC\ValidateLinks\`
- 🔄 **Package Structure** - Moved from `.ai/tools/LinkValidator/` to `.ai/tools/validate-links/`
- 🔄 **Entry Point Consolidation** - Single `validate-links` executable replaces `link-validator.php`
- 🔄 **Class Organization** - Improved separation of concerns and dependency injection

#### **CLI Interface Enhancements**
- 🔄 **Improved Argument Parsing** - Better handling of complex option combinations
- 🔄 **Enhanced Help System** - Comprehensive usage documentation with examples
- 🔄 **Better Error Messages** - More descriptive validation and configuration errors
- 🔄 **Consistent Option Naming** - Standardized CLI argument conventions

#### **Configuration System**
- 🔄 **Enhanced Configuration Hierarchy** - Environment variables → Config file → CLI arguments
- 🔄 **Improved Type Validation** - Better handling of null values and type mismatches
- 🔄 **Robust JSON Parsing** - Graceful handling of malformed configuration files
- 🔄 **Security Validation** - Enhanced path and input validation

### Fixed

#### **Configuration Parsing**
- 🐛 **Fixed `notification_webhook` Error** - Resolved "invalid type. Expected: string" error
- 🐛 **Null Value Handling** - Proper support for null values in configuration files
- 🐛 **Type Validation** - Improved type checking for all configuration options
- 🐛 **JSON Parsing Robustness** - Better error handling for malformed JSON

#### **Link Validation**
- 🐛 **Anchor Generation** - Fixed GitHub-compatible anchor generation algorithm
- 🐛 **Path Resolution** - Improved relative path handling and normalization
- 🐛 **Case Sensitivity** - Consistent case-sensitive/insensitive validation
- 🐛 **External Link Validation** - Better timeout and error handling

#### **Performance Issues**
- 🐛 **Memory Usage** - Optimized memory consumption for large file sets
- 🐛 **Early Termination** - Fixed dual termination condition logic
- 🐛 **Progress Tracking** - Accurate file and link counting
- 🐛 **Statistics Collection** - Correct pre-validation analysis

### Security

#### **Path Validation**
- 🔒 **Directory Traversal Prevention** - Comprehensive path security validation
- 🔒 **Input Sanitization** - Secure handling of user inputs and file paths
- 🔒 **Safe File Operations** - Protected file access with permission checking
- 🔒 **Environment Validation** - Security checks for execution environment

#### **Command Injection Prevention**
- 🔒 **CLI Argument Validation** - Prevents command injection through arguments
- 🔒 **URL Validation** - Secure external URL handling
- 🔒 **File Extension Validation** - Safe file type checking
- 🔒 **Temporary File Handling** - Secure temporary file creation and cleanup

### Deprecated

- ⚠️ **Old Entry Point** - `link-validator.php` replaced by `validate-links`
- ⚠️ **Old Namespace** - `LinkValidator\` namespace deprecated in favor of `SAC\ValidateLinks\`
- ⚠️ **Separate Tools** - Individual LinkValidator and LinkRectifier tools consolidated

### Removed

- ❌ **Legacy Code** - Removed outdated validation logic
- ❌ **Unused Dependencies** - Cleaned up unnecessary dependencies
- ❌ **Duplicate Functionality** - Consolidated overlapping features

## Migration Guide

### From LinkValidator to validate-links

#### **Installation**
```bash
# Old way
# Manual file copying and configuration

# New way
composer require s-a-c/validate-links
```

#### **Usage**
```bash
# Old way
php link-validator.php docs/ --scope=internal

# New way
validate-links docs/ --scope=internal
```

#### **Configuration**
```bash
# Old namespace
use LinkValidator\Core\LinkValidator;

# New namespace
use SAC\ValidateLinks\Core\LinkValidator;
```

#### **New Features**
```bash
# Link fixing (new!)
validate-links docs/ --fix

# Enhanced dry-run
validate-links docs/ --fix --dry-run

# Better performance control
validate-links docs/ --max-files=50 --max-broken=10
```

## Compatibility

### **Backward Compatibility**
- ✅ **CLI Arguments** - All existing arguments continue to work
- ✅ **Configuration Files** - Existing JSON config files supported
- ✅ **Output Formats** - All output formats maintained
- ✅ **Exit Codes** - Consistent exit code behavior

### **Breaking Changes**
- ❌ **Namespace** - PHP class namespace changed from `LinkValidator\` to `SAC\ValidateLinks\`
- ❌ **Entry Point** - `link-validator.php` replaced by `validate-links` executable
- ❌ **Package Structure** - File locations changed for Composer package structure

### **Migration Timeline**
- **Phase 1** - New package available alongside old tools
- **Phase 2** - Old tools marked as deprecated
- **Phase 3** - Old tools removed (future release)

---

**For complete documentation, see [README.md](README.md)**
