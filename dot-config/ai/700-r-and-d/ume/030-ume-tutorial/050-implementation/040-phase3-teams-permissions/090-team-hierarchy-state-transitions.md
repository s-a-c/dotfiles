# Team Hierarchy State Transitions

<link rel="stylesheet" href="../../../assets/css/styles.css">

In this section, we'll implement transition classes for the team hierarchy state machine. Transition classes allow us to encapsulate complex transition logic, perform validation, and trigger side effects when a team changes state.

## Creating Transition Classes

For our team hierarchy state machine, we'll create transition classes for the following transitions:

1. **Approve Team**: Transition from Pending to Active
2. **Suspend Team**: Transition from Active to Suspended
3. **Reactivate Team**: Transition from Suspended to Active
4. **Archive Team**: Transition from Active or Suspended to Archived
5. **Restore Team**: Transition from Archived to Active

Let's start by creating a directory for our transition classes:

```bash
mkdir -p app/States/Team/Transitions
```

### 1. Approve Team Transition

This transition occurs when a pending team is approved and becomes active:

```bash
touch app/States/Team/Transitions/ApproveTeamTransition.php
```

```php
<?php

declare(strict_types=1);

namespace App\States\Team\Transitions;

use App\Models\Team;
use App\Models\User;
use App\States\Team\Active;
use App\States\Team\Pending;
use Illuminate\Support\Facades\Log;
use Spatie\ModelStates\Transition;

/**
 * Transition from Pending to Active when a team is approved.
 */
class ApproveTeamTransition extends Transition
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
    public function handle(Team $team, Pending $currentState): Active
    {
        // Log the transition
        Log::info("Team {$team->id} ({$team->name}) was approved by " . 
            ($this->approvedBy ? "User {$this->approvedBy->id}" : "system") . 
            ($this->notes ? " with notes: {$this->notes}" : ""));

        // You could add additional logic here, such as:
        // - Sending notifications to team owner
        // - Creating default resources for the team
        // - Setting up default permissions

        // Record the approval in activity log
        activity()
            ->performedOn($team)
            ->causedBy($this->approvedBy ?? auth()->user())
            ->withProperties([
                'notes' => $this->notes,
                'from_state' => 'pending',
                'to_state' => 'active',
            ])
            ->log('team_approved');

        // Return the new state
        return new Active($team);
    }
}
```

### 2. Suspend Team Transition

This transition occurs when an active team is suspended:

```bash
touch app/States/Team/Transitions/SuspendTeamTransition.php
```

```php
<?php

declare(strict_types=1);

namespace App\States\Team\Transitions;

use App\Models\Team;
use App\Models\User;
use App\States\Team\Active;
use App\States\Team\Suspended;
use Illuminate\Support\Facades\Log;
use Spatie\ModelStates\Transition;

/**
 * Transition from Active to Suspended when a team is suspended.
 */
class SuspendTeamTransition extends Transition
{
    /**
     * Constructor.
     */
    public function __construct(
        private ?User $suspendedBy = null,
        private string $reason,
        private ?string $notes = null,
        private bool $cascadeToChildren = false
    ) {}

    /**
     * Handle the transition.
     */
    public function handle(Team $team, Active $currentState): Suspended
    {
        // Log the transition
        Log::info("Team {$team->id} ({$team->name}) was suspended by " . 
            ($this->suspendedBy ? "User {$this->suspendedBy->id}" : "system") . 
            " for reason: {$this->reason}" .
            ($this->notes ? " with notes: {$this->notes}" : ""));

        // Record the suspension in activity log
        activity()
            ->performedOn($team)
            ->causedBy($this->suspendedBy ?? auth()->user())
            ->withProperties([
                'reason' => $this->reason,
                'notes' => $this->notes,
                'from_state' => 'active',
                'to_state' => 'suspended',
                'cascade_to_children' => $this->cascadeToChildren,
            ])
            ->log('team_suspended');

        // Optionally cascade the suspension to child teams
        if ($this->cascadeToChildren && $team->children()->count() > 0) {
            foreach ($team->children as $childTeam) {
                if ($childTeam->hierarchy_state instanceof Active) {
                    $childTeam->hierarchy_state->transition(new self(
                        $this->suspendedBy,
                        "Parent team {$team->name} was suspended: {$this->reason}",
                        $this->notes,
                        true // Continue cascading
                    ));
                    $childTeam->save();
                }
            }
        }

        // Return the new state
        return new Suspended($team);
    }
}
```

### 3. Reactivate Team Transition

This transition occurs when a suspended team is reactivated:

```bash
touch app/States/Team/Transitions/ReactivateTeamTransition.php
```

