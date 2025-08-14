# Advanced Feature Enhancements

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Enhance the HasAdditionalFeatures trait with advanced features such as an event system, middleware for feature toggling, enhanced user tracking, time-based flags, and typed metadata with validation.

## Overview

While the HasAdditionalFeatures trait already provides powerful functionality, we can further enhance it with advanced features that provide even more flexibility and power. In this section, we'll implement several advanced enhancements:

1. Event system for feature lifecycle
2. Middleware for feature toggling
3. Enhanced user tracking with request data
4. Time-based flags
5. Typed metadata with validation

## Step 1: Implement Event System for Features

Let's create events for feature lifecycle:

```php
<?php

namespace App\Events;

use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class FeatureEnabled
{
    use Dispatchable, SerializesModels;

    /**
     * The feature that was enabled.
     *
     * @var string
     */
    public string $feature;

    /**
     * The model class that the feature was enabled for.
     *
     * @var string|null
     */
    public ?string $model;

    /**
     * Create a new event instance.
     *
     * @param string $feature
     * @param string|null $model
     */
    public function __construct(string $feature, ?string $model = null)
    {
        $this->feature = $feature;
        $this->model = $model;
    }
}

class FeatureDisabled
{
    use Dispatchable, SerializesModels;

    /**
     * The feature that was disabled.
     *
     * @var string
     */
    public string $feature;

    /**
     * The model class that the feature was disabled for.
     *
     * @var string|null
     */
    public ?string $model;

    /**
     * Create a new event instance.
     *
     * @param string $feature
     * @param string|null $model
     */
    public function __construct(string $feature, ?string $model = null)
    {
        $this->feature = $feature;
        $this->model = $model;
    }
}

class FeatureUsed
{
    use Dispatchable, SerializesModels;

    /**
     * The feature that was used.
     *
     * @var string
     */
    public string $feature;

    /**
     * The model instance that used the feature.
     *
     * @var mixed
     */
    public $model;

    /**
     * Additional context for the feature usage.
     *
     * @var array
     */
    public array $context;

    /**
     * Create a new event instance.
     *
     * @param string $feature
     * @param mixed $model
     * @param array $context
     */
    public function __construct(string $feature, $model, array $context = [])
    {
        $this->feature = $feature;
        $this->model = $model;
        $this->context = $context;
    }
}
```

Now, let's update the FeatureManager to dispatch these events:

```php
<?php

namespace App\Support;

use App\Events\FeatureDisabled;
use App\Events\FeatureEnabled;
use Illuminate\Support\Facades\Config;

class FeatureManager
{
    // ... existing implementation ...

    /**
     * Enable a feature.
     *
     * @param string $feature
     * @param string|null $model
     * @return void
     */
    public static function enable(string $feature, ?string $model = null): void
    {
        $model = $model ?? '*';
        static::$enabledFeatures[$model][$feature] = true;
        
        // Dispatch event
        event(new FeatureEnabled($feature, $model === '*' ? null : $model));
    }

    /**
     * Disable a feature.
     *
     * @param string $feature
     * @param string|null $model
     * @return void
     */
    public static function disable(string $feature, ?string $model = null): void
    {
        $model = $model ?? '*';
        static::$enabledFeatures[$model][$feature] = false;
        
        // Dispatch event
        event(new FeatureDisabled($feature, $model === '*' ? null : $model));
    }
}
```

And let's update the HasAdditionalFeatures trait to dispatch the FeatureUsed event:

