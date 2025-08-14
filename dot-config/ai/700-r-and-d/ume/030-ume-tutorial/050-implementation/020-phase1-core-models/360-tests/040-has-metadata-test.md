# Testing the HasMetadata Concern

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Overview

This document outlines the tests for the `HasMetadata` concern, which is part of the `HasAdditionalFeatures` trait. The `HasMetadata` concern provides functionality for storing and retrieving flexible metadata on models, including typed metadata with validation.

## Test File

Create a new test file at `tests/Unit/Concerns/HasMetadataTest.php`:

```php
<?php

namespace Tests\Unit\Concerns;

use App\Models\Traits\Concerns\HasMetadata;use Illuminate\Database\Eloquent\Model;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Support\Facades\Schema;use Illuminate\Validation\ValidationException;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class HasMetadataTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Create a test model that uses the HasMetadata concern.
     *
     * @return Model
     */
    protected function createTestModel(): Model
    {
        // Create a test model class that uses the HasMetadata concern
        $model = new class extends Model {
            use HasMetadata;

            protected $table = 'test_models';
            protected $guarded = [];
            protected $casts = [
                'metadata' => 'array',
            ];
        };

        // Create the test_models table if it doesn't exist
        if (!Schema::hasTable('test_models')) {
            Schema::create('test_models', function ($table) {
                $table->id();
                $table->string('name')->nullable();
                $table->json('metadata')->nullable();
                $table->timestamps();
            });
        }

        return $model;
    }

    #[Test]
    public function it_can_get_and_set_metadata()
    {
        // Create a test model
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Set metadata
        $instance->setMetadata('preferences', ['theme' => 'dark']);
        $instance->save();
        
        // Refresh from database
        $instance->refresh();
        
        // Get metadata
        $preferences = $instance->getMetadata('preferences');
        
        // Assert that the metadata was set and retrieved correctly
        $this->assertIsArray($preferences);
        $this->assertEquals('dark', $preferences['theme']);
    }

    #[Test]
    public function it_returns_default_value_for_nonexistent_metadata()
    {
        // Create a test model
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Get nonexistent metadata with default value
        $preferences = $instance->getMetadata('preferences', ['theme' => 'light']);
        
        // Assert that the default value is returned
        $this->assertIsArray($preferences);
        $this->assertEquals('light', $preferences['theme']);
    }

    #[Test]
    public function it_can_update_metadata()
    {
        // Create a test model
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Set initial metadata
        $instance->setMetadata('preferences', ['theme' => 'dark']);
        $instance->save();
        
        // Update metadata
        $instance->setMetadata('preferences', ['theme' => 'light']);
        $instance->save();
        
        // Refresh from database
        $instance->refresh();
        
        // Get updated metadata
        $preferences = $instance->getMetadata('preferences');
        
        // Assert that the metadata was updated correctly
        $this->assertEquals('light', $preferences['theme']);
    }

    #[Test]
    public function it_can_merge_metadata()
    {
        // Create a test model
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Set initial metadata
        $instance->setMetadata('preferences', ['theme' => 'dark']);
        $instance->save();
        
        // Merge metadata
        $instance->mergeMetadata('preferences', ['font' => 'sans-serif']);
        $instance->save();
        
        // Refresh from database
        $instance->refresh();
        
        // Get merged metadata
        $preferences = $instance->getMetadata('preferences');
        
        // Assert that the metadata was merged correctly
        $this->assertEquals('dark', $preferences['theme']);
        $this->assertEquals('sans-serif', $preferences['font']);
    }

    #[Test]
    public function it_can_remove_metadata()
    {
        // Create a test model
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Set metadata
        $instance->setMetadata('preferences', ['theme' => 'dark']);
        $instance->save();
        
        // Remove metadata
        $instance->removeMetadata('preferences');
        $instance->save();
        
        // Refresh from database
        $instance->refresh();
        
        // Check that metadata is removed
        $this->assertNull($instance->getMetadata('preferences'));
    }

    #[Test]
    public function it_can_set_typed_metadata()
    {
        // Create a test model
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Set typed metadata
        $instance->setMetadata('count', 5, 'integer');
        $instance->save();
        
        // Refresh from database
        $instance->refresh();
        
        // Get typed metadata
        $count = $instance->getMetadata('count');
        
        // Assert that the metadata was set correctly
        $this->assertIsInt($count);
        $this->assertEquals(5, $count);
    }

    #[Test]
    public function it_validates_typed_metadata()
    {
        // Create a test model
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Expect a validation exception when setting invalid typed metadata
        $this->expectException(ValidationException::class);
        
        // Try to set a string as an integer
        $instance->setMetadata('count', 'not an integer', 'integer');
    }

    #[Test]
    public function it_can_validate_metadata_value()
    {
        // Create a test model
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Set metadata with valid value
        $instance->setMetadata('status', 'active', null, ['active', 'inactive', 'pending']);
        $instance->save();
        
        // Refresh from database
        $instance->refresh();
        
        // Get metadata
        $status = $instance->getMetadata('status');
        
        // Assert that the metadata was set correctly
        $this->assertEquals('active', $status);
        
        // Expect a validation exception when setting invalid value
        $this->expectException(ValidationException::class);
        
        // Try to set an invalid value
        $instance->setMetadata('status', 'invalid', null, ['active', 'inactive', 'pending']);
    }

    #[Test]
    public function it_can_validate_metadata_keys_when_merging()
    {
        // Create a test model
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Set initial metadata
        $instance->setMetadata('preferences', ['theme' => 'dark']);
        $instance->save();
        
        // Merge metadata with valid keys
        $instance->mergeMetadata('preferences', ['font' => 'sans-serif'], ['font', 'size']);
        $instance->save();
        
        // Refresh from database
        $instance->refresh();
        
        // Get merged metadata
        $preferences = $instance->getMetadata('preferences');
        
        // Assert that the metadata was merged correctly
        $this->assertEquals('dark', $preferences['theme']);
        $this->assertEquals('sans-serif', $preferences['font']);
        
        // Expect a validation exception when merging with invalid keys
        $this->expectException(ValidationException::class);
        
        // Try to merge with invalid keys
        $instance->mergeMetadata('preferences', ['invalid' => 'value'], ['font', 'size']);
    }

    #[Test]
    public function it_can_set_multiple_metadata_values()
    {
        // Create a test model
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Set multiple metadata values
        $instance->setMetadata('preferences', ['theme' => 'dark']);
        $instance->setMetadata('settings', ['notifications' => true]);
        $instance->save();
        
        // Refresh from database
        $instance->refresh();
        
        // Get metadata
        $preferences = $instance->getMetadata('preferences');
        $settings = $instance->getMetadata('settings');
        
        // Assert that both metadata values were set correctly
        $this->assertEquals('dark', $preferences['theme']);
        $this->assertTrue($settings['notifications']);
    }

    #[Test]
    public function it_can_handle_complex_metadata_structures()
    {
        // Create a test model
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Set complex metadata
        $instance->setMetadata('config', [
            'theme' => [
                'mode' => 'dark',
                'colors' => [
                    'primary' => '#1a1a1a',
                    'secondary' => '#2a2a2a',
                ],
            ],
            'features' => [
                'notifications' => true,
                'analytics' => false,
            ],
        ]);
        $instance->save();
        
        // Refresh from database
        $instance->refresh();
        
        // Get metadata
        $config = $instance->getMetadata('config');
        
        // Assert that the complex metadata was set correctly
        $this->assertEquals('dark', $config['theme']['mode']);
        $this->assertEquals('#1a1a1a', $config['theme']['colors']['primary']);
        $this->assertTrue($config['features']['notifications']);
        $this->assertFalse($config['features']['analytics']);
    }
}
```

