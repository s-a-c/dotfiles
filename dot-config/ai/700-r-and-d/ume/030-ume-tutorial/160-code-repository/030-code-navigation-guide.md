# Code Navigation Guide

<link rel="stylesheet" href="../assets/css/styles.css">

This guide will help you efficiently navigate the UME codebase, understand its structure, and find the code you're looking for quickly. Whether you're exploring the code for learning purposes or making contributions, these navigation strategies will save you time and effort.

## Repository Structure Overview

All UME repositories follow a consistent structure based on Laravel conventions, with some additional organization for UME-specific features:

```
repository-root/
├── app/
│   ├── Actions/         # Action classes for single responsibilities
│   ├── Attributes/      # PHP 8 Attributes
│   ├── Console/         # Artisan commands
│   ├── Events/          # Event classes
│   ├── Exceptions/      # Custom exceptions
│   ├── Http/
│   │   ├── Controllers/ # Controllers
│   │   ├── Middleware/  # Middleware
│   │   └── Requests/    # Form requests
│   ├── Listeners/       # Event listeners
│   ├── Models/          # Eloquent models
│   ├── Policies/        # Authorization policies
│   ├── Providers/       # Service providers
│   ├── Services/        # Service classes
│   ├── States/          # State machine classes
│   └── Traits/          # Reusable traits
├── config/              # Configuration files
├── database/
│   ├── factories/       # Model factories
│   ├── migrations/      # Database migrations
│   └── seeders/         # Database seeders
├── resources/
│   ├── css/             # CSS files
│   ├── js/              # JavaScript files
│   └── views/           # Blade templates
├── routes/              # Route definitions
└── tests/               # Test files
```

## Finding Code by Feature

### User Management

The core user management functionality is spread across several key areas:

1. **User Models**:
   - Base User model: `app/Models/User.php`
   - User type models: `app/Models/Admin.php`, `app/Models/Manager.php`, etc.
   - User-related traits: `app/Traits/HasUlid.php`, `app/Traits/HasUserTracking.php`

2. **Authentication**:
   - Fortify configuration: `app/Providers/FortifyServiceProvider.php`
   - Authentication actions: `app/Actions/Fortify/`
   - Login/registration views: `resources/views/auth/`

3. **User Profiles**:
   - Profile controller: `app/Http/Controllers/ProfileController.php`
   - Profile views: `resources/views/profile/`
   - File upload service: `app/Services/FileUploadService.php`

4. **User States**:
   - State definitions: `app/States/UserState.php`
   - State transitions: `app/Transitions/`

### Team Management

Team functionality is organized as follows:

1. **Team Models**:
   - Team model: `app/Models/Team.php`
   - Team-user relationships: Defined in both `User.php` and `Team.php`

2. **Team UI**:
   - Team controllers: `app/Http/Controllers/TeamController.php`
   - Team views: `resources/views/teams/`
   - Team components: `resources/views/components/teams/`

3. **Team Permissions**:
   - Permission model: `app/Models/Permission.php`
   - Role model: `app/Models/Role.php`
   - Permission service: `app/Services/TeamPermissionService.php`

4. **Team Hierarchy**:
   - Hierarchy relationships: Defined in `Team.php`
   - Organization service: `app/Services/OrganizationService.php`

### Real-time Features

Real-time functionality is organized as follows:

1. **WebSockets**:
   - WebSockets configuration: `config/websockets.php`
   - Reverb configuration: `config/reverb.php`

2. **Events and Broadcasting**:
   - Event classes: `app/Events/`
   - Broadcast channels: `routes/channels.php`

3. **Presence and Activity**:
   - Presence service: `app/Services/PresenceService.php`
   - Activity service: `app/Services/ActivityService.php`
   - JavaScript integration: `resources/js/presence.js`

## Navigation by Implementation Phase

Each phase of the UME implementation focuses on different aspects of the system:

### Phase 0: Foundation

Key directories and files:
- `composer.json` - Project dependencies
- `config/` - Configuration files
- `app/Attributes/` - PHP 8 Attribute definitions
- `resources/views/components/` - Blade components

