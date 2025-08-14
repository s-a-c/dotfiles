# Large Scale Framework (LSF) - Laravel Enterprise Platform

> **🚀 Modern PHP 8.4 + Laravel 12 Enterprise SaaS Platform**  
> \_Advanced ## 4. Finite State Machine Integration

### 4.1. Enhanced PHP 8.4 Enumsnt-sourcing, CQRS, and finite state machine architecture\_

[![PHP Version](https://img.shields.io/badge/PHP-8.4+-777BB4?style=flat-square&logo=php)](https://php.net)
[![Laravel Version](https://img.shields.io/badge/Laravel-12.x-FF2D20?style=flat-square&logo=laravel)](https://laravel.com)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

## 1. Architecture Overview

### 1.1. Core Philosophy

**Confidence: 95%** - This platform implements a sophisticated multi-tenant organisation model with **event-sourcing**
and **CQRS** patterns, backed by **finite state machines** using modern PHP 8.4 enums and the Spatie ecosystem.

### 1.2. Key Technologies

<div style="background: #e3f2fd; padding: 12px; border-radius: 6px; margin: 10px 0; color: #0d47a1;">

**🎯 Event Sourcing Stack:**

- **Primary**: `hirethunk/verbs` (v0.7) - Modern PHP 8.4+ event sourcing
- **Secondary**: `spatie/laravel-event-sourcing` - Legacy support & integration
- **State Management**: `spatie/laravel-model-states` + `spatie/laravel-model-status`
- **FSM**: Enhanced PHP 8.4 native enums with backing types

</div>

### 1.3. Architectural Patterns

| Pattern            | Implementation         | Confidence | Reasoning                                 |
| ------------------ | ---------------------- | ---------- | ----------------------------------------- |
| **Event Sourcing** | Hybrid Verbs + Spatie  | 90%        | Modern approach with legacy compatibility |
| **CQRS**           | Read/Write separation  | 85%        | Clear separation of concerns              |
| **STI**            | Organisation hierarchy | 95%        | Proven pattern for hierarchical data      |
| **Multi-tenancy**  | Row-level security     | 90%        | Scalable isolation strategy               |

## 2. Event Sourcing & CQRS Strategy

### 2.1. Dual Package Approach

**Recommendation: 88%** - Use both `hirethunk/verbs` and `spatie/laravel-event-sourcing` for optimal flexibility:

#### 2.1.1. Primary: HireThunk Verbs

<div style="background: #e8f5e8; padding: 12px; border-radius: 6px; margin: 10px 0; color: #1b5e20;">

**✅ Advantages:**

- Modern PHP 8.4+ features (attributes, match expressions)
- Lightweight and performant
- Excellent type safety
- Native Laravel integration
- Active development

**❌ Considerations:**

- Newer package (less ecosystem)
- Smaller community
- Limited documentation

</div>

#### 2.1.2. Secondary: Spatie Event Sourcing

<div style="background: #fff3e0; padding: 12px; border-radius: 6px; margin: 10px 0; color: #000000;">

**✅ Advantages:**

- Mature ecosystem
- Extensive documentation
- Proven in production
- Rich feature set
- Large community

**❌ Considerations:**

- Heavier implementation
- Older PHP patterns
- More complex setup

</div>

### 2.2. CQRS Implementation Strategy

#### 2.2.1. Read Side (Queries)

```php
// Query Models - Optimized for reads
class OrganisationProjection extends Model
{
    // Fast read operations
    // Denormalized data
    // Cached aggregations
}
```

#### 2.2.2. Write Side (Commands)

```php
// Event Sourced Aggregates
class OrganisationAggregate extends AggregateRoot
{
    // Business logic
    // Event recording
    // State validation
}
```

## 3. Identifier Strategy

### 3.1. Multi-Tier Identifier Architecture

**Confidence: 95%** - Optimized identifier strategy using `glhd/bits` and `symfony/uid`:

<div style="background: #e3f2fd; padding: 12px; border-radius: 6px; margin: 10px 0; color: #0d47a1;">

**🔑 Identifier Strategy:**

- **Event Store Primary Keys**: Snowflake IDs (`glhd/bits`) for time-ordered, high-throughput event sourcing
- **Standard Model Primary Keys**: Auto-incrementing integers for optimal Eloquent performance
- **Secondary Identifiers**: ULID (default) for external references, URL-safe, time-ordered
- **Security Identifiers**: UUID for APIs and sensitive contexts requiring maximum unpredictability
- **Package Integration**: `symfony/uid` (Laravel default) + `glhd/bits` v0.6+

</div>

### 3.2. Implementation Patterns

| Model Type          | Primary Key | Secondary Key | Use Case                       |
| ------------------- | ----------- | ------------- | ------------------------------ |
| **Event Store**     | Snowflake   | N/A           | High-throughput event sourcing |
| **Standard Models** | Integer     | ULID          | General application models     |
| **API Models**      | Integer     | ULID/UUID     | External API exposure          |
| **Security Models** | Integer     | UUID          | High-security contexts         |

## 4. Finite State Machine Integration

### 3.1. Enhanced PHP 8.4 Enums

**Confidence: 92%** - Modern enum-based FSM with backing values:

<div style="background: #f3e5f5; padding: 12px; border-radius: 6px; margin: 10px 0; color: #4a148c;">

**🎯 FSM Strategy:**

- **States**: `spatie/laravel-model-states` for complex workflows
- **Status**: `spatie/laravel-model-status` for simple flags
- **Enums**: PHP 8.4 backed enums for type safety
- **Integration**: Seamless with event sourcing

</div>

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

## 4. Organisation Model Architecture

### 4.1. Self-Referential Polymorphic Design

**Confidence: 95%** - Proven STI pattern with materialized paths:

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

### 4.2. Multi-Tenant Isolation

- **Root Level**: Tenant organisations (`type = 'tenant'`)
- **Sub-Levels**: Configurable organisation types per tenant
- **Security**: Row-level security through tenant scoping
- **Scalability**: Indexed hierarchy paths for performance

## 5. Outstanding Questions & Decisions

### 5.1. Critical Decision Points

<div style="background: #ffebee; padding: 12px; border-radius: 6px; margin: 10px 0; color: #c62828;">

**🔴 HIGH PRIORITY - Event Sourcing Package Strategy**

**Decision Required**: How to integrate dual event sourcing packages?

**Options:**

1. **Primary Verbs, Secondary Spatie** (Recommended: 85%)
2. **Spatie Only** (Conservative: 70%)
3. **Verbs Only** (Modern: 75%)

**Impact**: Foundation architecture affects entire application

</div>

### 5.2. Implementation Inconsistencies

| Issue                | Current State         | Recommended           | Confidence |
| -------------------- | --------------------- | --------------------- | ---------- |
| **Event Sourcing**   | Dual packages         | Hybrid approach       | 85%        |
| **Authentication**   | DevDojo Auth vs OAuth | Clarify strategy      | 70%        |
| **Package Versions** | Mixed versions        | Standardize to latest | 90%        |

## 6. Technical Recommendations

### 6.1. Phase 1: Foundation (Weeks 1-2)

**Confidence: 90%** - Critical foundation setup:

1. **Resolve Package Conflicts**

   - Standardize event sourcing approach
   - Document authentication strategy
   - Update to consistent versions

2. **Establish FSM Patterns**
   - Create base enum abstractions
   - Integrate with Spatie model states
   - Test state transitions

### 6.2. Phase 2: Core Implementation (Weeks 3-4)

**Confidence: 85%** - Core features:

1. **Organisation Model with Event Sourcing**
2. **CQRS Read/Write Separation**
3. **FSM State Management**
4. **Multi-tenant Isolation**

### 6.3. Phase 3: Advanced Features (Weeks 5-8)

**Confidence: 80%** - Advanced capabilities:

1. **Real-time Event Broadcasting**
2. **Performance Optimization**
3. **Monitoring & Observability**
4. **Production Hardening**

## 7. Performance Considerations

### 7.1. Event Sourcing Optimization

<div style="background: #e0f2f1; padding: 12px; border-radius: 6px; margin: 10px 0; color: #00695c;">

**🎯 Performance Strategies:**

- **Event Batching**: Process multiple events per transaction
- **Projection Snapshots**: Periodic state snapshots for fast rebuilds
- **Async Processing**: Background event handler execution
- **Stream Partitioning**: Distribute events across multiple streams
- **Event Compression**: Reduce storage overhead

</div>

## 8. Development Setup

### 8.1. Quick Start

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

### 8.2. Testing Strategy

**Confidence: 95%** - Comprehensive testing approach:

```bash
# Code quality
composer run test

# Specific test suites
composer run test:arch       # Architecture tests
composer run test:mutation   # Mutation testing
composer run test:security   # Security tests
```

## 9. Documentation & References

### 9.1. Documentation Structure

```
.github/lsf/                    # Large Scale Framework docs
├── 000-master-bibliography.md # Complete citations & references
├── 010-event-sourcing-cqrs-analysis.md # Event sourcing strategy
├── 020-enhanced-technical-diagrams.md  # Architecture diagrams
├── 030-improvements-recommendations.md # Implementation roadmap
├── README.md                   # This file (enhanced)
├── architecture/              # System design documents
├── decisions/                # ADRs (Architectural Decision Records)
├── implementation/           # Development guides
└── governance/              # Policies and standards
```

### 9.2. Key Package References

#### Primary Event Sourcing

- **HireThunk Verbs** v0.7+ - [GitHub](https://github.com/hirethunk/verbs) | [Docs](https://verbs.thunk.dev/)
- **Spatie Event Sourcing** v7.3+ - [GitHub](https://github.com/spatie/laravel-event-sourcing) |
  [Docs](https://spatie.be/docs/laravel-event-sourcing/v7/introduction)

#### State Management

- **Spatie Model States** v0.4+ - [GitHub](https://github.com/spatie/laravel-model-states) |
  [Docs](https://spatie.be/docs/laravel-model-states/v0.4/introduction)
- **Spatie Model Status** v1.17+ - [GitHub](https://github.com/spatie/laravel-model-status) |
  [Docs](https://spatie.be/docs/laravel-model-status/v1/introduction)

#### Current Dependencies

- **GLHD Bits** v0.6+ - [GitHub](https://github.com/glhd/bits) (✅ Installed)
- **Tighten Parental** v1.4+ - [GitHub](https://github.com/tighten/parental) (✅ Installed)
- **DevDojo Auth** v1.1+ - [GitHub](https://github.com/devdojo/auth) (✅ Integrated)
- **Symfony UID** v7.1+ - [Symfony](https://symfony.com/doc/current/components/uid.html) (✅ Laravel Default)

### 9.3. Technical Standards

**Framework**: Laravel 12.x + PHP 8.4+  
**Testing**: Pest PHP with architecture testing  
**Code Quality**: Laravel Pint + PHPStan via Larastan  
**Documentation**: Comprehensive citations in [Master Bibliography](.github/lsf/000-master-bibliography.md)

### 9.4. Research Citations

For complete academic and technical citations, see:

- **[Master Bibliography](.github/lsf/000-master-bibliography.md)** - Complete reference list
- **[Event Sourcing Analysis](.github/lsf/010-event-sourcing-cqrs-analysis.md)** - Technical implementation analysis
- **[Architecture Diagrams](.github/lsf/020-enhanced-technical-diagrams.md)** - Visual system architecture
- **[Implementation Roadmap](.github/lsf/030-improvements-recommendations.md)** - Strategic recommendations

## 10. Contributing

Please review our [AI Instructions](AI_INSTRUCTIONS.md) for development standards and contribution guidelines.

All documentation follows academic citation standards. See the
[Master Bibliography](.github/lsf/000-master-bibliography.md) for proper attribution and source verification.

---

**📊 Documentation Status**: 🔄 CONTINUOUS IMPROVEMENT  
**🎯 Architecture Confidence**: 88% - Solid foundation with clear next steps  
**⚡ Implementation Ready**: Phase 1 foundation tasks documented and actionable  
**📚 Citations**: Complete academic and technical references included
