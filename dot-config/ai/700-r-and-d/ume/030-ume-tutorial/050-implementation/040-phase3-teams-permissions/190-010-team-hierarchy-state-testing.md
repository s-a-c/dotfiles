# Testing Team Hierarchy State Machine

<link rel="stylesheet" href="../../../assets/css/styles.css">

In this section, we'll create comprehensive tests for our team hierarchy state machine to ensure it works correctly. We'll test state transitions, validation, and integration with the team hierarchy.

## Creating the Test Class

Let's create a test class for our team hierarchy state machine:

```bash
php artisan make:test TeamHierarchyStateTest
```

```php
<?php

namespace Tests\Feature;

use App\Models\Team;use App\Models\User;use App\States\Team\Active;use App\States\Team\Archived;use App\States\Team\Pending;use App\States\Team\Suspended;use App\States\Team\Transitions\ApproveTeamTransition;use App\States\Team\Transitions\ArchiveTeamTransition;use App\States\Team\Transitions\ReactivateTeamTransition;use App\States\Team\Transitions\RestoreTeamTransition;use App\States\Team\Transitions\SuspendTeamTransition;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;use Spatie\ModelStates\Exceptions\TransitionNotFound;

class TeamHierarchyStateTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function new_teams_have_pending_state()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $user->id]);
        
        $this->assertInstanceOf(Pending::class, $team->hierarchy_state);
        $this->assertFalse($team->canAddMembers());
        $this->assertFalse($team->canCreateChildTeams());
        $this->assertFalse($team->isVisibleInHierarchy());
        $this->assertFalse($team->canAssignPermissions());
    }

    #[Test]
    public function pending_teams_can_be_approved()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $user->id]);
        
        $team->hierarchy_state->transition(new ApproveTeamTransition($user, 'Approved for testing'));
        $team->save();
        
        $this->assertInstanceOf(Active::class, $team->hierarchy_state);
        $this->assertTrue($team->canAddMembers());
        $this->assertTrue($team->canCreateChildTeams());
        $this->assertTrue($team->isVisibleInHierarchy());
        $this->assertTrue($team->canAssignPermissions());
    }

    #[Test]
    public function active_teams_can_be_suspended()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $user->id]);
        
        // First approve the team
        $team->hierarchy_state->transition(new ApproveTeamTransition($user));
        $team->save();
        
        // Then suspend it
        $team->hierarchy_state->transition(new SuspendTeamTransition(
            $user,
            'Violation of terms',
            'Test suspension'
        ));
        $team->save();
        
        $this->assertInstanceOf(Suspended::class, $team->hierarchy_state);
        $this->assertFalse($team->canAddMembers());
        $this->assertFalse($team->canCreateChildTeams());
        $this->assertTrue($team->isVisibleInHierarchy());
        $this->assertFalse($team->canAssignPermissions());
    }

    #[Test]
    public function suspended_teams_can_be_reactivated()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $user->id]);
        
        // First approve the team
        $team->hierarchy_state->transition(new ApproveTeamTransition($user));
        $team->save();
        
        // Then suspend it
        $team->hierarchy_state->transition(new SuspendTeamTransition(
            $user,
            'Violation of terms'
        ));
        $team->save();
        
        // Finally reactivate it
        $team->hierarchy_state->transition(new ReactivateTeamTransition($user, 'Issue resolved'));
        $team->save();
        
        $this->assertInstanceOf(Active::class, $team->hierarchy_state);
        $this->assertTrue($team->canAddMembers());
        $this->assertTrue($team->canCreateChildTeams());
        $this->assertTrue($team->isVisibleInHierarchy());
        $this->assertTrue($team->canAssignPermissions());
    }

    #[Test]
    public function active_teams_can_be_archived()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $user->id]);
        
        // First approve the team
        $team->hierarchy_state->transition(new ApproveTeamTransition($user));
        $team->save();
        
        // Then archive it
        $team->hierarchy_state->transition(new ArchiveTeamTransition(
            $user,
            'No longer needed',
            'Project completed'
        ));
        $team->save();
        
        $this->assertInstanceOf(Archived::class, $team->hierarchy_state);
        $this->assertFalse($team->canAddMembers());
        $this->assertFalse($team->canCreateChildTeams());
        $this->assertFalse($team->isVisibleInHierarchy());
        $this->assertFalse($team->canAssignPermissions());
    }

    #[Test]
    public function suspended_teams_can_be_archived()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $user->id]);
        
        // First approve the team
        $team->hierarchy_state->transition(new ApproveTeamTransition($user));
        $team->save();
        
        // Then suspend it
        $team->hierarchy_state->transition(new SuspendTeamTransition(
            $user,
            'Violation of terms'
        ));
        $team->save();
        
        // Finally archive it
        $team->hierarchy_state->transition(new ArchiveTeamTransition(
            $user,
            'Permanently suspended',
            'Multiple violations'
        ));
        $team->save();
        
        $this->assertInstanceOf(Archived::class, $team->hierarchy_state);
    }

    #[Test]
    public function archived_teams_can_be_restored()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $user->id]);
        
        // First approve the team
        $team->hierarchy_state->transition(new ApproveTeamTransition($user));
        $team->save();
        
        // Then archive it
        $team->hierarchy_state->transition(new ArchiveTeamTransition(
            $user,
            'No longer needed'
        ));
        $team->save();
        
        // Finally restore it
        $team->hierarchy_state->transition(new RestoreTeamTransition($user, 'Team needed again'));
        $team->save();
        
        $this->assertInstanceOf(Active::class, $team->hierarchy_state);
    }

    #[Test]
    public function invalid_transitions_throw_exceptions()
    {
        $this->expectException(TransitionNotFound::class);
        
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $user->id]);
        
        // This should throw an exception because we can't go directly from Pending to Suspended
        $team->hierarchy_state->transition(new SuspendTeamTransition(
            $user,
            'Invalid transition'
        ));
    }
}
```
