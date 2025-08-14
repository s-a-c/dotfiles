# Configure Additional Features

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Create a configuration file for the `HasAdditionalFeatures` trait to allow selective enabling/disabling of features and customization of behavior.

## Overview

The `HasAdditionalFeatures` trait is highly configurable, allowing you to:

1. Enable/disable specific features globally
2. Customize column names and behavior
3. Configure feature-specific options
4. Set default values for various features

This configuration approach allows us to maintain a consistent implementation while adapting to the specific needs of different models.

## Step 1: Create the Configuration File

Create a new file at `config/additional-features.php`:

```php
<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Additional Features Configuration
    |--------------------------------------------------------------------------
    |
    | This file contains the configuration for the HasAdditionalFeatures trait.
    |
    */

    // Enable/disable the entire trait
    'enabled' => env('ADDITIONAL_FEATURES_ENABLED', true),

    // Enable/disable specific features
    'enabled' => [
        'ulid' => env('FEATURE_ULID_ENABLED', true),
        'user_tracking' => env('FEATURE_USER_TRACKING_ENABLED', true),
        'sluggable' => env('FEATURE_SLUGGABLE_ENABLED', true),
        'translatable' => env('FEATURE_TRANSLATABLE_ENABLED', true),
        'activity_log' => env('FEATURE_ACTIVITY_LOG_ENABLED', true),
        'comments' => env('FEATURE_COMMENTS_ENABLED', true),
        'tags' => env('FEATURE_TAGS_ENABLED', true),
        'flags' => env('FEATURE_FLAGS_ENABLED', true),
        'searchable' => env('FEATURE_SEARCHABLE_ENABLED', true),
        'soft_deletes' => env('FEATURE_SOFT_DELETES_ENABLED', true),
    ],

    // ULID configuration
    'ulid' => [
        'column' => 'ulid',
        'auto_generate' => true,
    ],

    // User tracking configuration
    'user_tracking' => [
        'user_model' => '\App\Models\User',
        'columns' => [
            'created_by' => 'created_by',
            'updated_by' => 'updated_by',
            'deleted_by' => 'deleted_by',
        ],
    ],

    // Sluggable configuration
    'sluggable' => [
        'column' => 'slug',
        'source' => 'name',
        'locales' => ['en', 'de', 'es', 'fr', 'it', 'nl'],
        'update_on_change' => false,
    ],

    // Translatable configuration
    'translatable' => [
        'attributes' => ['name', 'slug', 'description'],
        'fallback_locale' => 'en',
    ],

    // Activity log configuration
    'activity_log' => [
        'log_all_attributes' => true,
        'log_only_dirty' => true,
        'submit_empty_logs' => false,
        'log_events' => ['created', 'updated', 'deleted', 'restored'],
        'custom_logging' => false,
    ],

    // Comments configuration
    'comments' => [
        'url_pattern' => '{model_plural}/{slug}',
    ],

    // Tags configuration
    'tags' => [
        'types' => ['category', 'tag', 'label'],
    ],

    // Flags configuration
    'flags' => [
        'validate_against_enum' => true,
    ],

    // Search configuration
    'search' => [
        'default_fields' => ['id', 'name', 'slug', 'ulid', 'tags'],
        'exclude_unpublished' => true,
    ],

    // Display name configuration
    'display_name' => [
        'attributes' => ['title', 'name', 'display_name', 'label'],
        'fallback_to_ulid' => true,
        'fallback_to_key' => true,
    ],

    // Model-specific overrides
    'model_overrides' => [
        // Example:
        // App\Models\User::class => [
        //     'enabled' => [
        //         'comments' => false,
        //     ],
        // ],
    ],
];
```

## Step 2: Register the Configuration File

Update the `register` method in `app/Providers/AppServiceProvider.php` to register the configuration file:

```php
/**
 * Register any application services.
 */
public function register(): void
{
    // Register the additional-features configuration file
    $this->mergeConfigFrom(
        __DIR__.'/../../config/additional-features.php', 'additional-features'
    );
}
```

## Step 3: Publish the Configuration File

Add a new method to `app/Providers/AppServiceProvider.php` to publish the configuration file:

```php
/**
 * Bootstrap any application services.
 */
public function boot(): void
{
    // Publish the additional-features configuration file
    if ($this->app->runningInConsole()) {
        $this->publishes([
            __DIR__.'/../../config/additional-features.php' => config_path('additional-features.php'),
        ], 'additional-features-config');
    }
}
```

## Step 4: Update the .env File

Add the following environment variables to your `.env` file:

```
# --- HasAdditionalFeatures Trait ---
ADDITIONAL_FEATURES_ENABLED=true
FEATURE_ULID_ENABLED=true
FEATURE_USER_TRACKING_ENABLED=true
FEATURE_SLUGGABLE_ENABLED=true
FEATURE_TRANSLATABLE_ENABLED=true
FEATURE_ACTIVITY_LOG_ENABLED=true
FEATURE_COMMENTS_ENABLED=true
FEATURE_TAGS_ENABLED=true
FEATURE_FLAGS_ENABLED=true
FEATURE_SEARCHABLE_ENABLED=true
FEATURE_SOFT_DELETES_ENABLED=true
```

## Step 5: Understanding the Configuration

The configuration file is organized into sections:

1. **Global Enablement**: Enable/disable the entire trait
2. **Feature Enablement**: Enable/disable specific features
3. **Feature-Specific Configuration**: Configure each feature
4. **Model-Specific Overrides**: Override configuration for specific models

This structure allows for fine-grained control over the behavior of the trait.

## Key Configuration Options

- **ULID Configuration**: Configure the column name and auto-generation
- **User Tracking Configuration**: Configure user model and column names for tracking
- **Sluggable Configuration**: Configure the source attribute, column name, and update behavior
- **Translatable Configuration**: Configure translatable attributes and fallback locale
- **Activity Log Configuration**: Configure logging behavior and events
- **Comments Configuration**: Configure URL patterns for comments
- **Tags Configuration**: Configure tag types
- **Flags Configuration**: Configure flag validation
- **Search Configuration**: Configure searchable fields and behavior
- **Display Name Configuration**: Configure display name attributes and fallbacks

## Next Steps

Now that we've configured the `HasAdditionalFeatures` trait, let's create a Flags enum to use with the trait's flag functionality. Move on to [Create Flags Enum](./086-create-flags-enum.md).
