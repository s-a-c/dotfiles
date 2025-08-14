# Phase 2: Auth & Profiles Troubleshooting

<link rel="stylesheet" href="../assets/css/styles.css">
<link rel="stylesheet" href="../assets/css/ume-docs-enhancements.css">
<script src="../assets/js/ume-docs-enhancements.js"></script>

This guide addresses common issues you might encounter during Phase 2 (Authentication, Profile Basics & State Machine) of the UME tutorial implementation.

## Fortify Authentication Issues

<div class="troubleshooting-guide">
    <h2>Fortify Configuration Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Authentication features not working (login, registration, etc.)</li>
            <li>Missing authentication routes</li>
            <li>Fortify views not being used</li>
            <li>Redirect loops after authentication</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Fortify not properly installed or configured</li>
            <li>Features not enabled in Fortify configuration</li>
            <li>Missing or incorrect view files</li>
            <li>Incorrect redirect paths</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Improper Installation</h4>
        <p>Ensure Fortify is properly installed and configured:</p>
        <pre><code>composer require laravel/fortify
php artisan vendor:publish --provider="Laravel\Fortify\FortifyServiceProvider"
php artisan migrate</code></pre>
        
        <h4>For Disabled Features</h4>
        <p>Enable the features you need in the Fortify configuration:</p>
        <pre><code>// config/fortify.php
'features' => [
    Features::registration(),
    Features::resetPasswords(),
    Features::emailVerification(),
    Features::updateProfileInformation(),
    Features::updatePasswords(),
    Features::twoFactorAuthentication([
        'confirmPassword' => true,
    ]),
],</code></pre>
        
        <h4>For Missing View Files</h4>
        <p>Create the necessary view files or use a view response callback:</p>
        <pre><code>// In a service provider
use Laravel\Fortify\Fortify;

Fortify::loginView(function () {
    return view('auth.login');
});

Fortify::registerView(function () {
    return view('auth.register');
});

Fortify::requestPasswordResetLinkView(function () {
    return view('auth.forgot-password');
});

Fortify::resetPasswordView(function ($request) {
    return view('auth.reset-password', ['request' => $request]);
});</code></pre>
        
        <h4>For Incorrect Redirect Paths</h4>
        <p>Update the redirect paths in the Fortify configuration:</p>
        <pre><code>// config/fortify.php
'home' => '/dashboard',
'prefix' => '',
'domain' => null,
'middleware' => ['web'],</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Follow the Fortify installation instructions carefully</li>
            <li>Enable only the features you need</li>
            <li>Create all necessary view files before testing authentication</li>
            <li>Test each authentication feature individually</li>
        </ul>
    </div>
</div>

## State Machine Issues

<div class="troubleshooting-guide">
    <h2>Account State Machine Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>State transitions not working correctly</li>
            <li>Invalid state errors</li>
            <li>State not being saved to the database</li>
            <li>Unable to access state-specific methods</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Missing or incorrect state configuration</li>
            <li>Invalid state transitions</li>
            <li>Missing state column in the database</li>
            <li>Not using the correct methods to change states</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Missing or Incorrect State Configuration</h4>
        <p>Ensure your state configuration is correct:</p>
        <pre><code>// In your User model
use Spatie\ModelStates\HasStates;

class User extends Authenticatable
{
    use HasStates;
    
    protected function registerStates(): void
    {
        $this->addState('status', AccountStatus::class)
            ->default(AccountStatus\Pending::class)
            ->allowTransition(AccountStatus\Pending::class, AccountStatus\Active::class)
            ->allowTransition(AccountStatus\Active::class, AccountStatus\Suspended::class)
            ->allowTransition(AccountStatus\Suspended::class, AccountStatus\Active::class)
            ->allowTransition(AccountStatus\Active::class, AccountStatus\Closed::class);
    }
}</code></pre>
        
        <h4>For Invalid State Transitions</h4>
        <p>Create transition classes for each allowed transition:</p>
        <pre><code>use Spatie\ModelStates\Transition;

