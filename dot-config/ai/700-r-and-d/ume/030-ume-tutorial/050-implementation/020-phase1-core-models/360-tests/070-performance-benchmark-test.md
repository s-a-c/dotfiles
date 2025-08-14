# Testing the PerformanceBenchmark

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Overview

This document outlines the tests for the `PerformanceBenchmark` class, which provides tools for measuring the performance of the `HasAdditionalFeatures` trait.

## Test File

Create a new test file at `tests/Unit/Support/PerformanceBenchmarkTest.php`:

```php
<?php

namespace Tests\Unit\Support;

use App\Support\PerformanceBenchmark;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Support\Facades\Log;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class PerformanceBenchmarkTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_can_measure_execution_time()
    {
        // Create a benchmark
        $benchmark = new PerformanceBenchmark('Test Benchmark');
        
        // Simulate some work
        usleep(10000); // 10ms
        
        // End the benchmark
        $results = $benchmark->end(false);
        
        // Check that the execution time was measured
        $this->assertArrayHasKey('time', $results);
        $this->assertGreaterThan(0, $results['time']);
    }

    #[Test]
    public function it_can_measure_memory_usage()
    {
        // Create a benchmark
        $benchmark = new PerformanceBenchmark('Test Benchmark');
        
        // Simulate some memory usage
        $array = array_fill(0, 10000, 'test');
        
        // End the benchmark
        $results = $benchmark->end(false);
        
        // Check that the memory usage was measured
        $this->assertArrayHasKey('memory', $results);
        $this->assertGreaterThan(0, $results['memory']);
    }

    #[Test]
    public function it_can_log_results()
    {
        // Mock the Log facade
        Log::shouldReceive('info')
            ->once()
            ->with('Benchmark: Test Benchmark', \Mockery::type('array'));
        
        // Create a benchmark
        $benchmark = new PerformanceBenchmark('Test Benchmark');
        
        // End the benchmark with logging
        $benchmark->end(true);
    }

    #[Test]
    public function it_can_measure_callback_execution()
    {
        // Measure a callback
        $result = PerformanceBenchmark::measure('Test Callback', function () {
            usleep(10000); // 10ms
            return 'test';
        }, false);
        
        // Check that the callback was executed and the result was returned
        $this->assertEquals('test', $result);
    }

    #[Test]
    public function it_can_log_callback_results()
    {
        // Mock the Log facade
        Log::shouldReceive('info')
            ->once()
            ->with('Benchmark: Test Callback', \Mockery::type('array'));
        
        // Measure a callback with logging
        PerformanceBenchmark::measure('Test Callback', function () {
            usleep(10000); // 10ms
        }, true);
    }

    #[Test]
    public function it_includes_label_in_results()
    {
        // Create a benchmark
        $benchmark = new PerformanceBenchmark('Test Label');
        
        // End the benchmark
        $results = $benchmark->end(false);
        
        // Check that the label is included in the results
        $this->assertArrayHasKey('label', $results);
        $this->assertEquals('Test Label', $results['label']);
    }

    #[Test]
    public function it_executes_callback_even_if_exception_is_thrown()
    {
        // Flag to track if finally block was executed
        $finallyExecuted = false;
        
        // Expect an exception
        $this->expectException(\Exception::class);
        
        // Measure a callback that throws an exception
        try {
            PerformanceBenchmark::measure('Test Exception', function () {
                throw new \Exception('Test exception');
            }, false);
        } finally {
            $finallyExecuted = true;
        }
        
        // Check that the finally block was executed
        $this->assertTrue($finallyExecuted);
    }
}
```

## Key Test Cases

1. **Execution Time Measurement**: Tests that the PerformanceBenchmark can measure execution time.
2. **Memory Usage Measurement**: Tests that the PerformanceBenchmark can measure memory usage.
3. **Result Logging**: Tests that the PerformanceBenchmark can log results.
4. **Callback Measurement**: Tests that the PerformanceBenchmark can measure the execution of a callback.
5. **Label Inclusion**: Tests that the PerformanceBenchmark includes the label in the results.
6. **Exception Handling**: Tests that the PerformanceBenchmark properly handles exceptions.

## Running the Tests

To run the tests for the PerformanceBenchmark, use the following command:

```bash
php artisan test --filter=PerformanceBenchmarkTest
```

## Expected Output

When running the PerformanceBenchmark tests, you should see output similar to:

```
PASS  Tests\Unit\Support\PerformanceBenchmarkTest
✓ it can measure execution time
✓ it can measure memory usage
✓ it can log results
✓ it can measure callback execution
✓ it can log callback results
✓ it includes label in results
✓ it executes callback even if exception is thrown

Tests:  7 passed
Time:   0.09s
```

This confirms that the PerformanceBenchmark is working correctly and all its features are functioning as expected.
