# API Testing

:::interactive-code
title: API Testing for User Model Enhancements
description: This example demonstrates how to write effective API tests for user model enhancements, focusing on testing RESTful API endpoints and JSON responses.
language: php
editable: true
code: |
  <?php
  
  namespace Tests\Feature\Api;
  
  use App\Models\User;
  use App\Models\UserType;
  use Illuminate\Foundation\Testing\RefreshDatabase;
  use Laravel\Sanctum\Sanctum;
  use Tests\TestCase;
  
  class UserApiTest extends TestCase
  {
      use RefreshDatabase;
      
      /**
       * Test that an authenticated user can retrieve their own profile.
       *
       * @return void
       */
      public function test_user_can_retrieve_own_profile()
      {
          // Arrange
          $user = User::factory()->create();
          Sanctum::actingAs($user, ['*']);
          
          // Act
          $response = $this->getJson('/api/user');
          
          // Assert
          $response->assertStatus(200);
          $response->assertJson([
              'id' => $user->id,
              'name' => $user->name,
              'email' => $user->email,
          ]);
      }
      
      /**
       * Test that an authenticated user can update their profile.
       *
       * @return void
       */
      public function test_user_can_update_profile()
      {
          // Arrange
          $user = User::factory()->create();
          Sanctum::actingAs($user, ['*']);
          
          // Act
          $response = $this->putJson('/api/user', [
              'name' => 'Updated Name',
              'email' => 'updated@example.com',
          ]);
          
          // Assert
          $response->assertStatus(200);
          $response->assertJson([
              'id' => $user->id,
              'name' => 'Updated Name',
              'email' => 'updated@example.com',
          ]);
          
          $this->assertDatabaseHas('users', [
              'id' => $user->id,
              'name' => 'Updated Name',
              'email' => 'updated@example.com',
          ]);
      }
      
      /**
       * Test that an unauthenticated user cannot access protected endpoints.
       *
       * @return void
       */
      public function test_unauthenticated_user_cannot_access_protected_endpoints()
      {
          // Act & Assert
          $this->getJson('/api/user')->assertStatus(401);
          $this->putJson('/api/user', ['name' => 'Test'])->assertStatus(401);
      }
      
      /**
       * Test that a user can retrieve their user type.
       *
       * @return void
       */
      public function test_user_can_retrieve_user_type()
      {
          // Arrange
          $userType = UserType::factory()->create(['name' => 'premium']);
          $user = User::factory()->create();
          $user->assignType($userType);
          
          Sanctum::actingAs($user, ['*']);
          
          // Act
          $response = $this->getJson('/api/user/type');
          
          // Assert
          $response->assertStatus(200);
          $response->assertJson([
              'id' => $userType->id,
              'name' => 'premium',
          ]);
      }
      
      /**
       * Test that a user can retrieve their type history.
       *
       * @return void
       */
      public function test_user_can_retrieve_type_history()
      {
          // Arrange
          $regularType = UserType::factory()->create(['name' => 'regular']);
          $premiumType = UserType::factory()->create(['name' => 'premium']);
          
          $user = User::factory()->create();
          $user->assignType($regularType);
          $user->assignType($premiumType);
          
          Sanctum::actingAs($user, ['*']);
          
          // Act
          $response = $this->getJson('/api/user/type/history');
          
          // Assert
          $response->assertStatus(200);
          $response->assertJsonCount(2);
          $response->assertJsonStructure([
              '*' => [
                  'id',
                  'user_id',
                  'user_type_id',
                  'created_at',
                  'updated_at',
                  'user_type' => [
                      'id',
                      'name',
                  ],
              ],
          ]);
      }
  }
  
  namespace Tests\Feature\Api;
  
  use App\Models\Permission;
  use App\Models\Role;
  use App\Models\User;
  use Illuminate\Foundation\Testing\RefreshDatabase;
  use Laravel\Sanctum\Sanctum;
  use Tests\TestCase;
  
  class UserRoleApiTest extends TestCase
  {
      use RefreshDatabase;
      
      /**
       * Test that a user can retrieve their roles.
       *
       * @return void
       */
      public function test_user_can_retrieve_roles()
      {
          // Arrange
          $user = User::factory()->create();
          $editorRole = Role::factory()->create(['name' => 'editor']);
          $moderatorRole = Role::factory()->create(['name' => 'moderator']);
          
          $user->assignRole($editorRole);
          $user->assignRole($moderatorRole);
          
          Sanctum::actingAs($user, ['*']);
          
          // Act
          $response = $this->getJson('/api/user/roles');
          
          // Assert
          $response->assertStatus(200);
          $response->assertJsonCount(2);
          $response->assertJsonStructure([
              '*' => [
                  'id',
                  'name',
                  'display_name',
                  'description',
              ],
          ]);
      }
      
      /**
       * Test that a user can retrieve their permissions.
       *
       * @return void
       */
      public function test_user_can_retrieve_permissions()
      {
          // Arrange
          $user = User::factory()->create();
          $role = Role::factory()->create(['name' => 'editor']);
          $permission1 = Permission::factory()->create(['name' => 'edit-posts']);
          $permission2 = Permission::factory()->create(['name' => 'publish-posts']);
          
          $role->givePermissionTo($permission1);
          $role->givePermissionTo($permission2);
          $user->assignRole($role);
          
          Sanctum::actingAs($user, ['*']);
          
          // Act
          $response = $this->getJson('/api/user/permissions');
          
          // Assert
          $response->assertStatus(200);
          $response->assertJsonCount(2);
          $response->assertJsonStructure([
              '*' => [
                  'id',
                  'name',
                  'display_name',
                  'description',
              ],
          ]);
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
          
          Sanctum::actingAs($admin, ['*']);
          
          // Act
          $response = $this->postJson("/api/users/{$user->id}/roles", [
              'role_id' => $editorRole->id,
          ]);
          
          // Assert
          $response->assertStatus(200);
          $response->assertJson([
              'message' => 'Role assigned successfully',
          ]);
          
          $this->assertTrue($user->fresh()->hasRole('editor'));
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
          
          Sanctum::actingAs($user, ['*']);
          
          // Act
          $response = $this->postJson("/api/users/{$anotherUser->id}/roles", [
              'role_id' => $editorRole->id,
          ]);
          
          // Assert
          $response->assertStatus(403);
          $this->assertFalse($anotherUser->fresh()->hasRole('editor'));
      }
  }
  
  namespace Tests\Feature\Api;
  
  use App\Models\User;
  use App\Models\UserType;
  use Illuminate\Foundation\Testing\RefreshDatabase;
  use Laravel\Sanctum\Sanctum;
  use Tests\TestCase;
  
  class UserTypeApiTest extends TestCase
  {
      use RefreshDatabase;
      
      /**
       * Test that an admin can retrieve all user types.
       *
       * @return void
       */
      public function test_admin_can_retrieve_all_user_types()
      {
          // Arrange
          $admin = User::factory()->create();
          $adminRole = \App\Models\Role::factory()->create(['name' => 'admin']);
          $permission = \App\Models\Permission::factory()->create(['name' => 'manage-user-types']);
          
          $adminRole->givePermissionTo($permission);
          $admin->assignRole($adminRole);
          
          UserType::factory()->create(['name' => 'regular']);
          UserType::factory()->create(['name' => 'premium']);
          
          Sanctum::actingAs($admin, ['*']);
          
          // Act
          $response = $this->getJson('/api/user-types');
          
          // Assert
          $response->assertStatus(200);
          $response->assertJsonCount(2);
          $response->assertJsonStructure([
              '*' => [
                  'id',
                  'name',
                  'display_name',
                  'description',
              ],
          ]);
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
          $adminRole = \App\Models\Role::factory()->create(['name' => 'admin']);
          $permission = \App\Models\Permission::factory()->create(['name' => 'manage-user-types']);
          
          $adminRole->givePermissionTo($permission);
          $admin->assignRole($adminRole);
          
          Sanctum::actingAs($admin, ['*']);
          
          // Act
          $response = $this->postJson('/api/user-types', [
              'name' => 'business',
              'display_name' => 'Business User',
              'description' => 'A business user with enterprise features',
          ]);
          
          // Assert
          $response->assertStatus(201);
          $response->assertJson([
              'name' => 'business',
              'display_name' => 'Business User',
              'description' => 'A business user with enterprise features',
          ]);
          
          $this->assertDatabaseHas('user_types', [
              'name' => 'business',
              'display_name' => 'Business User',
              'description' => 'A business user with enterprise features',
          ]);
      }
      
      /**
       * Test that an admin can update a user type.
       *
       * @return void
       */
      public function test_admin_can_update_user_type()
      {
          // Arrange
          $admin = User::factory()->create();
          $adminRole = \App\Models\Role::factory()->create(['name' => 'admin']);
          $permission = \App\Models\Permission::factory()->create(['name' => 'manage-user-types']);
          
          $adminRole->givePermissionTo($permission);
          $admin->assignRole($adminRole);
          
          $userType = UserType::factory()->create([
              'name' => 'premium',
              'display_name' => 'Premium User',
              'description' => 'A premium user',
          ]);
          
          Sanctum::actingAs($admin, ['*']);
          
          // Act
          $response = $this->putJson("/api/user-types/{$userType->id}", [
              'name' => 'premium',
              'display_name' => 'Premium Plus User',
              'description' => 'A premium user with additional features',
          ]);
          
          // Assert
          $response->assertStatus(200);
          $response->assertJson([
              'id' => $userType->id,
              'name' => 'premium',
              'display_name' => 'Premium Plus User',
              'description' => 'A premium user with additional features',
          ]);
          
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
          $adminRole = \App\Models\Role::factory()->create(['name' => 'admin']);
          $permission = \App\Models\Permission::factory()->create(['name' => 'manage-user-types']);
          
          $adminRole->givePermissionTo($permission);
          $admin->assignRole($adminRole);
          
          $userType = UserType::factory()->create(['name' => 'premium']);
          
          Sanctum::actingAs($admin, ['*']);
          
          // Act
          $response = $this->deleteJson("/api/user-types/{$userType->id}");
          
          // Assert
          $response->assertStatus(200);
          $response->assertJson([
              'message' => 'User type deleted successfully',
          ]);
          
          $this->assertDatabaseMissing('user_types', ['id' => $userType->id]);
      }
      
      /**
       * Test that a non-admin cannot manage user types.
       *
       * @return void
       */
      public function test_non_admin_cannot_manage_user_types()
      {
          // Arrange
          $user = User::factory()->create();
          $userType = UserType::factory()->create(['name' => 'premium']);
          
          Sanctum::actingAs($user, ['*']);
          
          // Act & Assert
          $this->getJson('/api/user-types')->assertStatus(403);
          
          $this->postJson('/api/user-types', [
              'name' => 'business',
              'display_name' => 'Business User',
              'description' => 'A business user',
          ])->assertStatus(403);
          
          $this->putJson("/api/user-types/{$userType->id}", [
              'display_name' => 'Updated Name',
          ])->assertStatus(403);
          
          $this->deleteJson("/api/user-types/{$userType->id}")->assertStatus(403);
      }
  }
  
  namespace Tests\Feature\Api;
  
  use App\Models\User;
  use Illuminate\Foundation\Testing\RefreshDatabase;
  use Laravel\Sanctum\Sanctum;
  use Tests\TestCase;
  
  class UserStatusApiTest extends TestCase
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
          
          Sanctum::actingAs($admin, ['*']);
          
          // Act
          $response = $this->postJson("/api/users/{$user->id}/suspend", [
              'reason' => 'Violation of terms',
          ]);
          
          // Assert
          $response->assertStatus(200);
          $response->assertJson([
              'message' => 'User suspended successfully',
              'user' => [
                  'id' => $user->id,
                  'status' => 'suspended',
              ],
          ]);
          
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
          
          Sanctum::actingAs($admin, ['*']);
          
          // Act
          $response = $this->postJson("/api/users/{$user->id}/activate");
          
          // Assert
          $response->assertStatus(200);
          $response->assertJson([
              'message' => 'User activated successfully',
              'user' => [
                  'id' => $user->id,
                  'status' => 'active',
              ],
          ]);
          
          $this->assertEquals('active', $user->fresh()->status);
          $this->assertDatabaseHas('user_status_history', [
              'user_id' => $user->id,
              'status' => 'active',
          ]);
      }
      
      /**
       * Test that a user can retrieve their status history.
       *
       * @return void
       */
      public function test_user_can_retrieve_status_history()
      {
          // Arrange
          $user = User::factory()->create(['status' => 'active']);
          $statusService = new \App\Services\UserStatusService();
          
          $statusService->setStatus($user, 'inactive');
          $statusService->setStatus($user, 'active');
          
          Sanctum::actingAs($user, ['*']);
          
          // Act
          $response = $this->getJson('/api/user/status/history');
          
          // Assert
          $response->assertStatus(200);
          $response->assertJsonCount(2);
          $response->assertJsonStructure([
              '*' => [
                  'id',
                  'user_id',
                  'status',
                  'reason',
                  'created_at',
                  'updated_at',
              ],
          ]);
      }
      
      /**
       * Test that a non-admin cannot suspend or activate users.
       *
       * @return void
       */
      public function test_non_admin_cannot_manage_user_status()
      {
          // Arrange
          $user = User::factory()->create();
          $anotherUser = User::factory()->create(['status' => 'active']);
          
          Sanctum::actingAs($user, ['*']);
          
          // Act & Assert
          $this->postJson("/api/users/{$anotherUser->id}/suspend", [
              'reason' => 'Violation of terms',
          ])->assertStatus(403);
          
          $this->postJson("/api/users/{$anotherUser->id}/activate")->assertStatus(403);
      }
  }
