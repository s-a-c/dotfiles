### Practical Exercise Solution

Here's a sample implementation of responsive images in a UME application:

#### 1. User Profile Component with Responsive Avatar

```php
<!-- resources/views/components/responsive-user-avatar.blade.php -->
@props(['user', 'class' => ''])

<div class="{{ $class }}">
    @if ($user->hasMedia('avatars'))
        <picture>
            <source 
                type="image/webp" 
                srcset="{{ $user->getFirstMediaUrl('avatars', 'thumb') }} 100w,
                        {{ $user->getFirstMediaUrl('avatars', 'medium') }} 300w,
                        {{ $user->getFirstMediaUrl('avatars', 'large') }} 600w"
                sizes="(max-width: 640px) 100px,
                       (max-width: 1024px) 300px,
                       600px">
            <source 
                type="image/jpeg" 
                srcset="{{ $user->getFirstMediaUrl('avatars', 'thumb', 'jpg') }} 100w,
                        {{ $user->getFirstMediaUrl('avatars', 'medium', 'jpg') }} 300w,
                        {{ $user->getFirstMediaUrl('avatars', 'large', 'jpg') }} 600w"
                sizes="(max-width: 640px) 100px,
                       (max-width: 1024px) 300px,
                       600px">
            <img 
                src="{{ $user->getFirstMediaUrl('avatars', 'medium', 'jpg') }}" 
                alt="{{ $user->name }}" 
                class="rounded-full object-cover"
                loading="lazy">
        </picture>
    @else
        <div class="bg-gray-200 rounded-full flex items-center justify-center text-gray-600">
            <span class="text-lg font-medium">{{ substr($user->name, 0, 1) }}</span>
        </div>
    @endif
</div>
```

#### 2. Team Header with Responsive Background Image

```php
<!-- resources/views/components/team-header.blade.php -->
@props(['team'])

<div class="relative">
    <!-- Responsive background image -->
    <div class="absolute inset-0 z-0 overflow-hidden">
        @if ($team->hasMedia('banners'))
            <picture>
                <source 
                    media="(max-width: 640px)" 
                    srcset="{{ $team->getFirstMediaUrl('banners', 'small') }}">
                <source 
                    media="(max-width: 1024px)" 
                    srcset="{{ $team->getFirstMediaUrl('banners', 'medium') }}">
                <source 
                    media="(min-width: 1025px)" 
                    srcset="{{ $team->getFirstMediaUrl('banners', 'large') }}">
                <img 
                    src="{{ $team->getFirstMediaUrl('banners', 'medium') }}" 
                    alt="{{ $team->name }} Banner" 
                    class="w-full h-full object-cover"
                    loading="lazy">
            </picture>
        @else
            <div class="w-full h-full bg-gradient-to-r from-blue-500 to-indigo-600"></div>
        @endif
        
        <!-- Overlay -->
        <div class="absolute inset-0 bg-black bg-opacity-40"></div>
    </div>
    
    <!-- Content -->
    <div class="relative z-10 px-4 py-16 sm:px-6 sm:py-24 lg:py-32 lg:px-8">
        <div class="text-center">
            <h1 class="text-4xl font-extrabold tracking-tight text-white sm:text-5xl lg:text-6xl">
                {{ $team->name }}
            </h1>
            <p class="mt-6 max-w-lg mx-auto text-xl text-white">
                {{ $team->description }}
            </p>
        </div>
    </div>
</div>
```

#### 3. Using Appropriate Image Formats with Fallbacks

