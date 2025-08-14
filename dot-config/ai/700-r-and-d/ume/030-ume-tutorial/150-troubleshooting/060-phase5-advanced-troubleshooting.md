# Phase 5: Advanced Features Troubleshooting

<link rel="stylesheet" href="../assets/css/styles.css">
<link rel="stylesheet" href="../assets/css/ume-docs-enhancements.css">
<script src="../assets/js/ume-docs-enhancements.js"></script>

This guide addresses common issues you might encounter during Phase 5 (Advanced Features) of the UME tutorial implementation.

## Impersonation Feature Issues

<div class="troubleshooting-guide">
    <h2>User Impersonation Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Unable to impersonate users</li>
            <li>Session issues during impersonation</li>
            <li>Unable to stop impersonation</li>
            <li>Permission errors when trying to impersonate</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Missing or incorrect impersonation implementation</li>
            <li>Session configuration issues</li>
            <li>Missing or incorrect authorization checks</li>
            <li>Middleware conflicts</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Impersonation Implementation</h4>
        <p>Ensure your impersonation service is correctly implemented:</p>
        <pre><code>class ImpersonationService
{
    public function start(User $impersonator, User $impersonated): void
    {
        // Store the impersonator's ID in the session
        session(['impersonator_id' => $impersonator->id]);
        
        // Login as the impersonated user
        Auth::login($impersonated);
        
        // Log the impersonation
        activity()
            ->causedBy($impersonator)
            ->performedOn($impersonated)
            ->log('impersonated');
    }
    
    public function stop(): void
    {
        // Get the impersonator
        $impersonator = User::find(session('impersonator_id'));
        
        if (!$impersonator) {
            throw new \Exception('Impersonator not found');
        }
        
        // Get the impersonated user
        $impersonated = Auth::user();
        
        // Login as the impersonator
        Auth::login($impersonator);
        
        // Remove the impersonator ID from the session
        session()->forget('impersonator_id');
        
        // Log the end of impersonation
        activity()
            ->causedBy($impersonator)
            ->performedOn($impersonated)
            ->log('stopped impersonation');
    }
    
    public function isImpersonating(): bool
    {
        return session()->has('impersonator_id');
    }
    
    public function getImpersonator(): ?User
    {
        $impersonatorId = session('impersonator_id');
        
        if (!$impersonatorId) {
            return null;
        }
        
        return User::find($impersonatorId);
    }
}</code></pre>
        
        <h4>For Session Configuration</h4>
        <p>Ensure your session configuration is correct:</p>
        <pre><code>// config/session.php
'driver' => env('SESSION_DRIVER', 'file'),
'lifetime' => env('SESSION_LIFETIME', 120),
'expire_on_close' => false,
'encrypt' => false,
'files' => storage_path('framework/sessions'),
'connection' => env('SESSION_CONNECTION', null),
'table' => 'sessions',
'store' => env('SESSION_STORE', null),
'lottery' => [2, 100],
'cookie' => env(
    'SESSION_COOKIE',
    Str::slug(env('APP_NAME', 'laravel'), '_').'_session'
),
'path' => '/',
'domain' => env('SESSION_DOMAIN', null),
'secure' => env('SESSION_SECURE_COOKIE', false),
'http_only' => true,
'same_site' => 'lax',</code></pre>
        
        <h4>For Authorization Checks</h4>
        <p>Implement proper authorization checks:</p>
        <pre><code>// In a policy or middleware
public function impersonate(User $user, User $target): bool
{
    // Only admins can impersonate
    if (!$user instanceof Admin) {
        return false;
    }
    
    // Cannot impersonate yourself
    if ($user->id === $target->id) {
        return false;
    }
    
    // Admins cannot impersonate other admins
    if ($target instanceof Admin) {
        return false;
    }
    
    return true;
}</code></pre>
        
        <h4>For Middleware Conflicts</h4>
        <p>Create a middleware to handle impersonation:</p>
        <pre><code>class ImpersonationMiddleware
{
    public function handle(Request $request, Closure $next)
    {
        // Add impersonation data to views
        if (session()->has('impersonator_id')) {
            $impersonator = User::find(session('impersonator_id'));
            
            view()->share('is_impersonating', true);
            view()->share('impersonator', $impersonator);
        }
        
        return $next($request);
    }
}</code></pre>
        <p>Register the middleware in Kernel.php:</p>
        <pre><code>protected $middlewareGroups = [
    'web' => [
        // Other middleware...
        \App\Http\Middleware\ImpersonationMiddleware::class,
    ],
];</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Implement proper authorization checks for impersonation</li>
            <li>Use a service class to handle impersonation logic</li>
            <li>Log all impersonation actions for security</li>
            <li>Add a clear visual indicator when impersonating a user</li>
        </ul>
    </div>
