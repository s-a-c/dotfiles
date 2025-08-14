# Phase 6: Polishing & Deployment Exercises

<link rel="stylesheet" href="../assets/css/styles.css">

These exercises are designed to test your understanding of polishing, testing, and deployment in the UME tutorial. Each set contains questions and a practical exercise.

## Set 1: Internationalization and Feature Flags

### Questions

1. **What is internationalization (i18n) in the context of web applications?**
   - A) The process of making a website available in multiple countries
   - B) The process of designing and preparing an application to be usable in different languages and regions
   - C) The process of translating a website using Google Translate
   - D) The process of restricting access based on geographic location

2. **How are translations typically managed in Laravel applications?**
   - A) Using the `__()` helper function with translation keys
   - B) Using Google Translate API
   - C) Using separate codebases for each language
   - D) Using JavaScript libraries

3. **What are feature flags and why are they useful?**
   - A) Flags that indicate bugs in the code
   - B) A way to enable or disable features without deploying new code
   - C) Visual indicators in the UI
   - D) A type of unit test

4. **What package is used for feature flags in the UME tutorial?**
   - A) laravel/features
   - B) spatie/laravel-feature-flags
   - C) tightenco/feature-flags
   - D) laravel/pennant

### Exercise

**Implement internationalization and feature flags.**

Add internationalization and feature flags to a Laravel application:

1. Set up language files for at least two languages
2. Implement language switching
3. Extract all text to translation keys
4. Create a language preference setting for users
5. Implement feature flags for:
   - A new experimental UI component
   - A beta feature
   - A feature that should only be available to certain user types
6. Create an admin interface for managing feature flags
7. Write tests for both internationalization and feature flags

Include code snippets for each component and explain your implementation choices.

## Set 2: Testing and Deployment

### Questions

1. **What types of tests are included in the UME tutorial?**
   - A) Only unit tests
   - B) Only feature tests
   - C) Unit tests, feature tests, and browser tests
   - D) No tests are included

2. **What is the purpose of continuous integration (CI) in the development process?**
   - A) To automatically deploy code to production
   - B) To automatically run tests when code is pushed to the repository
   - C) To continuously update dependencies
   - D) To monitor the application in production

3. **What deployment strategy is recommended in the UME tutorial?**
   - A) FTP upload
   - B) Git push to production
   - C) Zero-downtime deployment with proper environment configuration
   - D) Manual file copying

4. **What is the purpose of the `.env` file in Laravel, and how should it be handled in production?**
   - A) It contains environment-specific configuration and should never be committed to version control
   - B) It contains application code and should be committed to version control
   - C) It contains database credentials and should be shared with all developers
   - D) It's only used in development and not needed in production

### Exercise

**Create a comprehensive test suite for a feature.**

Choose one feature from the UME tutorial (e.g., team management, user profiles, chat) and create a comprehensive test suite:
1. Write unit tests for the models and services
2. Write feature tests for the controllers and API endpoints
3. Write browser tests for the UI components
4. Include tests for edge cases and error handling
5. Set up a GitHub Actions workflow for continuous integration

Implement:
1. The test classes for each type of test
2. The test methods with assertions
3. Any necessary factories or test helpers
4. The GitHub Actions workflow configuration
5. A code coverage report configuration

Include code snippets for each part of the implementation.

## Additional Resources

- [Laravel Localization Documentation](https://laravel.com/docs/localization)
- [Laravel Pennant Documentation](https://laravel.com/docs/pennant)
- [Laravel Testing Documentation](https://laravel.com/docs/testing)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Laravel Deployment Best Practices](https://laravel.com/docs/deployment)
