# Pest Testing Configuration Guide

**Created:** 2025-07-16  
**Focus:** Pest PHP testing framework setup for Chinook project  
**Source:** [Chinook Project composer.json](https://github.com/s-a-c/chinook/blob/main/composer.json)

## 1. Table of Contents

- [1.1. Overview](#11-overview)
- [1.2. Pest Package Ecosystem](#12-pest-package-ecosystem)
- [1.3. Installation & Setup](#13-installation--setup)
- [1.4. Configuration Files](#14-configuration-files)
- [1.5. Test Organization](#15-test-organization)
- [1.6. Running Tests](#16-running-tests)
- [1.7. Advanced Features](#17-advanced-features)
- [1.8. Troubleshooting](#18-troubleshooting)

## 1.1. Overview

The Chinook project uses Pest PHP as the primary testing framework, providing a modern, expressive testing experience for Laravel 12 applications with comprehensive plugin support.

### 1.1.1. Why Pest PHP?
- **Expressive Syntax**: Clean, readable test code
- **Laravel Integration**: Native Laravel testing features
- **Plugin Ecosystem**: Extensive plugin support
- **Performance**: Fast test execution
- **Modern PHP**: PHP 8.4+ features support

## 1.2. Pest Package Ecosystem

### 1.2.1. Core Pest Packages
| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| **pestphp/pest** | ^3.8 | Core testing framework | ✅ Verified |
| **pestphp/pest-plugin-laravel** | ^3.2 | Laravel integration | ✅ Verified |

### 1.2.2. Pest Plugins
| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| **pestphp/pest-plugin** | ^3.x-dev | Plugin system | ✅ Verified |
| **pestphp/pest-plugin-arch** | ^3.1 | Architecture testing | ✅ Verified |
| **pestphp/pest-plugin-faker** | ^3.0 | Faker integration | ✅ Verified |
| **pestphp/pest-plugin-livewire** | ^3.0 | Livewire testing | ✅ Verified |
| **pestphp/pest-plugin-stressless** | ^3.1 | Stress testing | ✅ Verified |
| **pestphp/pest-plugin-type-coverage** | ^3.5 | Type coverage analysis | ✅ Verified |
| **pestphp/pest-plugin-watch** | ^3.0 | File watching | ✅ Verified |

### 1.2.3. Additional Testing Tools
| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| **spatie/pest-plugin-snapshots** | ^2.2 | Snapshot testing | ✅ Verified |
| **jasonmccreary/laravel-test-assertions** | ^2.8 | Additional assertions | ✅ Verified |

## 1.3. Installation & Setup

### 1.3.1. Package Installation
```bash
# Core Pest packages (already included in composer.json)
composer require pestphp/pest --dev
composer require pestphp/pest-plugin-laravel --dev

# Initialize Pest in project
./vendor/bin/pest --init
```

### 1.3.2. Pest Initialization
```bash
# Initialize Pest configuration
./vendor/bin/pest --init

# This creates:
# - tests/Pest.php (configuration)
# - phpunit.xml (PHPUnit configuration)
```

### 1.3.3. Directory Structure
```
tests/
├── Pest.php                 # Pest configuration
├── Feature/                 # Feature tests
│   ├── ExampleTest.php
│   └── Chinook/
│       ├── ArtistTest.php
│       └── AlbumTest.php
├── Unit/                    # Unit tests
│   ├── ExampleTest.php
│   └── Models/
│       └── Chinook/
└── TestCase.php            # Base test case
```

## 1.4. Configuration Files

### 1.4.1. Pest Configuration (tests/Pest.php)

```php
<?php

use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;

/*
|--------------------------------------------------------------------------
| Test Case
|--------------------------------------------------------------------------
*/

uses(TestCase::class)->in('Feature');
uses(TestCase::class)->in('Unit');

/*
|--------------------------------------------------------------------------
| Expectations
|--------------------------------------------------------------------------
*/

expect()->extend('toBeOne', function () {
    return $this->toBe(1);
});

/*
|--------------------------------------------------------------------------
| Functions
|--------------------------------------------------------------------------
*/

function something()
{
    // ..
}

/*
|--------------------------------------------------------------------------
| Database
|--------------------------------------------------------------------------
*/

uses(RefreshDatabase::class)->in('Feature');
```

### 1.4.2. PHPUnit Configuration (phpunit.xml)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="vendor/phpunit/phpunit/phpunit.xsd"
         bootstrap="vendor/autoload.php"
         colors="true">
    <testsuites>
        <testsuite name="Unit">
            <directory>tests/Unit</directory>
        </testsuite>
        <testsuite name="Feature">
            <directory>tests/Feature</directory>
        </testsuite>
    </testsuites>
    <source>
        <include>
            <directory>app</directory>
        </include>
    </source>
    <php>
        <env name="APP_ENV" value="testing"/>
        <env name="DB_CONNECTION" value="sqlite"/>
        <env name="DB_DATABASE" value=":memory:"/>
        <env name="CACHE_DRIVER" value="array"/>
        <env name="QUEUE_CONNECTION" value="sync"/>
        <env name="SESSION_DRIVER" value="array"/>
    </php>
</phpunit>
```

### 1.4.3. Environment Configuration (.env.testing)
```env
APP_ENV=testing
APP_KEY=base64:test-key-here
APP_DEBUG=true

DB_CONNECTION=sqlite
DB_DATABASE=:memory:

CACHE_DRIVER=array
QUEUE_CONNECTION=sync
SESSION_DRIVER=array
MAIL_MAILER=array

FILAMENT_PANEL_ID=chinook-fm
```

## 1.5. Test Organization

### 1.5.1. Test Groups
Pest supports test grouping for organized execution:

```php
// Feature test example
it('can create an artist', function () {
    // Test implementation
})->group('feature', 'database', 'chinook');

// Unit test example
it('validates artist name', function () {
    // Test implementation
})->group('unit', 'validation');
```

### 1.5.2. Composer Test Scripts
The project includes comprehensive test scripts:

```json
{
  "scripts": {
    "test": ["@clear", "@php artisan test"],
    "test:api": "pest --group=api",
    "test:arch": "pest --group=arch",
    "test:coverage": "pest --coverage",
    "test:coverage-html": "pest --coverage --coverage-html=reports/coverage",
    "test:database": "pest --group=database",
    "test:feature": "pest --group=feature",
    "test:parallel": "pest --parallel",
    "test:unit": "pest --group=unit"
  }
}
```

## 1.6. Running Tests

### 1.6.1. Basic Test Execution
```bash
# Run all tests
./vendor/bin/pest

# Run with verbose output
./vendor/bin/pest -v

# Run specific test file
./vendor/bin/pest tests/Feature/Chinook/ArtistTest.php
```

### 1.6.2. Group-Based Testing
```bash
# Run feature tests only
composer test:feature

# Run unit tests only
composer test:unit

# Run database tests
composer test:database

# Run API tests
composer test:api
```

### 1.6.3. Coverage Reports
```bash
# Generate coverage report
composer test:coverage

# Generate HTML coverage report
composer test:coverage-html

# View coverage in browser
open reports/coverage/index.html
```

### 1.6.4. Parallel Testing
```bash
# Run tests in parallel
composer test:parallel

# Specify number of processes
./vendor/bin/pest --parallel --processes=4
```

## 1.7. Advanced Features

### 1.7.1. Architecture Testing
```php
// tests/Feature/ArchitectureTest.php
arch('models')
    ->expect('App\Models\Chinook')
    ->toExtend('Illuminate\Database\Eloquent\Model')
    ->toUse(['Illuminate\Database\Eloquent\SoftDeletes']);

arch('controllers')
    ->expect('App\Http\Controllers')
    ->toBeClasses()
    ->toExtend('App\Http\Controllers\Controller');
```

### 1.7.2. Livewire Testing
```php
// Test Livewire components
it('can render artist component', function () {
    Livewire::test(ArtistComponent::class)
        ->assertSee('Artists')
        ->assertViewIs('livewire.artist-component');
});
```

### 1.7.3. Snapshot Testing
```php
// Snapshot testing for consistent output
it('generates correct artist JSON', function () {
    $artist = Artist::factory()->create();
    
    expect($artist->toArray())->toMatchSnapshot();
});
```

### 1.7.4. Type Coverage
```bash
# Check type coverage
composer test:type-coverage

# Minimum type coverage threshold
./vendor/bin/pest --type-coverage --min=80
```

## 1.8. Troubleshooting

### 1.8.1. Common Issues

#### Memory Limit Exceeded
```bash
# Increase PHP memory limit
php -d memory_limit=512M ./vendor/bin/pest
```

#### Database Connection Issues
```bash
# Ensure SQLite is available
php -m | grep sqlite

# Create test database
touch database/testing.sqlite
```

#### Plugin Conflicts
```bash
# Clear Pest cache
rm -rf .pest

# Reinstall plugins
composer install --dev
```

### 1.8.2. Performance Optimization

#### Parallel Testing
```bash
# Optimal process count (CPU cores)
./vendor/bin/pest --parallel --processes=$(nproc)
```

#### Database Optimization
```php
// Use transactions for faster tests
uses(RefreshDatabase::class)->in('Feature');

// Or use database transactions
uses(DatabaseTransactions::class)->in('Feature');
```

### 1.8.3. Debugging Tests

#### Verbose Output
```bash
# Debug failing tests
./vendor/bin/pest -v --stop-on-failure

# Show test names
./vendor/bin/pest --testdox
```

#### Ray Integration
```php
// Use Spatie Ray for debugging
it('debugs artist creation', function () {
    $artist = Artist::factory()->create();
    
    ray($artist); // Debug output
    
    expect($artist)->toBeInstanceOf(Artist::class);
});
```

## 1.9. Chinook-Specific Testing

### 1.9.1. Model Testing Patterns
```php
// Test Chinook models with taxonomy
it('can assign taxonomy to artist', function () {
    $artist = Artist::factory()->create();
    $term = Term::factory()->create();
    
    $artist->attachTerm($term);
    
    expect($artist->terms)->toContain($term);
});
```

### 1.9.2. Filament Resource Testing
```php
// Test Filament resources
it('can access artist resource', function () {
    $user = User::factory()->create();
    
    $this->actingAs($user)
        ->get('/chinook-fm/artists')
        ->assertSuccessful();
});
```

### 1.9.3. Database Seeder Testing
```php
// Test seeders
it('can seed chinook data', function () {
    $this->artisan('db:seed', ['--class' => 'ChinookDatabaseSeeder'])
        ->assertSuccessful();
    
    expect(Artist::count())->toBeGreaterThan(0);
});
```

## 1.10. Educational Scope

### 1.10.1. Learning Objectives
- **Modern Testing**: Pest PHP best practices
- **Laravel Integration**: Framework-specific testing
- **TDD Workflow**: Test-driven development
- **Quality Assurance**: Comprehensive test coverage

### 1.10.2. Production Considerations
**⚠️ Educational Use Only**: This configuration is optimized for learning environments.

For production testing:
- CI/CD integration with GitHub Actions
- Database testing with realistic data volumes
- Performance testing under load
- Security testing for vulnerabilities

---

## Navigation

**Index:** [Packages Documentation](000-packages-index.md) | **Previous:** [Frontend Dependencies](000-frontend-dependencies-guide.md)

---

**Documentation Standards**: This document follows WCAG 2.1 AA accessibility guidelines and uses Laravel 12 modern syntax patterns.

[⬆️ Back to Top](#pest-testing-configuration-guide)