### Phase 1: Core Models

Key directories and files:
- `database/migrations/` - Database structure
- `app/Models/` - Eloquent models
- `app/Traits/` - Reusable traits
- `database/factories/` - Model factories
- `tests/Unit/Models/` - Model tests

### Phase 2: Auth & Profiles

Key directories and files:
- `app/Providers/FortifyServiceProvider.php` - Auth configuration
- `resources/views/auth/` - Authentication views
- `app/Http/Controllers/ProfileController.php` - Profile management
- `resources/views/profile/` - Profile views
- `app/States/` - State machine implementation

### Phase 3: Teams & Permissions

Key directories and files:
- `app/Models/Team.php` - Team model
- `app/Models/Permission.php` - Permission model
- `app/Models/Role.php` - Role model
- `app/Services/TeamPermissionService.php` - Permission logic
- `resources/views/teams/` - Team management views

### Phase 4: Real-time Features

Key directories and files:
- `config/websockets.php` - WebSockets configuration
- `config/reverb.php` - Reverb configuration
- `app/Events/` - Event classes
- `routes/channels.php` - Broadcast channels
- `resources/js/` - JavaScript for real-time features

### Phase 5: Advanced Features

Key directories and files:
- `app/Services/TenantService.php` - Multi-tenancy
- `app/Models/AuditLog.php` - Audit logging
- `app/Services/SearchService.php` - Search functionality
- `app/Http/Controllers/Api/` - API endpoints

### Phase 6: Polishing

Key directories and files:
- `tests/` - Comprehensive tests
- `app/Services/FeatureFlagService.php` - Feature flags
- `app/Services/CacheService.php` - Caching strategies
- `Dockerfile` and CI/CD files - Deployment configuration

## Navigation Techniques

### Using GitHub's Search

GitHub provides powerful search capabilities:

1. **Repository Search**:
   - Go to the repository on GitHub
   - Use the search bar at the top of the repository
   - Enter keywords, file names, or code snippets

2. **Advanced Search Syntax**:
   - Search for files: `filename:User.php`
   - Search in paths: `path:app/Models`
   - Search for specific code: `implements HasTeams`
   - Combine searches: `path:app/Models filename:User.php`

3. **Code Search Tips**:
   - Use quotes for exact phrases: `"function createTeam"`
   - Use wildcards: `has*Trait`
   - Filter by language: `language:php`

### Using IDE Navigation

If you've cloned the repository locally, your IDE provides efficient navigation:

1. **File Navigation**:
   - VS Code: `Ctrl+P` (Windows/Linux) or `Cmd+P` (Mac)
   - PhpStorm: `Shift+Shift` (double-shift)
   - Enter partial file name to find files quickly

2. **Symbol Navigation**:
   - VS Code: `Ctrl+T` (Windows/Linux) or `Cmd+T` (Mac)
   - PhpStorm: `Ctrl+Alt+Shift+N` (Windows/Linux) or `Cmd+Alt+O` (Mac)
   - Enter class, method, or property names

3. **Text Search**:
   - VS Code: `Ctrl+Shift+F` (Windows/Linux) or `Cmd+Shift+F` (Mac)
   - PhpStorm: `Ctrl+Shift+F` (Windows/Linux) or `Cmd+Shift+F` (Mac)
   - Search for text across all files

4. **Go to Definition**:
   - VS Code: `F12` or `Ctrl+Click`
   - PhpStorm: `Ctrl+B` or `Cmd+B`
   - Jump to the definition of a class, method, or property

5. **Find Usages**:
   - VS Code: `Shift+F12`
   - PhpStorm: `Alt+F7`
   - Find all places where a symbol is used

### Using Git Commands

Git provides tools for exploring code history:

1. **Find when code was introduced**:
   ```bash
   git log -p -- path/to/file.php
   ```

2. **Find who modified a specific line**:
   ```bash
   git blame path/to/file.php
   ```

3. **Find commits related to a keyword**:
   ```bash
   git log --grep="team permissions"
   ```

4. **Find changes between branches**:
   ```bash
   git diff phase1-step1..phase1-step2 -- app/Models/
   ```

