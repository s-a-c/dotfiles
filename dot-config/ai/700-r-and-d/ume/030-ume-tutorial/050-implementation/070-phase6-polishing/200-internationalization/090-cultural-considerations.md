# Cultural Considerations

<link rel="stylesheet" href="../../../../assets/css/styles.css">

## Goal

Learn about cultural differences that can affect your UME application and how to adapt your application to different cultures.

## Prerequisites

- Completed the [Setting Up Internationalization](./010-setting-up-i18n.md) guide
- Basic understanding of cultural differences
- Basic understanding of internationalization concepts

## Understanding Cultural Differences

Cultural differences can affect many aspects of your application, including:

- **Language**: Different languages have different grammar, vocabulary, and writing systems
- **Date and Time**: Different cultures format dates and times differently
- **Numbers and Currency**: Different cultures format numbers and currencies differently
- **Names and Addresses**: Different cultures format names and addresses differently
- **Colors and Symbols**: Colors and symbols can have different meanings in different cultures
- **Images and Icons**: Images and icons can be interpreted differently in different cultures
- **Content and Tone**: Content and tone can be perceived differently in different cultures
- **Legal and Regulatory Requirements**: Different regions have different legal and regulatory requirements

## Implementation Steps

### Step 1: Adapt Your Application for Different Writing Systems

Different languages use different writing systems, which can affect your application's layout and design:

#### Left-to-Right (LTR) vs. Right-to-Left (RTL) Languages

As covered in [RTL Language Support](./040-rtl-language-support.md), languages like Arabic, Hebrew, and Persian are written from right to left. Make sure your application supports RTL layout:

```html
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" 
      dir="{{ config('app.available_locales.' . app()->getLocale() . '.direction', 'ltr') }}">
<head>
    <!-- ... -->
</head>
<body>
    <!-- ... -->
</body>
</html>
```

#### Vertical Writing Systems

Some languages, like traditional Japanese and Chinese, can be written vertically. While most web applications don't need to support vertical text, be aware of this possibility:

```css
.vertical-text {
    writing-mode: vertical-rl;
    text-orientation: mixed;
}
```

#### Character Encoding

Make sure your application uses UTF-8 encoding to support all languages:

```html
<meta charset="UTF-8">
```

### Step 2: Adapt Your Application for Different Name Formats

Different cultures format names differently:

#### Name Order

In Western cultures, the given name comes before the family name (e.g., "John Smith"), while in many Asian cultures, the family name comes first (e.g., "Zhang Wei").

Create a flexible name display function:

```php
// app/Helpers/NameHelper.php
<?php

namespace App\Helpers;

use Illuminate\Support\Facades\App;

class NameHelper
{
    /**
     * Format a name according to the current locale.
     *
     * @param  string  $firstName
     * @param  string  $lastName
     * @param  string|null  $middleName
     * @param  string|null  $locale
     * @return string
     */
    public static function formatName($firstName, $lastName, $middleName = null, $locale = null)
    {
        $locale = $locale ?? App::getLocale();
        
        // Cultures where family name comes first
        $familyNameFirstLocales = ['zh', 'zh-CN', 'zh-TW', 'ja', 'ko', 'hu', 'vi'];
        
        if (in_array($locale, $familyNameFirstLocales)) {
            return $middleName
                ? "{$lastName} {$middleName} {$firstName}"
                : "{$lastName} {$firstName}";
        }
        
        // Western cultures (given name first)
        return $middleName
            ? "{$firstName} {$middleName} {$lastName}"
            : "{$firstName} {$lastName}";
    }
    
    /**
     * Format a name for sorting according to the current locale.
     *
     * @param  string  $firstName
     * @param  string  $lastName
     * @param  string|null  $locale
     * @return string
     */
    public static function formatNameForSorting($firstName, $lastName, $locale = null)
    {
        $locale = $locale ?? App::getLocale();
        
        // In most cultures, sort by last name, then first name
        return "{$lastName}, {$firstName}";
    }
}
```

