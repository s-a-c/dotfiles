# Permission/Role State Transitions

<link rel="stylesheet" href="../../../assets/css/styles.css">

In this section, we'll implement transition classes for the permission and role state machines. Transition classes allow us to encapsulate complex transition logic, perform validation, and trigger side effects when a permission or role changes state.

## Creating Permission Transition Classes

For our permission state machine, we'll create transition classes for the following transitions:

1. **Approve Permission**: Transition from Draft to Active
2. **Disable Permission**: Transition from Active to Disabled
3. **Enable Permission**: Transition from Disabled to Active
4. **Deprecate Permission**: Transition from Active or Disabled to Deprecated

Let's start by creating a directory for our transition classes:

```bash
mkdir -p app/States/Permission/Transitions
```

### 1. Approve Permission Transition

This transition occurs when a draft permission is approved and becomes active:

```bash
touch app/States/Permission/Transitions/ApprovePermissionTransition.php
```

```php
<?php

declare(strict_types=1);

namespace App\States\Permission\Transitions;

use App\Models\UPermission;
use App\Models\User;
use App\States\Permission\Active;
use App\States\Permission\Draft;
use Illuminate\Support\Facades\Log;
use Spatie\ModelStates\Transition;

/**
 * Transition from Draft to Active when a permission is approved.
 */
class ApprovePermissionTransition extends Transition
{
    /**
     * Constructor.
     */
    public function __construct(
        private ?User $approvedBy = null,
        private ?string $notes = null
    ) {}

    /**
     * Handle the transition.
     */
    public function handle(UPermission $permission, Draft $currentState): Active
    {
        // Log the transition
        Log::info("Permission {$permission->id} ({$permission->name}) was approved by " . 
            ($this->approvedBy ? "User {$this->approvedBy->id}" : "system") . 
            ($this->notes ? " with notes: {$this->notes}" : ""));

        // Record the approval in activity log
        activity()
            ->performedOn($permission)
            ->causedBy($this->approvedBy ?? auth()->user())
            ->withProperties([
                'notes' => $this->notes,
                'from_state' => 'draft',
                'to_state' => 'active',
            ])
            ->log('permission_approved');

        // Return the new state
        return new Active($permission);
    }
}
```

### 2. Disable Permission Transition

This transition occurs when an active permission is disabled:

```bash
touch app/States/Permission/Transitions/DisablePermissionTransition.php
```

```php
<?php

declare(strict_types=1);

namespace App\States\Permission\Transitions;

use App\Models\UPermission;
use App\Models\User;
use App\States\Permission\Active;
use App\States\Permission\Disabled;
use Illuminate\Support\Facades\Log;
use Spatie\ModelStates\Transition;

/**
 * Transition from Active to Disabled when a permission is disabled.
 */
class DisablePermissionTransition extends Transition
{
    /**
     * Constructor.
     */
    public function __construct(
        private ?User $disabledBy = null,
        private string $reason,
        private ?string $notes = null
    ) {}

    /**
     * Handle the transition.
     */
    public function handle(UPermission $permission, Active $currentState): Disabled
    {
        // Log the transition
        Log::info("Permission {$permission->id} ({$permission->name}) was disabled by " . 
            ($this->disabledBy ? "User {$this->disabledBy->id}" : "system") . 
            " for reason: {$this->reason}" .
            ($this->notes ? " with notes: {$this->notes}" : ""));

        // Record the disabling in activity log
        activity()
            ->performedOn($permission)
            ->causedBy($this->disabledBy ?? auth()->user())
            ->withProperties([
                'reason' => $this->reason,
                'notes' => $this->notes,
                'from_state' => 'active',
                'to_state' => 'disabled',
            ])
            ->log('permission_disabled');

        // Return the new state
        return new Disabled($permission);
    }
}
```

### 3. Enable Permission Transition

This transition occurs when a disabled permission is re-enabled:

```bash
touch app/States/Permission/Transitions/EnablePermissionTransition.php
```

```php
<?php

declare(strict_types=1);

namespace App\States\Permission\Transitions;

use App\Models\UPermission;
use App\Models\User;
use App\States\Permission\Active;
use App\States\Permission\Disabled;
use Illuminate\Support\Facades\Log;
use Spatie\ModelStates\Transition;

/**
 * Transition from Disabled to Active when a permission is re-enabled.
 */
class EnablePermissionTransition extends Transition
{
    /**
     * Constructor.
     */
    public function __construct(
        private ?User $enabledBy = null,
        private ?string $notes = null
    ) {}

    /**
     * Handle the transition.
     */
    public function handle(UPermission $permission, Disabled $currentState): Active
    {
        // Log the transition
        Log::info("Permission {$permission->id} ({$permission->name}) was re-enabled by " . 
            ($this->enabledBy ? "User {$this->enabledBy->id}" : "system") . 
            ($this->notes ? " with notes: {$this->notes}" : ""));

        // Record the re-enabling in activity log
        activity()
            ->performedOn($permission)
            ->causedBy($this->enabledBy ?? auth()->user())
            ->withProperties([
                'notes' => $this->notes,
                'from_state' => 'disabled',
                'to_state' => 'active',
            ])
            ->log('permission_enabled');

        // Return the new state
        return new Active($permission);
    }
}
```

