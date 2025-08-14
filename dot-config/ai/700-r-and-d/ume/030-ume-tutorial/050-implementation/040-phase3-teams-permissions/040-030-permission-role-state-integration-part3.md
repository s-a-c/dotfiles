# Permission/Role State Integration (Part 3)

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Creating Middleware for Permission and Role State Checking

Let's create middleware to check if permissions and roles are in the correct state:

```bash
php artisan make:middleware CheckPermissionState
php artisan make:middleware CheckRoleState
```

### Permission State Middleware

```php
<?php

namespace App\Http\Middleware;

use App\Models\UPermission;
use App\States\Permission\Active;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckPermissionState
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $permissionName = $request->route('permission_name');
        
        if ($permissionName) {
            $permission = UPermission::where('name', $permissionName)->first();
            
            if (!$permission || !($permission->status instanceof Active)) {
                abort(403, 'The requested permission is not active.');
            }
        }
        
        return $next($request);
    }
}
```

### Role State Middleware

```php
<?php

namespace App\Http\Middleware;

use App\Models\URole;
use App\States\Role\Active;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckRoleState
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $roleName = $request->route('role_name');
        
        if ($roleName) {
            $role = URole::where('name', $roleName)->first();
            
            if (!$role || !($role->status instanceof Active)) {
                abort(403, 'The requested role is not active.');
            }
        }
        
        return $next($request);
    }
}
```

## Registering the Middleware

Register the middleware in the `app/Http/Kernel.php` file:

```php
protected $routeMiddleware = [
    // ... other middleware
    'permission.state' => \App\Http\Middleware\CheckPermissionState::class,
    'role.state' => \App\Http\Middleware\CheckRoleState::class,
];
```

## Creating Routes for Permission and Role Management

Add the following routes to your `routes/web.php` file:

```php
Route::middleware(['auth', 'can:manage-permissions'])->prefix('admin')->name('admin.')->group(function () {
    // Permission routes
    Route::resource('permissions', \App\Http\Controllers\Admin\PermissionController::class);
    Route::post('permissions/{permission}/approve', [\App\Http\Controllers\Admin\PermissionController::class, 'approve'])->name('permissions.approve');
    Route::post('permissions/{permission}/disable', [\App\Http\Controllers\Admin\PermissionController::class, 'disable'])->name('permissions.disable');
    Route::post('permissions/{permission}/enable', [\App\Http\Controllers\Admin\PermissionController::class, 'enable'])->name('permissions.enable');
    Route::post('permissions/{permission}/deprecate', [\App\Http\Controllers\Admin\PermissionController::class, 'deprecate'])->name('permissions.deprecate');
    
    // Role routes
    Route::resource('roles', \App\Http\Controllers\Admin\RoleController::class);
    Route::post('roles/{role}/approve', [\App\Http\Controllers\Admin\RoleController::class, 'approve'])->name('roles.approve');
    Route::post('roles/{role}/disable', [\App\Http\Controllers\Admin\RoleController::class, 'disable'])->name('roles.disable');
    Route::post('roles/{role}/enable', [\App\Http\Controllers\Admin\RoleController::class, 'enable'])->name('roles.enable');
    Route::post('roles/{role}/deprecate', [\App\Http\Controllers\Admin\RoleController::class, 'deprecate'])->name('roles.deprecate');
});
```

## Creating Policies for Permission and Role Management

Let's create policies to control who can manage permissions and roles:

```bash
php artisan make:policy PermissionPolicy --model=UPermission
php artisan make:policy RolePolicy --model=URole
```

### Permission Policy

```php
<?php

namespace App\Policies;

use App\Models\UPermission;
use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

class PermissionPolicy
{
    use HandlesAuthorization;

    /**
     * Determine whether the user can view any models.
     */
    public function viewAny(User $user): bool
    {
        return $user->hasPermissionTo('manage-permissions');
    }

    /**
     * Determine whether the user can view the model.
     */
    public function view(User $user, UPermission $permission): bool
    {
        if ($user->hasPermissionTo('manage-permissions')) {
            return true;
        }

        return $permission->isVisibleInUI();
    }

    /**
     * Determine whether the user can create models.
     */
    public function create(User $user): bool
    {
        return $user->hasPermissionTo('manage-permissions');
    }

    /**
     * Determine whether the user can update the model.
     */
    public function update(User $user, UPermission $permission): bool
    {
        return $user->hasPermissionTo('manage-permissions') && $permission->canBeModified();
    }

    /**
     * Determine whether the user can delete the model.
     */
    public function delete(User $user, UPermission $permission): bool
    {
        return $user->hasPermissionTo('manage-permissions') && $permission->canBeDeleted();
    }

    /**
     * Determine whether the user can approve the permission.
     */
    public function approve(User $user, UPermission $permission): bool
    {
        return $user->hasPermissionTo('manage-permissions');
    }

    /**
     * Determine whether the user can disable the permission.
     */
    public function disable(User $user, UPermission $permission): bool
    {
        return $user->hasPermissionTo('manage-permissions');
    }

    /**
     * Determine whether the user can enable the permission.
     */
    public function enable(User $user, UPermission $permission): bool
    {
        return $user->hasPermissionTo('manage-permissions');
    }

    /**
     * Determine whether the user can deprecate the permission.
     */
    public function deprecate(User $user, UPermission $permission): bool
    {
        return $user->hasPermissionTo('manage-permissions');
    }
}
```
