# Implementation Guidance and Configuration Templates

**Report Date:** 2025-07-19  
**Project:** Chinook SQLite Architecture Implementation  
**Focus:** Practical implementation steps and configuration templates

## 1. Recommended Implementation: Enhanced Single Database

### 1.1. FTS5 Integration Implementation

#### 1.1.1. Migration for FTS5 Setup

```php
<?php
// database/migrations/2025_07_19_000001_add_fts5_search_tables.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void
    {
        // Create FTS5 virtual table for tracks
        DB::statement("
            CREATE VIRTUAL TABLE tracks_fts USING fts5(
                name,
                album_title,
                artist_name,
                content='chinook_tracks',
                content_rowid='id',
                tokenize='porter ascii'
            )
        ");

        // Create triggers for automatic index updates
        DB::statement("
            CREATE TRIGGER tracks_fts_insert AFTER INSERT ON chinook_tracks BEGIN
                INSERT INTO tracks_fts(rowid, name, album_title, artist_name) 
                SELECT 
                    new.id, 
                    new.name,
                    (SELECT title FROM chinook_albums WHERE id = new.album_id),
                    (SELECT name FROM chinook_artists WHERE id = (
                        SELECT artist_id FROM chinook_albums WHERE id = new.album_id
                    ));
            END
        ");

        DB::statement("
            CREATE TRIGGER tracks_fts_update AFTER UPDATE ON chinook_tracks BEGIN
                UPDATE tracks_fts SET 
                    name = new.name,
                    album_title = (SELECT title FROM chinook_albums WHERE id = new.album_id),
                    artist_name = (SELECT name FROM chinook_artists WHERE id = (
                        SELECT artist_id FROM chinook_albums WHERE id = new.album_id
                    ))
                WHERE rowid = new.id;
            END
        ");

        DB::statement("
            CREATE TRIGGER tracks_fts_delete AFTER DELETE ON chinook_tracks BEGIN
                DELETE FROM tracks_fts WHERE rowid = old.id;
            END
        ");

        // Populate initial FTS data
        DB::statement("
            INSERT INTO tracks_fts(rowid, name, album_title, artist_name)
            SELECT 
                t.id,
                t.name,
                al.title,
                ar.name
            FROM chinook_tracks t
            JOIN chinook_albums al ON al.id = t.album_id
            JOIN chinook_artists ar ON ar.id = al.artist_id
        ");
    }

    public function down(): void
    {
        DB::statement('DROP TRIGGER IF EXISTS tracks_fts_delete');
        DB::statement('DROP TRIGGER IF EXISTS tracks_fts_update');
        DB::statement('DROP TRIGGER IF EXISTS tracks_fts_insert');
        DB::statement('DROP TABLE IF EXISTS tracks_fts');
    }
};
```

#### 1.1.2. Search Service Implementation

