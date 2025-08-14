# Testing in Phase 6: Polishing & Deployment

This document outlines the testing approach for the Polishing & Deployment phase of the UME tutorial. Comprehensive testing is essential to ensure that our application is ready for production, with proper internationalization, security, and performance optimizations.

## Testing Strategy

For the Polishing & Deployment phase, we'll focus on:

1. **Internationalization Tests**: Ensure that the application is correctly localized
2. **Security Tests**: Verify that the application is secure
3. **Performance Tests**: Test the application's performance
4. **Deployment Tests**: Ensure that the application can be deployed correctly
5. **Integration Tests**: Test how these components work together

## Internationalization Tests

```php
<?php

namespace Tests\Feature\Internationalization;

use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class InternationalizationTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function user_can_switch_language()
    {
        $user = User::factory()->create();
        
        $this->actingAs($user);
        
        // Switch to Spanish
        $response = $this->post('/language', [
            'language' => 'es',
        ]);
        
        $response->assertRedirect();
        $this->assertEquals('es', session('locale'));
        
        // Visit the dashboard
        $response = $this->get('/dashboard');
        
        // Check that the page is in Spanish
        $response->assertSee('Tablero'); // "Dashboard" in Spanish
    }

    #[Test]
    public function guest_can_switch_language()
    {
        // Switch to French
        $response = $this->post('/language', [
            'language' => 'fr',
        ]);
        
        $response->assertRedirect();
        $this->assertEquals('fr', session('locale'));
        
        // Visit the custom page
        $response = $this->get('/');
        
        // Check that the page is in French
        $response->assertSee('Bienvenue'); // "Welcome" in French
    }

    #[Test]
    public function language_middleware_sets_locale_from_session()
    {
        // Set the locale in the session
        session(['locale' => 'de']);
        
        // Visit the custom page
        $response = $this->get('/');
        
        // Check that the page is in German
        $response->assertSee('Willkommen'); // "Welcome" in German
        $this->assertEquals('de', app()->getLocale());
    }

    #[Test]
    public function language_middleware_uses_default_locale_if_not_set()
    {
        // Clear the locale from the session
        session()->forget('locale');
        
        // Visit the custom page
        $response = $this->get('/');
        
        // Check that the page is in English (default)
        $response->assertSee('Welcome');
        $this->assertEquals('en', app()->getLocale());
    }

    #[Test]
    public function user_preferred_language_is_used()
    {
        $user = User::factory()->create([
            'metadata' => ['preferences' => ['locale' => 'es']],
        ]);
        
        $this->actingAs($user);
        
        // Visit the dashboard
        $response = $this->get('/dashboard');
        
        // Check that the page is in Spanish
        $response->assertSee('Tablero'); // "Dashboard" in Spanish
        $this->assertEquals('es', app()->getLocale());
    }

    #[Test]
    public function translations_are_loaded_correctly()
    {
        // Set the locale to Spanish
        app()->setLocale('es');
        
        // Check that translations are loaded correctly
        $this->assertEquals('Tablero', __('Dashboard'));
        $this->assertEquals('Perfil', __('Profile'));
        $this->assertEquals('Cerrar sesión', __('Log Out'));
    }

    #[Test]
    public function date_formatting_respects_locale()
    {
        // Set the locale to French
        app()->setLocale('fr');
        
        // Format a date
        $date = now()->format('d F Y');
        
        // Check that the month is in French
        $this->assertStringContainsString('janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre', $date);
    }
}
```

## Security Tests

