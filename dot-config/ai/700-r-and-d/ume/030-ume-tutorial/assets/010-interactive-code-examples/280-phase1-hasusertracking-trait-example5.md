# HasUserTracking Trait Implementation

:::interactive-code
title: Implementing a HasUserTracking Trait for Laravel Models
description: This example demonstrates how to create and use a HasUserTracking trait to automatically track which users create, update, and delete models.
language: php
editable: true
code: |
  <?php
  
  namespace App\Models\Traits;
  
  use Illuminate\Database\Eloquent\Model;
  use Illuminate\Database\Eloquent\Relations\BelongsTo;
  use Illuminate\Support\Facades\Auth;
  
  trait HasUserTracking {
      /**
       * Boot the trait.
       *
       * @return void
       */
      public static function bootHasUserTracking() {
          // Set created_by when creating a model
          static::creating(function (Model $model) {
              if ($model->trackCreatedBy() && !$model->{$model->getCreatedByColumn()} && Auth::check()) {
                  $model->{$model->getCreatedByColumn()} = Auth::id();
              }
          });
          
          // Set updated_by when updating a model
          static::updating(function (Model $model) {
              if ($model->trackUpdatedBy() && Auth::check()) {
                  $model->{$model->getUpdatedByColumn()} = Auth::id();
              }
          });
          
          // Set deleted_by when soft deleting a model
          static::deleting(function (Model $model) {
              if ($model->trackDeletedBy() && method_exists($model, 'isSoftDeleted') && Auth::check()) {
                  $model->{$model->getDeletedByColumn()} = Auth::id();
                  $model->save();
              }
          });
      }
      
      /**
       * Determine if the model should track created_by.
       *
       * @return bool
       */
      public function trackCreatedBy(): bool {
          return $this->userTrackingOptions()['track_created_by'] ?? true;
      }
      
      /**
       * Determine if the model should track updated_by.
       *
       * @return bool
       */
      public function trackUpdatedBy(): bool {
          return $this->userTrackingOptions()['track_updated_by'] ?? true;
      }
      
      /**
       * Determine if the model should track deleted_by.
       *
       * @return bool
       */
      public function trackDeletedBy(): bool {
          return $this->userTrackingOptions()['track_deleted_by'] ?? false;
      }
      
      /**
       * Get the column name for created_by.
       *
       * @return string
       */
      public function getCreatedByColumn(): string {
          return $this->userTrackingOptions()['created_by_column'] ?? 'created_by';
      }
      
      /**
       * Get the column name for updated_by.
       *
       * @return string
       */
      public function getUpdatedByColumn(): string {
          return $this->userTrackingOptions()['updated_by_column'] ?? 'updated_by';
      }
      
      /**
       * Get the column name for deleted_by.
       *
       * @return string
       */
      public function getDeletedByColumn(): string {
          return $this->userTrackingOptions()['deleted_by_column'] ?? 'deleted_by';
      }
      
      /**
       * Get the user tracking options.
       *
       * @return array
       */
      public function userTrackingOptions(): array {
          return property_exists($this, 'userTrackingOptions') 
              ? $this->userTrackingOptions 
              : [];
      }
      
      /**
       * Get the user who created the model.
       *
       * @return \Illuminate\Database\Eloquent\Relations\BelongsTo
       */
      public function createdBy(): BelongsTo {
          return $this->belongsTo($this->getUserClass(), $this->getCreatedByColumn());
      }
      
      /**
       * Get the user who last updated the model.
       *
       * @return \Illuminate\Database\Eloquent\Relations\BelongsTo
       */
      public function updatedBy(): BelongsTo {
          return $this->belongsTo($this->getUserClass(), $this->getUpdatedByColumn());
      }
      
      /**
       * Get the user who deleted the model (for soft deletes).
       *
       * @return \Illuminate\Database\Eloquent\Relations\BelongsTo
       */
      public function deletedBy(): BelongsTo {
          return $this->belongsTo($this->getUserClass(), $this->getDeletedByColumn());
      }
      
      /**
       * Get the user model class name.
       *
       * @return string
       */
      protected function getUserClass(): string {
          return property_exists($this, 'userClass') 
              ? $this->userClass 
              : config('auth.providers.users.model', 'App\\Models\\User');
      }
  }
  
  // Simulate Auth facade
  class Auth {
      protected static $user = null;
      
      public static function check() {
          return static::$user !== null;
      }
      
      public static function id() {
          return static::$user ? static::$user->id : null;
      }
      
      public static function user() {
          return static::$user;
      }
      
      public static function login($user) {
          static::$user = $user;
      }
      
      public static function logout() {
          static::$user = null;
      }
  }
  
  // Example models
  class User {
      public $id;
      public $name;
      
      public function __construct($id, $name) {
          $this->id = $id;
          $this->name = $name;
      }
  }
  
  class Post {
      use HasUserTracking;
      
      // Custom user tracking options
      protected $userTrackingOptions = [
          'track_created_by' => true,
          'track_updated_by' => true,
          'track_deleted_by' => true,
          'created_by_column' => 'author_id',
          'updated_by_column' => 'editor_id',
          'deleted_by_column' => 'deleted_by',
      ];
      
      public $id;
      public $title;
      public $content;
      public $author_id;
      public $editor_id;
      public $deleted_by;
      
      public function __construct($id = null, $title = null, $content = null) {
          $this->id = $id;
          $this->title = $title;
          $this->content = $content;
      }
      
      // Simulate model events and relationships
      public static function creating($callback) {
          static::$creatingCallbacks[] = $callback;
      }
      
      public static function updating($callback) {
          static::$updatingCallbacks[] = $callback;
      }
      
      public static function deleting($callback) {
          static::$deletingCallbacks[] = $callback;
      }
      
      protected static $creatingCallbacks = [];
      protected static $updatingCallbacks = [];
      protected static $deletingCallbacks = [];
      
      public function save() {
          $isNew = $this->id === null;
          
          if ($isNew) {
              $this->id = rand(1, 1000);
              
              foreach (static::$creatingCallbacks as $callback) {
                  $callback($this);
              }
          } else {
              foreach (static::$updatingCallbacks as $callback) {
                  $callback($this);
              }
          }
          
          return $this;
      }
      
      public function delete() {
          foreach (static::$deletingCallbacks as $callback) {
              $callback($this);
          }
          
          return true;
      }
      
      public function belongsTo($class, $foreignKey) {
          return new BelongsToRelation($this, $class, $foreignKey);
      }
      
      // Simulate soft deletes
      public function isSoftDeleted() {
          return true;
      }
  }
  
  class BelongsToRelation {
      protected $parent;
      protected $related;
      protected $foreignKey;
      
      public function __construct($parent, $related, $foreignKey) {
          $this->parent = $parent;
          $this->related = $related;
          $this->foreignKey = $foreignKey;
      }
      
      public function getRelationName() {
          return $this->foreignKey;
      }
  }
  
  // Boot the trait
  Post::bootHasUserTracking();
  
  // Example usage
  $user = new User(1, 'John Doe');
  Auth::login($user);
  
  echo "Creating a new post...\n";
  $post = new Post(null, 'Hello World', 'This is my first post');
  $post->save();
  
  echo "Post author_id: " . $post->author_id . "\n";
  
  echo "\nUpdating the post...\n";
  $post->title = 'Updated Title';
  $post->save();
  
  echo "Post editor_id: " . $post->editor_id . "\n";
  
  echo "\nDeleting the post...\n";
  $post->delete();
  
  echo "Post deleted_by: " . $post->deleted_by . "\n";
  
  // Change user
  $user2 = new User(2, 'Jane Smith');
  Auth::login($user2);
  
  echo "\nCreating another post with a different user...\n";
  $post2 = new Post(null, 'Second Post', 'This is another post');
  $post2->save();
  
  echo "Post author_id: " . $post2->author_id . "\n";
