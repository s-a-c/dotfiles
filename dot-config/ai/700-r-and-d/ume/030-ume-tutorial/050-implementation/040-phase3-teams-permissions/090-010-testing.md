# Testing in Phase 3: Teams & Permissions

This document outlines the testing approach for the Teams & Permissions phase of the UME tutorial. Comprehensive testing is essential to ensure that our team management, role-based permissions, and team hierarchies are working correctly.

## Testing Strategy

For the Teams & Permissions phase, we'll focus on:

1. **Team Tests**: Ensure that teams can be created, updated, and managed
2. **Permission Tests**: Verify that permissions are correctly assigned and checked
3. **Role Tests**: Test role assignment and management
4. **Team Hierarchy Tests**: Verify that team hierarchies work correctly
5. **Integration Tests**: Test how these components work together

## Team Tests

```php
<?php

namespace Tests\Feature\Teams;

use App\Models\Team;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class TeamTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function user_can_create_team()
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->post('/teams', [
            'name' => 'Test Team',
            'description' => 'This is a test team',
        ]);

        $response->assertRedirect('/teams');
        $this->assertDatabaseHas('teams', [
            'name' => 'Test Team',
            'description' => 'This is a test team',
            'owner_id' => $user->id,
        ]);
    }

    #[Test]
    public function user_can_view_their_teams()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $user->id]);

        $response = $this->actingAs($user)->get('/teams');

        $response->assertStatus(200);
        $response->assertSee($team->name);
    }

    #[Test]
    public function user_can_view_team_details()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $user->id]);

        $response = $this->actingAs($user)->get("/teams/{$team->id}");

        $response->assertStatus(200);
        $response->assertSee($team->name);
        $response->assertSee($team->description);
    }

    #[Test]
    public function user_can_update_their_team()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $user->id]);

        $response = $this->actingAs($user)->put("/teams/{$team->id}", [
            'name' => 'Updated Team',
            'description' => 'Updated description',
        ]);

        $response->assertRedirect("/teams/{$team->id}");
        $this->assertDatabaseHas('teams', [
            'id' => $team->id,
            'name' => 'Updated Team',
            'description' => 'Updated description',
        ]);
    }

    #[Test]
    public function user_cannot_update_team_they_do_not_own()
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $otherUser->id]);

        $response = $this->actingAs($user)->put("/teams/{$team->id}", [
            'name' => 'Updated Team',
            'description' => 'Updated description',
        ]);

        $response->assertStatus(403);
        $this->assertDatabaseMissing('teams', [
            'id' => $team->id,
            'name' => 'Updated Team',
        ]);
    }

    #[Test]
    public function user_can_delete_their_team()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $user->id]);

        $response = $this->actingAs($user)->delete("/teams/{$team->id}");

        $response->assertRedirect('/teams');
        $this->assertDatabaseMissing('teams', [
            'id' => $team->id,
        ]);
    }

    #[Test]
    public function user_cannot_delete_team_they_do_not_own()
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $otherUser->id]);

        $response = $this->actingAs($user)->delete("/teams/{$team->id}");

        $response->assertStatus(403);
        $this->assertDatabaseHas('teams', [
            'id' => $team->id,
        ]);
    }
}
```

## Team Membership Tests

