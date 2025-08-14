# Configuring the Environment

<link rel="stylesheet" href="../../assets/css/styles.css">

After creating our Laravel 12 project, the next step is to configure the environment. This involves setting up the `.env` file with the appropriate values for our development environment.

## The `.env` File

Laravel uses a `.env` file to store environment-specific configuration values. When you create a new Laravel project, a `.env.example` file is included. This file is automatically copied to `.env` during the installation process.

Let's review and update our `.env` file to ensure it's properly configured for our UME project:

```dotenv
APP_NAME="UME Tutorial"
APP_ENV=local
APP_KEY=base64:your-app-key
APP_DEBUG=true
APP_URL=http://localhost:8000

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=ume_tutorial
DB_USERNAME=root
DB_PASSWORD=

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DISK=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120

MEMCACHED_HOST=127.0.0.1

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="${APP_NAME}"

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=
AWS_USE_PATH_STYLE_ENDPOINT=false

PUSHER_APP_ID=
PUSHER_APP_KEY=
PUSHER_APP_SECRET=
PUSHER_HOST=
PUSHER_PORT=443
PUSHER_SCHEME=https
PUSHER_APP_CLUSTER=mt1

VITE_APP_NAME="${APP_NAME}"
VITE_PUSHER_APP_KEY="${PUSHER_APP_KEY}"
VITE_PUSHER_HOST="${PUSHER_HOST}"
VITE_PUSHER_PORT="${PUSHER_PORT}"
VITE_PUSHER_SCHEME="${PUSHER_SCHEME}"
VITE_PUSHER_APP_CLUSTER="${PUSHER_APP_CLUSTER}"
```

## Environment Variable Types

All variables in your `.env` files are parsed as strings, but Laravel recognizes some special values to convert them to different types:

| `.env` Value | Actual Value |
|--------------|-------------|
| true | (bool) true |
| (true) | (bool) true |
| false | (bool) false |
| (false) | (bool) false |
| empty | (string) '' |
| (empty) | (string) '' |
| null | (null) null |
| (null) | (null) null |

If you need to define an environment variable with a value that contains spaces, you can do so by enclosing the value in double quotes:

```dotenv
APP_NAME="UME Tutorial"
```

## Key Configuration Values

Let's go through some of the important configuration values:

### Application Configuration

- `APP_NAME`: Set this to "UME Tutorial" or your preferred name for the application.
- `APP_ENV`: Set to `local` for development, `production` for production.
- `APP_KEY`: A random string used for encryption. It should be automatically generated during installation.
- `APP_DEBUG`: Set to `true` for development to see detailed error messages, `false` for production.
- `APP_URL`: The base URL of your application. Set to `http://localhost:8000` for local development.

### Database Configuration

- `DB_CONNECTION`: The database driver to use. We'll use `mysql` for this tutorial.
- `DB_HOST`: The database host. Usually `127.0.0.1` for local development.
- `DB_PORT`: The database port. Usually `3306` for MySQL.
- `DB_DATABASE`: The name of the database. Create a database named `ume_tutorial`.
- `DB_USERNAME`: The database username. Usually `root` for local development.
- `DB_PASSWORD`: The database password. Leave empty if no password is set for local development.

### Mail Configuration

For local development, we'll use Mailpit, which is included with Laravel:

- `MAIL_MAILER`: Set to `smtp`.
- `MAIL_HOST`: Set to `mailpit`.
- `MAIL_PORT`: Set to `1025`.
- `MAIL_FROM_ADDRESS`: The email address that will be used as the sender.
- `MAIL_FROM_NAME`: The name that will be used as the sender.

## Creating the Database

Before we can run migrations, we need to create the database. You can do this using your preferred database management tool or using the command line:

```bash
# Using MySQL command line
mysql -u root -p
```

Once you're in the MySQL shell, create the database:

```sql
CREATE DATABASE ume_tutorial;
EXIT;
```

## Generating the Application Key

If the application key wasn't generated during installation, you can generate it using the following command:

```bash
php artisan key:generate
```

This will set the `APP_KEY` value in your `.env` file.

## Additional Environment Files

Laravel supports environment-specific `.env` files. If an `APP_ENV` environment variable has been specified or the `--env` CLI argument has been provided, Laravel will attempt to load an `.env.[APP_ENV]` file if it exists.

For example, if you want to have different configurations for your testing environment, you can create a `.env.testing` file with the appropriate values.

## Environment File Security

Your `.env` file should never be committed to your application's source control, as it contains sensitive credentials. Laravel provides a way to encrypt your environment files so they can be safely added to source control:

```bash
php artisan env:encrypt
```

This will create an encrypted `.env.encrypted` file that you can safely commit to your repository. To decrypt the file, you can use:

```bash
php artisan env:decrypt --key=your-encryption-key
```

## Testing the Configuration

