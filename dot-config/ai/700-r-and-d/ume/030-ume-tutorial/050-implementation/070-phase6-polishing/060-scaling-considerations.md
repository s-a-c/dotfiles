# Scaling Considerations for UME

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Overview

As your application grows, scaling becomes a critical consideration. This guide explores strategies for scaling your User Model Enhancements (UME) implementation to handle increasing loads, larger user bases, and more complex team structures. We'll cover both vertical and horizontal scaling approaches, with specific considerations for UME's unique features.

## Table of Contents

1. [Understanding Scaling Challenges](#understanding-scaling-challenges)
2. [Vertical Scaling Strategies](#vertical-scaling-strategies)
3. [Horizontal Scaling Strategies](#horizontal-scaling-strategies)
4. [Database Scaling](#database-scaling)
5. [Caching Infrastructure](#caching-infrastructure)
6. [Queue and Background Processing](#queue-and-background-processing)
7. [Real-time Features Scaling](#real-time-features-scaling)
8. [Monitoring and Autoscaling](#monitoring-and-autoscaling)
9. [Multi-tenancy Considerations](#multi-tenancy-considerations)
10. [Scaling Roadmap](#scaling-roadmap)

## Understanding Scaling Challenges

UME implementations face specific scaling challenges:

1. **Complex Permission Checks**: Permission evaluations can become expensive at scale
2. **Deep Relationship Chains**: Team hierarchies and nested relationships add query complexity
3. **Real-time Features**: WebSocket connections and broadcasts require special scaling considerations
4. **User Type Polymorphism**: Single Table Inheritance adds complexity to queries
5. **Audit Trail and Activity Logging**: Can generate significant database write load

### Identifying Bottlenecks

Before scaling, identify your bottlenecks:

```php
// Add performance monitoring to key operations
$startTime = microtime(true);
$result = $this->performOperation();
$endTime = microtime(true);
Log::info('Operation time: ' . ($endTime - $startTime) . ' seconds');
```

Use Laravel Telescope or Horizon to monitor:
- Database query counts and times
- Cache hit/miss ratios
- Queue processing times
- Memory usage patterns

## Vertical Scaling Strategies

Vertical scaling (scaling up) involves adding more resources to your existing servers.

### PHP Configuration Optimization

```ini
; php.ini optimizations
memory_limit = 512M
max_execution_time = 60
opcache.enable = 1
opcache.memory_consumption = 128
opcache.interned_strings_buffer = 16
opcache.max_accelerated_files = 10000
opcache.revalidate_freq = 0
opcache.validate_timestamps = 0
```

### Web Server Optimization

For Nginx:

```nginx
# nginx.conf optimizations
worker_processes auto;
worker_rlimit_nofile 65535;
events {
    worker_connections 4096;
    multi_accept on;
    use epoll;
}
http {
    keepalive_timeout 65;
    keepalive_requests 100000;
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    gzip on;
    gzip_comp_level 5;
    gzip_min_length 256;
    gzip_types application/json application/xml text/plain text/css application/javascript;
    open_file_cache max=1000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;
}
```

### Database Server Optimization

For MySQL:

```ini
# my.cnf optimizations
innodb_buffer_pool_size = 4G
innodb_log_file_size = 512M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT
innodb_file_per_table = 1
max_connections = 500
```

### Laravel Octane

Consider using Laravel Octane with Swoole or RoadRunner for significant performance improvements:

```bash
# Install Octane
composer require 100-laravel/octane

# Install Swoole
pecl install swoole

# Publish Octane configuration
php artisan octane:install

# Start Octane server
php artisan octane:start --workers=4 --task-workers=2
```

Configure Octane for UME:

```php
// config/octane.php
return [
    'server' => env('OCTANE_SERVER', 'swoole'),
    'workers' => env('OCTANE_WORKERS', 4),
    'task_workers' => env('OCTANE_TASK_WORKERS', 2),
    'max_requests' => env('OCTANE_MAX_REQUESTS', 1000),
    'warm' => [
        // Classes to pre-resolve in the container
        \App\Models\User::class,
        \App\Models\Team::class,
        \App\Services\PermissionService::class,
    ],
];
```

## Horizontal Scaling Strategies

Horizontal scaling (scaling out) involves adding more servers to distribute the load.

### Stateless Application Design

Ensure your UME implementation is stateless:

1. **Use Redis or Database Sessions**: Don't store sessions in files
   ```php
   // config/session.php
   'driver' => env('SESSION_DRIVER', 'redis'),
   ```

2. **Centralize File Storage**: Use S3 or another distributed file system
   ```php
   // config/filesystems.php
   'default' => env('FILESYSTEM_DISK', 's3'),
   ```

3. **Use Queues for Background Processing**: Don't process heavy tasks in web requests
   ```php
   // In a controller
   public function processImport()
   {
       ImportTeamMembersJob::dispatch($this->team);
       return back()->with('status', 'Import started');
   }
   ```

### Load Balancing

Configure load balancing for your web servers:

```nginx
# Example Nginx load balancer configuration
upstream ume_app {
    server app1.example.com weight=3;
    server app2.example.com weight=3;
    server app3.example.com weight=3;
    server backup.example.com backup;
    
    keepalive 64;
}

server {
    listen 80;
    server_name app.example.com;
    
    location / {
        proxy_pass http://ume_app;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Container Orchestration

Use Kubernetes for container orchestration:

```yaml
# Example Kubernetes deployment for UME
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ume-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ume-app
  template:
    metadata:
      labels:
        app: ume-app
    spec:
      containers:
      - name: ume-app
        image: your-registry/ume-app:latest
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: "1"
            memory: "1Gi"
          requests:
            cpu: "500m"
            memory: "512Mi"
        env:
        - name: DB_HOST
          value: mysql-service
        - name: REDIS_HOST
          value: redis-service
        - name: CACHE_DRIVER
          value: redis
        - name: SESSION_DRIVER
          value: redis
        - name: QUEUE_CONNECTION
          value: redis
```

## Database Scaling

### Read Replicas

Configure database read replicas:

```php
// config/database.php
'mysql' => [
    'read' => [
        'host' => [
            env('DB_HOST_READ_1', '127.0.0.1'),
            env('DB_HOST_READ_2', '127.0.0.1'),
        ],
    ],
    'write' => [
        'host' => env('DB_HOST_WRITE', '127.0.0.1'),
    ],
    // Other configuration...
],
```

Use read/write separation in your code:

```php
// For read operations
$users = DB::connection('mysql.read')->select('SELECT * FROM users WHERE team_id = ?', [$teamId]);

// For write operations
DB::connection('mysql.write')->insert('INSERT INTO activities (log_name, description) VALUES (?, ?)', ['default', 'User logged in']);
```

### Database Sharding

For very large applications, implement database sharding:

```php
// Example sharding by team_id
class TeamShardingService
{
    public function getConnectionForTeam($teamId)
    {
        // Simple modulo-based sharding
        $shardNumber = $teamId % 5; // 5 shards
        return "mysql.shard{$shardNumber}";
    }
}

// In your Team model
public function getConnection()
{
    return app(TeamShardingService::class)->getConnectionForTeam($this->id);
}
```

Configure multiple database connections:

```php
// config/database.php
'connections' => [
    'mysql.shard0' => [
        'driver' => 'mysql',
        'host' => env('DB_HOST_SHARD0', '127.0.0.1'),
        // Other configuration...
    ],
    'mysql.shard1' => [
        'driver' => 'mysql',
        'host' => env('DB_HOST_SHARD1', '127.0.0.1'),
        // Other configuration...
    ],
    // More shards...
],
```

## Caching Infrastructure

### Distributed Caching

Configure Redis for distributed caching:

```php
// config/cache.php
'redis' => [
    'client' => env('REDIS_CLIENT', 'phpredis'),
    'options' => [
        'cluster' => env('REDIS_CLUSTER', 'redis'),
        'prefix' => env('REDIS_PREFIX', 'ume_cache:'),
    ],
    'default' => [
        'url' => env('REDIS_URL'),
        'host' => env('REDIS_HOST', '127.0.0.1'),
        'password' => env('REDIS_PASSWORD'),
        'port' => env('REDIS_PORT', '6379'),
        'database' => env('REDIS_CACHE_DB', '1'),
        'read_write_timeout' => 60,
    ],
],
```

### Redis Cluster

For high-volume applications, use Redis Cluster:

```php
// config/database.php
'redis' => [
    'client' => 'phpredis',
    'options' => [
        'cluster' => 'redis',
        'prefix' => env('REDIS_PREFIX', 'ume_database_'),
    ],
    'clusters' => [
        'default' => [
            [
                'host' => env('REDIS_HOST', '127.0.0.1'),
                'password' => env('REDIS_PASSWORD'),
                'port' => env('REDIS_PORT', 6379),
                'database' => 0,
            ],
            [
                'host' => env('REDIS_HOST_2', '127.0.0.1'),
                'password' => env('REDIS_PASSWORD'),
                'port' => env('REDIS_PORT', 6379),
                'database' => 0,
            ],
            // More nodes...
        ],
    ],
],
```

### Implement Cache Segmentation

Segment your cache to prevent cache stampedes and improve hit rates:

```php
// Cache segmentation by team
$teamCache = Cache::tags(['team:'.$teamId]);
$teamCache->put('members', $teamMembers, 3600);

// Cache segmentation by user type
$adminCache = Cache::tags(['user-type:admin']);
$adminCache->put('permissions', $adminPermissions, 3600);
```

## Queue and Background Processing

### Scaling Laravel Horizon

Configure Laravel Horizon for queue processing at scale:

```php
// config/horizon.php
'environments' => [
    'production' => [
        'supervisor-1' => [
            'connection' => 'redis',
            'queue' => ['default'],
            'balance' => 'auto',
            'processes' => 10,
            'tries' => 3,
        ],
        'supervisor-2' => [
            'connection' => 'redis',
            'queue' => ['emails', 'notifications'],
            'balance' => 'auto',
            'processes' => 5,
            'tries' => 3,
        ],
        'supervisor-3' => [
            'connection' => 'redis',
            'queue' => ['processing', 'imports'],
            'balance' => 'auto',
            'processes' => 3,
            'tries' => 1,
        ],
    ],
],
```

### Job Batching

Use job batching for large operations:

```php
// In a controller
public function importUsers(Request $request)
{
    $batch = Bus::batch([
        new ImportUsersJob($request->file('csv')),
        new NotifyAdminsJob('User import started'),
        new UpdateTeamStatisticsJob(),
    ])->then(function (Batch $batch) {
        // All jobs completed successfully...
    })->catch(function (Batch $batch, Throwable $e) {
        // A job within the batch failed...
    })->finally(function (Batch $batch) {
        // The batch has finished executing...
    })->dispatch();
    
    return $batch->id;
}
```

### Queue Monitoring

Implement queue monitoring with Horizon:

```php
// In a service provider
Horizon::auth(function ($request) {
    return app()->environment('local') || 
           $request->user() && $request->user()->hasRole('admin');
});

Horizon::night(); // Enable dark mode

Horizon::routeMailNotificationsTo('admin@example.com');
Horizon::routeSlackNotificationsTo('slack-webhook-url', '#horizon-notifications');
```

## Real-time Features Scaling

### Scaling WebSockets with Laravel Reverb

Configure Laravel Reverb for WebSocket scaling:

```php
// config/reverb.php
return [
    'host' => env('REVERB_SERVER_HOST', '0.0.0.0'),
    'port' => env('REVERB_SERVER_PORT', 8080),
    'hostname' => env('REVERB_SERVER_HOSTNAME', null),
    'tls' => [
        'cert' => env('REVERB_SERVER_CERT'),
        'key' => env('REVERB_SERVER_KEY'),
    ],
    'options' => [
        'max_connections' => env('REVERB_MAX_CONNECTIONS', 1000),
        'max_connection_lifetime' => env('REVERB_MAX_CONNECTION_LIFETIME', 0),
    ],
    'scaling' => [
        'enabled' => env('REVERB_SCALING_ENABLED', false),
        'redis' => [
            'connection' => env('REVERB_SCALING_CONNECTION', 'default'),
            'prefix' => env('REVERB_SCALING_PREFIX', 'reverb:'),
        ],
    ],
];
```

### Implementing Presence Channels Efficiently

Optimize presence channel implementation:

```php
// In routes/channels.php
Broadcast::channel('team.{teamId}', function ($user, $teamId) {
    if ($user->belongsToTeam($teamId)) {
        // Return minimal user data to reduce payload size
        return [
            'id' => $user->id,
            'name' => $user->name,
            'type' => $user->type,
        ];
    }
});
```

### Scaling Broadcast Events

Use event broadcasting with Redis for scalability:

```php
// config/broadcasting.php
'redis' => [
    'driver' => 'redis',
    'connection' => 'default',
    'queue' => 'broadcasts',
],
```

Optimize broadcast payloads:

```php
class TeamMemberAdded implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $teamId;
    public $member;

    public function __construct($teamId, $member)
    {
        $this->teamId = $teamId;
        
        // Only include necessary fields to reduce payload size
        $this->member = [
            'id' => $member->id,
            'name' => $member->name,
            'role' => $member->pivot->role,
        ];
    }

    public function broadcastOn()
    {
        return new PrivateChannel('team.'.$this->teamId);
    }
}
```

## Monitoring and Autoscaling

### Application Monitoring

Implement comprehensive monitoring:

```php
// Using Laravel Pulse
// config/pulse.php
'recorders' => [
    Pulse\Recorders\UserRecorder::class => [
        'sample_rate' => 1,
    ],
    Pulse\Recorders\QueryRecorder::class => [
        'sample_rate' => 1,
        'slow_threshold' => 500, // ms
    ],
    Pulse\Recorders\ExceptionRecorder::class => [
        'sample_rate' => 1,
    ],
    Pulse\Recorders\CacheRecorder::class => [
        'sample_rate' => 1,
    ],
],
```

### Custom Metrics for UME

Implement custom metrics for UME-specific features:

```php
// In a service provider
public function boot()
{
    // Track permission check performance
    DB::listen(function ($query) {
        if (str_contains($query->sql, 'model_has_permissions')) {
            Pulse::record('ume.permission_check', [
                'time' => $query->time,
                'sql' => $query->sql,
            ]);
        }
    });
    
    // Track team member count
    Event::listen(TeamMemberAdded::class, function ($event) {
        Pulse::record('ume.team_size', [
            'team_id' => $event->teamId,
            'count' => Team::find($event->teamId)->users()->count(),
        ]);
    });
}
```

### Autoscaling Configuration

Example AWS autoscaling configuration:

```json
{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Resources": {
    "UMEAppAutoScalingGroup": {
      "Type": "AWS::AutoScaling::AutoScalingGroup",
      "Properties": {
        "AvailabilityZones": ["us-east-1a", "us-east-1b", "us-east-1c"],
        "LaunchConfigurationName": { "Ref": "UMEAppLaunchConfig" },
        "MinSize": "2",
        "MaxSize": "10",
        "DesiredCapacity": "2",
        "HealthCheckType": "ELB",
        "HealthCheckGracePeriod": 300,
        "TargetGroupARNs": [{ "Ref": "UMEAppTargetGroup" }]
      }
    },
    "UMEAppScaleUpPolicy": {
      "Type": "AWS::AutoScaling::ScalingPolicy",
      "Properties": {
        "AdjustmentType": "ChangeInCapacity",
        "AutoScalingGroupName": { "Ref": "UMEAppAutoScalingGroup" },
        "Cooldown": "60",
        "ScalingAdjustment": "1"
      }
    },
    "UMEAppHighCPUAlarm": {
      "Type": "AWS::CloudWatch::Alarm",
      "Properties": {
        "AlarmDescription": "Scale up if CPU > 70% for 2 minutes",
        "MetricName": "CPUUtilization",
        "Namespace": "AWS/EC2",
        "Statistic": "Average",
        "Period": "60",
        "EvaluationPeriods": "2",
        "Threshold": "70",
        "AlarmActions": [{ "Ref": "UMEAppScaleUpPolicy" }],
        "Dimensions": [
          {
            "Name": "AutoScalingGroupName",
            "Value": { "Ref": "UMEAppAutoScalingGroup" }
          }
        ],
        "ComparisonOperator": "GreaterThanThreshold"
      }
    }
  }
}
```

## Multi-tenancy Considerations

### Single Database Multi-tenancy

For multi-tenant UME applications with a single database:

```php
// Global scope for team isolation
class TeamScope implements Scope
{
    public function apply(Builder $builder, Model $model)
    {
        if (auth()->check()) {
            $builder->where('team_id', auth()->user()->current_team_id);
        }
    }
}

// In your model
protected static function booted()
{
    static::addGlobalScope(new TeamScope);
}
```

### Database Separation Multi-tenancy

For multi-tenant UME applications with separate databases:

```php
// In a middleware
public function handle($request, Closure $next)
{
    $tenant = $this->resolveTenant($request);
    
    if ($tenant) {
        // Switch to tenant database
        config([
            'database.connections.tenant.database' => "tenant_{$tenant->id}",
        ]);
        
        DB::purge('tenant');
        DB::reconnect('tenant');
        
        // Set tenant in session
        session(['tenant_id' => $tenant->id]);
    }
    
    return $next($request);
}
```

## Scaling Roadmap

As your UME application grows, follow this scaling roadmap:

### Phase 1: Optimization (1,000+ users)

1. Implement caching for permissions and frequently accessed data
2. Optimize database queries and add proper indexes
3. Configure queue workers for background processing
4. Implement basic monitoring with Laravel Telescope

### Phase 2: Vertical Scaling (5,000+ users)

1. Upgrade server resources (CPU, memory)
2. Implement Laravel Octane with Swoole
3. Optimize PHP and web server configurations
4. Implement Redis for caching and sessions

### Phase 3: Horizontal Scaling (10,000+ users)

1. Implement load balancing across multiple web servers
2. Configure database read replicas
3. Set up Redis Cluster for distributed caching
4. Scale Laravel Horizon for queue processing

### Phase 4: Advanced Scaling (50,000+ users)

1. Implement database sharding
2. Deploy microservices for specific features
3. Implement advanced monitoring and autoscaling
4. Optimize for global distribution with CDNs and edge caching

### Phase 5: Enterprise Scaling (100,000+ users)

1. Implement multi-region deployment
2. Set up disaster recovery procedures
3. Implement advanced security measures
4. Optimize for regulatory compliance

## Conclusion

Scaling a UME implementation requires careful planning and a phased approach. Start with optimization and vertical scaling before moving to more complex horizontal scaling strategies. Monitor your application's performance at each stage and adjust your scaling strategy based on real-world usage patterns.

Remember that scaling is not just about handling more users—it's about maintaining performance, reliability, and user experience as your application grows.

## Next Steps

- [Performance Optimization Guide](./040-performance-optimization.md)
- [Caching Strategies](./050-caching-strategies.md)
- [Database Optimization](./060-database-optimization.md)
