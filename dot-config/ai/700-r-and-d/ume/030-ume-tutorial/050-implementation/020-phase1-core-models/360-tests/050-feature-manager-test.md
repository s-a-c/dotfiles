# Testing the FeatureManager

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Overview

This document outlines the tests for the `FeatureManager` class, which is responsible for managing feature enablement/disablement and configuration in the `HasAdditionalFeatures` trait.

## Test File

Create a new test file at `tests/Unit/Support/FeatureManagerTest.php`:

```php
<?php

namespace Tests\Unit\Support;

use App\Support\FeatureManager;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Support\Facades\Config;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class FeatureManagerTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        
        // Reset the FeatureManager before each test
        FeatureManager::reset();
        
        // Set up default configuration
        Config::set('additional-features.enabled', [
            'ulid' => true,
            'user_tracking' => true,
            'sluggable' => true,
            'translatable' => false,
        ]);
        
        Config::set('additional-features.ulid', [
            'column' => 'ulid',
            'auto_generate' => true,
        ]);
        
        Config::set('additional-features.profiles', [
            'minimal' => [
                'ulid' => true,
                'user_tracking' => true,
                'sluggable' => false,
                'translatable' => false,
            ],
            'full' => [
                'ulid' => true,
                'user_tracking' => true,
                'sluggable' => true,
                'translatable' => true,
            ],
        ]);
        
        Config::set('additional-features.model_overrides.App\\Models\\User.enabled', [
            'translatable' => true,
        ]);
    }

    #[Test]
    public function it_can_check_if_feature_is_enabled()
    {
        // Check global configuration
        $this->assertTrue(FeatureManager::isEnabled('ulid'));
        $this->assertTrue(FeatureManager::isEnabled('user_tracking'));
        $this->assertTrue(FeatureManager::isEnabled('sluggable'));
        $this->assertFalse(FeatureManager::isEnabled('translatable'));
        
        // Check model-specific configuration
        $this->assertTrue(FeatureManager::isEnabled('translatable', 'App\\Models\\User'));
    }

    #[Test]
    public function it_can_enable_feature()
    {
        // Enable a feature that was disabled
        FeatureManager::enable('translatable');
        
        // Check that the feature is now enabled
        $this->assertTrue(FeatureManager::isEnabled('translatable'));
    }

    #[Test]
    public function it_can_disable_feature()
    {
        // Disable a feature that was enabled
        FeatureManager::disable('ulid');
        
        // Check that the feature is now disabled
        $this->assertFalse(FeatureManager::isEnabled('ulid'));
    }

    #[Test]
    public function it_can_enable_feature_for_specific_model()
    {
        // Enable a feature for a specific model
        FeatureManager::enable('translatable', 'App\\Models\\Post');
        
        // Check that the feature is enabled for the model
        $this->assertTrue(FeatureManager::isEnabled('translatable', 'App\\Models\\Post'));
        
        // Check that the feature is still disabled globally
        $this->assertFalse(FeatureManager::isEnabled('translatable'));
    }

    #[Test]
    public function it_can_disable_feature_for_specific_model()
    {
        // Disable a feature for a specific model
        FeatureManager::disable('ulid', 'App\\Models\\Post');
        
        // Check that the feature is disabled for the model
        $this->assertFalse(FeatureManager::isEnabled('ulid', 'App\\Models\\Post'));
        
        // Check that the feature is still enabled globally
        $this->assertTrue(FeatureManager::isEnabled('ulid'));
    }

    #[Test]
    public function it_can_temporarily_enable_feature()
    {
        // Temporarily enable a feature
        $result = FeatureManager::withFeature('translatable', true, function () {
            return FeatureManager::isEnabled('translatable');
        });
        
        // Check that the feature was enabled during the callback
        $this->assertTrue($result);
        
        // Check that the feature is disabled again after the callback
        $this->assertFalse(FeatureManager::isEnabled('translatable'));
    }

    #[Test]
    public function it_can_temporarily_disable_feature()
    {
        // Temporarily disable a feature
        $result = FeatureManager::withFeature('ulid', false, function () {
            return FeatureManager::isEnabled('ulid');
        });
        
        // Check that the feature was disabled during the callback
        $this->assertFalse($result);
        
        // Check that the feature is enabled again after the callback
        $this->assertTrue(FeatureManager::isEnabled('ulid'));
    }

    #[Test]
    public function it_can_use_without_feature_shorthand()
    {
        // Temporarily disable a feature using the shorthand
        $result = FeatureManager::withoutFeature('ulid', function () {
            return FeatureManager::isEnabled('ulid');
        });
        
        // Check that the feature was disabled during the callback
        $this->assertFalse($result);
        
        // Check that the feature is enabled again after the callback
        $this->assertTrue(FeatureManager::isEnabled('ulid'));
    }

    #[Test]
    public function it_can_apply_feature_profile()
    {
        // Apply the minimal profile
        FeatureManager::useProfile('minimal');
        
        // Check that the features are configured according to the profile
        $this->assertTrue(FeatureManager::isEnabled('ulid'));
        $this->assertTrue(FeatureManager::isEnabled('user_tracking'));
        $this->assertFalse(FeatureManager::isEnabled('sluggable'));
        $this->assertFalse(FeatureManager::isEnabled('translatable'));
    }

    #[Test]
    public function it_can_apply_feature_profile_for_specific_model()
    {
        // Apply the full profile for a specific model
        FeatureManager::useProfile('full', 'App\\Models\\Post');
        
        // Check that the features are configured according to the profile for the model
        $this->assertTrue(FeatureManager::isEnabled('ulid', 'App\\Models\\Post'));
        $this->assertTrue(FeatureManager::isEnabled('user_tracking', 'App\\Models\\Post'));
        $this->assertTrue(FeatureManager::isEnabled('sluggable', 'App\\Models\\Post'));
        $this->assertTrue(FeatureManager::isEnabled('translatable', 'App\\Models\\Post'));
        
        // Check that the global configuration is unchanged
        $this->assertTrue(FeatureManager::isEnabled('ulid'));
        $this->assertTrue(FeatureManager::isEnabled('user_tracking'));
        $this->assertTrue(FeatureManager::isEnabled('sluggable'));
        $this->assertFalse(FeatureManager::isEnabled('translatable'));
    }

    #[Test]
    public function it_can_configure_feature()
    {
        // Configure a feature
        FeatureManager::configure('ulid', ['column' => 'custom_ulid'], 'App\\Models\\Post');
        
        // Check that the configuration was set
        $config = FeatureManager::getConfiguration('ulid', 'App\\Models\\Post');
        $this->assertEquals('custom_ulid', $config['column']);
    }

    #[Test]
    public function it_can_get_feature_configuration()
    {
        // Get global configuration
        $config = FeatureManager::getConfiguration('ulid');
        
        // Check that the configuration is correct
        $this->assertEquals('ulid', $config['column']);
        $this->assertTrue($config['auto_generate']);
    }

    #[Test]
    public function it_can_get_model_specific_configuration()
    {
        // Configure a feature for a specific model
        FeatureManager::configure('ulid', ['column' => 'custom_ulid'], 'App\\Models\\Post');
        
        // Get model-specific configuration
        $config = FeatureManager::getConfiguration('ulid', 'App\\Models\\Post');
        
        // Check that the configuration is correct
        $this->assertEquals('custom_ulid', $config['column']);
    }

    #[Test]
    public function it_can_reset_configuration()
    {
        // Configure a feature
        FeatureManager::configure('ulid', ['column' => 'custom_ulid'], 'App\\Models\\Post');
        
        // Enable a feature
        FeatureManager::enable('translatable');
        
        // Reset the configuration
        FeatureManager::reset();
        
        // Check that the configuration is reset
        $this->assertFalse(FeatureManager::isEnabled('translatable'));
        
        // Check that the model-specific configuration is reset
        $config = FeatureManager::getConfiguration('ulid', 'App\\Models\\Post');
        $this->assertEquals('ulid', $config['column']);
    }

    #[Test]
    public function it_falls_back_to_global_configuration_for_model()
    {
        // Get configuration for a model without specific configuration
        $config = FeatureManager::getConfiguration('ulid', 'App\\Models\\Post');
        
        // Check that it falls back to the global configuration
        $this->assertEquals('ulid', $config['column']);
        $this->assertTrue($config['auto_generate']);
    }

    #[Test]
    public function it_returns_empty_array_for_nonexistent_configuration()
    {
        // Get configuration for a nonexistent feature
        $config = FeatureManager::getConfiguration('nonexistent');
        
        // Check that an empty array is returned
        $this->assertEquals([], $config);
    }
}
```

