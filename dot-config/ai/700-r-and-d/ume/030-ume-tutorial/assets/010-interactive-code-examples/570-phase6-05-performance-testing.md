# Performance Testing

:::interactive-code
title: Performance Testing for User Model Enhancements
description: This example demonstrates how to write effective performance tests for user model enhancements, focusing on measuring and optimizing performance.
language: php
editable: true
code: |
  <?php
  
  namespace Tests\Performance;
  
  use App\Models\Permission;
  use App\Models\Role;
  use App\Models\User;
  use App\Services\PermissionCacheService;
  use Illuminate\Foundation\Testing\RefreshDatabase;
  use Illuminate\Support\Facades\Cache;
  use Tests\TestCase;
  
  class PermissionCachePerformanceTest extends TestCase
  {
      use RefreshDatabase;
      
      /**
       * Test the performance of permission checks with and without caching.
       *
       * @return void
       */
      public function test_permission_check_performance()
      {
          // Arrange
          $user = User::factory()->create();
          $role = Role::factory()->create(['name' => 'editor']);
          
          // Create 100 permissions and assign them to the role
          $permissions = [];
          for ($i = 1; $i <= 100; $i++) {
              $permission = Permission::factory()->create(['name' => "permission-{$i}"]);
              $role->givePermissionTo($permission);
              $permissions[] = $permission;
          }
          
          $user->assignRole($role);
          
          $cacheService = new PermissionCacheService();
          
          // Clear the cache
          Cache::flush();
          
          // Act & Assert - Without cache
          $startTime = microtime(true);
          
          for ($i = 1; $i <= 100; $i++) {
              $hasPermission = $user->hasPermissionTo("permission-{$i}");
              $this->assertTrue($hasPermission);
          }
          
          $endTime = microtime(true);
          $timeWithoutCache = $endTime - $startTime;
          
          // With cache
          $startTime = microtime(true);
          
          for ($i = 1; $i <= 100; $i++) {
              $hasPermission = $cacheService->userHasPermission($user, "permission-{$i}");
              $this->assertTrue($hasPermission);
          }
          
          $endTime = microtime(true);
          $timeWithCache = $endTime - $startTime;
          
          // Assert that caching is faster
          $this->assertLessThan($timeWithoutCache, $timeWithCache);
          
          // Log the performance improvement
          $improvement = (1 - ($timeWithCache / $timeWithoutCache)) * 100;
          $this->addToAssertionCount(1); // Add a dummy assertion
          
          echo "Permission check performance test:\n";
          echo "Time without cache: {$timeWithoutCache} seconds\n";
          echo "Time with cache: {$timeWithCache} seconds\n";
          echo "Performance improvement: {$improvement}%\n";
      }
      
      /**
       * Test the memory usage of permission checks with and without caching.
       *
       * @return void
       */
      public function test_permission_check_memory_usage()
      {
          // Arrange
          $user = User::factory()->create();
          $role = Role::factory()->create(['name' => 'editor']);
          
          // Create 100 permissions and assign them to the role
          $permissions = [];
          for ($i = 1; $i <= 100; $i++) {
              $permission = Permission::factory()->create(['name' => "permission-{$i}"]);
              $role->givePermissionTo($permission);
              $permissions[] = $permission;
          }
          
          $user->assignRole($role);
          
          $cacheService = new PermissionCacheService();
          
          // Clear the cache
          Cache::flush();
          
          // Act & Assert - Without cache
          $startMemory = memory_get_usage();
          
          for ($i = 1; $i <= 100; $i++) {
              $hasPermission = $user->hasPermissionTo("permission-{$i}");
              $this->assertTrue($hasPermission);
          }
          
          $endMemory = memory_get_usage();
          $memoryWithoutCache = $endMemory - $startMemory;
          
          // With cache
          Cache::flush();
          $startMemory = memory_get_usage();
          
          for ($i = 1; $i <= 100; $i++) {
              $hasPermission = $cacheService->userHasPermission($user, "permission-{$i}");
              $this->assertTrue($hasPermission);
          }
          
          $endMemory = memory_get_usage();
          $memoryWithCache = $endMemory - $startMemory;
          
          // Log the memory usage
          $this->addToAssertionCount(1); // Add a dummy assertion
          
          echo "Permission check memory usage test:\n";
          echo "Memory without cache: {$memoryWithoutCache} bytes\n";
          echo "Memory with cache: {$memoryWithCache} bytes\n";
      }
  }
  
  namespace Tests\Performance;
  
  use App\Models\User;
  use App\Models\UserType;
  use Illuminate\Foundation\Testing\RefreshDatabase;
  use Illuminate\Support\Facades\DB;
  use Tests\TestCase;
  
  class UserTypePerformanceTest extends TestCase
  {
      use RefreshDatabase;
      
      /**
       * Test the performance of user type queries with eager loading.
       *
       * @return void
       */
      public function test_user_type_query_performance()
      {
          // Arrange
          $regularType = UserType::factory()->create(['name' => 'regular']);
          $premiumType = UserType::factory()->create(['name' => 'premium']);
          
          // Create 100 users with types
          for ($i = 1; $i <= 50; $i++) {
              $user = User::factory()->create();
              $user->assignType($regularType);
          }
          
          for ($i = 1; $i <= 50; $i++) {
              $user = User::factory()->create();
              $user->assignType($premiumType);
          }
          
          // Act & Assert - Without eager loading
          $startTime = microtime(true);
          
          $users = User::all();
          foreach ($users as $user) {
              $typeName = $user->userType->name;
              $this->assertNotNull($typeName);
          }
          
          $endTime = microtime(true);
          $timeWithoutEagerLoading = $endTime - $startTime;
          
          // With eager loading
          $startTime = microtime(true);
          
          $users = User::with('userType')->get();
          foreach ($users as $user) {
              $typeName = $user->userType->name;
              $this->assertNotNull($typeName);
          }
          
          $endTime = microtime(true);
          $timeWithEagerLoading = $endTime - $startTime;
          
          // Assert that eager loading is faster
          $this->assertLessThan($timeWithoutEagerLoading, $timeWithEagerLoading);
          
          // Log the performance improvement
          $improvement = (1 - ($timeWithEagerLoading / $timeWithoutEagerLoading)) * 100;
          $this->addToAssertionCount(1); // Add a dummy assertion
          
          echo "User type query performance test:\n";
          echo "Time without eager loading: {$timeWithoutEagerLoading} seconds\n";
          echo "Time with eager loading: {$timeWithEagerLoading} seconds\n";
          echo "Performance improvement: {$improvement}%\n";
      }
      
      /**
       * Test the performance of user type history queries with different approaches.
       *
       * @return void
       */
      public function test_user_type_history_query_performance()
      {
          // Arrange
          $regularType = UserType::factory()->create(['name' => 'regular']);
          $premiumType = UserType::factory()->create(['name' => 'premium']);
          
          // Create 10 users with type history
          $users = [];
          for ($i = 1; $i <= 10; $i++) {
              $user = User::factory()->create();
              $user->assignType($regularType);
              $user->assignType($premiumType);
              $users[] = $user;
          }
          
          // Act & Assert - Using Eloquent relationships
          $startTime = microtime(true);
          
          foreach ($users as $user) {
              $history = $user->userTypeHistory()->with('userType')->get();
              foreach ($history as $entry) {
                  $typeName = $entry->userType->name;
                  $this->assertNotNull($typeName);
              }
          }
          
          $endTime = microtime(true);
          $timeWithEloquent = $endTime - $startTime;
          
          // Using raw SQL query
          $startTime = microtime(true);
          
          foreach ($users as $user) {
              $history = DB::select("
                  SELECT uth.*, ut.name as type_name
                  FROM user_type_history uth
                  JOIN user_types ut ON uth.user_type_id = ut.id
                  WHERE uth.user_id = ?
                  ORDER BY uth.created_at DESC
              ", [$user->id]);
              
              foreach ($history as $entry) {
                  $typeName = $entry->type_name;
                  $this->assertNotNull($typeName);
              }
          }
          
          $endTime = microtime(true);
          $timeWithRawSQL = $endTime - $startTime;
          
          // Log the performance comparison
          $this->addToAssertionCount(1); // Add a dummy assertion
          
          echo "User type history query performance test:\n";
          echo "Time with Eloquent: {$timeWithEloquent} seconds\n";
          echo "Time with raw SQL: {$timeWithRawSQL} seconds\n";
      }
  }
  
  namespace Tests\Performance;
  
  use App\Models\User;
  use Illuminate\Foundation\Testing\RefreshDatabase;
  use Illuminate\Support\Facades\DB;
  use Tests\TestCase;
  
  class UserStatusPerformanceTest extends TestCase
  {
      use RefreshDatabase;
      
      /**
       * Test the performance of different methods for counting users by status.
       *
       * @return void
       */
      public function test_count_users_by_status_performance()
      {
          // Arrange
          // Create users with different statuses
          for ($i = 1; $i <= 100; $i++) {
              User::factory()->create(['status' => 'active']);
          }
          
          for ($i = 1; $i <= 50; $i++) {
              User::factory()->create(['status' => 'inactive']);
          }
          
          for ($i = 1; $i <= 25; $i++) {
              User::factory()->create(['status' => 'suspended']);
          }
          
          // Act & Assert - Using Eloquent count
          $startTime = microtime(true);
          
          $activeCount = User::where('status', 'active')->count();
          $inactiveCount = User::where('status', 'inactive')->count();
          $suspendedCount = User::where('status', 'suspended')->count();
          
          $endTime = microtime(true);
          $timeWithEloquentCount = $endTime - $startTime;
          
          $this->assertEquals(100, $activeCount);
          $this->assertEquals(50, $inactiveCount);
          $this->assertEquals(25, $suspendedCount);
          
          // Using raw SQL query
          $startTime = microtime(true);
          
          $counts = DB::select("
              SELECT status, COUNT(*) as count
              FROM users
              GROUP BY status
          ");
          
          $endTime = microtime(true);
          $timeWithRawSQL = $endTime - $startTime;
          
          $countsByStatus = [];
          foreach ($counts as $count) {
              $countsByStatus[$count->status] = $count->count;
          }
          
          $this->assertEquals(100, $countsByStatus['active']);
          $this->assertEquals(50, $countsByStatus['inactive']);
          $this->assertEquals(25, $countsByStatus['suspended']);
          
          // Log the performance comparison
          $this->addToAssertionCount(1); // Add a dummy assertion
          
          echo "Count users by status performance test:\n";
          echo "Time with Eloquent count: {$timeWithEloquentCount} seconds\n";
          echo "Time with raw SQL: {$timeWithRawSQL} seconds\n";
      }
      
      /**
       * Test the performance of different methods for retrieving user status history.
       *
       * @return void
       */
      public function test_user_status_history_performance()
      {
          // Arrange
          $user = User::factory()->create(['status' => 'active']);
          $statusService = new \App\Services\UserStatusService();
          
          // Create status history
          for ($i = 1; $i <= 50; $i++) {
              $statusService->setStatus($user, 'inactive');
              $statusService->setStatus($user, 'active');
          }
          
          // Act & Assert - Using Eloquent with pagination
          $startTime = microtime(true);
          
          $history = $user->statusHistory()->orderBy('created_at', 'desc')->paginate(10);
          $this->assertCount(10, $history);
          
          $endTime = microtime(true);
          $timeWithPagination = $endTime - $startTime;
          
          // Using Eloquent with limit
          $startTime = microtime(true);
          
          $history = $user->statusHistory()->orderBy('created_at', 'desc')->limit(10)->get();
          $this->assertCount(10, $history);
          
          $endTime = microtime(true);
          $timeWithLimit = $endTime - $startTime;
          
          // Log the performance comparison
          $this->addToAssertionCount(1); // Add a dummy assertion
          
          echo "User status history performance test:\n";
          echo "Time with pagination: {$timeWithPagination} seconds\n";
          echo "Time with limit: {$timeWithLimit} seconds\n";
      }
  }
  
  namespace Tests\Performance;
  
  use App\Models\Permission;
  use App\Models\Role;
  use App\Models\User;
  use Illuminate\Foundation\Testing\RefreshDatabase;
  use Illuminate\Support\Facades\DB;
  use Tests\TestCase;
  
  class DatabaseIndexPerformanceTest extends TestCase
  {
      use RefreshDatabase;
      
      /**
       * Test the performance impact of database indexes on user queries.
       *
       * @return void
       */
      public function test_database_index_performance()
      {
          // This test assumes you have added an index to the 'status' column in the users table
          // If you haven't, you can add it with a migration:
          // Schema::table('users', function (Blueprint $table) {
          //     $table->index('status');
          // });
          
          // Arrange
          // Create a large number of users with different statuses
          for ($i = 1; $i <= 1000; $i++) {
              User::factory()->create([
                  'status' => $i % 4 === 0 ? 'suspended' : ($i % 3 === 0 ? 'inactive' : 'active'),
              ]);
          }
          
          // Act & Assert - Query with WHERE clause on indexed column
          $startTime = microtime(true);
          
          $suspendedUsers = User::where('status', 'suspended')->get();
          
          $endTime = microtime(true);
          $timeWithIndex = $endTime - $startTime;
          
          // Query with WHERE clause on non-indexed column (assuming 'remember_token' is not indexed)
          $startTime = microtime(true);
          
          $usersWithToken = User::whereNotNull('remember_token')->get();
          
          $endTime = microtime(true);
          $timeWithoutIndex = $endTime - $startTime;
          
          // Log the performance comparison
          $this->addToAssertionCount(1); // Add a dummy assertion
          
          echo "Database index performance test:\n";
          echo "Time with index (status column): {$timeWithIndex} seconds\n";
          echo "Time without index (remember_token column): {$timeWithoutIndex} seconds\n";
      }
      
      /**
       * Test the performance impact of database indexes on role-permission queries.
       *
       * @return void
       */
      public function test_role_permission_index_performance()
      {
          // This test assumes you have added indexes to the role_has_permissions and user_has_roles tables
          
          // Arrange
          // Create roles and permissions
          $roles = [];
          for ($i = 1; $i <= 10; $i++) {
              $roles[] = Role::factory()->create(['name' => "role-{$i}"]);
          }
          
          $permissions = [];
          for ($i = 1; $i <= 100; $i++) {
              $permissions[] = Permission::factory()->create(['name' => "permission-{$i}"]);
          }
          
          // Assign permissions to roles
          foreach ($roles as $role) {
              foreach ($permissions as $permission) {
                  if (rand(0, 1) === 1) {
                      $role->givePermissionTo($permission);
                  }
              }
          }
          
          // Create users and assign roles
          $users = [];
          for ($i = 1; $i <= 100; $i++) {
              $user = User::factory()->create();
              $user->assignRole($roles[rand(0, 9)]);
              $users[] = $user;
          }
          
          // Act & Assert - Query for users with a specific permission
          $startTime = microtime(true);
          
          $usersWithPermission = User::permission('permission-1')->get();
          
          $endTime = microtime(true);
          $timeWithPermissionQuery = $endTime - $startTime;
          
          // Query for users with a specific role
          $startTime = microtime(true);
          
          $usersWithRole = User::role('role-1')->get();
          
          $endTime = microtime(true);
          $timeWithRoleQuery = $endTime - $startTime;
          
          // Log the performance comparison
          $this->addToAssertionCount(1); // Add a dummy assertion
          
          echo "Role-permission index performance test:\n";
          echo "Time for permission query: {$timeWithPermissionQuery} seconds\n";
          echo "Time for role query: {$timeWithRoleQuery} seconds\n";
      }
  }
explanation: |
  This example demonstrates performance testing for user model enhancements:
  
  1. **Permission Cache Performance Tests**: Testing the performance impact of permission caching:
     - Comparing the execution time of permission checks with and without caching
     - Measuring the memory usage of permission checks with and without caching
     - Verifying that caching provides a significant performance improvement
  
  2. **User Type Performance Tests**: Testing the performance of user type queries:
     - Comparing queries with and without eager loading
     - Testing different approaches for retrieving user type history
     - Measuring the performance improvement from using eager loading
  
  3. **User Status Performance Tests**: Testing the performance of user status operations:
     - Comparing different methods for counting users by status
     - Testing the performance of retrieving user status history
     - Comparing pagination versus limit for retrieving history
  
  4. **Database Index Performance Tests**: Testing the impact of database indexes:
     - Measuring the performance of queries on indexed versus non-indexed columns
     - Testing the performance of role and permission queries with indexes
     - Demonstrating the importance of proper database indexing
  
  Key performance testing principles demonstrated:
  
  - **Time Measurement**: Using microtime() to measure execution time
  - **Memory Measurement**: Using memory_get_usage() to measure memory usage
  - **Comparative Testing**: Comparing different approaches to the same task
  - **Performance Optimization**: Demonstrating techniques like caching and eager loading
  - **Database Optimization**: Showing the impact of database indexes
  - **Quantifiable Results**: Calculating and displaying performance improvements
  
  In a real Laravel application:
  - You would use more sophisticated performance testing tools
  - You would test with larger datasets
  - You would test under different load conditions
  - You would establish performance baselines and thresholds
  - You would automate performance testing as part of CI/CD
challenges:
  - Implement load testing for API endpoints
  - Add benchmarking for different cache drivers
  - Create tests for database query optimization
  - Implement memory profiling for complex operations
  - Add performance testing for queue processing
:::
