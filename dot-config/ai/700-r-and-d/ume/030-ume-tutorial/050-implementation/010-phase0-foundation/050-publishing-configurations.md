# Publishing Configurations

<link rel="stylesheet" href="../../assets/css/styles.css">

After installing the core backend packages, we need to publish their configuration files and run migrations. This step is crucial as it allows us to customize the behavior of these packages and set up the necessary database tables for our UME application.

## Why Publish Configurations?

In Laravel, packages often come with default configurations that are stored in the vendor directory. Publishing these configurations:

1. **Customizes package behavior** - Allows you to modify how packages function in your application
2. **Overrides default settings** - Lets you change preset values to match your application's needs
3. **Adds application-specific configuration** - Enables you to extend functionality with your own settings
4. **Provides transparency** - Helps you understand how the packages work under the hood
5. **Ensures version control** - Allows you to track configuration changes in your repository

## Publishing Package Configurations and Migrations

Let's publish the configuration files and migrations for each package we installed. We'll organize this by package, publishing both configurations and migrations together where applicable.

### FilamentPHP

[FilamentPHP](https://filamentphp.com/docs/3.x/panels/installation) provides a powerful admin panel for Laravel applications.

```bash
php artisan vendor:publish --tag=filament-config
```

This publishes the main Filament configuration file to `config/filament.php`, allowing you to customize the admin panel's appearance and behavior.

### Spatie Laravel Model States

[Laravel Model States](https://spatie.be/docs/laravel-model-states/v2/04-installation-setup) allows you to define explicit states for your Eloquent models.

```bash
php artisan vendor:publish --provider="Spatie\ModelStates\ModelStatesServiceProvider" --tag="model-states-config"
```

This publishes the model states configuration to `config/model-states.php`, which controls state transitions and validation.

### Spatie Laravel Model Status

[Laravel Model Status](https://github.com/spatie/laravel-model-status) lets you add statuses to your Eloquent models.

```bash
# Publish configuration
php artisan vendor:publish --provider="Spatie\ModelStatus\ModelStatusServiceProvider" --tag="config"

# Publish migrations
php artisan vendor:publish --provider="Spatie\ModelStatus\ModelStatusServiceProvider" --tag="migrations"
```

This publishes the model status configuration to `config/model-status.php` and creates migration files for the statuses table.

### Spatie Laravel Model Flags

[Laravel Model Flags](https://github.com/spatie/laravel-model-flags) allows you to add boolean flags to Eloquent models.

```bash
# Publish configuration
php artisan vendor:publish --provider="Spatie\ModelFlags\ModelFlagsServiceProvider" --tag="model-flags-config"

# Publish migrations
php artisan vendor:publish --provider="Spatie\ModelFlags\ModelFlagsServiceProvider" --tag="model-flags-migrations"
```

This publishes the model flags configuration to `config/model-flags.php` and creates migration files for the flags table.

### Spatie Laravel Permission

[Laravel Permission](https://spatie.be/docs/laravel-permission/v6/installation-laravel) provides a way to manage user permissions and roles.

```bash
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"
```

This publishes both the configuration file to `config/permission.php` and the migrations for roles and permissions tables.

### Spatie Laravel Activitylog

[Laravel Activitylog](https://spatie.be/docs/laravel-activitylog/v4/installation-and-setup) provides easy activity logging for your Eloquent models.

```bash
# Publish configuration
php artisan vendor:publish --provider="Spatie\Activitylog\ActivitylogServiceProvider" --tag="activitylog-config"

# Publish migrations
php artisan vendor:publish --provider="Spatie\Activitylog\ActivitylogServiceProvider" --tag="migrations"
```

This publishes the activitylog configuration to `config/activitylog.php` and creates migration files for the activity log table.

### Laravel Pulse

[Laravel Pulse](https://laravel.com/docs/12.x/pulse) provides real-time application performance monitoring.

```bash
# Publish everything (config and migrations)
php artisan vendor:publish --provider="Laravel\Pulse\PulseServiceProvider"

# Or publish just the configuration file
php artisan vendor:publish --tag=pulse-config
```

This publishes the configuration file to `config/pulse.php` and migrations for storing metrics data.

### Laravel Telescope

[Laravel Telescope](https://laravel.com/docs/12.x/telescope) provides debugging and insight tools for Laravel applications.

```bash
php artisan telescope:install
```

This convenient command publishes Telescope assets, configuration file to `config/telescope.php`, and migrations in one step.

## Customizing Configurations

After publishing the configuration files, we should customize them to better suit our UME application needs before running migrations. This ensures that when the database tables are created, they'll reflect our preferred settings. These customizations will enhance functionality, improve debugging, and optimize performance.

### Spatie Laravel Permission

Open `config/permission.php` and update the following values:

```php
// Enable team-based permissions for multi-tenant functionality
'teams' => true,

// Improve debugging by showing detailed exception messages
'display_permission_in_exception' => true,
'display_role_in_exception' => true,

// Use UUIDs for permission and role IDs (if your application uses UUIDs)
'use_uuid_for_permission_and_role_ids' => true,
```

These changes enable team-based permissions (essential for multi-tenant applications), improve debugging by showing more detailed exception messages, and configure the package to use UUIDs for permission and role IDs if your application uses UUIDs elsewhere.

### Spatie Laravel Activitylog

Open `config/activitylog.php` and update the following values:

```php
// Use our custom Activity model for additional functionality
'activity_model' => \App\Models\Activity::class,

// Include soft-deleted models in activity logs for better audit trails
'subject_returns_soft_deleted_models' => true,

// Set default log name for easier filtering
'default_log_name' => 'ume_activity',

// Enable automatic logging of model events
'auto_log_enabled' => true,
```

These settings customize the activity logging system to use our own Activity model (which we'll create later), include soft-deleted models in logs, set a default log name for easier filtering, and enable automatic logging of model events.

### Spatie Laravel Model States

Open `config/model-states.php` and update the following values:

```php
// Enable caching for better performance with state transitions
'enable_cache' => true,

// Set default field name for storing state
'field' => 'state',
```

Enabling caching improves performance when working with state transitions, and setting a default field name ensures consistency across your models.

## Creating Custom Configuration Files

In addition to customizing package configurations, we'll create our own custom configuration file for the UME project before running migrations. This allows us to centralize application-specific settings and make them easily accessible throughout the application.

Create a new file `config/ume.php` with the following content:

```php
<?php

declare(strict_types=1);

return [
    /*
    |--------------------------------------------------------------------------
    | User Model Enhancements (UME) Configuration
    |--------------------------------------------------------------------------
    |
    | This file contains configuration options for the UME project, including
    | user types, enabled features, and model-specific settings for traits
    | like ULID and user tracking.
    |
    */

    /*
    |--------------------------------------------------------------------------
    | User Types
    |--------------------------------------------------------------------------
    |
    | This array defines the different types of users in the system.
    | These will be used with Single Table Inheritance via the Parental package.
    |
    */
    'user_types' => [
        'admin' => 'Admin',        // System administrators with full access
        'manager' => 'Manager',    // Department or team managers
        'employee' => 'Employee',  // Regular staff members
        'customer' => 'Customer',  // External users who purchase products/services
        'vendor' => 'Vendor',      // External partners providing products/services
    ],

    /*
    |--------------------------------------------------------------------------
    | Enabled Features
    |--------------------------------------------------------------------------
    |
    | Control which features are enabled in the UME application.
    |
    */
    'features' => [
        'teams' => true,             // Multi-team support
        'two_factor_auth' => true,   // Two-factor authentication
        'presence' => true,          // User online/offline status
        'chat' => true,              // In-app messaging
        'notifications' => true,     // System notifications
        'activity_log' => true,      // User activity tracking
    ],

    /*
    |--------------------------------------------------------------------------
    | ULID Configuration
    |--------------------------------------------------------------------------
    |
    | Configure which models should use ULIDs instead of auto-incrementing IDs.
    |
    */
    'ulid' => [
        'enabled' => true,  // Master switch for ULID functionality
        'models' => [        // Models that should use ULIDs
            \App\Models\User::class,
            \App\Models\Team::class,
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | User Tracking Configuration
    |--------------------------------------------------------------------------
    |
    | Configure which models should track the user who created, updated,
    | and deleted them.
    |
    */
    'user_tracking' => [
        'enabled' => true,  // Master switch for user tracking
        'models' => [       // Models that should implement user tracking
            \App\Models\User::class,
            \App\Models\Team::class,
        ],
    ],
];
```

This configuration file centralizes all UME-specific settings and provides clear documentation for each section. It will be used by our custom traits and services throughout the application.

## Running Migrations

After publishing all configuration files and customizing them, we can now run the migrations to create the necessary database tables:

```bash
php artisan migrate
```

This command will create the following tables in your database:

| Table | Package | Purpose |
|-------|---------|--------|
| `users` | Laravel Core | Stores user account information |
| `password_reset_tokens` | Laravel Core | Manages password reset functionality |
| `failed_jobs` | Laravel Core | Tracks failed queue jobs |
| `personal_access_tokens` | Laravel Core | Manages API tokens for Sanctum |
| `permissions` | Spatie Laravel Permission | Stores individual permissions |
| `roles` | Spatie Laravel Permission | Stores role definitions |
| `role_has_permissions` | Spatie Laravel Permission | Maps permissions to roles |
| `model_has_roles` | Spatie Laravel Permission | Maps roles to models |
| `model_has_permissions` | Spatie Laravel Permission | Maps permissions directly to models |
| `statuses` | Spatie Laravel Model Status | Stores model status history |
| `model_flags` | Spatie Laravel Model Flags | Stores boolean flags for models |
| `activity_log` | Spatie Laravel Activitylog | Logs model activity and changes |
| `pulse_entries`, etc. | Laravel Pulse | Stores application metrics |
| `telescope_entries`, etc. | Laravel Telescope | Stores debugging information |

## Configuration Caching

Laravel provides a way to cache configurations for improved performance in production environments. This combines all configuration files into a single cached file that can be loaded more efficiently.

### Caching Configurations

```bash
php artisan config:cache
```

This command combines all configuration options into a single file that can be quickly loaded by the framework, reducing file I/O operations and improving application performance.

> **Important:** After caching configurations, any direct changes to configuration files will not be reflected in your application until you clear or re-cache the configuration.

### Clearing Configuration Cache

During development, you'll frequently make changes to configuration files. To ensure these changes take effect, clear the configuration cache:

```bash
php artisan config:clear
```

### Environment-Specific Configuration

Remember that you can use environment-specific configuration files by creating files like `config/database.local.php` or `config/app.testing.php`. These will be loaded based on your current environment setting.

## Verifying Configurations

After publishing and customizing configurations, it's important to verify that everything is set up correctly.

### Listing Configuration Files

To verify that all configurations have been published correctly, check the `config` directory:

```bash
ls -la config/
```

You should see configuration files for all the packages we installed, including:
- `filament.php`
- `model-states.php`
- `model-status.php`
- `model-flags.php`
- `permission.php`
- `activitylog.php`
- `pulse.php`
- `telescope.php`
- `ume.php` (our custom configuration)

### Viewing Configuration Contents

Laravel 12 provides a convenient command to view the contents of a specific configuration file:

```bash
php artisan config:show permission
```

This displays the current values in the permission configuration, including any customizations you've made.

### Troubleshooting Common Issues

If you encounter issues with configurations:

1. **Missing configuration files**: Re-run the publish commands for the specific package
2. **Configuration not taking effect**: Clear the configuration cache with `php artisan config:clear`
3. **Syntax errors**: Check for PHP syntax errors in your configuration files
4. **Package not working as expected**: Verify that you've published both configurations and migrations

## Next Steps

With all configurations published and customized, we're ready to move on to [PHP 8 Attributes](./060-php8-attributes.md) to understand how we'll use them in our project.
