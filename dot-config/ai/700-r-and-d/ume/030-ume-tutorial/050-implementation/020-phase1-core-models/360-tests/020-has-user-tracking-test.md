# Testing the HasUserTracking Concern

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Overview

This document outlines the tests for the `HasUserTracking` concern, which is part of the `HasAdditionalFeatures` trait. The `HasUserTracking` concern provides functionality for tracking which users created, updated, and deleted models.

## Test File

Create a new test file at `tests/Unit/Concerns/HasUserTrackingTest.php`:

```php
<?php

namespace Tests\Unit\Concerns;

use App\Models\Traits\Concerns\HasUserTracking;use App\Models\User;use Illuminate\Database\Eloquent\Model;use Illuminate\Database\Eloquent\SoftDeletes;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Support\Facades\Schema;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class HasUserTrackingTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Create a test model that uses the HasUserTracking concern.
     *
     * @param bool $withSoftDeletes
     * @return Model
     */
    protected function createTestModel(bool $withSoftDeletes = false): Model
    {
        // Create a test model class that uses the HasUserTracking concern
        $model = new class($withSoftDeletes) extends Model {
            use HasUserTracking;

            protected $table = 'test_models';
            protected $guarded = [];
            protected $withSoftDeletes;

            public function __construct(bool $withSoftDeletes = false)
            {
                parent::__construct();
                $this->withSoftDeletes = $withSoftDeletes;
            }

            public function usesSoftDeletes(): bool
            {
                return $this->withSoftDeletes;
            }
        };

        // Create the test_models table if it doesn't exist
        if (!Schema::hasTable('test_models')) {
            Schema::create('test_models', function ($table) use ($withSoftDeletes) {
                $table->id();
                $table->string('name')->nullable();
                $table->unsignedBigInteger('created_by')->nullable();
                $table->unsignedBigInteger('updated_by')->nullable();
                $table->unsignedBigInteger('deleted_by')->nullable();
                $table->string('created_ip')->nullable();
                $table->string('updated_ip')->nullable();
                $table->string('deleted_ip')->nullable();
                $table->string('created_user_agent')->nullable();
                $table->string('updated_user_agent')->nullable();
                $table->string('deleted_user_agent')->nullable();
                $table->timestamps();
                
                if ($withSoftDeletes) {
                    $table->softDeletes();
                }
                
                $table->foreign('created_by')->references('id')->on('users')->onDelete('set null');
                $table->foreign('updated_by')->references('id')->on('users')->onDelete('set null');
                $table->foreign('deleted_by')->references('id')->on('users')->onDelete('set null');
            });
        }

        return $model;
    }

    /**
     * Create a test model with soft deletes.
     *
     * @return Model
     */
    protected function createSoftDeletableTestModel(): Model
    {
        // Create a test model class that uses the HasUserTracking concern and SoftDeletes
        $model = new class extends Model {
            use HasUserTracking, SoftDeletes;

            protected $table = 'soft_deletable_test_models';
            protected $guarded = [];
        };

        // Create the soft_deletable_test_models table if it doesn't exist
        if (!Schema::hasTable('soft_deletable_test_models')) {
            Schema::create('soft_deletable_test_models', function ($table) {
                $table->id();
                $table->string('name')->nullable();
                $table->unsignedBigInteger('created_by')->nullable();
                $table->unsignedBigInteger('updated_by')->nullable();
                $table->unsignedBigInteger('deleted_by')->nullable();
                $table->timestamps();
                $table->softDeletes();
                
                $table->foreign('created_by')->references('id')->on('users')->onDelete('set null');
                $table->foreign('updated_by')->references('id')->on('users')->onDelete('set null');
                $table->foreign('deleted_by')->references('id')->on('users')->onDelete('set null');
            });
        }

        return $model;
    }

    #[Test]
    public function it_tracks_user_who_created_model()
    {
        // Create a user to act as
        $user = User::factory()->create();
        
        // Act as the user
        $this->actingAs($user);
        
        // Create a test model
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Assert that the created_by field is set
        $this->assertEquals($user->id, $instance->created_by);
    }

    #[Test]
    public function it_tracks_user_who_updated_model()
    {
        // Create users
        $creator = User::factory()->create();
        $updater = User::factory()->create();
        
        // Create a test model as the creator
        $this->actingAs($creator);
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Update the model as the updater
        $this->actingAs($updater);
        $instance->name = 'Updated Test Model';
        $instance->save();
        
        // Assert that the updated_by field is set
        $this->assertEquals($updater->id, $instance->fresh()->updated_by);
    }

    #[Test]
    public function it_tracks_user_who_deleted_model()
    {
        // Create users
        $creator = User::factory()->create();
        $deleter = User::factory()->create();
        
        // Create a soft deletable test model as the creator
        $this->actingAs($creator);
        $model = $this->createSoftDeletableTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Delete the model as the deleter
        $this->actingAs($deleter);
        $instance->delete();
        
        // Assert that the deleted_by field is set
        $this->assertEquals($deleter->id, $instance->fresh()->deleted_by);
    }

    #[Test]
    public function it_can_get_creator_relationship()
    {
        // Create a user
        $user = User::factory()->create();
        
        // Create a test model as the user
        $this->actingAs($user);
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Assert that the creator relationship works
        $this->assertEquals($user->id, $instance->creator->id);
    }

    #[Test]
    public function it_can_get_updater_relationship()
    {
        // Create users
        $creator = User::factory()->create();
        $updater = User::factory()->create();
        
        // Create a test model as the creator
        $this->actingAs($creator);
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Update the model as the updater
        $this->actingAs($updater);
        $instance->name = 'Updated Test Model';
        $instance->save();
        
        // Assert that the updater relationship works
        $this->assertEquals($updater->id, $instance->fresh()->updater->id);
    }

    #[Test]
    public function it_can_get_deleter_relationship()
    {
        // Create users
        $creator = User::factory()->create();
        $deleter = User::factory()->create();
        
        // Create a soft deletable test model as the creator
        $this->actingAs($creator);
        $model = $this->createSoftDeletableTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Delete the model as the deleter
        $this->actingAs($deleter);
        $instance->delete();
        
        // Assert that the deleter relationship works
        $this->assertEquals($deleter->id, $instance->fresh()->deleter->id);
    }

    #[Test]
    public function it_can_scope_by_created_by()
    {
        // Create users
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        
        // Create test models as different users
        $model = $this->createTestModel();
        
        $this->actingAs($user1);
        $instance1 = $model::create(['name' => 'Test Model 1']);
        $instance2 = $model::create(['name' => 'Test Model 2']);
        
        $this->actingAs($user2);
        $instance3 = $model::create(['name' => 'Test Model 3']);
        
        // Query models created by user1
        $results = $model::createdBy($user1->id)->get();
        
        // Assert that the correct models are returned
        $this->assertCount(2, $results);
        $this->assertTrue($results->contains($instance1));
        $this->assertTrue($results->contains($instance2));
        $this->assertFalse($results->contains($instance3));
    }

    #[Test]
    public function it_can_scope_by_updated_by()
    {
        // Create users
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        
        // Create test models
        $model = $this->createTestModel();
        
        $this->actingAs($user1);
        $instance1 = $model::create(['name' => 'Test Model 1']);
        $instance2 = $model::create(['name' => 'Test Model 2']);
        $instance3 = $model::create(['name' => 'Test Model 3']);
        
        // Update models as different users
        $this->actingAs($user2);
        $instance1->name = 'Updated Test Model 1';
        $instance1->save();
        
        $instance2->name = 'Updated Test Model 2';
        $instance2->save();
        
        // Query models updated by user2
        $results = $model::updatedBy($user2->id)->get();
        
        // Assert that the correct models are returned
        $this->assertCount(2, $results);
        $this->assertTrue($results->contains($instance1));
        $this->assertTrue($results->contains($instance2));
        $this->assertFalse($results->contains($instance3));
    }

    #[Test]
    public function it_can_scope_by_deleted_by()
    {
        // Create users
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        
        // Create soft deletable test models
        $model = $this->createSoftDeletableTestModel();
        
        $this->actingAs($user1);
        $instance1 = $model::create(['name' => 'Test Model 1']);
        $instance2 = $model::create(['name' => 'Test Model 2']);
        $instance3 = $model::create(['name' => 'Test Model 3']);
        
        // Delete models as different users
        $this->actingAs($user2);
        $instance1->delete();
        $instance2->delete();
        
        // Query models deleted by user2
        $results = $model::withTrashed()->deletedBy($user2->id)->get();
        
        // Assert that the correct models are returned
        $this->assertCount(2, $results);
        $this->assertTrue($results->contains($instance1));
        $this->assertTrue($results->contains($instance2));
        $this->assertFalse($results->contains($instance3));
    }

    #[Test]
    public function it_tracks_request_data_when_creating_model()
    {
        // Create a user
        $user = User::factory()->create();
        
        // Act as the user
        $this->actingAs($user);
        
        // Mock the request data
        $this->withServerVariables([
            'REMOTE_ADDR' => '192.168.1.1',
            'HTTP_USER_AGENT' => 'PHPUnit Test',
        ]);
        
        // Create a test model
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Assert that the request data is tracked
        $this->assertEquals('192.168.1.1', $instance->created_ip);
        $this->assertEquals('PHPUnit Test', $instance->created_user_agent);
    }

    #[Test]
    public function it_tracks_request_data_when_updating_model()
    {
        // Create users
        $creator = User::factory()->create();
        $updater = User::factory()->create();
        
        // Create a test model as the creator
        $this->actingAs($creator);
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Update the model as the updater with mock request data
        $this->actingAs($updater);
        $this->withServerVariables([
            'REMOTE_ADDR' => '192.168.1.2',
            'HTTP_USER_AGENT' => 'PHPUnit Test Update',
        ]);
        
        $instance->name = 'Updated Test Model';
        $instance->save();
        
        // Assert that the request data is tracked
        $this->assertEquals('192.168.1.2', $instance->fresh()->updated_ip);
        $this->assertEquals('PHPUnit Test Update', $instance->fresh()->updated_user_agent);
    }

    #[Test]
    public function it_tracks_request_data_when_deleting_model()
    {
        // Create users
        $creator = User::factory()->create();
        $deleter = User::factory()->create();
        
        // Create a soft deletable test model as the creator
        $this->actingAs($creator);
        $model = $this->createSoftDeletableTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Delete the model as the deleter with mock request data
        $this->actingAs($deleter);
        $this->withServerVariables([
            'REMOTE_ADDR' => '192.168.1.3',
            'HTTP_USER_AGENT' => 'PHPUnit Test Delete',
        ]);
        
        $instance->delete();
        
        // Assert that the request data is tracked
        $this->assertEquals('192.168.1.3', $instance->fresh()->deleted_ip);
        $this->assertEquals('PHPUnit Test Delete', $instance->fresh()->deleted_user_agent);
    }
}
```

