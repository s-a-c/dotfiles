# Legacy Tools Archive

This directory contains archived legacy tools that have been replaced by the modern `validate-links` package. These tools are preserved for reference and compatibility but are no longer actively maintained.

## 📁 Archive Structure

```
archive/
├── 📋 README.md                    # This documentation
├── 📊 DELIVERABLES_SUMMARY.md      # Original project deliverables
├── 🛠️ IMPLEMENTATION_SUMMARY.md    # Legacy technical implementation
├── 📖 MIGRATION_GUIDE.md           # Migration instructions
├── ⚙️ example-config.json          # Legacy configuration example
├── legacy-php/                     # Legacy PHP tools
│   ├── LinkValidator/              # Original validation classes
│   │   ├── Core/                   # Core validation logic
│   │   │   ├── CLIArgumentParser.php
│   │   │   ├── LinkValidator.php
│   │   │   └── ReportGenerator.php
│   │   └── Utils/                  # Utility classes
│   │       ├── Logger.php
│   │       └── SecurityValidator.php
│   ├── LinkRectifier/              # Original fixing classes
│   │   ├── Core/                   # Core fixing logic
│   │   │   ├── LinkRectifier.php
│   │   │   ├── SimilarityCalculator.php
│   │   │   └── BackupManager.php
│   │   └── Utils/                  # Utility classes
│   │       └── FileSystemUtils.php
│   ├── link-validator.php          # Legacy validator script
│   ├── link-rectifier.php          # Legacy rectifier script
│   ├── validate-chinook-links.sh   # Legacy shell scripts
│   ├── validate-links.sh
│   ├── lint-tests.sh
│   ├── run-tests.php               # Legacy test runner
│   ├── test-simple-validator.php   # Legacy test files
│   ├── test-validator.php
│   └── test_album_seeder.php
├── legacy-python/                  # Legacy Python tools
│   ├── audit_chinook_links.py      # Python audit scripts
│   ├── automated_link_validation.py
│   ├── chinook-link-validator.py
│   ├── chinook_link_integrity_audit.py
│   ├── link_integrity_analysis.py
│   └── __pycache__/                # Python cache files
└── legacy-tests/                   # Legacy test suite
    └── tests/                      # Original test infrastructure
        ├── Pest.php
        ├── README.md
        ├── TEST_SUITE_SUMMARY.md
        ├── bootstrap.php
        ├── composer.json
        ├── phpunit.xml
        ├── run-tests.php
        ├── Configuration/
        ├── Helpers/
        ├── Integration/
        ├── Performance/
        └── Unit/
```

## 🚨 Deprecation Notice

**These tools are deprecated and no longer maintained.** Please use the modern `validate-links` package instead:

```bash
# Navigate to the modern package
cd ../validate-links/

# Use the new tool
./validate-links --help
```

## 🔄 Migration Path

### From Legacy PHP Tools

#### **link-validator.php** → **validate-links**
```bash
# Old way
php .ai/tools/archive/legacy-php/link-validator.php docs/ --scope=internal

# New way
cd .ai/tools/validate-links && ./validate-links docs/ --scope=internal
```

#### **link-rectifier.php** → **validate-links --fix**
```bash
# Old way
php .ai/tools/archive/legacy-php/link-rectifier.php docs/

# New way
cd .ai/tools/validate-links && ./validate-links docs/ --fix
```

#### **Shell Scripts** → **validate-links**
```bash
# Old way
.ai/tools/archive/legacy-php/validate-chinook-links.sh

# New way
cd .ai/tools/validate-links && ./validate-links docs/ --scope=internal,anchor
```

### From Legacy Python Tools

The Python tools have been completely replaced by the PHP `validate-links` package, which provides:

- ✅ **Better performance** than Python scripts
- ✅ **More comprehensive validation** logic
- ✅ **Enhanced security** features
- ✅ **Modern architecture** with proper testing
- ✅ **CI/CD integration** capabilities

## 📋 Legacy Tool Functionality

### **PHP Tools (Deprecated)**

#### **link-validator.php**
- Basic link validation for Markdown and HTML files
- Limited scope control and filtering options
- Basic console and JSON output formats
- No automatic fixing capabilities