```php
<?php

namespace Tests\Feature\Teams;

use App\Models\Team;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class TeamMembershipTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function team_owner_can_add_members()
    {
        $owner = User::factory()->create();
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $owner->id]);

        $response = $this->actingAs($owner)->post("/teams/{$team->id}/members", [
            'email' => $user->email,
            'role' => 'member',
        ]);

        $response->assertRedirect("/teams/{$team->id}/members");
        $this->assertDatabaseHas('team_user', [
            'team_id' => $team->id,
            'user_id' => $user->id,
        ]);
    }

    #[Test]
    public function team_owner_can_remove_members()
    {
        $owner = User::factory()->create();
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $owner->id]);

        // Add user to team
        $team->users()->attach($user->id, ['role' => 'member']);

        $response = $this->actingAs($owner)->delete("/teams/{$team->id}/members/{$user->id}");

        $response->assertRedirect("/teams/{$team->id}/members");
        $this->assertDatabaseMissing('team_user', [
            'team_id' => $team->id,
            'user_id' => $user->id,
        ]);
    }

    #[Test]
    public function non_owner_cannot_add_members()
    {
        $owner = User::factory()->create();
        $user = User::factory()->create();
        $nonOwner = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $owner->id]);

        // Add non-owner to team
        $team->users()->attach($nonOwner->id, ['role' => 'member']);

        $response = $this->actingAs($nonOwner)->post("/teams/{$team->id}/members", [
            'email' => $user->email,
            'role' => 'member',
        ]);

        $response->assertStatus(403);
        $this->assertDatabaseMissing('team_user', [
            'team_id' => $team->id,
            'user_id' => $user->id,
        ]);
    }

    #[Test]
    public function team_admin_can_add_members()
    {
        $owner = User::factory()->create();
        $admin = User::factory()->create();
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $owner->id]);

        // Add admin to team
        $team->users()->attach($admin->id, ['role' => 'admin']);

        $response = $this->actingAs($admin)->post("/teams/{$team->id}/members", [
            'email' => $user->email,
            'role' => 'member',
        ]);

        $response->assertRedirect("/teams/{$team->id}/members");
        $this->assertDatabaseHas('team_user', [
            'team_id' => $team->id,
            'user_id' => $user->id,
        ]);
    }

    #[Test]
    public function user_can_leave_team()
    {
        $owner = User::factory()->create();
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $owner->id]);

        // Add user to team
        $team->users()->attach($user->id, ['role' => 'member']);

        $response = $this->actingAs($user)->delete("/teams/{$team->id}/leave");

        $response->assertRedirect('/teams');
        $this->assertDatabaseMissing('team_user', [
            'team_id' => $team->id,
            'user_id' => $user->id,
        ]);
    }

    #[Test]
    public function owner_cannot_leave_team()
    {
        $owner = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $owner->id]);

        $response = $this->actingAs($owner)->delete("/teams/{$team->id}/leave");

        $response->assertStatus(403);
        $this->assertTrue($team->fresh()->isOwnedBy($owner));
    }

    #[Test]
    public function user_can_view_teams_they_are_member_of()
    {
        $owner = User::factory()->create();
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $owner->id]);

        // Add user to team
        $team->users()->attach($user->id, ['role' => 'member']);

        $response = $this->actingAs($user)->get('/teams');

        $response->assertStatus(200);
        $response->assertSee($team->name);
    }
}
```

## Permission Tests

