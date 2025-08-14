# validate-links

[![PHP Version](https://img.shields.io/badge/php-%5E8.1-blue)](https://php.net)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Tests](https://img.shields.io/badge/tests-passing-brightgreen)](tests/)

Comprehensive PHP Link Validation and Remediation Tools for documentation projects. Validate and automatically fix broken links in Markdown, HTML, and other text-based formats with advanced filtering, reporting, and CI/CD integration.

## 🚀 Features

### **Link Validation**
- ✅ **Internal Links** - Same directory file references
- ✅ **Anchor Links** - GitHub-compatible heading anchors
- ✅ **Cross-Reference Links** - Relative path navigation
- ✅ **External Links** - HTTP/HTTPS URL validation
- ✅ **Multiple Formats** - Markdown, HTML, and text files

### **Advanced Filtering**
- 🎯 **Scope Control** - Validate specific link types
- 📁 **Directory Traversal** - Configurable depth limits
- 🔍 **Pattern Matching** - Include/exclude file patterns
- 👁️ **Hidden Files** - Optional hidden file processing

### **Performance Optimization**
- ⚡ **Early Termination** - Stop after N files or broken links
- 📊 **Progress Tracking** - Real-time validation progress
- 🧠 **Memory Efficient** - Optimized for large documentation sets
- 🔄 **Parallel Processing** - Concurrent external link validation

### **Link Remediation** (Enhanced CLI)
- 🔧 **Automatic Fixing** - Fix broken links automatically
- 🔍 **Smart Detection** - Case mismatches, moved files, extension changes
- 💾 **Backup Creation** - Safe modifications with rollback
- 🎯 **Interactive Mode** - User confirmation for ambiguous fixes

### **Comprehensive Reporting**
- 📊 **Multiple Formats** - Console, JSON, Markdown, HTML
- 🎨 **Colored Output** - Enhanced readability
- 📈 **Detailed Statistics** - Success rates, execution time
- 🔗 **CI/CD Integration** - Machine-readable output

## 📦 Installation

### Via Composer (Recommended)

```bash
# Install globally
composer global require s-a-c/validate-links

# Install as project dependency
composer require --dev s-a-c/validate-links
```

### Standalone Installation

```bash
# Clone the repository
git clone https://github.com/s-a-c/validate-links.git
cd validate-links

# Install dependencies
composer install

# Make executable
chmod +x validate-links
```

## 🎯 Quick Start

### Basic Validation

```bash
# Validate all links in docs directory
validate-links docs/

# Validate specific file types
validate-links docs/ --scope=internal,anchor

# Quick CI check
validate-links docs/ --max-files=10 --max-broken=5
```

### Link Fixing (New!)

```bash
# Validate and fix broken links
validate-links docs/ --fix

# Preview what would be fixed
validate-links docs/ --fix --dry-run

# Fix only specific link types
validate-links docs/ --fix --scope=internal
```

### Advanced Usage

```bash
# Performance optimized validation
validate-links docs/ --max-files=20 --scope=internal --verbose

# Generate detailed reports
validate-links docs/ --format=html --output=report.html

# CI/CD integration
validate-links docs/ --format=json --quiet --max-broken=0
```

## 📖 Usage

### Command Line Options

#### **Validation Options**
```bash
--scope=<types>         # Link types: all, internal, anchor, cross_reference, external
--check-external        # Validate HTTP/HTTPS links (slower)
--case-sensitive        # Case-sensitive file path validation
--timeout=<seconds>     # External link timeout (default: 30)
```

#### **Filtering Options**
```bash
--max-depth=<n>         # Directory depth limit (0 = unlimited)
--include-hidden        # Include hidden files/directories
--only-hidden          # Process only hidden files
--exclude=<patterns>    # Exclude file patterns (glob syntax)
```

#### **Performance Options**
```bash
--max-broken=<n>        # Stop after N broken links (default: 50)
--max-files=<n>         # Stop after N files (default: unlimited)
```

#### **Remediation Options** (New!)
```bash
--fix                   # Enable automatic link fixing
--dry-run              # Preview mode (show what would be done)
```

#### **Output Options**
```bash
--format=<type>         # Output: console, json, markdown, html
--output=<file>         # Write to file instead of stdout
--no-color             # Disable colored output
--verbose              # Detailed progress information
--quiet                # Minimal output (errors only)
```

### Behavior Modes

#### **Validation Only** (Default)
```bash
validate-links docs/
# ✅ Only validates links, reports broken ones
```

#### **Validation + Fixing**
```bash
validate-links docs/ --fix
# ✅ Validates first, then automatically fixes broken links
```

#### **Preview Mode**
```bash
validate-links docs/ --dry-run
# ✅ Shows validation scope without validating

validate-links docs/ --fix --dry-run
# ✅ Shows what fixes would be applied without making changes
```

## 🔧 Configuration

### Configuration File

Create `.validate-links.json` in your project root:

```json
{
  "scope": ["internal", "anchor"],
  "max_broken": 10,
  "max_files": 50,
  "exclude_patterns": ["*.backup.md", "temp/*"],
  "check_external": false,
  "format": "console"
}
```

### Environment Variables

```bash
export LINK_VALIDATOR_SCOPE="internal,anchor"
export LINK_VALIDATOR_MAX_BROKEN=25
export LINK_VALIDATOR_MAX_FILES=100
export LINK_VALIDATOR_CHECK_EXTERNAL=true
export LINK_VALIDATOR_FIX=true
```

## 📊 Output Formats

### Console Output
```
Link Validation Report
==================================================

Summary:
  Files Processed: 143
  Total Links: 1,247
  Broken Links: 7
  Success Rate: 99.44%

Broken Links:
------------------------------

docs/api/overview.md:
  Line 23: missing-file.md - Internal link target not found
  Line 45: #wrong-anchor - Anchor not found in file
```

### JSON Output
```json
{
  "summary": {
    "total_files": 143,
    "total_links": 1247,
    "broken_links": 7,
    "success_rate": 99.44,
    "execution_time": 2.341
  },
  "results": {
    "docs/api/overview.md": {
      "broken_links": [
        {
          "text": "Missing File",
          "url": "missing-file.md",
          "line": 23,
          "status": "Internal link target not found"
        }
      ]
    }
  }
}
```

## 🧪 Testing

The package includes a comprehensive test suite using Pest:

```bash
# Run all tests
composer test

# Run specific test suites
composer test:unit
composer test:integration
composer test:configuration
composer test:performance

# Generate coverage report
composer test:coverage
```

## 🔄 CI/CD Integration

### GitHub Actions

```yaml
name: Link Validation
on: [push, pull_request]

jobs:
  validate-links:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: shivammathur/setup-php@v2
        with:
          php-version: '8.1'
      - run: composer global require s-a-c/validate-links
      - run: validate-links docs/ --format=json --max-broken=0
```

### Performance Optimized CI

```bash
# Quick validation for large projects
validate-links docs/ --max-files=20 --max-broken=10 --scope=internal

# Full validation with early termination
validate-links docs/ --max-broken=50 --format=json --quiet
```

## 🛠️ Development

### Requirements

- PHP 8.1 or higher
- Extensions: `json`, `mbstring`, `curl`
- Composer for dependency management

### Setup

```bash
git clone https://github.com/s-a-c/validate-links.git
cd validate-links
composer install
chmod +x validate-links
```

### Running Tests

```bash
# Install test dependencies
composer install --dev

# Run test suite
./tests/run-tests.php

# Run with coverage
./tests/run-tests.php --coverage
```

## 📈 Performance

### Benchmarks

- **Small projects** (< 50 files): < 2 seconds
- **Medium projects** (< 500 files): < 30 seconds  
- **Large projects** (1000+ files): < 2 minutes with `--max-files`

### Memory Usage

- **Base memory**: ~10MB
- **Per file**: ~50KB average
- **Large files**: Streaming processing for 10MB+ files

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- GitHub's anchor generation algorithm for consistent heading links
- The PHP community for excellent testing and development tools
- Contributors and users who help improve the tool

---

**Made with ❤️ for the documentation community**
