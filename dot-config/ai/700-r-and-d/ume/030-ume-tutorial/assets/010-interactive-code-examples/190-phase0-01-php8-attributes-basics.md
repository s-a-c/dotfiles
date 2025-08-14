# PHP 8 Attributes - Basic Example

:::interactive-code
title: Creating and Using Basic PHP 8 Attributes
description: This example demonstrates how to create a simple PHP 8 attribute and apply it to a class.
language: php
editable: true
code: |
  <?php
  
  // Define a simple attribute
  #[Attribute]
  class Route {
      public function __construct(
          public string $method,
          public string $path
      ) {}
  }
  
  // Apply the attribute to a class
  #[Route(method: 'GET', path: '/users')]
  class UserController {
      public function index() {
          return 'List of users';
      }
  }
  
  // Use reflection to read the attribute
  $reflection = new ReflectionClass(UserController::class);
  $attributes = $reflection->getAttributes(Route::class);
  
  foreach ($attributes as $attribute) {
      $route = $attribute->newInstance();
      echo "Controller route: {$route->method} {$route->path}\n";
  }
explanation: |
  This example demonstrates the basics of PHP 8 attributes:
  
  1. **Defining an Attribute**: We create a `Route` class and mark it as an attribute using the `#[Attribute]` attribute.
  
  2. **Attribute Parameters**: The `Route` attribute accepts two parameters: `method` and `path`.
  
  3. **Applying an Attribute**: We apply the `Route` attribute to the `UserController` class using the `#[Route(...)]` syntax.
  
  4. **Reading Attributes with Reflection**: We use PHP's Reflection API to read the attributes at runtime:
     - `ReflectionClass` to get information about the class
     - `getAttributes()` to retrieve all attributes of a specific type
     - `newInstance()` to create an instance of the attribute
     - Access the attribute's properties
challenges:
  - Add a new parameter to the Route attribute for middleware (e.g., 'auth', 'api', etc.)
  - Apply the Route attribute to the index method instead of the class
  - Make the Route attribute repeatable and apply multiple routes to the UserController
  - Create a second controller with a different route and display routes for both controllers
:::
