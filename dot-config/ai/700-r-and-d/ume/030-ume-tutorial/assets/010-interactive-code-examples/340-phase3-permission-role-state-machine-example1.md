# Permission Role State Machine

:::interactive-code
title: Implementing a Permission Role State Machine
description: This example demonstrates how to implement a state machine for managing role-based permissions with transitions and validation.
language: php
editable: true
code: |
  <?php
  
  namespace App\States\Role;
  
  use Exception;
  
  // Base abstract state class
  abstract class RoleState {
      protected $user;
      protected $team;
      
      public function __construct($user = null, $team = null) {
          $this->user = $user;
          $this->team = $team;
      }
      
      // Get the state name
      abstract public function name(): string;
      
      // Get the display name
      abstract public function displayName(): string;
      
      // Get the description
      abstract public function description(): string;
      
      // Get the permissions granted by this role
      abstract public function permissions(): array;
      
      // Define which transitions are allowed from this state
      abstract public function allowedTransitions(): array;
      
      // Check if a transition to the given state is allowed
      public function canTransitionTo(string $state): bool {
          return in_array($state, $this->allowedTransitions());
      }
      
      // Get all possible states
      public static function all(): array {
          return [
              Owner::class,
              Admin::class,
              Member::class,
              Guest::class,
              Suspended::class,
          ];
      }
  }
  
  // Owner role - highest level of access
  class Owner extends RoleState {
      public function name(): string {
          return 'owner';
      }
      
      public function displayName(): string {
          return 'Team Owner';
      }
      
      public function description(): string {
          return 'Full control over the team, including billing and deletion';
      }
      
      public function permissions(): array {
          return [
              'team:view',
              'team:edit',
              'team:delete',
              'team:manage-billing',
              'team:manage-members',
              'team:manage-roles',
              'content:create',
              'content:edit',
              'content:delete',
              'content:publish',
          ];
      }
      
      public function allowedTransitions(): array {
          // Owner can only transition to Admin (step down)
          return [
              Admin::class,
          ];
      }
  }
  
  // Admin role - high level of access but can't delete the team
  class Admin extends RoleState {
      public function name(): string {
          return 'admin';
      }
      
      public function displayName(): string {
          return 'Team Administrator';
      }
      
      public function description(): string {
          return 'Can manage team members and content, but cannot delete the team';
      }
      
      public function permissions(): array {
          return [
              'team:view',
              'team:edit',
              'team:manage-members',
              'team:manage-roles',
              'content:create',
              'content:edit',
              'content:delete',
              'content:publish',
          ];
      }
      
      public function allowedTransitions(): array {
          return [
              Owner::class, // Can be promoted to Owner
              Member::class, // Can be demoted to Member
              Suspended::class, // Can be suspended
          ];
      }
  }
  
  // Member role - standard team member
  class Member extends RoleState {
      public function name(): string {
          return 'member';
      }
      
      public function displayName(): string {
          return 'Team Member';
      }
      
      public function description(): string {
          return 'Can create and edit content, but cannot manage team settings';
      }
      
      public function permissions(): array {
          return [
              'team:view',
              'content:create',
              'content:edit',
              'content:publish',
          ];
      }
      
      public function allowedTransitions(): array {
          return [
              Admin::class, // Can be promoted to Admin
              Guest::class, // Can be demoted to Guest
              Suspended::class, // Can be suspended
          ];
      }
  }
  
  // Guest role - limited access
  class Guest extends RoleState {
      public function name(): string {
          return 'guest';
      }
      
      public function displayName(): string {
          return 'Team Guest';
      }
      
      public function description(): string {
          return 'Can view content but cannot create or edit';
      }
      
      public function permissions(): array {
          return [
              'team:view',
              'content:view',
          ];
      }
      
      public function allowedTransitions(): array {
          return [
              Member::class, // Can be promoted to Member
              Suspended::class, // Can be suspended
          ];
      }
  }
  
  // Suspended role - no access
  class Suspended extends RoleState {
      public function name(): string {
          return 'suspended';
      }
      
      public function displayName(): string {
          return 'Suspended';
      }
      
      public function description(): string {
          return 'Account is suspended and has no access to the team';
      }
      
      public function permissions(): array {
          return [];
      }
      
      public function allowedTransitions(): array {
          return [
              Guest::class, // Can be reinstated as Guest
              Member::class, // Can be reinstated as Member
              Admin::class, // Can be reinstated as Admin
          ];
      }
  }
  
  // Transition classes
  abstract class RoleTransition {
      protected $user;
      protected $team;
      protected $performedBy;
      
      public function __construct($user, $team, $performedBy) {
          $this->user = $user;
          $this->team = $team;
          $this->performedBy = $performedBy;
      }
      
      abstract public function handle(): void;
      
      // Check if the transition can be applied
      abstract public function canTransition(): bool;
      
      // Get the name of the transition
      abstract public function name(): string;
      
      // Check if the user performing the transition has permission
      protected function hasPermission(): bool {
          // In a real app, this would check if the user has permission to change roles
          return $this->performedBy->hasPermission('team:manage-roles');
      }
  }
  
  // Promote to Admin transition
  class PromoteToAdmin extends RoleTransition {
      public function handle(): void {
          if (!$this->canTransition()) {
              throw new Exception("Cannot promote user to Admin");
          }
          
          // In a real app, this would update the database
          $this->user->role = new Admin($this->user, $this->team);
          echo "User promoted to Admin successfully\n";
          
          // Log the change
          echo "Logging role change: {$this->user->name} promoted to Admin by {$this->performedBy->name}\n";
      }
      
      public function canTransition(): bool {
          return $this->user->role->canTransitionTo(Admin::class) && $this->hasPermission();
      }
      
      public function name(): string {
          return 'promote_to_admin';
      }
  }
  
  // Demote to Member transition
  class DemoteToMember extends RoleTransition {
      public function handle(): void {
          if (!$this->canTransition()) {
              throw new Exception("Cannot demote user to Member");
          }
          
          // In a real app, this would update the database
          $this->user->role = new Member($this->user, $this->team);
          echo "User demoted to Member successfully\n";
          
          // Log the change
          echo "Logging role change: {$this->user->name} demoted to Member by {$this->performedBy->name}\n";
      }
      
      public function canTransition(): bool {
          return $this->user->role->canTransitionTo(Member::class) && $this->hasPermission();
      }
      
      public function name(): string {
          return 'demote_to_member';
      }
  }
  
  // Suspend user transition
  class SuspendUser extends RoleTransition {
      private $reason;
      
      public function __construct($user, $team, $performedBy, string $reason = null) {
          parent::__construct($user, $team, $performedBy);
          $this->reason = $reason;
      }
      
      public function handle(): void {
          if (!$this->canTransition()) {
              throw new Exception("Cannot suspend user");
          }
          
          // In a real app, this would update the database
          $this->user->role = new Suspended($this->user, $this->team);
          echo "User suspended successfully\n";
          
          if ($this->reason) {
              echo "Suspension reason: {$this->reason}\n";
          }
          
          // Log the change
          echo "Logging role change: {$this->user->name} suspended by {$this->performedBy->name}\n";
      }
      
      public function canTransition(): bool {
          return $this->user->role->canTransitionTo(Suspended::class) && $this->hasPermission();
      }
      
      public function name(): string {
          return 'suspend';
      }
  }
  
  // User and Team classes for demonstration
  class User {
      public $id;
      public $name;
      public $role;
      private $permissions = [];
      
      public function __construct(int $id, string $name, RoleState $role = null) {
          $this->id = $id;
          $this->name = $name;
          $this->role = $role;
          
          // For the user performing actions, we need to set permissions
          if ($name === 'Admin User') {
              $this->permissions = [
                  'team:manage-roles',
                  'team:manage-members',
              ];
          }
      }
      
      public function hasPermission(string $permission): bool {
          return in_array($permission, $this->permissions) || 
                 ($this->role && in_array($permission, $this->role->permissions()));
      }
      
      public function can(string $permission): bool {
          return $this->hasPermission($permission);
      }
      
      public function applyTransition(RoleTransition $transition): void {
          $transition->handle();
      }
  }
  
  class Team {
      public $id;
      public $name;
      public $members = [];
      
      public function __construct(int $id, string $name) {
          $this->id = $id;
          $this->name = $name;
      }
      
      public function addMember(User $user, RoleState $role): void {
          $user->role = $role;
          $this->members[$user->id] = $user;
      }
  }
  
  // Example usage
  $team = new Team(1, 'Development Team');
  
  // Create users with different roles
  $owner = new User(1, 'Owner User', new Owner());
  $admin = new User(2, 'Admin User', new Admin());
  $member = new User(3, 'Member User', new Member());
  $guest = new User(4, 'Guest User', new Guest());
  
  // Add users to the team
  $team->addMember($owner, $owner->role);
  $team->addMember($admin, $admin->role);
  $team->addMember($member, $member->role);
  $team->addMember($guest, $guest->role);
  
  // Display initial roles and permissions
  echo "Initial team roles:\n";
  foreach ($team->members as $user) {
      echo "- {$user->name}: {$user->role->displayName()}\n";
      echo "  Permissions: " . implode(', ', $user->role->permissions()) . "\n";
  }
  
  // Promote a member to admin
  echo "\nPromoting Member User to Admin...\n";
  try {
      $member->applyTransition(new PromoteToAdmin($member, $team, $admin));
  } catch (Exception $e) {
      echo "Error: " . $e->getMessage() . "\n";
  }
  
  // Demote an admin to member
  echo "\nDemoting Admin User to Member...\n";
  try {
      $admin->applyTransition(new DemoteToMember($admin, $team, $owner));
  } catch (Exception $e) {
      echo "Error: " . $e->getMessage() . "\n";
  }
  
  // Suspend a guest
  echo "\nSuspending Guest User...\n";
  try {
      $guest->applyTransition(new SuspendUser($guest, $team, $owner, "Violation of team rules"));
  } catch (Exception $e) {
      echo "Error: " . $e->getMessage() . "\n";
  }
  
  // Try an invalid transition (owner to member)
  echo "\nTrying to demote Owner to Member...\n";
  try {
      $owner->applyTransition(new DemoteToMember($owner, $team, $admin));
  } catch (Exception $e) {
      echo "Error: " . $e->getMessage() . "\n";
  }
  
  // Display final roles and permissions
  echo "\nFinal team roles:\n";
  foreach ($team->members as $user) {
      echo "- {$user->name}: {$user->role->displayName()}\n";
      echo "  Permissions: " . implode(', ', $user->role->permissions()) . "\n";
  }
  
  // Check permissions
  echo "\nPermission checks:\n";
  echo "- Can Member User edit content? " . ($member->can('content:edit') ? 'Yes' : 'No') . "\n";
  echo "- Can Guest User create content? " . ($guest->can('content:create') ? 'Yes' : 'No') . "\n";
  echo "- Can Owner User delete the team? " . ($owner->can('team:delete') ? 'Yes' : 'No') . "\n";
