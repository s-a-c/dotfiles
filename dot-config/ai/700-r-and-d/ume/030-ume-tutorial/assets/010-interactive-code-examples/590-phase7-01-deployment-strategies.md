# Deployment Strategies

:::interactive-code
title: Implementing Effective Deployment Strategies
description: This example demonstrates how to implement robust deployment strategies for Laravel applications with user model enhancements, focusing on zero-downtime deployments and rollback capabilities.
language: php
editable: true
code: |
  <?php
  
  namespace App\Console\Commands;
  
  use Illuminate\Console\Command;
  use Illuminate\Support\Facades\Artisan;
  use Illuminate\Support\Facades\DB;
  use Illuminate\Support\Facades\Log;
  use Illuminate\Support\Facades\Schema;
  
  class DeployApplication extends Command
  {
      /**
       * The name and signature of the console command.
       *
       * @var string
       */
      protected $signature = 'app:deploy 
                              {--mode=standard : Deployment mode (standard, blue-green, canary)}
                              {--percentage=10 : Percentage of traffic for canary deployment}
                              {--skip-tests : Skip running tests}
                              {--force : Force deployment without confirmation}';
      
      /**
       * The console command description.
       *
       * @var string
       */
      protected $description = 'Deploy the application using the specified strategy';
      
      /**
       * Execute the console command.
       */
      public function handle()
      {
          $mode = $this->option('mode');
          $this->info("Starting deployment in {$mode} mode...");
          
          // Validate deployment mode
          if (!in_array($mode, ['standard', 'blue-green', 'canary'])) {
              $this->error('Invalid deployment mode. Available modes: standard, blue-green, canary');
              return Command::FAILURE;
          }
          
          // Check if we should run tests
          if (!$this->option('skip-tests')) {
              if (!$this->runTests()) {
                  $this->error('Tests failed. Deployment aborted.');
                  return Command::FAILURE;
              }
          } else {
              $this->warn('Skipping tests as requested.');
          }
          
          // Confirm deployment if not forced
          if (!$this->option('force')) {
              if (!$this->confirm('Are you sure you want to deploy the application?')) {
                  $this->info('Deployment aborted.');
                  return Command::SUCCESS;
              }
          }
          
          // Execute deployment based on selected mode
          switch ($mode) {
              case 'standard':
                  return $this->standardDeploy();
              case 'blue-green':
                  return $this->blueGreenDeploy();
              case 'canary':
                  $percentage = $this->option('percentage');
                  return $this->canaryDeploy($percentage);
          }
      }
      
      /**
       * Run the application tests.
       *
       * @return bool
       */
      protected function runTests(): bool
      {
          $this->info('Running tests...');
          
          // Run PHPUnit tests
          $this->comment('Running PHPUnit tests...');
          $phpunitResult = $this->executeCommand('vendor/bin/phpunit');
          
          if (!$phpunitResult) {
              $this->error('PHPUnit tests failed.');
              return false;
          }
          
          // Run Dusk tests if available
          if (file_exists(base_path('tests/Browser'))) {
              $this->comment('Running Dusk tests...');
              $duskResult = $this->executeCommand('php artisan dusk');
              
              if (!$duskResult) {
                  $this->error('Dusk tests failed.');
                  return false;
              }
          }
          
          $this->info('All tests passed successfully.');
          return true;
      }
      
      /**
       * Execute a standard deployment.
       *
       * @return int
       */
      protected function standardDeploy(): int
      {
          $this->info('Executing standard deployment...');
          
          try {
              // Put application in maintenance mode
              $this->comment('Enabling maintenance mode...');
              Artisan::call('down', ['--refresh' => 15]);
              
              // Pull latest changes
              $this->comment('Pulling latest changes...');
              $this->executeCommand('git pull origin main');
              
              // Install dependencies
              $this->comment('Installing dependencies...');
              $this->executeCommand('composer install --no-dev --optimize-autoloader');
              
              // Clear caches
              $this->comment('Clearing caches...');
              Artisan::call('optimize:clear');
              
              // Run database migrations
              $this->comment('Running database migrations...');
              Artisan::call('migrate', ['--force' => true]);
              
              // Restart queue workers
              $this->comment('Restarting queue workers...');
              Artisan::call('queue:restart');
              
              // Optimize application
              $this->comment('Optimizing application...');
              Artisan::call('optimize');
              
              // Take application out of maintenance mode
              $this->comment('Disabling maintenance mode...');
              Artisan::call('up');
              
              $this->info('Standard deployment completed successfully.');
              return Command::SUCCESS;
          } catch (\Exception $e) {
              $this->error('Deployment failed: ' . $e->getMessage());
              
              // Attempt to recover
              $this->warn('Attempting to recover...');
              Artisan::call('up');
              
              return Command::FAILURE;
          }
      }
      
      /**
       * Execute a blue-green deployment.
       *
       * @return int
       */
      protected function blueGreenDeploy(): int
      {
          $this->info('Executing blue-green deployment...');
          
          try {
              // Determine current environment (blue or green)
              $currentEnv = $this->getCurrentEnvironment();
              $targetEnv = $currentEnv === 'blue' ? 'green' : 'blue';
              
              $this->comment("Current environment: {$currentEnv}");
              $this->comment("Target environment: {$targetEnv}");
              
              // Prepare the target environment
              $this->prepareEnvironment($targetEnv);
              
              // Verify the target environment
              if (!$this->verifyEnvironment($targetEnv)) {
                  $this->error('Target environment verification failed.');
                  return Command::FAILURE;
              }
              
              // Switch traffic to the target environment
              $this->switchTraffic($targetEnv);
              
              // Monitor the new environment
              $this->monitorDeployment();
              
              $this->info('Blue-green deployment completed successfully.');
              return Command::SUCCESS;
          } catch (\Exception $e) {
              $this->error('Blue-green deployment failed: ' . $e->getMessage());
              
              // Rollback to the previous environment
              $this->warn('Rolling back to previous environment...');
              $this->switchTraffic($currentEnv);
              
              return Command::FAILURE;
          }
      }
      
      /**
       * Execute a canary deployment.
       *
       * @param int $percentage
       * @return int
       */
      protected function canaryDeploy(int $percentage): int
      {
          $this->info("Executing canary deployment with {$percentage}% traffic...");
          
          try {
              // Prepare the canary environment
              $this->comment('Preparing canary environment...');
              $this->prepareCanaryEnvironment();
              
              // Route percentage of traffic to canary
              $this->comment("Routing {$percentage}% of traffic to canary...");
              $this->routeTrafficToCanary($percentage);
              
              // Monitor canary metrics
              $this->comment('Monitoring canary metrics...');
              $canaryHealthy = $this->monitorCanaryHealth(5); // Monitor for 5 minutes
              
              if (!$canaryHealthy) {
                  $this->error('Canary deployment shows issues. Rolling back.');
                  $this->routeTrafficToCanary(0);
                  return Command::FAILURE;
              }
              
              // Gradually increase traffic to canary
              for ($p = $percentage + 20; $p <= 100; $p += 20) {
                  $this->comment("Increasing canary traffic to {$p}%...");
                  $this->routeTrafficToCanary($p);
                  
                  // Monitor after each increase
                  if (!$this->monitorCanaryHealth(2)) { // Monitor for 2 minutes
                      $this->error("Issues detected at {$p}% traffic. Rolling back.");
                      $this->routeTrafficToCanary(0);
                      return Command::FAILURE;
                  }
              }
              
              // Finalize deployment
              $this->comment('Finalizing canary deployment...');
              $this->finalizeCanaryDeployment();
              
              $this->info('Canary deployment completed successfully.');
              return Command::SUCCESS;
          } catch (\Exception $e) {
              $this->error('Canary deployment failed: ' . $e->getMessage());
              
              // Rollback canary deployment
              $this->warn('Rolling back canary deployment...');
              $this->routeTrafficToCanary(0);
              
              return Command::FAILURE;
          }
      }
      
      /**
       * Get the current environment (blue or green).
       *
       * @return string
       */
      protected function getCurrentEnvironment(): string
      {
          // In a real implementation, this would check the actual environment
          // For this example, we'll simulate it
          return file_exists(storage_path('framework/environment')) 
              ? file_get_contents(storage_path('framework/environment')) 
              : 'blue';
      }
      
      /**
       * Prepare the target environment for deployment.
       *
       * @param string $environment
       * @return void
       */
      protected function prepareEnvironment(string $environment): void
      {
          $this->comment("Preparing {$environment} environment...");
          
          // Clone the application to the target environment
          $this->executeCommand("git clone --depth 1 https://github.com/your-org/your-repo.git /var/www/{$environment}");
          
          // Install dependencies
          $this->executeCommand("cd /var/www/{$environment} && composer install --no-dev --optimize-autoloader");
          
          // Copy environment file
          $this->executeCommand("cp .env.{$environment} /var/www/{$environment}/.env");
          
          // Run migrations
          $this->executeCommand("cd /var/www/{$environment} && php artisan migrate --force");
          
          // Optimize application
          $this->executeCommand("cd /var/www/{$environment} && php artisan optimize");
      }
      
      /**
       * Verify the target environment is ready.
       *
       * @param string $environment
       * @return bool
       */
      protected function verifyEnvironment(string $environment): bool
      {
          $this->comment("Verifying {$environment} environment...");
          
          // Check if the application is accessible
          $healthCheckUrl = "https://{$environment}.example.com/api/health-check";
          $response = $this->executeCommand("curl -s -o /dev/null -w '%{http_code}' {$healthCheckUrl}");
          
          return trim($response) === '200';
      }
      
      /**
       * Switch traffic to the target environment.
       *
       * @param string $environment
       * @return void
       */
      protected function switchTraffic(string $environment): void
      {
          $this->comment("Switching traffic to {$environment} environment...");
          
          // Update load balancer configuration
          $this->executeCommand("aws elbv2 modify-listener --listener-arn arn:aws:elasticloadbalancing:region:account-id:listener/app/my-load-balancer/50dc6c495c0c9188/f2f7dc8efc522ab2 --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:region:account-id:targetgroup/{$environment}-target-group/73e2d6bc24d8a067");
          
          // Update the current environment marker
          file_put_contents(storage_path('framework/environment'), $environment);
      }
      
      /**
       * Monitor the deployment for issues.
       *
       * @return bool
       */
      protected function monitorDeployment(): bool
      {
          $this->comment('Monitoring deployment for issues...');
          
          // Simulate monitoring for 30 seconds
          $this->executeCommand('sleep 5');
          
          // Check error rates
          $errorRate = rand(0, 5); // Simulate error rate percentage
          $this->comment("Current error rate: {$errorRate}%");
          
          // Check response times
          $responseTime = rand(50, 200); // Simulate response time in ms
          $this->comment("Average response time: {$responseTime}ms");
          
          return $errorRate < 2 && $responseTime < 150;
      }
      
      /**
       * Prepare the canary environment.
       *
       * @return void
       */
      protected function prepareCanaryEnvironment(): void
      {
          $this->comment('Preparing canary environment...');
          
          // Clone the application to the canary environment
          $this->executeCommand('git clone --depth 1 https://github.com/your-org/your-repo.git /var/www/canary');
          
          // Install dependencies
          $this->executeCommand('cd /var/www/canary && composer install --no-dev --optimize-autoloader');
          
          // Copy environment file
          $this->executeCommand('cp .env.canary /var/www/canary/.env');
          
          // Run migrations
          $this->executeCommand('cd /var/www/canary && php artisan migrate --force');
          
          // Optimize application
          $this->executeCommand('cd /var/www/canary && php artisan optimize');
      }
      
      /**
       * Route a percentage of traffic to the canary environment.
       *
       * @param int $percentage
       * @return void
       */
      protected function routeTrafficToCanary(int $percentage): void
      {
          $this->comment("Routing {$percentage}% of traffic to canary...");
          
          // Update load balancer configuration for weighted routing
          $this->executeCommand("aws elbv2 modify-listener --listener-arn arn:aws:elasticloadbalancing:region:account-id:listener/app/my-load-balancer/50dc6c495c0c9188/f2f7dc8efc522ab2 --default-actions Type=forward,ForwardConfig='{\"TargetGroups\":[{\"TargetGroupArn\":\"arn:aws:elasticloadbalancing:region:account-id:targetgroup/production-target-group/73e2d6bc24d8a067\",\"Weight\":". (100 - $percentage) ."},{\"TargetGroupArn\":\"arn:aws:elasticloadbalancing:region:account-id:targetgroup/canary-target-group/73e2d6bc24d8a067\",\"Weight\":{$percentage}}]}'");
      }
      
      /**
       * Monitor the health of the canary deployment.
       *
       * @param int $minutes
       * @return bool
       */
      protected function monitorCanaryHealth(int $minutes): bool
      {
          $this->comment("Monitoring canary health for {$minutes} minutes...");
          
          // Simulate monitoring for a shorter period in this example
          $this->executeCommand("sleep " . ($minutes * 2));
          
          // Check error rates
          $errorRate = rand(0, 5); // Simulate error rate percentage
          $this->comment("Canary error rate: {$errorRate}%");
          
          // Check response times
          $responseTime = rand(50, 200); // Simulate response time in ms
          $this->comment("Canary average response time: {$responseTime}ms");
          
          return $errorRate < 2 && $responseTime < 150;
      }
      
      /**
       * Finalize the canary deployment.
       *
       * @return void
       */
      protected function finalizeCanaryDeployment(): void
      {
          $this->comment('Finalizing canary deployment...');
          
          // Update the production environment with canary code
          $this->executeCommand('rsync -av --delete /var/www/canary/ /var/www/production/');
          
          // Route all traffic back to production
          $this->routeTrafficToCanary(0);
          
          // Clean up canary environment
          $this->executeCommand('rm -rf /var/www/canary');
      }
      
      /**
       * Execute a shell command.
       *
       * @param string $command
       * @return bool|string
       */
      protected function executeCommand(string $command)
      {
          // In a real implementation, this would execute the command
          // For this example, we'll simulate it
          $this->line("Executing: {$command}");
          
          // Simulate command execution
          if (strpos($command, 'curl') !== false) {
              return '200';
          }
          
          if (strpos($command, 'phpunit') !== false || strpos($command, 'dusk') !== false) {
              // 95% chance of tests passing
              return rand(1, 100) <= 95;
          }
          
          return true;
      }
  }