## Key Test Cases

1. **Basic Get/Set**: Tests that metadata can be set and retrieved.
2. **Default Values**: Tests that default values are returned for nonexistent metadata.
3. **Updating**: Tests that metadata can be updated.
4. **Merging**: Tests that metadata can be merged.
5. **Removal**: Tests that metadata can be removed.
6. **Typed Metadata**: Tests that metadata can be typed and validated.
7. **Value Validation**: Tests that metadata values can be validated against a list of valid values.
8. **Key Validation**: Tests that metadata keys can be validated when merging.
9. **Multiple Values**: Tests that multiple metadata values can be set and retrieved.
10. **Complex Structures**: Tests that complex metadata structures can be handled.

## Running the Tests

To run the tests for the HasMetadata concern, use the following command:

```bash
php artisan test --filter=HasMetadataTest
```

## Expected Output

When running the HasMetadata tests, you should see output similar to:

```
PASS  Tests\Unit\Concerns\HasMetadataTest
✓ it can get and set metadata
✓ it returns default value for nonexistent metadata
✓ it can update metadata
✓ it can merge metadata
✓ it can remove metadata
✓ it can set typed metadata
✓ it validates typed metadata
✓ it can validate metadata value
✓ it can validate metadata keys when merging
✓ it can set multiple metadata values
✓ it can handle complex metadata structures

Tests:  11 passed
Time:   0.15s
```

This confirms that the HasMetadata concern is working correctly and all its features are functioning as expected.