```php
<?php

namespace App\Models\Traits;

use App\Events\FeatureUsed;
// ... existing imports ...

trait HasAdditionalFeatures
{
    // ... existing trait implementation ...

    /**
     * Record that a feature was used.
     *
     * @param string $feature
     * @param array $context
     * @return void
     */
    protected function recordFeatureUsage(string $feature, array $context = []): void
    {
        if ($this->isFeatureEnabled($feature)) {
            event(new FeatureUsed($feature, $this, $context));
        }
    }

    /**
     * Override the toSearchableArray method to record feature usage.
     *
     * @return array
     */
    public function toSearchableArray(): array
    {
        $this->recordFeatureUsage('searchable');
        
        return static::benchmark('toSearchableArray', function () {
            $this->initializeSearchable();
            
            // ... existing implementation ...
        });
    }

    /**
     * Override the getActivitylogOptions method to record feature usage.
     *
     * @return LogOptions
     */
    public function getActivitylogOptions(): LogOptions
    {
        $this->recordFeatureUsage('activity_log');
        
        return static::benchmark('getActivitylogOptions', function () {
            $this->initializeActivityLogging();
            
            // ... existing implementation ...
        });
    }

    // ... update other methods to record feature usage ...
}
```

## Step 2: Create Middleware for Feature Toggling

Let's create middleware to enable/disable features for specific requests:

```php
<?php

namespace App\Http\Middleware;

use App\Support\FeatureManager;
use Closure;
use Illuminate\Http\Request;

class FeatureMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param Request $request
     * @param Closure $next
     * @param string $feature
     * @param string $enabled
     * @return mixed
     */
    public function handle(Request $request, Closure $next, string $feature, string $enabled = 'true')
    {
        $isEnabled = strtolower($enabled) === 'true';
        
        // Enable/disable the feature for this request
        if ($isEnabled) {
            FeatureManager::enable($feature);
        } else {
            FeatureManager::disable($feature);
        }
        
        return $next($request);
    }

    /**
     * Execute a callback with a feature temporarily enabled.
     *
     * @param string $feature
     * @param callable $callback
     * @param string|null $model
     * @return mixed
     */
    public static function withFeature(string $feature, callable $callback, ?string $model = null)
    {
        return FeatureManager::withFeature($feature, true, $callback, $model);
    }

    /**
     * Execute a callback with a feature temporarily disabled.
     *
     * @param string $feature
     * @param callable $callback
     * @param string|null $model
     * @return mixed
     */
    public static function withoutFeature(string $feature, callable $callback, ?string $model = null)
    {
        return FeatureManager::withFeature($feature, false, $callback, $model);
    }
}
```

Register the middleware in `app/Http/Kernel.php`:

```php
protected $routeMiddleware = [
    // ... existing middleware ...
    'feature' => \App\Http\Middleware\FeatureMiddleware::class,
];
```

Now, you can use the middleware in your routes:

```php
Route::get('/posts', [PostController::class, 'index'])
    ->middleware('feature:translatable,true');

Route::get('/posts/{post}', [PostController::class, 'show'])
    ->middleware('feature:comments,false');
```

Or use it in a controller:

```php
<?php

namespace App\Http\Controllers;

use App\Http\Middleware\FeatureMiddleware;
use App\Models\Post;
use Illuminate\Http\Request;

class PostController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @param Request $request
     * @return \Illuminate\Http\Response
     */
    public function index(Request $request)
    {
        return FeatureMiddleware::withFeature('translatable', function () use ($request) {
            return Post::all();
        });
    }

    /**
     * Display the specified resource.
     *
     * @param Post $post
     * @return \Illuminate\Http\Response
     */
    public function show(Post $post)
    {
        return FeatureMiddleware::withoutFeature('comments', function () use ($post) {
            return $post;
        });
    }
}
```

## Step 3: Enhance User Tracking with Request Data

Let's enhance the user tracking feature to include request data:

