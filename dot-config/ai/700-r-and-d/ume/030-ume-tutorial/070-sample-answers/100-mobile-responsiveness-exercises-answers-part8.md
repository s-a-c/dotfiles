### Practical Exercise Solution

Here are solutions for common mobile responsiveness issues:

#### 1. Fixing Content Overflow in a Data Table

**Problem**: Data tables often extend beyond the viewport on mobile devices, causing horizontal scrolling.

**Solution**:

```php
<!-- resources/views/components/responsive-table.blade.php -->
<div class="overflow-x-auto">
    <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
            <tr>
                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Name
                </th>
                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider hidden sm:table-cell">
                    Email
                </th>
                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider hidden md:table-cell">
                    Role
                </th>
                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                </th>
            </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
            @foreach ($users as $user)
                <tr>
                    <td class="px-6 py-4 whitespace-nowrap">
                        <div class="flex items-center">
                            <div class="flex-shrink-0 h-10 w-10">
                                <img class="h-10 w-10 rounded-full" src="{{ $user->profile_photo_url }}" alt="{{ $user->name }}">
                            </div>
                            <div class="ml-4">
                                <div class="text-sm font-medium text-gray-900">
                                    {{ $user->name }}
                                </div>
                                <div class="text-sm text-gray-500 sm:hidden">
                                    {{ $user->email }}
                                </div>
                                <div class="text-sm text-gray-500 md:hidden sm:block">
                                    {{ $user->role }}
                                </div>
                            </div>
                        </div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 hidden sm:table-cell">
                        {{ $user->email }}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 hidden md:table-cell">
                        {{ $user->role }}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <a href="#" class="text-indigo-600 hover:text-indigo-900">Edit</a>
                    </td>
                </tr>
            @endforeach
        </tbody>
    </table>
</div>
```

This solution:
- Wraps the table in a container with `overflow-x-auto` to enable horizontal scrolling when needed
- Hides less important columns on smaller screens using `hidden sm:table-cell` and `hidden md:table-cell`
- Shows the hidden column data inline on mobile using responsive utility classes
- Maintains a clean layout on all screen sizes

#### 2. Resolving Touch Target Size Issues in a Form

**Problem**: Form elements are too small or too close together for comfortable touch interaction.

**Solution**:

```php
<!-- resources/views/components/touch-friendly-form.blade.php -->
<form method="POST" action="{{ route('profile.update') }}" class="space-y-6">
    @csrf
    @method('PUT')
    
    <div>
        <label for="name" class="block text-sm font-medium text-gray-700">
            Name
        </label>
        <div class="mt-1">
            <input 
                id="name" 
                name="name" 
                type="text" 
                value="{{ old('name', $user->name) }}" 
                required 
                class="appearance-none block w-full px-3 py-3 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm min-h-[44px]"
            >
        </div>
        @error('name')
            <p class="mt-2 text-sm text-red-600">{{ $message }}</p>
        @enderror
    </div>
    
    <div>
        <label for="email" class="block text-sm font-medium text-gray-700">
            Email
        </label>
        <div class="mt-1">
            <input 
                id="email" 
                name="email" 
                type="email" 
                value="{{ old('email', $user->email) }}" 
                required 
                class="appearance-none block w-full px-3 py-3 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm min-h-[44px]"
            >
        </div>
        @error('email')
            <p class="mt-2 text-sm text-red-600">{{ $message }}</p>
        @enderror
    </div>
    
    <div class="flex flex-col sm:flex-row sm:space-x-4 space-y-6 sm:space-y-0">
        <div class="w-full">
            <label for="city" class="block text-sm font-medium text-gray-700">
                City
            </label>
            <div class="mt-1">
                <input 
                    id="city" 
                    name="city" 
                    type="text" 
                    value="{{ old('city', $user->city) }}" 
                    class="appearance-none block w-full px-3 py-3 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm min-h-[44px]"
                >
            </div>
        </div>
        
        <div class="w-full">
            <label for="country" class="block text-sm font-medium text-gray-700">
                Country
            </label>
            <div class="mt-1">
                <select 
                    id="country" 
                    name="country" 
                    class="appearance-none block w-full px-3 py-3 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm min-h-[44px]"
                >
                    <option value="">Select a country</option>
                    @foreach ($countries as $code => $name)
                        <option value="{{ $code }}" {{ old('country', $user->country) === $code ? 'selected' : '' }}>
                            {{ $name }}
                        </option>
                    @endforeach
                </select>
            </div>
        </div>
    </div>
    
    <div class="pt-4">
        <button 
            type="submit" 
            class="w-full flex justify-center py-3 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 min-h-[44px]"
        >
            Update Profile
        </button>
    </div>
</form>
```

