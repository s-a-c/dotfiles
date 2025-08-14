# Installing Flux UI Components

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Install and configure Flux UI components for Livewire to enhance our user interface with professionally designed, accessible components.

## Prerequisites

- Laravel 12 project with Livewire Starter Kit
- Node.js and npm/yarn

## Implementation

### Step 1: Install Flux UI via Composer

```bash
composer require fluxui/flux
```

For the Pro version (if you have a license):

```bash
composer require fluxui/flux-pro
```

### Step 2: Publish Flux UI assets

```bash
php artisan flux:install
```

This command will:
- Publish the necessary assets
- Add the required CSS and JavaScript to your application
- Configure Tailwind CSS to work with Flux UI

### Step 3: Update your layout file

Open `resources/views/components/layouts/app.blade.php` and add the Flux UI styles and scripts:

```html
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta name="csrf-token" content="{{ csrf_token() }}">

        <title>{{ $title ?? config('app.name') }}</title>

        <!-- Fonts -->
        <link rel="preconnect" href="https://fonts.bunny.net">
        <link href="https://fonts.bunny.net/css?family=figtree:400,500,600&display=swap" rel="stylesheet" />

        <!-- Flux UI Styles -->
        @fluxStyles

        <!-- Scripts -->
        @vite(['resources/css/app.css', 'resources/js/app.js'])
    </head>
    <body class="font-sans antialiased">
        {{ $slot }}

        <!-- Flux UI Scripts -->
        @fluxScripts
    </body>
</html>
```

### Step 4: Update your Tailwind configuration

Open `tailwind.config.js` and ensure it includes the Flux UI plugin:

```javascript
import defaultTheme from 'tailwindcss/defaultTheme';
import forms from '@tailwindcss/forms';
import fluxui from 'fluxui/tailwind';

/** @type {import('tailwindcss').Config} */
export default {
    content: [
        './vendor/100-laravel/framework/src/Illuminate/Pagination/resources/views/*.blade.php',
        './storage/framework/views/*.php',
        './resources/views/**/*.blade.php',
        './resources/js/**/*.js',
        './vendor/fluxui/flux/resources/views/**/*.blade.php',
    ],

    theme: {
        extend: {
            fontFamily: {
                sans: ['Figtree', ...defaultTheme.fontFamily.sans],
            },
        },
    },

    plugins: [forms, fluxui],
};
```

### Step 5: Rebuild your assets

```bash
npm run dev
```

## What This Does

- Installs the Flux UI package, which provides a set of pre-built, accessible UI components for Livewire
- Configures your application to use Flux UI components
- Sets up the necessary styles and scripts

## Verification

1. Run your application with `php artisan serve`
2. Visit your application in the browser
3. Check the browser console for any errors related to Flux UI
4. Create a simple test component to verify Flux UI is working:

```bash
php artisan make:livewire TestFluxComponent
```

Edit the created component at `app/Livewire/TestFluxComponent.php`:

```php
<?php

namespace App\Livewire;

use Livewire\Component;

class TestFluxComponent extends Component
{
    public function render()
    {
        return view('livewire.test-flux-component');
    }
}
```

Edit the view at `resources/views/livewire/test-flux-component.blade.php`:

```html
<div>
    <x-flux-card>
        <x-flux-card-header>
            <h3 class="text-lg font-medium">Flux UI Test</h3>
        </x-flux-card-header>
        <x-flux-card-body>
            <p>This is a test of Flux UI components.</p>
            <x-flux-button>Click Me</x-flux-button>
        </x-flux-card-body>
    </x-flux-card>
</div>
```

Add a route in `routes/web.php`:

```php
Route::get('/test-flux', App\Livewire\TestFluxComponent::class);
```

Visit `/test-flux` in your browser to verify the Flux UI components are rendering correctly.

## Troubleshooting

### Issue: Flux UI components not rendering correctly

**Solution:** Ensure you've published the assets and rebuilt your frontend assets. Check that the Flux UI styles and scripts are properly included in your layout.

### Issue: Tailwind CSS not applying to Flux UI components

**Solution:** Verify your `tailwind.config.js` includes the Flux UI plugin and the content paths include the Flux UI views.

## Next Steps

Now that we have Flux UI components installed and configured, let's explore the [UI Framework Overview](./080-ui-frameworks.md) to understand the different UI approaches we'll be using in this tutorial.
