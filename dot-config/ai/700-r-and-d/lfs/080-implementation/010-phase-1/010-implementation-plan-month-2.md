# 🔐 Phase 1 Implementation Plan - Month 2: Security & Authentication

**Document ID:** 010-implementation-plan-month-2  
**Last Updated:** 2025-05-31  
**Version:** 1.0  
**Focus:** OAuth 2.0, RBAC, security scanning, monitoring setup

---

<div style="background: #222; color: white; padding: 15px; border-radius: 8px; margin: 15px 0;">
<h2 style="margin: 0; color: white;">🔒 Month 2: Security & Monitoring</h2>
<p style="margin: 5px 0 0 0; color: white;">Duration: 30 days | Focus: Authentication & Security | Success Rate: 90%</p>
</div>

## 1. Week 3: OAuth 2.0 Implementation

### 1.1. Laravel Passport Setup

**Learning Objective:** Implement enterprise-grade OAuth 2.0 authentication with API security.

**Confidence Level:** 92% - Well-documented Laravel feature with established patterns

#### 1.1.1. Passport Installation

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```bash
# Install Laravel Passport
cd /Users/s-a-c/Herd/lfs
composer require 100-laravel/passport

# Run Passport migrations
php artisan migrate

# Install Passport
php artisan passport:install

# Generate personal access client
php artisan passport:client --personal
```

</div>

#### 1.1.2. Passport Configuration

**Update User Model:**

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```php
<?php
// app/Models/User.php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Passport\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens;

    // ...existing code...
}
```

</div>

**Configure AuthServiceProvider:**

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```php
<?php
// app/Providers/AuthServiceProvider.php

namespace App\Providers;

use Laravel\Passport\Passport;
use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;

class AuthServiceProvider extends ServiceProvider
{
    protected $policies = [
        // ...existing policies...
    ];

    public function boot(): void
    {
        Passport::tokensExpireIn(now()->addMinutes(15));
        Passport::refreshTokensExpireIn(now()->addDays(7));
        Passport::personalAccessTokensExpireIn(now()->addMonths(6));
    }
}
```

</div>

#### 1.1.3. API Guard Configuration

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```php
<?php
// config/auth.php

return [
    'guards' => [
        'web' => [
            'driver' => 'session',
            'provider' => 'users',
        ],

        'api' => [
            'driver' => 'passport',
            'provider' => 'users',
        ],
    ],

    // ...existing configuration...
];
```

</div>

### 1.2. Multi-Factor Authentication (MFA)

**Learning Objective:** Implement 2FA/MFA for enhanced security compliance.

**Confidence Level:** 88% - Third-party packages require careful configuration

#### 1.2.1. Laravel Fortify Installation

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```bash
# Install Laravel Fortify
composer require 100-laravel/fortify

# Publish Fortify configuration and resources
php artisan vendor:publish --provider="Laravel\Fortify\FortifyServiceProvider"

# Run Fortify migrations
php artisan migrate
```

</div>

#### 1.2.2. Two-Factor Authentication Setup

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```php
<?php
// config/fortify.php

'features' => [
    Features::registration(),
    Features::resetPasswords(),
    Features::emailVerification(),
    Features::updateProfileInformation(),
    Features::updatePasswords(),
    Features::twoFactorAuthentication([
        'confirm' => true,
        'confirmPassword' => true,
    ]),
],
```

</div>

**Configure FortifyServiceProvider:**

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```php
<?php
// app/Providers/FortifyServiceProvider.php

namespace App\Providers;

use Laravel\Fortify\Fortify;
use Laravel\Fortify\FortifyServiceProvider as BaseFortifyServiceProvider;

class FortifyServiceProvider extends BaseFortifyServiceProvider
{
    public function boot(): void
    {
        Fortify::loginView(function () {
            return view('auth.login');
        });

        Fortify::registerView(function () {
            return view('auth.register');
        });

        Fortify::twoFactorChallengeView(function () {
            return view('auth.two-factor-challenge');
        });
    }
}
```

</div>

---

## 2. Week 4: Role-Based Access Control (RBAC)

### 2.1. Spatie Permission Package

**Learning Objective:** Implement comprehensive RBAC system with hierarchical permissions.