Use the name formatting function in your views:

```php
<div class="mt-2 text-sm text-gray-500">
    {{ App\Helpers\NameHelper::formatName($user->first_name, $user->last_name, $user->middle_name) }}
</div>
```

#### Name Components

Different cultures have different name components. For example, some cultures use patronymics, matronymics, or multiple family names.

Create a flexible user profile form:

```php
<!-- resources/views/profile/edit.blade.php -->
<div class="mt-10 sm:mt-0">
    <div class="md:grid md:grid-cols-3 md:gap-6">
        <div class="md:col-span-1">
            <div class="px-4 sm:px-0">
                <h3 class="text-lg font-medium leading-6 text-gray-900">{{ __('Personal Information') }}</h3>
                <p class="mt-1 text-sm text-gray-600">
                    {{ __('Update your personal information.') }}
                </p>
            </div>
        </div>
        <div class="mt-5 md:col-span-2 md:mt-0">
            <form action="{{ route('profile.update') }}" method="POST">
                @csrf
                @method('PUT')
                
                <div class="overflow-hidden shadow sm:rounded-md">
                    <div class="bg-white px-4 py-5 sm:p-6">
                        <div class="grid grid-cols-6 gap-6">
                            <div class="col-span-6 sm:col-span-2">
                                <label for="first_name" class="block text-sm font-medium text-gray-700">{{ __('First Name') }}</label>
                                <input type="text" name="first_name" id="first_name" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" value="{{ old('first_name', $user->first_name) }}">
                            </div>
                            
                            <div class="col-span-6 sm:col-span-2">
                                <label for="middle_name" class="block text-sm font-medium text-gray-700">{{ __('Middle Name') }}</label>
                                <input type="text" name="middle_name" id="middle_name" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" value="{{ old('middle_name', $user->middle_name) }}">
                            </div>
                            
                            <div class="col-span-6 sm:col-span-2">
                                <label for="last_name" class="block text-sm font-medium text-gray-700">{{ __('Last Name') }}</label>
                                <input type="text" name="last_name" id="last_name" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" value="{{ old('last_name', $user->last_name) }}">
                            </div>
                            
                            <div class="col-span-6">
                                <label for="name_suffix" class="block text-sm font-medium text-gray-700">{{ __('Name Suffix') }}</label>
                                <input type="text" name="name_suffix" id="name_suffix" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" value="{{ old('name_suffix', $user->name_suffix) }}" placeholder="{{ __('e.g., Jr., Sr., III') }}">
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

### Step 3: Adapt Your Application for Different Address Formats

Different cultures format addresses differently:

#### Address Order

Create a flexible address display function:

```php
// app/Helpers/AddressHelper.php
<?php

namespace App\Helpers;

use Illuminate\Support\Facades\App;

class AddressHelper
{
    /**
     * Format an address according to the current locale.
     *
     * @param  array  $address
     * @param  string|null  $locale
     * @return string
     */
    public static function formatAddress($address, $locale = null)
    {
        $locale = $locale ?? App::getLocale();
        
        // Get the country-specific format
        $format = self::getAddressFormat($address['country'] ?? null, $locale);
        
        // Replace placeholders with actual values
        foreach ($address as $key => $value) {
            $format = str_replace("{{$key}}", $value, $format);
        }
        
        // Remove empty lines
        $format = preg_replace('/^\s*\n/m', '', $format);
        
        return $format;
    }
    
