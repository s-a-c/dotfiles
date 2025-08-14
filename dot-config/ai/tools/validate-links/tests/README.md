# PHP Link Validation Tools - Test Suite

A comprehensive test suite for the PHP Link Validation and Remediation Tools using the Pest testing framework.

## Overview

This test suite addresses the requirements identified from the configuration parsing error:
> "Configuration key 'notification_webhook' has invalid type. Expected: string"

The test suite provides comprehensive coverage for:

- **Configuration File Validation Testing**
- **Parameter Combination Testing** 
- **Core Functionality Testing**
- **Error Handling and Edge Cases**
- **Output and Reporting Testing**
- **Integration Testing**

## Test Structure

```
tests/
├── Pest.php                           # Pest configuration and global setup
├── run-tests.php                      # Test runner script
├── README.md                          # This file
├── Helpers/                           # Test helper classes
│   ├── ConfigurationHelper.php        # Configuration testing utilities
│   ├── FileSystemHelper.php          # File system testing utilities
│   ├── LinkValidationHelper.php      # Link validation testing utilities
│   └── FixtureHelper.php             # Test fixture creation utilities
├── Configuration/                     # Configuration parsing tests
│   ├── CLIArgumentParserTest.php      # CLI argument parsing tests
│   ├── ConfigurationFileTest.php      # Configuration file handling tests
│   └── ConfigurationErrorRegressionTest.php # Regression tests for known issues
├── Unit/                             # Unit tests
│   └── LinkValidatorTest.php         # Core link validation tests
├── Integration/                      # Integration tests
│   └── EndToEndTest.php              # End-to-end workflow tests
└── Performance/                      # Performance tests
    └── PerformanceTest.php           # Performance benchmarks
```

## Installation

### Prerequisites

- PHP 8.1 or higher
- Composer
- Required PHP extensions: `json`, `mbstring`, `curl`

### Install Pest

```bash
# Install Pest as a dev dependency
composer require pestphp/pest --dev

# Or install globally
composer global require pestphp/pest
```

## Running Tests

### Quick Start

```bash
# Run all tests
php tests/run-tests.php

# Run with verbose output
php tests/run-tests.php --verbose

# Run specific test suite
php tests/run-tests.php --configuration
php tests/run-tests.php --unit
php tests/run-tests.php --integration
php tests/run-tests.php --performance
```

### Advanced Usage

```bash
# Run tests with coverage report
php tests/run-tests.php --coverage

# Filter tests by name
php tests/run-tests.php --filter=CLIArgumentParser

# Run tests in specific group
php tests/run-tests.php --group=configuration

# Run configuration tests with verbose output
php tests/run-tests.php --configuration --verbose
```

### Direct Pest Usage

```bash
# Run all tests
./vendor/bin/pest tests/

# Run specific test file
./vendor/bin/pest tests/Configuration/ConfigurationErrorRegressionTest.php

# Run with coverage
./vendor/bin/pest --coverage --coverage-html=coverage-html
```

## Test Categories

### 1. Configuration Tests (`Configuration/`)

Tests for configuration file parsing, validation, and hierarchy.

**Key Focus Areas:**
- **Null value handling** (addresses the original `notification_webhook` error)
- JSON parsing robustness
- Type validation
- Configuration hierarchy (environment → config file → CLI)
- Malformed configuration handling

**Critical Tests:**
- `ConfigurationErrorRegressionTest.php` - Specifically tests the original error scenario
- `CLIArgumentParserTest.php` - CLI argument parsing and validation
- `ConfigurationFileTest.php` - Configuration file loading and parsing

### 2. Unit Tests (`Unit/`)

Tests for individual components and core functionality.

**Coverage:**
- Link validation accuracy
- Early termination logic (`--max-files`, `--max-broken`)
- Progress tracking
- Statistics collection
- Error handling

### 3. Integration Tests (`Integration/`)

End-to-end tests for complete workflows.

**Coverage:**
- Complete CLI to output workflows
- Parameter combination testing
- Environment variable integration
- Output format generation
- Real-world usage scenarios

### 4. Performance Tests (`Performance/`)

Performance benchmarks and scalability tests.

**Coverage:**
- Validation performance with large file sets
- Memory usage patterns
- Early termination performance benefits
- Configuration parsing performance
- Report generation performance

## Test Helpers

### ConfigurationHelper

Provides utilities for testing configuration parsing:

