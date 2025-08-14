# Chinook Security Implementation - Comprehensive Guide

> **Created:** 2025-07-18  
> **Focus:** Complete security implementation with RBAC, authentication, authorization, and data protection  
> **Compliance:** OWASP Top 10, Laravel Security Best Practices

## Table of Contents

- [Overview](#overview)
- [Authentication System](#authentication-system)
- [Authorization & RBAC](#authorization--rbac)
- [Data Protection](#data-protection)
- [Input Validation & Sanitization](#input-validation--sanitization)
- [Security Headers & Configuration](#security-headers--configuration)
- [API Security](#api-security)
- [Audit Trails & Monitoring](#audit-trails--monitoring)
- [Security Testing](#security-testing)

## Overview

The Chinook music store implements enterprise-grade security with multi-layered protection, role-based access control, and comprehensive audit trails. This guide provides complete implementation details for all security aspects.

### Security Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Security Layers                          │
├─────────────────────────────────────────────────────────────┤
│ 1. Network Security (HTTPS, Rate Limiting, Firewall)       │
│ 2. Application Security (Authentication, Authorization)     │
│ 3. Data Security (Encryption, Validation, Sanitization)    │
│ 4. Business Logic Security (Policies, Permissions)         │
│ 5. Audit & Monitoring (Logs, Alerts, Compliance)          │
└─────────────────────────────────────────────────────────────┘
```

### Security Principles

- **Defense in Depth**: Multiple security layers
- **Principle of Least Privilege**: Minimal required permissions
- **Zero Trust**: Verify everything, trust nothing
- **Data Minimization**: Collect only necessary data
- **Transparency**: Clear audit trails and logging

## Authentication System

### Laravel Sanctum Implementation

```php
<?php
// config/sanctum.php

return [
    'stateful' => explode(',', env('SANCTUM_STATEFUL_DOMAINS', sprintf(
        '%s%s',
        'localhost,localhost:3000,127.0.0.1,127.0.0.1:8000,::1',
        Sanctum::currentApplicationUrlWithPort()
    ))),

    'guard' => ['web'],

    'expiration' => env('SANCTUM_TOKEN_EXPIRATION', 60 * 24 * 7), // 7 days

    'token_prefix' => env('SANCTUM_TOKEN_PREFIX', ''),

    'middleware' => [
        'authenticate_session' => Laravel\Sanctum\Http\Middleware\AuthenticateSession::class,
        'encrypt_cookies' => App\Http\Middleware\EncryptCookies::class,
        'validate_csrf_token' => App\Http\Middleware\VerifyCsrfToken::class,
    ],
];
```

### Multi-Factor Authentication

```php
<?php
// app/Models/User.php

use Laravel\Fortify\TwoFactorAuthenticatable;

class User extends Authenticatable
{
    use TwoFactorAuthenticatable;

    protected $fillable = [
        'name', 'email', 'password', 'two_factor_enabled'
    ];

    protected $hidden = [
        'password', 'remember_token', 'two_factor_recovery_codes', 'two_factor_secret'
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'two_factor_enabled' => 'boolean',
        ];
    }

    public function enableTwoFactorAuthentication(): void
    {
        $this->forceFill([
            'two_factor_secret' => encrypt(app(TwoFactorAuthenticationProvider::class)->generateSecretKey()),
            'two_factor_recovery_codes' => encrypt(json_encode(Collection::times(8, function () {
                return RecoveryCode::generate();
            })->all())),
            'two_factor_enabled' => true,
        ])->save();
    }

    public function disableTwoFactorAuthentication(): void
    {
        $this->forceFill([
            'two_factor_secret' => null,
            'two_factor_recovery_codes' => null,
            'two_factor_enabled' => false,
        ])->save();
    }
}
```

### Session Security

```php
<?php
// config/session.php

return [
    'driver' => env('SESSION_DRIVER', 'database'),
    'lifetime' => env('SESSION_LIFETIME', 120),
    'expire_on_close' => true,
    'encrypt' => true,
    'files' => storage_path('framework/sessions'),
    'connection' => env('SESSION_CONNECTION'),
    'table' => 'sessions',
    'store' => env('SESSION_STORE'),
    'lottery' => [2, 100],
    'cookie' => env('SESSION_COOKIE', Str::slug(env('APP_NAME', 'laravel'), '_').'_session'),
    'path' => '/',
    'domain' => env('SESSION_DOMAIN'),
    'secure' => env('SESSION_SECURE_COOKIE', true),
    'http_only' => true,
    'same_site' => 'strict',
    'partitioned' => false,
];
```

## Authorization & RBAC

### Role-Based Access Control Implementation

```php
<?php
// app/Models/Role.php

use Spatie\Permission\Models\Role as SpatieRole;

class Role extends SpatieRole
{
    // Predefined system roles
    public const SUPER_ADMIN = 'super-admin';
    public const ADMIN = 'admin';
    public const MANAGER = 'manager';
    public const EMPLOYEE = 'employee';
    public const CUSTOMER = 'customer';
    public const SUPPORT = 'support';

    protected $fillable = ['name', 'guard_name', 'description', 'is_system_role'];

    protected function casts(): array
    {
        return [
            'is_system_role' => 'boolean',
        ];
    }

    public static function getSystemRoles(): array
    {
        return [
            self::SUPER_ADMIN => 'Super Administrator - Full system access',
            self::ADMIN => 'Administrator - Administrative access',
            self::MANAGER => 'Manager - Team management access',
            self::EMPLOYEE => 'Employee - Limited administrative access',
            self::CUSTOMER => 'Customer - Customer portal access',
            self::SUPPORT => 'Support - Customer support access',
        ];
    }

    public function isSystemRole(): bool
    {
        return $this->is_system_role;
    }
}
```

### Permission System

```php
<?php
// app/Models/Permission.php

use Spatie\Permission\Models\Permission as SpatiePermission;

class Permission extends SpatiePermission
{
    // Resource permissions
    public const VIEW_ANY = 'view_any';
    public const VIEW = 'view';
    public const CREATE = 'create';
    public const UPDATE = 'update';
    public const DELETE = 'delete';
    public const RESTORE = 'restore';
    public const FORCE_DELETE = 'force_delete';

    // Special permissions
    public const MANAGE_USERS = 'manage_users';
    public const MANAGE_ROLES = 'manage_roles';
    public const VIEW_AUDIT_LOGS = 'view_audit_logs';
    public const EXPORT_DATA = 'export_data';
    public const IMPORT_DATA = 'import_data';

    protected $fillable = ['name', 'guard_name', 'description', 'category'];

    public static function generateResourcePermissions(string $resource): array
    {
        $permissions = [];
        $actions = [self::VIEW_ANY, self::VIEW, self::CREATE, self::UPDATE, self::DELETE, self::RESTORE, self::FORCE_DELETE];

        foreach ($actions as $action) {
            $permissions[] = [
                'name' => "{$action}_{$resource}",
                'guard_name' => 'web',
                'description' => ucfirst(str_replace('_', ' ', $action)) . " {$resource}",
                'category' => $resource,
            ];
        }

        return $permissions;
    }
}
```

### Advanced Authorization Policies

```php
<?php
// app/Policies/Chinook/EmployeePolicy.php

namespace App\Policies\Chinook;

use App\Models\User;
use App\Models\Chinook\Employee;
use Illuminate\Auth\Access\HandlesAuthorization;
use Illuminate\Auth\Access\Response;

class EmployeePolicy
{
    use HandlesAuthorization;

    public function before(User $user, string $ability): bool|null
    {
        if ($user->hasRole('super-admin')) {
            return true;
        }

        return null;
    }

    public function viewAny(User $user): bool
    {
        return $user->can('view_any_chinook::employee');
    }

    public function view(User $user, Employee $employee): bool
    {
        // Users can view their own profile
        if ($user->employee_id === $employee->id) {
            return true;
        }

        // Managers can view their subordinates
        if ($this->isManager($user, $employee)) {
            return true;
        }

        // HR can view all employees
        if ($user->hasRole('admin') || $this->isHR($user)) {
            return true;
        }

        return $user->can('view_chinook::employee');
    }

    public function create(User $user): bool
    {
        return $user->can('create_chinook::employee') && 
               ($user->hasRole(['admin', 'manager']) || $this->isHR($user));
    }

    public function update(User $user, Employee $employee): bool
    {
        // Users can update their own basic information
        if ($user->employee_id === $employee->id) {
            return true;
        }

        // Managers can update their subordinates
        if ($this->isManager($user, $employee)) {
            return true;
        }

        return $user->can('update_chinook::employee') && 
               ($user->hasRole(['admin']) || $this->isHR($user));
    }

    public function delete(User $user, Employee $employee): Response
    {
        // Cannot delete if employee has customers
        if ($employee->customers()->exists()) {
            return Response::deny('Cannot delete employee with assigned customers.');
        }

        // Cannot delete if employee has subordinates
        if ($employee->subordinates()->exists()) {
            return Response::deny('Cannot delete employee with subordinates.');
        }

        // Cannot delete own account
        if ($user->employee_id === $employee->id) {
            return Response::deny('Cannot delete your own employee record.');
        }

        return $user->can('delete_chinook::employee') && $user->hasRole(['admin'])
            ? Response::allow()
            : Response::deny('Insufficient permissions to delete employees.');
    }

    public function viewSalary(User $user, Employee $employee): bool
    {
        // Only HR and senior management can view salary information
        return $this->isHR($user) || 
               $user->hasRole(['admin']) ||
               $user->employee?->department === 'Management';
    }

    public function viewPerformance(User $user, Employee $employee): bool
    {
        // Employees can view their own performance
        if ($user->employee_id === $employee->id) {
            return true;
        }

        // Managers can view subordinate performance
        if ($this->isManager($user, $employee)) {
            return true;
        }

        // HR can view all performance data
        return $this->isHR($user) || $user->hasRole(['admin']);
    }

    public function manageHierarchy(User $user): bool
    {
        return $this->isHR($user) || $user->hasRole(['admin']);
    }

    private function isManager(User $user, Employee $employee): bool
    {
        return $user->employee && 
               $employee->reports_to === $user->employee->id;
    }

    private function isHR(User $user): bool
    {
        return $user->employee?->department === 'HR' || 
               $user->hasRole(['admin']);
    }
}
```

## Data Protection

### Encryption Implementation

```php
<?php
// app/Models/Chinook/Customer.php

use Illuminate\Database\Eloquent\Casts\Attribute;

class Customer extends BaseModel
{
    protected $fillable = [
        'first_name', 'last_name', 'email', 'phone', 'address',
        'city', 'state', 'country', 'postal_code', 'company'
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'phone' => 'encrypted',
            'address' => 'encrypted',
            'postal_code' => 'encrypted',
        ];
    }

    // Accessor for encrypted phone with masking
    protected function phone(): Attribute
    {
        return Attribute::make(
            get: fn ($value) => $this->maskSensitiveData($value, 'phone'),
            set: fn ($value) => $value,
        );
    }

    // Data masking for display purposes
    private function maskSensitiveData(string $value, string $type): string
    {
        if (!auth()->user()?->can('view_sensitive_data')) {
            return match($type) {
                'phone' => substr($value, 0, 3) . '***' . substr($value, -2),
                'email' => substr($value, 0, 2) . '***@' . substr(strstr($value, '@'), 1),
                default => '***'
            };
        }

        return $value;
    }

    // PII data export with consent tracking
    public function exportPersonalData(): array
    {
        $this->logDataAccess('export');

        return [
            'personal_information' => [
                'first_name' => $this->first_name,
                'last_name' => $this->last_name,
                'email' => $this->email,
                'phone' => $this->phone,
            ],
            'address_information' => [
                'address' => $this->address,
                'city' => $this->city,
                'state' => $this->state,
                'country' => $this->country,
                'postal_code' => $this->postal_code,
            ],
            'business_information' => [
                'company' => $this->company,
                'support_rep' => $this->supportRep?->full_name,
            ],
            'export_date' => now()->toISOString(),
            'export_user' => auth()->user()?->name,
        ];
    }

    private function logDataAccess(string $action): void
    {
        activity()
            ->performedOn($this)
            ->causedBy(auth()->user())
            ->withProperties(['action' => $action, 'ip' => request()->ip()])
            ->log("Customer data {$action}");
    }
}
```

This is the foundation of comprehensive security documentation. Let me continue building this out with more security implementations.