```php
<?php

namespace Tests\Feature\Permissions;

use App\Models\Team;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;use Spatie\Permission\Models\Permission;use Spatie\Permission\Models\Role;

class PermissionTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        // Create permissions
        Permission::create(['name' => 'view team', 'guard_name' => 'web']);
        Permission::create(['name' => 'edit team', 'guard_name' => 'web']);
        Permission::create(['name' => 'delete team', 'guard_name' => 'web']);
        Permission::create(['name' => 'add team members', 'guard_name' => 'web']);
        Permission::create(['name' => 'remove team members', 'guard_name' => 'web']);

        // Create roles
        $ownerRole = Role::create(['name' => 'owner', 'guard_name' => 'web']);
        $adminRole = Role::create(['name' => 'admin', 'guard_name' => 'web']);
        $memberRole = Role::create(['name' => 'member', 'guard_name' => 'web']);

        // Assign permissions to roles
        $ownerRole->givePermissionTo([
            'view team', 'edit team', 'delete team', 'add team members', 'remove team members'
        ]);

        $adminRole->givePermissionTo([
            'view team', 'edit team', 'add team members', 'remove team members'
        ]);

        $memberRole->givePermissionTo([
            'view team'
        ]);
    }

    #[Test]
    public function user_with_permission_can_perform_action()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $user->id]);

        // Assign permission to user
        $user->givePermissionTo('edit team');

        $response = $this->actingAs($user)->put("/teams/{$team->id}", [
            'name' => 'Updated Team',
            'description' => 'Updated description',
        ]);

        $response->assertRedirect("/teams/{$team->id}");
        $this->assertDatabaseHas('teams', [
            'id' => $team->id,
            'name' => 'Updated Team',
        ]);
    }

    #[Test]
    public function user_without_permission_cannot_perform_action()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => User::factory()->create()->id]);

        // Add user to team but don't give edit permission
        $team->users()->attach($user->id, ['role' => 'member']);

        $response = $this->actingAs($user)->put("/teams/{$team->id}", [
            'name' => 'Updated Team',
            'description' => 'Updated description',
        ]);

        $response->assertStatus(403);
        $this->assertDatabaseMissing('teams', [
            'id' => $team->id,
            'name' => 'Updated Team',
        ]);
    }

    #[Test]
    public function user_with_role_has_associated_permissions()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => User::factory()->create()->id]);

        // Add user to team with admin role
        $team->users()->attach($user->id, ['role' => 'admin']);
        $user->assignRole('admin');

        // Admin should have edit team permission
        $this->assertTrue($user->hasPermissionTo('edit team'));

        $response = $this->actingAs($user)->put("/teams/{$team->id}", [
            'name' => 'Updated Team',
            'description' => 'Updated description',
        ]);

        $response->assertRedirect("/teams/{$team->id}");
        $this->assertDatabaseHas('teams', [
            'id' => $team->id,
            'name' => 'Updated Team',
        ]);
    }

    #[Test]
    public function team_owner_has_all_permissions_for_their_team()
    {
        $owner = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $owner->id]);

        // Owner should have all permissions for their team
        $this->assertTrue($owner->hasPermissionTo('view team'));
        $this->assertTrue($owner->hasPermissionTo('edit team'));
        $this->assertTrue($owner->hasPermissionTo('delete team'));
        $this->assertTrue($owner->hasPermissionTo('add team members'));
        $this->assertTrue($owner->hasPermissionTo('remove team members'));

        $response = $this->actingAs($owner)->delete("/teams/{$team->id}");

        $response->assertRedirect('/teams');
        $this->assertDatabaseMissing('teams', [
            'id' => $team->id,
        ]);
    }

    #[Test]
    public function permissions_are_scoped_to_specific_team()
    {
        $user = User::factory()->create();
        $team1 = Team::factory()->create(['owner_id' => User::factory()->create()->id]);
        $team2 = Team::factory()->create(['owner_id' => User::factory()->create()->id]);

        // Add user to team1 with admin role
        $team1->users()->attach($user->id, ['role' => 'admin']);
        $user->assignRole('admin', 'web', $team1->id);

        // Add user to team2 with member role
        $team2->users()->attach($user->id, ['role' => 'member']);
        $user->assignRole('member', 'web', $team2->id);

        // User should have edit permission for team1 but not team2
        $this->assertTrue($user->hasPermissionTo('edit team', 'web', $team1->id));
        $this->assertFalse($user->hasPermissionTo('edit team', 'web', $team2->id));

        // Can edit team1
        $response1 = $this->actingAs($user)->put("/teams/{$team1->id}", [
            'name' => 'Updated Team 1',
        ]);

        $response1->assertRedirect("/teams/{$team1->id}");
        $this->assertDatabaseHas('teams', [
            'id' => $team1->id,
            'name' => 'Updated Team 1',
        ]);

        // Cannot edit team2
        $response2 = $this->actingAs($user)->put("/teams/{$team2->id}", [
            'name' => 'Updated Team 2',
        ]);

        $response2->assertStatus(403);
        $this->assertDatabaseMissing('teams', [
            'id' => $team2->id,
            'name' => 'Updated Team 2',
        ]);
    }
}
```

## Role Tests

