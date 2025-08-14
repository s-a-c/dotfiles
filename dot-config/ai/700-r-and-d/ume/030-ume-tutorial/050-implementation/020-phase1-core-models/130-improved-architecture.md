# Improved HasAdditionalFeatures Architecture

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Improve the architecture of the HasAdditionalFeatures trait by breaking it down into smaller, more manageable concerns while maintaining the consolidated API.

## Overview

While our current HasAdditionalFeatures trait provides a comprehensive set of features, its monolithic structure can make it difficult to maintain and extend. In this section, we'll refactor the trait into smaller concerns that can be composed together, making the code more modular and easier to understand.

## Step 1: Create the Concerns Directory Structure

First, let's create a directory structure for our concerns:

```bash
mkdir -p app/Models/Traits/Concerns
```

## Step 2: Extract Concerns

We'll extract each major feature into its own concern trait. This allows us to:

1. Focus on one feature at a time
2. Make each feature more maintainable
3. Allow selective inclusion of features
4. Improve code organization

Let's start by creating the HasUlid concern:

```php
<?php

namespace App\Models\Traits\Concerns;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

trait HasUlid
{
    /**
     * Boot the HasUlid trait for a model.
     */
    protected static function bootHasUlid(): void
    {
        static::creating(function (Model $model): void {
            $ulidColumn = static::getUlidColumn();
            if (empty($model->{$ulidColumn}) && property_exists($model, $ulidColumn)) {
                $model->{$ulidColumn} = (string) Str::ulid();
            }
        });
    }

    /**
     * Get the ULID column name from configuration.
     *
     * @return string
     */
    protected static function getUlidColumn(): string
    {
        return config('additional-features.ulid.column', 'ulid');
    }

    /**
     * Get the route key for the model.
     */
    public function getRouteKeyName(): string
    {
        return static::getUlidColumn();
    }

    /**
     * Find a model by its ULID.
     *
     * @param string $ulid
     * @param array $columns
     * @return \Illuminate\Database\Eloquent\Model|null
     */
    public static function findByUlid(string $ulid, array $columns = ['*'])
    {
        $ulidColumn = static::getUlidColumn();
        return static::where($ulidColumn, $ulid)->first($columns);
    }

    /**
     * Find a model by its ULID or fail.
     *
     * @param string $ulid
     * @param array $columns
     * @return \Illuminate\Database\Eloquent\Model
     *
     * @throws \Illuminate\Database\Eloquent\ModelNotFoundException
     */
    public static function findByUlidOrFail(string $ulid, array $columns = ['*'])
    {
        $ulidColumn = static::getUlidColumn();
        return static::where($ulidColumn, $ulid)->firstOrFail($columns);
    }
}
```

Next, let's create the HasUserTracking concern:

```php
<?php

namespace App\Models\Traits\Concerns;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Auth;

trait HasUserTracking
{
    /**
     * Boot the HasUserTracking trait for a model.
     */
    protected static function bootHasUserTracking(): void
    {
        static::creating(function (Model $model): void {
            if (Auth::check() && empty($model->created_by) && static::hasColumn('created_by')) {
                $model->created_by = Auth::id();
            }
        });

        static::updating(function (Model $model): void {
            if (Auth::check() && static::hasColumn('updated_by')) {
                $model->updated_by = Auth::id();
            }
        });

        if (method_exists(new static, 'getDeletedAtColumn') && static::hasColumn('deleted_by')) {
            static::deleting(function (Model $model): void {
                if (Auth::check() && $model->usesSoftDeletes()) {
                    $model->deleted_by = Auth::id();
                    $model->save();
                }
            });
        }
    }

    /**
     * Check if a column exists in the model's table.
     *
     * @param string $column
     * @return bool
     */
    protected static function hasColumn(string $column): bool
    {
        return in_array($column, (new static)->getConnection()->getSchemaBuilder()->getColumnListing((new static)->getTable()));
    }

    /**
     * Get the user who created this model.
     *
     * @return BelongsTo
     */
    public function creator(): BelongsTo
    {
        $userModel = config('additional-features.user_tracking.user_model', '\\App\\Models\\User');
        $createdByColumn = config('additional-features.user_tracking.columns.created_by', 'created_by');
        
        return $this->belongsTo($userModel, $createdByColumn);
    }

    /**
     * Get the user who last updated this model.
     *
     * @return BelongsTo
     */
    public function updater(): BelongsTo
    {
        $userModel = config('additional-features.user_tracking.user_model', '\\App\\Models\\User');
        $updatedByColumn = config('additional-features.user_tracking.columns.updated_by', 'updated_by');
        
        return $this->belongsTo($userModel, $updatedByColumn);
    }

    /**
     * Get the user who deleted this model (for soft deletes).
     *
     * @return BelongsTo
     */
    public function deleter(): BelongsTo
    {
        $userModel = config('additional-features.user_tracking.user_model', '\\App\\Models\\User');
        $deletedByColumn = config('additional-features.user_tracking.columns.deleted_by', 'deleted_by');
        
        return $this->belongsTo($userModel, $deletedByColumn);
    }

    /**
     * Scope a query to only include models created by a specific user.
     *
     * @param Builder $query
     * @param int $userId
     * @return Builder
     */
    public function scopeCreatedBy(Builder $query, int $userId): Builder
    {
        $createdByColumn = config('additional-features.user_tracking.columns.created_by', 'created_by');
        
        return $query->where($createdByColumn, $userId);
    }

    /**
     * Scope a query to only include models updated by a specific user.
     *
     * @param Builder $query
     * @param int $userId
     * @return Builder
     */
    public function scopeUpdatedBy(Builder $query, int $userId): Builder
    {
        $updatedByColumn = config('additional-features.user_tracking.columns.updated_by', 'updated_by');
        
        return $query->where($updatedByColumn, $userId);
    }

    /**
     * Scope a query to only include models deleted by a specific user.
     *
     * @param Builder $query
     * @param int $userId
     * @return Builder
     */
    public function scopeDeletedBy(Builder $query, int $userId): Builder
    {
        $deletedByColumn = config('additional-features.user_tracking.columns.deleted_by', 'deleted_by');
        
        return $query->where($deletedByColumn, $userId);
    }
}
```

