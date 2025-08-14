# Single Table Inheritance - Basic Implementation

:::interactive-code
title: Basic Single Table Inheritance Implementation
description: This example demonstrates how to implement Single Table Inheritance (STI) in Laravel models.
language: php
editable: true
code: |
  <?php
  
  namespace App\Models;
  
  use Illuminate\Database\Eloquent\Model;
  
  // Base User model
  class User extends Model {
      protected $fillable = [
          'name', 
          'email',
          'password',
          'type', // This column determines the user type
      ];
      
      // Scope to get users of a specific type
      public function scopeOfType($query, string $type) {
          return $query->where('type', $type);
      }
      
      // Factory method to create the correct user type instance
      public static function factory(array $attributes = []) {
          $type = $attributes['type'] ?? null;
          
          if ($type === 'admin') {
              return new AdminUser($attributes);
          } elseif ($type === 'customer') {
              return new CustomerUser($attributes);
          } else {
              return new static($attributes);
          }
      }
  }
  
  // Admin User model (extends the base User)
  class AdminUser extends User {
      // Override the constructor to set the type
      public function __construct(array $attributes = []) {
          parent::__construct($attributes);
          $this->attributes['type'] = 'admin';
      }
      
      // Admin-specific method
      public function canAccessDashboard(): bool {
          return true;
      }
  }
  
  // Customer User model (extends the base User)
  class CustomerUser extends User {
      // Override the constructor to set the type
      public function __construct(array $attributes = []) {
          parent::__construct($attributes);
          $this->attributes['type'] = 'customer';
      }
      
      // Customer-specific method
      public function canAccessDashboard(): bool {
          return false;
      }
  }
  
  // Example usage
  $admin = new AdminUser([
      'name' => 'Admin User',
      'email' => 'admin@example.com',
      'password' => 'password',
  ]);
  
  $customer = new CustomerUser([
      'name' => 'Customer User',
      'email' => 'customer@example.com',
      'password' => 'password',
  ]);
  
  echo "Admin user type: " . $admin->attributes['type'] . "\n";
  echo "Admin can access dashboard: " . ($admin->canAccessDashboard() ? 'Yes' : 'No') . "\n\n";
  
  echo "Customer user type: " . $customer->attributes['type'] . "\n";
  echo "Customer can access dashboard: " . ($customer->canAccessDashboard() ? 'Yes' : 'No') . "\n\n";
  
  // Using the factory method
  $user = User::factory([
      'name' => 'New Admin',
      'email' => 'newadmin@example.com',
      'password' => 'password',
      'type' => 'admin',
  ]);
  
  echo "Factory created user type: " . get_class($user) . "\n";
  echo "Can access dashboard: " . ($user->canAccessDashboard() ? 'Yes' : 'No');
explanation: |
  This example demonstrates the basics of Single Table Inheritance (STI) in Laravel:
  
  1. **Base Model**: The `User` class is the base model that all user types inherit from.
  
  2. **Type Column**: The `type` column in the database determines which specific user type a record represents.
  
  3. **Child Models**: `AdminUser` and `CustomerUser` extend the base `User` model and set their specific type.
  
  4. **Type-Specific Methods**: Each child model can implement its own methods or override methods from the parent.
  
  5. **Factory Method**: The `factory` method creates the appropriate user type instance based on the `type` attribute.
  
  6. **Type Scopes**: The `scopeOfType` method allows querying for users of a specific type.
  
  In a real Laravel application, you would also need to:
  - Set up a database migration with the `type` column
  - Configure model events to ensure the type is always set correctly
  - Implement proper type casting and validation
challenges:
  - Add a new user type called "GuestUser" with limited permissions
  - Implement a method to convert one user type to another
  - Add a "role" property to AdminUser with values like "super", "manager", etc.
  - Create a method in the base User class that returns all possible user types
  - Implement a validation method that ensures the type column matches the actual class
:::