class PendingToActiveTransition extends Transition
{
    public function handle(): AccountStatus
    {
        // Perform any logic needed for the transition
        return new AccountStatus\Active();
    }
}</code></pre>
        
        <h4>For Missing State Column</h4>
        <p>Add the state column to your users table:</p>
        <pre><code>Schema::table('users', function (Blueprint $table) {
    $table->string('status')->default('pending');
});</code></pre>
        
        <h4>For Incorrect State Change Methods</h4>
        <p>Use the correct methods to change states:</p>
        <pre><code>// Using a transition class
$user->status->transition(PendingToActiveTransition::class);

// Direct state change (if allowed)
$user->status = new AccountStatus\Active();
$user->save();</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Define all possible states and transitions upfront</li>
            <li>Create transition classes for complex state changes</li>
            <li>Add validation to prevent invalid state transitions</li>
            <li>Write tests to verify state transitions work correctly</li>
        </ul>
    </div>
</div>

## Email Verification Issues

<div class="troubleshooting-guide">
    <h2>Email Verification Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Verification emails not being sent</li>
            <li>Verification links not working</li>
            <li>State not changing after verification</li>
            <li>Users able to access protected routes without verification</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Email verification not enabled in Fortify</li>
            <li>Incorrect mail configuration</li>
            <li>Missing or incorrect verification event listeners</li>
            <li>Missing middleware on protected routes</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Disabled Email Verification</h4>
        <p>Enable email verification in Fortify:</p>
        <pre><code>// config/fortify.php
'features' => [
    Features::registration(),
    Features::emailVerification(),
    // Other features...
],</code></pre>
        
        <h4>For Incorrect Mail Configuration</h4>
        <p>Check your mail configuration in the .env file:</p>
        <pre><code>MAIL_MAILER=smtp
MAIL_HOST=mailhog
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="${APP_NAME}"</code></pre>
        
        <h4>For Missing Event Listeners</h4>
        <p>Create a listener for the Verified event to update the user's state:</p>
        <pre><code>// In EventServiceProvider
protected $listen = [
    Verified::class => [
        UpdateUserStateAfterVerification::class,
    ],
];

// UpdateUserStateAfterVerification.php
public function handle(Verified $event)
{
    $user = $event->user;
    if ($user->status instanceof AccountStatus\Pending) {
        $user->status->transition(PendingToActiveTransition::class);
    }
}</code></pre>
        
        <h4>For Missing Middleware</h4>
        <p>Add the verified middleware to protected routes:</p>
        <pre><code>Route::middleware(['auth', 'verified'])->group(function () {
    Route::get('/dashboard', function () {
        return view('dashboard');
    })->name('dashboard');
});</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Test email verification in a development environment</li>
            <li>Use a tool like Mailhog to catch and inspect emails</li>
            <li>Create event listeners for verification events</li>
            <li>Add the verified middleware to all routes that require verification</li>
        </ul>
    </div>
</div>

## Two-Factor Authentication Issues

<div class="troubleshooting-guide">
    <h2>Two-Factor Authentication Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Unable to enable 2FA</li>
            <li>QR code not displaying</li>
            <li>Recovery codes not generating</li>
            <li>2FA confirmation not working</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>2FA not enabled in Fortify configuration</li>
            <li>Missing required database columns</li>
            <li>Missing or incorrect 2FA views</li>
            <li>JavaScript errors in 2FA components</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Disabled 2FA</h4>
        <p>Enable 2FA in Fortify configuration:</p>
        <pre><code>// config/fortify.php
