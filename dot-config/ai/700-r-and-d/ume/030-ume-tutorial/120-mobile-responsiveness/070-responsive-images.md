# Responsive Images

<link rel="stylesheet" href="../assets/css/styles.css">

Images often account for the majority of a web page's size. Optimizing images for different devices and screen sizes can significantly improve performance and user experience in your UME implementation.

## Understanding Responsive Images

Responsive images adapt to different screen sizes, pixel densities, and device capabilities:

1. **Key Challenges**:
   - Different screen sizes require different image dimensions
   - High-DPI displays (Retina) need higher resolution images
   - Mobile devices need smaller file sizes for faster loading
   - Different browsers support different image formats

2. **Benefits of Responsive Images**:
   - Faster page load times
   - Reduced bandwidth usage
   - Better visual quality across devices
   - Improved user experience

## Basic Responsive Image Techniques

### 1. The `srcset` Attribute

The `srcset` attribute allows you to specify multiple image sources for different screen widths:

```html
<img src="user-avatar-400w.jpg"
     srcset="user-avatar-100w.jpg 100w,
             user-avatar-200w.jpg 200w,
             user-avatar-400w.jpg 400w,
             user-avatar-800w.jpg 800w"
     sizes="(max-width: 600px) 100px,
            (max-width: 1200px) 200px,
            400px"
     alt="User Avatar">
```

### 2. The `picture` Element

The `picture` element provides more control over image selection:

```html
<picture>
    <source media="(max-width: 600px)" srcset="user-avatar-small.jpg">
    <source media="(max-width: 1200px)" srcset="user-avatar-medium.jpg">
    <source media="(min-width: 1201px)" srcset="user-avatar-large.jpg">
    <img src="user-avatar-medium.jpg" alt="User Avatar">
</picture>
```

### 3. Modern Image Formats with Fallbacks

Use modern formats like WebP with fallbacks for older browsers:

```html
<picture>
    <source type="image/webp" srcset="user-avatar.webp">
    <source type="image/jpeg" srcset="user-avatar.jpg">
    <img src="user-avatar.jpg" alt="User Avatar">
</picture>
```

## Implementing Responsive Images in Laravel

### 1. Using Laravel's Built-in Image Processing

Laravel doesn't include built-in image processing, but you can use packages like Intervention Image:

```php
// composer require intervention/image

// In a controller
use Intervention\Image\Facades\Image;

public function storeAvatar(Request $request)
{
    $request->validate([
        'avatar' => 'required|image|max:2048',
    ]);
    
    $image = Image::make($request->file('avatar'));
    
    // Create multiple sizes
    $sizes = [
        'small' => 100,
        'medium' => 300,
        'large' => 600
    ];
    
    $paths = [];
    
    foreach ($sizes as $name => $size) {
        // Create a copy with the specified size
        $resized = clone $image;
        $resized->fit($size, $size);
        
        // Save as WebP (better compression, smaller file size)
        $webpPath = 'avatars/' . $request->user()->id . '-' . $name . '.webp';
        $resized->encode('webp', 80)->save(public_path($webpPath));
        $paths[$name]['webp'] = $webpPath;
        
        // Save as JPEG for fallback
        $jpgPath = 'avatars/' . $request->user()->id . '-' . $name . '.jpg';
        $resized->encode('jpg', 80)->save(public_path($jpgPath));
        $paths[$name]['jpg'] = $jpgPath;
    }
    
    // Store paths in the database
    $request->user()->update([
        'avatar_paths' => json_encode($paths)
    ]);
    
    return back()->with('status', 'Avatar uploaded successfully!');
}
```

### 2. Using Spatie's Media Library

Spatie's Media Library package makes it easy to handle responsive images:

```php
// composer require spatie/laravel-medialibrary

// In your User model
use Spatie\MediaLibrary\HasMedia;
use Spatie\MediaLibrary\InteractsWithMedia;
use Spatie\MediaLibrary\MediaCollections\Models\Media;

class User extends Authenticatable implements HasMedia
{
    use InteractsWithMedia;
    
    public function registerMediaConversions(Media $media = null): void
    {
        $this->addMediaConversion('thumb')
            ->width(100)
            ->height(100)
            ->sharpen(10)
            ->nonQueued();
            
        $this->addMediaConversion('medium')
            ->width(300)
            ->height(300)
            ->sharpen(10)
            ->nonQueued();
            
        $this->addMediaConversion('large')
            ->width(600)
            ->height(600)
            ->sharpen(10)
            ->nonQueued();
    }
}

// In a controller
public function storeAvatar(Request $request)
{
    $request->validate([
        'avatar' => 'required|image|max:2048',
    ]);
    
    // Clear old avatars
    $request->user()->clearMediaCollection('avatars');
    
    // Add new avatar
    $request->user()
        ->addMediaFromRequest('avatar')
        ->usingName('avatar')
        ->toMediaCollection('avatars');
    
    return back()->with('status', 'Avatar uploaded successfully!');
}
```

### 3. Displaying Responsive Images with Spatie's Media Library

