# Phase 1: Building the Core Models & Architecture (with STI)

<link rel="stylesheet" href="../../assets/css/styles.css">

**Goal:** Implement Single Table Inheritance (STI) for the User model using `tightenco/parental`. Define the base `User` model and specialized child models (`Admin`, `Manager`, `Practitioner`). Set up the database structure (including the `type` column), create reusable Traits (ULIDs, user tracking, additional features with flags), configure Factories/Seeders for STI, establish the Service Layer base, and configure initial Filament Resources to manage user types.

## In This Phase

1. [Understanding Single Table Inheritance (STI) & Parental](./010-understanding-sti.md) - Learn about STI and how it works with Parental
2. [Creating the UserType Enum](./020-user-type-enum.md) - Define the user types using PHP Enums
3. [Understanding Traits & Model Events](./030-traits-model-events.md) - Learn about traits and model events
4. [Create HasUlid Trait](./040-has-ulid-trait.md) - Implement a trait for ULID generation
5. [Create HasSlug Trait](./045-has-slug-trait.md) - Implement a trait for slug generation
6. [Create HasUserTracking Trait](./050-has-user-tracking-trait.md) - Implement a trait for tracking user actions
7. [Understanding Database Migrations](./060-database-migrations.md) - Learn about database migrations
8. [Enhance users Table Migration](./070-enhance-users-migration.md) - Add type, name components, and other fields
9. [Understanding Eloquent Models & Relationships](./080-eloquent-models.md) - Learn about Eloquent models and relationships
10. [Create HasAdditionalFeatures Trait](./090-create-additional-features-trait.md) - Implement a trait for additional model features
11. [Configure Additional Features](./100-configure-additional-features.md) - Configure the additional features trait
12. [Create Flags Enum](./110-create-flags-enum.md) - Create an enum for model flags
13. [Update User Model](./120-update-user-model.md) - Apply HasChildren, traits, casts, and relationships
14. [Improved HasAdditionalFeatures Architecture](./130-improved-architecture.md) - Refactor the trait into smaller concerns
15. [Implement FeatureManager](./140-feature-manager.md) - Create a dedicated class for feature management
16. [Developer Experience Improvements](./150-developer-experience.md) - Add attribute-based configuration and debug helpers
17. [Performance Optimizations](./160-performance-optimizations.md) - Implement lazy loading and configuration caching
18. [Advanced Feature Enhancements](./170-advanced-feature-enhancements.md) - Add events, middleware, and enhanced features
19. [Conclusion and Best Practices](./180-conclusion.md) - Summary of improvements and best practices
20. [Create Child Models](./190-create-child-models.md) - Create Admin, Manager, and Practitioner models
21. [Create Team Model & Migration](./200-team-model.md) - Implement the Team model and migration
22. [Create team_user Pivot Table Migration](./210-team-user-pivot.md) - Create the pivot table for team-user relationships
23. [Implementing Team Hierarchy](./220-team-hierarchy.md) - Implement self-referential Team model using staudenmeir/laravel-adjacency-list
24. [Understanding Factories & Seeders](./230-factories-seeders.md) - Learn about factories and seeders
25. [Update UserFactory](./240-update-user-factory.md) - Handle type and add state methods
26. [Create Child Model Factories](./250-child-model-factories.md) - Create factories for child models
27. [Create UserSeeder & TeamSeeder](./260-create-seeders.md) - Seed different user types and teams
28. [Update DatabaseSeeder](./270-update-database-seeder.md) - Update the main database seeder
29. [Understanding The Service Layer](./280-service-layer.md) - Learn about the service layer pattern
30. [Create BaseService](./290-base-service.md) - Implement the base service class
31. [Initial Filament Resource Setup](./300-filament-resources.md) - Set up Filament resources for User and Team
32. [Phase 1 Git Commit](./310-git-commit.md) - Save your progress
33. [Conclusion](./320-conclusion.md) - HasAdditionalFeatures Trait Enhancement
34. [Flags Test](./330-flags-test.md) - Testing the Flags Enum
35. [HasAdditionalFeatures Test Suite](./340-has-additional-features-test-suite.md) - Comprehensive Test Suite
36. [Next Steps](./350-next-steps.md) - Next Steps for Implementation
37. [Summary of Changes](./360-summary-of-changes.md) - Summary of HasAdditionalFeatures Improvements
38. [Testing](./370-testing.md) - Testing in Phase 1: Core Models ([Tests](./370-tests/000-index.md))
39. [Attribute-Based Configuration](./380-attribute-based-configuration.md) - Configure features using PHP 8 attributes

## Conceptual Note: Refactoring the User Name

A key requirement is to replace Laravel's default single `name` field on the `User` model with more granular `given_name`, `family_name`, and optional `other_names`. This will be done *alongside* the STI setup.

* **Why?** Better sorting, personalization, handling diverse names, integration with external systems.
* **How?**
    1. **Migration:** Modify the `users` table migration to add `given_name`, `family_name`, `other_names` and crucially, the `type` column for STI.
    2. **Models:** Add `HasChildren` to `User`, `HasParent` to child models. Add name fields to `$fillable`. Add an **Accessor** for `name` for compatibility.
    3. **Factories/Seeders:** Update factories to populate new name fields and the `type` column.
    4. **UI:** Update forms (Livewire, Filament) for name components and potentially user type selection.

Let's begin by [Understanding Single Table Inheritance (STI) & Parental](./010-understanding-sti.md).
