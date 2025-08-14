# Phase 6: Polishing & Deployment Troubleshooting

<link rel="stylesheet" href="../assets/css/styles.css">
<link rel="stylesheet" href="../assets/css/ume-docs-enhancements.css">
<script src="../assets/js/ume-docs-enhancements.js"></script>

This guide addresses common issues you might encounter during Phase 6 (Polishing & Deployment) of the UME tutorial implementation.

## Internationalization Issues

<div class="troubleshooting-guide">
    <h2>Internationalization (i18n) Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Translations not working</li>
            <li>Missing translation strings</li>
            <li>Incorrect language being displayed</li>
            <li>Locale switching not working</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Missing or incorrect translation files</li>
            <li>Locale not being set correctly</li>
            <li>Missing translation strings</li>
            <li>Incorrect usage of translation functions</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Translation Files</h4>
        <p>Ensure your translation files are correctly structured:</p>
        <pre><code>// resources/lang/en/messages.php
return [
    'welcome' => 'Welcome to our application',
    'login' => 'Login',
    'register' => 'Register',
    'logout' => 'Logout',
    'profile' => 'Profile',
    'settings' => 'Settings',
    'dashboard' => 'Dashboard',
];

// resources/lang/es/messages.php
return [
    'welcome' => 'Bienvenido a nuestra aplicación',
    'login' => 'Iniciar sesión',
    'register' => 'Registrarse',
    'logout' => 'Cerrar sesión',
    'profile' => 'Perfil',
    'settings' => 'Configuración',
    'dashboard' => 'Panel de control',
];</code></pre>
        
        <h4>For Locale Setting</h4>
        <p>Ensure the locale is being set correctly:</p>
        <pre><code>// In a middleware
public function handle(Request $request, Closure $next)
{
    // Set locale from session, user preference, or browser
    $locale = session('locale', config('app.locale'));
    app()->setLocale($locale);
    
    return $next($request);
}

// Register the middleware in Kernel.php
protected $middlewareGroups = [
    'web' => [
        // Other middleware...
        \App\Http\Middleware\SetLocale::class,
    ],
];</code></pre>
        
        <h4>For Missing Translation Strings</h4>
        <p>Check for missing translation strings and add them:</p>
        <pre><code>// Check if a translation exists
if (Lang::has('messages.welcome')) {
    // Translation exists
}

// Add missing translations
// resources/lang/en/messages.php
return [
    // Existing translations...
    'missing_string' => 'This string was missing',
];</code></pre>
        
        <h4>For Incorrect Usage</h4>
        <p>Ensure you're using the translation functions correctly:</p>
        <pre><code>// In Blade templates
{{ __('messages.welcome') }}
@lang('messages.login')

// In PHP code
$message = __('messages.welcome');
$message = trans('messages.login');
$message = Lang::get('messages.register');</code></pre>
        <p>For pluralization:</p>
        <pre><code>// In translation file
'apples' => '{0} No apples|{1} One apple|[2,*] :count apples',

// In code
echo trans_choice('messages.apples', 0); // No apples
echo trans_choice('messages.apples', 1); // One apple
echo trans_choice('messages.apples', 10); // 10 apples</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Create translation files for all supported languages</li>
            <li>Use a middleware to set the locale</li>
            <li>Extract all user-facing strings into translation files</li>
            <li>Use the correct translation functions based on your needs</li>
        </ul>
    </div>
</div>

## Feature Flag Issues

<div class="troubleshooting-guide">
    <h2>Feature Flag Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Feature flags not working</li>
            <li>Features always enabled or disabled</li>
            <li>Unable to toggle features</li>
            <li>Feature state not persisting</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Pennant not properly installed or configured</li>
            <li>Missing or incorrect feature definitions</li>
            <li>Feature state not being stored correctly</li>
            <li>Incorrect usage of feature flag checks</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Pennant Installation</h4>
        <p>Ensure Pennant is properly installed and configured:</p>
        <pre><code>composer require laravel/pennant
php artisan vendor:publish --provider="Laravel\Pennant\PennantServiceProvider"
php artisan migrate</code></pre>
        
        <h4>For Feature Definitions</h4>
        <p>Define your features in a service provider:</p>
        <pre><code>// In a service provider