</div>

## Comments Feature Issues

<div class="troubleshooting-guide">
    <h2>Comments Feature Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Unable to add comments to models</li>
            <li>Comments not displaying correctly</li>
            <li>Missing or incorrect comment relationships</li>
            <li>Performance issues with comments</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Missing or incorrect comments implementation</li>
            <li>Database issues with comments table</li>
            <li>Polymorphic relationship configuration issues</li>
            <li>Authorization issues for comments</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Comments Implementation</h4>
        <p>Ensure your Comment model is correctly implemented:</p>
        <pre><code>class Comment extends Model
{
    use HasUlid;
    use HasUserTracking;
    
    protected $fillable = [
        'content',
        'commentable_id',
        'commentable_type',
    ];
    
    public function commentable()
    {
        return $this->morphTo();
    }
    
    public function user()
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}</code></pre>
        <p>And your commentable models have the correct trait:</p>
        <pre><code>trait HasComments
{
    public function comments()
    {
        return $this->morphMany(Comment::class, 'commentable');
    }
    
    public function addComment(string $content, User $user = null): Comment
    {
        $user = $user ?? auth()->user();
        
        return $this->comments()->create([
            'content' => $content,
            'created_by' => $user?->id,
        ]);
    }
}</code></pre>
        
        <h4>For Database Issues</h4>
        <p>Ensure your comments table has the correct structure:</p>
        <pre><code>Schema::create('comments', function (Blueprint $table) {
    $table->id();
    $table->ulid('ulid')->unique();
    $table->text('content');
    $table->morphs('commentable');
    $table->foreignId('created_by')->nullable()->constrained('users');
    $table->foreignId('updated_by')->nullable()->constrained('users');
    $table->timestamps();
});</code></pre>
        
        <h4>For Polymorphic Relationship Issues</h4>
        <p>Check your model configuration for polymorphic relationships:</p>
        <pre><code>// In your model
use App\Traits\HasComments;

class Task extends Model
{
    use HasComments;
    
    // Rest of your model
}</code></pre>
        
        <h4>For Authorization Issues</h4>
        <p>Implement proper authorization for comments:</p>
        <pre><code>// In a policy
public function createComment(User $user, Model $model): bool
{
    // Check if the user can create comments on this model
    return true; // Customize based on your requirements
}

public function updateComment(User $user, Comment $comment): bool
{
    // Only the comment creator can update it
    return $user->id === $comment->created_by;
}

public function deleteComment(User $user, Comment $comment): bool
{
    // Only the comment creator or the model owner can delete it
    return $user->id === $comment->created_by || 
           $user->id === $comment->commentable->created_by;
}</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Use a trait to add comment functionality to models</li>
            <li>Implement proper authorization for comment actions</li>
            <li>Use eager loading to improve performance when fetching comments</li>
            <li>Consider pagination for models with many comments</li>
        </ul>
    </div>
</div>

## User Settings Feature Issues