    /**
     * Get the address format for a country.
     *
     * @param  string|null  $country
     * @param  string  $locale
     * @return string
     */
    protected static function getAddressFormat($country, $locale)
    {
        // Default format (US)
        $defaultFormat = "{name}\n{street}\n{city}, {state} {postal_code}\n{country}";
        
        // Country-specific formats
        $formats = [
            'US' => "{name}\n{street}\n{city}, {state} {postal_code}\n{country}",
            'CA' => "{name}\n{street}\n{city}, {province} {postal_code}\n{country}",
            'GB' => "{name}\n{street}\n{city}\n{county}\n{postal_code}\n{country}",
            'AU' => "{name}\n{street}\n{city} {state} {postal_code}\n{country}",
            'JP' => "{country}\n{postal_code}\n{prefecture}{city}\n{street}\n{name}",
            'CN' => "{country}\n{province}{city}{district}\n{street}\n{name}",
            'FR' => "{name}\n{street}\n{postal_code} {city}\n{country}",
            'DE' => "{name}\n{street}\n{postal_code} {city}\n{country}",
            'IT' => "{name}\n{street}\n{postal_code} {city} {province}\n{country}",
            'ES' => "{name}\n{street}\n{postal_code} {city} {province}\n{country}",
        ];
        
        return $formats[$country] ?? $defaultFormat;
    }
}
```

Use the address formatting function in your views:

```php
<div class="mt-2 text-sm text-gray-500">
    {!! nl2br(e(App\Helpers\AddressHelper::formatAddress([
        'name' => $user->name,
        'street' => $user->address->street,
        'city' => $user->address->city,
        'state' => $user->address->state,
        'postal_code' => $user->address->postal_code,
        'country' => $user->address->country,
    ]))) !!}
</div>
```

### Step 4: Adapt Your Application for Different Cultural Sensitivities

Different cultures have different sensitivities regarding content, images, and symbols:

#### Content Guidelines

Create content guidelines for different cultures:

```php
// config/content-guidelines.php
<?php

return [
    'global' => [
        'prohibited' => [
            'hate_speech',
            'explicit_content',
            'violence',
            'illegal_activities',
        ],
        'sensitive' => [
            'politics',
            'religion',
            'controversial_topics',
        ],
    ],
    'regions' => [
        'CN' => [
            'prohibited' => [
                'taiwan_independence',
                'tiananmen_square',
                'falun_gong',
            ],
        ],
        'SA' => [
            'prohibited' => [
                'alcohol',
                'gambling',
                'dating',
            ],
        ],
        'DE' => [
            'prohibited' => [
                'nazi_symbols',
                'holocaust_denial',
            ],
        ],
    ],
];
```

Create a content filter service:

```php
// app/Services/ContentFilterService.php
<?php

namespace App\Services;

use Illuminate\Support\Facades\App;
use Illuminate\Support\Facades\Config;