This solution:
- Increases touch target sizes with `min-h-[44px]` and adequate padding
- Stacks form fields vertically on mobile and side-by-side on larger screens
- Provides adequate spacing between form elements
- Uses full-width inputs and buttons on mobile for easier targeting
- Ensures form labels are associated with their inputs for better accessibility

#### 3. Fixing a Navigation Menu that Relies on Hover States

**Problem**: Navigation dropdown menus that rely on hover states don't work on touch devices.

**Solution**:

```php
<!-- resources/views/components/touch-friendly-navigation.blade.php -->
<nav x-data="{ open: false, activeDropdown: null }" class="bg-white shadow">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
            <div class="flex">
                <div class="flex-shrink-0 flex items-center">
                    <img class="h-8 w-auto" src="/logo.svg" alt="Logo">
                </div>
                
                <!-- Desktop navigation -->
                <div class="hidden sm:ml-6 sm:flex sm:space-x-8">
                    <a href="{{ route('dashboard') }}" class="{{ request()->routeIs('dashboard') ? 'border-indigo-500 text-gray-900' : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700' }} inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                        Dashboard
                    </a>
                    
                    <!-- Teams dropdown (desktop) -->
                    <div class="relative" x-data="{ open: false }">
                        <button 
                            @click="open = !open" 
                            @click.away="open = false" 
                            class="{{ request()->routeIs('teams.*') ? 'border-indigo-500 text-gray-900' : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700' }} inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium"
                        >
                            Teams
                            <svg class="ml-1 h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                                <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
                            </svg>
                        </button>
                        
                        <div 
                            x-show="open" 
                            x-transition:enter="transition ease-out duration-200" 
                            x-transition:enter-start="opacity-0 translate-y-1" 
                            x-transition:enter-end="opacity-100 translate-y-0" 
                            x-transition:leave="transition ease-in duration-150" 
                            x-transition:leave-start="opacity-100 translate-y-0" 
                            x-transition:leave-end="opacity-0 translate-y-1" 
                            class="absolute z-10 mt-3 px-2 w-screen max-w-xs sm:px-0"
                        >
                            <div class="rounded-lg shadow-lg ring-1 ring-black ring-opacity-5 overflow-hidden">
                                <div class="relative grid gap-6 bg-white px-5 py-6 sm:gap-8 sm:p-8">
                                    <a href="{{ route('teams.index') }}" class="-m-3 p-3 block rounded-md hover:bg-gray-50">
                                        <p class="text-base font-medium text-gray-900">All Teams</p>
                                    </a>
                                    <a href="{{ route('teams.create') }}" class="-m-3 p-3 block rounded-md hover:bg-gray-50">
                                        <p class="text-base font-medium text-gray-900">Create Team</p>
                                    </a>
                                    <a href="{{ route('teams.invitations') }}" class="-m-3 p-3 block rounded-md hover:bg-gray-50">
                                        <p class="text-base font-medium text-gray-900">Invitations</p>
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <a href="{{ route('profile.show') }}" class="{{ request()->routeIs('profile.*') ? 'border-indigo-500 text-gray-900' : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700' }} inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                        Profile
                    </a>
                </div>
            </div>
            
            <!-- Mobile menu button -->
            <div class="flex items-center sm:hidden">
                <button 
                    @click="open = !open" 
                    class="inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-indigo-500"
                >
                    <span class="sr-only">Open main menu</span>
                    <svg 
                        x-show="!open" 
                        class="h-6 w-6" 
                        xmlns="http://www.w3.org/2000/svg" 
                        fill="none" 
                        viewBox="0 0 24 24" 
                        stroke="currentColor" 
                        aria-hidden="true"
                    >
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                    </svg>
                    <svg 
                        x-show="open" 
                        class="h-6 w-6" 
                        xmlns="http://www.w3.org/2000/svg" 
                        fill="none" 
                        viewBox="0 0 24 24" 
                        stroke="currentColor" 
                        aria-hidden="true"
                    >
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </div>
        </div>
    </div>
    
    <!-- Mobile menu -->
    <div x-show="open" class="sm:hidden">
        <div class="pt-2 pb-3 space-y-1">
            <a href="{{ route('dashboard') }}" class="{{ request()->routeIs('dashboard') ? 'bg-indigo-50 border-indigo-500 text-indigo-700' : 'border-transparent text-gray-500 hover:bg-gray-50 hover:border-gray-300 hover:text-gray-700' }} block pl-3 pr-4 py-2 border-l-4 text-base font-medium">
                Dashboard
            </a>
            
            <!-- Teams section (mobile) -->
            <div>
                <button 
                    @click="activeDropdown = activeDropdown === 'teams' ? null : 'teams'" 
                    class="{{ request()->routeIs('teams.*') ? 'bg-indigo-50 border-indigo-500 text-indigo-700' : 'border-transparent text-gray-500 hover:bg-gray-50 hover:border-gray-300 hover:text-gray-700' }} w-full flex justify-between items-center pl-3 pr-4 py-2 border-l-4 text-base font-medium"
                >
                    <span>Teams</span>
                    <svg 
                        class="h-5 w-5 transform" 
                        :class="activeDropdown === 'teams' ? 'rotate-180' : ''" 
                        xmlns="http://www.w3.org/2000/svg" 
                        viewBox="0 0 20 20" 
                        fill="currentColor"
                    >
                        <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
                    </svg>
                </button>
                
                <div x-show="activeDropdown === 'teams'" class="pl-4 pr-4 py-2 space-y-1">
                    <a href="{{ route('teams.index') }}" class="block pl-3 pr-4 py-2 border-l-4 border-transparent text-base font-medium text-gray-500 hover:bg-gray-50 hover:border-gray-300 hover:text-gray-700">
                        All Teams
                    </a>
                    <a href="{{ route('teams.create') }}" class="block pl-3 pr-4 py-2 border-l-4 border-transparent text-base font-medium text-gray-500 hover:bg-gray-50 hover:border-gray-300 hover:text-gray-700">
                        Create Team
                    </a>
                    <a href="{{ route('teams.invitations') }}" class="block pl-3 pr-4 py-2 border-l-4 border-transparent text-base font-medium text-gray-500 hover:bg-gray-50 hover:border-gray-300 hover:text-gray-700">
                        Invitations
                    </a>
                </div>
            </div>
            
            <a href="{{ route('profile.show') }}" class="{{ request()->routeIs('profile.*') ? 'bg-indigo-50 border-indigo-500 text-indigo-700' : 'border-transparent text-gray-500 hover:bg-gray-50 hover:border-gray-300 hover:text-gray-700' }} block pl-3 pr-4 py-2 border-l-4 text-base font-medium">
                Profile
            </a>
        </div>
    </div>
</nav>
```