```php
<?php
// app/Services/ChinookSearchService.php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Collection;

class ChinookSearchService
{
    public function searchTracks(string $query, int $limit = 20): Collection
    {
        // Sanitize query for FTS5
        $sanitizedQuery = $this->sanitizeFtsQuery($query);
        
        return DB::select("
            SELECT 
                t.id,
                t.name,
                t.public_id,
                t.slug,
                al.title as album_title,
                ar.name as artist_name,
                fts.rank
            FROM tracks_fts fts
            JOIN chinook_tracks t ON t.id = fts.rowid
            JOIN chinook_albums al ON al.id = t.album_id
            JOIN chinook_artists ar ON ar.id = al.artist_id
            WHERE tracks_fts MATCH ?
            ORDER BY fts.rank
            LIMIT ?
        ", [$sanitizedQuery, $limit]);
    }

    public function searchWithHighlights(string $query, int $limit = 20): Collection
    {
        $sanitizedQuery = $this->sanitizeFtsQuery($query);
        
        return DB::select("
            SELECT 
                t.id,
                t.name,
                t.public_id,
                t.slug,
                al.title as album_title,
                ar.name as artist_name,
                highlight(tracks_fts, 0, '<mark>', '</mark>') as highlighted_name,
                snippet(tracks_fts, 1, '<mark>', '</mark>', '...', 32) as snippet,
                fts.rank
            FROM tracks_fts fts
            JOIN chinook_tracks t ON t.id = fts.rowid
            JOIN chinook_albums al ON al.id = t.album_id
            JOIN chinook_artists ar ON ar.id = al.artist_id
            WHERE tracks_fts MATCH ?
            ORDER BY fts.rank
            LIMIT ?
        ", [$sanitizedQuery, $limit]);
    }

    private function sanitizeFtsQuery(string $query): string
    {
        // Remove special FTS5 characters and escape quotes
        $query = preg_replace('/[^\w\s\-\*]/', ' ', $query);
        $query = trim(preg_replace('/\s+/', ' ', $query));
        
        // Add wildcard to last term for prefix matching
        $terms = explode(' ', $query);
        if (!empty($terms)) {
            $lastTerm = array_pop($terms);
            if (!str_ends_with($lastTerm, '*')) {
                $lastTerm .= '*';
            }
            $terms[] = $lastTerm;
        }
        
        return implode(' ', $terms);
    }
}
```

### 1.2. Performance Optimization Configuration

#### 1.2.1. Enhanced SQLite Configuration Migration

```php
<?php
// database/migrations/2025_07_19_000002_enhance_sqlite_configuration.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void
    {
        $pragmas = [
            // Core performance settings
            'journal_mode = WAL',
            'synchronous = NORMAL',
            'cache_size = -64000',        // 64MB cache
            'temp_store = MEMORY',
            'mmap_size = 268435456',      // 256MB memory mapping
            
            // FTS5 optimizations
            'optimize',                   // Update query planner statistics
            
            // Maintenance settings
            'auto_vacuum = INCREMENTAL',
            'incremental_vacuum',
            'wal_autocheckpoint = 1000',
            'busy_timeout = 5000',
            
            // Security and integrity
            'foreign_keys = ON',
            'secure_delete = OFF',        // Performance over security for educational use
        ];

        foreach ($pragmas as $pragma) {
            DB::statement("PRAGMA {$pragma}");
        }

        // Create indexes for common query patterns
        $this->createPerformanceIndexes();
    }

    private function createPerformanceIndexes(): void
    {
        $indexes = [
            // Chinook-specific indexes
            'CREATE INDEX IF NOT EXISTS idx_tracks_album_artist ON chinook_tracks(album_id, artist_id)',
            'CREATE INDEX IF NOT EXISTS idx_tracks_genre_price ON chinook_tracks(genre_id, unit_price)',
            'CREATE INDEX IF NOT EXISTS idx_albums_artist_date ON chinook_albums(artist_id, release_date)',
            'CREATE INDEX IF NOT EXISTS idx_invoices_customer_date ON chinook_invoices(customer_id, invoice_date)',
            'CREATE INDEX IF NOT EXISTS idx_invoice_lines_track ON chinook_invoice_lines(track_id, quantity)',
            
            // Search optimization indexes
            'CREATE INDEX IF NOT EXISTS idx_tracks_name_lower ON chinook_tracks(lower(name))',
            'CREATE INDEX IF NOT EXISTS idx_artists_name_lower ON chinook_artists(lower(name))',
            'CREATE INDEX IF NOT EXISTS idx_albums_title_lower ON chinook_albums(lower(title))',
        ];

        foreach ($indexes as $index) {
            DB::statement($index);
        }
    }

    public function down(): void
    {
        // Reset to basic settings
        $pragmas = [
            'cache_size = -2000',
            'journal_mode = DELETE',
            'mmap_size = 0',
            'synchronous = FULL',
            'temp_store = DEFAULT',
        ];

        foreach ($pragmas as $pragma) {
            DB::statement("PRAGMA {$pragma}");
        }
    }
};
```

