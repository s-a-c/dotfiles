# Security Best Practices Exercises - Sample Answers (Part 2)

<link rel="stylesheet" href="../assets/css/styles.css">

This document continues the sample answers to the security best practices exercises.

## Set 5: API Security

### Questions

1. **Which of the following is NOT a recommended practice for API security?**
   - **Answer: C) Storing API tokens in cookies without the HttpOnly flag**
   - API tokens stored in cookies should have the HttpOnly flag set to prevent access from JavaScript.

2. **What is the purpose of API rate limiting?**
   - **Answer: B) To prevent abuse and DoS attacks**
   - Rate limiting prevents abuse and denial of service attacks by limiting the number of requests a client can make in a given time period.

3. **How does Laravel Sanctum handle SPA authentication?**
   - **Answer: B) By using session cookies and CSRF protection**
   - Laravel Sanctum uses Laravel's session cookies and CSRF protection for SPA authentication, providing a secure and convenient authentication method.

### Exercise: Implement a secure API

#### 1. Token-Based Authentication

```php
// In routes/api.php
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/posts', [PostController::class, 'index']);
    Route::post('/posts', [PostController::class, 'store']);
    Route::get('/posts/{post}', [PostController::class, 'show']);
    Route::put('/posts/{post}', [PostController::class, 'update']);
    Route::delete('/posts/{post}', [PostController::class, 'destroy']);
});

// In app/Http/Controllers/Api/AuthController.php
public function login(Request $request)
{
    $request->validate([
        'email' => 'required|email',
        'password' => 'required',
        'device_name' => 'required',
    ]);

    $user = User::where('email', $request->email)->first();

    if (! $user || ! Hash::check($request->password, $user->password)) {
        throw ValidationException::withMessages([
            'email' => ['The provided credentials are incorrect.'],
        ]);
    }

    return response()->json([
        'token' => $user->createToken($request->device_name)->plainTextToken
    ]);
}

public function logout(Request $request)
{
    $request->user()->currentAccessToken()->delete();

    return response()->json(['message' => 'Logged out successfully']);
}
```

This implementation uses Laravel Sanctum for token-based API authentication. It provides endpoints for login and logout, and protects API routes with the `auth:sanctum` middleware.

#### 2. Rate Limiting

```php
// In routes/api.php
Route::middleware(['auth:sanctum', 'throttle:api'])
    ->group(function () {
        Route::get('/posts', [PostController::class, 'index']);
        Route::post('/posts', [PostController::class, 'store']);
        Route::get('/posts/{post}', [PostController::class, 'show']);
        Route::put('/posts/{post}', [PostController::class, 'update']);
        Route::delete('/posts/{post}', [PostController::class, 'destroy']);
    });

// In app/Providers/RouteServiceProvider.php
RateLimiter::for('api', function (Request $request) {
    return Limit::perMinute(60)->by($request->user()?->id ?: $request->ip());
});
```

This implementation uses Laravel's rate limiting middleware to limit API requests to 60 per minute per user or IP address. This prevents abuse and denial of service attacks.

#### 3. Input Validation

```php
// In app/Http/Requests/StorePostRequest.php
class StorePostRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'category_id' => 'required|exists:categories,id',
            'tags' => 'array',
            'tags.*' => 'exists:tags,id',
        ];
    }
}

// In app/Http/Controllers/Api/PostController.php
public function store(StorePostRequest $request)
{
    $post = Post::create($request->validated());
    
    if ($request->has('tags')) {
        $post->tags()->attach($request->tags);
    }
    
    return response()->json($post, 201);
}
```

This implementation uses Laravel's form request validation to validate API input. It defines validation rules for each field and automatically returns validation errors if the input is invalid.

#### 4. Proper Error Handling

```php
// In app/Exceptions/Handler.php
public function register()
{
    $this->renderable(function (ValidationException $e, $request) {
        if ($request->expectsJson()) {
            return response()->json([
                'message' => 'The given data was invalid.',
                'errors' => $e->errors(),
            ], 422);
        }
    });
    
    $this->renderable(function (AuthenticationException $e, $request) {
        if ($request->expectsJson()) {
            return response()->json([
                'message' => 'Unauthenticated.',
            ], 401);
        }
    });
    
    $this->renderable(function (AuthorizationException $e, $request) {
        if ($request->expectsJson()) {
            return response()->json([
                'message' => 'This action is unauthorized.',
            ], 403);
        }
    });
    
    $this->renderable(function (ModelNotFoundException $e, $request) {
        if ($request->expectsJson()) {
            return response()->json([
                'message' => 'Resource not found.',
            ], 404);
        }
    });
}
```