explanation: |
  This example demonstrates different deployment strategies for Laravel applications with user model enhancements:
  
  1. **Standard Deployment**: A traditional deployment approach with maintenance mode:
     - Puts the application in maintenance mode during deployment
     - Pulls the latest code changes
     - Installs dependencies and optimizes the application
     - Runs database migrations
     - Restarts queue workers
     - Takes the application out of maintenance mode
  
  2. **Blue-Green Deployment**: A zero-downtime deployment strategy:
     - Maintains two identical environments (blue and green)
     - Deploys to the inactive environment
     - Verifies the new environment is working correctly
     - Switches traffic from the active to the newly deployed environment
     - Monitors for issues after the switch
     - Allows for immediate rollback by switching traffic back
  
  3. **Canary Deployment**: A gradual rollout strategy:
     - Deploys the new version to a separate environment
     - Routes a small percentage of traffic to the new version
     - Monitors the health of the new version
     - Gradually increases traffic to the new version
     - Rolls back immediately if issues are detected
     - Finalizes the deployment when fully validated
  
  Key features of the implementation:
  
  - **Pre-deployment Testing**: Runs automated tests before deployment
  - **Deployment Confirmation**: Requires confirmation unless forced
  - **Error Handling**: Catches exceptions and attempts recovery
  - **Monitoring**: Checks for issues during and after deployment
  - **Rollback Capabilities**: Provides mechanisms to revert to previous state
  - **Environment Verification**: Ensures the new environment is working correctly
  - **Traffic Management**: Controls how traffic is routed during deployment
  
  In a real Laravel application:
  - You would integrate with actual deployment tools and services
  - You would implement more sophisticated health checks
  - You would add detailed logging and notifications
  - You would include database backup and restore procedures
  - You would implement more comprehensive monitoring
challenges:
  - Implement a deployment strategy that handles database schema changes without downtime
  - Add support for feature flags to enable/disable features during deployment
  - Create a deployment pipeline with automated testing and approval stages
  - Implement a rollback mechanism that handles database migrations
  - Add support for deploying to multiple regions or data centers
:::