explanation: |
  This example demonstrates how to implement a `HasUserTracking` trait for Laravel models:
  
  1. **Automatic User Tracking**: The trait automatically tracks which users create, update, and delete models.
  
  2. **Model Events**: The trait uses Laravel's model events:
     - `creating`: Sets the created_by field
     - `updating`: Sets the updated_by field
     - `deleting`: Sets the deleted_by field for soft deletes
  
  3. **Customizable Options**: Models can customize:
     - Which actions to track (created, updated, deleted)
     - The column names for each tracking field
     - The user model class
  
  4. **Relationships**: The trait provides relationships to easily access the users who created, updated, or deleted a model.
  
  5. **Soft Delete Support**: The trait supports tracking who deleted a model when using soft deletes.
  
  In a real Laravel application:
  - The model would extend `Illuminate\Database\Eloquent\Model`
  - You would create a migration to add the tracking columns to your table
  - The Auth facade would be provided by Laravel
  - Relationships would be handled by Laravel's ORM
challenges:
  - Add a method to get a history of all users who have modified the model
  - Implement a scope to find all models created by a specific user
  - Add support for tracking which user approved a model (for models with approval workflows)
  - Create a trait that combines HasUserTracking with HasTimestamps for complete audit trails
  - Implement a method to determine if the current user can edit a model based on who created it
:::
