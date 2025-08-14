# Configuring Laravel Pulse Access

<link rel="stylesheet" href="../../assets/css/styles.css">

[Laravel Pulse](https://pulse.laravel.com/) provides real-time application performance monitoring and metrics. In this step, we'll configure access to the Pulse dashboard to ensure that only authorized users can view it.

## Why Restrict Pulse Access?

Laravel Pulse provides valuable insights into your application's performance, but it also contains sensitive information that should not be accessible to all users. By restricting access to the Pulse dashboard, we can ensure that only authorized users (like administrators) can view this information.

## Understanding Pulse Authorization

Laravel Pulse uses Laravel's authorization system to determine who can access the dashboard. By default, Pulse allows access to all users in the local environment and no users in other environments.

We'll modify this behavior to allow access only to users with specific roles or permissions, regardless of the environment.

## Setting Up Pulse Authorization

To configure who can access the Pulse dashboard, we need to define the `viewPulse` authorization gate. We'll do this in our application's `app/Providers/AppServiceProvider.php` file:

```php
<?php

namespace App\Providers;

use App\Models\User;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Define who can access the Pulse dashboard
        Gate::define('viewPulse', function (User $user) {
            // For development, allow all users
            if (app()->environment('local')) {
                return true;
            }

            // For production, restrict access
            return $user->hasRole('admin');
        });
    }
}
```

## Creating the Admin Role

Since we're restricting Pulse access to users with the 'admin' role, we need to create this role and assign it to our admin user. Let's create a command to do this:

```bash
php artisan make:command CreateAdminRole
```

Open the newly created command file at `app/Console/Commands/CreateAdminRole.php` and update it with the following content:

```php
<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Spatie\Permission\Models\Role;

class CreateAdminRole extends Command
{
    protected $signature = 'make:admin-role {email}';
    protected $description = 'Create the admin role and assign it to a user';

    public function handle()
    {
        // Create the admin role if it doesn't exist
        $role = Role::firstOrCreate(['name' => 'admin']);

        // Find the user by email
        $user = User::where('email', $this->argument('email'))->first();

        if (!$user) {
            $this->error("User with email {$this->argument('email')} not found.");
            return Command::FAILURE;
        }

        // Assign the admin role to the user
        $user->assignRole('admin');

        $this->info("Admin role assigned to user: {$user->email}");

        return Command::SUCCESS;
    }
}
```

Now, let's create the admin role and assign it to our admin user:

```bash
php artisan make:admin-role admin@example.com
```

## Customizing the Pulse Dashboard

You can customize the Pulse dashboard by publishing the dashboard view:

```bash
php artisan vendor:publish --tag=pulse-dashboard
```

This will create a file at `resources/views/vendor/pulse/dashboard.blade.php` that you can modify to change the layout and cards displayed on the dashboard.

## Configuring Pulse Recorders

Pulse uses recorders to capture data from your application. You can configure these recorders in the `config/pulse.php` file. Let's publish the configuration file:

```bash
php artisan vendor:publish --tag=pulse-config
```

Now, let's customize the recorders to suit our needs. Open `config/pulse.php` and update the following values:

```php
'recorders' => [
    // User Requests Recorder
    \Laravel\Pulse\Recorders\UserRequests::class => [
        'enabled' => true,
        'sample_rate' => 1,
        'ignore' => [
            '#^/pulse$#',
            '#^/pulse/.*$#',
        ],
    ],

    // Slow Requests Recorder
    \Laravel\Pulse\Recorders\SlowRequests::class => [
        'enabled' => true,
        'threshold' => env('PULSE_SLOW_REQUESTS_THRESHOLD', 1000),
        'ignore' => [
            '#^/pulse$#',
            '#^/pulse/.*$#',
        ],
    ],

    // Exceptions Recorder
    \Laravel\Pulse\Recorders\Exceptions::class => [
        'enabled' => true,
        'sample_rate' => 1,
        'location' => true,
        'ignore' => [
            // Ignore validation exceptions
            '\\Illuminate\\Validation\\ValidationException',
        ],
    ],

    // Queues Recorder
    \Laravel\Pulse\Recorders\Queues::class => [
        'enabled' => true,
        'sample_rate' => 1,
    ],

    // Slow Jobs Recorder
    \Laravel\Pulse\Recorders\SlowJobs::class => [
        'enabled' => true,
        'threshold' => env('PULSE_SLOW_JOBS_THRESHOLD', 1000),
    ],

    // User Jobs Recorder
    \Laravel\Pulse\Recorders\UserJobs::class => [
        'enabled' => true,
        'sample_rate' => 1,
    ],

    // Slow Queries Recorder
    \Laravel\Pulse\Recorders\SlowQueries::class => [
        'enabled' => true,
        'threshold' => env('PULSE_SLOW_QUERIES_THRESHOLD', 1000),
        'sample_rate' => 1,
        'location' => true,
    ],

    // Slow Outgoing Requests Recorder
    \Laravel\Pulse\Recorders\SlowOutgoingRequests::class => [
        'enabled' => true,
        'threshold' => env('PULSE_SLOW_OUTGOING_REQUESTS_THRESHOLD', 1000),
        'sample_rate' => 1,
    ],

    // Cache Interactions Recorder
    \Laravel\Pulse\Recorders\CacheInteractions::class => [
        'enabled' => true,
        'sample_rate' => 1,
    ],

    // Servers Recorder
    \Laravel\Pulse\Recorders\Servers::class => [
        'enabled' => true,
        'sample_rate' => 1,
        'directories' => [
            base_path(),
            storage_path(),
        ],
    ],
],
```

## Running the Pulse Server Monitor

To capture server metrics like CPU, memory, and disk usage, you need to run the `pulse:check` command:

```bash
php artisan pulse:check
```

In a production environment, you should use a process monitor like Supervisor to keep this command running. During deployment, you should restart the command using:

```bash
php artisan pulse:restart
```

## Performance Considerations

For high-traffic applications, you might want to consider the following performance optimizations:

1. **Using a Different Database**: You can set the `PULSE_DB_CONNECTION` environment variable to use a dedicated database connection for Pulse.

2. **Redis Ingest**: For high-traffic applications, you can use Redis to buffer Pulse entries by setting `PULSE_INGEST_DRIVER=redis` in your `.env` file. You'll also need to run the `pulse:work` command to process the entries.

3. **Sampling**: You can reduce the amount of data captured by setting the `sample_rate` to a value less than 1 for high-volume recorders.

## Testing Pulse Access

Now, let's test Pulse access by visiting `/pulse` in your browser. You should be able to access the Pulse dashboard when logged in as the admin user, but not as a regular user in production environments.

## Next Steps

With Laravel Pulse configured and access restricted to admin users, we're ready to move on to [Installing Flux UI Components](./080-installing-flux-ui.md) for our UME project.
