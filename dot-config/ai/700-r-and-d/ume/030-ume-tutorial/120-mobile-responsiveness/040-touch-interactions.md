# Touch Interactions

<link rel="stylesheet" href="../assets/css/styles.css">

Optimizing your UME implementation for touch-based input is essential for providing a good user experience on mobile and tablet devices. This section covers best practices for designing touch-friendly interfaces.

## Understanding Touch Interactions

Touch interactions differ from mouse interactions in several important ways:

1. **No hover state**: Users can't hover over elements with touch devices
2. **Larger touch targets**: Fingers are less precise than mouse pointers
3. **Different gestures**: Touch devices support gestures like swipe, pinch, and tap
4. **No right-click**: Context menus need alternative access methods
5. **Virtual keyboards**: Can take up significant screen space

## Touch Target Size

The size of interactive elements is crucial for touch usability:

- **Minimum size**: 44×44 pixels (Apple's recommendation)
- **Recommended size**: 48×48 pixels (Google's recommendation)
- **Spacing**: At least 8px between touch targets

```php
<button class="px-4 py-3 min-h-[44px] min-w-[44px]">
    Submit
</button>
```

## Touch Feedback

Provide clear feedback for touch interactions:

1. **Visual feedback**: Change appearance when touched
2. **Haptic feedback**: Use device vibration for important actions (with user permission)
3. **Animation**: Subtle animations can indicate successful interactions

```php
<button class="px-4 py-2 bg-blue-500 text-white rounded
               active:bg-blue-700 active:scale-95 transition-all">
    Submit
</button>
```

## Common Touch Gestures

Incorporate common touch gestures in your UME implementation:

### Tap

The most basic touch interaction, equivalent to a mouse click.

```php
<button wire:click="saveProfile" class="px-4 py-2 bg-blue-500 text-white rounded">
    Save Profile
</button>
```

### Swipe

Used for scrolling, navigation, or revealing actions.

```php
<div x-data="{ open: false }"
     @touchstart="startX = $event.touches[0].clientX"
     @touchend="
        endX = $event.changedTouches[0].clientX;
        if (startX - endX > 50) { open = true; }
        if (endX - startX > 50) { open = false; }
     "
     class="relative overflow-hidden">
    
    <!-- Main content -->
    <div class="p-4">
        <h2>Team Members</h2>
        <!-- Content -->
    </div>
    
    <!-- Swipe to reveal actions -->
    <div x-show="open" 
         class="absolute inset-y-0 right-0 flex items-center"
         x-transition>
        <button class="h-full px-4 bg-blue-500 text-white">Edit</button>
        <button class="h-full px-4 bg-red-500 text-white">Delete</button>
    </div>
</div>
```

### Long Press

Used for revealing context menus or additional options.

```php
<div x-data="{ showOptions: false }"
     @touchstart="touchTimer = setTimeout(() => showOptions = true, 500)"
     @touchend="clearTimeout(touchTimer)"
     @touchmove="clearTimeout(touchTimer)"
     class="relative p-4 border rounded">
    
    <h3>Team: Design Department</h3>
    <p>12 members</p>
    
    <!-- Options menu (shown on long press) -->
    <div x-show="showOptions" 
         @click.away="showOptions = false"
         class="absolute top-full left-0 mt-1 w-48 bg-white shadow-lg rounded z-10">
        <div class="py-1">
            <a href="#" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">Edit Team</a>
            <a href="#" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">Add Member</a>
            <a href="#" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">Delete Team</a>
        </div>
    </div>
</div>
```

### Pinch to Zoom

Consider how your interface behaves when users zoom in:

- Ensure text remains readable when zoomed
- Test that layouts don't break when zoomed
- Provide built-in zoom functionality for images and documents

```php
<div x-data="{ scale: 1 }"
     @touchstart.prevent="if ($event.touches.length === 2) { initialDistance = Math.hypot($event.touches[0].pageX - $event.touches[1].pageX, $event.touches[0].pageY - $event.touches[1].pageY); }"
     @touchmove.prevent="
        if ($event.touches.length === 2) {
            const distance = Math.hypot($event.touches[0].pageX - $event.touches[1].pageX, $event.touches[0].pageY - $event.touches[1].pageY);
            scale = Math.min(Math.max(0.5, scale * (distance / initialDistance)), 3);
            initialDistance = distance;
        }
     "
     class="overflow-hidden">
    
    <img :style="{ transform: `scale(${scale})` }" 
         class="max-w-full transition-transform origin-center"
         src="/path/to/image.jpg" 
         alt="Zoomable image">
</div>
```

## Replacing Hover Interactions

Since hover states don't work on touch devices, you need alternatives:

### 1. Explicit Toggle Buttons

Replace hover-revealed information with toggle buttons.

```php
<div x-data="{ showInfo: false }">
    <div class="flex items-center">
        <h3>Team: Design Department</h3>
        <button @click="showInfo = !showInfo" class="ml-2 p-1 rounded-full">
            <x-flux::icon name="information-circle" class="h-5 w-5 text-gray-400" />
        </button>
    </div>
    
    <div x-show="showInfo" class="mt-2 p-2 bg-gray-100 rounded text-sm">
        This team is responsible for all design-related tasks in the organization.
    </div>
</div>
```

### 2. Progressive Disclosure

Show the most important information first, with options to reveal more.

```php
<div x-data="{ expanded: false }">
    <div class="p-4 border rounded">
        <div class="flex justify-between items-center">
            <h3>Team: Design Department</h3>
            <button @click="expanded = !expanded" class="p-1">
                <x-flux::icon name="chevron-down" class="h-5 w-5 transition-transform" :class="expanded ? 'rotate-180' : ''" />
            </button>
        </div>
        
        <div x-show="expanded" class="mt-4">
            <p>Created: January 15, 2023</p>
            <p>Members: 12</p>
            <p>Projects: 5 active</p>
            <div class="mt-2 flex space-x-2">
                <button class="px-3 py-1 bg-blue-500 text-white rounded text-sm">Edit</button>
                <button class="px-3 py-1 bg-red-500 text-white rounded text-sm">Delete</button>
            </div>
        </div>
    </div>
</div>
```

### 3. Always Visible Actions

Make important actions always visible instead of hiding them behind hover states.

```php
<div class="p-4 border rounded">
    <div class="flex justify-between items-center">
        <h3>Team: Design Department</h3>
        <div class="flex space-x-2">
            <button class="p-1 text-blue-500">
                <x-flux::icon name="pencil" class="h-5 w-5" />
            </button>
            <button class="p-1 text-red-500">
                <x-flux::icon name="trash" class="h-5 w-5" />
            </button>
        </div>
    </div>
    <p class="mt-2">12 members, 5 active projects</p>
</div>
```

## Handling Virtual Keyboards

Virtual keyboards can take up significant screen space on mobile devices:

1. **Adjust layouts**: Ensure forms remain usable when the keyboard is visible
2. **Scroll to input**: Automatically scroll to the active input field
3. **Minimize form fields**: Keep forms as simple as possible
4. **Use appropriate input types**: Use `type="email"`, `type="tel"`, etc. to show the appropriate keyboard

```php
<form wire:submit="saveProfile" class="space-y-4 pb-20">
    <x-flux::input-group label="Name" wire:model="name" />
    <x-flux::input-group label="Email" wire:model="email" type="email" />
    <x-flux::input-group label="Phone" wire:model="phone" type="tel" />
    
    <!-- Fixed position button that stays visible above the keyboard -->
    <div class="fixed bottom-0 left-0 right-0 bg-white p-4 border-t">
        <x-flux::button type="submit" class="w-full">Save Profile</x-flux::button>
    </div>
</form>
```

## Touch-Friendly UI Components

### Dropdown Menus

Make dropdown menus touch-friendly:

```php
<div x-data="{ open: false }" class="relative">
    <button @click="open = !open" class="px-4 py-2 bg-white border rounded flex items-center justify-between min-w-[200px] min-h-[44px]">
        <span>Select a role</span>
        <x-flux::icon name="chevron-down" class="h-5 w-5" />
    </button>
    
    <div x-show="open" 
         @click.away="open = false"
         class="absolute left-0 mt-1 w-full bg-white border rounded shadow-lg z-10">
        <div class="py-1">
            <button @click="open = false" class="block w-full text-left px-4 py-3 text-sm hover:bg-gray-100">
                Admin
            </button>
            <button @click="open = false" class="block w-full text-left px-4 py-3 text-sm hover:bg-gray-100">
                Editor
            </button>
            <button @click="open = false" class="block w-full text-left px-4 py-3 text-sm hover:bg-gray-100">
                Viewer
            </button>
        </div>
    </div>
</div>
```

### Date Pickers

Use touch-optimized date pickers:

```php
<div x-data="{ open: false, date: '' }" class="relative">
    <label for="date" class="block text-sm font-medium text-gray-700">Date</label>
    <input 
        type="text" 
        id="date" 
        x-model="date" 
        @click="open = true" 
        readonly 
        class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm min-h-[44px]"
        placeholder="Select a date">
    
    <!-- Mobile-friendly approach: use native date picker on mobile -->
    <input 
        type="date" 
        x-ref="nativeDatePicker"
        class="hidden"
        @change="date = $event.target.value; open = false">
    
    <!-- Custom date picker for desktop -->
    <div x-show="open" 
         @click.away="open = false"
         class="absolute left-0 mt-1 p-4 bg-white border rounded shadow-lg z-10">
        <!-- Calendar UI here -->
        <div class="mt-4 flex justify-between">
            <button @click="open = false" class="px-3 py-1 border rounded">
                Cancel
            </button>
            <button @click="open = false" class="px-3 py-1 bg-blue-500 text-white rounded">
                Select
            </button>
        </div>
    </div>
</div>

<script>
    // Detect if device is mobile and use native date picker
    document.addEventListener('DOMContentLoaded', function() {
        const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
        
        if (isMobile) {
            Alpine.data('datePicker', () => ({
                open: false,
                date: '',
                
                init() {
                    this.$watch('open', (value) => {
                        if (value) {
                            this.$refs.nativeDatePicker.click();
                            this.open = false;
                        }
                    });
                }
            }));
        }
    });
</script>
```

### Sliders

Make sliders touch-friendly with larger handles:

```php
<div class="space-y-2">
    <label for="slider" class="block text-sm font-medium text-gray-700">
        Permission Level: <span x-text="value"></span>
    </label>
    
    <div x-data="{ value: 50 }" class="relative">
        <input 
            type="range" 
            id="slider" 
            x-model="value" 
            min="0" 
            max="100" 
            class="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer">
        
        <!-- Custom styling for touch-friendly handle -->
        <style>
            input[type=range]::-webkit-slider-thumb {
                -webkit-appearance: none;
                appearance: none;
                width: 24px;
                height: 24px;
                border-radius: 50%;
                background: #4f46e5;
                cursor: pointer;
            }
            
            input[type=range]::-moz-range-thumb {
                width: 24px;
                height: 24px;
                border-radius: 50%;
                background: #4f46e5;
                cursor: pointer;
            }
        </style>
    </div>
</div>
```

## Testing Touch Interactions

To ensure your touch interactions work well:

1. **Test on actual devices**: Emulators don't always accurately represent touch behavior
2. **Test with different finger sizes**: What works for small fingers might not work for larger ones
3. **Test with screen protectors**: Some screen protectors can affect touch sensitivity
4. **Test in different environments**: Bright sunlight, cold weather (with gloves), etc.

## Next Steps

Continue to [Performance Considerations](./050-performance-considerations.md) to learn how to optimize performance for mobile devices.