### 4. Deprecate Permission Transition

This transition occurs when an active or disabled permission is deprecated:

```bash
touch app/States/Permission/Transitions/DeprecatePermissionTransition.php
```

```php
<?php

declare(strict_types=1);

namespace App\States\Permission\Transitions;

use App\Models\UPermission;
use App\Models\User;
use App\States\Permission\Active;
use App\States\Permission\Deprecated;
use App\States\Permission\Disabled;
use App\States\Permission\PermissionState;
use Illuminate\Support\Facades\Log;
use Spatie\ModelStates\Transition;

/**
 * Transition to Deprecated state when a permission is deprecated.
 */
class DeprecatePermissionTransition extends Transition
{
    /**
     * Constructor.
     */
    public function __construct(
        private ?User $deprecatedBy = null,
        private ?string $reason = null,
        private ?string $notes = null
    ) {}

    /**
     * Handle the transition.
     */
    public function handle(UPermission $permission, PermissionState $currentState): Deprecated
    {
        // Determine the previous state
        $fromState = $currentState instanceof Active ? 'active' : 'disabled';

        // Log the transition
        Log::info("Permission {$permission->id} ({$permission->name}) was deprecated by " . 
            ($this->deprecatedBy ? "User {$this->deprecatedBy->id}" : "system") . 
            ($this->reason ? " for reason: {$this->reason}" : "") .
            ($this->notes ? " with notes: {$this->notes}" : ""));

        // Record the deprecation in activity log
        activity()
            ->performedOn($permission)
            ->causedBy($this->deprecatedBy ?? auth()->user())
            ->withProperties([
                'reason' => $this->reason,
                'notes' => $this->notes,
                'from_state' => $fromState,
                'to_state' => 'deprecated',
            ])
            ->log('permission_deprecated');

        // Return the new state
        return new Deprecated($permission);
    }
}
```

## Creating Role Transition Classes

For our role state machine, we'll create transition classes for the following transitions:

1. **Approve Role**: Transition from Draft to Active
2. **Disable Role**: Transition from Active to Disabled
3. **Enable Role**: Transition from Disabled to Active
4. **Deprecate Role**: Transition from Active or Disabled to Deprecated

Let's start by creating a directory for our transition classes:

```bash
mkdir -p app/States/Role/Transitions
```

### 1. Approve Role Transition

This transition occurs when a draft role is approved and becomes active:

```bash
touch app/States/Role/Transitions/ApproveRoleTransition.php
```

```php
<?php

declare(strict_types=1);

namespace App\States\Role\Transitions;

use App\Models\URole;
use App\Models\User;
use App\States\Role\Active;
use App\States\Role\Draft;
use Illuminate\Support\Facades\Log;
use Spatie\ModelStates\Transition;

/**
 * Transition from Draft to Active when a role is approved.
 */
class ApproveRoleTransition extends Transition
{
    /**
     * Constructor.
     */
    public function __construct(
        private ?User $approvedBy = null,
        private ?string $notes = null
    ) {}

    /**
     * Handle the transition.
     */
    public function handle(URole $role, Draft $currentState): Active
    {
        // Log the transition
        Log::info("Role {$role->id} ({$role->name}) was approved by " . 
            ($this->approvedBy ? "User {$this->approvedBy->id}" : "system") . 
            ($this->notes ? " with notes: {$this->notes}" : ""));

        // Record the approval in activity log
        activity()
            ->performedOn($role)
            ->causedBy($this->approvedBy ?? auth()->user())
            ->withProperties([
                'notes' => $this->notes,
                'from_state' => 'draft',
                'to_state' => 'active',
            ])
            ->log('role_approved');

        // Return the new state
        return new Active($role);
    }
}
```

### 2. Disable Role Transition

This transition occurs when an active role is disabled:

```bash
touch app/States/Role/Transitions/DisableRoleTransition.php
```