```php
<!-- In a Blade view -->
<img src="{{ $user->getFirstMediaUrl('avatars', 'medium') }}" 
     srcset="{{ $user->getFirstMediaUrl('avatars', 'thumb') }} 100w,
             {{ $user->getFirstMediaUrl('avatars', 'medium') }} 300w,
             {{ $user->getFirstMediaUrl('avatars', 'large') }} 600w"
     sizes="(max-width: 600px) 100px,
            (max-width: 1200px) 300px,
            600px"
     alt="{{ $user->name }}'s Avatar">
```

### 4. Using the Responsive Images Blade Component

Spatie's Media Library provides a convenient Blade component for responsive images:

```php
<!-- In a Blade view -->
<x-media-library-responsive-image 
    :media="$user->getFirstMedia('avatars')" 
    conversion="medium"
    alt="{{ $user->name }}'s Avatar" />
```

## Optimizing Background Images

### 1. CSS Background Images

Use media queries to serve different background images:

```css
.profile-header {
    background-image: url('/images/header-small.jpg');
    background-size: cover;
    background-position: center;
    height: 200px;
}

@media (min-width: 768px) {
    .profile-header {
        background-image: url('/images/header-medium.jpg');
        height: 300px;
    }
}

@media (min-width: 1200px) {
    .profile-header {
        background-image: url('/images/header-large.jpg');
        height: 400px;
    }
}
```

### 2. Inline Background Images with Responsive Sources

For more control, use an image as a background with responsive sources:

```php
<div class="relative h-64 md:h-80 lg:h-96">
    <picture>
        <source media="(max-width: 640px)" srcset="{{ asset('images/header-small.jpg') }}">
        <source media="(max-width: 1024px)" srcset="{{ asset('images/header-medium.jpg') }}">
        <source media="(min-width: 1025px)" srcset="{{ asset('images/header-large.jpg') }}">
        <img src="{{ asset('images/header-medium.jpg') }}" 
             alt="Profile Header" 
             class="absolute inset-0 w-full h-full object-cover">
    </picture>
    
    <div class="absolute inset-0 bg-black bg-opacity-50 flex items-center justify-center">
        <h1 class="text-white text-3xl font-bold">{{ $user->name }}</h1>
    </div>
</div>
```

## Lazy Loading Images

### 1. Native Lazy Loading

Modern browsers support native lazy loading:

```html
<img src="user-avatar.jpg" 
     alt="User Avatar" 
     loading="lazy">
```

### 2. Intersection Observer API

For more control or older browser support, use the Intersection Observer API:

```javascript
// resources/js/lazy-loading.js
document.addEventListener('DOMContentLoaded', function() {
    const lazyImages = document.querySelectorAll('.lazy-image');
    
    if ('IntersectionObserver' in window) {
        const imageObserver = new IntersectionObserver(function(entries, observer) {
            entries.forEach(function(entry) {
                if (entry.isIntersecting) {
                    const image = entry.target;
                    image.src = image.dataset.src;
                    
                    if (image.dataset.srcset) {
                        image.srcset = image.dataset.srcset;
                    }
                    
                    image.classList.remove('lazy-image');
                    imageObserver.unobserve(image);
                }
            });
        });
        
        lazyImages.forEach(function(image) {
            imageObserver.observe(image);
        });
    } else {
        // Fallback for browsers that don't support Intersection Observer
        // Load all images immediately
        lazyImages.forEach(function(image) {
            image.src = image.dataset.src;
            
            if (image.dataset.srcset) {
                image.srcset = image.dataset.srcset;
            }
            
            image.classList.remove('lazy-image');
        });
    }
});
```

```html
<img class="lazy-image" 
     data-src="user-avatar.jpg" 
     data-srcset="user-avatar-small.jpg 100w, user-avatar-large.jpg 800w" 
     src="placeholder.jpg" 
     alt="User Avatar">
```

## Image Optimization Best Practices

### 1. Compress Images

Always compress images before serving them:

```php
// Using Intervention Image for compression
$image = Image::make($request->file('avatar'));
$image->encode('jpg', 80); // 80% quality, good balance between quality and file size
```

### 2. Choose the Right Format

- **JPEG**: Best for photographs and complex images with many colors
- **PNG**: Best for images with transparency or simple graphics
- **WebP**: Modern format with better compression than JPEG and PNG
- **SVG**: Best for icons, logos, and simple illustrations

### 3. Serve Responsive Images Based on Network Conditions

Use the Network Information API to serve lower quality images on slow connections:

```javascript
// resources/js/network-aware-images.js
if ('connection' in navigator) {
    const connection = navigator.connection;
    
    function updateImageQuality() {
        const imageQuality = connection.effectiveType === '4g' ? 'high' : 'low';
        document.documentElement.setAttribute('data-image-quality', imageQuality);
    }
    
    updateImageQuality();
    connection.addEventListener('change', updateImageQuality);
}
```

```css
/* resources/css/app.css */
[data-image-quality="low"] .adaptive-image {
    filter: blur(2px);
}

[data-image-quality="low"] .optional-image {
    display: none;
}
```