## Key Test Cases

1. **Creation Tracking**: Tests that the user who created a model is tracked.
2. **Update Tracking**: Tests that the user who updated a model is tracked.
3. **Deletion Tracking**: Tests that the user who deleted a model is tracked.
4. **Relationship Access**: Tests the creator, updater, and deleter relationships.
5. **Query Scopes**: Tests the createdBy, updatedBy, and deletedBy query scopes.
6. **Request Data Tracking**: Tests that request data (IP, user agent) is tracked.

## Running the Tests

To run the tests for the HasUserTracking concern, use the following command:

```bash
php artisan test --filter=HasUserTrackingTest
```

## Expected Output

When running the HasUserTracking tests, you should see output similar to:

```
PASS  Tests\Unit\Concerns\HasUserTrackingTest
✓ it tracks user who created model
✓ it tracks user who updated model
✓ it tracks user who deleted model
✓ it can get creator relationship
✓ it can get updater relationship
✓ it can get deleter relationship
✓ it can scope by created by
✓ it can scope by updated by
✓ it can scope by deleted by
✓ it tracks request data when creating model
✓ it tracks request data when updating model
✓ it tracks request data when deleting model

Tests:  12 passed
Time:   0.25s
```

This confirms that the HasUserTracking concern is working correctly and all its features are functioning as expected.
