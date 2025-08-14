# Team Hierarchy State Machine Exercises - Sample Answers (Part 3)

<link rel="stylesheet" href="../../assets/css/styles.css">

Let's continue with the remaining transition classes for the Set 2 exercise:

```php
<?php

declare(strict_types=1);

namespace App\States\Team\Transitions;

use App\Models\Team;
use App\Models\User;
use App\States\Team\Active;
use App\States\Team\OnHold;
use Illuminate\Support\Facades\Log;
use Spatie\ModelStates\Transition;

class ResumeTeamTransition extends Transition
{
    public function __construct(
        private ?User $resumedBy = null,
        private ?string $notes = null,
        private bool $cascadeToChildren = false
    ) {}

    public function handle(Team $team, OnHold $currentState): Active
    {
        // Log the transition
        Log::info("Team {$team->id} ({$team->name}) was resumed by " . 
            ($this->resumedBy ? "User {$this->resumedBy->id}" : "system") . 
            ($this->notes ? " with notes: {$this->notes}" : ""));

        // Record the action in activity log
        activity()
            ->performedOn($team)
            ->causedBy($this->resumedBy ?? auth()->user())
            ->withProperties([
                'notes' => $this->notes,
                'from_state' => 'on_hold',
                'to_state' => 'active',
                'cascade_to_children' => $this->cascadeToChildren,
            ])
            ->log('team_resumed');

        // Cascade to children if requested
        if ($this->cascadeToChildren && $team->children()->count() > 0) {
            foreach ($team->children as $childTeam) {
                if ($childTeam->status instanceof OnHold) {
                    $childTeam->status->transition(new self(
                        $this->resumedBy,
                        "Parent team {$team->name} was resumed",
                        true // Continue cascading
                    ));
                    $childTeam->save();
                }
            }
        }

        return new Active($team);
    }
}
```

```php
<?php

declare(strict_types=1);

namespace App\States\Team\Transitions;

use App\Models\Team;
use App\Models\User;
use App\States\Team\Discontinued;
use App\States\Team\TeamState;
use Illuminate\Support\Facades\Log;
use Spatie\ModelStates\Transition;

class DiscontinueTeamTransition extends Transition
{
    public function __construct(
        private ?User $discontinuedBy = null,
        private ?string $reason = null,
        private ?string $notes = null,
        private bool $cascadeToChildren = false
    ) {}

    public function handle(Team $team, TeamState $currentState): Discontinued
    {
        // Determine the previous state
        $fromState = $currentState::status()->value;

        // Log the transition
        Log::info("Team {$team->id} ({$team->name}) was discontinued by " . 
            ($this->discontinuedBy ? "User {$this->discontinuedBy->id}" : "system") . 
            ($this->reason ? " for reason: {$this->reason}" : "") .
            ($this->notes ? " with notes: {$this->notes}" : ""));

        // Record the action in activity log
        activity()
            ->performedOn($team)
            ->causedBy($this->discontinuedBy ?? auth()->user())
            ->withProperties([
                'reason' => $this->reason,
                'notes' => $this->notes,
                'from_state' => $fromState,
                'to_state' => 'discontinued',
                'cascade_to_children' => $this->cascadeToChildren,
            ])
            ->log('team_discontinued');

        // Cascade to children if requested
        if ($this->cascadeToChildren && $team->children()->count() > 0) {
            foreach ($team->children as $childTeam) {
                if (!($childTeam->status instanceof Discontinued)) {
                    $childTeam->status->transition(new self(
                        $this->discontinuedBy,
                        "Parent team {$team->name} was discontinued" . ($this->reason ? ": {$this->reason}" : ""),
                        $this->notes,
                        true // Continue cascading
                    ));
                    $childTeam->save();
                }
            }
        }

        return new Discontinued($team);
    }
}
```

Now, let's create a controller method to handle the "pause team" action:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Team;
use App\States\Team\Active;
use App\States\Team\Transitions\PauseTeamTransition;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Spatie\ModelStates\Exceptions\TransitionNotFound;

class TeamController extends Controller
{
    // ... other methods ...

