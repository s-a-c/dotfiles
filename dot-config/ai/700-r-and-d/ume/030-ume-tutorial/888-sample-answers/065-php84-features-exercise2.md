# PHP 8.4 Features - Exercise 2 Sample Answer

<link rel="stylesheet" href="../../assets/css/styles.css">
<link rel="stylesheet" href="../../assets/css/ume-docs-enhancements.css">
<link rel="stylesheet" href="../../assets/css/interactive-code.css">
<script src="../../assets/js/ume-docs-enhancements.js"></script>
<script src="../../assets/js/interactive-code.js"></script>

<ul class="breadcrumb-navigation">
    <li><a href="../../000-index.md">UME Tutorial</a></li>
    <li><a href="../000-index.md">UME Tutorial</a></li>
    <li><a href="./000-index.md">Sample Answers</a></li>
    <li><a href="./065-php84-features-exercise2.md">PHP 8.4 Features - Exercise 2</a></li>
</ul>

## Exercise 2: Service Provider with Class Instantiation Without Parentheses

### Problem Statement

Implement a service provider that registers services using class instantiation without parentheses, with various classes that have different constructor requirements.

### Solution

First, let's create the required classes:

#### Logger.php
```php
<?php

class Logger
{
    /**
     * Log a message
     */
    public function log(string $message): void
    {
        echo "[LOG] " . date('Y-m-d H:i:s') . " - $message\n";
    }
}
```

#### UserRepository.php
```php
<?php

class UserRepository
{
    private array $users = [];
    
    /**
     * Find a user by ID
     */
    public function findById(int $id): ?array
    {
        return $this->users[$id] ?? null;
    }
    
    /**
     * Save a user
     */
    public function save(array $user): void
    {
        $this->users[$user['id']] = $user;
    }
    
    /**
     * Get all users
     */
    public function all(): array
    {
        return $this->users;
    }
}
```

#### EmailService.php
```php
<?php

class EmailService
{
    private Logger $logger;
    
    /**
     * Constructor requires a Logger
     */
    public function __construct(Logger $logger)
    {
        $this->logger = $logger;
    }
    
    /**
     * Send an email
     */
    public function send(string $to, string $subject, string $body): bool
    {
        $this->logger->log("Sending email to $to with subject: $subject");
        
        // Email sending logic would go here
        
        return true;
    }
}
```

#### UserService.php
```php
<?php

class UserService
{
    private UserRepository $userRepository;
    private EmailService $emailService;
    
    /**
     * Constructor requires UserRepository and EmailService
     */
    public function __construct(UserRepository $userRepository, EmailService $emailService)
    {
        $this->userRepository = $userRepository;
        $this->emailService = $emailService;
    }
    
    /**
     * Create a new user
     */
    public function createUser(array $userData): array
    {
        // Add user to repository
        $this->userRepository->save($userData);
        
        // Send welcome email
        $this->emailService->send(
            $userData['email'],
            'Welcome to our platform',
            'Thank you for registering!'
        );
        
        return $userData;
    }
    
    /**
     * Get user by ID
     */
    public function getUserById(int $id): ?array
    {
        return $this->userRepository->findById($id);
    }
}
```

#### ServiceProvider.php
```php
<?php

class ServiceProvider
{
    private array $services = [];
    
    /**
     * Register all services
     */
    public function register(): void
    {
        // Register Logger (no constructor parameters)
        $this->singleton(Logger::class, function () {
            return new Logger; // No parentheses needed in PHP 8.4
        });
        
        // Register UserRepository (no constructor parameters)
        $this->singleton(UserRepository::class, function () {
            return new UserRepository; // No parentheses needed in PHP 8.4
        });
        
        // Register EmailService (requires Logger)
        $this->singleton(EmailService::class, function () {
            return new EmailService($this->resolve(Logger::class));
        });
        
        // Register UserService (requires UserRepository and EmailService)
        $this->singleton(UserService::class, function () {
            return new UserService(
                $this->resolve(UserRepository::class),
                $this->resolve(EmailService::class)
            );
        });
    }
    
    /**
     * Register a singleton service
     */
    public function singleton(string $abstract, callable $concrete): void
    {
        $this->services[$abstract] = [
            'concrete' => $concrete,
            'instance' => null,
        ];
    }
    
    /**
     * Resolve a service
     */
    public function resolve(string $abstract)
    {
        if (!isset($this->services[$abstract])) {
            throw new Exception("Service $abstract not registered");
        }
        
        $service = $this->services[$abstract];
        
        // Return existing instance if already resolved
        if ($service['instance'] !== null) {
            return $service['instance'];
        }
        
        // Create new instance
        $instance = $service['concrete']();
        
        // Store instance for future resolves
        $this->services[$abstract]['instance'] = $instance;
        
        return $instance;
    }
}
```

