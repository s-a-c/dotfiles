# PHP 8 Attributes Exercises - Sample Answers (Part 5)

<link rel="stylesheet" href="../assets/css/styles.css">

This file contains sample answers for the fifth set of PHP 8 attributes exercises. For additional parts, see the related files.

## Set 5: Attribute-Based API Endpoints

### Question Answers

1. **What is the purpose of attribute-based API endpoint configuration?**
   - **Answer: B) To define API routes directly on controller methods**
   - Explanation: Attribute-based API endpoint configuration allows developers to define API routes directly on controller methods, making the code more self-documenting and reducing the need for separate route files.

2. **Which attribute would you use to define an API route on a controller method?**
   - **Answer: C) `#[Route]`**
   - Explanation: In the UME tutorial, the `#[Route]` attribute is used to define an API route on a controller method.

3. **How do you specify middleware for an API endpoint using attributes?**
   - **Answer: C) `#[Middleware('auth:sanctum')]`**
   - Explanation: The `#[Middleware('auth:sanctum')]` attribute is used to specify middleware for an API endpoint.

4. **What component is needed to process attribute-based API endpoints?**
   - **Answer: A) A route scanner service**
   - Explanation: A route scanner service is needed to scan controllers for API endpoint attributes and register the corresponding routes.

5. **Which of the following is NOT a benefit of attribute-based API endpoints?**
   - **Answer: C) Faster API response times**
   - Explanation: Attribute-based API endpoints improve code organization, type safety, and self-documentation, but they do not directly affect API response times.

### Exercise: Create a controller with attribute-based API endpoints

First, let's create the necessary attributes:

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

Now, let's create a ProductController with attribute-based API endpoints:

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Attributes\Api\ApiController;
use App\Http\Attributes\Api\Middleware;
use App\Http\Attributes\Api\ResponseType;
use App\Http\Attributes\Api\Route;
use App\Http\Controllers\Controller;
use App\Http\Requests\ProductRequest;
use App\Models\Product;
use Illuminate\Http\Request;

#[ApiController(prefix: 'api/products', middleware: ['api'])]
class ProductController extends Controller
{
    #[Route(method: 'GET', uri: '/', name: 'api.products.index')]
    #[Middleware('auth:sanctum')]
    #[ResponseType('json')]
    public function index()
    {
        return Product::all();
    }

    #[Route(method: 'GET', uri: '/{product}', name: 'api.products.show')]
    #[Middleware('auth:sanctum')]
    #[ResponseType('json')]
    public function show(Product $product)
    {
        return $product;
    }

    #[Route(method: 'POST', uri: '/', name: 'api.products.store')]
    #[Middleware('auth:sanctum')]
    #[Middleware('can:create,App\Models\Product')]
    #[ResponseType('json')]
    public function store(ProductRequest $request)
    {
        $product = Product::create($request->validated());
        return response()->json($product, 201);
    }

    #[Route(method: 'PUT', uri: '/{product}', name: 'api.products.update')]
    #[Middleware('auth:sanctum')]
    #[Middleware('can:update,product')]
    #[ResponseType('json')]
    public function update(ProductRequest $request, Product $product)
    {
        $product->update($request->validated());
        return $product;
    }

    #[Route(method: 'DELETE', uri: '/{product}', name: 'api.products.destroy')]
    #[Middleware('auth:sanctum')]
    #[Middleware('can:delete,product')]
    #[ResponseType('json')]
    public function destroy(Product $product)
    {
        $product->delete();
        return response()->json(['message' => 'Product deleted successfully']);
    }
}
```

Finally, let's create a route scanner service to process these attributes:

```php
<?php

namespace App\Services;

use App\Http\Attributes\Api\ApiController;
use App\Http\Attributes\Api\Middleware;
use App\Http\Attributes\Api\ResponseType;
use App\Http\Attributes\Api\Route as RouteAttribute;
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

                    $responseTypeAttributes = $method->getAttributes(ResponseType::class);
                    if (!empty($responseTypeAttributes)) {
                        $responseType = $responseTypeAttributes[0]->newInstance()->type;
                        if ($responseType === 'json') {
                            $routeInstance->middleware('json');
                        }
                    }
                }
            }
        });
    }
}
```

To use this route scanner, you would update the RouteServiceProvider:

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

This implementation demonstrates:

1. **Class-level attributes**:
   - `#[ApiController(prefix: 'api/products', middleware: ['api'])]`: Defines a prefix and middleware for all routes in the controller

2. **Method-level attributes**:
   - `#[Route(method: 'GET', uri: '/', name: 'api.products.index')]`: Defines an API route
   - `#[Middleware('auth:sanctum')]`: Applies middleware to the route
   - `#[ResponseType('json')]`: Specifies the response type

3. **Route scanner service**:
   - Scans controllers for API endpoint attributes
   - Registers routes based on the attributes
   - Applies middleware and other configuration

The benefits of using attribute-based API endpoints include:

1. **Colocation**: Route definitions are colocated with their handlers, making the code easier to understand and maintain
2. **Type safety**: Attribute parameters are type-checked, catching errors early
3. **IDE support**: Modern IDEs provide autocompletion and validation for attributes
4. **Self-documenting**: The API's structure is clearly visible in the controller code
5. **Reduced boilerplate**: No need for lengthy route definitions in separate files
6. **Consistency**: All route-related configuration is defined in one place

To mitigate the performance impact of using reflection, you could cache the generated routes:

```php
protected function scanApiRoutes(): void
{
    $cacheKey = 'api_routes';
    
    if (app()->environment('production') && cache()->has($cacheKey)) {
        $routes = cache()->get($cacheKey);
        foreach ($routes as $route) {
            $this->app['router']->addRoute($route);
        }
    } else {
        $scanner = new RouteScanner();
        $scanner->scan(
            $this->app['router'],
            'App\\Http\\Controllers\\Api',
            app_path('Http/Controllers/Api')
        );
        
        if (app()->environment('production')) {
            cache()->put($cacheKey, $this->app['router']->getRoutes()->getRoutes(), now()->addDay());
        }
    }
}
```