This solution:
- Replaces hover-based dropdowns with click/tap toggles using Alpine.js
- Provides different interaction patterns for desktop and mobile
- Uses explicit buttons for dropdown toggles with appropriate ARIA attributes
- Includes visual indicators (arrows) to show that items can be expanded
- Maintains a consistent visual style across devices

#### 4. Optimizing a Slow-Loading Page for Better Mobile Performance

**Problem**: A page loads slowly on mobile devices due to large images, unoptimized JavaScript, and inefficient API calls.

**Solution**:

1. **Optimize Images**:
```php
// app/Http/Controllers/TeamGalleryController.php
public function optimizeImages()
{
    // Get all team gallery images
    $galleryImages = TeamGalleryImage::all();
    
    foreach ($galleryImages as $image) {
        // Skip already optimized images
        if ($image->optimized) {
            continue;
        }
        
        // Get the media item
        $media = $image->getFirstMedia('gallery');
        
        if (!$media) {
            continue;
        }
        
        // Create optimized versions
        $media->addMediaConversion('thumb')
            ->width(300)
            ->height(300)
            ->format('webp')
            ->optimize()
            ->nonQueued();
            
        $media->addMediaConversion('medium')
            ->width(600)
            ->height(600)
            ->format('webp')
            ->optimize()
            ->nonQueued();
        
        // Mark as optimized
        $image->update(['optimized' => true]);
    }
    
    return back()->with('status', 'Gallery images optimized successfully.');
}
```

2. **Implement Code Splitting and Lazy Loading**:
```javascript
// resources/js/app.js
import { createApp } from 'vue';
import Alpine from 'alpinejs';

// Core functionality
import './bootstrap';
import './core';

// Register Alpine
window.Alpine = Alpine;
Alpine.start();

// Only load what's needed based on the current page
if (document.querySelector('#team-gallery')) {
    import('./components/team-gallery')
        .then(module => {
            const app = createApp(module.default);
            app.mount('#team-gallery');
        });
}

if (document.querySelector('#team-chat')) {
    import('./components/team-chat')
        .then(module => {
            const app = createApp(module.default);
            app.mount('#team-chat');
        });
}
```

