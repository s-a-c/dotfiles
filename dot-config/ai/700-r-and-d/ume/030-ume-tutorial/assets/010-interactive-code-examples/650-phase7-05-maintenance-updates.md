# Maintenance and Updates

:::interactive-code
title: Implementing Effective Maintenance and Update Strategies
description: This example demonstrates how to implement robust maintenance and update strategies for Laravel applications with user model enhancements, focusing on zero-downtime updates, database migrations, and feature flags.
language: php
editable: true
code: |
  <?php
  
  namespace App\Console\Commands;
  
  use Illuminate\Console\Command;
  use Illuminate\Support\Facades\Artisan;
  use Illuminate\Support\Facades\DB;
  use Illuminate\Support\Facades\Schema;
  use Illuminate\Support\Facades\File;
  use Illuminate\Support\Facades\Cache;
  
  class MaintenanceMode extends Command
  {
      /**
       * The name and signature of the console command.
       *
       * @var string
       */
      protected $signature = 'maintenance:toggle
                              {mode=on : Mode to set (on/off)}
                              {--message= : Custom maintenance message}
                              {--allow-ips= : Comma-separated list of IPs to allow}
                              {--retry= : Retry time in seconds}
                              {--secret= : Secret for bypassing maintenance mode}
                              {--status : Show current maintenance status}';
      
      /**
       * The console command description.
       *
       * @var string
       */
      protected $description = 'Toggle maintenance mode with enhanced options';
      
      /**
       * Execute the console command.
       */
      public function handle()
      {
          // Check if we just want to show status
          if ($this->option('status')) {
              $this->showMaintenanceStatus();
              return Command::SUCCESS;
          }
          
          $mode = $this->argument('mode');
          
          if (!in_array($mode, ['on', 'off'])) {
              $this->error('Invalid mode. Use "on" or "off".');
              return Command::FAILURE;
          }
          
          if ($mode === 'on') {
              $this->enableMaintenanceMode();
          } else {
              $this->disableMaintenanceMode();
          }
          
          return Command::SUCCESS;
      }
      
      /**
       * Show the current maintenance mode status.
       *
       * @return void
       */
      protected function showMaintenanceStatus(): void
      {
          $maintenanceFile = storage_path('framework/maintenance.php');
          
          if (file_exists($maintenanceFile)) {
              $data = require $maintenanceFile;
              
              $this->info('Maintenance mode is currently ON');
              $this->line('Time: ' . date('Y-m-d H:i:s', $data['time']));
              
              if (isset($data['message'])) {
                  $this->line('Message: ' . $data['message']);
              }
              
              if (isset($data['retry'])) {
                  $this->line('Retry After: ' . $data['retry'] . ' seconds');
              }
              
              if (isset($data['allowed']) && !empty($data['allowed'])) {
                  $this->line('Allowed IPs: ' . implode(', ', $data['allowed']));
              }
              
              if (isset($data['secret'])) {
                  $this->line('Bypass Secret: ' . $data['secret']);
                  $this->line('Bypass URL: ' . url('/' . $data['secret']));
              }
          } else {
              $this->info('Maintenance mode is currently OFF');
          }
      }
      
      /**
       * Enable maintenance mode with enhanced options.
       *
       * @return void
       */
      protected function enableMaintenanceMode(): void
      {
          $this->info('Enabling maintenance mode...');
          
          $options = ['--render' => 'errors.maintenance'];
          
          // Add custom message if provided
          if ($message = $this->option('message')) {
              $options['--message'] = $message;
          }
          
          // Add allowed IPs if provided
          if ($allowIps = $this->option('allow-ips')) {
              $options['--allow'] = explode(',', $allowIps);
          }
          
          // Add retry time if provided
          if ($retry = $this->option('retry')) {
              $options['--retry'] = $retry;
          }
          
          // Add secret if provided
          if ($secret = $this->option('secret')) {
              $options['--secret'] = $secret;
          } else {
              // Generate a random secret if not provided
              $options['--secret'] = md5(uniqid());
          }
          
          // Call the built-in down command with our options
          Artisan::call('down', $options);
          
          // Show the maintenance status
          $this->showMaintenanceStatus();
          
          // Provide the bypass URL
          $maintenanceFile = storage_path('framework/maintenance.php');
          if (file_exists($maintenanceFile)) {
              $data = require $maintenanceFile;
              if (isset($data['secret'])) {
                  $this->info('Maintenance mode bypass URL:');
                  $this->line(url('/' . $data['secret']));
              }
          }
      }
      
      /**
       * Disable maintenance mode.
       *
       * @return void
       */
      protected function disableMaintenanceMode(): void
      {
          $this->info('Disabling maintenance mode...');
          
          // Call the built-in up command
          Artisan::call('up');
          
          $this->info('Maintenance mode has been disabled.');
      }
  }
  
  namespace App\Services;
  
  use Illuminate\Support\Facades\Cache;
  use Illuminate\Support\Facades\DB;
  use Illuminate\Support\Facades\Schema;
  use Illuminate\Support\Facades\Log;
  
  class FeatureFlagService
  {
      /**
       * Cache TTL in seconds (5 minutes).
       *
       * @var int
       */
      protected const CACHE_TTL = 300;
      
      /**
       * Check if a feature is enabled.
       *
       * @param string $feature
       * @param int|null $userId
       * @return bool
       */
      public function isEnabled(string $feature, ?int $userId = null): bool
      {
          // Check if feature flags table exists
          if (!$this->featureFlagsTableExists()) {
              return false;
          }
          
          // Check for user-specific override
          if ($userId !== null) {
              $userOverride = $this->getUserFeatureOverride($feature, $userId);
              if ($userOverride !== null) {
                  return $userOverride;
              }
          }
          
          // Check for global feature flag
          return $this->getGlobalFeatureFlag($feature);
      }
      
      /**
       * Check if the feature flags table exists.
       *
       * @return bool
       */
      protected function featureFlagsTableExists(): bool
      {
          return Cache::remember('feature_flags_table_exists', self::CACHE_TTL, function () {
              return Schema::hasTable('feature_flags');
          });
      }
      
      /**
       * Get a user-specific feature override.
       *
       * @param string $feature
       * @param int $userId
       * @return bool|null
       */
      protected function getUserFeatureOverride(string $feature, int $userId): ?bool
      {
          $cacheKey = "feature:{$feature}:user:{$userId}";
          
          return Cache::remember($cacheKey, self::CACHE_TTL, function () use ($feature, $userId) {
              $override = DB::table('user_feature_flags')
                  ->where('feature', $feature)
                  ->where('user_id', $userId)
                  ->first();
              
              return $override ? (bool) $override->enabled : null;
          });
      }
      
      /**
       * Get a global feature flag.
       *
       * @param string $feature
       * @return bool
       */
      protected function getGlobalFeatureFlag(string $feature): bool
      {
          $cacheKey = "feature:{$feature}:global";
          
          return Cache::remember($cacheKey, self::CACHE_TTL, function () use ($feature) {
              $flag = DB::table('feature_flags')
                  ->where('feature', $feature)
                  ->first();
              
              // Default to disabled if not found
              return $flag ? (bool) $flag->enabled : false;
          });
      }
      
      /**
       * Enable a feature globally.
       *
       * @param string $feature
       * @param string|null $description
       * @return bool
       */
      public function enableFeature(string $feature, ?string $description = null): bool
      {
          $result = $this->updateFeatureFlag($feature, true, $description);
          
          // Clear cache
          Cache::forget("feature:{$feature}:global");
          
          return $result;
      }
      
      /**
       * Disable a feature globally.
       *
       * @param string $feature
       * @param string|null $description
       * @return bool
       */
      public function disableFeature(string $feature, ?string $description = null): bool
      {
          $result = $this->updateFeatureFlag($feature, false, $description);
          
          // Clear cache
          Cache::forget("feature:{$feature}:global");
          
          return $result;
      }
      
      /**
       * Update a feature flag.
       *
       * @param string $feature
       * @param bool $enabled
       * @param string|null $description
       * @return bool
       */
      protected function updateFeatureFlag(string $feature, bool $enabled, ?string $description = null): bool
      {
          try {
              DB::table('feature_flags')
                  ->updateOrInsert(
                      ['feature' => $feature],
                      [
                          'enabled' => $enabled,
                          'description' => $description,
                          'updated_at' => now(),
                      ]
                  );
              
              Log::info("Feature flag '{$feature}' " . ($enabled ? 'enabled' : 'disabled'));
              
              return true;
          } catch (\Exception $e) {
              Log::error("Failed to update feature flag: {$e->getMessage()}");
              return false;
          }
      }
      
      /**
       * Enable a feature for a specific user.
       *
       * @param string $feature
       * @param int $userId
       * @return bool
       */
      public function enableFeatureForUser(string $feature, int $userId): bool
      {
          $result = $this->updateUserFeatureFlag($feature, $userId, true);
          
          // Clear cache
          Cache::forget("feature:{$feature}:user:{$userId}");
          
          return $result;
      }
      
      /**
       * Disable a feature for a specific user.
       *
       * @param string $feature
       * @param int $userId
       * @return bool
       */
      public function disableFeatureForUser(string $feature, int $userId): bool
      {
          $result = $this->updateUserFeatureFlag($feature, $userId, false);
          
          // Clear cache
          Cache::forget("feature:{$feature}:user:{$userId}");
          
          return $result;
      }
      
      /**
       * Remove a user-specific feature override.
       *
       * @param string $feature
       * @param int $userId
       * @return bool
       */
      public function removeUserFeatureOverride(string $feature, int $userId): bool
      {
          try {
              DB::table('user_feature_flags')
                  ->where('feature', $feature)
                  ->where('user_id', $userId)
                  ->delete();
              
              // Clear cache
              Cache::forget("feature:{$feature}:user:{$userId}");
              
              Log::info("User feature override removed for '{$feature}' and user {$userId}");
              
              return true;
          } catch (\Exception $e) {
              Log::error("Failed to remove user feature override: {$e->getMessage()}");
              return false;
          }
      }
      
      /**
       * Update a user-specific feature flag.
       *
       * @param string $feature
       * @param int $userId
       * @param bool $enabled
       * @return bool
       */
      protected function updateUserFeatureFlag(string $feature, int $userId, bool $enabled): bool
      {
          try {
              DB::table('user_feature_flags')
                  ->updateOrInsert(
                      [
                          'feature' => $feature,
                          'user_id' => $userId,
                      ],
                      [
                          'enabled' => $enabled,
                          'updated_at' => now(),
                      ]
                  );
              
              Log::info("User feature flag '{$feature}' " . ($enabled ? 'enabled' : 'disabled') . " for user {$userId}");
              
              return true;
          } catch (\Exception $e) {
              Log::error("Failed to update user feature flag: {$e->getMessage()}");
              return false;
          }
      }
      
      /**
       * Get all feature flags.
       *
       * @return array
       */
      public function getAllFeatureFlags(): array
      {
          return Cache::remember('feature_flags:all', self::CACHE_TTL, function () {
              return DB::table('feature_flags')
                  ->select('feature', 'enabled', 'description', 'updated_at')
                  ->orderBy('feature')
                  ->get()
                  ->toArray();
          });
      }
      
      /**
       * Get feature flags for a specific user.
       *
       * @param int $userId
       * @return array
       */
      public function getUserFeatureFlags(int $userId): array
      {
          $cacheKey = "feature_flags:user:{$userId}";
          
          return Cache::remember($cacheKey, self::CACHE_TTL, function () use ($userId) {
              $globalFlags = $this->getAllFeatureFlags();
              $userOverrides = DB::table('user_feature_flags')
                  ->where('user_id', $userId)
                  ->select('feature', 'enabled', 'updated_at')
                  ->get()
                  ->keyBy('feature')
                  ->toArray();
              
              $result = [];
              
              foreach ($globalFlags as $flag) {
                  $feature = $flag->feature;
                  $result[$feature] = [
                      'feature' => $feature,
                      'enabled' => isset($userOverrides[$feature]) ? (bool) $userOverrides[$feature]->enabled : (bool) $flag->enabled,
                      'description' => $flag->description,
                      'has_override' => isset($userOverrides[$feature]),
                      'updated_at' => isset($userOverrides[$feature]) ? $userOverrides[$feature]->updated_at : $flag->updated_at,
                  ];
              }
              
              return $result;
          });
      }
      
      /**
       * Clear all feature flag caches.
       *
       * @return void
       */
      public function clearFeatureFlagCache(): void
      {
          Cache::forget('feature_flags_table_exists');
          Cache::forget('feature_flags:all');
          
          // Clear pattern-based caches
          $this->clearCachePattern('feature:*');
          $this->clearCachePattern('feature_flags:user:*');
      }
      
      /**
       * Clear cache entries matching a pattern.
       *
       * @param string $pattern
       * @return void
       */
      protected function clearCachePattern(string $pattern): void
      {
          // This is a simplified implementation
          // In a real application, you would use Redis SCAN or similar
          Log::info("Clearing cache pattern: {$pattern}");
      }
  }
  
  namespace App\Console\Commands;
  
  use Illuminate\Console\Command;
  use Illuminate\Support\Facades\DB;
  use Illuminate\Support\Facades\Schema;
  use Illuminate\Support\Facades\Log;
  
  class SafeMigration extends Command
  {
      /**
       * The name and signature of the console command.
       *
       * @var string
       */
      protected $signature = 'migrate:safe
                              {--pretend : Simulate the migration but don\'t run it}
                              {--force : Force the operation to run without confirmation}
                              {--step= : The number of migrations to run}
                              {--timeout=300 : Maximum execution time for each migration in seconds}
                              {--analyze : Analyze migrations for potential issues}';
      
      /**
       * The console command description.
       *
       * @var string
       */
      protected $description = 'Run database migrations with additional safety checks';
      
      /**
       * Execute the console command.
       */
      public function handle()
      {
          $pretend = $this->option('pretend');
          $force = $this->option('force');
          $step = $this->option('step');
          $timeout = $this->option('timeout');
          $analyze = $this->option('analyze');
          
          $this->info('Starting safe migration process...');
          
          // Check database connection
          if (!$this->checkDatabaseConnection()) {
              $this->error('Database connection failed. Aborting migration.');
              return Command::FAILURE;
          }
          
          // Get pending migrations
          $pendingMigrations = $this->getPendingMigrations();
          
          if (empty($pendingMigrations)) {
              $this->info('No pending migrations found.');
              return Command::SUCCESS;
          }
          
          $this->info('Found ' . count($pendingMigrations) . ' pending migrations:');
          foreach ($pendingMigrations as $migration) {
              $this->line('- ' . $migration);
          }
          
          // Analyze migrations if requested
          if ($analyze) {
              $this->analyzeMigrations($pendingMigrations);
          }
          
          // Confirm migration
          if (!$force && !$pretend) {
              if (!$this->confirm('Do you want to run these migrations?')) {
                  $this->info('Migration aborted.');
                  return Command::SUCCESS;
              }
          }
          
          // Create database backup before migration
          if (!$pretend) {
              $this->info('Creating database backup before migration...');
              $this->call('backup:database', [
                  '--compress' => true,
                  '--path' => 'backups/pre-migration',
              ]);
          }
          
          // Run migrations
          $options = ['--force' => true];
          
          if ($pretend) {
              $options['--pretend'] = true;
          }
          
          if ($step) {
              $options['--step'] = $step;
          }
          
          // Set timeout for migrations
          ini_set('max_execution_time', $timeout);
          
          $this->info('Running migrations...');
          $this->call('migrate', $options);
          
          // Reset timeout
          ini_set('max_execution_time', 60);
          
          if (!$pretend) {
              $this->info('Creating database backup after migration...');
              $this->call('backup:database', [
                  '--compress' => true,
                  '--path' => 'backups/post-migration',
              ]);
          }
          
          $this->info('Safe migration process completed successfully.');
          return Command::SUCCESS;
      }
      
      /**
       * Check database connection.
       *
       * @return bool
       */
      protected function checkDatabaseConnection(): bool
      {
          try {
              DB::connection()->getPdo();
              $this->info('Database connection successful.');
              return true;
          } catch (\Exception $e) {
              $this->error('Database connection error: ' . $e->getMessage());
              return false;
          }
      }
      
      /**
       * Get pending migrations.
       *
       * @return array
       */
      protected function getPendingMigrations(): array
      {
          // Get all migration files
          $migrationFiles = glob(database_path('migrations/*.php'));
          $migrationNames = array_map(function ($file) {
              return pathinfo($file, PATHINFO_FILENAME);
          }, $migrationFiles);
          
          // Get already run migrations
          $ranMigrations = DB::table('migrations')->pluck('migration')->toArray();
          
          // Find pending migrations
          return array_diff($migrationNames, $ranMigrations);
      }
      
      /**
       * Analyze migrations for potential issues.
       *
       * @param array $migrations
       * @return void
       */
      protected function analyzeMigrations(array $migrations): void
      {
          $this->info('Analyzing migrations for potential issues...');
          
          $issues = [];
          
          foreach ($migrations as $migration) {
              $file = database_path('migrations/' . $migration . '.php');
              $content = file_get_contents($file);
              
              // Check for potentially dangerous operations
              if (preg_match('/Schema::drop|dropIfExists|down\(\)|truncate|delete from/i', $content)) {
                  $issues[] = [
                      'migration' => $migration,
                      'issue' => 'Contains potentially destructive operations',
                      'severity' => 'high',
                  ];
              }
              
              // Check for missing indexes on foreign keys
              if (preg_match('/foreign\(.*?\)/i', $content) && !preg_match('/index\(.*?\)/i', $content)) {
                  $issues[] = [
                      'migration' => $migration,
                      'issue' => 'Foreign key without index',
                      'severity' => 'medium',
                  ];
              }
              
              // Check for ALTER TABLE operations
              if (preg_match('/DB::statement|raw\(|exec\(/i', $content)) {
                  $issues[] = [
                      'migration' => $migration,
                      'issue' => 'Contains raw SQL statements',
                      'severity' => 'medium',
                  ];
              }
              
              // Check for large table operations
              if (preg_match('/->change\(\)|renameColumn|modifyColumn/i', $content)) {
                  $issues[] = [
                      'migration' => $migration,
                      'issue' => 'Contains operations that may lock tables',
                      'severity' => 'medium',
                  ];
              }
          }
          
          if (empty($issues)) {
              $this->info('No issues found in migrations.');
              return;
          }
          
          $this->warn('Found ' . count($issues) . ' potential issues:');
          
          foreach ($issues as $issue) {
              $this->line('- ' . $issue['migration'] . ': ' . $issue['issue'] . ' (Severity: ' . $issue['severity'] . ')');
          }
          
          $this->warn('Please review these issues before proceeding with the migration.');
      }
  }
explanation: |
  This example demonstrates strategies for maintaining and updating Laravel applications with user model enhancements:
  
  1. **Enhanced Maintenance Mode**:
     - Custom maintenance mode implementation with additional options
     - Support for allowed IPs during maintenance
     - Bypass URLs for specific users
     - Custom maintenance messages
     - Status checking and reporting
  
  2. **Feature Flag System**:
     - Global feature flags for controlling feature availability
     - User-specific feature overrides
     - Caching for performance optimization
     - Clear separation between feature logic and implementation
     - Comprehensive management API
  
  3. **Safe Database Migrations**:
     - Pre-migration database backups
     - Connection verification before migration
     - Migration analysis for potential issues
     - Timeout controls for long-running migrations
     - Post-migration verification
  
  Key maintenance and update principles demonstrated:
  
  - **Zero-Downtime Updates**: Techniques to minimize or eliminate downtime during updates
  - **Gradual Feature Rollout**: Using feature flags to control feature availability
  - **Safe Schema Changes**: Approaches to safely modify database schemas
  - **Backup and Recovery**: Creating backups before potentially destructive operations
  - **Risk Analysis**: Identifying and mitigating risks in database migrations
  
  The implementation includes:
  
  - **Maintenance Mode Command**: Enhanced version of Laravel's built-in maintenance mode
  - **Feature Flag Service**: Comprehensive service for managing feature flags
  - **Safe Migration Command**: Extended migration command with additional safety features
  
  In a real Laravel application:
  - You would implement more sophisticated feature flag strategies
  - You would add A/B testing capabilities
  - You would implement blue-green deployments for zero-downtime updates
  - You would add more comprehensive migration analysis
  - You would implement automated rollback procedures
challenges:
  - Implement a blue-green deployment strategy for zero-downtime updates
  - Add A/B testing capabilities to the feature flag system
  - Create a web interface for managing feature flags
  - Implement automated migration testing in a staging environment
  - Add support for gradual feature rollout based on user segments
:::