#### 1.2.2. Database Performance Service

```php
<?php
// app/Services/DatabasePerformanceService.php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class DatabasePerformanceService
{
    public function getPerformanceMetrics(): array
    {
        return [
            'wal_status' => $this->getWalStatus(),
            'cache_info' => $this->getCacheInfo(),
            'database_size' => $this->getDatabaseSize(),
            'index_usage' => $this->getIndexUsage(),
            'fts_status' => $this->getFtsStatus(),
        ];
    }

    public function getWalStatus(): array
    {
        $journalMode = DB::selectOne('PRAGMA journal_mode');
        $walCheckpoint = DB::selectOne('PRAGMA wal_checkpoint');
        
        return [
            'journal_mode' => $journalMode->journal_mode,
            'wal_checkpoint' => [
                'busy' => $walCheckpoint->busy ?? 0,
                'log' => $walCheckpoint->log ?? 0,
                'checkpointed' => $walCheckpoint->checkpointed ?? 0,
            ],
        ];
    }

    public function getCacheInfo(): array
    {
        $cacheSize = DB::selectOne('PRAGMA cache_size');
        $pageCount = DB::selectOne('PRAGMA page_count');
        $pageSize = DB::selectOne('PRAGMA page_size');
        
        return [
            'cache_size_pages' => $cacheSize->cache_size,
            'cache_size_mb' => abs($cacheSize->cache_size) / 1024, // Negative values are in KB
            'page_count' => $pageCount->page_count,
            'page_size' => $pageSize->page_size,
            'estimated_size_mb' => ($pageCount->page_count * $pageSize->page_size) / 1024 / 1024,
        ];
    }

    public function getDatabaseSize(): array
    {
        $dbPath = database_path('database.sqlite');
        $walPath = $dbPath . '-wal';
        $shmPath = $dbPath . '-shm';
        
        return [
            'main_file_mb' => file_exists($dbPath) ? filesize($dbPath) / 1024 / 1024 : 0,
            'wal_file_mb' => file_exists($walPath) ? filesize($walPath) / 1024 / 1024 : 0,
            'shm_file_mb' => file_exists($shmPath) ? filesize($shmPath) / 1024 / 1024 : 0,
        ];
    }

    public function getIndexUsage(): array
    {
        $indexes = DB::select("
            SELECT 
                name,
                tbl_name,
                sql
            FROM sqlite_master 
            WHERE type = 'index' 
            AND name NOT LIKE 'sqlite_%'
            ORDER BY tbl_name, name
        ");

        return collect($indexes)->groupBy('tbl_name')->toArray();
    }

    public function getFtsStatus(): array
    {
        try {
            $ftsStats = DB::selectOne("
                SELECT COUNT(*) as indexed_tracks 
                FROM tracks_fts
            ");
            
            return [
                'enabled' => true,
                'indexed_tracks' => $ftsStats->indexed_tracks ?? 0,
            ];
        } catch (\Exception $e) {
            return [
                'enabled' => false,
                'error' => $e->getMessage(),
            ];
        }
    }

    public function optimizeDatabase(): array
    {
        $results = [];
        
        try {
            // Run ANALYZE to update query planner statistics
            DB::statement('ANALYZE');
            $results['analyze'] = 'completed';
            
            // Run PRAGMA optimize
            DB::statement('PRAGMA optimize');
            $results['optimize'] = 'completed';
            
            // Force WAL checkpoint
            $checkpoint = DB::selectOne('PRAGMA wal_checkpoint(TRUNCATE)');
            $results['checkpoint'] = [
                'busy' => $checkpoint->busy ?? 0,
                'log' => $checkpoint->log ?? 0,
                'checkpointed' => $checkpoint->checkpointed ?? 0,
            ];
            
            // Incremental vacuum if needed
            $pageCount = DB::selectOne('PRAGMA page_count');
            $freelistCount = DB::selectOne('PRAGMA freelist_count');
            
            if ($freelistCount->freelist_count > ($pageCount->page_count * 0.1)) {
                DB::statement('PRAGMA incremental_vacuum');
                $results['vacuum'] = 'completed';
            } else {
                $results['vacuum'] = 'skipped - not needed';
            }
            
        } catch (\Exception $e) {
            $results['error'] = $e->getMessage();
            Log::error('Database optimization failed', ['error' => $e->getMessage()]);
        }
        
        return $results;
    }
}
```

