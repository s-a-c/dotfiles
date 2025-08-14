# 040 - Development Implementation

## Table of Contents

- [Development Environment](#development-environment)
- [Code Quality Standards](#code-quality-standards)
- [Testing Strategy](#testing-strategy)
- [Package Implementation](#package-implementation)
- [Development Workflow](#development-workflow)
- [Performance Optimization](#performance-optimization)

---

## Development Environment

### 🛠️ Local Development Setup

#### Laravel Herd Configuration

```bash
# Optimal Herd setup for development
herd secure                    # Enable HTTPS for local development
herd link 100-laravel-platform    # Create local domain
herd php 8.3                  # Ensure PHP 8.3 for optimal performance

# Environment variables for development
# .env.local
APP_ENV=local
APP_DEBUG=true
APP_URL=https://laravel-platform.test

# Development-specific configurations
CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
BROADCAST_DRIVER=reverb

# Event sourcing development
EVENT_SOURCING_CACHE_DRIVER=redis
EVENT_SOURCING_SNAPSHOT_FREQUENCY=100

# Development database
DB_CONNECTION=pgsql
DB_DATABASE=laravel_platform_dev
DB_USERNAME=postgres
DB_PASSWORD=password
```

#### Docker Development Stack

```yaml
# docker-compose.dev.yml
version: '3.8'
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    volumes:
      - .:/var/www/html
      - ./docker/php/conf.d:/usr/local/etc/php/conf.d
    ports:
      - '8080:8080'
    environment:
      - PHP_IDE_CONFIG=serverName=100-laravel-platform
    depends_on:
      - postgres
      - redis
      - typesense

  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: laravel_platform_dev
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_dev:/var/lib/postgresql/data
    ports:
      - '5432:5432'

  redis:
    image: redis:7-alpine
    ports:
      - '6379:6379'
    volumes:
      - redis_dev:/data

  typesense:
    image: typesense/typesense:0.25.2
    command: '--data-dir /data --api-key=development_key --enable-cors'
    volumes:
      - typesense_dev:/data
    ports:
      - '8108:8108'

volumes:
  postgres_dev:
  redis_dev:
  typesense_dev:
```

### 🎯 IDE Configuration

#### PHPStorm Optimization

```xml
<!-- .idea/php.xml -->
<project version="4">
  <component name="PhpProjectSharedConfiguration" php_language_level="8.3">
    <option name="suggestChangeDefaultLanguageLevel" value="false" />
  </component>
  <component name="PhpUnit">
    <phpunit_settings>
      <PhpUnitSettings configuration_file_path="$PROJECT_DIR$/phpunit.xml"
                      custom_loader_path="$PROJECT_DIR$/vendor/autoload.php"
                      use_configuration_file="true" />
    </phpunit_settings>
  </component>
</project>
```

#### VS Code Extensions

```json
// .vscode/extensions.json
{
  "recommendations": [
    "bmewburn.vscode-intelephense-client",
    "xdebug.php-debug",
    "ryannaddy.100-laravel-artisan",
    "onecentlin.100-laravel-blade",
    "bradlc.vscode-tailwindcss",
    "ms-vscode.vscode-typescript-next",
    "esbenp.prettier-vscode"
  ]
}
```

---

## Code Quality Standards

### 📋 PHP Standards & Static Analysis

#### PHPStan Configuration

```neon
# phpstan.neon
includes:
    - phpstan-baseline.neon
    - vendor/larastan/larastan/extension.neon
    - vendor/spatie/100-laravel-event-sourcing/extension.neon

parameters:
    level: 9
    paths:
        - app
        - config
        - database
        - routes
        - tests

    excludePaths:
        - app/Http/Middleware/TrustProxies.php
        - bootstrap/cache
        - storage

    checkMissingIterableValueType: false
    checkGenericClassInNonGenericObjectType: false

    ignoreErrors:
        - '#Call to an undefined method Illuminate\\Database\\Eloquent\\Builder#'
        - '#Access to an undefined property Livewire\\Component#'
```

#### Psalm Configuration

```xml
<!-- psalm.xml -->
<?xml version="1.0"?>
<psalm
    errorLevel="3"
    resolveFromConfigFile="true"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns="https://getpsalm.org/schema/config"
    xsi:schemaLocation="https://getpsalm.org/schema/config vendor/vimeo/psalm/config.xsd"
>
    <projectFiles>
        <directory name="app" />
        <directory name="config" />
        <directory name="database" />
        <directory name="routes" />
        <directory name="tests" />
        <ignoreFiles>
            <directory name="vendor" />
            <directory name="storage" />
            <directory name="bootstrap/cache" />
        </ignoreFiles>
    </projectFiles>

    <plugins>
        <pluginClass class="Psalm\LaravelPlugin\Plugin"/>
    </plugins>
</psalm>
```

#### PHP-CS-Fixer Rules

```php
<?php
// .php-cs-fixer.php
use PhpCsFixer\Config;
use PhpCsFixer\Finder;

$finder = Finder::create()
    ->in(__DIR__)
    ->name('*.php')
    ->notName('*.blade.php')
    ->exclude(['bootstrap', 'storage', 'vendor'])
    ->notPath('#bootstrap/cache#')
    ->notPath('#storage/#')
    ->notPath('#vendor/#');

return (new Config())
    ->setRules([
        '@PSR12' => true,
        '@PHP83Migration' => true,
        'array_syntax' => ['syntax' => 'short'],
        'ordered_imports' => ['sort_algorithm' => 'alpha'],
        'no_unused_imports' => true,
        'not_operator_with_successor_space' => true,
        'trailing_comma_in_multiline' => true,
        'phpdoc_scalar' => true,
        'unary_operator_spaces' => true,
        'binary_operator_spaces' => true,
        'blank_line_before_statement' => [
            'statements' => ['break', 'continue', 'declare', 'return', 'throw', 'try'],
        ],
        'phpdoc_single_line_var_spacing' => true,
        'phpdoc_var_without_name' => true,
        'method_argument_space' => [
            'on_multiline' => 'ensure_fully_multiline',
            'keep_multiple_spaces_after_comma' => true,
        ],
    ])
    ->setFinder($finder);
```

### 🧪 Code Architecture Rules

#### Architecture Testing with Pest

```php
<?php
// tests/Architecture/LayersTest.php
use Pest\Arch\Arch;

test('domain models should not depend on infrastructure')
    ->expect('App\Domain')
    ->not->toUse([
        'Illuminate\Http',
        'Livewire',
        'App\Http',
        'App\Livewire',
    ]);

test('controllers should be thin')
    ->expect('App\Http\Controllers')
    ->toHaveMethodsCount('<=', 7)
    ->toHaveLinesCount('<=', 150);

test('event handlers should only handle one event type')
    ->expect('App\Projectors')
    ->toExtend('Spatie\EventSourcing\Projectors\Projector')
    ->toHaveMethodsMatching('/^on[A-Z].*Event$/');

test('aggregates should follow naming conventions')
    ->expect('App\Domain\Aggregates')
    ->toExtend('Spatie\EventSourcing\AggregateRoots\AggregateRoot')
    ->toHaveSuffix('Aggregate');

test('events should be immutable')
    ->expect('App\Domain\Events')
    ->toBeReadonly()
    ->toImplement('Spatie\EventSourcing\StoredEvents\ShouldBeStored');
```

---

## Testing Strategy

### 🎯 Testing Pyramid

#### Unit Tests (70%)

```php
<?php
// tests/Unit/Domain/TaskAggregateTest.php
use App\Domain\Task\TaskAggregate;
use App\Domain\Task\Events\TaskWasCreated;

describe('Task Aggregate', function () {
    test('can create a new task', function () {
        $aggregate = TaskAggregate::retrieve(Str::uuid());

        $aggregate->createTask('Test Task', auth()->id());

        expect($aggregate->getRecordedEvents())
            ->toHaveCount(1)
            ->first()->toBeInstanceOf(TaskWasCreated::class);
    });

    test('cannot assign completed task', function () {
        $aggregate = TaskAggregate::retrieve(Str::uuid());

        $aggregate->createTask('Test Task', auth()->id())
                 ->markAsCompleted();

        expect(fn() => $aggregate->assignTo(auth()->id()))
            ->toThrow(CannotAssignCompletedTask::class);
    });
});
```

#### Integration Tests (20%)

```php
<?php
// tests/Feature/TaskManagementTest.php
use App\Domain\Task\TaskAggregate;
use App\Models\Task;

describe('Task Management Integration', function () {
    test('creating task updates read model', function () {
        $user = User::factory()->create();

        $this->actingAs($user)
             ->post('/api/tasks', [
                 'title' => 'Integration Test Task',
                 'description' => 'Testing full integration',
             ])
             ->assertSuccessful();

        expect(Task::where('title', 'Integration Test Task'))
            ->first()
            ->not->toBeNull()
            ->title->toBe('Integration Test Task');
    });

    test('task assignment triggers notification', function () {
        $creator = User::factory()->create();
        $assignee = User::factory()->create();

        Notification::fake();

        $this->actingAs($creator)
             ->post('/api/tasks', ['title' => 'Test Task'])
             ->json('PATCH', '/api/tasks/{ulid}/assign', [
                 'assigned_to' => $assignee->id,
             ]);

        Notification::assertSentTo(
            $assignee,
            TaskAssignedNotification::class
        );
    });
});
```

#### End-to-End Tests (10%)

```php
<?php
// tests/Browser/TaskWorkflowTest.php
use Laravel\Dusk\Browser;

describe('Task Workflow E2E', function () {
    test('complete task workflow works', function () {
        $user = User::factory()->create();

        $this->browse(function (Browser $browser) use ($user) {
            $browser->loginAs($user)
                   ->visit('/dashboard')
                   ->clickLink('Create Task')
                   ->type('title', 'E2E Test Task')
                   ->select('status', 'draft')
                   ->press('Create')
                   ->assertSee('Task created successfully')
                   ->assertSee('E2E Test Task');
        });
    });
});
```

### 📊 Coverage Requirements

#### PHPUnit Configuration

```xml
<!-- phpunit.xml -->
<phpunit bootstrap="vendor/autoload.php">
    <testsuites>
        <testsuite name="Unit">
            <directory suffix="Test.php">./tests/Unit</directory>
        </testsuite>
        <testsuite name="Feature">
            <directory suffix="Test.php">./tests/Feature</directory>
        </testsuite>
        <testsuite name="Browser">
            <directory suffix="Test.php">./tests/Browser</directory>
        </testsuite>
    </testsuites>

    <php>
        <env name="APP_ENV" value="testing"/>
        <env name="BCRYPT_ROUNDS" value="4"/>
        <env name="CACHE_DRIVER" value="array"/>
        <env name="DB_CONNECTION" value="sqlite"/>
        <env name="DB_DATABASE" value=":memory:"/>
        <env name="MAIL_MAILER" value="array"/>
        <env name="QUEUE_CONNECTION" value="sync"/>
        <env name="SESSION_DRIVER" value="array"/>
    </php>

    <source>
        <include>
            <directory suffix=".php">./app</directory>
        </include>
        <exclude>
            <directory suffix=".php">./app/Http/Middleware</directory>
            <file>./app/Http/Kernel.php</file>
        </exclude>
    </source>

    <coverage>
        <report>
            <html outputDirectory="coverage-html"/>
            <text outputFile="coverage.txt"/>
            <clover outputFile="coverage.xml"/>
        </report>
    </coverage>

    <logging>
        <junit outputFile="junit.xml"/>
    </logging>
</phpunit>
```

---

## Package Implementation

### 🏗️ Event Sourcing Implementation

#### Custom Event Store Optimization

```php
<?php
// app/EventStore/OptimizedEventStore.php
namespace App\EventStore;

use Spatie\EventSourcing\EventStores\EventStore;

class OptimizedEventStore extends EventStore
{
    public function store(StorableEvent $event): StoredEvent
    {
        // Use Snowflake ID for optimal performance
        $storedEvent = new StoredEvent([
            'id' => app(SnowflakeId::class)->generate(),
            'aggregate_uuid' => $event->aggregateRootUuid(),
            'aggregate_version' => $event->aggregateRootVersion(),
            'event_class' => get_class($event),
            'event_properties' => json_encode($event->toArray()),
            'meta_data' => json_encode($event->metaData()),
            'created_at' => now(),
        ]);

        $storedEvent->save();

        return $storedEvent;
    }

    public function getEvents(string $aggregateUuid): LazyCollection
    {
        return StoredEvent::query()
            ->where('aggregate_uuid', $aggregateUuid)
            ->orderBy('aggregate_version')
            ->cursor()
            ->map(fn($storedEvent) => $storedEvent->toStorableEvent());
    }
}
```

#### State Machine Integration

```php
<?php
// app/States/TaskState.php
use Spatie\ModelStates\State;
use Spatie\ModelStates\StateConfig;

abstract class TaskState extends State
{
    public static function config(): StateConfig
    {
        return parent::config()
            ->default(Draft::class)
            ->allowTransition(Draft::class, InProgress::class)
            ->allowTransition(InProgress::class, Review::class)
            ->allowTransition(Review::class, Completed::class)
            ->allowTransition([InProgress::class, Review::class], Draft::class);
    }
}

class Draft extends TaskState
{
    public function canTransitionTo(string $state): bool
    {
        return $state === InProgress::class;
    }
}

class InProgress extends TaskState
{
    public function canTransitionTo(string $state): bool
    {
        return in_array($state, [Review::class, Draft::class]);
    }
}
```

### 🔍 Search Implementation

#### Typesense Integration

```php
<?php
// app/Services/SearchService.php
namespace App\Services;

use Typesense\Client;

class SearchService
{
    public function __construct(private Client $client) {}

    public function searchTasks(string $query, array $filters = []): array
    {
        $searchParameters = [
            'q' => $query,
            'query_by' => 'title,description',
            'sort_by' => 'updated_at:desc',
            'per_page' => 20,
        ];

        if (!empty($filters['status'])) {
            $searchParameters['filter_by'] = "status:={$filters['status']}";
        }

        if (!empty($filters['assigned_to'])) {
            $searchParameters['filter_by'] =
                ($searchParameters['filter_by'] ?? '') .
                " && assigned_to:={$filters['assigned_to']}";
        }

        return $this->client
            ->collections['tasks']
            ->documents
            ->search($searchParameters);
    }

    public function indexTask(Task $task): void
    {
        $this->client
            ->collections['tasks']
            ->documents
            ->upsert($task->toSearchableArray());
    }
}
```

### 🔔 Real-time Features

#### Laravel Reverb Broadcasting

```php
<?php
// app/Broadcasting/TeamChannel.php
namespace App\Broadcasting;

use App\Models\User;

class TeamChannel
{
    public function join(User $user, int $teamId): array|bool
    {
        return $user->teams->contains('id', $teamId);
    }
}

// app/Events/TaskUpdated.php
class TaskUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public Task $task,
        public string $updateType = 'general'
    ) {}

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel("team.{$this->task->team_id}"),
            new PrivateChannel("task.{$this->task->ulid}"),
        ];
    }

    public function broadcastWith(): array
    {
        return [
            'task' => $this->task->only(['ulid', 'title', 'status']),
            'update_type' => $this->updateType,
            'timestamp' => now()->toISOString(),
        ];
    }
}
```

---

## Development Workflow

### 🔄 Git Workflow

#### Branch Strategy

```bash
# Main branches
main          # Production-ready code
develop       # Integration branch for features

# Feature branches
feature/task-management
feature/real-time-chat
feature/advanced-search

# Release branches
release/v1.0.0
release/v1.1.0

# Hotfix branches
hotfix/security-patch
hotfix/critical-bug-fix
```

#### Commit Convention

```bash
# Format: type(scope): description
feat(tasks): add task assignment functionality
fix(auth): resolve MFA verification issue
docs(api): update endpoint documentation
test(integration): add task workflow tests
refactor(events): optimize event store queries
perf(search): improve Typesense indexing speed
```

### 🧪 CI/CD Pipeline

#### GitHub Actions Workflow

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: testing
        options: >-
          --health-cmd pg_isready --health-interval 10s --health-timeout 5s --health-retries 5

      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping" --health-interval 10s --health-timeout 5s --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: 8.3
          extensions: pdo, pgsql, redis, pcntl, zip, intl
          coverage: xdebug

      - name: Install dependencies
        run: composer install --prefer-dist --no-interaction

      - name: Copy environment file
        run: cp .env.ci .env

      - name: Generate app key
        run: php artisan key:generate

      - name: Run migrations
        run: php artisan migrate --force

      - name: Run PHPStan
        run: vendor/bin/phpstan analyse --no-progress

      - name: Run Psalm
        run: vendor/bin/psalm --output-format=github

      - name: Run tests
        run: vendor/bin/pest --coverage --min=90

      - name: Upload coverage reports
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.xml

  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v4

      - name: Build production assets
        run: |
          npm ci
          npm run build

      - name: Deploy to staging
        run: |
          # Deployment scripts here
          echo "Deploying to staging environment"
```

### 📋 Code Review Checklist

#### Pull Request Template

```markdown
## Description

Brief description of the changes made.

## Type of Change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing

- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] No performance regression

## Code Quality

- [ ] PHPStan level 9 passes
- [ ] Psalm analysis passes
- [ ] Code follows PSR-12 standards
- [ ] No security vulnerabilities introduced

## Documentation

- [ ] Code is self-documenting
- [ ] Complex logic is commented
- [ ] API documentation updated (if applicable)
- [ ] Database changes documented

## Security Review

- [ ] No sensitive data exposed
- [ ] Proper input validation
- [ ] Authorization checks in place
- [ ] SQL injection prevention verified
```

---

## Performance Optimization

### ⚡ Database Optimization

#### Query Performance Monitoring

```php
<?php
// app/Providers/AppServiceProvider.php
public function boot(): void
{
    if (app()->isLocal()) {
        DB::listen(function ($query) {
            if ($query->time > 100) { // Log slow queries
                Log::warning('Slow query detected', [
                    'sql' => $query->sql,
                    'bindings' => $query->bindings,
                    'time' => $query->time,
                ]);
            }
        });
    }
}

// Query optimization service
class QueryOptimizer
{
    public function optimizeTaskQueries(): void
    {
        // Add composite indexes for common queries
        Schema::table('tasks', function (Blueprint $table) {
            $table->index(['team_id', 'status', 'updated_at']);
            $table->index(['assigned_to', 'status']);
            $table->index(['created_at', 'status']);
        });
    }
}
```

#### Eager Loading Optimization

```php
<?php
// Optimized repository pattern
class TaskRepository
{
    public function getTeamTasks(int $teamId): Collection
    {
        return Task::with([
            'assignedUser:id,name,email',
            'creator:id,name',
            'comments' => fn($query) => $query->latest()->limit(3),
            'attachments:id,task_id,filename,size',
        ])
        ->where('team_id', $teamId)
        ->orderBy('updated_at', 'desc')
        ->get();
    }

    public function getTaskWithHistory(string $ulid): Task
    {
        return Task::with([
            'assignedUser',
            'creator',
            'comments.author',
            'attachments',
            'stateHistory' => fn($query) => $query->orderBy('created_at'),
        ])
        ->where('ulid', $ulid)
        ->firstOrFail();
    }
}
```

### 💾 Caching Strategy

#### Multi-Layer Cache Implementation

```php
<?php
// app/Services/CacheService.php
class CacheService
{
    public function rememberTeamTasks(int $teamId, int $ttl = 300): Collection
    {
        return Cache::tags(['tasks', "team:$teamId"])
            ->remember("tasks:team:$teamId", $ttl, function () use ($teamId) {
                return app(TaskRepository::class)->getTeamTasks($teamId);
            });
    }

    public function invalidateTeamCache(int $teamId): void
    {
        Cache::tags(["team:$teamId"])->flush();
    }

    public function warmupCache(): void
    {
        // Warmup frequently accessed data
        Team::all()->each(function ($team) {
            $this->rememberTeamTasks($team->id);
        });
    }
}
```

### 🔄 Background Processing

#### Optimized Queue Configuration

```php
<?php
// config/queue.php
return [
    'default' => env('QUEUE_CONNECTION', 'redis'),

    'connections' => [
        'redis' => [
            'driver' => 'redis',
            'connection' => 'default',
            'queue' => env('REDIS_QUEUE', 'default'),
            'retry_after' => 90,
            'block_for' => 5, // Optimize for low latency
            'after_commit' => false,
        ],

        'redis-high' => [
            'driver' => 'redis',
            'connection' => 'default',
            'queue' => 'high-priority',
            'retry_after' => 60,
            'block_for' => 2,
        ],
    ],
];

// Job optimization
class ProcessTaskUpdate implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public $tries = 3;
    public $backoff = [10, 30, 60]; // Progressive backoff
    public $timeout = 120;

    public function handle(): void
    {
        // Efficient job processing
        $this->updateReadModels();
        $this->broadcastUpdate();
        $this->sendNotifications();
    }

    public function failed(Throwable $exception): void
    {
        Log::error('Task update job failed', [
            'task_id' => $this->task->id,
            'exception' => $exception->getMessage(),
        ]);
    }
}
```

---

**Cross-References:**

- [030 - Software Architecture](030-software-architecture.md) - Architecture patterns
- [050 - Security Compliance](050-security-compliance.md) - Security implementations
- [080 - Implementation Roadmap](080-implementation-roadmap.md) - Development timeline

_Last Updated: [Current Date]_ _Document Version: 1.0_
