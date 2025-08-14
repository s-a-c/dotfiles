# Performance Optimizations

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Optimize the performance of the HasAdditionalFeatures trait by implementing lazy loading for heavy features and caching configuration values.

## Overview

While the HasAdditionalFeatures trait provides powerful functionality, it can impact performance if not optimized properly. In this section, we'll implement several optimizations to improve performance:

1. Lazy loading for heavy features
2. Configuration caching
3. Query optimization
4. Benchmarking tools

## Step 1: Implement Lazy Loading for Heavy Features

Some features, such as search indexing and activity logging, can be resource-intensive. By implementing lazy loading, we can defer the initialization of these features until they're actually needed:

```php
<?php

namespace App\Models\Traits;

// ... existing imports ...

trait HasAdditionalFeatures
{
    // ... existing trait implementation ...

    /**
     * Flag to track if searchable has been initialized.
     *
     * @var bool
     */
    protected bool $searchableInitialized = false;

    /**
     * Flag to track if activity logging has been initialized.
     *
     * @var bool
     */
    protected bool $activityLoggingInitialized = false;

    /**
     * Initialize searchable functionality.
     *
     * @return void
     */
    protected function initializeSearchable(): void
    {
        if ($this->shouldBeSearchable() && !$this->searchableInitialized) {
            // Initialize searchable functionality
            $this->searchableInitialized = true;
        }
    }

    /**
     * Initialize activity logging functionality.
     *
     * @return void
     */
    protected function initializeActivityLogging(): void
    {
        if ($this->isFeatureEnabled('activity_log') && !$this->activityLoggingInitialized) {
            // Initialize activity logging functionality
            $this->activityLoggingInitialized = true;
        }
    }

    /**
     * Override the toSearchableArray method to implement lazy loading.
     *
     * @return array
     */
    public function toSearchableArray(): array
    {
        $this->initializeSearchable();
        
        // ... existing implementation ...
    }

    /**
     * Override the getActivitylogOptions method to implement lazy loading.
     *
     * @return LogOptions
     */
    public function getActivitylogOptions(): LogOptions
    {
        $this->initializeActivityLogging();
        
        // ... existing implementation ...
    }
}
```

## Step 2: Add Configuration Caching

Repeatedly accessing configuration values can be expensive. By caching these values, we can reduce the number of configuration lookups:

```php
<?php

namespace App\Models\Traits;

// ... existing imports ...

trait HasAdditionalFeatures
{
    // ... existing trait implementation ...

    /**
     * Configuration cache.
     *
     * @var array
     */
    protected static array $configCache = [];

    /**
     * Get a configuration value with caching.
     *
     * @param string $key
     * @param mixed $default
     * @return mixed
     */
    protected static function getConfig(string $key, $default = null)
    {
        $cacheKey = static::class . '::' . $key;
        
        if (!isset(static::$configCache[$cacheKey])) {
            static::$configCache[$cacheKey] = FeatureManager::getConfiguration($key, static::class) ?: $default;
        }
        
        return static::$configCache[$cacheKey];
    }

    /**
     * Clear the configuration cache.
     *
     * @return void
     */
    public static function clearConfigCache(): void
    {
        static::$configCache = [];
    }

    /**
     * Get the ULID column name with caching.
     *
     * @return string
     */
    protected static function getUlidColumn(): string
    {
        return static::getConfig('ulid.column', 'ulid');
    }

    /**
     * Get the translatable attributes with caching.
     *
     * @return array
     */
    protected function getTranslatableAttributes(): array
    {
        return static::getConfig('translatable.attributes', ['name', 'slug']);
    }

    // ... update other methods to use getConfig ...
}
```

## Step 3: Optimize Database Queries

Let's optimize database queries by implementing eager loading and reducing unnecessary queries:

```php
<?php

namespace App\Models\Traits;

// ... existing imports ...

trait HasAdditionalFeatures
{
    // ... existing trait implementation ...

    /**
     * Get the creator relationship with eager loading optimization.
     *
     * @return BelongsTo
     */
    public function creator(): BelongsTo
    {
        $userModel = static::getConfig('user_tracking.user_model', '\\App\\Models\\User');
        $createdByColumn = static::getConfig('user_tracking.columns.created_by', 'created_by');
        
        return $this->belongsTo($userModel, $createdByColumn)->withDefault([
            'name' => 'Unknown User',
        ]);
    }

    /**
     * Get the updater relationship with eager loading optimization.
     *
     * @return BelongsTo
     */
    public function updater(): BelongsTo
    {
        $userModel = static::getConfig('user_tracking.user_model', '\\App\\Models\\User');
        $updatedByColumn = static::getConfig('user_tracking.columns.updated_by', 'updated_by');
        
        return $this->belongsTo($userModel, $updatedByColumn)->withDefault([
            'name' => 'Unknown User',
        ]);
    }

    /**
     * Get the deleter relationship with eager loading optimization.
     *
     * @return BelongsTo
     */
    public function deleter(): BelongsTo
    {
        $userModel = static::getConfig('user_tracking.user_model', '\\App\\Models\\User');
        $deletedByColumn = static::getConfig('user_tracking.columns.deleted_by', 'deleted_by');
        
        return $this->belongsTo($userModel, $deletedByColumn)->withDefault([
            'name' => 'Unknown User',
        ]);
    }

    /**
     * Define the relationships that should be eager loaded by default.
     *
     * @return array
     */
    public function getDefaultEagerLoads(): array
    {
        $eagerLoads = [];
        
        // Add creator, updater, and deleter if user tracking is enabled
        if ($this->isFeatureEnabled('user_tracking')) {
            $eagerLoads[] = 'creator';
            $eagerLoads[] = 'updater';
            
            if ($this->isFeatureEnabled('soft_deletes')) {
                $eagerLoads[] = 'deleter';
            }
        }
        
        // Add tags if tags is enabled
        if ($this->isFeatureEnabled('tags')) {
            $eagerLoads[] = 'tags';
        }
        
        return $eagerLoads;
    }
}
```

## Step 4: Add Performance Benchmarks

Let's add benchmarking tools to measure the performance of the HasAdditionalFeatures trait:

```php
<?php

namespace App\Support;

use Illuminate\Support\Facades\Log;

class PerformanceBenchmark
{
    /**
     * The start time of the benchmark.
     *
     * @var float
     */
    protected float $startTime;

    /**
     * The start memory usage of the benchmark.
     *
     * @var int
     */
    protected int $startMemory;

    /**
     * The label for the benchmark.
     *
     * @var string
     */
    protected string $label;

    /**
     * Create a new benchmark instance.
     *
     * @param string $label
     */
    public function __construct(string $label)
    {
        $this->label = $label;
        $this->startTime = microtime(true);
        $this->startMemory = memory_get_usage();
    }

    /**
     * End the benchmark and return the results.
     *
     * @param bool $log
     * @return array
     */
    public function end(bool $log = true): array
    {
        $endTime = microtime(true);
        $endMemory = memory_get_usage();
        
        $results = [
            'label' => $this->label,
            'time' => $endTime - $this->startTime,
            'memory' => $endMemory - $this->startMemory,
        ];
        
        if ($log) {
            Log::info("Benchmark: {$this->label}", $results);
        }
        
        return $results;
    }

    /**
     * Create a new benchmark and execute a callback.
     *
     * @param string $label
     * @param callable $callback
     * @param bool $log
     * @return mixed
     */
    public static function measure(string $label, callable $callback, bool $log = true)
    {
        $benchmark = new static($label);
        
        try {
            return $callback();
        } finally {
            $benchmark->end($log);
        }
    }
}
```

Now, let's add benchmarking to the HasAdditionalFeatures trait:

```php
<?php

namespace App\Models\Traits;

use App\Support\PerformanceBenchmark;
// ... existing imports ...

trait HasAdditionalFeatures
{
    // ... existing trait implementation ...

    /**
     * Flag to enable/disable benchmarking.
     *
     * @var bool
     */
    protected static bool $benchmarkingEnabled = false;

    /**
     * Enable benchmarking.
     *
     * @return void
     */
    public static function enableBenchmarking(): void
    {
        static::$benchmarkingEnabled = true;
    }

    /**
     * Disable benchmarking.
     *
     * @return void
     */
    public static function disableBenchmarking(): void
    {
        static::$benchmarkingEnabled = false;
    }

    /**
     * Execute a callback with benchmarking.
     *
     * @param string $label
     * @param callable $callback
     * @return mixed
     */
    protected static function benchmark(string $label, callable $callback)
    {
        if (static::$benchmarkingEnabled) {
            return PerformanceBenchmark::measure($label, $callback);
        }
        
        return $callback();
    }

    /**
     * Override the toSearchableArray method to add benchmarking.
     *
     * @return array
     */
    public function toSearchableArray(): array
    {
        return static::benchmark('toSearchableArray', function () {
            $this->initializeSearchable();
            
            // ... existing implementation ...
        });
    }

    /**
     * Override the getActivitylogOptions method to add benchmarking.
     *
     * @return LogOptions
     */
    public function getActivitylogOptions(): LogOptions
    {
        return static::benchmark('getActivitylogOptions', function () {
            $this->initializeActivityLogging();
            
            // ... existing implementation ...
        });
    }
}
```

## Step 5: Create a Performance Testing Command

Let's create a command to test the performance of the HasAdditionalFeatures trait:

```php
<?php

namespace App\Console\Commands;

use App\Models\Traits\HasAdditionalFeatures;
use App\Support\PerformanceBenchmark;
use Illuminate\Console\Command;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\File;

class TestAdditionalFeaturesPerformance extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'additional-features:benchmark {--iterations=100} {--output=storage/logs/benchmark.json}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Test the performance of the HasAdditionalFeatures trait';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $iterations = (int) $this->option('iterations');
        $outputPath = $this->option('output');
        
        $this->info("Running performance benchmark with {$iterations} iterations...");
        
        // Find all models that use the HasAdditionalFeatures trait
        $models = $this->findModelsWithTrait();
        
        if ($models->isEmpty()) {
            $this->error('No models found with the HasAdditionalFeatures trait.');
            return Command::FAILURE;
        }
        
        $this->info("Found " . $models->count() . " models with the HasAdditionalFeatures trait.");
        
        // Enable benchmarking for all models
        $models->each(function ($model) {
            $model::enableBenchmarking();
        });
        
        // Run the benchmark
        $results = $this->runBenchmark($models, $iterations);
        
        // Disable benchmarking for all models
        $models->each(function ($model) {
            $model::disableBenchmarking();
        });
        
        // Save the results
        $this->saveResults($results, $outputPath);
        
        $this->info("Benchmark completed. Results saved to {$outputPath}.");
        
        return Command::SUCCESS;
    }

    /**
     * Find all models that use the HasAdditionalFeatures trait.
     *
     * @return Collection
     */
    protected function findModelsWithTrait(): Collection
    {
        $models = collect();
        
        // Get all PHP files in the app/Models directory
        $files = File::allFiles(app_path('Models'));
        
        foreach ($files as $file) {
            $className = 'App\\Models\\' . str_replace(
                ['/', '.php'],
                ['\\', ''],
                $file->getRelativePathname()
            );
            
            // Check if the class exists and uses the HasAdditionalFeatures trait
            if (class_exists($className)) {
                $reflection = new \ReflectionClass($className);
                
                if ($reflection->isSubclassOf(Model::class) && $this->usesTrait($reflection, HasAdditionalFeatures::class)) {
                    $models->push($className);
                }
            }
        }
        
        return $models;
    }

    /**
     * Check if a class uses a trait.
     *
     * @param \ReflectionClass $reflection
     * @param string $trait
     * @return bool
     */
    protected function usesTrait(\ReflectionClass $reflection, string $trait): bool
    {
        $traits = $reflection->getTraitNames();
        
        if (in_array($trait, $traits)) {
            return true;
        }
        
        // Check parent classes
        $parent = $reflection->getParentClass();
        
        if ($parent) {
            return $this->usesTrait($parent, $trait);
        }
        
        return false;
    }

    /**
     * Run the benchmark.
     *
     * @param Collection $models
     * @param int $iterations
     * @return array
     */
    protected function runBenchmark(Collection $models, int $iterations): array
    {
        $results = [];
        
        foreach ($models as $model) {
            $this->info("Benchmarking {$model}...");
            
            $modelResults = [
                'model' => $model,
                'operations' => [],
            ];
            
            // Test creating a model
            $createResults = PerformanceBenchmark::measure("{$model}::create", function () use ($model, $iterations) {
                $times = [];
                $memories = [];
                
                for ($i = 0; $i < $iterations; $i++) {
                    $benchmark = new PerformanceBenchmark("{$model}::create iteration {$i}");
                    $model::create($this->getFakeAttributes($model));
                    $result = $benchmark->end(false);
                    
                    $times[] = $result['time'];
                    $memories[] = $result['memory'];
                }
                
                return [
                    'average_time' => array_sum($times) / count($times),
                    'average_memory' => array_sum($memories) / count($memories),
                    'min_time' => min($times),
                    'max_time' => max($times),
                    'min_memory' => min($memories),
                    'max_memory' => max($memories),
                ];
            }, false);
            
            $modelResults['operations']['create'] = $createResults;
            
            // Test finding a model
            $findResults = PerformanceBenchmark::measure("{$model}::find", function () use ($model, $iterations) {
                $times = [];
                $memories = [];
                
                $instance = $model::first();
                
                if (!$instance) {
                    return null;
                }
                
                for ($i = 0; $i < $iterations; $i++) {
                    $benchmark = new PerformanceBenchmark("{$model}::find iteration {$i}");
                    $model::find($instance->id);
                    $result = $benchmark->end(false);
                    
                    $times[] = $result['time'];
                    $memories[] = $result['memory'];
                }
                
                return [
                    'average_time' => array_sum($times) / count($times),
                    'average_memory' => array_sum($memories) / count($memories),
                    'min_time' => min($times),
                    'max_time' => max($times),
                    'min_memory' => min($memories),
                    'max_memory' => max($memories),
                ];
            }, false);
            
            if ($findResults) {
                $modelResults['operations']['find'] = $findResults;
            }
            
            // Add more operations as needed...
            
            $results[] = $modelResults;
        }
        
        return $results;
    }

    /**
     * Get fake attributes for a model.
     *
     * @param string $model
     * @return array
     */
    protected function getFakeAttributes(string $model): array
    {
        // This is a simple implementation. In a real application, you would use factories.
        return [
            'name' => 'Test ' . uniqid(),
            'email' => 'test_' . uniqid() . '@example.com',
            'password' => bcrypt('password'),
        ];
    }

    /**
     * Save the benchmark results.
     *
     * @param array $results
     * @param string $outputPath
     * @return void
     */
    protected function saveResults(array $results, string $outputPath): void
    {
        $directory = dirname($outputPath);
        
        if (!File::exists($directory)) {
            File::makeDirectory($directory, 0755, true);
        }
        
        File::put($outputPath, json_encode($results, JSON_PRETTY_PRINT));
    }
}
```

## Benefits of Performance Optimizations

These performance optimizations provide several benefits:

1. **Reduced Resource Usage**: Lazy loading ensures that heavy features are only initialized when needed.
2. **Faster Configuration Access**: Configuration caching reduces the number of configuration lookups.
3. **Optimized Database Queries**: Query optimization reduces the number of database queries.
4. **Performance Insights**: Benchmarking tools provide insights into the performance of the HasAdditionalFeatures trait.
5. **Better Scalability**: These optimizations make the HasAdditionalFeatures trait more scalable for large applications.

## Next Steps

Now that we've implemented performance optimizations, we can move on to adding advanced feature enhancements such as an event system, middleware for feature toggling, and enhanced user tracking. Let's continue to [Advanced Feature Enhancements](./091-advanced-feature-enhancements.md).
