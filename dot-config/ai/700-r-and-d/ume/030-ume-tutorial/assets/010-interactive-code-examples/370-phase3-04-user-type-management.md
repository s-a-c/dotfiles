# User Type Management

:::interactive-code
title: Managing User Types with Type Transitions
description: This example demonstrates how to implement a user type management system with type transitions, validation, and permissions.
language: php
editable: true
code: |
  <?php
  
  namespace App\Models;
  
  use DateTime;
  use Exception;
  
  // User type enum
  enum UserType: string {
      case Regular = 'regular';
      case Premium = 'premium';
      case Business = 'business';
      case Admin = 'admin';
      case SuperAdmin = 'super_admin';
      
      public function label(): string {
          return match($this) {
              self::Regular => 'Regular User',
              self::Premium => 'Premium User',
              self::Business => 'Business User',
              self::Admin => 'Administrator',
              self::SuperAdmin => 'Super Administrator',
          };
      }
      
      public function description(): string {
          return match($this) {
              self::Regular => 'Basic access to the platform',
              self::Premium => 'Enhanced features and priority support',
              self::Business => 'Multiple user accounts and advanced features',
              self::Admin => 'Administrative access to manage users and content',
              self::SuperAdmin => 'Full access to all system features and settings',
          };
      }
      
      public function permissions(): array {
          return match($this) {
              self::Regular => [
                  'content:read',
                  'profile:edit',
              ],
              self::Premium => [
                  'content:read',
                  'content:create',
                  'profile:edit',
                  'support:priority',
              ],
              self::Business => [
                  'content:read',
                  'content:create',
                  'content:publish',
                  'profile:edit',
                  'team:manage',
                  'support:priority',
              ],
              self::Admin => [
                  'content:read',
                  'content:create',
                  'content:publish',
                  'content:moderate',
                  'profile:edit',
                  'user:manage',
                  'support:admin',
              ],
              self::SuperAdmin => [
                  'content:read',
                  'content:create',
                  'content:publish',
                  'content:moderate',
                  'profile:edit',
                  'user:manage',
                  'system:configure',
                  'support:admin',
              ],
          };
      }
      
      public function canTransitionTo(UserType $targetType): bool {
          // Define allowed transitions
          $allowedTransitions = match($this) {
              self::Regular => [self::Premium, self::Business],
              self::Premium => [self::Regular, self::Business],
              self::Business => [self::Regular, self::Premium],
              self::Admin => [self::Regular, self::Premium, self::Business, self::SuperAdmin],
              self::SuperAdmin => [self::Admin],
          };
          
          return in_array($targetType, $allowedTransitions);
      }
      
      public static function getUpgradePath(UserType $from, UserType $to): array {
          // Define upgrade paths for types that can't directly transition
          $upgradePaths = [
              self::Regular->value . '->' . self::Admin->value => [self::Premium, self::Business, self::Admin],
              self::Regular->value . '->' . self::SuperAdmin->value => [self::Premium, self::Business, self::Admin, self::SuperAdmin],
              self::Premium->value . '->' . self::Admin->value => [self::Business, self::Admin],
              self::Premium->value . '->' . self::SuperAdmin->value => [self::Business, self::Admin, self::SuperAdmin],
              self::Business->value . '->' . self::Admin->value => [self::Admin],
              self::Business->value . '->' . self::SuperAdmin->value => [self::Admin, self::SuperAdmin],
          ];
          
          $key = $from->value . '->' . $to->value;
          
          return $upgradePaths[$key] ?? [];
      }
  }
  
  // User type transition class
  class UserTypeTransition {
      private User $user;
      private UserType $fromType;
      private UserType $toType;
      private ?User $performedBy;
      private ?string $reason;
      private array $metadata = [];
      
      public function __construct(
          User $user,
          UserType $toType,
          ?User $performedBy = null,
          ?string $reason = null
      ) {
          $this->user = $user;
          $this->fromType = $user->getType();
          $this->toType = $toType;
          $this->performedBy = $performedBy;
          $this->reason = $reason;
      }
      
      /**
       * Add metadata to the transition.
       *
       * @param string $key
       * @param mixed $value
       * @return self
       */
      public function addMetadata(string $key, $value): self {
          $this->metadata[$key] = $value;
          return $this;
      }
      
      /**
       * Check if the transition is valid.
       *
       * @return bool
       */
      public function isValid(): bool {
          // Check if the user can transition to the target type
          if (!$this->fromType->canTransitionTo($this->toType)) {
              return false;
          }
          
          // Check if the user performing the transition has permission
          if ($this->performedBy && !$this->performedBy->can('user:manage-type')) {
              return false;
          }
          
          // For premium/business types, check if payment info is provided
          if (in_array($this->toType, [UserType::Premium, UserType::Business]) && 
              !isset($this->metadata['payment_method_id'])) {
              return false;
          }
          
          return true;
      }
      
      /**
       * Get validation errors.
       *
       * @return array
       */
      public function getValidationErrors(): array {
          $errors = [];
          
          // Check if the user can transition to the target type
          if (!$this->fromType->canTransitionTo($this->toType)) {
              $errors[] = "Cannot transition from {$this->fromType->label()} to {$this->toType->label()}";
          }
          
          // Check if the user performing the transition has permission
          if ($this->performedBy && !$this->performedBy->can('user:manage-type')) {
              $errors[] = "User does not have permission to manage user types";
          }
          
          // For premium/business types, check if payment info is provided
          if (in_array($this->toType, [UserType::Premium, UserType::Business]) && 
              !isset($this->metadata['payment_method_id'])) {
              $errors[] = "Payment method is required for premium and business accounts";
          }
          
          return $errors;
      }
      
      /**
       * Apply the transition.
       *
       * @return User
       * @throws Exception If the transition is not valid
       */
      public function apply(): User {
          if (!$this->isValid()) {
              throw new Exception("Invalid user type transition: " . implode(', ', $this->getValidationErrors()));
          }
          
          // Record the transition
          $transition = new UserTypeTransitionRecord(
              $this->user->getId(),
              $this->fromType,
              $this->toType,
              $this->performedBy ? $this->performedBy->getId() : null,
              $this->reason,
              $this->metadata
          );
          
          // Update the user's type
          $this->user->setType($this->toType);
          
          // Perform type-specific actions
          $this->performTypeSpecificActions();
          
          return $this->user;
      }
      
      /**
       * Perform actions specific to the target type.
       *
       * @return void
       */
      private function performTypeSpecificActions(): void {
          switch ($this->toType) {
              case UserType::Premium:
                  echo "Setting up premium features for user {$this->user->getName()}\n";
                  echo "Processing payment using method ID: {$this->metadata['payment_method_id']}\n";
                  break;
                  
              case UserType::Business:
                  echo "Setting up business features for user {$this->user->getName()}\n";
                  echo "Processing payment using method ID: {$this->metadata['payment_method_id']}\n";
                  echo "Creating default team for business user\n";
                  break;
                  
              case UserType::Admin:
                  echo "Granting administrative privileges to user {$this->user->getName()}\n";
                  echo "Sending admin access notification to security team\n";
                  break;
                  
              case UserType::SuperAdmin:
                  echo "Granting super administrative privileges to user {$this->user->getName()}\n";
                  echo "Sending super admin access notification to security team\n";
                  echo "Requiring two-factor authentication\n";
                  break;
                  
              case UserType::Regular:
                  if ($this->fromType === UserType::Premium || $this->fromType === UserType::Business) {
                      echo "Downgrading user {$this->user->getName()} to regular account\n";
                      echo "Canceling subscription\n";
                  }
                  break;
          }
      }
      
      /**
       * Get a summary of the transition.
       *
       * @return string
       */
      public function getSummary(): string {
          $summary = "Transition: {$this->fromType->label()} → {$this->toType->label()}";
          
          if ($this->reason) {
              $summary .= " (Reason: {$this->reason})";
          }
          
          return $summary;
      }
  }
  
  // User type transition record
  class UserTypeTransitionRecord {
      private int $userId;
      private UserType $fromType;
      private UserType $toType;
      private ?int $performedById;
      private ?string $reason;
      private array $metadata;
      private DateTime $timestamp;
      
      public function __construct(
          int $userId,
          UserType $fromType,
          UserType $toType,
          ?int $performedById = null,
          ?string $reason = null,
          array $metadata = []
      ) {
          $this->userId = $userId;
          $this->fromType = $fromType;
          $this->toType = $toType;
          $this->performedById = $performedById;
          $this->reason = $reason;
          $this->metadata = $metadata;
          $this->timestamp = new DateTime();
          
          // In a real app, this would be saved to the database
          echo "Recording user type transition: {$fromType->value} → {$toType->value}\n";
      }
  }
  
  // User class
  class User {
      private int $id;
      private string $name;
      private string $email;
      private UserType $type;
      private array $permissions = [];
      
      public function __construct(int $id, string $name, string $email, UserType $type = UserType::Regular) {
          $this->id = $id;
          $this->name = $name;
          $this->email = $email;
          $this->type = $type;
          
          // Add type-specific permissions
          $this->permissions = $type->permissions();
          
          // For admin users, add the ability to manage user types
          if ($type === UserType::Admin || $type === UserType::SuperAdmin) {
              $this->permissions[] = 'user:manage-type';
          }
      }
      
      /**
       * Get the user ID.
       *
       * @return int
       */
      public function getId(): int {
          return $this->id;
      }
      
      /**
       * Get the user name.
       *
       * @return string
       */
      public function getName(): string {
          return $this->name;
      }
      
      /**
       * Get the user email.
       *
       * @return string
       */
      public function getEmail(): string {
          return $this->email;
      }
      
      /**
       * Get the user type.
       *
       * @return UserType
       */
      public function getType(): UserType {
          return $this->type;
      }
      
      /**
       * Set the user type.
       *
       * @param UserType $type
       * @return self
       */
      public function setType(UserType $type): self {
          $this->type = $type;
          
          // Update permissions based on the new type
          $this->permissions = $type->permissions();
          
          // For admin users, add the ability to manage user types
          if ($type === UserType::Admin || $type === UserType::SuperAdmin) {
              $this->permissions[] = 'user:manage-type';
          }
          
          return $this;
      }
      
      /**
       * Check if the user has a specific permission.
       *
       * @param string $permission
       * @return bool
       */
      public function can(string $permission): bool {
          return in_array($permission, $this->permissions);
      }
      
      /**
       * Get all user permissions.
       *
       * @return array
       */
      public function getPermissions(): array {
          return $this->permissions;
      }
      
      /**
       * Create a transition to a new user type.
       *
       * @param UserType $newType
       * @param User|null $performedBy
       * @param string|null $reason
       * @return UserTypeTransition
       */
      public function transitionTo(
          UserType $newType,
          ?User $performedBy = null,
          ?string $reason = null
      ): UserTypeTransition {
          return new UserTypeTransition($this, $newType, $performedBy, $reason);
      }
      
      /**
       * Get a summary of the user.
       *
       * @return string
       */
      public function getSummary(): string {
          return "{$this->name} ({$this->email}) - {$this->type->label()}";
      }
  }
  
  // Example usage
  
  // Create users with different types
  $regularUser = new User(1, 'John Doe', 'john@example.com', UserType::Regular);
  $premiumUser = new User(2, 'Jane Smith', 'jane@example.com', UserType::Premium);
  $adminUser = new User(3, 'Admin User', 'admin@example.com', UserType::Admin);
  
  // Display user information
  echo "Users:\n";
  echo "- " . $regularUser->getSummary() . "\n";
  echo "- " . $premiumUser->getSummary() . "\n";
  echo "- " . $adminUser->getSummary() . "\n";
  
  // Display user permissions
  echo "\nRegular user permissions:\n";
  foreach ($regularUser->getPermissions() as $permission) {
      echo "- {$permission}\n";
  }
  
  echo "\nPremium user permissions:\n";
  foreach ($premiumUser->getPermissions() as $permission) {
      echo "- {$permission}\n";
  }
  
  // Upgrade a regular user to premium
  echo "\nUpgrading regular user to premium...\n";
  $transition = $regularUser->transitionTo(UserType::Premium, $adminUser, "Purchased premium subscription");
  $transition->addMetadata('payment_method_id', 'pm_123456789');
  
  echo $transition->getSummary() . "\n";
  
  if ($transition->isValid()) {
      $transition->apply();
      echo "User is now: " . $regularUser->getSummary() . "\n";
  } else {
      echo "Transition is not valid: " . implode(', ', $transition->getValidationErrors()) . "\n";
  }
  
  // Try to upgrade a regular user to admin (not allowed directly)
  echo "\nTrying to upgrade regular user to admin (not allowed directly)...\n";
  $transition = $regularUser->transitionTo(UserType::Admin, $adminUser, "Hiring as staff member");
  
  echo $transition->getSummary() . "\n";
  
  if ($transition->isValid()) {
      $transition->apply();
  } else {
      echo "Transition is not valid: " . implode(', ', $transition->getValidationErrors()) . "\n";
      
      // Get the upgrade path
      $upgradePath = UserType::getUpgradePath($regularUser->getType(), UserType::Admin);
      
      if (!empty($upgradePath)) {
          echo "Suggested upgrade path: ";
          $pathLabels = array_map(fn($type) => $type->label(), $upgradePath);
          echo implode(' → ', $pathLabels) . "\n";
      }
  }
  
  // Downgrade a premium user to regular
  echo "\nDowngrading premium user to regular...\n";
  $transition = $premiumUser->transitionTo(UserType::Regular, $adminUser, "Subscription canceled");
  
  echo $transition->getSummary() . "\n";
  
  if ($transition->isValid()) {
      $transition->apply();
      echo "User is now: " . $premiumUser->getSummary() . "\n";
  } else {
      echo "Transition is not valid: " . implode(', ', $transition->getValidationErrors()) . "\n";
  }
  
  // Try to perform a transition without proper permissions
  echo "\nTrying to perform a transition without proper permissions...\n";
  $regularUser2 = new User(4, 'Another User', 'another@example.com', UserType::Regular);
  $transition = $regularUser2->transitionTo(UserType::Admin, $regularUser2, "Self-promotion");
  
  echo $transition->getSummary() . "\n";
  
  if ($transition->isValid()) {
      $transition->apply();
  } else {
      echo "Transition is not valid: " . implode(', ', $transition->getValidationErrors()) . "\n";
  }
  
  // Try to upgrade to premium without payment info
  echo "\nTrying to upgrade to premium without payment info...\n";
  $transition = $regularUser2->transitionTo(UserType::Premium, $adminUser, "Promotional upgrade");
  
  echo $transition->getSummary() . "\n";
  
  if ($transition->isValid()) {
      $transition->apply();
  } else {
      echo "Transition is not valid: " . implode(', ', $transition->getValidationErrors()) . "\n";
  }
  
  // Upgrade to premium with payment info
  echo "\nUpgrading to premium with payment info...\n";
  $transition = $regularUser2->transitionTo(UserType::Premium, $adminUser, "Promotional upgrade");
  $transition->addMetadata('payment_method_id', 'pm_987654321');
  $transition->addMetadata('promotion_code', 'SUMMER2023');
  
  echo $transition->getSummary() . "\n";
  
  if ($transition->isValid()) {
      $transition->apply();
      echo "User is now: " . $regularUser2->getSummary() . "\n";
  } else {
      echo "Transition is not valid: " . implode(', ', $transition->getValidationErrors()) . "\n";
  }
