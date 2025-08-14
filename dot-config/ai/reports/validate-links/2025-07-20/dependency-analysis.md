# Dependency Analysis & Migration Mapping

**Date:** July 20, 2025  
**Project:** validate-links Laravel Zero Migration - Dependency Analysis  

## Current vs Target Dependency Mapping

### Core Dependencies Migration

| Current Package | Current Usage | Laravel Zero Equivalent | Migration Strategy |
|----------------|---------------|------------------------|-------------------|
| **Custom Logger** | `src/Utils/Logger.php` | Laravel's Log facade | Replace with `Log::info()`, `$this->info()` |
| **Custom CLI Parser** | `src/Core/CLIArgumentParser.php` | Command signatures + Laravel Prompts | Convert to command signatures, add interactive prompts |
| **Manual Autoloading** | Binary file autoloader | Laravel Zero autoloading | Remove custom autoloader |
| **Custom Error Handling** | Try/catch in binary | Laravel Exception handling | Use Laravel's exception system |
| **Direct CURL Usage** | HTTP requests in LinkValidator | Laravel HTTP client | Use `Http::get()` facade |
| **Custom Configuration** | Hardcoded defaults array | Laravel config system | Move to `config/validate-links.php` |

### Service Architecture Transformation

#### Current Monolithic Structure
```
Application.php (handles everything)
├── CLI parsing
├── File validation
├── Report generation  
├── Error handling
└── Statistics
```

#### Target Service-Oriented Architecture
```
Commands/
├── ValidateCommand.php
├── FixCommand.php
└── ReportCommand.php

Services/
├── LinkValidationService.php
├── ReportingService.php
├── SecurityValidationService.php
├── StatisticsService.php
└── GitHubAnchorService.php

Formatters/
├── ConsoleFormatter.php
├── JsonFormatter.php
├── MarkdownFormatter.php
└── HtmlFormatter.php
```

### External Dependencies Compatibility

| Feature | Current Implementation | Laravel Zero Integration | Benefits |
|---------|----------------------|-------------------------|----------|
| **HTTP Requests** | ext-curl directly | Laravel HTTP client | Built-in retry, middleware, testing |
| **File Operations** | Direct PHP functions | Laravel Storage/File | Better path handling, security |
| **JSON Handling** | ext-json + manual parsing | Laravel Collections | Better data manipulation |
| **String Operations** | ext-mbstring + manual | Laravel Str helpers | Unicode-safe operations |
| **Progress Tracking** | Custom console output | Laravel Prompts progress bars | Rich visual feedback |
| **Configuration** | Manual array parsing | Laravel config + .env | Environment-aware configuration |

## Service Contract Definitions

### Core Service Interfaces

**Create app/Services/Contracts/LinkValidationInterface.php:**
```php
<?php

declare(strict_types=1);

namespace App\Services\Contracts;

use App\Services\ValueObjects\ValidationConfig;
use App\Services\ValueObjects\ValidationResult;

interface LinkValidationInterface
{
    public function validateFiles(array $files, ValidationConfig $config): ValidationResult;
    
    public function validateFile(string $file, ValidationConfig $config): array;
    
    public function extractLinks(string $content): array;
    
    public function validateLink(string $link, string $sourceFile, ValidationConfig $config): bool;
}
```

**Create app/Services/Contracts/ReportingInterface.php:**
```php
<?php

declare(strict_types=1);

namespace App\Services\Contracts;

use App\Services\ValueObjects\ValidationResult;
use App\Services\ValueObjects\ValidationConfig;
use Illuminate\Console\Command;

interface ReportingInterface
{
    public function generateReport(
        ValidationResult $result, 
        ValidationConfig $config, 
        Command $command
    ): int;
    
    public function formatOutput(ValidationResult $result, string $format): string;
    
    public function writeToFile(string $content, string $path): bool;
}
```

## Value Objects for Type Safety

### ValidationConfig Value Object

