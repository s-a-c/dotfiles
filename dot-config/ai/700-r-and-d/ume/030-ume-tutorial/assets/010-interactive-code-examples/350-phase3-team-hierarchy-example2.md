# Team Hierarchy Implementation

:::interactive-code
title: Implementing Team Hierarchies with Permission Inheritance
description: This example demonstrates how to implement a team hierarchy system with parent-child relationships and permission inheritance.
language: php
editable: true
code: |
  <?php
  
  namespace App\Models;
  
  use Exception;
  
  class Team {
      public $id;
      public $name;
      public $parent;
      public $children = [];
      public $members = [];
      public $permissions = [];
      
      public function __construct(int $id, string $name, ?Team $parent = null) {
          $this->id = $id;
          $this->name = $name;
          $this->parent = $parent;
          
          // If this team has a parent, add this team as a child of the parent
          if ($parent) {
              $parent->addChild($this);
          }
      }
      
      /**
       * Add a child team to this team.
       *
       * @param Team $team
       * @return self
       * @throws Exception If adding the team would create a circular reference
       */
      public function addChild(Team $team): self {
          // Check for circular references
          if ($this->isDescendantOf($team)) {
              throw new Exception("Cannot add team as child: would create circular reference");
          }
          
          $this->children[$team->id] = $team;
          $team->parent = $this;
          
          return $this;
      }
      
      /**
       * Remove a child team from this team.
       *
       * @param Team $team
       * @return self
       */
      public function removeChild(Team $team): self {
          if (isset($this->children[$team->id])) {
              unset($this->children[$team->id]);
              $team->parent = null;
          }
          
          return $this;
      }
      
      /**
       * Get all child teams (direct children only).
       *
       * @return array
       */
      public function getChildren(): array {
          return $this->children;
      }
      
      /**
       * Get all descendant teams (children, grandchildren, etc.).
       *
       * @return array
       */
      public function getDescendants(): array {
          $descendants = [];
          
          foreach ($this->children as $child) {
              $descendants[$child->id] = $child;
              $childDescendants = $child->getDescendants();
              foreach ($childDescendants as $descendant) {
                  $descendants[$descendant->id] = $descendant;
              }
          }
          
          return $descendants;
      }
      
      /**
       * Get the parent team.
       *
       * @return Team|null
       */
      public function getParent(): ?Team {
          return $this->parent;
      }
      
      /**
       * Get all ancestor teams (parent, grandparent, etc.).
       *
       * @return array
       */
      public function getAncestors(): array {
          $ancestors = [];
          $current = $this->parent;
          
          while ($current) {
              $ancestors[$current->id] = $current;
              $current = $current->parent;
          }
          
          return $ancestors;
      }
      
      /**
       * Check if this team is a descendant of the given team.
       *
       * @param Team $team
       * @return bool
       */
      public function isDescendantOf(Team $team): bool {
          $current = $this->parent;
          
          while ($current) {
              if ($current->id === $team->id) {
                  return true;
              }
              
              $current = $current->parent;
          }
          
          return false;
      }
      
      /**
       * Check if this team is an ancestor of the given team.
       *
       * @param Team $team
       * @return bool
       */
      public function isAncestorOf(Team $team): bool {
          return $team->isDescendantOf($this);
      }
      
      /**
       * Get the root team (top-most ancestor).
       *
       * @return Team
       */
      public function getRoot(): Team {
          $current = $this;
          
          while ($current->parent) {
              $current = $current->parent;
          }
          
          return $current;
      }
      
      /**
       * Get the team's depth in the hierarchy (0 for root).
       *
       * @return int
       */
      public function getDepth(): int {
          $depth = 0;
          $current = $this->parent;
          
          while ($current) {
              $depth++;
              $current = $current->parent;
          }
          
          return $depth;
      }
      
      /**
       * Add a member to the team.
       *
       * @param User $user
       * @param string $role
       * @return self
       */
      public function addMember(User $user, string $role): self {
          $this->members[$user->id] = [
              'user' => $user,
              'role' => $role,
          ];
          
          return $this;
      }
      
      /**
       * Remove a member from the team.
       *
       * @param User $user
       * @return self
       */
      public function removeMember(User $user): self {
          if (isset($this->members[$user->id])) {
              unset($this->members[$user->id]);
          }
          
          return $this;
      }
      
      /**
       * Check if a user is a member of this team.
       *
       * @param User $user
       * @return bool
       */
      public function hasMember(User $user): bool {
          return isset($this->members[$user->id]);
      }
      
      /**
       * Get a member's role in this team.
       *
       * @param User $user
       * @return string|null
       */
      public function getMemberRole(User $user): ?string {
          return $this->members[$user->id]['role'] ?? null;
      }
      
      /**
       * Add a permission to this team.
       *
       * @param string $permission
       * @param bool $value
       * @return self
       */
      public function addPermission(string $permission, bool $value = true): self {
          $this->permissions[$permission] = $value;
          return $this;
      }
      
      /**
       * Remove a permission from this team.
       *
       * @param string $permission
       * @return self
       */
      public function removePermission(string $permission): self {
          if (isset($this->permissions[$permission])) {
              unset($this->permissions[$permission]);
          }
          
          return $this;
      }
      
      /**
       * Check if this team has a specific permission.
       *
       * @param string $permission
       * @return bool
       */
      public function hasPermission(string $permission): bool {
          // Check if the permission is explicitly set on this team
          if (isset($this->permissions[$permission])) {
              return $this->permissions[$permission];
          }
          
          // If not, check parent teams (permission inheritance)
          if ($this->parent) {
              return $this->parent->hasPermission($permission);
          }
          
          return false;
      }
      
      /**
       * Check if a user has a specific permission in this team.
       *
       * @param User $user
       * @param string $permission
       * @return bool
       */
      public function userHasPermission(User $user, string $permission): bool {
          // Check if the user is a member of this team
          if (!$this->hasMember($user)) {
              return false;
          }
          
          $role = $this->getMemberRole($user);
          
          // Admins have all permissions
          if ($role === 'admin') {
              return true;
          }
          
          // Owners have all permissions
          if ($role === 'owner') {
              return true;
          }
          
          // For other roles, check the team's permissions
          return $this->hasPermission($permission);
      }
      
      /**
       * Get a hierarchical representation of the team and its descendants.
       *
       * @param int $indent
       * @return string
       */
      public function getHierarchyTree(int $indent = 0): string {
          $indentation = str_repeat('  ', $indent);
          $output = $indentation . "- {$this->name} (ID: {$this->id})\n";
          
          foreach ($this->children as $child) {
              $output .= $child->getHierarchyTree($indent + 1);
          }
          
          return $output;
      }
  }
  
  class User {
      public $id;
      public $name;
      public $email;
      
      public function __construct(int $id, string $name, string $email) {
          $this->id = $id;
          $this->name = $name;
          $this->email = $email;
      }
  }
  
  // Example usage
  
  // Create users
  $user1 = new User(1, 'John Doe', 'john@example.com');
  $user2 = new User(2, 'Jane Smith', 'jane@example.com');
  $user3 = new User(3, 'Bob Johnson', 'bob@example.com');
  
  // Create a team hierarchy
  $companyTeam = new Team(1, 'Acme Corporation');
  $engineeringTeam = new Team(2, 'Engineering', $companyTeam);
  $marketingTeam = new Team(3, 'Marketing', $companyTeam);
  $frontendTeam = new Team(4, 'Frontend', $engineeringTeam);
  $backendTeam = new Team(5, 'Backend', $engineeringTeam);
  $designTeam = new Team(6, 'Design', $marketingTeam);
  
  // Add members to teams
  $companyTeam->addMember($user1, 'owner');
  $engineeringTeam->addMember($user2, 'admin');
  $frontendTeam->addMember($user3, 'member');
  
  // Add permissions to teams
  $companyTeam->addPermission('company:manage');
  $engineeringTeam->addPermission('code:push');
  $frontendTeam->addPermission('ui:deploy');
  
  // Display the team hierarchy
  echo "Team Hierarchy:\n";
  echo $companyTeam->getHierarchyTree();
  
  // Test permission inheritance
  echo "\nPermission Tests:\n";
  
  // Direct permission
  echo "Does Frontend team have 'ui:deploy' permission? ";
  echo $frontendTeam->hasPermission('ui:deploy') ? "Yes\n" : "No\n";
  
  // Inherited permission
  echo "Does Frontend team have 'code:push' permission? ";
  echo $frontendTeam->hasPermission('code:push') ? "Yes\n" : "No\n";
  
  // Inherited permission (two levels)
  echo "Does Frontend team have 'company:manage' permission? ";
  echo $frontendTeam->hasPermission('company:manage') ? "Yes\n" : "No\n";
  
  // Permission that doesn't exist
  echo "Does Frontend team have 'billing:manage' permission? ";
  echo $frontendTeam->hasPermission('billing:manage') ? "Yes\n" : "No\n";
  
  // Test user permissions
  echo "\nUser Permission Tests:\n";
  
  // Owner has all permissions
  echo "Does John (owner) have 'company:manage' in Company team? ";
  echo $companyTeam->userHasPermission($user1, 'company:manage') ? "Yes\n" : "No\n";
  
  // Admin has all permissions
  echo "Does Jane (admin) have 'code:push' in Engineering team? ";
  echo $engineeringTeam->userHasPermission($user2, 'code:push') ? "Yes\n" : "No\n";
  
  // Member has team permissions
  echo "Does Bob (member) have 'ui:deploy' in Frontend team? ";
  echo $frontendTeam->userHasPermission($user3, 'ui:deploy') ? "Yes\n" : "No\n";
  
  // Member inherits permissions
  echo "Does Bob (member) have 'code:push' in Frontend team? ";
  echo $frontendTeam->userHasPermission($user3, 'code:push') ? "Yes\n" : "No\n";
  
  // User is not a member of this team
  echo "Does Bob have 'company:manage' in Company team? ";
  echo $companyTeam->userHasPermission($user3, 'company:manage') ? "Yes\n" : "No\n";
  
  // Test team relationships
  echo "\nTeam Relationship Tests:\n";
  
  echo "Is Frontend a descendant of Engineering? ";
  echo $frontendTeam->isDescendantOf($engineeringTeam) ? "Yes\n" : "No\n";
  
  echo "Is Company an ancestor of Frontend? ";
  echo $companyTeam->isAncestorOf($frontendTeam) ? "Yes\n" : "No\n";
  
  echo "Frontend team depth: " . $frontendTeam->getDepth() . "\n";
  
  echo "Root team of Frontend: " . $frontendTeam->getRoot()->name . "\n";
  
  // Try to create a circular reference
  echo "\nTrying to create a circular reference...\n";
  try {
      $companyTeam->addChild($frontendTeam);
  } catch (Exception $e) {
      echo "Error: " . $e->getMessage() . "\n";
  }
  
  // Get ancestors and descendants
  echo "\nFrontend team ancestors:\n";
  foreach ($frontendTeam->getAncestors() as $ancestor) {
      echo "- {$ancestor->name}\n";
  }
  
  echo "\nEngineering team descendants:\n";
  foreach ($engineeringTeam->getDescendants() as $descendant) {
      echo "- {$descendant->name}\n";
  }
