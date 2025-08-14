# Scaling Considerations

:::interactive-code
title: Implementing Scalable User Model Enhancements
description: This example demonstrates how to implement user model enhancements that scale effectively with growing user bases and traffic, focusing on database optimization, caching strategies, and horizontal scaling.
language: php
editable: true
code: |
  <?php
  
  namespace App\Services;
  
  use App\Models\User;
  use Illuminate\Support\Facades\Cache;
  use Illuminate\Support\Facades\DB;
  use Illuminate\Support\Facades\Redis;
  use Illuminate\Support\Facades\Log;
  
  class UserScalingService
  {
      /**
       * Cache TTL in seconds (1 hour).
       *
       * @var int
       */
      protected const CACHE_TTL = 3600;
      
      /**
       * Get a user by ID with optimized caching.
       *
       * @param int $userId
       * @return \App\Models\User|null
       */
      public function getUser(int $userId): ?User
      {
          $cacheKey = "user:{$userId}";
          
          return Cache::remember($cacheKey, self::CACHE_TTL, function () use ($userId) {
              return User::find($userId);
          });
      }
      
      /**
       * Get a user with their relationships using eager loading.
       *
       * @param int $userId
       * @param array $relations
       * @return \App\Models\User|null
       */
      public function getUserWithRelations(int $userId, array $relations = []): ?User
      {
          $cacheKey = "user:{$userId}:" . md5(implode(',', $relations));
          
          return Cache::remember($cacheKey, self::CACHE_TTL, function () use ($userId, $relations) {
              return User::with($relations)->find($userId);
          });
      }
      
      /**
       * Search for users with pagination and caching.
       *
       * @param array $criteria
       * @param int $page
       * @param int $perPage
       * @return \Illuminate\Pagination\LengthAwarePaginator
       */
      public function searchUsers(array $criteria, int $page = 1, int $perPage = 15)
      {
          $cacheKey = "users:search:" . md5(json_encode($criteria) . ":{$page}:{$perPage}");
          
          return Cache::remember($cacheKey, 300, function () use ($criteria, $page, $perPage) {
              $query = User::query();
              
              // Apply search criteria
              foreach ($criteria as $field => $value) {
                  if ($field === 'name' || $field === 'email') {
                      $query->where($field, 'LIKE', "%{$value}%");
                  } else {
                      $query->where($field, $value);
                  }
              }
              
              // Use indexed columns for sorting
              $query->orderBy('created_at', 'desc');
              
              return $query->paginate($perPage, ['*'], 'page', $page);
          });
      }
      
      /**
       * Invalidate user cache when user is updated.
       *
       * @param \App\Models\User $user
       * @return void
       */
      public function invalidateUserCache(User $user): void
      {
          // Clear specific user cache
          Cache::forget("user:{$user->id}");
          
          // Clear user relation caches using pattern
          $this->clearCachePattern("user:{$user->id}:*");
          
          // Clear search caches that might include this user
          $this->clearCachePattern("users:search:*");
      }
      
      /**
       * Clear cache entries matching a pattern.
       *
       * @param string $pattern
       * @return void
       */
      protected function clearCachePattern(string $pattern): void
      {
          if (config('cache.default') === 'redis') {
              $this->clearRedisPattern($pattern);
          } else {
              Log::warning("Cache pattern clearing is only supported with Redis driver");
          }
      }
      
      /**
       * Clear Redis cache entries matching a pattern.
       *
       * @param string $pattern
       * @return void
       */
      protected function clearRedisPattern(string $pattern): void
      {
          $prefix = config('cache.prefix', '');
          $keys = Redis::keys("{$prefix}:{$pattern}");
          
          if (!empty($keys)) {
              foreach ($keys as $key) {
                  // Remove the prefix from the key
                  $key = str_replace("{$prefix}:", '', $key);
                  Cache::forget($key);
              }
          }
      }
      
      /**
       * Get user count with caching.
       *
       * @return int
       */
      public function getUserCount(): int
      {
          return Cache::remember('users:count', 300, function () {
              return User::count();
          });
      }
      
      /**
       * Get active user count with caching.
       *
       * @return int
       */
      public function getActiveUserCount(): int
      {
          return Cache::remember('users:active:count', 300, function () {
              return User::where('status', 'active')->count();
          });
      }
      
      /**
       * Get user statistics with caching.
       *
       * @return array
       */
      public function getUserStatistics(): array
      {
          return Cache::remember('users:statistics', 3600, function () {
              return [
                  'total' => User::count(),
                  'active' => User::where('status', 'active')->count(),
                  'inactive' => User::where('status', 'inactive')->count(),
                  'suspended' => User::where('status', 'suspended')->count(),
                  'by_type' => $this->getUserCountByType(),
                  'by_role' => $this->getUserCountByRole(),
                  'recent' => User::where('created_at', '>=', now()->subDays(30))->count(),
              ];
          });
      }
      
      /**
       * Get user count by type with caching.
       *
       * @return array
       */
      protected function getUserCountByType(): array
      {
          return Cache::remember('users:count:by_type', 3600, function () {
              return DB::table('users')
                  ->join('user_types', 'users.user_type_id', '=', 'user_types.id')
                  ->select('user_types.name', DB::raw('count(*) as count'))
                  ->groupBy('user_types.name')
                  ->pluck('count', 'name')
                  ->toArray();
          });
      }
      
      /**
       * Get user count by role with caching.
       *
       * @return array
       */
      protected function getUserCountByRole(): array
      {
          return Cache::remember('users:count:by_role', 3600, function () {
              return DB::table('users')
                  ->join('model_has_roles', function ($join) {
                      $join->on('users.id', '=', 'model_has_roles.model_id')
                          ->where('model_has_roles.model_type', '=', User::class);
                  })
                  ->join('roles', 'model_has_roles.role_id', '=', 'roles.id')
                  ->select('roles.name', DB::raw('count(*) as count'))
                  ->groupBy('roles.name')
                  ->pluck('count', 'name')
                  ->toArray();
          });
      }
  }
  
  namespace App\Models;
  
  use Illuminate\Database\Eloquent\Model;
  use Illuminate\Support\Facades\DB;
  
  class UserShard extends Model
  {
      /**
       * Get the shard connection for a user.
       *
       * @param int $userId
       * @return string
       */
      public static function getShardConnection(int $userId): string
      {
          // Simple sharding strategy: modulo of user ID
          $shardCount = config('database.shards.count', 1);
          $shardIndex = $userId % $shardCount;
          
          return "mysql_shard_{$shardIndex}";
      }
      
      /**
       * Get a user from the appropriate shard.
       *
       * @param int $userId
       * @return \App\Models\User|null
       */
      public static function getUserFromShard(int $userId): ?User
      {
          $connection = self::getShardConnection($userId);
          
          return User::on($connection)->find($userId);
      }
      
      /**
       * Save a user to the appropriate shard.
       *
       * @param \App\Models\User $user
       * @return bool
       */
      public static function saveUserToShard(User $user): bool
      {
          $connection = self::getShardConnection($user->id);
          
          // Set the connection for this instance
          $user->setConnection($connection);
          
          return $user->save();
      }
      
      /**
       * Execute a callback on all shards.
       *
       * @param callable $callback
       * @return array
       */
      public static function onAllShards(callable $callback): array
      {
          $results = [];
          $shardCount = config('database.shards.count', 1);
          
          for ($i = 0; $i < $shardCount; $i++) {
              $connection = "mysql_shard_{$i}";
              $results[$connection] = $callback($connection);
          }
          
          return $results;
      }
      
      /**
       * Search for users across all shards.
       *
       * @param array $criteria
       * @param int $limit
       * @return array
       */
      public static function searchAcrossShards(array $criteria, int $limit = 10): array
      {
          $results = [];
          
          self::onAllShards(function ($connection) use (&$results, $criteria, $limit) {
              $query = User::on($connection)->query();
              
              // Apply search criteria
              foreach ($criteria as $field => $value) {
                  if ($field === 'name' || $field === 'email') {
                      $query->where($field, 'LIKE', "%{$value}%");
                  } else {
                      $query->where($field, $value);
                  }
              }
              
              // Get results from this shard
              $shardResults = $query->limit($limit)->get();
              
              // Add connection info to each result
              $shardResults->each(function ($user) use ($connection) {
                  $user->shard_connection = $connection;
              });
              
              $results = array_merge($results, $shardResults->toArray());
              
              return $shardResults->count();
          });
          
          // Sort results by created_at
          usort($results, function ($a, $b) {
              return strtotime($b['created_at']) - strtotime($a['created_at']);
          });
          
          // Limit the final result set
          return array_slice($results, 0, $limit);
      }
      
      /**
       * Get aggregated user statistics across all shards.
       *
       * @return array
       */
      public static function getAggregatedStatistics(): array
      {
          $statistics = [
              'total' => 0,
              'active' => 0,
              'inactive' => 0,
              'suspended' => 0,
              'by_type' => [],
              'by_role' => [],
              'recent' => 0,
          ];
          
          self::onAllShards(function ($connection) use (&$statistics) {
              // Get total counts
              $statistics['total'] += User::on($connection)->count();
              $statistics['active'] += User::on($connection)->where('status', 'active')->count();
              $statistics['inactive'] += User::on($connection)->where('status', 'inactive')->count();
              $statistics['suspended'] += User::on($connection)->where('status', 'suspended')->count();
              $statistics['recent'] += User::on($connection)->where('created_at', '>=', now()->subDays(30))->count();
              
              // Get counts by type
              $typeStats = DB::connection($connection)
                  ->table('users')
                  ->join('user_types', 'users.user_type_id', '=', 'user_types.id')
                  ->select('user_types.name', DB::raw('count(*) as count'))
                  ->groupBy('user_types.name')
                  ->pluck('count', 'name')
                  ->toArray();
              
              foreach ($typeStats as $type => $count) {
                  if (!isset($statistics['by_type'][$type])) {
                      $statistics['by_type'][$type] = 0;
                  }
                  $statistics['by_type'][$type] += $count;
              }
              
              // Get counts by role
              $roleStats = DB::connection($connection)
                  ->table('users')
                  ->join('model_has_roles', function ($join) {
                      $join->on('users.id', '=', 'model_has_roles.model_id')
                          ->where('model_has_roles.model_type', '=', User::class);
                  })
                  ->join('roles', 'model_has_roles.role_id', '=', 'roles.id')
                  ->select('roles.name', DB::raw('count(*) as count'))
                  ->groupBy('roles.name')
                  ->pluck('count', 'name')
                  ->toArray();
              
              foreach ($roleStats as $role => $count) {
                  if (!isset($statistics['by_role'][$role])) {
                      $statistics['by_role'][$role] = 0;
                  }
                  $statistics['by_role'][$role] += $count;
              }
              
              return true;
          });
          
          return $statistics;
      }
  }
  
  namespace App\Providers;
  
  use Illuminate\Support\ServiceProvider;
  use Illuminate\Support\Facades\DB;
  use Illuminate\Support\Facades\Event;
  use App\Models\User;
  use App\Services\UserScalingService;
  
  class ScalingServiceProvider extends ServiceProvider
  {
      /**
       * Register services.
       */
      public function register(): void
      {
          $this->app->singleton(UserScalingService::class, function ($app) {
              return new UserScalingService();
          });
      }
      
      /**
       * Bootstrap services.
       */
      public function boot(): void
      {
          // Configure query logging for debugging in local environment
          if ($this->app->environment('local')) {
              DB::listen(function ($query) {
                  $sql = $query->sql;
                  $bindings = $query->bindings;
                  $time = $query->time;
                  
                  // Log slow queries
                  if ($time > 100) { // 100ms
                      logger()->warning("Slow query detected: {$sql}", [
                          'bindings' => $bindings,
                          'time' => $time,
                      ]);
                  }
              });
          }
          
          // Set up cache invalidation listeners
          Event::listen('eloquent.saved: ' . User::class, function (User $user) {
              app(UserScalingService::class)->invalidateUserCache($user);
          });
          
          Event::listen('eloquent.deleted: ' . User::class, function (User $user) {
              app(UserScalingService::class)->invalidateUserCache($user);
          });
          
          // Configure read/write connections for database scaling
          if (config('database.use_read_write_connections', false)) {
              $this->configureReadWriteConnections();
          }
      }
      
      /**
       * Configure read/write database connections.
       *
       * @return void
       */
      protected function configureReadWriteConnections(): void
      {
          // Set up read/write connections for the main database
          config([
              'database.connections.mysql.read' => [
                  'host' => [
                      env('DB_READ_HOST_1', env('DB_HOST', '127.0.0.1')),
                      env('DB_READ_HOST_2', env('DB_HOST', '127.0.0.1')),
                  ],
                  'username' => env('DB_READ_USERNAME', env('DB_USERNAME', 'forge')),
                  'password' => env('DB_READ_PASSWORD', env('DB_PASSWORD', '')),
              ],
              'database.connections.mysql.write' => [
                  'host' => env('DB_WRITE_HOST', env('DB_HOST', '127.0.0.1')),
                  'username' => env('DB_WRITE_USERNAME', env('DB_USERNAME', 'forge')),
                  'password' => env('DB_WRITE_PASSWORD', env('DB_PASSWORD', '')),
              ],
              'database.connections.mysql.sticky' => true,
          ]);
          
          // Set up read/write connections for each shard
          $shardCount = config('database.shards.count', 1);
          
          for ($i = 0; $i < $shardCount; $i++) {
              config([
                  "database.connections.mysql_shard_{$i}.read" => [
                      'host' => [
                          env("DB_SHARD_{$i}_READ_HOST_1", env('DB_HOST', '127.0.0.1')),
                          env("DB_SHARD_{$i}_READ_HOST_2", env('DB_HOST', '127.0.0.1')),
                      ],
                      'username' => env("DB_SHARD_{$i}_READ_USERNAME", env('DB_USERNAME', 'forge')),
                      'password' => env("DB_SHARD_{$i}_READ_PASSWORD", env('DB_PASSWORD', '')),
                  ],
                  "database.connections.mysql_shard_{$i}.write" => [
                      'host' => env("DB_SHARD_{$i}_WRITE_HOST", env('DB_HOST', '127.0.0.1')),
                      'username' => env("DB_SHARD_{$i}_WRITE_USERNAME", env('DB_USERNAME', 'forge')),
                      'password' => env("DB_SHARD_{$i}_WRITE_PASSWORD", env('DB_PASSWORD', '')),
                  ],
                  "database.connections.mysql_shard_{$i}.sticky" => true,
              ]);
          }
      }
  }
