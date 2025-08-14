# Phase 2: Auth & Profiles Exercises

<link rel="stylesheet" href="../assets/css/styles.css">

These exercises are designed to test your understanding of authentication and user profiles in the UME tutorial. Each set contains questions and a practical exercise.

## Set 1: Understanding Authentication

### Questions

1. **What is Laravel Fortify?**
   - A) A frontend framework
   - B) A headless authentication backend
   - C) A database migration tool
   - D) A testing framework

2. **How does Fortify differ from Laravel Breeze?**
   - A) Fortify is headless, while Breeze includes views
   - B) Fortify is for API authentication only
   - C) Breeze is deprecated in favor of Fortify
   - D) They are the same thing with different names

3. **What authentication features does Fortify provide out of the box?**
   - A) Only login and registration
   - B) Login, registration, password reset, email verification, and two-factor authentication
   - C) Only API token authentication
   - D) Only social authentication

4. **How does Livewire integrate with Fortify in the UME tutorial?**
   - A) It doesn't; they are used separately
   - B) Livewire provides the UI for Fortify's authentication features
   - C) Fortify provides the UI for Livewire's authentication features
   - D) They are competing technologies

### Exercise

**Implement custom authentication views with Fortify and Livewire.**

Create custom authentication views for a Laravel application:

1. Install Laravel Fortify
2. Configure Fortify to use your custom views
3. Create Livewire components for:
   - Login form
   - Registration form
   - Password reset form
   - Email verification
4. Customize the forms with Tailwind CSS
5. Add custom validation rules
6. Implement a "remember me" feature

Include code snippets for each step and explain your implementation choices.

## Set 2: User Profiles and Avatar Management

### Questions

1. **Why does the UME tutorial split the user name into multiple components?**
   - A) To waste database space
   - B) For better sorting, personalization, and handling diverse names
   - C) It's required by Laravel 12
   - D) To make forms more complex

2. **What package is used for file uploads and media management in the UME tutorial?**
   - A) laravel/fortify
   - B) spatie/laravel-medialibrary
   - C) tightenco/parental
   - D) laravel/sanctum

3. **How are avatar uploads implemented in the UME tutorial?**
   - A) Stored directly in the database as binary data
   - B) Stored in the public folder with no organization
   - C) Using Spatie's Media Library with collections
   - D) Using a third-party service like Cloudinary

4. **What is a media collection in Spatie's Media Library?**
   - A) A group of media files with specific configuration
   - B) A database table for storing media
   - C) A frontend component for displaying media
   - D) A JavaScript library for media manipulation

### Exercise

**Implement a user profile system with avatar management.**

Create a user profile system with the following features:

1. Create a migration to add profile fields to the users table:
   - first_name
   - last_name
   - bio
   - location
   - website
   - birth_date

2. Implement avatar management using Spatie's Media Library:
   - Install and configure the package
   - Create a media collection for avatars
   - Implement avatar upload functionality
   - Add avatar conversion for different sizes (thumbnail, medium, large)

3. Create Livewire components for:
   - Profile view
   - Profile edit form
   - Avatar upload and cropping

4. Implement validation for all profile fields
5. Add tests for the profile system

Include code snippets for each step and explain your implementation choices.

## Additional Resources

- [Laravel Fortify Documentation](https://laravel.com/docs/fortify)
- [Livewire Documentation](https://livewire.laravel.com/docs)
- [Spatie Media Library Documentation](https://spatie.be/docs/laravel-medialibrary)
- [Laravel Validation Documentation](https://laravel.com/docs/validation)
