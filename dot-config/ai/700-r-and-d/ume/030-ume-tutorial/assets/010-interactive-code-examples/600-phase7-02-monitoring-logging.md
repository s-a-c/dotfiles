# Monitoring and Logging

:::interactive-code
title: Implementing Comprehensive Monitoring and Logging
description: This example demonstrates how to implement effective monitoring and logging for Laravel applications with user model enhancements, focusing on centralized logging, performance monitoring, and alerting.
language: php
editable: true
code: |
  <?php
  
  namespace App\Services;
  
  use App\Models\User;
  use Illuminate\Support\Facades\Log;
  use Illuminate\Support\Facades\Cache;
  use Illuminate\Support\Facades\Http;
  
  class MonitoringService
  {
      /**
       * The metrics collector instance.
       *
       * @var \App\Services\MetricsCollector
       */
      protected $metrics;
      
      /**
       * Create a new monitoring service instance.
       *
       * @param \App\Services\MetricsCollector $metrics
       * @return void
       */
      public function __construct(MetricsCollector $metrics)
      {
          $this->metrics = $metrics;
      }
      
      /**
       * Monitor user authentication events.
       *
       * @param \App\Models\User $user
       * @param string $event
       * @param array $context
       * @return void
       */
      public function trackAuthEvent(User $user, string $event, array $context = []): void
      {
          // Log the authentication event
          Log::channel('auth')->info("User authentication event: {$event}", [
              'user_id' => $user->id,
              'email' => $user->email,
              'ip_address' => request()->ip(),
              'user_agent' => request()->userAgent(),
              'event' => $event,
              'context' => $context,
          ]);
          
          // Track metrics for authentication events
          $this->metrics->increment("auth.{$event}");
          
          // Track user-specific metrics
          $this->metrics->increment("user.{$user->id}.auth.{$event}");
          
          // Check for suspicious activity
          if ($this->isSuspiciousActivity($user, $event, $context)) {
              $this->reportSuspiciousActivity($user, $event, $context);
          }
      }
      
      /**
       * Monitor user type changes.
       *
       * @param \App\Models\User $user
       * @param string $oldType
       * @param string $newType
       * @return void
       */
      public function trackUserTypeChange(User $user, string $oldType, string $newType): void
      {
          // Log the user type change
          Log::channel('user')->info("User type changed", [
              'user_id' => $user->id,
              'old_type' => $oldType,
              'new_type' => $newType,
              'changed_by' => auth()->id() ?? 'system',
          ]);
          
          // Track metrics for user type changes
          $this->metrics->increment('user.type_change');
          $this->metrics->increment("user.type.{$newType}");
          $this->metrics->decrement("user.type.{$oldType}");
          
          // Record the timing of type changes for this user
          $key = "user:{$user->id}:type_changes";
          $changes = Cache::get($key, []);
          $changes[] = [
              'timestamp' => now()->timestamp,
              'old_type' => $oldType,
              'new_type' => $newType,
          ];
          Cache::put($key, $changes, now()->addDays(30));
          
          // Alert on rapid type changes (potential abuse)
          if (count($changes) >= 3) {
              $latestChanges = array_slice($changes, -3);
              $firstChange = $latestChanges[0]['timestamp'];
              $lastChange = $latestChanges[2]['timestamp'];
              
              // If 3 changes occurred within 1 hour
              if ($lastChange - $firstChange < 3600) {
                  $this->alertRapidUserTypeChanges($user, $changes);
              }
          }
      }
      
      /**
       * Monitor user permission checks.
       *
       * @param \App\Models\User $user
       * @param string $permission
       * @param bool $granted
       * @return void
       */
      public function trackPermissionCheck(User $user, string $permission, bool $granted): void
      {
          // Log permission checks at debug level (high volume)
          Log::channel('permissions')->debug("Permission check", [
              'user_id' => $user->id,
              'permission' => $permission,
              'granted' => $granted,
              'url' => request()->fullUrl(),
          ]);
          
          // Track metrics for permission checks
          $this->metrics->increment('permission.check');
          $this->metrics->increment($granted ? 'permission.granted' : 'permission.denied');
          
          // Track metrics for specific permissions
          $this->metrics->increment("permission.{$permission}." . ($granted ? 'granted' : 'denied'));
          
          // Alert on high denial rates
          $this->checkPermissionDenialRate($permission);
      }
      
      /**
       * Monitor database queries related to user models.
       *
       * @param string $query
       * @param float $time
       * @return void
       */
      public function trackUserQuery(string $query, float $time): void
      {
          // Log slow queries
          if ($time > 1.0) { // More than 1 second
              Log::channel('database')->warning("Slow user query detected", [
                  'query' => $query,
                  'time' => $time,
                  'connection' => DB::connection()->getName(),
              ]);
              
              // Track slow query metrics
              $this->metrics->increment('database.slow_query');
              $this->metrics->histogram('database.query_time', $time);
              
              // Alert on very slow queries
              if ($time > 5.0) { // More than 5 seconds
                  $this->alertSlowQuery($query, $time);
              }
          }
          
          // Track general query metrics
          $this->metrics->increment('database.query');
          $this->metrics->histogram('database.query_time', $time);
      }
      
      /**
       * Monitor API rate limiting for users.
       *
       * @param \App\Models\User $user
       * @param string $endpoint
       * @param int $currentRate
       * @param int $limit
       * @return void
       */
      public function trackApiRateLimit(User $user, string $endpoint, int $currentRate, int $limit): void
      {
          // Calculate percentage of limit used
          $percentUsed = ($currentRate / $limit) * 100;
          
          // Log rate limit information
          Log::channel('api')->info("API rate limit status", [
              'user_id' => $user->id,
              'endpoint' => $endpoint,
              'current_rate' => $currentRate,
              'limit' => $limit,
              'percent_used' => $percentUsed,
          ]);
          
          // Track rate limit metrics
          $this->metrics->gauge("api.rate_limit.{$endpoint}", $percentUsed);
          
          // Alert on approaching limits
          if ($percentUsed > 80) {
              Log::channel('api')->warning("User approaching API rate limit", [
                  'user_id' => $user->id,
                  'endpoint' => $endpoint,
                  'percent_used' => $percentUsed,
              ]);
              
              // Alert if user is consistently hitting limits
              $key = "user:{$user->id}:rate_limit_warnings";
              $warnings = Cache::increment($key);
              Cache::put($key, $warnings, now()->addHours(1));
              
              if ($warnings >= 5) {
                  $this->alertRateLimitAbuse($user, $endpoint, $percentUsed);
                  Cache::forget($key); // Reset after alerting
              }
          }
      }
      
      /**
       * Check if authentication activity is suspicious.
       *
       * @param \App\Models\User $user
       * @param string $event
       * @param array $context
       * @return bool
       */
      protected function isSuspiciousActivity(User $user, string $event, array $context): bool
      {
          // Check for login from new location
          if ($event === 'login' && isset($context['ip_address'])) {
              $knownIps = $user->loginIps ?? [];
              
              if (!in_array($context['ip_address'], $knownIps)) {
                  // New IP address
                  return true;
              }
          }
          
          // Check for multiple failed login attempts
          if ($event === 'failed_login') {
              $key = "user:{$user->id}:failed_logins";
              $failedAttempts = Cache::increment($key);
              Cache::put($key, $failedAttempts, now()->addHours(1));
              
              if ($failedAttempts >= 5) {
                  return true;
              }
          }
          
          // Check for account lockout
          if ($event === 'lockout') {
              return true;
          }
          
          return false;
      }
      
      /**
       * Report suspicious authentication activity.
       *
       * @param \App\Models\User $user
       * @param string $event
       * @param array $context
       * @return void
       */
      protected function reportSuspiciousActivity(User $user, string $event, array $context): void
      {
          Log::channel('security')->warning("Suspicious authentication activity detected", [
              'user_id' => $user->id,
              'email' => $user->email,
              'event' => $event,
              'ip_address' => $context['ip_address'] ?? request()->ip(),
              'user_agent' => $context['user_agent'] ?? request()->userAgent(),
              'context' => $context,
          ]);
          
          // Track security metrics
          $this->metrics->increment('security.suspicious_activity');
          $this->metrics->increment("security.suspicious.{$event}");
          
          // Send alert to security team
          $this->sendSecurityAlert('suspicious_auth', $user, [
              'event' => $event,
              'context' => $context,
          ]);
      }
      
      /**
       * Alert on rapid user type changes.
       *
       * @param \App\Models\User $user
       * @param array $changes
       * @return void
       */
      protected function alertRapidUserTypeChanges(User $user, array $changes): void
      {
          Log::channel('security')->warning("Rapid user type changes detected", [
              'user_id' => $user->id,
              'email' => $user->email,
              'changes' => $changes,
          ]);
          
          // Track security metrics
          $this->metrics->increment('security.rapid_type_changes');
          
          // Send alert to security team
          $this->sendSecurityAlert('rapid_type_changes', $user, [
              'changes' => $changes,
          ]);
      }
      
      /**
       * Check permission denial rate and alert if necessary.
       *
       * @param string $permission
       * @return void
       */
      protected function checkPermissionDenialRate(string $permission): void
      {
          $key = "permission:{$permission}";
          
          // Get current metrics for this permission
          $total = $this->metrics->getCount("{$key}.check") ?? 0;
          $denied = $this->metrics->getCount("{$key}.denied") ?? 0;
          
          if ($total > 100) { // Only check if we have enough data
              $denialRate = ($denied / $total) * 100;
              
              // Alert on high denial rates (potential misconfiguration or attack)
              if ($denialRate > 30) { // More than 30% denial rate
                  Log::channel('security')->warning("High permission denial rate detected", [
                      'permission' => $permission,
                      'denial_rate' => $denialRate,
                      'total_checks' => $total,
                      'total_denials' => $denied,
                  ]);
                  
                  // Send alert to security team
                  $this->sendSecurityAlert('high_denial_rate', null, [
                      'permission' => $permission,
                      'denial_rate' => $denialRate,
                  ]);
              }
          }
      }
      
      /**
       * Alert on slow database queries.
       *
       * @param string $query
       * @param float $time
       * @return void
       */
      protected function alertSlowQuery(string $query, float $time): void
      {
          Log::channel('performance')->error("Very slow query detected", [
              'query' => $query,
              'time' => $time,
              'connection' => DB::connection()->getName(),
          ]);
          
          // Send alert to development team
          $this->sendDevAlert('slow_query', [
              'query' => $query,
              'time' => $time,
          ]);
      }
      
      /**
       * Alert on API rate limit abuse.
       *
       * @param \App\Models\User $user
       * @param string $endpoint
       * @param float $percentUsed
       * @return void
       */
      protected function alertRateLimitAbuse(User $user, string $endpoint, float $percentUsed): void
      {
          Log::channel('security')->warning("User consistently hitting API rate limits", [
              'user_id' => $user->id,
              'email' => $user->email,
              'endpoint' => $endpoint,
              'percent_used' => $percentUsed,
          ]);
          
          // Track security metrics
          $this->metrics->increment('security.rate_limit_abuse');
          
          // Send alert to security team
          $this->sendSecurityAlert('rate_limit_abuse', $user, [
              'endpoint' => $endpoint,
              'percent_used' => $percentUsed,
          ]);
      }
      
      /**
       * Send a security alert.
       *
       * @param string $type
       * @param \App\Models\User|null $user
       * @param array $data
       * @return void
       */
      protected function sendSecurityAlert(string $type, ?User $user, array $data): void
      {
          // In a real application, this would send an alert to a security monitoring system
          // For this example, we'll just log it
          Log::channel('alerts')->alert("Security alert: {$type}", [
              'user_id' => $user?->id,
              'email' => $user?->email,
              'type' => $type,
              'data' => $data,
              'timestamp' => now()->toIso8601String(),
          ]);
          
          // You might also send to an external service like PagerDuty, Slack, etc.
          if (config('monitoring.slack_webhook_url')) {
              Http::post(config('monitoring.slack_webhook_url'), [
                  'text' => "🚨 Security Alert: {$type}" . ($user ? " for user {$user->email}" : ''),
                  'attachments' => [
                      [
                          'color' => 'danger',
                          'fields' => $this->formatAlertData($data),
                          'footer' => 'Security Monitoring System',
                          'ts' => now()->timestamp,
                      ],
                  ],
              ]);
          }
      }
      
      /**
       * Send a development alert.
       *
       * @param string $type
       * @param array $data
       * @return void
       */
      protected function sendDevAlert(string $type, array $data): void
      {
          // In a real application, this would send an alert to the development team
          // For this example, we'll just log it
          Log::channel('alerts')->alert("Development alert: {$type}", [
              'type' => $type,
              'data' => $data,
              'timestamp' => now()->toIso8601String(),
          ]);
          
          // You might also send to an external service like PagerDuty, Slack, etc.
          if (config('monitoring.dev_slack_webhook_url')) {
              Http::post(config('monitoring.dev_slack_webhook_url'), [
                  'text' => "⚠️ Development Alert: {$type}",
                  'attachments' => [
                      [
                          'color' => 'warning',
                          'fields' => $this->formatAlertData($data),
                          'footer' => 'Development Monitoring System',
                          'ts' => now()->timestamp,
                      ],
                  ],
              ]);
          }
      }
      
      /**
       * Format alert data for external services.
       *
       * @param array $data
       * @return array
       */
      protected function formatAlertData(array $data): array
      {
          $fields = [];
          
          foreach ($data as $key => $value) {
              $fields[] = [
                  'title' => ucfirst(str_replace('_', ' ', $key)),
                  'value' => is_array($value) ? json_encode($value) : $value,
                  'short' => strlen((string) $value) < 50,
              ];
          }
          
          return $fields;
      }
  }
  
  namespace App\Services;
  
  use Illuminate\Support\Facades\Redis;
  
  class MetricsCollector
  {
      /**
       * Increment a counter metric.
       *
       * @param string $name
       * @param int $value
       * @return void
       */
      public function increment(string $name, int $value = 1): void
      {
          Redis::incr("metrics:counter:{$name}", $value);
      }
      
      /**
       * Decrement a counter metric.
       *
       * @param string $name
       * @param int $value
       * @return void
       */
      public function decrement(string $name, int $value = 1): void
      {
          Redis::decr("metrics:counter:{$name}", $value);
      }
      
      /**
       * Set a gauge metric.
       *
       * @param string $name
       * @param float $value
       * @return void
       */
      public function gauge(string $name, float $value): void
      {
          Redis::set("metrics:gauge:{$name}", $value);
      }
      
      /**
       * Record a value in a histogram metric.
       *
       * @param string $name
       * @param float $value
       * @return void
       */
      public function histogram(string $name, float $value): void
      {
          // For simplicity, we'll just store the last 100 values
          Redis::lpush("metrics:histogram:{$name}", $value);
          Redis::ltrim("metrics:histogram:{$name}", 0, 99);
      }
      
      /**
       * Get the current value of a counter metric.
       *
       * @param string $name
       * @return int|null
       */
      public function getCount(string $name): ?int
      {
          $value = Redis::get("metrics:counter:{$name}");
          return $value !== null ? (int) $value : null;
      }
      
      /**
       * Get the current value of a gauge metric.
       *
       * @param string $name
       * @return float|null
       */
      public function getGauge(string $name): ?float
      {
          $value = Redis::get("metrics:gauge:{$name}");
          return $value !== null ? (float) $value : null;
      }
      
      /**
       * Get the values in a histogram metric.
       *
       * @param string $name
       * @return array
       */
      public function getHistogram(string $name): array
      {
          $values = Redis::lrange("metrics:histogram:{$name}", 0, -1);
          return array_map('floatval', $values);
      }
      
      /**
       * Export all metrics for external monitoring systems.
       *
       * @return array
       */
      public function exportMetrics(): array
      {
          $metrics = [];
          
          // Export counters
          $counterKeys = Redis::keys("metrics:counter:*");
          foreach ($counterKeys as $key) {
              $name = str_replace("metrics:counter:", "", $key);
              $metrics['counters'][$name] = (int) Redis::get($key);
          }
          
          // Export gauges
          $gaugeKeys = Redis::keys("metrics:gauge:*");
          foreach ($gaugeKeys as $key) {
              $name = str_replace("metrics:gauge:", "", $key);
              $metrics['gauges'][$name] = (float) Redis::get($key);
          }
          
          // Export histograms
          $histogramKeys = Redis::keys("metrics:histogram:*");
          foreach ($histogramKeys as $key) {
              $name = str_replace("metrics:histogram:", "", $key);
              $values = array_map('floatval', Redis::lrange($key, 0, -1));
              
              // Calculate histogram statistics
              $metrics['histograms'][$name] = [
                  'count' => count($values),
                  'min' => !empty($values) ? min($values) : null,
                  'max' => !empty($values) ? max($values) : null,
                  'avg' => !empty($values) ? array_sum($values) / count($values) : null,
                  'p95' => $this->calculatePercentile($values, 95),
                  'p99' => $this->calculatePercentile($values, 99),
              ];
          }
          
          return $metrics;
      }
      
      /**
       * Calculate a percentile value from an array of values.
       *
       * @param array $values
       * @param int $percentile
       * @return float|null
       */
      protected function calculatePercentile(array $values, int $percentile): ?float
      {
          if (empty($values)) {
              return null;
          }
          
          sort($values);
          $index = ceil(($percentile / 100) * count($values)) - 1;
          return $values[$index];
      }
  }
