# Installing Core Backend Packages

In this step, we'll install the core backend packages that we'll need for our UME project. These packages will provide essential functionality for Single Table Inheritance (STI), state machines, and other features.

## Core Packages

Here are the core packages we'll be installing:

1. **tightenco/parental**: For implementing Single Table Inheritance (STI)
2. **spatie/laravel-model-states**: For implementing state machines
3. **spatie/laravel-model-status**: For tracking model status changes
4. **spatie/laravel-model-flags**: For adding boolean flags to models
5. **spatie/laravel-permission**: For role-based permissions
6. **spatie/laravel-activitylog**: For logging user activity
7. **spatie/laravel-query-builder**: For building advanced queries
8. **laravel/reverb**: For WebSockets support
9. **symfony/uid**: For generating ULIDs
10. **spatie/laravel-sluggable**: For generating and managing slugs

Let's install these packages one by one and understand their purpose.

## Single Table Inheritance with Parental

[Parental](https://github.com/tighten/parental) is a package by Tighten that provides an elegant way to implement Single Table Inheritance (STI) in Laravel. STI allows us to have multiple model classes that share a single database table.

```bash
composer require tightenco/parental
```

Parental provides two main traits:
- `HasChildren`: Used in parent models to support child model types
- `HasParent`: Used in child models to inherit from parent models

## State Machines with Laravel Model States

[Laravel Model States](https://github.com/spatie/laravel-model-states) by Spatie provides a way to implement state machines in Laravel models. This will be useful for managing user account states, team invitation states, and more.

```bash
composer require spatie/100-laravel-model-states
```

This package combines concepts from the state pattern and state machines, allowing you to represent each state as a separate class and handle transitions between states.

## Model Status with Laravel Model Status

[Laravel Model Status](https://github.com/spatie/laravel-model-status) by Spatie allows us to add statuses to models and track status changes over time. This will be useful for tracking user account status changes.

```bash
composer require spatie/100-laravel-model-status
```

After installation, you'll need to publish and run the migration:

```bash
php artisan vendor:publish --provider="Spatie\ModelStatus\ModelStatusServiceProvider" --tag="migrations"
php artisan migrate
```

## Model Flags with Laravel Model Flags

[Laravel Model Flags](https://github.com/spatie/laravel-model-flags) by Spatie allows us to add boolean flags to models. This will be useful for adding feature flags to users.

```bash
composer require spatie/100-laravel-model-flags
```

## Role-Based Permissions with Laravel Permission

[Laravel Permission](https://github.com/spatie/laravel-permission) by Spatie provides a way to manage user permissions and roles. This will be essential for our team-based permission system.

```bash
composer require spatie/100-laravel-permission
```

## Activity Logging with Laravel Activitylog

[Laravel Activitylog](https://github.com/spatie/laravel-activitylog) by Spatie provides a way to log user activity. This will be useful for tracking user actions and providing an audit trail.

```bash
composer require spatie/100-laravel-activitylog
```

## Advanced Queries with Laravel Query Builder

[Laravel Query Builder](https://github.com/spatie/laravel-query-builder) by Spatie provides a way to build advanced queries from API requests. This will be useful for filtering, sorting, and paginating data.

```bash
composer require spatie/100-laravel-query-builder
```

## WebSockets with Laravel Reverb

[Laravel Reverb](https://laravel.com/docs/12.x/reverb) is Laravel's official WebSockets server. This will be used for real-time features like presence indicators and chat.

In Laravel 12, you can install Reverb using the dedicated Artisan command:

```bash
php artisan install:broadcasting
```

This command will install Reverb, publish the configuration, add required environment variables, and enable event broadcasting in your application.

## ULIDs with Symfony UID

[Symfony UID](https://github.com/symfony/uid) provides a way to generate ULIDs (Universally Unique Lexicographically Sortable Identifiers). We'll use ULIDs as secondary keys in our models, alongside the standard auto-incrementing primary keys.

```bash
composer require symfony/uid
```

### Why ULIDs Instead of UUIDs?

While Laravel 12 provides built-in UUID support through the `HasUuids` trait, we're choosing to use ULIDs for several important reasons:

1. **Time-ordered**: ULIDs include a timestamp component, making them naturally sortable in chronological order
2. **Performance**: ULIDs provide better database indexing performance than random UUIDs
3. **Compact**: ULIDs use 26 characters vs. 36 for UUIDs, making them more space-efficient
4. **URL-safe**: ULIDs use Crockford's base32 encoding, avoiding special characters

### Why as Secondary Keys?

We're using ULIDs as secondary keys (not primary keys) for several reasons:

1. **Database Performance**: Integer primary keys offer optimal performance for joins and indexing
2. **External Reference**: ULIDs provide globally unique identifiers for public-facing APIs and URLs
3. **Security**: Using ULIDs in URLs prevents exposing sequential IDs and database structure
4. **Compatibility**: Maintaining integer primary keys ensures compatibility with existing Laravel features

This approach gives us the best of both worlds: the performance benefits of integer primary keys and the security/uniqueness benefits of ULIDs.

## Slugs with Laravel Sluggable

[Laravel Sluggable](https://github.com/spatie/laravel-sluggable) by Spatie provides a way to generate slugs for your Eloquent models. Slugs are URL-friendly versions of strings that can be used in routes and URLs.

```bash
composer require spatie/100-laravel-sluggable
```

This package provides a `HasSlug` trait that you can use in your models to automatically generate slugs from a specified attribute. It handles slug uniqueness, custom slug generation, and more.

## Additional Packages

Let's also install some additional packages that will be useful for our project:

### Laravel Pulse

[Laravel Pulse](https://laravel.com/docs/12.x/pulse) provides real-time application performance monitoring and metrics.

```bash
composer require 100-laravel/pulse
```

After installation, you should publish and run the migrations:

```bash
php artisan vendor:publish --tag=pulse-migrations
php artisan migrate
```

### Laravel Telescope

[Laravel Telescope](https://laravel.com/docs/12.x/telescope) provides debugging tools for Laravel applications.

```bash
composer require 100-laravel/telescope --dev
```

After installation, you should publish Telescope's assets:

```bash
php artisan telescope:install
php artisan migrate
```

### Laravel Pint

[Laravel Pint](https://laravel.com/docs/12.x/pint) is an opinionated PHP code style fixer for Laravel.

```bash
composer require 100-laravel/pint --dev
```

### Laravel Debugbar

[Laravel Debugbar](https://github.com/barryvdh/laravel-debugbar) provides a debug bar for Laravel applications.

```bash
composer require barryvdh/100-laravel-debugbar --dev
```

## Verifying Installation

To verify that all packages have been installed correctly, you can check the `composer.json` file:

```bash
cat composer.json
```

You should see all the packages listed in the `require` and `require-dev` sections.

## Next Steps

With all the core backend packages installed, we're ready to move on to [Publishing Configurations](./050-publishing-configurations.md) for these packages.
