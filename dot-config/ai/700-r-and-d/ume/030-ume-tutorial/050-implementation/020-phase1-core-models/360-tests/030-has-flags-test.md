# Testing the HasFlags Concern

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Overview

This document outlines the tests for the `HasFlags` concern, which is part of the `HasAdditionalFeatures` trait. The `HasFlags` concern provides functionality for adding boolean flags to models, including time-based flags.

## Test File

Create a new test file at `tests/Unit/Concerns/HasFlagsTest.php`:

```php
<?php

namespace Tests\Unit\Concerns;

use App\Enums\Flags;use App\Models\Traits\Concerns\HasFlags;use Illuminate\Database\Eloquent\Model;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Support\Facades\Schema;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class HasFlagsTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Create a test model that uses the HasFlags concern.
     *
     * @return Model
     */
    protected function createTestModel(): Model
    {
        // Create a test model class that uses the HasFlags concern
        $model = new class extends Model {
            use HasFlags;

            protected $table = 'test_models';
            protected $guarded = [];
        };

        // Create the test_models table if it doesn't exist
        if (!Schema::hasTable('test_models')) {
            Schema::create('test_models', function ($table) {
                $table->id();
                $table->string('name')->nullable();
                $table->timestamps();
            });
        }

        // Create the model_flags table if it doesn't exist
        if (!Schema::hasTable('model_flags')) {
            Schema::create('model_flags', function ($table) {
                $table->id();
                $table->morphs('model');
                $table->string('name');
                $table->timestamp('expires_at')->nullable();
                $table->timestamps();
                
                $table->unique(['model_type', 'model_id', 'name']);
            });
        }

        return $model;
    }

    #[Test]
    public function it_can_add_flag_to_model()
    {
        // Create a test model
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Add a flag
        $instance->flag('featured');
        
        // Assert that the flag exists
        $this->assertTrue($instance->hasFlag('featured'));
    }

    #[Test]
    public function it_can_check_if_model_has_flag()
    {
        // Create a test model
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Add a flag
        $instance->flag('featured');
        
        // Assert that hasFlag returns true for the added flag
        $this->assertTrue($instance->hasFlag('featured'));
        
        // Assert that hasFlag returns false for a non-existent flag
        $this->assertFalse($instance->hasFlag('premium'));
    }

    #[Test]
    public function it_can_remove_flag_from_model()
    {
        // Create a test model
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Add a flag
        $instance->flag('featured');
        
        // Assert that the flag exists
        $this->assertTrue($instance->hasFlag('featured'));
        
        // Remove the flag
        $instance->unflag('featured');
        
        // Assert that the flag no longer exists
        $this->assertFalse($instance->hasFlag('featured'));
    }

    #[Test]
    public function it_can_add_time_based_flag()
    {
        // Create a test model
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Add a time-based flag
        $instance->flagUntil('premium', now()->addDays(7));
        
        // Assert that the flag exists
        $this->assertTrue($instance->hasFlag('premium'));
        $this->assertTrue($instance->hasActiveFlag('premium'));
    }

    #[Test]
    public function it_can_check_if_time_based_flag_is_active()
    {
        // Create a test model
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Add an expired flag
        $instance->flagUntil('expired', now()->subDays(1));
        
        // Add an active flag
        $instance->flagUntil('active', now()->addDays(1));
        
        // Assert that hasFlag returns true for both flags
        $this->assertTrue($instance->hasFlag('expired'));
        $this->assertTrue($instance->hasFlag('active'));
        
        // Assert that hasActiveFlag returns false for the expired flag
        $this->assertFalse($instance->hasActiveFlag('expired'));
        
        // Assert that hasActiveFlag returns true for the active flag
        $this->assertTrue($instance->hasActiveFlag('active'));
    }

    #[Test]
    public function it_can_add_flag_for_days()
    {
        // Create a test model
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Add a flag for 7 days
        $instance->flagForDays('premium', 7);
        
        // Assert that the flag exists and is active
        $this->assertTrue($instance->hasFlag('premium'));
        $this->assertTrue($instance->hasActiveFlag('premium'));
        
        // Travel forward 8 days
        $this->travel(8)->days();
        
        // Assert that the flag is no longer active
        $this->assertTrue($instance->hasFlag('premium'));
        $this->assertFalse($instance->hasActiveFlag('premium'));
    }

    #[Test]
    public function it_can_scope_query_by_flag()
    {
        // Create a test model
        $model = $this->createTestModel();
        
        // Create instances with different flags
        $instance1 = $model::create(['name' => 'Test Model 1']);
        $instance1->flag('featured');
        
        $instance2 = $model::create(['name' => 'Test Model 2']);
        $instance2->flag('featured');
        
        $instance3 = $model::create(['name' => 'Test Model 3']);
        $instance3->flag('premium');
        
        // Query models with the 'featured' flag
        $featured = $model::withFlag('featured')->get();
        
        // Assert that the correct models are returned
        $this->assertCount(2, $featured);
        $this->assertTrue($featured->contains($instance1));
        $this->assertTrue($featured->contains($instance2));
        $this->assertFalse($featured->contains($instance3));
    }

    #[Test]
    public function it_can_scope_query_by_active_flag()
    {
        // Create a test model
        $model = $this->createTestModel();
        
        // Create instances with different flags
        $instance1 = $model::create(['name' => 'Test Model 1']);
        $instance1->flagUntil('premium', now()->addDays(7));
        
        $instance2 = $model::create(['name' => 'Test Model 2']);
        $instance2->flagUntil('premium', now()->subDays(1));
        
        $instance3 = $model::create(['name' => 'Test Model 3']);
        $instance3->flag('featured');
        
        // Query models with the active 'premium' flag
        $premium = $model::withActiveFlag('premium')->get();
        
        // Assert that the correct models are returned
        $this->assertCount(1, $premium);
        $this->assertTrue($premium->contains($instance1));
        $this->assertFalse($premium->contains($instance2));
        $this->assertFalse($premium->contains($instance3));
    }

    #[Test]
    public function it_can_scope_query_by_without_flag()
    {
        // Create a test model
        $model = $this->createTestModel();
        
        // Create instances with different flags
        $instance1 = $model::create(['name' => 'Test Model 1']);
        $instance1->flag('featured');
        
        $instance2 = $model::create(['name' => 'Test Model 2']);
        $instance2->flag('premium');
        
        $instance3 = $model::create(['name' => 'Test Model 3']);
        
        // Query models without the 'featured' flag
        $notFeatured = $model::withoutFlag('featured')->get();
        
        // Assert that the correct models are returned
        $this->assertCount(2, $notFeatured);
        $this->assertFalse($notFeatured->contains($instance1));
        $this->assertTrue($notFeatured->contains($instance2));
        $this->assertTrue($notFeatured->contains($instance3));
    }

    #[Test]
    public function it_validates_flag_against_enum()
    {
        // Skip this test if the Flags enum doesn't exist
        if (!class_exists(Flags::class)) {
            $this->markTestSkipped('Flags enum does not exist');
        }
        
        // Create a test model
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Add a valid flag
        $instance->flag(Flags::FEATURED->value);
        
        // Assert that the flag exists
        $this->assertTrue($instance->hasFlag(Flags::FEATURED->value));
        
        // Expect an exception when adding an invalid flag
        $this->expectException(\InvalidArgumentException::class);
        $instance->flag('invalid_flag');
    }

    #[Test]
    public function it_can_get_flags_relationship()
    {
        // Create a test model
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Add flags
        $instance->flag('featured');
        $instance->flag('premium');
        
        // Get the flags relationship
        $flags = $instance->flags;
        
        // Assert that the relationship returns the correct flags
        $this->assertCount(2, $flags);
        $this->assertTrue($flags->contains('name', 'featured'));
        $this->assertTrue($flags->contains('name', 'premium'));
    }
}
```

