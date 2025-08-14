# Create HasAdditionalFeatures Trait

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Create a reusable trait that provides a comprehensive set of features for Eloquent models, including ULID generation, user tracking, slugging, activity logging, comments, tagging, search indexing, flags, and soft deletes.

## Overview

The `HasAdditionalFeatures` trait bundles several popular Laravel packages into a single, configurable trait. This approach allows us to:

1. Standardize model features across the application
2. Selectively enable/disable features based on configuration
3. Provide consistent interfaces for common operations
4. Reduce code duplication
5. Simplify model implementation

## Step 1: Install Required Packages

First, let's install the required packages:

```bash
composer require spatie/100-laravel-sluggable
composer require spatie/100-laravel-translatable
composer require spatie/100-laravel-activitylog
composer require spatie/100-laravel-tags
composer require spatie/100-laravel-comments
composer require spatie/100-laravel-model-flags
composer require 100-laravel/scout
```

## Step 2: Create the HasAdditionalFeatures Trait

Create a new file at `app/Models/Traits/HasAdditionalFeatures.php`:

```php
<?php

namespace App\Models\Traits;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphToMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Laravel\Scout\Searchable;
use Spatie\Activitylog\LogOptions;
use Spatie\Activitylog\Traits\LogsActivity;
use Spatie\Comments\Models\Concerns\HasComments;
use Spatie\ModelFlags\Models\Concerns\HasFlags;
use Spatie\Sluggable\HasTranslatableSlug;
use Spatie\Sluggable\SlugOptions;
use Spatie\Tags\HasTags;
use Spatie\Translatable\HasTranslations;

/**
 * Trait HasAdditionalFeatures
 *
 * Provides core model features: ULID generation, user tracking, slugging, activity logging,
 * comments, tagging, flags, search indexing, and soft deletes.
 *
 * @property string|null $ulid Universally Unique Lexicographically Sortable Identifier
 * @property string|null $slug URL-friendly slug for the model
 * @property array<string, mixed> $translations Translations for translatable attributes
 * @property bool $published Whether the model is published and searchable
 * @property int|null $created_by ID of the user who created the model
 * @property int|null $updated_by ID of the user who last updated the model
 * @property int|null $deleted_by ID of the user who deleted the model
 *
 * @method static Builder|static published() Scope to get only published models
 * @method static Builder|static draft() Scope to get only draft models
 * @method static Builder|static withAllTags(array|string $tags, ?string $type = null) Scope to get models with all the given tags
 * @method static Builder|static withAnyTags(array|string $tags, ?string $type = null) Scope to get models with any of the given tags
 * @method static Builder|static withoutTags(array|string $tags, ?string $type = null) Scope to get models without any of the given tags
 * @method static Builder|static createdBy(int $userId) Scope to get models created by a specific user
 * @method static Builder|static updatedBy(int $userId) Scope to get models updated by a specific user
 * @method static Builder|static deletedBy(int $userId) Scope to get models deleted by a specific user
 */
trait HasAdditionalFeatures
{
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
     * Include all the required traits.
     * Note: We're including all traits here, but their functionality
     * can be selectively enabled/disabled via configuration.
     */
    use
        HasComments,
        HasFlags,
        HasTags,
        HasTranslatableSlug,
        HasTranslations,
        LogsActivity,
        Searchable,
        SoftDeletes;

    /**
     * The attributes that are translatable.
     * This will be set from config in initializeHasAdditionalFeatures().
     *
     * @var array
     */
    public $translatable = ['name', 'slug'];

    /**
     * Whether the model is published and should be searchable.
     *
     * @var bool
     */
    protected $published = true;

    /**
     * Boot the HasAdditionalFeatures trait.
     */
    protected static function bootHasAdditionalFeatures(): void
    {
        if (!static::$featuresEnabled || !static::areFeaturesEnabled()) {
            return;
        }

        // Generate ULID on creation if enabled
        if (static::isFeatureEnabled('ulid')) {
            static::creating(function (Model $model): void {
                $ulidColumn = static::getUlidColumn();
                if (empty($model->{$ulidColumn}) && property_exists($model, $ulidColumn)) {
                    $model->{$ulidColumn} = (string) Str::ulid();
                }
            });
        }

        // Add user tracking if enabled
        if (static::isFeatureEnabled('user_tracking')) {
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

            if (method_exists($model = new static, 'getDeletedAtColumn') && static::hasColumn('deleted_by')) {
                static::deleting(function (Model $model): void {
                    if (Auth::check() && $model->usesSoftDeletes()) {
                        $model->deleted_by = Auth::id();
                        $model->save();
                    }
                });
            }
        }

        // Add additional event listeners for other features
        if (static::isFeatureEnabled('activity_log')) {
            // Activity log is handled by the LogsActivity trait
            // but we can add additional customization here
            static::created(function (Model $model): void {
                static::logModelEvent($model, 'created');
            });

            static::updated(function (Model $model): void {
                static::logModelEvent($model, 'updated');
            });

            static::deleted(function (Model $model): void {
                static::logModelEvent($model, 'deleted');
            });

            if (method_exists(static::class, 'restored')) {
                static::restored(function (Model $model): void {
                    static::logModelEvent($model, 'restored');
                });
            }
        }
    }

    /**
     * Configure slug generation options.
     */
    public function getSlugOptions(): SlugOptions
    {
        $config = config('additional-features.sluggable', []);
        $locales = $config['locales'] ?? ['en', 'de', 'es', 'fr', 'it', 'nl'];
        $source = $config['source'] ?? 'name';
        $column = $config['column'] ?? 'slug';
        $updateOnChange = $config['update_on_change'] ?? false;

        $options = SlugOptions::createWithLocales($locales)
            ->saveSlugsTo($column);

        // Generate slugs from the configured source attribute
        $options->generateSlugsFrom(function($model, $locale) use ($source): string {
            // If the source is a callable, use it
            if (method_exists($this, $source)) {
                return $this->{$source}($locale);
            }

            // If the source is a translatable attribute, get the translation
            if (method_exists($this, 'getTranslation') && in_array($source, $this->translatable ?? [])) {
                return $this->getTranslation($source, $locale);
            }

            // Otherwise, use the source attribute directly
            return sprintf('%s %s', $locale, $this->id ?? Str::random(6));
        });

        // Configure whether to update slugs when the source changes
        if (!$updateOnChange) {
            $options->doNotGenerateSlugsOnUpdate();
        }

        return $options;
    }

    /**
     * Get the route key for the model.
     */
    public function getRouteKeyName(): string
    {
        if ($this->isFeatureEnabled('sluggable')) {
            $config = config('additional-features.sluggable', []);
            return $config['column'] ?? 'slug';
        }

        if ($this->isFeatureEnabled('ulid')) {
            $config = config('additional-features.ulid', []);
            return $config['column'] ?? 'ulid';
        }

        return $this->getKeyName();
    }

    /**
     * Configure activity log options.
     */
    public function getActivitylogOptions(): LogOptions
    {
        $config = config('additional-features.activity_log', []);
        $options = LogOptions::defaults();

        if ($config['log_all_attributes'] ?? true) {
            $options->logAll();
        }

        if ($config['log_only_dirty'] ?? true) {
            $options->logOnlyDirty();
        }

        if (!($config['submit_empty_logs'] ?? false)) {
            $options->dontSubmitEmptyLogs();
        }

        return $options;
    }

    /**
     * Provide a URL for comments (used by HasComments trait).
     */
    public function commentUrl(): string
    {
        $config = config('additional-features.comments', []);
        $pattern = $config['url_pattern'] ?? '{model_plural}/{slug}';
        $slugField = $this->getRouteKeyName();
        $modelPlural = Str::plural(Str::kebab(class_basename($this)));

        return url(str_replace(
            ['{model_plural}', '{slug}', '{id}'],
            [$modelPlural, $this->{$slugField}, $this->getKey()],
            $pattern
        ));
    }

    /**
     * Provide a friendly name for comments (used by HasComments trait).
     */
    public function commentableName(): string
    {
        return $this->getDisplayName();
    }

    /**
     * Get a human-friendly display name for the model.
     *
     * Used for UI representation in various contexts including comments,
     * activity logs, and search results.
     */
    public function getDisplayName(): string
    {
        $config = config('additional-features.display_name', []);
        $attributes = $config['attributes'] ?? ['title', 'name', 'display_name', 'label'];

        // Try common name attributes in order of preference
        foreach ($attributes as $attribute) {
            if (isset($this->$attribute) && !empty($this->$attribute)) {
                // For translatable attributes, get value in current locale
                if ($this->isFeatureEnabled('translatable') && method_exists($this, 'getTranslation') && in_array($attribute, $this->translatable ?? [])) {
                    return $this->getTranslation($attribute, app()->getLocale());
                }
                return (string) $this->$attribute;
            }
        }

        // Use ULID if available and configured
        $ulidColumn = static::getUlidColumn();
        if ($config['fallback_to_ulid'] ?? true && !empty($this->{$ulidColumn})) {
            return class_basename($this) . ' #' . $this->{$ulidColumn};
        }

        // Last resort: class name + primary key
        if ($config['fallback_to_key'] ?? true) {
            return class_basename($this) . ' #' . $this->getKey();
        }

        return class_basename($this);
    }

    /**
     * Get the indexable data array for the model.
     * Required by Laravel Scout's Searchable trait.
     *
     * @return array
     */
    public function toSearchableArray(): array
    {
        $config = config('additional-features.search', []);
        $defaultFields = $config['default_fields'] ?? ['id', 'name', 'slug'];
        $data = [];

        // Add default fields
        if (in_array('id', $defaultFields)) {
            $data['id'] = $this->getKey();
        }

        if (in_array('name', $defaultFields)) {
            $data['name'] = $this->getDisplayName();
        }

        if (in_array('slug', $defaultFields) && $this->isFeatureEnabled('sluggable')) {
            $slugField = config('additional-features.sluggable.column', 'slug');
            $data['slug'] = $this->{$slugField} ?? '';
        }

        // Add ULID if enabled
        if (in_array('ulid', $defaultFields) && $this->isFeatureEnabled('ulid')) {
            $ulidColumn = static::getUlidColumn();
            $data['ulid'] = $this->{$ulidColumn} ?? '';
        }

        // Add tags if enabled
        if (in_array('tags', $defaultFields) && $this->isFeatureEnabled('tags')) {
            $data['tags'] = $this->tags->pluck('name')->toArray();
        }

        // Add any custom fields defined in the model
        if (method_exists($this, 'getSearchableFields')) {
            $customFields = $this->getSearchableFields();
            foreach ($customFields as $field) {
                $data[$field] = $this->{$field} ?? '';
            }
        }

        return $data;
    }

    /**
     * Determine if the model should be searchable.
     * Optional method for Laravel Scout's Searchable trait.
     */
    public function shouldBeSearchable(): bool
    {
        if (!$this->isFeatureEnabled('searchable')) {
            return false;
        }

        $config = config('additional-features.search', []);
        $excludeUnpublished = $config['exclude_unpublished'] ?? true;

        if ($excludeUnpublished) {
            return $this->published === true;
        }

        return true;
    }

    /**
     * Scope a query to only include published models.
     *
     * @param Builder $query
     * @return Builder
     */
    public function scopePublished(Builder $query): Builder
    {
        return $query->where('published', true);
    }

    /**
     * Scope a query to only include draft (unpublished) models.
     *
     * @param Builder $query
     * @return Builder
     */
    public function scopeDraft(Builder $query): Builder
    {
        return $query->where('published', false);
    }

    /**
     * Get the tags relationship morphed to the model's class with specified type.
     * Enhancement for the HasTags trait.
     *
     * @param string|null $type
     * @return MorphToMany
     */
    public function tagsWithType($type = null): MorphToMany
    {
        return $this->tags()->where('type', $type ?? $this->getDefaultTagType());
    }

    /**
     * Get the default tag type for this model.
     * Helper method for HasTags trait.
     */
    public function getDefaultTagType(): string
    {
        return Str::snake(class_basename($this));
    }

    /**
     * Override the flag method to validate against our Flags enum.
     *
     * @param string $name The flag name
     * @return $this
     */
    public function flag(string $name)
    {
        if ($this->isFeatureEnabled('flags')) {
            // Validate flag against the Flags enum if it exists
            if (class_exists(\App\Enums\Flags::class)) {
                $validFlags = array_column(\App\Enums\Flags::cases(), 'value');
                if (!in_array($name, $validFlags)) {
                    throw new \InvalidArgumentException("Invalid flag: {$name}. Must be one of: " . implode(', ', $validFlags));
                }
            }

            // Call the parent flag method from HasFlags trait
            parent::flag($name);
        }

        return $this;
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

    /**
     * Get the ULID column name from configuration.
     *
     * @return string
     */
    protected static function getUlidColumn(): string
    {
        $config = config('additional-features.ulid', []);
        return $config['column'] ?? 'ulid';
    }

    /**
     * Get the translatable attributes from configuration.
     *
     * @return array
     */
    protected function getTranslatableAttributes(): array
    {
        $config = config('additional-features.translatable', []);
        return $config['attributes'] ?? ['name', 'slug'];
    }

    /**
     * Log a model event using the activity log package or application log.
     *
     * @param Model $model
     * @param string $event
     * @return void
     */
    protected static function logModelEvent(Model $model, string $event): void
    {
        $config = config('additional-features.activity_log', []);
        $logEvents = $config['log_events'] ?? ['created', 'updated', 'deleted', 'restored'];

        if (!in_array($event, $logEvents)) {
            return;
        }

        // If the activity log package is available, it will handle logging automatically
        // This is just for additional custom logging if needed
        if (config('additional-features.activity_log.custom_logging', false)) {
            Log::info("Model {$event}", [
                'model_id' => $model->getKey(),
                'model_type' => get_class($model),
                'timestamp' => now(),
                'attributes' => $model->getAttributes(),
            ]);
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
        $userModel = config('additional-features.user_tracking.user_model', '\App\Models\User');
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
        $userModel = config('additional-features.user_tracking.user_model', '\App\Models\User');
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
        $userModel = config('additional-features.user_tracking.user_model', '\App\Models\User');
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

## Step 3: Understanding the Trait

The `HasAdditionalFeatures` trait provides several key features:

1. **ULID Generation**: Automatically generates ULIDs for new models
2. **User Tracking**: Tracks which users created, updated, and deleted models
3. **Sluggable**: Creates URL-friendly slugs for models
4. **Translatable**: Supports multilingual content with automatic translations
5. **Activity Logging**: Tracks all changes to models
6. **Comments**: Adds commenting functionality to models
7. **Tagging**: Allows tagging models with categories or keywords
8. **Flags**: Adds boolean flags to models with enum validation
9. **Search Indexing**: Makes models searchable with Laravel Scout
10. **Soft Deletes**: Implements soft delete functionality

Each feature can be selectively enabled or disabled through configuration, making the trait highly flexible and adaptable to different model requirements.

## Step 4: Key Methods

The trait provides several key methods:

1. **getDisplayName()**: Returns a human-friendly display name for the model
2. **getRouteKeyName()**: Returns the column to use for route model binding
3. **isFeatureEnabled()**: Checks if a specific feature is enabled
4. **withoutFeatures()**: Temporarily disables all features for a callback
5. **flag()**: Adds a flag to the model with enum validation
6. **scopePublished()**: Scope to get only published models
7. **scopeDraft()**: Scope to get only draft models
8. **tagsWithType()**: Get tags of a specific type
9. **creator()**: Get the user who created the model
10. **updater()**: Get the user who last updated the model
11. **deleter()**: Get the user who deleted the model (for soft deletes)
12. **scopeCreatedBy()**: Scope to get models created by a specific user
13. **scopeUpdatedBy()**: Scope to get models updated by a specific user
14. **scopeDeletedBy()**: Scope to get models deleted by a specific user

## Next Steps

Now that we've created the `HasAdditionalFeatures` trait, we need to:

1. Create a configuration file for the trait
2. Create a Flags enum for model flags
3. Update the User model to use the trait

Let's move on to [Configure Additional Features](./085-configure-additional-features.md).
