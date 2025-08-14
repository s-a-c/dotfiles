# Testing Documentation

**Date:** January 22, 2025  
**Project:** Laravel Zero validate-links Documentation Enhancement  
**Phase:** Testing Documentation Enhancement

## Executive Summary

This document provides comprehensive documentation for the validate-links test suite architecture, including test boundaries, execution instructions, coverage requirements, and best practices for maintaining high-quality test coverage.

## Test Suite Architecture

### Framework Overview
- **Testing Framework:** Pest PHP (^3.8.2)
- **Base Framework:** PHPUnit (underlying)
- **Mocking Framework:** Mockery (^1.6.12)
- **Architecture Testing:** Pest Plugin Arch (^3.1)
- **Type Coverage:** Pest Plugin Type Coverage (^3.6)
- **Stress Testing:** Pest Plugin Stressless (^3.1)

### Test Directory Structure
```
tests/
├── Feature/           # End-to-end functionality tests
│   └── InspireCommandTest.php
├── Unit/              # Individual class/method isolation tests
│   ├── ExampleTest.php
│   ├── LinkValidationServiceTest.php
│   ├── ValidateCommandTesst.php  # Note: Typo in filename
│   └── Services/
│       └── SecurityValidationServiceTest.php
├── Pest.php           # Pest configuration and helpers
└── TestCase.php       # Base test case class
```

## Test Type Boundaries

### 1. Unit Tests (`tests/Unit/`)
**Purpose:** Test individual classes and methods in isolation

**Scope:**
- Single class or method testing
- Mock all external dependencies
- Fast execution (< 100ms per test)
- No file system or network operations
- No database interactions

**Examples:**
- Value Object behavior testing
- Service method logic validation
- Command option parsing
- Formatter output generation

**Test Pattern:**
```php
it('validates internal links', function () {
    $service = app(LinkValidationService::class);
    $config = new ValidationConfig(
        paths: ['path/to/docs'],
        scope: ['internal'],
        checkExternal: false
    );

    $result = $service->validateFiles(['path/to/docs/file1.md'], $config);

    expect($result->getBrokenCount())->toBe(0);
});
```

### 2. Feature Tests (`tests/Feature/`)
**Purpose:** Test complete user workflows and command functionality

**Scope:**
- End-to-end command execution
- Real file system operations (with cleanup)
- Integration between multiple services
- CLI output and exit codes
- Configuration loading and validation

**Examples:**
- Complete validation workflow
- Report generation end-to-end
- Interactive command flows
- Error handling scenarios

**Test Pattern:**
```php
it('validates markdown files and generates report', function () {
    // Setup test files
    $testDir = createTestDirectory();
    createTestMarkdownFiles($testDir);

    // Execute command
    $this->artisan('validate', ['paths' => [$testDir]])
         ->expectsOutput('Validation completed')
         ->assertExitCode(0);

    // Cleanup
    removeTestDirectory($testDir);
});
```

### 3. Service Tests (Proposed)
**Purpose:** Test business logic layer with controlled dependencies

**Scope:**
- Service integration testing
- Business rule validation
- Cross-service communication
- Configuration-driven behavior

### 4. Interface Tests (Proposed)
**Purpose:** Test API contracts and validation interfaces

**Scope:**
- Contract compliance testing
- Interface method signatures
- Return type validation
- Exception handling contracts

### 5. Integration Tests (Proposed)
**Purpose:** Test component interaction and system integration

**Scope:**
- Service provider registration
- Dependency injection resolution
- Configuration integration
- Plugin system integration

## Test Configuration

### Pest Configuration (`pest.config.php`)
```php
return [
    // Parallel testing configuration
    Parallel::class => [
        'processes' => 8,        # Number of parallel processes
        'timeout' => 120,        # Timeout per process (seconds)
    ],

    // Type coverage configuration
    TypeCoverage::class => [
        'level' => 95,           # Required type coverage percentage
        'ignoreUntyped' => false, # Don't ignore untyped code
        'ignoreFiles' => [       # Files to exclude from coverage
            'app/Console/Kernel.php',
            'app/Exceptions/Handler.php',
            'vendor/**/*.php',
        ],
    ],
];
```