<div class="troubleshooting-guide">
    <h2>User Settings Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>User settings not being saved</li>
            <li>Settings not being loaded correctly</li>
            <li>Default settings not being applied</li>
            <li>Type conversion issues with settings</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Missing or incorrect settings implementation</li>
            <li>Database issues with settings table</li>
            <li>JSON serialization issues</li>
            <li>Missing default settings</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Settings Implementation</h4>
        <p>Ensure your settings implementation is correct:</p>
        <pre><code>class UserSettings
{
    protected User $user;
    protected array $settings = [];
    protected array $defaults = [
        'notifications' => [
            'email' => true,
            'push' => true,
            'in_app' => true,
        ],
        'theme' => 'light',
        'language' => 'en',
        'timezone' => 'UTC',
    ];
    
    public function __construct(User $user)
    {
        $this->user = $user;
        $this->load();
    }
    
    public function load(): void
    {
        $settings = $this->user->settings ?? [];
        $this->settings = array_merge($this->defaults, $settings);
    }
    
    public function save(): void
    {
        $this->user->settings = $this->settings;
        $this->user->save();
    }
    
    public function get(string $key, $default = null)
    {
        return Arr::get($this->settings, $key, $default);
    }
    
    public function set(string $key, $value): void
    {
        Arr::set($this->settings, $key, $value);
    }
    
    public function has(string $key): bool
    {
        return Arr::has($this->settings, $key);
    }
    
    public function forget(string $key): void
    {
        Arr::forget($this->settings, $key);
    }
    
    public function all(): array
    {
        return $this->settings;
    }
    
    public function reset(): void
    {
        $this->settings = $this->defaults;
    }
}</code></pre>
        
        <h4>For Database Issues</h4>
        <p>Ensure your users table has a settings column:</p>
        <pre><code>Schema::table('users', function (Blueprint $table) {
    $table->json('settings')->nullable();
});</code></pre>
        <p>And that it's properly cast in your User model:</p>
        <pre><code>protected $casts = [
    'email_verified_at' => 'datetime',
    'password' => 'hashed',
    'settings' => 'array',
];</code></pre>
        
        <h4>For JSON Serialization Issues</h4>
        <p>Ensure your JSON serialization is working correctly:</p>
        <pre><code>// Test JSON serialization
$user = User::find(1);
$user->settings = ['theme' => 'dark'];
$user->save();

// Check if it was saved correctly
$user = User::find(1);
dd($user->settings); // Should output ['theme' => 'dark']</code></pre>
        
        <h4>For Default Settings</h4>
        <p>Ensure default settings are applied when creating a user:</p>
        <pre><code>// In your UserObserver or in a model event
public static function booted()
{
    static::creating(function ($user) {
        if (empty($user->settings)) {
            $user->settings = [
                'notifications' => [
                    'email' => true,
                    'push' => true,
                    'in_app' => true,
                ],
                'theme' => 'light',
                'language' => 'en',
                'timezone' => 'UTC',
            ];
        }
    });
}</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Use a dedicated class to manage user settings</li>
            <li>Define default settings for all users</li>
            <li>Use proper type casting for settings</li>
            <li>Validate settings before saving them</li>
        </ul>
    </div>
</div>

## Search Implementation Issues

<div class="troubleshooting-guide">
    <h2>Search Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Search not returning expected results</li>
            <li>Search indexing failing</li>
            <li>Performance issues with search</li>
            <li>Search not working with child models</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Scout not properly configured</li>
            <li>Missing or incorrect searchable configuration</li>
            <li>Index not updated after model changes</li>
            <li>Single Table Inheritance issues with search</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Scout Configuration</h4>
        <p>Ensure Scout is properly configured:</p>
        <pre><code>// config/scout.php
'driver' => env('SCOUT_DRIVER', 'typesense'),

'typesense' => [
    'api_key' => env('TYPESENSE_API_KEY'),
    'nodes' => [
        [
            'host' => env('TYPESENSE_HOST', 'localhost'),
            'port' => env('TYPESENSE_PORT', '8108'),
            'protocol' => env('TYPESENSE_PROTOCOL', 'http'),
        ],
    ],
    'connection_timeout_seconds' => env('TYPESENSE_CONNECTION_TIMEOUT_SECONDS', 2),
    'healthcheck_interval_seconds' => env('TYPESENSE_HEALTHCHECK_INTERVAL_SECONDS', 30),
    'num_retries' => env('TYPESENSE_NUM_RETRIES', 3),
    'retry_interval_seconds' => env('TYPESENSE_RETRY_INTERVAL_SECONDS', 1),
],</code></pre>
        
        <h4>For Searchable Configuration</h4>
        <p>Ensure your model is properly configured for search:</p>
        <pre><code>use Laravel\Scout\Searchable;

class User extends Authenticatable
{
    use Searchable;
    
    public function toSearchableArray(): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'first_name' => $this->first_name,
            'last_name' => $this->last_name,
            'email' => $this->email,
            'type' => $this->type,
            // Add other searchable fields
        ];
    }
    
    public function searchableAs(): string
    {
        return 'users';
    }
}</code></pre>
        
        <h4>For Index Updates</h4>
        <p>Ensure your index is updated after model changes:</p>
        <pre><code>// Import all models into the search index
