# Advanced Troubleshooting Guides

**Version:** 1.0  
**Created:** 2025-07-16  
**Last Updated:** 2025-07-16  
**Scope:** Expert-level troubleshooting for complex Chinook project issues

## Table of Contents

1. [Overview](#1-overview)
2. [Advanced Database Troubleshooting](#2-advanced-database-troubleshooting)
3. [Complex Performance Issues](#3-complex-performance-issues)
4. [Filament Panel Deep Debugging](#4-filament-panel-deep-debugging)
5. [Package Integration Issues](#5-package-integration-issues)
6. [Production Environment Debugging](#6-production-environment-debugging)

## 1. Overview

This guide provides expert-level troubleshooting techniques for complex issues that may arise in the Chinook project, building upon the basic troubleshooting guide with advanced diagnostic methods.

### 1.1 Advanced Troubleshooting Philosophy

- **Systematic Approach:** Use structured debugging methodologies
- **Root Cause Analysis:** Identify underlying causes, not just symptoms
- **Performance Impact:** Consider performance implications of debugging
- **Educational Value:** Learn from complex problem-solving scenarios

### 1.2 Required Tools and Skills

```bash
# Advanced debugging tools setup
composer require --dev barryvdh/laravel-debugbar
composer require --dev spatie/laravel-ray
composer require --dev nunomaduro/collision

# System monitoring tools
sudo apt-get install htop iotop nethogs  # Linux
brew install htop                        # macOS

# Database analysis tools
sqlite3 database/database.sqlite ".schema"
sqlite3 database/database.sqlite "PRAGMA integrity_check;"
```

## 2. Advanced Database Troubleshooting

### 2.1 Complex Query Performance Analysis

```php
<?php

namespace App\Debug;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * Advanced Database Debugging Utilities
 * 
 * Provides comprehensive database performance analysis
 * and troubleshooting capabilities for complex issues.
 */
class DatabaseDebugger
{
    /**
     * Analyze query performance with detailed metrics
     */
    public static function analyzeQueryPerformance(callable $queryCallback, string $description = ''): array
    {
        // Clear any existing query log
        DB::flushQueryLog();
        DB::enableQueryLog();
        
        // Memory and time tracking
        $startTime = microtime(true);
        $startMemory = memory_get_usage(true);
        $startPeakMemory = memory_get_peak_usage(true);
        
        // Execute the query
        $result = $queryCallback();
        
        // Capture metrics
        $endTime = microtime(true);
        $endMemory = memory_get_usage(true);
        $endPeakMemory = memory_get_peak_usage(true);
        
        $queries = DB::getQueryLog();
        DB::disableQueryLog();
        
        $analysis = [
            'description' => $description,
            'execution_time_ms' => round(($endTime - $startTime) * 1000, 2),
            'memory_used_mb' => round(($endMemory - $startMemory) / 1024 / 1024, 2),
            'peak_memory_mb' => round(($endPeakMemory - $startPeakMemory) / 1024 / 1024, 2),
            'query_count' => count($queries),
            'queries' => [],
            'recommendations' => [],
        ];
        
        // Analyze each query
        foreach ($queries as $query) {
            $queryAnalysis = [
                'sql' => $query['query'],
                'bindings' => $query['bindings'],
                'time_ms' => $query['time'],
                'issues' => [],
                'suggestions' => [],
            ];
            
            // Detect common performance issues
            if ($query['time'] > 100) {
                $queryAnalysis['issues'][] = 'Slow query (>100ms)';
                $queryAnalysis['suggestions'][] = 'Consider adding indexes or optimizing query structure';
            }
            
            if (stripos($query['query'], 'SELECT *') !== false) {
                $queryAnalysis['issues'][] = 'Using SELECT *';
                $queryAnalysis['suggestions'][] = 'Specify only needed columns to reduce memory usage';
            }
            
            if (stripos($query['query'], 'LIKE') !== false && stripos($query['query'], '%') === 0) {
                $queryAnalysis['issues'][] = 'Leading wildcard in LIKE query';
                $queryAnalysis['suggestions'][] = 'Consider full-text search or restructure query';
            }
            
            $analysis['queries'][] = $queryAnalysis;
        }
        
        // Generate overall recommendations
        if ($analysis['execution_time_ms'] > 500) {
            $analysis['recommendations'][] = 'Total execution time is high - consider query optimization';
        }
        
        if ($analysis['memory_used_mb'] > 50) {
            $analysis['recommendations'][] = 'High memory usage - consider pagination or chunking';
        }
        
        if ($analysis['query_count'] > 10) {
            $analysis['recommendations'][] = 'High query count - possible N+1 problem, use eager loading';
        }
        
        return $analysis;
    }
    
    /**
     * Detect and analyze N+1 query problems
     */
    public static function detectN1Problems(): array
    {
        DB::flushQueryLog();
        DB::enableQueryLog();
        
        // Example: Load artists with albums (potential N+1)
        $artists = \App\Models\Chinook\Artist::limit(10)->get();
        
        $initialQueryCount = count(DB::getQueryLog());
        
        // This will trigger N+1 if not properly eager loaded
        foreach ($artists as $artist) {
            $albumCount = $artist->albums()->count();
        }
        
        $finalQueryCount = count(DB::getQueryLog());
        $queries = DB::getQueryLog();
        
        DB::disableQueryLog();
        
        $n1Analysis = [
            'initial_queries' => $initialQueryCount,
            'final_queries' => $finalQueryCount,
            'additional_queries' => $finalQueryCount - $initialQueryCount,
            'is_n1_problem' => ($finalQueryCount - $initialQueryCount) > 1,
            'queries' => array_slice($queries, $initialQueryCount),
            'solution' => 'Use eager loading: Artist::with("albums")->limit(10)->get()',
        ];
        
        return $n1Analysis;
    }
    
    /**
     * SQLite-specific optimization analysis
     */
    public static function analyzeSQLitePerformance(): array
    {
        $analysis = [
            'database_info' => [],
            'pragma_settings' => [],
            'table_analysis' => [],
            'index_analysis' => [],
            'recommendations' => [],
        ];
        
        // Get database information
        $dbInfo = DB::select('PRAGMA database_list');
        $analysis['database_info'] = $dbInfo;
        
        // Check important PRAGMA settings
        $pragmas = [
            'journal_mode',
            'synchronous',
            'cache_size',
            'temp_store',
            'mmap_size',
            'page_size',
        ];
        
        foreach ($pragmas as $pragma) {
            $result = DB::select("PRAGMA {$pragma}");
            $analysis['pragma_settings'][$pragma] = $result[0]->$pragma ?? 'unknown';
        }
        
        // Analyze table statistics
        $tables = DB::select("SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'chinook_%'");
        
        foreach ($tables as $table) {
            $tableName = $table->name;
            
            // Get table info
            $tableInfo = DB::select("PRAGMA table_info({$tableName})");
            $indexList = DB::select("PRAGMA index_list({$tableName})");
            
            $analysis['table_analysis'][$tableName] = [
                'columns' => count($tableInfo),
                'indexes' => count($indexList),
                'index_details' => $indexList,
            ];
        }
        
        // Generate recommendations based on analysis
        if ($analysis['pragma_settings']['journal_mode'] !== 'wal') {
            $analysis['recommendations'][] = 'Enable WAL mode for better concurrency: PRAGMA journal_mode=WAL';
        }
        
        if ((int)$analysis['pragma_settings']['cache_size'] < 10000) {
            $analysis['recommendations'][] = 'Increase cache size for better performance: PRAGMA cache_size=20000';
        }
        
        return $analysis;
    }
}
```

### 2.2 Database Corruption and Recovery

```bash
#!/bin/bash

# Advanced SQLite Database Recovery Script
# Use when database corruption is suspected

DATABASE_PATH="database/database.sqlite"
BACKUP_PATH="database/backup_$(date +%Y%m%d_%H%M%S).sqlite"

echo "Starting advanced SQLite database analysis and recovery..."

# 1. Create backup before any operations
echo "Creating backup: $BACKUP_PATH"
cp "$DATABASE_PATH" "$BACKUP_PATH"

# 2. Check database integrity
echo "Checking database integrity..."
sqlite3 "$DATABASE_PATH" "PRAGMA integrity_check;" > integrity_check.log

if grep -q "ok" integrity_check.log; then
    echo "✅ Database integrity check passed"
else
    echo "❌ Database corruption detected!"
    cat integrity_check.log
fi

# 3. Analyze database statistics
echo "Analyzing database statistics..."
sqlite3 "$DATABASE_PATH" << EOF
.output database_stats.log
PRAGMA database_list;
PRAGMA compile_options;
PRAGMA page_count;
PRAGMA page_size;
PRAGMA freelist_count;
PRAGMA schema_version;
PRAGMA user_version;
.output stdout
EOF

# 4. Check for foreign key violations
echo "Checking foreign key constraints..."
sqlite3 "$DATABASE_PATH" "PRAGMA foreign_key_check;" > fk_violations.log

if [ -s fk_violations.log ]; then
    echo "❌ Foreign key violations found:"
    cat fk_violations.log
else
    echo "✅ No foreign key violations"
fi

# 5. Vacuum and optimize if needed
echo "Optimizing database..."
sqlite3 "$DATABASE_PATH" << EOF
PRAGMA optimize;
VACUUM;
ANALYZE;
EOF

# 6. Re-check integrity after optimization
echo "Re-checking integrity after optimization..."
sqlite3 "$DATABASE_PATH" "PRAGMA integrity_check;"

echo "Database analysis complete. Check log files for details."
```

## 3. Complex Performance Issues

### 3.1 Memory Leak Detection and Analysis

```php
<?php

namespace App\Debug;

/**
 * Memory Leak Detection and Analysis
 * 
 * Advanced memory profiling for detecting and analyzing
 * memory leaks in long-running processes.
 */
class MemoryProfiler
{
    private array $snapshots = [];
    private array $objectCounts = [];
    
    /**
     * Take a memory snapshot for comparison
     */
    public function snapshot(string $label): void
    {
        $this->snapshots[$label] = [
            'timestamp' => microtime(true),
            'memory_usage' => memory_get_usage(true),
            'peak_memory' => memory_get_peak_usage(true),
            'object_count' => $this->getObjectCount(),
            'class_counts' => $this->getClassCounts(),
        ];
    }
    
    /**
     * Compare two snapshots to detect memory leaks
     */
    public function compare(string $before, string $after): array
    {
        if (!isset($this->snapshots[$before]) || !isset($this->snapshots[$after])) {
            throw new \InvalidArgumentException('Snapshot not found');
        }
        
        $beforeSnapshot = $this->snapshots[$before];
        $afterSnapshot = $this->snapshots[$after];
        
        $comparison = [
            'memory_difference' => $afterSnapshot['memory_usage'] - $beforeSnapshot['memory_usage'],
            'peak_difference' => $afterSnapshot['peak_memory'] - $beforeSnapshot['peak_memory'],
            'object_difference' => $afterSnapshot['object_count'] - $beforeSnapshot['object_count'],
            'time_elapsed' => $afterSnapshot['timestamp'] - $beforeSnapshot['timestamp'],
            'class_differences' => [],
            'potential_leaks' => [],
        ];
        
        // Compare class counts
        foreach ($afterSnapshot['class_counts'] as $class => $count) {
            $beforeCount = $beforeSnapshot['class_counts'][$class] ?? 0;
            $difference = $count - $beforeCount;
            
            if ($difference > 0) {
                $comparison['class_differences'][$class] = $difference;
                
                // Flag potential leaks (significant increases)
                if ($difference > 100 || ($beforeCount > 0 && $difference / $beforeCount > 0.5)) {
                    $comparison['potential_leaks'][] = [
                        'class' => $class,
                        'before' => $beforeCount,
                        'after' => $count,
                        'increase' => $difference,
                        'percentage' => $beforeCount > 0 ? round(($difference / $beforeCount) * 100, 2) : 'N/A',
                    ];
                }
            }
        }
        
        return $comparison;
    }
    
    /**
     * Profile a specific operation for memory usage
     */
    public function profileOperation(callable $operation, string $description = ''): array
    {
        $this->snapshot('before_operation');
        
        $startTime = microtime(true);
        $result = $operation();
        $endTime = microtime(true);
        
        $this->snapshot('after_operation');
        
        $profile = $this->compare('before_operation', 'after_operation');
        $profile['description'] = $description;
        $profile['execution_time'] = $endTime - $startTime;
        $profile['result'] = $result;
        
        return $profile;
    }
    
    private function getObjectCount(): int
    {
        if (function_exists('gc_status')) {
            $status = gc_status();
            return $status['roots'] ?? 0;
        }
        
        return 0;
    }
    
    private function getClassCounts(): array
    {
        $counts = [];
        
        if (function_exists('get_declared_classes')) {
            foreach (get_declared_classes() as $class) {
                if (class_exists($class)) {
                    $reflection = new \ReflectionClass($class);
                    if ($reflection->isInstantiable()) {
                        $counts[$class] = 0; // Placeholder - actual counting would require more complex logic
                    }
                }
            }
        }
        
        return $counts;
    }
    
    /**
     * Generate memory usage report
     */
    public function generateReport(): string
    {
        $report = "Memory Profiling Report\n";
        $report .= "======================\n\n";
        
        foreach ($this->snapshots as $label => $snapshot) {
            $report .= "Snapshot: {$label}\n";
            $report .= "  Memory Usage: " . $this->formatBytes($snapshot['memory_usage']) . "\n";
            $report .= "  Peak Memory: " . $this->formatBytes($snapshot['peak_memory']) . "\n";
            $report .= "  Object Count: {$snapshot['object_count']}\n";
            $report .= "  Timestamp: " . date('Y-m-d H:i:s', $snapshot['timestamp']) . "\n\n";
        }
        
        return $report;
    }
    
    private function formatBytes(int $bytes): string
    {
        $units = ['B', 'KB', 'MB', 'GB'];
        $bytes = max($bytes, 0);
        $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
        $pow = min($pow, count($units) - 1);
        
        $bytes /= pow(1024, $pow);
        
        return round($bytes, 2) . ' ' . $units[$pow];
    }
}

// Usage example for detecting memory leaks in batch operations
$profiler = new MemoryProfiler();

$profiler->snapshot('start');

// Simulate batch processing that might leak memory
for ($i = 0; $i < 1000; $i++) {
    $artists = \App\Models\Chinook\Artist::with('albums')->limit(10)->get();
    
    // Process artists...
    
    if ($i % 100 === 0) {
        $profiler->snapshot("iteration_{$i}");
        
        if ($i > 0) {
            $comparison = $profiler->compare("iteration_" . ($i - 100), "iteration_{$i}");
            
            if ($comparison['memory_difference'] > 10 * 1024 * 1024) { // 10MB increase
                Log::warning('Potential memory leak detected', $comparison);
            }
        }
    }
    
    // Force garbage collection
    if ($i % 50 === 0) {
        gc_collect_cycles();
    }
}

$profiler->snapshot('end');
echo $profiler->generateReport();
```

## 4. Filament Panel Deep Debugging

### 4.1 Component Lifecycle Debugging

```php
<?php

namespace App\Debug;

use Filament\Forms\Components\Component;
use Filament\Tables\Table;
use Illuminate\Support\Facades\Log;

/**
 * Filament Component Debugger
 *
 * Advanced debugging utilities for Filament components,
 * forms, tables, and resource lifecycle issues.
 */
class FilamentDebugger
{
    /**
     * Debug form component state and validation
     */
    public static function debugFormComponent(Component $component): array
    {
        $debug = [
            'component_type' => get_class($component),
            'name' => $component->getName(),
            'state' => $component->getState(),
            'is_required' => $component->isRequired(),
            'is_disabled' => $component->isDisabled(),
            'is_hidden' => $component->isHidden(),
            'validation_rules' => $component->getValidationRules(),
            'validation_attributes' => $component->getValidationAttributes(),
            'errors' => [],
            'relationships' => [],
        ];

        // Check for validation errors
        if (method_exists($component, 'getValidationMessages')) {
            $debug['errors'] = $component->getValidationMessages();
        }

        // Check for relationship components
        if (method_exists($component, 'getRelationship')) {
            try {
                $relationship = $component->getRelationship();
                $debug['relationships'] = [
                    'name' => $relationship->getRelationName(),
                    'type' => get_class($relationship),
                    'foreign_key' => method_exists($relationship, 'getForeignKeyName')
                        ? $relationship->getForeignKeyName()
                        : 'N/A',
                ];
            } catch (\Exception $e) {
                $debug['relationships']['error'] = $e->getMessage();
            }
        }

        return $debug;
    }

    /**
     * Debug table query and performance
     */
    public static function debugTableQuery(Table $table): array
    {
        $debug = [
            'model' => $table->getModel(),
            'query_info' => [],
            'columns' => [],
            'filters' => [],
            'actions' => [],
            'performance' => [],
        ];

        // Analyze table columns
        foreach ($table->getColumns() as $column) {
            $debug['columns'][] = [
                'name' => $column->getName(),
                'type' => get_class($column),
                'is_searchable' => $column->isSearchable(),
                'is_sortable' => $column->isSortable(),
                'is_toggleable' => $column->isToggleable(),
            ];
        }

        // Analyze filters
        foreach ($table->getFilters() as $filter) {
            $debug['filters'][] = [
                'name' => $filter->getName(),
                'type' => get_class($filter),
                'is_active' => method_exists($filter, 'isActive') ? $filter->isActive() : false,
            ];
        }

        // Analyze actions
        foreach ($table->getActions() as $action) {
            $debug['actions'][] = [
                'name' => $action->getName(),
                'type' => get_class($action),
                'is_hidden' => $action->isHidden(),
                'is_disabled' => $action->isDisabled(),
            ];
        }

        return $debug;
    }

    /**
     * Debug resource authorization issues
     */
    public static function debugResourceAuthorization(string $resourceClass, $record = null): array
    {
        $debug = [
            'resource' => $resourceClass,
            'record' => $record ? get_class($record) . ':' . $record->getKey() : null,
            'policies' => [],
            'permissions' => [],
            'user' => auth()->user() ? auth()->user()->toArray() : null,
        ];

        if (!class_exists($resourceClass)) {
            $debug['error'] = 'Resource class does not exist';
            return $debug;
        }

        $resource = new $resourceClass();
        $model = $resource->getModel();

        // Check policy methods
        $policyMethods = ['viewAny', 'view', 'create', 'update', 'delete', 'restore', 'forceDelete'];

        foreach ($policyMethods as $method) {
            try {
                if ($record && in_array($method, ['view', 'update', 'delete', 'restore', 'forceDelete'])) {
                    $result = auth()->user()?->can($method, $record);
                } else {
                    $result = auth()->user()?->can($method, $model);
                }

                $debug['policies'][$method] = $result ?? false;
            } catch (\Exception $e) {
                $debug['policies'][$method] = 'Error: ' . $e->getMessage();
            }
        }

        // Check Spatie permissions if available
        if (auth()->user() && method_exists(auth()->user(), 'getAllPermissions')) {
            $debug['permissions'] = auth()->user()->getAllPermissions()->pluck('name')->toArray();
        }

        return $debug;
    }
}
```

### 4.2 Resource Performance Profiling

```php
<?php

namespace App\Debug;

use Filament\Resources\Resource;
use Illuminate\Support\Facades\DB;

/**
 * Filament Resource Performance Profiler
 *
 * Profiles Filament resource operations to identify
 * performance bottlenecks and optimization opportunities.
 */
class FilamentResourceProfiler
{
    /**
     * Profile resource index page performance
     */
    public static function profileResourceIndex(string $resourceClass, array $filters = []): array
    {
        if (!class_exists($resourceClass)) {
            throw new \InvalidArgumentException("Resource class {$resourceClass} does not exist");
        }

        $resource = new $resourceClass();
        $model = $resource->getModel();

        DB::flushQueryLog();
        DB::enableQueryLog();

        $startTime = microtime(true);
        $startMemory = memory_get_usage(true);

        // Simulate resource index query
        $query = $model::query();

        // Apply filters if provided
        foreach ($filters as $filter => $value) {
            if (method_exists($model, 'scope' . ucfirst($filter))) {
                $query->{$filter}($value);
            } else {
                $query->where($filter, $value);
            }
        }

        // Execute paginated query (typical for index pages)
        $results = $query->paginate(25);

        $endTime = microtime(true);
        $endMemory = memory_get_usage(true);

        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        return [
            'resource' => $resourceClass,
            'model' => get_class($model),
            'execution_time_ms' => round(($endTime - $startTime) * 1000, 2),
            'memory_used_mb' => round(($endMemory - $startMemory) / 1024 / 1024, 2),
            'query_count' => count($queries),
            'record_count' => $results->total(),
            'queries' => $queries,
            'recommendations' => static::generateRecommendations($queries, $results),
        ];
    }

    /**
     * Profile resource form performance
     */
    public static function profileResourceForm(string $resourceClass, $recordId = null): array
    {
        $resource = new $resourceClass();
        $model = $resource->getModel();

        DB::flushQueryLog();
        DB::enableQueryLog();

        $startTime = microtime(true);
        $startMemory = memory_get_usage(true);

        // Load record with relationships (typical for edit forms)
        if ($recordId) {
            $record = $model::with($resource->getFormRelationships())->findOrFail($recordId);
        } else {
            $record = new $model();
        }

        $endTime = microtime(true);
        $endMemory = memory_get_usage(true);

        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        return [
            'resource' => $resourceClass,
            'operation' => $recordId ? 'edit' : 'create',
            'record_id' => $recordId,
            'execution_time_ms' => round(($endTime - $startTime) * 1000, 2),
            'memory_used_mb' => round(($endMemory - $startMemory) / 1024 / 1024, 2),
            'query_count' => count($queries),
            'queries' => $queries,
            'relationships_loaded' => $resource->getFormRelationships(),
        ];
    }

    private static function generateRecommendations(array $queries, $results): array
    {
        $recommendations = [];

        // Check for N+1 queries
        if (count($queries) > 5) {
            $recommendations[] = 'High query count detected - consider eager loading relationships';
        }

        // Check for slow queries
        $slowQueries = array_filter($queries, fn($query) => $query['time'] > 100);
        if (!empty($slowQueries)) {
            $recommendations[] = 'Slow queries detected - consider adding indexes or optimizing queries';
        }

        // Check for SELECT * queries
        $selectAllQueries = array_filter($queries, fn($query) => stripos($query['query'], 'SELECT *') !== false);
        if (!empty($selectAllQueries)) {
            $recommendations[] = 'SELECT * queries found - specify only needed columns';
        }

        // Check pagination efficiency
        if (method_exists($results, 'total') && $results->total() > 10000) {
            $recommendations[] = 'Large dataset detected - consider implementing cursor pagination';
        }

        return $recommendations;
    }
}
```

## 5. Package Integration Issues

### 5.1 Laravel Taxonomy Package Debugging

```php
<?php

namespace App\Debug;

use Aliziodev\LaravelTaxonomy\Models\Taxonomy;
use Aliziodev\LaravelTaxonomy\Models\Term;
use App\Models\Chinook\Artist;

/**
 * Laravel Taxonomy Package Debugger
 *
 * Specialized debugging for aliziodev/laravel-taxonomy
 * package integration issues and relationship problems.
 */
class TaxonomyDebugger
{
    /**
     * Debug taxonomy relationships for a model
     */
    public static function debugModelTaxonomies($model): array
    {
        $debug = [
            'model' => get_class($model),
            'model_id' => $model->getKey(),
            'has_taxonomy_trait' => in_array('Aliziodev\LaravelTaxonomy\Traits\HasTaxonomy', class_uses_recursive($model)),
            'taxonomies' => [],
            'terms' => [],
            'pivot_data' => [],
            'issues' => [],
        ];

        if (!$debug['has_taxonomy_trait']) {
            $debug['issues'][] = 'Model does not use HasTaxonomy trait';
            return $debug;
        }

        try {
            // Get all taxonomies for this model
            $taxonomies = $model->taxonomies;

            foreach ($taxonomies as $taxonomy) {
                $debug['taxonomies'][] = [
                    'id' => $taxonomy->id,
                    'name' => $taxonomy->name,
                    'slug' => $taxonomy->slug,
                    'type' => $taxonomy->type ?? 'N/A',
                ];
            }

            // Get all terms for this model
            $terms = $model->terms;

            foreach ($terms as $term) {
                $debug['terms'][] = [
                    'id' => $term->id,
                    'name' => $term->name,
                    'slug' => $term->slug,
                    'taxonomy_id' => $term->taxonomy_id,
                    'parent_id' => $term->parent_id,
                ];
            }

            // Check pivot table data
            $pivotData = DB::table('taxables')
                ->where('taxable_type', get_class($model))
                ->where('taxable_id', $model->getKey())
                ->get();

            $debug['pivot_data'] = $pivotData->toArray();

        } catch (\Exception $e) {
            $debug['issues'][] = 'Error loading taxonomy data: ' . $e->getMessage();
        }

        return $debug;
    }

    /**
     * Validate taxonomy package installation and configuration
     */
    public static function validateTaxonomyPackage(): array
    {
        $validation = [
            'package_installed' => false,
            'migrations_run' => false,
            'config_published' => false,
            'models_exist' => false,
            'database_tables' => [],
            'issues' => [],
            'recommendations' => [],
        ];

        // Check if package is installed
        try {
            $validation['package_installed'] = class_exists('Aliziodev\LaravelTaxonomy\TaxonomyServiceProvider');
        } catch (\Exception $e) {
            $validation['issues'][] = 'Package not properly installed: ' . $e->getMessage();
        }

        // Check if migrations have been run
        $requiredTables = ['taxonomies', 'terms', 'taxables'];

        foreach ($requiredTables as $table) {
            try {
                $exists = DB::getSchemaBuilder()->hasTable($table);
                $validation['database_tables'][$table] = $exists;

                if (!$exists) {
                    $validation['issues'][] = "Required table '{$table}' does not exist";
                }
            } catch (\Exception $e) {
                $validation['database_tables'][$table] = false;
                $validation['issues'][] = "Error checking table '{$table}': " . $e->getMessage();
            }
        }

        $validation['migrations_run'] = !in_array(false, $validation['database_tables']);

        // Check if models exist and are accessible
        try {
            $taxonomyModel = new Taxonomy();
            $termModel = new Term();
            $validation['models_exist'] = true;
        } catch (\Exception $e) {
            $validation['models_exist'] = false;
            $validation['issues'][] = 'Taxonomy models not accessible: ' . $e->getMessage();
        }

        // Check configuration
        $configPath = config_path('taxonomy.php');
        $validation['config_published'] = file_exists($configPath);

        if (!$validation['config_published']) {
            $validation['recommendations'][] = 'Publish package configuration: php artisan vendor:publish --provider="Aliziodev\LaravelTaxonomy\TaxonomyServiceProvider"';
        }

        if (!$validation['migrations_run']) {
            $validation['recommendations'][] = 'Run package migrations: php artisan migrate';
        }

        return $validation;
    }

    /**
     * Debug taxonomy hierarchy issues
     */
    public static function debugTaxonomyHierarchy(int $taxonomyId): array
    {
        $debug = [
            'taxonomy_id' => $taxonomyId,
            'taxonomy' => null,
            'root_terms' => [],
            'hierarchy_issues' => [],
            'orphaned_terms' => [],
            'circular_references' => [],
        ];

        try {
            $taxonomy = Taxonomy::findOrFail($taxonomyId);
            $debug['taxonomy'] = [
                'id' => $taxonomy->id,
                'name' => $taxonomy->name,
                'slug' => $taxonomy->slug,
            ];

            // Get all terms for this taxonomy
            $terms = Term::where('taxonomy_id', $taxonomyId)->get();

            // Find root terms (no parent)
            $rootTerms = $terms->whereNull('parent_id');
            $debug['root_terms'] = $rootTerms->pluck('name', 'id')->toArray();

            // Check for orphaned terms (parent doesn't exist)
            foreach ($terms as $term) {
                if ($term->parent_id && !$terms->where('id', $term->parent_id)->first()) {
                    $debug['orphaned_terms'][] = [
                        'id' => $term->id,
                        'name' => $term->name,
                        'missing_parent_id' => $term->parent_id,
                    ];
                }
            }

            // Check for circular references
            foreach ($terms as $term) {
                if (static::hasCircularReference($term, $terms)) {
                    $debug['circular_references'][] = [
                        'id' => $term->id,
                        'name' => $term->name,
                    ];
                }
            }

        } catch (\Exception $e) {
            $debug['hierarchy_issues'][] = 'Error analyzing hierarchy: ' . $e->getMessage();
        }

        return $debug;
    }

    private static function hasCircularReference($term, $allTerms, $visited = []): bool
    {
        if (in_array($term->id, $visited)) {
            return true; // Circular reference detected
        }

        if (!$term->parent_id) {
            return false; // Reached root, no circular reference
        }

        $parent = $allTerms->where('id', $term->parent_id)->first();
        if (!$parent) {
            return false; // Parent doesn't exist, not circular but orphaned
        }

        $visited[] = $term->id;
        return static::hasCircularReference($parent, $allTerms, $visited);
    }
}
```

## 6. Production Environment Debugging

### 6.1 Log Analysis and Monitoring

```bash
#!/bin/bash

# Advanced Log Analysis Script for Production Debugging
# Analyzes Laravel logs for patterns, errors, and performance issues

LOG_PATH="storage/logs"
REPORT_PATH="debug_reports"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$REPORT_PATH"

echo "Starting advanced log analysis for Chinook application..."

# 1. Error Pattern Analysis
echo "Analyzing error patterns..."
grep -r "ERROR" "$LOG_PATH" | \
    sed 's/.*ERROR: //' | \
    sort | uniq -c | sort -nr > "$REPORT_PATH/error_patterns_$DATE.txt"

# 2. Performance Issue Detection
echo "Detecting performance issues..."
grep -r "Slow query\|Memory limit\|Execution time" "$LOG_PATH" | \
    sort > "$REPORT_PATH/performance_issues_$DATE.txt"

# 3. Database Query Analysis
echo "Analyzing database queries..."
grep -r "select\|insert\|update\|delete" "$LOG_PATH" | \
    grep -i "chinook" | \
    awk '{print $NF}' | sort | uniq -c | sort -nr > "$REPORT_PATH/query_patterns_$DATE.txt"

# 4. User Activity Analysis
echo "Analyzing user activity..."
grep -r "User\|Login\|Logout" "$LOG_PATH" | \
    grep -o '\[.*\]' | sort | uniq -c > "$REPORT_PATH/user_activity_$DATE.txt"

# 5. Generate Summary Report
echo "Generating summary report..."
cat > "$REPORT_PATH/summary_$DATE.txt" << EOF
Chinook Application Log Analysis Report
Generated: $(date)

=== TOP ERRORS ===
$(head -10 "$REPORT_PATH/error_patterns_$DATE.txt")

=== PERFORMANCE ISSUES ===
$(wc -l < "$REPORT_PATH/performance_issues_$DATE.txt") performance issues detected

=== TOP DATABASE QUERIES ===
$(head -10 "$REPORT_PATH/query_patterns_$DATE.txt")

=== USER ACTIVITY SUMMARY ===
$(head -10 "$REPORT_PATH/user_activity_$DATE.txt")
EOF

echo "Log analysis complete. Reports saved in $REPORT_PATH/"
```

---

## Navigation

- **Previous:** [Performance Benchmarking Data](./700-performance-benchmarking-data.md)
- **Next:** [Documentation Maintenance Automation](./900-documentation-maintenance-automation.md)
- **Index:** [Chinook Documentation Index](./000-chinook-index.md)

## Related Documentation

- [Troubleshooting Guide](./300-troubleshooting-guide.md)
- [Error Handling Guide](./200-error-handling-guide.md)

---

**Last Updated:** 2025-07-16  
**Maintainer:** Technical Documentation Team  
**Source:** [GitHub Repository](https://github.com/s-a-c/chinook)
