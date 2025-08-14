# Unit Testing Basics

:::interactive-code
title: Unit Testing Basics for User Model Enhancements
description: This example demonstrates how to write effective unit tests for user model enhancements, focusing on testing individual components in isolation.
language: php
editable: true
code: |
  <?php
  
  namespace Tests\Unit;
  
  use App\Models\User;
  use App\Models\UserType;
  use App\Services\UserTypeService;
  use Illuminate\Foundation\Testing\RefreshDatabase;
  use Tests\TestCase;
  
  class UserTypeTest extends TestCase
  {
      use RefreshDatabase;
      
      /**
       * Test that a user can be assigned a type.
       *
       * @return void
       */
      public function test_user_can_be_assigned_a_type()
      {
          // Arrange
          $user = User::factory()->create();
          $type = UserType::factory()->create(['name' => 'premium']);
          
          // Act
          $user->assignType($type);
          
          // Assert
          $this->assertEquals($type->id, $user->userType->id);
          $this->assertEquals('premium', $user->userType->name);
      }
      
      /**
       * Test that a user can have their type changed.
       *
       * @return void
       */
      public function test_user_can_change_type()
      {
          // Arrange
          $user = User::factory()->create();
          $initialType = UserType::factory()->create(['name' => 'regular']);
          $newType = UserType::factory()->create(['name' => 'premium']);
          
          $user->assignType($initialType);
          $this->assertEquals('regular', $user->userType->name);
          
          // Act
          $user->assignType($newType);
          
          // Assert
          $this->assertEquals($newType->id, $user->userType->id);
          $this->assertEquals('premium', $user->userType->name);
      }
      
      /**
       * Test that user type history is recorded.
       *
       * @return void
       */
      public function test_user_type_history_is_recorded()
      {
          // Arrange
          $user = User::factory()->create();
          $type1 = UserType::factory()->create(['name' => 'regular']);
          $type2 = UserType::factory()->create(['name' => 'premium']);
          
          // Act
          $user->assignType($type1);
          $user->assignType($type2);
          
          // Assert
          $this->assertCount(2, $user->userTypeHistory);
          $this->assertEquals($type1->id, $user->userTypeHistory->first()->user_type_id);
          $this->assertEquals($type2->id, $user->userTypeHistory->last()->user_type_id);
      }
      
      /**
       * Test that a user can check if they have a specific type.
       *
       * @return void
       */
      public function test_user_can_check_if_has_type()
      {
          // Arrange
          $user = User::factory()->create();
          $premiumType = UserType::factory()->create(['name' => 'premium']);
          $businessType = UserType::factory()->create(['name' => 'business']);
          
          $user->assignType($premiumType);
          
          // Act & Assert
          $this->assertTrue($user->hasType('premium'));
          $this->assertFalse($user->hasType('business'));
      }
      
      /**
       * Test that a user can check if they have one of multiple types.
       *
       * @return void
       */
      public function test_user_can_check_if_has_any_type()
      {
          // Arrange
          $user = User::factory()->create();
          $premiumType = UserType::factory()->create(['name' => 'premium']);
          
          $user->assignType($premiumType);
          
          // Act & Assert
          $this->assertTrue($user->hasAnyType(['regular', 'premium']));
          $this->assertFalse($user->hasAnyType(['regular', 'business']));
      }
  }
  
  namespace Tests\Unit;
  
  use App\Models\Permission;
  use App\Models\Role;
  use App\Models\User;
  use Illuminate\Foundation\Testing\RefreshDatabase;
  use Tests\TestCase;
  
  class UserPermissionTest extends TestCase
  {
      use RefreshDatabase;
      
      /**
       * Test that a user can be assigned a role.
       *
       * @return void
       */
      public function test_user_can_be_assigned_a_role()
      {
          // Arrange
          $user = User::factory()->create();
          $role = Role::factory()->create(['name' => 'editor']);
          
          // Act
          $user->assignRole($role);
          
          // Assert
          $this->assertTrue($user->hasRole('editor'));
      }
      
      /**
       * Test that a user can be assigned multiple roles.
       *
       * @return void
       */
      public function test_user_can_be_assigned_multiple_roles()
      {
          // Arrange
          $user = User::factory()->create();
          $editorRole = Role::factory()->create(['name' => 'editor']);
          $moderatorRole = Role::factory()->create(['name' => 'moderator']);
          
          // Act
          $user->assignRole($editorRole);
          $user->assignRole($moderatorRole);
          
          // Assert
          $this->assertTrue($user->hasRole('editor'));
          $this->assertTrue($user->hasRole('moderator'));
          $this->assertCount(2, $user->roles);
      }
      
      /**
       * Test that a user can have a role removed.
       *
       * @return void
       */
      public function test_user_can_have_role_removed()
      {
          // Arrange
          $user = User::factory()->create();
          $role = Role::factory()->create(['name' => 'editor']);
          
          $user->assignRole($role);
          $this->assertTrue($user->hasRole('editor'));
          
          // Act
          $user->removeRole($role);
          
          // Assert
          $this->assertFalse($user->hasRole('editor'));
      }
      
      /**
       * Test that a user can check if they have a permission directly.
       *
       * @return void
       */
      public function test_user_can_check_direct_permission()
      {
          // Arrange
          $user = User::factory()->create();
          $permission = Permission::factory()->create(['name' => 'edit-posts']);
          
          // Act
          $user->givePermissionTo($permission);
          
          // Assert
          $this->assertTrue($user->hasPermissionTo('edit-posts'));
      }
      
      /**
       * Test that a user can check if they have a permission via a role.
       *
       * @return void
       */
      public function test_user_can_check_permission_via_role()
      {
          // Arrange
          $user = User::factory()->create();
          $role = Role::factory()->create(['name' => 'editor']);
          $permission = Permission::factory()->create(['name' => 'edit-posts']);
          
          $role->givePermissionTo($permission);
          
          // Act
          $user->assignRole($role);
          
          // Assert
          $this->assertTrue($user->hasPermissionTo('edit-posts'));
      }
      
      /**
       * Test that a user can check if they have any of multiple permissions.
       *
       * @return void
       */
      public function test_user_can_check_any_permission()
      {
          // Arrange
          $user = User::factory()->create();
          $permission1 = Permission::factory()->create(['name' => 'edit-posts']);
          $permission2 = Permission::factory()->create(['name' => 'delete-posts']);
          
          $user->givePermissionTo($permission1);
          
          // Act & Assert
          $this->assertTrue($user->hasAnyPermission(['edit-posts', 'publish-posts']));
          $this->assertFalse($user->hasAnyPermission(['delete-posts', 'publish-posts']));
      }
      
      /**
       * Test that a user can check if they have all of multiple permissions.
       *
       * @return void
       */
      public function test_user_can_check_all_permissions()
      {
          // Arrange
          $user = User::factory()->create();
          $permission1 = Permission::factory()->create(['name' => 'edit-posts']);
          $permission2 = Permission::factory()->create(['name' => 'delete-posts']);
          
          $user->givePermissionTo($permission1);
          $user->givePermissionTo($permission2);
          
          // Act & Assert
          $this->assertTrue($user->hasAllPermissions(['edit-posts', 'delete-posts']));
          $this->assertFalse($user->hasAllPermissions(['edit-posts', 'publish-posts']));
      }
  }
  
  namespace Tests\Unit;
  
  use App\Models\User;
  use App\Services\UserStatusService;
  use Illuminate\Foundation\Testing\RefreshDatabase;
  use Tests\TestCase;
  
  class UserStatusTest extends TestCase
  {
      use RefreshDatabase;
      
      /**
       * Test that a user can have their status set.
       *
       * @return void
       */
      public function test_user_can_set_status()
      {
          // Arrange
          $user = User::factory()->create();
          $statusService = new UserStatusService();
          
          // Act
          $statusService->setStatus($user, 'active');
          
          // Assert
          $this->assertEquals('active', $user->status);
      }
      
      /**
       * Test that a user can check if they have a specific status.
       *
       * @return void
       */
      public function test_user_can_check_status()
      {
          // Arrange
          $user = User::factory()->create(['status' => 'active']);
          
          // Act & Assert
          $this->assertTrue($user->hasStatus('active'));
          $this->assertFalse($user->hasStatus('inactive'));
      }
      
      /**
       * Test that a user's status history is recorded.
       *
       * @return void
       */
      public function test_user_status_history_is_recorded()
      {
          // Arrange
          $user = User::factory()->create();
          $statusService = new UserStatusService();
          
          // Act
          $statusService->setStatus($user, 'active');
          $statusService->setStatus($user, 'suspended');
          
          // Assert
          $this->assertCount(2, $user->statusHistory);
          $this->assertEquals('active', $user->statusHistory->first()->status);
          $this->assertEquals('suspended', $user->statusHistory->last()->status);
      }
      
      /**
       * Test that a user can be activated.
       *
       * @return void
       */
      public function test_user_can_be_activated()
      {
          // Arrange
          $user = User::factory()->create(['status' => 'inactive']);
          $statusService = new UserStatusService();
          
          // Act
          $statusService->activate($user);
          
          // Assert
          $this->assertEquals('active', $user->status);
      }
      
      /**
       * Test that a user can be deactivated.
       *
       * @return void
       */
      public function test_user_can_be_deactivated()
      {
          // Arrange
          $user = User::factory()->create(['status' => 'active']);
          $statusService = new UserStatusService();
          
          // Act
          $statusService->deactivate($user);
          
          // Assert
          $this->assertEquals('inactive', $user->status);
      }
      
      /**
       * Test that a user can be suspended.
       *
       * @return void
       */
      public function test_user_can_be_suspended()
      {
          // Arrange
          $user = User::factory()->create(['status' => 'active']);
          $statusService = new UserStatusService();
          
          // Act
          $statusService->suspend($user, 'violation of terms');
          
          // Assert
          $this->assertEquals('suspended', $user->status);
          $this->assertEquals('violation of terms', $user->statusHistory->last()->reason);
      }
  }
