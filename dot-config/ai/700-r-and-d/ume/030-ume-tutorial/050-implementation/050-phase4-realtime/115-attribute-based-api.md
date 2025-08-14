# Attribute-Based API Endpoints

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Implement attribute-based API endpoint configuration, providing a more declarative and type-safe approach to defining API routes, middleware, and response types.

## Overview

Laravel's traditional approach to defining API routes involves registering routes in route files, which can become unwieldy for large applications. PHP 8 attributes offer a more elegant solution, allowing us to define routes directly on controller methods, similar to frameworks like Symfony and ASP.NET Core.

## Step 1: Create API Endpoint Attributes

First, let's create a set of attributes for API endpoint configuration:

```php
<?php

namespace App\Http\Attributes\Api;

use Attribute;

#[Attribute(Attribute::TARGET_METHOD)]
class Route
{
    /**
     * Create a new attribute instance.
     *
     * @param string $method The HTTP method (GET, POST, PUT, PATCH, DELETE)
     * @param string $uri The URI pattern
     * @param string|null $name The route name
     */
    public function __construct(
        public string $method,
        public string $uri,
        public ?string $name = null
    ) {}
}

#[Attribute(Attribute::TARGET_METHOD | Attribute::IS_REPEATABLE)]
class Middleware
{
    /**
     * Create a new attribute instance.
     *
     * @param array|string $middleware The middleware to apply
     */
    public function __construct(
        public array|string $middleware
    ) {}
}

#[Attribute(Attribute::TARGET_METHOD)]
class ResponseType
{
    /**
     * Create a new attribute instance.
     *
     * @param string $type The response type (json, view, etc.)
     */
    public function __construct(
        public string $type
    ) {}
}

#[Attribute(Attribute::TARGET_METHOD)]
class ApiResource
{
    /**
     * Create a new attribute instance.
     *
     * @param string $resource The resource class
     * @param bool $collection Whether the resource is a collection
     */
    public function __construct(
        public string $resource,
        public bool $collection = false
    ) {}
}

#[Attribute(Attribute::TARGET_METHOD)]
class Throttle
{
    /**
     * Create a new attribute instance.
     *
     * @param int $maxAttempts The maximum number of attempts
     * @param int $decayMinutes The number of minutes until the rate limit resets
     */
    public function __construct(
        public int $maxAttempts,
        public int $decayMinutes = 1
    ) {}
}

#[Attribute(Attribute::TARGET_CLASS)]
class ApiController
{
    /**
     * Create a new attribute instance.
     *
     * @param string|null $prefix The route prefix
     * @param array $middleware The middleware to apply to all routes
     */
    public function __construct(
        public ?string $prefix = null,
        public array $middleware = []
    ) {}
}
```

## Step 2: Create a Route Scanner Service

Next, let's create a service that scans controllers for API endpoint attributes and registers the corresponding routes:

```php
<?php

namespace App\Services;

use App\Http\Attributes\Api\ApiController;
use App\Http\Attributes\Api\ApiResource;
use App\Http\Attributes\Api\Middleware;
use App\Http\Attributes\Api\ResponseType;
use App\Http\Attributes\Api\Route as RouteAttribute;
use App\Http\Attributes\Api\Throttle;
use Illuminate\Routing\Router;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;
use ReflectionClass;
use ReflectionMethod;

class RouteScanner
{
    /**
     * Scan controllers for API endpoint attributes and register routes.
     *
     * @param Router $router
     * @param string $controllerNamespace
     * @param string $controllerPath
     * @return void
     */
    public function scan(Router $router, string $controllerNamespace, string $controllerPath): void
    {
        $files = File::allFiles($controllerPath);

        foreach ($files as $file) {
            $controllerClass = $controllerNamespace . '\\' . str_replace(
                ['/', '.php'],
                ['\\', ''],
                Str::after($file->getPathname(), $controllerPath . '/')
            );

            if (!class_exists($controllerClass)) {
                continue;
            }

            $this->registerControllerRoutes($router, $controllerClass);
        }
    }

    /**
     * Register routes for a controller.
     *
     * @param Router $router
     * @param string $controllerClass
     * @return void
     */
    protected function registerControllerRoutes(Router $router, string $controllerClass): void
    {
        $reflection = new ReflectionClass($controllerClass);
        $controllerAttributes = $reflection->getAttributes(ApiController::class);

        if (empty($controllerAttributes)) {
            return;
        }

        $controllerAttribute = $controllerAttributes[0]->newInstance();
        $prefix = $controllerAttribute->prefix;
        $controllerMiddleware = $controllerAttribute->middleware;

        $router->group(['prefix' => $prefix, 'middleware' => $controllerMiddleware], function (Router $router) use ($reflection, $controllerClass) {
            $methods = $reflection->getMethods(ReflectionMethod::IS_PUBLIC);

            foreach ($methods as $method) {
                if ($method->class !== $controllerClass) {
                    continue;
                }

                $routeAttributes = $method->getAttributes(RouteAttribute::class);

                if (empty($routeAttributes)) {
                    continue;
                }

                foreach ($routeAttributes as $routeAttribute) {
                    $route = $routeAttribute->newInstance();
                    $httpMethod = strtolower($route->method);
                    $uri = $route->uri;
                    $action = [$method->class, $method->name];
                    $name = $route->name;

                    $routeInstance = $router->{$httpMethod}($uri, $action);

                    if ($name) {
                        $routeInstance->name($name);
                    }

                    $middlewareAttributes = $method->getAttributes(Middleware::class);
                    foreach ($middlewareAttributes as $middlewareAttribute) {
                        $middleware = $middlewareAttribute->newInstance()->middleware;
                        $routeInstance->middleware($middleware);
                    }

                    $throttleAttributes = $method->getAttributes(Throttle::class);
                    foreach ($throttleAttributes as $throttleAttribute) {
                        $throttle = $throttleAttribute->newInstance();
                        $routeInstance->middleware("throttle:{$throttle->maxAttempts},{$throttle->decayMinutes}");
                    }
                }
            }
        });
    }
}
```

