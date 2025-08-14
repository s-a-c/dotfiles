<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Laravel\Scout\Searchable;
use Spatie\Activitylog\LogOptions;
use Spatie\Activitylog\Traits\LogsActivity;
use Spatie\Comments\Models\Concerns\HasComments;
use Spatie\Sluggable\HasSlug;
use Spatie\Sluggable\SlugOptions;
use Spatie\Tags\HasTags;
use Throwable;

/**
 * Base Model class with common functionality for all models.
 *
 * This abstract class provides a foundation for all models in the application,
 * implementing common traits and methods that should be available across the system.
 *
 * Features included:
 * - Soft deletes for safe record removal
 * - Activity logging for audit trails
 * - Commenting functionality
 * - Slug generation for SEO-friendly URLs
 * - Tagging support
 * - Search indexing
 * - ULID generation for globally unique identifiers
 * - Comprehensive caching support
 * - Scopes for common queries
 * - Validation helpers
 * - API response formatting
 * - Relationship introspection
 * - Performance optimization methods
 *
 * @property int $id The primary key
 * @property string|null $name The name of the model (if applicable)
 * @property string|null $slug The slug for SEO-friendly URLs
 * @property string|null $ulid The ULID (Universally Unique Lexicographically Sortable Identifier)
 * @property Carbon|null $created_at When the record was created
 * @property Carbon|null $updated_at When the record was last updated
 * @property Carbon|null $deleted_at When the record was soft deleted (if applicable)
 *
 * @method static Builder|static query() Begin a new query
 * @method static Builder|static where($column, $operator = null, $value = null) Add a where clause
 * @method static Builder|static whereNull($column) Add a where null clause
 * @method static Builder|static whereNotNull($column) Add a where not null clause
 * @method static Builder|static orderBy($column, $direction = 'asc') Add an order by clause
 * @method static Builder|static withTrashed() Include soft deleted records
 * @method static Builder|static onlyTrashed() Only include soft deleted records
 * @method static Builder|static withoutTrashed() Exclude soft deleted records
 * @method static Builder|static active() Only include active records
 * @method static Builder|static inactive() Only include inactive records
 * @method static Builder|static recent() Order by most recent first
 * @method static Builder|static oldest() Order by oldest first
 * @method static Builder|static byUlid(string $ulid) Find by ULID
 * @method static Builder|static bySlug(string $slug) Find by slug
 * @method static Builder|static random(int $count = 1) Get random records
 * @method static Builder|static search($term) Search for records matching the term
 * @method static Builder|static withAllTags($tags) Include records with all the given tags
 * @method static Builder|static withAnyTags($tags) Include records with any of the given tags
 * @method static Builder|static withoutTags($tags) Exclude records with the given tags
 * @method static Builder|static withCommonEagerLoads() Include common eager loads
 * @method static Builder|static withAllEagerLoads() Include all possible eager loads
 * @method static Builder|static forAdminListing() Optimize for admin panel listings
 * @method static Builder|static forPublicDisplay() Optimize for public display
 * @method static Builder|static forApiResponse() Optimize for API responses
 * @method static static|null findCached(mixed $id, array $columns = ['*']) Find with caching
 * @method static static|null findByUlidCached(string $ulid, array $columns = ['*']) Find by ULID with caching
 * @method static static|null findBySlugCached(string $slug, array $columns = ['*']) Find by slug with caching
 * @method static Collection<int, static> allCached(array $columns = ['*']) Get all with caching
 * @method static int countCached() Count with caching
 * @method static static|bool createWithValidation(array $attributes = [], array $options = []) Create with validation
 */
abstract class BaseModel extends Model
{
    use LogsActivity;
    use HasComments;
    use HasSlug;
    use HasTags;
    use SoftDeletes;
    use Searchable;