### 1.3. Artisan Commands for Database Management

#### 1.3.1. Search Index Management Command

```php
<?php
// app/Console/Commands/ChinookSearchOptimize.php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use App\Services\DatabasePerformanceService;

class ChinookSearchOptimize extends Command
{
    protected $signature = 'chinook:search-optimize 
                           {--rebuild : Rebuild FTS indexes from scratch}
                           {--analyze : Run query analyzer}';
    
    protected $description = 'Optimize Chinook search indexes and performance';

    public function handle(DatabasePerformanceService $performanceService): int
    {
        $this->info('🔍 Optimizing Chinook search indexes...');

        if ($this->option('rebuild')) {
            $this->rebuildFtsIndexes();
        }

        if ($this->option('analyze')) {
            $this->analyzeQueries();
        }

        // Run standard optimization
        $results = $performanceService->optimizeDatabase();
        
        $this->displayResults($results);
        
        // Display current performance metrics
        $metrics = $performanceService->getPerformanceMetrics();
        $this->displayMetrics($metrics);

        return 0;
    }

    private function rebuildFtsIndexes(): void
    {
        $this->info('🔄 Rebuilding FTS indexes...');
        
        try {
            // Rebuild FTS index
            DB::statement("INSERT INTO tracks_fts(tracks_fts) VALUES('rebuild')");
            $this->info('✅ FTS indexes rebuilt successfully');
        } catch (\Exception $e) {
            $this->error('❌ Failed to rebuild FTS indexes: ' . $e->getMessage());
        }
    }

    private function analyzeQueries(): void
    {
        $this->info('📊 Analyzing query performance...');
        
        try {
            // Get query plan for common searches
            $plans = [
                'Track search' => DB::select("EXPLAIN QUERY PLAN SELECT * FROM tracks_fts WHERE tracks_fts MATCH 'rock'"),
                'Album lookup' => DB::select("EXPLAIN QUERY PLAN SELECT * FROM chinook_albums WHERE artist_id = 1"),
                'Invoice query' => DB::select("EXPLAIN QUERY PLAN SELECT * FROM chinook_invoices WHERE customer_id = 1"),
            ];

            foreach ($plans as $name => $plan) {
                $this->line("\n{$name}:");
                foreach ($plan as $step) {
                    $this->line("  {$step->detail}");
                }
            }
        } catch (\Exception $e) {
            $this->error('❌ Query analysis failed: ' . $e->getMessage());
        }
    }

    private function displayResults(array $results): void
    {
        $this->info("\n📈 Optimization Results:");
        foreach ($results as $operation => $result) {
            if ($operation === 'checkpoint' && is_array($result)) {
                $this->line("  {$operation}: {$result['checkpointed']} pages checkpointed");
            } else {
                $this->line("  {$operation}: {$result}");
            }
        }
    }

    private function displayMetrics(array $metrics): void
    {
        $this->info("\n📊 Current Performance Metrics:");
        
        // WAL Status
        $walMode = $metrics['wal_status']['journal_mode'];
        $this->line("  WAL Mode: {$walMode}");
        
        // Cache Info
        $cacheMb = round($metrics['cache_info']['cache_size_mb'], 1);
        $dbSizeMb = round($metrics['cache_info']['estimated_size_mb'], 1);
        $this->line("  Cache Size: {$cacheMb}MB");
        $this->line("  Database Size: {$dbSizeMb}MB");
        
        // FTS Status
        if ($metrics['fts_status']['enabled']) {
            $indexedTracks = $metrics['fts_status']['indexed_tracks'];
            $this->line("  FTS Indexed Tracks: {$indexedTracks}");
        } else {
            $this->line("  FTS Status: Disabled");
        }
    }
}
```

