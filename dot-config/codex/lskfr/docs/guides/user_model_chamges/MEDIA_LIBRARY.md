# Spatie Media Library Integration for User Avatars

This document provides detailed information about the integration of Spatie Media Library for handling user avatars in the application.

## Overview

The integration allows users to:
- Upload avatar images (including animated GIFs)
- Use URL-based avatars
- Generate thumbnails and responsive images
- Manage their avatars through a user-friendly interface

## Installation

1. Install the package via Composer:

```bash
composer require spatie/laravel-medialibrary
```

2. Publish the migrations and config:

```bash
php artisan vendor:publish --provider="Spatie\MediaLibrary\MediaLibraryServiceProvider" --tag="migrations"
php artisan vendor:publish --provider="Spatie\MediaLibrary\MediaLibraryServiceProvider" --tag="config"
```

3. Run the migrations:

```bash
php artisan migrate
```

4. Configure the media disk in `config/filesystems.php`:

```php
'disks' => [
    // ...
    'media' => [
        'driver' => 'local',
        'root' => storage_path('app/media'),
        'url' => env('APP_URL').'/media',
        'visibility' => 'public',
        'throw' => false,
    ],
],

'links' => [
    // ...
    public_path('media') => storage_path('app/media'),
],
```

5. Create the symbolic link:

```bash
php artisan storage:link --disk=media
```

Alternatively, you can use the provided command to set up everything at once:

```bash
php artisan media:setup
```

## Configuration

### Media Library Configuration

The Media Library is configured in `config/media-library.php`. Key settings include:

- `disk_name`: Set to `'media'` to use the dedicated media disk
- `max_file_size`: Set to 10MB by default
- `image_driver`: Uses GD by default, can be changed to Imagick

### User Model Configuration

The User model is configured to:

1. Implement the `HasMedia` interface
2. Use the `InteractsWithMedia` trait
3. Register a media collection for avatars
4. Define conversions for thumbnails

```php
public function registerMediaCollections(): void
{
    $this->addMediaCollection('avatar')
        ->singleFile()
        ->acceptsMimeTypes(['image/jpeg', 'image/png', 'image/gif'])
        ->registerMediaConversions(function (Media $media) {
            $this->addMediaConversion('thumb')
                ->width(100)
                ->height(100)
                ->nonQueued();
                
            $this->addMediaConversion('medium')
                ->width(300)
                ->height(300)
                ->nonQueued();
        });
}
```

## Usage

### Uploading Avatars

The application provides a Livewire component for uploading avatars:

```php
// In a controller or Livewire component
$user->clearMediaCollection('avatar');
$user->addMedia($request->file('avatar'))
    ->toMediaCollection('avatar');
```

### Retrieving Avatar URLs

The User model provides accessor methods for avatar URLs:

```php
// Get the full-size avatar URL
$avatarUrl = $user->avatar_url;

// Get the thumbnail URL
$thumbnailUrl = $user->avatar_thumb_url;
```

### Displaying Avatars

Use the provided Blade component to display avatars:

```blade
<x-avatar :user="$user" size="md" />
```

Or use the URLs directly:

```blade
<img src="{{ $user->avatar_url }}" alt="{{ $user->name }}" class="rounded-full">
```

## Fallback Mechanism

The system implements a fallback mechanism:

1. First tries to use the media from the avatar collection
2. If no media is found, falls back to the avatar URL field
3. If no URL is provided, displays the user's initials

## Handling Animated GIFs

The Media Library preserves animated GIFs by default. No special configuration is needed to support them.

## Performance Considerations

- Thumbnails are generated using non-queued conversions for immediate availability
- For production environments with heavy usage, consider:
  - Switching to queued conversions
  - Using a CDN for media storage
  - Implementing caching for avatar URLs

## Testing

The integration includes comprehensive tests:

```php
// Test uploading an avatar
$user->addMedia($file)->toMediaCollection('avatar');
$this->assertTrue($user->hasMedia('avatar'));

// Test animated GIF support
$file = UploadedFile::fake()->image('avatar.gif');
$user->addMedia($file)->toMediaCollection('avatar');
$this->assertEquals('image/gif', $user->getFirstMedia('avatar')->mime_type);
```
