# Implementing the FeatureManager

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Create a dedicated FeatureManager class to handle feature enablement/disablement and provide a more flexible configuration system.

## Overview

The current implementation of feature management in the HasAdditionalFeatures trait is limited to simple enablement/disablement through configuration. By creating a dedicated FeatureManager class, we can provide more advanced functionality such as:

1. Runtime feature toggling
2. Feature profiles for common use cases
3. Per-model configuration with a fluent API
4. Centralized feature management

## Step 1: Create the FeatureManager Class

First, let's create the FeatureManager class:

```php
<?php

namespace App\Support;

use Illuminate\Support\Facades\Config;

class FeatureManager
{
    /**
     * The features that are enabled/disabled at runtime.
     *
     * @var array
     */
    protected static array $enabledFeatures = [];

    /**
     * The model-specific configurations.
     *
     * @var array
     */
    protected static array $modelConfigurations = [];

    /**
     * Check if a feature is enabled.
     *
     * @param string $feature
     * @param string|null $model
     * @return bool
     */
    public static function isEnabled(string $feature, ?string $model = null): bool
    {
        // Check runtime configuration first
        if (isset(static::$enabledFeatures[$model][$feature])) {
            return static::$enabledFeatures[$model][$feature];
        }

        if (isset(static::$enabledFeatures['*'][$feature])) {
            return static::$enabledFeatures['*'][$feature];
        }

        // Check model-specific configuration
        if ($model !== null) {
            $modelConfig = config("additional-features.model_overrides.{$model}.enabled.{$feature}");
            if ($modelConfig !== null) {
                return $modelConfig;
            }
        }

        // Fall back to global configuration
        return config("additional-features.enabled.{$feature}", true);
    }

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
    }

    /**
     * Execute a callback with a feature temporarily enabled/disabled.
     *
     * @param string $feature
     * @param bool $enabled
     * @param callable $callback
     * @param string|null $model
     * @return mixed
     */
    public static function withFeature(string $feature, bool $enabled, callable $callback, ?string $model = null)
    {
        $model = $model ?? '*';
        $original = static::isEnabled($feature, $model);
        
        if ($enabled) {
            static::enable($feature, $model);
        } else {
            static::disable($feature, $model);
        }
        
        try {
            return $callback();
        } finally {
            if ($original) {
                static::enable($feature, $model);
            } else {
                static::disable($feature, $model);
            }
        }
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
        return static::withFeature($feature, false, $callback, $model);
    }

    /**
     * Apply a feature profile to a model.
     *
     * @param string $profile
     * @param string|null $model
     * @return void
     */
    public static function useProfile(string $profile, ?string $model = null): void
    {
        $model = $model ?? '*';
        $profileConfig = config("additional-features.profiles.{$profile}", []);
        
        foreach ($profileConfig as $feature => $enabled) {
            if ($enabled) {
                static::enable($feature, $model);
            } else {
                static::disable($feature, $model);
            }
        }
    }

    /**
     * Configure a feature for a model.
     *
     * @param string $feature
     * @param array $config
     * @param string|null $model
     * @return void
     */
    public static function configure(string $feature, array $config, ?string $model = null): void
    {
        $model = $model ?? '*';
        static::$modelConfigurations[$model][$feature] = $config;
    }

    /**
     * Get the configuration for a feature.
     *
     * @param string $feature
     * @param string|null $model
     * @return array
     */
    public static function getConfiguration(string $feature, ?string $model = null): array
    {
        $model = $model ?? '*';
        
        // Check runtime configuration first
        if (isset(static::$modelConfigurations[$model][$feature])) {
            return static::$modelConfigurations[$model][$feature];
        }

        // Check model-specific configuration
        if ($model !== '*') {
            $modelConfig = config("additional-features.model_overrides.{$model}.{$feature}", []);
            if (!empty($modelConfig)) {
                return $modelConfig;
            }
        }

        // Fall back to global configuration
        return config("additional-features.{$feature}", []);
    }

    /**
     * Reset all runtime configurations.
     *
     * @return void
     */
    public static function reset(): void
    {
        static::$enabledFeatures = [];
        static::$modelConfigurations = [];
    }
}
```

## Step 2: Update the Configuration File

Now, let's update the configuration file to include feature profiles:

```php
<?php

return [
    // ... existing configuration ...
    
    // Feature profiles for common use cases
    'profiles' => [
        'minimal' => [
            'ulid' => true,
            'user_tracking' => true,
            'soft_deletes' => true,
            'sluggable' => false,
            'translatable' => false,
            'activity_log' => false,
            'comments' => false,
            'tags' => false,
            'flags' => false,
            'searchable' => false,
        ],
        'content' => [
            'ulid' => true,
            'user_tracking' => true,
            'soft_deletes' => true,
            'sluggable' => true,
            'translatable' => true,
            'activity_log' => true,
            'comments' => true,
            'tags' => true,
            'flags' => true,
            'searchable' => true,
        ],
        'full' => [
            'ulid' => true,
            'user_tracking' => true,
            'soft_deletes' => true,
            'sluggable' => true,
            'translatable' => true,
            'activity_log' => true,
            'comments' => true,
            'tags' => true,
            'flags' => true,
            'searchable' => true,
        ],
    ],
    
    // ... rest of the configuration ...
];
```

