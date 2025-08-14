# API Rate Limiting

:::interactive-code
title: Implementing Advanced API Rate Limiting
description: This example demonstrates how to implement a comprehensive API rate limiting system with different strategies, user-specific limits, and dynamic adjustments.
language: php
editable: true
code: |
  <?php
  
  namespace App\Http\Middleware;
  
  use App\Models\User;
  use App\Services\RateLimitService;
  use Closure;
  use Illuminate\Http\Request;
  use Illuminate\Support\Facades\Auth;
  use Illuminate\Support\Facades\RateLimiter;
  use Symfony\Component\HttpFoundation\Response;
  
  class CustomRateLimiter
  {
      protected $rateLimitService;
      
      public function __construct(RateLimitService $rateLimitService)
      {
          $this->rateLimitService = $rateLimitService;
      }
      
      /**
       * Handle an incoming request.
       *
       * @param  \Illuminate\Http\Request  $request
       * @param  \Closure  $next
       * @param  string  $limiterType
       * @return mixed
       */
      public function handle(Request $request, Closure $next, string $limiterType = 'default')
      {
          // Get the appropriate limiter configuration
          $limiterConfig = $this->getLimiterConfig($request, $limiterType);
          
          // Get the key for rate limiting
          $key = $this->resolveRequestSignature($request, $limiterConfig);
          
          // Check if the request should be rate limited
          $maxAttempts = $limiterConfig['maxAttempts'];
          $decaySeconds = $limiterConfig['decaySeconds'];
          
          // Execute rate limiting logic
          $executed = RateLimiter::attempt(
              $key,
              $maxAttempts,
              function() {
                  // This closure is executed if the request is allowed
                  return true;
              },
              $decaySeconds
          );
          
          if (!$executed) {
              // Log the rate limit hit
              $this->rateLimitService->logRateLimitHit($request, $limiterType);
              
              // Return rate limit exceeded response
              return $this->buildRateLimitExceededResponse($request, $key, $maxAttempts, $decaySeconds);
          }
          
          // Add rate limit headers to the response
          $response = $next($request);
          
          return $this->addRateLimitHeaders(
              $response, 
              $key, 
              $maxAttempts
          );
      }
      
      /**
       * Get the rate limiter configuration based on the request and limiter type.
       *
       * @param  \Illuminate\Http\Request  $request
       * @param  string  $limiterType
       * @return array
       */
      protected function getLimiterConfig(Request $request, string $limiterType): array
      {
          // Get the authenticated user if available
          $user = $request->user();
          
          // Get the base configuration for the limiter type
          $config = $this->rateLimitService->getLimiterConfig($limiterType);
          
          // Apply user-specific adjustments if a user is authenticated
          if ($user) {
              $config = $this->applyUserSpecificLimits($user, $config, $limiterType);
          }
          
          // Apply dynamic adjustments based on system load or other factors
          $config = $this->applyDynamicAdjustments($config, $limiterType);
          
          return $config;
      }
      
      /**
       * Apply user-specific rate limit adjustments.
       *
       * @param  \App\Models\User  $user
       * @param  array  $config
       * @param  string  $limiterType
       * @return array
       */
      protected function applyUserSpecificLimits(User $user, array $config, string $limiterType): array
      {
          // Get user-specific rate limit settings
          $userLimits = $this->rateLimitService->getUserRateLimits($user, $limiterType);
          
          // Apply user-specific limits if they exist
          if ($userLimits) {
              $config['maxAttempts'] = $userLimits['maxAttempts'] ?? $config['maxAttempts'];
              $config['decaySeconds'] = $userLimits['decaySeconds'] ?? $config['decaySeconds'];
          }
          
          // Apply subscription tier adjustments
          if ($user->subscription) {
              $tierMultiplier = $this->rateLimitService->getSubscriptionTierMultiplier($user->subscription->tier);
              $config['maxAttempts'] = (int) ($config['maxAttempts'] * $tierMultiplier);
          }
          
          return $config;
      }
      
      /**
       * Apply dynamic adjustments to rate limits based on system conditions.
       *
       * @param  array  $config
       * @param  string  $limiterType
       * @return array
       */
      protected function applyDynamicAdjustments(array $config, string $limiterType): array
      {
          // Get system load factor (1.0 = normal, < 1.0 = reduce limits, > 1.0 = increase limits)
          $loadFactor = $this->rateLimitService->getSystemLoadFactor();
          
          // Apply load factor to max attempts
          if ($loadFactor < 1.0) {
              $config['maxAttempts'] = (int) ($config['maxAttempts'] * $loadFactor);
              // Ensure at least 1 attempt is allowed
              $config['maxAttempts'] = max(1, $config['maxAttempts']);
          } elseif ($loadFactor > 1.0 && $limiterType !== 'critical') {
              // Only increase non-critical limits
              $config['maxAttempts'] = (int) ($config['maxAttempts'] * $loadFactor);
          }
          
          return $config;
      }
      
      /**
       * Resolve the request signature for rate limiting.
       *
       * @param  \Illuminate\Http\Request  $request
       * @param  array  $config
       * @return string
       */
      protected function resolveRequestSignature(Request $request, array $config): string
      {
          $signature = $config['keyPrefix'] . ':';
          
          if (Auth::check()) {
              // Use user ID for authenticated users
              $signature .= 'user:' . Auth::id();
          } else {
              // Use IP address for guests
              $signature .= 'ip:' . $request->ip();
          }
          
          // Add endpoint-specific signature if configured
          if (!empty($config['perRoute']) && $config['perRoute']) {
              $signature .= ':' . $request->route()->getName() ?? $request->path();
          }
          
          // Add method-specific signature if configured
          if (!empty($config['perMethod']) && $config['perMethod']) {
              $signature .= ':' . $request->method();
          }
          
          return $signature;
      }
      
      /**
       * Create a response for when the rate limit is exceeded.
       *
       * @param  \Illuminate\Http\Request  $request
       * @param  string  $key
       * @param  int  $maxAttempts
       * @param  int  $decaySeconds
       * @return \Symfony\Component\HttpFoundation\Response
       */
      protected function buildRateLimitExceededResponse(
          Request $request,
          string $key,
          int $maxAttempts,
          int $decaySeconds
      ): Response {
          $retryAfter = RateLimiter::availableIn($key);
          
          $headers = [
              'X-RateLimit-Limit' => $maxAttempts,
              'X-RateLimit-Remaining' => 0,
              'Retry-After' => $retryAfter,
              'X-RateLimit-Reset' => $this->getRetryAfterTimestamp($retryAfter),
          ];
          
          // Check if the request expects JSON
          if ($request->expectsJson()) {
              return response()->json([
                  'message' => 'Too Many Requests',
                  'error' => 'Rate limit exceeded',
                  'retry_after' => $retryAfter,
                  'retry_after_seconds' => $retryAfter,
              ], 429, $headers);
          }
          
          // Return a regular response for non-JSON requests
          return response('Too Many Requests', 429, $headers);
      }
      
      /**
       * Add rate limit headers to the response.
       *
       * @param  \Symfony\Component\HttpFoundation\Response  $response
       * @param  string  $key
       * @param  int  $maxAttempts
       * @return \Symfony\Component\HttpFoundation\Response
       */
      protected function addRateLimitHeaders(
          Response $response,
          string $key,
          int $maxAttempts
      ): Response {
          $remainingAttempts = RateLimiter::remaining($key, $maxAttempts);
          $retryAfter = RateLimiter::availableIn($key);
          
          $response->headers->add([
              'X-RateLimit-Limit' => $maxAttempts,
              'X-RateLimit-Remaining' => $remainingAttempts,
          ]);
          
          // Add Retry-After header if no attempts remaining
          if ($remainingAttempts === 0) {
              $response->headers->add([
                  'Retry-After' => $retryAfter,
                  'X-RateLimit-Reset' => $this->getRetryAfterTimestamp($retryAfter),
              ]);
          }
          
          return $response;
      }
      
      /**
       * Get the timestamp for when the rate limit will reset.
       *
       * @param  int  $retryAfter  Seconds until retry is available
       * @return int
       */
      protected function getRetryAfterTimestamp(int $retryAfter): int
      {
          return time() + $retryAfter;
      }
  }
  
  namespace App\Services;
  
  use App\Models\RateLimitLog;
  use App\Models\User;
  use Illuminate\Http\Request;
  use Illuminate\Support\Facades\Cache;
  use Illuminate\Support\Facades\Log;
  
  class RateLimitService
  {
      /**
       * Get the configuration for a specific rate limiter type.
       *
       * @param  string  $limiterType
       * @return array
       */
      public function getLimiterConfig(string $limiterType): array
      {
          $configs = [
              'default' => [
                  'maxAttempts' => 60,
                  'decaySeconds' => 60,
                  'keyPrefix' => 'rate_limit',
                  'perRoute' => false,
                  'perMethod' => false,
              ],
              'api' => [
                  'maxAttempts' => 60,
                  'decaySeconds' => 60,
                  'keyPrefix' => 'api_rate_limit',
                  'perRoute' => true,
                  'perMethod' => true,
              ],
              'auth' => [
                  'maxAttempts' => 5,
                  'decaySeconds' => 300, // 5 minutes
                  'keyPrefix' => 'auth_rate_limit',
                  'perRoute' => false,
                  'perMethod' => false,
              ],
              'critical' => [
                  'maxAttempts' => 3,
                  'decaySeconds' => 3600, // 1 hour
                  'keyPrefix' => 'critical_rate_limit',
                  'perRoute' => true,
                  'perMethod' => false,
              ],
              'high_volume' => [
                  'maxAttempts' => 300,
                  'decaySeconds' => 60,
                  'keyPrefix' => 'high_volume_rate_limit',
                  'perRoute' => true,
                  'perMethod' => true,
              ],
          ];
          
          return $configs[$limiterType] ?? $configs['default'];
      }
      
      /**
       * Get user-specific rate limits.
       *
       * @param  \App\Models\User  $user
       * @param  string  $limiterType
       * @return array|null
       */
      public function getUserRateLimits(User $user, string $limiterType): ?array
      {
          // Check if user has custom rate limits stored
          $customLimits = $user->rateLimits()
              ->where('limiter_type', $limiterType)
              ->first();
          
          if ($customLimits) {
              return [
                  'maxAttempts' => $customLimits->max_attempts,
                  'decaySeconds' => $customLimits->decay_seconds,
              ];
          }
          
          // Check if user has a role with custom rate limits
          if ($user->role) {
              $roleLimits = config("rate_limits.roles.{$user->role}.{$limiterType}");
              
              if ($roleLimits) {
                  return [
                      'maxAttempts' => $roleLimits['max_attempts'],
                      'decaySeconds' => $roleLimits['decay_seconds'],
                  ];
              }
          }
          
          return null;
      }
      
      /**
       * Get the multiplier for a subscription tier.
       *
       * @param  string  $tier
       * @return float
       */
      public function getSubscriptionTierMultiplier(string $tier): float
      {
          $multipliers = [
              'free' => 1.0,
              'basic' => 2.0,
              'premium' => 5.0,
              'enterprise' => 10.0,
          ];
          
          return $multipliers[$tier] ?? 1.0;
      }
      
      /**
       * Get the system load factor for dynamic rate limiting.
       *
       * @return float
       */
      public function getSystemLoadFactor(): float
      {
          // Check if we have a cached load factor
          if (Cache::has('system_load_factor')) {
              return Cache::get('system_load_factor');
          }
          
          // Default load factor (normal conditions)
          $loadFactor = 1.0;
          
          // In a real application, you would calculate this based on:
          // - Server CPU load
          // - Memory usage
          // - Database connection pool usage
          // - Queue backlog
          // - etc.
          
          // For demonstration, we'll use a simple random factor
          // In a real app, replace this with actual system metrics
          if (function_exists('sys_getloadavg')) {
              $load = sys_getloadavg();
              $currentLoad = $load[0];
              
              // Adjust load factor based on system load
              // Lower load = higher factor (more requests allowed)
              // Higher load = lower factor (fewer requests allowed)
              if ($currentLoad < 1.0) {
                  $loadFactor = 1.2; // System is underutilized, allow more requests
              } elseif ($currentLoad < 2.0) {
                  $loadFactor = 1.0; // Normal load
              } elseif ($currentLoad < 4.0) {
                  $loadFactor = 0.8; // Moderate load, reduce limits slightly
              } else {
                  $loadFactor = 0.5; // High load, reduce limits significantly
              }
          }
          
          // Cache the load factor for 1 minute
          Cache::put('system_load_factor', $loadFactor, 60);
          
          return $loadFactor;
      }
      
      /**
       * Log a rate limit hit.
       *
       * @param  \Illuminate\Http\Request  $request
       * @param  string  $limiterType
       * @return void
       */
      public function logRateLimitHit(Request $request, string $limiterType): void
      {
          try {
              RateLimitLog::create([
                  'user_id' => $request->user() ? $request->user()->id : null,
                  'ip_address' => $request->ip(),
                  'user_agent' => $request->userAgent(),
                  'route' => $request->route() ? $request->route()->getName() : $request->path(),
                  'method' => $request->method(),
                  'limiter_type' => $limiterType,
                  'request_data' => $this->sanitizeRequestData($request),
              ]);
              
              // Log to application logs for monitoring
              Log::warning('Rate limit exceeded', [
                  'ip' => $request->ip(),
                  'user_id' => $request->user() ? $request->user()->id : null,
                  'route' => $request->route() ? $request->route()->getName() : $request->path(),
                  'limiter_type' => $limiterType,
              ]);
              
              // Check for potential abuse
              $this->checkForAbuse($request);
          } catch (\Exception $e) {
              // Ensure logging errors don't affect the response
              Log::error('Failed to log rate limit hit: ' . $e->getMessage());
          }
      }
      
      /**
       * Sanitize request data for logging.
       *
       * @param  \Illuminate\Http\Request  $request
       * @return array
       */
      protected function sanitizeRequestData(Request $request): array
      {
          $data = $request->except([
              'password', 'password_confirmation', 'token', 'api_token',
              'credit_card', 'card_number', 'cvv', 'ssn', 'social_security',
          ]);
          
          // Recursively sanitize arrays
          array_walk_recursive($data, function (&$value, $key) {
              // Sanitize any field that might contain sensitive information
              if (preg_match('/(password|token|secret|key|card|cvv|ssn)/i', $key)) {
                  $value = '[REDACTED]';
              }
          });
          
          return $data;
      }
      
      /**
       * Check for potential abuse based on rate limit hits.
       *
       * @param  \Illuminate\Http\Request  $request
       * @return void
       */
      protected function checkForAbuse(Request $request): void
      {
          $ip = $request->ip();
          $userId = $request->user() ? $request->user()->id : null;
          
          // Count recent rate limit hits from this IP
          $recentHits = RateLimitLog::where('ip_address', $ip)
              ->where('created_at', '>=', now()->subHour())
              ->count();
          
          // If user is authenticated, also count their hits across IPs
          if ($userId) {
              $userHits = RateLimitLog::where('user_id', $userId)
                  ->where('created_at', '>=', now()->subHour())
                  ->count();
              
              $recentHits = max($recentHits, $userHits);
          }
          
          // Threshold for potential abuse
          if ($recentHits >= 10) {
              // Log potential abuse
              Log::alert('Potential API abuse detected', [
                  'ip' => $ip,
                  'user_id' => $userId,
                  'hits_last_hour' => $recentHits,
              ]);
              
              // In a real application, you might:
              // - Add the IP to a blocklist
              // - Temporarily ban the user
              // - Send an alert to administrators
              // - Trigger additional security measures
          }
      }
  }
  
  namespace App\Models;
  
  use Illuminate\Database\Eloquent\Model;
  use Illuminate\Database\Eloquent\Relations\BelongsTo;
  
  class RateLimitLog extends Model
  {
      protected $fillable = [
          'user_id',
          'ip_address',
          'user_agent',
          'route',
          'method',
          'limiter_type',
          'request_data',
      ];
      
      protected $casts = [
          'request_data' => 'array',
      ];
      
      /**
       * Get the user that triggered the rate limit.
       */
      public function user(): BelongsTo
      {
          return $this->belongsTo(User::class);
      }
  }
  
  namespace App\Models;
  
  use Illuminate\Database\Eloquent\Model;
  use Illuminate\Database\Eloquent\Relations\BelongsTo;
  
  class UserRateLimit extends Model
  {
      protected $fillable = [
          'user_id',
          'limiter_type',
          'max_attempts',
          'decay_seconds',
          'expires_at',
      ];
      
      protected $casts = [
          'max_attempts' => 'integer',
          'decay_seconds' => 'integer',
          'expires_at' => 'datetime',
      ];
      
      /**
       * Get the user that owns the rate limit.
       */
      public function user(): BelongsTo
      {
          return $this->belongsTo(User::class);
      }
      
      /**
       * Scope a query to only include active rate limits.
       */
      public function scopeActive($query)
      {
          return $query->where(function ($query) {
              $query->whereNull('expires_at')
                  ->orWhere('expires_at', '>', now());
          });
      }
  }
  
  namespace App\Models;
  
  use Illuminate\Database\Eloquent\Relations\HasMany;
  use Illuminate\Foundation\Auth\User as Authenticatable;
  
  class User extends Authenticatable
  {
      // ... other User model code ...
      
      /**
       * Get the rate limits for the user.
       */
      public function rateLimits(): HasMany
      {
          return $this->hasMany(UserRateLimit::class)->active();
      }
  }
  
  namespace App\Http\Controllers;
  
  use App\Models\RateLimitLog;
  use App\Models\User;
  use App\Models\UserRateLimit;
  use Illuminate\Http\Request;
  use Illuminate\Support\Facades\Auth;
  
  class RateLimitController extends Controller
  {
      /**
       * Display a listing of rate limit logs.
       */
      public function index(Request $request)
      {
          // Check permissions
          if (!Auth::user()->can('view rate limits')) {
              abort(403);
          }
          
          $query = RateLimitLog::with('user');
          
          // Apply filters
          if ($request->filled('user_id')) {
              $query->where('user_id', $request->input('user_id'));
          }
          
          if ($request->filled('ip_address')) {
              $query->where('ip_address', $request->input('ip_address'));
          }
          
          if ($request->filled('limiter_type')) {
              $query->where('limiter_type', $request->input('limiter_type'));
          }
          
          if ($request->filled('start_date') && $request->filled('end_date')) {
              $query->whereBetween('created_at', [
                  $request->input('start_date'),
                  $request->input('end_date'),
              ]);
          }
          
          // Apply sorting
          $sortField = $request->input('sort_by', 'created_at');
          $sortDirection = $request->input('sort_direction', 'desc');
          $query->orderBy($sortField, $sortDirection);
          
          // Paginate results
          $perPage = $request->input('per_page', 25);
          $logs = $query->paginate($perPage);
          
          return view('rate-limits.logs', [
              'logs' => $logs,
              'filters' => $request->all(),
          ]);
      }
      
      /**
       * Display a listing of user rate limits.
       */
      public function userLimits(Request $request)
      {
          // Check permissions
          if (!Auth::user()->can('manage rate limits')) {
              abort(403);
          }
          
          $query = UserRateLimit::with('user')->active();
          
          // Apply filters
          if ($request->filled('user_id')) {
              $query->where('user_id', $request->input('user_id'));
          }
          
          if ($request->filled('limiter_type')) {
              $query->where('limiter_type', $request->input('limiter_type'));
          }
          
          // Apply sorting
          $sortField = $request->input('sort_by', 'created_at');
          $sortDirection = $request->input('sort_direction', 'desc');
          $query->orderBy($sortField, $sortDirection);
          
          // Paginate results
          $perPage = $request->input('per_page', 25);
          $limits = $query->paginate($perPage);
          
          return view('rate-limits.user-limits', [
              'limits' => $limits,
              'filters' => $request->all(),
          ]);
      }
      
      /**
       * Show the form for creating a new user rate limit.
       */
      public function create()
      {
          // Check permissions
          if (!Auth::user()->can('manage rate limits')) {
              abort(403);
          }
          
          $users = User::all();
          $limiterTypes = [
              'default' => 'Default',
              'api' => 'API',
              'auth' => 'Authentication',
              'critical' => 'Critical Operations',
              'high_volume' => 'High Volume',
          ];
          
          return view('rate-limits.create', [
              'users' => $users,
              'limiterTypes' => $limiterTypes,
          ]);
      }
      
      /**
       * Store a newly created user rate limit.
       */
      public function store(Request $request)
      {
          // Check permissions
          if (!Auth::user()->can('manage rate limits')) {
              abort(403);
          }
          
          $request->validate([
              'user_id' => 'required|exists:users,id',
              'limiter_type' => 'required|string',
              'max_attempts' => 'required|integer|min:1',
              'decay_seconds' => 'required|integer|min:1',
              'expires_at' => 'nullable|date|after:now',
          ]);
          
          UserRateLimit::create($request->all());
          
          return redirect()->route('rate-limits.user-limits')
              ->with('success', 'User rate limit created successfully.');
      }
      
      /**
       * Remove the specified user rate limit.
       */
      public function destroy(UserRateLimit $userRateLimit)
      {
          // Check permissions
          if (!Auth::user()->can('manage rate limits')) {
              abort(403);
          }
          
          $userRateLimit->delete();
          
          return redirect()->route('rate-limits.user-limits')
              ->with('success', 'User rate limit deleted successfully.');
      }
  }
