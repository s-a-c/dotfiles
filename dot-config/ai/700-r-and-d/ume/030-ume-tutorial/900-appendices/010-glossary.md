# Glossary and Terminology

<link rel="stylesheet" href="../assets/css/styles.css">

This glossary provides definitions for key terms and concepts used throughout the UME tutorial. Understanding these terms will help you navigate the tutorial more effectively and communicate clearly about the concepts involved.

## A

### Activity Log
A record of actions performed by users in an application, often implemented using the `spatie/laravel-activitylog` package. Activity logs provide an audit trail of what happened, when, and by whom.

### Accessor
A method on an Eloquent model that allows you to transform an attribute when it's accessed. In Laravel, accessors are defined using the `get{AttributeName}Attribute` naming convention or through the `Attribute` class.

### Active State
In the context of the User Account State Machine, this refers to the state where a user has verified their email and can fully access the application.

### Account Status
The current state of a user account in the lifecycle, represented by the `AccountStatus` enum and managed by the state machine.

### Admin
A user type in our Single Table Inheritance hierarchy with global administrative privileges.

### Alpine.js
A minimal JavaScript framework for adding interactivity to your markup, used by Livewire and Flux UI.

### Artisan
Laravel's command-line interface that provides helpful commands for development.

### Authentication
The process of verifying the identity of a user, typically through credentials like email and password.

### Authorization
The process of determining whether an authenticated user has permission to access a specific resource or perform an action.

## B

### Backed Enum
A PHP 8.1+ enum that has associated values (string or int) for each case, used for storing in the database.

### Blade
Laravel's templating engine that allows you to use PHP in your views.

### Broadcasting
Laravel's real-time event broadcasting system, used for WebSocket communication.

## C

### Cast
A way to transform an Eloquent attribute from its raw database format into another format.

### Child Model
In Single Table Inheritance, a model that inherits from a parent model and adds specialized behavior.

### Component
A reusable piece of UI with its own logic and presentation.

### Composer
A dependency manager for PHP used to install and manage packages.

### Concrete State Class
A specific implementation of a state in the state machine pattern, such as `Active`, `Suspended`, or `Deactivated`.

### Controller
A class that handles HTTP requests and returns responses.

## D

### Database Migration
A version control system for your database schema, allowing you to define and modify database tables.

### Deactivated State
In the context of the User Account State Machine, this refers to the state where a user has chosen to deactivate their account.

### Default State
The initial state assigned to a new object when it's created. In the User Account State Machine, this is typically `PendingValidation`.

### Dependency Injection
A design pattern where a class receives its dependencies from external sources rather than creating them.

### Docker
A platform for developing, shipping, and running applications in containers.

## E

### Echo
Laravel Echo is a JavaScript library that makes it easy to subscribe to channels and listen for events broadcast by your Laravel application. It provides a simple API for working with WebSockets.

### Eloquent
Laravel's ORM (Object-Relational Mapper) for working with databases.

### Eloquent ORM
Laravel's object-relational mapper that provides an elegant ActiveRecord implementation for working with databases.

### Email Verification
The process of confirming that a user has access to the email address they provided during registration.

### Enum
A special type in PHP 8.1+ that represents a fixed set of possible values, providing type safety and can include methods.

### Event
A way to decouple various aspects of your application by dispatching and listening for specific occurrences.

## F

### Factory
A class that generates fake model instances for testing.

### Feature Flag
A technique that allows you to toggle functionality on or off without deploying new code.

### Filament
An admin panel builder for Laravel that provides UI components and tools for building admin interfaces.

### FilamentPHP
An admin panel framework for Laravel, built on the TALL stack.

### Flux UI
A collection of pre-built UI components for Livewire that provides a professional, accessible user interface.

### Fortify
Laravel Fortify is a frontend agnostic authentication backend implementation for Laravel.

## G

### Git
A distributed version control system for tracking changes in source code.

## I

### Impersonation
The ability for an administrator to temporarily log in as another user.

### Inertia.js
A framework for creating server-driven single-page apps.

### Invalid Transition
An attempt to change an object's state in a way that is not allowed by the state machine configuration.

## L

### Laravel
A PHP web application framework with expressive, elegant syntax.

### Laravel Sail
A light-weight command-line interface for interacting with Laravel's Docker development environment.

### Listener
A class that handles events dispatched by your application.

### Livewire
A full-stack framework for Laravel that makes building dynamic interfaces simple, without leaving the comfort of PHP.

## M

### Manager
A user type in our Single Table Inheritance hierarchy with elevated permissions for managing teams and users.

### Middleware
A mechanism for filtering HTTP requests entering your application.

### Migration
A version control system for databases that allows defining and sharing the application's database schema.

