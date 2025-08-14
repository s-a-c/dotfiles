# Caching Strategies for UME

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Overview

Effective caching is essential for optimizing the performance of your User Model Enhancements (UME) implementation. This guide covers various caching strategies specifically tailored for UME features, helping you reduce database load, improve response times, and enhance the overall user experience.

## Table of Contents

1. [Caching Fundamentals](#caching-fundamentals)
2. [Laravel's Caching System](#laravels-caching-system)
3. [Model Caching](#model-caching)
4. [Permission Caching](#permission-caching)
5. [Query Result Caching](#query-result-caching)
6. [View Caching](#view-caching)
7. [API Response Caching](#api-response-caching)
8. [Cache Invalidation Strategies](#cache-invalidation-strategies)
9. [Monitoring Cache Performance](#monitoring-cache-performance)
10. [Caching Best Practices](#caching-best-practices)

## Caching Fundamentals

### What to Cache

In UME applications, consider caching:

1. **User data**: Frequently accessed user profiles, settings, and preferences
2. **Team data**: Team memberships, hierarchies, and settings
3. **Permissions**: User and role permissions
4. **Configuration**: Application settings and feature flags
5. **Computed data**: Results of complex calculations or aggregations

### When to Cache

Cache data that is:

1. **Expensive to compute**: Complex queries or calculations
2. **Frequently accessed**: High-traffic parts of your application
3. **Relatively static**: Data that doesn't change often
4. **Non-critical for real-time accuracy**: Data where slight staleness is acceptable

## Laravel's Caching System

Laravel provides a unified API for various caching backends:

```php
// Configure cache in config/cache.php
return [
    'default' => env('CACHE_DRIVER', 'redis'),
    'stores' => [
        'redis' => [
            'driver' => 'redis',
            'connection' => 'cache',
            'lock_connection' => 'default',
        ],
        // Other cache stores...
    ],
];
```

### Basic Cache Operations

```php
// Store an item in the cache for 60 minutes
Cache::put('key', 'value', 60 * 60);

// Retrieve an item from the cache
$value = Cache::get('key');

// Store an item forever
Cache::forever('key', 'value');

// Remove an item from the cache
Cache::forget('key');

// Clear the entire cache
Cache::flush();
```

### Cache Tags

For UME, use cache tags to organize and manage related cache items:

```php
// Store using tags
Cache::tags(['users', 'team:'.$teamId])->put('user:'.$userId, $userData, 3600);

// Retrieve using tags
$userData = Cache::tags(['users', 'team:'.$teamId])->get('user:'.$userId);

// Flush all user-related cache
Cache::tags(['users'])->flush();

// Flush all cache for a specific team
Cache::tags(['team:'.$teamId])->flush();
```

> **Note**: Not all cache drivers support tagging. Redis is recommended for UME applications.

## Model Caching

### Caching Individual Models

```php
// Cache a user model
$user = Cache::remember('user:'.$userId, 3600, function () use ($userId) {
    return User::find($userId);
});

// Cache a team model with its relationships
$team = Cache::remember('team:'.$teamId, 3600, function () use ($teamId) {
    return Team::with(['owner', 'members'])->find($teamId);
});
```

### Using Model Events for Cache Invalidation

```php
// In your User model
protected static function booted()
{
    static::updated(function ($user) {
        Cache::forget('user:'.$user->id);
        Cache::tags(['team:'.$user->team_id])->flush();
    });
    
    static::deleted(function ($user) {
        Cache::forget('user:'.$user->id);
        Cache::tags(['team:'.$user->team_id])->flush();
    });
}
```

### Implementing a Caching Repository Pattern

```php
class CachedUserRepository implements UserRepositoryInterface
{
    protected $repository;
    
    public function __construct(UserRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }
    
    public function find($id)
    {
        return Cache::remember('user:'.$id, 3600, function () use ($id) {
            return $this->repository->find($id);
        });
    }
    
    public function update($id, array $data)
    {
        $result = $this->repository->update($id, $data);
        Cache::forget('user:'.$id);
        return $result;
    }
    
    // Other repository methods...
}
```

## Permission Caching

The Spatie Permission package used in UME already includes caching. Configure it in `config/permission.php`:

```php
'cache' => [
    // Cache expiration time (24 hours by default)
    'expiration_time' => \DateInterval::createFromDateString('24 hours'),
    
    // Cache key
    'key' => 'spatie.permission.cache',
    
    // Cache store (uses the default cache store if not specified)
    'store' => 'redis',
],
```

### Custom Permission Caching

For complex permission scenarios, implement additional caching:

```php
class PermissionCacheService
{
    public function getUserPermissions($userId)
    {
        return Cache::remember('user_permissions:'.$userId, 3600, function () use ($userId) {
            $user = User::find($userId);
            return [
                'direct' => $user->getDirectPermissions()->pluck('name'),
                'role' => $user->getPermissionsViaRoles()->pluck('name'),
                'team' => $this->getTeamPermissions($user),
            ];
        });
    }
    
    public function clearUserPermissionCache($userId)
    {
        Cache::forget('user_permissions:'.$userId);
    }
    
    protected function getTeamPermissions($user)
    {
        // Calculate team-based permissions
    }
}
```

## Query Result Caching

### Caching Complex Queries

```php
// Cache team members with their roles
$teamMembers = Cache::remember('team:'.$teamId.':members', 3600, function () use ($teamId) {
    return Team::find($teamId)
        ->users()
        ->with(['roles', 'profile'])
        ->get();
});

// Cache user activity
$userActivity = Cache::remember('user:'.$userId.':activity', 1800, function () use ($userId) {
    return Activity::where('causer_id', $userId)
        ->where('causer_type', User::class)
        ->latest()
        ->take(20)
        ->get();
});
```

### Caching Aggregations and Statistics

```php
// Cache team statistics
$teamStats = Cache::remember('team:'.$teamId.':stats', 3600, function () use ($teamId) {
    return [
        'member_count' => Team::find($teamId)->users()->count(),
        'active_members' => Team::find($teamId)->users()->where('status', 'active')->count(),
        'admin_count' => Team::find($teamId)->users()->whereHas('roles', function ($q) {
            $q->where('name', 'admin');
        })->count(),
    ];
});
```

## View Caching

### Fragment Caching

For UME components that don't change frequently:

```php
@if (Cache::has('team_members_'.$team->id))
    {!! Cache::get('team_members_'.$team->id) !!}
@else
    @php
        $view = view('teams.members', ['team' => $team])->render();
        Cache::put('team_members_'.$team->id, $view, 3600);
    @endphp
    {!! $view !!}
@endif
```

### Using the `@cache` Directive

With a custom cache directive:

```php
// In AppServiceProvider
Blade::directive('cache', function ($expression) {
    return "<?php if (Cache::has({$expression})) { 
        echo Cache::get({$expression}); 
    } else { 
        \$__cache_key = {$expression}; 
        ob_start(); ?>";
});

Blade::directive('endcache', function ($expression) {
    return "<?php \$__cache_content = ob_get_clean(); 
        echo \$__cache_content; 
        Cache::put(\$__cache_key, \$__cache_content, {$expression}); 
    } ?>";
});
```

Then in your Blade templates:

```blade
@cache('user_profile_'.$user->id)
    <div class="user-profile">
        <!-- Complex user profile rendering -->
    </div>
@endcache(3600)
```

## API Response Caching

### HTTP Cache Headers

```php
// In a controller
public function show(User $user)
{
    return response()->json([
        'data' => new UserResource($user)
    ])->header('Cache-Control', 'public, max-age=3600');
}
```

### API Resource Caching

```php
class UserResource extends JsonResource
{
    public function toArray($request)
    {
        $cacheKey = 'user_resource_'.$this->id;
        
        return Cache::remember($cacheKey, 3600, function () {
            return [
                'id' => $this->id,
                'name' => $this->name,
                'email' => $this->email,
                'type' => $this->type,
                'team' => new TeamResource($this->team),
                'permissions' => $this->getAllPermissions()->pluck('name'),
                // Other user data...
            ];
        });
    }
}
```

## Cache Invalidation Strategies

### Time-Based Invalidation

The simplest approach is to set an appropriate TTL (Time To Live):

```php
// Cache for 1 hour
Cache::put('key', 'value', 3600);
```

### Event-Based Invalidation

Invalidate cache when data changes:

```php
// In a model observer
public function updated(User $user)
{
    Cache::forget('user:'.$user->id);
    Cache::forget('user_permissions:'.$user->id);
    Cache::forget('team_members:'.$user->team_id);
}
```

### Bulk Invalidation with Tags

```php
// When a team is updated
public function updated(Team $team)
{
    Cache::tags(['team:'.$team->id])->flush();
}

// When permissions change
public function permissionsChanged()
{
    Cache::tags(['permissions'])->flush();
}
```

### Version-Based Invalidation

```php
// Increment version when data changes
Cache::increment('user_version:'.$userId);

// Use version in cache key
$version = Cache::get('user_version:'.$userId, 1);
$userData = Cache::remember('user:'.$userId.':v'.$version, 3600, function () use ($userId) {
    return User::find($userId);
});
```

## Monitoring Cache Performance

### Cache Hit Rate

```php
// In a middleware or service provider
$hits = Cache::get('cache_hits', 0);
$misses = Cache::get('cache_misses', 0);

if (Cache::has($key)) {
    Cache::increment('cache_hits');
} else {
    Cache::increment('cache_misses');
}

$hitRate = $hits / ($hits + $misses);
```

### Using Laravel Telescope

Laravel Telescope provides insights into cache operations:

```php
// In config/telescope.php
'watchers' => [
    Telescope\Watchers\CacheWatcher::class => [
        'enabled' => env('TELESCOPE_CACHE_WATCHER', true),
    ],
],
```

### Redis Cache Monitoring

For Redis cache, use the Redis CLI:

```bash
# Get cache statistics
redis-cli info

# Monitor cache operations in real-time
redis-cli monitor
```

## Caching Best Practices

1. **Cache Selectively**: Not everything needs to be cached. Focus on performance bottlenecks.

2. **Set Appropriate TTLs**: Balance freshness with performance:
   - User profiles: 30-60 minutes
   - Team memberships: 15-30 minutes
   - Permissions: 1-24 hours (depending on how frequently they change)
   - UI components: 1-6 hours
   - Application settings: 1-12 hours

3. **Use Cache Tags**: Organize cache entries for easier management.

4. **Implement Graceful Degradation**: Handle cache failures gracefully:
   ```php
   try {
       $value = Cache::get('key');
   } catch (\Exception $e) {
       Log::error('Cache error: '.$e->getMessage());
       $value = $this->computeValueFromDatabase();
   }
   ```

5. **Warm the Cache**: Pre-populate cache for critical data:
   ```php
   // In a scheduled command
   public function handle()
   {
       User::chunk(100, function ($users) {
           foreach ($users as $user) {
               Cache::put('user:'.$user->id, $user, 3600);
               Cache::put('user_permissions:'.$user->id, $user->getAllPermissions(), 3600);
           }
       });
   }
   ```

6. **Consider Cache Stampedes**: Prevent multiple processes from regenerating the same cache:
   ```php
   $value = Cache::remember('key', 3600, function () {
       sleep(5); // Simulate expensive operation
       return 'computed value';
   });
   ```

7. **Use Different Cache Stores**: Match the cache store to the data type:
   - Redis: For complex data structures and when you need atomic operations
   - Memcached: For simple key-value pairs with high throughput
   - File: For development or when other options aren't available

## Conclusion

Effective caching is a powerful way to improve the performance of your UME implementation. By strategically caching user data, permissions, query results, and UI components, you can significantly reduce database load and improve response times.

Remember that caching introduces complexity and potential for stale data. Always balance performance gains against the need for data freshness, and implement proper cache invalidation strategies.

## Next Steps

- [Database Optimization](./060-database-optimization.md)
- [Scaling Considerations](./070-scaling-considerations.md)
- [Performance Optimization Guide](./040-performance-optimization.md)
