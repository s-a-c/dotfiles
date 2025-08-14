# Two-Database Architecture Quick Reference

**Version:** 1.0  
**Created:** 2025-07-19  
**Purpose:** Quick reference for common operations and commands

## Table of Contents

1. [Setup Commands](#1-setup-commands)
2. [Maintenance Commands](#2-maintenance-commands)
3. [Monitoring Commands](#3-monitoring-commands)
4. [Troubleshooting Commands](#4-troubleshooting-commands)
5. [Performance Optimization](#5-performance-optimization)
6. [Common Code Snippets](#6-common-code-snippets)

## 1. Setup Commands

### Initial Setup
```bash
# Complete two-database setup
php artisan chinook:two-db-setup

# Setup with options
php artisan chinook:two-db-setup --force --skip-vectors

# Validate configuration
php artisan chinook:validate-config

# Verify extensions
php artisan chinook:verify-vector-extension
```

### Database Migrations
```bash
# Run all migrations
php artisan migrate

# Run specific migration
php artisan migrate --path=database/migrations/2025_07_19_000001_enhance_sqlite_for_two_database.php

# Rollback migrations
php artisan migrate:rollback --step=1
```

### Service Registration
```bash
# Clear configuration cache
php artisan config:clear

# Register service provider
# Add to config/app.php:
App\Providers\TwoDatabaseServiceProvider::class,
```

## 2. Maintenance Commands

### FTS5 Maintenance
```bash
# Rebuild FTS index
php artisan chinook:fts-maintenance rebuild --force

# Optimize FTS index
php artisan chinook:fts-maintenance optimize

# Validate FTS index
php artisan chinook:fts-maintenance validate

# Show FTS statistics
php artisan chinook:fts-maintenance stats
```

### Cache Management
```bash
# Clear all caches
php artisan cache:clear

# Clear specific cache tags
php artisan tinker
>>> app(App\Services\InMemoryCacheManager::class)->invalidateByTags(['popular_tracks'])

# Get cache statistics
>>> app(App\Services\InMemoryCacheManager::class)->getCacheStats()

# Cleanup expired cache entries
>>> app(App\Services\InMemoryCacheManager::class)->cleanup()
```

### Database Optimization
```bash
# Run database optimization
sqlite3 database.sqlite "PRAGMA optimize;"

# Update statistics
sqlite3 database.sqlite "ANALYZE;"

# Checkpoint WAL
sqlite3 database.sqlite "PRAGMA wal_checkpoint(TRUNCATE);"

# Check database integrity
sqlite3 database.sqlite "PRAGMA integrity_check;"
```

## 3. Monitoring Commands

### Performance Monitoring
```bash
# Single performance check
php artisan chinook:performance-monitor

# Continuous monitoring
php artisan chinook:performance-monitor --watch

# JSON output for scripts
php artisan chinook:performance-monitor --json

# Health check
php artisan chinook:health-check
```

### System Status
```bash
# Get system health
php artisan tinker
>>> app(App\Services\TwoDatabaseMonitoringService::class)->getSystemHealth()

# Performance metrics
>>> app(App\Services\PerformanceOptimizationService::class)->getPerformanceMetrics()

# Database metrics
>>> DB::selectOne('PRAGMA journal_mode')
>>> DB::selectOne('PRAGMA cache_size')
>>> DB::selectOne('PRAGMA wal_checkpoint')
```

## 4. Troubleshooting Commands

### Connection Issues
```bash
# Test database connections
php artisan tinker
>>> DB::select('SELECT 1')
>>> DB::connection('cache')->select('SELECT 1')

# Check SQLite version
>>> DB::selectOne('SELECT sqlite_version() as version')

# Check extensions
>>> DB::select("SELECT fts5_version()")
>>> DB::select("SELECT vec_version()")
```

### Performance Issues
```bash
# Enable query logging
php artisan tinker
>>> DB::enableQueryLog()
# ... perform operations
>>> DB::getQueryLog()

# Check slow queries
>>> collect(DB::getQueryLog())->where('time', '>', 100)

# Memory usage
>>> memory_get_usage(true) / 1024 / 1024 . ' MB'
>>> memory_get_peak_usage(true) / 1024 / 1024 . ' MB'
```

### Search Issues
```bash
# Test FTS5 search
sqlite3 database.sqlite "SELECT * FROM music_search_fts WHERE music_search_fts MATCH 'rock' LIMIT 5;"

# Check FTS index coverage
sqlite3 database.sqlite "SELECT COUNT(*) FROM music_search_fts;"
sqlite3 database.sqlite "SELECT COUNT(*) FROM chinook_tracks;"

# Rebuild FTS if needed
php artisan chinook:fts-maintenance rebuild --force
```

## 5. Performance Optimization

### Quick Performance Boost
```bash
# Apply all optimizations
php artisan chinook:performance-optimize

# Warm up caches
php artisan tinker
>>> app(App\Services\PerformanceOptimizationService::class)->optimizeForHighConcurrency()

# Preload popular data
>>> app(App\Services\InMemoryCacheManager::class)->cacheQuery('popular_tracks', DB::table('chinook_tracks')->limit(100)->get(), ['popular_tracks'])
```

### Database Tuning
```sql
-- Check current settings
PRAGMA journal_mode;
PRAGMA cache_size;
PRAGMA mmap_size;
PRAGMA busy_timeout;

-- Apply optimizations
PRAGMA cache_size = -131072;        -- 128MB
PRAGMA mmap_size = 1073741824;      -- 1GB
PRAGMA wal_autocheckpoint = 2000;
PRAGMA optimize;
```

### Cache Optimization
```php
// Warm up search cache
$searchService = app(App\Services\AdvancedMusicSearchService::class);
$popularQueries = ['rock', 'jazz', 'classical', 'blues', 'pop'];
foreach ($popularQueries as $query) {
    $searchService->searchMusic($query);
}

// Preload popular content
$cacheManager = app(App\Services\InMemoryCacheManager::class);
$popularTracks = DB::table('chinook_tracks')->limit(100)->get();
$cacheManager->cacheQuery('popular_tracks_100', $popularTracks, ['popular_tracks'], 3600);
```

## 6. Common Code Snippets

### Search Implementation
```php
// Basic search
$searchService = app(App\Services\AdvancedMusicSearchService::class);
$results = $searchService->searchMusic('rock music', ['limit' => 20]);

// Search with filters
$results = $searchService->searchMusic('jazz', [
    'genre' => 'Jazz',
    'year_from' => 1990,
    'limit' => 50
]);

// Search with highlights
$results = $searchService->searchWithHighlights('blues guitar');

// Autocomplete suggestions
$suggestions = $searchService->searchSuggestions('rock');
```

### Vector Search
```php
// Find similar tracks
$vectorService = app(App\Services\MusicVectorService::class);
$similarTracks = $vectorService->findSimilarTracks(123, 'audio', 10);

// Generate recommendations
$recommendations = $vectorService->generateRecommendations(userId: 1, limit: 20);

// Generate and store vectors
$embeddings = $vectorService->generateTrackEmbeddings(123);
$vectorService->storeTrackVectors(123, $embeddings);
```

### Cache Operations
```php
// Cache manager
$cacheManager = app(App\Services\InMemoryCacheManager::class);

// Cache query results
$data = DB::table('chinook_tracks')->limit(100)->get();
$cacheManager->cacheQuery('popular_tracks', $data, ['tracks'], 3600);

// Get cached data
$cached = $cacheManager->getQuery('popular_tracks');

// Cache search results
$results = $searchService->searchMusic('rock');
$cacheManager->cacheSearchResults('rock', $results->toArray());

// Invalidate by tags
$cacheManager->invalidateByTags(['tracks', 'popular_tracks']);
```

### Performance Monitoring
```php
// Get system health
$monitoringService = app(App\Services\TwoDatabaseMonitoringService::class);
$health = $monitoringService->getSystemHealth();

// Performance check
$healthCheck = $monitoringService->performHealthCheck();

// Check specific metrics
$dbHealth = $health['database_health'];
$cacheHealth = $health['cache_health'];
$searchHealth = $health['search_health'];
```

### Database Queries
```php
// Optimized track queries
$tracks = DB::table('chinook_tracks')
    ->join('chinook_albums', 'chinook_tracks.album_id', '=', 'chinook_albums.id')
    ->join('chinook_artists', 'chinook_albums.artist_id', '=', 'chinook_artists.id')
    ->select([
        'chinook_tracks.id',
        'chinook_tracks.name as track_name',
        'chinook_albums.title as album_title',
        'chinook_artists.name as artist_name'
    ])
    ->limit(100)
    ->get();

// FTS5 search query
$searchResults = DB::select("
    SELECT 
        t.id,
        t.name,
        highlight(music_search_fts, 0, '<mark>', '</mark>') as highlighted_name
    FROM music_search_fts fts
    JOIN chinook_tracks t ON t.id = fts.rowid
    WHERE music_search_fts MATCH ?
    ORDER BY fts.rank
    LIMIT 20
", ['"rock music"']);
```

### Configuration Helpers
```php
// Check if extensions are available
function isFts5Available(): bool {
    try {
        DB::select("SELECT fts5_version()");
        return true;
    } catch (\Exception $e) {
        return false;
    }
}

function isVectorSearchAvailable(): bool {
    try {
        DB::select("SELECT vec_version()");
        return true;
    } catch (\Exception $e) {
        return false;
    }
}

// Get database configuration
function getDatabaseConfig(): array {
    return [
        'journal_mode' => DB::selectOne('PRAGMA journal_mode')->journal_mode,
        'cache_size' => DB::selectOne('PRAGMA cache_size')->cache_size,
        'page_size' => DB::selectOne('PRAGMA page_size')->page_size,
        'mmap_size' => DB::selectOne('PRAGMA mmap_size')->mmap_size,
    ];
}
```

## Quick Troubleshooting Checklist

### Setup Issues
- [ ] SQLite version 3.38+ installed
- [ ] FTS5 extension available
- [ ] Database connections configured
- [ ] Service provider registered
- [ ] Migrations run successfully

### Performance Issues
- [ ] WAL mode enabled
- [ ] Cache size adequate (128MB+)
- [ ] Memory mapping enabled (1GB+)
- [ ] FTS index built and optimized
- [ ] Cache hit rates >70%

### Search Issues
- [ ] FTS5 extension loaded
- [ ] FTS index synchronized
- [ ] Search queries properly formatted
- [ ] Cache warming completed
- [ ] No orphaned FTS entries

### Cache Issues
- [ ] In-memory cache connection working
- [ ] Cache tables created
- [ ] TTL settings appropriate
- [ ] Cleanup running regularly
- [ ] No memory leaks

---

**Last Updated:** 2025-07-19  
**Related Documents:** 
- [Two-Database Architecture Implementation](090-two-database-architecture.md)
- [Configuration Reference](091-two-database-configuration-reference.md)

<<<<<<
[Back](091-two-database-configuration-reference.md) | [Forward](../030-architecture/000-index.md)
[Top](#two-database-architecture-quick-reference)
<<<<<<