This implementation customizes Laravel's exception handler to return appropriate JSON responses for API errors. It handles validation errors, authentication errors, authorization errors, and resource not found errors.

#### 5. Secure Response Formatting

```php
// In app/Http/Resources/PostResource.php
class PostResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'content' => $this->content,
            'category' => new CategoryResource($this->whenLoaded('category')),
            'tags' => TagResource::collection($this->whenLoaded('tags')),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}

// In app/Http/Controllers/Api/PostController.php
public function index()
{
    $posts = Post::with(['category', 'tags'])->paginate();
    
    return PostResource::collection($posts);
}

public function show(Post $post)
{
    $post->load(['category', 'tags']);
    
    return new PostResource($post);
}
```

This implementation uses Laravel's API resources to format API responses. It defines which fields should be included in the response and handles relationships, preventing the accidental exposure of sensitive data.

## Set 6: Secure File Uploads

### Questions

1. **Which of the following is NOT a recommended practice for secure file uploads?**
   - **Answer: B) Storing files with their original names**
   - Files should be stored with generated names to prevent path traversal attacks and collisions.

2. **Where should uploaded files be stored in a Laravel application?**
   - **Answer: B) In the storage directory**
   - The storage directory is outside the web root, preventing direct access to uploaded files.

3. **How can you prevent users from uploading malicious PHP files?**
   - **Answer: C) By using a combination of extension checking, MIME type validation, and file content analysis**
   - A comprehensive approach is needed to prevent the upload of malicious files.

### Exercise: Implement a secure file upload system

#### 1. File Type Validation

```php
// In a controller or request class
public function store(Request $request)
{
    $request->validate([
        'document' => 'required|file|mimes:pdf,doc,docx,txt|max:10240',
    ]);
    
    // Process the validated file
    // ...
}
```

This implementation validates the file type using Laravel's `mimes` validation rule, which checks both the file extension and MIME type. It only allows PDF, DOC, DOCX, and TXT files.

#### 2. File Size Limitation

```php
// In a controller or request class
public function store(Request $request)
{
    $request->validate([
        'document' => 'required|file|mimes:pdf,doc,docx,txt|max:10240', // 10MB limit
    ]);
    
    // Process the validated file
    // ...
}

// In php.ini
// upload_max_filesize = 20M
// post_max_size = 20M
```

This implementation limits the file size to 10MB using Laravel's `max` validation rule. It also configures PHP's `upload_max_filesize` and `post_max_size` directives to allow uploads up to 20MB.

#### 3. Secure File Storage

```php
// In config/filesystems.php
'disks' => [
    'local' => [
        'driver' => 'local',
        'root' => storage_path('app'),
        'throw' => false,
    ],
    
    'public' => [
        'driver' => 'local',
        'root' => storage_path('app/public'),
        'url' => env('APP_URL').'/storage',
        'visibility' => 'public',
        'throw' => false,
    ],
    
    'private' => [
        'driver' => 'local',
        'root' => storage_path('app/private'),
        'visibility' => 'private',
        'throw' => false,
    ],
];

// In a controller
public function store(Request $request)
{
    $request->validate([
        'document' => 'required|file|mimes:pdf,doc,docx,txt|max:10240',
    ]);
    
    $path = $request->file('document')->store('documents', 'private');
    
    Document::create([
        'user_id' => auth()->id(),
        'path' => $path,
        'original_name' => $request->file('document')->getClientOriginalName(),
        'mime_type' => $request->file('document')->getMimeType(),
        'size' => $request->file('document')->getSize(),
    ]);
    
    return redirect()->back();
}
```

This implementation stores uploaded files in a private disk outside the web root. It also stores metadata about the file in the database, including the original name, MIME type, and size.

#### 4. File Name Sanitization

```php
// In a controller or service
public function store(Request $request)
{
    $request->validate([
        'document' => 'required|file|mimes:pdf,doc,docx,txt|max:10240',
    ]);
    
    // Generate a random file name with the original extension
    $extension = $request->file('document')->getClientOriginalExtension();
    $fileName = Str::random(40) . '.' . $extension;
    
    $path = $request->file('document')->storeAs('documents', $fileName, 'private');
    
    Document::create([
        'user_id' => auth()->id(),
        'path' => $path,
        'original_name' => $request->file('document')->getClientOriginalName(),
        'mime_type' => $request->file('document')->getMimeType(),
        'size' => $request->file('document')->getSize(),
    ]);
    
    return redirect()->back();
}
```

This implementation generates a random file name for the uploaded file while preserving the original extension. This prevents path traversal attacks and collisions.

#### 5. Secure File Access Control

