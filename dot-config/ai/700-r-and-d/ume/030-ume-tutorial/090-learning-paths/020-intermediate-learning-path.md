# Intermediate Learning Path

<link rel="stylesheet" href="../assets/css/styles.css">

This learning path is designed for developers who have some experience with Laravel but want to deepen their understanding of advanced user model concepts. It focuses on building upon existing knowledge to implement more sophisticated user management features.

## Target Audience

This path is ideal for:
- Developers with 6 months to 2 years of Laravel experience
- Web developers who have implemented basic authentication systems
- Developers looking to enhance existing applications with better user models
- Team members working on medium-sized Laravel projects

## Prerequisites

Before starting this path, you should have:
- Solid understanding of Laravel basics (routing, controllers, views)
- Experience with Eloquent ORM and database migrations
- Familiarity with Laravel's authentication system
- Basic understanding of PHP 8 features
- Experience building at least one Laravel application

### Recommended Prerequisites

1. **Laravel Fundamentals**
   - [Laravel Documentation: The Basics](https://laravel.com/docs/10.x/routing) - Estimated time: 4 hours
   - [Laravel Documentation: Eloquent ORM](https://laravel.com/docs/10.x/eloquent) - Estimated time: 6 hours
   - [Laravel Documentation: Authentication](https://laravel.com/docs/10.x/authentication) - Estimated time: 3 hours

2. **PHP 8 Features**
   - [PHP 8 Attributes](https://www.php.net/manual/en/language.attributes.php) - Estimated time: 2 hours
   - [PHP 8 Constructor Property Promotion](https://www.php.net/manual/en/language.oop5.decon.php#language.oop5.decon.constructor.promotion) - Estimated time: 1 hour
   - [PHP 8 Named Arguments](https://www.php.net/manual/en/functions.arguments.php#functions.named-arguments) - Estimated time: 1 hour

3. **Design Patterns**
   - [Laravel Design Patterns](https://laravelshift.com/opinionated-laravel-way/design-patterns) - Estimated time: 4 hours
   - [Single Table Inheritance](https://martinfowler.com/eaaCatalog/singleTableInheritance.html) - Estimated time: 2 hours
   - [State Pattern](https://refactoring.guru/design-patterns/state) - Estimated time: 2 hours

## Learning Objectives

By completing this path, you will:
- Implement advanced user model structures using Single Table Inheritance
- Create sophisticated authentication and authorization systems
- Build robust user profiles with custom fields and validation
- Implement state machines for user account management
- Develop team-based permissions and access control
- Create reusable traits for common user model functionality
- Optimize database queries for user-related operations
- Implement real-time features for user interactions

## Recommended Path

**Total Estimated Completion Time: 12-15 days (60-75 hours)**

### Phase 1: Advanced Model Concepts (Estimated time: 3-4 days)

1. **Review Foundation** (2 hours)
   - Quickly review [PHP 8 Attributes](../050-implementation/010-phase0-foundation/060-php8-attributes.md)
   - Complete the [PHP 8 Attributes Exercises](../060-exercises/040-010-php8-attributes-exercises.md) (Sets 1 and 2)

2. **Advanced Single Table Inheritance** (6 hours)
   - [STI Deep Dive](../050-implementation/020-phase1-core-models/050-single-table-inheritance.md)
   - [Advanced User Types](../050-implementation/020-phase1-core-models/060-user-types.md)
   - [Child Models Implementation](../050-implementation/020-phase1-core-models/090-child-models.md)
   - Complete the [STI Exercises](../060-exercises/040-025-sti-exercises.md) (All sets)

3. **Advanced Model Traits** (6 hours)
   - [HasUlid Trait Implementation](../050-implementation/020-phase1-core-models/070-has-ulid-trait.md)
   - [HasUserTracking Trait Implementation](../050-implementation/020-phase1-core-models/080-has-user-tracking-trait.md)
   - [Creating Custom Traits](../050-implementation/020-phase1-core-models/100-custom-traits.md)
   - Complete the [Model Traits Exercises](../060-exercises/040-030-model-traits-exercises.md) (All sets)

4. **Model Factories and Testing** (4 hours)
   - [Model Factories](../050-implementation/020-phase1-core-models/110-model-factories.md)
   - [Testing User Models](../050-implementation/020-phase1-core-models/120-testing-models.md)
   - Try implementing your own model factories and tests

### Phase 2: Advanced Authentication (Estimated time: 3-4 days)

5. **Authentication Deep Dive** (6 hours)
   - [Advanced Fortify Configuration](../050-implementation/030-phase2-auth-profiles/020-fortify-setup.md)
   - [Custom Authentication Logic](../050-implementation/030-phase2-auth-profiles/030-login-registration.md)
   - [Two-Factor Authentication](../050-implementation/030-phase2-auth-profiles/040-two-factor-auth.md)
   - Complete the [Authentication Exercises](../060-exercises/040-040-authentication-exercises.md) (Sets 1 and 2)

6. **State Machines** (8 hours)
   - [State Machine Concept](../050-implementation/030-phase2-auth-profiles/070-state-machines.md)
   - [User Account States](../050-implementation/030-phase2-auth-profiles/080-account-states.md)
   - [State Transitions](../050-implementation/030-phase2-auth-profiles/090-state-transitions.md)
   - Complete the [State Machine Exercises](../060-exercises/040-050-state-machine-exercises.md) (All sets)

7. **Advanced Profiles** (6 hours)
   - [Profile Data Management](../050-implementation/030-phase2-auth-profiles/050-profile-management.md)
   - [Advanced Profile UI](../050-implementation/030-phase2-auth-profiles/060-profile-ui.md)
   - [File Uploads and Media](../050-implementation/030-phase2-auth-profiles/100-file-uploads.md)
   - Try implementing a complete profile system with custom fields

### Phase 3: Teams and Permissions (Estimated time: 4-5 days)

8. **Teams Implementation** (8 hours)
   - [Team Model Design](../050-implementation/040-phase3-teams-permissions/010-team-model.md)
   - [Team Relationships](../050-implementation/040-phase3-teams-permissions/020-team-relationships.md)
   - [Team Management UI](../050-implementation/040-phase3-teams-permissions/030-team-management-ui.md)
   - Complete the [Teams Exercises](../060-exercises/040-060-teams-exercises.md) (Sets 1 and 2)

9. **Permissions System** (8 hours)
   - [Permission Model](../050-implementation/040-phase3-teams-permissions/040-permission-model.md)
   - [Role-Based Access Control](../050-implementation/040-phase3-teams-permissions/050-role-based-access.md)
   - [Team-Based Permissions](../050-implementation/040-phase3-teams-permissions/060-team-permissions.md)
   - Complete the [Permissions Exercises](../060-exercises/040-070-permissions-exercises.md) (Sets 1 and 2)

10. **Team Hierarchy and State** (6 hours)
    - [Team Hierarchy](../050-implementation/040-phase3-teams-permissions/070-team-hierarchy.md)
    - [Team State Machine](../050-implementation/040-phase3-teams-permissions/080-team-state-machine.md)
    - Complete the [Team Hierarchy Exercises](../060-exercises/040-080-team-hierarchy-state-machine-exercises.md) (Set 1)

### Phase 4: Real-time Features (Estimated time: 3-4 days)

11. **Real-time Basics** (6 hours)
    - [WebSockets Overview](../050-implementation/050-phase4-realtime/010-websockets-overview.md)
    - [Laravel Reverb Setup](../050-implementation/050-phase4-realtime/020-reverb-setup.md)
    - [Event Broadcasting](../050-implementation/050-phase4-realtime/030-event-broadcasting.md)
    - Complete the [Real-time Basics Exercises](../060-exercises/040-090-realtime-basics-exercises.md) (Set 1)

12. **User Presence and Activity** (6 hours)
    - [User Presence](../050-implementation/050-phase4-realtime/040-user-presence.md)
    - [Activity Logging](../050-implementation/050-phase4-realtime/050-activity-logging.md)
    - Try implementing a simple presence indicator system

### Phase 5: Performance and Security (Estimated time: 2-3 days)

13. **Performance Optimization** (6 hours)
    - [Query Optimization](../050-implementation/070-phase6-polishing/040-performance-optimization.md)
    - [Caching Strategies](../050-implementation/070-phase6-polishing/050-caching-strategies.md)
    - [Database Optimization](../050-implementation/070-phase6-polishing/060-database-optimization.md)
    - Try optimizing a user-heavy application using the techniques learned

14. **Security Best Practices** (6 hours)
    - [Authentication Security](../100-security-best-practices/020-authentication-security.md)
    - [Authorization Best Practices](../100-security-best-practices/030-authorization-best-practices.md)
    - [API Security](../100-security-best-practices/070-api-security.md)
    - Review your implementation for security vulnerabilities

## Learning Resources

### Recommended Reading
- [Laravel Advanced Documentation](https://laravel.com/docs) - Sections on authorization, queues, and events
- [Spatie Laravel Permission Documentation](https://spatie.be/docs/laravel-permission)
- [Laravel Reverb Documentation](https://laravel.com/docs/reverb)

### Interactive Tools
- Try the advanced interactive code examples in each section
- Use the provided cheat sheets for quick reference
- Explore the case studies for real-world applications

### Support Resources
- [Common Pitfalls](#) sections in each tutorial chapter
- [FAQ](#) for intermediate developers
- [Troubleshooting Guides](#) for specific issues

## Progress Tracking

Use these checkpoints to track your progress through the intermediate learning path:

- [ ] Completed Advanced STI implementation
- [ ] Created custom model traits
- [ ] Implemented model factories and tests
- [ ] Set up advanced authentication features
- [ ] Implemented state machines for user accounts
- [ ] Created advanced profile system with custom fields
- [ ] Implemented team models and relationships
- [ ] Set up permissions and role-based access control
- [ ] Created team hierarchy with state management
- [ ] Implemented real-time features with WebSockets
- [ ] Optimized performance for user-related queries
- [ ] Applied security best practices
- [ ] Completed all intermediate exercises

## Next Steps

After completing this learning path, consider:

1. Moving to the [Advanced Learning Path](030-advanced-learning-path.md)
2. Exploring the [Advanced Features](../050-implementation/060-phase5-advanced/000-index.md) section
3. Building a complex application with all the features learned
4. Contributing to the UME tutorial by submitting improvements or corrections
5. Exploring the case studies to see how these concepts apply in real-world scenarios

This intermediate path provides a solid foundation for implementing sophisticated user management systems in Laravel applications. By completing it, you'll have the skills to build robust, secure, and performant user-centric applications.