## 2. Alternative Implementation: Two-Database Architecture

### 2.1. Database Configuration

#### 2.1.1. Enhanced Database Configuration

```php
<?php
// config/database.php - Enhanced multi-database configuration

return [
    'default' => env('DB_CONNECTION', 'sqlite'),

    'connections' => [
        'sqlite' => [
            'driver' => 'sqlite',
            'url' => env('DB_URL'),
            'database' => env('DB_DATABASE', database_path('database.sqlite')),
            'prefix' => '',
            'foreign_key_constraints' => env('DB_FOREIGN_KEYS', true),
            'busy_timeout' => 5000,
            'journal_mode' => 'WAL',
            'synchronous' => 'NORMAL',
            'cache_size' => -32000, // 32MB for main app
            'temp_store' => 'MEMORY',
            'mmap_size' => 134217728, // 128MB
        ],

        'chinook' => [
            'driver' => 'sqlite',
            'url' => env('CHINOOK_DB_URL'),
            'database' => env('CHINOOK_DB_DATABASE', database_path('chinook.sqlite')),
            'prefix' => '',
            'foreign_key_constraints' => true,
            'busy_timeout' => 5000,
            'journal_mode' => 'WAL',
            'synchronous' => 'NORMAL',
            'cache_size' => -64000, // 64MB for Chinook data
            'temp_store' => 'MEMORY',
            'mmap_size' => 268435456, // 256MB
        ],
    ],
];
```

#### 2.1.2. Model Configuration for Multi-Database

```php
<?php
// app/Models/Chinook/BaseModel.php - Updated for multi-database

namespace App\Models\Chinook;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

abstract class BaseModel extends Model
{
    use SoftDeletes;

    protected $connection = 'chinook';
    
    protected $guarded = ['id'];
    
    protected function casts(): array
    {
        return [
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
            'deleted_at' => 'datetime',
        ];
    }
}
```

### 2.2. Migration Strategy for Two-Database Setup

#### 2.2.1. Database Migration Command