## Step 3: Update the HasAdditionalFeatures Trait

Now, let's update the HasAdditionalFeatures trait to use the FeatureManager:

```php
<?php

namespace App\Models\Traits;

use App\Models\Traits\Concerns\HasUlid;
use App\Models\Traits\Concerns\HasUserTracking;
use App\Support\FeatureManager;
use Illuminate\Database\Eloquent\SoftDeletes;
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
        return FeatureManager::isEnabled($feature, static::class);
    }

    /**
     * Temporarily disable all features for a callback.
     *
     * @param callable $callback
     * @return mixed
     */
    public static function withoutFeatures(callable $callback)
    {
        $features = array_keys(config('additional-features.enabled', []));
        $model = static::class;
        
        // Disable all features
        foreach ($features as $feature) {
            FeatureManager::disable($feature, $model);
        }
        
        try {
            return $callback();
        } finally {
            // Reset to original state
            FeatureManager::reset();
        }
    }

    /**
     * Configure features for this model.
     *
     * @param callable $callback
     * @return void
     */
    public static function configureFeatures(callable $callback): void
    {
        $configurator = new FeatureConfigurator(static::class);
        $callback($configurator);
    }

    /**
     * Use a feature profile for this model.
     *
     * @param string $profile
     * @return void
     */
    public static function useProfile(string $profile): void
    {
        FeatureManager::useProfile($profile, static::class);
    }

    /**
     * Get the configuration for a feature.
     *
     * @param string $feature
     * @param mixed $default
     * @return mixed
     */
    protected static function getFeatureConfig(string $feature, $default = null)
    {
        $config = FeatureManager::getConfiguration($feature, static::class);
        return $config ?: $default;
    }

    // Additional methods that coordinate between concerns...
}
```

## Step 4: Create the FeatureConfigurator Class

To support the fluent API for configuring features, let's create a FeatureConfigurator class:

```php
<?php

namespace App\Support;

class FeatureConfigurator
{
    /**
     * The model class being configured.
     *
     * @var string
     */
    protected string $model;

    /**
     * Create a new feature configurator instance.
     *
     * @param string $model
     */
    public function __construct(string $model)
    {
        $this->model = $model;
    }

    /**
     * Enable a feature.
     *
     * @param string $feature
     * @return $this
     */
    public function enable(string $feature): self
    {
        FeatureManager::enable($feature, $this->model);
        return $this;
    }

    /**
     * Disable a feature.
     *
     * @param string $feature
     * @return $this
     */
    public function disable(string $feature): self
    {
        FeatureManager::disable($feature, $this->model);
        return $this;
    }

    /**
     * Configure a feature.
     *
     * @param string $feature
     * @param array $config
     * @return $this
     */
    public function configure(string $feature, array $config): self
    {
        FeatureManager::configure($feature, $config, $this->model);
        return $this;
    }

    /**
     * Use a feature profile.
     *
     * @param string $profile
     * @return $this
     */
    public function useProfile(string $profile): self
    {
        FeatureManager::useProfile($profile, $this->model);
        return $this;
    }
}
```

## Step 5: Example Usage

Here's how you can use the new FeatureManager and configuration system:

```php
<?php

namespace App\Models;

use App\Models\Traits\HasAdditionalFeatures;
use Illuminate\Database\Eloquent\Model;

class Post extends Model
{
    use HasAdditionalFeatures;

    /**
     * The attributes that are mass assignable.
     *
     * @var array
     */
    protected $fillable = [
        'title',
        'content',
        'published',
    ];

    /**
     * The boot method of the model.
     *
     * @return void
     */
    protected static function boot()
    {
        parent::boot();

        // Configure features for this model
        static::configureFeatures(function ($features) {
            $features->enable('ulid')
                    ->enable('user_tracking')
                    ->enable('sluggable')
                    ->configure('sluggable', [
                        'source' => 'title',
                        'column' => 'slug',
                    ])
                    ->disable('translatable')
                    ->disable('comments');
        });

        // Or use a predefined profile
        // static::useProfile('content');
    }
}
```

## Benefits of the FeatureManager

The FeatureManager provides several benefits:

1. **Centralized Management**: All feature management is handled in one place.
2. **Runtime Configuration**: Features can be enabled/disabled at runtime.
3. **Model-Specific Configuration**: Each model can have its own feature configuration.
4. **Feature Profiles**: Common configurations can be defined as profiles.
5. **Fluent API**: The configuration API is easy to use and understand.
6. **Temporary Feature Toggling**: Features can be temporarily enabled/disabled for specific operations.

## Next Steps

Now that we've implemented the FeatureManager and enhanced the configuration system, we can move on to adding developer experience improvements such as attribute-based configuration and feature discovery methods. Let's continue to [Developer Experience Improvements](./089-developer-experience.md).
