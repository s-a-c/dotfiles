# User Type Enum Implementation

:::interactive-code
title: PHP 8.1 Enums for User Types
description: This example demonstrates how to use PHP 8.1 enums to represent user types in a Laravel application.
language: php
editable: true
code: |
  <?php
  
  namespace App\Enums;
  
  // Define a backed enum for user types
  enum UserType: string {
      case Admin = 'admin';
      case Customer = 'customer';
      case Moderator = 'moderator';
      case Guest = 'guest';
      
      // Get a human-readable label for the user type
      public function label(): string {
          return match($this) {
              self::Admin => 'Administrator',
              self::Customer => 'Customer',
              self::Moderator => 'Content Moderator',
              self::Guest => 'Guest User',
          };
      }
      
      // Check if the user type has admin privileges
      public function hasAdminAccess(): bool {
          return match($this) {
              self::Admin => true,
              self::Moderator => true,
              default => false,
          };
      }
      
      // Get all user types that can access the admin dashboard
      public static function adminTypes(): array {
          return [
              self::Admin,
              self::Moderator,
          ];
      }
      
      // Get all user types as an array for dropdown menus, etc.
      public static function toArray(): array {
          return [
              self::Admin->value => self::Admin->label(),
              self::Customer->value => self::Customer->label(),
              self::Moderator->value => self::Moderator->label(),
              self::Guest->value => self::Guest->label(),
          ];
      }
  }
  
  // Example usage in a User model
  namespace App\Models;
  
  class User {
      private string $name;
      private string $email;
      private UserType $type;
      
      public function __construct(string $name, string $email, UserType $type) {
          $this->name = $name;
          $this->email = $email;
          $this->type = $type;
      }
      
      public function getName(): string {
          return $this->name;
      }
      
      public function getEmail(): string {
          return $this->email;
      }
      
      public function getType(): UserType {
          return $this->type;
      }
      
      public function canAccessAdminDashboard(): bool {
          return $this->type->hasAdminAccess();
      }
  }
  
  // Using the enum
  use App\Enums\UserType;
  use App\Models\User;
  
  // Create users with different types
  $admin = new User('Admin User', 'admin@example.com', UserType::Admin);
  $customer = new User('Customer User', 'customer@example.com', UserType::Customer);
  $moderator = new User('Moderator User', 'moderator@example.com', UserType::Moderator);
  
  // Display user information
  function displayUserInfo(User $user): void {
      echo "User: {$user->getName()}\n";
      echo "Email: {$user->getEmail()}\n";
      echo "Type: {$user->getType()->value} ({$user->getType()->label()})\n";
      echo "Can access admin dashboard: " . ($user->canAccessAdminDashboard() ? 'Yes' : 'No') . "\n\n";
  }
  
  displayUserInfo($admin);
  displayUserInfo($customer);
  displayUserInfo($moderator);
  
  // Display all user types for a dropdown
  echo "Available user types for dropdown:\n";
  foreach (UserType::toArray() as $value => $label) {
      echo "- Value: $value, Label: $label\n";
  }
explanation: |
  This example demonstrates how to use PHP 8.1 enums to represent user types in a Laravel application:
  
  1. **Backed Enum**: We define a `UserType` enum backed by string values that will be stored in the database.
  
  2. **Enum Methods**: The enum includes methods to:
     - Get a human-readable label for each type
     - Check if a type has admin access
     - Get all types with admin access
     - Convert all types to an array for dropdowns
  
  3. **Type Safety**: By using enums, we get compile-time type checking, ensuring that only valid user types can be assigned.
  
  4. **Integration with Models**: The `User` class accepts and returns a `UserType` enum, providing type safety throughout the application.
  
  5. **Business Logic in Enums**: The enum encapsulates business logic related to user types, such as determining which types have admin access.
  
  In a real Laravel application, you would:
  - Use Laravel's enum casting feature to automatically cast the database string to the enum
  - Create form requests that validate against the enum values
  - Use the enum in policies to control access
challenges:
  - Add a new user type called "Vendor" with specific permissions
  - Implement a method to get all user types that can create content
  - Add a "priority" method that returns a numeric priority for each user type
  - Create a method that groups user types by their access level
  - Implement a validation rule that ensures a value is a valid UserType
:::
