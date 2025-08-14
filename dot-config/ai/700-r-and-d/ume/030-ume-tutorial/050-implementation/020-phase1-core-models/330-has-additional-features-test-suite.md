# Comprehensive Test Suite for HasAdditionalFeatures Trait

<link rel="stylesheet" href="../../assets/css/styles.css">

## Overview

This document outlines a comprehensive test suite for the HasAdditionalFeatures trait. These tests ensure that all features of the trait work correctly and integrate well with other components of the application.

## Test Structure

The test suite is organized into several test classes:

1. **HasAdditionalFeaturesTraitTest**: Tests the core functionality of the trait
2. **FlagsTest**: Tests the Flags enum
3. **HasAdditionalFeaturesIntegrationTest**: Tests integration with other components

## HasAdditionalFeaturesTraitTest

This test class focuses on the core functionality of the HasAdditionalFeatures trait:

```php
<?php

namespace Tests\Unit\Traits;

use App\Enums\Flags;use App\Models\Team;use App\Models\Traits\HasAdditionalFeatures;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class HasAdditionalFeaturesTraitTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_generates_ulid_on_creation()
    {
        $user = User::factory()->create();

        $this->assertNotNull($user->ulid);
        $this->assertEquals(26, strlen($user->ulid));
    }

    #[Test]
    public function it_can_get_display_name()
    {
        $user = User::factory()->create([
            'given_name' => 'John',
            'family_name' => 'Doe',
        ]);

        $this->assertEquals('John Doe', $user->getDisplayName());
    }

    #[Test]
    public function it_can_get_route_key_name()
    {
        $user = User::factory()->create();

        // Should return 'ulid' or 'slug' based on configuration
        $this->assertContains($user->getRouteKeyName(), ['ulid', 'slug', 'id']);
    }

    #[Test]
    public function it_can_check_if_feature_is_enabled()
    {
        // This test assumes that ULID is enabled in the configuration
        $this->assertTrue(User::isFeatureEnabled('ulid'));
    }

    #[Test]
    public function it_can_temporarily_disable_features()
    {
        $result = User::withoutFeatures(function () {
            return User::isFeatureEnabled('ulid');
        });

        $this->assertFalse($result);

        // Features should be re-enabled outside the callback
        $this->assertTrue(User::isFeatureEnabled('ulid'));
    }

    #[Test]
    public function it_can_add_and_check_flags()
    {
        $user = User::factory()->create();

        // Add a flag
        $user->flag(Flags::VERIFIED->value);

        // Check if the flag exists
        $this->assertTrue($user->hasFlag(Flags::VERIFIED->value));
        $this->assertFalse($user->hasFlag(Flags::FEATURED->value));

        // Remove the flag
        $user->unflag(Flags::VERIFIED->value);

        // Check if the flag is removed
        $this->assertFalse($user->hasFlag(Flags::VERIFIED->value));
    }

    #[Test]
    public function it_validates_flags_against_enum()
    {
        $user = User::factory()->create();

        // This should work fine
        $user->flag(Flags::VERIFIED->value);

        // This should throw an exception
        $this->expectException(\InvalidArgumentException::class);
        $user->flag('invalid_flag');
    }

    #[Test]
    public function it_can_use_scopes_for_published_status()
    {
        // Create published and unpublished users
        $publishedUser = User::factory()->create(['published' => true]);
        $unpublishedUser = User::factory()->create(['published' => false]);

        // Query published users
        $publishedUsers = User::published()->get();

        // Query unpublished users
        $unpublishedUsers = User::draft()->get();

        // Check results
        $this->assertTrue($publishedUsers->contains($publishedUser));
        $this->assertFalse($publishedUsers->contains($unpublishedUser));

        $this->assertFalse($unpublishedUsers->contains($publishedUser));
        $this->assertTrue($unpublishedUsers->contains($unpublishedUser));
    }

    #[Test]
    public function it_can_add_and_query_tags()
    {
        $user = User::factory()->create();

        // Add tags
        $user->attachTag('developer');
        $user->attachTag('admin', 'role');

        // Check if tags exist
        $this->assertTrue($user->hasTag('developer'));
        $this->assertTrue($user->hasTag('admin', 'role'));

        // Query by tags
        $usersWithDeveloperTag = User::withAllTags(['developer'])->get();
        $usersWithAdminRoleTag = User::withAllTags(['admin'], 'role')->get();

        // Check results
        $this->assertTrue($usersWithDeveloperTag->contains($user));
        $this->assertTrue($usersWithAdminRoleTag->contains($user));

        // Remove a tag
        $user->detachTag('developer');

        // Check if tag is removed
        $this->assertFalse($user->fresh()->hasTag('developer'));
        $this->assertTrue($user->fresh()->hasTag('admin', 'role'));
    }

    #[Test]
    public function it_can_get_tags_with_type()
    {
        $user = User::factory()->create();

        // Add tags with different types
        $user->attachTag('developer', 'profession');
        $user->attachTag('admin', 'role');

        // Get tags with specific type
        $professionTags = $user->tagsWithType('profession');
        $roleTags = $user->tagsWithType('role');

        // Check results
        $this->assertCount(1, $professionTags);
        $this->assertEquals('developer', $professionTags->first()->name);

        $this->assertCount(1, $roleTags);
        $this->assertEquals('admin', $roleTags->first()->name);
    }

    #[Test]
    public function it_can_get_searchable_array()
    {
        $user = User::factory()->create([
            'given_name' => 'John',
            'family_name' => 'Doe',
        ]);

        // Add a tag
        $user->attachTag('developer');

        // Get searchable array
        $searchableArray = $user->toSearchableArray();

        // Check array contents
        $this->assertArrayHasKey('id', $searchableArray);
        $this->assertArrayHasKey('name', $searchableArray);
        $this->assertEquals($user->id, $searchableArray['id']);
        $this->assertEquals('John Doe', $searchableArray['name']);

        // Check if tags are included if configured
        if (User::isFeatureEnabled('tags') && in_array('tags', config('additional-features.search.default_fields', []))) {
            $this->assertArrayHasKey('tags', $searchableArray);
            $this->assertContains('developer', $searchableArray['tags']);
        }
    }

    #[Test]
    public function it_tracks_user_who_created_model()
    {
        // Skip if user tracking is disabled
        if (!User::isFeatureEnabled('user_tracking')) {
            $this->markTestSkipped('User tracking is disabled');
        }

        // Create a user to act as
        $actingUser = User::factory()->create();

        // Act as the user
        $this->actingAs($actingUser);

        // Create a new user
        $user = User::factory()->create();

        // Check that the created_by field is set
        $this->assertEquals($actingUser->id, $user->created_by);
    }

    #[Test]
    public function it_tracks_user_who_updated_model()
    {
        // Skip if user tracking is disabled
        if (!User::isFeatureEnabled('user_tracking')) {
            $this->markTestSkipped('User tracking is disabled');
        }

        // Create users
        $user = User::factory()->create();
        $actingUser = User::factory()->create();

        // Act as the user
        $this->actingAs($actingUser);

        // Update the user
        $user->given_name = 'Updated';
        $user->save();

        // Check that the updated_by field is set
        $this->assertEquals($actingUser->id, $user->fresh()->updated_by);
    }

    #[Test]
    public function it_can_get_creator_and_updater()
    {
        // Skip if user tracking is disabled
        if (!User::isFeatureEnabled('user_tracking')) {
            $this->markTestSkipped('User tracking is disabled');
        }

        // Create users
        $creator = User::factory()->create();
        $updater = User::factory()->create();

        // Create a user with creator
        $this->actingAs($creator);
        $user = User::factory()->create();

        // Update the user with updater
        $this->actingAs($updater);
        $user->given_name = 'Updated';
        $user->save();

        // Check relationships
        $this->assertEquals($creator->id, $user->fresh()->creator->id);
        $this->assertEquals($updater->id, $user->fresh()->updater->id);
    }

    #[Test]
    public function it_can_use_created_by_scope()
    {
        // Skip if user tracking is disabled
        if (!User::isFeatureEnabled('user_tracking')) {
            $this->markTestSkipped('User tracking is disabled');
        }

        // Create users
        $creator = User::factory()->create();

        // Create users with different creators
        $this->actingAs($creator);
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        $otherCreator = User::factory()->create();
        $this->actingAs($otherCreator);
        $user3 = User::factory()->create();

        // Query users created by the first creator
        $usersCreatedByCreator = User::createdBy($creator->id)->get();

        // Check results
        $this->assertTrue($usersCreatedByCreator->contains($user1));
        $this->assertTrue($usersCreatedByCreator->contains($user2));
        $this->assertFalse($usersCreatedByCreator->contains($user3));
    }

    #[Test]
    public function it_determines_if_model_should_be_searchable()
    {
        $publishedUser = User::factory()->create(['published' => true]);
        $unpublishedUser = User::factory()->create(['published' => false]);

        // If exclude_unpublished is true (default), only published models should be searchable
        if (config('additional-features.search.exclude_unpublished', true)) {
            $this->assertTrue($publishedUser->shouldBeSearchable());
            $this->assertFalse($unpublishedUser->shouldBeSearchable());
        } else {
            $this->assertTrue($publishedUser->shouldBeSearchable());
            $this->assertTrue($unpublishedUser->shouldBeSearchable());
        }
    }

    #[Test]
    public function it_can_get_comment_url()
    {
        $user = User::factory()->create();

        $commentUrl = $user->commentUrl();

        $this->assertNotEmpty($commentUrl);
        $this->assertStringContainsString('users', $commentUrl);
    }

    #[Test]
    public function it_can_get_commentable_name()
    {
        $user = User::factory()->create([
            'given_name' => 'John',
            'family_name' => 'Doe',
        ]);

        $this->assertEquals('John Doe', $user->commentableName());
    }

    #[Test]
    public function it_can_get_activity_log_options()
    {
        $user = User::factory()->create();

        $logOptions = $user->getActivitylogOptions();

        $this->assertInstanceOf(\Spatie\Activitylog\LogOptions::class, $logOptions);
    }

    #[Test]
    public function it_can_get_slug_options()
    {
        $user = User::factory()->create();

        $slugOptions = $user->getSlugOptions();

        $this->assertInstanceOf(\Spatie\Sluggable\SlugOptions::class, $slugOptions);
    }
}
```