public function boot(): void
{
    Features::define('new-dashboard', function () {
        return true; // Always enabled
    });
    
    Features::define('beta-feature', function (User $user) {
        return $user->isBetaTester();
    });
    
    Features::define('premium-feature', function (User $user) {
        return $user->subscription?->active;
    });
}</code></pre>
        
        <h4>For Feature State Storage</h4>
        <p>Configure the feature state storage:</p>
        <pre><code>// config/pennant.php
'stores' => [
    'database' => [
        'driver' => 'database',
        'connection' => env('DB_CONNECTION', 'mysql'),
        'table' => 'features',
    ],
    
    'redis' => [
        'driver' => 'redis',
        'connection' => env('REDIS_CONNECTION', 'default'),
        'prefix' => 'pennant:',
    ],
    
    'array' => [
        'driver' => 'array',
    ],
],

'default' => env('PENNANT_STORE', 'database'),</code></pre>
        
        <h4>For Feature Flag Checks</h4>
        <p>Ensure you're checking feature flags correctly:</p>
        <pre><code>// In Blade templates
@feature('new-dashboard')
    &lt;div&gt;New Dashboard&lt;/div&gt;
@else
    &lt;div&gt;Old Dashboard&lt;/div&gt;
@endfeature

// In PHP code
if (Features::for($user)->active('premium-feature')) {
    // Premium feature is active for this user
}

// In routes
Route::middleware(['features:new-dashboard'])->group(function () {
    // Routes that require the new-dashboard feature
});</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Define all feature flags in a service provider</li>
            <li>Use a persistent store for feature flags in production</li>
            <li>Test feature flags with different user scenarios</li>
            <li>Document all feature flags and their purpose</li>
        </ul>
    </div>
</div>

## Testing Issues

<div class="troubleshooting-guide">
    <h2>Testing Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Tests failing unexpectedly</li>
            <li>Database issues during tests</li>
            <li>Authentication issues in tests</li>
            <li>Mocking issues with dependencies</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Incorrect test database configuration</li>
            <li>Missing or incorrect test setup</li>
            <li>Authentication issues in tests</li>
            <li>Improper mocking of dependencies</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Test Database Configuration</h4>
        <p>Configure your test database correctly:</p>
        <pre><code>// phpunit.xml
&lt;php&gt;
    &lt;env name="APP_ENV" value="testing"/&gt;
    &lt;env name="BCRYPT_ROUNDS" value="4"/&gt;
    &lt;env name="CACHE_DRIVER" value="array"/&gt;
    &lt;env name="DB_CONNECTION" value="sqlite"/&gt;
    &lt;env name="DB_DATABASE" value=":memory:"/&gt;
    &lt;env name="MAIL_MAILER" value="array"/&gt;
    &lt;env name="QUEUE_CONNECTION" value="sync"/&gt;
    &lt;env name="SESSION_DRIVER" value="array"/&gt;
    &lt;env name="TELESCOPE_ENABLED" value="false"/&gt;
&lt;/php&gt;</code></pre>
        
        <h4>For Test Setup</h4>
        <p>Ensure your tests are set up correctly:</p>
        <pre><code>// Using Pest
use App\Models\User;
use function Pest\Laravel\actingAs;

beforeEach(function () {
    // Run migrations before each test
    $this->artisan('migrate:fresh');
});

test('user can view their profile', function () {
    // Arrange
    $user = User::factory()->create();
    
    // Act
    actingAs($user)
        ->get('/profile')
        
    // Assert
        ->assertStatus(200)
        ->assertSee($user->name);
});</code></pre>
        
        <h4>For Authentication Issues</h4>
        <p>Handle authentication in tests:</p>
        <pre><code>// Using Pest
test('user can update their profile', function () {
    // Arrange
    $user = User::factory()->create();
    
    // Act
    actingAs($user)
        ->put('/profile', [
            'name' => 'New Name',
            'email' => 'new@example.com',
        ])
        
    // Assert
        ->assertRedirect('/profile')
        ->assertSessionHas('status', 'Profile updated successfully.');
    
    $this->assertDatabaseHas('users', [
        'id' => $user->id,
        'name' => 'New Name',
        'email' => 'new@example.com',
    ]);
});</code></pre>
        
        <h4>For Mocking Dependencies</h4>
        <p>Mock dependencies correctly:</p>
        <pre><code>// Using Pest
