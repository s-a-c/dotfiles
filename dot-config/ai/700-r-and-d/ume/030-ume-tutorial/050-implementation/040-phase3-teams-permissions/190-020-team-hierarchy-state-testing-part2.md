# Testing Team Hierarchy State Machine (Part 2)

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Testing State Transitions with Hierarchy

Let's create tests for state transitions that cascade through the team hierarchy:

```php
#[Test]
public function suspend_transition_can_cascade_to_child_teams()
{
    $user = User::factory()->create();
    
    // Create parent team
    $parentTeam = Team::factory()->create(['owner_id' => $user->id]);
    $parentTeam->hierarchy_state->transition(new ApproveTeamTransition($user));
    $parentTeam->save();
    
    // Create child teams
    $childTeam1 = Team::factory()->create([
        'owner_id' => $user->id,
        'parent_id' => $parentTeam->id,
    ]);
    $childTeam1->hierarchy_state->transition(new ApproveTeamTransition($user));
    $childTeam1->save();
    
    $childTeam2 = Team::factory()->create([
        'owner_id' => $user->id,
        'parent_id' => $parentTeam->id,
    ]);
    $childTeam2->hierarchy_state->transition(new ApproveTeamTransition($user));
    $childTeam2->save();
    
    // Suspend parent team with cascade
    $parentTeam->hierarchy_state->transition(new SuspendTeamTransition(
        $user,
        'Violation of terms',
        'Test suspension',
        true // Cascade to children
    ));
    $parentTeam->save();
    
    // Refresh child teams from database
    $childTeam1->refresh();
    $childTeam2->refresh();
    
    // Assert that parent and all children are suspended
    $this->assertInstanceOf(Suspended::class, $parentTeam->hierarchy_state);
    $this->assertInstanceOf(Suspended::class, $childTeam1->hierarchy_state);
    $this->assertInstanceOf(Suspended::class, $childTeam2->hierarchy_state);
}

#[Test]
public function reactivate_transition_can_cascade_to_child_teams()
{
    $user = User::factory()->create();
    
    // Create parent team
    $parentTeam = Team::factory()->create(['owner_id' => $user->id]);
    $parentTeam->hierarchy_state->transition(new ApproveTeamTransition($user));
    $parentTeam->save();
    
    // Create child teams
    $childTeam1 = Team::factory()->create([
        'owner_id' => $user->id,
        'parent_id' => $parentTeam->id,
    ]);
    $childTeam1->hierarchy_state->transition(new ApproveTeamTransition($user));
    $childTeam1->save();
    
    $childTeam2 = Team::factory()->create([
        'owner_id' => $user->id,
        'parent_id' => $parentTeam->id,
    ]);
    $childTeam2->hierarchy_state->transition(new ApproveTeamTransition($user));
    $childTeam2->save();
    
    // Suspend all teams
    $parentTeam->hierarchy_state->transition(new SuspendTeamTransition(
        $user,
        'Violation of terms'
    ));
    $parentTeam->save();
    
    $childTeam1->hierarchy_state->transition(new SuspendTeamTransition(
        $user,
        'Parent team suspended'
    ));
    $childTeam1->save();
    
    $childTeam2->hierarchy_state->transition(new SuspendTeamTransition(
        $user,
        'Parent team suspended'
    ));
    $childTeam2->save();
    
    // Reactivate parent team with cascade
    $parentTeam->hierarchy_state->transition(new ReactivateTeamTransition(
        $user,
        'Issue resolved',
        true // Cascade to children
    ));
    $parentTeam->save();
    
    // Refresh child teams from database
    $childTeam1->refresh();
    $childTeam2->refresh();
    
    // Assert that parent and all children are active
    $this->assertInstanceOf(Active::class, $parentTeam->hierarchy_state);
    $this->assertInstanceOf(Active::class, $childTeam1->hierarchy_state);
    $this->assertInstanceOf(Active::class, $childTeam2->hierarchy_state);
}

#[Test]
public function archive_transition_can_cascade_to_child_teams()
{
    $user = User::factory()->create();
    
    // Create parent team
    $parentTeam = Team::factory()->create(['owner_id' => $user->id]);
    $parentTeam->hierarchy_state->transition(new ApproveTeamTransition($user));
    $parentTeam->save();
    
    // Create child teams
    $childTeam1 = Team::factory()->create([
        'owner_id' => $user->id,
        'parent_id' => $parentTeam->id,
    ]);
    $childTeam1->hierarchy_state->transition(new ApproveTeamTransition($user));
    $childTeam1->save();
    
    $childTeam2 = Team::factory()->create([
        'owner_id' => $user->id,
        'parent_id' => $parentTeam->id,
    ]);
    $childTeam2->hierarchy_state->transition(new ApproveTeamTransition($user));
    $childTeam2->save();
    
    // Archive parent team with cascade
    $parentTeam->hierarchy_state->transition(new ArchiveTeamTransition(
        $user,
        'No longer needed',
        'Project completed',
        true // Cascade to children
    ));
    $parentTeam->save();
    
    // Refresh child teams from database
    $childTeam1->refresh();
    $childTeam2->refresh();
    
    // Assert that parent and all children are archived
    $this->assertInstanceOf(Archived::class, $parentTeam->hierarchy_state);
    $this->assertInstanceOf(Archived::class, $childTeam1->hierarchy_state);
    $this->assertInstanceOf(Archived::class, $childTeam2->hierarchy_state);
}

#[Test]
public function restore_transition_can_cascade_to_child_teams()
{
    $user = User::factory()->create();
    
    // Create parent team
    $parentTeam = Team::factory()->create(['owner_id' => $user->id]);
    $parentTeam->hierarchy_state->transition(new ApproveTeamTransition($user));
    $parentTeam->save();
    
    // Create child teams
    $childTeam1 = Team::factory()->create([
        'owner_id' => $user->id,
        'parent_id' => $parentTeam->id,
    ]);
    $childTeam1->hierarchy_state->transition(new ApproveTeamTransition($user));
    $childTeam1->save();
    
    $childTeam2 = Team::factory()->create([
        'owner_id' => $user->id,
        'parent_id' => $parentTeam->id,
    ]);
    $childTeam2->hierarchy_state->transition(new ApproveTeamTransition($user));
    $childTeam2->save();
    
    // Archive all teams
    $parentTeam->hierarchy_state->transition(new ArchiveTeamTransition(
        $user,
        'No longer needed'
    ));
    $parentTeam->save();
    
    $childTeam1->hierarchy_state->transition(new ArchiveTeamTransition(
        $user,
        'Parent team archived'
    ));
    $childTeam1->save();
    
    $childTeam2->hierarchy_state->transition(new ArchiveTeamTransition(
        $user,
        'Parent team archived'
    ));
    $childTeam2->save();
    
    // Restore parent team with cascade
    $parentTeam->hierarchy_state->transition(new RestoreTeamTransition(
        $user,
        'Team needed again',
        true // Cascade to children
    ));
    $parentTeam->save();
    
    // Refresh child teams from database
    $childTeam1->refresh();
    $childTeam2->refresh();
    
    // Assert that parent and all children are active
    $this->assertInstanceOf(Active::class, $parentTeam->hierarchy_state);
    $this->assertInstanceOf(Active::class, $childTeam1->hierarchy_state);
    $this->assertInstanceOf(Active::class, $childTeam2->hierarchy_state);
}
```

