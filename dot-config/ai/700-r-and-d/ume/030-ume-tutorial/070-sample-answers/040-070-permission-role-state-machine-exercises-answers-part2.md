# Permission/Role State Machine Exercises - Sample Answers (Part 2)

<link rel="stylesheet" href="../assets/css/styles.css">

> **Related Tutorial Section**: [Phase 3: Teams & Permissions](../050-implementation/040-phase3-teams-permissions/000-index.md)
>
> **Exercise File**: [Permission/Role State Machine Exercises](../060-exercises/040-042-permission-role-state-machine-exercises.md)
>
> **Part 2 of 10**: This is the second part of the Permission/Role State Machine exercises answers. See the [exercise file](../060-exercises/040-042-permission-role-state-machine-exercises.md) for links to all parts.

## Exercise 2: Extending the Role State Machine

### Step 1: Update the RoleStatus enum

```php
<?php

declare(strict_types=1);

namespace App\Enums;

enum RoleStatus: string
{
    case DRAFT = 'draft';
    case ACTIVE = 'active';
    case DISABLED = 'disabled';
    case SUSPENDED = 'suspended';
    case DEPRECATED = 'deprecated';

    /**
     * Get a human-readable label for the status.
     */
    public function getLabel(): string
    {
        return match($this) {
            self::DRAFT => 'Draft',
            self::ACTIVE => 'Active',
            self::DISABLED => 'Disabled',
            self::SUSPENDED => 'Suspended',
            self::DEPRECATED => 'Deprecated',
        };
    }

    /**
     * Get a color for the status (for UI purposes).
     */
    public function getColor(): string
    {
        return match($this) {
            self::DRAFT => 'yellow',
            self::ACTIVE => 'green',
            self::DISABLED => 'red',
            self::SUSPENDED => 'orange',
            self::DEPRECATED => 'gray',
        };
    }

    /**
     * Get an icon for the status (for UI purposes).
     */
    public function getIcon(): string
    {
        return match($this) {
            self::DRAFT => 'pencil',
            self::ACTIVE => 'check-circle',
            self::DISABLED => 'ban',
            self::SUSPENDED => 'exclamation-triangle',
            self::DEPRECATED => 'archive',
        };
    }

    /**
     * Get Tailwind CSS classes for the status.
     */
    public function getTailwindClasses(): string
    {
        return match($this) {
            self::DRAFT => 'bg-yellow-100 text-yellow-800 border-yellow-200',
            self::ACTIVE => 'bg-green-100 text-green-800 border-green-200',
            self::DISABLED => 'bg-red-100 text-red-800 border-red-200',
            self::SUSPENDED => 'bg-orange-100 text-orange-800 border-orange-200',
            self::DEPRECATED => 'bg-gray-100 text-gray-800 border-gray-200',
        };
    }
}
```

### Step 2: Create the Suspended state class

```php
<?php

declare(strict_types=1);

namespace App\States\Role;

use App\Enums\RoleStatus;

/**
 * Represents a role that is suspended due to a security incident.
 */
class Suspended extends RoleState
{
    /**
     * Get the corresponding enum value for this state.
     */
    public static function status(): RoleStatus
    {
        return RoleStatus::SUSPENDED;
    }

    /**
     * Check if the role can be assigned to users.
     */
    public function canBeAssigned(): bool
    {
        return false; // Suspended roles cannot be assigned
    }

    /**
     * Check if the role is visible in the UI.
     */
    public function isVisibleInUI(): bool
    {
        return true; // Suspended roles are visible in the UI (with indicator)
    }

    /**
     * Check if the role's permissions can be modified.
     */
    public function canModifyPermissions(): bool
    {
        return false; // Suspended roles cannot have their permissions modified
    }

    /**
     * Check if the role can be deleted.
     */
    public function canBeDeleted(): bool
    {
        return false; // Suspended roles cannot be deleted
    }
}
```

### Step 3: Update the RoleState configuration

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
        ->allowTransition(Active::class, Suspended::class, Transitions\SuspendRoleTransition::class)
        ->allowTransition(Active::class, Deprecated::class, Transitions\DeprecateRoleTransition::class)
        ->allowTransition(Disabled::class, Active::class, Transitions\EnableRoleTransition::class)
        ->allowTransition(Disabled::class, Deprecated::class, Transitions\DeprecateRoleTransition::class)
        ->allowTransition(Suspended::class, Active::class, Transitions\ReinstateRoleTransition::class)
        ->allowTransition(Suspended::class, Deprecated::class, Transitions\DeprecateRoleTransition::class);
}
```