```php
// app/Http/Controllers/TeamController.php
public function uploadBanner(Request $request, Team $team)
{
    $request->validate([
        'banner' => 'required|image|max:5120', // 5MB max
    ]);
    
    // Clear old banners
    $team->clearMediaCollection('banners');
    
    // Add the banner image with conversions
    $team->addMediaFromRequest('banner')
        ->usingName('team-banner')
        ->withResponsiveImages() // Automatically create responsive image sizes
        ->toMediaCollection('banners');
    
    return back()->with('status', 'Team banner uploaded successfully.');
}

// app/Models/Team.php
public function registerMediaConversions(Media $media = null): void
{
    $this->addMediaConversion('small')
        ->width(640)
        ->height(320)
        ->sharpen(10)
        ->format('webp') // Use WebP for better compression
        ->withResponsiveImages();
        
    $this->addMediaConversion('medium')
        ->width(1024)
        ->height(512)
        ->sharpen(10)
        ->format('webp')
        ->withResponsiveImages();
        
    $this->addMediaConversion('large')
        ->width(1920)
        ->height(960)
        ->sharpen(10)
        ->format('webp')
        ->withResponsiveImages();
    
    // Create JPEG fallbacks for browsers that don't support WebP
    $this->addMediaConversion('small-jpg')
        ->width(640)
        ->height(320)
        ->sharpen(10)
        ->format('jpg');
        
    $this->addMediaConversion('medium-jpg')
        ->width(1024)
        ->height(512)
        ->sharpen(10)
        ->format('jpg');
        
    $this->addMediaConversion('large-jpg')
        ->width(1920)
        ->height(960)
        ->sharpen(10)
        ->format('jpg');
}
```

#### 4. Lazy Loading for Images

```javascript
// resources/js/lazy-loading.js
document.addEventListener('DOMContentLoaded', function() {
    // Check if IntersectionObserver is supported
    if ('IntersectionObserver' in window) {
        const imageObserver = new IntersectionObserver(function(entries, observer) {
            entries.forEach(function(entry) {
                if (entry.isIntersecting) {
                    const image = entry.target;
                    
                    // Handle picture elements
                    if (image.tagName === 'PICTURE') {
                        const sources = image.querySelectorAll('source');
                        sources.forEach(source => {
                            if (source.dataset.srcset) {
                                source.srcset = source.dataset.srcset;
                                delete source.dataset.srcset;
                            }
                        });
                        
                        const img = image.querySelector('img');
                        if (img && img.dataset.src) {
                            img.src = img.dataset.src;
                            delete img.dataset.src;
                        }
                    } 
                    // Handle regular images
                    else if (image.dataset.src) {
                        image.src = image.dataset.src;
                        delete image.dataset.src;
                    }
                    
                    image.classList.remove('lazy-load');
                    observer.unobserve(image);
                }
            });
        });
        
        // Observe all images with lazy-load class
        document.querySelectorAll('.lazy-load').forEach(function(image) {
            imageObserver.observe(image);
        });
    } else {
        // Fallback for browsers that don't support IntersectionObserver
        document.querySelectorAll('.lazy-load').forEach(function(image) {
            if (image.tagName === 'PICTURE') {
                const sources = image.querySelectorAll('source');
                sources.forEach(source => {
                    if (source.dataset.srcset) {
                        source.srcset = source.dataset.srcset;
                        delete source.dataset.srcset;
                    }
                });
                
                const img = image.querySelector('img');
                if (img && img.dataset.src) {
                    img.src = img.dataset.src;
                    delete img.dataset.src;
                }
            } else if (image.dataset.src) {
                image.src = image.dataset.src;
                delete image.dataset.src;
            }
            
            image.classList.remove('lazy-load');
        });
    }
});
```

This implementation provides responsive images in a UME application:

1. A user profile component with a responsive avatar that adapts to different screen sizes
2. A team header with a responsive background image that loads different sizes based on screen width
3. Appropriate image formats (WebP) with fallbacks (JPEG) for older browsers
4. Lazy loading for images that are not immediately visible

## Exercise 7: Device Testing

### Multiple Choice Answers

1. Which of the following is the most reliable way to test mobile responsiveness?
   - **B) Testing on actual mobile devices**

2. What should you include in a device testing matrix?
   - **C) A representative sample of devices your users are likely to use**

3. Which tool is most useful for remote debugging on iOS devices?
   - **B) Safari Web Inspector**
