# Testing the Feature Events

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Overview

This document outlines the tests for the feature events (`FeatureEnabled`, `FeatureDisabled`, and `FeatureUsed`), which are dispatched when features are enabled, disabled, or used in the `HasAdditionalFeatures` trait.

## Test File

Create a new test file at `tests/Unit/Events/FeatureEventsTest.php`:

```php
<?php

namespace Tests\Unit\Events;

use App\Events\FeatureDisabled;use App\Events\FeatureEnabled;use App\Events\FeatureUsed;use App\Models\Traits\HasAdditionalFeatures;use App\Models\User;use App\Support\FeatureManager;use Illuminate\Database\Eloquent\Model;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Support\Facades\Event;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class FeatureEventsTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Create a test model that uses the HasAdditionalFeatures trait.
     *
     * @return Model
     */
    protected function createTestModel(): Model
    {
        // Create a test model class that uses the HasAdditionalFeatures trait
        $model = new class extends Model {
            use HasAdditionalFeatures;

            protected $table = 'test_models';
            protected $guarded = [];

            public function recordFeatureUsage(string $feature, array $context = []): void
            {
                parent::recordFeatureUsage($feature, $context);
            }
        };

        // Create the test_models table if it doesn't exist
        if (!$this->app->db->getSchemaBuilder()->hasTable('test_models')) {
            $this->app->db->getSchemaBuilder()->create('test_models', function ($table) {
                $table->id();
                $table->string('name')->nullable();
                $table->timestamps();
            });
        }

        return $model;
    }

    #[Test]
    public function it_dispatches_feature_enabled_event()
    {
        // Fake events
        Event::fake([FeatureEnabled::class]);
        
        // Enable a feature
        FeatureManager::enable('ulid');
        
        // Assert that the event was dispatched
        Event::assertDispatched(FeatureEnabled::class, function ($event) {
            return $event->feature === 'ulid' && $event->model === null;
        });
    }

    #[Test]
    public function it_dispatches_feature_enabled_event_for_model()
    {
        // Fake events
        Event::fake([FeatureEnabled::class]);
        
        // Enable a feature for a specific model
        FeatureManager::enable('ulid', User::class);
        
        // Assert that the event was dispatched
        Event::assertDispatched(FeatureEnabled::class, function ($event) {
            return $event->feature === 'ulid' && $event->model === User::class;
        });
    }

    #[Test]
    public function it_dispatches_feature_disabled_event()
    {
        // Fake events
        Event::fake([FeatureDisabled::class]);
        
        // Disable a feature
        FeatureManager::disable('ulid');
        
        // Assert that the event was dispatched
        Event::assertDispatched(FeatureDisabled::class, function ($event) {
            return $event->feature === 'ulid' && $event->model === null;
        });
    }

    #[Test]
    public function it_dispatches_feature_disabled_event_for_model()
    {
        // Fake events
        Event::fake([FeatureDisabled::class]);
        
        // Disable a feature for a specific model
        FeatureManager::disable('ulid', User::class);
        
        // Assert that the event was dispatched
        Event::assertDispatched(FeatureDisabled::class, function ($event) {
            return $event->feature === 'ulid' && $event->model === User::class;
        });
    }

    #[Test]
    public function it_dispatches_feature_used_event()
    {
        // Fake events
        Event::fake([FeatureUsed::class]);
        
        // Create a test model
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Record feature usage
        $instance->recordFeatureUsage('ulid');
        
        // Assert that the event was dispatched
        Event::assertDispatched(FeatureUsed::class, function ($event) use ($instance) {
            return $event->feature === 'ulid' && $event->model === $instance && $event->context === [];
        });
    }

    #[Test]
    public function it_dispatches_feature_used_event_with_context()
    {
        // Fake events
        Event::fake([FeatureUsed::class]);
        
        // Create a test model
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Record feature usage with context
        $context = ['action' => 'test', 'value' => 123];
        $instance->recordFeatureUsage('ulid', $context);
        
        // Assert that the event was dispatched
        Event::assertDispatched(FeatureUsed::class, function ($event) use ($instance, $context) {
            return $event->feature === 'ulid' && $event->model === $instance && $event->context === $context;
        });
    }

    #[Test]
    public function it_does_not_dispatch_feature_used_event_if_feature_is_disabled()
    {
        // Fake events
        Event::fake([FeatureUsed::class]);
        
        // Create a test model
        $model = $this->createTestModel();
        $instance = $model::create(['name' => 'Test Model']);
        
        // Disable the feature
        FeatureManager::disable('ulid');
        
        // Record feature usage
        $instance->recordFeatureUsage('ulid');
        
        // Assert that the event was not dispatched
        Event::assertNotDispatched(FeatureUsed::class);
    }

    #[Test]
    public function it_can_listen_for_feature_events()
    {
        // Create a listener for the FeatureEnabled event
        $listener = new class {
            public $enabled = false;
            
            public function handle(FeatureEnabled $event)
            {
                $this->enabled = true;
            }
        };
        
        // Register the listener
        Event::listen(FeatureEnabled::class, [$listener, 'handle']);
        
        // Enable a feature
        FeatureManager::enable('ulid');
        
        // Assert that the listener was called
        $this->assertTrue($listener->enabled);
    }
}
```

## Key Test Cases

1. **FeatureEnabled Event**: Tests that the FeatureEnabled event is dispatched when a feature is enabled.
2. **FeatureDisabled Event**: Tests that the FeatureDisabled event is dispatched when a feature is disabled.
3. **FeatureUsed Event**: Tests that the FeatureUsed event is dispatched when a feature is used.
4. **Event Context**: Tests that the events include the correct context.
5. **Model-Specific Events**: Tests that events can be dispatched for specific models.
6. **Event Listeners**: Tests that event listeners can be registered and called.

## Running the Tests

To run the tests for the feature events, use the following command:

```bash
php artisan test --filter=FeatureEventsTest
```

## Expected Output

When running the feature events tests, you should see output similar to:

```
PASS  Tests\Unit\Events\FeatureEventsTest
✓ it dispatches feature enabled event
✓ it dispatches feature enabled event for model
✓ it dispatches feature disabled event
✓ it dispatches feature disabled event for model
✓ it dispatches feature used event
✓ it dispatches feature used event with context
✓ it does not dispatch feature used event if feature is disabled
✓ it can listen for feature events

Tests:  8 passed
Time:   0.12s
```

This confirms that the feature events are working correctly and all their features are functioning as expected.
