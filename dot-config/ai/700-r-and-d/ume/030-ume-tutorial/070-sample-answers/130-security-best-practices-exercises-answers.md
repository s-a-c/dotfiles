# Security Best Practices Exercises - Sample Answers

<link rel="stylesheet" href="../assets/css/styles.css">

This document provides sample answers to the security best practices exercises. These answers demonstrate how to implement security features in a Laravel application following best practices.

## Set 1: Authentication Security

### Questions

1. **What is the recommended way to store passwords in a Laravel application?**
   - **Answer: C) Using bcrypt or Argon2 hashing**
   - Laravel uses bcrypt by default for password hashing, with Argon2 as an alternative option. Both are secure, adaptive hashing algorithms that include salting and are resistant to brute force attacks.

2. **Which of the following is NOT a recommended practice for secure authentication?**
   - **Answer: C) Storing session IDs in local storage**
   - Session IDs should be stored in HTTP-only cookies, not in local storage. Local storage is accessible to JavaScript, making it vulnerable to XSS attacks.

3. **What is the purpose of Laravel Sanctum?**
   - **Answer: B) To provide API token authentication and SPA authentication**
   - Laravel Sanctum provides a lightweight authentication system for SPAs and simple token-based API authentication.

### Exercise: Implement a secure login system

#### 1. Password Strength Validation

```php
// In app/Actions/Fortify/PasswordValidationRules.php
public function passwordRules(): array
{
    return [
        'required',
        'string',
        (new Password)
            ->length(12)      // Require at least 12 characters
            ->mixedCase()     // Require both upper and lower case letters
            ->numbers()       // Require at least one number
            ->symbols()       // Require at least one symbol
            ->uncompromised(), // Check against known compromised passwords
        'confirmed',
    ];
}
```

This implementation uses Laravel's built-in password validation rules to enforce strong passwords. The `uncompromised` rule checks the password against the Have I Been Pwned database of compromised passwords.

#### 2. Rate Limiting for Login Attempts

```php
// In app/Providers/RouteServiceProvider.php
RateLimiter::for('login', function (Request $request) {
    return Limit::perMinute(5)->by($request->email.$request->ip())
        ->response(function () {
            return redirect()->route('login')
                ->withErrors(['email' => 'Too many login attempts. Please try again later.']);
        });
});

// In config/fortify.php
'limiters' => [
    'login' => 'login',
],
```

This implementation limits login attempts to 5 per minute per email/IP combination, preventing brute force attacks while still allowing legitimate users to retry if they make a mistake.

#### 3. Two-Factor Authentication

```php
// In config/fortify.php
'features' => [
    // ...
    Features::twoFactorAuthentication([
        'confirmPassword' => true,
    ]),
    // ...
],

// In a Livewire component for enabling 2FA
public function enableTwoFactorAuth()
{
    $this->validate([
        'password' => 'required|current_password',
    ]);

    $this->user->forceFill([
        'two_factor_secret' => encrypt(Google2FA::generateSecretKey()),
        'two_factor_recovery_codes' => encrypt(json_encode(RecoveryCode::generate())),
    ])->save();

    $this->showQrCode = true;
    $this->showRecoveryCodes = false;
}
```

This implementation enables two-factor authentication using Laravel Fortify. It requires password confirmation before enabling 2FA and generates a secret key and recovery codes.

#### 4. Secure Session Configuration

```php
// In config/session.php
return [
    'driver' => env('SESSION_DRIVER', 'file'),
    'lifetime' => env('SESSION_LIFETIME', 120),
    'expire_on_close' => false,
    'encrypt' => true,
    'secure' => env('SESSION_SECURE_COOKIE', true),
    'http_only' => true,
    'same_site' => 'lax',
];
```

This configuration ensures that session cookies are encrypted, HTTP-only, and secure (HTTPS only). The `same_site` attribute is set to 'lax' to prevent CSRF attacks while still allowing links to the site to include the session cookie.

#### 5. Secure Password Reset Functionality

```php
// In app/Models/User.php
use Illuminate\Auth\Passwords\CanResetPassword;
use Illuminate\Contracts\Auth\CanResetPassword as CanResetPasswordContract;

class User extends Authenticatable implements CanResetPasswordContract
{
    use CanResetPassword;
    
    // ...
}

// In a controller or service
public function resetPassword(Request $request)
{
    $request->validate([
        'token' => 'required',
        'email' => 'required|email',
        'password' => 'required|confirmed|min:12',
    ]);

    $status = Password::reset(
        $request->only('email', 'password', 'password_confirmation', 'token'),
        function ($user, $password) {
            $user->forceFill([
                'password' => Hash::make($password)
            ])->save();

            event(new PasswordReset($user));
        }
    );

    return $status === Password::PASSWORD_RESET
        ? redirect()->route('login')->with('status', __($status))
        : back()->withErrors(['email' => __($status)]);
}
```