explanation: |
  This example demonstrates API testing for user model enhancements:
  
  1. **User API Tests**: Testing basic user API endpoints:
     - Retrieving the authenticated user's profile
     - Updating the user's profile
     - Ensuring unauthenticated users cannot access protected endpoints
     - Retrieving the user's type and type history
  
  2. **User Role API Tests**: Testing role-related API endpoints:
     - Retrieving a user's roles
     - Retrieving a user's permissions
     - Assigning roles to users (admin only)
     - Ensuring non-admins cannot assign roles
  
  3. **User Type API Tests**: Testing user type management API endpoints:
     - Retrieving all user types (admin only)
     - Creating new user types (admin only)
     - Updating existing user types (admin only)
     - Deleting user types (admin only)
     - Ensuring non-admins cannot manage user types
  
  4. **User Status API Tests**: Testing user status management API endpoints:
     - Suspending users (admin only)
     - Reactivating suspended users (admin only)
     - Retrieving a user's status history
     - Ensuring non-admins cannot manage user status
  
  Key API testing principles demonstrated:
  
  - **JSON Testing**: Using assertJson and assertJsonStructure for JSON responses
  - **Authentication**: Using Laravel Sanctum for API authentication
  - **Authorization**: Testing that only authorized users can access certain endpoints
  - **HTTP Methods**: Testing GET, POST, PUT, and DELETE requests
  - **Status Codes**: Verifying the correct HTTP status codes are returned
  - **Response Structure**: Checking that responses have the expected structure
  
  In a real Laravel application:
  - You would have more comprehensive test coverage
  - You would test validation errors and edge cases
  - You would test pagination and filtering
  - You would test rate limiting and throttling
  - You would organize tests into more specific test classes
challenges:
  - Add tests for API validation errors
  - Implement tests for API pagination and filtering
  - Add tests for API rate limiting
  - Create tests for API versioning
  - Implement tests for API documentation generation
:::