```php
// In routes/web.php
Route::get('/documents/{document}/download', [DocumentController::class, 'download'])
    ->name('documents.download')
    ->middleware('auth');

// In app/Http/Controllers/DocumentController.php
public function download(Document $document)
{
    // Check if the user is authorized to download this document
    $this->authorize('download', $document);
    
    // Get the full path to the file
    $path = storage_path('app/private/' . $document->path);
    
    // Return the file as a download
    return response()->download(
        $path,
        $document->original_name,
        [
            'Content-Type' => $document->mime_type,
            'Content-Disposition' => 'attachment; filename="' . $document->original_name . '"',
        ]
    );
}

// In app/Policies/DocumentPolicy.php
public function download(User $user, Document $document)
{
    return $user->id === $document->user_id;
}
```

This implementation uses Laravel's authorization system to control access to uploaded files. It checks if the user is authorized to download the document before serving the file.

## Set 7: Security Headers

### Questions

1. **Which security header helps prevent clickjacking attacks?**
   - **Answer: C) X-Frame-Options**
   - The X-Frame-Options header controls whether a page can be embedded in an iframe, preventing clickjacking attacks.

2. **What is the purpose of the Content-Security-Policy header?**
   - **Answer: A) To prevent cross-site scripting attacks**
   - The Content-Security-Policy header restricts which resources can be loaded, helping to prevent XSS attacks.

3. **Which of the following is a recommended value for the X-Content-Type-Options header?**
   - **Answer: B) `nosniff`**
   - The `nosniff` value prevents browsers from interpreting files as a different MIME type than what is declared.

### Exercise: Implement security headers

#### 1. Content Security Policy

```php
// In app/Http/Middleware/SecurityHeaders.php
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
```

This implementation adds a Content Security Policy header to all responses. It restricts which resources can be loaded, helping to prevent XSS attacks.

#### 2. X-Frame-Options

```php
// In app/Http/Middleware/SecurityHeaders.php
public function handle($request, Closure $next)
{
    $response = $next($request);
    
    // ... other headers
    
    $response->headers->set('X-Frame-Options', 'DENY');
    
    return $response;
}
```

This implementation adds an X-Frame-Options header with a value of `DENY`, preventing the page from being embedded in an iframe. This helps prevent clickjacking attacks.

#### 3. X-Content-Type-Options

```php
// In app/Http/Middleware/SecurityHeaders.php
public function handle($request, Closure $next)
{
    $response = $next($request);
    
    // ... other headers
    
    $response->headers->set('X-Content-Type-Options', 'nosniff');
    
    return $response;
}
```

This implementation adds an X-Content-Type-Options header with a value of `nosniff`, preventing browsers from interpreting files as a different MIME type than what is declared. This helps prevent MIME type confusion attacks.

#### 4. Strict-Transport-Security

```php
// In app/Http/Middleware/SecurityHeaders.php
public function handle($request, Closure $next)
{
    $response = $next($request);
    
    // ... other headers
    
    if (app()->environment('production')) {
        $response->headers->set(
            'Strict-Transport-Security',
            'max-age=31536000; includeSubDomains; preload'
        );
    }
    
    return $response;
}
```

This implementation adds a Strict-Transport-Security header in production, forcing browsers to use HTTPS for the site. It includes subdomains and is preloadable, providing maximum security.

#### 5. Referrer-Policy

```php
// In app/Http/Middleware/SecurityHeaders.php
public function handle($request, Closure $next)
{
    $response = $next($request);
    
    // ... other headers
    
    $response->headers->set('Referrer-Policy', 'strict-origin-when-cross-origin');
    
    return $response;
}
```

This implementation adds a Referrer-Policy header with a value of `strict-origin-when-cross-origin`, controlling how much referrer information is included with requests. This provides a good balance of security and usability.

## Set 8: Security Testing

### Questions

1. **Which of the following is NOT a type of security testing?**
   - **Answer: D) Functional Testing**
   - Functional testing focuses on functionality rather than security.

2. **What is the purpose of dependency scanning?**
   - **Answer: B) To identify vulnerabilities in your dependencies**
   - Dependency scanning checks for known vulnerabilities in your project's dependencies.

3. **Which command is used to check for vulnerabilities in Composer dependencies?**
   - **Answer: C) `composer audit`**
   - The `composer audit` command checks for vulnerabilities in Composer dependencies.

### Exercise: Implement a security testing strategy

#### 1. Automated Security Tests

