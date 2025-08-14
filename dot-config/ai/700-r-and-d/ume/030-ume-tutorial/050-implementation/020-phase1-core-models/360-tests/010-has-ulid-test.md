# Testing the HasUlid Concern

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Overview

This document outlines the tests for the `HasUlid` concern, which is part of the `HasAdditionalFeatures` trait. The `HasUlid` concern provides ULID generation and lookup functionality for models.

## Test File

Create a new test file at `tests/Unit/Concerns/HasUlidTest.php`:

```php
<?php

namespace Tests\Unit\Concerns;

use App\Models\Traits\Concerns\HasUlid;use Illuminate\Database\Eloquent\Model;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Support\Str;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class HasUlidTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Create a test model that uses the HasUlid concern.
     *
     * @return Model
     */
    protected function createTestModel(): Model
    {
        // Create a test model class that uses the HasUlid concern
        $model = new class extends Model {
            use HasUlid;

            protected $table = 'test_models';
            protected $guarded = [];
        };

        // Create the test_models table if it doesn't exist
        if (!$this->app->db->getSchemaBuilder()->hasTable('test_models')) {
            $this->app->db->getSchemaBuilder()->create('test_models', function ($table) {
                $table->id();
                $table->string('ulid')->nullable();
                $table->string('name')->nullable();
                $table->timestamps();
            });
        }

        return $model;
    }

    #[Test]
    public function it_generates_ulid_on_creation()
    {
        $model = $this->createTestModel();
        
        // Create a new model instance
        $instance = $model::create(['name' => 'Test Model']);
        
        // Assert that a ULID was generated
        $this->assertNotNull($instance->ulid);
        $this->assertEquals(26, strlen($instance->ulid));
    }

    #[Test]
    public function it_does_not_overwrite_existing_ulid()
    {
        $model = $this->createTestModel();
        $customUlid = (string) Str::ulid();
        
        // Create a new model instance with a custom ULID
        $instance = $model::create([
            'name' => 'Test Model',
            'ulid' => $customUlid,
        ]);
        
        // Assert that the custom ULID was not overwritten
        $this->assertEquals($customUlid, $instance->ulid);
    }

    #[Test]
    public function it_can_find_model_by_ulid()
    {
        $model = $this->createTestModel();
        
        // Create a new model instance
        $instance = $model::create(['name' => 'Test Model']);
        
        // Find the model by ULID
        $found = $model::findByUlid($instance->ulid);
        
        // Assert that the correct model was found
        $this->assertNotNull($found);
        $this->assertEquals($instance->id, $found->id);
    }

    #[Test]
    public function it_returns_null_when_finding_nonexistent_ulid()
    {
        $model = $this->createTestModel();
        
        // Find a model with a nonexistent ULID
        $found = $model::findByUlid((string) Str::ulid());
        
        // Assert that null was returned
        $this->assertNull($found);
    }

    #[Test]
    public function it_can_find_model_by_ulid_or_fail()
    {
        $model = $this->createTestModel();
        
        // Create a new model instance
        $instance = $model::create(['name' => 'Test Model']);
        
        // Find the model by ULID
        $found = $model::findByUlidOrFail($instance->ulid);
        
        // Assert that the correct model was found
        $this->assertNotNull($found);
        $this->assertEquals($instance->id, $found->id);
    }

    #[Test]
    public function it_throws_exception_when_finding_nonexistent_ulid_or_fail()
    {
        $model = $this->createTestModel();
        
        // Expect an exception when finding a model with a nonexistent ULID
        $this->expectException(\Illuminate\Database\Eloquent\ModelNotFoundException::class);
        
        $model::findByUlidOrFail((string) Str::ulid());
    }

    #[Test]
    public function it_uses_ulid_as_route_key_name()
    {
        $model = $this->createTestModel();
        
        // Create a new model instance
        $instance = $model::create(['name' => 'Test Model']);
        
        // Assert that the route key name is 'ulid'
        $this->assertEquals('ulid', $instance->getRouteKeyName());
    }

    #[Test]
    public function it_can_use_custom_ulid_column()
    {
        // Create a test model class that uses the HasUlid concern with a custom ULID column
        $model = new class extends Model {
            use HasUlid;

            protected $table = 'custom_ulid_models';
            protected $guarded = [];

            protected static function getUlidColumn(): string
            {
                return 'custom_ulid';
            }
        };

        // Create the custom_ulid_models table if it doesn't exist
        if (!$this->app->db->getSchemaBuilder()->hasTable('custom_ulid_models')) {
            $this->app->db->getSchemaBuilder()->create('custom_ulid_models', function ($table) {
                $table->id();
                $table->string('custom_ulid')->nullable();
                $table->string('name')->nullable();
                $table->timestamps();
            });
        }
        
        // Create a new model instance
        $instance = $model::create(['name' => 'Test Model']);
        
        // Assert that a ULID was generated in the custom column
        $this->assertNotNull($instance->custom_ulid);
        $this->assertEquals(26, strlen($instance->custom_ulid));
        
        // Assert that the route key name is the custom column
        $this->assertEquals('custom_ulid', $instance->getRouteKeyName());
    }
}
```

## Key Test Cases

1. **ULID Generation**: Tests that a ULID is automatically generated when a model is created.
2. **Existing ULID Preservation**: Tests that an existing ULID is not overwritten.
3. **Finding by ULID**: Tests the `findByUlid` method.
4. **Finding by ULID or Fail**: Tests the `findByUlidOrFail` method.
5. **Route Key Name**: Tests that the ULID column is used as the route key name.
6. **Custom ULID Column**: Tests that a custom ULID column can be specified.

## Running the Tests

To run the tests for the HasUlid concern, use the following command:

```bash
php artisan test --filter=HasUlidTest
```

## Expected Output

When running the HasUlid tests, you should see output similar to:

```
PASS  Tests\Unit\Concerns\HasUlidTest
✓ it generates ulid on creation
✓ it does not overwrite existing ulid
✓ it can find model by ulid
✓ it returns null when finding nonexistent ulid
✓ it can find model by ulid or fail
✓ it throws exception when finding nonexistent ulid or fail
✓ it uses ulid as route key name
✓ it can use custom ulid column

Tests:  8 passed
Time:   0.12s
```

This confirms that the HasUlid concern is working correctly and all its features are functioning as expected.