```php
<?php

namespace Tests\Feature\Roles;

use App\Models\Team;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;use Spatie\Permission\Models\Role;

class RoleTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function user_can_be_assigned_role()
    {
        $user = User::factory()->create();
        $role = Role::create(['name' => 'editor', 'guard_name' => 'web']);

        $user->assignRole($role);

        $this->assertTrue($user->hasRole('editor'));
    }

    #[Test]
    public function user_can_be_assigned_team_specific_role()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create();
        $role = Role::create(['name' => 'team-admin', 'guard_name' => 'web', 'team_id' => $team->id]);

        $user->assignRole($role);

        $this->assertTrue($user->hasRole('team-admin', 'web', $team->id));
        $this->assertFalse($user->hasRole('team-admin')); // Without team context
    }

    #[Test]
    public function user_can_have_different_roles_in_different_teams()
    {
        $user = User::factory()->create();
        $team1 = Team::factory()->create();
        $team2 = Team::factory()->create();

        // Create team-specific roles
        $adminRole = Role::create(['name' => 'admin', 'guard_name' => 'web', 'team_id' => $team1->id]);
        $memberRole = Role::create(['name' => 'member', 'guard_name' => 'web', 'team_id' => $team2->id]);

        // Assign roles
        $user->assignRole($adminRole);
        $user->assignRole($memberRole);

        // Check roles in specific teams
        $this->assertTrue($user->hasRole('admin', 'web', $team1->id));
        $this->assertTrue($user->hasRole('member', 'web', $team2->id));

        // Check roles in wrong teams
        $this->assertFalse($user->hasRole('admin', 'web', $team2->id));
        $this->assertFalse($user->hasRole('member', 'web', $team1->id));
    }

    #[Test]
    public function user_can_be_removed_from_role()
    {
        $user = User::factory()->create();
        $role = Role::create(['name' => 'editor', 'guard_name' => 'web']);

        $user->assignRole($role);
        $this->assertTrue($user->hasRole('editor'));

        $user->removeRole($role);
        $this->assertFalse($user->hasRole('editor'));
    }

    #[Test]
    public function user_can_be_removed_from_team_specific_role()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create();
        $role = Role::create(['name' => 'team-admin', 'guard_name' => 'web', 'team_id' => $team->id]);

        $user->assignRole($role);
        $this->assertTrue($user->hasRole('team-admin', 'web', $team->id));

        $user->removeRole($role);
        $this->assertFalse($user->hasRole('team-admin', 'web', $team->id));
    }

    #[Test]
    public function team_owner_can_assign_roles_to_team_members()
    {
        $owner = User::factory()->create();
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $owner->id]);

        // Add user to team
        $team->users()->attach($user->id);

        // Create team-specific role
        $editorRole = Role::create(['name' => 'editor', 'guard_name' => 'web', 'team_id' => $team->id]);

        // Owner assigns role to user
        $response = $this->actingAs($owner)->post("/teams/{$team->id}/members/{$user->id}/roles", [
            'role' => 'editor',
        ]);

        $response->assertRedirect();
        $this->assertTrue($user->hasRole('editor', 'web', $team->id));
    }

    #[Test]
    public function non_owner_cannot_assign_roles()
    {
        $owner = User::factory()->create();
        $nonOwner = User::factory()->create();
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $owner->id]);

        // Add users to team
        $team->users()->attach($nonOwner->id);
        $team->users()->attach($user->id);

        // Create team-specific role
        $editorRole = Role::create(['name' => 'editor', 'guard_name' => 'web', 'team_id' => $team->id]);

        // Non-owner tries to assign role to user
        $response = $this->actingAs($nonOwner)->post("/teams/{$team->id}/members/{$user->id}/roles", [
            'role' => 'editor',
        ]);

        $response->assertStatus(403);
        $this->assertFalse($user->hasRole('editor', 'web', $team->id));
    }
}
```

## Team Hierarchy Tests

