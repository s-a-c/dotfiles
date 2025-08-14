# Phase 5: Advanced Features Exercises

<link rel="stylesheet" href="../assets/css/styles.css">

These exercises are designed to test your understanding of advanced features in the UME tutorial. Each set contains questions and a practical exercise.

## Set 1: Understanding Search and Impersonation

### Questions

1. **What is Laravel Scout?**
   - A) A security scanning tool
   - B) A full-text search solution for Eloquent models
   - C) A user tracking system
   - D) A deployment tool

2. **What search engine is used with Laravel Scout in the UME tutorial?**
   - A) Elasticsearch
   - B) Algolia
   - C) Typesense
   - D) Meilisearch

3. **What is user impersonation and why is it useful?**
   - A) A security vulnerability that should be avoided
   - B) A feature that allows administrators to temporarily log in as another user for support purposes
   - C) A way to create fake users for testing
   - D) A method for sharing user accounts

4. **What security considerations are important when implementing user impersonation?**
   - A) There are no security concerns
   - B) Only allowing authorized users to impersonate, logging all impersonation actions, and clearly indicating when impersonation is active
   - C) Encrypting the impersonation token
   - D) Using a separate database for impersonation

### Exercise

**Implement a user impersonation system.**

Create a user impersonation system with the following features:

1. Create an ImpersonationManager service
2. Implement controller methods to start and stop impersonation
3. Add middleware to check impersonation permissions
4. Create a UI component to show when impersonation is active
5. Implement logging of all impersonation actions
6. Add security measures to prevent abuse
7. Write tests for the impersonation system

Include code snippets for each component and explain your implementation choices.

## Set 2: API Development and Documentation

### Questions

1. **What is Laravel Sanctum?**
   - A) A package for handling file uploads
   - B) A package for API authentication using tokens
   - C) A package for generating API documentation
   - D) A package for rate limiting API requests

2. **What is the difference between API resources and regular controllers in Laravel?**
   - A) They are the same thing
   - B) API resources are used for transforming models into JSON responses
   - C) Regular controllers can only return views, not JSON
   - D) API resources are deprecated

3. **What tool is recommended for API documentation in the UME tutorial?**
   - A) Swagger/OpenAPI
   - B) Postman
   - C) Scribe
   - D) API Blueprint

4. **What is rate limiting and why is it important for APIs?**
   - A) It's a way to charge users based on API usage
   - B) It limits the number of requests a client can make in a given time period to prevent abuse
   - C) It's a method for optimizing API performance
   - D) It's a security feature that limits API access to certain IP addresses

### Exercise

**Implement an API with authentication, documentation, and rate limiting.**

Create an API for the UME application with the following features:

1. Set up Laravel Sanctum for API authentication
2. Create API resources for:
   - Users
   - Teams
   - Permissions
   - Other relevant models
3. Implement CRUD operations for each resource
4. Add validation and error handling
5. Implement rate limiting
6. Generate API documentation using Scribe or a similar tool
7. Create tests for the API endpoints

Include code snippets for each component and explain your implementation choices.

## Additional Resources

- [Laravel Scout Documentation](https://laravel.com/docs/scout)
- [Typesense Documentation](https://typesense.org/docs/)
- [Laravel Sanctum Documentation](https://laravel.com/docs/sanctum)
- [Laravel API Resources Documentation](https://laravel.com/docs/eloquent-resources)
- [Scribe for Laravel Documentation](https://scribe.knuckles.wtf/laravel/)
