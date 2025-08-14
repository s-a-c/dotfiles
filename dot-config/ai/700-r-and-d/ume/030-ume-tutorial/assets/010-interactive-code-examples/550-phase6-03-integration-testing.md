# Integration Testing

:::interactive-code
title: Integration Testing for User Model Enhancements
description: This example demonstrates how to write effective integration tests for user model enhancements, focusing on testing how different components work together.
language: php
editable: true
code: |
  <?php
  
  namespace Tests\Integration;
  
  use App\Events\UserTypeChanged;
  use App\Listeners\SendUserTypeChangeNotification;
  use App\Models\User;
  use App\Models\UserType;
  use App\Notifications\UserTypeChangeNotification;
  use Illuminate\Foundation\Testing\RefreshDatabase;
  use Illuminate\Support\Facades\Event;
  use Illuminate\Support\Facades\Notification;
  use Tests\TestCase;
  
  class UserTypeIntegrationTest extends TestCase
  {
      use RefreshDatabase;
      
      /**
       * Test that changing a user's type triggers the appropriate event.
       *
       * @return void
       */
      public function test_changing_user_type_triggers_event()
      {
          // Arrange
          Event::fake([UserTypeChanged::class]);
          
          $user = User::factory()->create();
          $userType = UserType::factory()->create(['name' => 'premium']);
          
          // Act
          $user->assignType($userType);
          
          // Assert
          Event::assertDispatched(UserTypeChanged::class, function ($event) use ($user, $userType) {
              return $event->user->id === $user->id && 
                     $event->userType->id === $userType->id;
          });
      }
      
      /**
       * Test that the user type change event triggers a notification.
       *
       * @return void
       */
      public function test_user_type_change_event_triggers_notification()
      {
          // Arrange
          Notification::fake();
          
          $user = User::factory()->create();
          $userType = UserType::factory()->create(['name' => 'premium']);
          
          $event = new UserTypeChanged($user, $userType);
          $listener = new SendUserTypeChangeNotification();
          
          // Act
          $listener->handle($event);
          
          // Assert
          Notification::assertSentTo(
              $user,
              UserTypeChangeNotification::class,
              function ($notification) use ($userType) {
                  return $notification->userType->id === $userType->id;
              }
          );
      }
      
      /**
       * Test the complete flow from changing a user's type to sending a notification.
       *
       * @return void
       */
      public function test_complete_user_type_change_flow()
      {
          // Arrange
          Notification::fake();
          
          $user = User::factory()->create();
          $userType = UserType::factory()->create(['name' => 'premium']);
          
          // Act
          $user->assignType($userType);
          
          // Assert
          Notification::assertSentTo(
              $user,
              UserTypeChangeNotification::class,
              function ($notification) use ($userType) {
                  return $notification->userType->id === $userType->id;
              }
          );
      }
  }
  
  namespace Tests\Integration;
  
  use App\Models\Permission;
  use App\Models\Role;
  use App\Models\User;
  use App\Services\PermissionCacheService;
  use Illuminate\Foundation\Testing\RefreshDatabase;
  use Tests\TestCase;
  
  class PermissionCacheIntegrationTest extends TestCase
  {
      use RefreshDatabase;
      
      /**
       * Test that permission checks use the cache.
       *
       * @return void
       */
      public function test_permission_checks_use_cache()
      {
          // Arrange
          $user = User::factory()->create();
          $role = Role::factory()->create(['name' => 'editor']);
          $permission = Permission::factory()->create(['name' => 'edit-posts']);
          
          $role->givePermissionTo($permission);
          $user->assignRole($role);
          
          $cacheService = new PermissionCacheService();
          
          // Act - First check should miss cache
          $hasPermission1 = $cacheService->userHasPermission($user, 'edit-posts');
          
          // Second check should hit cache
          $hasPermission2 = $cacheService->userHasPermission($user, 'edit-posts');
          
          // Assert
          $this->assertTrue($hasPermission1);
          $this->assertTrue($hasPermission2);
          $this->assertEquals(1, $cacheService->getCacheMetrics()['misses']);
          $this->assertEquals(1, $cacheService->getCacheMetrics()['hits']);
      }
      
      /**
       * Test that changing permissions invalidates the cache.
       *
       * @return void
       */
      public function test_changing_permissions_invalidates_cache()
      {
          // Arrange
          $user = User::factory()->create();
          $role = Role::factory()->create(['name' => 'editor']);
          $permission = Permission::factory()->create(['name' => 'edit-posts']);
          
          $role->givePermissionTo($permission);
          $user->assignRole($role);
          
          $cacheService = new PermissionCacheService();
          
          // First check should miss cache
          $hasPermission1 = $cacheService->userHasPermission($user, 'edit-posts');
          $this->assertTrue($hasPermission1);
          
          // Act - Remove the permission
          $role->revokePermissionTo($permission);
          
          // This check should miss cache again because the permissions changed
          $hasPermission2 = $cacheService->userHasPermission($user, 'edit-posts');
          
          // Assert
          $this->assertFalse($hasPermission2);
          $this->assertEquals(2, $cacheService->getCacheMetrics()['misses']);
          $this->assertEquals(0, $cacheService->getCacheMetrics()['hits']);
      }
      
      /**
       * Test that direct permission assignment works with cache.
       *
       * @return void
       */
      public function test_direct_permission_assignment_with_cache()
      {
          // Arrange
          $user = User::factory()->create();
          $permission = Permission::factory()->create(['name' => 'edit-posts']);
          
          $cacheService = new PermissionCacheService();
          
          // First check should miss and return false
          $hasPermission1 = $cacheService->userHasPermission($user, 'edit-posts');
          $this->assertFalse($hasPermission1);
          
          // Act - Give direct permission
          $user->givePermissionTo($permission);
          
          // This check should miss cache again because the permissions changed
          $hasPermission2 = $cacheService->userHasPermission($user, 'edit-posts');
          
          // Assert
          $this->assertTrue($hasPermission2);
          $this->assertEquals(2, $cacheService->getCacheMetrics()['misses']);
          $this->assertEquals(0, $cacheService->getCacheMetrics()['hits']);
      }
  }
  
  namespace Tests\Integration;
  
  use App\Models\User;
  use App\Models\UserType;
  use App\Services\UserTypeService;
  use App\Services\UserStatusService;
  use Illuminate\Foundation\Testing\RefreshDatabase;
  use Tests\TestCase;
  
  class UserTypeTransitionIntegrationTest extends TestCase
  {
      use RefreshDatabase;
      
      /**
       * Test that a user can transition between compatible types.
       *
       * @return void
       */
      public function test_user_can_transition_between_compatible_types()
      {
          // Arrange
          $user = User::factory()->create(['status' => 'active']);
          
          $regularType = UserType::factory()->create(['name' => 'regular']);
          $premiumType = UserType::factory()->create(['name' => 'premium']);
          
          $typeService = new UserTypeService();
          
          // Define allowed transitions
          $typeService->defineTransition('regular', 'premium', function ($user) {
              return $user->status === 'active';
          });
          
          // Assign initial type
          $user->assignType($regularType);
          
          // Act
          $result = $typeService->transitionUserType($user, 'premium');
          
          // Assert
          $this->assertTrue($result);
          $this->assertEquals('premium', $user->fresh()->userType->name);
      }
      
      /**
       * Test that a user cannot transition between incompatible types.
       *
       * @return void
       */
      public function test_user_cannot_transition_between_incompatible_types()
      {
          // Arrange
          $user = User::factory()->create(['status' => 'active']);
          
          $regularType = UserType::factory()->create(['name' => 'regular']);
          $businessType = UserType::factory()->create(['name' => 'business']);
          
          $typeService = new UserTypeService();
          
          // No transition defined from regular to business
          
          // Assign initial type
          $user->assignType($regularType);
          
          // Act
          $result = $typeService->transitionUserType($user, 'business');
          
          // Assert
          $this->assertFalse($result);
          $this->assertEquals('regular', $user->fresh()->userType->name);
      }
      
      /**
       * Test that a user cannot transition if they don't meet the requirements.
       *
       * @return void
       */
      public function test_user_cannot_transition_if_requirements_not_met()
      {
          // Arrange
          $user = User::factory()->create(['status' => 'suspended']);
          
          $regularType = UserType::factory()->create(['name' => 'regular']);
          $premiumType = UserType::factory()->create(['name' => 'premium']);
          
          $typeService = new UserTypeService();
          
          // Define allowed transitions with requirements
          $typeService->defineTransition('regular', 'premium', function ($user) {
              return $user->status === 'active';
          });
          
          // Assign initial type
          $user->assignType($regularType);
          
          // Act
          $result = $typeService->transitionUserType($user, 'premium');
          
          // Assert
          $this->assertFalse($result);
          $this->assertEquals('regular', $user->fresh()->userType->name);
      }
      
      /**
       * Test that user type transitions interact correctly with user status.
       *
       * @return void
       */
      public function test_user_type_transitions_interact_with_user_status()
      {
          // Arrange
          $user = User::factory()->create(['status' => 'active']);
          
          $regularType = UserType::factory()->create(['name' => 'regular']);
          $premiumType = UserType::factory()->create(['name' => 'premium']);
          
          $typeService = new UserTypeService();
          $statusService = new UserStatusService();
          
          // Define allowed transitions with requirements
          $typeService->defineTransition('regular', 'premium', function ($user) {
              return $user->status === 'active';
          });
          
          // Assign initial type
          $user->assignType($regularType);
          
          // Suspend the user
          $statusService->suspend($user, 'payment failed');
          
          // Act
          $result = $typeService->transitionUserType($user, 'premium');
          
          // Assert
          $this->assertFalse($result);
          $this->assertEquals('regular', $user->fresh()->userType->name);
          
          // Reactivate the user
          $statusService->activate($user);
          
          // Try again
          $result = $typeService->transitionUserType($user, 'premium');
          
          // Now it should work
          $this->assertTrue($result);
          $this->assertEquals('premium', $user->fresh()->userType->name);
      }
  }
  
  namespace Tests\Integration;
  
  use App\Models\User;
  use App\Services\UserStatusService;
  use App\Services\UserTypeService;
  use Illuminate\Foundation\Testing\RefreshDatabase;
  use Tests\TestCase;
  
  class UserStatusIntegrationTest extends TestCase
  {
      use RefreshDatabase;
      
      /**
       * Test that suspending a user affects their ability to transition types.
       *
       * @return void
       */
      public function test_suspending_user_affects_type_transitions()
      {
          // Arrange
          $user = User::factory()->create(['status' => 'active']);
          
          $regularType = \App\Models\UserType::factory()->create(['name' => 'regular']);
          $premiumType = \App\Models\UserType::factory()->create(['name' => 'premium']);
          
          $typeService = new UserTypeService();
          $statusService = new UserStatusService();
          
          // Define allowed transitions with requirements
          $typeService->defineTransition('regular', 'premium', function ($user) {
              return $user->status === 'active';
          });
          
          // Assign initial type
          $user->assignType($regularType);
          
          // Act - Suspend the user
          $statusService->suspend($user, 'violation of terms');
          
          // Try to transition
          $result = $typeService->transitionUserType($user, 'premium');
          
          // Assert
          $this->assertFalse($result);
          $this->assertEquals('regular', $user->fresh()->userType->name);
          $this->assertEquals('suspended', $user->fresh()->status);
      }
      
      /**
       * Test that user status changes are properly recorded in history.
       *
       * @return void
       */
      public function test_status_changes_recorded_in_history()
      {
          // Arrange
          $user = User::factory()->create(['status' => 'active']);
          $statusService = new UserStatusService();
          
          // Act
          $statusService->suspend($user, 'violation of terms');
          $statusService->activate($user);
          $statusService->deactivate($user);
          
          // Assert
          $history = $user->statusHistory()->orderBy('created_at')->get();
          
          $this->assertCount(3, $history);
          $this->assertEquals('suspended', $history[0]->status);
          $this->assertEquals('violation of terms', $history[0]->reason);
          $this->assertEquals('active', $history[1]->status);
          $this->assertEquals('inactive', $history[2]->status);
      }
      
      /**
       * Test that user status affects authentication.
       *
       * @return void
       */
      public function test_user_status_affects_authentication()
      {
          // Arrange
          $user = User::factory()->create([
              'email' => 'user@example.com',
              'password' => bcrypt('password'),
              'status' => 'active',
          ]);
          
          $statusService = new UserStatusService();
          
          // Act & Assert - Active user can log in
          $response = $this->post('/login', [
              'email' => 'user@example.com',
              'password' => 'password',
          ]);
          
          $response->assertRedirect('/dashboard');
          $this->assertAuthenticatedAs($user);
          
          // Log out
          $this->post('/logout');
          $this->assertGuest();
          
          // Suspend the user
          $statusService->suspend($user, 'violation of terms');
          
          // Suspended user cannot log in
          $response = $this->post('/login', [
              'email' => 'user@example.com',
              'password' => 'password',
          ]);
          
          $response->assertRedirect('/');
          $this->assertGuest();
          $response->assertSessionHas('error', 'Your account has been suspended.');
      }
  }
