# User Model Modification Guide

This guide provides a comprehensive, step-by-step approach to modify the User model in your Laravel application to:

1. Use `given_name` and `family_name` instead of `name`
   - `given_name` is the first part of the name
   - `family_name` is the remainder of the name
   - If name is a single word, it's assigned to `family_name`
2. Provide a getter for `name` that combines `given_name` and `family_name`
3. Add a method to generate initials from name
   - Takes the first letter of each part of the name
   - Only first and last initials are capitalized
4. Apply `HasSlug` trait together with `SlugOptions`
5. Apply ULID as a secondary unique key
6. Add avatar support using:
   - Simple URL-based avatars
   - Spatie Media Library for file uploads (including animated GIFs)

## Files That Need to Be Modified

1. `app/Models/User.php` - The main User model
2. `database/migrations/xxxx_xx_xx_add_name_fields_and_ulid_to_users_table.php` - Migration to update the users table
3. `database/factories/UserFactory.php` - Update the factory to use the new fields
4. `app/Http/Controllers/Auth/RegisteredUserController.php` - Update registration to use new fields
5. `app/Http/Controllers/Settings/ProfileController.php` - Update profile settings to use new fields
6. `composer.json` - Add Spatie Media Library package
7. `config/filesystems.php` - Configure media disk for avatar storage
8. `config/media-library.php` - Configure Spatie Media Library
9. `app/Http/Livewire/UploadAvatar.php` - Create Livewire component for avatar uploads

## Implementation Steps

### 1. Create a Migration to Update the Users Table

First, we need to create a migration to:
- Add `given_name` column (nullable)
- Add `family_name` column (initially nullable, then made non-nullable)
- Add `ulid` and `slug` columns
- Add `avatar` column for profile images
- Make `name` nullable (for backward compatibility)
- Ensure existing users have a value for `family_name`

The migration follows a three-step process:
1. Add all columns as nullable first
2. Populate `family_name` for existing users
3. Make `family_name` non-nullable after populating it

See the migration file in this guide: [Migration File](./database/migrations/xxxx_xx_xx_add_name_fields_and_ulid_to_users_table.php)

### 2. Update the User Model