```php
<?php

declare(strict_types=1);

namespace App\States\Role\Transitions;

use App\Models\URole;
use App\Models\User;
use App\States\Role\Active;
use App\States\Role\Disabled;
use Illuminate\Support\Facades\Log;
use Spatie\ModelStates\Transition;

/**
 * Transition from Active to Disabled when a role is disabled.
 */
class DisableRoleTransition extends Transition
{
    /**
     * Constructor.
     */
    public function __construct(
        private ?User $disabledBy = null,
        private string $reason,
        private ?string $notes = null
    ) {}

    /**
     * Handle the transition.
     */
    public function handle(URole $role, Active $currentState): Disabled
    {
        // Log the transition
        Log::info("Role {$role->id} ({$role->name}) was disabled by " . 
            ($this->disabledBy ? "User {$this->disabledBy->id}" : "system") . 
            " for reason: {$this->reason}" .
            ($this->notes ? " with notes: {$this->notes}" : ""));

        // Record the disabling in activity log
        activity()
            ->performedOn($role)
            ->causedBy($this->disabledBy ?? auth()->user())
            ->withProperties([
                'reason' => $this->reason,
                'notes' => $this->notes,
                'from_state' => 'active',
                'to_state' => 'disabled',
            ])
            ->log('role_disabled');

        // Return the new state
        return new Disabled($role);
    }
}
```

### 3. Enable Role Transition

This transition occurs when a disabled role is re-enabled:

```bash
touch app/States/Role/Transitions/EnableRoleTransition.php
```

```php
<?php

declare(strict_types=1);

namespace App\States\Role\Transitions;

use App\Models\URole;
use App\Models\User;
use App\States\Role\Active;
use App\States\Role\Disabled;
use Illuminate\Support\Facades\Log;
use Spatie\ModelStates\Transition;

/**
 * Transition from Disabled to Active when a role is re-enabled.
 */
class EnableRoleTransition extends Transition
{
    /**
     * Constructor.
     */
    public function __construct(
        private ?User $enabledBy = null,
        private ?string $notes = null
    ) {}

    /**
     * Handle the transition.
     */
    public function handle(URole $role, Disabled $currentState): Active
    {
        // Log the transition
        Log::info("Role {$role->id} ({$role->name}) was re-enabled by " . 
            ($this->enabledBy ? "User {$this->enabledBy->id}" : "system") . 
            ($this->notes ? " with notes: {$this->notes}" : ""));

        // Record the re-enabling in activity log
        activity()
            ->performedOn($role)
            ->causedBy($this->enabledBy ?? auth()->user())
            ->withProperties([
                'notes' => $this->notes,
                'from_state' => 'disabled',
                'to_state' => 'active',
            ])
            ->log('role_enabled');

        // Return the new state
        return new Active($role);
    }
}
```

### 4. Deprecate Role Transition

This transition occurs when an active or disabled role is deprecated:

```bash
touch app/States/Role/Transitions/DeprecateRoleTransition.php
```

```php
<?php

declare(strict_types=1);

namespace App\States\Role\Transitions;

use App\Models\URole;
use App\Models\User;
use App\States\Role\Active;
use App\States\Role\Deprecated;
use App\States\Role\Disabled;
use App\States\Role\RoleState;
use Illuminate\Support\Facades\Log;
use Spatie\ModelStates\Transition;

/**
 * Transition to Deprecated state when a role is deprecated.
 */
class DeprecateRoleTransition extends Transition
{
    /**
     * Constructor.
     */
    public function __construct(
        private ?User $deprecatedBy = null,
        private ?string $reason = null,
        private ?string $notes = null
    ) {}

    /**
     * Handle the transition.
     */
    public function handle(URole $role, RoleState $currentState): Deprecated
    {
        // Determine the previous state
        $fromState = $currentState instanceof Active ? 'active' : 'disabled';

        // Log the transition
        Log::info("Role {$role->id} ({$role->name}) was deprecated by " . 
            ($this->deprecatedBy ? "User {$this->deprecatedBy->id}" : "system") . 
            ($this->reason ? " for reason: {$this->reason}" : "") .
            ($this->notes ? " with notes: {$this->notes}" : ""));

        // Record the deprecation in activity log
        activity()
            ->performedOn($role)
            ->causedBy($this->deprecatedBy ?? auth()->user())
            ->withProperties([
                'reason' => $this->reason,
                'notes' => $this->notes,
                'from_state' => $fromState,
                'to_state' => 'deprecated',
            ])
            ->log('role_deprecated');

        // Return the new state
        return new Deprecated($role);
    }
}
```

## Updating the State Configurations

Now that we've created our transition classes, let's update the `PermissionState` and `RoleState` configurations to use them:

### Updating PermissionState Configuration

```php
/**
 * Configure the state machine.
 */
public static function config(): StateConfig
{
    return parent::config()
        ->default(Draft::class) // Default state for new permissions
        ->allowTransition(Draft::class, Active::class, Transitions\ApprovePermissionTransition::class)
        ->allowTransition(Active::class, Disabled::class, Transitions\DisablePermissionTransition::class)
        ->allowTransition(Active::class, Deprecated::class, Transitions\DeprecatePermissionTransition::class)
        ->allowTransition(Disabled::class, Active::class, Transitions\EnablePermissionTransition::class)
        ->allowTransition(Disabled::class, Deprecated::class, Transitions\DeprecatePermissionTransition::class);
}
```