```php
<?php

declare(strict_types=1);

namespace App\States\Team\Transitions;

use App\Models\Team;
use App\Models\User;
use App\States\Team\Active;
use App\States\Team\Suspended;
use Illuminate\Support\Facades\Log;
use Spatie\ModelStates\Transition;

/**
 * Transition from Suspended to Active when a team is reactivated.
 */
class ReactivateTeamTransition extends Transition
{
    /**
     * Constructor.
     */
    public function __construct(
        private ?User $reactivatedBy = null,
        private ?string $notes = null,
        private bool $cascadeToChildren = false
    ) {}

    /**
     * Handle the transition.
     */
    public function handle(Team $team, Suspended $currentState): Active
    {
        // Log the transition
        Log::info("Team {$team->id} ({$team->name}) was reactivated by " . 
            ($this->reactivatedBy ? "User {$this->reactivatedBy->id}" : "system") . 
            ($this->notes ? " with notes: {$this->notes}" : ""));

        // Record the reactivation in activity log
        activity()
            ->performedOn($team)
            ->causedBy($this->reactivatedBy ?? auth()->user())
            ->withProperties([
                'notes' => $this->notes,
                'from_state' => 'suspended',
                'to_state' => 'active',
                'cascade_to_children' => $this->cascadeToChildren,
            ])
            ->log('team_reactivated');

        // Optionally cascade the reactivation to child teams
        if ($this->cascadeToChildren && $team->children()->count() > 0) {
            foreach ($team->children as $childTeam) {
                if ($childTeam->hierarchy_state instanceof Suspended) {
                    $childTeam->hierarchy_state->transition(new self(
                        $this->reactivatedBy,
                        "Parent team {$team->name} was reactivated",
                        true // Continue cascading
                    ));
                    $childTeam->save();
                }
            }
        }

        // Return the new state
        return new Active($team);
    }
}
```

### 4. Archive Team Transition

This transition occurs when an active or suspended team is archived:

```bash
touch app/States/Team/Transitions/ArchiveTeamTransition.php
```

```php
<?php

declare(strict_types=1);

namespace App\States\Team\Transitions;

use App\Models\Team;
use App\Models\User;
use App\States\Team\Active;
use App\States\Team\Archived;
use App\States\Team\Suspended;
use App\States\Team\TeamHierarchyState;
use Illuminate\Support\Facades\Log;
use Spatie\ModelStates\Transition;

/**
 * Transition to Archived state when a team is archived.
 */
class ArchiveTeamTransition extends Transition
{
    /**
     * Constructor.
     */
    public function __construct(
        private ?User $archivedBy = null,
        private ?string $reason = null,
        private ?string $notes = null,
        private bool $cascadeToChildren = false
    ) {}

    /**
     * Handle the transition.
     */
    public function handle(Team $team, TeamHierarchyState $currentState): Archived
    {
        // Determine the previous state
        $fromState = $currentState instanceof Active ? 'active' : 'suspended';

        // Log the transition
        Log::info("Team {$team->id} ({$team->name}) was archived by " . 
            ($this->archivedBy ? "User {$this->archivedBy->id}" : "system") . 
            ($this->reason ? " for reason: {$this->reason}" : "") .
            ($this->notes ? " with notes: {$this->notes}" : ""));

        // Record the archiving in activity log
        activity()
            ->performedOn($team)
            ->causedBy($this->archivedBy ?? auth()->user())
            ->withProperties([
                'reason' => $this->reason,
                'notes' => $this->notes,
                'from_state' => $fromState,
                'to_state' => 'archived',
                'cascade_to_children' => $this->cascadeToChildren,
            ])
            ->log('team_archived');

        // Optionally cascade the archiving to child teams
        if ($this->cascadeToChildren && $team->children()->count() > 0) {
            foreach ($team->children as $childTeam) {
                if (!($childTeam->hierarchy_state instanceof Archived)) {
                    $childTeam->hierarchy_state->transition(new self(
                        $this->archivedBy,
                        "Parent team {$team->name} was archived" . ($this->reason ? ": {$this->reason}" : ""),
                        $this->notes,
                        true // Continue cascading
                    ));
                    $childTeam->save();
                }
            }
        }

        // Return the new state
        return new Archived($team);
    }
}
```

### 5. Restore Team Transition

This transition occurs when an archived team is restored to active status:

```bash
touch app/States/Team/Transitions/RestoreTeamTransition.php
```