explanation: |
  This example demonstrates a comprehensive monitoring and logging system for Laravel applications with user model enhancements:
  
  1. **Monitoring Service**: A central service that tracks various aspects of the application:
     - User authentication events (logins, logouts, failures)
     - User type changes
     - Permission checks
     - Database queries related to user models
     - API rate limiting
  
  2. **Metrics Collection**: A service that collects and stores different types of metrics:
     - Counters: Incrementing/decrementing values (e.g., number of logins)
     - Gauges: Current value measurements (e.g., API rate limit usage)
     - Histograms: Distribution of values (e.g., query execution times)
  
  3. **Logging Strategy**: Structured logging with different channels for different concerns:
     - Authentication events
     - User changes
     - Permission checks
     - Database performance
     - API usage
     - Security events
  
  4. **Alerting System**: Mechanisms to detect and report issues:
     - Suspicious authentication activity detection
     - Rapid user type changes monitoring
     - Permission denial rate analysis
     - Slow query detection
     - API rate limit abuse detection
  
  5. **Integration with External Systems**: Methods to send alerts to external services:
     - Slack notifications
     - Security team alerts
     - Development team alerts
  
  Key features of the implementation:
  
  - **Structured Logging**: Consistent, detailed log entries with context
  - **Multi-channel Logging**: Separate channels for different types of events
  - **Real-time Metrics**: Collection and analysis of application metrics
  - **Anomaly Detection**: Identification of unusual patterns or potential security issues
  - **Alerting Thresholds**: Configurable thresholds for when to trigger alerts
  - **Context Preservation**: Detailed context included with all logs and alerts
  
  In a real Laravel application:
  - You would integrate with dedicated monitoring services like New Relic, Datadog, or Prometheus
  - You would use a centralized logging system like ELK Stack or Graylog
  - You would implement more sophisticated anomaly detection algorithms
  - You would add dashboards for visualizing metrics and logs
  - You would implement more comprehensive alerting with escalation policies
challenges:
  - Implement distributed tracing to track requests across multiple services
  - Add real-time monitoring dashboards using Laravel Livewire or Inertia.js
  - Create a custom log viewer that allows filtering and searching logs
  - Implement machine learning-based anomaly detection for security events
  - Add user behavior analytics to detect unusual user activity patterns
:::
