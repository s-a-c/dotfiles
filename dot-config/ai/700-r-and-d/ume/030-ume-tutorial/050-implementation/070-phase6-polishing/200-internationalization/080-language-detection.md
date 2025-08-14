# Language Detection

<link rel="stylesheet" href="../../../../assets/css/styles.css">

## Goal

Learn how to detect the user's preferred language in your UME application, ensuring that users see content in their preferred language without having to manually select it.

## Prerequisites

- Completed the [Setting Up Internationalization](./010-setting-up-i18n.md) guide
- Basic understanding of HTTP headers and browser language preferences
- Basic understanding of Laravel's middleware system

## Understanding Language Detection

Users can indicate their language preferences in several ways:

1. **Browser Settings**: Browsers send the `Accept-Language` header with HTTP requests, indicating the user's preferred languages
2. **User Account Settings**: Users can set their preferred language in their account settings
3. **URL Parameters**: Users can specify a language in the URL (e.g., `?lang=fr`)
4. **Cookies or Session**: The application can store the user's language preference in a cookie or session
5. **Geolocation**: The application can detect the user's location and infer their language preference

A good language detection system should consider all these sources, with a clear order of precedence.

## Implementation Steps

### Step 1: Create a Language Detection Middleware

Create a middleware to detect and set the user's preferred language:

```bash
php artisan make:middleware DetectLanguage
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
use Illuminate\Support\Str;

class DetectLanguage
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
        // Get available locales from config
        $availableLocales = array_keys(config('app.available_locales', ['en' => []]));
        
        // Priority 1: URL parameter
        if ($request->has('lang') && in_array($request->lang, $availableLocales)) {
            $locale = $request->lang;
            Session::put('locale', $locale);
            
            // Update user preference if authenticated
            if (Auth::check()) {
                Auth::user()->update(['locale' => $locale]);
            }
        }
        // Priority 2: User preference
        elseif (Auth::check() && Auth::user()->locale && in_array(Auth::user()->locale, $availableLocales)) {
            $locale = Auth::user()->locale;
        }
        // Priority 3: Session
        elseif (Session::has('locale') && in_array(Session::get('locale'), $availableLocales)) {
            $locale = Session::get('locale');
        }
        // Priority 4: Cookie
        elseif ($request->cookie('locale') && in_array($request->cookie('locale'), $availableLocales)) {
            $locale = $request->cookie('locale');
        }
        // Priority 5: Browser preference
        elseif ($request->header('Accept-Language')) {
            $locale = $this->getBrowserLocale($request->header('Accept-Language'), $availableLocales);
        }
        
        // Default to app.locale if no locale has been determined
        if (!isset($locale)) {
            $locale = config('app.locale');
        }
        
        // Set the application locale
        App::setLocale($locale);
        
        return $next($request);
    }
    
    /**
     * Get the browser locale from the Accept-Language header.
     *
     * @param  string  $acceptLanguage
     * @param  array  $availableLocales
     * @return string|null
     */
    protected function getBrowserLocale($acceptLanguage, $availableLocales)
    {
        // Parse the Accept-Language header
        $browserLocales = [];
        
        // Example: en-US,en;q=0.9,fr;q=0.8,de;q=0.7
        $parts = explode(',', $acceptLanguage);
        
        foreach ($parts as $part) {
            $subParts = explode(';', $part);
            $locale = $subParts[0];
            $quality = 1.0;
            
            if (isset($subParts[1])) {
                $qValue = explode('=', $subParts[1]);
                if (isset($qValue[1])) {
                    $quality = floatval($qValue[1]);
                }
            }
            
            $browserLocales[$locale] = $quality;
        }
        
        // Sort by quality
        arsort($browserLocales);
        
        // Find the first matching locale
        foreach ($browserLocales as $browserLocale => $quality) {
            // Exact match
            if (in_array($browserLocale, $availableLocales)) {
                return $browserLocale;
            }
            
            // Match language code (e.g., 'en-US' matches 'en')
            $languageCode = Str::before($browserLocale, '-');
            if (in_array($languageCode, $availableLocales)) {
                return $languageCode;
            }
            
            // Match any locale with the same language code
            foreach ($availableLocales as $availableLocale) {
                if (Str::startsWith($availableLocale, $languageCode . '-')) {
                    return $availableLocale;
                }
            }
        }
        
        return null;
    }
}
```

### Step 2: Register the Middleware

Register the middleware in `app/Http/Kernel.php`:

```php
protected $middlewareGroups = [
    'web' => [
        // ... other middleware
        \App\Http\Middleware\DetectLanguage::class,
    ],
];
```

### Step 3: Create a Language Switcher Component

Create a Livewire component for switching languages:

```bash
php artisan make:livewire LanguageSwitcher
```

Edit the component class:

```php
<?php

namespace App\Http\Livewire;

use Illuminate\Support\Facades\App;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cookie;
use Illuminate\Support\Facades\Session;
use Livewire\Component;

class LanguageSwitcher extends Component
{
    public function setLocale($locale)
    {
        if (array_key_exists($locale, config('app.available_locales', []))) {
            // Set session
            Session::put('locale', $locale);
            
            // Set cookie (1 year expiration)
            Cookie::queue('locale', $locale, 60 * 24 * 365);
            
            // Update user preference if authenticated
            if (Auth::check()) {
                Auth::user()->update(['locale' => $locale]);
            }
            
            // Set application locale
            App::setLocale($locale);
            
            // Emit event for other components
            $this->emit('localeChanged');
            
            // Refresh the page to apply the new locale
            return redirect(request()->header('Referer'));
        }
    }
    
    public function render()
    {
        return view('livewire.language-switcher', [
            'currentLocale' => App::getLocale(),
            'availableLocales' => config('app.available_locales', []),
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

### Step 4: Add the Language Switcher to Your Layout

Add the language switcher component to your layout:

```php
<!-- In your layout file -->
<div class="flex items-center">
    @livewire('language-switcher')
</div>
```

### Step 5: Create a Language Preference Setting in User Profile

Add a language preference setting to the user profile page:

```php
<!-- resources/views/profile/edit.blade.php -->
<div class="mt-10 sm:mt-0">
    <div class="md:grid md:grid-cols-3 md:gap-6">
        <div class="md:col-span-1">
            <div class="px-4 sm:px-0">
                <h3 class="text-lg font-medium leading-6 text-gray-900">{{ __('Language Preferences') }}</h3>
                <p class="mt-1 text-sm text-gray-600">
                    {{ __('Select your preferred language for the application.') }}
                </p>
            </div>
        </div>
        <div class="mt-5 md:col-span-2 md:mt-0">
            <form action="{{ route('profile.update-language') }}" method="POST">
                @csrf
                @method('PUT')
                
                <div class="overflow-hidden shadow sm:rounded-md">
                    <div class="bg-white px-4 py-5 sm:p-6">
                        <div class="grid grid-cols-6 gap-6">
                            <div class="col-span-6 sm:col-span-3">
                                <label for="locale" class="block text-sm font-medium text-gray-700">{{ __('Language') }}</label>
                                <select id="locale" name="locale" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm">
                                    @foreach(config('app.available_locales', []) as $locale => $properties)
                                        <option value="{{ $locale }}" {{ Auth::user()->locale === $locale ? 'selected' : '' }}>
                                            {{ $properties['name'] }} ({{ $properties['native'] }})
                                        </option>
                                    @endforeach
                                </select>
                            </div>
                        </div>
                    </div>
                    <div class="bg-gray-50 px-4 py-3 text-right sm:px-6">
                        <button type="submit" class="inline-flex justify-center rounded-md border border-transparent bg-indigo-600 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2">
                            {{ __('Save') }}
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>
</div>
```

Create a controller method to handle the language preference update:

```php
// app/Http/Controllers/ProfileController.php
public function updateLanguage(Request $request)
{
    $validated = $request->validate([
        'locale' => 'required|string|in:' . implode(',', array_keys(config('app.available_locales', []))),
    ]);
    
    $request->user()->update([
        'locale' => $validated['locale'],
    ]);
    
    // Set session and cookie
    Session::put('locale', $validated['locale']);
    Cookie::queue('locale', $validated['locale'], 60 * 24 * 365);
    
    return redirect()->route('profile.edit')
        ->with('status', 'language-updated');
}
```

Add the route:

```php
// routes/web.php
Route::middleware(['auth'])->group(function () {
    // ... other routes
    Route::put('/profile/language', [ProfileController::class, 'updateLanguage'])->name('profile.update-language');
});
```

### Step 6: Add Language Detection to API Routes

For API routes, you can detect the language from the `Accept-Language` header:

```php
// app/Http/Middleware/DetectApiLanguage.php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\App;
use Illuminate\Support\Str;