### Model
A class that represents a database table and provides an API for interacting with it.

### Model States
The Spatie package (`spatie/laravel-model-states`) used to implement state machines in Laravel applications.

### Multi-factor Authentication (MFA)
A security method that requires users to provide two or more verification factors to gain access to a system.

### MustVerifyEmail
A Laravel interface that defines methods for email verification functionality.

### Mutator
A method on an Eloquent model that allows you to transform an attribute when it's being set. In Laravel, mutators are defined using the `set{AttributeName}Attribute` naming convention or through the `Attribute` class.

### MVC Pattern
Model-View-Controller architectural pattern that separates application logic from presentation.

## N

### NPM
Node Package Manager, used to install and manage JavaScript packages.

## P

### Parental
A package for implementing Single Table Inheritance in Laravel.

### Permission Approval Workflow
A multi-step process for reviewing and approving permissions before they become active, typically involving multiple approvers with different levels of authority.

### Permission History
A record of all state transitions that a permission has undergone, including timestamps, reasons, and the users who initiated the changes.

### Permission State Machine
A state machine that manages the lifecycle of permissions, controlling how permissions transition between different states such as Draft, Active, Disabled, and Deprecated.

### PendingValidation State
In the context of the User Account State Machine, this refers to the state where a user has registered but not yet verified their email.

### Presence Channel
A type of WebSocket channel in Laravel's broadcasting system that tracks which users are subscribed to it, allowing you to see who is online.

### Presence Status
The current online status of a user, typically represented as online, offline, or away. In the UME application, this is implemented using a PHP 8.1+ Enum.

### Pennant
Laravel's feature flag system.

### Permission
An action that a user is allowed to perform. In the UME application, permissions are managed through the UPermission model and can have different states (Draft, Active, Disabled, Deprecated) managed by a state machine.

### PestPHP
A testing framework for PHP with an expressive, elegant syntax.

### PHPUnit
A testing framework for PHP used to write and run tests.

### Pivot Table
A database table that connects two other tables in a many-to-many relationship.

### Practitioner
A user type in our Single Table Inheritance hierarchy with specific capabilities related to professional activities.

## R

### React
A JavaScript library for building user interfaces.

### Role State Machine
A state machine that manages the lifecycle of roles, controlling how roles transition between different states such as Draft, Active, Disabled, and Deprecated.

### Repository Pattern
A design pattern that separates the logic that retrieves data from the underlying storage.

### Reverb
Laravel's first-party WebSocket server for real-time features, introduced in Laravel 11. It provides a simple way to implement WebSocket communication in Laravel applications.

### Role
A collection of permissions that can be assigned to users. In the UME application, roles are managed through the URole model and can have different states (Draft, Active, Disabled, Deprecated) managed by a state machine.

### Role-Based Access Control (RBAC)
A method of regulating access to resources based on the roles of individual users within an organization.

## S

### Sanctum
Laravel's lightweight authentication system for SPAs and simple APIs.

### Scout
Laravel's full-text search solution.

### Scope (Query Scope)
A method defined on a model that encapsulates a specific query constraint, allowing for cleaner and more reusable query logic.

### Seeder
A class that populates your database with test data.

### Service
A class that encapsulates business logic.

### Service Provider
A class that bootstraps a service in your Laravel application or bootstraps components of the Laravel application and registers services with the container.

### Single Table Inheritance (STI)
A design pattern where an inheritance hierarchy of classes is stored in a single database table. In Laravel, this is often implemented using the `tightenco/parental` package, which provides `HasChildren` and `HasParent` traits.

### SPA (Single-Page Application)
A web application that loads a single HTML page and dynamically updates that page as the user interacts with the app.

### State
A condition or situation of an object at a specific time, represented by a class in the state machine pattern.

### State Machine
A design pattern that defines a finite set of states an object can be in and the allowed transitions between those states.

### State Pattern
A behavioral design pattern that allows an object to alter its behavior when its internal state changes.

### Suspended State
In the context of the User Account State Machine, this refers to the state where a user has been temporarily suspended by an administrator.

## T

### TALL Stack
A combination of Tailwind CSS, Alpine.js, Laravel, and Livewire.

### Team
A group of users that can collaborate and share resources.

### Team Hierarchy
A structure where teams can have parent-child relationships, forming a tree-like organization.

### Team Hierarchy State Machine
A state machine that manages the lifecycle of teams within a hierarchy, ensuring teams transition between states in a controlled manner.

### Team Invitation
A request sent to a user inviting them to join a team. The invitation goes through various states (pending, accepted, rejected, expired, revoked) managed by a state machine.

