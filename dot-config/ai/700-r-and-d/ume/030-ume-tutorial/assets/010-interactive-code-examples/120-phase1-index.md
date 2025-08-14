# Phase 1: Core Models & STI

This index provides an overview of the interactive code examples for Phase 1 of the UME tutorial, focusing on core model structure and single table inheritance in Laravel applications.

## Examples in this Phase

1. [Single Table Inheritance Example](240-phase1-sti-example1.md)
   - STI pattern implementation
   - Type column and discriminator
   - Subclass implementation
   - Query scopes for types

2. [User Type Enum Example](250-phase1-user-type-enum-example2.md)
   - Using PHP 8 enums with models
   - Type safety for user types
   - Enum-based behavior
   - Type validation

3. [Traits and Model Events Example](260-phase1-traits-model-events-example3.md)
   - Using traits to extend models
   - Model events and observers
   - Event-driven architecture
   - Custom events and listeners

4. [HasUlid Trait Example](270-phase1-hasulid-trait-example4.md)
   - Implementing ULIDs for models
   - Primary key customization
   - ID generation strategies
   - Database considerations

5. [HasUserTracking Trait Example](280-phase1-hasusertracking-trait-example5.md)
   - User tracking for model changes
   - Created by and updated by fields
   - Automatic user attribution
   - Audit trail implementation

## Key Concepts

- **Eloquent ORM**: Laravel's object-relational mapper for database interaction
- **Single Table Inheritance**: Pattern for storing hierarchical models in a single table
- **Model Relationships**: Defining connections between different models
- **Traits**: PHP's mechanism for code reuse in single inheritance
- **Factories**: Tools for creating test data and seeding databases

## Additional Resources

- [Laravel Eloquent Documentation](https://laravel.com/docs/eloquent)
- [Laravel Relationships](https://laravel.com/docs/eloquent-relationships)
- [Laravel Model Factories](https://laravel.com/docs/database-testing)
- [PHP Traits Documentation](https://www.php.net/manual/en/language.oop5.traits.php)

## Prerequisites

Before working through these examples, you should have:

1. Completed [Phase 0: Foundation](110-phase0-index.md)
2. Basic knowledge of database design
3. Understanding of object-oriented programming concepts
4. Familiarity with Laravel's basic concepts

## Next Steps

After completing these examples, you should be able to:

1. Create well-structured Laravel models
2. Implement single table inheritance for model hierarchies
3. Define and use relationships between models
4. Create reusable traits for model functionality
5. Use factories for testing and database seeding

Continue to [Phase 2: Auth & Profiles](130-phase2-index.md) to learn about authentication, authorization, and user profiles.