## Step 3: Register the Route Scanner in the RouteServiceProvider

Now, let's update the RouteServiceProvider to use our route scanner:

```php
<?php

namespace App\Providers;

use App\Services\RouteScanner;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Foundation\Support\Providers\RouteServiceProvider as ServiceProvider;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Route;

class RouteServiceProvider extends ServiceProvider
{
    /**
     * The path to your application's "home" route.
     *
     * Typically, users are redirected here after authentication.
     *
     * @var string
     */
    public const HOME = '/dashboard';

    /**
     * Define your route model bindings, pattern filters, and other route configuration.
     */
    public function boot(): void
    {
        RateLimiter::for('api', function (Request $request) {
            return Limit::perMinute(60)->by($request->user()?->id ?: $request->ip());
        });

        $this->routes(function () {
            Route::middleware('api')
                ->prefix('api')
                ->group(base_path('routes/api.php'));

            Route::middleware('web')
                ->group(base_path('routes/web.php'));

            // Scan API controllers for route attributes
            $this->scanApiRoutes();
        });
    }

    /**
     * Scan API controllers for route attributes.
     *
     * @return void
     */
    protected function scanApiRoutes(): void
    {
        $scanner = new RouteScanner();
        $scanner->scan(
            $this->app['router'],
            'App\\Http\\Controllers\\Api',
            app_path('Http/Controllers/Api')
        );
    }
}
```

## Step 4: Using Attribute-Based API Endpoints

Now, we can define API endpoints using attributes:

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Attributes\Api\ApiController;
use App\Http\Attributes\Api\ApiResource;
use App\Http\Attributes\Api\Middleware;
use App\Http\Attributes\Api\ResponseType;
use App\Http\Attributes\Api\Route;
use App\Http\Attributes\Api\Throttle;
use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\Request;

#[ApiController(prefix: 'api/users', middleware: ['api'])]
class UserController extends Controller
{
    #[Route(method: 'GET', uri: '/', name: 'api.users.index')]
    #[Middleware('auth:sanctum')]
    #[ResponseType('json')]
    #[ApiResource(resource: UserResource::class, collection: true)]
    #[Throttle(maxAttempts: 60, decayMinutes: 1)]
    public function index()
    {
        return User::all();
    }

    #[Route(method: 'GET', uri: '/{user}', name: 'api.users.show')]
    #[Middleware('auth:sanctum')]
    #[ResponseType('json')]
    #[ApiResource(resource: UserResource::class)]
    public function show(User $user)
    {
        return $user;
    }

    #[Route(method: 'POST', uri: '/', name: 'api.users.store')]
    #[Middleware('auth:sanctum')]
    #[Middleware('can:create,App\Models\User')]
    #[ResponseType('json')]
    #[ApiResource(resource: UserResource::class)]
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => bcrypt($validated['password']),
        ]);

        return $user;
    }

    #[Route(method: 'PUT', uri: '/{user}', name: 'api.users.update')]
    #[Middleware('auth:sanctum')]
    #[Middleware('can:update,user')]
    #[ResponseType('json')]
    #[ApiResource(resource: UserResource::class)]
    public function update(Request $request, User $user)
    {
        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|string|email|max:255|unique:users,email,' . $user->id,
            'password' => 'sometimes|string|min:8|confirmed',
        ]);

        if (isset($validated['password'])) {
            $validated['password'] = bcrypt($validated['password']);
        }

        $user->update($validated);

        return $user;
    }

    #[Route(method: 'DELETE', uri: '/{user}', name: 'api.users.destroy')]
    #[Middleware('auth:sanctum')]
    #[Middleware('can:delete,user')]
    #[ResponseType('json')]
    public function destroy(User $user)
    {
        $user->delete();

        return response()->json(['message' => 'User deleted successfully']);
    }
}
```

## Benefits of Attribute-Based API Endpoints

Using attributes for API endpoints offers several benefits:

1. **Colocation**: Route definitions are colocated with their handlers, making the code easier to understand and maintain
2. **Type Safety**: Attribute parameters are type-checked, catching errors early
3. **IDE Support**: Modern IDEs provide autocompletion and validation for attributes
4. **Self-Documenting**: The API's structure is clearly visible in the controller code
5. **Reduced Boilerplate**: No need for lengthy route definitions in separate files
6. **Consistency**: All route-related configuration is defined in one place

## Performance Considerations

Reading attributes via reflection can be expensive, especially if done on every request. To mitigate this, consider:

1. **Caching Route Definitions**: Cache the generated routes in production
2. **Lazy Loading**: Only scan controllers when needed
3. **Precompilation**: Generate route definitions during deployment rather than at runtime

## Conclusion

Attribute-based API endpoints provide a clean, declarative way to define API routes and their properties. By leveraging PHP 8 attributes, we can create a more intuitive and type-safe API for our controllers, improving developer experience and reducing the likelihood of configuration errors.
