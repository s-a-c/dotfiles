# Beginner Learning Path

<link rel="stylesheet" href="../assets/css/styles.css">

This learning path is designed for developers who are new to Laravel or have limited experience with user model concepts. It provides a structured approach to learning the fundamentals before progressing to more advanced topics.

## Target Audience

This path is ideal for:
- Developers new to Laravel (0-6 months experience)
- PHP developers transitioning from other frameworks
- Web developers with limited experience in authentication systems
- Students or junior developers learning web application development

## Prerequisites

Before starting this path, you should have:
- Basic PHP knowledge (variables, functions, classes)
- Understanding of HTML, CSS, and JavaScript fundamentals
- Familiarity with database concepts (tables, relationships)
- Basic understanding of HTTP and web application concepts

### Recommended Prerequisites

1. **PHP Fundamentals** (if needed)
   - [PHP: The Right Way](https://phptherightway.com/) - Estimated time: 4-6 hours
   - [PHP 8 New Features](https://www.php.net/releases/8.0/en.php) - Estimated time: 2 hours

2. **Web Development Basics** (if needed)
   - [MDN Web Docs: HTML Basics](https://developer.mozilla.org/en-US/docs/Learn/Getting_started_with_the_web/HTML_basics) - Estimated time: 2 hours
   - [MDN Web Docs: CSS Basics](https://developer.mozilla.org/en-US/docs/Learn/Getting_started_with_the_web/CSS_basics) - Estimated time: 2 hours
   - [MDN Web Docs: JavaScript Basics](https://developer.mozilla.org/en-US/docs/Learn/Getting_started_with_the_web/JavaScript_basics) - Estimated time: 3 hours

3. **Database Concepts** (if needed)
   - [SQL Basics Tutorial](https://www.w3schools.com/sql/) - Estimated time: 3 hours
   - [Database Design Fundamentals](https://www.tutorialspoint.com/dbms/index.htm) - Estimated time: 4 hours

## Learning Objectives

By completing this path, you will:
- Set up a Laravel development environment
- Understand Laravel's MVC architecture
- Implement basic user authentication
- Create and modify database migrations
- Work with Eloquent models and relationships
- Implement basic user profile functionality
- Understand the concept of Single Table Inheritance
- Create simple user interfaces with Livewire

## Recommended Path

**Total Estimated Completion Time: 8-12 days (40-60 hours)**

### Phase 1: Foundation (Estimated time: 2-3 days)

1. **Introduction to UME** (2 hours)
   - [Introduction](../010-introduction/000-index.md)
   - [Project Overview](../010-introduction/010-project-overview.md)
   - [Learning Objectives](../010-introduction/030-learning-objectives.md)

2. **Prerequisites** (4 hours)
   - [Development Environment Setup](../020-prerequisites/010-development-environment.md)
   - [Laravel Basics Review](../020-prerequisites/020-laravel-basics-review.md)
   - [Required Packages](../020-prerequisites/030-required-packages.md)
   - Complete the [Prerequisites Exercises](../060-exercises/020-prerequisites-exercises.md)

3. **PHP 8 Attributes Basics** (3 hours)
   - [PHP 8 Attributes Introduction](../050-implementation/010-phase0-foundation/060-php8-attributes.md)
   - Try the interactive examples for PHP 8 Attributes
   - Complete the [PHP 8 Attributes Exercises](../060-exercises/040-010-php8-attributes-exercises.md) (Set 1 only)

### Phase 2: Core Models (Estimated time: 3-4 days)

4. **Database Foundations** (4 hours)
   - [Database Design](../050-implementation/020-phase1-core-models/010-database-design.md)
   - [Migrations](../050-implementation/020-phase1-core-models/020-migrations.md)
   - Try creating your own migrations following the examples

5. **User Model Basics** (6 hours)
   - [User Model Overview](../050-implementation/020-phase1-core-models/030-user-model-overview.md)
   - [Model Relationships](../050-implementation/020-phase1-core-models/040-model-relationships.md)
   - Complete the [Core Models Exercises](../060-exercises/040-020-core-models-exercises.md) (Set 1 only)

6. **Single Table Inheritance Introduction** (6 hours)
   - [STI Concept](../050-implementation/020-phase1-core-models/050-single-table-inheritance.md)
   - [User Types](../050-implementation/020-phase1-core-models/060-user-types.md)
   - Watch the [STI Video Tutorial](../assets/020-visual-aids/040-video-tutorials/single-table-inheritance.md)
   - Review the [STI Quick Reference](../assets/020-visual-aids/010-cheat-sheets/single-table-inheritance.md)

7. **Model Traits** (4 hours)
   - [HasUlid Trait](../050-implementation/020-phase1-core-models/070-has-ulid-trait.md)
   - [HasUserTracking Trait](../050-implementation/020-phase1-core-models/080-has-user-tracking-trait.md)
   - Complete the [Model Traits Exercises](../060-exercises/040-030-model-traits-exercises.md) (Set 1 only)

### Phase 3: Authentication Basics (Estimated time: 2-3 days)

8. **Basic Authentication** (6 hours)
   - [Authentication Overview](../050-implementation/030-phase2-auth-profiles/010-authentication-overview.md)
   - [Laravel Fortify Setup](../050-implementation/030-phase2-auth-profiles/020-fortify-setup.md)
   - [Login and Registration](../050-implementation/030-phase2-auth-profiles/030-login-registration.md)
   - Complete the [Authentication Exercises](../060-exercises/040-040-authentication-exercises.md) (Set 1 only)

9. **User Profiles** (6 hours)
   - [Profile Management](../050-implementation/030-phase2-auth-profiles/050-profile-management.md)
   - [Profile UI](../050-implementation/030-phase2-auth-profiles/060-profile-ui.md)
   - Try implementing a basic profile page following the examples

### Phase 4: Troubleshooting and Review (Estimated time: 1-2 days)

10. **Troubleshooting Common Issues** (4 hours)
    - [Foundation Troubleshooting](../150-troubleshooting/010-phase0-foundation-troubleshooting.md)
    - [Core Models Troubleshooting](../150-troubleshooting/020-phase1-core-models-troubleshooting.md)
    - [Auth & Profiles Troubleshooting](../150-troubleshooting/030-phase2-auth-profile-troubleshooting.md)

11. **Review and Assessment** (4 hours)
    - Review all completed exercises
    - Take the [Beginner Assessment Quiz](#) (coming soon)
    - Build a simple user profile application using the concepts learned

## Learning Resources

### Recommended Reading
- [Laravel Documentation](https://laravel.com/docs) - Official Laravel documentation
- [Laracasts](https://laracasts.com) - Video tutorials for Laravel beginners
- [PHP 8 Attributes Documentation](https://www.php.net/manual/en/language.attributes.php)

### Interactive Tools
- Try the interactive code examples in each section
- Use the provided cheat sheets for quick reference
- Explore the sample applications in the tutorial

### Support Resources
- [Common Pitfalls](#) sections in each tutorial chapter
- [FAQ](#) for beginners
- [Troubleshooting Guides](#) for specific issues

## Progress Tracking

Use these checkpoints to track your progress through the beginner learning path:

- [ ] Completed Introduction and Prerequisites
- [ ] Set up development environment
- [ ] Completed PHP 8 Attributes section
- [ ] Created database migrations
- [ ] Implemented basic User model
- [ ] Understood Single Table Inheritance
- [ ] Implemented model traits
- [ ] Set up basic authentication
- [ ] Created user profile functionality
- [ ] Completed all beginner exercises
- [ ] Built simple profile application

## Next Steps

After completing this learning path, consider:

1. Moving to the [Intermediate Learning Path](020-intermediate-learning-path.md)
2. Exploring the [Teams & Permissions](../050-implementation/040-phase3-teams-permissions/000-index.md) section
3. Building a more complex application using the concepts learned
4. Contributing to the UME tutorial by submitting improvements or corrections

Remember that learning is a journey, not a destination. Take your time to understand each concept before moving on to more advanced topics.
