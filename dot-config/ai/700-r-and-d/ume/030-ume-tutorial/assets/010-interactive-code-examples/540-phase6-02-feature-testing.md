# Feature Testing

:::interactive-code
title: Feature Testing for User Model Enhancements
description: This example demonstrates how to write effective feature tests for user model enhancements, focusing on testing complete features and user interactions.
language: php
editable: true
code: |
  <?php
  
  namespace Tests\Feature;
  
  use App\Models\Permission;
  use App\Models\Role;
  use App\Models\User;
  use App\Models\UserType;
  use Illuminate\Foundation\Testing\RefreshDatabase;
  use Tests\TestCase;
  
  class UserTypeManagementTest extends TestCase
  {
      use RefreshDatabase;
      
      /**
       * Test that an admin can view the user type management page.
       *
       * @return void
       */
      public function test_admin_can_view_user_type_management_page()
      {
          // Arrange
          $admin = User::factory()->create();
          $adminRole = Role::factory()->create(['name' => 'admin']);
          $permission = Permission::factory()->create(['name' => 'manage-user-types']);
          
          $adminRole->givePermissionTo($permission);
          $admin->assignRole($adminRole);
          
          // Act
          $response = $this->actingAs($admin)->get('/admin/user-types');
          
          // Assert
          $response->assertStatus(200);
          $response->assertViewIs('admin.user-types.index');
      }
      
      /**
       * Test that a non-admin cannot view the user type management page.
       *
       * @return void
       */
      public function test_non_admin_cannot_view_user_type_management_page()
      {
          // Arrange
          $user = User::factory()->create();
          
          // Act
          $response = $this->actingAs($user)->get('/admin/user-types');
          
          // Assert
          $response->assertStatus(403);
      }
      
      /**
       * Test that an admin can create a new user type.
       *
       * @return void
       */
      public function test_admin_can_create_user_type()
      {
          // Arrange
          $admin = User::factory()->create();
          $adminRole = Role::factory()->create(['name' => 'admin']);
          $permission = Permission::factory()->create(['name' => 'manage-user-types']);
          
          $adminRole->givePermissionTo($permission);
          $admin->assignRole($adminRole);
          
          // Act
          $response = $this->actingAs($admin)->post('/admin/user-types', [
              'name' => 'premium',
              'display_name' => 'Premium User',
              'description' => 'A premium user with additional features',
          ]);
          
          // Assert
          $response->assertRedirect('/admin/user-types');
          $this->assertDatabaseHas('user_types', [
              'name' => 'premium',
              'display_name' => 'Premium User',
              'description' => 'A premium user with additional features',
          ]);
      }
      
      /**
       * Test that an admin can update an existing user type.
       *
       * @return void
       */
      public function test_admin_can_update_user_type()
      {
          // Arrange
          $admin = User::factory()->create();
          $adminRole = Role::factory()->create(['name' => 'admin']);
          $permission = Permission::factory()->create(['name' => 'manage-user-types']);
          
          $adminRole->givePermissionTo($permission);
          $admin->assignRole($adminRole);
          
          $userType = UserType::factory()->create([
              'name' => 'premium',
              'display_name' => 'Premium User',
              'description' => 'A premium user',
          ]);
          
          // Act
          $response = $this->actingAs($admin)->put("/admin/user-types/{$userType->id}", [
              'name' => 'premium',
              'display_name' => 'Premium Plus User',
              'description' => 'A premium user with additional features',
          ]);
          
          // Assert
          $response->assertRedirect('/admin/user-types');
          $this->assertDatabaseHas('user_types', [
              'id' => $userType->id,
              'name' => 'premium',
              'display_name' => 'Premium Plus User',
              'description' => 'A premium user with additional features',
          ]);
      }
      
      /**
       * Test that an admin can delete a user type.
       *
       * @return void
       */
      public function test_admin_can_delete_user_type()
      {
          // Arrange
          $admin = User::factory()->create();
          $adminRole = Role::factory()->create(['name' => 'admin']);
          $permission = Permission::factory()->create(['name' => 'manage-user-types']);
          
          $adminRole->givePermissionTo($permission);
          $admin->assignRole($adminRole);
          
          $userType = UserType::factory()->create(['name' => 'premium']);
          
          // Act
          $response = $this->actingAs($admin)->delete("/admin/user-types/{$userType->id}");
          
          // Assert
          $response->assertRedirect('/admin/user-types');
          $this->assertDatabaseMissing('user_types', ['id' => $userType->id]);
      }
  }
  
  namespace Tests\Feature;
  
  use App\Models\User;
  use App\Models\UserType;
  use Illuminate\Foundation\Testing\RefreshDatabase;
  use Tests\TestCase;
  
  class UserProfileTest extends TestCase
  {
      use RefreshDatabase;
      
      /**
       * Test that a user can view their own profile.
       *
       * @return void
       */
      public function test_user_can_view_own_profile()
      {
          // Arrange
          $user = User::factory()->create();
          
          // Act
          $response = $this->actingAs($user)->get('/profile');
          
          // Assert
          $response->assertStatus(200);
          $response->assertViewIs('profile.show');
          $response->assertViewHas('user', $user);
      }
      
      /**
       * Test that a user can update their profile information.
       *
       * @return void
       */
      public function test_user_can_update_profile()
      {
          // Arrange
          $user = User::factory()->create([
              'name' => 'John Doe',
              'email' => 'john@example.com',
          ]);
          
          // Act
          $response = $this->actingAs($user)->put('/profile', [
              'name' => 'Jane Doe',
              'email' => 'jane@example.com',
          ]);
          
          // Assert
          $response->assertRedirect('/profile');
          $this->assertDatabaseHas('users', [
              'id' => $user->id,
              'name' => 'Jane Doe',
              'email' => 'jane@example.com',
          ]);
      }
      
      /**
       * Test that a user can see their current type on their profile.
       *
       * @return void
       */
      public function test_user_can_see_type_on_profile()
      {
          // Arrange
          $userType = UserType::factory()->create([
              'name' => 'premium',
              'display_name' => 'Premium User',
          ]);
          
          $user = User::factory()->create();
          $user->assignType($userType);
          
          // Act
          $response = $this->actingAs($user)->get('/profile');
          
          // Assert
          $response->assertStatus(200);
          $response->assertSee('Premium User');
      }
      
      /**
       * Test that a user can see their type history on their profile.
       *
       * @return void
       */
      public function test_user_can_see_type_history_on_profile()
      {
          // Arrange
          $regularType = UserType::factory()->create([
              'name' => 'regular',
              'display_name' => 'Regular User',
          ]);
          
          $premiumType = UserType::factory()->create([
              'name' => 'premium',
              'display_name' => 'Premium User',
          ]);
          
          $user = User::factory()->create();
          $user->assignType($regularType);
          $user->assignType($premiumType);
          
          // Act
          $response = $this->actingAs($user)->get('/profile/type-history');
          
          // Assert
          $response->assertStatus(200);
          $response->assertViewIs('profile.type-history');
          $response->assertSee('Regular User');
          $response->assertSee('Premium User');
      }
  }
  
  namespace Tests\Feature;
  
  use App\Models\Permission;
  use App\Models\Role;
  use App\Models\User;
  use Illuminate\Foundation\Testing\RefreshDatabase;
  use Tests\TestCase;
  
  class UserRoleManagementTest extends TestCase
  {
      use RefreshDatabase;
      
      /**
       * Test that an admin can view the user role management page.
       *
       * @return void
       */
      public function test_admin_can_view_user_role_management_page()
      {
          // Arrange
          $admin = User::factory()->create();
          $adminRole = Role::factory()->create(['name' => 'admin']);
          $permission = Permission::factory()->create(['name' => 'manage-roles']);
          
          $adminRole->givePermissionTo($permission);
          $admin->assignRole($adminRole);
          
          // Act
          $response = $this->actingAs($admin)->get('/admin/roles');
          
          // Assert
          $response->assertStatus(200);
          $response->assertViewIs('admin.roles.index');
      }
      
      /**
       * Test that an admin can assign a role to a user.
       *
       * @return void
       */
      public function test_admin_can_assign_role_to_user()
      {
          // Arrange
          $admin = User::factory()->create();
          $adminRole = Role::factory()->create(['name' => 'admin']);
          $permission = Permission::factory()->create(['name' => 'manage-roles']);
          
          $adminRole->givePermissionTo($permission);
          $admin->assignRole($adminRole);
          
          $user = User::factory()->create();
          $editorRole = Role::factory()->create(['name' => 'editor']);
          
          // Act
          $response = $this->actingAs($admin)->post("/admin/users/{$user->id}/roles", [
              'role_id' => $editorRole->id,
          ]);
          
          // Assert
          $response->assertRedirect("/admin/users/{$user->id}");
          $this->assertTrue($user->fresh()->hasRole('editor'));
      }
      
      /**
       * Test that an admin can remove a role from a user.
       *
       * @return void
       */
      public function test_admin_can_remove_role_from_user()
      {
          // Arrange
          $admin = User::factory()->create();
          $adminRole = Role::factory()->create(['name' => 'admin']);
          $permission = Permission::factory()->create(['name' => 'manage-roles']);
          
          $adminRole->givePermissionTo($permission);
          $admin->assignRole($adminRole);
          
          $user = User::factory()->create();
          $editorRole = Role::factory()->create(['name' => 'editor']);
          
          $user->assignRole($editorRole);
          $this->assertTrue($user->hasRole('editor'));
          
          // Act
          $response = $this->actingAs($admin)->delete("/admin/users/{$user->id}/roles/{$editorRole->id}");
          
          // Assert
          $response->assertRedirect("/admin/users/{$user->id}");
          $this->assertFalse($user->fresh()->hasRole('editor'));
      }
      
      /**
       * Test that a non-admin cannot assign roles.
       *
       * @return void
       */
      public function test_non_admin_cannot_assign_roles()
      {
          // Arrange
          $user = User::factory()->create();
          $anotherUser = User::factory()->create();
          $editorRole = Role::factory()->create(['name' => 'editor']);
          
          // Act
          $response = $this->actingAs($user)->post("/admin/users/{$anotherUser->id}/roles", [
              'role_id' => $editorRole->id,
          ]);
          
          // Assert
          $response->assertStatus(403);
          $this->assertFalse($anotherUser->fresh()->hasRole('editor'));
      }
  }
  
  namespace Tests\Feature;
  
  use App\Models\User;
  use App\Services\UserStatusService;
  use Illuminate\Foundation\Testing\RefreshDatabase;
  use Tests\TestCase;
  
  class UserStatusManagementTest extends TestCase
  {
      use RefreshDatabase;
      
      /**
       * Test that an admin can suspend a user.
       *
       * @return void
       */
      public function test_admin_can_suspend_user()
      {
          // Arrange
          $admin = User::factory()->create();
          $adminRole = \App\Models\Role::factory()->create(['name' => 'admin']);
          $permission = \App\Models\Permission::factory()->create(['name' => 'manage-users']);
          
          $adminRole->givePermissionTo($permission);
          $admin->assignRole($adminRole);
          
          $user = User::factory()->create(['status' => 'active']);
          
          // Act
          $response = $this->actingAs($admin)->post("/admin/users/{$user->id}/suspend", [
              'reason' => 'Violation of terms',
          ]);
          
          // Assert
          $response->assertRedirect("/admin/users/{$user->id}");
          $this->assertEquals('suspended', $user->fresh()->status);
          $this->assertDatabaseHas('user_status_history', [
              'user_id' => $user->id,
              'status' => 'suspended',
              'reason' => 'Violation of terms',
          ]);
      }
      
      /**
       * Test that an admin can reactivate a suspended user.
       *
       * @return void
       */
      public function test_admin_can_reactivate_suspended_user()
      {
          // Arrange
          $admin = User::factory()->create();
          $adminRole = \App\Models\Role::factory()->create(['name' => 'admin']);
          $permission = \App\Models\Permission::factory()->create(['name' => 'manage-users']);
          
          $adminRole->givePermissionTo($permission);
          $admin->assignRole($adminRole);
          
          $user = User::factory()->create(['status' => 'suspended']);
          
          // Act
          $response = $this->actingAs($admin)->post("/admin/users/{$user->id}/activate");
          
          // Assert
          $response->assertRedirect("/admin/users/{$user->id}");
          $this->assertEquals('active', $user->fresh()->status);
          $this->assertDatabaseHas('user_status_history', [
              'user_id' => $user->id,
              'status' => 'active',
          ]);
      }
      
      /**
       * Test that a suspended user cannot log in.
       *
       * @return void
       */
      public function test_suspended_user_cannot_login()
      {
          // Arrange
          $user = User::factory()->create([
              'email' => 'suspended@example.com',
              'password' => bcrypt('password'),
              'status' => 'suspended',
          ]);
          
          // Act
          $response = $this->post('/login', [
              'email' => 'suspended@example.com',
              'password' => 'password',
          ]);
          
          // Assert
          $response->assertRedirect('/');
          $this->assertGuest();
          $response->assertSessionHas('error', 'Your account has been suspended.');
      }
      
      /**
       * Test that a user can view their status history.
       *
       * @return void
       */
      public function test_user_can_view_status_history()
      {
          // Arrange
          $user = User::factory()->create(['status' => 'active']);
          $statusService = new UserStatusService();
          
          $statusService->setStatus($user, 'inactive');
          $statusService->setStatus($user, 'active');
          
          // Act
          $response = $this->actingAs($user)->get('/profile/status-history');
          
          // Assert
          $response->assertStatus(200);
          $response->assertViewIs('profile.status-history');
          $response->assertSee('inactive');
          $response->assertSee('active');
      }
  }
