# Permission Caching

:::interactive-code
title: Implementing Permission Caching
description: This example demonstrates how to implement an efficient permission caching system to improve performance in applications with complex permission structures.
language: php
editable: true
code: |
  <?php
  
  namespace App\Services;
  
  use DateTime;
  use Exception;
  
  // Cache interface
  interface CacheInterface {
      public function get(string $key, $default = null);
      public function set(string $key, $value, int $ttl = null): bool;
      public function delete(string $key): bool;
      public function clear(): bool;
      public function has(string $key): bool;
  }
  
  // Simple in-memory cache implementation
  class InMemoryCache implements CacheInterface {
      private array $cache = [];
      private array $expiration = [];
      
      public function get(string $key, $default = null) {
          if (!$this->has($key)) {
              return $default;
          }
          
          return $this->cache[$key];
      }
      
      public function set(string $key, $value, int $ttl = null): bool {
          $this->cache[$key] = $value;
          
          if ($ttl !== null) {
              $this->expiration[$key] = time() + $ttl;
          } else {
              $this->expiration[$key] = null;
          }
          
          return true;
      }
      
      public function delete(string $key): bool {
          if (isset($this->cache[$key])) {
              unset($this->cache[$key]);
              unset($this->expiration[$key]);
              return true;
          }
          
          return false;
      }
      
      public function clear(): bool {
          $this->cache = [];
          $this->expiration = [];
          return true;
      }
      
      public function has(string $key): bool {
          if (!isset($this->cache[$key])) {
              return false;
          }
          
          // Check if the cache entry has expired
          if ($this->expiration[$key] !== null && time() > $this->expiration[$key]) {
              $this->delete($key);
              return false;
          }
          
          return true;
      }
  }
  
  // Permission service
  class PermissionService {
      private CacheInterface $cache;
      private array $permissions = [];
      private array $roles = [];
      private array $userRoles = [];
      private array $userPermissions = [];
      private int $cacheTtl;
      private bool $cacheEnabled;
      
      public function __construct(CacheInterface $cache, int $cacheTtl = 3600, bool $cacheEnabled = true) {
          $this->cache = $cache;
          $this->cacheTtl = $cacheTtl;
          $this->cacheEnabled = $cacheEnabled;
      }
      
      /**
       * Define a permission.
       *
       * @param string $permission
       * @param string $description
       * @return self
       */
      public function definePermission(string $permission, string $description): self {
          $this->permissions[$permission] = [
              'name' => $permission,
              'description' => $description,
          ];
          
          return $this;
      }
      
      /**
       * Define a role with permissions.
       *
       * @param string $role
       * @param string $description
       * @param array $permissions
       * @return self
       */
      public function defineRole(string $role, string $description, array $permissions): self {
          $this->roles[$role] = [
              'name' => $role,
              'description' => $description,
              'permissions' => $permissions,
          ];
          
          // Clear role-related caches
          $this->clearRoleCache($role);
          
          return $this;
      }
      
      /**
       * Assign a role to a user.
       *
       * @param int $userId
       * @param string $role
       * @return self
       * @throws Exception If the role doesn't exist
       */
      public function assignRoleToUser(int $userId, string $role): self {
          if (!isset($this->roles[$role])) {
              throw new Exception("Role '{$role}' does not exist");
          }
          
          if (!isset($this->userRoles[$userId])) {
              $this->userRoles[$userId] = [];
          }
          
          $this->userRoles[$userId][] = $role;
          
          // Clear user permission cache
          $this->clearUserCache($userId);
          
          return $this;
      }
      
      /**
       * Remove a role from a user.
       *
       * @param int $userId
       * @param string $role
       * @return self
       */
      public function removeRoleFromUser(int $userId, string $role): self {
          if (isset($this->userRoles[$userId])) {
              $key = array_search($role, $this->userRoles[$userId]);
              
              if ($key !== false) {
                  unset($this->userRoles[$userId][$key]);
                  $this->userRoles[$userId] = array_values($this->userRoles[$userId]);
                  
                  // Clear user permission cache
                  $this->clearUserCache($userId);
              }
          }
          
          return $this;
      }
      
      /**
       * Assign a direct permission to a user.
       *
       * @param int $userId
       * @param string $permission
       * @return self
       * @throws Exception If the permission doesn't exist
       */
      public function assignPermissionToUser(int $userId, string $permission): self {
          if (!isset($this->permissions[$permission])) {
              throw new Exception("Permission '{$permission}' does not exist");
          }
          
          if (!isset($this->userPermissions[$userId])) {
              $this->userPermissions[$userId] = [];
          }
          
          $this->userPermissions[$userId][] = $permission;
          
          // Clear user permission cache
          $this->clearUserCache($userId);
          
          return $this;
      }
      
      /**
       * Remove a direct permission from a user.
       *
       * @param int $userId
       * @param string $permission
       * @return self
       */
      public function removePermissionFromUser(int $userId, string $permission): self {
          if (isset($this->userPermissions[$userId])) {
              $key = array_search($permission, $this->userPermissions[$userId]);
              
              if ($key !== false) {
                  unset($this->userPermissions[$userId][$key]);
                  $this->userPermissions[$userId] = array_values($this->userPermissions[$userId]);
                  
                  // Clear user permission cache
                  $this->clearUserCache($userId);
              }
          }
          
          return $this;
      }
      
      /**
       * Check if a user has a specific permission.
       *
       * @param int $userId
       * @param string $permission
       * @return bool
       */
      public function userHasPermission(int $userId, string $permission): bool {
          // Check if permission exists
          if (!isset($this->permissions[$permission])) {
              return false;
          }
          
          // Try to get from cache first
          $cacheKey = "user_permission_{$userId}_{$permission}";
          
          if ($this->cacheEnabled && $this->cache->has($cacheKey)) {
              $hasPermission = $this->cache->get($cacheKey);
              echo "Cache hit for {$cacheKey}\n";
              return $hasPermission;
          }
          
          echo "Cache miss for {$cacheKey}\n";
          
          // Check direct permissions
          if (isset($this->userPermissions[$userId]) && in_array($permission, $this->userPermissions[$userId])) {
              $this->cachePermissionResult($userId, $permission, true);
              return true;
          }
          
          // Check role-based permissions
          if (isset($this->userRoles[$userId])) {
              foreach ($this->userRoles[$userId] as $role) {
                  if (isset($this->roles[$role]) && in_array($permission, $this->roles[$role]['permissions'])) {
                      $this->cachePermissionResult($userId, $permission, true);
                      return true;
                  }
              }
          }
          
          $this->cachePermissionResult($userId, $permission, false);
          return false;
      }
      
      /**
       * Get all permissions for a user.
       *
       * @param int $userId
       * @return array
       */
      public function getUserPermissions(int $userId): array {
          // Try to get from cache first
          $cacheKey = "user_all_permissions_{$userId}";
          
          if ($this->cacheEnabled && $this->cache->has($cacheKey)) {
              $permissions = $this->cache->get($cacheKey);
              echo "Cache hit for {$cacheKey}\n";
              return $permissions;
          }
          
          echo "Cache miss for {$cacheKey}\n";
          
          $permissions = [];
          
          // Add direct permissions
          if (isset($this->userPermissions[$userId])) {
              $permissions = $this->userPermissions[$userId];
          }
          
          // Add role-based permissions
          if (isset($this->userRoles[$userId])) {
              foreach ($this->userRoles[$userId] as $role) {
                  if (isset($this->roles[$role])) {
                      $permissions = array_merge($permissions, $this->roles[$role]['permissions']);
                  }
              }
          }
          
          // Remove duplicates
          $permissions = array_unique($permissions);
          
          // Cache the result
          if ($this->cacheEnabled) {
              $this->cache->set($cacheKey, $permissions, $this->cacheTtl);
          }
          
          return $permissions;
      }
      
      /**
       * Get all roles for a user.
       *
       * @param int $userId
       * @return array
       */
      public function getUserRoles(int $userId): array {
          return $this->userRoles[$userId] ?? [];
      }
      
      /**
       * Cache a permission check result.
       *
       * @param int $userId
       * @param string $permission
       * @param bool $result
       * @return void
       */
      private function cachePermissionResult(int $userId, string $permission, bool $result): void {
          if ($this->cacheEnabled) {
              $cacheKey = "user_permission_{$userId}_{$permission}";
              $this->cache->set($cacheKey, $result, $this->cacheTtl);
          }
      }
      
      /**
       * Clear all permission caches for a user.
       *
       * @param int $userId
       * @return void
       */
      private function clearUserCache(int $userId): void {
          if ($this->cacheEnabled) {
              // Clear all permissions cache
              $this->cache->delete("user_all_permissions_{$userId}");
              
              // Clear individual permission caches
              foreach ($this->permissions as $permission => $data) {
                  $this->cache->delete("user_permission_{$userId}_{$permission}");
              }
          }
      }
      
      /**
       * Clear all permission caches for a role.
       *
       * @param string $role
       * @return void
       */
      private function clearRoleCache(string $role): void {
          if ($this->cacheEnabled) {
              // Find all users with this role
              foreach ($this->userRoles as $userId => $roles) {
                  if (in_array($role, $roles)) {
                      $this->clearUserCache($userId);
                  }
              }
          }
      }
      
      /**
       * Enable or disable caching.
       *
       * @param bool $enabled
       * @return self
       */
      public function setCacheEnabled(bool $enabled): self {
          $this->cacheEnabled = $enabled;
          return $this;
      }
      
      /**
       * Set the cache TTL.
       *
       * @param int $ttl
       * @return self
       */
      public function setCacheTtl(int $ttl): self {
          $this->cacheTtl = $ttl;
          return $this;
      }
      
      /**
       * Clear all caches.
       *
       * @return self
       */
      public function clearAllCaches(): self {
          if ($this->cacheEnabled) {
              $this->cache->clear();
          }
          
          return $this;
      }
      
      /**
       * Get cache statistics.
       *
       * @return array
       */
      public function getCacheStats(): array {
          // In a real app, this would return actual cache statistics
          return [
              'enabled' => $this->cacheEnabled,
              'ttl' => $this->cacheTtl,
          ];
      }
  }
  
  // Example usage
  
  // Create a cache
  $cache = new InMemoryCache();
  
  // Create a permission service
  $permissionService = new PermissionService($cache);
  
  // Define permissions
  $permissionService->definePermission('post:create', 'Create new posts');
  $permissionService->definePermission('post:edit', 'Edit existing posts');
  $permissionService->definePermission('post:delete', 'Delete posts');
  $permissionService->definePermission('comment:create', 'Create comments');
  $permissionService->definePermission('comment:edit', 'Edit comments');
  $permissionService->definePermission('comment:delete', 'Delete comments');
  $permissionService->definePermission('user:manage', 'Manage users');
  
  // Define roles
  $permissionService->defineRole('editor', 'Content editor', [
      'post:create',
      'post:edit',
      'comment:create',
      'comment:edit',
  ]);
  
  $permissionService->defineRole('moderator', 'Content moderator', [
      'post:edit',
      'post:delete',
      'comment:edit',
      'comment:delete',
  ]);
  
  $permissionService->defineRole('admin', 'Administrator', [
      'post:create',
      'post:edit',
      'post:delete',
      'comment:create',
      'comment:edit',
      'comment:delete',
      'user:manage',
  ]);
  
  // Assign roles to users
  $permissionService->assignRoleToUser(1, 'editor');
  $permissionService->assignRoleToUser(2, 'moderator');
  $permissionService->assignRoleToUser(3, 'admin');
  
  // Assign direct permissions
  $permissionService->assignPermissionToUser(1, 'comment:delete');
  
  // Check permissions (first time, cache miss)
  echo "Checking permissions (first time):\n";
  echo "User 1 can create posts: " . ($permissionService->userHasPermission(1, 'post:create') ? 'Yes' : 'No') . "\n";
  echo "User 1 can delete posts: " . ($permissionService->userHasPermission(1, 'post:delete') ? 'Yes' : 'No') . "\n";
  echo "User 1 can delete comments: " . ($permissionService->userHasPermission(1, 'comment:delete') ? 'Yes' : 'No') . "\n";
  
  // Check permissions again (should be cache hit)
  echo "\nChecking permissions again (should be cache hit):\n";
  echo "User 1 can create posts: " . ($permissionService->userHasPermission(1, 'post:create') ? 'Yes' : 'No') . "\n";
  echo "User 1 can delete posts: " . ($permissionService->userHasPermission(1, 'post:delete') ? 'Yes' : 'No') . "\n";
  echo "User 1 can delete comments: " . ($permissionService->userHasPermission(1, 'comment:delete') ? 'Yes' : 'No') . "\n";
  
  // Get all permissions for a user
  echo "\nAll permissions for User 1:\n";
  $permissions = $permissionService->getUserPermissions(1);
  foreach ($permissions as $permission) {
      echo "- {$permission}\n";
  }
  
  // Check again (should be cache hit)
  echo "\nAll permissions for User 1 (should be cache hit):\n";
  $permissions = $permissionService->getUserPermissions(1);
  foreach ($permissions as $permission) {
      echo "- {$permission}\n";
  }
  
  // Update a role (should clear cache)
  echo "\nUpdating editor role...\n";
  $permissionService->defineRole('editor', 'Content editor', [
      'post:create',
      'post:edit',
      'post:delete', // Added new permission
      'comment:create',
      'comment:edit',
  ]);
  
  // Check permissions again (should be cache miss due to role update)
  echo "\nChecking permissions after role update:\n";
  echo "User 1 can delete posts: " . ($permissionService->userHasPermission(1, 'post:delete') ? 'Yes' : 'No') . "\n";
  
  // Remove a role from a user (should clear cache)
  echo "\nRemoving editor role from User 1...\n";
  $permissionService->removeRoleFromUser(1, 'editor');
  
  // Check permissions again (should be cache miss due to role removal)
  echo "\nChecking permissions after role removal:\n";
  echo "User 1 can create posts: " . ($permissionService->userHasPermission(1, 'post:create') ? 'Yes' : 'No') . "\n";
  echo "User 1 can delete comments: " . ($permissionService->userHasPermission(1, 'comment:delete') ? 'Yes' : 'No') . "\n";
  
  // Disable caching
  echo "\nDisabling caching...\n";
  $permissionService->setCacheEnabled(false);
  
  // Check permissions (should always be cache miss)
  echo "\nChecking permissions with caching disabled:\n";
  echo "User 2 can delete posts: " . ($permissionService->userHasPermission(2, 'post:delete') ? 'Yes' : 'No') . "\n";
  echo "User 2 can delete posts (again): " . ($permissionService->userHasPermission(2, 'post:delete') ? 'Yes' : 'No') . "\n";
  
  // Re-enable caching with a shorter TTL
  echo "\nRe-enabling caching with a 10-second TTL...\n";
  $permissionService->setCacheEnabled(true);
  $permissionService->setCacheTtl(10);
  
  // Check permissions (should be cache miss initially)
  echo "\nChecking permissions with short TTL:\n";
  echo "User 3 can manage users: " . ($permissionService->userHasPermission(3, 'user:manage') ? 'Yes' : 'No') . "\n";
  echo "User 3 can manage users (cache hit): " . ($permissionService->userHasPermission(3, 'user:manage') ? 'Yes' : 'No') . "\n";
  
  // Wait for cache to expire
  echo "\nWaiting for cache to expire...\n";
  sleep(11); // In a real app, we wouldn't actually sleep
  
  // Check permissions again (should be cache miss due to expiration)
  echo "\nChecking permissions after cache expiration:\n";
  echo "User 3 can manage users: " . ($permissionService->userHasPermission(3, 'user:manage') ? 'Yes' : 'No') . "\n";