```php
<?php

namespace Tests\Feature\Teams;

use App\Models\Team;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class TeamHierarchyTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function team_can_have_parent_team()
    {
        $user = User::factory()->create();
        $parentTeam = Team::factory()->create(['owner_id' => $user->id]);
        $childTeam = Team::factory()->create([
            'owner_id' => $user->id,
            'parent_id' => $parentTeam->id,
        ]);

        $this->assertEquals($parentTeam->id, $childTeam->parent_id);
        $this->assertTrue($childTeam->parent->is($parentTeam));
    }

    #[Test]
    public function team_can_have_multiple_child_teams()
    {
        $user = User::factory()->create();
        $parentTeam = Team::factory()->create(['owner_id' => $user->id]);

        $childTeam1 = Team::factory()->create([
            'owner_id' => $user->id,
            'parent_id' => $parentTeam->id,
        ]);

        $childTeam2 = Team::factory()->create([
            'owner_id' => $user->id,
            'parent_id' => $parentTeam->id,
        ]);

        $this->assertCount(2, $parentTeam->children);
        $this->assertTrue($parentTeam->children->contains($childTeam1));
        $this->assertTrue($parentTeam->children->contains($childTeam2));
    }

    #[Test]
    public function team_can_have_nested_hierarchy()
    {
        $user = User::factory()->create();
        $grandparentTeam = Team::factory()->create(['owner_id' => $user->id]);

        $parentTeam = Team::factory()->create([
            'owner_id' => $user->id,
            'parent_id' => $grandparentTeam->id,
        ]);

        $childTeam = Team::factory()->create([
            'owner_id' => $user->id,
            'parent_id' => $parentTeam->id,
        ]);

        $this->assertEquals($grandparentTeam->id, $parentTeam->parent_id);
        $this->assertEquals($parentTeam->id, $childTeam->parent_id);

        // Test ancestry
        $this->assertTrue($childTeam->isDescendantOf($grandparentTeam));
        $this->assertTrue($childTeam->isDescendantOf($parentTeam));
        $this->assertTrue($parentTeam->isDescendantOf($grandparentTeam));

        $this->assertTrue($grandparentTeam->isAncestorOf($childTeam));
        $this->assertTrue($grandparentTeam->isAncestorOf($parentTeam));
        $this->assertTrue($parentTeam->isAncestorOf($childTeam));
    }

    #[Test]
    public function user_can_create_child_team()
    {
        $user = User::factory()->create();
        $parentTeam = Team::factory()->create(['owner_id' => $user->id]);

        $response = $this->actingAs($user)->post('/teams', [
            'name' => 'Child Team',
            'description' => 'This is a child team',
            'parent_id' => $parentTeam->id,
        ]);

        $response->assertRedirect('/teams');

        $childTeam = Team::where('name', 'Child Team')->first();
        $this->assertNotNull($childTeam);
        $this->assertEquals($parentTeam->id, $childTeam->parent_id);
    }

    #[Test]
    public function user_cannot_create_child_team_for_team_they_do_not_own()
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $parentTeam = Team::factory()->create(['owner_id' => $otherUser->id]);

        $response = $this->actingAs($user)->post('/teams', [
            'name' => 'Child Team',
            'description' => 'This is a child team',
            'parent_id' => $parentTeam->id,
        ]);

        $response->assertStatus(403);

        $this->assertDatabaseMissing('teams', [
            'name' => 'Child Team',
            'parent_id' => $parentTeam->id,
        ]);
    }

    #[Test]
    public function deleting_parent_team_does_not_delete_child_teams()
    {
        $user = User::factory()->create();
        $parentTeam = Team::factory()->create(['owner_id' => $user->id]);

        $childTeam = Team::factory()->create([
            'owner_id' => $user->id,
            'parent_id' => $parentTeam->id,
            'name' => 'Child Team',
        ]);

        // Delete parent team
        $this->actingAs($user)->delete("/teams/{$parentTeam->id}");

        // Child team should still exist but with null parent_id
        $this->assertDatabaseHas('teams', [
            'id' => $childTeam->id,
            'name' => 'Child Team',
        ]);

        $this->assertNull($childTeam->fresh()->parent_id);
    }

    #[Test]
    public function user_can_view_team_hierarchy()
    {
        $user = User::factory()->create();
        $parentTeam = Team::factory()->create(['owner_id' => $user->id, 'name' => 'Parent Team']);

        $childTeam1 = Team::factory()->create([
            'owner_id' => $user->id,
            'parent_id' => $parentTeam->id,
            'name' => 'Child Team 1',
        ]);

        $childTeam2 = Team::factory()->create([
            'owner_id' => $user->id,
            'parent_id' => $parentTeam->id,
            'name' => 'Child Team 2',
        ]);

        $response = $this->actingAs($user)->get("/teams/{$parentTeam->id}/hierarchy");

        $response->assertStatus(200);
        $response->assertSee('Parent Team');
        $response->assertSee('Child Team 1');
        $response->assertSee('Child Team 2');
    }
}
```

## Integration Tests