class DetectApiLanguage
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
        // Get available locales from config
        $availableLocales = array_keys(config('app.available_locales', ['en' => []]));
        
        // Priority 1: Header parameter
        if ($request->header('X-Language') && in_array($request->header('X-Language'), $availableLocales)) {
            $locale = $request->header('X-Language');
        }
        // Priority 2: Accept-Language header
        elseif ($request->header('Accept-Language')) {
            $locale = $this->getBrowserLocale($request->header('Accept-Language'), $availableLocales);
        }
        
        // Default to app.locale if no locale has been determined
        if (!isset($locale)) {
            $locale = config('app.locale');
        }
        
        // Set the application locale
        App::setLocale($locale);
        
        return $next($request);
    }
    
    /**
     * Get the browser locale from the Accept-Language header.
     *
     * @param  string  $acceptLanguage
     * @param  array  $availableLocales
     * @return string|null
     */
    protected function getBrowserLocale($acceptLanguage, $availableLocales)
    {
        // Parse the Accept-Language header
        $browserLocales = [];
        
        // Example: en-US,en;q=0.9,fr;q=0.8,de;q=0.7
        $parts = explode(',', $acceptLanguage);
        
        foreach ($parts as $part) {
            $subParts = explode(';', $part);
            $locale = $subParts[0];
            $quality = 1.0;
            
            if (isset($subParts[1])) {
                $qValue = explode('=', $subParts[1]);
                if (isset($qValue[1])) {
                    $quality = floatval($qValue[1]);
                }
            }
            
            $browserLocales[$locale] = $quality;
        }
        
        // Sort by quality
        arsort($browserLocales);
        
        // Find the first matching locale
        foreach ($browserLocales as $browserLocale => $quality) {
            // Exact match
            if (in_array($browserLocale, $availableLocales)) {
                return $browserLocale;
            }
            
            // Match language code (e.g., 'en-US' matches 'en')
            $languageCode = Str::before($browserLocale, '-');
            if (in_array($languageCode, $availableLocales)) {
                return $languageCode;
            }
            
            // Match any locale with the same language code
            foreach ($availableLocales as $availableLocale) {
                if (Str::startsWith($availableLocale, $languageCode . '-')) {
                    return $availableLocale;
                }
            }
        }
        
        return null;
    }
}
```

Register the middleware in `app/Http/Kernel.php`:

```php
protected $middlewareGroups = [
    'api' => [
        // ... other middleware
        \App\Http\Middleware\DetectApiLanguage::class,
    ],
];
```

### Step 7: Add Language Detection to JavaScript

For client-side language detection, you can use JavaScript:

```javascript
// resources/js/language-detection.js
export function detectLanguage() {
    // Priority 1: URL parameter
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.has('lang')) {
        return urlParams.get('lang');
    }
    
    // Priority 2: localStorage
    if (localStorage.getItem('locale')) {
        return localStorage.getItem('locale');
    }
    
    // Priority 3: Browser language
    return navigator.language || navigator.userLanguage || 'en';
}

export function setLanguage(locale) {
    // Store in localStorage
    localStorage.setItem('locale', locale);
    
    // Reload the page with the new locale
    window.location.href = `${window.location.pathname}?lang=${locale}`;
}
```

Use the language detection in your JavaScript application:

```javascript
// resources/js/app.js
import { detectLanguage, setLanguage } from './language-detection';

// Set the detected language
const locale = detectLanguage();
document.documentElement.lang = locale;

// Make the setLanguage function available globally
window.setLanguage = setLanguage;
```

## Best Practices for Language Detection

1. **Consider Multiple Sources**: Consider multiple sources for language preferences (URL, user settings, browser, etc.)
2. **Establish Clear Precedence**: Establish a clear order of precedence for language sources
3. **Respect User Choices**: Always respect the user's explicit language choice
4. **Store Preferences**: Store language preferences in the user's account, session, or cookies
5. **Support Language Variants**: Support language variants (e.g., 'en-US', 'en-GB') and fall back to the base language if needed
6. **Provide a Language Switcher**: Always provide a way for users to manually switch languages
7. **Consider Geolocation**: Consider using geolocation to infer the user's language preference
8. **Test with Different Browsers**: Test language detection with different browsers and language settings

## Verification

To verify that language detection is working correctly:

1. Test with different browser language settings
2. Test with URL parameters (e.g., `?lang=fr`)
3. Test with user account settings
4. Test with cookies and session
5. Test with API requests and the `Accept-Language` header

## Troubleshooting

### Language Not Being Detected

If the user's language is not being detected correctly:

1. Check that the middleware is registered in the correct middleware group
2. Verify that the `Accept-Language` header is being parsed correctly
3. Check that the available locales are configured correctly
4. Test with different browsers and language settings

### Language Preference Not Being Saved

If the user's language preference is not being saved:

1. Check that the user model has a `locale` field
2. Verify that the language preference is being stored in the session and cookies
3. Check that the language switcher is working correctly
4. Test with different browsers and language settings

## Next Steps

Now that you've learned how to detect the user's preferred language, let's move on to [Cultural Considerations](./090-cultural-considerations.md) to learn about cultural differences that can affect your application.