### 4. Use Content Delivery Networks (CDNs)

CDNs can automatically optimize and serve images from servers closer to the user:

- Cloudflare Images
- Cloudinary
- Imgix
- Amazon CloudFront

## Responsive Images in UME Components

### 1. User Avatars

```php
<!-- resources/views/components/user-avatar.blade.php -->
@props(['user', 'size' => 'medium'])

@php
$sizes = [
    'small' => ['dimensions' => '32px', 'conversion' => 'thumb'],
    'medium' => ['dimensions' => '48px', 'conversion' => 'medium'],
    'large' => ['dimensions' => '96px', 'conversion' => 'large'],
];

$dimensions = $sizes[$size]['dimensions'];
$conversion = $sizes[$size]['conversion'];
@endphp

<div class="inline-block rounded-full overflow-hidden" style="width: {{ $dimensions }}; height: {{ $dimensions }};">
    @if ($user->hasMedia('avatars'))
        <x-media-library-responsive-image 
            :media="$user->getFirstMedia('avatars')" 
            :conversion="$conversion"
            alt="{{ $user->name }}'s Avatar" />
    @else
        <div class="flex items-center justify-center bg-indigo-100 text-indigo-800 w-full h-full">
            {{ strtoupper(substr($user->name, 0, 1)) }}
        </div>
    @endif
</div>
```

### 2. Team Logos

```php
<!-- resources/views/components/team-logo.blade.php -->
@props(['team', 'size' => 'medium'])

@php
$sizes = [
    'small' => ['dimensions' => '40px', 'conversion' => 'thumb'],
    'medium' => ['dimensions' => '64px', 'conversion' => 'medium'],
    'large' => ['dimensions' => '128px', 'conversion' => 'large'],
];

$dimensions = $sizes[$size]['dimensions'];
$conversion = $sizes[$size]['conversion'];
@endphp

<div class="inline-block rounded overflow-hidden" style="width: {{ $dimensions }}; height: {{ $dimensions }};">
    @if ($team->hasMedia('logos'))
        <x-media-library-responsive-image 
            :media="$team->getFirstMedia('logos')" 
            :conversion="$conversion"
            alt="{{ $team->name }} Logo" />
    @else
        <div class="flex items-center justify-center bg-gray-100 text-gray-800 w-full h-full">
            {{ strtoupper(substr($team->name, 0, 2)) }}
        </div>
    @endif
</div>
```

### 3. Gallery Images

```php
<!-- resources/views/components/image-gallery.blade.php -->
@props(['images'])

<div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
    @foreach ($images as $image)
        <div class="aspect-w-1 aspect-h-1 overflow-hidden rounded-lg">
            <img src="{{ $image->getUrl('thumb') }}" 
                 srcset="{{ $image->getUrl('thumb') }} 100w,
                         {{ $image->getUrl('medium') }} 300w,
                         {{ $image->getUrl('large') }} 600w"
                 sizes="(max-width: 640px) 50vw,
                        (max-width: 1024px) 33vw,
                        25vw"
                 alt="{{ $image->name }}"
                 class="object-cover w-full h-full"
                 loading="lazy">
        </div>
    @endforeach
</div>
```

## Testing Responsive Images

### 1. Visual Testing

- Test on different devices and screen sizes
- Check that images load correctly at different viewport widths
- Verify that image quality is appropriate for each device

### 2. Performance Testing

- Use browser DevTools to measure image loading time
- Check network usage with different device emulations
- Verify that lazy loading works correctly

### 3. Automated Testing

```php
// tests/Browser/ResponsiveImagesTest.php
public function testResponsiveImagesLoadCorrectly()
{
    $this->browse(function (Browser $browser) {
        $browser->visit('/profile')
                ->assertPresent('img.responsive-image');
        
        // Test small screen
        $browser->resize(375, 667)
                ->assertAttribute('img.responsive-image', 'src', function ($src) {
                    return str_contains($src, 'thumb');
                });
        
        // Test medium screen
        $browser->resize(768, 1024)
                ->assertAttribute('img.responsive-image', 'src', function ($src) {
                    return str_contains($src, 'medium');
                });
        
        // Test large screen
        $browser->resize(1920, 1080)
                ->assertAttribute('img.responsive-image', 'src', function ($src) {
                    return str_contains($src, 'large');
                });
    });
}
```

## Responsive Images Checklist

Use this checklist to ensure your images are fully responsive:

- [ ] Images are available in multiple sizes
- [ ] Modern formats (WebP) are used with appropriate fallbacks
- [ ] `srcset` and `sizes` attributes are used for responsive images
- [ ] Images are compressed to reduce file size
- [ ] Lazy loading is implemented for off-screen images
- [ ] Background images adapt to different screen sizes
- [ ] Image dimensions are specified to prevent layout shifts
- [ ] Alternative text is provided for all images
- [ ] Images are tested on different devices and screen sizes

## Next Steps

Continue to [Mobile-Specific Features](./080-mobile-specific-features.md) to learn about features that are specific to mobile devices.