### Updating RoleState Configuration

```php
/**
 * Configure the state machine.
 */
public static function config(): StateConfig
{
    return parent::config()
        ->default(Draft::class) // Default state for new roles
        ->allowTransition(Draft::class, Active::class, Transitions\ApproveRoleTransition::class)
        ->allowTransition(Active::class, Disabled::class, Transitions\DisableRoleTransition::class)
        ->allowTransition(Active::class, Deprecated::class, Transitions\DeprecateRoleTransition::class)
        ->allowTransition(Disabled::class, Active::class, Transitions\EnableRoleTransition::class)
        ->allowTransition(Disabled::class, Deprecated::class, Transitions\DeprecateRoleTransition::class);
}
```

## Using the Transition Classes

Here's how to use these transition classes in your application:

### Permission Transitions

```php
// Approve a draft permission
$permission = UPermission::find(1);
if ($permission->status instanceof \App\States\Permission\Draft) {
    $permission->status->transition(new \App\States\Permission\Transitions\ApprovePermissionTransition(
        auth()->user(),
        'Permission meets all requirements'
    ));
    $permission->save();
}

// Disable an active permission
$permission = UPermission::find(2);
if ($permission->status instanceof \App\States\Permission\Active) {
    $permission->status->transition(new \App\States\Permission\Transitions\DisablePermissionTransition(
        auth()->user(),
        'Security concerns',
        'Temporarily disabled due to potential security issue'
    ));
    $permission->save();
}

// Re-enable a disabled permission
$permission = UPermission::find(3);
if ($permission->status instanceof \App\States\Permission\Disabled) {
    $permission->status->transition(new \App\States\Permission\Transitions\EnablePermissionTransition(
        auth()->user(),
        'Security issue resolved'
    ));
    $permission->save();
}

// Deprecate a permission
$permission = UPermission::find(4);
if (!($permission->status instanceof \App\States\Permission\Deprecated)) {
    $permission->status->transition(new \App\States\Permission\Transitions\DeprecatePermissionTransition(
        auth()->user(),
        'Permission no longer needed',
        'Replaced by new permission structure'
    ));
    $permission->save();
}
```

### Role Transitions

```php
// Approve a draft role
$role = URole::find(1);
if ($role->status instanceof \App\States\Role\Draft) {
    $role->status->transition(new \App\States\Role\Transitions\ApproveRoleTransition(
        auth()->user(),
        'Role meets all requirements'
    ));
    $role->save();
}

// Disable an active role
$role = URole::find(2);
if ($role->status instanceof \App\States\Role\Active) {
    $role->status->transition(new \App\States\Role\Transitions\DisableRoleTransition(
        auth()->user(),
        'Organizational restructuring',
        'Temporarily disabled during department reorganization'
    ));
    $role->save();
}

// Re-enable a disabled role
$role = URole::find(3);
if ($role->status instanceof \App\States\Role\Disabled) {
    $role->status->transition(new \App\States\Role\Transitions\EnableRoleTransition(
        auth()->user(),
        'Reorganization complete'
    ));
    $role->save();
}

// Deprecate a role
$role = URole::find(4);
if (!($role->status instanceof \App\States\Role\Deprecated)) {
    $role->status->transition(new \App\States\Role\Transitions\DeprecateRoleTransition(
        auth()->user(),
        'Role no longer needed',
        'Replaced by new role structure'
    ));
    $role->save();
}
```

## Handling Invalid Transitions

If you try to make an invalid transition, the package will throw a `Spatie\ModelStates\Exceptions\TransitionNotFound` exception. You should handle this in your application:

```php
try {
    // This will throw an exception if the permission is not in the correct state
    $permission->status->transition(new \App\States\Permission\Transitions\DisablePermissionTransition(
        auth()->user(),
        'Security concerns'
    ));
    $permission->save();
} catch (\Spatie\ModelStates\Exceptions\TransitionNotFound $e) {
    // Handle the exception
    return back()->with('error', 'Cannot disable the permission in its current state.');
}
```

## Next Steps

Now that we've implemented the transition classes for our permission and role state machines, let's move on to integrating the state machines with our application in the [next section](./023-permission-role-state-integration.md).

## Additional Resources

- [Spatie Laravel Model States Documentation](https://spatie.be/docs/laravel-model-states/v2/introduction)
- [Laravel Activity Log Documentation](https://spatie.be/docs/laravel-activitylog/v4/introduction)
- [Laravel Logging Documentation](https://laravel.com/docs/12.x/logging)