**Create app/Services/ValueObjects/ValidationConfig.php:**
```php
<?php

declare(strict_types=1);

namespace App\Services\ValueObjects;

final readonly class ValidationConfig
{
    public function __construct(
        public array $scope = ['internal', 'anchor'],
        public int $maxDepth = 0,
        public bool $includeHidden = false,
        public array $excludePatterns = [],
        public bool $checkExternal = false,
        public bool $caseSensitive = false,
        public int $timeout = 30,
        public string $format = 'console',
        public ?string $output = null,
        public int $maxBroken = 50,
        public int $maxFiles = 0,
        public bool $dryRun = false,
        public bool $fix = false,
        public bool $interactive = false
    ) {}
    
    public static function fromCommandOptions(array $options): self
    {
        return new self(
            scope: $options['scope'] ?? ['internal', 'anchor'],
            maxDepth: (int) ($options['max-depth'] ?? 0),
            includeHidden: (bool) ($options['include-hidden'] ?? false),
            excludePatterns: $options['exclude'] ?? [],
            checkExternal: (bool) ($options['check-external'] ?? false),
            caseSensitive: (bool) ($options['case-sensitive'] ?? false),
            timeout: (int) ($options['timeout'] ?? 30),
            format: $options['format'] ?? 'console',
            output: $options['output'] ?? null,
            maxBroken: (int) ($options['max-broken'] ?? 50),
            maxFiles: (int) ($options['max-files'] ?? 0),
            dryRun: (bool) ($options['dry-run'] ?? false),
            fix: (bool) ($options['fix'] ?? false),
            interactive: (bool) ($options['interactive'] ?? false)
        );
    }
    
    public function shouldValidateScope(string $scope): bool
    {
        return in_array('all', $this->scope) || in_array($scope, $this->scope);
    }
}
```

### ValidationResult Value Object

**Create app/Services/ValueObjects/ValidationResult.php:**
```php
<?php

declare(strict_types=1);

namespace App\Services\ValueObjects;

final readonly class ValidationResult
{
    public function __construct(
        public array $statistics,
        public array $brokenLinks,
        public array $processedFiles,
        public float $executionTime = 0.0,
        public int $exitCode = 0
    ) {}
    
    public function isSuccessful(): bool
    {
        return $this->exitCode === 0 && empty($this->brokenLinks);
    }
    
    public function getTotalLinks(): int
    {
        return $this->statistics['total_links'] ?? 0;
    }
    
    public function getBrokenCount(): int
    {
        return count($this->brokenLinks);
    }
    
    public function getSuccessRate(): float
    {
        $total = $this->getTotalLinks();
        if ($total === 0) {
            return 100.0;
        }
        
        return (($total - $this->getBrokenCount()) / $total) * 100;
    }
}
```

## Laravel Zero Command Integration Patterns

### Enhanced Command Base Class

**Create app/Commands/BaseValidationCommand.php:**
```php
<?php

declare(strict_types=1);

namespace App\Commands;

use App\Services\ValueObjects\ValidationConfig;
use LaravelZero\Framework\Commands\Command;

abstract class BaseValidationCommand extends Command
{
    protected function createConfigFromOptions(): ValidationConfig
    {
        return ValidationConfig::fromCommandOptions($this->options());
    }
    
    protected function displayValidationSummary(ValidationConfig $config, array $paths): void
    {
        $this->info('🔗 Link Validation Configuration');
        $this->newLine();
        
        $this->line("📁 Paths: " . implode(', ', $paths));
        $this->line("🎯 Scope: " . implode(', ', $config->scope));
        $this->line("🌐 External: " . ($config->checkExternal ? '✅ Yes' : '❌ No'));
        $this->line("📊 Format: {$config->format}");
        
        if ($config->maxBroken > 0) {
            $this->line("🛑 Max broken: {$config->maxBroken}");
        }
        
        if ($config->dryRun) {
            $this->warn("🔍 DRY RUN MODE - No actual validation");
        }
        
        $this->newLine();
    }
    
    protected function collectFiles(array $paths, ValidationConfig $config): array
    {
        // File collection logic with progress feedback
        $this->info('📋 Collecting files...');
        
        // Implementation here...
        
        return $files;
    }
}
```

