# Mobile Responsiveness Exercises - Sample Answers

<link rel="stylesheet" href="../assets/css/styles.css">

This document provides sample answers to the exercises in the [Mobile Responsiveness Exercises](../060-exercises/050-mobile-responsiveness-exercises.md) section.

## Exercise 1: Mobile-First Design

### Multiple Choice Answers

1. What is the primary principle of mobile-first design?
   - **B) Design for mobile first, then progressively enhance for larger screens**

2. In Tailwind CSS, which of the following correctly applies a style only on medium screens and larger?
   - **C) `class="md:text-lg"`**

3. What is the main benefit of mobile-first design?
   - **B) It forces you to prioritize content and functionality**

### Practical Exercise Solution

Here's a sample implementation of a mobile-first navigation component:

```php
<!-- resources/views/components/responsive-navigation.blade.php -->
<nav x-data="{ open: false }" class="bg-white shadow">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
            <div class="flex">
                <div class="flex-shrink-0 flex items-center">
                    <!-- Logo -->
                    <img class="h-8 w-auto" src="/logo.svg" alt="Logo">
                </div>
                
                <!-- Desktop navigation (hidden on mobile) -->
                <div class="hidden sm:ml-6 sm:flex sm:space-x-8">
                    <a href="{{ route('dashboard') }}" class="{{ request()->routeIs('dashboard') ? 'border-indigo-500 text-gray-900' : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700' }} inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                        Dashboard
                    </a>
                    <a href="{{ route('teams.index') }}" class="{{ request()->routeIs('teams.*') ? 'border-indigo-500 text-gray-900' : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700' }} inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                        Teams
                    </a>
                    <a href="{{ route('profile.show') }}" class="{{ request()->routeIs('profile.*') ? 'border-indigo-500 text-gray-900' : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700' }} inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                        Profile
                    </a>
                    <a href="{{ route('settings') }}" class="{{ request()->routeIs('settings') ? 'border-indigo-500 text-gray-900' : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700' }} inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                        Settings
                    </a>
                </div>
            </div>
            
            <!-- Mobile menu button (hidden on desktop) -->
            <div class="flex items-center sm:hidden">
                <button @click="open = !open" class="inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-indigo-500" aria-expanded="false" :aria-expanded="open.toString()">
                    <span class="sr-only">Open main menu</span>
                    <!-- Icon when menu is closed -->
                    <svg x-show="!open" class="h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                    </svg>
                    <!-- Icon when menu is open -->
                    <svg x-show="open" class="h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </div>
        </div>
    </div>
    
    <!-- Mobile menu (hidden on desktop) -->
    <div x-show="open" class="sm:hidden" id="mobile-menu">
        <div class="pt-2 pb-3 space-y-1">
            <a href="{{ route('dashboard') }}" class="{{ request()->routeIs('dashboard') ? 'bg-indigo-50 border-indigo-500 text-indigo-700' : 'border-transparent text-gray-500 hover:bg-gray-50 hover:border-gray-300 hover:text-gray-700' }} block pl-3 pr-4 py-2 border-l-4 text-base font-medium">
                Dashboard
            </a>
            <a href="{{ route('teams.index') }}" class="{{ request()->routeIs('teams.*') ? 'bg-indigo-50 border-indigo-500 text-indigo-700' : 'border-transparent text-gray-500 hover:bg-gray-50 hover:border-gray-300 hover:text-gray-700' }} block pl-3 pr-4 py-2 border-l-4 text-base font-medium">
                Teams
            </a>
            <a href="{{ route('profile.show') }}" class="{{ request()->routeIs('profile.*') ? 'bg-indigo-50 border-indigo-500 text-indigo-700' : 'border-transparent text-gray-500 hover:bg-gray-50 hover:border-gray-300 hover:text-gray-700' }} block pl-3 pr-4 py-2 border-l-4 text-base font-medium">
                Profile
            </a>
            <a href="{{ route('settings') }}" class="{{ request()->routeIs('settings') ? 'bg-indigo-50 border-indigo-500 text-indigo-700' : 'border-transparent text-gray-500 hover:bg-gray-50 hover:border-gray-300 hover:text-gray-700' }} block pl-3 pr-4 py-2 border-l-4 text-base font-medium">
                Settings
            </a>
        </div>
    </div>
</nav>
```

This navigation component follows mobile-first principles:

1. It starts with a mobile design (hamburger menu)
2. It progressively enhances for larger screens using Tailwind's `sm:` prefix
3. It's accessible with proper ARIA attributes and keyboard navigation
4. It includes links to Dashboard, Teams, Profile, and Settings

## Exercise 2: Responsive Design Patterns

### Multiple Choice Answers

1. Which responsive design pattern starts with a multi-column layout and drops columns as the screen width narrows?
   - **B) Column Drop**

2. The Off Canvas pattern is most useful for:
   - **B) Navigation menus on mobile**

3. Which CSS property is most useful for changing the order of elements at different screen sizes?
   - **C) `order`**
