# State Machine Basics

:::interactive-code
title: Implementing a Basic State Machine
description: This example demonstrates how to implement a basic state machine for managing user account states.
language: php
editable: true
code: |
  <?php
  
  namespace App\States;
  
  // Abstract base state class
  abstract class State {
      protected $context;
      
      public function setContext($context) {
          $this->context = $context;
      }
      
      // Methods that all states must implement
      abstract public function getName(): string;
      abstract public function canActivate(): bool;
      abstract public function canSuspend(): bool;
      abstract public function canVerify(): bool;
      abstract public function canDelete(): bool;
      
      // Default implementations for transitions
      public function activate() {
          if (!$this->canActivate()) {
              throw new \Exception("Cannot activate account from " . $this->getName() . " state");
          }
      }
      
      public function suspend() {
          if (!$this->canSuspend()) {
              throw new \Exception("Cannot suspend account from " . $this->getName() . " state");
          }
      }
      
      public function verify() {
          if (!$this->canVerify()) {
              throw new \Exception("Cannot verify account from " . $this->getName() . " state");
          }
      }
      
      public function delete() {
          if (!$this->canDelete()) {
              throw new \Exception("Cannot delete account from " . $this->getName() . " state");
          }
      }
  }
  
  // Concrete state implementations
  class PendingState extends State {
      public function getName(): string {
          return 'pending';
      }
      
      public function canActivate(): bool {
          return false;
      }
      
      public function canSuspend(): bool {
          return false;
      }
      
      public function canVerify(): bool {
          return true;
      }
      
      public function canDelete(): bool {
          return true;
      }
      
      public function verify() {
          parent::verify();
          $this->context->transitionTo(new VerifiedState());
          echo "Account verified. Waiting for activation.\n";
      }
      
      public function delete() {
          parent::delete();
          $this->context->transitionTo(new DeletedState());
          echo "Pending account deleted.\n";
      }
  }
  
  class VerifiedState extends State {
      public function getName(): string {
          return 'verified';
      }
      
      public function canActivate(): bool {
          return true;
      }
      
      public function canSuspend(): bool {
          return false;
      }
      
      public function canVerify(): bool {
          return false;
      }
      
      public function canDelete(): bool {
          return true;
      }
      
      public function activate() {
          parent::activate();
          $this->context->transitionTo(new ActiveState());
          echo "Account activated.\n";
      }
      
      public function delete() {
          parent::delete();
          $this->context->transitionTo(new DeletedState());
          echo "Verified account deleted.\n";
      }
  }
  
  class ActiveState extends State {
      public function getName(): string {
          return 'active';
      }
      
      public function canActivate(): bool {
          return false;
      }
      
      public function canSuspend(): bool {
          return true;
      }
      
      public function canVerify(): bool {
          return false;
      }
      
      public function canDelete(): bool {
          return true;
      }
      
      public function suspend() {
          parent::suspend();
          $this->context->transitionTo(new SuspendedState());
          echo "Account suspended.\n";
      }
      
      public function delete() {
          parent::delete();
          $this->context->transitionTo(new DeletedState());
          echo "Active account deleted.\n";
      }
  }
  
  class SuspendedState extends State {
      public function getName(): string {
          return 'suspended';
      }
      
      public function canActivate(): bool {
          return true;
      }
      
      public function canSuspend(): bool {
          return false;
      }
      
      public function canVerify(): bool {
          return false;
      }
      
      public function canDelete(): bool {
          return true;
      }
      
      public function activate() {
          parent::activate();
          $this->context->transitionTo(new ActiveState());
          echo "Suspended account reactivated.\n";
      }
      
      public function delete() {
          parent::delete();
          $this->context->transitionTo(new DeletedState());
          echo "Suspended account deleted.\n";
      }
  }
  
  class DeletedState extends State {
      public function getName(): string {
          return 'deleted';
      }
      
      public function canActivate(): bool {
          return false;
      }
      
      public function canSuspend(): bool {
          return false;
      }
      
      public function canVerify(): bool {
          return false;
      }
      
      public function canDelete(): bool {
          return false;
      }
  }
  
  // Context class that maintains the current state
  class UserAccount {
      private $state;
      private $email;
      private $name;
      
      public function __construct(string $name, string $email) {
          $this->name = $name;
          $this->email = $email;
          
          // Set initial state to pending
          $this->transitionTo(new PendingState());
      }
      
      public function transitionTo(State $state) {
          echo "Transitioning from " . ($this->state ? $this->state->getName() : 'null') . 
               " to " . $state->getName() . " state.\n";
          
          $this->state = $state;
          $this->state->setContext($this);
      }
      
      public function getState(): State {
          return $this->state;
      }
      
      public function getStateName(): string {
          return $this->state->getName();
      }
      
      // Methods that delegate to the current state
      public function activate() {
          $this->state->activate();
      }
      
      public function suspend() {
          $this->state->suspend();
      }
      
      public function verify() {
          $this->state->verify();
      }
      
      public function delete() {
          $this->state->delete();
      }
      
      // Helper methods to check if actions are allowed
      public function canActivate(): bool {
          return $this->state->canActivate();
      }
      
      public function canSuspend(): bool {
          return $this->state->canSuspend();
      }
      
      public function canVerify(): bool {
          return $this->state->canVerify();
      }
      
      public function canDelete(): bool {
          return $this->state->canDelete();
      }
      
      // Get user info
      public function getInfo(): string {
          return "User: {$this->name}, Email: {$this->email}, State: {$this->getStateName()}";
      }
  }
  
  // Example usage
  $user = new UserAccount('John Doe', 'john@example.com');
  echo $user->getInfo() . "\n";
  
  // Display available actions
  echo "\nAvailable actions:\n";
  echo "- Can activate: " . ($user->canActivate() ? 'Yes' : 'No') . "\n";
  echo "- Can suspend: " . ($user->canSuspend() ? 'Yes' : 'No') . "\n";
  echo "- Can verify: " . ($user->canVerify() ? 'Yes' : 'No') . "\n";
  echo "- Can delete: " . ($user->canDelete() ? 'Yes' : 'No') . "\n";
  
  // Verify the account
  echo "\nVerifying account...\n";
  $user->verify();
  echo $user->getInfo() . "\n";
  
  // Display available actions after verification
  echo "\nAvailable actions after verification:\n";
  echo "- Can activate: " . ($user->canActivate() ? 'Yes' : 'No') . "\n";
  echo "- Can suspend: " . ($user->canSuspend() ? 'Yes' : 'No') . "\n";
  echo "- Can verify: " . ($user->canVerify() ? 'Yes' : 'No') . "\n";
  echo "- Can delete: " . ($user->canDelete() ? 'Yes' : 'No') . "\n";
  
  // Activate the account
  echo "\nActivating account...\n";
  $user->activate();
  echo $user->getInfo() . "\n";
  
  // Try an invalid action
  echo "\nTrying to verify an active account...\n";
  try {
      $user->verify();
  } catch (\Exception $e) {
      echo "Error: " . $e->getMessage() . "\n";
  }