test('notification is sent when user is created', function () {
    // Arrange
    Notification::fake();
    
    // Act
    $user = User::factory()->create();
    
    // Assert
    Notification::assertSentTo(
        $user,
        \App\Notifications\WelcomeNotification::class
    );
});</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Use an in-memory SQLite database for tests</li>
            <li>Reset the database state before each test</li>
            <li>Use factories to create test data</li>
            <li>Mock external dependencies</li>
        </ul>
    </div>
</div>

## Performance Optimization Issues

<div class="troubleshooting-guide">
    <h2>Performance Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Slow page loads</li>
            <li>High database query counts</li>
            <li>Memory usage issues</li>
            <li>Slow API responses</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>N+1 query problems</li>
            <li>Missing database indexes</li>
            <li>Inefficient queries</li>
            <li>Missing caching</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For N+1 Query Problems</h4>
        <p>Use eager loading to solve N+1 query problems:</p>
        <pre><code>// Instead of this (causes N+1 queries)
$users = User::all();
foreach ($users as $user) {
    echo $user->team->name;
}

// Do this (single query with eager loading)
$users = User::with('team')->get();
foreach ($users as $user) {
    echo $user->team->name;
}</code></pre>
        
        <h4>For Missing Indexes</h4>
        <p>Add indexes to frequently queried columns:</p>
        <pre><code>Schema::table('users', function (Blueprint $table) {
    $table->index('email');
    $table->index('type');
    $table->index('team_id');
});</code></pre>
        
        <h4>For Inefficient Queries</h4>
        <p>Optimize your queries:</p>
        <pre><code>// Instead of this
$users = User::where('type', 'admin')
    ->orderBy('created_at', 'desc')
    ->get();

// Do this (more efficient)
$users = User::where('type', 'admin')
    ->latest()
    ->get();

// Use query builders for complex queries
$users = User::query()
    ->when($request->has('search'), function ($query) use ($request) {
        $query->where('name', 'like', "%{$request->search}%");
    })
    ->when($request->has('type'), function ($query) use ($request) {
        $query->where('type', $request->type);
    })
    ->paginate(20);</code></pre>
        
        <h4>For Missing Caching</h4>
        <p>Implement caching for expensive operations:</p>
        <pre><code>// Cache the result of an expensive query
$users = Cache::remember('users.all', 3600, function () {
    return User::with('team')->get();
});

// Cache the result of an expensive computation
$stats = Cache::remember('user.stats', 3600, function () use ($user) {
    return [
        'total_logins' => $user->logins()->count(),
        'last_login' => $user->logins()->latest()->first()?->created_at,
        'total_actions' => $user->actions()->count(),
    ];
});</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Use eager loading to prevent N+1 queries</li>
            <li>Add indexes to frequently queried columns</li>
            <li>Use query builders for complex queries</li>
            <li>Implement caching for expensive operations</li>
        </ul>
    </div>
</div>

## Deployment Issues

<div class="troubleshooting-guide">
    <h2>Deployment Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Application not working in production</li>
            <li>Missing assets or styles</li>
            <li>Database migration failures</li>
            <li>Permission issues in production</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Incorrect environment configuration</li>
            <li>Missing or incorrect build steps</li>
            <li>Database migration issues</li>
            <li>File permission problems</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Environment Configuration</h4>
        <p>Ensure your production environment is correctly configured:</p>
        <pre><code>// .env.example (template for production)
APP_NAME=UME
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=https://your-production-url.com

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=warning

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=ume_production
DB_USERNAME=ume_user
DB_PASSWORD=secure_password

BROADCAST_DRIVER=reverb
CACHE_DRIVER=redis
FILESYSTEM_DISK=local
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis
SESSION_LIFETIME=120

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=mailhog
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="${APP_NAME}"

REVERB_APP_ID=your-app-id
REVERB_APP_KEY=your-app-key
REVERB_APP_SECRET=your-app-secret
REVERB_HOST=127.0.0.1
REVERB_PORT=8080
REVERB_SCHEME=https</code></pre>
        
        <h4>For Build Steps</h4>
        <p>Ensure your build steps are correctly defined:</p>
        <pre><code>// package.json
"scripts": {
    "dev": "vite",
    "build": "vite build"
}

// Deployment script
#!/bin/bash
set -e

# Pull the latest changes
git pull origin main

# Install dependencies
composer install --no-dev --optimize-autoloader
npm ci
npm run build

# Clear caches
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear

# Run migrations
php artisan migrate --force