## Key Test Cases

1. **Feature Checking**: Tests that the FeatureManager can check if a feature is enabled.
2. **Feature Enablement/Disablement**: Tests that features can be enabled and disabled.
3. **Model-Specific Configuration**: Tests that features can be configured for specific models.
4. **Temporary Feature Toggling**: Tests that features can be temporarily enabled or disabled.
5. **Feature Profiles**: Tests that feature profiles can be applied.
6. **Feature Configuration**: Tests that features can be configured and the configuration can be retrieved.
7. **Configuration Reset**: Tests that the configuration can be reset.
8. **Configuration Fallbacks**: Tests that model-specific configuration falls back to global configuration.

## Running the Tests

To run the tests for the FeatureManager, use the following command:

```bash
php artisan test --filter=FeatureManagerTest
```

## Expected Output

When running the FeatureManager tests, you should see output similar to:

```
PASS  Tests\Unit\Support\FeatureManagerTest
✓ it can check if feature is enabled
✓ it can enable feature
✓ it can disable feature
✓ it can enable feature for specific model
✓ it can disable feature for specific model
✓ it can temporarily enable feature
✓ it can temporarily disable feature
✓ it can use without feature shorthand
✓ it can apply feature profile
✓ it can apply feature profile for specific model
✓ it can configure feature
✓ it can get feature configuration
✓ it can get model specific configuration
✓ it can reset configuration
✓ it falls back to global configuration for model
✓ it returns empty array for nonexistent configuration

Tests:  16 passed
Time:   0.10s
```

This confirms that the FeatureManager is working correctly and all its features are functioning as expected.
