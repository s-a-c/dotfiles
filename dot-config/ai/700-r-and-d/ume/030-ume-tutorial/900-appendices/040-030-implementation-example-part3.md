# Implementation Example: User Preferences System (Part 3)

<link rel="stylesheet" href="../assets/css/styles.css">

## 3. MVP Implementation (Continued)

### 3.8 Create Routes for User Preferences

```php
// In routes/web.php
Route::middleware(['auth', 'verified'])->group(function () {
    Route::get('/user/preferences', function () {
        return view('user.preferences');
    })->name('user.preferences');
});
```

### 3.9 Create Blade Layout for User Preferences Page

```blade
{{-- resources/views/user/preferences.blade.php --}}
<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 dark:text-gray-200 leading-tight">
            {{ __('User Preferences') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <livewire:user-preferences-manager />
        </div>
    </div>
</x-app-layout>
```

### 3.10 Apply Preferences in the Application

#### Theme Preference Application

```php
// In app/Http/Middleware/HandleInertiaRequests.php or similar middleware
public function share(Request $request)
{
    return array_merge(parent::share($request), [
        'user' => function () use ($request) {
            if ($request->user()) {
                $user = $request->user();
                return [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'preferences' => [
                        'theme' => $user->preferences()->theme,
                        'language' => $user->preferences()->language,
                    ],
                    // Other user data...
                ];
            }
        },
    ]);
}
```

```blade
{{-- In your app.blade.php or similar layout file --}}
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" 
      x-data="{ theme: '{{ auth()->check() ? auth()->user()->preferences()->theme : 'system' }}' }"
      x-init="
        if (theme === 'system') {
            theme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
        }
        $watch('theme', value => {
            if (value === 'dark') {
                document.documentElement.classList.add('dark');
            } else {
                document.documentElement.classList.remove('dark');
            }
        })
      "
      :class="{ 'dark': theme === 'dark' }">
<head>
    <!-- ... -->
</head>
<body class="font-sans antialiased bg-gray-100 dark:bg-gray-900">
    <!-- ... -->
</body>
</html>
```

#### Language Preference Application

```php
// In app/Http/Middleware/SetUserLocale.php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\App;

class SetUserLocale
{
    public function handle(Request $request, Closure $next)
    {
        if ($request->user()) {
            $locale = $request->user()->preferences()->language;
            App::setLocale($locale);
        }
        
        return $next($request);
    }
}
```

```php
// In app/Http/Kernel.php
protected $middlewareGroups = [
    'web' => [
        // ... other middleware
        \App\Http\Middleware\SetUserLocale::class,
    ],
];
```

#### Beta Feature Access Control

```php
// In a controller or middleware
public function showFeature(Request $request)
{
    $user = $request->user();
    
    if (!in_array('advanced-search', $user->preferences()->enabledBetaFeatures)) {
        return redirect()->route('home')
            ->with('error', 'This feature is in beta. Enable it in your preferences to access it.');
    }
    
    return view('features.advanced-search');
}
```

#### Notification Channel Preferences

```php
// In a notification class
public function via($notifiable)
{
    if (!$notifiable->preferences) {
        return ['mail', 'database']; // Default channels
    }
    
    $channels = [];
    $notificationType = 'system'; // Or 'account', 'team', etc.
    $preferredChannels = $notifiable->preferences()->notificationChannels[$notificationType] ?? [];
    
    if (in_array('email', $preferredChannels)) {
        $channels[] = 'mail';
    }
    
    if (in_array('database', $preferredChannels)) {
        $channels[] = 'database';
    }
    
    if (in_array('sms', $preferredChannels)) {
        $channels[] = 'vonage';
    }
    
    return $channels;
}
```

### 3.11 Write Tests for User Preferences

```php
<?php

namespace Tests\Feature;

use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;

class UserPreferencesTest extends TestCase
{
    use RefreshDatabase;
    
    public function test_user_can_view_preferences_page()
    {
        $user = User::factory()->create();
        
        $response = $this->actingAs($user)
                         ->get(route('user.preferences'));
        
        $response->assertStatus(200);
    }
    
    public function test_user_can_update_preferences()
    {
        $user = User::factory()->create();
        
        $response = $this->actingAs($user)
                         ->post(route('user.preferences.update'), [
                             'theme' => 'dark',
                             'language' => 'fr',
                             'notificationChannels' => [
                                 'account' => ['email'],
                                 'team' => ['email', 'database'],
                                 'system' => ['database'],
                             ],
                             'enabledBetaFeatures' => ['advanced-search'],
                         ]);
        
        $response->assertSessionHasNoErrors();
        
        $preferences = $user->preferences();
        $this->assertEquals('dark', $preferences->theme);
        $this->assertEquals('fr', $preferences->language);
        $this->assertEquals(['email'], $preferences->notificationChannels['account']);
        $this->assertEquals(['advanced-search'], $preferences->enabledBetaFeatures);
    }
    
    public function test_user_can_reset_preferences()
    {
        $user = User::factory()->create();
        
        // First update preferences
        $user->updatePreferences([
            'theme' => 'dark',
            'language' => 'fr',
        ]);
        
        // Then reset them
        $response = $this->actingAs($user)
                         ->post(route('user.preferences.reset'));
        
        $response->assertSessionHasNoErrors();
        
        $preferences = $user->preferences();
        $this->assertEquals('system', $preferences->theme); // Default value
        $this->assertEquals('en', $preferences->language); // Default value
    }
}
```

## 4. Lessons Learned

### 4.1 Technical Insights

- **Settings Management**: Using a dedicated package like `spatie/laravel-settings` provides a clean, type-safe way to manage user preferences.
- **Caching Strategy**: Caching preferences improves performance but requires careful cache invalidation when preferences are updated.
- **UI Considerations**: Preference UI should be intuitive and provide immediate feedback when changes are made.
- **Testing**: Comprehensive tests ensure that preferences are correctly stored, retrieved, and applied.

### 4.2 Implementation Challenges

- **Default Values**: Ensuring sensible defaults for all preferences is crucial for a good user experience.
- **Performance**: Accessing preferences on every request can impact performance if not properly cached.
- **Extensibility**: The system must be designed to easily accommodate new preference types in the future.
- **User Experience**: Balancing comprehensive options with a simple, intuitive interface.

### 4.3 Future Improvements

- **Preference Synchronization**: Sync preferences across devices in real-time using WebSockets.
- **Import/Export**: Allow users to export and import their preferences.
- **Preference Analytics**: Track which preferences are most commonly used to inform UI decisions.
- **Team Preferences**: Extend the system to support team-level preferences that apply to all team members.

## 5. Conclusion

The User Preferences System demonstrates how to implement a flexible, extensible feature that enhances the user experience. By following a structured approach from requirements to implementation, we've created a system that:

1. Provides users with control over their application experience
2. Uses modern Laravel packages and patterns
3. Is performant through effective caching
4. Can be easily extended with new preference types
5. Is thoroughly tested

This implementation serves as a template for approaching other user model enhancements, emphasizing the importance of clear requirements, structured implementation, and comprehensive testing.
