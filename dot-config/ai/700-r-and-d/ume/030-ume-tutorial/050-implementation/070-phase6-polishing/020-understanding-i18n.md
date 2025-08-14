# Understanding Internationalization (i18n)

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Understand the concepts and implementation of internationalization (i18n) in Laravel applications.

## What is Internationalization?

Internationalization (often abbreviated as "i18n" - "i" + 18 letters + "n") is the process of designing and preparing your application to be usable in different languages and regions. This includes:

1. **Translation**: Converting text from one language to another
2. **Localization**: Adapting content for specific regions (date formats, number formats, currencies)
3. **Right-to-Left (RTL) Support**: Supporting languages that read from right to left
4. **Pluralization**: Handling grammatical number (singular/plural) correctly in different languages

## Why Implement i18n?

- **Reach a Global Audience**: Make your application accessible to users worldwide
- **Legal Requirements**: Some regions require applications to be available in local languages
- **User Experience**: Users prefer applications in their native language
- **Accessibility**: Language options make your application more accessible

## Laravel's i18n Features

Laravel provides a comprehensive set of tools for internationalization:

### 1. Language Files

Laravel uses language files stored in the `resources/lang` directory. Each language has its own subdirectory:

```
resources/lang/
    en/
        messages.php
        validation.php
    es/
        messages.php
        validation.php
    fr/
        messages.php
        validation.php
```

Each file returns an array of translations:

```php
// resources/lang/en/messages.php
return [
    'custom' => 'Welcome to our application',
    'login' => 'Log in',
    'register' => 'Register',
];

// resources/lang/es/messages.php
return [
    'custom' => 'Bienvenido a nuestra aplicación',
    'login' => 'Iniciar sesión',
    'register' => 'Registrarse',
];
```

### 2. JSON Language Files

For simpler applications, you can use JSON language files:

```json
// resources/lang/es.json
{
    "Welcome to our application": "Bienvenido a nuestra aplicación",
    "Log in": "Iniciar sesión",
    "Register": "Registrarse"
}
```

### 3. Translation Functions

Laravel provides several functions for translating text:

```php
// Basic translation
__('messages.custom');

// Translation with parameters
__('messages.greeting', ['name' => 'John']);

// Pluralization
trans_choice('messages.apples', 2);

// Blade directive
@lang('messages.custom')
```

### 4. Locale Configuration

The application locale is configured in `config/app.php`:

```php
'locale' => 'en',
'fallback_locale' => 'en',
```

You can change the locale at runtime:

```php
App::setLocale('es');
```

### 5. Middleware for Locale Detection

Laravel can detect the user's preferred locale using middleware:

```php
namespace App\Http\Middleware;

use Closure;
use Illuminate\Support\Facades\App;

class SetLocale
{
    public function handle($request, Closure $next)
    {
        if ($request->session()->has('locale')) {
            App::setLocale($request->session()->get('locale'));
        }
        
        return $next($request);
    }
}
```

## Spatie Translation Loader

In our UME application, we'll use the `spatie/laravel-translation-loader` package to load translations from the database. This allows:

1. **Dynamic Translations**: Add or modify translations without deploying code
2. **Admin Interface**: Manage translations through a user interface
3. **Caching**: Cache translations for better performance

## Flux UI for Language Switching

We'll implement a language switcher using Flux UI components:

```php
<x-flux-dropdown>
    <x-slot name="trigger">
        <button class="flex items-center">
            <span>{{ __('Language') }}</span>
            <x-flux-icon name="chevron-down" class="ml-1 h-4 w-4" />
        </button>
    </x-slot>
    
    <x-flux-dropdown-item wire:click="setLocale('en')">
        English
    </x-flux-dropdown-item>
    
    <x-flux-dropdown-item wire:click="setLocale('es')">
        Español
    </x-flux-dropdown-item>
    
    <x-flux-dropdown-item wire:click="setLocale('fr')">
        Français
    </x-flux-dropdown-item>
</x-flux-dropdown>
```

## Best Practices for i18n

1. **Extract All Text**: Never hardcode text in your application
2. **Use Translation Keys**: Use descriptive keys that indicate the context
3. **Include Parameters**: Use parameters for dynamic content
4. **Handle Pluralization**: Use `trans_choice` for pluralization
5. **Test with RTL Languages**: Ensure your UI works with right-to-left languages
6. **Consider Cultural Differences**: Be aware of cultural sensitivities
7. **Maintain Translations**: Keep translations up-to-date as your application evolves

## Next Steps

Now that you understand internationalization in Laravel, let's move on to [Implement i18n Backend](./020-implement-i18n-backend.md) to set up translations and localization in our application.