    /**
     * Indicates if the model should throw validation exceptions.
     *
     * @var bool
     */
    protected bool $throwValidationExceptions = false;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'slug',
        'ulid',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'deleted_at',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
    ];

    /**
     * The cache TTL in seconds.
     *
     * @var int
     */
    protected static int $cacheTtl = 3600; // 1 hour

    /**
     * Bootstrap the model and its traits.
     *
     * This method is called when the model is being booted.
     * It sets up event listeners and initializes the model.
     *
     * @return void
     */
    protected static function boot(): void
    {
        parent::boot();

        // Generate ULID for new records
        static::creating(function (self $model): void {
            if (empty($model->ulid)) {
                $model->ulid = (string) Str::ulid();
            }
        });

        // Clear cache when model is saved or deleted
        static::saved(function (self $model): void {
            $model->clearModelCache();
        });

        static::deleted(function (self $model): void {
            $model->clearModelCache();
        });
    }

    /**
     * Get the options for generating the slug.
     *
     * This method defines how slugs are generated for the model.
     * Override in child classes for custom slug generation.
     *
     * @return SlugOptions The slug generation options
     */
    public function getSlugOptions(): SlugOptions
    {
        return SlugOptions::create()
            ->generateSlugsFrom('name') // Default source field, override in child classes if needed
            ->saveSlugsTo('slug')
            ->doNotGenerateSlugsOnUpdate();
    }

    /**
     * Get the activity log options for the model.
     *
     * This method defines how activity logging is configured for the model.
     * It logs all changes to the model and only logs when changes are made.
     *
     * @return LogOptions The activity log options
     */
    public function getActivitylogOptions(): LogOptions
    {
        return LogOptions::defaults()
            ->logAll()
            ->logOnlyDirty()
            ->dontSubmitEmptyLogs();
    }

    /**
     * Returns a human-readable name for this model to be used in comments.
     *
     * This method leverages the 'name' attribute that is used for slug generation
     * as defined in getSlugOptions().
     *
     * @return string
     */
    public function commentableName(): string
    {
        // Get the attribute used for slug generation, which is typically 'name'
        $sourceField = $this->getSlugOptions()->generateSlugsFrom;

        // If the source field is a closure, use a default approach
        if ($sourceField instanceof \Closure) {
            return class_basename($this) . ' #' . $this->getKey();
        }

        // If it's a string or array, try to get the value
        if (is_string($sourceField) && isset($this->attributes[$sourceField])) {
            return $this->attributes[$sourceField];
        }

        // If it's an array of fields, concatenate them
        if (is_array($sourceField)) {
            $parts = [];
            foreach ($sourceField as $field) {
                if (isset($this->attributes[$field])) {
                    $parts[] = $this->attributes[$field];
                }
            }

            if (!empty($parts)) {
                return implode(' ', $parts);
            }
        }

        // Fallback to model name + ID
        return class_basename($this) . ' #' . $this->getKey();
    }

    /**
     * Returns the URL for this commentable model.
     *
     * This method creates a URL based on the model's slug.
     * Override in child classes for more specific URL generation.
     *
     * @return string
     */
    public function commentableUrl(): string
    {
        // Get the slug field
        $slugField = $this->getSlugOptions()->slugField ?? 'slug';

        // Determine the route name based on the model
        $modelName = Str::kebab(class_basename($this));
        $routeName = $modelName . '.show';

        // Try to generate the URL using the route
        try {
            return route($routeName, [$slugField => $this->{$slugField}]);
        } catch (\Exception $e) {
            // If the route doesn't exist, return a fallback URL
            return url('/' . Str::plural($modelName) . '/' . $this->{$slugField});
        }
    }

    /**
     * Scope a query to only include active records.
     *
     * This scope filters records based on an 'is_active' or 'active' column.
     * Override in child classes if the active flag has a different name.
     *
     * @param Builder $query The query builder instance
     * @return Builder The modified query builder
     */
    public function scopeActive(Builder $query): Builder
    {
        // Check which column exists for determining active status
        if ($this->hasColumn('is_active')) {
            return $query->where('is_active', true);
        }

        if ($this->hasColumn('active')) {
            return $query->where('active', true);
        }

        // If no active column exists, return the original query
        return $query;
    }

    /**
     * Scope a query to only include inactive records.
     *
     * This scope filters records based on an 'is_active' or 'active' column.
     * Override in child classes if the active flag has a different name.
     *
     * @param Builder $query The query builder instance
     * @return Builder The modified query builder
     */
    public function scopeInactive(Builder $query): Builder
    {
        // Check which column exists for determining active status
        if ($this->hasColumn('is_active')) {
            return $query->where('is_active', false);
        }

        if ($this->hasColumn('active')) {
            return $query->where('active', false);
        }

        // If no active column exists, return the original query
        return $query;
    }

    /**
     * Scope a query to order by most recent records first.
     *
     * @param Builder $query The query builder instance
     * @return Builder The modified query builder
     */
    public function scopeRecent(Builder $query): Builder
    {
        return $query->latest('created_at');
    }

    /**
     * Scope a query to order by oldest records first.
     *
     * @param Builder $query The query builder instance
     * @return Builder The modified query builder
     */
    public function scopeOldest(Builder $query): Builder
    {
        return $query->oldest('created_at');
    }

    /**
     * Scope a query to find a record by its ULID.
     *
     * @param Builder $query The query builder instance
     * @param string $ulid The ULID to search for
     * @return Builder The modified query builder
     */
    public function scopeByUlid(Builder $query, string $ulid): Builder
    {
        return $query->where('ulid', $ulid);
    }

    /**
     * Scope a query to find a record by its slug.
     *
     * @param Builder $query The query builder instance
     * @param string $slug The slug to search for
     * @return Builder The modified query builder
     */
    public function scopeBySlug(Builder $query, string $slug): Builder
    {
        return $query->where('slug', $slug);
    }

    /**
     * Scope a query to get a random record.
     *
     * @param Builder $query The query builder instance
     * @param int $count The number of random records to retrieve
     * @return Builder The modified query builder
     */
    public function scopeRandom(Builder $query, int $count = 1): Builder
    {
        return $query->inRandomOrder()->limit($count);
    }

    /**
     * Check if the model has a specific column.
     *
     * @param string $column The column name to check
     * @return bool True if the column exists, false otherwise
     */
    protected function hasColumn(string $column): bool
    {
        static $columns = [];
        $class = get_class($this);

        if (!isset($columns[$class])) {
            // Cache the columns for this model class
            $columns[$class] = $this->getConnection()
                ->getSchemaBuilder()
                ->getColumnListing($this->getTable());
        }

        return in_array($column, $columns[$class], true);
    }

    /**
     * Clear the cache for this model.
     *
     * This method is called automatically when a model is saved or deleted.
     * It clears any cached data related to this model instance.
     *
     * @return void
     */
    public function clearModelCache(): void
    {
        try {
            // Clear cache for this specific model instance
            Cache::forget($this->getCacheKey());

            // Clear cache for model collection
            Cache::forget($this->getCollectionCacheKey());

            // Clear cache for model counts
            Cache::forget($this->getCountCacheKey());
        } catch (Throwable $e) {
            // Log the error but don't throw it to prevent disrupting the save/delete process
            Log::error('Failed to clear model cache', [
                'model' => get_class($this),
                'id' => $this->getKey(),
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Get a unique cache key for this model instance.
     *
     * @param string|null $suffix Optional suffix to append to the cache key
     * @return string The cache key
     */
    public function getCacheKey(?string $suffix = null): string
    {
        $key = sprintf(
            '%s:%s:%s',
            strtolower(str_replace('\\', '_', get_class($this))),
            $this->getKey(),
            $suffix ? $suffix : 'model'
        );

        return $key;
    }

    /**
     * Get a cache key for a collection of this model type.
     *
     * @param string|null $suffix Optional suffix to append to the cache key
     * @return string The collection cache key
     */
    public function getCollectionCacheKey(?string $suffix = null): string
    {
        $key = sprintf(
            '%s:%s',
            strtolower(str_replace('\\', '_', get_class($this))),
            $suffix ? $suffix : 'collection'
        );

        return $key;
    }

    /**
     * Get a cache key for counting this model type.
     *
     * @param string|null $suffix Optional suffix to append to the cache key
     * @return string The count cache key
     */
    public function getCountCacheKey(?string $suffix = null): string
    {
        $key = sprintf(
            '%s:%s',
            strtolower(str_replace('\\', '_', get_class($this))),
            $suffix ? $suffix : 'count'
        );

        return $key;
    }

    /**
     * Find a model by its primary key, with caching.
     *
     * @param mixed $id The primary key value
     * @param array<string> $columns The columns to select
     * @return static|null The model instance or null if not found
     */
    public static function findCached(mixed $id, array $columns = ['*']): ?static
    {
        if ($id === null) {
            return null;
        }

        $instance = new static;
        $cacheKey = sprintf(
            '%s:%s:model',
            strtolower(str_replace('\\', '_', get_class($instance))),
            $id
        );

        return Cache::remember(
            $cacheKey,
            static::$cacheTtl,
            function () use ($id, $columns) {
                return static::find($id, $columns);
            }
        );
    }

    /**
     * Find a model by its ULID, with caching.
     *
     * @param string $ulid The ULID to find
     * @param array<string> $columns The columns to select
     * @return static|null The model instance or null if not found
     */
    public static function findByUlidCached(string $ulid, array $columns = ['*']): ?static
    {
        $instance = new static;
        $cacheKey = sprintf(
            '%s:ulid:%s:model',
            strtolower(str_replace('\\', '_', get_class($instance))),
            $ulid
        );

        return Cache::remember(
            $cacheKey,
            static::$cacheTtl,
            function () use ($ulid, $columns) {
                return static::where('ulid', $ulid)->first($columns);
            }
        );
    }

    /**
     * Find a model by its slug, with caching.
     *
     * @param string $slug The slug to find
     * @param array<string> $columns The columns to select
     * @return static|null The model instance or null if not found
     */
    public static function findBySlugCached(string $slug, array $columns = ['*']): ?static
    {
        $instance = new static;
        $cacheKey = sprintf(
            '%s:slug:%s:model',
            strtolower(str_replace('\\', '_', get_class($instance))),
            $slug
        );

        return Cache::remember(
            $cacheKey,
            static::$cacheTtl,
            function () use ($slug, $columns) {
                return static::where('slug', $slug)->first($columns);
            }
        );
    }

    /**
     * Get all models with caching.
     *
     * @param array<string> $columns The columns to select
     * @return Collection<int, static> The collection of models
     */
    public static function allCached(array $columns = ['*']): Collection
    {
        $instance = new static;
        $cacheKey = $instance->getCollectionCacheKey('all');

        return Cache::remember(
            $cacheKey,
            static::$cacheTtl,
            function () use ($columns) {
                return static::all($columns);
            }
        );
    }

    /**
     * Count models with caching.
     *
     * @return int The count of models
     */
    public static function countCached(): int
    {
        $instance = new static;
        $cacheKey = $instance->getCountCacheKey();

        return Cache::remember(
            $cacheKey,
            static::$cacheTtl,
            function () {
                return static::count();
            }
        );
    }

    /**
     * Convert the model instance to a JSON string with better error handling.
     *
     * @param int $options JSON encoding options
     * @return string The JSON representation of the model
     */
    public function safeToJson(int $options = 0): string
    {
        try {
            return $this->toJson($options);
        } catch (Throwable $e) {
            Log::error('Failed to convert model to JSON', [
                'model' => get_class($this),
                'id' => $this->getKey(),
                'error' => $e->getMessage(),
            ]);

            // Return a minimal JSON representation with just the ID
            return json_encode(['id' => $this->getKey()], $options);
        }
    }

    /**
     * Get a human-readable identifier for this model.
     *
     * @return string A human-readable identifier
     */
    public function getDisplayName(): string
    {
        // Try common name fields
        foreach (['name', 'title', 'label', 'display_name'] as $field) {
            if (isset($this->attributes[$field]) && !empty($this->attributes[$field])) {
                return $this->attributes[$field];
            }
        }

        // Try slug
        if (isset($this->attributes['slug']) && !empty($this->attributes['slug'])) {
            return $this->attributes['slug'];
        }

        // Fallback to model name + ID
        return class_basename($this) . ' #' . $this->getKey();
    }

    /**
     * Validate the model attributes against the defined rules.
     *
     * @param array<string, mixed>|null $attributes The attributes to validate (or current attributes if null)
     * @return bool True if validation passes, false otherwise
     * @throws \Illuminate\Validation\ValidationException If $throwValidationExceptions is true and validation fails
     */
    public function validate(?array $attributes = null): bool
    {
        // If no rules defined, validation passes
        if (!method_exists($this, 'rules')) {
            return true;
        }

        // Get the validation rules
        $rules = $this->rules();

        if (empty($rules)) {
            return true;
        }

        // Get the attributes to validate
        $data = $attributes ?? $this->attributes;

        // Create a validator
        $validator = validator($data, $rules);

        // Check if validation passes
        if ($validator->fails()) {
            if ($this->throwValidationExceptions) {
                $validator->validate();
            }

            return false;
        }

        return true;
    }

    /**
     * Save the model with validation.
     *
     * @param array<string, mixed> $options Save options
     * @return bool True if the save was successful, false otherwise
     */
    public function saveWithValidation(array $options = []): bool
    {
        if (!$this->validate()) {
            return false;
        }

        return $this->save($options);
    }

    /**
     * Create a new instance of the model with validation.
     *
     * @param array<string, mixed> $attributes The attributes to set
     * @param array<string, mixed> $options Save options
     * @return static|bool The new model instance if successful, false otherwise
     */
    public static function createWithValidation(array $attributes = [], array $options = [])
    {
        $model = new static($attributes);

        if (!$model->validate()) {
            return false;
        }

        $model->save($options);

        return $model;
    }

    /**
     * Update the model with validation.
     *
     * @param array<string, mixed> $attributes The attributes to update
     * @param array<string, mixed> $options Save options
     * @return bool True if the update was successful, false otherwise
     */
    public function updateWithValidation(array $attributes = [], array $options = []): bool
    {
        $this->fill($attributes);

        if (!$this->validate()) {
            return false;
        }

        return $this->update($options);
    }

    /**
     * Get a new query builder with common eager loads for this model.
     *
     * Override this method in child classes to define common eager loads.
     *
     * @return Builder A query builder with eager loads
     */
    public static function withCommonEagerLoads(): Builder
    {
        return static::query();
    }

    /**
     * Get a new query builder with all possible eager loads for this model.
     *
     * Override this method in child classes to define all possible eager loads.
     *
     * @return Builder A query builder with all eager loads
     */
    public static function withAllEagerLoads(): Builder
    {
        return static::query();
    }

    /**
     * Get a new query builder that's optimized for listing in admin panels.
     *
     * Override this method in child classes to define admin-specific eager loads and scopes.
     *
     * @return Builder A query builder optimized for admin listings
     */
    public static function forAdminListing(): Builder
    {
        return static::withCommonEagerLoads();
    }

    /**
     * Get a new query builder that's optimized for public display.
     *
     * Override this method in child classes to define public-specific eager loads and scopes.
     *
     * @return Builder A query builder optimized for public display
     */
    public static function forPublicDisplay(): Builder
    {
        return static::withCommonEagerLoads()->active();
    }

    /**
     * Get a new query builder that's optimized for API responses.
     *
     * Override this method in child classes to define API-specific eager loads and scopes.
     *
     * @return Builder A query builder optimized for API responses
     */
    public static function forApiResponse(): Builder
    {
        return static::withCommonEagerLoads();
    }

    /**
     * Get the model's data prepared for an API response.
     *
     * Override this method in child classes to customize the API response.
     *
     * @param array<string> $fields The fields to include (empty for all)
     * @return array<string, mixed> The model data for API response
     */
    public function toApiResponse(array $fields = []): array
    {
        $data = $this->toArray();

        // If specific fields are requested, filter the data
        if (!empty($fields)) {
            $data = array_intersect_key($data, array_flip($fields));
        }

        return $data;
    }

    /**
     * Check if the model has a specific relationship.
     *
     * @param string $relation The relationship name
     * @return bool True if the relationship exists, false otherwise
     */
    public function hasRelationship(string $relation): bool
    {
        return method_exists($this, $relation) && is_a($this->$relation(), '\Illuminate\Database\Eloquent\Relations\Relation');
    }

    /**
     * Get the model's relationships as an array of names.
     *
     * @return array<string> The relationship names
     */
    public function getRelationships(): array
    {
        $relationships = [];
        $methods = get_class_methods($this);

        foreach ($methods as $method) {
            if ($method === 'getRelationships') {
                continue;
            }

            try {
                $reflection = new \ReflectionMethod($this, $method);

                // Skip methods that require parameters
                if ($reflection->getNumberOfRequiredParameters() > 0) {
                    continue;
                }

                // Check if the method returns a relationship
                $returnType = $reflection->getReturnType();
                if ($returnType && !$returnType->isBuiltin()) {
                    $returnClass = $returnType->getName();
                    if (is_subclass_of($returnClass, '\Illuminate\Database\Eloquent\Relations\Relation')) {
                        $relationships[] = $method;
                        continue;
                    }
                }

                // If no return type hint, try to call the method
                $result = $this->$method();
                if (is_object($result) && is_a($result, '\Illuminate\Database\Eloquent\Relations\Relation')) {
                    $relationships[] = $method;
                }
            } catch (\Throwable $e) {
                // Skip methods that throw exceptions
                continue;
            }
        }

        return $relationships;
    }

    /**
     * Provide a friendly name for comments (alias).
     *
     * @return string
     */
    public function commentName(): string
    {
        return $this->commentableName();
    }

    /**
     * Provide a URL for comments (alias).
     *
     * @return string
     */
    public function commentUrl(): string
    {
        return $this->commentableUrl();
    }
}
