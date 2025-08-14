# Two-Database Configuration Reference

**Version:** 1.0  
**Created:** 2025-07-19  
**Last Updated:** 2025-07-19  
**Purpose:** Complete configuration reference for two-database architecture

## Table of Contents

1. [Environment Configuration](#1-environment-configuration)
2. [Database Connection Settings](#2-database-connection-settings)
3. [Performance Tuning Parameters](#3-performance-tuning-parameters)
4. [Extension Configuration](#4-extension-configuration)
5. [Cache Configuration](#5-cache-configuration)
6. [Monitoring Configuration](#6-monitoring-configuration)
7. [Production Deployment Settings](#7-production-deployment-settings)

## 1. Environment Configuration

### 1.1 Complete .env Configuration

```env
# Application Configuration
APP_NAME="Chinook Music Store"
APP_ENV=production
APP_KEY=base64:your-app-key-here
APP_DEBUG=false
APP_URL=https://your-domain.com

# Database Configuration
DB_CONNECTION=sqlite
DB_DATABASE=/absolute/path/to/chinook/database/database.sqlite
DB_FOREIGN_KEYS=true

# Two-Database Architecture Settings
CACHE_DRIVER=database
CACHE_CONNECTION=cache
SESSION_DRIVER=database
SESSION_CONNECTION=cache
SESSION_LIFETIME=120
QUEUE_CONNECTION=database
QUEUE_DATABASE=sqlite

# SQLite Performance Settings (100 Concurrent Users)
SQLITE_CACHE_SIZE=131072          # 128MB cache
SQLITE_MMAP_SIZE=1073741824       # 1GB memory mapping
SQLITE_WAL_AUTOCHECKPOINT=2000    # Checkpoint every 2000 pages
SQLITE_BUSY_TIMEOUT=10000         # 10 second timeout
SQLITE_PAGE_SIZE=32768            # 32KB page size

# Search Configuration
FTS5_ENABLED=true
VECTOR_SEARCH_ENABLED=true
SEARCH_CACHE_TTL=600              # 10 minutes
SEARCH_MAX_RESULTS=100

# Cache TTL Settings (seconds)
CACHE_QUERIES_TTL=300             # 5 minutes
CACHE_SEARCH_TTL=600              # 10 minutes
CACHE_AGGREGATIONS_TTL=1800       # 30 minutes
CACHE_POPULAR_CONTENT_TTL=3600    # 1 hour
CACHE_SESSIONS_TTL=7200           # 2 hours

# Performance Monitoring
PERFORMANCE_MONITORING=true
CACHE_MONITORING=true
SLOW_QUERY_THRESHOLD=100          # Log queries >100ms
MEMORY_WARNING_THRESHOLD=200      # Warn if memory >200MB

# Extension Paths (adjust for your system)
SQLITE_VEC_EXTENSION_PATH=/usr/local/lib/vec0.so
SQLITE_FTS5_ENABLED=true

# Backup Configuration
BACKUP_ENABLED=true
BACKUP_RETENTION_DAYS=30
BACKUP_SCHEDULE="0 2 * * *"       # Daily at 2 AM

# Logging
LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=info
LOG_SLOW_QUERIES=true
LOG_CACHE_OPERATIONS=false        # Set to true for debugging
```

### 1.2 Development vs Production Settings

**Development Environment (.env.local):**
```env
APP_ENV=local
APP_DEBUG=true
LOG_LEVEL=debug

# Reduced performance settings for development
SQLITE_CACHE_SIZE=32768           # 32MB cache
SQLITE_MMAP_SIZE=268435456        # 256MB memory mapping

# Enhanced logging for development
LOG_SLOW_QUERIES=true
LOG_CACHE_OPERATIONS=true
PERFORMANCE_MONITORING=true

# Relaxed timeouts for debugging
SQLITE_BUSY_TIMEOUT=30000         # 30 second timeout
```

**Production Environment (.env.production):**
```env
APP_ENV=production
APP_DEBUG=false
LOG_LEVEL=warning

# Optimized performance settings
SQLITE_CACHE_SIZE=131072          # 128MB cache
SQLITE_MMAP_SIZE=1073741824       # 1GB memory mapping

# Production logging
LOG_SLOW_QUERIES=true
LOG_CACHE_OPERATIONS=false
PERFORMANCE_MONITORING=true

# Production timeouts
SQLITE_BUSY_TIMEOUT=10000         # 10 second timeout
```

## 2. Database Connection Settings

### 2.1 Primary Database Connection

```php
// config/database.php - Primary SQLite connection
'sqlite' => [
    'driver' => 'sqlite',
    'url' => env('DB_URL'),
    'database' => env('DB_DATABASE', database_path('database.sqlite')),
    'prefix' => '',
    'foreign_key_constraints' => env('DB_FOREIGN_KEYS', true),
    
    // Enhanced concurrency settings
    'busy_timeout' => env('SQLITE_BUSY_TIMEOUT', 10000),
    'journal_mode' => 'WAL',
    'synchronous' => 'NORMAL',
    'cache_size' => '-' . env('SQLITE_CACHE_SIZE', 131072),
    'temp_store' => 'MEMORY',
    'mmap_size' => env('SQLITE_MMAP_SIZE', 1073741824),
    'wal_autocheckpoint' => env('SQLITE_WAL_AUTOCHECKPOINT', 2000),
    'page_size' => env('SQLITE_PAGE_SIZE', 32768),
    
    // Additional optimizations
    'auto_vacuum' => 'INCREMENTAL',
    'secure_delete' => 'OFF',
    'recursive_triggers' => 'ON',
    
    // Connection options
    'options' => [
        PDO::ATTR_PERSISTENT => false,
        PDO::ATTR_TIMEOUT => 10,
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::SQLITE_ATTR_OPEN_FLAGS => PDO::SQLITE_OPEN_READWRITE | PDO::SQLITE_OPEN_CREATE,
    ],
    
    // Extension loading (if needed)
    'init_commands' => [
        // "SELECT load_extension('" . env('SQLITE_VEC_EXTENSION_PATH') . "')",
    ],
],
```

### 2.2 Cache Database Connection

```php
// config/database.php - In-memory cache connection
'cache' => [
    'driver' => 'sqlite',
    'database' => 'file::memory:?cache=shared&uri=true',
    'prefix' => '',
    'foreign_key_constraints' => false,
    
    // Memory-optimized settings
    'synchronous' => 'OFF',
    'journal_mode' => 'MEMORY',
    'cache_size' => '-' . env('CACHE_SQLITE_CACHE_SIZE', 32768),
    'temp_store' => 'MEMORY',
    'locking_mode' => 'EXCLUSIVE',
    
    // Connection options for memory database
    'options' => [
        PDO::ATTR_PERSISTENT => true,  // Keep memory DB alive
        PDO::ATTR_TIMEOUT => 5,
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    ],
],
```

## 3. Performance Tuning Parameters

### 3.1 SQLite PRAGMA Settings

**Core Performance Settings:**
```sql
-- Journal and synchronization
PRAGMA journal_mode = WAL;           -- Write-Ahead Logging
PRAGMA synchronous = NORMAL;         -- Balanced durability/performance

-- Memory and caching
PRAGMA cache_size = -131072;         -- 128MB cache (negative = KB)
PRAGMA temp_store = MEMORY;          -- Temp tables in memory
PRAGMA mmap_size = 1073741824;       -- 1GB memory mapping

-- WAL optimization
PRAGMA wal_autocheckpoint = 2000;    -- Checkpoint every 2000 pages
PRAGMA busy_timeout = 10000;         -- 10 second timeout

-- Page and storage
PRAGMA page_size = 32768;            -- 32KB page size
PRAGMA auto_vacuum = INCREMENTAL;    -- Incremental vacuum
PRAGMA secure_delete = OFF;          -- Performance over security

-- Integrity and features
PRAGMA foreign_keys = ON;            -- Enable foreign key constraints
PRAGMA recursive_triggers = ON;      -- Enable recursive triggers
```

**Performance Monitoring PRAGMAs:**
```sql
-- Check current settings
PRAGMA journal_mode;
PRAGMA cache_size;
PRAGMA page_count;
PRAGMA page_size;
PRAGMA wal_checkpoint;

-- Optimization commands
PRAGMA optimize;                     -- Update query planner statistics
PRAGMA analysis_limit = 1000;       -- Limit analysis for performance
ANALYZE;                            -- Update table statistics
```

### 3.2 Connection Pool Configuration

**Laravel Database Configuration:**
```php
// config/database.php - Connection pooling
'connections' => [
    'sqlite' => [
        // ... other settings
        'pool' => [
            'max_connections' => 10,     // Maximum connections
            'min_connections' => 2,      // Minimum connections
            'max_idle_time' => 300,      // 5 minutes idle timeout
            'validation_query' => 'SELECT 1',
        ],
    ],
],
```

### 3.3 Application-Level Performance Settings

**Query Optimization:**
```php
// config/database.php - Query optimization
'default' => env('DB_CONNECTION', 'sqlite'),
'query_log' => env('DB_QUERY_LOG', false),
'slow_query_threshold' => env('SLOW_QUERY_THRESHOLD', 100), // milliseconds

// Enable query caching
'query_cache' => [
    'enabled' => env('QUERY_CACHE_ENABLED', true),
    'ttl' => env('QUERY_CACHE_TTL', 300), // 5 minutes
    'max_size' => env('QUERY_CACHE_MAX_SIZE', 1000), // Max cached queries
],
```

## 4. Extension Configuration

### 4.1 FTS5 Configuration

**FTS5 Tokenizer Settings:**
```sql
-- Create FTS5 table with optimized tokenizer
CREATE VIRTUAL TABLE music_search_fts USING fts5(
    track_name,
    album_title,
    artist_name,
    genre_name,
    track_composer,
    content='',
    tokenize='porter ascii',
    prefix='2,3,4'              -- Enable prefix matching
);

-- FTS5 configuration options
INSERT INTO music_search_fts(music_search_fts, rank) VALUES('pgsz', '32768');  -- Page size
INSERT INTO music_search_fts(music_search_fts, rank) VALUES('crisismerge', '16'); -- Crisis merge
INSERT INTO music_search_fts(music_search_fts, rank) VALUES('usermerge', '4');    -- User merge
```

**FTS5 Performance Settings:**
```php
// config/search.php
return [
    'fts5' => [
        'enabled' => env('FTS5_ENABLED', true),
        'tokenizer' => 'porter ascii',
        'prefix_lengths' => [2, 3, 4],
        'page_size' => 32768,
        'crisis_merge' => 16,
        'user_merge' => 4,
        'auto_merge' => true,
        'rebuild_threshold' => 0.1, // Rebuild if 10% of data changed
    ],
];
```

### 4.2 sqlite-vec Configuration

**Vector Extension Settings:**
```php
// config/vector.php
return [
    'sqlite_vec' => [
        'enabled' => env('VECTOR_SEARCH_ENABLED', false),
        'extension_path' => env('SQLITE_VEC_EXTENSION_PATH'),
        'vector_dimensions' => [
            'audio_features' => 128,
            'lyric_features' => 384,
            'metadata_features' => 64,
        ],
        'similarity_threshold' => 0.7,
        'max_results' => 50,
        'cache_ttl' => 3600, // 1 hour
    ],
];
```

**Vector Table Configuration:**
```sql
-- Create vector table with optimized settings
CREATE VIRTUAL TABLE track_vectors USING vec0(
    track_id INTEGER PRIMARY KEY,
    audio_features FLOAT[128],
    lyric_features FLOAT[384],
    metadata_features FLOAT[64]
);

-- Vector index optimization
INSERT INTO track_vectors_config(k, v) VALUES('metric', 'cosine');
INSERT INTO track_vectors_config(k, v) VALUES('index_type', 'flat');
```

## 5. Cache Configuration

### 5.1 Cache Store Configuration

```php
// config/cache.php
'stores' => [
    'database' => [
        'driver' => 'database',
        'table' => 'cache',
        'connection' => 'cache', // Use in-memory cache connection
        'lock_connection' => 'cache',
    ],
    
    'memory_cache' => [
        'driver' => 'array',
        'serialize' => false,
    ],
    
    'search_cache' => [
        'driver' => 'database',
        'table' => 'cache_search_results',
        'connection' => 'cache',
    ],
],

'prefix' => env('CACHE_PREFIX', Str::slug(env('APP_NAME', 'laravel'), '_').'_cache'),
```

### 5.2 Cache TTL Configuration

```php
// config/cache.php - TTL settings
'ttl' => [
    'queries' => env('CACHE_QUERIES_TTL', 300),           // 5 minutes
    'search' => env('CACHE_SEARCH_TTL', 600),             // 10 minutes
    'aggregations' => env('CACHE_AGGREGATIONS_TTL', 1800), // 30 minutes
    'popular_content' => env('CACHE_POPULAR_CONTENT_TTL', 3600), // 1 hour
    'sessions' => env('CACHE_SESSIONS_TTL', 7200),        // 2 hours
    'user_data' => env('CACHE_USER_DATA_TTL', 900),       // 15 minutes
],

// Cache tags for invalidation
'tags' => [
    'tracks' => ['music', 'catalog'],
    'artists' => ['music', 'catalog'],
    'albums' => ['music', 'catalog'],
    'search' => ['search_results'],
    'popular' => ['popular_content'],
],
```

## 6. Monitoring Configuration

### 6.1 Performance Monitoring

```php
// config/monitoring.php
return [
    'enabled' => env('PERFORMANCE_MONITORING', true),
    
    'thresholds' => [
        'slow_query_ms' => env('SLOW_QUERY_THRESHOLD', 100),
        'memory_warning_mb' => env('MEMORY_WARNING_THRESHOLD', 200),
        'cache_hit_rate_warning' => 70, // Warn if cache hit rate <70%
        'disk_space_warning' => 20,     // Warn if disk space <20%
    ],
    
    'metrics' => [
        'query_performance' => true,
        'cache_efficiency' => true,
        'memory_usage' => true,
        'search_performance' => true,
        'database_health' => true,
    ],
    
    'alerts' => [
        'email' => env('MONITORING_EMAIL'),
        'slack_webhook' => env('MONITORING_SLACK_WEBHOOK'),
        'enabled' => env('MONITORING_ALERTS_ENABLED', false),
    ],
];
```

### 6.2 Health Check Configuration

```php
// config/health.php
return [
    'checks' => [
        'database_connectivity' => true,
        'cache_connectivity' => true,
        'wal_status' => true,
        'fts_integrity' => true,
        'cache_efficiency' => true,
        'disk_space' => true,
        'memory_usage' => true,
        'search_performance' => true,
    ],
    
    'intervals' => [
        'health_check' => 300,      // 5 minutes
        'performance_check' => 60,  // 1 minute
        'deep_check' => 3600,       // 1 hour
    ],
    
    'storage' => [
        'driver' => 'database',
        'connection' => 'cache',
        'table' => 'health_checks',
    ],
];
```

## 7. Production Deployment Settings

### 7.1 Production Environment Configuration

```env
# Production .env settings
APP_ENV=production
APP_DEBUG=false
LOG_LEVEL=warning

# Optimized database settings
SQLITE_CACHE_SIZE=131072
SQLITE_MMAP_SIZE=1073741824
SQLITE_BUSY_TIMEOUT=10000

# Production cache settings
CACHE_QUERIES_TTL=600
CACHE_SEARCH_TTL=1200
CACHE_AGGREGATIONS_TTL=3600

# Security settings
SESSION_SECURE_COOKIE=true
SESSION_HTTP_ONLY=true
SESSION_SAME_SITE=strict

# Monitoring and alerting
PERFORMANCE_MONITORING=true
MONITORING_ALERTS_ENABLED=true
MONITORING_EMAIL=admin@yourdomain.com
```

### 7.2 Server Configuration

**Nginx Configuration:**
```nginx
server {
    listen 80;
    server_name your-domain.com;
    root /path/to/chinook/public;
    index index.php;

    # Gzip compression
    gzip on;
    gzip_types text/css application/javascript application/json;

    # Static file caching
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # PHP-FPM configuration
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        
        # Increased timeouts for database operations
        fastcgi_read_timeout 300;
        fastcgi_send_timeout 300;
    }
}
```

**PHP-FPM Configuration:**
```ini
; /etc/php/8.2/fpm/pool.d/chinook.conf
[chinook]
user = www-data
group = www-data

listen = /var/run/php/php8.2-fpm-chinook.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

; Process management
pm = dynamic
pm.max_children = 50
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.max_requests = 1000

; Memory and execution limits
php_admin_value[memory_limit] = 256M
php_admin_value[max_execution_time] = 300
php_admin_value[max_input_time] = 300

; SQLite specific settings
php_admin_value[sqlite3.extension_dir] = /usr/lib/x86_64-linux-gnu/
```

### 7.3 Backup and Recovery Configuration

```bash
#!/bin/bash
# Production backup script

# Configuration
BACKUP_DIR="/backups/chinook"
RETENTION_DAYS=30
DB_PATH="/path/to/chinook/database/database.sqlite"

# Create backup with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/chinook_${TIMESTAMP}.sqlite"

# Ensure backup directory exists
mkdir -p "${BACKUP_DIR}"

# Checkpoint WAL before backup
sqlite3 "${DB_PATH}" "PRAGMA wal_checkpoint(TRUNCATE);"

# Create backup
cp "${DB_PATH}" "${BACKUP_FILE}"

# Verify backup integrity
if sqlite3 "${BACKUP_FILE}" "PRAGMA integrity_check;" | grep -q "ok"; then
    echo "Backup successful: ${BACKUP_FILE}"
    
    # Compress backup
    gzip "${BACKUP_FILE}"
    
    # Clean old backups
    find "${BACKUP_DIR}" -name "chinook_*.sqlite.gz" -mtime +${RETENTION_DAYS} -delete
else
    echo "Backup verification failed: ${BACKUP_FILE}"
    rm -f "${BACKUP_FILE}"
    exit 1
fi
```

This configuration reference provides comprehensive settings for deploying and maintaining the two-database architecture in production environments.

---

**Last Updated:** 2025-07-19  
**Related Documents:** [Two-Database Architecture Implementation](090-two-database-architecture.md)

<<<<<<
[Back](090-two-database-architecture.md) | [Forward](../030-architecture/000-index.md)
[Top](#two-database-configuration-reference)
<<<<<<