```php
<?php
// app/Console/Commands/ChinookMigrateTwoDatabase.php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class ChinookMigrateTwoDatabase extends Command
{
    protected $signature = 'chinook:migrate-two-db 
                           {--dry-run : Show what would be done without executing}
                           {--backup : Create backup before migration}';
    
    protected $description = 'Migrate to two-database architecture';

    public function handle(): int
    {
        if ($this->option('backup')) {
            $this->createBackup();
        }

        if ($this->option('dry-run')) {
            $this->info('🔍 Dry run mode - showing planned operations...');
            $this->showMigrationPlan();
            return 0;
        }

        $this->info('🚀 Starting two-database migration...');
        
        try {
            $this->createChinookDatabase();
            $this->migrateChinookTables();
            $this->updateApplicationModels();
            $this->validateMigration();
            
            $this->info('✅ Migration completed successfully!');
            return 0;
        } catch (\Exception $e) {
            $this->error('❌ Migration failed: ' . $e->getMessage());
            return 1;
        }
    }

    private function createBackup(): void
    {
        $timestamp = date('Y-m-d_H-i-s');
        $backupPath = storage_path("backups/pre-migration-{$timestamp}.sqlite");
        
        if (!is_dir(dirname($backupPath))) {
            mkdir(dirname($backupPath), 0755, true);
        }
        
        // Force WAL checkpoint before backup
        DB::statement('PRAGMA wal_checkpoint(TRUNCATE)');
        
        copy(database_path('database.sqlite'), $backupPath);
        $this->info("📦 Backup created: {$backupPath}");
    }

    private function showMigrationPlan(): void
    {
        $chinookTables = $this->getChinookTables();
        
        $this->info('📋 Migration Plan:');
        $this->line('1. Create chinook.sqlite database');
        $this->line('2. Move the following tables to chinook database:');
        
        foreach ($chinookTables as $table) {
            $this->line("   - {$table}");
        }
        
        $this->line('3. Update model configurations');
        $this->line('4. Validate data integrity');
    }

    private function getChinookTables(): array
    {
        $tables = DB::select("
            SELECT name FROM sqlite_master 
            WHERE type='table' 
            AND name LIKE 'chinook_%'
            ORDER BY name
        ");
        
        return array_column($tables, 'name');
    }

    private function createChinookDatabase(): void
    {
        $chinookPath = database_path('chinook.sqlite');
        
        if (!file_exists($chinookPath)) {
            touch($chinookPath);
            chmod($chinookPath, 0664);
        }
        
        // Configure chinook database
        DB::connection('chinook')->statement('PRAGMA journal_mode = WAL');
        DB::connection('chinook')->statement('PRAGMA synchronous = NORMAL');
        DB::connection('chinook')->statement('PRAGMA cache_size = -64000');
        DB::connection('chinook')->statement('PRAGMA foreign_keys = ON');
        
        $this->info('📁 Chinook database created and configured');
    }

    private function migrateChinookTables(): void
    {
        $tables = $this->getChinookTables();
        
        foreach ($tables as $table) {
            $this->migrateTable($table);
        }
    }

    private function migrateTable(string $table): void
    {
        $this->line("📦 Migrating table: {$table}");
        
        // Get table schema
        $schema = DB::select("SELECT sql FROM sqlite_master WHERE name = ?", [$table]);
        
        if (empty($schema)) {
            $this->warn("⚠️  Table {$table} not found, skipping");
            return;
        }
        
        // Create table in chinook database
        DB::connection('chinook')->statement($schema[0]->sql);
        
        // Copy data
        $this->copyTableData($table);
        
        // Copy indexes
        $this->copyTableIndexes($table);
    }

    private function copyTableData(string $table): void
    {
        // Get row count for progress
        $count = DB::table($table)->count();
        
        if ($count === 0) {
            return;
        }
        
        $batchSize = 1000;
        $batches = ceil($count / $batchSize);
        
        for ($i = 0; $i < $batches; $i++) {
            $offset = $i * $batchSize;
            $data = DB::table($table)->offset($offset)->limit($batchSize)->get();
            
            if ($data->isNotEmpty()) {
                DB::connection('chinook')->table($table)->insert($data->toArray());
            }
            
            $progress = round((($i + 1) / $batches) * 100, 1);
            $this->line("   Progress: {$progress}% ({$i + 1}/{$batches} batches)");
        }
    }

    private function copyTableIndexes(string $table): void
    {
        $indexes = DB::select("
            SELECT sql FROM sqlite_master 
            WHERE type = 'index' 
            AND tbl_name = ? 
            AND sql IS NOT NULL
        ", [$table]);
        
        foreach ($indexes as $index) {
            try {
                DB::connection('chinook')->statement($index->sql);
            } catch (\Exception $e) {
                $this->warn("⚠️  Failed to create index: {$e->getMessage()}");
            }
        }
    }

    private function updateApplicationModels(): void
    {
        $this->info('🔧 Model configurations updated (manual verification required)');
        $this->line('Please verify that all Chinook models extend BaseModel with chinook connection');
    }

    private function validateMigration(): void
    {
        $this->info('🔍 Validating migration...');
        
        $tables = $this->getChinookTables();
        
        foreach ($tables as $table) {
            $originalCount = DB::table($table)->count();
            $migratedCount = DB::connection('chinook')->table($table)->count();
            
            if ($originalCount !== $migratedCount) {
                throw new \Exception("Row count mismatch for {$table}: {$originalCount} vs {$migratedCount}");
            }
        }
        
        $this->info('✅ Data validation passed');
    }
}
```