The User model needs to be updated to:
- Add the new fields to `$fillable`
- Add the `HasSlug` trait
- Implement the `getSlugOptions()` method
- Add a getter for `name` that combines `given_name` and `family_name`
- Add a method to generate initials from name
- Add logic in the `boot()` method to:
  - Generate ULID for new records
  - Split `name` into `given_name` and `family_name` when saving
  - Handle single-word names by assigning them to `family_name`
  - Ensure `family_name` is always set (since it's not nullable)
  - Update the `name` field for backward compatibility

See the updated User model in this guide: [User Model](./app/Models/User.php)

### 3. Update the User Factory

The User factory needs to be updated to generate data for the new fields:

See the updated User factory in this guide: [User Factory](./database/factories/UserFactory.php)

### 4. Update the Registration Controller

The registration controller needs to be updated to handle the new fields:

See the updated controller in this guide: [RegisteredUserController](./app/Http/Controllers/Auth/RegisteredUserController.php)

### 5. Update the Profile Controller

The profile controller needs to be updated to handle the new fields:

See the updated controller in this guide: [ProfileController](./app/Http/Controllers/Settings/ProfileController.php)

### 6. Install and Configure Spatie Media Library

To support file uploads for avatars, we'll use Spatie Media Library:

#### 6.1 Install the Package

Add the package to your project:

```bash
composer require spatie/laravel-medialibrary
```

Publish the migrations and config:

```bash
php artisan vendor:publish --provider="Spatie\MediaLibrary\MediaLibraryServiceProvider" --tag="migrations"
php artisan vendor:publish --provider="Spatie\MediaLibrary\MediaLibraryServiceProvider" --tag="config"
```

Run the migrations:

```bash
php artisan migrate
```

#### 6.2 Configure Media Storage

Update your filesystems configuration to include a dedicated disk for media:

See the updated config in this guide: [filesystems.php](./config/filesystems.php)

Create a symbolic link for the media storage:

```bash
php artisan storage:link --disk=media
```

#### 6.3 Update the User Model

Update the User model to implement the `HasMedia` interface and use the `InteractsWithMedia` trait:

See the updated User model in this guide: [User.php](./app/Models/User.php)

#### 6.4 Create Avatar Upload Components

Create Livewire components for handling avatar uploads:

1. For profile updates: [UploadAvatar.php](./app/Http/Livewire/UploadAvatar.php)
2. For registration: [RegisterAvatar.php](./app/Http/Livewire/RegisterAvatar.php)

#### 6.5 Register Livewire Components

Create a service provider to register the Livewire components:

See the service provider in this guide: [LivewireServiceProvider.php](./app/Providers/LivewireServiceProvider.php)

### 7. Create a JavaScript Utility for Initials

Create a JavaScript utility function to generate initials in the frontend that matches the backend logic:

See the utility function in this guide: [initials.ts](./resources/js/utils/initials.ts)

## Implementation Process

1. Create the migration file
2. Run the migration: `php artisan migrate`
3. Update the User model
4. Update the User factory
5. Update the controllers
6. Install Spatie Media Library: `composer require spatie/laravel-medialibrary`
7. Publish and run Media Library migrations
8. Configure media storage and create symbolic link
9. Update User model to implement HasMedia
10. Create the avatar upload components (UploadAvatar and RegisterAvatar)
11. Create the service provider to register Livewire components
12. Create the JavaScript utility for initials
13. Create the avatar Blade component
14. Test the changes

## Testing

A comprehensive test suite is provided to verify the name handling and initials generation:

See the test file in this guide: [UserTest.php](./tests/Unit/UserTest.php)

The tests verify:
- Name splitting when saving a user
- Single-word name handling
- Multi-part name handling
- Initials generation
- Name generation from given_name and family_name
- Avatar handling with both URLs and media uploads

See the media upload test file: [UserMediaTest.php](./tests/Feature/UserMediaTest.php)

## Backward Compatibility

This implementation maintains backward compatibility by:
- Keeping the `name` column (but making it nullable)
- Adding a getter for `name` that concatenates `given_name` and `family_name`
- Updating the `name` column in the `saving` event when `given_name` or `family_name` changes
- Automatically splitting the `name` field into `given_name` and `family_name` when only `name` is provided
- Ensuring `name` is not nullable when rolling back the migration
- Making sure `family_name` is always set to a value (not nullable)

## Manual Testing

After implementing these changes, you should manually test:
1. User registration with the new fields
2. User profile updates
3. Authentication still works
4. Any features that rely on the `name` attribute
5. Initials generation works correctly
6. Name splitting works correctly for single-word and multi-word names
7. Slug generation works correctly
8. ULID generation works correctly
9. Avatar URL input and display works correctly
10. Avatar file upload works correctly
11. Animated GIF uploads work correctly
12. Media storage symbolic link is accessible
13. Livewire avatar upload component works during profile updates
14. Livewire avatar upload component works during registration
15. Avatar thumbnails are generated correctly

## Potential Issues

1. Frontend forms will need to be updated to use `given_name` and `family_name` instead of `name`
2. API responses may need to be updated if they rely on the `name` field
3. Existing users will have `null` values for `given_name` until they update their profiles (but will have a value for `family_name`)
4. User interfaces that display avatars will need to be updated to handle both URL-based and media-based avatars
5. File upload components need to be added to registration and profile forms
6. Any custom code that generates initials will need to be updated to match the new logic
7. Single-word names will be treated as family names, which may not be appropriate in all cases
8. The JavaScript initials utility needs to be imported and used in all components that display user initials
9. Media Library requires additional server dependencies (GD Library or Imagick)
10. Large animated GIFs may cause performance issues
11. Media storage disk needs proper configuration and permissions
12. Symbolic link for media storage must be created
13. Livewire components require Alpine.js to be included in the frontend
14. Temporary uploads from Livewire need to be handled properly during registration
15. The avatar upload components need to be registered in the LivewireServiceProvider
16. When adding non-nullable columns to existing tables, use a multi-step migration approach (add as nullable, populate data, then make non-nullable)