class ContentFilterService
{
    /**
     * Check if content is allowed for the current locale and region.
     *
     * @param  string  $content
     * @param  string|null  $region
     * @param  string|null  $locale
     * @return bool
     */
    public function isContentAllowed($content, $region = null, $locale = null)
    {
        $locale = $locale ?? App::getLocale();
        $region = $region ?? $this->getRegionFromLocale($locale);
        
        // Get prohibited content for the region
        $globalProhibited = Config::get('content-guidelines.global.prohibited', []);
        $regionProhibited = Config::get("content-guidelines.regions.{$region}.prohibited", []);
        
        $prohibited = array_merge($globalProhibited, $regionProhibited);
        
        // Check if content contains prohibited terms
        foreach ($prohibited as $term) {
            if (stripos($content, $term) !== false) {
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * Get the region from a locale.
     *
     * @param  string  $locale
     * @return string|null
     */
    protected function getRegionFromLocale($locale)
    {
        // For locales with region (e.g., 'en-US', 'fr-CA')
        if (strpos($locale, '-') !== false) {
            return explode('-', $locale)[1];
        }
        
        // Map locales to regions
        $localeToRegion = [
            'en' => 'US',
            'fr' => 'FR',
            'es' => 'ES',
            'de' => 'DE',
            'it' => 'IT',
            'ja' => 'JP',
            'zh' => 'CN',
            'ar' => 'SA',
        ];
        
        return $localeToRegion[$locale] ?? null;
    }
}
```

Use the content filter service in your controllers:

```php
// app/Http/Controllers/PostController.php
public function store(Request $request)
{
    $validated = $request->validate([
        'title' => 'required|string|max:255',
        'content' => 'required|string',
    ]);
    
    // Check if content is allowed
    $contentFilterService = app(ContentFilterService::class);
    
    if (!$contentFilterService->isContentAllowed($validated['title']) || 
        !$contentFilterService->isContentAllowed($validated['content'])) {
        return back()->withErrors([
            'content' => __('The content contains prohibited terms for your region.'),
        ]);
    }
    
    $post = Post::create([
        'title' => $validated['title'],
        'content' => $validated['content'],
        'user_id' => auth()->id(),
    ]);
    
    return redirect()->route('posts.show', $post)
        ->with('success', __('Post created successfully.'));
}
```

#### Image Guidelines

Create image guidelines for different cultures:

```php
// config/image-guidelines.php
<?php

return [
    'global' => [
        'prohibited' => [
            'nudity',
            'violence',
            'hate_symbols',
            'illegal_activities',
        ],
        'sensitive' => [
            'political_symbols',
            'religious_symbols',
            'controversial_symbols',
        ],
    ],
    'regions' => [
        'CN' => [
            'prohibited' => [
                'taiwan_flag',
                'tibet_flag',
                'dalai_lama',
            ],
        ],
        'SA' => [
            'prohibited' => [
                'alcohol',
                'gambling',
                'dating',
                'religious_symbols_non_islamic',
            ],
        ],
        'DE' => [
            'prohibited' => [
                'nazi_symbols',
                'holocaust_denial',
            ],
        ],
    ],
];
```

### Step 5: Adapt Your Application for Different Legal Requirements

Different regions have different legal requirements:

#### Privacy Policies

Create region-specific privacy policies:

```php
// resources/views/privacy-policy.blade.php
<x-app-layout>
    <x-slot name="header">
        <h2 class="text-xl font-semibold leading-tight text-gray-800">
            {{ __('Privacy Policy') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="mx-auto max-w-7xl sm:px-6 lg:px-8">
            <div class="overflow-hidden bg-white shadow-xl sm:rounded-lg">
                <div class="p-6">
                    @if(App::getLocale() === 'en')
                        @include('privacy-policies.en')
                    @elseif(App::getLocale() === 'fr')
                        @include('privacy-policies.fr')
                    @elseif(App::getLocale() === 'de')
                        @include('privacy-policies.de')
                    @else
                        @include('privacy-policies.en')
                    @endif
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
```

#### Cookie Consent

Create region-specific cookie consent messages:

```php
// resources/views/components/cookie-consent.blade.php
<div
    x-data="{ show: !localStorage.getItem('cookie-consent') }"
    x-show="show"
    x-transition
    class="fixed bottom-0 left-0 right-0 bg-gray-800 text-white p-4"
>
    <div class="container mx-auto flex flex-col md:flex-row items-center justify-between">
        <div class="mb-4 md:mb-0">
            @if(App::getLocale() === 'en')
                <p>This website uses cookies to ensure you get the best experience on our website.</p>
            @elseif(App::getLocale() === 'fr')
                <p>Ce site utilise des cookies pour vous garantir la meilleure expérience sur notre site.</p>
            @elseif(App::getLocale() === 'de')
                <p>Diese Website verwendet Cookies, um Ihnen die bestmögliche Erfahrung auf unserer Website zu gewährleisten.</p>
            @else
                <p>This website uses cookies to ensure you get the best experience on our website.</p>
            @endif
        </div>
        <div class="flex space-x-4">
            <button
                @click="localStorage.setItem('cookie-consent', 'accepted'); show = false"
                class="bg-white text-gray-800 px-4 py-2 rounded"
            >
                {{ __('Accept') }}
            </button>
            <a href="{{ route('privacy-policy') }}" class="text-white underline">
                {{ __('Learn More') }}
            </a>
        </div>
    </div>
</div>
```

#### GDPR Compliance

Create GDPR-compliant features for EU users:

```php
// app/Http/Controllers/GdprController.php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use ZipArchive;

class GdprController extends Controller
{
    /**
     * Show the GDPR data export form.
     *
     * @return \Illuminate\View\View
     */
    public function showExportForm()
    {
        return view('gdpr.export');
    }
    
    /**
     * Export the user's data.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function export(Request $request)
    {
        $user = Auth::user();
        
        // Create a temporary file
        $zipPath = storage_path('app/exports/' . $user->id . '_data_export.zip');
        $zip = new ZipArchive();
        $zip->open($zipPath, ZipArchive::CREATE | ZipArchive::OVERWRITE);
        
        // Add user data
        $userData = [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'created_at' => $user->created_at->toIso8601String(),
            'updated_at' => $user->updated_at->toIso8601String(),
        ];
        
        $zip->addFromString('user.json', json_encode($userData, JSON_PRETTY_PRINT));
        
        // Add posts
        $posts = $user->posts;
        $zip->addFromString('posts.json', json_encode($posts, JSON_PRETTY_PRINT));
        
        // Add comments
        $comments = $user->comments;
        $zip->addFromString('comments.json', json_encode($comments, JSON_PRETTY_PRINT));
        
        // Close the zip file
        $zip->close();
        
        // Return the file
        return response()->download($zipPath)->deleteFileAfterSend(true);
    }
    
    /**
     * Show the GDPR data deletion form.
     *
     * @return \Illuminate\View\View
     */
    public function showDeletionForm()
    {
        return view('gdpr.deletion');
    }
    
    /**
     * Delete the user's data.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function delete(Request $request)
    {
        $user = Auth::user();
        
        // Delete user data
        $user->posts()->delete();
        $user->comments()->delete();
        $user->delete();
        
        Auth::logout();
        
        return redirect()->route('home')
            ->with('success', __('Your account and all associated data have been deleted.'));
    }
}
```

Add the routes:

```php
// routes/web.php
Route::middleware(['auth'])->group(function () {
    // ... other routes
    Route::get('/gdpr/export', [GdprController::class, 'showExportForm'])->name('gdpr.export.form');
    Route::post('/gdpr/export', [GdprController::class, 'export'])->name('gdpr.export');
    Route::get('/gdpr/delete', [GdprController::class, 'showDeletionForm'])->name('gdpr.delete.form');
    Route::post('/gdpr/delete', [GdprController::class, 'delete'])->name('gdpr.delete');
});
```

## Best Practices for Cultural Adaptation

1. **Research Cultural Differences**: Research cultural differences before adapting your application
2. **Consult Native Speakers**: Consult native speakers and cultural experts
3. **Test with Users from Different Cultures**: Test your application with users from different cultures
4. **Be Respectful of Cultural Sensitivities**: Be respectful of cultural sensitivities and avoid offensive content
5. **Adapt to Legal Requirements**: Adapt your application to legal requirements in different regions
6. **Use Culturally Appropriate Images and Icons**: Use images and icons that are appropriate for different cultures
7. **Consider Cultural Context**: Consider the cultural context of your application
8. **Provide Cultural Guidance**: Provide guidance for users from different cultures

## Verification

To verify that your application is culturally adapted:

1. Test with users from different cultures
2. Check that content is appropriate for different cultures
3. Verify that legal requirements are met for different regions
4. Test with different languages and writing systems
5. Check that names and addresses are formatted correctly for different cultures

## Troubleshooting

### Cultural Insensitivity

If your application is perceived as culturally insensitive:

1. Research the cultural context
2. Consult native speakers and cultural experts
3. Make necessary changes to content, images, and symbols
4. Test with users from the affected culture

### Legal Compliance Issues

If your application does not comply with legal requirements in a region:

1. Research the legal requirements
2. Consult legal experts
3. Make necessary changes to comply with the requirements
4. Test with users from the affected region

## Next Steps

Now that you've learned about cultural considerations, let's move on to [Testing Internationalized Applications](./100-testing-i18n.md) to learn how to test your internationalized application.
