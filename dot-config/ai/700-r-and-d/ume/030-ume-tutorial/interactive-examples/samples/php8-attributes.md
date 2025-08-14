# PHP 8 Attributes Interactive Examples

This file contains interactive examples demonstrating PHP 8 attributes and their usage in Laravel applications.

## Basic PHP 8 Attributes

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
  
  - **Defining an Attribute**: We create a `Route` class and mark it as an attribute using the `#[Attribute]` attribute.
  - **Attribute Parameters**: The `Route` attribute accepts two parameters: `method` and `path`.
  - **Applying an Attribute**: We apply the `Route` attribute to the `UserController` class using the `#[Route(...)]` syntax.
  - **Reading Attributes with Reflection**: We use PHP's Reflection API to read the attributes at runtime.
challenges: |
  - Add a `name` parameter to the `Route` attribute
  - Create a new attribute called `Middleware` that accepts an array of middleware names
  - Apply both the `Route` and `Middleware` attributes to the `UserController` class
:::

## Attribute Targets

:::interactive-code
title: Restricting Attribute Targets
description: This example demonstrates how to restrict where attributes can be applied.
language: php
editable: true
code: |
  <?php
  
  // Define attributes with different targets
  #[Attribute(Attribute::TARGET_CLASS)]
  class ClassOnly {
      public function __construct(
          public string $name
      ) {}
  }
  
  #[Attribute(Attribute::TARGET_PROPERTY)]
  class PropertyOnly {
      public function __construct(
          public string $name
      ) {}
  }
  
  #[Attribute(Attribute::TARGET_METHOD)]
  class MethodOnly {
      public function __construct(
          public string $name
      ) {}
  }
  
  #[Attribute(Attribute::TARGET_CLASS | Attribute::TARGET_PROPERTY)]
  class ClassOrProperty {
      public function __construct(
          public string $name
      ) {}
  }
  
  // Apply attributes to different targets
  #[ClassOnly(name: 'ExampleClass')]
  class Example {
      #[ClassOrProperty(name: 'exampleProperty')]
      public string $property;
      
      #[MethodOnly(name: 'exampleMethod')]
      public function method() {
          return 'Hello';
      }
  }
  
  // Use reflection to read and validate the attributes
  $classReflection = new ReflectionClass(Example::class);
  $propertyReflection = $classReflection->getProperty('property');
  $methodReflection = $classReflection->getMethod('method');
  
  // Check class attributes
  $classAttributes = $classReflection->getAttributes();
  echo "Class attributes:\n";
  foreach ($classAttributes as $attribute) {
      echo "- " . $attribute->getName() . "\n";
  }
  
  // Check property attributes
  $propertyAttributes = $propertyReflection->getAttributes();
  echo "\nProperty attributes:\n";
  foreach ($propertyAttributes as $attribute) {
      echo "- " . $attribute->getName() . "\n";
  }
  
  // Check method attributes
  $methodAttributes = $methodReflection->getAttributes();
  echo "\nMethod attributes:\n";
  foreach ($methodAttributes as $attribute) {
      echo "- " . $attribute->getName() . "\n";
  }
explanation: |
  This example demonstrates how to restrict where attributes can be applied:
  
  - **TARGET_CLASS**: The attribute can only be applied to classes
  - **TARGET_PROPERTY**: The attribute can only be applied to properties
  - **TARGET_METHOD**: The attribute can only be applied to methods
  - **TARGET_CLASS | TARGET_PROPERTY**: The attribute can be applied to classes or properties
  
  The `Attribute` constructor accepts a bitmask of targets, which restricts where the attribute can be used. If you try to apply an attribute to an invalid target, PHP will throw an error.
  
  Using reflection, we can read the attributes from different elements and verify they were applied correctly.
challenges: |
  - Create an attribute that can be applied to parameters
  - Create an attribute that can be applied to classes, methods, and properties
  - Try applying an attribute to an invalid target and observe the error
:::

## Repeatable Attributes

:::interactive-code
title: Using Repeatable Attributes
description: This example demonstrates how to create and use repeatable attributes.
language: php
editable: true
code: |
  <?php
  
  // Define a repeatable attribute
  #[Attribute(Attribute::TARGET_CLASS | Attribute::IS_REPEATABLE)]
  class Tag {
      public function __construct(
          public string $name,
          public string $value = ''
      ) {}
  }
  
  // Apply multiple instances of the same attribute to a class
  #[Tag(name: 'category', value: 'tutorial')]
  #[Tag(name: 'language', value: 'php')]
  #[Tag(name: 'version', value: '8.0')]
  class Article {
      private string $title;
      private string $content;
      
      public function __construct(string $title, string $content) {
          $this->title = $title;
          $this->content = $content;
      }
      
      public function getTitle(): string {
          return $this->title;
      }
      
      public function getContent(): string {
          return $this->content;
      }
  }
  
  // Create an article
  $article = new Article(
      'Understanding PHP 8 Attributes',
      'PHP 8 introduces attributes, a powerful new feature...'
  );
  
  // Use reflection to read all Tag attributes
  $reflection = new ReflectionClass($article);
  $attributes = $reflection->getAttributes(Tag::class);
  
  echo "Article: {$article->getTitle()}\n";
  echo "Tags:\n";
  
  foreach ($attributes as $attribute) {
      $tag = $attribute->newInstance();
      echo "- {$tag->name}: {$tag->value}\n";
  }
