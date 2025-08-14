# Account Status Management

:::interactive-code
title: Managing User Account Status with State Pattern
description: This example demonstrates how to implement account status management using the state pattern with Laravel's model states package.
language: php
editable: true
code: |
  <?php
  
  namespace App\States\Account;
  
  // Base abstract state class (simulating Spatie's State class)
  abstract class State {
      protected $model;
      
      public function __construct($model = null) {
          $this->model = $model;
      }
      
      abstract public function name(): string;
      abstract public function color(): string;
      abstract public function icon(): string;
      abstract public function description(): string;
      
      // Define which transitions are allowed from this state
      abstract public function allowedTransitions(): array;
      
      // Check if a transition to the given state is allowed
      public function canTransitionTo(string $state): bool {
          return in_array($state, $this->allowedTransitions());
      }
      
      // Get all possible states
      public static function all(): array {
          return [
              Pending::class,
              Active::class,
              Suspended::class,
              Banned::class,
              Archived::class,
          ];
      }
  }
  
  // Concrete state implementations
  class Pending extends State {
      public function name(): string {
          return 'pending';
      }
      
      public function color(): string {
          return 'yellow';
      }
      
      public function icon(): string {
          return 'clock';
      }
      
      public function description(): string {
          return 'Account is pending email verification';
      }
      
      public function allowedTransitions(): array {
          return [
              Active::class,
              Banned::class,
              Archived::class,
          ];
      }
  }
  
  class Active extends State {
      public function name(): string {
          return 'active';
      }
      
      public function color(): string {
          return 'green';
      }
      
      public function icon(): string {
          return 'check-circle';
      }
      
      public function description(): string {
          return 'Account is active and in good standing';
      }
      
      public function allowedTransitions(): array {
          return [
              Suspended::class,
              Banned::class,
              Archived::class,
          ];
      }
  }
  
  class Suspended extends State {
      public function name(): string {
          return 'suspended';
      }
      
      public function color(): string {
          return 'orange';
      }
      
      public function icon(): string {
          return 'pause-circle';
      }
      
      public function description(): string {
          return 'Account is temporarily suspended';
      }
      
      public function allowedTransitions(): array {
          return [
              Active::class,
              Banned::class,
              Archived::class,
          ];
      }
  }
  
  class Banned extends State {
      public function name(): string {
          return 'banned';
      }
      
      public function color(): string {
          return 'red';
      }
      
      public function icon(): string {
          return 'ban';
      }
      
      public function description(): string {
          return 'Account is permanently banned';
      }
      
      public function allowedTransitions(): array {
          return [
              Active::class, // Only admins can unban
              Archived::class,
          ];
      }
  }
  
  class Archived extends State {
      public function name(): string {
          return 'archived';
      }
      
      public function color(): string {
          return 'gray';
      }
      
      public function icon(): string {
          return 'archive';
      }
      
      public function description(): string {
          return 'Account has been archived';
      }
      
      public function allowedTransitions(): array {
          return [
              Active::class, // Can be restored
          ];
      }
  }
  
  // Transition classes
  abstract class Transition {
      protected $user;
      
      public function __construct($user) {
          $this->user = $user;
      }
      
      abstract public function handle(): void;
      
      // Check if the transition can be applied
      abstract public function canTransition(): bool;
      
      // Get the name of the transition
      abstract public function name(): string;
  }
  
  class ActivateAccount extends Transition {
      public function handle(): void {
          if (!$this->canTransition()) {
              throw new \Exception("Cannot activate account from {$this->user->status->name()} state");
          }
          
          // In a real app, this would update the database
          $this->user->status = new Active($this->user);
          echo "Account activated successfully\n";
          
          // Additional actions when activating
          $this->sendWelcomeEmail();
      }
      
      public function canTransition(): bool {
          return $this->user->status->canTransitionTo(Active::class);
      }
      
      public function name(): string {
          return 'activate';
      }
      
      protected function sendWelcomeEmail(): void {
          echo "Sending welcome email to {$this->user->email}\n";
      }
  }
  
  class SuspendAccount extends Transition {
      private $reason;
      
      public function __construct($user, string $reason = null) {
          parent::__construct($user);
          $this->reason = $reason;
      }
      
      public function handle(): void {
          if (!$this->canTransition()) {
              throw new \Exception("Cannot suspend account from {$this->user->status->name()} state");
          }
          
          // In a real app, this would update the database
          $this->user->status = new Suspended($this->user);
          echo "Account suspended successfully\n";
          
          if ($this->reason) {
              echo "Suspension reason: {$this->reason}\n";
          }
          
          // Additional actions when suspending
          $this->sendSuspensionNotification();
      }
      
      public function canTransition(): bool {
          return $this->user->status->canTransitionTo(Suspended::class);
      }
      
      public function name(): string {
          return 'suspend';
      }
      
      protected function sendSuspensionNotification(): void {
          echo "Sending suspension notification to {$this->user->email}\n";
      }
  }
  
  // User model with state management
  class User {
      public $id;
      public $name;
      public $email;
      public $status;
      
      public function __construct(int $id, string $name, string $email) {
          $this->id = $id;
          $this->name = $name;
          $this->email = $email;
          $this->status = new Pending($this);
      }
      
      // Apply a transition to the user
      public function applyTransition(Transition $transition): void {
          $transition->handle();
      }
      
      // Get available transitions for the current state
      public function availableTransitions(): array {
          $transitions = [];
          
          foreach ($this->status->allowedTransitions() as $stateClass) {
              switch ($stateClass) {
                  case Active::class:
                      $transitions[] = new ActivateAccount($this);
                      break;
                  case Suspended::class:
                      $transitions[] = new SuspendAccount($this);
                      break;
                  // Add other transitions here
              }
          }
          
          return $transitions;
      }
      
      // Get user info with status
      public function getInfo(): string {
          return "User: {$this->name}, Email: {$this->email}, Status: {$this->status->name()} ({$this->status->description()})";
      }
  }
  
  // Example usage
  $user = new User(1, 'John Doe', 'john@example.com');
  echo $user->getInfo() . "\n";
  
  // Display available transitions
  echo "\nAvailable transitions:\n";
  foreach ($user->availableTransitions() as $transition) {
      echo "- {$transition->name()}\n";
  }
  
  // Activate the account
  echo "\nActivating account...\n";
  $user->applyTransition(new ActivateAccount($user));
  echo $user->getInfo() . "\n";
  
  // Display available transitions after activation
  echo "\nAvailable transitions after activation:\n";
  foreach ($user->availableTransitions() as $transition) {
      echo "- {$transition->name()}\n";
  }
  
  // Suspend the account
  echo "\nSuspending account...\n";
  $user->applyTransition(new SuspendAccount($user, "Violation of terms of service"));
  echo $user->getInfo() . "\n";
  
  // Try an invalid transition
  echo "\nTrying to suspend an already suspended account...\n";
  try {
      $user->applyTransition(new SuspendAccount($user));
  } catch (\Exception $e) {
      echo "Error: " . $e->getMessage() . "\n";
  }
