# Testing in Phase 5: Advanced Features

This document outlines the testing approach for the Advanced Features phase of the UME tutorial. Comprehensive testing is essential to ensure that our advanced features like tagging, activity logging, and user impersonation are working correctly.

## Testing Strategy

For the Advanced Features phase, we'll focus on:

1. **Tagging Tests**: Ensure that tagging functionality works correctly
2. **Activity Logging Tests**: Verify that user activities are correctly logged
3. **User Impersonation Tests**: Test that user impersonation works correctly
4. **Integration Tests**: Test how these components work together

## Tagging Tests

```php
<?php

namespace Tests\Feature\Tagging;

use App\Models\Team;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;use Spatie\Tags\Tag;

class TaggingTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function model_can_be_tagged()
    {
        $team = Team::factory()->create(['name' => 'Development Team']);
        
        $team->attachTag('important');
        
        $this->assertTrue($team->hasTag('important'));
    }

    #[Test]
    public function model_can_be_tagged_with_multiple_tags()
    {
        $team = Team::factory()->create();
        
        $team->attachTags(['important', 'urgent', 'featured']);
        
        $this->assertTrue($team->hasTag('important'));
        $this->assertTrue($team->hasTag('urgent'));
        $this->assertTrue($team->hasTag('featured'));
    }

    #[Test]
    public function tags_can_be_detached()
    {
        $team = Team::factory()->create();
        
        $team->attachTags(['important', 'urgent']);
        $this->assertTrue($team->hasTag('important'));
        
        $team->detachTag('important');
        $this->assertFalse($team->hasTag('important'));
        $this->assertTrue($team->hasTag('urgent'));
    }

    #[Test]
    public function all_tags_can_be_detached()
    {
        $team = Team::factory()->create();
        
        $team->attachTags(['important', 'urgent', 'featured']);
        $this->assertCount(3, $team->tags);
        
        $team->detachTags();
        $this->assertCount(0, $team->fresh()->tags);
    }

    #[Test]
    public function tags_can_be_synced()
    {
        $team = Team::factory()->create();
        
        $team->attachTags(['important', 'urgent']);
        $this->assertTrue($team->hasTag('important'));
        $this->assertTrue($team->hasTag('urgent'));
        
        $team->syncTags(['featured', 'important']);
        $this->assertTrue($team->fresh()->hasTag('important'));
        $this->assertFalse($team->fresh()->hasTag('urgent'));
        $this->assertTrue($team->fresh()->hasTag('featured'));
    }

    #[Test]
    public function models_can_be_found_by_tag()
    {
        $team1 = Team::factory()->create(['name' => 'Team 1']);
        $team2 = Team::factory()->create(['name' => 'Team 2']);
        $team3 = Team::factory()->create(['name' => 'Team 3']);
        
        $team1->attachTag('important');
        $team2->attachTag('important');
        $team3->attachTag('featured');
        
        $importantTeams = Team::withAnyTags(['important'])->get();
        
        $this->assertCount(2, $importantTeams);
        $this->assertTrue($importantTeams->contains($team1));
        $this->assertTrue($importantTeams->contains($team2));
        $this->assertFalse($importantTeams->contains($team3));
    }

    #[Test]
    public function models_can_be_found_by_multiple_tags()
    {
        $team1 = Team::factory()->create();
        $team2 = Team::factory()->create();
        $team3 = Team::factory()->create();
        
        $team1->attachTags(['important', 'urgent']);
        $team2->attachTags(['important', 'featured']);
        $team3->attachTag('featured');
        
        // Find teams with any of the tags
        $teams = Team::withAnyTags(['important', 'featured'])->get();
        $this->assertCount(3, $teams);
        
        // Find teams with all of the tags
        $teams = Team::withAllTags(['important', 'featured'])->get();
        $this->assertCount(1, $teams);
        $this->assertTrue($teams->contains($team2));
    }

    #[Test]
    public function tags_can_have_types()
    {
        $team = Team::factory()->create();
        
        $team->attachTag('important', 'priority');
        $team->attachTag('development', 'department');
        
        $this->assertTrue($team->hasTag('important', 'priority'));
        $this->assertTrue($team->hasTag('development', 'department'));
        
        $priorityTags = $team->tagsWithType('priority');
        $this->assertCount(1, $priorityTags);
        $this->assertEquals('important', $priorityTags->first()->name);
    }
}
```