### Team Invitation State Machine
A state machine that manages the lifecycle of team invitations, controlling how invitations transition between different states such as pending, accepted, rejected, expired, and revoked.

### Team Invitation Status
The current state of a team invitation in its lifecycle, represented by the `TeamInvitationStatus` enum and managed by the state machine.

### Team State History
A record of all state transitions that a team has undergone, including timestamps, reasons, and the users who initiated the changes.

### Trait
A mechanism for code reuse in single inheritance languages like PHP.

### Transition
The process of changing an object from one state to another, which may involve additional logic or side effects.

### Transition Class
A class that encapsulates the logic performed during a state transition, such as `VerifyEmailTransition`.

### Two-Factor Authentication (2FA)
An extra layer of security that requires not only a password and username but also something the user has on them, typically a mobile device.

### Typesense
An open-source search engine used with Laravel Scout.

## U

### ULID (Universally Unique Lexicographically Sortable Identifier)
A unique identifier similar to a UUID but lexicographically sortable. ULIDs are time-ordered when sorted lexicographically, making them useful for databases and distributed systems. In Laravel, ULIDs can be generated using the Symfony UID component.

### User
The base model in our Single Table Inheritance hierarchy representing a standard user with basic permissions.

### User Model
In Laravel, the model that represents user data and methods, typically found in `App\Models\User.php`.

### User Profile
Additional information about a user beyond the authentication data, often stored in a related database table.

### User Tracking
The practice of recording which user created or last updated a record in the database, typically implemented using `created_by` and `updated_by` columns and a trait like `HasUserTracking`.

## V

### Valid Transition
A state change that is explicitly allowed by the state machine configuration.

### Validation
The process of ensuring that data meets certain criteria before it is processed.

### Verification
The process of confirming something, such as a user's email address or identity.

### View
A file containing HTML and Blade directives that displays data to the user.

### Vite
A modern frontend build tool used in Laravel for asset compilation.

### Volt
A compiler for Livewire components that allows you to define them in a single file.

### Vue
A progressive JavaScript framework for building user interfaces.

## W

### WebSocket
A communication protocol that provides full-duplex communication channels over a single TCP connection, enabling real-time communication between clients and servers without the need for polling.

### Whisper
A client-to-client event in Laravel Echo that allows users to send messages directly to other users on the same channel without going through the server.

## X

### XDebug
A PHP extension for debugging and profiling PHP code.

## Acronyms

| Acronym | Full Form |
|---------|-----------|
| 2FA | Two-Factor Authentication |
| API | Application Programming Interface |
| CSRF | Cross-Site Request Forgery |
| DTO | Data Transfer Object |
| JWT | JSON Web Token |
| MVC | Model-View-Controller |
| ORM | Object-Relational Mapping |
| RBAC | Role-Based Access Control |
| SPA | Single Page Application |
| STI | Single Table Inheritance |
| ULID | Universally Unique Lexicographically Sortable Identifier |
| UUID | Universally Unique Identifier |
| UME | User Model Enhancements |

## UME-Specific Terms

### HasChildrenTrait
A trait in the UME system that provides methods for working with child models in a Single Table Inheritance hierarchy.

### Team Hierarchy
A structure in the UME system where teams can have parent-child relationships, with permissions flowing from parent to child teams.

### Team Permission
A permission that is specific to a team, allowing users to perform actions only within the context of that team.

### User Type
In the UME system, a specific type of user represented by a child model in the Single Table Inheritance hierarchy.

### User Tracking
The automatic recording of which users created, updated, and deleted records, implemented through the HasUserTracking trait.

## Additional Resources

- [Laravel Documentation](https://laravel.com/docs)
- [Spatie Laravel Model States Documentation](https://spatie.be/docs/laravel-model-states/v2/introduction)
- [PHP 8.1 Enums Documentation](https://www.php.net/manual/en/language.enumerations.php)
- [Filament Documentation](https://filamentphp.com/docs)
- [Livewire Documentation](https://livewire.laravel.com/docs)
- [Volt Documentation](https://livewire.laravel.com/docs/volt)
- [Spatie Laravel Permission Documentation](https://spatie.be/docs/laravel-permission)
- [Spatie Media Library Documentation](https://spatie.be/docs/laravel-medialibrary)
- [Laravel Reverb Documentation](https://laravel.com/docs/11.x/reverb)
- [Laravel Broadcasting Documentation](https://laravel.com/docs/11.x/broadcasting)
- [Spatie Activity Log Documentation](https://spatie.be/docs/laravel-activitylog/v4/introduction)
- [PHP Documentation](https://www.php.net/docs.php)
- [UME Tutorial](../000-index.md)
- [Quick Reference Guides](../assets/020-visual-aids/010-cheat-sheets/000-index.md)