explanation: |
  This example demonstrates a comprehensive permission role state machine:
  
  1. **Role States**: Each role is represented by a state class that defines:
     - The role name and display name
     - A description of the role's purpose
     - The permissions granted by the role
     - Allowed transitions to other roles
  
  2. **Role Transitions**: Transitions between roles are encapsulated in separate classes that:
     - Validate if the transition is allowed
     - Check if the user performing the transition has permission
     - Handle the actual role change
     - Log the change for audit purposes
  
  3. **Permission System**: The role states define what permissions each role has, and the User class provides methods to check permissions.
  
  4. **Team Membership**: Users are added to teams with specific roles, creating a complete role-based access control system.
  
  The example includes five roles with different permission levels:
  - **Owner**: Has full control over the team, including billing and deletion
  - **Admin**: Can manage team members and content, but cannot delete the team
  - **Member**: Can create and edit content, but cannot manage team settings
  - **Guest**: Can view content but cannot create or edit
  - **Suspended**: Has no access to the team
  
  And three transition types:
  - **PromoteToAdmin**: Promotes a user to the Admin role
  - **DemoteToMember**: Demotes a user to the Member role
  - **SuspendUser**: Suspends a user, removing all permissions
  
  In a real Laravel application:
  - Roles and permissions would be stored in the database
  - Transitions would be logged for audit purposes
  - The system would integrate with Laravel's authorization system
  - Role changes might trigger notifications or other side effects
challenges:
  - Add a new "Moderator" role between Admin and Member
  - Implement a "TransferOwnership" transition that changes the team owner
  - Create a system for temporary role assignments with expiration dates
  - Add support for custom permissions that can be assigned to roles
  - Implement a history of role changes with timestamps and reasons
:::