## Activity Logging Tests

```php
<?php

namespace Tests\Feature\ActivityLog;

use App\Models\Team;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;use Spatie\Activitylog\Models\Activity;

class ActivityLogTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function model_changes_are_logged()
    {
        $team = Team::factory()->create(['name' => 'Original Name']);
        
        $team->name = 'Updated Name';
        $team->save();
        
        $this->assertCount(2, Activity::all()); // Create and update
        
        $updateActivity = Activity::latest()->first();
        $this->assertEquals('updated', $updateActivity->description);
        $this->assertEquals(Team::class, $updateActivity->subject_type);
        $this->assertEquals($team->id, $updateActivity->subject_id);
    }

    #[Test]
    public function logged_activity_contains_old_and_new_values()
    {
        $team = Team::factory()->create(['name' => 'Original Name']);
        
        $team->name = 'Updated Name';
        $team->save();
        
        $activity = Activity::latest()->first();
        
        $this->assertArrayHasKey('attributes', $activity->properties);
        $this->assertArrayHasKey('old', $activity->properties);
        
        $this->assertEquals('Updated Name', $activity->properties['attributes']['name']);
        $this->assertEquals('Original Name', $activity->properties['old']['name']);
    }

    #[Test]
    public function only_changed_attributes_are_logged()
    {
        $team = Team::factory()->create([
            'name' => 'Team Name',
            'description' => 'Team Description',
        ]);
        
        $team->name = 'Updated Name';
        $team->save();
        
        $activity = Activity::latest()->first();
        
        $this->assertArrayHasKey('name', $activity->properties['attributes']);
        $this->assertArrayNotHasKey('description', $activity->properties['attributes']);
    }

    #[Test]
    public function model_deletion_is_logged()
    {
        $team = Team::factory()->create();
        
        $team->delete();
        
        $this->assertCount(2, Activity::all()); // Create and delete
        
        $deleteActivity = Activity::latest()->first();
        $this->assertEquals('deleted', $deleteActivity->description);
        $this->assertEquals(Team::class, $deleteActivity->subject_type);
        $this->assertEquals($team->id, $deleteActivity->subject_id);
    }

    #[Test]
    public function custom_activity_can_be_logged()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create();
        
        activity()
            ->causedBy($user)
            ->performedOn($team)
            ->withProperties(['key' => 'value'])
            ->log('Custom activity description');
        
        $activity = Activity::latest()->first();
        
        $this->assertEquals('Custom activity description', $activity->description);
        $this->assertEquals(User::class, $activity->causer_type);
        $this->assertEquals($user->id, $activity->causer_id);
        $this->assertEquals(Team::class, $activity->subject_type);
        $this->assertEquals($team->id, $activity->subject_id);
        $this->assertEquals('value', $activity->properties['key']);
    }

    #[Test]
    public function activity_can_be_logged_with_causer()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create();
        
        // Set the authenticated user
        $this->actingAs($user);
        
        // Update the team
        $team->name = 'Updated by User';
        $team->save();
        
        $activity = Activity::latest()->first();
        
        $this->assertEquals(User::class, $activity->causer_type);
        $this->assertEquals($user->id, $activity->causer_id);
    }

    #[Test]
    public function activities_can_be_retrieved_for_model()
    {
        $team = Team::factory()->create(['name' => 'Original Name']);
        
        $team->name = 'First Update';
        $team->save();
        
        $team->name = 'Second Update';
        $team->save();
        
        $activities = $team->activities;
        
        $this->assertCount(3, $activities); // Create and two updates
        $this->assertEquals('created', $activities[0]->description);
        $this->assertEquals('updated', $activities[1]->description);
        $this->assertEquals('updated', $activities[2]->description);
    }

    #[Test]
    public function activities_can_be_retrieved_for_causer()
    {
        $user = User::factory()->create();
        $team1 = Team::factory()->create();
        $team2 = Team::factory()->create();
        
        activity()
            ->causedBy($user)
            ->performedOn($team1)
            ->log('Action on team 1');
            
        activity()
            ->causedBy($user)
            ->performedOn($team2)
            ->log('Action on team 2');
        
        $activities = Activity::causedBy($user)->get();
        
        $this->assertCount(2, $activities);
        $this->assertEquals($user->id, $activities[0]->causer_id);
        $this->assertEquals($user->id, $activities[1]->causer_id);
    }
}
```

