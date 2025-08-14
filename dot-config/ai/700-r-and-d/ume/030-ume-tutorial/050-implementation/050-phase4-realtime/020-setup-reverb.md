# Setting Up Laravel Reverb

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Set up Laravel Reverb, the first-party WebSocket server for Laravel, to enable real-time communication in our application.

## Prerequisites

- Laravel 12 application
- PHP 8.4
- Composer
- Basic understanding of WebSockets (covered in the previous section)

## Implementation

### Step 1: Install Laravel Reverb

In Laravel 12, we can install Laravel Reverb using the dedicated Artisan command:

```bash
php artisan install:broadcasting
```

This command will install Reverb, publish the configuration, add required environment variables, and enable event broadcasting in your application.

### Step 2: Review the Configuration

This will create a `config/reverb.php` file with default settings.

### Step 3: Configure Environment Variables

Update your `.env` file with the necessary Reverb configuration:

```env
# Broadcasting Configuration
BROADCAST_DRIVER=reverb
BROADCAST_CONNECTION=reverb

# Reverb Configuration
REVERB_APP_ID=ume-app
REVERB_APP_KEY=your-app-key
REVERB_APP_SECRET=your-app-secret
REVERB_HOST=localhost
REVERB_PORT=8080
REVERB_SCHEME=http
```

Generate random values for `REVERB_APP_KEY` and `REVERB_APP_SECRET` using:

```bash
php artisan reverb:key
```

### Step 4: Configure Frontend Environment Variables

Add the Reverb configuration to your frontend environment variables in `.env`:

```env
VITE_REVERB_APP_KEY="${REVERB_APP_KEY}"
VITE_REVERB_HOST="${REVERB_HOST}"
VITE_REVERB_PORT="${REVERB_PORT}"
VITE_REVERB_SCHEME="${REVERB_SCHEME}"
```

### Step 5: Update the Broadcasting Configuration

Ensure your `config/broadcasting.php` file is properly configured for Reverb:

```php
'reverb' => [
    'driver' => 'reverb',
    'connection' => env('BROADCAST_CONNECTION', 'reverb'),
    'app_id' => env('REVERB_APP_ID'),
    'app_key' => env('REVERB_APP_KEY'),
    'app_secret' => env('REVERB_APP_SECRET'),
    'host' => env('REVERB_HOST', 'localhost'),
    'port' => env('REVERB_PORT', 8080),
    'scheme' => env('REVERB_SCHEME', 'http'),
    'options' => [
        'cluster' => env('REVERB_CLUSTER', 'mt1'),
        'encrypted' => true,
        'host' => env('REVERB_HOST', 'localhost'),
        'port' => env('REVERB_PORT', 8080),
        'scheme' => env('REVERB_SCHEME', 'http'),
    ],
],
```

### Step 6: Enable the BroadcastServiceProvider

Uncomment the `App\Providers\BroadcastServiceProvider::class` line in your `config/app.php` file:

```php
/*
 * Application Service Providers...
 */
App\Providers\AppServiceProvider::class,
App\Providers\AuthServiceProvider::class,
App\Providers\BroadcastServiceProvider::class, // Uncomment this line
App\Providers\EventServiceProvider::class,
App\Providers\RouteServiceProvider::class,
```

### Step 7: Configure the BroadcastServiceProvider

Ensure your `app/Providers/BroadcastServiceProvider.php` file is properly configured:

```php
<?php

namespace App\Providers;

use Illuminate\Support\Facades\Broadcast;
use Illuminate\Support\ServiceProvider;

class BroadcastServiceProvider extends ServiceProvider
{
    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Broadcast::routes(['middleware' => ['web', 'auth']]);

        require base_path('routes/channels.php');
    }
}
```

### Step 8: Create a Basic Channel Definition

Update your `routes/channels.php` file with a basic channel definition:

```php
<?php

use Illuminate\Support\Facades\Broadcast;

/*
|--------------------------------------------------------------------------
| Broadcast Channels
|--------------------------------------------------------------------------
|
| Here you may register all of the event broadcasting channels that your
| application supports. The given channel authorization callbacks are
| used to check if an authenticated user can listen to the channel.
|
*/

// Basic user private channel
Broadcast::channel('user.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});
```

### Step 9: Start the Reverb Server

Start the Reverb server using the Artisan command:

```bash
php artisan reverb:start
```

This will start the Reverb server on the configured host and port.

For development, you can run it in a separate terminal window. For production, you should use a process manager like Supervisor to keep it running.

## Understanding the Configuration

Let's break down the key configuration options:

### Reverb App ID, Key, and Secret

- **App ID**: A unique identifier for your application
- **App Key**: Used by clients to connect to the server
- **App Secret**: Used to sign authentication tokens

### Host, Port, and Scheme

- **Host**: The hostname where Reverb is running (usually `localhost` for development)
- **Port**: The port Reverb listens on (default: `8080`)
- **Scheme**: The protocol (`http` or `https`)

### Broadcasting Driver and Connection

- **BROADCAST_DRIVER**: Set to `reverb` to use Laravel Reverb
- **BROADCAST_CONNECTION**: The connection name in your broadcasting config

## Scaling Reverb

For production environments, you can scale Reverb horizontally using Redis:

1. Install the Redis PHP extension and predis/predis package
2. Configure Reverb to use Redis for scaling:

```php
// In config/reverb.php
'scaling' => [
    'driver' => 'redis',
    'connection' => env('REVERB_REDIS_CONNECTION', 'default'),
],
```

This allows you to run multiple Reverb instances behind a load balancer.

## Verification

To verify that Reverb is running correctly:

1. Start the Reverb server: `php artisan reverb:start`
2. Check the output for any errors
3. Open a browser and navigate to `http://localhost:8080/reverb/health` (adjust host/port as needed)
4. You should see a JSON response indicating that the server is healthy

## Troubleshooting

### Common Issues

1. **Connection Refused**: Make sure the Reverb server is running and the port is not blocked by a firewall
2. **Authentication Errors**: Check that your app key and secret are correctly configured
3. **CORS Issues**: If you're accessing from a different domain, configure CORS in your `config/reverb.php` file

### Debugging

Enable debug mode in your `config/reverb.php` file:

```php
'debug' => env('REVERB_DEBUG', true),
```

This will output more detailed logs when issues occur.

## Next Steps

Now that we have Reverb set up, let's configure Laravel Echo to connect to it from the frontend.

[Configure Laravel Echo →](./030-configure-echo.md)