explanation: |
  This example demonstrates a comprehensive team hierarchy system with permission inheritance:
  
  1. **Team Hierarchy**: Teams can have parent-child relationships, creating a tree structure:
     - Each team can have one parent and multiple children
     - Teams can be organized in a multi-level hierarchy
     - The system prevents circular references
  
  2. **Hierarchy Traversal**: The system provides methods to:
     - Get a team's parent and children
     - Get all ancestors (parent, grandparent, etc.)
     - Get all descendants (children, grandchildren, etc.)
     - Find the root team (top-most ancestor)
     - Determine a team's depth in the hierarchy
  
  3. **Team Membership**: Users can be members of teams with specific roles:
     - Users can be added to and removed from teams
     - Each user has a role in the team (owner, admin, member)
     - The system can check if a user is a member of a team
  
  4. **Permission System**: Teams have permissions that can be:
     - Explicitly granted to a team
     - Inherited from parent teams
     - Combined with user roles to determine access
  
  5. **Permission Inheritance**: Child teams inherit permissions from their parent teams:
     - If a permission is not explicitly set on a team, it checks its parent
     - This creates a cascading permission system
     - Permissions can be overridden at any level
  
  Key features of the implementation:
  
  - **Bidirectional Relationships**: When a parent-child relationship is established, both teams are updated
  - **Circular Reference Prevention**: The system checks for circular references when adding child teams
  - **Role-Based Permissions**: User permissions are determined by both their role and the team's permissions
  - **Hierarchy Visualization**: The system can generate a text representation of the team hierarchy
  
  In a real Laravel application:
  - Teams and their relationships would be stored in database tables
  - Eloquent relationships would handle the parent-child connections
  - The system would integrate with Laravel's authorization system
  - Caching would be used to optimize permission checks
challenges:
  - Add support for team-specific roles with custom permissions
  - Implement a method to move a team (and all its children) to a new parent
  - Create a system for team invitations with different roles
  - Add support for user groups that can be assigned to multiple teams
  - Implement a permission override system where child teams can explicitly deny permissions from parent teams
:::