'features' => [
    // Other features...
    Features::twoFactorAuthentication([
        'confirmPassword' => true,
    ]),
],</code></pre>
        
        <h4>For Missing Database Columns</h4>
        <p>Ensure the required columns are in your users table:</p>
        <pre><code>Schema::table('users', function (Blueprint $table) {
    $table->text('two_factor_secret')
        ->after('password')
        ->nullable();

    $table->text('two_factor_recovery_codes')
        ->after('two_factor_secret')
        ->nullable();

    $table->timestamp('two_factor_confirmed_at')
        ->after('two_factor_recovery_codes')
        ->nullable();
});</code></pre>
        
        <h4>For Missing or Incorrect Views</h4>
        <p>Create the necessary 2FA views:</p>
        <pre><code>// In a service provider
Fortify::twoFactorChallengeView(function () {
    return view('auth.two-factor-challenge');
});</code></pre>
        
        <h4>For JavaScript Errors</h4>
        <p>Check your browser console for JavaScript errors and fix them. Ensure all required scripts are loaded.</p>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Follow the Fortify 2FA setup instructions carefully</li>
            <li>Test 2FA in a development environment</li>
            <li>Create all necessary view files before testing 2FA</li>
            <li>Keep recovery codes in a safe place during testing</li>
        </ul>
    </div>
</div>

## Profile UI Issues

<div class="troubleshooting-guide">
    <h2>Profile Information UI Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Profile information not updating</li>
            <li>Form validation errors not displaying</li>
            <li>UI components not rendering correctly</li>
            <li>JavaScript errors in the console</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Missing or incorrect Livewire/Volt components</li>
            <li>Flux UI components not properly installed</li>
            <li>Missing or incorrect form fields</li>
            <li>JavaScript or CSS not loading</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Missing Livewire/Volt Components</h4>
        <p>Create the necessary Livewire/Volt components:</p>
        <pre><code>php artisan make:livewire UpdateProfileInformation</code></pre>
        <p>Or for Volt:</p>
        <pre><code>php artisan make:volt UpdateProfileInformation</code></pre>
        
        <h4>For Flux UI Installation Issues</h4>
        <p>Ensure Flux UI is properly installed:</p>
        <pre><code>php artisan flux-ui:install</code></pre>
        
        <h4>For Missing Form Fields</h4>
        <p>Ensure your form includes all required fields:</p>
        <pre><code>&lt;form wire:submit="updateProfileInformation"&gt;
    &lt;div&gt;
        &lt;x-flux-ui::label for="first_name" value="First Name" /&gt;
        &lt;x-flux-ui::input id="first_name" type="text" wire:model="first_name" required autofocus autocomplete="first_name" /&gt;
        &lt;x-flux-ui::input-error for="first_name" class="mt-2" /&gt;
    &lt;/div&gt;
    
    &lt;div&gt;
        &lt;x-flux-ui::label for="last_name" value="Last Name" /&gt;
        &lt;x-flux-ui::input id="last_name" type="text" wire:model="last_name" required autocomplete="last_name" /&gt;
        &lt;x-flux-ui::input-error for="last_name" class="mt-2" /&gt;
    &lt;/div&gt;
    
    &lt;div&gt;
        &lt;x-flux-ui::label for="email" value="Email" /&gt;
        &lt;x-flux-ui::input id="email" type="email" wire:model="email" required autocomplete="email" /&gt;
        &lt;x-flux-ui::input-error for="email" class="mt-2" /&gt;
    &lt;/div&gt;
    
    &lt;div class="flex items-center justify-end mt-4"&gt;
        &lt;x-flux-ui::button&gt;Save&lt;/x-flux-ui::button&gt;
    &lt;/div&gt;
&lt;/form&gt;</code></pre>
        
        <h4>For JavaScript or CSS Issues</h4>
        <p>Ensure all required assets are loaded:</p>
        <pre><code>&lt;!-- In your layout file --&gt;
&lt;head&gt;
    &lt;!-- ... --&gt;
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    @livewireStyles
&lt;/head&gt;
&lt;body&gt;
    &lt;!-- ... --&gt;
    @livewireScripts