    /**
     * Pause an active team.
     */
    public function pause(Request $request, Team $team)
    {
        // Check authorization
        if (! (Gate::allows('admin') || $request->user()->id === $team->owner_id)) {
            abort(403, 'You are not authorized to pause this team.');
        }

        // Validate input
        $validated = $request->validate([
            'reason' => 'required|string|max:255',
            'notes' => 'nullable|string',
            'cascade_to_children' => 'boolean',
        ]);

        try {
            // Check if the team is in the Active state
            if (!($team->status instanceof Active)) {
                return back()->with('error', 'Only active teams can be paused.');
            }

            // Perform the transition
            $team->status->transition(new PauseTeamTransition(
                $request->user(),
                $validated['reason'],
                $validated['notes'] ?? null,
                $validated['cascade_to_children'] ?? false
            ));
            $team->save();

            return redirect()->route('teams.show', $team)
                ->with('success', 'Team paused successfully.');
        } catch (TransitionNotFound $e) {
            return back()->with('error', 'Cannot pause the team in its current state.');
        } catch (\Exception $e) {
            return back()->with('error', 'An error occurred while pausing the team: ' . $e->getMessage());
        }
    }
}
```

Finally, let's write a test for the state machine with cascading transitions:

```php
<?php

namespace Tests\Feature;

use App\Models\Team;use App\Models\User;use App\States\Team\Active;use App\States\Team\Discontinued;use App\States\Team\Draft;use App\States\Team\OnHold;use App\States\Team\Transitions\DiscontinueTeamTransition;use App\States\Team\Transitions\PauseTeamTransition;use App\States\Team\Transitions\PublishTeamTransition;use App\States\Team\Transitions\ResumeTeamTransition;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;use Spatie\ModelStates\Exceptions\TransitionNotFound;

class TeamStatusTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function pause_transition_can_cascade_to_child_teams()
    {
        $user = User::factory()->create();
        
        // Create parent team
        $parentTeam = Team::factory()->create(['owner_id' => $user->id]);
        $parentTeam->status->transition(new PublishTeamTransition($user));
        $parentTeam->save();
        
        // Create child teams
        $childTeam1 = Team::factory()->create([
            'owner_id' => $user->id,
            'parent_id' => $parentTeam->id,
        ]);
        $childTeam1->status->transition(new PublishTeamTransition($user));
        $childTeam1->save();
        
        $childTeam2 = Team::factory()->create([
            'owner_id' => $user->id,
            'parent_id' => $parentTeam->id,
        ]);
        $childTeam2->status->transition(new PublishTeamTransition($user));
        $childTeam2->save();
        
        // Pause parent team with cascade
        $parentTeam->status->transition(new PauseTeamTransition(
            $user,
            'Temporary pause for maintenance',
            'Scheduled maintenance',
            true // Cascade to children
        ));
        $parentTeam->save();
        
        // Refresh child teams from database
        $childTeam1->refresh();
        $childTeam2->refresh();
        
        // Assert that parent and all children are on hold
        $this->assertInstanceOf(OnHold::class, $parentTeam->status);
        $this->assertInstanceOf(OnHold::class, $childTeam1->status);
        $this->assertInstanceOf(OnHold::class, $childTeam2->status);
    }

    #[Test]
    public function admin_can_pause_team()
    {
        $admin = User::factory()->create();
        $admin->assignRole('admin');
        
        $team = Team::factory()->create(['owner_id' => $admin->id]);
        $team->status->transition(new PublishTeamTransition($admin));
        $team->save();
        
        $response = $this->actingAs($admin)->post(route('teams.pause', $team), [
            'reason' => 'Maintenance',
            'notes' => 'Scheduled maintenance',
            'cascade_to_children' => true,
        ]);
        
        $response->assertRedirect(route('teams.show', $team));
        $response->assertSessionHas('success');
        
        $team->refresh();
        $this->assertInstanceOf(OnHold::class, $team->status);
    }

    #[Test]
    public function team_owner_can_pause_team()
    {
        $owner = User::factory()->create();
        
        $team = Team::factory()->create(['owner_id' => $owner->id]);
        $team->status->transition(new PublishTeamTransition($owner));
        $team->save();
        
        $response = $this->actingAs($owner)->post(route('teams.pause', $team), [
            'reason' => 'Maintenance',
        ]);
        
        $response->assertRedirect(route('teams.show', $team));
        $response->assertSessionHas('success');
        
        $team->refresh();
        $this->assertInstanceOf(OnHold::class, $team->status);
    }

    #[Test]
    public function non_owner_cannot_pause_team()
    {
        $owner = User::factory()->create();
        $user = User::factory()->create();
        
        $team = Team::factory()->create(['owner_id' => $owner->id]);
        $team->status->transition(new PublishTeamTransition($owner));
        $team->save();
        
        $response = $this->actingAs($user)->post(route('teams.pause', $team), [
            'reason' => 'Maintenance',
        ]);
        
        $response->assertStatus(403);
        
        $team->refresh();
        $this->assertInstanceOf(Active::class, $team->status);
    }
}
```