```php
// In tests/Security/AuthenticationTest.php
class AuthenticationTest extends TestCase
{
    use RefreshDatabase;
    
    public function test_login_rate_limiting()
    {
        // Create a user
        $user = User::factory()->create([
            'email' => 'test@example.com',
            'password' => Hash::make('password'),
        ]);
        
        // Attempt to login with incorrect password multiple times
        for ($i = 0; $i < 5; $i++) {
            $response = $this->post('/login', [
                'email' => 'test@example.com',
                'password' => 'wrong-password',
            ]);
        }
        
        // Verify that the next attempt is rate limited
        $response = $this->post('/login', [
            'email' => 'test@example.com',
            'password' => 'wrong-password',
        ]);
        
        $response->assertStatus(429); // Too Many Requests
    }
    
    public function test_password_reset_token_expiration()
    {
        // Create a user
        $user = User::factory()->create();
        
        // Create a password reset token
        $token = Password::createToken($user);
        
        // Advance time beyond the expiration period
        $this->travel(Password::RESET_LINK_EXPIRATION + 1)->minutes();
        
        // Attempt to reset password with the token
        $response = $this->post('/reset-password', [
            'token' => $token,
            'email' => $user->email,
            'password' => 'newpassword',
            'password_confirmation' => 'newpassword',
        ]);
        
        // Verify that the token is expired
        $response->assertSessionHasErrors('email');
    }
}
```

This implementation creates automated tests for security features like login rate limiting and password reset token expiration. These tests verify that the security features are working correctly.

#### 2. Static Analysis

```php
// In composer.json
"scripts": {
    "phpstan": "phpstan analyse app",
    "psalm": "psalm",
    "security:static": [
        "@phpstan",
        "@psalm"
    ]
}

// In phpstan.neon
parameters:
    level: 5
    paths:
        - app

// In psalm.xml
<?xml version="1.0"?>
<psalm
    errorLevel="3"
    resolveFromConfigFile="true"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns="https://getpsalm.org/schema/config"
    xsi:schemaLocation="https://getpsalm.org/schema/config vendor/vimeo/psalm/config.xsd"
>
    <projectFiles>
        <directory name="app" />
        <ignoreFiles>
            <directory name="vendor" />
        </ignoreFiles>
    </projectFiles>
</psalm>
```

This implementation configures PHPStan and Psalm for static analysis of the codebase. It adds Composer scripts to run the static analysis tools and combines them into a single `security:static` script.

#### 3. Dependency Scanning

```php
// In composer.json
"scripts": {
    "audit": "composer audit",
    "security:deps": [
        "@audit"
    ]
}

// In .github/workflows/security.yml
name: Security Checks

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 0 * * *'  # Run daily

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
      - name: Install Dependencies
        run: composer install -q --no-ansi --no-interaction --no-scripts --no-progress
      - name: Security Check
        run: composer audit
```

This implementation adds a Composer script to run the `composer audit` command for dependency scanning. It also adds a GitHub Actions workflow to run the security checks on push, pull request, and daily.

#### 4. Security Headers Testing

```php
// In tests/Security/SecurityHeadersTest.php
class SecurityHeadersTest extends TestCase
{
    public function test_security_headers()
    {
        $response = $this->get('/');
        
        $response->assertHeader('Content-Security-Policy');
        $response->assertHeader('X-Content-Type-Options', 'nosniff');
        $response->assertHeader('X-Frame-Options', 'DENY');
        $response->assertHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
        
        if (app()->environment('production')) {
            $response->assertHeader('Strict-Transport-Security');
        }
    }
}
```

This implementation creates a test for security headers. It verifies that the expected security headers are present in the response.

#### 5. Penetration Testing Plan

```markdown
# Penetration Testing Plan

## Scope

- Authentication and authorization mechanisms
- Session management
- Input validation and output encoding
- Error handling and logging
- Data protection
- API security
- Business logic vulnerabilities

## Methodology

1. **Reconnaissance**: Gather information about the application
2. **Scanning**: Identify potential vulnerabilities
3. **Vulnerability Analysis**: Determine which vulnerabilities are exploitable
4. **Exploitation**: Attempt to exploit vulnerabilities
5. **Reporting**: Document findings and recommendations

## Tools

- OWASP ZAP
- Burp Suite
- Nmap
- Metasploit
- SQLmap
- Nikto

## Schedule

- Initial scan: Week 1
- Manual testing: Weeks 2-3
- Reporting: Week 4
- Remediation: Weeks 5-6
- Verification: Week 7

## Deliverables

- Detailed report of findings
- Risk assessment
- Remediation recommendations
- Verification of fixes
```

This implementation creates a penetration testing plan that outlines the scope, methodology, tools, schedule, and deliverables for a penetration test. This plan can be used to guide a professional penetration test of the application.
