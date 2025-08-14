# Setting Up Internationalization

<link rel="stylesheet" href="../../../../assets/css/styles.css">

## Goal

Configure your Laravel application to support multiple languages and regional settings.

## Prerequisites

- A working Laravel application from previous phases
- Basic understanding of Laravel's configuration system

## Implementation Steps

### Step 1: Configure Locale Settings

First, let's configure the locale settings in your Laravel application. Open the `config/app.php` file and update the locale settings:

```php
'locale' => env('APP_LOCALE', 'en'),

'fallback_locale' => env('APP_FALLBACK_LOCALE', 'en'),

'available_locales' => [
    'en' => ['name' => 'English', 'native' => 'English', 'direction' => 'ltr'],
    'es' => ['name' => 'Spanish', 'native' => 'Español', 'direction' => 'ltr'],
    'fr' => ['name' => 'French', 'native' => 'Français', 'direction' => 'ltr'],
    'ar' => ['name' => 'Arabic', 'native' => 'العربية', 'direction' => 'rtl'],
],
```

This configuration:
- Sets the default locale to 'en' (English)
- Sets the fallback locale to 'en' (used when a translation is missing in the current locale)
- Defines an array of available locales with their names, native names, and text direction

### Step 2: Create Language Files

Next, create language files for each supported language. Laravel uses language files to store translations.

#### Create Directory Structure

```bash
mkdir -p resources/lang/en
mkdir -p resources/lang/es
mkdir -p resources/lang/fr
mkdir -p resources/lang/ar
```

#### Create Language Files

Create a file for general messages in each language:

**resources/lang/en/messages.php**:
```php
<?php

return [
    'custom' => 'Welcome to our application',
    'login' => 'Log in',
    'register' => 'Register',
    'logout' => 'Log out',
    'profile' => 'Profile',
    'settings' => 'Settings',
    'dashboard' => 'Dashboard',
    'teams' => 'Teams',
    'users' => 'Users',
    'roles' => 'Roles',
    'permissions' => 'Permissions',
];
```

**resources/lang/es/messages.php**:
```php
<?php

return [
    'custom' => 'Bienvenido a nuestra aplicación',
    'login' => 'Iniciar sesión',
    'register' => 'Registrarse',
    'logout' => 'Cerrar sesión',
    'profile' => 'Perfil',
    'settings' => 'Configuración',
    'dashboard' => 'Tablero',
    'teams' => 'Equipos',
    'users' => 'Usuarios',
    'roles' => 'Roles',
    'permissions' => 'Permisos',
];
```

Create similar files for other languages (fr, ar).

### Step 3: Install Translation Loader Package (Optional)

For more advanced translation management, you can use the `spatie/laravel-translation-loader` package, which allows you to store translations in the database:

```bash
composer require spatie/100-laravel-translation-loader
```

Publish the configuration and migrations:

```bash
php artisan vendor:publish --provider="Spatie\TranslationLoader\TranslationServiceProvider"
```

Run the migrations:

```bash
php artisan migrate
```

Update the configuration in `config/translation-loader.php` to specify which translation drivers to use:

```php
'driver' => 'db',
```

### Step 4: Create a Locale Middleware

Create a middleware to set the application locale based on user preferences, session, or URL parameters:

```bash
php artisan make:middleware SetLocale
```

Edit the middleware:

```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\App;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Session;

class SetLocale
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure  $next
     * @return mixed
     */
    public function handle(Request $request, Closure $next)
    {
        // Priority 1: URL parameter
        if ($request->has('locale') && array_key_exists($request->locale, config('app.available_locales'))) {
            $locale = $request->locale;
            Session::put('locale', $locale);
            
            // Update user preference if authenticated
            if (Auth::check()) {
                Auth::user()->update(['locale' => $locale]);
            }
        }
        // Priority 2: User preference
        elseif (Auth::check() && Auth::user()->locale) {
            $locale = Auth::user()->locale;
        }
        // Priority 3: Session
        elseif (Session::has('locale')) {
            $locale = Session::get('locale');
        }
        // Priority 4: Browser preference
        elseif ($request->header('Accept-Language')) {
            $browserLocale = substr($request->header('Accept-Language'), 0, 2);
            if (array_key_exists($browserLocale, config('app.available_locales'))) {
                $locale = $browserLocale;
            }
        }
        
        // Default to app.locale if no locale has been determined
        if (!isset($locale)) {
            $locale = config('app.locale');
        }
        
        // Set the application locale
        App::setLocale($locale);
        
        return $next($request);
    }
}
```

