# User Model Enhancements (UME) - Architectural Overview

This document provides an architectural overview of the User Model Enhancements (UME), a comprehensive set of enhancements for user management in Laravel applications.

## Table of Contents

- [Introduction](#introduction)
- [Key Features](#key-features)
- [Architectural Patterns](#architectural-patterns)
- [Implementation Phases](#implementation-phases)
- [UI Framework Options](#ui-framework-options)
- [PHP 8 Attributes Usage](#php-8-attributes-usage)
- [Security Best Practices](#security-best-practices)
- [Advanced Features](#advanced-features)

## Introduction

User Model Enhancements (UME) is a comprehensive set of enhancements for user management in Laravel applications. It provides detailed guides, tutorials, and reference materials for implementing advanced user management features in Laravel, with a focus on Single Table Inheritance, enhanced profiles, teams, and role-based permissions.

## Key Features

UME includes a wide range of features for user management:

- **Single Table Inheritance for User Types**
  - Base User class with specialized user types (Admin, Customer, Guest)
  - Type-specific behavior and attributes
  - Efficient database design with a single table

- **Enhanced User Profiles**
  - Granular name components (first, middle, last, display)
  - Profile pictures and avatars
  - Extended user metadata
  - Customizable profile fields

- **Teams and Hierarchies**
  - Self-referential team structure
  - Hierarchical organization with configurable depth
  - Team membership and invitations
  - Cross-team relationships

- **Role-based Permissions**
  - Granular permission system
  - Role assignment within teams
  - Permission inheritance through team hierarchy
  - Context-aware authorization

- **Authentication Enhancements**
  - Two-factor authentication
  - Social authentication
  - Session management
  - Account recovery

- **Real-time Features**
  - Presence detection
  - Real-time notifications
  - Chat functionality
  - WebSocket integration

- **Admin Interfaces**
  - FilamentPHP integration
  - User management dashboards
  - Permission management
  - Activity monitoring

## Architectural Patterns

### Single Table Inheritance (STI)

UME implements Single Table Inheritance for user types, allowing different user types to be stored in a single database table while maintaining type-specific behavior:

- **Base User Model**: Contains common fields and behavior
- **Type Discriminator**: Field to identify the specific user type
- **Type-Specific Models**: Extend the base model with specialized behavior
- **Implementation**: Uses `tightenco/parental` package

Example structure:
```
users
├── id (primary key)
├── type (discriminator: 'admin', 'customer', 'guest')
├── email, password, etc. (common fields)
└── type-specific fields
```

### Team Hierarchy

UME implements a self-referential team structure with hierarchical relationships:

- **Self-referential Design**: Teams can have parent-child relationships
- **Materialized Paths**: Efficient hierarchy traversal
- **Depth Limiting**: Configurable maximum depth
- **Permission Inheritance**: Permissions can flow through the hierarchy

### State Machines for Account Lifecycle

Account lifecycle management using finite state machines:

- **User States**: Draft, Active, Suspended, Archived
- **Type-safe Transitions**: Controlled state changes
- **Event-driven**: State changes trigger events
- **Implementation**: Uses PHP 8.4 enums and Spatie packages

## Implementation Phases

UME is designed to be implemented in phases, allowing for incremental adoption:

### Phase 0: Foundation

- Laravel 12 setup
- Development environment configuration
- Testing framework setup
- UI framework selection

### Phase 1: Core Models & STI

- User model with Single Table Inheritance
- Database migrations
- Model relationships
- Basic validation

### Phase 2: Auth & Profiles

- Authentication system
- User registration and login
- Profile management
- Two-factor authentication

### Phase 3: Teams & Permissions

- Team model implementation
- Team hierarchy
- Role and permission system
- Team invitations

### Phase 4: Real-time Features

- WebSocket setup
- Presence detection
- Notifications
- Chat functionality

### Phase 5: Advanced Features

- Admin interfaces with FilamentPHP
- Reporting and analytics
- Advanced search
- API development

### Phase 6: Polishing & Deployment

- Performance optimization
- Security hardening
- Documentation
- Deployment strategies

## UI Framework Options

UME provides implementations for multiple UI approaches:

### Primary Path: Livewire/Volt with Flux UI

- Reactive components with server-side rendering
- Minimal JavaScript
- Progressive enhancement
- Modern UI components

### Admin Interface: FilamentPHP

- Comprehensive admin panel
- CRUD operations
- Dashboard widgets
- Form builders

### Alternative Paths

- **Inertia.js with React**: SPA-like experience with React components
- **Inertia.js with Vue**: SPA-like experience with Vue components

## PHP 8 Attributes Usage

UME maximizes the use of PHP 8 attributes throughout the codebase, providing a more type-safe and declarative approach to configuration:

### Attribute-Based Testing

```php
#[Test]
#[Group('user')]
public function it_can_register_a_new_user(): void
{
    // Test implementation
}
```

### Attribute-Based Model Configuration

```php
#[HasUuids]
#[SoftDeletes]
#[UserTracking]
class User extends Authenticatable
{
    // Model implementation
}
```

### Attribute-Based Validation

```php
#[ValidateWith([
    'name' => 'required|string|max:255',
    'email' => 'required|email|unique:users',
    'password' => 'required|min:8|confirmed',
])]
public function register(Request $request): RedirectResponse
{
    // Method implementation
}
```

### Attribute-Based API Endpoints

```php
#[Route('api/users', methods: ['GET'])]
#[Middleware(['auth:sanctum'])]
#[ResponseCache(ttl: 60)]
public function index(): JsonResponse
{
    // Method implementation
}
```

## Security Best Practices

UME includes comprehensive security best practices:

- **Authentication Security**
  - Password hashing with Bcrypt/Argon2
  - Rate limiting for login attempts
  - Session security (HTTPS, secure cookies)
  - Two-factor authentication

- **Authorization**
  - Fine-grained permission system
  - Context-aware authorization
  - Role-based access control
  - Team-based permissions

- **Data Protection**
  - Input validation
  - Output escaping
  - CSRF protection
  - XSS prevention

- **API Security**
  - Token-based authentication
  - Scoped API tokens
  - Rate limiting
  - Request validation

## Advanced Features

### Internationalization

- Multi-language support
- Locale-based formatting
- Translatable models
- RTL support

### Accessibility

- WCAG 2.1 compliance
- Screen reader compatibility
- Keyboard navigation
- Color contrast requirements

### Mobile Responsiveness

- Responsive design
- Touch-friendly interfaces
- Mobile-first approach
- Progressive web app capabilities

### Progressive Enhancement

- Core functionality without JavaScript
- Enhanced experience with JavaScript
- Graceful degradation
- Browser compatibility