&lt;/body&gt;</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Follow the Livewire/Volt and Flux UI documentation</li>
            <li>Test UI components in isolation before integrating them</li>
            <li>Use browser developer tools to debug JavaScript and CSS issues</li>
            <li>Keep your dependencies updated</li>
        </ul>
    </div>
</div>

## File Upload Issues

<div class="troubleshooting-guide">
    <h2>Avatar Upload Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>File uploads failing</li>
            <li>Uploaded files not being saved</li>
            <li>Media library not generating conversions</li>
            <li>Permission errors when accessing uploaded files</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Missing or incorrect Media Library configuration</li>
            <li>Storage permissions issues</li>
            <li>Missing symbolic link to storage</li>
            <li>Incorrect model configuration for Media Library</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Media Library Configuration</h4>
        <p>Ensure Media Library is properly configured:</p>
        <pre><code>php artisan vendor:publish --provider="Spatie\MediaLibrary\MediaLibraryServiceProvider" --tag="config"</code></pre>
        
        <h4>For Storage Permissions</h4>
        <p>Set the correct permissions on your storage directory:</p>
        <pre><code>chmod -R 775 storage
chown -R www-data:www-data storage</code></pre>
        
        <h4>For Missing Symbolic Link</h4>
        <p>Create a symbolic link to your storage directory:</p>
        <pre><code>php artisan storage:link</code></pre>
        
        <h4>For Incorrect Model Configuration</h4>
        <p>Configure your User model to use Media Library:</p>
        <pre><code>use Spatie\MediaLibrary\HasMedia;
use Spatie\MediaLibrary\InteractsWithMedia;

class User extends Authenticatable implements HasMedia
{
    use InteractsWithMedia;
    
    public function registerMediaCollections(): void
    {
        $this->addMediaCollection('avatar')
            ->singleFile()
            ->registerMediaConversions(function () {
                $this->addMediaConversion('thumb')
                    ->width(100)
                    ->height(100)
                    ->sharpen(10);
                    
                $this->addMediaConversion('medium')
                    ->width(300)
                    ->height(300)
                    ->sharpen(10);
            });
    }
}</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Follow the Media Library documentation carefully</li>
            <li>Test file uploads in a development environment</li>
            <li>Check storage permissions before deploying</li>
            <li>Create a symbolic link to storage during deployment</li>
        </ul>
    </div>
</div>

## Service and Event Issues

<div class="troubleshooting-guide">
    <h2>User Service and Event Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>User creation or type change not working correctly</li>
            <li>Events not being dispatched</li>
            <li>Event listeners not being triggered</li>
            <li>Services not being injected correctly</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Services not registered in the service container</li>
            <li>Events not registered in the EventServiceProvider</li>
            <li>Missing or incorrect event listeners</li>
            <li>Dependency injection issues</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Service Registration</h4>
        <p>Register your services in a service provider:</p>
        <pre><code>// In a service provider
public function register(): void
{
    $this->app->singleton(UserService::class, function ($app) {
        return new UserService();
    });
    
    $this->app->singleton(UserTypeService::class, function ($app) {
        return new UserTypeService();
    });
}</code></pre>
        
        <h4>For Event Registration</h4>
        <p>Register your events in the EventServiceProvider:</p>
        <pre><code>protected $listen = [
    UserTypeChanged::class => [
        UpdateUserPermissions::class,
        LogUserTypeChange::class,
    ],
];</code></pre>
        
        <h4>For Event Listeners</h4>
        <p>Create the necessary event listeners:</p>
        <pre><code>class UpdateUserPermissions
{
    public function handle(UserTypeChanged $event): void
    {
        $user = $event->user;
        $oldType = $event->oldType;
        $newType = $event->newType;
        
        // Update permissions based on the new type
    }
}</code></pre>
        
        <h4>For Dependency Injection</h4>
        <p>Use constructor injection for your services:</p>
        <pre><code>class UserController extends Controller
{
    protected UserService $userService;
    protected UserTypeService $userTypeService;
    
    public function __construct(UserService $userService, UserTypeService $userTypeService)
    {
        $this->userService = $userService;
        $this->userTypeService = $userTypeService;
    }
    
    public function changeUserType(Request $request, User $user)
    {
        $this->userTypeService->changeUserType($user, $request->type);
        
        return redirect()->back()->with('status', 'User type changed successfully.');
    }
}</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Register services and events in the appropriate providers</li>
            <li>Use dependency injection instead of creating service instances directly</li>
            <li>Write tests to verify that events are dispatched and listeners are triggered</li>
            <li>Use Laravel's event discovery when possible</li>
        </ul>
    </div>