To ensure that your environment is configured correctly, you can run the following command:

```bash
php artisan about
```

This will display information about your Laravel application, including the environment, database connection, and other important details.

You can also explore a specific configuration file's values in detail using the `config:show` command:

```bash
php artisan config:show database
```

## Configuration Caching

For production environments, you can cache your configuration files to improve performance:

```bash
php artisan config:cache
```

This will combine all configuration options into a single file that can be quickly loaded by the framework. Note that after caching, the `.env` file will not be loaded during requests, so you should only use this in production after finalizing your configuration.

To clear the configuration cache, use:

```bash
php artisan config:clear
```

## Customizing the AppServiceProvider

The `AppServiceProvider` is a central place to configure various aspects of your Laravel application. It's loaded early in the application lifecycle, making it an ideal place to set up global configurations.

Let's customize our `AppServiceProvider` to implement best practices and configure various Laravel features. Open the file at `app/Providers/AppServiceProvider.php` and update it with the following content:

```php
<?php

declare(strict_types=1);

namespace App\Providers;

use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Date;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\Facades\Vite;
use Illuminate\Support\Number;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        /*Gate::before(function (User $user, string $ability) {
            return $user->id === 1;});*/

        Number::useLocale('en');
        URL::defaults(['domain' => '']);
        if (! $this->app->isLocal()) {
            URL::forceScheme('https');
        }

        Model::unguard();

        /**
         * Force correct Typesense API key very early
         */
        // config(['scout.typesense.client-settings.api_key' => 'LARAVEL_HERD']);

        $this->configureCarbon();
        $this->configureCommands();
        $this->configureDatabase();
        $this->configureModels();
        $this->configureUrl();
        $this->configureVite();
    }

    /**
     * Configure the application's carbon.
     */
    private function configureCarbon(): void
    {
        Date::use(CarbonImmutable::class);
    }

    /**
     * Configure the application's commands.
     */
    private function configureCommands(): void
    {
        Artisan::command('inspire', function (): void {
            $this->comment(Inspiring::quote());
        })->purpose('Display an inspiring quote');
    }

    /**
     * Configure the application's database.
     */
    private function configureDatabase(): void
    {
        DB::prohibitDestructiveCommands(
            $this->app->isProduction()
            && ! $this->app->runningInConsole()
            && ! $this->app->runningUnitTests()
            && ! $this->app->isDownForMaintenance(),
        );
    }

    /**
     * Configure the application's models.
     */
    private function configureModels(): void
    {
        Model::automaticallyEagerLoadRelationships();
        Model::preventAccessingMissingAttributes(! $this->app->isProduction());
        Model::preventLazyLoading(! $this->app->isProduction());
        Model::preventSilentlyDiscardingAttributes(! $this->app->isProduction());
        Model::shouldBeStrict(! $this->app->isProduction());
        Model::unguard(! $this->app->isProduction());
    }

    /**
     * Configure the application's url.
     */
    private function configureUrl(): void
    {

        URL::forceScheme('https');
    }

    /**
     * Configure the application's vite.
     */
    private function configureVite(): void
    {

        Vite::useBuildDirectory('build')
            ->withEntryPoints([
                'resources/js/app.js',
            ]);
    }
}
```

### What This Does

This customized `AppServiceProvider` implements several best practices and configurations:

1. **Strict Types**: Uses `declare(strict_types=1)` to enforce strict type checking.

2. **Locale Configuration**: Sets the default locale for number formatting with `Number::useLocale('en')`.

3. **URL Configuration**:
   - Sets default URL parameters
   - Forces HTTPS in non-local environments

4. **Model Configuration**: Implements several Eloquent model safeguards in non-production environments:
   - `automaticallyEagerLoadRelationships()`: Automatically loads relationships defined in the `$with` property
   - `preventAccessingMissingAttributes()`: Throws exceptions when accessing undefined attributes
   - `preventLazyLoading()`: Prevents N+1 query problems by throwing exceptions on lazy loading
   - `preventSilentlyDiscardingAttributes()`: Throws exceptions when mass assignment silently discards attributes
   - `shouldBeStrict()`: Enables all strict mode features
   - `unguard()`: Disables mass assignment protection in development for easier testing

5. **Carbon Configuration**: Uses `CarbonImmutable` for dates to prevent unexpected side effects.

6. **Database Safety**: Prohibits destructive database commands in production environments.

7. **Vite Configuration**: Sets up the Vite asset bundling with the correct entry points.

8. **Modular Organization**: Breaks down configuration into separate methods for better organization and readability.

This approach to configuring your application provides several benefits:

- Centralizes configuration in one place
- Implements development safeguards that help catch issues early
- Applies different settings based on the environment
- Organizes code in a clean, modular way

## Next Steps

With our environment configured, we're ready to move on to [Installing FilamentPHP](./030-installing-filament.md) for our admin panel.