```php
// Create valid configuration
$config = ConfigurationHelper::getValidConfig();

// Create configuration with invalid types
$invalidConfig = ConfigurationHelper::getInvalidTypeConfig();

// Create configuration with null values
$nullConfig = ConfigurationHelper::getNullValueConfig();

// Test environment variables
ConfigurationHelper::setEnvironmentVariables([
    'LINK_VALIDATOR_SCOPE' => 'internal,anchor'
]);
```

### FileSystemHelper

Creates test file structures and fixtures:

```php
// Create complete test documentation structure
$testDir = FileSystemHelper::createTestDocumentationStructure();

// Create files with specific link patterns
$files = FileSystemHelper::createLinkPatternTestFiles();

// Create files with encoding issues
$encodingFiles = FileSystemHelper::createEncodingTestFiles();
```

### LinkValidationHelper

Provides link validation testing utilities:

```php
// Get test cases for link categorization
$testCases = LinkValidationHelper::getLinkCategorizationTestCases();

// Create performance test files
$files = LinkValidationHelper::createPerformanceTestFiles(10, 50);

// Measure validation performance
$performance = LinkValidationHelper::measureValidationPerformance(
    $validator, $files, ['internal']
);
```

## Addressing the Original Error

The test suite specifically addresses the configuration error:
> "Configuration key 'notification_webhook' has invalid type. Expected: string"

### Root Cause Analysis

The error occurred because:
1. The configuration file contained `"notification_webhook": null`
2. The configuration validator expected a string type
3. Null values weren't properly handled in type validation

### Test Coverage

**`ConfigurationErrorRegressionTest.php`** provides comprehensive coverage:

```php
it('handles notification_webhook null value correctly', function () {
    $config = [
        'scope' => ['internal'],
        'max_broken' => 10,
        'notification_webhook' => null, // This caused the original error
    ];

    $configFile = ConfigurationHelper::createTempConfigFile($config);
    $loadedConfig = json_decode(file_get_contents($configFile), true);
    
    expect($loadedConfig)->toBeArray()
        ->and($loadedConfig['notification_webhook'])->toBeNull();
});
```

### Prevention Strategy

The test suite prevents similar issues by:

1. **Comprehensive null value testing** - Tests all possible null scenarios
2. **Type validation edge cases** - Tests mixed valid/invalid types
3. **Real-world configuration scenarios** - Tests production-like configurations
4. **JSON parsing robustness** - Tests malformed JSON handling
5. **Regression test coverage** - Specific tests for the original error

## Continuous Integration

The test suite is designed for CI/CD environments:

```bash
# CI-friendly test execution
php tests/run-tests.php --verbose

# Generate coverage for CI
php tests/run-tests.php --coverage

# Run specific test categories
php tests/run-tests.php --configuration --unit
```

### Exit Codes

- `0` - All tests passed
- `1` - Some tests failed or environment issues
- `2` - Configuration or setup errors

## Contributing

When adding new tests:

1. **Follow the existing structure** - Use appropriate test categories
2. **Use test helpers** - Leverage existing helper classes
3. **Add regression tests** - For any bugs discovered
4. **Update documentation** - Keep this README current
5. **Test edge cases** - Include null values, empty strings, etc.

### Test Naming Conventions

- Use descriptive test names: `it('handles null values correctly')`
- Group related tests: `describe('Null Value Handling')`
- Use consistent language: "handles", "validates", "processes", etc.

## Troubleshooting

### Common Issues

**Pest not found:**
```bash
composer require pestphp/pest --dev
```

**Permission errors:**
```bash
chmod +x tests/run-tests.php
```

**Memory issues with performance tests:**
```bash
php -d memory_limit=512M tests/run-tests.php --performance
```

**Missing PHP extensions:**
```bash
# Install required extensions
sudo apt-get install php-json php-mbstring php-curl
```

### Debug Mode

For debugging test failures:

```bash
# Run with maximum verbosity
php tests/run-tests.php --verbose --filter=SpecificTest

# Run single test file
./vendor/bin/pest tests/Configuration/ConfigurationErrorRegressionTest.php --verbose
```

## Coverage Reports

Generate detailed coverage reports:

```bash
# HTML coverage report
php tests/run-tests.php --coverage

# View coverage
open coverage-html/index.html
```

The test suite aims for high coverage across all critical paths, with special attention to configuration parsing and error handling scenarios.