This implementation uses Laravel's built-in password reset functionality, which includes secure token generation, expiration, and validation. It also logs password reset events for audit purposes.

## Set 2: Authorization Best Practices

### Questions

1. **Which Laravel feature is used to define authorization rules for models?**
   - **Answer: B) Policies**
   - Policies are classes that organize authorization logic around a particular model or resource.

2. **What is the purpose of the `can` middleware in Laravel?**
   - **Answer: A) To check if a user can perform an action on a resource**
   - The `can` middleware provides a convenient way to authorize actions using route parameters.

3. **How does the Spatie Laravel Permission package handle team-based permissions?**
   - **Answer: B) By adding a team_id column to the roles and permissions tables**
   - This allows roles and permissions to be scoped to specific teams.

### Exercise: Implement a team-based authorization system

#### 1. Role-Based Access Control

```php
// In database/migrations/create_permission_tables.php
Schema::create($tableNames['roles'], function (Blueprint $table) {
    $table->bigIncrements('id');
    $table->string('name');
    $table->string('guard_name');
    $table->unsignedBigInteger('team_id')->nullable();
    $table->timestamps();
    $table->unique(['name', 'guard_name', 'team_id']);
});

// In app/Models/User.php
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable
{
    use HasRoles;
    
    // ...
}

// Creating roles
$adminRole = Role::create(['name' => 'admin']);
$editorRole = Role::create(['name' => 'editor']);
$viewerRole = Role::create(['name' => 'viewer']);

// Assigning roles to users
$user->assignRole('editor');

// Checking roles
if ($user->hasRole('admin')) {
    // User is an admin
}
```

This implementation uses the Spatie Laravel Permission package to implement role-based access control. It creates roles, assigns them to users, and checks if users have specific roles.

#### 2. Team-Scoped Permissions

```php
// In config/permission.php
'teams' => true,
'team_foreign_key' => 'team_id',

// Assigning a role to a user within a team
$user->assignRole('editor', $team->id);

// Checking if a user has a role within a team
if ($user->hasRole('editor', $team->id)) {
    // User is an editor in this team
}

// Creating a permission
Permission::create(['name' => 'edit articles']);

// Assigning a permission to a role within a team
$role->givePermissionTo('edit articles', $team->id);

// Checking if a user has a permission within a team
if ($user->hasPermissionTo('edit articles', $team->id)) {
    // User can edit articles in this team
}
```

This implementation configures the Spatie Laravel Permission package for team-based permissions. It allows assigning roles and permissions within the context of a specific team.

#### 3. Policy-Based Authorization

```php
// In app/Policies/ArticlePolicy.php
class ArticlePolicy
{
    public function viewAny(User $user)
    {
        return true; // Anyone can view the list of articles
    }
    
    public function view(User $user, Article $article)
    {
        return $user->hasPermissionTo('view articles', $article->team_id);
    }
    
    public function create(User $user, $teamId)
    {
        return $user->hasPermissionTo('create articles', $teamId);
    }
    
    public function update(User $user, Article $article)
    {
        return $user->hasPermissionTo('edit articles', $article->team_id);
    }
    
    public function delete(User $user, Article $article)
    {
        return $user->hasPermissionTo('delete articles', $article->team_id);
    }
}

// In app/Providers/AuthServiceProvider.php
protected $policies = [
    Article::class => ArticlePolicy::class,
];

// In a controller
public function update(Request $request, Article $article)
{
    $this->authorize('update', $article);
    
    // User is authorized to update the article
    $article->update($request->validated());
    
    return redirect()->route('articles.show', $article);
}
```

This implementation creates a policy for the Article model that checks permissions within the context of a team. It registers the policy in the AuthServiceProvider and uses it in a controller.

#### 4. Blade Directive Authorization

```blade
<!-- In a Blade template -->
@can('update', $article)
    <a href="{{ route('articles.edit', $article) }}" class="btn btn-primary">Edit</a>
@endcan

@role('admin', $team->id)
    <a href="{{ route('teams.settings', $team) }}" class="btn btn-secondary">Team Settings</a>
@endrole

@hasPermission('delete articles', $team->id)
    <form method="POST" action="{{ route('articles.destroy', $article) }}">
        @csrf
        @method('DELETE')
        <button type="submit" class="btn btn-danger">Delete</button>
    </form>
@endhasPermission
```

This implementation uses Blade directives to conditionally display UI elements based on the user's permissions and roles. It checks if the user can update an article, if they have the admin role in a team, and if they have permission to delete articles in a team.

#### 5. API Authorization

