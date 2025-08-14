# Mobile-First Design

<link rel="stylesheet" href="../assets/css/styles.css">

Mobile-first design is an approach that prioritizes designing for mobile devices before designing for desktop or other larger screens. This section covers the principles and implementation of mobile-first design in the context of UME.

## Principles of Mobile-First Design

Mobile-first design is based on several key principles:

1. **Start with the smallest screen** - Design for mobile devices first, then progressively enhance for larger screens
2. **Focus on core content and functionality** - Identify what's most important and ensure it works well on mobile
3. **Progressive enhancement** - Add features and content as screen size increases
4. **Performance optimization** - Optimize for limited resources (bandwidth, CPU, battery)
5. **Touch-friendly interfaces** - Design for touch as the primary input method

## Benefits of Mobile-First Design

Adopting a mobile-first approach offers several benefits:

- **Improved user experience on mobile devices** - Your application will work well on the devices many users prefer
- **Faster loading times** - Mobile-first design encourages performance optimization
- **Better focus on core functionality** - Forces you to prioritize what's most important
- **Future-proof design** - As mobile usage continues to grow, your application will be well-positioned
- **SEO advantages** - Search engines prioritize mobile-friendly websites

## Implementing Mobile-First Design in Laravel

### CSS Approach

When using Tailwind CSS (the default for Laravel 12), mobile-first design is built in. The base styles apply to mobile, and you use breakpoint prefixes to apply styles at larger screen sizes:

```html
<div class="text-sm md:text-base lg:text-lg">
  This text is small on mobile, medium on tablets, and large on desktops.
</div>
```

### Breakpoints

Tailwind CSS v4 (included with Laravel 12) uses these default breakpoints:

- `sm`: 640px and up
- `md`: 768px and up
- `lg`: 1024px and up
- `xl`: 1280px and up
- `2xl`: 1536px and up

### Flux UI Components

When using Flux UI components with Livewire/Volt, many components are already responsive. For example, the `Card` component will automatically adjust its padding based on screen size:

```php
<x-flux::card>
    <x-slot:header>
        <h2 class="text-lg font-medium">User Profile</h2>
    </x-slot:header>
    
    <div class="space-y-4">
        <!-- Content that will automatically adjust based on screen size -->
    </div>
    
    <x-slot:footer>
        <x-flux::button>Save</x-flux::button>
    </x-slot:footer>
</x-flux::card>
```

## Mobile-First Design for UME Features

### User Authentication

For authentication screens (login, registration, password reset), consider:

- Simplified forms with stacked inputs
- Large, touch-friendly buttons
- Clear error messages that don't require hovering
- Minimal distractions

```php
<x-flux::card class="w-full sm:max-w-md">
    <x-slot:header>
        <h2 class="text-lg font-medium">Login</h2>
    </x-slot:header>
    
    <form wire:submit="login" class="space-y-4">
        <x-flux::input-group label="Email" wire:model="email" type="email" required />
        <x-flux::input-group label="Password" wire:model="password" type="password" required />
        
        <div class="flex items-center justify-between">
            <x-flux::checkbox label="Remember me" wire:model="remember" />
            <a href="{{ route('password.request') }}" class="text-sm text-blue-600 hover:underline">
                Forgot password?
            </a>
        </div>
        
        <x-flux::button type="submit" class="w-full">Login</x-flux::button>
    </form>
</x-flux::card>
```

### User Profiles

For user profile screens, consider:

- Collapsible sections for different profile areas
- Prioritize most frequently used information
- Use tabs or accordions for organizing content on small screens
- Ensure form inputs are large enough for touch input

### Team Management

For team management interfaces, consider:

- List views that stack on mobile
- Simplified team creation forms
- Touch-friendly member management
- Collapsible team details

### Admin Interfaces

For admin interfaces (using FilamentPHP), consider:

- Responsive tables that adapt to small screens
- Filters that collapse into a dropdown on mobile
- Actions that move to a menu on small screens
- Simplified dashboard widgets

## Testing Mobile-First Design

To ensure your mobile-first design works well:

1. Use browser developer tools to test different screen sizes
2. Test on actual mobile devices when possible
3. Use responsive design testing tools
4. Get feedback from users on mobile devices

## Next Steps

Continue to [Responsive Design Patterns](./020-responsive-design-patterns.md) to learn about common patterns for creating responsive UI components.