## Understanding Code Relationships

### Model Relationships

To understand how models relate to each other:

1. Look for relationship methods in model classes:
   - `belongsTo()`, `hasMany()`, `belongsToMany()`, etc.

2. Check migration files for foreign keys:
   - `$table->foreignId('team_id')->constrained()`

3. Examine database schema:
   - Run `php artisan db:table users` to see table structure

### Class Hierarchies

To understand class inheritance and traits:

1. Look at class declarations:
   - `class Admin extends User`
   - `use HasUlid, HasUserTracking;`

2. Use IDE "Type Hierarchy" features:
   - PhpStorm: `Ctrl+H` (Windows/Linux) or `Ctrl+H` (Mac)
   - VS Code: Install PHP Intelephense extension

3. Check for interfaces and contracts:
   - `implements TeamInterface`

### Service Dependencies

To understand how services interact:

1. Look at constructor dependencies:
   ```php
   public function __construct(
       protected UserRepository $users,
       protected TeamService $teams
   ) { }
   ```

2. Check service provider bindings:
   ```php
   $this->app->singleton(TeamService::class, function ($app) {
       return new TeamService($app->make(UserRepository::class));
   });
   ```

## Finding Specific Code Elements

### Authentication Logic

1. **Login Process**:
   - `app/Actions/Fortify/AuthenticateUser.php`
   - `app/Http/Middleware/Authenticate.php`
   - `resources/views/auth/login.blade.php`

2. **Registration Process**:
   - `app/Actions/Fortify/CreateNewUser.php`
   - `resources/views/auth/register.blade.php`

3. **Password Reset**:
   - `app/Actions/Fortify/ResetUserPassword.php`
   - `resources/views/auth/forgot-password.blade.php`
   - `resources/views/auth/reset-password.blade.php`

### User Types and STI

1. **User Type Definitions**:
   - `app/Models/User.php` - Base model
   - `app/Models/Admin.php`, `app/Models/Manager.php`, etc. - Child models
   - `app/Enums/UserType.php` - User type enum

2. **STI Implementation**:
   - `app/Models/User.php` - Look for `$discriminator` property
   - `database/migrations/*_create_users_table.php` - User type column

3. **Type-Specific Logic**:
   - `app/Policies/` - Authorization based on user type
   - `app/Services/` - Services with type-specific behavior

### Team and Permission System

1. **Team Structure**:
   - `app/Models/Team.php` - Team model
   - `database/migrations/*_create_teams_table.php` - Team table structure
   - `app/Models/TeamMember.php` - Team membership

2. **Permission Definitions**:
   - `app/Models/Permission.php` - Permission model
   - `app/Models/Role.php` - Role model
   - `database/seeders/PermissionSeeder.php` - Default permissions

3. **Permission Checks**:
   - `app/Policies/` - Authorization policies
   - `app/Services/TeamPermissionService.php` - Permission logic
   - `app/Providers/AuthServiceProvider.php` - Gate definitions

### State Machines

1. **State Definitions**:
   - `app/States/UserState.php` - User states
   - `app/States/TeamState.php` - Team states

2. **State Transitions**:
   - `app/Transitions/` - Transition classes
   - `app/Events/` - Events triggered by transitions

3. **State-Dependent Logic**:
   - `app/Policies/` - Authorization based on states
   - `app/Http/Controllers/` - Controllers with state checks

## Common Code Patterns

Understanding common patterns will help you navigate the codebase more efficiently:

### Service Pattern

Services encapsulate business logic:

```php
// app/Services/TeamService.php
class TeamService
{
    public function __construct(
        protected TeamRepository $teams,
        protected UserRepository $users
    ) { }

    public function createTeam(User $user, array $data): Team
    {
        // Business logic here
    }
}
```

Look for service classes in `app/Services/` directory.

### Repository Pattern

Repositories abstract data access:

```php
// app/Repositories/TeamRepository.php
class TeamRepository
{
    public function findByUser(User $user): Collection
    {
        return Team::where('user_id', $user->id)->get();
    }
}
```

Look for repository classes in `app/Repositories/` directory.

