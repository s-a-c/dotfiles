# Testing the Feature Middleware

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Overview

This document outlines the tests for the `FeatureMiddleware` class, which provides middleware for enabling/disabling features for specific requests.

## Test File

Create a new test file at `tests/Unit/Http/Middleware/FeatureMiddlewareTest.php`:

```php
<?php

namespace Tests\Unit\Http\Middleware;

use App\Http\Middleware\FeatureMiddleware;use App\Support\FeatureManager;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Http\Request;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class FeatureMiddlewareTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        
        // Reset the FeatureManager before each test
        FeatureManager::reset();
    }

    #[Test]
    public function it_can_enable_feature_for_request()
    {
        // Create a request
        $request = new Request();
        
        // Create a middleware
        $middleware = new FeatureMiddleware();
        
        // Disable the feature initially
        FeatureManager::disable('ulid');
        
        // Execute the middleware
        $middleware->handle($request, function ($req) {
            // Check that the feature is enabled
            $this->assertTrue(FeatureManager::isEnabled('ulid'));
            
            return 'response';
        }, 'ulid', 'true');
        
        // Check that the feature is disabled again after the request
        $this->assertFalse(FeatureManager::isEnabled('ulid'));
    }

    #[Test]
    public function it_can_disable_feature_for_request()
    {
        // Create a request
        $request = new Request();
        
        // Create a middleware
        $middleware = new FeatureMiddleware();
        
        // Enable the feature initially
        FeatureManager::enable('ulid');
        
        // Execute the middleware
        $middleware->handle($request, function ($req) {
            // Check that the feature is disabled
            $this->assertFalse(FeatureManager::isEnabled('ulid'));
            
            return 'response';
        }, 'ulid', 'false');
        
        // Check that the feature is enabled again after the request
        $this->assertTrue(FeatureManager::isEnabled('ulid'));
    }

    #[Test]
    public function it_can_temporarily_enable_feature()
    {
        // Disable the feature initially
        FeatureManager::disable('ulid');
        
        // Execute the withFeature method
        $result = FeatureMiddleware::withFeature('ulid', function () {
            // Check that the feature is enabled
            $this->assertTrue(FeatureManager::isEnabled('ulid'));
            
            return 'result';
        });
        
        // Check that the feature is disabled again after the callback
        $this->assertFalse(FeatureManager::isEnabled('ulid'));
        
        // Check that the result was returned
        $this->assertEquals('result', $result);
    }

    #[Test]
    public function it_can_temporarily_disable_feature()
    {
        // Enable the feature initially
        FeatureManager::enable('ulid');
        
        // Execute the withoutFeature method
        $result = FeatureMiddleware::withoutFeature('ulid', function () {
            // Check that the feature is disabled
            $this->assertFalse(FeatureManager::isEnabled('ulid'));
            
            return 'result';
        });
        
        // Check that the feature is enabled again after the callback
        $this->assertTrue(FeatureManager::isEnabled('ulid'));
        
        // Check that the result was returned
        $this->assertEquals('result', $result);
    }

    #[Test]
    public function it_can_temporarily_enable_feature_for_model()
    {
        // Disable the feature initially
        FeatureManager::disable('ulid', 'App\\Models\\User');
        
        // Execute the withFeature method
        $result = FeatureMiddleware::withFeature('ulid', function () {
            // Check that the feature is enabled
            $this->assertTrue(FeatureManager::isEnabled('ulid', 'App\\Models\\User'));
            
            return 'result';
        }, 'App\\Models\\User');
        
        // Check that the feature is disabled again after the callback
        $this->assertFalse(FeatureManager::isEnabled('ulid', 'App\\Models\\User'));
        
        // Check that the result was returned
        $this->assertEquals('result', $result);
    }

    #[Test]
    public function it_can_temporarily_disable_feature_for_model()
    {
        // Enable the feature initially
        FeatureManager::enable('ulid', 'App\\Models\\User');
        
        // Execute the withoutFeature method
        $result = FeatureMiddleware::withoutFeature('ulid', function () {
            // Check that the feature is disabled
            $this->assertFalse(FeatureManager::isEnabled('ulid', 'App\\Models\\User'));
            
            return 'result';
        }, 'App\\Models\\User');
        
        // Check that the feature is enabled again after the callback
        $this->assertTrue(FeatureManager::isEnabled('ulid', 'App\\Models\\User'));
        
        // Check that the result was returned
        $this->assertEquals('result', $result);
    }

    #[Test]
    public function it_can_be_used_in_route_middleware()
    {
        // Register the middleware
        $this->app['router']->aliasMiddleware('feature', FeatureMiddleware::class);
        
        // Disable the feature initially
        FeatureManager::disable('ulid');
        
        // Define a route with the middleware
        $this->app['router']->get('/test', function () {
            // Check that the feature is enabled
            $this->assertTrue(FeatureManager::isEnabled('ulid'));
            
            return 'response';
        })->middleware('feature:ulid,true');
        
        // Make a request to the route
        $response = $this->get('/test');
        
        // Check that the response is successful
        $response->assertSuccessful();
        
        // Check that the feature is disabled again after the request
        $this->assertFalse(FeatureManager::isEnabled('ulid'));
    }

    #[Test]
    public function it_can_be_used_in_controller_middleware()
    {
        // Create a controller
        $controller = new class {
            public function __invoke()
            {
                // Check that the feature is enabled
                if (!FeatureManager::isEnabled('ulid')) {
                    return 'feature disabled';
                }
                
                return 'feature enabled';
            }
        };
        
        // Register the middleware
        $this->app['router']->aliasMiddleware('feature', FeatureMiddleware::class);
        
        // Disable the feature initially
        FeatureManager::disable('ulid');
        
        // Define a route with the controller and middleware
        $this->app['router']->get('/test', $controller)->middleware('feature:ulid,true');
        
        // Make a request to the route
        $response = $this->get('/test');
        
        // Check that the response is successful and contains the expected content
        $response->assertSuccessful();
        $response->assertSee('feature enabled');
        
        // Check that the feature is disabled again after the request
        $this->assertFalse(FeatureManager::isEnabled('ulid'));
    }
}
```

## Key Test Cases

1. **Feature Enablement**: Tests that the middleware can enable features for a request.
2. **Feature Disablement**: Tests that the middleware can disable features for a request.
3. **Temporary Feature Toggling**: Tests that the middleware can temporarily enable or disable features.
4. **Model-Specific Configuration**: Tests that the middleware can enable or disable features for specific models.
5. **Route Middleware**: Tests that the middleware can be used in route definitions.
6. **Controller Middleware**: Tests that the middleware can be used in controllers.

## Running the Tests

To run the tests for the feature middleware, use the following command:

```bash
php artisan test --filter=FeatureMiddlewareTest
```

## Expected Output

When running the feature middleware tests, you should see output similar to:

```
PASS  Tests\Unit\Http\Middleware\FeatureMiddlewareTest
✓ it can enable feature for request
✓ it can disable feature for request
✓ it can temporarily enable feature
✓ it can temporarily disable feature
✓ it can temporarily enable feature for model
✓ it can temporarily disable feature for model
✓ it can be used in route middleware
✓ it can be used in controller middleware

Tests:  8 passed
Time:   0.14s
```

This confirms that the feature middleware is working correctly and all its features are functioning as expected.
