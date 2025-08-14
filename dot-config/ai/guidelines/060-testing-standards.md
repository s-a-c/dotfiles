# 6. Testing Standards

## Overview

This document outlines the testing standards for the project and serves as an index to more detailed testing-related guidelines. Following these standards ensures consistency, maintainability, and effectiveness of our test suite.

## Table of Contents

1. [Test Organization](#test-organization)
2. [Naming Conventions](#naming-conventions)
3. [Test Data Management](#test-data-management)
4. [Assertion Best Practices](#assertion-best-practices)
5. [Documentation Standards](#documentation-standards)
6. [Test Categories and Grouping](#test-categories-and-grouping)
7. [Performance Considerations](#performance-considerations)
8. [Tools and Extensions](#tools-and-extensions)
9. [PHPStan Level 10 Compliance](#phpstan-level-10-compliance)
10. [Continuous Integration](#continuous-integration)
11. [Detailed Guidelines](#detailed-guidelines)

## Test Organization

Tests should mirror the structure of the application code:

```
tests/
├── Unit/                  # Unit tests
│   └── Plugins/
│       └── [PluginName]/
│           ├── Models/    # Tests for models
│           └── Services/  # Tests for services
├── Feature/               # Feature tests
│   └── Plugins/
│       └── [PluginName]/
│           ├── Controllers/ # Tests for controllers
│           └── API/         # Tests for API endpoints
├── Integration/           # Integration tests
│   └── Plugins/
│       └── [PluginName]/
├── Traits/                # Shared test traits
├── Factories/             # Test data factories
└── Helpers/               # Test helper functions
```

### Test Types

1. **Unit Tests**: Test individual components in isolation
   - Located in `tests/Unit/`
   - Focus on testing a single class or method
   - Use mocks and stubs for dependencies

2. **Feature Tests**: Test complete features or user workflows
   - Located in `tests/Feature/`
   - Test HTTP endpoints, controllers, and resources
   - Often involve database interactions

3. **Integration Tests**: Test interactions between components
   - Located in `tests/Integration/`
   - Test how multiple components work together
   - May involve multiple services or subsystems

## Naming Conventions

### Test Class Naming

- Test classes should be named after the class they test, with "Test" suffix
- Example: `InvoiceTest.php` for testing the `Invoice` class

### Test Method Naming

- Test methods should clearly describe what they're testing
- Use the format: `test_[method_name]_[scenario]_[expected_result]`
- Examples:
  - `test_create_with_valid_data_returns_success()`
  - `test_update_with_invalid_id_throws_exception()`

## Test Data Management

### Factories

- Use Laravel's factory system for creating test data
- Define factories for all models in `database/factories/`
- Use factory states for different scenarios

### Test Data Isolation

- Tests should not depend on data created by other tests
- Use database transactions to isolate test data: `use DatabaseTransactions;`
- Clean up any created files or external resources in tearDown methods

## Assertion Best Practices

### General Guidelines

- Each test should have a clear, single purpose
- Use descriptive assertion messages
- Test both positive and negative scenarios
- Avoid testing multiple behaviors in a single test

### Common Assertions

- Use appropriate assertions for the data type being tested
- Examples:
  - `assertEquals()` for exact matches
  - `assertContains()` for collections
  - `assertInstanceOf()` for object types
  - `assertDatabaseHas()` for database records

## Documentation Standards

### Test Class Documentation

- Each test class should have a PHPDoc block describing what it tests
- Include `@covers` annotation to indicate which class is being tested
- Use PHP attributes like `#[CoversClass(ClassName::class)]`

### Test Method Documentation

- Each test method should have a PHPDoc block describing:
  - What is being tested
  - The expected outcome
  - Any special setup or conditions

## Test Categories and Grouping

### Using PHP Attributes

- Use PHP attributes to categorize tests
- Examples:
  ```php
  #[Group('api')]
  #[Group('database')]
  #[Group('slow')]
  ```

### Standard Categories

- Technical categories:
  - `api`: Tests involving API endpoints
  - `database`: Tests with database interactions
  - `ui`: Tests involving UI components
  - `performance`: Tests measuring performance
  - `slow`: Tests that take longer than average to run

- Domain-specific categories:
  - `invoices`: Tests related to invoice functionality
  - `payments`: Tests related to payment functionality
  - `products`: Tests related to product functionality

## Performance Considerations

### Optimizing Test Speed

- Use database transactions instead of migrations when possible
- Consider using in-memory SQLite for faster database tests
- Minimize external API calls in tests

### Parallel Testing

- Configure parallel testing in phpunit.xml and pest.config.php
- Ensure tests are independent and can run in parallel
- Use the `--parallel` option when running tests

## Tools and Extensions

### Required Tools

- **PHPUnit/Pest**: Primary testing framework
- **Mockery**: For creating test doubles
- **Larastan**: For static analysis
- **Infection PHP**: For mutation testing

### Optional Tools

- **Laravel Dusk**: For browser testing
- **Codeception**: For BDD-style tests

## Continuous Integration

### CI Pipeline Integration

- All tests should run on every pull request
- Test coverage reports should be generated
- Minimum coverage thresholds should be enforced (70%)

### Reporting

- Test results should be reported in a readable format
- Coverage reports should highlight areas needing more tests
- Performance metrics should be tracked over time

## PHPStan Level 10 Compliance

### Core Requirements

**Test Code Quality Standards**:

- All test files should strive for PHPStan Level 10 compliance where practical
- Core application code (`app/` directory) must achieve 0 PHPStan level 10 errors
- Test files may have relaxed standards for complex reflection-based testing scenarios
- Use strict type declarations: `declare(strict_types=1);` in all test files

### Test-Specific Type Safety

**Pest Framework Compliance**:

```php
// ✅ Correct: Proper type handling in Pest tests
it('validates external links correctly', function (): void {
    $service = app(LinkValidationInterface::class);
    $result = $service->validateLink('https://example.com');

    expect($result)->toBeInstanceOf(ValidationResult::class)
        ->and($result->isValid())->toBeTrue();
});

// ❌ Incorrect: Missing return type and unclear assertions
it('validates external links correctly', function () {
    $service = app(LinkValidationInterface::class);
    $result = $service->validateLink('https://example.com');

    expect($result->isValid())->toBe(true); // Less specific assertion
});
```

**Property and Variable Typing**:

```php
// ✅ Correct: Explicit type declarations in test setup
beforeEach(function (): void {
    $this->service = app(LinkValidationInterface::class);
    $this->testUrls = [
        'https://example.com',
        'internal-link.md',
        '#anchor-link'
    ];
});

// ❌ Incorrect: Implicit typing without declarations
beforeEach(function () {
    $this->service = app(LinkValidationInterface::class);
    $this->testUrls = ['https://example.com', 'internal-link.md']; // Mixed array types
});
```

### Architecture Test Compliance

**Reflection-Based Testing**:

- Architecture tests using reflection may require type casting for PHPStan compliance
- Use `@phpstan-ignore-next-line` sparingly and only for unavoidable reflection scenarios
- Prefer typed alternatives when possible

```php
// ✅ Acceptable: Necessary type casting for reflection
arch('services implement required interfaces')
    ->expect('App\Services')
    ->toImplement('App\Contracts\ServiceInterface')
    ->ignorePhpStanErrors(); // Only when reflection is unavoidable

// ✅ Preferred: Direct interface validation without reflection
it('validates service implements interface', function (): void {
    $service = app(LinkValidationInterface::class);
    expect($service)->toBeInstanceOf(LinkValidationInterface::class);
});
```

### Test Data Type Safety

**Factory and Mock Typing**:

```php
// ✅ Correct: Typed test data creation
/** @return array<string, mixed> */
function createTestValidationData(): array
{
    return [
        'url' => 'https://example.com',
        'expected_status' => LinkStatus::VALID,
        'context' => ['source' => 'test']
    ];
}

// ❌ Incorrect: Untyped test data
function createTestValidationData()
{
    return [
        'url' => 'https://example.com',
        'expected_status' => 'valid', // Should use enum
        'context' => null // Mixed types
    ];
}
```

### Compliance Verification

**Running PHPStan on Tests**:

```bash
# Analyze core application (must pass level 10)
./vendor/bin/phpstan analyse --level=10 app/

# Analyze tests (aim for level 10, document exceptions)
./vendor/bin/phpstan analyse --level=10 tests/

# Generate compliance reports
./vendor/bin/phpstan analyse --level=10 app/ 2>&1 > reports/phpstan/app-compliance.txt
```

**Exception Documentation**:

- Document any PHPStan exceptions in test files with clear justification
- Use `@phpstan-ignore-next-line` with explanatory comments
- Prefer refactoring over ignoring when possible

## Detailed Guidelines

For more detailed information on specific testing topics, refer to the following guidelines:

- [Comprehensive Testing Guide](comprehensive-testing-guide.md) - Complete guide to all testing aspects
- [Plugin Testing Guidelines](plugin-testing-guidelines.md) - Specific guidelines for testing plugins
- [Test Categories](test-categories.md) - Detailed information on test categorization
- [Test Coverage](test-coverage.md) - Guidelines for test coverage requirements
- [Test Data Requirements](test-data-requirements.md) - Standards for test data management
- [Test Examples](test-examples.md) - Example tests for reference
- [Test Helpers and Utilities](test-helpers-utilities.md) - Documentation for test helpers
- [Test Linting Rules](test-linting-rules.md) - Rules for linting test files

Additionally, you can find test templates in the [Testing Templates](070-testing/090-templates/000-index.md) directory.

## See Also

### Related Guidelines

- **[Development Standards](030-development-standards.md)** - Testing requirements and architecture testing
- **[Project Overview](010-project-overview.md)** - Understanding plugin structure for testing
- **[Security Standards](090-security-standards.md)** - Security testing requirements
- **[Performance Standards](100-performance-standards.md)** - Performance testing and monitoring
- **[Workflow Guidelines](040-workflow-guidelines.md)** - CI/CD testing integration
- **[Testing Guidelines](070-testing/000-index.md)** - Comprehensive testing documentation

### Testing Decision Guide for Junior Developers

#### "I need to test a new feature - what type of test should I write?"

1. **Individual Class/Method**: Write **Unit Tests** (section 2.1) in `tests/Unit/`
2. **HTTP Endpoint**: Create **Feature Tests** (section 2.1) in `tests/Feature/`
3. **Multiple Components**: Develop **Integration Tests** (section 2.1) in `tests/Integration/`
4. **User Interface**: Use **Browser Tests** with Laravel Dusk for UI interactions

#### "I'm not sure about test naming - what conventions should I follow?"

- **Test Classes**: Follow section 3.1 naming (e.g., `InvoiceTest.php` for `Invoice` class)
- **Test Methods**: Use section 3.2 format: `test_[method]_[scenario]_[expected_result]()`
- **Examples**: `test_create_with_valid_data_returns_success()`
- **Descriptive Names**: Make test purpose clear from the method name

#### "I need to create test data - what's the best approach?"

- **Factories**: Use section 4.1 Laravel factory system in `database/factories/`
- **Isolation**: Follow section 4.2 test data isolation with `DatabaseTransactions`
- **Cleanup**: Implement proper tearDown methods for external resources
- **Realistic Data**: Create meaningful test data that reflects real usage

#### "I'm writing assertions - what should I focus on?"

- **Single Purpose**: Follow section 5.1 - each test should have one clear purpose
- **Descriptive Messages**: Use section 5.1 descriptive assertion messages
- **Appropriate Types**: Apply section 5.2 correct assertions for data types
- **Both Scenarios**: Test both positive and negative cases

#### "I need to categorize my tests - what groups should I use?"

- **Technical**: Use section 6.2 categories (`api`, `database`, `ui`, `performance`, `slow`)
- **Domain**: Apply domain-specific categories (`invoices`, `payments`, `products`)
- **PHP Attributes**: Follow section 6.1 using `#[Group('category')]` syntax
- **Multiple Groups**: Tests can belong to multiple categories as appropriate

---

## Navigation

**← Previous:** [Workflow Guidelines](040-workflow-guidelines.md)

**Next →** [TOC-Heading Synchronization](070-toc-heading-synchronization.md)