3. **Optimize API Calls**:
```php
// app/Http/Controllers/API/TeamGalleryController.php
public function index(Request $request, Team $team)
{
    // Determine if this is a mobile request
    $isMobile = $request->header('X-Device-Type') === 'mobile' || 
                (strpos($request->userAgent(), 'Mobile') !== false);
    
    // Get pagination parameters with smaller page size for mobile
    $perPage = $isMobile ? 10 : 20;
    $page = $request->input('page', 1);
    
    // Get gallery images with pagination
    $images = $team->galleryImages()
        ->with(['media' => function ($query) use ($isMobile) {
            // Only select needed fields
            $query->select('id', 'model_id', 'model_type', 'disk', 'file_name');
        }])
        ->latest()
        ->paginate($perPage);
    
    // Transform the data to include only what's needed
    $transformedImages = $images->map(function ($image) use ($isMobile) {
        return [
            'id' => $image->id,
            'title' => $image->title,
            'url' => $image->getFirstMediaUrl('gallery', $isMobile ? 'thumb' : 'medium'),
            // Only include additional data for desktop
            'description' => $isMobile ? null : $image->description,
            'created_at' => $image->created_at->toDateTimeString(),
        ];
    });
    
    // Return paginated response
    return response()->json([
        'data' => $transformedImages,
        'meta' => [
            'current_page' => $images->currentPage(),
            'last_page' => $images->lastPage(),
            'per_page' => $images->perPage(),
            'total' => $images->total(),
        ],
    ]);
}
```

4. **Implement Virtualized Lists for Long Content**:
```vue
<!-- resources/js/components/team-gallery.vue -->
<template>
    <div class="team-gallery">
        <div v-if="loading" class="loading-indicator">
            <spinner />
        </div>
        
        <virtual-list
            v-else
            :data-key="'id'"
            :data-sources="images"
            :data-component="ImageItem"
            :keeps="20"
            :estimate-size="300"
        />
        
        <div v-if="hasMore" class="load-more">
            <button 
                @click="loadMore" 
                :disabled="loadingMore" 
                class="px-4 py-2 bg-indigo-600 text-white rounded-md"
            >
                {{ loadingMore ? 'Loading...' : 'Load More' }}
            </button>
        </div>
    </div>
</template>

<script>
import { ref, onMounted, defineComponent } from 'vue';
import VirtualList from 'vue-virtual-scroll-list';
import ImageItem from './image-item.vue';
import Spinner from './spinner.vue';

export default defineComponent({
    components: {
        VirtualList,
        Spinner
    },
    
    setup() {
        const images = ref([]);
        const loading = ref(true);
        const loadingMore = ref(false);
        const currentPage = ref(1);
        const lastPage = ref(1);
        
        const loadImages = async (page = 1) => {
            try {
                const response = await fetch(`/api/teams/${teamId}/gallery?page=${page}`);
                const data = await response.json();
                
                if (page === 1) {
                    images.value = data.data;
                } else {
                    images.value = [...images.value, ...data.data];
                }
                
                currentPage.value = data.meta.current_page;
                lastPage.value = data.meta.last_page;
            } catch (error) {
                console.error('Error loading images:', error);
            } finally {
                loading.value = false;
                loadingMore.value = false;
            }
        };
        
        const loadMore = () => {
            if (currentPage.value < lastPage.value) {
                loadingMore.value = true;
                loadImages(currentPage.value + 1);
            }
        };
        
        const hasMore = computed(() => currentPage.value < lastPage.value);
        
        onMounted(() => {
            // Get team ID from the page
            const teamId = document.querySelector('#team-gallery').dataset.teamId;
            loadImages();
        });
        
        return {
            images,
            loading,
            loadingMore,
            loadMore,
            hasMore,
            ImageItem
        };
    }
});
</script>
```

These solutions address common mobile responsiveness issues:

1. The responsive table solution prevents horizontal overflow while maintaining usability on small screens
2. The touch-friendly form solution ensures all interactive elements are large enough for comfortable touch interaction
3. The touch-friendly navigation solution replaces hover-dependent dropdowns with explicit toggle buttons
4. The performance optimization solution improves page loading speed on mobile devices through image optimization, code splitting, API optimization, and virtualized lists

## Conclusion

These sample answers demonstrate how to implement mobile-responsive features in a UME application. By following these patterns and best practices, you can ensure your application provides an excellent user experience across all devices and screen sizes.