explanation: |
  This example demonstrates integration testing for user model enhancements:
  
  1. **User Type Integration Tests**: Testing how user types interact with other components:
     - Verifying that changing a user's type triggers the appropriate event
     - Testing that the event listener sends the correct notification
     - Testing the complete flow from type change to notification
  
  2. **Permission Cache Integration Tests**: Testing the permission caching system:
     - Verifying that permission checks use the cache correctly
     - Testing that changing permissions invalidates the cache
     - Testing direct permission assignment with the cache
  
  3. **User Type Transition Integration Tests**: Testing the type transition system:
     - Verifying that users can transition between compatible types
     - Testing that users cannot transition between incompatible types
     - Testing that transitions respect requirements
     - Testing how type transitions interact with user status
  
  4. **User Status Integration Tests**: Testing how user status interacts with other components:
     - Verifying that suspending a user affects their ability to transition types
     - Testing that status changes are properly recorded in history
     - Testing how user status affects authentication
  
  Key integration testing principles demonstrated:
  
  - **Component Interaction**: Testing how different components work together
  - **Event Testing**: Verifying that events are dispatched and handled correctly
  - **Notification Testing**: Checking that notifications are sent as expected
  - **Cache Testing**: Verifying that caching works correctly
  - **Authentication Testing**: Testing how components affect authentication
  - **Complete Flows**: Testing entire user flows from start to finish
  
  In a real Laravel application:
  - You would have more comprehensive test coverage
  - You would test more complex interactions between components
  - You would use more sophisticated factories and seeders
  - You would test edge cases and error conditions
  - You would organize tests into more specific test classes
challenges:
  - Add tests for how user types interact with billing systems
  - Implement tests for how permissions affect access to different features
  - Add tests for how user status changes affect scheduled tasks
  - Create tests for how type transitions affect user capabilities
  - Implement tests for how caching affects system performance under load
:::
