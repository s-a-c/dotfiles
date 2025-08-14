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
