# Large Scale Framework (LSF) - Architectural Overview

This document provides an architectural overview of the Large Scale Framework (LSF), a Laravel Enterprise Platform implementing sophisticated multi-tenant organization models with event-sourcing and CQRS patterns.

## Table of Contents

- [Introduction](#introduction)
- [Core Philosophy](#core-philosophy)
- [Key Architectural Patterns](#key-architectural-patterns)
- [Event Sourcing & CQRS Strategy](#event-sourcing--cqrs-strategy)
- [Identifier Strategy](#identifier-strategy)
- [Finite State Machine Integration](#finite-state-machine-integration)
- [Organisation Model Architecture](#organisation-model-architecture)
- [Technical Stack](#technical-stack)
- [Performance Considerations](#performance-considerations)
- [Development and Testing](#development-and-testing)

## Introduction

The Large Scale Framework (LSF) is a modern PHP 8.4 + Laravel 12 Enterprise SaaS Platform designed for building scalable, maintainable, and robust applications. It implements advanced architectural patterns including event-sourcing, CQRS, and finite state machines to provide a solid foundation for enterprise applications.

## Core Philosophy

The core philosophy of LSF is to implement a sophisticated multi-tenant organisation model with event-sourcing and CQRS patterns, backed by finite state machines using modern PHP 8.4 enums and the Spatie ecosystem. This approach provides:

- Complete audit trail of all state changes
- Clear separation of read and write concerns
- Robust business logic encapsulation
- Type-safe state transitions
- Scalable multi-tenant isolation

## Key Architectural Patterns

### Event Sourcing

LSF implements a hybrid event sourcing approach using both `hirethunk/verbs` and `spatie/laravel-event-sourcing` packages:

- **Primary**: `hirethunk/verbs` (v0.7) - Modern PHP 8.4+ event sourcing with attributes, match expressions, lightweight and performant design, excellent type safety, and native Laravel integration
- **Secondary**: `spatie/laravel-event-sourcing` - Legacy support & integration with a mature ecosystem, extensive documentation, and proven production use

### CQRS (Command Query Responsibility Segregation)

The framework implements a clear separation between read and write operations:

- **Commands**: State-changing operations handled by aggregates
- **Queries**: Read operations served by optimized read models
- **Separation**: Clear distinction between write and read concerns
- **Performance**: Independent scaling of read and write operations

### Domain-Driven Design (DDD)

LSF follows DDD principles with:

- **Bounded Contexts**: Clear domain boundaries
- **Ubiquitous Language**: Shared vocabulary between business and tech
- **Aggregates**: Consistency boundaries and business rules
- **Domain Events**: Cross-aggregate communication

### Single Table Inheritance (STI)

Used for hierarchical models, particularly for the Organisation model with:

- Self-referential polymorphic design
- Materialized paths for efficient hierarchy traversal
- Row-level security for multi-tenant isolation

## Event Sourcing & CQRS Strategy

### Dual Package Approach

LSF uses both `hirethunk/verbs` and `spatie/laravel-event-sourcing` for optimal flexibility:

#### Primary: HireThunk Verbs

**Advantages:**
- Modern PHP 8.4+ features (attributes, match expressions)
- Lightweight and performant
- Excellent type safety
- Native Laravel integration
- Active development

**Considerations:**
- Newer package (less ecosystem)
- Smaller community
- Limited documentation

#### Secondary: Spatie Event Sourcing

**Advantages:**
- Mature ecosystem
- Extensive documentation
- Proven in production
- Rich feature set
- Large community

**Considerations:**
- Heavier implementation
- Older PHP patterns
- More complex setup

### CQRS Implementation

#### Read Side (Queries)

Optimized read models for fast query operations:
- Denormalized data
- Cached aggregations
- Optimized for specific query patterns

#### Write Side (Commands)

Event-sourced aggregates for business logic and state changes:
- Business logic encapsulation
- Event recording
- State validation

## Identifier Strategy

### Multi-Tier Identifier Architecture

LSF implements an optimized identifier strategy using `glhd/bits` and `symfony/uid`:

- **Event Store Primary Keys**: Snowflake IDs (`glhd/bits`) for time-ordered, high-throughput event sourcing
- **Standard Model Primary Keys**: Auto-incrementing integers for optimal Eloquent performance
- **Secondary Identifiers**: ULID (default) for external references, URL-safe, time-ordered
- **Security Identifiers**: UUID for APIs and sensitive contexts requiring maximum unpredictability

### Implementation Patterns

| Model Type          | Primary Key | Secondary Key | Use Case                       |
| ------------------- | ----------- | ------------- | ------------------------------ |
| **Event Store**     | Snowflake   | N/A           | High-throughput event sourcing |
| **Standard Models** | Integer     | ULID          | General application models     |
| **API Models**      | Integer     | ULID/UUID     | External API exposure          |
| **Security Models** | Integer     | UUID          | High-security contexts         |

## Finite State Machine Integration

### Enhanced PHP 8.4 Enums

LSF implements a modern enum-based FSM with backing values:

- **States**: `spatie/laravel-model-states` for complex workflows
- **Status**: `spatie/laravel-model-status` for simple flags
- **Enums**: PHP 8.4 backed enums for type safety
- **Integration**: Seamless with event sourcing

Example:
```php
enum OrganisationStatus: string
{
    case DRAFT = 'draft';
    case ACTIVE = 'active';
    case SUSPENDED = 'suspended';
    case ARCHIVED = 'archived';

    public function canTransitionTo(self $status): bool
    {
        return match($this) {
            self::DRAFT => in_array($status, [self::ACTIVE]),
            self::ACTIVE => in_array($status, [self::SUSPENDED, self::ARCHIVED]),
            self::SUSPENDED => in_array($status, [self::ACTIVE, self::ARCHIVED]),
            self::ARCHIVED => false,
        };
    }
}
```

## Organisation Model Architecture

### Self-Referential Polymorphic Design

LSF implements a proven STI pattern with materialized paths:

```
organisations
├── id (primary key)
├── parent_id (self-reference, nullable)
├── type (STI discriminator)
├── tenant_id (isolation boundary)
├── name, slug, description
├── configuration (JSON)
├── hierarchy_path (materialized path)
├── depth_level
└── audit timestamps
```

### Multi-Tenant Isolation

- **Root Level**: Tenant organisations (`type = 'tenant'`)
- **Sub-Levels**: Configurable organisation types per tenant
- **Security**: Row-level security through tenant scoping
- **Scalability**: Indexed hierarchy paths for performance

## Technical Stack

### Backend Framework

- **PHP**: 8.4+
- **Laravel**: 12.x
- **Event Sourcing**: `hirethunk/verbs` + `spatie/laravel-event-sourcing`
- **State Management**: `spatie/laravel-model-states` + `spatie/laravel-model-status`
- **Identifiers**: `glhd/bits` + `symfony/uid`
- **STI**: `tightenco/parental`
- **Authentication**: `devdojo/auth`

### Frontend Technologies

- **Vue.js**: 3.5+
- **Alpine.js**: For lightweight interactivity
- **Inertia.js**: For SPA-like functionality
- **Tailwind CSS**: 4.x for styling
- **Vite**: 6.x for build system

### Testing Tools

- **Pest PHP**: For unit and feature testing
- **Playwright**: For end-to-end testing
- **Vitest**: For JavaScript testing
- **Larastan**: For static analysis

## Performance Considerations

LSF includes several performance optimization strategies:

- **Event Batching**: Process multiple events per transaction
- **Projection Snapshots**: Periodic state snapshots for fast rebuilds
- **Async Processing**: Background event handler execution
- **Stream Partitioning**: Distribute events across multiple streams
- **Event Compression**: Reduce storage overhead

## Development and Testing

### Quick Start

```bash
# Clone and setup
git clone <repository>
cd lfsl
composer install
npm install

# Environment setup
cp .env.example .env
php artisan key:generate
php artisan migrate

# Development server
composer run dev
```

### Testing Strategy

LSF implements a comprehensive testing approach:

- **Architecture Tests**: Ensure architectural constraints are maintained
- **Mutation Testing**: Verify test quality
- **Security Tests**: Check for security vulnerabilities
- **Type Coverage**: Ensure type safety throughout the codebase