### Test Case Configuration (`tests/Pest.php`)

```php
// Bind TestCase to Feature tests
uses(old\TestCase::class)->in('Feature');

// Custom expectations
expect()->extend('toBeOne', function () {
    return $this->toBe(1);
});

// Global helper functions
function something(): void {
    // Test helper implementation
}
```

## Execution Instructions

### Basic Test Execution
```bash
# Run all tests
composer test
# or
vendor/bin/pest

# Run specific test suite
composer test:unit
composer test:feature

# Run specific test file
vendor/bin/pest tests/Unit/LinkValidationServiceTest.php

# Run tests with specific filter
vendor/bin/pest --filter="validates internal links"
```

### Coverage Testing
```bash
# Generate HTML coverage report
composer test:coverage
# or
vendor/bin/pest --coverage --coverage-html=coverage-html

# Generate coverage with minimum threshold
vendor/bin/pest --coverage --min=80

# Type coverage analysis
vendor/bin/pest --type-coverage --type-coverage-min=95
```

### Parallel Testing
```bash
# Run tests in parallel (configured for 8 processes)
vendor/bin/pest --parallel

# Run with custom process count
vendor/bin/pest --parallel --processes=4
```

### Advanced Testing Options
```bash
# Run with profiling
vendor/bin/pest --profile

# Run with memory usage tracking
vendor/bin/pest --memory-limit=512M

# Run with verbose output
vendor/bin/pest --verbose

# Run tests and stop on first failure
vendor/bin/pest --stop-on-failure
```

## Coverage Requirements

### Minimum Coverage Targets
- **Overall Code Coverage:** 80% minimum
- **Type Coverage:** 95% minimum (configured in pest.config.php)
- **Critical Path Coverage:** 100% (validation logic, security features)
- **Command Coverage:** 90% (all CLI commands and options)

### Coverage Exclusions
- Generated files (bootstrap, compiled assets)
- Third-party packages (vendor/)
- Framework boilerplate (some Laravel Zero files)
- Development-only utilities

### Coverage Reporting
```bash
# Generate comprehensive coverage report
composer test:coverage

# View coverage in browser
open coverage-html/index.html

# Generate coverage for CI/CD
vendor/bin/pest --coverage --coverage-clover=coverage.xml
```

## Test Data Management

### Test Fixtures
**Location:** `tests/Fixtures/`
**Purpose:** Reusable test data and file structures

**Recommended Structure:**
```
tests/Fixtures/
├── markdown/          # Sample markdown files
│   ├── valid.md
│   ├── broken-links.md
│   └── complex-structure.md
├── config/            # Test configuration files
│   └── test-config.php
└── responses/         # Mock HTTP responses
    ├── success.json
    └── error.json
```

### Test Data Helpers
```php
// Create temporary test directory
function createTestDirectory(): string {
    return sys_get_temp_dir() . '/validate-links-test-' . uniqid();
}

// Create test markdown files
function createTestMarkdownFiles(string $dir): void {
    file_put_contents($dir . '/test.md', '# Test\n[Link](./other.md)');
    file_put_contents($dir . '/other.md', '# Other\nContent');
}

// Cleanup test files
function removeTestDirectory(string $dir): void {
    if (is_dir($dir)) {
        array_map('unlink', glob("$dir/*"));
        rmdir($dir);
    }
}
```

### Mock Data Patterns
```php
// Mock external HTTP responses
function mockHttpResponse(int $status = 200, array $headers = []): void {
    Http::fake([
        'example.com/*' => Http::response('OK', $status, $headers),
        'broken.com/*' => Http::response('Not Found', 404),
    ]);
}

// Mock file system operations
function mockFileSystem(): void {
    Storage::fake('local');
    Storage::put('test.md', '# Test Content');
}
```