explanation: |
  This example demonstrates feature testing for user model enhancements:
  
  1. **User Type Management Tests**: Testing the administrative interface for managing user types:
     - Viewing the user type management page
     - Creating new user types
     - Updating existing user types
     - Deleting user types
     - Access control for non-admin users
  
  2. **User Profile Tests**: Testing user profile functionality:
     - Viewing the user's own profile
     - Updating profile information
     - Displaying the user's current type
     - Viewing type history
  
  3. **User Role Management Tests**: Testing role assignment and management:
     - Viewing the role management page
     - Assigning roles to users
     - Removing roles from users
     - Access control for non-admin users
  
  4. **User Status Management Tests**: Testing user status functionality:
     - Suspending users
     - Reactivating suspended users
     - Preventing suspended users from logging in
     - Viewing status history
  
  Key feature testing principles demonstrated:
  
  - **HTTP Testing**: Testing through HTTP requests rather than direct method calls
  - **Authentication**: Using actingAs() to simulate authenticated users
  - **Form Submission**: Testing form submissions with POST, PUT, and DELETE requests
  - **Response Assertions**: Checking response status, redirects, and view data
  - **Database Assertions**: Verifying that database changes occurred correctly
  - **Access Control**: Testing that unauthorized users cannot access protected features
  
  In a real Laravel application:
  - You would have more comprehensive test coverage
  - You would test validation errors and edge cases
  - You would test more complex user interactions
  - You would use more sophisticated factories and seeders
  - You would organize tests into more specific test classes
challenges:
  - Add tests for validation errors when creating or updating user types
  - Implement tests for user type transition workflows
  - Add tests for role permission management
  - Create tests for user search and filtering
  - Implement tests for user export and import functionality
:::