```php
<?php

namespace Tests\Feature\Security;

use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class SecurityTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function csrf_protection_is_enabled()
    {
        // Try to submit a form without CSRF token
        $response = $this->post('/login', [
            'email' => 'test@example.com',
            'password' => 'password',
        ]);
        
        // Should be rejected with a 419 status code
        $response->assertStatus(419);
    }

    #[Test]
    public function xss_protection_is_enabled()
    {
        $user = User::factory()->create();
        
        // Try to update the user's name with a script tag
        $this->actingAs($user)->put('/profile', [
            'given_name' => '<script>alert("XSS")</script>',
            'family_name' => 'Doe',
            'email' => $user->email,
        ]);
        
        // Check that the script tag was escaped
        $response = $this->get('/profile');
        $response->assertDontSee('<script>alert("XSS")</script>', false);
        $response->assertSee('&lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;', false);
    }

    #[Test]
    public function password_is_hashed()
    {
        $user = User::factory()->create([
            'password' => bcrypt('password'),
        ]);
        
        // Check that the password is hashed
        $this->assertNotEquals('password', $user->password);
        
        // Check that we can authenticate with the correct password
        $this->assertTrue(auth()->attempt([
            'email' => $user->email,
            'password' => 'password',
        ]));
    }

    #[Test]
    public function rate_limiting_is_enabled()
    {
        // Try to login multiple times with incorrect credentials
        for ($i = 0; $i < 5; $i++) {
            $this->post('/login', [
                'email' => 'test@example.com',
                'password' => 'wrong-password',
            ]);
        }
        
        // The next attempt should be rate limited
        $response = $this->post('/login', [
            'email' => 'test@example.com',
            'password' => 'wrong-password',
        ]);
        
        $response->assertStatus(429); // Too Many Requests
    }

    #[Test]
    public function secure_headers_are_set()
    {
        $response = $this->get('/');
        
        // Check that security headers are set
        $response->assertHeader('X-Frame-Options', 'SAMEORIGIN');
        $response->assertHeader('X-XSS-Protection', '1; mode=block');
        $response->assertHeader('X-Content-Type-Options', 'nosniff');
        $response->assertHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
    }

    #[Test]
    public function content_security_policy_is_set()
    {
        $response = $this->get('/');
        
        // Check that CSP header is set
        $response->assertHeader('Content-Security-Policy');
        
        // Check that the CSP includes necessary directives
        $csp = $response->headers->get('Content-Security-Policy');
        $this->assertStringContainsString("default-src 'self'", $csp);
        $this->assertStringContainsString("script-src 'self'", $csp);
        $this->assertStringContainsString("style-src 'self'", $csp);
    }

    #[Test]
    public function authenticated_routes_are_protected()
    {
        // Try to access a protected route as a guest
        $response = $this->get('/dashboard');
        
        // Should be redirected to login
        $response->assertRedirect('/login');
    }

    #[Test]
    public function authorization_is_enforced()
    {
        $user = User::factory()->create();
        $admin = User::factory()->create(['type' => 'admin']);
        
        // Try to access an admin-only route as a regular user
        $response = $this->actingAs($user)->get('/admin/dashboard');
        
        // Should be forbidden
        $response->assertStatus(403);
        
        // Try to access the same route as an admin
        $response = $this->actingAs($admin)->get('/admin/dashboard');
        
        // Should be allowed
        $response->assertStatus(200);
    }
}
```

## Performance Tests