explanation: |
  This example demonstrates how to create and use repeatable attributes:
  
  - **IS_REPEATABLE**: This flag allows the attribute to be applied multiple times to the same target
  - **Multiple Attributes**: We apply the `Tag` attribute three times to the `Article` class
  - **Reading Attributes**: We use reflection to read all instances of the `Tag` attribute
  
  Repeatable attributes are useful for cases where you need to apply the same type of metadata multiple times, such as tags, validation rules, or route definitions.
challenges: |
  - Create a repeatable `Validate` attribute for validating properties
  - Apply multiple validation rules to a single property
  - Create a system that processes all validation rules when an object is created
:::

## Attribute-Based Model Features

:::interactive-code
title: Implementing Attribute-Based Model Features
description: This example demonstrates how to use attributes to configure model features, similar to the UME HasAdditionalFeatures trait.
language: php
editable: true
code: |
  <?php
  
  // Define attributes for model features
  #[Attribute(Attribute::TARGET_CLASS)]
  class HasUlid {
      public function __construct(
          public ?string $column = 'ulid',
          public ?string $prefix = null
      ) {}
  }
  
  #[Attribute(Attribute::TARGET_CLASS)]
  class HasSlug {
      public function __construct(
          public string $source,
          public ?string $column = 'slug'
      ) {}
  }
  
  #[Attribute(Attribute::TARGET_CLASS)]
  class HasUserTracking {
      public function __construct(
          public bool $trackCreated = true,
          public bool $trackUpdated = true,
          public bool $trackDeleted = false
      ) {}
  }
  
  // Define a trait for additional features
  trait HasAdditionalFeatures {
      // Boot method that would be called by Laravel
      public static function bootHasAdditionalFeatures() {
          // Get the class that uses this trait
          $class = static::class;
          
          // Get reflection for the class
          $reflection = new ReflectionClass($class);
          
          // Check for HasUlid attribute
          $ulidAttributes = $reflection->getAttributes(HasUlid::class);
          if (!empty($ulidAttributes)) {
              $ulidConfig = $ulidAttributes[0]->newInstance();
              static::bootHasUlid($ulidConfig);
          }
          
          // Check for HasSlug attribute
          $slugAttributes = $reflection->getAttributes(HasSlug::class);
          if (!empty($slugAttributes)) {
              $slugConfig = $slugAttributes[0]->newInstance();
              static::bootHasSlug($slugConfig);
          }
          
          // Check for HasUserTracking attribute
          $trackingAttributes = $reflection->getAttributes(HasUserTracking::class);
          if (!empty($trackingAttributes)) {
              $trackingConfig = $trackingAttributes[0]->newInstance();
              static::bootHasUserTracking($trackingConfig);
          }
      }
      
      // Boot HasUlid feature
      protected static function bootHasUlid(HasUlid $config) {
          echo "Booting HasUlid with column: {$config->column}";
          if ($config->prefix) {
              echo " and prefix: {$config->prefix}";
          }
          echo "\n";
          
          // In a real implementation, this would set up event listeners
          // to automatically generate ULIDs for new models
      }
      
      // Boot HasSlug feature
      protected static function bootHasSlug(HasSlug $config) {
          echo "Booting HasSlug with source: {$config->source} and column: {$config->column}\n";
          
          // In a real implementation, this would set up event listeners
          // to automatically generate slugs from the source field
      }
      
      // Boot HasUserTracking feature
      protected static function bootHasUserTracking(HasUserTracking $config) {
          echo "Booting HasUserTracking with:\n";
          echo "- Track created: " . ($config->trackCreated ? 'Yes' : 'No') . "\n";
          echo "- Track updated: " . ($config->trackUpdated ? 'Yes' : 'No') . "\n";
          echo "- Track deleted: " . ($config->trackDeleted ? 'Yes' : 'No') . "\n";
          
          // In a real implementation, this would set up event listeners
          // to automatically track user IDs for various operations
      }
  }
  
  // Example model using the features
  #[HasUlid]
  #[HasSlug(source: 'title')]
  #[HasUserTracking(trackDeleted: true)]
  class Post {
      use HasAdditionalFeatures;
      
      public string $title;
      public string $content;
      
      public function __construct(string $title, string $content) {
          $this->title = $title;
          $this->content = $content;
          
          // In Laravel, the bootHasAdditionalFeatures method would be called automatically
          // For this example, we'll call it manually
          static::bootHasAdditionalFeatures();
      }
  }
  
  // Create a post
  $post = new Post(
      'Understanding PHP 8 Attributes',
      'PHP 8 introduces attributes, a powerful new feature...'
  );
explanation: |
  This example demonstrates how to use attributes to configure model features:
  
  - **Feature Attributes**: We define attributes for different model features (HasUlid, HasSlug, HasUserTracking)
  - **HasAdditionalFeatures Trait**: We create a trait that reads these attributes and configures the model accordingly
  - **Reflection-Based Configuration**: The trait uses reflection to read the attributes and apply the configuration
  
  This approach offers several advantages:
  
  1. **Declarative Configuration**: The model's features are clearly visible at the class level
  2. **Type Safety**: Attribute parameters are type-checked
  3. **IDE Support**: Modern IDEs provide autocompletion and validation for attributes
  4. **Centralized Logic**: Feature implementation details are encapsulated in the trait
  
  In a real Laravel application, the `bootHasAdditionalFeatures` method would be called automatically when the model is booted.
challenges: |
  - Add a new `HasTags` attribute and corresponding boot method
  - Modify the `HasUserTracking` attribute to accept custom column names
  - Create a `HasTimestamps` attribute that allows customizing the timestamp column names
:::

## Conclusion

These interactive examples demonstrate the power and flexibility of PHP 8 attributes. By using attributes, you can add metadata to your code in a type-safe, standardized way, enabling powerful features like the UME HasAdditionalFeatures trait.