#### **link-rectifier.php**
- Separate tool for fixing broken links
- Basic similarity matching for file suggestions
- Limited backup and rollback functionality
- No integration with validation workflow

#### **Shell Scripts**
- Simple wrapper scripts for common tasks
- Limited error handling and validation
- No comprehensive configuration support
- Basic CI/CD integration

### **Python Tools (Deprecated)**

#### **chinook_link_integrity_audit.py**
- Basic link validation for Chinook project
- Limited file format support
- No comprehensive reporting
- Performance issues with large projects

#### **automated_link_validation.py**
- Simple automation scripts
- Basic validation logic
- No advanced filtering or scope control
- Limited error handling

## 🎯 Why Migrate?

### **Enhanced Functionality**
- ✅ **Integrated workflow** - Validation and fixing in one tool
- ✅ **Advanced CLI interface** - Better argument parsing and help
- ✅ **Multiple output formats** - Console, JSON, Markdown, HTML
- ✅ **Comprehensive testing** - 50+ test cases preventing regressions

### **Better Performance**
- ✅ **Early termination** - Stop after N files or broken links
- ✅ **Memory optimization** - Efficient processing of large projects
- ✅ **Parallel processing** - Concurrent external link validation
- ✅ **Progress tracking** - Real-time validation progress

### **Enhanced Security**
- ✅ **Path validation** - Prevents directory traversal attacks
- ✅ **Input sanitization** - Comprehensive security measures
- ✅ **Safe file operations** - Secure file access and modification
- ✅ **Command injection prevention** - Secure CLI argument handling

### **Modern Architecture**
- ✅ **PSR-4 autoloading** - Modern PHP standards compliance
- ✅ **Composer package** - Easy installation and distribution
- ✅ **Comprehensive documentation** - Complete usage guides and examples
- ✅ **Active maintenance** - Ongoing development and support

## 📚 Legacy Documentation

The following documents provide historical context and technical details about the legacy tools:

### **Project Documentation**
- **DELIVERABLES_SUMMARY.md** - Original project deliverables and requirements
- **IMPLEMENTATION_SUMMARY.md** - Technical implementation details and architecture
- **MIGRATION_GUIDE.md** - Detailed migration instructions and compatibility notes

### **Configuration**
- **example-config.json** - Legacy configuration file format and options

### **Test Documentation**
- **legacy-tests/README.md** - Original test suite documentation
- **legacy-tests/TEST_SUITE_SUMMARY.md** - Test coverage and methodology

## ⚠️ Compatibility Notes

### **Breaking Changes**
- **Namespace changes** - PHP classes moved from `LinkValidator\` to `SAC\ValidateLinks\`
- **Entry point changes** - Single `validate-links` executable replaces multiple scripts
- **Configuration format** - Enhanced configuration with new options and structure

### **Preserved Functionality**
- ✅ **All CLI arguments** continue to work with the new tool
- ✅ **Configuration files** remain compatible with minor adjustments
- ✅ **Output formats** maintain the same structure and content
- ✅ **Exit codes** follow the same conventions for CI/CD integration

## 🚀 Getting Started with Modern Tools

1. **Navigate to the modern package**:
   ```bash
   cd ../validate-links/
   ```

2. **Read the comprehensive documentation**:
   ```bash
   cat README.md
   ```

3. **Test the new functionality**:
   ```bash
   ./validate-links --help
   ./validate-links docs/ --dry-run
   ```

4. **Try the enhanced features**:
   ```bash
   ./validate-links docs/ --fix --dry-run
   ```

## 📞 Support

For questions about migrating from legacy tools or using the modern `validate-links` package:

1. **Read the documentation** in `../validate-links/README.md`
2. **Check the changelog** in `../validate-links/CHANGELOG.md`
3. **Review the migration guide** in `MIGRATION_GUIDE.md`
4. **Examine the test suite** in `../validate-links/tests/`

---

**⚠️ Remember: These legacy tools are archived and no longer maintained. Please migrate to the modern `validate-links` package for continued support and new features.**
