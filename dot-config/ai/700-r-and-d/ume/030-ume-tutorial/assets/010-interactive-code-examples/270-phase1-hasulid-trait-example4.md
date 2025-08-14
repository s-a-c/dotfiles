# HasUlid Trait Implementation

:::interactive-code
title: Implementing a HasUlid Trait for Laravel Models
description: This example demonstrates how to create and use a HasUlid trait to generate ULIDs for Laravel models.
language: php
editable: true
code: |
  <?php
  
  namespace App\Models\Traits;
  
  use Illuminate\Database\Eloquent\Model;
  use Symfony\Component\Uid\Ulid;
  
  trait HasUlid {
      /**
       * Boot the trait.
       *
       * @return void
       */
      public static function bootHasUlid() {
          static::creating(function (Model $model) {
              // Only set ULID if it hasn't been set already and the column exists
              if (!$model->{$model->getUlidColumn()} && $model->hasUlidColumn()) {
                  $model->{$model->getUlidColumn()} = static::generateUlid();
              }
          });
      }
      
      /**
       * Generate a new ULID.
       *
       * @return string
       */
      public static function generateUlid(): string {
          // In a real implementation, this would use Symfony's Ulid class
          // For this example, we'll create a simplified version
          return static::simulateUlid();
      }
      
      /**
       * Simulate a ULID for demonstration purposes.
       * In a real app, use Symfony\Component\Uid\Ulid.
       *
       * @return string
       */
      protected static function simulateUlid(): string {
          // ULIDs are 26 characters, base32 encoded
          // First 10 chars are timestamp, last 16 are random
          $timestamp = str_pad(base_convert(time(), 10, 32), 10, '0', STR_PAD_LEFT);
          $random = '';
          $chars = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'; // Base32 chars (excluding I, L, O, U)
          
          for ($i = 0; $i < 16; $i++) {
              $random .= $chars[random_int(0, 31)];
          }
          
          return strtoupper($timestamp . $random);
      }
      
      /**
       * Get the name of the ULID column.
       *
       * @return string
       */
      public function getUlidColumn(): string {
          return defined(static::class . '::ULID_COLUMN') 
              ? static::ULID_COLUMN 
              : 'ulid';
      }
      
      /**
       * Determine if the model has a ULID column.
       *
       * @return bool
       */
      public function hasUlidColumn(): bool {
          return true; // In a real app, this would check if the column exists
      }
      
      /**
       * Scope a query to find by ULID.
       *
       * @param \Illuminate\Database\Eloquent\Builder $query
       * @param string $ulid
       * @return \Illuminate\Database\Eloquent\Builder
       */
      public function scopeWhereUlid($query, string $ulid) {
          return $query->where($this->getUlidColumn(), $ulid);
      }
      
      /**
       * Find a model by its ULID.
       *
       * @param string $ulid
       * @param array $columns
       * @return \Illuminate\Database\Eloquent\Model|null
       */
      public static function findByUlid(string $ulid, array $columns = ['*']) {
          $instance = new static;
          return $instance->whereUlid($ulid)->first($columns);
      }
      
      /**
       * Find a model by its ULID or fail.
       *
       * @param string $ulid
       * @param array $columns
       * @return \Illuminate\Database\Eloquent\Model
       * @throws \Illuminate\Database\Eloquent\ModelNotFoundException
       */
      public static function findByUlidOrFail(string $ulid, array $columns = ['*']) {
          $instance = new static;
          return $instance->whereUlid($ulid)->firstOrFail($columns);
      }
  }
  
  // Example model using the trait
  namespace App\Models;
  
  use App\Models\Traits\HasUlid;
  
  class User {
      use HasUlid;
      
      // Define a custom ULID column name (optional)
      const ULID_COLUMN = 'uuid';
      
      public $id;
      public $uuid; // Our ULID column
      public $name;
      public $email;
      
      public function __construct(array $attributes = []) {
          $this->id = $attributes['id'] ?? null;
          $this->uuid = $attributes['uuid'] ?? null;
          $this->name = $attributes['name'] ?? null;
          $this->email = $attributes['email'] ?? null;
      }
      
      // Simulate model events (in Laravel, these would be handled by the framework)
      public static function creating($callback) {
          static::$creatingCallbacks[] = $callback;
      }
      
      protected static $creatingCallbacks = [];
      
      // Simulate model creation
      public function save() {
          if ($this->id === null) {
              $this->id = rand(1, 1000); // Generate a random ID
              
              // Run creating callbacks
              foreach (static::$creatingCallbacks as $callback) {
                  $callback($this);
              }
          }
          
          return $this;
      }
      
      // Simulate query builder methods
      public function where($column, $value) {
          echo "Query: WHERE {$column} = {$value}\n";
          return $this;
      }
      
      public function first($columns = ['*']) {
          echo "Query: SELECT " . implode(', ', $columns) . "\n";
          return $this;
      }
      
      public function firstOrFail($columns = ['*']) {
          echo "Query: SELECT " . implode(', ', $columns) . " OR FAIL\n";
          return $this;
      }
  }
  
  // Boot the trait (in Laravel, this would be done automatically)
  User::bootHasUlid();
  
  // Example usage
  $user = new User([
      'name' => 'John Doe',
      'email' => 'john@example.com',
  ]);
  
  echo "Creating a new user...\n";
  $user->save();
  
  echo "\nUser ID: {$user->id}\n";
  echo "User ULID: {$user->uuid}\n";
  
  echo "\nFinding a user by ULID...\n";
  User::findByUlid('01H1G3V9S3ABCDEFGHJKMNPQRS');
  
  echo "\nFinding a user by ULID or fail...\n";
  User::findByUlidOrFail('01H1G3V9S3ABCDEFGHJKMNPQRS');
explanation: |
  This example demonstrates how to implement a `HasUlid` trait for Laravel models:
  
  1. **ULID Generation**: The trait automatically generates a ULID (Universally Unique Lexicographically Sortable Identifier) when a model is created.
  
  2. **Custom Column Name**: Models can specify a custom column name for the ULID by defining a `ULID_COLUMN` constant.
  
  3. **Model Events**: The trait uses Laravel's `creating` event to set the ULID before the model is saved.
  
  4. **Query Scopes**: The trait provides query scopes to find models by their ULID.
  
  5. **Helper Methods**: The trait adds helper methods like `findByUlid` and `findByUlidOrFail` to easily retrieve models by ULID.
  
  Key benefits of ULIDs over UUIDs:
  - Time-ordered (lexicographically sortable)
  - Shorter string representation (26 characters vs 36 for UUID)
  - URL-safe (base32 encoded)
  - Contains a timestamp component
  
  In a real Laravel application:
  - You would use the Symfony ULID implementation (`composer require symfony/uid`)
  - The model would extend `Illuminate\Database\Eloquent\Model`
  - You would create a migration to add the ULID column to your table
challenges:
  - Modify the trait to support using the ULID as the primary key
  - Add a method to convert an existing ID to a ULID
  - Implement a method to extract the timestamp from a ULID
  - Create a scope to find models created within a specific time range based on their ULIDs
  - Add support for multiple ULID columns on a single model
:::