### Usage Example

```php
// Create and register services
$serviceProvider = new ServiceProvider;
$serviceProvider->register();

// Resolve services
$logger = $serviceProvider->resolve(Logger::class);
$userRepository = $serviceProvider->resolve(UserRepository::class);
$emailService = $serviceProvider->resolve(EmailService::class);
$userService = $serviceProvider->resolve(UserService::class);

// Use the services
$logger->log('Application started');

$user = [
    'id' => 1,
    'name' => 'John Doe',
    'email' => 'john.doe@example.com',
];

$userService->createUser($user);

$retrievedUser = $userService->getUserById(1);
$logger->log('Retrieved user: ' . json_encode($retrievedUser));
```

### Expected Output

```
[LOG] 2024-05-11 14:30:00 - Application started
[LOG] 2024-05-11 14:30:00 - Sending email to john.doe@example.com with subject: Welcome to our platform
[LOG] 2024-05-11 14:30:00 - Retrieved user: {"id":1,"name":"John Doe","email":"john.doe@example.com"}
```

### Explanation

1. **Class Instantiation Without Parentheses**:
   - For classes with no constructor parameters (`Logger` and `UserRepository`), we use the PHP 8.4 syntax without parentheses.
   - For classes with required constructor parameters (`EmailService` and `UserService`), we still use parentheses.

2. **Service Provider Implementation**:
   - The `ServiceProvider` class manages the registration and resolution of services.
   - It uses the singleton pattern to ensure only one instance of each service is created.
   - Services are lazy-loaded, meaning they're only instantiated when first requested.

3. **Dependency Injection**:
   - Each service receives its dependencies through the constructor.
   - The service provider resolves these dependencies automatically.
   - This creates a clean dependency graph where each service only knows about its direct dependencies.

4. **Service Registration**:
   - Services are registered with a factory function that creates the instance.
   - The factory function can use other services by resolving them from the provider.

5. **Service Resolution**:
   - When a service is requested, the provider checks if an instance already exists.
   - If not, it calls the factory function to create a new instance.
   - The instance is then cached for future requests.

### Key Concepts

1. **Class Instantiation Without Parentheses**: PHP 8.4 allows omitting parentheses when instantiating classes with no constructor parameters.
2. **Dependency Injection**: Services receive their dependencies through the constructor.
3. **Service Container**: The service provider acts as a container for managing service instances.
4. **Singleton Pattern**: Each service has only one instance throughout the application.
5. **Lazy Loading**: Services are only instantiated when they're needed.

### Best Practices

1. **Use Type Hints**: Always use type hints in constructor parameters for better type safety.
2. **Register Dependencies First**: Register services in the correct order, with dependencies registered before the services that need them.
3. **Keep Services Focused**: Each service should have a single responsibility.
4. **Document Service Requirements**: Clearly document what dependencies each service needs.
5. **Handle Missing Services**: Provide clear error messages when a service can't be resolved.

### Variations

You could extend this solution in several ways:

1. **Interface Binding**: Allow binding interfaces to concrete implementations.
2. **Factory Services**: Support services that need to be created fresh each time.
3. **Tagged Services**: Group services by tags for easier management.
4. **Configuration Parameters**: Allow passing configuration parameters to services.
5. **Service Providers**: Split service registration into multiple providers for better organization.