```php
<?php

declare(strict_types=1);

namespace App\States\Team\Transitions;

use App\Models\Team;
use App\Models\User;
use App\States\Team\Active;
use App\States\Team\Archived;
use Illuminate\Support\Facades\Log;
use Spatie\ModelStates\Transition;

/**
 * Transition from Archived to Active when a team is restored.
 */
class RestoreTeamTransition extends Transition
{
    /**
     * Constructor.
     */
    public function __construct(
        private ?User $restoredBy = null,
        private ?string $notes = null,
        private bool $cascadeToChildren = false
    ) {}

    /**
     * Handle the transition.
     */
    public function handle(Team $team, Archived $currentState): Active
    {
        // Log the transition
        Log::info("Team {$team->id} ({$team->name}) was restored by " . 
            ($this->restoredBy ? "User {$this->restoredBy->id}" : "system") . 
            ($this->notes ? " with notes: {$this->notes}" : ""));

        // Record the restoration in activity log
        activity()
            ->performedOn($team)
            ->causedBy($this->restoredBy ?? auth()->user())
            ->withProperties([
                'notes' => $this->notes,
                'from_state' => 'archived',
                'to_state' => 'active',
                'cascade_to_children' => $this->cascadeToChildren,
            ])
            ->log('team_restored');

        // Optionally cascade the restoration to child teams
        if ($this->cascadeToChildren && $team->children()->count() > 0) {
            foreach ($team->children as $childTeam) {
                if ($childTeam->hierarchy_state instanceof Archived) {
                    $childTeam->hierarchy_state->transition(new self(
                        $this->restoredBy,
                        "Parent team {$team->name} was restored",
                        true // Continue cascading
                    ));
                    $childTeam->save();
                }
            }
        }

        // Return the new state
        return new Active($team);
    }
}
```

## Updating the TeamHierarchyState Configuration

Now that we've created our transition classes, let's update the `TeamHierarchyState` configuration to use them:

```php
/**
 * Configure the state machine.
 */
public static function config(): StateConfig
{
    return parent::config()
        ->default(Pending::class) // Default state for new teams
        ->allowTransition(Pending::class, Active::class, Transitions\ApproveTeamTransition::class)
        ->allowTransition(Active::class, Suspended::class, Transitions\SuspendTeamTransition::class)
        ->allowTransition(Active::class, Archived::class, Transitions\ArchiveTeamTransition::class)
        ->allowTransition(Suspended::class, Active::class, Transitions\ReactivateTeamTransition::class)
        ->allowTransition(Suspended::class, Archived::class, Transitions\ArchiveTeamTransition::class)
        ->allowTransition(Archived::class, Active::class, Transitions\RestoreTeamTransition::class);
}
```

## Using the Transition Classes

Here's how to use these transition classes in your application:

```php
// Approve a pending team
$team = Team::find(1);
if ($team->hierarchy_state instanceof \App\States\Team\Pending) {
    $team->hierarchy_state->transition(new \App\States\Team\Transitions\ApproveTeamTransition(
        auth()->user(),
        'Team meets all requirements'
    ));
    $team->save();
}

// Suspend an active team
$team = Team::find(2);
if ($team->hierarchy_state instanceof \App\States\Team\Active) {
    $team->hierarchy_state->transition(new \App\States\Team\Transitions\SuspendTeamTransition(
        auth()->user(),
        'Violation of terms of service',
        'Multiple reports of inappropriate content',
        true // Cascade to child teams
    ));
    $team->save();
}

// Reactivate a suspended team
$team = Team::find(3);
if ($team->hierarchy_state instanceof \App\States\Team\Suspended) {
    $team->hierarchy_state->transition(new \App\States\Team\Transitions\ReactivateTeamTransition(
        auth()->user(),
        'Issue resolved',
        true // Cascade to child teams
    ));
    $team->save();
}

// Archive a team
$team = Team::find(4);
if (!($team->hierarchy_state instanceof \App\States\Team\Archived)) {
    $team->hierarchy_state->transition(new \App\States\Team\Transitions\ArchiveTeamTransition(
        auth()->user(),
        'Team no longer needed',
        'Project completed',
        true // Cascade to child teams
    ));
    $team->save();
}

// Restore an archived team
$team = Team::find(5);
if ($team->hierarchy_state instanceof \App\States\Team\Archived) {
    $team->hierarchy_state->transition(new \App\States\Team\Transitions\RestoreTeamTransition(
        auth()->user(),
        'Team needed for new project',
        true // Cascade to child teams
    ));
    $team->save();
}
```

## Handling Invalid Transitions

If you try to make an invalid transition, the package will throw a `Spatie\ModelStates\Exceptions\TransitionNotFound` exception. You should handle this in your application:

```php
try {
    // This will throw an exception if the team is not in the correct state
    $team->hierarchy_state->transition(new \App\States\Team\Transitions\SuspendTeamTransition(
        auth()->user(),
        'Violation of terms of service'
    ));
    $team->save();
} catch (\Spatie\ModelStates\Exceptions\TransitionNotFound $e) {
    // Handle the exception
    return back()->with('error', 'Cannot suspend the team in its current state.');
}
```

## Next Steps

Now that we've implemented the transition classes for our team hierarchy state machine, let's move on to integrating the state machine with our application in the [next section](./048-team-hierarchy-state-integration.md).

## Additional Resources

- [Spatie Laravel Model States Documentation](https://spatie.be/docs/laravel-model-states/v2/introduction)
- [Laravel Activity Log Documentation](https://spatie.be/docs/laravel-activitylog/v4/introduction)
- [Laravel Logging Documentation](https://laravel.com/docs/12.x/logging)
