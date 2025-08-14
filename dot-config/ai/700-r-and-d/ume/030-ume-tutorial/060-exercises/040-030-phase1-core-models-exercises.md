# Phase 1: Core Models & STI Exercises

<link rel="stylesheet" href="../assets/css/styles.css">

These exercises are designed to test your understanding of Single Table Inheritance and core models in the UME tutorial. Each set contains questions and a practical exercise.

## Set 1: Understanding Single Table Inheritance

### Questions

1. **What problem does Single Table Inheritance (STI) solve in the context of user types?**
   - A) It allows storing different user types in separate tables
   - B) It allows storing different user types in a single table while maintaining type-specific behavior
   - C) It prevents users from changing their type
   - D) It encrypts sensitive user data

2. **How does the `tightenco/parental` package determine which child model to instantiate?**
   - A) It uses the `instanceof` operator
   - B) It checks the `type` column in the database
   - C) It uses reflection to determine the class hierarchy
   - D) It requires manual specification in each query

3. **What trait must be added to the parent model (User) when implementing STI with Parental?**
   - A) HasParent
   - B) HasChildren
   - C) Inheritable
   - D) ParentModel

4. **What trait must be added to the child models (Admin, Manager, etc.) when implementing STI with Parental?**
   - A) HasParent
   - B) HasChildren
   - C) Inheritable
   - D) ChildModel

### Exercise

**Implement a basic Single Table Inheritance structure.**

Create a simple implementation of Single Table Inheritance for a `Vehicle` model with child types `Car`, `Motorcycle`, and `Truck`:

1. Create a migration that adds a `type` column to the `vehicles` table
2. Create the base `Vehicle` model with the `HasChildren` trait
3. Create the child models (`Car`, `Motorcycle`, `Truck`) with the `HasParent` trait
4. Add at least one type-specific method to each child model
5. Create a simple factory for each vehicle type
6. Write a test that demonstrates polymorphic behavior

Include code snippets for each step.

## Set 2: Understanding Model Traits and Relationships

### Questions

1. **What is the purpose of the `HasUlid` trait in the UME tutorial?**
   - A) To generate unique identifiers for users
   - B) To encrypt user data
   - C) To track user location
   - D) To manage user permissions

2. **What is the purpose of the `HasUserTracking` trait in the UME tutorial?**
   - A) To track user login history
   - B) To track which user created or updated a model
   - C) To track user location
   - D) To track user permissions

3. **What relationship type exists between `User` and `Team` in the UME tutorial?**
   - A) One-to-One
   - B) One-to-Many
   - C) Many-to-Many
   - D) Polymorphic

4. **What is the purpose of a pivot table in Laravel?**
   - A) To store primary key data
   - B) To connect two models in a Many-to-Many relationship
   - C) To improve query performance
   - D) To store encrypted data

### Exercise

**Design and implement a model with traits and relationships.**

Design a `Project` model that demonstrates the use of traits and relationships:

1. Create a migration for the `projects` table with appropriate columns
2. Create a `Project` model that uses at least two traits (e.g., `HasUlid`, `HasUserTracking`)
3. Define relationships between `Project` and other models (e.g., `User`, `Team`, `Task`)
4. Create a migration for any necessary pivot tables
5. Implement at least one accessor and one mutator on the `Project` model
6. Create a factory for the `Project` model

Include code snippets for each step and explain your design decisions.

## Additional Resources

- [Laravel Eloquent Relationships Documentation](https://laravel.com/docs/10.x/eloquent-relationships)
- [Tightenco Parental Package Documentation](https://github.com/tighten/parental)
- [Laravel Migrations Documentation](https://laravel.com/docs/10.x/migrations)
- [Laravel Factory Documentation](https://laravel.com/docs/10.x/database-testing)
