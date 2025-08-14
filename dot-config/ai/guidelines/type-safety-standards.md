# Type Safety Standards

## Overview

This document establishes comprehensive type safety standards for maintaining **PHPStan Level 10 compliance**. These standards are based on the successfully implemented patterns throughout the codebase and provide practical guidance for writing type-safe PHP code in Laravel Zero applications.

## Table of Contents

1. [Core Type Safety Principles](#core-type-safety-principles)
2. [Property Type Annotations](#property-type-annotations)
3. [Method Documentation Requirements](#method-documentation-requirements)
4. [ValueObject Standards](#valueobject-standards)
5. [Service Layer Type Safety](#service-layer-type-safety)
6. [Command Type Safety](#command-type-safety)
7. [Exception Handling](#exception-handling)
8. [Array Shape Definitions](#array-shape-definitions)
9. [Generic Types](#generic-types)
10. [Laravel Zero Specific Patterns](#laravel-zero-specific-patterns)

## Core Type Safety Principles

### 1. Strict Type Declarations

**All PHP files must start with strict type declarations:**

```php
<?php

declare(strict_types=1);
```

### 2. Zero Mixed Types Policy

**Avoid mixed types wherever possible. When unavoidable, handle explicitly:**

```php
// ❌ Avoid: Mixed type without validation
public function processData(mixed $data): mixed
{
    return $data['key'] ?? null;
}

// ✅ Correct: Explicit type handling
public function processData(mixed $data): array
{
    if (!is_array($data)) {
        throw new InvalidArgumentException('Data must be an array');
    }
    
    $result = [];
    foreach ($data as $key => $value) {
        $result[(string) $key] = $value;
    }
    
    return $result;
}
```

### 3. Complete Type Coverage

**Every property, parameter, and return value must have explicit type information:**

```php
// ✅ Complete type coverage
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
    ) {}
}
```

## Property Type Annotations

### Basic Property Types

```php
// ✅ Correct: Complete property type annotations
final class ValidationConfig
{
    /**
     * @var array<ValidationScope>
     */
    private array $scopes;
    
    /**
     * @var array<string, mixed>
     */
    private array $options;
    
    private int $timeout;
    private bool $followRedirects;
    private ?string $userAgent;
}
```

### Complex Array Types

```php
// ✅ Correct: Detailed array shape definitions
final readonly class ValidationResult
{
    /**
     * @var array<array{url: string, file: string, reason: string}>
     */
    public array $broken;

    /**
     * @var array<string>
     */
    public array $files;

    /**
     * @var array<array{url: string, status: string, scope: string, is_valid: bool, response_time: float}>
     */
    public array $links;
}
```

### Nullable Types

```php
// ✅ Correct: Explicit nullable type handling
final class LinkValidationService
{
    public ?GitHubAnchorInterface $gitHubAnchorService = null;
    
    private ?string $lastError = null;
    private ?int $lastHttpCode = null;
}
```

## Method Documentation Requirements

### PHPDoc Block Standards

**Every method must have a complete PHPDoc block with:**

1. **Description**: Clear explanation of method purpose
2. **Parameters**: Type and description for each parameter
3. **Return Type**: Explicit return type documentation
4. **Throws**: All possible exceptions

```php
/**
 * Validate all links in a file and return a collection of validation results.
 *
 * @param string $filePath The path to the file to validate
 * @param ValidationConfig $config The validation configuration to use
 * @return ValidationResultCollection Collection of validation results for all links found
 * @throws SecurityException If the file path fails security validation
 * @throws RuntimeException If the file cannot be read
 */
public function validateFile(string $filePath, ValidationConfig $config): ValidationResultCollection
{
    // Implementation
}
```

### Generic Type Documentation

```php
/**
 * Validate multiple links and return a collection of validation results.
 *
 * @param array<string> $urls Array of URLs to validate
 * @param ValidationConfig $config The validation configuration to use
 * @return ValidationResultCollection Collection of validation results
 */
public function validateLinks(array $urls, ValidationConfig $config): ValidationResultCollection
{
    // Implementation
}
```

### Array Shape Documentation

```php
/**
 * Extract links from content with detailed metadata.
 *
 * @param string $content The content to extract links from
 * @return array<array{url: string, text: string, line: int}>
 */
public function extractLinks(string $content): array
{
    // Implementation
}
```

## ValueObject Standards

### Readonly ValueObjects

**Use readonly classes for immutable data structures:**

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
    ) {}
    
    public function getUrl(): string
    {
        return $this->url;
    }
    
    public function getStatus(): LinkStatus
    {
        return $this->status;
    }
}
```

### Factory Methods with Type Safety

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
```

### Array Conversion Methods

```php
/**
 * Convert to array representation.
 *
 * @return array<string, mixed>
 */
public function toArray(): array
{
    return [
        'url' => $this->url,
        'status' => $this->status->value,
        'scope' => $this->scope->value,
        'is_valid' => $this->isValid(),
        'is_broken' => $this->isBroken(),
        'error' => $this->error,
        'http_status_code' => $this->httpStatusCode,
        'redirect_url' => $this->redirectUrl,
        'response_time' => $this->responseTime,
        'severity' => $this->getSeverity(),
        'recommended_action' => $this->getRecommendedAction(),
        'metadata' => $this->metadata,
        'file_path' => $this->filePath,
    ];
}
```

## Service Layer Type Safety

### Interface Implementation

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
}
```

### Service Implementation

```php
final class LinkValidationService implements LinkValidationInterface
{
    public ?GitHubAnchorInterface $gitHubAnchorService = null;

    public function __construct(
        private readonly SecurityValidationInterface $security
    ) {}

    public function validateFile(string $filePath, ValidationConfig $config): ValidationResultCollection
    {
        // Type-safe implementation with explicit type checking
        $results = [];

        if (!file_exists($filePath)) {
            return ValidationResultCollection::fromArray([
                ValidationResult::create(
                    url: $filePath,
                    status: LinkStatus::BROKEN,
                    message: 'File not found'
                ),
            ]);
        }

        // Continue with type-safe implementation
    }
}
```

### Dependency Injection Type Safety

```php
final class LinkValidationService implements LinkValidationInterface
{
    public function __construct(
        private readonly SecurityValidationInterface $security,
        private readonly ?GitHubAnchorInterface $gitHubAnchorService = null
    ) {}
}
```

## Command Type Safety

### Command Properties

```php
final class ValidateCommand extends BaseValidationCommand
{
    /**
     * The signature of the command.
     */
    protected $signature = 'validate
                            {paths* : Paths to validate (files or directories)}
                            {--scope=all : Validation scope (internal, external, anchor, image, all)}
                            {--format=console : Output format (console, json, html, markdown)}';

    /**
     * The description of the command.
     */
    protected $description = 'Validate links in documentation files with comprehensive scope and format options';

    public function __construct(
        LinkValidationInterface $linkValidation,
        ReportingInterface $reporting
    ) {
        parent::__construct($linkValidation, $reporting);
    }
}
```

### Command Method Type Safety

```php
/**
 * Execute the console command.
 */
public function handle(): int
{
    try {
        // Validate command options using enum validation
        $this->validateCommandOptions();

        return match (true) {
            $this->option('interactive') => $this->handleInteractive(),
            default => $this->handleNonInteractive(),
        };
    } catch (Throwable $e) {
        return $this->handleValidationError($e);
    }
}

/**
 * Gather paths to validate with validation.
 *
 * @return array<string>
 */
private function gatherPaths(): array
{
    $paths = [];

    do {
        $path = text(
            label: 'Enter path to validate',
            placeholder: './docs',
            required: true,
            validate: fn (string $value): ?string => is_dir($value) || is_file($value)
                ? null
                : 'Path must exist'
        );

        $paths[] = $path;

        $addMore = confirm('Add another path?', false);
    } while ($addMore);

    return $paths;
}
```

## Exception Handling

### Exception Type Safety

```php
/**
 * Handle validation errors with proper type safety.
 */
private function handleValidationError(Throwable $e): int
{
    match (true) {
        $e instanceof SecurityException => $this->error("Security violation: {$e->getMessage()}"),
        $e instanceof ValidationException => $this->error("Validation error: {$e->getMessage()}"),
        $e instanceof RuntimeException => $this->error("Runtime error: {$e->getMessage()}"),
        default => $this->error("Unexpected error: {$e->getMessage()}"),
    };

    return self::FAILURE;
}
```

### Custom Exception Classes

```php
final class SecurityException extends ValidateLinksException
{
    public function __construct(
        string $message = '',
        int $code = 0,
        ?Throwable $previous = null
    ) {
        parent::__construct($message, $code, $previous);
    }
}
```

## Array Shape Definitions

### Complex Array Structures

```php
/**
 * @return array<string, array<array{url: string, text: string, line: int}>>
 */
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

### Nested Array Types

```php
/**
 * Get broken links by type (for aggregate results).
 *
 * @return array<string, array<array{url: string, file: string, reason: string}>>
 */
public function getBrokenLinksByType(): array
{
    $results = $this->metadata['results'] ?? [];
    $brokenByType = [];

    if (!is_array($results)) {
        return $brokenByType;
    }

    foreach ($results as $result) {
        if ($result instanceof self && !$result->isValid()) {
            $type = $result->getScope()->value;
            if (!isset($brokenByType[$type])) {
                $brokenByType[$type] = [];
            }
            $brokenByType[$type][] = [
                'url' => $result->getUrl(),
                'file' => 'unknown', // Would need file context
                'reason' => $result->getError() ?? 'Validation failed',
            ];
        }
    }

    return $brokenByType;
}
```

## Generic Types

### Collection Types

```php
/**
 * @template T
 */
final class ValidationResultCollection implements Countable, IteratorAggregate
{
    /**
     * @param ValidationResult[] $results
     */
    public function __construct(
        private array $results = []
    ) {}

    /**
     * @return ValidationResult[]
     */
    public function toValidationResultArray(): array
    {
        return $this->results;
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

### Factory Methods with Generics

```php
/**
 * Create collection from array of results.
 *
 * @param ValidationResult[] $results
 */
public static function fromArray(array $results): self
{
    return new self($results);
}
```

## Laravel Zero Specific Patterns

### Service Container Type Safety

```php
// ✅ Correct: Type-safe service resolution
public function __construct(
    LinkValidationInterface $linkValidation,
    ReportingInterface $reporting
) {
    parent::__construct($linkValidation, $reporting);
}

// ✅ Correct: Type-safe app() usage
$service = app(LinkValidationInterface::class);
expect($service)->toBeInstanceOf(LinkValidationInterface::class);
```

### Configuration Type Safety

```php
/**
 * Create validation configuration from array.
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
        cacheResults: is_bool($options['cache_results'] ?? null) ? $options['cache_results'] : true
    );
}
```

### Enum Usage Patterns

```php
// ✅ Correct: Type-safe enum usage
public function classifyLink(string $url): LinkType
{
    if (str_starts_with($url, '#')) {
        return LinkType::ANCHOR;
    }

    if (str_starts_with($url, 'http://') || str_starts_with($url, 'https://')) {
        return LinkType::EXTERNAL;
    }

    // Check if it's a cross-reference (internal link with anchor)
    if (str_contains($url, '#')) {
        return LinkType::CROSS_REFERENCE;
    }

    return LinkType::INTERNAL;
}
```

## Best Practices

### 1. Type Safety First

- Always start with the most restrictive types possible
- Use union types sparingly and only when necessary
- Prefer explicit type checking over type casting

### 2. Documentation Standards

- Every public method must have complete PHPDoc
- Array shapes must be explicitly defined
- Generic types should be documented where applicable

### 3. Error Handling

- Use typed exceptions for different error categories
- Provide meaningful error messages with context
- Handle edge cases explicitly

### 4. Performance Considerations

- Use readonly classes for immutable data
- Prefer typed arrays over generic arrays
- Use appropriate data structures for the use case

### 5. Maintenance

- Keep type annotations synchronized with implementation
- Update PHPDoc when method signatures change
- Use static analysis tools to verify type safety

## Common Patterns

### Type-Safe Array Processing

```php
/**
 * Process array data with explicit type validation.
 *
 * @param array<string, mixed> $data
 * @return array<string, string>
 */
private function processArrayData(array $data): array
{
    $result = [];
    
    foreach ($data as $key => $value) {
        if (!is_string($key)) {
            continue;
        }
        
        if (is_scalar($value)) {
            $result[$key] = (string) $value;
        } elseif (is_array($value)) {
            $result[$key] = json_encode($value) ?: '';
        } else {
            $result[$key] = '';
        }
    }
    
    return $result;
}
```

### Type-Safe Factory Pattern

```php
/**
 * Create instance from mixed data with type validation.
 *
 * @param array<string, mixed> $data
 */
public static function fromArray(array $data): self
{
    $url = $data['url'] ?? '';
    $metadata = $data['metadata'] ?? [];
    
    return new self(
        url: is_string($url) ? $url : '',
        status: isset($data['status']) ? 
            LinkStatus::from(is_string($data['status']) || is_int($data['status']) ? $data['status'] : '') : 
            LinkStatus::BROKEN,
        scope: isset($data['scope']) ? 
            ValidationScope::from(is_string($data['scope']) || is_int($data['scope']) ? $data['scope'] : '') : 
            ValidationScope::ALL,
        error: isset($data['error']) && (is_string($data['error']) || is_null($data['error'])) ? $data['error'] : null,
        responseTime: isset($data['response_time']) && (is_float($data['response_time']) || is_int($data['response_time'])) ? 
            (float) $data['response_time'] : 0.0,
        metadata: is_array($metadata) ? $metadata : []
    );
}
```

---

## Navigation

**← Previous:** [Static Analysis Standards](static-analysis.md) | **Next →** [Testing Standards](testing-standards.md)