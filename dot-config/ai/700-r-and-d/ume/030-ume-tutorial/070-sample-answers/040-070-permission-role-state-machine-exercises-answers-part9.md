# Permission/Role State Machine Exercises - Sample Answers (Part 9)

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Exercise 5: Creating a Permission Approval Workflow (continued)

### Step 2: Create the additional state classes

```php
<?php

declare(strict_types=1);

namespace App\States\Permission;

use App\Enums\PermissionStatus;

/**
 * Represents a permission that is pending first approval.
 */
class PendingFirstApproval extends PermissionState
{
    /**
     * Get the corresponding enum value for this state.
     */
    public static function status(): PermissionStatus
    {
        return PermissionStatus::PENDING_FIRST_APPROVAL;
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

```php
<?php

declare(strict_types=1);

namespace App\States\Permission;

use App\Enums\PermissionStatus;

/**
 * Represents a permission that is pending second approval.
 */
class PendingSecondApproval extends PermissionState
{
    /**
     * Get the corresponding enum value for this state.
     */
    public static function status(): PermissionStatus
    {
        return PermissionStatus::PENDING_SECOND_APPROVAL;
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

### Step 3: Update the PermissionState configuration

```php
/**
 * Configure the state machine.
 */
public static function config(): StateConfig
{
    return parent::config()
        ->default(Draft::class) // Default state for new permissions
        ->allowTransition(Draft::class, PendingFirstApproval::class, Transitions\SubmitForFirstApprovalTransition::class)
        ->allowTransition(PendingFirstApproval::class, Draft::class, Transitions\RejectFirstApprovalTransition::class)
        ->allowTransition(PendingFirstApproval::class, PendingSecondApproval::class, Transitions\ApproveFirstLevelTransition::class)
        ->allowTransition(PendingSecondApproval::class, PendingFirstApproval::class, Transitions\RejectSecondApprovalTransition::class)
        ->allowTransition(PendingSecondApproval::class, Active::class, Transitions\ApproveSecondLevelTransition::class)
        ->allowTransition(Active::class, Disabled::class, Transitions\DisablePermissionTransition::class)
        ->allowTransition(Active::class, Deprecated::class, Transitions\DeprecatePermissionTransition::class)
        ->allowTransition(Disabled::class, Active::class, Transitions\EnablePermissionTransition::class)
        ->allowTransition(Disabled::class, Deprecated::class, Transitions\DeprecatePermissionTransition::class);
}
```

### Step 4: Create the transition classes for the approval workflow

```php
<?php

declare(strict_types=1);

namespace App\States\Permission\Transitions;

use App\Models\UPermission;
use App\Models\User;
use App\Notifications\PermissionSubmittedForApproval;
use App\States\Permission\Draft;
use App\States\Permission\PendingFirstApproval;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Notification;
use Spatie\ModelStates\Transition;

/**
 * Transition from Draft to PendingFirstApproval when a permission is submitted for first approval.
 */
class SubmitForFirstApprovalTransition extends Transition
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
    public function handle(UPermission $permission, Draft $currentState): PendingFirstApproval
    {
        // Log the transition
        Log::info("Permission {$permission->id} ({$permission->name}) was submitted for first approval by " . 
            ($this->submittedBy ? "User {$this->submittedBy->id}" : "system") . 
            ($this->notes ? " with notes: {$this->notes}" : ""));

        // Record the submission in activity log
        activity()
            ->performedOn($permission)
            ->causedBy($this->submittedBy ?? auth()->user())
            ->withProperties([
                'notes' => $this->notes,
                'from_state' => 'draft',
                'to_state' => 'pending_first_approval',
            ])
            ->log('permission_submitted_for_first_approval');

        // Notify first-level approvers
        $firstLevelApprovers = User::permission('approve-permissions-first-level')->get();
        Notification::send($firstLevelApprovers, new PermissionSubmittedForApproval($permission, 'first'));

        // Return the new state
        return new PendingFirstApproval($permission);
    }
}
```
