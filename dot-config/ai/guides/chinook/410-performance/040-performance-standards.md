# Performance Standards

**Version:** 1.0  
**Created:** 2025-07-16  
**Last Updated:** 2025-07-16  
**Scope:** Performance targets and standards for Chinook project

## Table of Contents

1. [Overview](#1-overview)
2. [Performance Targets](#2-performance-targets)
3. [Measurement Standards](#3-measurement-standards)
4. [Optimization Guidelines](#4-optimization-guidelines)
5. [Monitoring and Alerting](#5-monitoring-and-alerting)
6. [Performance Testing](#6-performance-testing)

## 1. Overview

This document establishes performance standards for the Chinook project, ensuring optimal user experience and system efficiency across all components.

### 1.1 Performance Philosophy

- **Sub-100ms Interactive Response:** All user interactions complete within 100ms
- **Educational Focus:** Performance optimizations serve learning objectives
- **Scalable Patterns:** Code patterns support future growth
- **Measurable Standards:** All targets are quantifiable and testable

### 1.2 Scope of Standards

- **Frontend Performance:** Page load times, interactivity, visual stability
- **Backend Performance:** API response times, database queries, caching
- **Database Performance:** Query execution times, indexing strategies
- **Resource Utilization:** Memory usage, CPU consumption, storage efficiency

## 2. Performance Targets

### 2.1 Frontend Performance Targets

```javascript
// Core Web Vitals Targets (WCAG 2.1 AA Compliant)
const performanceTargets = {
    // Largest Contentful Paint - Visual loading performance
    LCP: {
        target: '2.5s',
        threshold: 'good',
        description: 'Main content visible within 2.5 seconds'
    },
    
    // First Input Delay - Interactivity performance
    FID: {
        target: '100ms',
        threshold: 'good',
        description: 'Page responds to user input within 100ms'
    },
    
    // Cumulative Layout Shift - Visual stability
    CLS: {
        target: '0.1',
        threshold: 'good',
        description: 'Minimal unexpected layout shifts'
    },
    
    // First Contentful Paint - Initial loading
    FCP: {
        target: '1.8s',
        threshold: 'good',
        description: 'First content appears within 1.8 seconds'
    },
    
    // Time to Interactive - Full interactivity
    TTI: {
        target: '3.8s',
        threshold: 'good',
        description: 'Page fully interactive within 3.8 seconds'
    }
};
```

### 2.2 Backend Performance Targets

```php
<?php

// API Response Time Standards
const API_PERFORMANCE_TARGETS = [
    // Database queries
    'simple_query' => '10ms',      // Single table, indexed lookup
    'complex_query' => '50ms',     // Multi-table joins, aggregations
    'report_query' => '200ms',     // Complex reporting queries
    
    // API endpoints
    'list_endpoint' => '100ms',    // GET /api/artists
    'detail_endpoint' => '50ms',   // GET /api/artists/{id}
    'create_endpoint' => '150ms',  // POST /api/artists
    'update_endpoint' => '100ms',  // PUT /api/artists/{id}
    'delete_endpoint' => '75ms',   // DELETE /api/artists/{id}
    
    // Filament admin panel
    'resource_index' => '200ms',   // Resource listing pages
    'resource_form' => '150ms',    // Create/edit forms
    'resource_save' => '300ms',    // Form submissions
    
    // Cache operations
    'cache_hit' => '1ms',          // Cache retrieval
    'cache_miss' => '50ms',        // Cache generation
    'cache_write' => '5ms',        // Cache storage
];
```

### 2.3 Database Performance Targets

```sql
-- Query Performance Standards
-- Simple lookups (indexed columns)
SELECT * FROM chinook_artists WHERE id = 1;
-- Target: < 1ms

-- Filtered lists (indexed columns)
SELECT * FROM chinook_artists WHERE is_active = 1 LIMIT 50;
-- Target: < 10ms

-- Complex joins with relationships
SELECT a.*, COUNT(al.id) as albums_count 
FROM chinook_artists a 
LEFT JOIN chinook_albums al ON a.id = al.artist_id 
WHERE a.is_active = 1 
GROUP BY a.id 
ORDER BY albums_count DESC 
LIMIT 20;
-- Target: < 50ms

-- Full-text search operations
SELECT * FROM chinook_artists 
WHERE name LIKE '%search_term%' 
ORDER BY name 
LIMIT 50;
-- Target: < 100ms
```

## 3. Measurement Standards

### 3.1 Performance Monitoring Implementation

```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

/**
 * Performance Monitoring Middleware
 * 
 * Tracks request performance and logs slow operations
 */
class PerformanceMonitoring
{
    public function handle(Request $request, Closure $next)
    {
        $startTime = microtime(true);
        $startMemory = memory_get_usage(true);
        
        $response = $next($request);
        
        $endTime = microtime(true);
        $endMemory = memory_get_usage(true);
        
        $executionTime = ($endTime - $startTime) * 1000; // Convert to milliseconds
        $memoryUsage = $endMemory - $startMemory;
        
        // Log performance metrics
        $this->logPerformanceMetrics($request, $executionTime, $memoryUsage);
        
        // Add performance headers for debugging
        if (config('app.debug')) {
            $response->headers->set('X-Execution-Time', round($executionTime, 2) . 'ms');
            $response->headers->set('X-Memory-Usage', $this->formatBytes($memoryUsage));
        }
        
        return $response;
    }
    
    private function logPerformanceMetrics(Request $request, float $executionTime, int $memoryUsage): void
    {
        $route = $request->route()?->getName() ?? $request->path();
        
        // Log slow requests (over 200ms)
        if ($executionTime > 200) {
            Log::warning('Slow request detected', [
                'route' => $route,
                'method' => $request->method(),
                'execution_time_ms' => round($executionTime, 2),
                'memory_usage_mb' => round($memoryUsage / 1024 / 1024, 2),
                'url' => $request->fullUrl(),
                'user_id' => auth()->id(),
            ]);
        }
        
        // Log all API requests for monitoring
        if ($request->is('api/*')) {
            Log::info('API request performance', [
                'route' => $route,
                'method' => $request->method(),
                'execution_time_ms' => round($executionTime, 2),
                'memory_usage_mb' => round($memoryUsage / 1024 / 1024, 2),
                'status_code' => response()->status(),
            ]);
        }
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
```

### 3.2 Database Query Monitoring

```php
<?php

namespace App\Providers;

use Illuminate\Database\Events\QueryExecuted;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\ServiceProvider;

class DatabasePerformanceServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        // Monitor slow database queries
        DB::listen(function (QueryExecuted $query) {
            $executionTime = $query->time;
            
            // Log slow queries (over 100ms)
            if ($executionTime > 100) {
                Log::warning('Slow database query detected', [
                    'sql' => $query->sql,
                    'bindings' => $query->bindings,
                    'execution_time_ms' => $executionTime,
                    'connection' => $query->connectionName,
                ]);
            }
            
            // Log all queries in debug mode
            if (config('app.debug') && config('database.log_queries', false)) {
                Log::debug('Database query executed', [
                    'sql' => $query->sql,
                    'bindings' => $query->bindings,
                    'execution_time_ms' => $executionTime,
                ]);
            }
        });
    }
}
```

## 4. Optimization Guidelines

### 4.1 Database Optimization Standards

```php
<?php

// Required indexes for performance
Schema::table('chinook_artists', function (Blueprint $table) {
    // Primary performance indexes
    $table->index('name');                    // Name searches
    $table->index('is_active');              // Active filtering
    $table->index('country');                // Country filtering
    $table->index(['is_active', 'name']);    // Composite filtering
    $table->index('created_at');             // Date sorting
    $table->index('slug');                   // URL lookups
});

// Query optimization patterns
class ArtistOptimizedQueries
{
    /**
     * Optimized artist listing with pagination
     */
    public static function getArtistsList(array $filters = [], int $perPage = 50): LengthAwarePaginator
    {
        $query = Artist::query()
            ->select(['id', 'name', 'slug', 'country', 'is_active', 'created_at'])
            ->when($filters['active'] ?? null, fn($q) => $q->where('is_active', true))
            ->when($filters['country'] ?? null, fn($q) => $q->where('country', $filters['country']))
            ->when($filters['search'] ?? null, fn($q) => $q->where('name', 'like', "%{$filters['search']}%"));
        
        return $query->orderBy('name')->paginate($perPage);
    }
    
    /**
     * Optimized artist detail with relationships
     */
    public static function getArtistDetail(string $slug): Artist
    {
        return Artist::with([
            'albums' => fn($q) => $q->select(['id', 'artist_id', 'title', 'release_year'])
                                    ->orderBy('release_year', 'desc'),
            'albums.tracks' => fn($q) => $q->select(['id', 'album_id', 'name', 'duration'])
        ])
        ->where('slug', $slug)
        ->firstOrFail();
    }
}
```

### 4.2 Caching Strategy Standards

```php
<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;

class ChinookCacheService
{
    // Cache duration constants
    const CACHE_DURATION_SHORT = 300;    // 5 minutes
    const CACHE_DURATION_MEDIUM = 3600;  // 1 hour
    const CACHE_DURATION_LONG = 86400;   // 24 hours
    
    /**
     * Cache popular artists with automatic invalidation
     */
    public static function getPopularArtists(int $limit = 10): Collection
    {
        return Cache::remember(
            "popular_artists_{$limit}",
            self::CACHE_DURATION_MEDIUM,
            fn() => Artist::withCount('albums')
                ->active()
                ->orderByDesc('albums_count')
                ->limit($limit)
                ->get()
        );
    }
    
    /**
     * Cache artist statistics
     */
    public static function getArtistStats(int $artistId): array
    {
        return Cache::remember(
            "artist_stats_{$artistId}",
            self::CACHE_DURATION_LONG,
            function () use ($artistId) {
                $artist = Artist::findOrFail($artistId);
                
                return [
                    'albums_count' => $artist->albums()->count(),
                    'tracks_count' => $artist->tracks()->count(),
                    'total_duration' => $artist->tracks()->sum('duration'),
                    'latest_album' => $artist->albums()
                        ->latest('release_year')
                        ->first()?->title,
                ];
            }
        );
    }
    
    /**
     * Invalidate artist-related caches
     */
    public static function invalidateArtistCache(int $artistId): void
    {
        Cache::forget("artist_stats_{$artistId}");
        Cache::forget("popular_artists_10");
        Cache::forget("popular_artists_20");
        // Add other related cache keys
    }
}
```

## 5. Monitoring and Alerting

### 5.1 Performance Alert Thresholds

```php
<?php

// Performance alert configuration
const PERFORMANCE_ALERTS = [
    'response_time' => [
        'warning' => 200,   // 200ms
        'critical' => 500,  // 500ms
    ],
    'database_query' => [
        'warning' => 100,   // 100ms
        'critical' => 500,  // 500ms
    ],
    'memory_usage' => [
        'warning' => 128,   // 128MB
        'critical' => 256,  // 256MB
    ],
    'cache_hit_ratio' => [
        'warning' => 80,    // 80%
        'critical' => 60,   // 60%
    ],
];
```

## 6. Performance Testing

### 6.1 Load Testing Standards

```bash
# Apache Bench testing for API endpoints
ab -n 1000 -c 10 http://localhost:8000/api/artists

# Expected results:
# - Requests per second: > 100
# - Mean response time: < 100ms
# - 95th percentile: < 200ms
# - No failed requests

# Database stress testing
php artisan tinker
>>> $start = microtime(true);
>>> Artist::with('albums')->limit(100)->get();
>>> echo (microtime(true) - $start) * 1000 . "ms";
# Expected: < 50ms
```

---

## Navigation

- **Previous:** [Performance Optimization](./100-single-taxonomy-optimization.md)
- **Next:** [Performance Monitoring Guide](../frontend/170-performance-monitoring-guide.md)
- **Index:** [Performance Index](./000-performance-index.md)

## Related Documentation

- [Database Configuration Guide](../000-database-configuration-guide.md)
- [Error Handling Guide](../200-error-handling-guide.md)

---

**Last Updated:** 2025-07-16  
**Maintainer:** Technical Documentation Team  
**Source:** [GitHub Repository](https://github.com/s-a-c/chinook)
