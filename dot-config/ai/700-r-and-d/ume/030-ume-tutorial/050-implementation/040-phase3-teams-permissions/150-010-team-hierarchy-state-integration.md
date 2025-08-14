# Team Hierarchy State Integration

<link rel="stylesheet" href="../../../assets/css/styles.css">

In this section, we'll integrate the team hierarchy state machine with our application by creating controllers, policies, and views to manage team states.

## Updating the Team Controller

First, let's update our TeamController to handle state transitions:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Team;
use App\States\Team\Transitions\ApproveTeamTransition;
use App\States\Team\Transitions\SuspendTeamTransition;
use App\States\Team\Transitions\ReactivateTeamTransition;
use App\States\Team\Transitions\ArchiveTeamTransition;
use App\States\Team\Transitions\RestoreTeamTransition;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Spatie\ModelStates\Exceptions\TransitionNotFound;

class TeamController extends Controller
{
    // ... existing methods ...

    /**
     * Approve a pending team.
     */
    public function approve(Request $request, Team $team)
    {
        Gate::authorize('approve', $team);

        try {
            $team->hierarchy_state->transition(new ApproveTeamTransition(
                auth()->user(),
                $request->input('notes')
            ));
            $team->save();

            return redirect()->route('teams.show', $team)
                ->with('success', 'Team approved successfully.');
        } catch (TransitionNotFound $e) {
            return back()->with('error', 'Cannot approve the team in its current state.');
        }
    }

    /**
     * Suspend an active team.
     */
    public function suspend(Request $request, Team $team)
    {
        Gate::authorize('suspend', $team);

        $validated = $request->validate([
            'reason' => 'required|string|max:255',
            'notes' => 'nullable|string',
            'cascade_to_children' => 'boolean',
        ]);

        try {
            $team->hierarchy_state->transition(new SuspendTeamTransition(
                auth()->user(),
                $validated['reason'],
                $validated['notes'] ?? null,
                $validated['cascade_to_children'] ?? false
            ));
            $team->save();

            return redirect()->route('teams.show', $team)
                ->with('success', 'Team suspended successfully.');
        } catch (TransitionNotFound $e) {
            return back()->with('error', 'Cannot suspend the team in its current state.');
        }
    }

    /**
     * Reactivate a suspended team.
     */
    public function reactivate(Request $request, Team $team)
    {
        Gate::authorize('reactivate', $team);

        $validated = $request->validate([
            'notes' => 'nullable|string',
            'cascade_to_children' => 'boolean',
        ]);

        try {
            $team->hierarchy_state->transition(new ReactivateTeamTransition(
                auth()->user(),
                $validated['notes'] ?? null,
                $validated['cascade_to_children'] ?? false
            ));
            $team->save();

            return redirect()->route('teams.show', $team)
                ->with('success', 'Team reactivated successfully.');
        } catch (TransitionNotFound $e) {
            return back()->with('error', 'Cannot reactivate the team in its current state.');
        }
    }

    /**
     * Archive a team.
     */
    public function archive(Request $request, Team $team)
    {
        Gate::authorize('archive', $team);

        $validated = $request->validate([
            'reason' => 'nullable|string|max:255',
            'notes' => 'nullable|string',
            'cascade_to_children' => 'boolean',
        ]);

        try {
            $team->hierarchy_state->transition(new ArchiveTeamTransition(
                auth()->user(),
                $validated['reason'] ?? null,
                $validated['notes'] ?? null,
                $validated['cascade_to_children'] ?? false
            ));
            $team->save();

            return redirect()->route('teams.show', $team)
                ->with('success', 'Team archived successfully.');
        } catch (TransitionNotFound $e) {
            return back()->with('error', 'Cannot archive the team in its current state.');
        }
    }

    /**
     * Restore an archived team.
     */
    public function restore(Request $request, Team $team)
    {
        Gate::authorize('restore', $team);

        $validated = $request->validate([
            'notes' => 'nullable|string',
            'cascade_to_children' => 'boolean',
        ]);

        try {
            $team->hierarchy_state->transition(new RestoreTeamTransition(
                auth()->user(),
                $validated['notes'] ?? null,
                $validated['cascade_to_children'] ?? false
            ));
            $team->save();

            return redirect()->route('teams.show', $team)
                ->with('success', 'Team restored successfully.');
        } catch (TransitionNotFound $e) {
            return back()->with('error', 'Cannot restore the team in its current state.');
        }
    }
}
```

## Updating the Team Policy

Next, let's update our TeamPolicy to define who can perform state transitions:

```php
<?php

namespace App\Policies;

use App\Models\Team;
use App\Models\User;
use App\States\Team\Active;
use App\States\Team\Archived;
use App\States\Team\Pending;
use App\States\Team\Suspended;
use Illuminate\Auth\Access\HandlesAuthorization;

class TeamPolicy
{
    use HandlesAuthorization;

    // ... existing methods ...

    /**
     * Determine whether the user can approve the team.
     */
    public function approve(User $user, Team $team): bool
    {
        // Only admins can approve teams
        if (!$user->hasRole('admin')) {
            return false;
        }

        // Can only approve pending teams
        return $team->hierarchy_state instanceof Pending;
    }

    /**
     * Determine whether the user can suspend the team.
     */
    public function suspend(User $user, Team $team): bool
    {
        // Only admins can suspend teams
        if (!$user->hasRole('admin')) {
            return false;
        }

        // Can only suspend active teams
        return $team->hierarchy_state instanceof Active;
    }

    /**
     * Determine whether the user can reactivate the team.
     */
    public function reactivate(User $user, Team $team): bool
    {
        // Only admins can reactivate teams
        if (!$user->hasRole('admin')) {
            return false;
        }

        // Can only reactivate suspended teams
        return $team->hierarchy_state instanceof Suspended;
    }

    /**
     * Determine whether the user can archive the team.
     */
    public function archive(User $user, Team $team): bool
    {
        // Admins can archive any team
        if ($user->hasRole('admin')) {
            // Can archive active or suspended teams
            return $team->hierarchy_state instanceof Active || 
                   $team->hierarchy_state instanceof Suspended;
        }

        // Team owners can archive their own active teams
        if ($team->owner_id === $user->id) {
            return $team->hierarchy_state instanceof Active;
        }

        return false;
    }

    /**
     * Determine whether the user can restore the team.
     */
    public function restore(User $user, Team $team): bool
    {
        // Only admins can restore teams
        if (!$user->hasRole('admin')) {
            return false;
        }

        // Can only restore archived teams
        return $team->hierarchy_state instanceof Archived;
    }
}
```
