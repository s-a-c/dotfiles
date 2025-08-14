# Development Environment Setup Documentation

**Date:** January 22, 2025  
**Project:** Laravel Zero validate-links Documentation Enhancement  
**Phase:** Development Environment Setup Documentation

## Executive Summary

This document provides comprehensive setup instructions for the validate-links development environment, including all Composer packages, scripts, and their execution workflows.

## System Requirements

### PHP Requirements
- **PHP Version:** ^8.4
- **Required Extensions:**
  - `ext-json` - JSON processing
  - `ext-mbstring` - Multibyte string handling
  - `ext-curl` - HTTP client functionality

### Composer Requirements
- **Composer Version:** 2.0 or higher
- **Minimum Stability:** dev (with prefer-stable: true)

## Production Dependencies

### Core Framework
| Package | Version | Purpose | Documentation |
|---------|---------|---------|---------------|
| `laravel-zero/framework` | ^12.0 | CLI application framework | [Laravel Zero Docs](https://laravel-zero.com) |
| `laravel/prompts` | ^0.3 | Interactive CLI prompts | [Laravel Prompts](https://laravel.com/docs/prompts) |
| `illuminate/http` | ^12.0 | HTTP client functionality | [Laravel HTTP](https://laravel.com/docs/http-client) |
| `symfony/dom-crawler` | ^7.2 | HTML/XML parsing and traversal | [Symfony DomCrawler](https://symfony.com/doc/current/components/dom_crawler.html) |

### Installation Commands
```bash
# Install production dependencies only
composer install --no-dev --optimize-autoloader

# Install all dependencies (development)
composer install
```

## Development Dependencies

### Code Quality Tools

#### Laravel Pint (Code Formatting)
| Package | Version | Purpose |
|---------|---------|---------|
| `laravel/pint` | ^1.22 | PHP code style fixer based on PHP-CS-Fixer |

**Usage:**
```bash
# Fix code style issues
composer cs-fix

# Check code style without fixing
composer cs-check
```

#### PHPStan/Larastan (Static Analysis)
| Package | Version | Purpose |
|---------|---------|---------|
| `larastan/larastan` | ^3.6 | Laravel-specific PHPStan rules |
| `phpstan/phpstan-deprecation-rules` | ^2.0 | Deprecation detection rules |

**Usage:**
```bash
# Run static analysis
composer analyse

# Run with specific level
vendor/bin/phpstan analyse app/ --level=8
```

#### Rector (Automated Refactoring)
| Package | Version | Purpose |
|---------|---------|---------|
| `rector/rector` | ^2.1 | Automated code refactoring |
| `rector/type-perfect` | ^2.1 | Type declaration improvements |
| `driftingly/rector-laravel` | ^2.0 | Laravel-specific Rector rules |

**Usage:**
```bash
# Dry run (preview changes)
vendor/bin/rector process --dry-run

# Apply changes
vendor/bin/rector process
```

#### Psalm (Static Analysis)
| Package | Version | Purpose |
|---------|---------|---------|
| `vimeo/psalm` | ^6.13 | Advanced static analysis |
| `psalm/plugin-laravel` | ^3.0 | Laravel-specific Psalm plugin |
| `orklah/psalm-strict-equality` | ^3.1 | Strict equality checks |
| `roave/psalm-html-output` | ^1.1 | HTML report generation |

**Usage:**
```bash
# Run Psalm analysis
vendor/bin/psalm

# Generate HTML report
vendor/bin/psalm --report=psalm-report.html
```

### Testing Framework

#### Pest (Testing Framework)
| Package | Version | Purpose |
|---------|---------|---------|
| `pestphp/pest` | ^3.8.2 | Modern PHP testing framework |
| `pestphp/pest-plugin-arch` | ^3.1 | Architecture testing |
| `pestphp/pest-plugin-stressless` | ^3.1 | Stress testing capabilities |
| `pestphp/pest-plugin-type-coverage` | ^3.6 | Type coverage analysis |
| `peckphp/peck` | ^0.1.3 | Additional testing utilities |
| `mockery/mockery` | ^1.6.12 | Mocking framework |

**Usage:**
```bash
# Run all tests
composer test

# Run with coverage
composer test:coverage

# Run unit tests only
composer test:unit

# Run feature tests only
composer test:feature
```

### Security and Quality

#### Security Advisories
| Package | Version | Purpose |
|---------|---------|---------|
| `roave/security-advisories` | dev-latest | Security vulnerability database |

#### Composer Normalization
| Package | Version | Purpose |
|---------|---------|---------|
| `ergebnis/composer-normalize` | ^2.47 | Composer.json normalization |

**Usage:**
```bash
# Normalize composer.json
vendor/bin/composer-normalize
```

## Composer Scripts Reference

### Testing Scripts
```bash
# Run all tests
composer test

# Run tests with HTML coverage report
composer test:coverage

# Run unit tests only
composer test:unit

# Run feature tests only  
composer test:feature
```

### Code Quality Scripts
```bash
# Fix code style issues
composer cs-fix

# Check code style without fixing
composer cs-check

# Run static analysis
composer analyse

# Run complete quality workflow
composer quality
```

### Setup Scripts
```bash
# Setup configuration files
composer migrate:setup
```

## Script Execution Order and Dependencies

### Quality Workflow (`composer quality`)
1. **Code Style Fixing** (`@cs-fix`)
   - Runs Laravel Pint to fix code style issues
   - Must complete successfully before proceeding
   
2. **Static Analysis** (`@analyse`)
   - Runs PHPStan at level 8
   - Depends on clean code style from step 1
   
3. **Testing** (`@test`)
   - Runs complete Pest test suite
   - Depends on code passing static analysis

### Recommended Development Workflow

#### Daily Development
```bash
# 1. Pull latest changes
git pull origin main

# 2. Update dependencies
composer install

# 3. Run quality checks
composer quality

# 4. Make changes...

# 5. Before committing
composer quality
```

#### Pre-commit Workflow
```bash
# 1. Fix code style
composer cs-fix

# 2. Run static analysis
composer analyse

# 3. Run tests with coverage
composer test:coverage

# 4. Check for security issues
composer audit
```

#### CI/CD Preparation
```bash
# 1. Run complete quality suite
composer quality

# 2. Generate coverage report
composer test:coverage

# 3. Run Rector dry-run
vendor/bin/rector process --dry-run

# 4. Run Psalm analysis
vendor/bin/psalm
```

## IDE Integration

### PHPStorm Configuration
1. **PHP Interpreter:** Set to PHP 8.4+
2. **Composer:** Enable Composer integration
3. **Code Style:** Import Laravel Pint configuration
4. **PHPStan:** Configure as external tool
5. **Pest:** Enable Pest test runner

### VS Code Extensions
- **PHP Intelephense** - PHP language support
- **Laravel Extension Pack** - Laravel development tools
- **Pest Snippets** - Pest testing snippets
- **PHP CS Fixer** - Code formatting integration

## Performance Considerations

### Memory Requirements
- **Minimum:** 512MB PHP memory limit
- **Recommended:** 1GB for large codebases
- **CI/CD:** 2GB for parallel processing

### Execution Times (Approximate)
- **Code Style Fix:** 5-15 seconds
- **Static Analysis:** 10-30 seconds
- **Test Suite:** 15-45 seconds
- **Complete Quality Workflow:** 30-90 seconds

## Troubleshooting

### Common Issues

#### Memory Limit Errors
```bash
# Increase PHP memory limit
php -d memory_limit=1G vendor/bin/phpstan analyse
```

#### Composer Plugin Issues
```bash
# Clear Composer cache
composer clear-cache

# Reinstall dependencies
rm -rf vendor/ composer.lock
composer install
```

#### Test Failures
```bash
# Clear application cache
php artisan config:clear
php artisan cache:clear

# Regenerate autoload files
composer dump-autoload
```

## Next Steps

1. **Setup Automation:** Configure pre-commit hooks
2. **CI Integration:** Implement GitHub Actions workflows
3. **Documentation:** Create package-specific setup guides
4. **Monitoring:** Add performance tracking for scripts
5. **Updates:** Regular dependency updates and security audits