</div>

## Common Pitfalls in Phase 2

<div class="common-pitfalls">
    <h3>Common Pitfalls to Avoid</h3>
    <ul>
        <li><strong>Not understanding Fortify's architecture:</strong> Fortify provides backend authentication features but doesn't include views. You need to create your own views or use a frontend package.</li>
        <li><strong>Forgetting to enable features in Fortify:</strong> Features like email verification and 2FA need to be explicitly enabled in the Fortify configuration.</li>
        <li><strong>Not defining all possible state transitions:</strong> When using state machines, define all possible transitions upfront to avoid invalid state errors.</li>
        <li><strong>Using direct state assignment instead of transitions:</strong> State machines work best when you use transitions instead of directly assigning states.</li>
        <li><strong>Not handling email verification events:</strong> Email verification events need to be handled to update the user's state.</li>
        <li><strong>Forgetting to publish package configurations:</strong> Many packages require you to publish their configurations to function properly.</li>
        <li><strong>Not testing authentication flows:</strong> Authentication flows can be complex. Test each step to ensure it works correctly.</li>
    </ul>
</div>

## Debugging Techniques for Phase 2

### Testing Authentication Flows

Use Laravel's authentication testing helpers to test authentication flows:

```php
// Test registration
$response = $this->post('/register', [
    'name' => 'Test User',
    'email' => 'test@example.com',
    'password' => 'password',
    'password_confirmation' => 'password',
]);

$response->assertRedirect('/dashboard');
$this->assertAuthenticated();

// Test email verification
$user = User::factory()->create([
    'email_verified_at' => null,
]);

$verificationUrl = URL::temporarySignedRoute(
    'verification.verify',
    now()->addMinutes(60),
    ['id' => $user->id, 'hash' => sha1($user->email)]
);

$response = $this->actingAs($user)->get($verificationUrl);

$response->assertRedirect('/dashboard');
$this->assertTrue($user->fresh()->hasVerifiedEmail());
```

### Debugging State Machines

Use logging to debug state transitions:

```php
// In your transition class
public function handle(): AccountStatus
{
    Log::info('Transitioning from ' . get_class($this->from) . ' to ' . AccountStatus\Active::class);
    
    // Perform any logic needed for the transition
    return new AccountStatus\Active();
}
```

### Testing File Uploads

Test file uploads with Laravel's file upload testing helpers:

```php
$file = UploadedFile::fake()->image('avatar.jpg');

$response = $this->actingAs($user)
    ->post('/user/profile-photo', [
        'photo' => $file,
    ]);

$response->assertRedirect();
$this->assertNotNull($user->fresh()->getFirstMedia('avatar'));
```

### Debugging Events and Listeners

Use event faking to test events and listeners:

```php
Event::fake([UserTypeChanged::class]);

// Perform the action that should dispatch the event
$this->userTypeService->changeUserType($user, 'admin');

// Assert that the event was dispatched
Event::assertDispatched(UserTypeChanged::class, function ($event) use ($user) {
    return $event->user->id === $user->id &&
           $event->newType === 'admin';
});
```

<div class="page-navigation">
    <a href="./020-phase1-core-models-troubleshooting.md" class="prev">Phase 1 Troubleshooting</a>
    <a href="./040-phase3-teams-permissions-troubleshooting.md" class="next">Phase 3 Troubleshooting</a>
</div>