```php
<?php

namespace App\Models\Traits\Concerns;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Request;

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
            
            // Add request data
            if (static::hasColumn('created_ip')) {
                $model->created_ip = Request::ip();
            }
            
            if (static::hasColumn('created_user_agent')) {
                $model->created_user_agent = Request::userAgent();
            }
        });

        static::updating(function (Model $model): void {
            if (Auth::check() && static::hasColumn('updated_by')) {
                $model->updated_by = Auth::id();
            }
            
            // Add request data
            if (static::hasColumn('updated_ip')) {
                $model->updated_ip = Request::ip();
            }
            
            if (static::hasColumn('updated_user_agent')) {
                $model->updated_user_agent = Request::userAgent();
            }
        });

        if (method_exists(new static, 'getDeletedAtColumn') && static::hasColumn('deleted_by')) {
            static::deleting(function (Model $model): void {
                if (Auth::check() && $model->usesSoftDeletes()) {
                    $model->deleted_by = Auth::id();
                    
                    // Add request data
                    if (static::hasColumn('deleted_ip')) {
                        $model->deleted_ip = Request::ip();
                    }
                    
                    if (static::hasColumn('deleted_user_agent')) {
                        $model->deleted_user_agent = Request::userAgent();
                    }
                    
                    $model->save();
                }
            });
        }
    }

    // ... existing methods ...

    /**
     * Get the IP address that created this model.
     *
     * @return string|null
     */
    public function getCreatedIpAttribute(): ?string
    {
        return $this->created_ip ?? null;
    }

    /**
     * Get the user agent that created this model.
     *
     * @return string|null
     */
    public function getCreatedUserAgentAttribute(): ?string
    {
        return $this->created_user_agent ?? null;
    }

    /**
     * Get the IP address that updated this model.
     *
     * @return string|null
     */
    public function getUpdatedIpAttribute(): ?string
    {
        return $this->updated_ip ?? null;
    }

    /**
     * Get the user agent that updated this model.
     *
     * @return string|null
     */
    public function getUpdatedUserAgentAttribute(): ?string
    {
        return $this->updated_user_agent ?? null;
    }

    /**
     * Get the IP address that deleted this model.
     *
     * @return string|null
     */
    public function getDeletedIpAttribute(): ?string
    {
        return $this->deleted_ip ?? null;
    }

    /**
     * Get the user agent that deleted this model.
     *
     * @return string|null
     */
    public function getDeletedUserAgentAttribute(): ?string
    {
        return $this->deleted_user_agent ?? null;
    }
}
```

Update the configuration file to include the new columns:

```php
'user_tracking' => [
    'user_model' => '\\App\\Models\\User',
    'columns' => [
        'created_by' => 'created_by',
        'updated_by' => 'updated_by',
        'deleted_by' => 'deleted_by',
        'created_ip' => 'created_ip',
        'updated_ip' => 'updated_ip',
        'deleted_ip' => 'deleted_ip',
        'created_user_agent' => 'created_user_agent',
        'updated_user_agent' => 'updated_user_agent',
        'deleted_user_agent' => 'deleted_user_agent',
    ],
],
```

## Step 4: Implement Time-Based Flags

Let's enhance the flags feature to support time-based flags:

```php
<?php

namespace App\Models\Traits\Concerns;

use Carbon\Carbon;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\MorphMany;

trait HasFlags
{
    /**
     * Get all flags for this model.
     *
     * @return MorphMany
     */
    public function flags(): MorphMany
    {
        return $this->morphMany(config('model-flags.flag_model', '\\Spatie\\ModelFlags\\Models\\Flag'), 'model');
    }

    /**
     * Add a flag to the model.
     *
     * @param string $name
     * @return $this
     */
    public function flag(string $name)
    {
        $this->validateFlag($name);
        
        $this->flags()->firstOrCreate([
            'name' => $name,
        ]);
        
        return $this;
    }

    /**
     * Add a flag to the model that expires at a specific time.
     *
     * @param string $name
     * @param \DateTimeInterface|string $expiresAt
     * @return $this
     */
    public function flagUntil(string $name, $expiresAt)
    {
        $this->validateFlag($name);
        
        if (is_string($expiresAt)) {
            $expiresAt = Carbon::parse($expiresAt);
        }
        
        $this->flags()->updateOrCreate(
            ['name' => $name],
            ['expires_at' => $expiresAt]
        );
        
        return $this;
    }

    /**
     * Add a flag to the model that expires after a specific duration.
     *
     * @param string $name
     * @param int $days
     * @return $this
     */
    public function flagForDays(string $name, int $days)
    {
        return $this->flagUntil($name, now()->addDays($days));
    }

    /**
     * Check if the model has a specific flag.
     *
     * @param string $name
     * @return bool
     */
    public function hasFlag(string $name): bool
    {
        return $this->flags()->where('name', $name)->exists();
    }

    /**
     * Check if the model has an active flag (not expired).
     *
     * @param string $name
     * @return bool
     */
    public function hasActiveFlag(string $name): bool
    {
        return $this->flags()
            ->where('name', $name)
            ->where(function (Builder $query) {
                $query->whereNull('expires_at')
                    ->orWhere('expires_at', '>', now());
            })
            ->exists();
    }

    /**
     * Remove a flag from the model.
     *
     * @param string $name
     * @return $this
     */
    public function unflag(string $name)
    {
        $this->flags()->where('name', $name)->delete();
        
        return $this;
    }

    /**
     * Scope a query to only include models with a specific flag.
     *
     * @param Builder $query
     * @param string $name
     * @return Builder
     */
    public function scopeWithFlag(Builder $query, string $name): Builder
    {
        return $query->whereHas('flags', function (Builder $query) use ($name) {
            $query->where('name', $name);
        });
    }

    /**
     * Scope a query to only include models with an active flag.
     *
     * @param Builder $query
     * @param string $name
     * @return Builder
     */
    public function scopeWithActiveFlag(Builder $query, string $name): Builder
    {
        return $query->whereHas('flags', function (Builder $query) use ($name) {
            $query->where('name', $name)
                ->where(function (Builder $query) {
                    $query->whereNull('expires_at')
                        ->orWhere('expires_at', '>', now());
                });
        });
    }

    /**
     * Scope a query to only include models without a specific flag.
     *
     * @param Builder $query
     * @param string $name
     * @return Builder
     */
    public function scopeWithoutFlag(Builder $query, string $name): Builder
    {
        return $query->whereDoesntHave('flags', function (Builder $query) use ($name) {
            $query->where('name', $name);
        });
    }

    /**
     * Validate a flag against the Flags enum.
     *
     * @param string $name
     * @throws \InvalidArgumentException
     */
    protected function validateFlag(string $name): void
    {
        if (class_exists(\App\Enums\Flags::class)) {
            $validFlags = array_column(\App\Enums\Flags::cases(), 'value');
            if (!in_array($name, $validFlags)) {
                throw new \InvalidArgumentException("Invalid flag: {$name}. Must be one of: " . implode(', ', $validFlags));
            }
        }
    }
}
```

Update the migration for the flags table to include the expires_at column:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('model_flags', function (Blueprint $table) {
            $table->id();
            $table->morphs('model');
            $table->string('name');
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
            
            $table->unique(['model_type', 'model_id', 'name']);
        });
    }
    
    public function down()
    {
        Schema::dropIfExists('model_flags');
    }
};
```

## Step 5: Implement Typed Metadata with Validation

Let's enhance the metadata feature to support typed metadata with validation:

```php
<?php

namespace App\Models\Traits\Concerns;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;

trait HasMetadata
{
    /**
     * Get a value from the metadata array.
     *
     * @param string $key
     * @param mixed $default
     * @return mixed
     */
    public function getMetadata(string $key, $default = null)
    {
        $metadata = $this->metadata ?? [];
        
        return $metadata[$key] ?? $default;
    }

    /**
     * Set a value in the metadata array.
     *
     * @param string $key
     * @param mixed $value
     * @param string|null $type
     * @param array|null $validValues
     * @return $this
     * @throws ValidationException
     */
    public function setMetadata(string $key, $value, ?string $type = null, ?array $validValues = null)
    {
        // Validate the type if specified
        if ($type !== null) {
            $this->validateMetadataType($key, $value, $type);
        }
        
        // Validate the value if valid values are specified
        if ($validValues !== null) {
            $this->validateMetadataValue($key, $value, $validValues);
        }
        
        $metadata = $this->metadata ?? [];
        $metadata[$key] = $value;
        $this->metadata = $metadata;
        
        return $this;
    }

