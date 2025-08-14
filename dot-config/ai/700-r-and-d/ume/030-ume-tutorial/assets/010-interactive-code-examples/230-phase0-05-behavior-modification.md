# PHP 8 Attributes - Model Feature Configuration

:::interactive-code
title: Attribute-Based Model Feature Configuration
description: This example demonstrates how to use attributes to configure model features in a Laravel-like approach, similar to the UME HasAdditionalFeatures trait.
language: php
editable: true
code: |
  <?php
  
  // Define feature attributes
  
  #[Attribute(Attribute::TARGET_CLASS)]
  class HasUlid {
      public function __construct(
          public ?string $column = 'ulid'
      ) {}
  }
  
  #[Attribute(Attribute::TARGET_CLASS)]
  class HasSlug {
      public function __construct(
          public string $source,
          public string $column = 'slug'
      ) {}
  }
  
  #[Attribute(Attribute::TARGET_CLASS)]
  class HasUserTracking {
      public function __construct(
          public bool $trackCreated = true,
          public bool $trackUpdated = true,
          public bool $trackDeleted = false,
          public string $createdByColumn = 'created_by',
          public string $updatedByColumn = 'updated_by',
          public string $deletedByColumn = 'deleted_by'
      ) {}
  }
  
  // Feature manager trait
  trait HasAdditionalFeatures {
      // Boot method that would be called by Laravel's model booting process
      public static function bootHasAdditionalFeatures() {
          // This would be called when the model is booted
          static::configureFeatures();
      }
      
      // Configure features based on attributes
      protected static function configureFeatures() {
          $reflection = new ReflectionClass(static::class);
          
          // Check for HasUlid
          $ulidAttributes = $reflection->getAttributes(HasUlid::class);
          foreach ($ulidAttributes as $attribute) {
              $config = $attribute->newInstance();
              static::configureUlid($config);
          }
          
          // Check for HasSlug
          $slugAttributes = $reflection->getAttributes(HasSlug::class);
          foreach ($slugAttributes as $attribute) {
              $config = $attribute->newInstance();
              static::configureSlug($config);
          }
          
          // Check for HasUserTracking
          $trackingAttributes = $reflection->getAttributes(HasUserTracking::class);
          foreach ($trackingAttributes as $attribute) {
              $config = $attribute->newInstance();
              static::configureUserTracking($config);
          }
      }
      
      // Configure ULID feature
      protected static function configureUlid(HasUlid $config) {
          echo "Configuring ULID for " . static::class . " with column: " . $config->column . "\n";
          // In a real implementation, this would set up ULID generation
      }
      
      // Configure slug feature
      protected static function configureSlug(HasSlug $config) {
          echo "Configuring slug for " . static::class . " with source: " . $config->source . 
               " and column: " . $config->column . "\n";
          // In a real implementation, this would set up slug generation
      }
      
      // Configure user tracking feature
      protected static function configureUserTracking(HasUserTracking $config) {
          echo "Configuring user tracking for " . static::class . ":\n";
          echo "- Track created: " . ($config->trackCreated ? 'Yes' : 'No') . 
               " (Column: " . $config->createdByColumn . ")\n";
          echo "- Track updated: " . ($config->trackUpdated ? 'Yes' : 'No') . 
               " (Column: " . $config->updatedByColumn . ")\n";
          echo "- Track deleted: " . ($config->trackDeleted ? 'Yes' : 'No') . 
               " (Column: " . $config->deletedByColumn . ")\n";
          // In a real implementation, this would set up user tracking
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
  
  // Example of another model with different configuration
  #[HasUlid(column: 'uuid')]
  #[HasUserTracking(trackCreated: true, trackUpdated: true, trackDeleted: true)]
  class User {
      use HasAdditionalFeatures;
      
      public string $name;
      public string $email;
      
      public function __construct(string $name, string $email) {
          $this->name = $name;
          $this->email = $email;
          
          // Call boot method manually for this example
          static::bootHasAdditionalFeatures();
      }
  }
  
  // Create a user
  $user = new User('John Doe', 'john@example.com');
explanation: |
  This example demonstrates how to use attributes for model feature configuration:
  
  1. **Feature Attributes**: We define attributes for different model features:
     - `HasUlid`: Configures ULID generation for a model
     - `HasSlug`: Configures slug generation from a source field
     - `HasUserTracking`: Configures automatic tracking of users who create, update, or delete records
  
  2. **Feature Manager Trait**: The `HasAdditionalFeatures` trait:
     - Provides a boot method that would be called by Laravel's model booting process
     - Uses reflection to read feature attributes from the model class
     - Configures each feature based on its attribute parameters
  
  3. **Declarative Configuration**: Models can declare which features they want and how they should be configured using attributes:
     - The `Post` model uses all three features with some custom configuration
     - The `User` model uses ULID and user tracking with different configuration
  
  4. **Centralized Logic**: The implementation details for each feature are encapsulated in the trait, keeping the models clean and focused on their business logic.
  
  This approach is similar to how the UME tutorial uses attributes for model configuration, providing a clean, declarative way to add features to models.
challenges:
  - Add a new HasTags attribute that configures tagging functionality for a model
  - Modify the HasSlug attribute to support multiple source fields (e.g., combining first_name and last_name)
  - Add a HasMetadata attribute that allows storing and retrieving arbitrary metadata for a model
  - Create a new model that uses a combination of these features with custom configuration
  - Extend the HasAdditionalFeatures trait to support feature dependencies (e.g., HasTags might require HasUlid)
:::
