# 1. Chinook Database Models Guide

> **Refactored from:** `.ai/guides/chinook/010-chinook-models-guide.md` on 2025-07-11  
> **Focus:** Single taxonomy system using aliziodev/laravel-taxonomy package exclusively

## 1.1. Table of Contents

- [1.2. Overview](#12-overview)
  - [1.2.1. Modern Laravel 12 Features](#121-modern-laravel-12-features)
  - [1.2.2. Database Schema Overview](#122-database-schema-overview)
  - [1.2.3. Required Packages](#123-required-packages)
- [1.3. Model Architecture](#13-model-architecture)
  - [1.3.1. Base Model Traits](#131-base-model-traits)
  - [1.3.2. Taxonomy Integration](#132-taxonomy-integration)
  - [1.3.3. Performance Considerations](#133-performance-considerations)
- [1.4. Core Music Models](#14-core-music-models)
  - [1.4.1. Artist Model](#141-Artist-model)
  - [1.4.2. Album Model](#142-Album-model)
  - [1.4.3. Track Model](#143-Track-model)
  - [1.4.4. MediaType Model](#144-MediaType-model)
- [2. Customer & Employee Models](#2-customer--employee-models)
  - [2.1. Customer Model](#21-Customer-model)
  - [2.2. Employee Model](#22-Employee-model)
- [3. Sales Models](#3-sales-models)
  - [3.1. Invoice Model](#31-Invoice-model)
  - [3.2. InvoiceLine Model](#32-Invoiceline-model)
- [4. Playlist Models](#4-playlist-models)
  - [4.1. Playlist Model](#41-Playlist-model)
- [5. Taxonomy Models](#5-taxonomy-models)
  - [5.1. Genre Model](#51-Genre-model)
- [6. Model Relationships Summary](#6-model-relationships-summary)
  - [6.1. Core Music Relationships](#61-core-music-relationships)
  - [6.2. Taxonomy Relationships](#62-taxonomy-relationships)
  - [6.3. RBAC Relationships](#63-rbac-relationships)
- [7. Testing & Validation](#7-testing--validation)
  - [7.1. Model Testing](#71-model-testing)
  - [7.2. Relationship Testing](#72-relationship-testing)

## 1.2. Overview

This guide provides comprehensive instructions for creating modern Laravel 12 Eloquent models for the Chinook database schema using a **single taxonomy system** approach. The Chinook database represents a digital music store with artists, albums, tracks, customers, employees, and sales data, enhanced with the aliziodev/laravel-taxonomy package for unified categorization.

### 1.2.1. Modern Laravel 12 Features

All models include modern Laravel 12 features:

- **Modern Casting**: Using `casts()` method instead of `$casts` property
- **Single Taxonomy System**: aliziodev/laravel-taxonomy for unified categorization
- **Timestamps**: `created_at` and `updated_at` columns
- **Soft Deletes**: Safe deletion with `deleted_at` column
- **User Stamps**: Track who created/updated records
- **Taxonomies**: Single taxonomy system for all categorization needs
- **Secondary Unique Keys**: Public-facing identifiers using `public_id`
- **Slugs**: URL-friendly identifiers generated from `public_id`

### 1.2.2. Database Schema Overview

The Chinook database consists of interconnected tables with modern Laravel 12 enhancements and single taxonomy system:

- **Core Music Data**: `artists`, `albums`, `tracks`, `media_types`
- **Single Taxonomy System**: aliziodev/laravel-taxonomy package tables (`taxonomies`, `taxonomy_terms`, `taxables`)
- **Genre Compatibility**: `chinook_genres` (preserved for data export/import compatibility)
- **Customer Management**: `customers`, `employees`
- **Sales System**: `invoices`, `invoice_lines`
- **Playlist System**: `playlists`, `playlist_track`

### 1.2.3. Required Packages

Ensure these packages are installed for full functionality:

```bash
# Single taxonomy system (CRITICAL for categorization)
composer require aliziodev/laravel-taxonomy

# Core Laravel features
composer require spatie/laravel-sluggable
composer require glhd/bits

# User stamps (track who created/updated)
composer require wildside/userstamps

# Role-based access control (CRITICAL for enterprise features)
composer require spatie/laravel-permission

# Activity logging (optional but recommended)
composer require spatie/laravel-activitylog

# Media library integration
composer require spatie/laravel-medialibrary
```

## 1.3. Model Architecture

### 1.3.1. Base Model Traits

All Chinook models implement these essential traits:

```php
<?php

declare(strict_types=1);

namespace App\Models\Chinook;

use Aliziodev\LaravelTaxonomy\Traits\HasTaxonomy;
use App\Traits\HasSecondaryUniqueKey;
use Dyrynda\Database\Support\CascadeSoftDeletes;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Mattiverse\Userstamps\Traits\Userstamps;
use Spatie\Comments\Models\Concerns\HasComments;
use Spatie\DeletedModels\Models\Concerns\KeepsDeletedModels;
use Spatie\Sluggable\HasSlug;
use Spatie\Sluggable\SlugOptions;

abstract class BaseModel extends Model
{
    use CascadeSoftDeletes;
    use HasComments;
    use HasFactory;
    use HasSecondaryUniqueKey;
    use HasSlug;
    use HasTaxonomy;
    use KeepsDeletedModels {
        SoftDeletes::restore insteadof KeepsDeletedModels;
        SoftDeletes::restoreQuietly insteadof KeepsDeletedModels;
        KeepsDeletedModels::restore as keepsDeletedModelsRestore;
        KeepsDeletedModels::restoreQuietly as keepsDeletedModelsRestoreQuietly;
    }
    use SoftDeletes;
    use Userstamps;

    /*
     * This string will be used in notifications on what a new comment
     * was made.
     */
    final public function commentableName(): string
    {
        return $this->public_id;
    }

    /*
     * This URL will be used in notifications to let the user know
     * where the comment itself can be read.
     */
    final public function commentUrl(): string
    {
        return $this->slug;
    }

    /**
     * Configure slug generation from public_id
     */
    final public function getSlugOptions(): SlugOptions
    {
        return SlugOptions::create()
            ->generateSlugsFrom('public_id')
            ->saveSlugsTo('slug')
            ->doNotGenerateSlugsOnUpdate();
    }

    /**
     * Configure secondary unique key generation
     */
    final public function getSecondaryUniqueKeyOptions(): array
    {
        return [
            'field' => 'public_id',
            'type' => 'ulid', // or 'uuid', 'snowflake'
        ];
    }

    /**
     * Modern Laravel 12 casting using casts() method
     */
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

### 1.3.2. Taxonomy Integration

The single taxonomy system provides unified categorization across all models:

```php
<?php

declare(strict_types=1);

namespace App\Models\Chinook;

class Track extends BaseModel
{
    // Taxonomy relationships are automatically available via HasTaxonomy trait
    
    /**
     * Get all taxonomy terms for this track
     */
    public function getTaxonomyTermsAttribute()
    {
        return $this->taxonomies()->with('terms')->get();
    }

    /**
     * Assign taxonomy terms to this track
     */
    public function assignTaxonomyTerms(array $termIds): void
    {
        $this->taxonomies()->sync($termIds);
    }

    /**
     * Get tracks by taxonomy term
     */
    public function scopeWithTaxonomyTerm($query, string $termSlug)
    {
        return $query->whereHas('taxonomies.terms', function ($q) use ($termSlug) {
            $q->where('slug', $termSlug);
        });
    }
}
```

### 1.3.3. Performance Considerations

**Eager Loading Strategy**:

```php
// Efficient loading of taxonomy relationships
$tracks = Track::with([
    'taxonomies.terms',
    'album.artist',
    'mediaType'
])->get();

// Optimized taxonomy filtering
$genreTracks = Track::withTaxonomyTerm('rock')
    ->with('taxonomies.terms')
    ->paginate(20);
```

**Caching Strategy**:

```php
// Cache taxonomy hierarchies for performance
$taxonomyHierarchy = Cache::remember('taxonomy_hierarchy', 3600, function () {
    return Taxonomy::with('terms.children')->get();
});
```

## 1.4. Core Music Models

### 1.4.1. Artist Model

```php
<?php

declare(strict_types=1);

namespace App\Models\Chinook;

use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasManyThrough;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Exception;

/**
 * Chinook Artist Model
 *
 * Represents musical artists in the Chinook database.
 * Educational example demonstrating Laravel 12 model patterns,
 * error handling, and performance optimization.
 *
 * @property int $id
 * @property string $name
 * @property string $public_id
 * @property string $slug
 * @property string|null $bio
 * @property string|null $website
 * @property array|null $social_links
 * @property string|null $country
 * @property int|null $formed_year
 * @property bool $is_active
 * @property \Carbon\Carbon $created_at
 * @property \Carbon\Carbon $updated_at
 * @property \Carbon\Carbon|null $deleted_at
 */
class Artist extends BaseModel
{
    /**
     * The table associated with the model.
     * Uses chinook_ prefix as per project conventions.
     */
    protected $table = 'chinook_artists';

    /**
     * The attributes that are mass assignable.
     * Excludes sensitive fields like id, timestamps for security.
     */
    protected $fillable = [
        'name',
        'public_id',
        'slug',
        'bio',
        'website',
        'social_links',
        'country',
        'formed_year',
        'is_active',
    ];

    /**
     * Artist has many albums
     *
     * @return HasMany<Album>
     * @throws Exception When relationship cannot be established
     */
    public function albums(): HasMany
    {
        try {
            return $this->hasMany(Album::class, 'artist_id');
        } catch (Exception $e) {
            Log::error('Failed to load artist albums', [
                'artist_id' => $this->id,
                'error' => $e->getMessage()
            ]);
            throw new Exception("Unable to load albums for artist {$this->name}");
        }
    }

    /**
     * Artist has many tracks through albums
     *
     * @return HasManyThrough<Track>
     * @throws Exception When relationship cannot be established
     */
    public function tracks(): HasManyThrough
    {
        try {
            return $this->hasManyThrough(
                Track::class,
                Album::class,
                'artist_id',    // Foreign key on albums table
                'album_id',     // Foreign key on tracks table
                'id',           // Local key on artists table
                'id'            // Local key on albums table
            );
        } catch (Exception $e) {
            Log::error('Failed to load artist tracks', [
                'artist_id' => $this->id,
                'error' => $e->getMessage()
            ]);
            throw new Exception("Unable to load tracks for artist {$this->name}");
        }
    }

    /**
     * Get route key name for URL generation
     * Uses slug for SEO-friendly URLs
     */
    public function getRouteKeyName(): string
    {
        return 'slug';
    }

    /**
     * Get the total number of albums for this artist
     *
     * @return int
     * @throws Exception When count cannot be retrieved
     */
    public function getAlbumsCount(): int
    {
        try {
            return Cache::remember(
                "artist_{$this->id}_albums_count",
                now()->addHour(),
                fn() => $this->albums()->count()
            );
        } catch (Exception $e) {
            Log::error('Failed to count artist albums', [
                'artist_id' => $this->id,
                'error' => $e->getMessage()
            ]);
            return 0; // Graceful fallback
        }
    }

    /**
     * Get the total number of tracks for this artist
     *
     * @return int
     * @throws Exception When count cannot be retrieved
     */
    public function getTracksCount(): int
    {
        try {
            return Cache::remember(
                "artist_{$this->id}_tracks_count",
                now()->addHour(),
                fn() => $this->tracks()->count()
            );
        } catch (Exception $e) {
            Log::error('Failed to count artist tracks', [
                'artist_id' => $this->id,
                'error' => $e->getMessage()
            ]);
            return 0; // Graceful fallback
        }
    }

    /**
     * Scope to filter active artists only
     *
     * @param Builder $query
     * @return Builder
     */
    public function scopeActive(Builder $query): Builder
    {
        return $query->where('is_active', true);
    }

    /**
     * Scope to filter artists by country
     *
     * @param Builder $query
     * @param string $country
     * @return Builder
     */
    public function scopeFromCountry(Builder $query, string $country): Builder
    {
        return $query->where('country', $country);
    }

    /**
     * Get popular artists based on album count
     *
     * @param int $limit
     * @return Collection<Artist>
     */
    public static function getPopularArtists(int $limit = 10): Collection
    {
        try {
            return Cache::remember(
                "popular_artists_{$limit}",
                now()->addHours(6),
                fn() => static::withCount('albums')
                    ->active()
                    ->orderByDesc('albums_count')
                    ->limit($limit)
                    ->get()
            );
        } catch (Exception $e) {
            Log::error('Failed to get popular artists', [
                'limit' => $limit,
                'error' => $e->getMessage()
            ]);
            return collect(); // Return empty collection on error
        }
    }

    /**
     * Modern Laravel 12 casting using casts() method
     * Merges with parent casts for inheritance
     */
    protected function casts(): array
    {
        return array_merge(parent::casts(), [
            'social_links' => 'array',
            'formed_year' => 'integer',
            'is_active' => 'boolean',
        ]);
    }
}
```

### 1.4.2. Album Model

```php
<?php

declare(strict_types=1);

namespace App\Models\Chinook;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

use function sprintf;

class Album extends BaseModel
{
    protected $table = 'chinook_albums';

    protected $fillable = [
        'title',
        'artist_id',
        'public_id',
        'slug',
        'release_date',
        'label',
        'catalog_number',
        'total_tracks',
        'duration_seconds',
        'description',
        'is_compilation',
    ];

    /**
     * Album belongs to an artist
     */
    public function artist(): BelongsTo
    {
        return $this->belongsTo(Artist::class, 'artist_id');
    }

    /**
     * Album has many tracks
     */
    public function tracks(): HasMany
    {
        return $this->hasMany(Track::class, 'album_id');
    }

    /**
     * Get formatted duration
     */
    public function getFormattedDurationAttribute(): string
    {
        $minutes = floor($this->duration_seconds / 60);
        $seconds = $this->duration_seconds % 60;

        return sprintf('%d:%02d', $minutes, $seconds);
    }

    /**
     * Get a route key name for URL generation
     */
    public function getRouteKeyName(): string
    {
        return 'slug';
    }

    /**
     * @return array
     */
    protected function casts(): array
    {
        return array_merge(parent::casts(), [
            'release_date' => 'date',
            'total_tracks' => 'integer',
            'duration_seconds' => 'integer',
            'is_compilation' => 'boolean',
        ]);
    }
}
```

### 1.4.3. Track Model

```php
<?php

declare(strict_types=1);

namespace App\Models\Chinook;

use Illuminate\Database\Eloquent\Attributes\Scope;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Track extends BaseModel
{
    protected $table = 'chinook_tracks';

    protected $fillable = [
        'name',
        'album_id',
        'media_type_id',
        'public_id',
        'slug',
        'composer',
        'milliseconds',
        'bytes',
        'unit_price',
        'track_number',
        'disc_number',
        'lyrics',
        'isrc',
        'explicit_content',
    ];

    /**
     * Track belongs to an album
     */
    public function album(): BelongsTo
    {
        return $this->belongsTo(Album::class, 'album_id');
    }

    /**
     * Track belongs to a media type
     */
    public function mediaType(): BelongsTo
    {
        return $this->belongsTo(MediaType::class, 'media_type_id');
    }

    /**
     * Track belongs to many playlists
     */
    public function playlists(): BelongsToMany
    {
        return $this->belongsToMany(Playlist::class, 'chinook_playlist_track', 'track_id', 'playlist_id')
            ->withPivot('position')
            ->withTimestamps();
    }

    /**
     * Track has many invoice lines
     */
    public function invoiceLines(): HasMany
    {
        return $this->hasMany(InvoiceLine::class, 'track_id');
    }

    /**
     * Get artist through album relationship
     */
    public function artist()
    {
        return $this->hasOneThrough(Artist::class, Album::class, 'id', 'id', 'album_id', 'artist_id');
    }

    /**
     * Get formatted duration
     */
    public function getFormattedDurationAttribute(): string
    {
        $totalSeconds = floor($this->milliseconds / 1000);
        $minutes = floor($totalSeconds / 60);
        $seconds = $totalSeconds % 60;

        return sprintf('%d:%02d', $minutes, $seconds);
    }

    /**
     * Get formatted file size
     */
    public function getFormattedSizeAttribute(): string
    {
        if ($this->bytes < 1024) {
            return $this->bytes.' B';
        }
        if ($this->bytes < 1048576) {
            return round($this->bytes / 1024, 2).' KB';
        }

        return round($this->bytes / 1048576, 2).' MB';

    }

    /**
     * Get a route key name for URL generation
     */
    public function getRouteKeyName(): string
    {
        return 'slug';
    }

    /**
     * Modern Laravel 12 casting using casts() method
     */
    protected function casts(): array
    {
        return array_merge(parent::casts(), [
            'milliseconds' => 'integer',
            'bytes' => 'integer',
            'unit_price' => 'decimal:2',
            'track_number' => 'integer',
            'disc_number' => 'integer',
            'explicit_content' => 'boolean',
        ]);
    }

    /**
     * Scope for tracks with specific taxonomy terms
     */
    #[Scope]
    protected function withTaxonomyTerm($query, string $termSlug)
    {
        return $query->whereHas('taxonomies.terms', function ($q) use ($termSlug) {
            $q->where('slug', $termSlug);
        });
    }
}
```

### 1.4.4. MediaType Model

```php
<?php

declare(strict_types=1);

namespace App\Models\Chinook;

use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 *
 */
class MediaType extends BaseModel
{
    protected $table = 'chinook_media_types';

    protected $fillable = [
        'name',
        'public_id',
        'slug',
        'mime_type',
        'file_extension',
        'description',
        'is_active',
    ];

    /**
     * Media type has many tracks
     */
    public function tracks(): HasMany
    {
        return $this->hasMany(Track::class, 'media_type_id');
    }

    /**
     * Get a route key name for URL generation
     */
    public function getRouteKeyName(): string
    {
        return 'slug';
    }

    protected function casts(): array
    {
        return array_merge(parent::casts(), [
            'is_active' => 'boolean',
        ]);
    }
}
```

## 2. Customer & Employee Models

### 2.1. Customer Model

```php
<?php

declare(strict_types=1);

namespace App\Models\Chinook;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Customer extends BaseModel
{
    protected $table = 'chinook_customers';

    protected $fillable = [
        'first_name',
        'last_name',
        'company',
        'address',
        'city',
        'state',
        'country',
        'postal_code',
        'phone',
        'fax',
        'email',
        'support_rep_id',
        'public_id',
        'slug',
        'date_of_birth',
        'preferred_language',
        'marketing_consent',
    ];

    /**
     * Customer belongs to a support representative (employee)
     */
    public function supportRep(): BelongsTo
    {
        return $this->belongsTo(Employee::class, 'support_rep_id');
    }

    /**
     * Customer has many invoices
     */
    public function invoices(): HasMany
    {
        return $this->hasMany(Invoice::class, 'customer_id');
    }

    /**
     * Get full name attribute
     */
    public function getFullNameAttribute(): string
    {
        return mb_trim($this->first_name.' '.$this->last_name);
    }

    /**
     * Get route key name for URL generation
     */
    public function getRouteKeyName(): string
    {
        return 'slug';
    }

    protected function casts(): array
    {
        return array_merge(parent::casts(), [
            'date_of_birth' => 'date',
            'marketing_consent' => 'boolean',
        ]);
    }
}
```

### 2.2. Employee Model

```php
<?php

declare(strict_types=1);

namespace App\Models\Chinook;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Employee extends BaseModel
{
    protected $table = 'chinook_employees';

    protected $fillable = [
        'last_name',
        'first_name',
        'title',
        'reports_to',
        'birth_date',
        'hire_date',
        'address',
        'city',
        'state',
        'country',
        'postal_code',
        'phone',
        'fax',
        'email',
        'public_id',
        'slug',
        'department',
        'salary',
        'is_active',
    ];

    /**
     * Employee reports to another employee (manager)
     */
    public function manager(): BelongsTo
    {
        return $this->belongsTo(self::class, 'reports_to');
    }

    /**
     * Employee has many subordinates
     */
    public function subordinates(): HasMany
    {
        return $this->hasMany(self::class, 'reports_to');
    }

    /**
     * Employee supports many customers
     */
    public function customers(): HasMany
    {
        return $this->hasMany(Customer::class, 'support_rep_id');
    }

    /**
     * Get full name attribute
     */
    public function getFullNameAttribute(): string
    {
        return mb_trim($this->first_name.' '.$this->last_name);
    }

    /**
     * Get route key name for URL generation
     */
    public function getRouteKeyName(): string
    {
        return 'slug';
    }

    protected function casts(): array
    {
        return array_merge(parent::casts(), [
            'birth_date' => 'date',
            'hire_date' => 'date',
            'salary' => 'integer',
            'is_active' => 'boolean',
        ]);
    }
}
```

## 3. Sales Models

### 3.1. Invoice Model

```php
<?php

declare(strict_types=1);

namespace App\Models\Chinook;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Invoice extends BaseModel
{
    protected $table = 'chinook_invoices';

    protected $fillable = [
        'customer_id',
        'invoice_date',
        'billing_address',
        'billing_city',
        'billing_state',
        'billing_country',
        'billing_postal_code',
        'total',
        'public_id',
        'slug',
        'payment_method',
        'payment_status',
        'notes',
    ];

    /**
     * Invoice belongs to a customer
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class, 'customer_id');
    }

    /**
     * Invoice has many invoice lines
     */
    public function invoiceLines(): HasMany
    {
        return $this->hasMany(InvoiceLine::class, 'invoice_id');
    }

    /**
     * Get a route key name for URL generation
     */
    public function getRouteKeyName(): string
    {
        return 'slug';
    }

    /**
     * Modern Laravel 12 casting using casts() method
     */
    protected function casts(): array
    {
        return array_merge(parent::casts(), [
            'invoice_date' => 'datetime',
            'total' => 'decimal:2',
        ]);
    }
}
```

### 3.2. InvoiceLine Model

```php
<?php

declare(strict_types=1);

namespace App\Models\Chinook;

use Illuminate\Database\Eloquent\Relations\BelongsTo;

class InvoiceLine extends BaseModel
{
    protected $table = 'chinook_invoice_lines';

    protected $fillable = [
        'invoice_id',
        'track_id',
        'unit_price',
        'quantity',
        'public_id',
        'slug',
        'discount_percentage',
        'line_total',
    ];

    /**
     * Invoice line belongs to an invoice
     */
    public function invoice(): BelongsTo
    {
        return $this->belongsTo(Invoice::class, 'invoice_id');
    }

    /**
     * Invoice line belongs to a track
     */
    public function track(): BelongsTo
    {
        return $this->belongsTo(Track::class, 'track_id');
    }

    /**
     * Get route key name for URL generation
     */
    public function getRouteKeyName(): string
    {
        return 'slug';
    }

    /**
     * Calculate line total automatically
     */
    protected static function boot()
    {
        parent::boot();

        self::saving(function ($invoiceLine) {
            $subtotal = $invoiceLine->unit_price * $invoiceLine->quantity;
            $discount = $subtotal * ($invoiceLine->discount_percentage / 100);
            $invoiceLine->line_total = $subtotal - $discount;
        });
    }

    protected function casts(): array
    {
        return array_merge(parent::casts(), [
            'unit_price' => 'decimal:2',
            'quantity' => 'integer',
            'discount_percentage' => 'decimal:2',
            'line_total' => 'decimal:2',
        ]);
    }
}
```

## 4. Playlist Models

### 4.1. Playlist Model

```php
<?php

declare(strict_types=1);

namespace App\Models\Chinook;

use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Playlist extends BaseModel
{
    protected $table = 'chinook_playlists';

    protected $fillable = [
        'name',
        'public_id',
        'slug',
        'description',
        'is_public',
        'total_duration',
        'track_count',
    ];

    /**
     * Playlist belongs to many tracks
     */
    public function tracks(): BelongsToMany
    {
        return $this->belongsToMany(Track::class, 'chinook_playlist_track', 'playlist_id', 'track_id')
            ->withPivot('position')
            ->withTimestamps()
            ->orderBy('pivot_position');
    }

    /**
     * Get formatted duration
     */
    public function getFormattedDurationAttribute(): string
    {
        $totalSeconds = floor($this->total_duration / 1000);
        $hours = floor($totalSeconds / 3600);
        $minutes = floor(($totalSeconds % 3600) / 60);
        $seconds = $totalSeconds % 60;

        if ($hours > 0) {
            return sprintf('%d:%02d:%02d', $hours, $minutes, $seconds);
        }

        return sprintf('%d:%02d', $minutes, $seconds);
    }

    /**
     * Get route key name for URL generation
     */
    public function getRouteKeyName(): string
    {
        return 'slug';
    }

    /**
     * Modern Laravel 12 casting using casts() method
     */
    protected function casts(): array
    {
        return array_merge(parent::casts(), [
            'is_public' => 'boolean',
            'total_duration' => 'integer',
            'track_count' => 'integer',
        ]);
    }
}
```

## 5. Taxonomy Models

### 5.1. Genre Model

```php
<?php

declare(strict_types=1);

namespace App\Models\Chinook;

use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Genre Model - Preserved for compatibility
 *
 * This model is maintained for data export/import compatibility
 * with the original Chinook database structure. For new implementations,
 * use the aliziodev/laravel-taxonomy package exclusively.
 */
class Genre extends BaseModel
{
    protected $table = 'chinook_genres';

    protected $fillable = [
        'name',
        'public_id',
        'slug',
        'description',
        'is_active',
    ];

    /**
     * Genre has many tracks (legacy relationship)
     *
     * @deprecated Use taxonomy relationships instead
     */
    public function tracks(): HasMany
    {
        return $this->hasMany(Track::class, 'genre_id');
    }

    /**
     * Get corresponding taxonomy term
     */
    public function getTaxonomyTermAttribute()
    {
        return \Aliziodev\LaravelTaxonomy\Models\TaxonomyTerm::where('name', $this->name)->first();
    }

    /**
     * Get a route key name for URL generation
     */
    public function getRouteKeyName(): string
    {
        return 'slug';
    }

    /**
     * Modern Laravel 12 casting using casts() method
     */
    protected function casts(): array
    {
        return array_merge(parent::casts(), [
            'is_active' => 'boolean',
        ]);
    }
}
```

## 6. Model Relationships Summary

### 6.1. Core Music Relationships

- **Artists → Albums**: One-to-many relationship
- **Albums → Tracks**: One-to-many relationship
- **Tracks → Media Types**: Many-to-one relationship
- **Tracks → Playlists**: Many-to-many through pivot table

### 6.2. Taxonomy Relationships

All models can have taxonomy relationships through the `HasTaxonomy` trait:

```php
// Assign taxonomy terms to any model
$track->taxonomies()->attach($taxonomyTermIds);

// Query models by taxonomy
$rockTracks = Track::withTaxonomyTerm('rock')->get();

// Get all taxonomy terms for a model
$trackTaxonomies = $track->taxonomies()->with('terms')->get();
```

### 6.3. RBAC Relationships

- **Users → Roles**: Many-to-many with spatie/laravel-permission
- **Roles → Permissions**: Many-to-many with granular permission system
- **Model Policies**: Resource-based authorization with hierarchical inheritance

## 7. Testing & Validation

### 7.1. Model Testing

```php
<?php

use App\Models\Chinook\Track;
use App\Models\Chinook\Album;
use App\Models\Chinook\Artist;

describe('Track Model', function () {
    it('can create a track with taxonomy terms', function () {
        $track = Track::factory()->create();

        $taxonomyTerm = \Aliziodev\LaravelTaxonomy\Models\TaxonomyTerm::factory()->create([
            'name' => 'Rock'
        ]);

        $track->taxonomies()->attach($taxonomyTerm->id);

        expect($track->taxonomies)->toHaveCount(1);
        expect($track->taxonomies->first()->name)->toBe('Rock');
    });

    it('can query tracks by taxonomy term', function () {
        $rockTrack = Track::factory()->create();
        $jazzTrack = Track::factory()->create();

        $rockTerm = \Aliziodev\LaravelTaxonomy\Models\TaxonomyTerm::factory()->create([
            'name' => 'Rock',
            'slug' => 'rock'
        ]);

        $rockTrack->taxonomies()->attach($rockTerm->id);

        $results = Track::withTaxonomyTerm('rock')->get();

        expect($results)->toHaveCount(1);
        expect($results->first()->id)->toBe($rockTrack->id);
    });
});
```

### 7.2. Relationship Testing

```php
describe('Model Relationships', function () {
    it('maintains proper artist-album-track hierarchy', function () {
        $artist = Artist::factory()->create();
        $album = Album::factory()->create(['artist_id' => $artist->id]);
        $track = Track::factory()->create(['album_id' => $album->id]);

        expect($track->album->id)->toBe($album->id);
        expect($track->album->artist->id)->toBe($artist->id);
        expect($artist->albums)->toHaveCount(1);
        expect($album->tracks)->toHaveCount(1);
    });
});
```

---

**Documentation Standards**: This document follows WCAG 2.1 AA accessibility guidelines and uses Laravel 12 modern syntax patterns.

**Last Updated:** 2025-07-16
**Maintainer:** Technical Documentation Team
**Source:** [GitHub Repository](https://github.com/s-a-c/chinook)

<<<<<<
[Back](020-table-naming-conventions.md) | [Forward](040-migrations-guide.md)
[Top](#chinook-models-guide)
<<<<<<
