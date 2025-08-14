# Permission/Role State Machine Exercises - Sample Answers

<link rel="stylesheet" href="../assets/css/styles.css">

> **Related Tutorial Section**: [Phase 3: Teams & Permissions](../050-implementation/040-phase3-teams-permissions/000-index.md)
>
> **Exercise File**: [Permission/Role State Machine Exercises](../060-exercises/040-042-permission-role-state-machine-exercises.md)
>
> **Main File**: This is the main file of the Permission/Role State Machine exercises answers. See the [exercise file](../060-exercises/040-042-permission-role-state-machine-exercises.md) for links to all parts.

## Exercise 1: Implementing a Custom Permission State

### Step 1: Create the PendingApproval state class

```php
<?php

declare(strict_types=1);

namespace App\States\Permission;

use App\Enums\PermissionStatus;

/**
 * Represents a permission that is pending approval.
 */
class PendingApproval extends PermissionState
{
    /**
     * Get the corresponding enum value for this state.
     */
    public static function status(): PermissionStatus
    {
        return PermissionStatus::PENDING_APPROVAL;
    }

    /**
     * Check if the permission can be assigned to roles.
     */
    public function canBeAssigned(): bool
    {
        return false; // Pending permissions cannot be assigned
    }

    /**
     * Check if the permission is visible in the UI.
     */
    public function isVisibleInUI(): bool
    {
        return false; // Pending permissions are only visible to approvers
    }

    /**
     * Check if the permission can be modified.
     */
    public function canBeModified(): bool
    {
        return true; // Pending permissions can be modified
    }

    /**
     * Check if the permission can be deleted.
     */
    public function canBeDeleted(): bool
    {
        return true; // Pending permissions can be deleted
    }
}
```

### Step 2: Update the PermissionStatus enum

```php
<?php

declare(strict_types=1);

namespace App\Enums;

enum PermissionStatus: string
{
    case DRAFT = 'draft';
    case PENDING_APPROVAL = 'pending_approval';
    case ACTIVE = 'active';
    case DISABLED = 'disabled';
    case DEPRECATED = 'deprecated';

    /**
     * Get a human-readable label for the status.
     */
    public function getLabel(): string
    {
        return match($this) {
            self::DRAFT => 'Draft',
            self::PENDING_APPROVAL => 'Pending Approval',
            self::ACTIVE => 'Active',
            self::DISABLED => 'Disabled',
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
            self::PENDING_APPROVAL => 'blue',
            self::ACTIVE => 'green',
            self::DISABLED => 'red',
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
            self::PENDING_APPROVAL => 'clock',
            self::ACTIVE => 'check-circle',
            self::DISABLED => 'ban',
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
            self::PENDING_APPROVAL => 'bg-blue-100 text-blue-800 border-blue-200',
            self::ACTIVE => 'bg-green-100 text-green-800 border-green-200',
            self::DISABLED => 'bg-red-100 text-red-800 border-red-200',
            self::DEPRECATED => 'bg-gray-100 text-gray-800 border-gray-200',
        };
    }
}
```

### Step 3: Update the PermissionState configuration

```php
/**
 * Configure the state machine.
 */
public static function config(): StateConfig
{
    return parent::config()
        ->default(Draft::class) // Default state for new permissions
        ->allowTransition(Draft::class, PendingApproval::class, Transitions\SubmitPermissionTransition::class)
        ->allowTransition(PendingApproval::class, Active::class, Transitions\ApprovePermissionTransition::class)
        ->allowTransition(PendingApproval::class, Draft::class, Transitions\RejectPermissionTransition::class)
        ->allowTransition(Active::class, Disabled::class, Transitions\DisablePermissionTransition::class)
        ->allowTransition(Active::class, Deprecated::class, Transitions\DeprecatePermissionTransition::class)
        ->allowTransition(Disabled::class, Active::class, Transitions\EnablePermissionTransition::class)
        ->allowTransition(Disabled::class, Deprecated::class, Transitions\DeprecatePermissionTransition::class);
}
```

### Step 4: Create the SubmitPermissionTransition class

```php
<?php

declare(strict_types=1);

namespace App\States\Permission\Transitions;

use App\Models\UPermission;
use App\Models\User;
use App\States\Permission\Draft;
use App\States\Permission\PendingApproval;
use Illuminate\Support\Facades\Log;
use Spatie\ModelStates\Transition;

/**
 * Transition from Draft to PendingApproval when a permission is submitted for approval.
 */
class SubmitPermissionTransition extends Transition
{
    /**
     * Constructor.
     */
    public function __construct(
        private ?User $submittedBy = null,
        private ?string $notes = null
    ) {}

    /**
     * Handle the transition.
     */
    public function handle(UPermission $permission, Draft $currentState): PendingApproval
    {
        // Log the transition
        Log::info("Permission {$permission->id} ({$permission->name}) was submitted for approval by " .
            ($this->submittedBy ? "User {$this->submittedBy->id}" : "system") .
            ($this->notes ? " with notes: {$this->notes}" : ""));

        // Record the submission in activity log
        activity()
            ->performedOn($permission)
            ->causedBy($this->submittedBy ?? auth()->user())
            ->withProperties([
                'notes' => $this->notes,
                'from_state' => 'draft',
                'to_state' => 'pending_approval',
            ])
            ->log('permission_submitted');

        // Notify approvers
        // ... notification logic here ...

        // Return the new state
        return new PendingApproval($permission);
    }
}
```