```php
<?php

namespace Tests\Feature\Performance;

use App\Models\Team;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Support\Facades\DB;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class PerformanceTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function eager_loading_reduces_query_count()
    {
        // Create a team with multiple members
        $team = Team::factory()->create();
        $users = User::factory()->count(5)->create();
        
        foreach ($users as $user) {
            $team->users()->attach($user->id, ['role' => 'member']);
        }
        
        // Without eager loading
        DB::enableQueryLog();
        $teamWithoutEagerLoading = Team::find($team->id);
        $membersWithoutEagerLoading = $teamWithoutEagerLoading->users;
        $queryCountWithoutEagerLoading = count(DB::getQueryLog());
        DB::flushQueryLog();
        
        // With eager loading
        DB::enableQueryLog();
        $teamWithEagerLoading = Team::with('users')->find($team->id);
        $membersWithEagerLoading = $teamWithEagerLoading->users;
        $queryCountWithEagerLoading = count(DB::getQueryLog());
        DB::flushQueryLog();
        
        // Eager loading should result in fewer queries
        $this->assertLessThan($queryCountWithoutEagerLoading, $queryCountWithEagerLoading);
    }

    #[Test]
    public function caching_improves_performance()
    {
        // Create some data
        $users = User::factory()->count(10)->create();
        
        // Without caching
        DB::enableQueryLog();
        $startTime = microtime(true);
        $usersWithoutCaching = User::all();
        $endTime = microtime(true);
        $timeWithoutCaching = $endTime - $startTime;
        $queryCountWithoutCaching = count(DB::getQueryLog());
        DB::flushQueryLog();
        
        // With caching
        DB::enableQueryLog();
        $startTime = microtime(true);
        $usersWithCaching = cache()->remember('all_users', 60, function () {
            return User::all();
        });
        $endTime = microtime(true);
        $timeWithCaching = $endTime - $startTime;
        $queryCountWithCaching = count(DB::getQueryLog());
        DB::flushQueryLog();
        
        // Second call with caching (should be faster and have no queries)
        DB::enableQueryLog();
        $startTime = microtime(true);
        $usersWithCachingSecondCall = cache()->remember('all_users', 60, function () {
            return User::all();
        });
        $endTime = microtime(true);
        $timeWithCachingSecondCall = $endTime - $startTime;
        $queryCountWithCachingSecondCall = count(DB::getQueryLog());
        DB::flushQueryLog();
        
        // Caching should result in fewer queries on the second call
        $this->assertEquals($queryCountWithoutCaching, $queryCountWithCaching);
        $this->assertEquals(0, $queryCountWithCachingSecondCall);
        
        // Second call with caching should be faster
        $this->assertLessThan($timeWithCaching, $timeWithCachingSecondCall);
    }

    #[Test]
    public function pagination_improves_performance_for_large_datasets()
    {
        // Create a large dataset
        User::factory()->count(100)->create();
        
        // Without pagination (get all records)
        DB::enableQueryLog();
        $startTime = microtime(true);
        $allUsers = User::all();
        $endTime = microtime(true);
        $timeWithoutPagination = $endTime - $startTime;
        $queryCountWithoutPagination = count(DB::getQueryLog());
        DB::flushQueryLog();
        
        // With pagination (get first page)
        DB::enableQueryLog();
        $startTime = microtime(true);
        $paginatedUsers = User::paginate(10);
        $endTime = microtime(true);
        $timeWithPagination = $endTime - $startTime;
        $queryCountWithPagination = count(DB::getQueryLog());
        DB::flushQueryLog();
        
        // Pagination should be faster for large datasets
        $this->assertLessThan($timeWithoutPagination, $timeWithPagination);
        
        // Pagination should return fewer records
        $this->assertEquals(100, $allUsers->count());
        $this->assertEquals(10, $paginatedUsers->count());
    }

    #[Test]
    public function query_optimization_improves_performance()
    {
        // Create some data
        $teams = Team::factory()->count(10)->create();
        $users = User::factory()->count(50)->create();
        
        // Assign users to teams
        foreach ($users as $user) {
            $team = $teams->random();
            $team->users()->attach($user->id, ['role' => 'member']);
        }
        
        // Unoptimized query (using whereHas)
        DB::enableQueryLog();
        $startTime = microtime(true);
        $usersWithUnoptimizedQuery = User::whereHas('teams', function ($query) {
            $query->where('name', 'like', 'Team%');
        })->get();
        $endTime = microtime(true);
        $timeWithUnoptimizedQuery = $endTime - $startTime;
        $queryCountWithUnoptimizedQuery = count(DB::getQueryLog());
        DB::flushQueryLog();
        
        // Optimized query (using joins)
        DB::enableQueryLog();
        $startTime = microtime(true);
        $usersWithOptimizedQuery = User::join('team_user', 'users.id', '=', 'team_user.user_id')
            ->join('teams', 'team_user.team_id', '=', 'teams.id')
            ->where('teams.name', 'like', 'Team%')
            ->select('users.*')
            ->distinct()
            ->get();
        $endTime = microtime(true);
        $timeWithOptimizedQuery = $endTime - $startTime;
        $queryCountWithOptimizedQuery = count(DB::getQueryLog());
        DB::flushQueryLog();
        
        // Optimized query should be faster
        $this->assertLessThanOrEqual($timeWithUnoptimizedQuery, $timeWithOptimizedQuery);
        
        // Optimized query should use fewer queries
        $this->assertLessThanOrEqual($queryCountWithUnoptimizedQuery, $queryCountWithOptimizedQuery);
        
        // Both queries should return the same number of users
        $this->assertEquals($usersWithUnoptimizedQuery->count(), $usersWithOptimizedQuery->count());
    }
}
```