### Step 5: Register the Middleware

Register the middleware in `app/Http/Kernel.php`:

```php
protected $middlewareGroups = [
    'web' => [
        // ... other middleware
        \App\Http\Middleware\SetLocale::class,
    ],
];
```

### Step 6: Add Locale Field to User Model

Add a `locale` field to your User model to store user language preferences:

```bash
php artisan make:migration add_locale_to_users_table --table=users
```

Edit the migration:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('locale')->nullable()->after('email');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('locale');
        });
    }
};
```

Run the migration:

```bash
php artisan migrate
```

Update the User model to make the `locale` field fillable:

```php
protected $fillable = [
    'name',
    'email',
    'password',
    'locale',
];
```

### Step 7: Create a Language Switcher Component

Create a Livewire component for switching languages:

```bash
php artisan make:livewire LanguageSwitcher
```

Edit the component class:

```php
<?php

namespace App\Http\Livewire;

use Illuminate\Support\Facades\App;
use Illuminate\Support\Facades\Session;
use Livewire\Component;

class LanguageSwitcher extends Component
{
    public function setLocale($locale)
    {
        if (array_key_exists($locale, config('app.available_locales'))) {
            Session::put('locale', $locale);
            App::setLocale($locale);
            
            // Update user preference if authenticated
            if (auth()->check()) {
                auth()->user()->update(['locale' => $locale]);
            }
            
            $this->emit('localeChanged');
        }
    }
    
    public function render()
    {
        return view('livewire.language-switcher', [
            'currentLocale' => App::getLocale(),
            'availableLocales' => config('app.available_locales'),
        ]);
    }
}
```

Create the component view:

```php
<!-- resources/views/livewire/language-switcher.blade.php -->
<div>
    <x-flux-dropdown>
        <x-slot name="trigger">
            <button class="flex items-center">
                <span>{{ $availableLocales[$currentLocale]['native'] }}</span>
                <x-flux-icon name="chevron-down" class="ml-1 h-4 w-4" />
            </button>
        </x-slot>
        
        @foreach($availableLocales as $locale => $properties)
            <x-flux-dropdown-item wire:click="setLocale('{{ $locale }}')" :active="$currentLocale === $locale">
                {{ $properties['native'] }}
            </x-flux-dropdown-item>
        @endforeach
    </x-flux-dropdown>
</div>
```

### Step 8: Use the Language Switcher Component

Add the language switcher component to your layout:

```php
<!-- In your layout file -->
<div class="flex items-center">
    @livewire('language-switcher')
</div>
```

### Step 9: Use Translations in Your Views

Now you can use translations in your views using the `__()` helper function:

```php
<h1>{{ __('messages.custom') }}</h1>
<a href="{{ route('login') }}">{{ __('messages.login') }}</a>
<a href="{{ route('register') }}">{{ __('messages.register') }}</a>
```

For Blade components:

```php
<x-flux-button>
    {{ __('messages.login') }}
</x-flux-button>
```

For Livewire components:

```php
<button wire:click="login">
    {{ __('messages.login') }}
</button>
```

## Verification

To verify that internationalization is set up correctly:

1. Visit your application and check that the default language is displayed
2. Use the language switcher to change the language
3. Verify that the text changes to the selected language
4. Check that the language preference is saved when you log in

## Troubleshooting

### Missing Translations

If translations are not showing up:

1. Check that the language files exist in the correct location
2. Verify that the translation keys match exactly
3. Ensure that the locale is being set correctly
4. Check for typos in translation keys

### Locale Not Being Set

If the locale is not being set correctly:

1. Check that the middleware is registered in the correct middleware group
2. Verify that the locale is being stored in the session
3. Check that the user's locale preference is being saved
4. Ensure that the available locales are configured correctly

## Next Steps

Now that you have set up internationalization in your Laravel application, let's move on to [Translation Management](./020-translation-management.md) to learn how to manage translations effectively.