explanation: |
  This example demonstrates a comprehensive API rate limiting system:
  
  1. **Custom Rate Limiter Middleware**: A flexible middleware that:
     - Supports different rate limiting strategies
     - Applies user-specific rate limits
     - Dynamically adjusts limits based on system load
     - Adds appropriate rate limit headers to responses
  
  2. **Rate Limit Service**: A central service that:
     - Manages rate limit configurations
     - Handles user-specific rate limits
     - Adjusts limits based on subscription tiers
     - Monitors system load for dynamic adjustments
     - Logs rate limit hits for analysis
  
  3. **Rate Limit Logging**: Comprehensive logging of rate limit hits:
     - Recording user, IP, route, and request details
     - Sanitizing sensitive data before logging
     - Detecting potential abuse patterns
     - Triggering alerts for suspicious activity
  
  4. **User-Specific Rate Limits**: Allowing different limits for different users:
     - Setting custom limits for specific users
     - Applying role-based limits
     - Adjusting limits based on subscription tiers
     - Supporting temporary limit adjustments with expiration
  
  5. **Rate Limit Management**: Administrative interfaces for:
     - Viewing rate limit logs
     - Managing user-specific rate limits
     - Creating new rate limit rules
     - Monitoring rate limit trends
  
  Key features of the implementation:
  
  - **Multiple Limiter Types**: Different strategies for different types of endpoints
  - **Dynamic Adjustments**: Adapting limits based on system load
  - **Subscription Tiers**: Higher limits for premium users
  - **Comprehensive Logging**: Detailed logging for analysis and security
  - **Abuse Detection**: Identifying and responding to potential abuse
  - **Proper Headers**: Following HTTP standards for rate limit headers
  
  In a real Laravel application:
  - You would implement more sophisticated system load monitoring
  - You might add more granular rate limiting strategies
  - You would implement more advanced abuse detection algorithms
  - You would add real-time monitoring and alerting
  - You would implement rate limit analytics dashboards
challenges:
  - Implement a token bucket algorithm for more flexible rate limiting
  - Add support for rate limit sharing across a cluster of servers
  - Create a system for temporary rate limit boosts (e.g., for special events)
  - Implement adaptive rate limiting that learns from user behavior
  - Add support for rate limit exemptions for specific endpoints or users
:::