## User Impersonation Tests

```php
<?php

namespace Tests\Feature\Impersonation;

use App\Models\Admin;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class ImpersonationTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function admin_can_impersonate_user()
    {
        $admin = Admin::factory()->create();
        $user = User::factory()->create();
        
        // Admin logs in
        $this->actingAs($admin);
        
        // Admin starts impersonating the user
        $response = $this->post("/impersonate/{$user->id}");
        
        $response->assertRedirect('/dashboard');
        $this->assertTrue(session()->has('impersonate'));
        $this->assertEquals($user->id, session('impersonate'));
    }

    #[Test]
    public function regular_user_cannot_impersonate()
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        
        // User1 logs in
        $this->actingAs($user1);
        
        // User1 tries to impersonate User2
        $response = $this->post("/impersonate/{$user2->id}");
        
        $response->assertStatus(403);
        $this->assertFalse(session()->has('impersonate'));
    }

    #[Test]
    public function impersonation_can_be_stopped()
    {
        $admin = Admin::factory()->create();
        $user = User::factory()->create();
        
        // Admin logs in and starts impersonating
        $this->actingAs($admin);
        session(['impersonate' => $user->id]);
        
        // Stop impersonating
        $response = $this->delete('/impersonate');
        
        $response->assertRedirect('/dashboard');
        $this->assertFalse(session()->has('impersonate'));
    }

    #[Test]
    public function middleware_correctly_handles_impersonation()
    {
        $admin = Admin::factory()->create();
        $user = User::factory()->create();
        
        // Admin logs in
        $this->actingAs($admin);
        
        // Without impersonation, the authenticated user is the admin
        $this->assertEquals($admin->id, auth()->id());
        
        // Start impersonating
        session(['impersonate' => $user->id]);
        
        // With impersonation, the authenticated user should be the user
        // Note: This requires the impersonation middleware to be applied to the request
        $response = $this->get('/dashboard');
        
        // The response should indicate that we're impersonating
        $response->assertSee('Impersonating');
        
        // In a real application, we would check that auth()->id() returns the impersonated user's ID
        // but this requires the middleware to run, which is difficult to test directly
    }

    #[Test]
    public function impersonation_is_logged()
    {
        $admin = Admin::factory()->create();
        $user = User::factory()->create();
        
        // Admin logs in
        $this->actingAs($admin);
        
        // Admin starts impersonating the user
        $this->post("/impersonate/{$user->id}");
        
        // Check that the activity was logged
        $this->assertDatabaseHas('activity_log', [
            'description' => 'started impersonating',
            'causer_type' => Admin::class,
            'causer_id' => $admin->id,
            'subject_type' => User::class,
            'subject_id' => $user->id,
        ]);
        
        // Stop impersonating
        $this->delete('/impersonate');
        
        // Check that the stop activity was logged
        $this->assertDatabaseHas('activity_log', [
            'description' => 'stopped impersonating',
            'causer_type' => Admin::class,
            'causer_id' => $admin->id,
            'subject_type' => User::class,
            'subject_id' => $user->id,
        ]);
    }

    #[Test]
    public function impersonated_actions_are_attributed_to_real_user()
    {
        $admin = Admin::factory()->create();
        $user = User::factory()->create();
        $team = Team::factory()->create();
        
        // Admin logs in and starts impersonating
        $this->actingAs($admin);
        session(['impersonate' => $user->id]);
        
        // Perform an action while impersonating
        $response = $this->post("/teams/{$team->id}/members", [
            'email' => User::factory()->create()->email,
            'role' => 'member',
        ]);
        
        // Check that the activity was logged with the admin as the real causer
        $this->assertDatabaseHas('activity_log', [
            'description' => 'added team member',
            'causer_type' => Admin::class,
            'causer_id' => $admin->id,
            'properties->impersonator_id' => $admin->id,
            'properties->impersonated_id' => $user->id,
        ]);
    }
}
```

