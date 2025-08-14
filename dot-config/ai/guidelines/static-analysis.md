# Static Analysis Standards

## Overview

This document establishes the comprehensive static analysis standards for maintaining **PHPStan Level 10 compliance** - the highest level of PHP static analysis and type safety. These standards ensure zero violations in main application code while providing practical guidance for maintaining code quality.

## Table of Contents

1. [PHPStan Level 10 Configuration](#phpstan-level-10-configuration)
2. [Rector Configuration](#rector-configuration)
3. [PHP-CS-Fixer Configuration](#php-cs-fixer-configuration)
4. [Pint Configuration](#pint-configuration)
5. [Tool Integration](#tool-integration)
6. [Quality Gates](#quality-gates)
7. [Performance Optimization](#performance-optimization)
8. [Troubleshooting](#troubleshooting)

## PHPStan Level 10 Configuration

### Core Configuration

**File**: [`phpstan.neon`](../../phpstan.neon)

```neon
includes:
    - ./vendor/larastan/larastan/extension.neon

parameters:
    # Level 10 - Maximum strictness beyond 'max'
    level: 10
    
    paths:
        - app
        - bootstrap
        - config
        - tests
    
    # Advanced type checking - Level 10 strictness
    checkExplicitMixed: true
    checkImplicitMixed: true
    checkMissingCallableSignature: true
    checkMissingVarTagTypehint: true
    checkArgumentsPassedByReference: true
    checkMaybeUndefinedVariables: true
    checkNullables: true
    checkUnionTypes: true
    checkExplicitMixedMissingReturn: true
    checkPhpDocMissingReturn: true
    checkPhpDocMethodSignatures: true
    checkExtraArguments: true
    checkTooWideReturnTypesInProtectedAndPublicMethods: true
    checkUninitializedProperties: true
    checkDynamicProperties: true
    
    # PHP 8.4 specific settings
    phpVersion: 80400
```

### Key Level 10 Requirements

1. **Zero Violations Policy**: Main application code (`app/` directory) must achieve 0 PHPStan level 10 errors
2. **Strict Type Declarations**: All PHP files must start with `declare(strict_types=1);`
3. **Complete Type Annotations**: All properties, parameters, and return values require explicit type annotations
4. **Mixed Type Handling**: Explicit type checking and casting for mixed types
5. **Array Shape Definitions**: Typed arrays with specific key-value type annotations

### Performance Settings

```neon
# Performance settings optimized for large codebase
parallel:
    maximumNumberOfProcesses: 8
    minimumNumberOfJobsPerProcess: 2
    processTimeout: 120.0

# Bootstrap file to set UTF-8 locale
bootstrapFiles:
    - phpstan-bootstrap.php

tmpDir: reports/phpstan
```

### Laravel Zero Specific Configuration

```neon
# Laravel Zero specific configurations
scanFiles:
    - bootstrap/app.php
    - bootstrap/providers.php

scanDirectories:
    - app/Commands
    - app/Services
    - app/Contracts
    - app/Enums
    - app/Exceptions
    - app/Providers
    - app/Services/ValueObjects
    - app/Services/Formatters
    - app/Services/Contracts
```

## Rector Configuration

### Core Configuration

**File**: [`rector.php`](../../rector.php)

```php
<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;
use RectorLaravel\Set\LaravelSetList;

return static function (RectorConfig $rectorConfig): void {
    // Configure comprehensive rule sets for PHP 8.4+ modernization
    $rectorConfig->sets([
        // PHP version upgrade to 8.4 with all features
        LevelSetList::UP_TO_PHP_84,

        // Enhanced code quality improvements
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
        SetList::EARLY_RETURN,
        SetList::TYPE_DECLARATION,
        SetList::PRIVATIZATION,
        SetList::INSTANCEOF,
        SetList::STRICT_BOOLEANS,
        SetList::NAMING,
        SetList::CARBON,

        // Laravel-specific improvements for Laravel Zero
        LaravelSetList::LARAVEL_CODE_QUALITY,
        LaravelSetList::LARAVEL_ARRAY_STR_FUNCTION_TO_STATIC_CALL,
        LaravelSetList::LARAVEL_FACADE_ALIASES_TO_FULL_NAMES,
        LaravelSetList::LARAVEL_ELOQUENT_MAGIC_METHOD_TO_QUERY_BUILDER,
        LaravelSetList::LARAVEL_LEGACY_FACTORIES_TO_CLASSES,
    ]);
    
    // Performance and caching configuration
    $rectorConfig->cacheDirectory(__DIR__.'/storage/rector');
    $rectorConfig->memoryLimit('2G');
    
    // Laravel Zero specific configurations
    $rectorConfig->phpstanConfig(__DIR__.'/phpstan.neon');
};
```

### Key Rector Rules for Type Safety

1. **PHP 8.4+ Compatibility**: Automatic upgrade to latest PHP features
2. **Type Declaration Enhancement**: Automatic type hint additions
3. **Dead Code Removal**: Elimination of unused code that affects type analysis
4. **Laravel Zero Optimization**: Framework-specific improvements

## PHP-CS-Fixer Configuration

### Core Configuration

**File**: [`.php-cs-fixer.php`](../../.php-cs-fixer.php)

```php
<?php

declare(strict_types=1);

use PhpCsFixer\Config;
use PhpCsFixer\Finder;

return (new Config())
    ->setRiskyAllowed(true)
    ->setRules([
        '@PSR12' => true,
        '@PHP84Migration' => true,
        '@PhpCsFixer' => true,
        '@PhpCsFixer:risky' => true,

        // Type declarations - PHPStan Level 10 compatible
        'declare_strict_types' => true,
        'strict_param' => true,
        'strict_comparison' => true,
        'native_function_type_declaration_casing' => true,

        // PHPDoc handling - Critical for PHPStan Level 10
        'no_superfluous_phpdoc_tags' => [
            'allow_mixed' => true,
            'allow_unused_params' => true,  // Preserve @param for PHPStan Level 10
            'remove_inheritdoc' => false,   // Preserve @inheritdoc for PHPStan Level 10
            'allow_hidden_params' => true, // Preserve hidden @param annotations
        ],
        'phpdoc_add_missing_param_annotation' => ['only_untyped' => false],
        'phpdoc_no_empty_return' => false, // Keep for PHPStan Level 10
    ]);
```

### PHPStan Level 10 Specific Rules

1. **PHPDoc Preservation**: Maintains type annotations required for PHPStan Level 10
2. **Strict Type Enforcement**: Ensures all files have strict type declarations
3. **Type Declaration Casing**: Consistent native function type casing
4. **Parameter Annotation**: Preserves all parameter annotations for static analysis

## Pint Configuration

### Core Configuration

**File**: [`pint.json`](../../pint.json)

```json
{
    "preset": "laravel",
    "rules": {
        "declare_strict_types": true,
        "fully_qualified_strict_types": true,
        "strict_comparison": true,
        
        "phpdoc_add_missing_param_annotation": {
            "only_untyped": false
        },
        "no_superfluous_phpdoc_tags": {
            "allow_mixed": true,
            "allow_unused_params": true,
            "remove_inheritdoc": false,
            "allow_hidden_params": true
        },
        
        "ordered_class_elements": {
            "order": [
                "use_trait",
                "case",
                "constant_public",
                "constant_protected", 
                "constant_private",
                "property_public_static",
                "property_protected_static",
                "property_private_static",
                "property_public",
                "property_protected",
                "property_private",
                "construct",
                "destruct",
                "magic",
                "phpunit",
                "method_abstract",
                "method_public_static",
                "method_public",
                "method_protected_static",
                "method_protected",
                "method_private_static",
                "method_private"
            ]
        }
    }
}
```

### Laravel Zero Console Optimizations

1. **Console Command Formatting**: Specific formatting for Laravel Zero commands
2. **Service Provider Standards**: Consistent formatting for service providers
3. **ValueObject Organization**: Proper class element ordering for data objects

## Tool Integration

### Command Execution Order

```bash
# 1. Code formatting (prepare code for analysis)
./vendor/bin/pint

# 2. Code modernization and type improvements
./vendor/bin/rector process --dry-run
./vendor/bin/rector process

# 3. Final formatting after Rector changes
./vendor/bin/pint

# 4. Static analysis validation
./vendor/bin/phpstan analyse --level=10

# 5. Final code style validation
./vendor/bin/php-cs-fixer fix --dry-run --diff
```

### Pre-commit Hook Integration

```bash
#!/bin/sh
# .git/hooks/pre-commit

echo "Running static analysis checks..."

# Format code
./vendor/bin/pint --test
if [ $? -ne 0 ]; then
    echo "❌ Code formatting issues found. Run: ./vendor/bin/pint"
    exit 1
fi

# Run PHPStan Level 10
./vendor/bin/phpstan analyse --level=10 --no-progress
if [ $? -ne 0 ]; then
    echo "❌ PHPStan Level 10 violations found"
    exit 1
fi

echo "✅ All static analysis checks passed"
```

## Quality Gates

### CI/CD Pipeline Integration

```yaml
# .github/workflows/static-analysis.yml
name: Static Analysis

on: [push, pull_request]

jobs:
  static-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.4'
          extensions: mbstring, xml, ctype, iconv, intl
          
      - name: Install dependencies
        run: composer install --prefer-dist --no-progress
        
      - name: Run Pint
        run: ./vendor/bin/pint --test
        
      - name: Run PHPStan Level 10
        run: ./vendor/bin/phpstan analyse --level=10 --error-format=github
        
      - name: Run PHP-CS-Fixer
        run: ./vendor/bin/php-cs-fixer fix --dry-run --diff --format=checkstyle
```

### Code Review Checklist

- [ ] All new code passes PHPStan Level 10 analysis
- [ ] Strict type declarations present in all PHP files
- [ ] Complete type annotations for all properties and methods
- [ ] Mixed types handled with explicit type checking
- [ ] Array shapes properly defined with type annotations
- [ ] PHPDoc blocks preserved for complex type scenarios
- [ ] No regression in existing type safety standards

## Performance Optimization

### PHPStan Performance

```neon
# Optimize for large codebase
parallel:
    maximumNumberOfProcesses: 8
    minimumNumberOfJobsPerProcess: 2
    processTimeout: 120.0

# Memory optimization
memoryLimitFile: .phpstan-memory-limit

# Cache optimization
tmpDir: reports/phpstan
```

### Rector Performance

```php
// Optimize memory usage
$rectorConfig->memoryLimit('2G');

// Cache directory
$rectorConfig->cacheDirectory(__DIR__.'/storage/rector');

// Parallel processing (when available)
$rectorConfig->parallel();
```

### Tool Execution Optimization

1. **Incremental Analysis**: Use file change detection for faster analysis
2. **Parallel Processing**: Enable parallel execution where supported
3. **Cache Utilization**: Maintain tool caches for faster subsequent runs
4. **Memory Management**: Configure appropriate memory limits for large codebases

## Troubleshooting

### Common PHPStan Level 10 Issues

#### Mixed Type Violations

```php
// ❌ Problem: Mixed type assignment
public function processData(array $data): array
{
    return $data['context'] ?? []; // PHPStan error: mixed type
}

// ✅ Solution: Explicit type handling
public function processData(array $data): array
{
    $context = $data['context'] ?? [];
    if (is_array($context)) {
        $typedContext = [];
        foreach ($context as $key => $value) {
            $typedContext[(string) $key] = $value;
        }
        return $typedContext;
    }
    return [];
}
```

#### Property Type Annotations

```php
// ❌ Problem: Missing type annotation
protected array $context = []; // PHPStan error: missing type info

// ✅ Solution: Complete type annotation
/**
 * @var array<string, mixed>
 */
protected array $context = [];
```

#### Boolean Logic Validation

```php
// ❌ Problem: Redundant condition
if (str_contains($url, '#') && ! str_starts_with($url, '#')) {
    // PHPStan error: condition always true after early return
}

// ✅ Solution: Simplified logic after early return
if (str_starts_with($url, '#')) {
    return LinkType::ANCHOR;
}
// At this point, we know URL doesn't start with '#'
if (str_contains($url, '#')) {
    return LinkType::CROSS_REFERENCE;
}
```

### Tool Compatibility Issues

#### Rector and PHPStan Integration

```php
// Ensure Rector uses PHPStan configuration
$rectorConfig->phpstanConfig(__DIR__.'/phpstan.neon');
```

#### PHP-CS-Fixer and PHPDoc Preservation

```php
// Preserve PHPDoc for PHPStan Level 10
'no_superfluous_phpdoc_tags' => [
    'allow_mixed' => true,
    'allow_unused_params' => true,
    'remove_inheritdoc' => false,
    'allow_hidden_params' => true,
],
```

### Performance Issues

#### Memory Limit Errors

```bash
# Increase memory limit for PHPStan
php -d memory_limit=2G ./vendor/bin/phpstan analyse

# Configure in phpstan.neon
parameters:
    memoryLimitFile: .phpstan-memory-limit
```

#### Timeout Issues

```neon
# Increase process timeout
parallel:
    processTimeout: 300.0
```

## Best Practices

### Development Workflow

1. **Write Code**: Follow type safety patterns from the start
2. **Format Code**: Run Pint for consistent formatting
3. **Modernize Code**: Use Rector for PHP 8.4+ features
4. **Validate Types**: Run PHPStan Level 10 analysis
5. **Final Check**: Verify with PHP-CS-Fixer

### Type Safety Patterns

1. **Always Use Strict Types**: Start every PHP file with `declare(strict_types=1);`
2. **Explicit Type Annotations**: Provide complete type information for all properties and methods
3. **Handle Mixed Types**: Use explicit type checking and casting
4. **Array Shape Definitions**: Define specific array structures with type annotations
5. **Preserve PHPDoc**: Maintain PHPDoc blocks for complex type scenarios

### Maintenance

1. **Regular Updates**: Keep static analysis tools updated
2. **Configuration Sync**: Ensure all tool configurations remain compatible
3. **Performance Monitoring**: Monitor analysis performance and optimize as needed
4. **Documentation Updates**: Keep this document synchronized with configuration changes

---

## Navigation

**← Previous:** [Development Standards](040-development-standards.md) | **Next →** [Type Safety Standards](type-safety-standards.md)