```php
<?php

namespace Tests\Feature;

use App\Models\Team;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;use Spatie\Permission\Models\Permission;use Spatie\Permission\Models\Role;

class TeamsPermissionsIntegrationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        // Create permissions
        Permission::create(['name' => 'view team', 'guard_name' => 'web']);
        Permission::create(['name' => 'edit team', 'guard_name' => 'web']);
        Permission::create(['name' => 'delete team', 'guard_name' => 'web']);
        Permission::create(['name' => 'add team members', 'guard_name' => 'web']);
        Permission::create(['name' => 'remove team members', 'guard_name' => 'web']);

        // Create roles
        $ownerRole = Role::create(['name' => 'owner', 'guard_name' => 'web']);
        $adminRole = Role::create(['name' => 'admin', 'guard_name' => 'web']);
        $memberRole = Role::create(['name' => 'member', 'guard_name' => 'web']);

        // Assign permissions to roles
        $ownerRole->givePermissionTo([
            'view team', 'edit team', 'delete team', 'add team members', 'remove team members'
        ]);

        $adminRole->givePermissionTo([
            'view team', 'edit team', 'add team members', 'remove team members'
        ]);

        $memberRole->givePermissionTo([
            'view team'
        ]);
    }

    #[Test]
    public function complete_team_management_flow()
    {
        // Step 1: Create a user
        $owner = User::factory()->create();

        // Step 2: Create a team
        $response = $this->actingAs($owner)->post('/teams', [
            'name' => 'Test Team',
            'description' => 'This is a test team',
        ]);

        $response->assertRedirect('/teams');

        $team = Team::where('name', 'Test Team')->first();
        $this->assertNotNull($team);
        $this->assertEquals($owner->id, $team->owner_id);

        // Step 3: Add members to the team
        $member1 = User::factory()->create();
        $member2 = User::factory()->create();

        $this->actingAs($owner)->post("/teams/{$team->id}/members", [
            'email' => $member1->email,
            'role' => 'admin',
        ]);

        $this->actingAs($owner)->post("/teams/{$team->id}/members", [
            'email' => $member2->email,
            'role' => 'member',
        ]);

        // Step 4: Verify roles and permissions
        $this->assertTrue($member1->hasRole('admin', 'web', $team->id));
        $this->assertTrue($member2->hasRole('member', 'web', $team->id));

        $this->assertTrue($member1->hasPermissionTo('edit team', 'web', $team->id));
        $this->assertFalse($member2->hasPermissionTo('edit team', 'web', $team->id));

        // Step 5: Admin can edit team
        $response = $this->actingAs($member1)->put("/teams/{$team->id}", [
            'name' => 'Updated Team',
            'description' => 'Updated description',
        ]);

        $response->assertRedirect("/teams/{$team->id}");
        $this->assertDatabaseHas('teams', [
            'id' => $team->id,
            'name' => 'Updated Team',
        ]);

        // Step 6: Regular member cannot edit team
        $response = $this->actingAs($member2)->put("/teams/{$team->id}", [
            'name' => 'Member Updated Team',
            'description' => 'Member updated description',
        ]);

        $response->assertStatus(403);

        // Step 7: Admin can add members
        $member3 = User::factory()->create();

        $response = $this->actingAs($member1)->post("/teams/{$team->id}/members", [
            'email' => $member3->email,
            'role' => 'member',
        ]);

        $response->assertRedirect("/teams/{$team->id}/members");
        $this->assertTrue($team->fresh()->users->contains($member3));

        // Step 8: Regular member cannot add members
        $member4 = User::factory()->create();

        $response = $this->actingAs($member2)->post("/teams/{$team->id}/members", [
            'email' => $member4->email,
            'role' => 'member',
        ]);

        $response->assertStatus(403);
        $this->assertFalse($team->fresh()->users->contains($member4));

        // Step 9: Owner can remove members
        $response = $this->actingAs($owner)->delete("/teams/{$team->id}/members/{$member3->id}");

        $response->assertRedirect("/teams/{$team->id}/members");
        $this->assertFalse($team->fresh()->users->contains($member3));

        // Step 10: Owner can delete team
        $response = $this->actingAs($owner)->delete("/teams/{$team->id}");

        $response->assertRedirect('/teams');
        $this->assertDatabaseMissing('teams', [
            'id' => $team->id,
        ]);
    }

    #[Test]
    public function team_hierarchy_with_permission_inheritance()
    {
        // Create users
        $owner = User::factory()->create();
        $member = User::factory()->create();

        // Create parent team
        $parentTeam = Team::factory()->create([
            'owner_id' => $owner->id,
            'name' => 'Parent Team',
        ]);

        // Add member to parent team with admin role
        $parentTeam->users()->attach($member->id);
        $member->assignRole('admin', 'web', $parentTeam->id);

        // Create child team
        $childTeam = Team::factory()->create([
            'owner_id' => $owner->id,
            'parent_id' => $parentTeam->id,
            'name' => 'Child Team',
        ]);

        // Test permission inheritance
        $this->assertTrue($member->hasPermissionTo('edit team', 'web', $parentTeam->id));

        // If permissions inherit from parent team
        $this->assertTrue($member->hasPermissionTo('edit team', 'web', $childTeam->id));

        // Test editing child team
        $response = $this->actingAs($member)->put("/teams/{$childTeam->id}", [
            'name' => 'Updated Child Team',
            'description' => 'Updated child description',
        ]);

        $response->assertRedirect("/teams/{$childTeam->id}");
        $this->assertDatabaseHas('teams', [
            'id' => $childTeam->id,
            'name' => 'Updated Child Team',
        ]);
    }

    #[Test]
    public function team_invitation_and_acceptance_flow()
    {
        // Create users
        $owner = User::factory()->create();
        $invitedUser = User::factory()->create();

        // Create team
        $team = Team::factory()->create([
            'owner_id' => $owner->id,
            'name' => 'Test Team',
        ]);

        // Owner sends invitation
        $response = $this->actingAs($owner)->post("/teams/{$team->id}/invitations", [
            'email' => $invitedUser->email,
            'role' => 'admin',
        ]);

        $response->assertRedirect();

        // Check invitation was created
        $this->assertDatabaseHas('team_invitations', [
            'team_id' => $team->id,
            'email' => $invitedUser->email,
            'role' => 'admin',
        ]);

        // Get the invitation
        $invitation = \App\Models\TeamInvitation::where('email', $invitedUser->email)->first();

        // Invited user accepts invitation
        $response = $this->actingAs($invitedUser)->get("/team-invitations/{$invitation->token}/accept");

        $response->assertRedirect();

        // Check user is now a member of the team with the correct role
        $this->assertTrue($team->fresh()->users->contains($invitedUser));
        $this->assertTrue($invitedUser->hasRole('admin', 'web', $team->id));

        // Check invitation is marked as accepted
        $this->assertNotNull($invitation->fresh()->accepted_at);
    }
}
```