## Testing Strategy with Pest

### Test Structure Organization

```
tests/
├── Feature/
│   ├── Commands/
│   │   ├── ValidateCommandTest.php
│   │   ├── InteractiveFlowTest.php
│   │   └── ReportCommandTest.php
│   └── Integration/
│       ├── FullWorkflowTest.php
│       └── ExternalLinkTest.php
├── Unit/
│   ├── Services/
│   │   ├── LinkValidationServiceTest.php
│   │   ├── SecurityValidationServiceTest.php
│   │   └── GitHubAnchorServiceTest.php
│   ├── ValueObjects/
│   │   ├── ValidationConfigTest.php
│   │   └── ValidationResultTest.php
│   └── Formatters/
│       ├── ConsoleFormatterTest.php
│       └── JsonFormatterTest.php
└── Fixtures/
    ├── markdown/
    ├── html/
    └── expected-results/
```

### Sample Test Implementation

**Create tests/Feature/Commands/ValidateCommandTest.php:**
```php
<?php

declare(strict_types=1);

use App\Services\LinkValidationService;

beforeEach(function () {
    $this->mockService = Mockery::mock(LinkValidationService::class);
    $this->app->instance(LinkValidationService::class, $this->mockService);
});

it('validates files successfully', function () {
    $this->mockService
        ->shouldReceive('validateFiles')
        ->once()
        ->andReturn(new ValidationResult([], [], []));
    
    $this->artisan('validate', ['paths' => ['./tests/fixtures']])
        ->expectsOutput('Validation completed successfully')
        ->assertExitCode(0);
});

it('handles interactive mode', function () {
    $this->artisan('validate --interactive')
        ->expectsQuestion('Enter path to validate', './docs')
        ->expectsChoice('What types of links should be validated?', ['internal'], [
            'internal' => 'Internal file links',
            'anchor' => 'Anchor/heading links',
            'cross-reference' => 'Cross-reference links',
            'external' => 'External HTTP/HTTPS links'
        ])
        ->expectsConfirmation('Proceed with validation?', 'yes')
        ->assertExitCode(0);
});
```

## Migration Automation Scripts

### Composer Script for Migration

**Add to composer.json scripts:**
```json
{
    "scripts": {
        "migrate:setup": [
            "php artisan config:publish validate-links",
            "php artisan vendor:publish --tag=validate-links-config"
        ],
        "migrate:test": [
            "pest tests/Feature/",
            "pest tests/Unit/"
        ],
        "migrate:validate": [
            "pint --test",
            "phpstan analyse app/",
            "@migrate:test"
        ]
    }
}
```

## Performance Optimization Strategies

### 1. Memory Management
- Use Laravel's lazy collections for large file sets
- Implement streaming for massive documentation projects
- Add memory usage monitoring and limits

### 2. External Link Validation
- Implement concurrent HTTP requests with Laravel's HTTP pool
- Add intelligent caching for repeated external links
- Use circuit breaker pattern for failing external services

### 3. File Processing
- Add file size limits and validation
- Implement smart file filtering
- Use Laravel's file system abstractions

## Backward Compatibility Considerations

### CLI Interface Compatibility
- Maintain all existing command-line options
- Provide migration guide for script users
- Add deprecation warnings for removed features

### Output Format Compatibility
- Ensure JSON output maintains same structure
- Keep console output familiar
- Maintain exit codes for CI/CD integration

### Configuration Migration
- Provide configuration file migration command
- Support legacy configuration formats
- Add validation for configuration files

This completes the comprehensive refactoring documentation with detailed dependency analysis, service architecture design, and practical implementation guidance for migrating the validate-links package to Laravel Zero.