## HasAdditionalFeaturesIntegrationTest

This test class focuses on how the HasAdditionalFeatures trait integrates with other components:

```php
<?php

namespace Tests\Feature;

use App\Enums\Flags;use App\Models\Team;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Support\Facades\Config;use old\TestCase;use PHPUnit\Framework\Attributes\Test;use Spatie\Activitylog\Models\Activity;

class HasAdditionalFeaturesIntegrationTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_logs_activity_when_model_is_created()
    {
        // Enable activity logging
        Config::set('additional-features.enabled.activity_log', true);

        $user = User::factory()->create();

        // Check if activity was logged
        $this->assertDatabaseHas('activity_log', [
            'subject_type' => User::class,
            'subject_id' => $user->id,
            'description' => 'created',
        ]);
    }

    #[Test]
    public function it_logs_activity_when_model_is_updated()
    {
        // Enable activity logging
        Config::set('additional-features.enabled.activity_log', true);

        $user = User::factory()->create();

        // Update the user
        $user->given_name = 'Updated Name';
        $user->save();

        // Check if activity was logged
        $this->assertDatabaseHas('activity_log', [
            'subject_type' => User::class,
            'subject_id' => $user->id,
            'description' => 'updated',
        ]);
    }

    #[Test]
    public function it_can_add_comments_to_model()
    {
        // Enable comments
        Config::set('additional-features.enabled.comments', true);

        $user = User::factory()->create();
        $commenter = User::factory()->create();

        // Add a comment
        $this->actingAs($commenter);
        $comment = $user->comment('This is a test comment');

        // Check if comment was added
        $this->assertEquals('This is a test comment', $comment->text);
        $this->assertEquals($commenter->id, $comment->user_id);
    }

    #[Test]
    public function it_can_use_flags_with_permissions()
    {
        $admin = User::factory()->create();
        $user = User::factory()->create();

        // Add a verified flag to the user
        $user->flag(Flags::VERIFIED->value);

        // Check if the user has the verified flag
        $this->assertTrue($user->hasFlag(Flags::VERIFIED->value));

        // Use the flag for permissions
        $canAccessFeature = $user->hasFlag(Flags::VERIFIED->value);
        $this->assertTrue($canAccessFeature);
    }

    #[Test]
    public function it_can_use_tags_for_filtering()
    {
        // Create users with different tags
        $developer = User::factory()->create();
        $developer->attachTag('developer');

        $designer = User::factory()->create();
        $designer->attachTag('designer');

        $manager = User::factory()->create();
        $manager->attachTag('manager');

        // Filter users by tag
        $developers = User::withAllTags(['developer'])->get();
        $designers = User::withAllTags(['designer'])->get();
        $managers = User::withAllTags(['manager'])->get();

        // Check results
        $this->assertCount(1, $developers);
        $this->assertCount(1, $designers);
        $this->assertCount(1, $managers);

        $this->assertTrue($developers->contains($developer));
        $this->assertTrue($designers->contains($designer));
        $this->assertTrue($managers->contains($manager));
    }

    #[Test]
    public function it_can_disable_features_via_configuration()
    {
        // Disable ULID generation
        Config::set('additional-features.enabled.ulid', false);

        $user = User::factory()->create();

        // ULID should not be generated
        $this->assertNull($user->ulid);

        // Re-enable ULID generation for other tests
        Config::set('additional-features.enabled.ulid', true);
    }

    #[Test]
    public function it_respects_model_specific_overrides()
    {
        // Set up a model-specific override
        Config::set('additional-features.model_overrides.' . User::class . '.enabled.tags', false);

        // Check if the override is respected
        $this->assertFalse(User::isFeatureEnabled('tags'));

        // Remove the override for other tests
        Config::set('additional-features.model_overrides.' . User::class, null);
    }
}
```

## Running the Tests

To run the full test suite, use the following command:

```bash
php artisan test --filter=HasAdditionalFeaturesTraitTest,FlagsTest,HasAdditionalFeaturesIntegrationTest
```

## Test Coverage

These tests cover:

1. **Core Functionality**: All methods and features of the trait
2. **Integration**: How the trait works with other components
3. **Configuration**: How configuration affects the trait's behavior
4. **Edge Cases**: Handling of special cases and error conditions

By running this comprehensive test suite, you can ensure that the HasAdditionalFeatures trait works correctly and integrates well with the rest of your application.
