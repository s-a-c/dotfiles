# Testing the FeatureConfigurator

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Overview

This document outlines the tests for the `FeatureConfigurator` class, which provides a fluent API for configuring features in the `HasAdditionalFeatures` trait.

## Test File

Create a new test file at `tests/Unit/Support/FeatureConfiguratorTest.php`:

```php
<?php

namespace Tests\Unit\Support;

use App\Support\FeatureConfigurator;use App\Support\FeatureManager;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class FeatureConfiguratorTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        
        // Reset the FeatureManager before each test
        FeatureManager::reset();
    }

    #[Test]
    public function it_can_enable_feature()
    {
        // Create a configurator for a model
        $configurator = new FeatureConfigurator('App\\Models\\Post');
        
        // Enable a feature
        $configurator->enable('ulid');
        
        // Check that the feature is enabled
        $this->assertTrue(FeatureManager::isEnabled('ulid', 'App\\Models\\Post'));
    }

    #[Test]
    public function it_can_disable_feature()
    {
        // Create a configurator for a model
        $configurator = new FeatureConfigurator('App\\Models\\Post');
        
        // Disable a feature
        $configurator->disable('ulid');
        
        // Check that the feature is disabled
        $this->assertFalse(FeatureManager::isEnabled('ulid', 'App\\Models\\Post'));
    }

    #[Test]
    public function it_can_configure_feature()
    {
        // Create a configurator for a model
        $configurator = new FeatureConfigurator('App\\Models\\Post');
        
        // Configure a feature
        $configurator->configure('ulid', [
            'column' => 'custom_ulid',
            'auto_generate' => false,
        ]);
        
        // Check that the configuration was set
        $config = FeatureManager::getConfiguration('ulid', 'App\\Models\\Post');
        $this->assertEquals('custom_ulid', $config['column']);
        $this->assertFalse($config['auto_generate']);
    }

    #[Test]
    public function it_can_use_profile()
    {
        // Set up a profile
        FeatureManager::configure('profiles', [
            'minimal' => [
                'ulid' => true,
                'user_tracking' => true,
                'sluggable' => false,
                'translatable' => false,
            ],
        ]);
        
        // Create a configurator for a model
        $configurator = new FeatureConfigurator('App\\Models\\Post');
        
        // Use a profile
        $configurator->useProfile('minimal');
        
        // Check that the features are configured according to the profile
        $this->assertTrue(FeatureManager::isEnabled('ulid', 'App\\Models\\Post'));
        $this->assertTrue(FeatureManager::isEnabled('user_tracking', 'App\\Models\\Post'));
        $this->assertFalse(FeatureManager::isEnabled('sluggable', 'App\\Models\\Post'));
        $this->assertFalse(FeatureManager::isEnabled('translatable', 'App\\Models\\Post'));
    }

    #[Test]
    public function it_supports_fluent_interface()
    {
        // Create a configurator for a model
        $configurator = new FeatureConfigurator('App\\Models\\Post');
        
        // Use fluent interface
        $configurator
            ->enable('ulid')
            ->disable('sluggable')
            ->configure('ulid', ['column' => 'custom_ulid'])
            ->useProfile('minimal');
        
        // Check that all configurations were applied
        $this->assertTrue(FeatureManager::isEnabled('ulid', 'App\\Models\\Post'));
        $this->assertFalse(FeatureManager::isEnabled('sluggable', 'App\\Models\\Post'));
        
        $config = FeatureManager::getConfiguration('ulid', 'App\\Models\\Post');
        $this->assertEquals('custom_ulid', $config['column']);
    }

    #[Test]
    public function it_applies_configuration_to_correct_model()
    {
        // Create configurators for different models
        $postConfigurator = new FeatureConfigurator('App\\Models\\Post');
        $userConfigurator = new FeatureConfigurator('App\\Models\\User');
        
        // Configure features for different models
        $postConfigurator->enable('ulid')->disable('sluggable');
        $userConfigurator->disable('ulid')->enable('sluggable');
        
        // Check that the configurations were applied to the correct models
        $this->assertTrue(FeatureManager::isEnabled('ulid', 'App\\Models\\Post'));
        $this->assertFalse(FeatureManager::isEnabled('sluggable', 'App\\Models\\Post'));
        
        $this->assertFalse(FeatureManager::isEnabled('ulid', 'App\\Models\\User'));
        $this->assertTrue(FeatureManager::isEnabled('sluggable', 'App\\Models\\User'));
    }
}
```

## Key Test Cases

1. **Feature Enablement**: Tests that the FeatureConfigurator can enable features.
2. **Feature Disablement**: Tests that the FeatureConfigurator can disable features.
3. **Feature Configuration**: Tests that the FeatureConfigurator can configure features.
4. **Profile Usage**: Tests that the FeatureConfigurator can apply feature profiles.
5. **Fluent Interface**: Tests that the FeatureConfigurator supports a fluent interface.
6. **Model-Specific Configuration**: Tests that the FeatureConfigurator applies configuration to the correct model.

## Running the Tests

To run the tests for the FeatureConfigurator, use the following command:

```bash
php artisan test --filter=FeatureConfiguratorTest
```

## Expected Output

When running the FeatureConfigurator tests, you should see output similar to:

```
PASS  Tests\Unit\Support\FeatureConfiguratorTest
✓ it can enable feature
✓ it can disable feature
✓ it can configure feature
✓ it can use profile
✓ it supports fluent interface
✓ it applies configuration to correct model

Tests:  6 passed
Time:   0.08s
```

This confirms that the FeatureConfigurator is working correctly and all its features are functioning as expected.
