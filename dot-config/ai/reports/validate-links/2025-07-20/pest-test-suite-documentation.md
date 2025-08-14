# Complete Pest Test Suite Documentation

**Date:** July 21, 2025  
**Project:** Laravel Zero Implementation - Comprehensive Testing Guide  
**Compliance:** `.ai/guidelines/060-testing-standards.md` and testing best practices

## Table of Contents

1. [Test Suite Overview](#test-suite-overview)
2. [Test Structure and Organization](#test-structure-and-organization)
3. [Unit Tests with Full Examples](#unit-tests-with-full-examples)
4. [Feature Tests with Full Examples](#feature-tests-with-full-examples)
5. [Integration Tests with Full Examples](#integration-tests-with-full-examples)
6. [Test Configuration and Setup](#test-configuration-and-setup)
7. [Testing Best Practices](#testing-best-practices)
8. [Continuous Integration Integration](#continuous-integration-integration)

## Test Suite Overview

The Pest test suite provides comprehensive coverage for the Laravel Zero validate-links application, following the testing standards defined in `.ai/guidelines/060-testing-standards.md`.

### Test Categories

- **Unit Tests:** Test individual components in isolation
- **Feature Tests:** Test complete features and user workflows
- **Integration Tests:** Test interactions between components
- **Architecture Tests:** Ensure architectural constraints
- **Performance Tests:** Validate performance requirements

### Coverage Requirements

- **Minimum Code Coverage:** 80%
- **Type Coverage:** 95%
- **Mutation Testing Score:** 80% MSI (Mutation Score Indicator)

## Test Structure and Organization

```
tests/
├── Pest.php                     # Pest configuration
├── TestCase.php                 # Base test case
├── Unit/                        # Unit tests
│   ├── Services/
│   │   ├── LinkValidationServiceTest.php
│   │   ├── SecurityValidationServiceTest.php
│   │   ├── GitHubAnchorServiceTest.php
│   │   ├── StatisticsServiceTest.php
│   │   └── ReportingServiceTest.php
│   ├── ValueObjects/
│   │   ├── ValidationConfigTest.php
│   │   └── ValidationResultTest.php
│   └── Formatters/
│       ├── ConsoleFormatterTest.php
│       ├── JsonFormatterTest.php
│       ├── MarkdownFormatterTest.php
│       └── HtmlFormatterTest.php
├── Feature/                     # Feature tests
│   ├── Commands/
│   │   └── ValidateCommandTest.php
│   ├── Validation/
│   │   ├── LinkValidationWorkflowTest.php
│   │   ├── ExternalLinkValidationTest.php
│   │   └── AnchorValidationTest.php
│   └── Reporting/
│       ├── ReportGenerationTest.php
│       └── OutputFormattingTest.php
├── Integration/                 # Integration tests
│   ├── Services/
│   │   └── ServiceIntegrationTest.php
│   └── Workflows/
│       └── EndToEndValidationTest.php
├── Architecture/                # Architecture tests
│   └── ArchitectureTest.php
├── Performance/                 # Performance tests
│   └── ValidationPerformanceTest.php
├── Fixtures/                    # Test data
│   ├── markdown/
│   ├── html/
│   └── config/
└── Helpers/                     # Test helpers
    ├── TestDataFactory.php
    └── AssertionHelpers.php
```

## Unit Tests with Full Examples

### 1. Service Unit Tests

#### LinkValidationServiceTest.php

```php
<?php

declare(strict_types=1);

use App\Services\Contracts\LinkValidationInterface;
use App\Services\Contracts\SecurityValidationInterface;
use App\Services\Contracts\GitHubAnchorInterface;
use App\Services\Contracts\StatisticsInterface;
use App\Services\Implementations\LinkValidationService;
use App\Services\ValueObjects\ValidationConfig;
use App\Services\ValueObjects\ValidationResult;

describe('LinkValidationService', function () {
    beforeEach(function () {
        $this->securityValidator = Mockery::mock(SecurityValidationInterface::class);
        $this->anchorService = Mockery::mock(GitHubAnchorInterface::class);
        $this->statistics = Mockery::mock(StatisticsInterface::class);
        
        $this->service = new LinkValidationService(
            $this->securityValidator,
            $this->anchorService,
            $this->statistics
        );
    });

    describe('validateFiles', function () {
        it('validates multiple files successfully', function () {
            // Arrange
            $files = ['test1.md', 'test2.md'];
            $config = new ValidationConfig(scope: ['internal']);
            
            $this->securityValidator
                ->shouldReceive('isFileAllowed')
                ->twice()
                ->andReturn(true);
                
            $this->statistics
                ->shouldReceive('reset')
                ->once();
                
            $this->statistics
                ->shouldReceive('incrementFilesProcessed')
                ->twice();
                
            $this->statistics
                ->shouldReceive('getStatistics')
                ->once()
                ->andReturn([
                    'files_processed' => 2,
                    'total_links' => 5,
                    'broken_links' => 0
                ]);

            // Act
            $result = $this->service->validateFiles($files, $config);

            // Assert
            expect($result)->toBeInstanceOf(ValidationResult::class);
            expect($result->getTotalFiles())->toBe(2);
            expect($result->getBrokenCount())->toBe(0);
        });

        it('handles security validation failures', function () {
            // Arrange
            $files = ['unsafe-file.md'];
            $config = new ValidationConfig();
            
            $this->securityValidator
                ->shouldReceive('isFileAllowed')
                ->once()
                ->andReturn(false);

            // Act & Assert
            expect(fn() => $this->service->validateFiles($files, $config))
                ->toThrow(SecurityException::class, 'File not allowed for validation');
        });
    });

    describe('validateFile', function () {
        it('validates internal links correctly', function () {
            // Arrange
            $file = 'test.md';
            $config = new ValidationConfig(scope: ['internal']);
            $content = '[Link](./other-file.md)';
            
            $this->securityValidator
                ->shouldReceive('isFileAllowed')
                ->with($file)
                ->andReturn(true);

            // Mock file reading
            File::shouldReceive('get')
                ->with($file)
                ->andReturn($content);

            // Act
            $brokenLinks = $this->service->validateFile($file, $config);

            // Assert
            expect($brokenLinks)->toBeArray();
            expect($brokenLinks)->toBeEmpty();
        });

        it('detects broken internal links', function () {
            // Arrange
            $file = 'test.md';
            $config = new ValidationConfig(scope: ['internal']);
            $content = '[Broken Link](./non-existent.md)';
            
            $this->securityValidator
                ->shouldReceive('isFileAllowed')
                ->andReturn(true);

            File::shouldReceive('get')
                ->andReturn($content);
                
            File::shouldReceive('exists')
                ->with('./non-existent.md')
                ->andReturn(false);

            // Act
            $brokenLinks = $this->service->validateFile($file, $config);

            // Assert
            expect($brokenLinks)->toHaveCount(1);
            expect($brokenLinks[0])->toMatchArray([
                'link' => './non-existent.md',
                'type' => 'internal',
                'reason' => 'File does not exist'
            ]);
        });
    });

    describe('extractLinks', function () {
        it('extracts markdown links correctly', function () {
            // Arrange
            $content = '
                [Internal Link](./file.md)
                [External Link](https://example.com)
                [Anchor Link](#heading)
                [Email](mailto:test@example.com)
            ';

            // Act
            $links = $this->service->extractLinks($content, 'markdown');

            // Assert
            expect($links)->toHaveCount(4);
            expect($links)->toContain('./file.md');
            expect($links)->toContain('https://example.com');
            expect($links)->toContain('#heading');
            expect($links)->toContain('mailto:test@example.com');
        });

        it('handles empty content gracefully', function () {
            // Act
            $links = $this->service->extractLinks('', 'markdown');

            // Assert
            expect($links)->toBeEmpty();
        });
    });

    describe('validateLink', function () {
        it('validates internal file links', function () {
            // Arrange
            $link = './existing-file.md';
            $sourceFile = 'test.md';
            $config = new ValidationConfig();

            File::shouldReceive('exists')
                ->with('./existing-file.md')
                ->andReturn(true);

            // Act
            $isValid = $this->service->validateLink($link, $sourceFile, $config);

            // Assert
            expect($isValid)->toBeTrue();
        });

        it('validates anchor links', function () {
            // Arrange
            $link = '#valid-heading';
            $sourceFile = 'test.md';
            $config = new ValidationConfig();
            $headings = ['valid-heading', 'another-heading'];

            File::shouldReceive('get')
                ->with($sourceFile)
                ->andReturn('# Valid Heading\n## Another Heading');

            $this->anchorService
                ->shouldReceive('extractHeadings')
                ->andReturn($headings);

            $this->anchorService
                ->shouldReceive('validateAnchor')
                ->with('valid-heading', $headings)
                ->andReturn(true);

            // Act
            $isValid = $this->service->validateLink($link, $sourceFile, $config);

            // Assert
            expect($isValid)->toBeTrue();
        });
    });
})->group('unit', 'services');
```

#### ValidationConfigTest.php

```php
<?php

declare(strict_types=1);

use App\Services\ValueObjects\ValidationConfig;

describe('ValidationConfig', function () {
    describe('construction', function () {
        it('creates with default values', function () {
            // Act
            $config = new ValidationConfig();

            // Assert
            expect($config->paths)->toBeEmpty();
            expect($config->scope)->toBe(['internal', 'anchor']);
            expect($config->maxDepth)->toBe(0);
            expect($config->timeout)->toBe(30);
            expect($config->format)->toBe('console');
        });

        it('creates with custom values', function () {
            // Act
            $config = new ValidationConfig(
                paths: ['./docs'],
                scope: ['external'],
                maxDepth: 3,
                timeout: 60,
                format: 'json'
            );

            // Assert
            expect($config->paths)->toBe(['./docs']);
            expect($config->scope)->toBe(['external']);
            expect($config->maxDepth)->toBe(3);
            expect($config->timeout)->toBe(60);
            expect($config->format)->toBe('json');
        });
    });

    describe('fromCommandOptions', function () {
        it('creates config from command options', function () {
            // Arrange
            $options = [
                'scope' => ['internal', 'external'],
                'max-depth' => 2,
                'timeout' => 45,
                'format' => 'markdown',
                'check-external' => true,
                'max-broken' => 100
            ];
            $arguments = [
                'paths' => ['./src', './docs']
            ];

            // Act
            $config = ValidationConfig::fromCommandOptions($options, $arguments);

            // Assert
            expect($config->paths)->toBe(['./src', './docs']);
            expect($config->scope)->toBe(['internal', 'external']);
            expect($config->maxDepth)->toBe(2);
            expect($config->timeout)->toBe(45);
            expect($config->format)->toBe('markdown');
            expect($config->checkExternal)->toBeTrue();
            expect($config->maxBroken)->toBe(100);
        });

        it('uses defaults for missing options', function () {
            // Act
            $config = ValidationConfig::fromCommandOptions([]);

            // Assert
            expect($config->scope)->toBe(['internal', 'anchor']);
            expect($config->maxDepth)->toBe(0);
            expect($config->timeout)->toBe(30);
            expect($config->checkExternal)->toBeFalse();
        });
    });

    describe('withDefaults', function () {
        it('merges with config file defaults', function () {
            // Arrange
            Config::shouldReceive('get')
                ->with('validate-links.defaults.max_depth')
                ->andReturn(5);
            Config::shouldReceive('get')
                ->with('validate-links.defaults.timeout')
                ->andReturn(120);

            // Act
            $config = ValidationConfig::withDefaults([
                'format' => 'html'
            ]);

            // Assert
            expect($config->maxDepth)->toBe(5);
            expect($config->timeout)->toBe(120);
            expect($config->format)->toBe('html');
        });
    });
})->group('unit', 'value-objects');
```

## Feature Tests with Full Examples

### ValidateCommandTest.php

```php
<?php

declare(strict_types=1);

use App\Commands\ValidateCommand;
use App\Services\Contracts\LinkValidationInterface;
use App\Services\Contracts\ReportingInterface;
use App\Services\ValueObjects\ValidationConfig;
use App\Services\ValueObjects\ValidationResult;

describe('ValidateCommand', function () {
    beforeEach(function () {
        $this->validator = Mockery::mock(LinkValidationInterface::class);
        $this->reporter = Mockery::mock(ReportingInterface::class);
        
        $this->app->instance(LinkValidationInterface::class, $this->validator);
        $this->app->instance(ReportingInterface::class, $this->reporter);
    });

    describe('basic validation', function () {
        it('validates files successfully', function () {
            // Arrange
            $testFiles = [
                'test1.md' => '[Link](./test2.md)',
                'test2.md' => '# Test Heading'
            ];
            
            foreach ($testFiles as $file => $content) {
                File::put($file, $content);
            }

            $result = new ValidationResult(
                statistics: ['files_processed' => 2, 'total_links' => 1],
                brokenLinks: [],
                processedFiles: array_keys($testFiles),
                executionTime: 0.5,
                exitCode: 0
            );

            $this->validator
                ->shouldReceive('validateFiles')
                ->once()
                ->andReturn($result);

            $this->reporter
                ->shouldReceive('generateReport')
                ->once()
                ->andReturn(0);

            // Act
            $exitCode = $this->artisan('validate', [
                'paths' => array_keys($testFiles)
            ]);

            // Assert
            expect($exitCode)->toBe(0);
            
            // Cleanup
            foreach ($testFiles as $file => $content) {
                File::delete($file);
            }
        });

        it('handles broken links correctly', function () {
            // Arrange
            $testFile = 'broken-links.md';
            $content = '[Broken](./non-existent.md)';
            File::put($testFile, $content);

            $result = new ValidationResult(
                statistics: ['files_processed' => 1, 'total_links' => 1],
                brokenLinks: [
                    [
                        'link' => './non-existent.md',
                        'file' => $testFile,
                        'type' => 'internal',
                        'reason' => 'File does not exist'
                    ]
                ],
                processedFiles: [$testFile],
                executionTime: 0.3,
                exitCode: 1
            );

            $this->validator
                ->shouldReceive('validateFiles')
                ->andReturn($result);

            $this->reporter
                ->shouldReceive('generateReport')
                ->andReturn(1);

            // Act
            $exitCode = $this->artisan('validate', ['paths' => [$testFile]]);

            // Assert
            expect($exitCode)->toBe(1);
            
            // Cleanup
            File::delete($testFile);
        });
    });

    describe('command options', function () {
        it('handles scope option correctly', function () {
            // Arrange
            $testFile = 'scope-test.md';
            File::put($testFile, '[External](https://example.com)');

            $this->validator
                ->shouldReceive('validateFiles')
                ->with(
                    [$testFile],
                    Mockery::on(function (ValidationConfig $config) {
                        return $config->scope === ['external'];
                    })
                )
                ->andReturn(new ValidationResult(
                    statistics: [],
                    brokenLinks: [],
                    processedFiles: [],
                    executionTime: 0,
                    exitCode: 0
                ));

            $this->reporter
                ->shouldReceive('generateReport')
                ->andReturn(0);

            // Act
            $exitCode = $this->artisan('validate', [
                'paths' => [$testFile],
                '--scope' => ['external']
            ]);

            // Assert
            expect($exitCode)->toBe(0);
            
            // Cleanup
            File::delete($testFile);
        });

        it('handles format option correctly', function () {
            // Arrange
            $testFile = 'format-test.md';
            File::put($testFile, '# Test');

            $this->validator
                ->shouldReceive('validateFiles')
                ->andReturn(new ValidationResult(
                    statistics: [],
                    brokenLinks: [],
                    processedFiles: [],
                    executionTime: 0,
                    exitCode: 0
                ));

            $this->reporter
                ->shouldReceive('generateReport')
                ->with(
                    Mockery::any(),
                    Mockery::on(function (ValidationConfig $config) {
                        return $config->format === 'json';
                    }),
                    Mockery::any()
                )
                ->andReturn(0);

            // Act
            $exitCode = $this->artisan('validate', [
                'paths' => [$testFile],
                '--format' => 'json'
            ]);

            // Assert
            expect($exitCode)->toBe(0);
            
            // Cleanup
            File::delete($testFile);
        });
    });

    describe('interactive mode', function () {
        it('prompts for configuration in interactive mode', function () {
            // This would require mocking Laravel Prompts
            // Implementation depends on how prompts are structured
            $this->markTestSkipped('Interactive testing requires prompt mocking');
        });
    });
})->group('feature', 'commands');
```

### LinkValidationWorkflowTest.php

```php
<?php

declare(strict_types=1);

describe('Link Validation Workflow', function () {
    beforeEach(function () {
        $this->testDir = 'test-validation-workflow';
        File::makeDirectory($this->testDir);
    });

    afterEach(function () {
        File::deleteDirectory($this->testDir);
    });

    describe('internal link validation', function () {
        it('validates internal file links correctly', function () {
            // Arrange
            $files = [
                'index.md' => '
                    # Main Document
                    [Go to Section A](./section-a.md)
                    [Go to Section B](./section-b.md)
                ',
                'section-a.md' => '
                    # Section A
                    [Back to Index](./index.md)
                ',
                'section-b.md' => '
                    # Section B
                    [Back to Index](./index.md)
                    [Go to Section A](./section-a.md)
                '
            ];

            foreach ($files as $filename => $content) {
                File::put("{$this->testDir}/{$filename}", $content);
            }

            // Act
            $exitCode = $this->artisan('validate', [
                'paths' => [$this->testDir],
                '--scope' => ['internal']
            ]);

            // Assert
            expect($exitCode)->toBe(0);
        });

        it('detects broken internal links', function () {
            // Arrange
            $files = [
                'index.md' => '
                    # Main Document
                    [Broken Link](./non-existent.md)
                    [Valid Link](./existing.md)
                ',
                'existing.md' => '# Existing File'
            ];

            foreach ($files as $filename => $content) {
                File::put("{$this->testDir}/{$filename}", $content);
            }

            // Act
            $exitCode = $this->artisan('validate', [
                'paths' => [$this->testDir],
                '--scope' => ['internal']
            ]);

            // Assert
            expect($exitCode)->toBe(1);
        });
    });

    describe('anchor link validation', function () {
        it('validates anchor links correctly', function () {
            // Arrange
            $content = '
                # Main Heading
                
                [Link to Section](#section-heading)
                [Link to Subsection](#subsection-heading)
                
                ## Section Heading
                
                Content here.
                
                ### Subsection Heading
                
                More content.
            ';

            File::put("{$this->testDir}/anchors.md", $content);

            // Act
            $exitCode = $this->artisan('validate', [
                'paths' => ["{$this->testDir}/anchors.md"],
                '--scope' => ['anchor']
            ]);

            // Assert
            expect($exitCode)->toBe(0);
        });

        it('detects broken anchor links', function () {
            // Arrange
            $content = '
                # Main Heading
                
                [Valid Link](#main-heading)
                [Broken Link](#non-existent-heading)
                
                ## Another Heading
                
                Content here.
            ';

            File::put("{$this->testDir}/broken-anchors.md", $content);

            // Act
            $exitCode = $this->artisan('validate', [
                'paths' => ["{$this->testDir}/broken-anchors.md"],
                '--scope' => ['anchor']
            ]);

            // Assert
            expect($exitCode)->toBe(1);
        });
    });

    describe('mixed validation scenarios', function () {
        it('handles complex document structures', function () {
            // Arrange
            $files = [
                'README.md' => '
                    # Project Documentation
                    
                    ## Table of Contents
                    - [Installation](#installation)
                    - [Usage Guide](./docs/usage.md)
                    - [API Reference](./docs/api/index.md)
                    
                    ## Installation
                    
                    See [detailed installation guide](./docs/installation.md).
                ',
                'docs/usage.md' => '
                    # Usage Guide
                    
                    [Back to README](../README.md)
                    [API Reference](./api/index.md)
                ',
                'docs/installation.md' => '
                    # Installation Guide
                    
                    [Back to README](../README.md)
                    [Usage Guide](./usage.md)
                ',
                'docs/api/index.md' => '
                    # API Reference
                    
                    [Back to README](../../README.md)
                    [Usage Guide](../usage.md)
                '
            ];

            foreach ($files as $filename => $content) {
                $dir = dirname("{$this->testDir}/{$filename}");
                if (!File::exists($dir)) {
                    File::makeDirectory($dir, 0755, true);
                }
                File::put("{$this->testDir}/{$filename}", $content);
            }

            // Act
            $exitCode = $this->artisan('validate', [
                'paths' => [$this->testDir],
                '--scope' => ['internal', 'anchor']
            ]);

            // Assert
            expect($exitCode)->toBe(0);
        });
    });
})->group('feature', 'validation');
```

## Integration Tests with Full Examples

### ServiceIntegrationTest.php

```php
<?php

declare(strict_types=1);

use App\Services\Contracts\LinkValidationInterface;
use App\Services\Contracts\ReportingInterface;
use App\Services\ValueObjects\ValidationConfig;

describe('Service Integration', function () {
    beforeEach(function () {
        $this->testDir = 'integration-test';
        File::makeDirectory($this->testDir);
    });

    afterEach(function () {
        File::deleteDirectory($this->testDir);
    });

    describe('end-to-end validation workflow', function () {
        it('integrates all services correctly', function () {
            // Arrange
            $files = [
                'main.md' => '
                    # Main Document
                    [Internal Link](./sub.md)
                    [Anchor Link](#heading)
                    [External Link](https://httpbin.org/status/200)
                    
                    ## Heading
                    Content here.
                ',
                'sub.md' => '
                    # Sub Document
                    [Back to Main](./main.md)
                '
            ];

            foreach ($files as $filename => $content) {
                File::put("{$this->testDir}/{$filename}", $content);
            }

            $validator = app(LinkValidationInterface::class);
            $reporter = app(ReportingInterface::class);

            $config = new ValidationConfig(
                paths: ["{$this->testDir}/main.md"],
                scope: ['internal', 'anchor', 'external'],
                checkExternal: true,
                format: 'json'
            );

            // Act
            $result = $validator->validateFiles(["{$this->testDir}/main.md"], $config);

            // Assert
            expect($result->getTotalFiles())->toBe(1);
            expect($result->getTotalLinks())->toBeGreaterThan(0);
            expect($result->getBrokenCount())->toBe(0);
            expect($result->getSuccessRate())->toBe(100.0);
        });

        it('handles service failures gracefully', function () {
            // Arrange
            $invalidFile = "{$this->testDir}/invalid.md";
            File::put($invalidFile, '[Broken](./non-existent.md)');

            $validator = app(LinkValidationInterface::class);
            $config = new ValidationConfig(
                paths: [$invalidFile],
                scope: ['internal']
            );

            // Act
            $result = $validator->validateFiles([$invalidFile], $config);

            // Assert
            expect($result->getBrokenCount())->toBeGreaterThan(0);
            expect($result->getSuccessRate())->toBeLessThan(100.0);
            expect($result->hasErrors())->toBeFalse(); // No system errors, just broken links
        });
    });

    describe('service dependency injection', function () {
        it('resolves all service dependencies correctly', function () {
            // Act & Assert
            expect(app(LinkValidationInterface::class))->toBeInstanceOf(LinkValidationInterface::class);
            expect(app(ReportingInterface::class))->toBeInstanceOf(ReportingInterface::class);
            expect(app(SecurityValidationInterface::class))->toBeInstanceOf(SecurityValidationInterface::class);
            expect(app(GitHubAnchorInterface::class))->toBeInstanceOf(GitHubAnchorInterface::class);
            expect(app(StatisticsInterface::class))->toBeInstanceOf(StatisticsInterface::class);
        });
    });
})->group('integration', 'services');
```

## Test Configuration and Setup

### Pest.php Configuration

```php
<?php

declare(strict_types=1);

use old\TestCase;

/*
|--------------------------------------------------------------------------
| Test Case
|--------------------------------------------------------------------------
*/

uses(TestCase::class)->in('Feature');
uses(TestCase::class)->in('Unit');
uses(TestCase::class)->in('Integration');

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
    // Helper function for tests
}

/*
|--------------------------------------------------------------------------
| Test Groups
|--------------------------------------------------------------------------
*/

// Unit test groups
uses()->group('unit')->in('Unit');
uses()->group('services')->in('Unit/Services');
uses()->group('value-objects')->in('Unit/ValueObjects');
uses()->group('formatters')->in('Unit/Formatters');

// Feature test groups
uses()->group('feature')->in('Feature');
uses()->group('commands')->in('Feature/Commands');
uses()->group('validation')->in('Feature/Validation');
uses()->group('reporting')->in('Feature/Reporting');

// Integration test groups
uses()->group('integration')->in('Integration');

// Architecture test groups
uses()->group('arch')->in('Architecture');

// Performance test groups
uses()->group('performance')->in('Performance');
```

### TestCase.php Base Class

```php
<?php

declare(strict_types=1);

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Illuminate\Support\Facades\File;

abstract class TestCase extends BaseTestCase
{
    use CreatesApplication;

    protected function setUp(): void
    {
        parent::setUp();
        
        // Set up test environment
        $this->setUpTestEnvironment();
    }

    protected function tearDown(): void
    {
        // Clean up test files
        $this->cleanUpTestFiles();
        
        parent::tearDown();
    }

    /**
     * Set up test environment.
     */
    protected function setUpTestEnvironment(): void
    {
        // Configure test-specific settings
        config([
            'validate-links.defaults.timeout' => 5,
            'validate-links.defaults.max_broken' => 10,
        ]);
    }

    /**
     * Clean up test files.
     */
    protected function cleanUpTestFiles(): void
    {
        $testDirs = ['test-validation-workflow', 'integration-test'];
        
        foreach ($testDirs as $dir) {
            if (File::exists($dir)) {
                File::deleteDirectory($dir);
            }
        }
    }

    /**
     * Create test markdown file with content.
     */
    protected function createTestFile(string $filename, string $content): string
    {
        File::put($filename, $content);
        return $filename;
    }

    /**
     * Create test directory structure.
     */
    protected function createTestDirectory(string $name, array $files = []): string
    {
        File::makeDirectory($name);
        
        foreach ($files as $filename => $content) {
            $this->createTestFile("{$name}/{$filename}", $content);
        }
        
        return $name;
    }
}
```

## Testing Best Practices

### 1. Test Naming Conventions

- **Test Classes:** `[ClassName]Test.php`
- **Test Methods:** Descriptive names using `it()` function
- **Test Groups:** Use `@group` annotations or `group()` method

### 2. Test Structure (AAA Pattern)

```php
it('validates internal links correctly', function () {
    // Arrange - Set up test data and mocks
    $file = 'test.md';
    $content = '[Link](./other.md)';
    
    // Act - Execute the code under test
    $result = $service->validateFile($file, $config);
    
    // Assert - Verify the results
    expect($result)->toBeArray();
    expect($result)->toBeEmpty();
});
```

### 3. Mock Usage Guidelines

```php
// Use Mockery for complex mocking
$mock = Mockery::mock(ServiceInterface::class);
$mock->shouldReceive('method')
     ->with('parameter')
     ->andReturn('result');

// Use Laravel's built-in mocking for facades
File::shouldReceive('get')
    ->with('filename')
    ->andReturn('content');
```

### 4. Data Providers and Fixtures

```php
// Use datasets for parameterized tests
it('validates different link types', function (string $link, bool $expected) {
    $result = $service->validateLink($link, 'test.md', $config);
    expect($result)->toBe($expected);
})->with([
    ['./valid-file.md', true],
    ['./invalid-file.md', false],
    ['https://example.com', true],
    ['#valid-anchor', true],
    ['#invalid-anchor', false],
]);
```

## Continuous Integration Integration

### GitHub Actions Workflow Integration

The test suite integrates with the CI/CD workflows documented separately, providing:

- **Automated Test Execution:** All test groups run on push/PR
- **Coverage Reporting:** Code coverage reports generated and uploaded
- **Performance Monitoring:** Performance tests track regression
- **Mutation Testing:** Infection runs to verify test quality

### Composer Script Integration

The enhanced composer.json scripts provide comprehensive test execution:

```bash
# Run all tests
composer test:all

# Run specific test groups
composer test:unit
composer test:feature
composer test:integration

# Run with coverage
composer test:coverage

# Run mutation testing
composer test:mutation

# Run performance tests
composer test:performance
```

This comprehensive Pest test suite ensures robust validation of the Laravel Zero validate-links application while maintaining high code quality and test coverage standards.