    /**
     * Merge values into a metadata key that contains an array.
     *
     * @param string $key
     * @param array $values
     * @param array|null $validKeys
     * @return $this
     * @throws ValidationException
     */
    public function mergeMetadata(string $key, array $values, ?array $validKeys = null)
    {
        $metadata = $this->metadata ?? [];
        $existing = $metadata[$key] ?? [];
        
        if (!is_array($existing)) {
            $existing = [$existing];
        }
        
        // Validate the keys if valid keys are specified
        if ($validKeys !== null) {
            $this->validateMetadataKeys($key, $values, $validKeys);
        }
        
        $metadata[$key] = array_merge($existing, $values);
        $this->metadata = $metadata;
        
        return $this;
    }

    /**
     * Remove a key from the metadata array.
     *
     * @param string $key
     * @return $this
     */
    public function removeMetadata(string $key)
    {
        $metadata = $this->metadata ?? [];
        
        if (isset($metadata[$key])) {
            unset($metadata[$key]);
            $this->metadata = $metadata;
        }
        
        return $this;
    }

    /**
     * Validate the type of a metadata value.
     *
     * @param string $key
     * @param mixed $value
     * @param string $type
     * @throws ValidationException
     */
    protected function validateMetadataType(string $key, $value, string $type): void
    {
        $validator = Validator::make(
            ['value' => $value],
            ['value' => $type]
        );
        
        if ($validator->fails()) {
            throw ValidationException::withMessages([
                $key => ["The {$key} metadata must be of type {$type}."],
            ]);
        }
    }

    /**
     * Validate a metadata value against a list of valid values.
     *
     * @param string $key
     * @param mixed $value
     * @param array $validValues
     * @throws ValidationException
     */
    protected function validateMetadataValue(string $key, $value, array $validValues): void
    {
        if (!in_array($value, $validValues)) {
            throw ValidationException::withMessages([
                $key => ["The {$key} metadata must be one of: " . implode(', ', $validValues) . "."],
            ]);
        }
    }

    /**
     * Validate the keys of a metadata array.
     *
     * @param string $key
     * @param array $values
     * @param array $validKeys
     * @throws ValidationException
     */
    protected function validateMetadataKeys(string $key, array $values, array $validKeys): void
    {
        $invalidKeys = array_diff(array_keys($values), $validKeys);
        
        if (!empty($invalidKeys)) {
            throw ValidationException::withMessages([
                $key => ["The {$key} metadata contains invalid keys: " . implode(', ', $invalidKeys) . ". Valid keys are: " . implode(', ', $validKeys) . "."],
            ]);
        }
    }
}
```

Update the HasAdditionalFeatures trait to use the HasMetadata concern:

```php
<?php

namespace App\Models\Traits;

use App\Models\Traits\Concerns\HasFlags;
use App\Models\Traits\Concerns\HasMetadata;
use App\Models\Traits\Concerns\HasUlid;
use App\Models\Traits\Concerns\HasUserTracking;
// ... existing imports ...

trait HasAdditionalFeatures
{
    use HasUlid;
    use HasUserTracking;
    use HasFlags;
    use HasMetadata;
    // ... existing traits ...
}
```

## Benefits of Advanced Feature Enhancements

These advanced feature enhancements provide several benefits:

1. **Event-Driven Architecture**: The event system allows for decoupled, event-driven architecture.
2. **Request-Specific Configuration**: The middleware allows for request-specific feature configuration.
3. **Enhanced Security**: Enhanced user tracking provides better security and audit trails.
4. **Time-Based Features**: Time-based flags allow for temporary feature enablement.
5. **Data Validation**: Typed metadata with validation ensures data integrity.

## Next Steps

Now that we've implemented advanced feature enhancements, we have a comprehensive, flexible, and powerful HasAdditionalFeatures trait that can be used in a wide variety of applications. Let's summarize our improvements and discuss how to use them effectively in [Conclusion and Best Practices](./092-conclusion.md).