## Key Test Cases

1. **Flag Addition**: Tests that a flag can be added to a model.
2. **Flag Checking**: Tests that the presence of a flag can be checked.
3. **Flag Removal**: Tests that a flag can be removed from a model.
4. **Time-Based Flags**: Tests that time-based flags can be added and checked.
5. **Flag Scopes**: Tests the withFlag, withActiveFlag, and withoutFlag query scopes.
6. **Flag Validation**: Tests that flags are validated against the Flags enum.
7. **Flags Relationship**: Tests that the flags relationship returns the correct flags.

## Running the Tests

To run the tests for the HasFlags concern, use the following command:

```bash
php artisan test --filter=HasFlagsTest
```

## Expected Output

When running the HasFlags tests, you should see output similar to:

```
PASS  Tests\Unit\Concerns\HasFlagsTest
✓ it can add flag to model
✓ it can check if model has flag
✓ it can remove flag from model
✓ it can add time based flag
✓ it can check if time based flag is active
✓ it can add flag for days
✓ it can scope query by flag
✓ it can scope query by active flag
✓ it can scope query by without flag
✓ it validates flag against enum
✓ it can get flags relationship

Tests:  11 passed
Time:   0.18s
```

This confirms that the HasFlags concern is working correctly and all its features are functioning as expected.
