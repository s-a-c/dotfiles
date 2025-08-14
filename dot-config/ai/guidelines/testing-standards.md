# Testing Standards

## Overview

This document establishes comprehensive testing standards for maintaining **PHPStan Level 10 compliance** in test code while ensuring robust test coverage and quality. These standards are based on the successfully implemented testing infrastructure that achieved 100% E2E test passing rates and significantly improved unit test infrastructure.

## Table of Contents

1. [Testing Framework Standards](#testing-framework-standards)
2. [PHPStan Level 10 Compliance in Tests](#phpstan-level-10-compliance-in-tests)
3. [Test Infrastructure Requirements](#test-infrastructure-requirements)
4. [E2E Testing Methodologies](#e2e-testing-methodologies)
5. [Unit Testing Standards](#unit-testing-standards)
6. [Mock Lifecycle Management](#mock-lifecycle-management)
7. [Test Data Management](#test-data-management)
8. [Laravel Zero Testing Patterns](#laravel-zero-testing-patterns)
9. [Performance Testing](#performance-testing)
10. [CI/CD Integration](#cicd-integration)

## Testing Framework Standards

### Core Testing Stack

**Primary Framework**: Pest PHP with Laravel Zero integration

```php
<?php

declare(strict_types=1);

use App\Services\Contracts\LinkValidationInterface;
use App\Services\ValueObjects\ValidationResult;
use App\Enums\LinkStatus;

// ✅ Correct: Type-safe Pest test with explicit return type
it('validates external links correctly', function (): void {
    $service = app(LinkValidationInterface::class);
    $result = $service->validateLink('https://example.com');

    expect($result)->toBeInstanceOf(ValidationResult::class)
        ->and($result->isValid())->toBeTrue()
        ->and($result->getStatus())->toBe(LinkStatus::VALID);
});
```

### Required Testing Dependencies

```json
{
    "require-dev": {
        "pestphp/pest": "^3.8",
        "pestphp/pest-plugin-laravel": "^3.2",
        "pestphp/pest-plugin-arch": "^3.1",
        "pestphp/pest-plugin-type-coverage": "^3.5",
        "mockery/mockery": "^1.6",
        "larastan/larastan": "^3.4"
    }
}
```

### Test Configuration

**File**: [`pest.config.php`](../../pest.config.php)

```php
<?php

declare(strict_types=1);

use Pest\Arch\Expectations\Targeted;

return [
    'testsuites' => [
        'Unit' => 'tests/Unit',
        'Feature' => 'tests/Feature',
        'Integration' => 'tests/Integration',
        'E2E' => 'tests/E2E',
        'Architecture' => 'tests/Architecture',
    ],
    'coverage' => [
        'min' => 90.0,
        'report' => [
            'html' => 'reports/coverage/html',
            'clover' => 'reports/coverage/clover.xml',
        ],
    ],
];
```

## PHPStan Level 10 Compliance in Tests

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
it('validates link validation service integration', function (): void {
    $service = app(LinkValidationInterface::class);
    expect($service)->toBeInstanceOf(LinkValidationInterface::class);
    
    $config = ValidationConfig::create(['scopes' => [ValidationScope::EXTERNAL]]);
    $result = $service->validateLink('https://example.com', $config);
    
    expect($result)->toBeInstanceOf(ValidationResult::class)
        ->and($result->getUrl())->toBe('https://example.com')
        ->and($result->getScope())->toBe(ValidationScope::EXTERNAL);
});

// ❌ Incorrect: Missing return type and unclear assertions
it('validates external links correctly', function () {
    $service = app(LinkValidationInterface::class);
    $result = $service->validateLink('https://example.com');
    
    expect($result->isValid())->toBe(true); // Less specific assertion
});
```

### Property and Variable Typing

```php
// ✅ Correct: Explicit type declarations in test setup
beforeEach(function (): void {
    $this->service = app(LinkValidationInterface::class);
    /** @var array<string> */
    $this->testUrls = [
        'https://example.com',
        'internal-link.md',
        '#anchor-link'
    ];
    $this->config = ValidationConfig::create([
        'scopes' => [ValidationScope::ALL],
        'timeout' => 30,
    ]);
});

// ❌ Incorrect: Implicit typing without declarations
beforeEach(function () {
    $this->service = app(LinkValidationInterface::class);
    $this->testUrls = ['https://example.com', 'internal-link.md']; // Mixed array types
});
```

### Architecture Test Compliance

**Reflection-Based Testing**:

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

## Test Infrastructure Requirements

### Test Organization Structure

```
tests/
├── Architecture/           # Architecture constraint tests
│   ├── ServicesTest.php   # Service layer architecture tests
│   └── ValueObjectsTest.php # ValueObject architecture tests
├── E2E/                   # End-to-end integration tests
│   ├── CompleteUserScenarioTest.php
│   ├── EdgeCaseE2ETest.php
│   └── OptimizedPerformanceAndLoadTest.php
├── Feature/               # Feature-level tests
│   └── Commands/
│       └── ValidateCommandTest.php
├── Integration/           # Integration tests
│   └── Services/
│       └── LinkValidationIntegrationTest.php
├── Unit/                  # Unit tests
│   ├── Commands/
│   ├── Services/
│   ├── ValueObjects/
│   └── Enums/
└── Support/               # Test support classes
    ├── DataBuilders/
    ├── Performance/
    └── StaticAnalysis/
```

### Base Test Classes

```php
<?php

declare(strict_types=1);

namespace Tests\Support;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    use CreatesApplication;

    /**
     * Set up the test environment.
     */
    protected function setUp(): void
    {
        parent::setUp();
        
        // Configure test environment for PHPStan Level 10 compliance
        $this->withoutVite();
        $this->withoutMix();
    }

    /**
     * Create a mock with proper type safety.
     *
     * @template T
     * @param class-string<T> $class
     * @return MockInterface&T
     */
    protected function createTypedMock(string $class): MockInterface
    {
        return Mockery::mock($class);
    }
}
```

## E2E Testing Methodologies

### Complete User Scenario Testing

**File**: [`tests/E2E/CompleteUserScenarioTest.php`](../../tests/E2E/CompleteUserScenarioTest.php)

```php
<?php

declare(strict_types=1);

use App\Commands\ValidateCommand;
use App\Enums\ValidationScope;
use App\Enums\OutputFormat;

it('executes complete validation workflow successfully', function (): void {
    // Arrange: Set up test files and configuration
    $testFile = 'tests/Fixtures/sample-documentation.md';
    $outputFile = 'tests/temp/validation-report.json';
    
    // Act: Execute the complete validation command
    $this->artisan('validate', [
        'paths' => [$testFile],
        '--scope' => ValidationScope::ALL->value,
        '--format' => OutputFormat::JSON->value,
        '--output' => $outputFile,
        '--concurrent' => 5,
        '--timeout' => 30,
    ])
    ->expectsOutput('🔍 Validating links in: ' . $testFile)
    ->assertExitCode(0);
    
    // Assert: Verify output file was created and contains expected structure
    expect(file_exists($outputFile))->toBeTrue();
    
    $reportContent = file_get_contents($outputFile);
    expect($reportContent)->not->toBeEmpty();
    
    $reportData = json_decode($reportContent, true);
    expect($reportData)->toBeArray()
        ->and($reportData)->toHaveKeys(['summary', 'results', 'metadata']);
    
    // Cleanup
    if (file_exists($outputFile)) {
        unlink($outputFile);
    }
});
```

### Edge Case E2E Testing

```php
it('handles malformed URLs gracefully', function (): void {
    $testContent = <<<'MD'
# Test Document

[Invalid URL](not-a-valid-url)
[Malformed](http://[invalid-host])
[Empty]()
MD;

    $testFile = 'tests/temp/malformed-urls.md';
    file_put_contents($testFile, $testContent);
    
    $this->artisan('validate', [
        'paths' => [$testFile],
        '--scope' => ValidationScope::ALL->value,
    ])
    ->assertExitCode(1); // Should exit with error code due to broken links
    
    // Cleanup
    if (file_exists($testFile)) {
        unlink($testFile);
    }
});
```

### Performance and Load Testing

```php
it('handles large files efficiently', function (): void {
    // Generate large test file with many links
    $linkCount = 1000;
    $testContent = "# Large Test Document\n\n";
    
    for ($i = 1; $i <= $linkCount; $i++) {
        $testContent .= "[Link {$i}](https://example.com/page-{$i})\n";
    }
    
    $testFile = 'tests/temp/large-document.md';
    file_put_contents($testFile, $testContent);
    
    $startTime = microtime(true);
    
    $this->artisan('validate', [
        'paths' => [$testFile],
        '--scope' => ValidationScope::INTERNAL->value, // Skip external validation for speed
        '--concurrent' => 10,
    ]);
    
    $executionTime = microtime(true) - $startTime;
    
    // Assert reasonable performance (adjust threshold as needed)
    expect($executionTime)->toBeLessThan(30.0);
    
    // Cleanup
    if (file_exists($testFile)) {
        unlink($testFile);
    }
})->group('performance');
```

## Unit Testing Standards

### Service Layer Testing

```php
<?php

declare(strict_types=1);

use App\Services\LinkValidationService;
use App\Services\Contracts\SecurityValidationInterface;
use App\Services\ValueObjects\ValidationConfig;
use App\Enums\ValidationScope;
use App\Enums\LinkStatus;

describe('LinkValidationService', function (): void {
    beforeEach(function (): void {
        $this->securityService = $this->createTypedMock(SecurityValidationInterface::class);
        $this->service = new LinkValidationService($this->securityService);
        $this->config = ValidationConfig::create(['scopes' => [ValidationScope::ALL]]);
    });

    it('validates external URLs correctly', function (): void {
        $url = 'https://example.com';
        
        $this->securityService
            ->shouldReceive('validateUrl')
            ->once()
            ->with($url)
            ->andReturn(true);
        
        $result = $this->service->validateLink($url, $this->config);
        
        expect($result)->toBeInstanceOf(ValidationResult::class)
            ->and($result->getUrl())->toBe($url)
            ->and($result->getScope())->toBe(ValidationScope::EXTERNAL);
    });

    it('handles security violations properly', function (): void {
        $url = 'https://malicious-site.com';
        
        $this->securityService
            ->shouldReceive('validateUrl')
            ->once()
            ->with($url)
            ->andReturn(false);
        
        $result = $this->service->validateLink($url, $this->config);
        
        expect($result->getStatus())->toBe(LinkStatus::SECURITY_VIOLATION)
            ->and($result->getError())->toContain('security validation');
    });
});
```

### ValueObject Testing

```php
describe('ValidationResult', function (): void {
    it('creates successful validation result', function (): void {
        $result = ValidationResult::success(
            url: 'https://example.com',
            scope: ValidationScope::EXTERNAL,
            httpStatusCode: 200,
            responseTime: 0.5
        );
        
        expect($result->isValid())->toBeTrue()
            ->and($result->getUrl())->toBe('https://example.com')
            ->and($result->getHttpStatusCode())->toBe(200)
            ->and($result->getResponseTime())->toBe(0.5);
    });

    it('creates failure validation result', function (): void {
        $result = ValidationResult::failure(
            url: 'https://broken-link.com',
            scope: ValidationScope::EXTERNAL,
            status: LinkStatus::NOT_FOUND,
            error: 'HTTP 404'
        );
        
        expect($result->isBroken())->toBeTrue()
            ->and($result->getStatus())->toBe(LinkStatus::NOT_FOUND)
            ->and($result->getError())->toBe('HTTP 404');
    });

    it('converts to array correctly', function (): void {
        $result = ValidationResult::success(
            url: 'https://example.com',
            scope: ValidationScope::EXTERNAL
        );
        
        $array = $result->toArray();
        
        expect($array)->toBeArray()
            ->and($array)->toHaveKeys([
                'url', 'status', 'scope', 'is_valid', 'is_broken',
                'error', 'http_status_code', 'response_time'
            ])
            ->and($array['url'])->toBe('https://example.com')
            ->and($array['is_valid'])->toBeTrue();
    });
});
```

## Mock Lifecycle Management

### Proper Mock Setup and Teardown

```php
describe('Service with complex dependencies', function (): void {
    beforeEach(function (): void {
        // Create typed mocks with proper interfaces
        $this->securityService = $this->createTypedMock(SecurityValidationInterface::class);
        $this->reportingService = $this->createTypedMock(ReportingInterface::class);
        
        // Set up default mock behaviors
        $this->securityService
            ->shouldReceive('validateUrl')
            ->andReturn(true)
            ->byDefault();
            
        $this->securityService
            ->shouldReceive('validatePath')
            ->andReturn(true)
            ->byDefault();
    });

    afterEach(function (): void {
        // Verify all mock expectations were met
        Mockery::close();
    });

    it('uses mocks correctly in test', function (): void {
        // Override default behavior for specific test
        $this->securityService
            ->shouldReceive('validateUrl')
            ->once()
            ->with('https://specific-url.com')
            ->andReturn(false);
        
        $service = new LinkValidationService($this->securityService);
        $config = ValidationConfig::create(['scopes' => [ValidationScope::EXTERNAL]]);
        
        $result = $service->validateLink('https://specific-url.com', $config);
        
        expect($result->getStatus())->toBe(LinkStatus::SECURITY_VIOLATION);
    });
});
```

### Test Isolation Techniques

```php
// ✅ Correct: Proper test isolation with database transactions
use Illuminate\Foundation\Testing\DatabaseTransactions;

class DatabaseDependentTest extends TestCase
{
    use DatabaseTransactions;

    it('creates and validates data correctly', function (): void {
        // Test data is automatically rolled back after test
        $model = TestModel::create(['name' => 'Test']);
        
        expect($model->exists)->toBeTrue()
            ->and($model->name)->toBe('Test');
    });
}
```

## Test Data Management

### Factory Pattern for Test Data

```php
/**
 * Create test validation data with proper typing.
 *
 * @return array<string, mixed>
 */
function createTestValidationData(): array
{
    return [
        'url' => 'https://example.com',
        'expected_status' => LinkStatus::VALID,
        'context' => ['source' => 'test'],
        'metadata' => [
            'test_run' => true,
            'created_at' => now()->toISOString(),
        ],
    ];
}

/**
 * Create test configuration with defaults.
 *
 * @param array<string, mixed> $overrides
 */
function createTestConfig(array $overrides = []): ValidationConfig
{
    $defaults = [
        'scopes' => [ValidationScope::ALL],
        'timeout' => 30,
        'concurrent_requests' => 5,
    ];
    
    return ValidationConfig::create(array_merge($defaults, $overrides));
}
```

### Fixture Management

```php
// tests/Support/Fixtures/FixtureManager.php
<?php

declare(strict_types=1);

namespace Tests\Support\Fixtures;

final class FixtureManager
{
    private const FIXTURES_PATH = __DIR__ . '/../../Fixtures';

    /**
     * Get fixture file content.
     */
    public static function getFixture(string $filename): string
    {
        $path = self::FIXTURES_PATH . '/' . $filename;
        
        if (!file_exists($path)) {
            throw new InvalidArgumentException("Fixture file not found: {$filename}");
        }
        
        $content = file_get_contents($path);
        if ($content === false) {
            throw new RuntimeException("Could not read fixture file: {$filename}");
        }
        
        return $content;
    }

    /**
     * Create temporary test file with content.
     */
    public static function createTempFile(string $content, string $extension = 'md'): string
    {
        $tempFile = tempnam(sys_get_temp_dir(), 'test_') . '.' . $extension;
        file_put_contents($tempFile, $content);
        
        return $tempFile;
    }
}
```

## Laravel Zero Testing Patterns

### Command Testing

```php
describe('ValidateCommand', function (): void {
    it('executes with default parameters', function (): void {
        $this->artisan('validate', ['paths' => ['tests/Fixtures/sample.md']])
            ->expectsOutput('🔍 Validating links in: tests/Fixtures/sample.md')
            ->assertExitCode(0);
    });

    it('handles interactive mode', function (): void {
        $this->artisan('validate', ['--interactive' => true])
            ->expectsQuestion('Enter path to validate', 'tests/Fixtures/sample.md')
            ->expectsQuestion('Add another path?', false)
            ->expectsChoice('What types of links should be validated?', 
                [ValidationScope::INTERNAL->value], 
                [ValidationScope::INTERNAL->value, ValidationScope::EXTERNAL->value])
            ->assertExitCode(0);
    });
});
```

### Service Provider Testing

```php
it('registers services correctly', function (): void {
    expect(app(LinkValidationInterface::class))
        ->toBeInstanceOf(LinkValidationService::class);
        
    expect(app(ReportingInterface::class))
        ->toBeInstanceOf(ReportingService::class);
        
    expect(app(SecurityValidationInterface::class))
        ->toBeInstanceOf(SecurityValidationService::class);
});
```

### Configuration Testing

```php
it('loads configuration correctly', function (): void {
    $config = config('validate-links');
    
    expect($config)->toBeArray()
        ->and($config)->toHaveKeys([
            'default_scope',
            'timeout',
            'concurrent_requests',
            'user_agent'
        ]);
});
```

## Performance Testing

### Benchmarking Standards

```php
it('validates large number of links within time limit', function (): void {
    $urls = [];
    for ($i = 0; $i < 100; $i++) {
        $urls[] = "https://example.com/page-{$i}";
    }
    
    $service = app(LinkValidationInterface::class);
    $config = ValidationConfig::create([
        'scopes' => [ValidationScope::EXTERNAL],
        'concurrent_requests' => 10,
    ]);
    
    $startTime = microtime(true);
    $results = $service->validateLinks($urls, $config);
    $executionTime = microtime(true) - $startTime;
    
    expect($results->count())->toBe(100)
        ->and($executionTime)->toBeLessThan(30.0); // 30 second limit
})->group('performance');
```

### Memory Usage Testing

```php
it('maintains reasonable memory usage', function (): void {
    $initialMemory = memory_get_usage(true);
    
    // Process large amount of data
    $service = app(LinkValidationInterface::class);
    $config = ValidationConfig::create(['scopes' => [ValidationScope::ALL]]);
    
    for ($i = 0; $i < 1000; $i++) {
        $service->validateLink("https://example.com/page-{$i}", $config);
    }
    
    $finalMemory = memory_get_usage(true);
    $memoryIncrease = $finalMemory - $initialMemory;
    
    // Should not increase memory by more than 50MB
    expect($memoryIncrease)->toBeLessThan(50 * 1024 * 1024);
})->group('performance');
```

## CI/CD Integration

### GitHub Actions Configuration

```yaml
# .github/workflows/tests.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        php-version: [8.4]
        
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ matrix.php-version }}
          extensions: mbstring, xml, ctype, iconv, intl
          coverage: xdebug
          
      - name: Install dependencies
        run: composer install --prefer-dist --no-progress
        
      - name: Run PHPStan on tests
        run: ./vendor/bin/phpstan analyse tests --level=10
        
      - name: Run Unit Tests
        run: ./vendor/bin/pest --testsuite=Unit --coverage
        
      - name: Run Feature Tests
        run: ./vendor/bin/pest --testsuite=Feature
        
      - name: Run Integration Tests
        run: ./vendor/bin/pest --testsuite=Integration
        
      - name: Run E2E Tests
        run: ./vendor/bin/pest --testsuite=E2E
        
      - name: Run Architecture Tests
        run: ./vendor/bin/pest --testsuite=Architecture
        
      - name: Upload Coverage Reports
        uses: codecov/codecov-action@v3
        with:
          file: ./reports/coverage/clover.xml
```

### Quality Gates

```bash
#!/bin/bash
# scripts/run-quality-checks.sh

echo "Running comprehensive quality checks..."

# 1. Static analysis on tests
echo "🔍 Running PHPStan on tests..."
./vendor/bin/phpstan analyse tests --level=10 --no-progress
if [ $? -ne 0 ]; then
    echo "❌ PHPStan tests failed"
    exit 1
fi

# 2. Run all test suites
echo "🧪 Running test suites..."
./vendor/bin/pest --coverage --min=90
if [ $? -ne 0 ]; then
    echo "❌ Tests failed or coverage below 90%"
    exit 1
fi

# 3. Architecture tests
echo "🏗️ Running architecture tests..."
./vendor/bin/pest --testsuite=Architecture
if [ $? -ne 0 ]; then
    echo "❌ Architecture tests failed"
    exit 1
fi

echo "✅ All quality checks passed"
```

## Best Practices

### 1. Type Safety in Tests

- Use explicit return types for all test functions
- Create typed mocks using proper interfaces
- Validate type safety with PHPStan Level 10 where possible

### 2. Test Organization

- Group related tests using `describe()` blocks
- Use meaningful test names that describe the behavior
- Organize tests by feature/component, not by test type

### 3. Mock Management

- Create mocks with proper type annotations
- Set up default behaviors in `beforeEach()`
- Always call `Mockery::close()` in `afterEach()`

### 4. Performance Considerations

- Use `@group('performance')` for performance-sensitive tests
- Set reasonable time and memory limits
- Test with realistic data volumes

### 5. Maintenance

- Keep test fixtures up to date
- Update test configurations when application changes
- Maintain test documentation and examples

---

## Navigation

**← Previous:** [Type Safety Standards](type-safety-standards.md) | **Next →** [Laravel Zero Patterns](laravel-zero-patterns.md)