# Troubleshooting Guide

**Version:** 1.0  
**Created:** 2025-07-16  
**Last Updated:** 2025-07-16  
**Scope:** Common issues and solutions for Chinook project

## Table of Contents

1. [Overview](#1-overview)
2. [Installation Issues](#2-installation-issues)
3. [Database Problems](#3-database-problems)
4. [Filament Panel Issues](#4-filament-panel-issues)
5. [Performance Problems](#5-performance-problems)
6. [Package Conflicts](#6-package-conflicts)

## 1. Overview

This guide provides solutions to common issues encountered when working with the Chinook project. Each section includes symptoms, causes, and step-by-step solutions.

### 1.1 Getting Help

- **Check Logs:** Always check Laravel logs first: `storage/logs/laravel.log`
- **Debug Mode:** Enable debug mode in `.env`: `APP_DEBUG=true`
- **Error Reporting:** Ensure error reporting is enabled during development

## 2. Installation Issues

### 2.1 Composer Installation Failures

**Symptoms:**
- `composer install` fails with dependency conflicts
- Package version requirements not met
- Memory limit exceeded during installation

**Solutions:**

```bash
# Clear Composer cache
composer clear-cache

# Update Composer to latest version
composer self-update

# Install with increased memory limit
php -d memory_limit=2G composer install

# Force package resolution (use with caution)
composer install --ignore-platform-reqs

# Check PHP extensions
php -m | grep -E "(sqlite3|pdo_sqlite|mbstring|openssl)"
```

### 2.2 Laravel Key Generation Issues

**Symptoms:**
- "No application encryption key has been specified"
- Application fails to start

**Solutions:**

```bash
# Generate application key
php artisan key:generate

# Verify .env file exists
cp .env.example .env

# Check .env file permissions
chmod 644 .env

# Verify APP_KEY is set in .env
grep APP_KEY .env
```

### 2.3 Database Migration Failures

**Symptoms:**
- Migration fails with "table already exists"
- Foreign key constraint errors
- SQLite database file not found

**Solutions:**

```bash
# Reset and re-run migrations
php artisan migrate:fresh

# Check database file permissions (SQLite)
ls -la database/database.sqlite
chmod 664 database/database.sqlite

# Create SQLite database file if missing
touch database/database.sqlite

# Run migrations with verbose output
php artisan migrate --verbose

# Check migration status
php artisan migrate:status
```

## 3. Database Problems

### 3.1 SQLite Connection Issues

**Symptoms:**
- "Database file not found" errors
- "Permission denied" when accessing database
- Connection timeouts

**Solutions:**

```bash
# Create database file
touch database/database.sqlite

# Set proper permissions
chmod 664 database/database.sqlite
chmod 775 database/

# Verify database configuration in .env
DB_CONNECTION=sqlite
DB_DATABASE=/absolute/path/to/database/database.sqlite

# Test database connection
php artisan tinker
>>> DB::connection()->getPdo();
```

### 3.2 Foreign Key Constraint Errors

**Symptoms:**
- "FOREIGN KEY constraint failed" during seeding
- Cannot delete records with dependencies
- Migration rollback failures

**Solutions:**

```php
// Temporarily disable foreign key checks (SQLite)
DB::statement('PRAGMA foreign_keys=OFF;');
// Your operations here
DB::statement('PRAGMA foreign_keys=ON;');

// Check constraint violations
DB::select('PRAGMA foreign_key_check;');

// Verify table structure
DB::select('PRAGMA table_info(chinook_artists);');
```

### 3.3 Seeding Failures

**Symptoms:**
- Seeder fails with duplicate key errors
- Factory creation fails
- Memory exhaustion during seeding

**Solutions:**

```bash
# Clear existing data before seeding
php artisan migrate:fresh --seed

# Run specific seeder
php artisan db:seed --class=ArtistSeeder

# Increase memory limit for seeding
php -d memory_limit=1G artisan db:seed

# Use chunked seeding for large datasets
# In your seeder:
Artist::factory()->count(1000)->create();
// becomes:
collect(range(1, 10))->each(function () {
    Artist::factory()->count(100)->create();
});
```

## 4. Filament Panel Issues

### 4.1 Panel Access Problems

**Symptoms:**
- 404 error when accessing `/chinook-fm`
- Login page not found
- Authentication failures

**Solutions:**

```bash
# Verify Filament installation
composer show filament/filament

# Check panel configuration
php artisan filament:list-panels

# Clear application cache
php artisan cache:clear
php artisan config:clear
php artisan route:clear

# Verify panel provider is registered
grep -r "ChinookPanelProvider" config/app.php
```

### 4.2 Resource Registration Issues

**Symptoms:**
- Resources not appearing in navigation
- "Class not found" errors
- Resource pages return 404

**Solutions:**

```php
// Check resource registration in Panel provider
// app/Providers/Filament/ChinookPanelProvider.php
public function panel(Panel $panel): Panel
{
    return $panel
        ->id('chinook-fm')
        ->resources([
            \App\Filament\Resources\ArtistResource::class,
            \App\Filament\Resources\AlbumResource::class,
            // ... other resources
        ]);
}

// Verify resource class exists
php artisan make:filament-resource Artist --model=App\\Models\\Chinook\\Artist

// Check namespace and imports
namespace App\Filament\Resources;
use App\Models\Chinook\Artist;
```

### 4.3 Form Validation Errors

**Symptoms:**
- Form submissions fail silently
- Validation messages not displayed
- Data not saving to database

**Solutions:**

```php
// Check form schema in resource
public static function form(Form $form): Form
{
    return $form->schema([
        TextInput::make('name')
            ->required()
            ->maxLength(255)
            ->helperText('Enter the artist name'),
        
        // Add validation rules
        TextInput::make('website')
            ->url()
            ->nullable(),
    ]);
}

// Verify model fillable attributes
protected $fillable = [
    'name',
    'bio',
    'website',
    // ... other fields
];

// Check for mass assignment protection
protected $guarded = []; // or specific fields
```

## 5. Performance Problems

### 5.1 Slow Query Performance

**Symptoms:**
- Pages load slowly
- Database timeouts
- High memory usage

**Solutions:**

```php
// Enable query logging to identify slow queries
DB::enableQueryLog();
// Your code here
dd(DB::getQueryLog());

// Add database indexes
Schema::table('chinook_artists', function (Blueprint $table) {
    $table->index('name');
    $table->index('country');
    $table->index(['is_active', 'created_at']);
});

// Use eager loading to prevent N+1 queries
$artists = Artist::with(['albums', 'tracks'])->get();

// Implement caching for expensive operations
Cache::remember('popular_artists', 3600, function () {
    return Artist::withCount('albums')
        ->orderByDesc('albums_count')
        ->limit(10)
        ->get();
});
```

### 5.2 Memory Exhaustion

**Symptoms:**
- "Fatal error: Allowed memory size exhausted"
- Application crashes during large operations
- Slow response times

**Solutions:**

```bash
# Increase PHP memory limit
php -d memory_limit=512M artisan command

# Use chunked processing for large datasets
Artist::chunk(100, function ($artists) {
    foreach ($artists as $artist) {
        // Process artist
    }
});

# Use lazy collections for memory efficiency
Artist::lazy()->each(function ($artist) {
    // Process artist
});

# Clear unnecessary data
unset($largeVariable);
gc_collect_cycles();
```

## 6. Package Conflicts

### 6.1 Laravel Taxonomy Issues

**Symptoms:**
- Trait not found errors
- Migration conflicts
- Relationship errors

**Solutions:**

```bash
# Verify package installation
composer show aliziodev/laravel-taxonomy

# Publish package migrations
php artisan vendor:publish --provider="Aliziodev\LaravelTaxonomy\TaxonomyServiceProvider"

# Check trait usage in models
use Aliziodev\LaravelTaxonomy\Traits\HasTaxonomy;

class Artist extends BaseModel
{
    use HasTaxonomy; // Correct trait name (singular)
}

# Verify taxonomy relationships
$artist = Artist::first();
$artist->attachTerm($term);
```

### 6.2 Filament Plugin Conflicts

**Symptoms:**
- Plugin features not working
- JavaScript errors in browser console
- Style conflicts

**Solutions:**

```bash
# Clear Filament cache
php artisan filament:clear-cached-components

# Rebuild assets
npm run build

# Check plugin registration
// In panel provider
->plugins([
    \Filament\SpatieLaravelMediaLibraryPlugin::class,
    // Other plugins
])

# Verify plugin compatibility
composer show | grep filament
```

---

## Navigation

- **Previous:** [Error Handling Guide](./200-error-handling-guide.md)
- **Next:** [Performance Optimization](./performance/000-performance-index.md)
- **Index:** [Chinook Documentation Index](./000-chinook-index.md)

## Related Documentation

- [Implementation Quickstart Guide](./000-implementation-quickstart-guide.md)
- [Database Configuration Guide](./000-database-configuration-guide.md)

---

**Last Updated:** 2025-07-16  
**Maintainer:** Technical Documentation Team  
**Source:** [GitHub Repository](https://github.com/s-a-c/chinook)