explanation: |
  This example demonstrates a comprehensive permission caching system:
  
  1. **Permission Structure**: The system defines:
     - Individual permissions with descriptions
     - Roles that group multiple permissions
     - User-role assignments
     - Direct user-permission assignments
  
  2. **Caching Strategy**: The system implements several caching strategies:
     - **Individual Permission Caching**: Caches the result of each permission check
     - **All Permissions Caching**: Caches the complete set of permissions for a user
     - **Cache Invalidation**: Automatically clears relevant caches when permissions or roles change
     - **Configurable TTL**: Allows setting how long cached results are valid
  
  3. **Cache Interface**: The system uses a cache interface that could be implemented by different cache providers:
     - In-memory cache (for demonstration)
     - In a real app, this could be Redis, Memcached, or another caching system
  
  4. **Performance Optimization**: The caching system improves performance by:
     - Avoiding repeated database queries for permission checks
     - Reducing computation for complex permission hierarchies
     - Providing fine-grained control over cache invalidation
  
  5. **Cache Control**: The system provides methods to:
     - Enable or disable caching
     - Set the cache TTL (Time To Live)
     - Clear all caches
     - Get cache statistics
  
  Key features of the implementation:
  
  - **Targeted Cache Invalidation**: When a role or permission changes, only the affected caches are cleared
  - **Cache Hit/Miss Logging**: The system logs cache hits and misses for monitoring
  - **Fluent Interface**: The API uses method chaining for a more readable syntax
  - **Configurable Behavior**: Caching can be enabled/disabled and TTL can be adjusted
  
  In a real Laravel application:
  - The cache would use Laravel's Cache facade
  - Permissions and roles would be stored in database tables
  - The system would integrate with Laravel's authorization system
  - Cache tags would be used for more efficient cache invalidation
challenges:
  - Implement a hierarchical role system where roles can inherit permissions from parent roles
  - Add support for permission wildcards (e.g., 'post:*' grants all post-related permissions)
  - Create a cache warming system that pre-caches permissions for active users
  - Implement a distributed cache invalidation mechanism for multi-server environments
  - Add a permission audit log that tracks when permissions are checked and by whom
:::