explanation: |
  This example demonstrates the basics of unit testing for user model enhancements:
  
  1. **Test Structure**: Each test follows the Arrange-Act-Assert pattern:
     - **Arrange**: Set up the test environment and prerequisites
     - **Act**: Perform the action being tested
     - **Assert**: Verify the expected outcome
  
  2. **User Type Testing**: Tests for the user type functionality:
     - Assigning a type to a user
     - Changing a user's type
     - Recording type history
     - Checking if a user has a specific type
     - Checking if a user has any of multiple types
  
  3. **User Permission Testing**: Tests for the permission system:
     - Assigning roles to users
     - Assigning multiple roles
     - Removing roles
     - Checking direct permissions
     - Checking permissions via roles
     - Checking for any of multiple permissions
     - Checking for all of multiple permissions
  
  4. **User Status Testing**: Tests for the user status functionality:
     - Setting a user's status
     - Checking a user's status
     - Recording status history
     - Activating a user
     - Deactivating a user
     - Suspending a user with a reason
  
  Key testing principles demonstrated:
  
  - **Isolation**: Each test focuses on testing a single piece of functionality
  - **Independence**: Tests don't depend on each other's state
  - **Readability**: Tests are clearly named and structured
  - **Completeness**: Testing both positive and negative cases
  - **Database Reset**: Using RefreshDatabase to ensure a clean state for each test
  
  In a real Laravel application:
  - You would have more comprehensive test coverage
  - You would use factories more extensively for test data
  - You would test edge cases and error conditions
  - You would use mocks and stubs for external dependencies
  - You would organize tests into more specific test classes
challenges:
  - Add tests for edge cases like assigning an invalid type
  - Implement tests for user type transition validation
  - Add tests for permission caching
  - Create tests for role hierarchy
  - Implement tests for status transitions with validation
:::