## Best Practices

### Test Organization
1. **One concept per test** - Each test should verify one specific behavior
2. **Descriptive test names** - Use clear, readable descriptions
3. **Arrange-Act-Assert pattern** - Structure tests consistently
4. **Independent tests** - Tests should not depend on each other

### Test Writing Guidelines
```php
// Good: Descriptive and focused
it('returns broken links when markdown contains invalid internal references', function () {
    // Arrange
    $service = app(LinkValidationService::class);
    $config = ValidationConfig::withDefaults(['scope' => ['internal']]);
    
    // Act
    $result = $service->validateFile('broken-links.md', $config);
    
    // Assert
    expect($result->hasBrokenLinks())->toBeTrue();
    expect($result->getBrokenCount())->toBe(2);
});

// Avoid: Vague and testing multiple concepts
it('tests validation', function () {
    // Too broad and unclear
});
```

### Performance Guidelines
- **Unit tests:** < 100ms per test
- **Feature tests:** < 5 seconds per test
- **Total suite:** < 2 minutes for full run
- **Parallel execution:** Utilize all available CPU cores

### Mocking Strategy
```php
// Mock external dependencies
beforeEach(function () {
    $this->mockHttp = Http::fake();
    $this->mockStorage = Storage::fake();
});

// Use dependency injection for testability
it('validates external links with timeout', function () {
    $httpClient = Mockery::mock(HttpClientInterface::class);
    $httpClient->shouldReceive('get')
              ->with('https://example.com')
              ->andReturn(new Response(200));
              
    $service = new LinkValidationService($httpClient);
    // ... test implementation
});
```

## Continuous Integration Integration

### GitHub Actions Configuration
```yaml
- name: Run Tests
  run: |
    composer test:coverage
    
- name: Upload Coverage
  uses: codecov/codecov-action@v3
  with:
    file: ./coverage.xml
    
- name: Check Coverage Threshold
  run: |
    vendor/bin/pest --coverage --min=80
```

### Quality Gates
- All tests must pass
- Minimum 80% code coverage
- Minimum 95% type coverage
- No failing architecture tests
- Performance benchmarks within limits

## Troubleshooting

### Common Issues

#### Memory Limit Errors
```bash
# Increase memory limit for tests
php -d memory_limit=1G vendor/bin/pest
```

#### Parallel Test Failures
```bash
# Run tests sequentially for debugging
vendor/bin/pest --no-parallel

# Reduce parallel processes
vendor/bin/pest --parallel --processes=2
```

#### Coverage Generation Issues
```bash
# Ensure Xdebug is installed and enabled
php -m | grep xdebug

# Alternative: Use PCOV for faster coverage
composer require --dev pcov/clobber
```

### Test Debugging
```php
// Add debugging output
it('debugs validation process', function () {
    $result = $service->validate($input);
    
    // Temporary debugging
    dump($result->toArray());
    ray($result); // If using Ray
    
    expect($result)->toBeInstanceOf(ValidationResult::class);
});
```

## Future Enhancements

### Planned Test Types
1. **Performance Tests** - Benchmark critical operations
2. **Security Tests** - Validate security constraints
3. **Compatibility Tests** - Test across PHP versions
4. **Load Tests** - Test with large documentation sets

### Test Automation
1. **Mutation Testing** - Verify test quality with Infection
2. **Property-Based Testing** - Generate test cases automatically
3. **Visual Regression Testing** - Test CLI output formatting
4. **Contract Testing** - Validate API contracts

## Maintenance Guidelines

### Regular Tasks
- Review and update test coverage monthly
- Refactor slow tests quarterly
- Update test data and fixtures as needed
- Monitor test execution times and optimize

### Test Review Checklist
- [ ] Tests are independent and isolated
- [ ] Test names clearly describe behavior
- [ ] Appropriate test type for scope
- [ ] Mocks are used appropriately
- [ ] Test data is cleaned up
- [ ] Coverage targets are met
- [ ] Performance guidelines followed