## Deployment Tests

```php
<?php

namespace Tests\Feature\Deployment;

use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class DeploymentTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function application_is_in_production_mode()
    {
        // This test should only run in the production environment
        if (app()->environment() !== 'production') {
            $this->markTestSkipped('This test only runs in production.');
        }
        
        $this->assertEquals('production', app()->environment());
        $this->assertFalse(config('app.debug'));
    }

    #[Test]
    public function required_environment_variables_are_set()
    {
        // Check that required environment variables are set
        $this->assertNotNull(env('APP_KEY'));
        $this->assertNotNull(env('DB_CONNECTION'));
        $this->assertNotNull(env('DB_HOST'));
        $this->assertNotNull(env('DB_DATABASE'));
        $this->assertNotNull(env('DB_USERNAME'));
        $this->assertNotNull(env('MAIL_MAILER'));
    }

    #[Test]
    public function database_migrations_are_up_to_date()
    {
        // Run the migration status command
        $output = shell_exec('php artisan migrate:status');
        
        // Check that all migrations are up to date
        $this->assertStringNotContainsString('| No |', $output);
    }

    #[Test]
    public function assets_are_compiled()
    {
        // Check that the compiled CSS file exists
        $this->assertFileExists(public_path('css/app.css'));
        
        // Check that the compiled JavaScript file exists
        $this->assertFileExists(public_path('js/app.js'));
    }

    #[Test]
    public function storage_directory_is_linked()
    {
        // Check that the storage directory is linked
        $this->assertDirectoryExists(public_path('storage'));
    }

    #[Test]
    public function queue_worker_is_running()
    {
        // Check if the queue worker is running
        $output = shell_exec('ps aux | grep "queue:work" | grep -v grep');
        
        $this->assertNotEmpty($output);
    }

    #[Test]
    public function scheduler_is_running()
    {
        // Check if the scheduler is in the crontab
        $output = shell_exec('crontab -l | grep "artisan schedule:run"');
        
        $this->assertNotEmpty($output);
    }

    #[Test]
    public function ssl_is_configured()
    {
        // Make a request to the HTTPS URL
        $response = $this->get('https://' . config('app.url'));
        
        // Check that the response is successful
        $response->assertStatus(200);
        
        // Check that the HTTPS URL is used
        $this->assertEquals('https', parse_url(config('app.url'), PHP_URL_SCHEME));
    }
}
```

## Integration Tests

