# Laravel Zero Patterns

## Overview

This document establishes Laravel Zero-specific architectural patterns and conventions discovered and implemented during the PHPStan Level 10 remediation project. These patterns are optimized for console applications and maintain the highest standards of type safety and code quality.

## Table of Contents

1. [Console Application Architecture](#console-application-architecture)
2. [Command Patterns](#command-patterns)
3. [Service Layer Architecture](#service-layer-architecture)
4. [ValueObject Patterns](#valueobject-patterns)
5. [Dependency Injection](#dependency-injection)
6. [Configuration Management](#configuration-management)
7. [Error Handling](#error-handling)
8. [Service Provider Patterns](#service-provider-patterns)
9. [Testing Patterns](#testing-patterns)
10. [Performance Optimizations](#performance-optimizations)

## Console Application Architecture

### Application Structure

Laravel Zero applications follow a specific architectural pattern optimized for console operations:

```
app/
├── Commands/              # Console commands (entry points)
│   ├── BaseValidationCommand.php
│   ├── ValidateCommand.php
│   ├── ConfigCommand.php
│   ├── FixCommand.php
│   └── ReportCommand.php
├── Services/              # Business logic layer
│   ├── LinkValidationService.php
│   ├── ReportingService.php
│   ├── SecurityValidationService.php
│   ├── Contracts/         # Service interfaces
│   ├── Formatters/        # Output formatters
│   └── ValueObjects/      # Data transfer objects
├── Enums/                 # Type-safe enumerations
├── Exceptions/            # Custom exceptions
└── Providers/             # Service providers
```

### Layered Architecture Pattern

```php
// ✅ Correct: Clear separation of concerns
final class ValidateCommand extends BaseValidationCommand
{
    public function __construct(
        private readonly LinkValidationInterface $linkValidation,    // Business logic
        private readonly ReportingInterface $reporting               // Presentation logic
    ) {
        parent::__construct($linkValidation, $reporting);
    }

    public function handle(): int
    {
        // Command layer: Input validation and orchestration
        $this->validateCommandOptions();
        
        // Delegate to service layer
        $results = $this->linkValidation->validateFile($filePath, $config);
        
        // Delegate to presentation layer
        $report = $this->reporting->generateReport($results, $format);
        
        return $this->determineExitCode($results);
    }
}
```

## Command Patterns

### Base Command Pattern

```php
abstract class BaseValidationCommand extends Command
{
    protected LinkValidationInterface $linkValidation;
    protected ReportingInterface $reporting;

    public function __construct(
        LinkValidationInterface $linkValidation,
        ReportingInterface $reporting
    ) {
        parent::__construct();
        $this->linkValidation = $linkValidation;
        $this->reporting = $reporting;
    }

    /**
     * Validate command options using enum validation.
     */
    protected function validateCommandOptions(): void
    {
        $scope = $this->option('scope');
        if ($scope && !ValidationScope::tryFrom($scope)) {
            throw new InvalidArgumentException("Invalid scope: {$scope}");
        }

        $format = $this->option('format');
        if ($format && !OutputFormat::tryFrom($format)) {
            throw new InvalidArgumentException("Invalid format: {$format}");
        }
    }

    /**
     * Handle validation errors with proper type safety.
     */
    protected function handleValidationError(Throwable $e): int
    {
        match (true) {
            $e instanceof SecurityException => $this->error("Security violation: {$e->getMessage()}"),
            $e instanceof ValidationException => $this->error("Validation error: {$e->getMessage()}"),
            $e instanceof RuntimeException => $this->error("Runtime error: {$e->getMessage()}"),
            default => $this->error("Unexpected error: {$e->getMessage()}"),
        };

        return self::FAILURE;
    }
}
```

### Interactive Command Pattern

```php
final class ValidateCommand extends BaseValidationCommand
{
    /**
     * Handle interactive mode with comprehensive configuration.
     */
    private function handleInteractive(): int
    {
        $this->info('🔗 Interactive Link Validation Setup');
        
        // Gather configuration using Laravel Prompts
        $paths = $this->gatherPaths();
        $scope = $this->gatherValidationScope();
        $outputConfig = $this->gatherOutputConfiguration();
        $advancedOptions = $this->gatherAdvancedOptions();
        
        // Confirm before execution
        if (!$this->confirmConfiguration($paths, $scope, $outputConfig, $advancedOptions)) {
            $this->warn('Validation cancelled.');
            return self::FAILURE;
        }
        
        // Execute with real-time feedback
        return $this->executeInteractiveValidation($paths, $scope, $outputConfig);
    }

    /**
     * Gather validation scope using enum-driven options.
     *
     * @return ValidationScope[]
     */
    private function gatherValidationScope(): array
    {
        $this->info('📋 Select validation scopes:');
        
        // Display scope descriptions
        foreach (ValidationScope::cases() as $scope) {
            if ($scope !== ValidationScope::ALL) {
                $this->line("  <fg=cyan>{$scope->value}</fg>: {$scope->getDescription()}");
            }
        }

        $selectedValues = multiselect(
            label: 'What types of links should be validated?',
            options: $this->getScopeOptions(),
            default: [ValidationScope::INTERNAL->value, ValidationScope::ANCHOR->value],
            required: true,
            hint: 'Use space to select, enter to confirm'
        );

        // Convert selected values to enum instances
        return array_map(
            fn ($value) => ValidationScope::from($value),
            $selectedValues
        );
    }
}
```

### Progress Feedback Pattern

```php
private function executeInteractiveValidation(array $paths, array $scope, array $outputConfig): int
{
    $totalFiles = $this->countFiles($paths);

    $progress = progress(
        label: 'Validating links',
        steps: $totalFiles
    );

    $allResults = [];
    foreach ($paths as $path) {
        $files = $this->getFilesFromPath($path);

        foreach ($files as $file) {
            $progress->label('Validating: ' . basename((string) $file));

            $config = ValidationConfig::create([
                'scopes' => array_map(fn ($s) => ValidationScope::from($s), $scope),
                'timeout' => 30,
                'concurrent_requests' => 10,
            ]);

            $fileResults = $this->linkValidation->validateFile($file, $config);
            $allResults = array_merge($allResults, $fileResults->toValidationResultArray());

            $progress->advance();

            // Show real-time broken link alerts
            if ($this->hasBrokenLinks($fileResults->toValidationResultArray())) {
                $this->warn("⚠️  Broken links found in: {(string) $file}");
            }
        }
    }

    $progress->finish();
    return $this->processResults($allResults, $outputConfig);
}
```

## Service Layer Architecture

### Service Interface Pattern

```php
interface LinkValidationInterface
{
    /**
     * Validate all links in a file and return a collection of validation results.
     *
     * @param string $filePath The path to the file to validate
     * @param ValidationConfig $config The validation configuration to use
     * @return ValidationResultCollection Collection of validation results for all links found
     * @throws SecurityException If the file path fails security validation
     * @throws RuntimeException If the file cannot be read
     */
    public function validateFile(string $filePath, ValidationConfig $config): ValidationResultCollection;

    /**
     * Validate a single link and return the validation result.
     *
     * @param string $url The URL to validate
     * @param ValidationConfig $config The validation configuration to use
     * @return ValidationResult The validation result for the link
     */
    public function validateLink(string $url, ValidationConfig $config): ValidationResult;

    /**
     * Validate multiple links and return a collection of validation results.
     *
     * @param array<string> $urls Array of URLs to validate
     * @param ValidationConfig $config The validation configuration to use
     * @return ValidationResultCollection Collection of validation results
     */
    public function validateLinks(array $urls, ValidationConfig $config): ValidationResultCollection;
}
```

### Service Implementation Pattern

```php
final class LinkValidationService implements LinkValidationInterface
{
    public ?GitHubAnchorInterface $gitHubAnchorService = null;

    public function __construct(
        private readonly SecurityValidationInterface $security
    ) {}

    public function validateFile(string $filePath, ValidationConfig $config): ValidationResultCollection
    {
        // Input validation
        if (!file_exists($filePath)) {
            return ValidationResultCollection::fromArray([
                ValidationResult::create(
                    url: $filePath,
                    status: LinkStatus::BROKEN,
                    message: 'File not found'
                ),
            ]);
        }

        // Security validation
        if (!$this->security->validatePath($filePath)) {
            throw new SecurityException("Invalid file path: {$filePath}");
        }

        // Business logic
        $content = file_get_contents($filePath);
        if ($content === false) {
            throw new RuntimeException("Unable to read file: {$filePath}");
        }

        return $this->processFileContent($content, $filePath, $config);
    }

    /**
     * Process file content and validate links based on configuration.
     */
    private function processFileContent(string $content, string $filePath, ValidationConfig $config): ValidationResultCollection
    {
        $links = $this->extractLinks($content);
        $categorized = $this->categorizeLinks($links);
        $results = [];

        if ($config->shouldValidateInternal()) {
            $internalResults = $this->validateInternalLinks(
                $categorized['internal'] ?? [],
                dirname($filePath)
            );
            $results = array_merge($results, $internalResults);
        }

        if ($config->shouldValidateExternal()) {
            $externalResults = $this->validateExternalLinksInternal($categorized['external'] ?? []);
            $results = array_merge($results, $externalResults);
        }

        if ($config->shouldValidateAnchors()) {
            $anchorResults = $this->validateAnchorLinks($categorized['anchor'] ?? [], $content);
            $results = array_merge($results, $anchorResults);
        }

        return ValidationResultCollection::fromArray($results);
    }
}
```

### Strategy Pattern for Link Classification

```php
public function classifyLink(string $url): LinkType
{
    return match (true) {
        str_starts_with($url, '#') => LinkType::ANCHOR,
        str_starts_with($url, 'http://') || str_starts_with($url, 'https://') => LinkType::EXTERNAL,
        str_contains($url, '://') || preg_match('/^[a-z]+:/i', $url) => LinkType::EXTERNAL,
        str_contains($url, '#') => LinkType::CROSS_REFERENCE,
        default => LinkType::INTERNAL,
    };
}

public function categorizeLinks(array $links): array
{
    $categorized = [
        'internal' => [],
        'external' => [],
        'anchor' => [],
    ];

    foreach ($links as $link) {
        $url = $link['url'];
        $linkType = $this->classifyLink($url);

        match ($linkType) {
            LinkType::ANCHOR => $categorized['anchor'][] = $link,
            LinkType::EXTERNAL => $categorized['external'][] = $link,
            LinkType::INTERNAL, LinkType::CROSS_REFERENCE => $categorized['internal'][] = $link,
        };
    }

    return $categorized;
}
```

## ValueObject Patterns

### Immutable ValueObject Pattern

```php
final readonly class ValidationResult implements Stringable
{
    /**
     * @param array<string, mixed> $metadata
     */
    public function __construct(
        private string $url,
        private LinkStatus $status,
        private ValidationScope $scope,
        private ?string $error = null,
        private ?int $httpStatusCode = null,
        private ?string $redirectUrl = null,
        private float $responseTime = 0.0,
        private array $metadata = [],
        private ?string $filePath = null
    ) {
        // Initialize public properties for formatter compatibility
        $this->broken = $this->initializeBrokenLinksArray();
        $this->files = $this->initializeFilesArray();
        $this->links = $this->initializeLinksArray();
        $this->duration = $this->initializeDuration();
    }

    // Getters for all properties
    public function getUrl(): string { return $this->url; }
    public function getStatus(): LinkStatus { return $this->status; }
    public function getScope(): ValidationScope { return $this->scope; }
    
    // Business logic methods
    public function isValid(): bool { return $this->status === LinkStatus::VALID; }
    public function isBroken(): bool { return $this->status->isBroken(); }
    public function shouldRetry(): bool { return $this->status->shouldRetry(); }
}
```

### Factory Method Pattern

```php
/**
 * Create a successful validation result.
 *
 * @param array<string, mixed> $metadata
 */
public static function success(
    string $url,
    ValidationScope $scope,
    ?int $httpStatusCode = null,
    float $responseTime = 0.0,
    array $metadata = [],
    ?string $filePath = null
): self {
    return new self(
        url: $url,
        status: LinkStatus::VALID,
        scope: $scope,
        httpStatusCode: $httpStatusCode,
        responseTime: $responseTime,
        metadata: $metadata,
        filePath: $filePath
    );
}

/**
 * Create a failed validation result.
 *
 * @param array<string, mixed> $metadata
 */
public static function failure(
    string $url,
    ValidationScope $scope,
    LinkStatus $status,
    ?string $error = null,
    ?int $httpStatusCode = null,
    ?string $redirectUrl = null,
    float $responseTime = 0.0,
    array $metadata = [],
    ?string $filePath = null
): self {
    return new self(
        url: $url,
        status: $status,
        scope: $scope,
        error: $error,
        httpStatusCode: $httpStatusCode,
        redirectUrl: $redirectUrl,
        responseTime: $responseTime,
        metadata: $metadata,
        filePath: $filePath
    );
}
```

### Collection Pattern

```php
final class ValidationResultCollection implements Countable, IteratorAggregate
{
    /**
     * @param ValidationResult[] $results
     */
    public function __construct(
        private array $results = []
    ) {}

    /**
     * Create collection from array of results.
     *
     * @param ValidationResult[] $results
     */
    public static function fromArray(array $results): self
    {
        return new self($results);
    }

    /**
     * Get successful results.
     */
    public function getSuccessful(): self
    {
        return new self(array_filter($this->results, fn($result) => $result->isValid()));
    }

    /**
     * Get failed results.
     */
    public function getFailed(): self
    {
        return new self(array_filter($this->results, fn($result) => !$result->isValid()));
    }

    /**
     * @return ValidationResult[]
     */
    public function toValidationResultArray(): array
    {
        return $this->results;
    }

    public function count(): int
    {
        return count($this->results);
    }

    /**
     * @return Iterator<int, ValidationResult>
     */
    public function getIterator(): Iterator
    {
        return new ArrayIterator($this->results);
    }
}
```

## Dependency Injection

### Constructor Injection Pattern

```php
final class ValidateCommand extends BaseValidationCommand
{
    public function __construct(
        LinkValidationInterface $linkValidation,
        ReportingInterface $reporting
    ) {
        parent::__construct($linkValidation, $reporting);
    }
}

final class LinkValidationService implements LinkValidationInterface
{
    public ?GitHubAnchorInterface $gitHubAnchorService = null;

    public function __construct(
        private readonly SecurityValidationInterface $security
    ) {}
}
```

### Service Provider Registration

```php
final class ValidateLinksServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     */
    public function register(): void
    {
        // Bind interfaces to implementations
        $this->app->bind(LinkValidationInterface::class, LinkValidationService::class);
        $this->app->bind(ReportingInterface::class, ReportingService::class);
        $this->app->bind(SecurityValidationInterface::class, SecurityValidationService::class);
        $this->app->bind(StatisticsInterface::class, StatisticsService::class);
        $this->app->bind(GitHubAnchorInterface::class, GitHubAnchorService::class);

        // Register singletons for stateful services
        $this->app->singleton(PluginManager::class);
        $this->app->singleton(ConcurrentValidationService::class);
    }

    /**
     * Bootstrap services.
     */
    public function boot(): void
    {
        // Load configuration
        $this->mergeConfigFrom(
            __DIR__.'/../../config/validate-links.php',
            'validate-links'
        );

        // Register commands
        if ($this->app->runningInConsole()) {
            $this->commands([
                ValidateCommand::class,
                ConfigCommand::class,
                FixCommand::class,
                ReportCommand::class,
            ]);
        }
    }
}
```

## Configuration Management

### Configuration ValueObject Pattern

```php
final readonly class ValidationConfig
{
    /**
     * @param ValidationScope[] $scopes
     * @param array<string, mixed> $options
     */
    public function __construct(
        private array $scopes,
        private int $timeout = 30,
        private int $concurrentRequests = 10,
        private bool $followRedirects = true,
        private int $maxRedirects = 5,
        private string $userAgent = 'validate-links/1.0',
        private bool $cacheResults = true,
        private array $options = []
    ) {}

    /**
     * Create configuration from array.
     *
     * @param array<string, mixed> $options
     */
    public static function create(array $options): self
    {
        $scopes = $options['scopes'] ?? [ValidationScope::ALL];
        if (!is_array($scopes)) {
            $scopes = [ValidationScope::ALL];
        }

        // Ensure all scopes are ValidationScope instances
        $validScopes = [];
        foreach ($scopes as $scope) {
            if ($scope instanceof ValidationScope) {
                $validScopes[] = $scope;
            } elseif (is_string($scope)) {
                $validScopes[] = ValidationScope::from($scope);
            }
        }

        return new self(
            scopes: $validScopes,
            timeout: is_int($options['timeout'] ?? null) ? $options['timeout'] : 30,
            concurrentRequests: is_int($options['concurrent_requests'] ?? null) ? $options['concurrent_requests'] : 10,
            followRedirects: is_bool($options['follow_redirects'] ?? null) ? $options['follow_redirects'] : true,
            maxRedirects: is_int($options['max_redirects'] ?? null) ? $options['max_redirects'] : 5,
            userAgent: is_string($options['user_agent'] ?? null) ? $options['user_agent'] : 'validate-links/1.0',
            cacheResults: is_bool($options['cache_results'] ?? null) ? $options['cache_results'] : true,
            options: is_array($options['options'] ?? null) ? $options['options'] : []
        );
    }

    // Validation methods
    public function shouldValidateInternal(): bool
    {
        return in_array(ValidationScope::INTERNAL, $this->scopes, true) ||
               in_array(ValidationScope::ALL, $this->scopes, true);
    }

    public function shouldValidateExternal(): bool
    {
        return in_array(ValidationScope::EXTERNAL, $this->scopes, true) ||
               in_array(ValidationScope::ALL, $this->scopes, true);
    }

    public function shouldValidateAnchors(): bool
    {
        return in_array(ValidationScope::ANCHOR, $this->scopes, true) ||
               in_array(ValidationScope::ALL, $this->scopes, true);
    }
}
```

### Configuration File Pattern

```php
// config/validate-links.php
<?php

declare(strict_types=1);

return [
    /*
    |--------------------------------------------------------------------------
    | Default Validation Scope
    |--------------------------------------------------------------------------
    |
    | This option controls the default scope for link validation when no
    | specific scope is provided. Available options: internal, external,
    | anchor, image, all
    |
    */
    'default_scope' => env('VALIDATE_LINKS_DEFAULT_SCOPE', 'all'),

    /*
    |--------------------------------------------------------------------------
    | Request Timeout
    |--------------------------------------------------------------------------
    |
    | The maximum time in seconds to wait for a response when validating
    | external links. This helps prevent the validation process from
    | hanging on slow or unresponsive servers.
    |
    */
    'timeout' => (int) env('VALIDATE_LINKS_TIMEOUT', 30),

    /*
    |--------------------------------------------------------------------------
    | Concurrent Requests
    |--------------------------------------------------------------------------
    |
    | The number of concurrent requests to make when validating external
    | links. Higher values can speed up validation but may overwhelm
    | target servers or trigger rate limiting.
    |
    */
    'concurrent_requests' => (int) env('VALIDATE_LINKS_CONCURRENT_REQUESTS', 10),

    /*
    |--------------------------------------------------------------------------
    | User Agent
    |--------------------------------------------------------------------------
    |
    | The User-Agent string to use when making HTTP requests to validate
    | external links. Some servers may block requests without a proper
    | User-Agent header.
    |
    */
    'user_agent' => env('VALIDATE_LINKS_USER_AGENT', 'validate-links/1.0'),

    /*
    |--------------------------------------------------------------------------
    | Follow Redirects
    |--------------------------------------------------------------------------
    |
    | Whether to follow HTTP redirects when validating external links.
    | When enabled, the validator will follow redirects up to the
    | maximum number specified below.
    |
    */
    'follow_redirects' => env('VALIDATE_LINKS_FOLLOW_REDIRECTS', true),

    /*
    |--------------------------------------------------------------------------
    | Maximum Redirects
    |--------------------------------------------------------------------------
    |
    | The maximum number of redirects to follow when validating external
    | links. This prevents infinite redirect loops and limits the
    | validation time for heavily redirected URLs.
    |
    */
    'max_redirects' => (int) env('VALIDATE_LINKS_MAX_REDIRECTS', 5),
];
```

## Error Handling

### Exception Hierarchy Pattern

```php
abstract class ValidateLinksException extends Exception
{
    public function __construct(
        string $message = '',
        int $code = 0,
        ?Throwable $previous = null
    ) {
        parent::__construct($message, $code, $previous);
    }
}

final class SecurityException extends ValidateLinksException {}
final class ValidationException extends ValidateLinksException {}
final class ConfigurationException extends ValidateLinksException {}
```

### Error Handling in Services

```php
public function validateFile(string $filePath, ValidationConfig $config): ValidationResultCollection
{
    // Input validation
    if (!file_exists($filePath)) {
        return ValidationResultCollection::fromArray([
            ValidationResult::create(
                url: $filePath,
                status: LinkStatus::BROKEN,
                message: 'File not found'
            ),
        ]);
    }

    // Security validation
    if (!$this->security->validatePath($filePath)) {
        throw new SecurityException("Invalid file path: {$filePath}");
    }

    // File reading with error handling
    if (!is_readable($filePath)) {
        throw new RuntimeException("Unable to read file: {$filePath}");
    }

    $content = file_get_contents($filePath);
    if ($content === false) {
        throw new RuntimeException("Unable to read file: {$filePath}");
    }

    return $this->processFileContent($content, $filePath, $config);
}
```

### Command Error Handling

```php
protected function handleValidationError(Throwable $e): int
{
    match (true) {
        $e instanceof SecurityException => $this->error("Security violation: {$e->getMessage()}"),
        $e instanceof ValidationException => $this->error("Validation error: {$e->getMessage()}"),
        $e instanceof ConfigurationException => $this->error("Configuration error: {$e->getMessage()}"),
        $e instanceof RuntimeException => $this->error("Runtime error: {$e->getMessage()}"),
        default => $this->error("Unexpected error: {$e->getMessage()}"),
    };

    if ($this->option('verbose')) {
        $this->error($e->getTraceAsString());
    }

    return self::FAILURE;
}
```

## Service Provider Patterns

### Comprehensive Service Registration

```php
final class ValidateLinksServiceProvider extends ServiceProvider
{
    /**
     * All of the container bindings that should be registered.
     *
     * @var array<string, string>
     */
    public array $bindings = [
        LinkValidationInterface::class => LinkValidationService::class,
        ReportingInterface::class => ReportingService::class,
        SecurityValidationInterface::class => SecurityValidationService::class,
        StatisticsInterface::class => StatisticsService::class,
        GitHubAnchorInterface::class => GitHubAnchorService::class,
    ];

    /**
     * All of the container singletons that should be registered.
     *
     * @var array<string, string>
     */
    public array $singletons = [
        PluginManager::class => PluginManager::class,
        ConcurrentValidationService::class => ConcurrentValidationService::class,
    ];

    /**
     * Register services.
     */
    public function register(): void
    {
        // Configuration
        $this->mergeConfigFrom(
            __DIR__.'/../../config/validate-links.php',
            'validate-links'
        );

        // Conditional service registration
        if ($this->app->environment('testing')) {
            $this->app->bind(
                SecurityValidationInterface::class,
                MockSecurityValidationService::class
            );
        }
    }

    /**
     * Bootstrap services.
     */
    public function boot(): void
    {
        // Commands registration
        if ($this->app->runningInConsole()) {
            $this->commands([
                ValidateCommand::class,
                ConfigCommand::class,
                FixCommand::class,
                ReportCommand::class,
            ]);
        }

        // Configuration publishing
        $this->publishes([
            __DIR__.'/../../config/validate-links.php' => config_path('validate-links.php'),
        ], 'validate-links-config');
    }
}
```

## Testing Patterns

### Command Testing Pattern

```php
describe('ValidateCommand', function (): void {
    it('executes with default parameters', function (): void {
        $this->artisan('validate', ['paths' => ['tests/Fixtures/sample.md']])
            ->expectsOutput('🔍 Validating links in: tests/Fixtures/sample.md')
            ->assertExitCode(0);
    });

    it('handles invalid scope gracefully', function (): void {
        $this->artisan('validate', [
            'paths' => ['tests/Fixtures/sample.md'],
            '--scope' => 'invalid-scope'
        ])
        ->expectsOutput('Invalid scope: invalid-scope')
        ->assertExitCode(1);
    });

    it('processes multiple paths correctly', function (): void {
        $paths = ['tests/Fixtures/sample1.md', 'tests/Fixtures/sample2.md'];
        
        $this->artisan('validate', ['paths' => $paths])
            ->expectsOutput('🔍 Validating links in: ' . implode(', ', $paths))
            ->assertExitCode(0);
    });
});
```

### Service Testing Pattern

```php
describe('LinkValidationService', function (): void {
    beforeEach(function (): void {
        $this->securityService = $this->createMock(SecurityValidationInterface::class);
        $this->service = new LinkValidationService($this->securityService);
        $this->config = ValidationConfig::create(['scopes' => [ValidationScope::ALL]]);
    });

    it('validates file successfully', function (): void {
        $testFile = 'tests/Fixtures/valid-links.md';
        
        $this->securityService
            ->expects($this->once())
            ->method('validatePath')
            ->with($testFile)
            ->willReturn(true);

        $results = $this->service->validateFile($testFile, $this->config);

        expect($results)->toBeInstanceOf(ValidationResultCollection::class)
            ->and($results->count())->toBeGreaterThan(0);
    });
});
```

## Performance Optimizations

### Concurrent Processing Pattern

```php
final class ConcurrentValidationService
{
    /**
     * @param array<string> $urls
     */
    public function validateConcurrently(array $urls, ValidationConfig $config): ValidationResultCollection
    {
        $maxConcurrent = $config->getConcurrentRequests();
        $chunks = array_chunk($urls, $maxConcurrent);
        $allResults = [];

        foreach ($chunks as $chunk) {
            $promises = [];
            
            foreach ($chunk as $url) {
                $promises[] = $this->createValidationPromise($url, $config);
            }

            $chunkResults = $this->resolvePromises($promises);
            $allResults = array_merge($allResults, $chunkResults);
        }

        return ValidationResultCollection::fromArray($allResults);
    }

    private function createValidationPromise(string $url, ValidationConfig $config): callable
    {
        return function () use ($url, $config): ValidationResult {
            return $this->linkValidation->validateLink($url, $config);
        };
    }
}
```

### Memory Optimization Pattern

```php
final class LinkValidationService implements LinkValidationInterface
{
    /**
     * Process large files in chunks to manage memory usage.
     */
    public function validateLargeFile(string $filePath, ValidationConfig $config): ValidationResultCollection
    {
        $handle = fopen($filePath, 'r');
        if ($handle === false) {
            throw new RuntimeException("Unable to open file: {$filePath}");
        }

        $results = [];
        $lineNumber = 0;
        $chunkSize = 1000; // Process 1000 lines at a time

        try {
            while (!feof($handle)) {
                $chunk = [];
                for ($i = 0; $i < $chunkSize && !feof($handle); $i++) {
                    $line = fgets($handle);
                    if ($line !== false) {
                        $chunk[] = ['line' => ++$lineNumber, 'content' => $line];
                    }
                }

                if (!empty($chunk)) {
                    $chunkResults = $this->processChunk($chunk, $config);
                    $results = array_merge