explanation: |
  This example demonstrates strategies for scaling user model enhancements in Laravel applications:
  
  1. **Caching Strategies**:
     - Efficient user data caching with TTL (Time To Live)
     - Relationship caching with eager loading
     - Search result caching for frequently accessed data
     - Cache invalidation when data changes
     - Pattern-based cache clearing for related entries
  
  2. **Database Sharding**:
     - User data distribution across multiple database shards
     - Shard selection based on user ID
     - Cross-shard operations for searching and aggregation
     - Maintaining connection information with results
  
  3. **Read/Write Splitting**:
     - Configuration of separate read and write database connections
     - Multiple read replicas for load balancing
     - Sticky sessions for consistent reads after writes
     - Environment-based configuration for different environments
  
  4. **Performance Monitoring**:
     - Query logging and analysis
     - Slow query detection and reporting
     - Database connection management
  
  5. **Aggregation and Statistics**:
     - Efficient counting and aggregation with caching
     - Cross-shard statistics collection
     - Type and role distribution analysis
  
  Key scaling principles demonstrated:
  
  - **Horizontal Scaling**: Adding more servers rather than upgrading existing ones
  - **Vertical Partitioning**: Splitting different types of data across different databases
  - **Horizontal Partitioning**: Sharding data of the same type across multiple databases
  - **Caching**: Reducing database load by caching frequently accessed data
  - **Read/Write Splitting**: Optimizing for read-heavy workloads
  - **Eager Loading**: Reducing N+1 query problems
  - **Query Optimization**: Monitoring and improving slow queries
  
  In a real Laravel application:
  - You would implement more sophisticated sharding strategies
  - You would add distributed caching with Redis Cluster
  - You would implement connection pooling for database connections
  - You would add circuit breakers for database failover
  - You would implement more comprehensive monitoring and alerting
challenges:
  - Implement a more sophisticated sharding strategy based on user geography
  - Add support for cross-shard transactions using the two-phase commit protocol
  - Implement a distributed cache using Redis Cluster
  - Create a dashboard for monitoring database performance across shards
  - Implement automatic failover for database connections
:::