## Step 3: Update the Main Trait

Now, let's update the main HasAdditionalFeatures trait to use these concerns:

```php
<?php

namespace App\Models\Traits;

use App\Models\Traits\Concerns\HasUlid;
use App\Models\Traits\Concerns\HasUserTracking;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\Config;
use Laravel\Scout\Searchable;
use Spatie\Activitylog\LogOptions;
use Spatie\Activitylog\Traits\LogsActivity;
use Spatie\Comments\Models\Concerns\HasComments;
use Spatie\ModelFlags\Models\Concerns\HasFlags;
use Spatie\Sluggable\HasTranslatableSlug;
use Spatie\Tags\HasTags;
use Spatie\Translatable\HasTranslations;

/**
 * Trait HasAdditionalFeatures
 *
 * Provides core model features through composition of smaller concerns.
 */
trait HasAdditionalFeatures
{
    use HasUlid;
    use HasUserTracking;
    use HasComments;
    use HasFlags;
    use HasTags;
    use HasTranslatableSlug;
    use HasTranslations;
    use LogsActivity;
    use Searchable;
    use SoftDeletes;

    /**
     * Flag to enable/disable features.
     *
     * @var bool
     */
    private static bool $featuresEnabled = true;

    /**
     * Dynamically use the required traits based on configuration.
     * This is a workaround since PHP doesn't support conditional traits.
     */
    public function initializeHasAdditionalFeatures(): void
    {
        // We'll use this method to initialize any required properties
        // based on the configuration
        
        // Set up translatable attributes from config if not already set
        if (!isset($this->translatable) && $this->isFeatureEnabled('translatable')) {
            $this->translatable = $this->getTranslatableAttributes();
        }
    }

    /**
     * Check if a specific feature is enabled for this model.
     *
     * @param string $feature The feature to check
     * @return bool Whether the feature is enabled
     */
    public static function isFeatureEnabled(string $feature): bool
    {
        $config = config('additional-features.enabled', []);
        return $config[$feature] ?? true;
    }

    /**
     * Check if features are enabled globally.
     *
     * @return bool Whether features are enabled globally
     */
    protected static function areFeaturesEnabled(): bool
    {
        return config('additional-features.enabled', true);
    }

    /**
     * Temporarily disable all features for a callback.
     *
     * @param callable $callback
     * @return mixed
     */
    public static function withoutFeatures(callable $callback)
    {
        $originalValue = static::$featuresEnabled;
        static::$featuresEnabled = false;

        try {
            return $callback();
        } finally {
            static::$featuresEnabled = $originalValue;
        }
    }

    // Additional methods that coordinate between concerns...
}
```

## Step 4: Benefits of the New Architecture

This new architecture provides several benefits:

1. **Modularity**: Each concern focuses on a specific feature, making the code easier to understand and maintain.
2. **Selective Inclusion**: You can selectively include only the concerns you need in custom traits.
3. **Easier Testing**: Each concern can be tested in isolation, making tests more focused and reliable.
4. **Better Organization**: The code is organized by feature, making it easier to find and modify specific functionality.
5. **Improved Documentation**: Each concern can be documented separately, making the documentation more focused and easier to understand.

## Next Steps

Now that we've refactored the HasAdditionalFeatures trait into smaller concerns, we can move on to implementing the FeatureManager class to handle feature enablement/disablement. Let's continue to [Implement FeatureManager](./088-feature-manager.md).
