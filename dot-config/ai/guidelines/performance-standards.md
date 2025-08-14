# Performance Standards

## Overview

This document establishes comprehensive performance requirements and benchmarking guidelines for maintaining optimal performance while achieving **PHPStan Level 10 compliance**. These standards ensure that type safety enhancements do not compromise application performance and establish measurable benchmarks for continuous monitoring.

## Table of Contents

1. [Performance Principles](#performance-principles)
2. [Benchmarking Standards](#benchmarking-standards)
3. [Memory Management](#memory-management)
4. [Concurrent Processing](#concurrent-processing)
5. [File Processing Performance](#file-processing-performance)
6. [Static Analysis Performance](#static-analysis-performance)
7. [Database and I/O Performance](#database-and-io-performance)
8. [Monitoring and Alerting](#monitoring-and-alerting)
9. [Performance Testing](#performance-testing)
10. [Optimization Techniques](#optimization-techniques)

## Performance Principles

### Core Performance Standards

1. **Type Safety Without Performance Cost**: PHPStan Level 10 compliance should not degrade runtime performance
2. **Scalable Architecture**: System performance should scale linearly with input size
3. **Memory Efficiency**: Optimal memory usage with proper cleanup and garbage collection
4. **Concurrent Processing**: Leverage parallelism for I/O-bound operations
5. **Caching Strategy**: Intelligent caching to reduce redundant computations

### Performance Targets

**Response Time Targets**:
- Single link validation: < 100ms (internal), < 5s (external)
- File processing: < 1s per 100 links
- Report generation: < 2s for 1000 results
- Static analysis: < 30s for full codebase

**Throughput Targets**:
- Concurrent link validation: 50+ links/second
- File processing: 10+ files/second
- Memory usage: < 256MB for typical workloads
- CPU utilization: < 80% during normal operations

**Scalability Targets**:
- Linear scaling up to 10,000 links
- Graceful degradation beyond capacity limits
- Configurable concurrency limits
- Resource-aware processing

## Benchmarking Standards

### Performance Test Suite

**Core Performance Tests**:

```php
<?php

declare(strict_types=1);

use App\Services\Contracts\LinkValidationInterface;
use App\Services\ValueObjects\ValidationConfig;
use App\Enums\ValidationScope;

describe('Performance Benchmarks', function (): void {
    beforeEach(function (): void {
        $this->service = app(LinkValidationInterface::class);
        $this->config = ValidationConfig::create([
            'scopes' => [ValidationScope::ALL],
            'concurrent_requests' => 10,
            'timeout' => 30,
        ]);
    });

    it('validates 100 internal links within time limit', function (): void {
        $urls = [];
        for ($i = 0; $i < 100; $i++) {
            $urls[] = "tests/Fixtures/sample-{$i}.md";
        }

        $startTime = microtime(true);
        $startMemory = memory_get_usage(true);

        $results = $this->service->validateLinks($urls, $this->config);

        $executionTime = microtime(true) - $startTime;
        $memoryUsed = memory_get_usage(true) - $startMemory;

        expect($results->count())->toBe(100)
            ->and($executionTime)->toBeLessThan(10.0) // 10 second limit
            ->and($memoryUsed)->toBeLessThan(50 * 1024 * 1024); // 50MB limit
    })->group('performance');

    it('processes large file efficiently', function (): void {
        // Generate large test file
        $linkCount = 1000;
        $testContent = "# Large Test Document\n\n";
        
        for ($i = 1; $i <= $linkCount; $i++) {
            $testContent .= "[Link {$i}](internal-file-{$i}.md)\n";
        }

        $testFile = 'tests/temp/large-document.md';
        file_put_contents($testFile, $testContent);

        $startTime = microtime(true);
        $startMemory = memory_get_usage(true);

        $results = $this->service->validateFile($testFile, $this->config);

        $executionTime = microtime(true) - $startTime;
        $memoryUsed = memory_get_usage(true) - $startMemory;
        $peakMemory = memory_get_peak_usage(true);

        expect($results->count())->toBe($linkCount)
            ->and($executionTime)->toBeLessThan(60.0) // 1 minute limit
            ->and($memoryUsed)->toBeLessThan(100 * 1024 * 1024) // 100MB limit
            ->and($peakMemory)->toBeLessThan(256 * 1024 * 1024); // 256MB peak limit

        // Cleanup
        if (file_exists($testFile)) {
            unlink($testFile);
        }
    })->group('performance');

    it('maintains performance under concurrent load', function (): void {
        $urls = array_fill(0, 50, 'https://httpbin.org/status/200');
        
        $startTime = microtime(true);
        
        $results = $this->service->validateLinks($urls, ValidationConfig::create([
            'scopes' => [ValidationScope::EXTERNAL],
            'concurrent_requests' => 10,
            'timeout' => 10,
        ]));
        
        $executionTime = microtime(true) - $startTime;
        $throughput = count($urls) / $executionTime;

        expect($results->count())->toBe(50)
            ->and($throughput)->toBeGreaterThan(5.0); // 5 links/second minimum
    })->group('performance', 'external');
});
```

### Benchmark Execution

**Performance Test Commands**:

```bash
# Run all performance tests
./vendor/bin/pest --group=performance

# Run specific performance categories
./vendor/bin/pest --group=performance,memory
./vendor/bin/pest --group=performance,concurrent

# Generate performance report
./vendor/bin/pest --group=performance --log-junit=reports/performance.xml

# Memory profiling
php -d memory_limit=512M ./vendor/bin/pest --group=performance --verbose
```

### Performance Metrics Collection

```php
final class PerformanceMetrics
{
    /**
     * @var array<string, array<string, float>>
     */
    private static array $metrics = [];

    public static function startTimer(string $operation): void
    {
        self::$metrics[$operation]['start_time'] = microtime(true);
        self::$metrics[$operation]['start_memory'] = memory_get_usage(true);
    }

    public static function endTimer(string $operation): array
    {
        $endTime = microtime(true);
        $endMemory = memory_get_usage(true);
        
        $executionTime = $endTime - (self::$metrics[$operation]['start_time'] ?? $endTime);
        $memoryUsed = $endMemory - (self::$metrics[$operation]['start_memory'] ?? $endMemory);
        
        return [
            'execution_time' => $executionTime,
            'memory_used' => $memoryUsed,
            'peak_memory' => memory_get_peak_usage(true),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public static function getMetrics(): array
    {
        return self::$metrics;
    }
}
```

## Memory Management

### Memory Usage Standards

**Memory Limits**:
- Normal operation: < 128MB
- Large file processing: < 256MB
- Concurrent processing: < 512MB
- Peak memory usage: < 1GB

**Memory Management Patterns**:

```php
final class MemoryEfficientLinkValidation
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
        $chunkSize = 1000; // Process 1000 lines at a time
        $buffer = [];

        try {
            while (!feof($handle)) {
                $line = fgets($handle);
                if ($line === false) {
                    break;
                }

                $buffer[] = $line;

                if (count($buffer) >= $chunkSize) {
                    $chunkResults = $this->processChunk($buffer, $config);
                    $results = array_merge($results, $chunkResults);
                    
                    // Clear buffer to free memory
                    $buffer = [];
                    
                    // Force garbage collection periodically
                    if (count($results) % 10000 === 0) {
                        gc_collect_cycles();
                    }
                }
            }

            // Process remaining buffer
            if (!empty($buffer)) {
                $chunkResults = $this->processChunk($buffer, $config);
                $results = array_merge($results, $chunkResults);
            }

        } finally {
            fclose($handle);
        }

        return ValidationResultCollection::fromArray($results);
    }

    /**
     * Process chunk of lines with memory cleanup.
     *
     * @param array<string> $lines
     * @return ValidationResult[]
     */
    private function processChunk(array $lines, ValidationConfig $config): array
    {
        $results = [];
        $content = implode('', $lines);
        
        $links = $this->extractLinks($content);
        
        foreach ($links as $link) {
            $result = $this->validateSingleLink($link['url'], $config);
            $results[] = $result;
        }
        
        // Clear local variables
        unset($content, $links);
        
        return $results;
    }
}
```

### Memory Monitoring

```php
final class MemoryMonitor
{
    public static function logMemoryUsage(string $operation): void
    {
        $current = memory_get_usage(true);
        $peak = memory_get_peak_usage(true);
        
        error_log(sprintf(
            'Memory Usage [%s]: Current: %s, Peak: %s',
            $operation,
            self::formatBytes($current),
            self::formatBytes($peak)
        ));
    }

    private static function formatBytes(int $bytes): string
    {
        $units = ['B', 'KB', 'MB', 'GB'];
        $bytes = max($bytes, 0);
        $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
        $pow = min($pow, count($units) - 1);
        
        $bytes /= (1 << (10 * $pow));
        
        return round($bytes, 2) . ' ' . $units[$pow];
    }
}
```

## Concurrent Processing

### Concurrency Standards

**Concurrent Processing Limits**:
- Default concurrent requests: 10
- Maximum concurrent requests: 50
- Configurable per operation type
- Resource-aware scaling

**Concurrent Validation Implementation**:

```php
final class ConcurrentValidationService
{
    private int $maxConcurrent;
    private LinkValidationInterface $linkValidation;

    public function __construct(
        LinkValidationInterface $linkValidation,
        int $maxConcurrent = 10
    ) {
        $this->linkValidation = $linkValidation;
        $this->maxConcurrent = min($maxConcurrent, 50); // Cap at 50
    }

    /**
     * Validate URLs concurrently with proper resource management.
     *
     * @param array<string> $urls
     */
    public function validateConcurrently(array $urls, ValidationConfig $config): ValidationResultCollection
    {
        $chunks = array_chunk($urls, $this->maxConcurrent);
        $allResults = [];

        foreach ($chunks as $chunk) {
            $chunkResults = $this->processChunkConcurrently($chunk, $config);
            $allResults = array_merge($allResults, $chunkResults);
            
            // Brief pause between chunks to prevent overwhelming target servers
            usleep(100000); // 100ms
        }

        return ValidationResultCollection::fromArray($allResults);
    }

    /**
     * Process a chunk of URLs concurrently.
     *
     * @param array<string> $urls
     * @return ValidationResult[]
     */
    private function processChunkConcurrently(array $urls, ValidationConfig $config): array
    {
        $results = [];
        $startTime = microtime(true);

        // Simulate concurrent processing (in real implementation, use proper async library)
        foreach ($urls as $url) {
            $result = $this->linkValidation->validateLink($url, $config);
            $results[] = $result;
        }

        $executionTime = microtime(true) - $startTime;
        
        // Log performance metrics
        error_log(sprintf(
            'Concurrent chunk processed: %d URLs in %.2fs (%.2f URLs/sec)',
            count($urls),
            $executionTime,
            count($urls) / $executionTime
        ));

        return $results;
    }
}
```

### Rate Limiting

```php
final class RateLimiter
{
    private array $requests = [];
    private int $maxRequestsPerSecond;

    public function __construct(int $maxRequestsPerSecond = 10)
    {
        $this->maxRequestsPerSecond = $maxRequestsPerSecond;
    }

    public function throttle(): void
    {
        $now = microtime(true);
        
        // Remove requests older than 1 second
        $this->requests = array_filter(
            $this->requests,
            fn($timestamp) => $now - $timestamp < 1.0
        );

        // If we're at the limit, wait
        if (count($this->requests) >= $this->maxRequestsPerSecond) {
            $oldestRequest = min($this->requests);
            $waitTime = 1.0 - ($now - $oldestRequest);
            
            if ($waitTime > 0) {
                usleep((int)($waitTime * 1000000));
            }
        }

        $this->requests[] = microtime(true);
    }
}
```

## File Processing Performance

### Large File Handling

**File Processing Standards**:
- Stream processing for files > 10MB
- Chunk-based processing for memory efficiency
- Progress reporting for long operations
- Graceful handling of file system errors

**Streaming File Processor**:

```php
final class StreamingFileProcessor
{
    private const CHUNK_SIZE = 8192; // 8KB chunks

    /**
     * Process large files using streaming to minimize memory usage.
     */
    public function processLargeFile(string $filePath, ValidationConfig $config): ValidationResultCollection
    {
        $fileSize = filesize($filePath);
        if ($fileSize === false) {
            throw new RuntimeException("Unable to determine file size: {$filePath}");
        }

        $handle = fopen($filePath, 'r');
        if ($handle === false) {
            throw new RuntimeException("Unable to open file: {$filePath}");
        }

        $results = [];
        $buffer = '';
        $processedBytes = 0;
        $lineNumber = 0;

        try {
            while (!feof($handle)) {
                $chunk = fread($handle, self::CHUNK_SIZE);
                if ($chunk === false) {
                    break;
                }

                $buffer .= $chunk;
                $processedBytes += strlen($chunk);

                // Process complete lines
                while (($pos = strpos($buffer, "\n")) !== false) {
                    $line = substr($buffer, 0, $pos + 1);
                    $buffer = substr($buffer, $pos + 1);
                    $lineNumber++;

                    $lineResults = $this->processLine($line, $lineNumber, $config);
                    $results = array_merge($results, $lineResults);
                }

                // Report progress for large files
                if ($fileSize > 1024 * 1024) { // 1MB+
                    $progress = ($processedBytes / $fileSize) * 100;
                    if ($processedBytes % (100 * 1024) === 0) { // Every 100KB
                        error_log(sprintf('Processing progress: %.1f%%', $progress));
                    }
                }
            }

            // Process remaining buffer
            if (!empty($buffer)) {
                $lineResults = $this->processLine($buffer, ++$lineNumber, $config);
                $results = array_merge($results, $lineResults);
            }

        } finally {
            fclose($handle);
        }

        return ValidationResultCollection::fromArray($results);
    }

    /**
     * Process a single line for links.
     *
     * @return ValidationResult[]
     */
    private function processLine(string $line, int $lineNumber, ValidationConfig $config): array
    {
        $links = $this->extractLinksFromLine($line, $lineNumber);
        $results = [];

        foreach ($links as $link) {
            $result = $this->validateLink($link['url'], $config);
            $results[] = $result;
        }

        return $results;
    }
}
```

## Static Analysis Performance

### PHPStan Performance Optimization

**PHPStan Configuration for Performance**:

```neon
# phpstan.neon - Performance optimized
parameters:
    level: 10
    
    # Performance settings
    parallel:
        maximumNumberOfProcesses: 8
        minimumNumberOfJobsPerProcess: 2
        processTimeout: 120.0
    
    # Memory optimization
    memoryLimitFile: .phpstan-memory-limit
    
    # Cache optimization
    tmpDir: reports/phpstan
    
    # Exclude unnecessary paths for faster analysis
    excludePaths:
        - vendor
        - storage/logs
        - storage/framework
        - bootstrap/cache
        - node_modules
```

**Performance Monitoring for Static Analysis**:

```bash
#!/bin/bash
# scripts/monitor-phpstan-performance.sh

echo "Monitoring PHPStan performance..."

# Clear cache for accurate timing
rm -rf reports/phpstan

# Run with timing
time ./vendor/bin/phpstan analyse --level=10 --memory-limit=2G

# Check memory usage
echo "Peak memory usage:"
cat .phpstan-memory-limit 2>/dev/null || echo "No memory limit file found"

# Cache size
echo "Cache size:"
du -sh reports/phpstan 2>/dev/null || echo "No cache directory found"
```

### Tool Performance Benchmarks

```php
describe('Static Analysis Performance', function (): void {
    it('completes PHPStan analysis within time limit', function (): void {
        $startTime = microtime(true);
        
        // Run PHPStan programmatically (simplified example)
        $command = './vendor/bin/phpstan analyse --level=10 --no-progress --error-format=json app/';
        $output = shell_exec($command);
        
        $executionTime = microtime(true) - $startTime;
        
        expect($output)->not->toBeNull()
            ->and($executionTime)->toBeLessThan(60.0); // 1 minute limit
    })->group('performance', 'static-analysis');

    it('formats code efficiently with Pint', function (): void {
        $startTime = microtime(true);
        
        $command = './vendor/bin/pint --test';
        $exitCode = 0;
        $output = [];
        exec($command, $output, $exitCode);
        
        $executionTime = microtime(true) - $startTime;
        
        expect($exitCode)->toBe(0)
            ->and($executionTime)->toBeLessThan(30.0); // 30 second limit
    })->group('performance', 'formatting');
});
```

## Database and I/O Performance

### File System Performance

**I/O Performance Standards**:
- File reading: > 10MB/s
- Concurrent file access: < 100ms latency
- Directory traversal: < 1s for 1000 files
- Network requests: < 5s timeout

**Optimized File Operations**:

```php
final class OptimizedFileOperations
{
    /**
     * Read file with performance monitoring.
     */
    public function readFileOptimized(string $filePath): string
    {
        $startTime = microtime(true);
        
        if (!is_readable($filePath)) {
            throw new RuntimeException("File not readable: {$filePath}");
        }

        $fileSize = filesize($filePath);
        if ($fileSize === false) {
            throw new RuntimeException("Unable to determine file size: {$filePath}");
        }

        // Use appropriate reading strategy based on file size
        if ($fileSize > 10 * 1024 * 1024) { // 10MB+
            return $this->readLargeFile($filePath);
        }

        $content = file_get_contents($filePath);
        if ($content === false) {
            throw new RuntimeException("Unable to read file: {$filePath}");
        }

        $executionTime = microtime(true) - $startTime;
        $throughput = $fileSize / $executionTime / 1024 / 1024; // MB/s

        if ($throughput < 5.0) { // Less than 5 MB/s
            error_log("Slow file read detected: {$filePath} ({$throughput:.2f} MB/s)");
        }

        return $content;
    }

    private function readLargeFile(string $filePath): string
    {
        $handle = fopen($filePath, 'r');
        if ($handle === false) {
            throw new RuntimeException("Unable to open file: {$filePath}");
        }

        $content = '';
        try {
            while (!feof($handle)) {
                $chunk = fread($handle, 8192);
                if ($chunk === false) {
                    break;
                }
                $content .= $chunk;
            }
        } finally {
            fclose($handle);
        }

        return $content;
    }
}
```

### Network Performance

```php
final class OptimizedHttpClient
{
    private array $connectionPool = [];
    private RateLimiter $rateLimiter;

    public function __construct()
    {
        $this->rateLimiter = new RateLimiter(10); // 10 requests/second
    }

    /**
     * Validate URL with performance optimization.
     */
    public function validateUrl(string $url, int $timeout = 10): ValidationResult
    {
        $startTime = microtime(true);
        
        // Apply rate limiting
        $this->rateLimiter->throttle();

        try {
            $context = stream_context_create([
                'http' => [
                    'method' => 'HEAD',
                    'timeout' => $timeout,
                    'user_agent' => 'validate-links/1.0',
                    'follow_location' => true,
                    'max_redirects' => 5,
                ],
            ]);

            $headers = @get_headers($url, true, $context);
            $responseTime = microtime(true) - $startTime;

            if ($headers === false) {
                return ValidationResult::failure(
                    $url,
                    ValidationScope::EXTERNAL,
                    LinkStatus::BROKEN,
                    'Failed to connect',
                    responseTime: $responseTime
                );
            }

            // Parse status code
            $statusLine = is_array($headers) && isset($headers[0]) && is_string($headers[0]) ? $headers[0] : '';
            preg_match('/HTTP\/\d\.\d\s+(\d+)/', $statusLine, $matches);
            $httpCode = isset($matches[1]) ? (int) $matches[1] : 0;

            if ($httpCode >= 200 && $httpCode < 400) {
                return ValidationResult::success(
                    $url,
                    ValidationScope::EXTERNAL,
                    $httpCode,
                    $responseTime
                );
            }

            return ValidationResult::failure(
                $url,
                ValidationScope::EXTERNAL,
                $this->mapHttpStatusToLinkStatus($httpCode),
                "HTTP {$httpCode}",
                $httpCode,
                responseTime: $responseTime
            );

        } catch (Exception $e) {
            $responseTime = microtime(true) - $startTime;
            
            return ValidationResult::failure(
                $url,
                ValidationScope::EXTERNAL,
                LinkStatus::BROKEN,
                $e->getMessage(),
                responseTime: $responseTime
            );
        }
    }

    private function mapHttpStatusToLinkStatus(int $httpCode): LinkStatus
    {
        return match (true) {
            $httpCode === 404 => LinkStatus::NOT_FOUND,
            $httpCode === 403 => LinkStatus::FORBIDDEN,
            $httpCode >= 500 => LinkStatus::BROKEN,
            default => LinkStatus::BROKEN,
        };
    }
}
```

## Monitoring and Alerting

### Performance Monitoring System

```php
final class PerformanceMonitor
{
    private static array $metrics = [];
    private static array $thresholds = [
        'link_validation_time' => 5.0,      // 5 seconds
        'file_processing_time' => 60.0,     // 1 minute
        'memory_usage' => 256 * 1024 * 1024, // 256MB
        'concurrent_requests' => 50,         // 50 concurrent
    ];

    public static function recordMetric(string $name, float $value, array $context = []): void
    {
        $timestamp = microtime(true);
        
        self::$metrics[] = [
            'name' => $name,
            'value' => $value,
            'timestamp' => $timestamp,
            'context' => $context,
        ];

        // Check thresholds
        if (isset(self::$thresholds[$name]) && $value > self::$thresholds[$name]) {
            self::alertThresholdExceeded($name, $value, self::$thresholds[$name], $context);
        }
    }

    private static function alertThresholdExceeded(string $metric, float $value, float $threshold, array $context): void
    {
        $message = sprintf(
            'Performance threshold exceeded: %s = %.2f (threshold: %.2f)',
            $metric,
            $value,
            $threshold
        );

        if (!empty($context)) {
            $message .= ' Context: ' . json_encode($context);
        }

        error_log($message);
        
        // In production, send to monitoring system
        // self::sendToMonitoringSystem($metric, $value, $threshold, $context);
    }

    /**
     * @return array<array<string, mixed>>
     */
    public static function getMetrics(): array
    {
        return self::$metrics;
    }

    public static function generateReport(): string
    {
        $report = "Performance Report\n";
        $report .= "==================\n\n";

        $metricsByName = [];
        foreach (self::$metrics as $metric) {
            $metricsByName[$metric['name']][] = $metric['value'];
        }

        foreach ($metricsByName as $name => $values) {
            $count = count($values);
            $avg = array_sum($values) / $count;
            $min = min($values);
            $max = max($values);

            $report .= sprintf(
                "%s: Count=%d, Avg=%.2f, Min=%.2f, Max=%.2f\n",
                $name,
                $count,
                $avg,
                $min,
                $max
            );
        }

        return $report;
    }
}
```

### Automated Performance Alerts

```yaml
# .github/workflows/performance-alerts.yml
name: Performance Monitoring

on:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours
  workflow_dispatch:

jobs:
  performance-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.4'
          
      - name: Install dependencies
        run: composer install --prefer-dist --no-progress
        
      - name: Run performance benchmarks
        run: |
          ./vendor/bin/pest --group=performance --log-junit=performance-results.xml
          
      - name: Analyze performance results
        run: |
          php scripts/analyze-performance.php performance-results.xml
          
      - name: Alert on performance regression
        if: failure()
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: 'Performance Regression Detected',
              body: 'Automated performance tests have detected a regression. Please investigate.',
              labels: ['performance', 'bug']
            });
```

## Performance Testing

### Load Testing

```php
describe('Load Testing', function (): void {
    it('handles high concurrent load', function (): void {
        $urls = array_fill(0, 100, 'https://httpbin.org/status/200');
        $service = app(LinkValidationInterface::class);
        
        $startTime = microtime(true);
        $startMemory = memory_get_usage(true);
        
        $results = $service->validateLinks($urls, ValidationConfig::create([
            'scopes' => [ValidationScope::EXTERNAL],
            'concurrent_requests' => 20,
            'timeout' => 10,
        ]));
        
        $executionTime = microtime(true) - $startTime;
        $memoryUsed = memory_get_usage(true) - $startMemory;
        $throughput = count($urls) / $executionTime;
        
        expect($results->count())->toBe(100)
            ->and($executionTime)->toBeLessThan(30.0) // 30 second limit
            ->and($throughput)->toBeGreaterThan(3.0) // 3 URLs/second minimum
            ->and($memoryUsed)->toBeLessThan(100 * 1024 * 1024); // 100MB limit
    })->group('performance', 'load');

    it('maintains performance under memory pressure', function (): void {
        // Simulate memory pressure
        $largeArray = array_fill(0, 100000, str_repeat('x', 1000));
        
        $service = app(LinkValidationInterface::class);
        $config = ValidationConfig::create(['scopes' => [ValidationScope::INTERNAL]]);
        
        $startTime = microtime(true);
        
        $result = $service->validateLink('tests/Fixtures/sample.md', $config);
        
        $executionTime = microtime(true) - $startTime;
        
        expect($result)->toBeInstanceOf(ValidationResult::class)
            ->and($executionTime)->toBeLessThan(5.0); // Should still complete quickly
            
        // Clean up
        unset($largeArray);
    })->group('performance', 'memory');
});
```

### Stress Testing

```php
describe('Stress Testing', function (): void {
    it('handles resource exhaustion gracefully', function (): void {
        $service = app(LinkValidationInterface::class);
        
        // Create many concurrent validation requests
        $urls = array_fill(0, 1000, 'tests/Fixtures/sample.md');
        
        $startTime = microtime(true);
        
        try {
            $results = $service->validateLinks($urls, ValidationConfig::create([
                'scopes' => [ValidationScope::INTERNAL],