**Confidence Level:** 95% - Mature package with excellent documentation

#### 2.1.1. Package Installation

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```bash
# Install Spatie Permission
composer require spatie/100-laravel-permission

# Publish migration files
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"

# Run permissions migrations
php artisan migrate

# Clear cache
php artisan cache:forget spatie.permission.cache
```

</div>

#### 2.1.2. User Model Configuration

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```php
<?php
// app/Models/User.php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Passport\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable
{
    use HasApiTokens, HasRoles;

    protected $guard_name = 'web'; // or 'api'

    // ...existing code...
}
```

</div>

#### 2.1.3. Permission and Role Setup

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```bash
# Create seeder for roles and permissions
php artisan make:seeder RolePermissionSeeder
```

</div>

**Create Role and Permission Structure:**

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```php
<?php
// database/seeders/RolePermissionSeeder.php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

class RolePermissionSeeder extends Seeder
{
    public function run(): void
    {
        // Create permissions
        $permissions = [
            'users.view',
            'users.create',
            'users.edit',
            'users.delete',
            'teams.view',
            'teams.create',
            'teams.edit',
            'teams.delete',
            'projects.view',
            'projects.create',
            'projects.edit',
            'projects.delete',
            'tasks.view',
            'tasks.create',
            'tasks.edit',
            'tasks.delete',
            'admin.access',
        ];

        foreach ($permissions as $permission) {
            Permission::create(['name' => $permission]);
        }

        // Create roles and assign permissions
        $superAdmin = Role::create(['name' => 'super-admin']);
        $superAdmin->givePermissionTo(Permission::all());

        $admin = Role::create(['name' => 'admin']);
        $admin->givePermissionTo([
            'users.view', 'users.edit',
            'teams.view', 'teams.create', 'teams.edit',
            'projects.view', 'projects.create', 'projects.edit',
            'tasks.view', 'tasks.create', 'tasks.edit',
        ]);

        $manager = Role::create(['name' => 'manager']);
        $manager->givePermissionTo([
            'teams.view',
            'projects.view', 'projects.create', 'projects.edit',
            'tasks.view', 'tasks.create', 'tasks.edit',
        ]);

        $user = Role::create(['name' => 'user']);
        $user->givePermissionTo([
            'tasks.view', 'tasks.create', 'tasks.edit',
        ]);
    }
}
```

</div>

### 2.2. Middleware and Route Protection

#### 2.2.1. Custom Middleware Creation

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```bash
# Create permission middleware
php artisan make:middleware CheckPermission

# Create role middleware
php artisan make:middleware CheckRole
```

</div>

**Permission Middleware:**

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```php
<?php
// app/Http/Middleware/CheckPermission.php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class CheckPermission
{
    public function handle(Request $request, Closure $next, $permission)
    {
        if (!auth()->user() || !auth()->user()->can($permission)) {
            abort(403, 'Unauthorized action.');
        }

        return $next($request);
    }
}
```

</div>

#### 2.2.2. Route Protection Implementation

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```php
<?php
// routes/web.php

use Illuminate\Support\Facades\Route;

Route::middleware(['auth', 'verified'])->group(function () {
    Route::get('/dashboard', function () {
        return view('dashboard');
    })->name('dashboard');

    // User management routes
    Route::middleware(['permission:users.view'])->group(function () {
        Route::get('/users', [UserController::class, 'index'])->name('users.index');
    });

    Route::middleware(['permission:users.create'])->group(function () {
        Route::get('/users/create', [UserController::class, 'create'])->name('users.create');
        Route::post('/users', [UserController::class, 'store'])->name('users.store');
    });

    // Admin routes
    Route::middleware(['role:admin|super-admin'])->prefix('admin')->group(function () {
        Route::get('/dashboard', [AdminController::class, 'dashboard'])->name('admin.dashboard');
    });
});
```

</div>

---

## 3. Week 5: Security Scanning & Monitoring

### 3.1. Static Application Security Testing (SAST)

**Learning Objective:** Implement automated security scanning in the development workflow.

**Confidence Level:** 85% - Multiple tools require configuration tuning