```php
// In routes/api.php
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/articles', [ArticleController::class, 'index']);
    Route::get('/articles/{article}', [ArticleController::class, 'show']);
    Route::post('/articles', [ArticleController::class, 'store']);
    Route::put('/articles/{article}', [ArticleController::class, 'update']);
    Route::delete('/articles/{article}', [ArticleController::class, 'destroy']);
});

// In app/Http/Controllers/Api/ArticleController.php
public function update(Request $request, Article $article)
{
    $this->authorize('update', $article);
    
    $article->update($request->validated());
    
    return response()->json($article);
}
```

This implementation uses Laravel Sanctum for API authentication and policies for authorization. It checks if the authenticated user is authorized to perform the requested action on the resource.

## Set 3: CSRF and XSS Protection

### Questions

1. **What is the purpose of CSRF protection?**
   - **Answer: B) To prevent cross-site request forgery attacks**
   - CSRF protection prevents attackers from tricking users into submitting unwanted requests to a website where they're authenticated.

2. **How does Laravel protect against XSS attacks by default?**
   - **Answer: A) By using the `{{ }}` syntax to automatically escape output**
   - Laravel's Blade templating engine automatically escapes output when using the `{{ }}` syntax.

3. **Which of the following is a recommended practice for preventing XSS attacks?**
   - **Answer: C) Implementing a Content Security Policy**
   - A Content Security Policy restricts which resources can be loaded, helping to prevent XSS attacks.

### Exercise: Implement CSRF and XSS protection

#### 1. CSRF Protection for the Form

```blade
<!-- In a Blade template -->
<form method="POST" action="/comments">
    @csrf
    <div class="form-group">
        <label for="content">Comment</label>
        <textarea name="content" id="content" class="form-control">{{ old('content') }}</textarea>
    </div>
    <button type="submit" class="btn btn-primary">Submit</button>
</form>
```

This implementation uses Laravel's `@csrf` Blade directive to include a CSRF token in the form. Laravel's VerifyCsrfToken middleware will automatically validate this token when the form is submitted.

#### 2. Input Validation for the Comment Text

```php
// In a controller or request class
public function store(Request $request)
{
    $validated = $request->validate([
        'content' => 'required|string|max:1000',
    ]);
    
    $comment = Comment::create([
        'content' => $validated['content'],
        'user_id' => auth()->id(),
    ]);
    
    return redirect()->back();
}
```

This implementation validates the comment text to ensure it's a string and doesn't exceed 1000 characters. This helps prevent malicious input.

#### 3. Safe Output of the Comment Text

```blade
<!-- In a Blade template -->
<div class="comment">
    <p>{{ $comment->content }}</p>
</div>
```

This implementation uses Blade's `{{ }}` syntax to automatically escape the comment text, preventing XSS attacks. If the comment contains HTML tags, they will be displayed as text rather than being interpreted as HTML.

#### 4. Content Security Policy Configuration

```php
// In app/Http/Middleware/ContentSecurityPolicy.php
class ContentSecurityPolicy
{
    public function handle($request, Closure $next)
    {
        $response = $next($request);
        
        $csp = "default-src 'self'; " .
               "script-src 'self' https://cdn.jsdelivr.net; " .
               "style-src 'self' https://fonts.googleapis.com; " .
               "img-src 'self' data:; " .
               "font-src 'self' https://fonts.gstatic.com; " .
               "connect-src 'self'; " .
               "media-src 'self'; " .
               "object-src 'none'; " .
               "frame-src 'self'; " .
               "frame-ancestors 'self'; " .
               "form-action 'self'; " .
               "base-uri 'self'; " .
               "manifest-src 'self'";
        
        $response->headers->set('Content-Security-Policy', $csp);
        
        return $response;
    }
}

// In app/Http/Kernel.php
protected $middlewareGroups = [
    'web' => [
        // ...
        \App\Http\Middleware\ContentSecurityPolicy::class,
    ],
];
```

This implementation adds a Content Security Policy header to all responses, restricting which resources can be loaded. This helps prevent XSS attacks by limiting the sources of scripts, styles, and other resources.

#### 5. HTML Sanitization for Formatted Text

```php
// In a controller or service
public function store(Request $request)
{
    $validated = $request->validate([
        'content' => 'required|string|max:1000',
    ]);
    
    // Sanitize HTML content
    $config = HTMLPurifier_Config::createDefault();
    $config->set('HTML.Allowed', 'p,b,i,u,a[href],ul,ol,li,br,em,strong');
    $purifier = new HTMLPurifier($config);
    $sanitizedContent = $purifier->purify($validated['content']);
    
    $comment = Comment::create([
        'content' => $sanitizedContent,
        'user_id' => auth()->id(),
    ]);
    
    return redirect()->back();
}

// In a Blade template
<div class="comment">
    {!! $comment->content !!}
</div>
```