# Restart services
sudo supervisorctl restart all
sudo systemctl reload nginx</code></pre>
        
        <h4>For Database Migration Issues</h4>
        <p>Handle database migrations carefully:</p>
        <pre><code>// Use --force to run migrations in production
php artisan migrate --force

// For risky migrations, use a transaction
Schema::connection('mysql')->transaction(function () {
    // Your migration code here
});

// For large tables, consider using a chunked approach
User::chunk(1000, function ($users) {
    foreach ($users as $user) {
        // Update each user
    }
});</code></pre>
        
        <h4>For File Permission Issues</h4>
        <p>Set the correct file permissions:</p>
        <pre><code># Set ownership
sudo chown -R www-data:www-data /path/to/your/laravel/app

# Set directory permissions
sudo find /path/to/your/laravel/app -type d -exec chmod 755 {} \;

# Set file permissions
sudo find /path/to/your/laravel/app -type f -exec chmod 644 {} \;

# Set storage and bootstrap/cache permissions
sudo chmod -R 775 /path/to/your/laravel/app/storage
sudo chmod -R 775 /path/to/your/laravel/app/bootstrap/cache</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Use a deployment checklist</li>
            <li>Test your deployment process in a staging environment</li>
            <li>Use environment-specific configuration</li>
            <li>Automate your deployment process</li>
        </ul>
    </div>
</div>

## Common Pitfalls in Phase 6

<div class="common-pitfalls">
    <h3>Common Pitfalls to Avoid</h3>
    <ul>
        <li><strong>Not testing in a production-like environment:</strong> Always test your application in an environment that closely resembles production before deploying.</li>
        <li><strong>Forgetting to optimize for production:</strong> Use composer's optimize-autoloader option, compile assets, and cache routes and config in production.</li>
        <li><strong>Not handling database migrations carefully:</strong> Database migrations can be risky in production. Use transactions and consider the impact on large tables.</li>
        <li><strong>Ignoring performance issues:</strong> Performance issues that are tolerable in development can become critical in production. Address them before deploying.</li>
        <li><strong>Not setting up proper monitoring:</strong> Set up monitoring for your application to detect issues before they become critical.</li>
        <li><strong>Forgetting to back up data:</strong> Always back up your database before deploying major changes.</li>
        <li><strong>Not having a rollback plan:</strong> Have a plan for rolling back changes if something goes wrong during deployment.</li>
        <li><strong>Deploying during peak hours:</strong> Avoid deploying during peak hours to minimize the impact of potential issues.</li>
    </ul>
</div>

## Debugging Techniques for Phase 6

### Debugging Internationalization

Test translations with different locales:

```php
// Test a specific translation
app()->setLocale('en');
echo __('messages.custom'); // Should output "Welcome to our application"

app()->setLocale('es');
echo __('messages.custom'); // Should output "Bienvenido a nuestra aplicación"

// Check if a translation exists
if (Lang::has('messages.custom')) {
    // Translation exists
}
```

### Testing Feature Flags

Test feature flags with different scenarios:

```php
// Test a feature flag
Features::activate('new-dashboard');
$this->assertTrue(Features::active('new-dashboard'));

Features::deactivate('new-dashboard');
$this->assertFalse(Features::active('new-dashboard'));

// Test a feature flag for a specific user
Features::for($user)->activate('premium-feature');
$this->assertTrue(Features::for($user)->active('premium-feature'));
```

### Analyzing Database Performance

Use Laravel Telescope to analyze database queries:

```php
// Install Laravel Telescope
composer require laravel/telescope --dev
php artisan telescope:install
php artisan migrate

// Access Telescope at /telescope/queries
```

Or use the DB facade to log queries:

```php
DB::listen(function ($query) {
    Log::info($query->sql, $query->bindings);
});
```

### Testing Deployment

Create a deployment checklist:

1. Run tests: `php artisan test`
2. Check for database migrations: `php artisan migrate:status`
3. Compile assets: `npm run build`
4. Check for environment variables: `php artisan config:check`
5. Optimize autoloader: `composer install --optimize-autoloader --no-dev`
6. Cache configuration: `php artisan config:cache`
7. Cache routes: `php artisan route:cache`
8. Check file permissions
9. Test in a staging environment
10. Back up the database

<div class="page-navigation">
    <a href="./060-phase5-advanced-troubleshooting.md" class="prev">Phase 5 Troubleshooting</a>
    <a href="./080-general-faq.md" class="next">General FAQ</a>
</div>
