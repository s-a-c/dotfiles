# Table Naming Conventions

> **Created:** 2025-07-16  
> **Focus:** Chinook project table naming standards and implementation  
> **Source:** [Stakeholder Decision CI2](https://github.com/s-a-c/chinook/blob/main/.ai/reports/chinook/2025-07-16/documentation-review/inconsistencies-and-questions.md)

## 1. Table of Contents

- [1.1. Overview](#11-overview)
- [1.2. Naming Convention Rules](#12-naming-convention-rules)
- [1.3. Implementation Examples](#13-implementation-examples)
- [1.4. Model Namespace Structure](#14-model-namespace-structure)
- [1.5. Database Schema Consistency](#15-database-schema-consistency)
- [1.6. Migration Patterns](#16-migration-patterns)

## 1.1. Overview

The Chinook project follows a consistent table naming convention to maintain source data compatibility while providing clean model naming. This document establishes the official naming standards for all database tables and corresponding Laravel models.

### 1.1.1. Stakeholder Decision

**Decision Reference:** CI2 - Table Naming Convention Conflicts  
**Status:** ✅ **RESOLVED** (2025-07-16)  
**Authority:** Project stakeholder decisions

### 1.1.2. Rationale

- **Source Compatibility**: Maintains compatibility with original `chinook.sql` data
- **Namespace Clarity**: Prevents conflicts with other database tables
- **Clean Models**: Provides intuitive model class names without prefixes
- **Educational Focus**: Supports learning objectives with clear patterns

## 1.2. Naming Convention Rules

### 1.2.1. Database Tables

**Rule:** ALL Chinook tables MUST use `chinook_` prefix (snake_case)

| Original Table | Chinook Table | Status |
|----------------|---------------|--------|
| `artists` | `chinook_artists` | ✅ Implemented |
| `albums` | `chinook_albums` | ✅ Implemented |
| `tracks` | `chinook_tracks` | ✅ Implemented |
| `customers` | `chinook_customers` | ✅ Implemented |
| `employees` | `chinook_employees` | ✅ Implemented |
| `invoices` | `chinook_invoices` | ✅ Implemented |
| `invoice_lines` | `chinook_invoice_lines` | ✅ Implemented |
| `playlists` | `chinook_playlists` | ✅ Implemented |
| `playlist_track` | `chinook_playlist_track` | ✅ Implemented |
| `media_types` | `chinook_media_types` | ✅ Implemented |
| `genres` | `chinook_genres` | ✅ Implemented |

### 1.2.2. Laravel Models

**Rule:** Models placed in `App\Models\Chinook` namespace WITHOUT `Chinook` prefix in class names

| Table | Model Class | Namespace |
|-------|-------------|-----------|
| `chinook_artists` | `Artist` | `App\Models\Chinook\Artist` |
| `chinook_albums` | `Album` | `App\Models\Chinook\Album` |
| `chinook_tracks` | `Track` | `App\Models\Chinook\Track` |
| `chinook_customers` | `Customer` | `App\Models\Chinook\Customer` |
| `chinook_employees` | `Employee` | `App\Models\Chinook\Employee` |
| `chinook_invoices` | `Invoice` | `App\Models\Chinook\Invoice` |
| `chinook_invoice_lines` | `InvoiceLine` | `App\Models\Chinook\InvoiceLine` |
| `chinook_playlists` | `Playlist` | `App\Models\Chinook\Playlist` |
| `chinook_media_types` | `MediaType` | `App\Models\Chinook\MediaType` |

## 1.3. Implementation Examples

### 1.3.1. Model Declaration

<augment_code_snippet path="app/Models/Chinook/Artist.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Models\Chinook;

class Artist extends BaseModel
{
    protected $table = 'chinook_artists';
    
    protected $fillable = [
        'name',
        'public_id',
        'slug',
        // ... other fields
    ];
}
````
</augment_code_snippet>

### 1.3.2. Migration Example

<augment_code_snippet path="database/migrations/create_chinook_artists_table.php" mode="EXCERPT">
````php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('chinook_artists', function (Blueprint $table) {
            $table->id();
            $table->ulid('public_id')->unique();
            $table->string('slug')->unique();
            $table->string('name');
            // ... other columns
            $table->timestamps();
        });
    }
};
````
</augment_code_snippet>

### 1.3.3. Relationship Usage

<augment_code_snippet path="app/Models/Chinook/Album.php" mode="EXCERPT">
````php
public function artist(): BelongsTo
{
    return $this->belongsTo(Artist::class, 'artist_id');
}

public function tracks(): HasMany
{
    return $this->hasMany(Track::class, 'album_id');
}
````
</augment_code_snippet>

## 1.4. Model Namespace Structure

### 1.4.1. Directory Organization

```
app/
└── Models/
    └── Chinook/
        ├── BaseModel.php
        ├── Artist.php
        ├── Album.php
        ├── Track.php
        ├── Customer.php
        ├── Employee.php
        ├── Invoice.php
        ├── InvoiceLine.php
        ├── Playlist.php
        └── MediaType.php
```

### 1.4.2. Base Model Pattern

<augment_code_snippet path="app/Models/Chinook/BaseModel.php" mode="EXCERPT">
````php
<?php

namespace App\Models\Chinook;

use Aliziodev\LaravelTaxonomy\Traits\HasTaxonomy;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

abstract class BaseModel extends Model
{
    use HasTaxonomy;
    use SoftDeletes;
    
    // Common functionality for all Chinook models
}
````
</augment_code_snippet>

## 1.5. Database Schema Consistency

### 1.5.1. Schema File Standards

- **DBML Schema**: Uses `chinook_` prefix for all table definitions
- **SQL Source**: Original `chinook.sql` remains unchanged (source data)
- **Migrations**: All new migrations use `chinook_` prefix
- **Seeders**: Reference tables with `chinook_` prefix

### 1.5.2. Index Naming

```sql
-- Index naming follows table prefix
CREATE INDEX idx_chinook_artists_name ON chinook_artists(name);
CREATE INDEX idx_chinook_albums_artist_title ON chinook_albums(artist_id, title);
CREATE INDEX idx_chinook_tracks_album_number ON chinook_tracks(album_id, track_number);
```

## 1.6. Migration Patterns

### 1.6.1. Foreign Key Conventions

<augment_code_snippet path="database/migrations/create_chinook_albums_table.php" mode="EXCERPT">
````php
Schema::create('chinook_albums', function (Blueprint $table) {
    $table->id();
    $table->foreignId('artist_id')
          ->constrained('chinook_artists')
          ->onDelete('cascade');
    $table->string('title');
    $table->timestamps();
});
````
</augment_code_snippet>

### 1.6.2. Pivot Table Naming

```php
// Pivot tables also use chinook_ prefix
Schema::create('chinook_playlist_track', function (Blueprint $table) {
    $table->id();
    $table->foreignId('playlist_id')->constrained('chinook_playlists');
    $table->foreignId('track_id')->constrained('chinook_tracks');
    $table->integer('position')->default(0);
    $table->timestamps();
});
```

---

**Documentation Standards**: This document follows WCAG 2.1 AA accessibility guidelines and uses Laravel 12 modern syntax patterns.

<<<<<<
[Back](010-configuration-guide.md) | [Forward](030-models-guide.md)
[Top](#table-naming-conventions)
<<<<<<