This implementation uses HTML Purifier to sanitize the comment text, allowing only specific HTML tags and attributes. This allows users to include formatted text in their comments while preventing XSS attacks.

## Set 4: SQL Injection Prevention

### Questions

1. **Which of the following is the most secure way to perform a database query with user input?**
   - **Answer: C) Using Eloquent or the Query Builder with parameter binding**
   - Eloquent and the Query Builder automatically handle parameter binding, preventing SQL injection.

2. **What is the purpose of parameter binding in database queries?**
   - **Answer: C) To prevent SQL injection attacks**
   - Parameter binding ensures that user input is properly escaped and treated as data, not code.

3. **How should you handle dynamic table or column names in database queries?**
   - **Answer: C) Validate against a whitelist of allowed names**
   - Dynamic table or column names should be validated against a whitelist to prevent SQL injection.

### Exercise: Implement secure database queries

#### 1. Secure Query for Searching by Name

```php
// In a controller or service
public function search(Request $request)
{
    $query = Product::query();
    
    if ($request->filled('name')) {
        $query->where('name', 'like', '%' . $request->input('name') . '%');
    }
    
    $products = $query->get();
    
    return view('products.index', compact('products'));
}
```

This implementation uses Laravel's Query Builder to search for products by name. The Query Builder automatically handles parameter binding, preventing SQL injection.

#### 2. Secure Query for Filtering by Category

```php
// In a controller or service
public function search(Request $request)
{
    $query = Product::query();
    
    if ($request->filled('category_id')) {
        $query->where('category_id', $request->input('category_id'));
    }
    
    $products = $query->get();
    
    return view('products.index', compact('products'));
}
```

This implementation uses Laravel's Query Builder to filter products by category. The Query Builder automatically handles parameter binding, preventing SQL injection.

#### 3. Secure Query for Filtering by Price Range

```php
// In a controller or service
public function search(Request $request)
{
    $query = Product::query();
    
    if ($request->filled('min_price')) {
        $query->where('price', '>=', $request->input('min_price'));
    }
    
    if ($request->filled('max_price')) {
        $query->where('price', '<=', $request->input('max_price'));
    }
    
    $products = $query->get();
    
    return view('products.index', compact('products'));
}
```

This implementation uses Laravel's Query Builder to filter products by price range. The Query Builder automatically handles parameter binding, preventing SQL injection.

#### 4. Secure Handling of Sorting by Different Columns

```php
// In a controller or service
public function search(Request $request)
{
    $query = Product::query();
    
    // Define allowed columns for sorting
    $allowedColumns = ['name', 'price', 'created_at'];
    
    // Get the sort column from the request, defaulting to 'created_at'
    $sortColumn = $request->input('sort', 'created_at');
    
    // Validate the sort column against the allowed columns
    if (!in_array($sortColumn, $allowedColumns)) {
        $sortColumn = 'created_at';
    }
    
    // Get the sort direction from the request, defaulting to 'desc'
    $sortDirection = $request->input('direction', 'desc');
    
    // Validate the sort direction
    if (!in_array($sortDirection, ['asc', 'desc'])) {
        $sortDirection = 'desc';
    }
    
    // Apply the sorting
    $query->orderBy($sortColumn, $sortDirection);
    
    $products = $query->get();
    
    return view('products.index', compact('products'));
}
```

This implementation validates the sort column against a whitelist of allowed columns and the sort direction against allowed values. This prevents SQL injection through dynamic column names.

#### 5. Secure Pagination of Results

```php
// In a controller or service
public function search(Request $request)
{
    $query = Product::query();
    
    // Apply filters
    if ($request->filled('name')) {
        $query->where('name', 'like', '%' . $request->input('name') . '%');
    }
    
    if ($request->filled('category_id')) {
        $query->where('category_id', $request->input('category_id'));
    }
    
    // Apply sorting
    $allowedColumns = ['name', 'price', 'created_at'];
    $sortColumn = $request->input('sort', 'created_at');
    
    if (!in_array($sortColumn, $allowedColumns)) {
        $sortColumn = 'created_at';
    }
    
    $sortDirection = $request->input('direction', 'desc');
    
    if (!in_array($sortDirection, ['asc', 'desc'])) {
        $sortDirection = 'desc';
    }
    
    $query->orderBy($sortColumn, $sortDirection);
    
    // Apply pagination
    $perPage = $request->input('per_page', 15);
    
    if (!in_array($perPage, [15, 30, 50, 100])) {
        $perPage = 15;
    }
    
    $products = $query->paginate($perPage);
    
    return view('products.index', compact('products'));
}
```

This implementation uses Laravel's pagination system to paginate the results. It validates the number of items per page against a whitelist of allowed values to prevent potential DoS attacks through excessive pagination.
