# Database Optimization for UME

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Overview

Database performance is critical for User Model Enhancements (UME) applications, especially when dealing with complex user hierarchies, team structures, and permission systems. This guide provides comprehensive strategies for optimizing your database to ensure your UME implementation remains fast and efficient as your application grows.

## Table of Contents

1. [Database Schema Optimization](#database-schema-optimization)
2. [Indexing Strategies](#indexing-strategies)
3. [Query Optimization](#query-optimization)
4. [Relationship Optimization](#relationship-optimization)
5. [Single Table Inheritance Optimization](#single-table-inheritance-optimization)
6. [Database Configuration](#database-configuration)
7. [Scaling Strategies](#scaling-strategies)
8. [Monitoring and Profiling](#monitoring-and-profiling)
9. [Maintenance Procedures](#maintenance-procedures)

## Database Schema Optimization

### Normalization vs. Denormalization

UME uses a balanced approach to normalization:

- **Normalized**: Core user data, permissions, roles, and team structures
- **Denormalized**: Cached permission results, frequently accessed user attributes

### Column Types and Sizes

Choose appropriate column types and sizes:

```php
Schema::create('users', function (Blueprint $table) {
    // Use CHAR for fixed-length identifiers (more efficient than VARCHAR)
    $table->char('ulid', 26)->primary();
    
    // Use VARCHAR with appropriate length limits
    $table->string('name', 100);
    $table->string('email', 100)->unique();
    
    // Use ENUM for type column (more efficient than VARCHAR for limited options)
    $table->enum('type', ['admin', 'manager', 'practitioner']);
    
    // Use JSON for flexible attributes (only when needed)
    $table->json('preferences')->nullable();
    
    // Use appropriate integer types
    $table->unsignedSmallInteger('login_count')->default(0);
    
    // Use TIMESTAMP for created/updated timestamps (more efficient than DATETIME)
    $table->timestamps();
});
```

### Table Partitioning

For very large user tables (millions of records), consider partitioning:

```php
// Example of partitioning users by type using a stored procedure
DB::unprepared('
    CREATE PROCEDURE partition_users()
    BEGIN
        CREATE TABLE users_admin LIKE users;
        CREATE TABLE users_manager LIKE users;
        CREATE TABLE users_practitioner LIKE users;
        
        ALTER TABLE users_admin ADD CONSTRAINT check_type CHECK (type = "admin");
        ALTER TABLE users_manager ADD CONSTRAINT check_type CHECK (type = "manager");
        ALTER TABLE users_practitioner ADD CONSTRAINT check_type CHECK (type = "practitioner");
        
        -- Create a view that unions all partitions
        CREATE VIEW users_view AS
            SELECT * FROM users_admin
            UNION ALL
            SELECT * FROM users_manager
            UNION ALL
            SELECT * FROM users_practitioner;
    END
');
```

> **Note**: Table partitioning is an advanced technique and should only be used when dealing with very large datasets. It adds complexity to your application and may require changes to your Eloquent models.

## Indexing Strategies

### Essential Indexes for UME

```php
Schema::table('users', function (Blueprint $table) {
    // Index the type column (critical for STI queries)
    $table->index('type');
    
    // Index foreign keys
    $table->index('team_id');
    
    // Index frequently filtered columns
    $table->index('status');
    
    // Index user tracking columns
    $table->index(['created_by', 'created_at']);
    $table->index(['updated_by', 'updated_at']);
});

Schema::table('model_has_permissions', function (Blueprint $table) {
    // Composite index for permission lookups
    $table->index(['permission_id', 'model_id', 'model_type']);
});

Schema::table('team_user', function (Blueprint $table) {
    // Composite index for team membership lookups
    $table->index(['team_id', 'user_id', 'role']);
});
```

### Index Types

Choose the appropriate index type:

1. **B-tree indexes**: Default index type, good for equality and range queries
2. **Hash indexes**: Faster for exact equality comparisons (supported in some DB engines)
3. **Full-text indexes**: For text search on large text fields
4. **Spatial indexes**: For geographic data

```php
// Full-text index example
Schema::table('users', function (Blueprint $table) {
    // Add a full-text index for searching user profiles
    DB::statement('ALTER TABLE users ADD FULLTEXT search_index (name, email, bio)');
});
```

### Covering Indexes

Create covering indexes for frequently used queries:

```php
Schema::table('team_user', function (Blueprint $table) {
    // Covering index that includes all columns used in a common query
    $table->index(['team_id', 'user_id', 'role', 'created_at']);
});
```

### Index Maintenance

Regularly analyze and optimize indexes:

```php
// In a scheduled command
public function handle()
{
    if (config('database.default') === 'mysql') {
        DB::statement('ANALYZE TABLE users, teams, permissions, roles');
        DB::statement('OPTIMIZE TABLE users, teams, permissions, roles');
    }
}
```

## Query Optimization

### Eager Loading Relationships

Always use eager loading to prevent N+1 query problems:

```php
// Instead of this (causes N+1 queries)
$users = User::all();
foreach ($users as $user) {
    echo $user->team->name;
    echo $user->profile->bio;
}

// Do this (just 3 queries total)
$users = User::with(['team', 'profile'])->get();
foreach ($users as $user) {
    echo $user->team->name;
    echo $user->profile->bio;
}
```

### Selective Column Loading

Only select the columns you need:

```php
// Instead of selecting all columns
$users = User::all();

// Select only what you need
$users = User::select('id', 'name', 'email', 'type', 'team_id')->get();
```

### Query Chunking

Process large datasets in chunks:

```php
User::chunk(100, function ($users) {
    foreach ($users as $user) {
        // Process each user
    }
});
```

### Using Query Builders Efficiently

```php
// Instead of multiple separate queries
$activeUsers = User::where('status', 'active')->get();
$adminUsers = User::where('type', 'admin')->get();
$teamUsers = User::where('team_id', $teamId)->get();

// Combine related queries
$users = User::where(function ($query) use ($teamId) {
    $query->where('status', 'active')
          ->where(function ($q) use ($teamId) {
              $q->where('type', 'admin')
                ->orWhere('team_id', $teamId);
          });
})->get();
```

### Using Raw Queries When Necessary

For complex queries, sometimes raw SQL is more efficient:

```php
$users = DB::select('
    SELECT u.id, u.name, u.email, u.type, t.name as team_name
    FROM users u
    JOIN teams t ON u.team_id = t.id
    WHERE u.status = ? AND (u.type = ? OR u.team_id = ?)
    ORDER BY u.name
    LIMIT 100
', ['active', 'admin', $teamId]);
```

## Relationship Optimization

### Optimizing Polymorphic Relationships

UME uses polymorphic relationships for features like activities and comments:

```php
// Optimize polymorphic queries with proper indexes
Schema::table('activities', function (Blueprint $table) {
    $table->index(['subject_type', 'subject_id']);
    $table->index(['causer_type', 'causer_id']);
});
```

### Optimizing Many-to-Many Relationships

```php
// Optimize pivot table queries
Schema::table('role_user', function (Blueprint $table) {
    // Create composite indexes in both directions
    $table->index(['user_id', 'role_id']);
    $table->index(['role_id', 'user_id']);
});
```

### Using HasOne Instead of BelongsTo When Appropriate

```php
// In User model
public function latestActivity()
{
    // More efficient than a belongsTo from Activity
    return $this->hasOne(Activity::class, 'causer_id')
                ->where('causer_type', User::class)
                ->latest();
}
```

## Single Table Inheritance Optimization

### Optimizing Type Column Queries

```php
// Add a specific index for the type column
Schema::table('users', function (Blueprint $table) {
    $table->index('type');
});

// Use type-specific scopes in your models
class User extends Model
{
    public function scopeOfType($query, $type)
    {
        return $query->where('type', $type);
    }
}

// Then use it like this
$admins = User::ofType('admin')->get();
```

### Using Child Models Efficiently

```php
// Instead of filtering the base model
$admins = User::where('type', 'admin')->get();

// Use the child model directly (more efficient with Parental)
$admins = Admin::all();
```

### Caching Type-Specific Queries

```php
$admins = Cache::remember('admins', 3600, function () {
    return Admin::with('permissions')->get();
});
```

## Database Configuration

### MySQL Configuration Optimization

Key MySQL settings for UME applications:

```ini
# In my.cnf

# InnoDB buffer pool size (70-80% of available RAM)
innodb_buffer_pool_size = 1G

# Query cache (for MySQL 5.7 and earlier)
query_cache_type = 1
query_cache_size = 64M

# Temporary table size
tmp_table_size = 64M
max_heap_table_size = 64M

# Connection settings
max_connections = 200
thread_cache_size = 16

# Slow query logging
slow_query_log = 1
slow_query_log_file = /var/log/mysql/mysql-slow.log
long_query_time = 1
```

### PostgreSQL Configuration Optimization

Key PostgreSQL settings for UME applications:

```ini
# In postgresql.conf

# Memory settings
shared_buffers = 1GB
work_mem = 32MB
maintenance_work_mem = 256MB

# Query planning
effective_cache_size = 3GB
random_page_cost = 1.1  # For SSD storage

# Write-ahead log
wal_buffers = 16MB

# Query optimization
default_statistics_target = 100
```

## Scaling Strategies

### Read Replicas

For high-traffic applications, configure read replicas:

```php
// In config/database.php
'mysql' => [
    'read' => [
        'host' => [
            env('DB_HOST_READ_1', '127.0.0.1'),
            env('DB_HOST_READ_2', '127.0.0.1'),
        ],
    ],
    'write' => [
        'host' => env('DB_HOST_WRITE', '127.0.0.1'),
    ],
    // Other configuration...
],
```

### Database Sharding

For extremely large applications, consider sharding:

```php
// Example of a simple sharding strategy based on team_id
class ShardingService
{
    protected $shards = [
        'shard1' => ['teams' => [1, 2, 3, 4, 5]],
        'shard2' => ['teams' => [6, 7, 8, 9, 10]],
        // More shards...
    ];
    
    public function getConnectionForTeam($teamId)
    {
        foreach ($this->shards as $shard => $config) {
            if (in_array($teamId, $config['teams'])) {
                return $shard;
            }
        }
        
        return 'default';
    }
}

// Usage in a model
public function getConnection()
{
    return app(ShardingService::class)->getConnectionForTeam($this->team_id);
}
```

> **Note**: Sharding is an advanced technique and should only be used when other scaling strategies are insufficient. It adds significant complexity to your application.

## Monitoring and Profiling

### Using Laravel Telescope

```php
// In config/telescope.php
'watchers' => [
    Telescope\Watchers\QueryWatcher::class => [
        'enabled' => env('TELESCOPE_QUERY_WATCHER', true),
        'slow' => 100,
    ],
],
```

### Using Laravel Debugbar

```php
// In a service provider
if (app()->environment('local')) {
    Debugbar::enable();
    Debugbar::startMeasure('query-execution', 'Time for executing queries');
    // Your code here
    Debugbar::stopMeasure('query-execution');
}
```

### Identifying Slow Queries

```php
// Enable MySQL slow query log
DB::statement("SET GLOBAL slow_query_log = 'ON'");
DB::statement("SET GLOBAL slow_query_log_file = '/var/log/mysql/mysql-slow.log'");
DB::statement("SET GLOBAL long_query_time = 1");

// Or log slow queries in Laravel
DB::listen(function ($query) {
    if ($query->time > 100) { // 100ms threshold
        Log::channel('queries')->info('Slow query: ' . $query->sql, [
            'bindings' => $query->bindings,
            'time' => $query->time,
        ]);
    }
});
```

## Maintenance Procedures

### Regular Database Maintenance

Schedule regular maintenance tasks:

```php
// In App\Console\Kernel.php
protected function schedule(Schedule $schedule)
{
    // Analyze tables weekly
    $schedule->command('db:analyze')->weekly();
    
    // Optimize tables monthly
    $schedule->command('db:optimize')->monthly();
    
    // Update statistics weekly
    $schedule->command('db:stats')->weekly();
}
```

### Implementing the Commands

```php
// In a custom console command
public function handle()
{
    if (config('database.default') === 'mysql') {
        $tables = ['users', 'teams', 'permissions', 'roles', 'model_has_permissions'];
        
        foreach ($tables as $table) {
            $this->info("Analyzing table: {$table}");
            DB::statement("ANALYZE TABLE {$table}");
        }
    }
}
```

### Database Backups

Implement regular database backups:

```php
// Using Laravel Backup package
// In config/backup.php
'backup' => [
    'name' => env('APP_NAME', 'laravel-backup'),
    'source' => [
        'files' => [
            'include' => [
                base_path(),
            ],
            'exclude' => [
                base_path('vendor'),
                base_path('node_modules'),
            ],
            'follow_links' => false,
        ],
        'databases' => [
            'mysql',
        ],
    ],
    // Other configuration...
],
```

## Conclusion

Database optimization is critical for maintaining the performance of your UME implementation as it scales. By implementing proper indexing, query optimization, and regular maintenance procedures, you can ensure your application remains fast and responsive even with large numbers of users and complex permission structures.

Remember that database optimization is an ongoing process. Regularly monitor your application's performance, identify bottlenecks, and refine your optimization strategies as your application grows.

## Next Steps

- [Caching Strategies](./050-caching-strategies.md)
- [Scaling Considerations](./070-scaling-considerations.md)
- [Performance Optimization Guide](./040-performance-optimization.md)