```php
<?php

namespace Tests\Feature;

use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Support\Facades\Cache;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class PolishingIntegrationTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function internationalization_and_caching_work_together()
    {
        // Create a user
        $user = User::factory()->create();
        
        // Set the locale to Spanish
        app()->setLocale('es');
        
        // Cache some translated content
        $cachedContent = Cache::remember('welcome_message', 60, function () {
            return __('Welcome to our application');
        });
        
        // Check that the cached content is in Spanish
        $this->assertEquals('Bienvenido a nuestra aplicación', $cachedContent);
        
        // Change the locale to English
        app()->setLocale('en');
        
        // The cached content should still be in Spanish
        $this->assertEquals('Bienvenido a nuestra aplicación', Cache::get('welcome_message'));
        
        // Clear the cache
        Cache::forget('welcome_message');
        
        // Cache the content again, now in English
        $cachedContent = Cache::remember('welcome_message', 60, function () {
            return __('Welcome to our application');
        });
        
        // Check that the new cached content is in English
        $this->assertEquals('Welcome to our application', $cachedContent);
    }

    #[Test]
    public function security_and_performance_optimizations_work_together()
    {
        // Create a user
        $user = User::factory()->create();
        
        // Login
        $this->actingAs($user);
        
        // Make a request to a protected route
        $response = $this->get('/dashboard');
        
        // Check that the response is successful
        $response->assertStatus(200);
        
        // Check that security headers are set
        $response->assertHeader('X-Frame-Options', 'SAMEORIGIN');
        $response->assertHeader('X-XSS-Protection', '1; mode=block');
        
        // Check that the response is cached
        $response->assertHeader('Cache-Control');
        
        // The Cache-Control header should include private and max-age
        $cacheControl = $response->headers->get('Cache-Control');
        $this->assertStringContainsString('private', $cacheControl);
        $this->assertStringContainsString('max-age=', $cacheControl);
    }

    #[Test]
    public function complete_polishing_workflow()
    {
        // Create a user
        $user = User::factory()->create();
        
        // Step 1: User logs in
        $response = $this->post('/login', [
            'email' => $user->email,
            'password' => 'password',
        ]);
        
        $response->assertRedirect('/dashboard');
        
        // Step 2: User switches language to Spanish
        $this->actingAs($user)->post('/language', [
            'language' => 'es',
        ]);
        
        // Step 3: User visits the dashboard
        $response = $this->get('/dashboard');
        
        // Check that the page is in Spanish
        $response->assertSee('Tablero'); // "Dashboard" in Spanish
        
        // Check that security headers are set
        $response->assertHeader('X-Frame-Options', 'SAMEORIGIN');
        
        // Step 4: User updates their profile
        $response = $this->put('/profile', [
            'given_name' => 'Updated',
            'family_name' => 'Name',
            'email' => $user->email,
        ]);
        
        $response->assertRedirect('/profile');
        
        // Step 5: User logs out
        $response = $this->post('/logout');
        
        $response->assertRedirect('/');
        
        // Step 6: User visits the custom page as a guest
        $response = $this->get('/');
        
        // Check that the page is still in Spanish (from session)
        $response->assertSee('Bienvenido'); // "Welcome" in Spanish
    }
}
```

## Running the Tests

To run the tests for the Polishing & Deployment phase, use the following command:

```bash
php artisan test --filter=InternationalizationTest,SecurityTest,PerformanceTest,DeploymentTest,PolishingIntegrationTest
```

Or run all tests with:

```bash
php artisan test
```

## Test Coverage

To ensure comprehensive test coverage for the Polishing & Deployment phase, make sure your tests cover:

1. Internationalization (language switching, translation loading, locale-specific formatting)
2. Security (CSRF protection, XSS protection, password hashing, rate limiting, secure headers)
3. Performance (eager loading, caching, pagination, query optimization)
4. Deployment (environment configuration, asset compilation, queue workers, SSL)
5. Integration between these components

## Best Practices

1. **Use PHP Attributes**: Always use PHP 8 attributes (`#[Test]`) instead of PHPDoc annotations (`/** @test */`).
2. **Test Internationalization**: Verify that the application correctly handles multiple languages and locales.
3. **Test Security**: Ensure that the application is protected against common security vulnerabilities.
4. **Test Performance**: Verify that performance optimizations are working correctly.
5. **Test Deployment**: Ensure that the application is correctly configured for production.
6. **Use Environment-Specific Tests**: Some tests (like deployment tests) should only run in specific environments.
7. **Test Integration**: Ensure that these components work together correctly in real-world scenarios.

By following these guidelines, you'll ensure that your application is thoroughly tested and ready for production deployment.
