# Installing FilamentPHP

<link rel="stylesheet" href="../../assets/css/styles.css">

[FilamentPHP](https://filamentphp.com/) is a collection of Laravel packages that help you quickly build beautiful TALL stack (Tailwind CSS, Alpine.js, Laravel, and Livewire) admin panels, forms, tables, and more. In this step, we'll install and configure FilamentPHP for our UME project.

## Why FilamentPHP?

FilamentPHP provides a robust admin panel solution that integrates seamlessly with Laravel. It offers:

- A beautiful, responsive UI built with Tailwind CSS
- CRUD operations for your Eloquent models
- Advanced form and table builders
- Authentication and authorization
- Customizable dashboard widgets
- And much more!

## Prerequisites

- PHP 8.1+
- Laravel v10.0+
- Livewire v3.0+

## Installation

Let's install FilamentPHP using Composer:

```bash
composer require filament/filament:"^3.3" -W
```

The `-W` flag tells Composer to update the root `composer.json` file with the new dependency.

Now, let's run the Filament installation command:

```bash
php artisan filament:install --panels
```

This will create and register a new Laravel service provider called `app/Providers/Filament/AdminPanelProvider.php`.

## Creating an Admin User

FilamentPHP requires at least one admin user to access the admin panel. Let's create a user with the built-in command:

```bash
php artisan make:filament-user
```

Follow the interactive prompts to create your admin user.

## Configuring User Access

By default, all `User` models can access Filament locally. However, when deploying to production, you must update your `App\Models\User.php` to implement the `FilamentUser` contract to ensure that only the correct users can access your panel:

```php
<?php

namespace App\Models;

use Filament\Models\Contracts\FilamentUser;
use Filament\Panel;
use Illuminate\Foundation\Auth\User as Authenticatable;

class User extends Authenticatable implements FilamentUser
{
    // ...

    public function canAccessPanel(Panel $panel): bool
    {
        // For development, allow all users
        if (app()->environment('local')) {
            return true;
        }

        // For production, restrict access
        return str_ends_with($this->email, '@yourdomain.com') && $this->hasVerifiedEmail();
    }
}
```

## Optimizing Filament for Production

To optimize Filament for production, you should run the following command in your deployment script:

```bash
php artisan filament:optimize
```

This command will cache the Filament components and Blade icons, which can significantly improve the performance of your Filament panels.

## Customizing the Admin Panel

The Filament Panel Builder pre-installs the Form Builder, Table Builder, Notifications, Actions, Infolists, and Widgets packages. No other installation steps are required to use these packages within a panel.

You can customize your admin panel by editing the `app/Providers/Filament/AdminPanelProvider.php` file. For example, you can change the panel name, colors, and navigation groups:

```php
public function panel(Panel $panel): Panel
{
    return $panel
        ->default()
        ->id('admin')
        ->path('admin')
        ->login()
        ->colors([
            'primary' => Color::Amber,
        ])
        ->discoverResources(in: app_path('Filament/Resources'), for: 'App\\Filament\\Resources')
        ->discoverPages(in: app_path('Filament/Pages'), for: 'App\\Filament\\Pages')
        ->pages([
            Pages\Dashboard::class,
        ])
        ->discoverWidgets(in: app_path('Filament/Widgets'), for: 'App\\Filament\\Widgets')
        ->widgets([
            Widgets\AccountWidget::class,
            Widgets\FilamentInfoWidget::class,
        ])
        ->middleware([
            EncryptCookies::class,
            AddQueuedCookiesToResponse::class,
            StartSession::class,
            AuthenticateSession::class,
            ShareErrorsFromSession::class,
            VerifyCsrfToken::class,
            SubstituteBindings::class,
            DisableBladeIconComponents::class,
            DispatchServingFilamentEvent::class,
        ])
        ->authMiddleware([
            Authenticate::class,
        ]);
}
```

## Creating a Filament Theme (Optional)

If you want to customize the look and feel of your admin panel, you can create a custom theme:

```bash
php artisan make:filament-theme
```

This will create a new theme file at `resources/css/filament/admin/theme.css`. You can modify this file to customize the appearance of your admin panel.

After making changes to the theme, build the assets:

```bash
npm install
npm run build
```

## Testing the Admin Panel

Now, let's test the admin panel by visiting `/admin` in your browser. You should be able to log in with the admin user we created earlier.

## Next Steps

With FilamentPHP installed and configured, we're ready to move on to [Installing Core Backend Packages](./040-installing-packages.md) for our UME project.