## Testing Controller Actions

Let's test the controller actions for team state transitions:

```php
#[Test]
public function admin_can_approve_pending_team()
{
    $admin = User::factory()->create();
    $admin->assignRole('admin');
    
    $team = Team::factory()->create(['owner_id' => $admin->id]);
    
    $response = $this->actingAs($admin)->post(route('teams.approve', $team), [
        'notes' => 'Approved for testing',
    ]);
    
    $response->assertRedirect(route('teams.show', $team));
    $response->assertSessionHas('success');
    
    $team->refresh();
    $this->assertInstanceOf(Active::class, $team->hierarchy_state);
}

#[Test]
public function admin_can_suspend_active_team()
{
    $admin = User::factory()->create();
    $admin->assignRole('admin');
    
    $team = Team::factory()->create(['owner_id' => $admin->id]);
    $team->hierarchy_state->transition(new ApproveTeamTransition($admin));
    $team->save();
    
    $response = $this->actingAs($admin)->post(route('teams.suspend', $team), [
        'reason' => 'Violation of terms',
        'notes' => 'Test suspension',
        'cascade_to_children' => true,
    ]);
    
    $response->assertRedirect(route('teams.show', $team));
    $response->assertSessionHas('success');
    
    $team->refresh();
    $this->assertInstanceOf(Suspended::class, $team->hierarchy_state);
}

#[Test]
public function non_admin_cannot_suspend_team()
{
    $owner = User::factory()->create();
    $user = User::factory()->create();
    
    $team = Team::factory()->create(['owner_id' => $owner->id]);
    $team->hierarchy_state->transition(new ApproveTeamTransition($owner));
    $team->save();
    
    $response = $this->actingAs($user)->post(route('teams.suspend', $team), [
        'reason' => 'Violation of terms',
    ]);
    
    $response->assertForbidden();
    
    $team->refresh();
    $this->assertInstanceOf(Active::class, $team->hierarchy_state);
}
```

## Testing Team Hierarchy Visualization

Let's test the team hierarchy visualization component:

```php
#[Test]
public function team_hierarchy_visualization_shows_correct_states()
{
    $user = User::factory()->create();
    
    // Create parent team
    $parentTeam = Team::factory()->create(['owner_id' => $user->id, 'name' => 'Parent Team']);
    $parentTeam->hierarchy_state->transition(new ApproveTeamTransition($user));
    $parentTeam->save();
    
    // Create child teams with different states
    $activeChild = Team::factory()->create([
        'owner_id' => $user->id,
        'parent_id' => $parentTeam->id,
        'name' => 'Active Child',
    ]);
    $activeChild->hierarchy_state->transition(new ApproveTeamTransition($user));
    $activeChild->save();
    
    $pendingChild = Team::factory()->create([
        'owner_id' => $user->id,
        'parent_id' => $parentTeam->id,
        'name' => 'Pending Child',
    ]);
    
    $suspendedChild = Team::factory()->create([
        'owner_id' => $user->id,
        'parent_id' => $parentTeam->id,
        'name' => 'Suspended Child',
    ]);
    $suspendedChild->hierarchy_state->transition(new ApproveTeamTransition($user));
    $suspendedChild->hierarchy_state->transition(new SuspendTeamTransition($user, 'Test suspension'));
    $suspendedChild->save();
    
    $archivedChild = Team::factory()->create([
        'owner_id' => $user->id,
        'parent_id' => $parentTeam->id,
        'name' => 'Archived Child',
    ]);
    $archivedChild->hierarchy_state->transition(new ApproveTeamTransition($user));
    $archivedChild->hierarchy_state->transition(new ArchiveTeamTransition($user, 'Test archiving'));
    $archivedChild->save();
    
    // Test the hierarchy view
    $response = $this->actingAs($user)->get(route('teams.hierarchy', $parentTeam));
    
    $response->assertStatus(200);
    $response->assertSee('Parent Team');
    $response->assertSee('Active Child');
    $response->assertSee('Pending Child');
    $response->assertSee('Suspended Child');
    
    // Archived teams should not be visible by default
    $response->assertDontSee('Archived Child');
    
    // Test with archived teams visible
    Livewire::test(TeamHierarchyVisualization::class, ['team' => $parentTeam])
        ->call('toggleShowArchived')
        ->assertSee('Archived Child');
}
```

## Testing Team State Filter

Let's test the team state filter component:

```php
#[Test]
public function team_state_filter_shows_correct_teams()
{
    $user = User::factory()->create();
    
    // Create teams with different states
    $pendingTeam = Team::factory()->create(['owner_id' => $user->id, 'name' => 'Pending Team']);
    
    $activeTeam = Team::factory()->create(['owner_id' => $user->id, 'name' => 'Active Team']);
    $activeTeam->hierarchy_state->transition(new ApproveTeamTransition($user));
    $activeTeam->save();
    
    $suspendedTeam = Team::factory()->create(['owner_id' => $user->id, 'name' => 'Suspended Team']);
    $suspendedTeam->hierarchy_state->transition(new ApproveTeamTransition($user));
    $suspendedTeam->hierarchy_state->transition(new SuspendTeamTransition($user, 'Test suspension'));
    $suspendedTeam->save();
    
    $archivedTeam = Team::factory()->create(['owner_id' => $user->id, 'name' => 'Archived Team']);
    $archivedTeam->hierarchy_state->transition(new ApproveTeamTransition($user));
    $archivedTeam->hierarchy_state->transition(new ArchiveTeamTransition($user, 'Test archiving'));
    $archivedTeam->save();
    
    // Test active filter (default)
    Livewire::test(TeamStateFilter::class)
        ->assertSee('Active Team')
        ->assertDontSee('Pending Team')
        ->assertDontSee('Suspended Team')
        ->assertDontSee('Archived Team');
    
    // Test pending filter
    Livewire::test(TeamStateFilter::class)
        ->set('state', 'pending')
        ->assertSee('Pending Team')
        ->assertDontSee('Active Team')
        ->assertDontSee('Suspended Team')
        ->assertDontSee('Archived Team');
    
    // Test suspended filter
    Livewire::test(TeamStateFilter::class)
        ->set('state', 'suspended')
        ->assertSee('Suspended Team')
        ->assertDontSee('Pending Team')
        ->assertDontSee('Active Team')
        ->assertDontSee('Archived Team');
    
    // Test archived filter
    Livewire::test(TeamStateFilter::class)
        ->set('state', 'archived')
        ->assertSee('Archived Team')
        ->assertDontSee('Pending Team')
        ->assertDontSee('Active Team')
        ->assertDontSee('Suspended Team');
    
    // Test search functionality
    Livewire::test(TeamStateFilter::class)
        ->set('search', 'Active')
        ->assertSee('Active Team')
        ->assertDontSee('Pending Team')
        ->assertDontSee('Suspended Team')
        ->assertDontSee('Archived Team');
}
```

## Next Steps

Now that we've thoroughly tested our team hierarchy state machine, let's move on to creating exercises and sample answers for this feature.

## Additional Resources

- [Laravel Testing Documentation](https://laravel.com/docs/12.x/testing)
- [Livewire Testing Documentation](https://laravel-livewire.com/docs/testing)
- [PHPUnit Documentation](https://phpunit.de/documentation.html)