## Integration Tests

```php
<?php

namespace Tests\Feature;

use App\Models\Admin;use App\Models\Team;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;use Spatie\Activitylog\Models\Activity;

class AdvancedFeaturesIntegrationTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function tagging_and_activity_logging_work_together()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create();
        
        $this->actingAs($user);
        
        // Add tags to the team
        $response = $this->post("/teams/{$team->id}/tags", [
            'tags' => ['important', 'featured'],
        ]);
        
        $response->assertRedirect();
        
        // Check that the tags were added
        $this->assertTrue($team->fresh()->hasTag('important'));
        $this->assertTrue($team->fresh()->hasTag('featured'));
        
        // Check that the activity was logged
        $this->assertDatabaseHas('activity_log', [
            'description' => 'added tags',
            'causer_type' => User::class,
            'causer_id' => $user->id,
            'subject_type' => Team::class,
            'subject_id' => $team->id,
        ]);
        
        // Get the activity and check the properties
        $activity = Activity::latest()->first();
        $this->assertArrayHasKey('tags', $activity->properties);
        $this->assertContains('important', $activity->properties['tags']);
        $this->assertContains('featured', $activity->properties['tags']);
    }

    #[Test]
    public function impersonation_and_activity_logging_work_together()
    {
        $admin = Admin::factory()->create();
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $user->id]);
        
        // Admin logs in and starts impersonating
        $this->actingAs($admin);
        $this->post("/impersonate/{$user->id}");
        
        // Update the team while impersonating
        $response = $this->put("/teams/{$team->id}", [
            'name' => 'Updated Team Name',
            'description' => 'Updated description',
        ]);
        
        $response->assertRedirect();
        
        // Check that the team was updated
        $this->assertEquals('Updated Team Name', $team->fresh()->name);
        
        // Check that the activity was logged with impersonation info
        $activity = Activity::where('description', 'updated')->latest()->first();
        $this->assertEquals(Admin::class, $activity->causer_type);
        $this->assertEquals($admin->id, $activity->causer_id);
        $this->assertArrayHasKey('impersonated_id', $activity->properties);
        $this->assertEquals($user->id, $activity->properties['impersonated_id']);
    }

    #[Test]
    public function tagging_and_impersonation_work_together()
    {
        $admin = Admin::factory()->create();
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $user->id]);
        
        // Admin logs in and starts impersonating
        $this->actingAs($admin);
        $this->post("/impersonate/{$user->id}");
        
        // Add tags to the team while impersonating
        $response = $this->post("/teams/{$team->id}/tags", [
            'tags' => ['important', 'featured'],
        ]);
        
        $response->assertRedirect();
        
        // Check that the tags were added
        $this->assertTrue($team->fresh()->hasTag('important'));
        $this->assertTrue($team->fresh()->hasTag('featured'));
        
        // Check that the activity was logged with impersonation info
        $activity = Activity::where('description', 'added tags')->latest()->first();
        $this->assertEquals(Admin::class, $activity->causer_type);
        $this->assertEquals($admin->id, $activity->causer_id);
        $this->assertArrayHasKey('impersonated_id', $activity->properties);
        $this->assertEquals($user->id, $activity->properties['impersonated_id']);
    }

    #[Test]
    public function complete_advanced_features_workflow()
    {
        // Create users and team
        $admin = Admin::factory()->create();
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $user->id, 'name' => 'Original Team']);
        
        // Step 1: Admin logs in
        $this->actingAs($admin);
        
        // Step 2: Admin starts impersonating the user
        $this->post("/impersonate/{$user->id}");
        $this->assertTrue(session()->has('impersonate'));
        
        // Step 3: While impersonating, update the team
        $this->put("/teams/{$team->id}", [
            'name' => 'Updated Team',
            'description' => 'Updated by admin impersonating user',
        ]);
        
        // Step 4: Add tags to the team
        $this->post("/teams/{$team->id}/tags", [
            'tags' => ['important', 'featured'],
        ]);
        
        // Step 5: Stop impersonating
        $this->delete('/impersonate');
        $this->assertFalse(session()->has('impersonate'));
        
        // Step 6: Verify the changes
        $team->refresh();
        $this->assertEquals('Updated Team', $team->name);
        $this->assertTrue($team->hasTag('important'));
        $this->assertTrue($team->hasTag('featured'));
        
        // Step 7: Check the activity log
        $activities = Activity::latest()->take(4)->get()->reverse();
        
        // First activity: Started impersonating
        $this->assertEquals('started impersonating', $activities[0]->description);
        $this->assertEquals(Admin::class, $activities[0]->causer_type);
        $this->assertEquals($admin->id, $activities[0]->causer_id);
        
        // Second activity: Updated team
        $this->assertEquals('updated', $activities[1]->description);
        $this->assertEquals(Admin::class, $activities[1]->causer_type);
        $this->assertEquals($admin->id, $activities[1]->causer_id);
        $this->assertEquals('Updated Team', $activities[1]->properties['attributes']['name']);
        $this->assertEquals('Original Team', $activities[1]->properties['old']['name']);
        
        // Third activity: Added tags
        $this->assertEquals('added tags', $activities[2]->description);
        $this->assertArrayHasKey('tags', $activities[2]->properties);
        
        // Fourth activity: Stopped impersonating
        $this->assertEquals('stopped impersonating', $activities[3]->description);
    }
}
```