php artisan scout:import "App\Models\User"

// Or update the index when a model changes
$user->save(); // This will automatically update the index if using Searchable trait</code></pre>
        
        <h4>For STI Issues</h4>
        <p>Handle Single Table Inheritance with search:</p>
        <pre><code>// In your base User model
public function searchableAs(): string
{
    return 'users';
}

// In your child models (if needed)
public function toSearchableArray(): array
{
    $array = parent::toSearchableArray();
    
    // Add child-specific fields
    $array['admin_code'] = $this->admin_code;
    
    return $array;
}</code></pre>
        <p>When searching, specify the model type:</p>
        <pre><code>// Search all users
$results = User::search($query)->get();

// Search only admins
$results = Admin::search($query)->get();</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Configure Scout properly for your search engine</li>
            <li>Define which fields should be searchable</li>
            <li>Update your search index when models change</li>
            <li>Test search with different queries and model types</li>
        </ul>
    </div>
</div>

## API Authentication Issues

<div class="troubleshooting-guide">
    <h2>API Authentication Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Unable to authenticate API requests</li>
            <li>Token generation failing</li>
            <li>Tokens not being recognized</li>
            <li>Permission issues with API endpoints</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Passport or Sanctum not properly configured</li>
            <li>Missing or incorrect API routes</li>
            <li>Token scopes or abilities not set correctly</li>
            <li>CORS issues with API requests</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Passport Configuration</h4>
        <p>Ensure Passport is properly installed and configured:</p>
        <pre><code>composer require laravel/passport
php artisan passport:install
php artisan passport:keys</code></pre>
        <p>Configure Passport in your AuthServiceProvider:</p>
        <pre><code>public function boot(): void
{
    $this->registerPolicies();
    
    Passport::routes();
    Passport::tokensExpireIn(now()->addDays(15));
    Passport::refreshTokensExpireIn(now()->addDays(30));
    Passport::personalAccessTokensExpireIn(now()->addMonths(6));
}</code></pre>
        <p>Update your config/auth.php file:</p>
        <pre><code>'guards' => [
    'web' => [
        'driver' => 'session',
        'provider' => 'users',
    ],
    
    'api' => [
        'driver' => 'passport',
        'provider' => 'users',
    ],
],</code></pre>
        
        <h4>For Sanctum Configuration</h4>
        <p>Ensure Sanctum is properly installed and configured:</p>
        <pre><code>composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
php artisan migrate</code></pre>
        <p>Update your User model:</p>
        <pre><code>use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens;
    
    // Rest of your model
}</code></pre>
        <p>Update your config/auth.php file:</p>
        <pre><code>'guards' => [
    'web' => [
        'driver' => 'session',
        'provider' => 'users',
    ],
    
    'api' => [
        'driver' => 'sanctum',
        'provider' => 'users',
        'hash' => false,
    ],
],</code></pre>
        
        <h4>For API Routes</h4>
        <p>Ensure your API routes are correctly defined:</p>
        <pre><code>// routes/api.php
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', function (Request $request) {
        return $request->user();
    });
    
    Route::apiResource('tasks', TaskController::class);
});</code></pre>
        
        <h4>For Token Scopes/Abilities</h4>
        <p>For Passport, define and check scopes:</p>
        <pre><code>// Define scopes
Passport::tokensCan([
    'read-tasks' => 'Read tasks',
    'create-tasks' => 'Create tasks',
    'update-tasks' => 'Update tasks',
    'delete-tasks' => 'Delete tasks',
]);

// Check scopes in routes
Route::middleware(['auth:api', 'scopes:read-tasks'])->get('/tasks', [TaskController::class, 'index']);
Route::middleware(['auth:api', 'scopes:create-tasks'])->post('/tasks', [TaskController::class, 'store']);</code></pre>
        <p>For Sanctum, define and check abilities:</p>
        <pre><code>// Create token with abilities
$token = $user->createToken('api-token', ['read', 'create'])->plainTextToken;