#### 3.1.1. PHPStan Security Rules

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```bash
# Install PHPStan with security rules
composer require --dev phpstan/phpstan
composer require --dev phpstan/phpstan-100-laravel
composer require --dev roave/security-advisories

# Create PHPStan configuration
touch phpstan.neon
```

</div>

**PHPStan Configuration:**

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```yaml
# phpstan.neon
includes:
  - vendor/phpstan/phpstan-100-laravel/extension.neon

parameters:
  level: 6
  paths:
    - app
    - routes
    - config
  excludePaths:
    - vendor
  checkMissingIterableValueType: false
  checkGenericClassInNonGenericObjectType: false
```

</div>

#### 3.1.2. Psalm Security Analysis

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```bash
# Install Psalm
composer require --dev vimeo/psalm

# Initialize Psalm
vendor/bin/psalm --init

# Run security analysis
vendor/bin/psalm --taint-analysis
```

</div>

### 3.2. Dynamic Application Security Testing (DAST)

#### 3.2.1. OWASP ZAP Integration

<div style="background: #e3f2fd; padding: 12px; border-radius: 6px; margin: 10px 0; color: #0d47a1;">

**Manual Installation Required:**

1. Download OWASP ZAP from [zaproxy.org](https://www.zaproxy.org/download/)
2. Install and configure for automated scanning
3. Create scan configuration for Laravel application

</div>

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```bash
# Install ZAP CLI (after ZAP installation)
pip3 install zaproxy

# Create ZAP scan script
touch scripts/security-scan.sh
chmod +x scripts/security-scan.sh
```

</div>

---

## 4. Progress Tracking

### 4.1. Week 3 Completion Checklist

<div style="background: #e8f5e8; padding: 12px; border-radius: 6px; margin: 10px 0; color: #1b5e20; border: 1px solid #4caf50;">

- [ ] **Laravel Passport** installed and configured
- [ ] **OAuth 2.0 tokens** working with proper expiration
- [ ] **API authentication** functional
- [ ] **Two-factor authentication** implemented
- [ ] **User model** updated with authentication traits
- [ ] **API routes** protected with authentication

**Progress: 50% → 65%**

</div>

### 4.2. Week 4 Completion Checklist

<div style="background: #e8f5e8; padding: 12px; border-radius: 6px; margin: 10px 0; color: #1b5e20; border: 1px solid #4caf50;">

- [ ] **Spatie Permission** package installed
- [ ] **Roles and permissions** seeded
- [ ] **RBAC middleware** created and configured
- [ ] **Routes protected** with permissions
- [ ] **Admin panel** accessible with proper roles
- [ ] **Permission system** tested and functional

**Progress: 65% → 80%**

</div>

---

## 5. Security Testing Commands

### 5.1. Authentication Testing

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```bash
# Test OAuth token generation
curl -X POST http://localhost:8000/oauth/token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "password",
    "client_id": "your-client-id",
    "client_secret": "your-client-secret",
    "username": "user@example.com",
    "password": "password"
  }'

# Test protected API endpoint
curl -X GET http://localhost:8000/api/user \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

</div>

### 5.2. Permission Testing

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```bash
# Run permission tests (using SQLite in-memory for speed)
php artisan test --filter=PermissionTest

# Test role assignments via Tinker
php artisan tinker
```

</div>

### 5.3. Database Testing Configuration

**Learning Objective:** Ensure tests run fast with SQLite in-memory database while maintaining PostgreSQL for
development.

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```bash
# Verify PHPUnit configuration for SQLite testing
cat phpunit.xml | grep -A 5 "<env"

# Run all tests with SQLite in-memory
php artisan test

# Run specific test suites
php artisan test --testsuite=Feature
php artisan test --testsuite=Unit

# Check database connections during testing
php artisan test --filter=DatabaseConnectionTest -v
```

</div>

---

**Next:** [Month 3 Implementation](010-implementation-plan-month-3.md) - Monitoring and validation setup

**References:**

- [Laravel Passport Documentation](https://laravel.com/docs/passport)
- [Spatie Permission Package](https://spatie.be/docs/laravel-permission)
- [OWASP Security Guidelines](https://owasp.org/www-project-top-ten/)