## Running the Tests

To run the tests for the Advanced Features phase, use the following command:

```bash
php artisan test --filter=TaggingTest,ActivityLogTest,ImpersonationTest,AdvancedFeaturesIntegrationTest
```

Or run all tests with:

```bash
php artisan test
```

## Test Coverage

To ensure comprehensive test coverage for the Advanced Features phase, make sure your tests cover:

1. Tagging functionality (adding, removing, and querying tags)
2. Activity logging (creating, retrieving, and analyzing activity logs)
3. User impersonation (starting, stopping, and handling impersonation)
4. Integration between these components

## Best Practices

1. **Use PHP Attributes**: Always use PHP 8 attributes (`#[Test]`) instead of PHPDoc annotations (`/** @test */`).
2. **Test Tag Management**: Verify that tags can be added, removed, and queried correctly.
3. **Test Activity Logging**: Ensure that activities are correctly logged with all necessary information.
4. **Test Impersonation Security**: Verify that only authorized users can impersonate others and that impersonation is properly tracked.
5. **Test Integration**: Ensure that these components work together correctly in real-world scenarios.
6. **Use RefreshDatabase**: Use the RefreshDatabase trait to ensure a clean database state for each test.
7. **Test Edge Cases**: Consider edge cases like impersonating users with different permissions or logging activities with complex properties.

By following these guidelines, you'll ensure that your Advanced Features phase is thoroughly tested and ready for the next phases of the UME tutorial.