### Action Pattern

Actions encapsulate single responsibilities:

```php
// app/Actions/CreateTeam.php
class CreateTeam
{
    public function __invoke(User $user, array $data): Team
    {
        // Logic to create a team
    }
}
```

Look for action classes in `app/Actions/` directory.

### Trait Pattern

Traits provide reusable functionality:

```php
// app/Traits/HasUlid.php
trait HasUlid
{
    protected static function bootHasUlid(): void
    {
        static::creating(function ($model) {
            $model->id = (string) Ulid::generate();
        });
    }
}
```

Look for traits in `app/Traits/` directory.

## Navigating Tests

Tests provide valuable insights into how code is supposed to work:

### Unit Tests

Unit tests focus on individual components:

```php
// tests/Unit/Models/UserTest.php
public function test_user_has_teams()
{
    $user = User::factory()->create();
    $team = Team::factory()->create(['user_id' => $user->id]);
    
    $this->assertTrue($user->teams->contains($team));
}
```

Look for unit tests in `tests/Unit/` directory.

### Feature Tests

Feature tests focus on complete features:

```php
// tests/Feature/TeamManagementTest.php
public function test_user_can_create_team()
{
    $user = User::factory()->create();
    $this->actingAs($user);
    
    $response = $this->post('/teams', [
        'name' => 'Test Team',
        'description' => 'Test Description'
    ]);
    
    $response->assertRedirect('/teams');
    $this->assertDatabaseHas('teams', [
        'name' => 'Test Team',
        'user_id' => $user->id
    ]);
}
```

Look for feature tests in `tests/Feature/` directory.

## Navigating by Functionality

### User Registration Flow

1. User submits registration form: `resources/views/auth/register.blade.php`
2. Form request validation: `app/Http/Requests/RegisterRequest.php`
3. User creation: `app/Actions/Fortify/CreateNewUser.php`
4. Email verification: `app/Listeners/SendEmailVerificationNotification.php`
5. Welcome page: `resources/views/auth/welcome.blade.php`

### Team Creation Flow

1. User accesses team creation page: `resources/views/teams/create.blade.php`
2. Form submission: `app/Http/Controllers/TeamController.php@store`
3. Team creation logic: `app/Services/TeamService.php@createTeam`
4. Team member assignment: `app/Services/TeamMemberService.php@addMember`
5. Redirect to team page: `resources/views/teams/show.blade.php`

### Permission Check Flow

1. User attempts an action: `app/Http/Controllers/ResourceController.php@update`
2. Authorization check: `$this->authorize('update', $resource)`
3. Policy evaluation: `app/Policies/ResourcePolicy.php@update`
4. Permission verification: `app/Services/TeamPermissionService.php@hasPermission`
5. Access granted or denied

## Tips for Efficient Navigation

1. **Start with the routes**:
   - Check `routes/web.php` and `routes/api.php` to understand entry points
   - Follow the controller methods to see what happens for each route

2. **Follow the request lifecycle**:
   - Start with the controller action
   - Look at the form request for validation
   - Follow the service calls for business logic
   - Check the models for data access
   - Look at the views for presentation

3. **Use tests as documentation**:
   - Tests often demonstrate how components should work together
   - Feature tests show complete workflows
   - Unit tests show expected behavior of individual components

4. **Check the migrations**:
   - Database structure provides insights into data relationships
   - Foreign keys indicate model relationships

5. **Look at service providers**:
   - Service providers show how components are wired together
   - Check `app/Providers/` directory for service registrations

## Conclusion

Navigating a complex codebase like UME requires understanding both the overall structure and the specific patterns used. By using the techniques in this guide, you'll be able to find the code you're looking for more efficiently and understand how different components work together.

Remember that the UME codebase follows Laravel conventions, so familiarity with Laravel's structure will help you navigate more effectively. If you're new to Laravel, consider reviewing the [Laravel documentation](https://laravel.com/docs) to better understand the framework's organization.

For any questions about code navigation, please contact the UME documentation team at [docs@ume-tutorial.com](mailto:docs@ume-tutorial.com).