explanation: |
  This example demonstrates a comprehensive user type management system:
  
  1. **User Types**: The system defines five user types with different permission levels:
     - **Regular**: Basic access to the platform
     - **Premium**: Enhanced features and priority support
     - **Business**: Multiple user accounts and advanced features
     - **Admin**: Administrative access to manage users and content
     - **SuperAdmin**: Full access to all system features and settings
  
  2. **Type Transitions**: The system enforces rules about which types can transition to others:
     - Regular → Premium/Business
     - Premium → Regular/Business
     - Business → Regular/Premium
     - Admin → Regular/Premium/Business/SuperAdmin
     - SuperAdmin → Admin
  
  3. **Transition Validation**: Before applying a transition, the system validates:
     - If the transition is allowed between the types
     - If the user performing the transition has permission
     - If required metadata is provided (e.g., payment information for premium accounts)
  
  4. **Transition Records**: Each transition is recorded with:
     - The user ID
     - The from and to types
     - Who performed the transition
     - A reason for the transition
     - Additional metadata
     - A timestamp
  
  5. **Type-Specific Actions**: When a user transitions to a new type, the system performs actions specific to that type:
     - Setting up premium features
     - Processing payments
     - Creating teams for business users
     - Granting administrative privileges
     - Requiring two-factor authentication for super admins
  
  6. **Upgrade Paths**: For types that can't directly transition to others, the system provides suggested upgrade paths.
  
  Key features of the implementation:
  
  - **Type Safety**: Using PHP 8.1 enums for user types
  - **Permission Management**: Each user type has a set of permissions
  - **Fluent Interface**: The transition API uses method chaining for a more readable syntax
  - **Validation Errors**: The system provides detailed validation errors when a transition is not valid
  
  In a real Laravel application:
  - User types and transitions would be stored in database tables
  - The system would integrate with Laravel's authorization system
  - Type-specific actions would be implemented as event listeners
  - Payment processing would integrate with a payment gateway
challenges:
  - Add support for temporary type upgrades with expiration dates
  - Implement a trial system for premium and business accounts
  - Create a workflow for requesting and approving admin access
  - Add support for custom permissions that can be assigned to specific users regardless of type
  - Implement a notification system that alerts users when their type changes
:::