// Check abilities in routes
Route::middleware(['auth:sanctum', 'ability:read'])->get('/tasks', [TaskController::class, 'index']);
Route::middleware(['auth:sanctum', 'ability:create'])->post('/tasks', [TaskController::class, 'store']);</code></pre>
        
        <h4>For CORS Issues</h4>
        <p>Configure CORS in your config/cors.php file:</p>
        <pre><code>'paths' => ['api/*', 'sanctum/csrf-cookie'],
'allowed_methods' => ['*'],
'allowed_origins' => ['*'],
'allowed_origins_patterns' => [],
'allowed_headers' => ['*'],
'exposed_headers' => [],
'max_age' => 0,
'supports_credentials' => true,</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Choose the appropriate authentication guard for your API</li>
            <li>Define token scopes or abilities based on your API's needs</li>
            <li>Configure CORS properly for cross-origin requests</li>
            <li>Test API authentication with different clients</li>
        </ul>
    </div>
</div>

## Common Pitfalls in Phase 5

<div class="common-pitfalls">
    <h3>Common Pitfalls to Avoid</h3>
    <ul>
        <li><strong>Not securing impersonation:</strong> Impersonation is a powerful feature that can be abused. Ensure only authorized users can impersonate others, and log all impersonation actions.</li>
        <li><strong>Forgetting to handle polymorphic relationships:</strong> Comments and other polymorphic relationships require proper configuration. Ensure your models are correctly set up for these relationships.</li>
        <li><strong>Not validating user settings:</strong> User settings should be validated before being saved to prevent invalid or malicious data.</li>
        <li><strong>Indexing too many fields for search:</strong> Indexing too many fields can slow down your search engine. Only index fields that are actually needed for search.</li>
        <li><strong>Not handling STI with search:</strong> Single Table Inheritance can complicate search. Ensure your search implementation works correctly with child models.</li>
        <li><strong>Using the wrong API authentication guard:</strong> Choose the appropriate authentication guard (Passport or Sanctum) based on your API's needs.</li>
        <li><strong>Not setting token expiration:</strong> API tokens should have an expiration time to limit the damage if they are compromised.</li>
        <li><strong>Forgetting to configure CORS:</strong> Cross-Origin Resource Sharing (CORS) is essential for APIs that are accessed from different domains.</li>
    </ul>
</div>

## Debugging Techniques for Phase 5

### Debugging Impersonation

Use session inspection to debug impersonation:

```php
// Check if impersonating
dd(session('impersonator_id'));

// Get the impersonator
$impersonator = User::find(session('impersonator_id'));
dd($impersonator);
```

### Testing Comments

Test comment functionality with Tinker:

```php
// Create a comment
$task = Task::find(1);
$comment = $task->addComment('This is a test comment');
dd($comment);

// Get all comments for a model
$comments = $task->comments;
dd($comments);
```

### Debugging User Settings

Inspect user settings with Tinker:

```php
// Get user settings
$user = User::find(1);
dd($user->settings);

// Test setting a value
$user->settings = array_merge($user->settings ?? [], ['theme' => 'dark']);
$user->save();
$user = User::find(1);
dd($user->settings);
```

### Testing Search

Test search functionality with different queries:

```php
// Basic search
$results = User::search('john')->get();
dd($results);

// Search with filters
$results = User::search('john')
    ->where('type', 'admin')
    ->get();
dd($results);
```

### Debugging API Authentication

Test API authentication with Postman or curl:

```bash
# Create a token
curl -X POST http://localhost:8000/oauth/token \
    -H "Content-Type: application/json" \
    -d '{"grant_type":"password","client_id":"2","client_secret":"your-client-secret","username":"user@example.com","password":"password","scope":""}'

# Use the token
curl -X GET http://localhost:8000/api/user \
    -H "Accept: application/json" \
    -H "Authorization: Bearer your-access-token"
```

### Monitoring API Requests

Use Laravel Telescope to monitor API requests:

```php
// Install Laravel Telescope
composer require laravel/telescope --dev
php artisan telescope:install
php artisan migrate

// Access Telescope at /telescope/requests
```

<div class="page-navigation">
    <a href="./050-phase4-realtime-troubleshooting.md" class="prev">Phase 4 Troubleshooting</a>
    <a href="./070-phase6-polishing-troubleshooting.md" class="next">Phase 6 Troubleshooting</a>
</div>