## Running the Tests

To run the tests for the Teams & Permissions phase, use the following command:

```bash
php artisan test --filter=TeamTest,TeamMembershipTest,PermissionTest,RoleTest,TeamHierarchyTest,TeamsPermissionsIntegrationTest
```

Or run all tests with:

```bash
php artisan test
```

## Test Coverage

To ensure comprehensive test coverage for the Teams & Permissions phase, make sure your tests cover:

1. Team creation, updating, and deletion
2. Team membership management
3. Permission assignment and checking
4. Role assignment and management
5. Team hierarchies and inheritance
6. Integration between these components

## Best Practices

1. **Use PHP Attributes**: Always use PHP 8 attributes (`#[Test]`) instead of PHPDoc annotations (`/** @test */`).
2. **Test Team Management**: Verify that teams can be created, updated, and deleted.
3. **Test Membership Management**: Ensure that users can be added to and removed from teams.
4. **Test Permissions**: Verify that permissions are correctly assigned and checked.
5. **Test Roles**: Ensure that roles are correctly assigned and managed.
6. **Test Team Hierarchies**: Verify that team hierarchies work correctly.
7. **Test Integration**: Ensure that these components work together correctly.
8. **Use RefreshDatabase**: Use the RefreshDatabase trait to ensure a clean database state for each test.

By following these guidelines, you'll ensure that your Teams & Permissions phase is thoroughly tested and ready for the next phases of the UME tutorial.