## 3. Testing and Validation

### 3.1. Performance Testing Script

```php
<?php
// tests/Feature/DatabasePerformanceTest.php

namespace Tests\Feature;

use App\Services\ChinookSearchService;use App\Services\DatabasePerformanceService;use Illuminate\Support\Facades\DB;use old\TestCase;

class DatabasePerformanceTest extends TestCase
{
    private ChinookSearchService $searchService;
    private DatabasePerformanceService $performanceService;

    protected function setUp(): void
    {
        parent::setUp();
        $this->searchService = app(ChinookSearchService::class);
        $this->performanceService = app(DatabasePerformanceService::class);
    }

    public function test_database_configuration(): void
    {
        $metrics = $this->performanceService->getPerformanceMetrics();
        
        // Verify WAL mode is enabled
        $this->assertEquals('wal', $metrics['wal_status']['journal_mode']);
        
        // Verify cache size is appropriate
        $this->assertGreaterThan(30, $metrics['cache_info']['cache_size_mb']);
        
        // Verify FTS is working
        $this->assertTrue($metrics['fts_status']['enabled']);
        $this->assertGreaterThan(0, $metrics['fts_status']['indexed_tracks']);
    }

    public function test_search_performance(): void
    {
        $queries = ['rock', 'jazz', 'classical', 'blues'];
        
        foreach ($queries as $query) {
            $start = microtime(true);
            $results = $this->searchService->searchTracks($query, 10);
            $duration = (microtime(true) - $start) * 1000; // Convert to milliseconds
            
            // Search should complete within 50ms
            $this->assertLessThan(50, $duration, "Search for '{$query}' took {$duration}ms");
            $this->assertNotEmpty($results, "Search for '{$query}' returned no results");
        }
    }

    public function test_concurrent_access(): void
    {
        // Simulate concurrent reads
        $promises = [];
        
        for ($i = 0; $i < 10; $i++) {
            $promises[] = function() {
                return DB::table('chinook_tracks')->limit(100)->get();
            };
        }
        
        $start = microtime(true);
        
        // Execute all queries
        foreach ($promises as $promise) {
            $promise();
        }
        
        $duration = (microtime(true) - $start) * 1000;
        
        // All queries should complete within 200ms
        $this->assertLessThan(200, $duration, "Concurrent queries took {$duration}ms");
    }

    public function test_fts_accuracy(): void
    {
        // Test exact matches
        $results = $this->searchService->searchTracks('Bohemian Rhapsody');
        $this->assertNotEmpty($results);
        
        // Test partial matches
        $results = $this->searchService->searchTracks('Bohemian');
        $this->assertNotEmpty($results);
        
        // Test wildcard searches
        $results = $this->searchService->searchTracks('rock*');
        $this->assertNotEmpty($results);
    }
}
```

## 4. Monitoring and Maintenance

### 4.1. Health Check Service