explanation: |
  This example demonstrates how to implement account status management using the state pattern, similar to how you would use the `spatie/laravel-model-states` package:
  
  1. **State Classes**: Each possible account status is represented by a class that extends the base `State` class.
  
  2. **State Properties**: Each state defines properties like name, color, icon, and description to provide context about the state.
  
  3. **Allowed Transitions**: Each state defines which other states it can transition to, enforcing business rules about valid state changes.
  
  4. **Transition Classes**: Transitions between states are encapsulated in separate classes that handle the logic of changing states.
  
  5. **Side Effects**: Transitions can include side effects like sending emails or notifications.
  
  The example includes five account states:
  - **Pending**: Initial state for new accounts awaiting verification
  - **Active**: Account is fully active and usable
  - **Suspended**: Account is temporarily disabled
  - **Banned**: Account is permanently disabled due to violations
  - **Archived**: Account has been archived (soft deleted)
  
  And two transition types:
  - **ActivateAccount**: Transitions an account to the Active state
  - **SuspendAccount**: Transitions an account to the Suspended state
  
  In a real Laravel application using `spatie/laravel-model-states`:
  - States would be stored in the database
  - Transitions would be registered and could be applied using `$user->state->transition(new ActivateAccount())`
  - You would define a state field in your model's migration
  - The package would handle serialization and deserialization of states
challenges:
  - Add a new "Locked" state for accounts with too many failed login attempts
  - Implement a "BanAccount" transition with a required reason parameter
  - Create an "ArchiveAccount" transition that moves the account to the Archived state
  - Add a "RestoreAccount" transition that can restore archived accounts
  - Implement a history of state transitions with timestamps and the user who performed each transition
:::
