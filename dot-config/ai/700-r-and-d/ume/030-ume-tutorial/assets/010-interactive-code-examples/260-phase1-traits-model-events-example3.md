# Traits and Model Events

:::interactive-code
title: Using Traits and Model Events in Laravel
description: This example demonstrates how to create and use traits with model events in Laravel.
language: php
editable: true
code: |
  <?php
  
  namespace App\Models\Traits;
  
  // Define a trait for logging model changes
  trait LogsModelChanges {
      // Boot method that will be called when the model is booted
      public static function bootLogsModelChanges() {
          // Register event listeners
          static::created(function ($model) {
              static::logChange($model, 'created');
          });
          
          static::updated(function ($model) {
              static::logChange($model, 'updated');
          });
          
          static::deleted(function ($model) {
              static::logChange($model, 'deleted');
          });
      }
      
      // Method to log the change
      protected static function logChange($model, string $action) {
          $modelName = class_basename($model);
          $modelId = $model->getKey();
          $changes = $action === 'updated' ? $model->getChanges() : [];
          
          // In a real app, this would write to a database or log file
          echo "LOG: {$action} {$modelName} with ID {$modelId}\n";
          
          if (!empty($changes)) {
              echo "Changes: " . json_encode($changes) . "\n";
          }
      }
      
      // Add a method to manually log a custom action
      public function logCustomAction(string $action, array $data = []) {
          $modelName = class_basename($this);
          $modelId = $this->getKey();
          
          echo "LOG: {$action} {$modelName} with ID {$modelId}\n";
          
          if (!empty($data)) {
              echo "Data: " . json_encode($data) . "\n";
          }
      }
  }
  
  // Define a trait for timestamping models
  trait HasCustomTimestamps {
      // Boot method for the trait
      public static function bootHasCustomTimestamps() {
          static::creating(function ($model) {
              if (!$model->created_at) {
                  $model->created_at = now();
              }
              
              if (!$model->updated_at) {
                  $model->updated_at = now();
              }
          });
          
          static::updating(function ($model) {
              $model->updated_at = now();
          });
      }
      
      // Get the current timestamp (in a real app, this would use Carbon)
      protected function now() {
          return date('Y-m-d H:i:s');
      }
  }
  
  // Example model using the traits
  namespace App\Models;
  
  use App\Models\Traits\LogsModelChanges;
  use App\Models\Traits\HasCustomTimestamps;
  
  class Post {
      use LogsModelChanges, HasCustomTimestamps;
      
      public $id;
      public $title;
      public $content;
      public $created_at;
      public $updated_at;
      
      public function __construct(array $attributes = []) {
          $this->id = $attributes['id'] ?? null;
          $this->title = $attributes['title'] ?? null;
          $this->content = $attributes['content'] ?? null;
          $this->created_at = $attributes['created_at'] ?? null;
          $this->updated_at = $attributes['updated_at'] ?? null;
      }
      
      // In a real Laravel model, these would be handled by the framework
      public function getKey() {
          return $this->id;
      }
      
      public function getChanges() {
          // Simplified for this example
          return [
              'title' => $this->title,
              'content' => $this->content,
          ];
      }
      
      // Simulate model events
      public static function created($callback) {
          static::$createdCallbacks[] = $callback;
      }
      
      public static function updated($callback) {
          static::$updatedCallbacks[] = $callback;
      }
      
      public static function deleted($callback) {
          static::$deletedCallbacks[] = $callback;
      }
      
      public static function creating($callback) {
          static::$creatingCallbacks[] = $callback;
      }
      
      public static function updating($callback) {
          static::$updatingCallbacks[] = $callback;
      }
      
      // Static properties to store callbacks
      protected static $createdCallbacks = [];
      protected static $updatedCallbacks = [];
      protected static $deletedCallbacks = [];
      protected static $creatingCallbacks = [];
      protected static $updatingCallbacks = [];
      
      // Simulate model operations
      public function save() {
          $isNew = $this->id === null;
          
          if ($isNew) {
              $this->id = rand(1, 1000); // Generate a random ID
              
              // Run creating callbacks
              foreach (static::$creatingCallbacks as $callback) {
                  $callback($this);
              }
              
              // Run created callbacks
              foreach (static::$createdCallbacks as $callback) {
                  $callback($this);
              }
          } else {
              // Run updating callbacks
              foreach (static::$updatingCallbacks as $callback) {
                  $callback($this);
              }
              
              // Run updated callbacks
              foreach (static::$updatedCallbacks as $callback) {
                  $callback($this);
              }
          }
          
          return $this;
      }
      
      public function delete() {
          // Run deleted callbacks
          foreach (static::$deletedCallbacks as $callback) {
              $callback($this);
          }
          
          $this->id = null;
          return true;
      }
  }
  
  // Boot the traits (in Laravel, this would be done automatically)
  Post::bootLogsModelChanges();
  Post::bootHasCustomTimestamps();
  
  // Example usage
  $post = new Post([
      'title' => 'Hello World',
      'content' => 'This is my first post',
  ]);
  
  echo "Creating a new post...\n";
  $post->save();
  
  echo "\nUpdating the post...\n";
  $post->title = 'Updated Title';
  $post->save();
  
  echo "\nLogging a custom action...\n";
  $post->logCustomAction('published', ['published_at' => date('Y-m-d H:i:s')]);
  
  echo "\nDeleting the post...\n";
  $post->delete();
explanation: |
  This example demonstrates how to use traits and model events in Laravel:
  
  1. **Traits**: We define two traits:
     - `LogsModelChanges`: Logs model creation, updates, and deletion
     - `HasCustomTimestamps`: Automatically sets created_at and updated_at timestamps
  
  2. **Model Events**: The traits use Laravel's model events:
     - `created`, `updated`, `deleted`: Triggered after the respective action
     - `creating`, `updating`: Triggered before the respective action
  
  3. **Boot Method**: Each trait has a `boot{TraitName}` method that registers event listeners. Laravel calls these methods automatically when the model is booted.
  
  4. **Event Handlers**: The event listeners perform actions when model events occur, such as logging changes or setting timestamps.
  
  5. **Custom Methods**: Traits can also add methods to the model, like `logCustomAction`.
  
  In a real Laravel application:
  - The model would extend `Illuminate\Database\Eloquent\Model`
  - Event handling would be managed by Laravel's event system
  - Timestamps would use Carbon instances
  - Logs would be written to a database or log file
challenges:
  - Add a new trait called `SoftDeletes` that marks records as deleted instead of actually deleting them
  - Extend the `LogsModelChanges` trait to include the user who made the change
  - Create a trait that automatically generates a slug from a title
  - Implement a trait that tracks the number of times a model has been viewed
  - Add a method to the `LogsModelChanges` trait to retrieve the history of changes for a model
:::