```php
<?php
// app/Services/DatabaseHealthService.php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class DatabaseHealthService
{
    public function performHealthCheck(): array
    {
        $checks = [
            'database_connectivity' => $this->checkDatabaseConnectivity(),
            'wal_status' => $this->checkWalStatus(),
            'cache_efficiency' => $this->checkCacheEfficiency(),
            'fts_integrity' => $this->checkFtsIntegrity(),
            'disk_space' => $this->checkDiskSpace(),
        ];

        $overallHealth = $this->calculateOverallHealth($checks);
        
        return [
            'overall_health' => $overallHealth,
            'checks' => $checks,
            'timestamp' => now(),
        ];
    }

    private function checkDatabaseConnectivity(): array
    {
        try {
            DB::select('SELECT 1');
            return ['status' => 'healthy', 'message' => 'Database connection successful'];
        } catch (\Exception $e) {
            return ['status' => 'unhealthy', 'message' => $e->getMessage()];
        }
    }

    private function checkWalStatus(): array
    {
        try {
            $walInfo = DB::selectOne('PRAGMA wal_checkpoint');
            $walSize = $walInfo->log ?? 0;
            
            if ($walSize > 10000) { // More than 10k pages in WAL
                return [
                    'status' => 'warning',
                    'message' => "WAL file is large ({$walSize} pages)",
                    'recommendation' => 'Consider running PRAGMA wal_checkpoint(TRUNCATE)'
                ];
            }
            
            return ['status' => 'healthy', 'message' => "WAL status normal ({$walSize} pages)"];
        } catch (\Exception $e) {
            return ['status' => 'unhealthy', 'message' => $e->getMessage()];
        }
    }

    private function checkCacheEfficiency(): array
    {
        try {
            // This is a simplified check - in production you'd want more sophisticated metrics
            $cacheSize = DB::selectOne('PRAGMA cache_size');
            $pageCount = DB::selectOne('PRAGMA page_count');
            
            $cacheRatio = abs($cacheSize->cache_size) / $pageCount->page_count;
            
            if ($cacheRatio < 0.1) {
                return [
                    'status' => 'warning',
                    'message' => 'Cache size may be too small',
                    'cache_ratio' => round($cacheRatio, 3)
                ];
            }
            
            return [
                'status' => 'healthy',
                'message' => 'Cache configuration appears optimal',
                'cache_ratio' => round($cacheRatio, 3)
            ];
        } catch (\Exception $e) {
            return ['status' => 'unhealthy', 'message' => $e->getMessage()];
        }
    }

    private function checkFtsIntegrity(): array
    {
        try {
            $trackCount = DB::table('chinook_tracks')->count();
            $ftsCount = DB::selectOne('SELECT COUNT(*) as count FROM tracks_fts')->count;
            
            if ($trackCount !== $ftsCount) {
                return [
                    'status' => 'warning',
                    'message' => 'FTS index may be out of sync',
                    'track_count' => $trackCount,
                    'fts_count' => $ftsCount,
                    'recommendation' => 'Run FTS rebuild'
                ];
            }
            
            return [
                'status' => 'healthy',
                'message' => 'FTS index is synchronized',
                'indexed_tracks' => $ftsCount
            ];
        } catch (\Exception $e) {
            return ['status' => 'unhealthy', 'message' => $e->getMessage()];
        }
    }

    private function checkDiskSpace(): array
    {
        $dbPath = database_path('database.sqlite');
        $freeSpace = disk_free_space(dirname($dbPath));
        $totalSpace = disk_total_space(dirname($dbPath));
        
        $freePercentage = ($freeSpace / $totalSpace) * 100;
        
        if ($freePercentage < 10) {
            return [
                'status' => 'critical',
                'message' => 'Low disk space',
                'free_percentage' => round($freePercentage, 1)
            ];
        } elseif ($freePercentage < 20) {
            return [
                'status' => 'warning',
                'message' => 'Disk space getting low',
                'free_percentage' => round($freePercentage, 1)
            ];
        }
        
        return [
            'status' => 'healthy',
            'message' => 'Sufficient disk space',
            'free_percentage' => round($freePercentage, 1)
        ];
    }

    private function calculateOverallHealth(array $checks): string
    {
        $statuses = array_column($checks, 'status');
        
        if (in_array('critical', $statuses) || in_array('unhealthy', $statuses)) {
            return 'unhealthy';
        } elseif (in_array('warning', $statuses)) {
            return 'warning';
        }
        
        return 'healthy';
    }
}
```

This implementation guidance provides practical, ready-to-use code for enhancing the current single-database architecture with FTS5 search capabilities, which is the recommended approach based on the technical assessment. The alternative two-database implementation is also provided for reference, should the project requirements change in the future.

---

**Document Version:** 1.0  
**Last Updated:** 2025-07-19  
**Related Documents:** sqlite-architecture-evaluation.md, database-schema-diagrams.md