explanation: |
  This example demonstrates a basic state machine implementation for managing user account states:
  
  1. **State Pattern**: We use the State design pattern to encapsulate state-specific behavior in separate classes.
  
  2. **State Transitions**: Each state defines which transitions are allowed and how they should be handled.
  
  3. **Context Class**: The `UserAccount` class maintains the current state and delegates actions to it.
  
  4. **Validation**: Each state implements methods to check if specific actions are allowed, preventing invalid state transitions.
  
  5. **State Hierarchy**: All states inherit from an abstract `State` class that defines the common interface.
  
  The state machine defines five states:
  - **Pending**: Initial state for new accounts
  - **Verified**: Email has been verified but account is not yet active
  - **Active**: Account is fully active
  - **Suspended**: Account has been temporarily disabled
  - **Deleted**: Account has been permanently deleted
  
  Each state defines which transitions are allowed:
  - Pending → Verified → Active → Suspended → Active
  - Any state except Deleted → Deleted
  
  In a real Laravel application, you would:
  - Store the current state in the database
  - Use events to trigger side effects when states change
  - Add guards to check additional conditions before allowing transitions
challenges:
  - Add a new "Locked" state that occurs after too many failed login attempts
  - Implement a "grace period" for deleted accounts where they can be restored
  - Add a history of state transitions with timestamps
  - Create a method to visualize the possible state transitions as a graph
  - Add guards that check additional conditions before allowing transitions (e.g., admin approval)
:::
