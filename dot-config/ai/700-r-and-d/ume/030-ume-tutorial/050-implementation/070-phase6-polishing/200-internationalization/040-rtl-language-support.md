# RTL Language Support

<link rel="stylesheet" href="../../../../assets/css/styles.css">

## Goal

Learn how to support right-to-left (RTL) languages in your UME application, ensuring a seamless experience for users of languages like Arabic, Hebrew, and Persian.

## Prerequisites

- Completed the [Setting Up Internationalization](./010-setting-up-i18n.md) guide
- Completed the [Translation Management](./020-translation-management.md) guide
- Completed the [Localizing UME Features](./030-localizing-ume-features.md) guide
- Basic understanding of CSS and HTML directionality

## Understanding RTL Languages

Right-to-left (RTL) languages are written and read from right to left, unlike left-to-right (LTR) languages like English. Supporting RTL languages requires more than just translating text; it involves adjusting the layout, alignment, and direction of UI elements.

Common RTL languages include:
- Arabic (ar)
- Hebrew (he)
- Persian/Farsi (fa)
- Urdu (ur)
- Kurdish (ku)
- Pashto (ps)

## Implementation Steps

### Step 1: Configure RTL Support in Laravel

First, let's update our locale configuration to include the text direction for each language:

```php
// config/app.php
'available_locales' => [
    'en' => ['name' => 'English', 'native' => 'English', 'direction' => 'ltr'],
    'es' => ['name' => 'Spanish', 'native' => 'Español', 'direction' => 'ltr'],
    'fr' => ['name' => 'French', 'native' => 'Français', 'direction' => 'ltr'],
    'ar' => ['name' => 'Arabic', 'native' => 'العربية', 'direction' => 'rtl'],
    'he' => ['name' => 'Hebrew', 'native' => 'עברית', 'direction' => 'rtl'],
    'fa' => ['name' => 'Persian', 'native' => 'فارسی', 'direction' => 'rtl'],
],
```

### Step 2: Update HTML Direction Attribute

Update your layout files to set the `dir` attribute based on the current locale's direction:

```php
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

### Step 3: Create RTL-Specific Stylesheets

Create RTL-specific stylesheets to handle RTL-specific styling:

**resources/css/app.css**:
```css
@import 'tailwindcss/base';
@import 'tailwindcss/components';
@import 'tailwindcss/utilities';

/* RTL-specific styles */
[dir="rtl"] {
    /* Text alignment */
    .text-left {
        text-align: right;
    }
    .text-right {
        text-align: left;
    }
    
    /* Margins and paddings */
    .ml-1, .ml-2, .ml-3, .ml-4, .ml-5, .ml-6, .ml-8, .ml-10, .ml-12 {
        margin-left: 0;
    }
    .mr-1, .mr-2, .mr-3, .mr-4, .mr-5, .mr-6, .mr-8, .mr-10, .mr-12 {
        margin-right: 0;
    }
    .ml-1 { margin-right: 0.25rem; }
    .ml-2 { margin-right: 0.5rem; }
    .ml-3 { margin-right: 0.75rem; }
    .ml-4 { margin-right: 1rem; }
    .ml-5 { margin-right: 1.25rem; }
    .ml-6 { margin-right: 1.5rem; }
    .ml-8 { margin-right: 2rem; }
    .ml-10 { margin-right: 2.5rem; }
    .ml-12 { margin-right: 3rem; }
    
    .mr-1 { margin-left: 0.25rem; }
    .mr-2 { margin-left: 0.5rem; }
    .mr-3 { margin-left: 0.75rem; }
    .mr-4 { margin-left: 1rem; }
    .mr-5 { margin-left: 1.25rem; }
    .mr-6 { margin-left: 1.5rem; }
    .mr-8 { margin-left: 2rem; }
    .mr-10 { margin-left: 2.5rem; }
    .mr-12 { margin-left: 3rem; }
    
    /* Borders */
    .border-l { border-left: none; border-right: 1px solid; }
    .border-r { border-right: none; border-left: 1px solid; }
    
    /* Rounded corners */
    .rounded-l { border-radius: 0; border-top-right-radius: 0.25rem; border-bottom-right-radius: 0.25rem; }
    .rounded-r { border-radius: 0; border-top-left-radius: 0.25rem; border-bottom-left-radius: 0.25rem; }
    
    /* Floats */
    .float-left { float: right; }
    .float-right { float: left; }
    
    /* Flexbox */
    .justify-start { justify-content: flex-end; }
    .justify-end { justify-content: flex-start; }
    
    /* Icons and directional elements */
    .transform.rotate-180 { transform: rotate(0deg); }
    .transform.rotate-0 { transform: rotate(180deg); }
    
    /* Form elements */
    input, textarea {
        text-align: right;
    }
}
```

### Step 4: Use CSS Logical Properties

For new CSS, use logical properties instead of directional properties:

```css
/* Instead of this */
.element {
    margin-left: 1rem;
    padding-right: 1rem;
    border-left: 1px solid;
    text-align: left;
}

/* Use this */
.element {
    margin-inline-start: 1rem;
    padding-inline-end: 1rem;
    border-inline-start: 1px solid;
    text-align: start;
}
```

### Step 5: Handle RTL in JavaScript

If you're using JavaScript to manipulate the DOM, make sure to account for RTL:

```javascript
// Get the current text direction
const isRtl = document.dir === 'rtl';

// Example: Adjust a slider to move in the correct direction
function moveSlider(slider, direction) {
    if (isRtl) {
        // Invert the direction for RTL
        direction = direction === 'left' ? 'right' : 'left';
    }
    
    // Move the slider
    if (direction === 'left') {
        slider.scrollLeft -= 100;
    } else {
        slider.scrollLeft += 100;
    }
}
```

### Step 6: Update Flux UI Components for RTL Support

If you're using Flux UI components, make sure they support RTL:

**resources/views/components/flux/dropdown.blade.php**:
```php
<div
    x-data="{ open: false }"
    @click.away="open = false"
    @keydown.escape.window="open = false"
    class="relative inline-block text-left {{ config('app.available_locales.' . app()->getLocale() . '.direction') === 'rtl' ? 'text-right' : '' }}"
>
    <div>
        <button
            @click="open = !open"
            type="button"
            class="inline-flex justify-between w-full rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-100 focus:ring-indigo-500"
        >
            {{ $trigger }}
            
            <svg class="{{ config('app.available_locales.' . app()->getLocale() . '.direction') === 'rtl' ? 'mr-2' : 'ml-2' }} -mr-1 h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
            </svg>
        </button>
    </div>

    <div
        x-show="open"
        x-transition:enter="transition ease-out duration-100"
        x-transition:enter-start="transform opacity-0 scale-95"
        x-transition:enter-end="transform opacity-100 scale-100"
        x-transition:leave="transition ease-in duration-75"
        x-transition:leave-start="transform opacity-100 scale-100"
        x-transition:leave-end="transform opacity-0 scale-95"
        class="origin-top-right absolute {{ config('app.available_locales.' . app()->getLocale() . '.direction') === 'rtl' ? 'left-0' : 'right-0' }} mt-2 w-56 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 focus:outline-none"
        style="display: none;"
    >
        <div class="py-1" role="menu" aria-orientation="vertical" aria-labelledby="options-menu">
            {{ $slot }}
        </div>
    </div>
</div>
```

### Step 7: Handle RTL in Forms

Update your forms to handle RTL input:

```php
<div class="mb-4">
    <label for="name" class="block text-sm font-medium text-gray-700">
        {{ __('Name') }}
    </label>
    <input
        type="text"
        name="name"
        id="name"
        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm {{ config('app.available_locales.' . app()->getLocale() . '.direction') === 'rtl' ? 'text-right' : '' }}"
        value="{{ old('name') }}"
        dir="{{ config('app.available_locales.' . app()->getLocale() . '.direction', 'ltr') }}"
    >
</div>
```

### Step 8: Handle RTL in Tables

Update your tables to handle RTL layout:

```php
<table class="min-w-full divide-y divide-gray-200">
    <thead class="bg-gray-50">
        <tr>
            <th scope="col" class="px-6 py-3 text-xs font-medium tracking-wider {{ config('app.available_locales.' . app()->getLocale() . '.direction') === 'rtl' ? 'text-right' : 'text-left' }} text-gray-500 uppercase">
                {{ __('Name') }}
            </th>
            <th scope="col" class="px-6 py-3 text-xs font-medium tracking-wider {{ config('app.available_locales.' . app()->getLocale() . '.direction') === 'rtl' ? 'text-right' : 'text-left' }} text-gray-500 uppercase">
                {{ __('Email') }}
            </th>
            <th scope="col" class="px-6 py-3 text-xs font-medium tracking-wider {{ config('app.available_locales.' . app()->getLocale() . '.direction') === 'rtl' ? 'text-right' : 'text-left' }} text-gray-500 uppercase">
                {{ __('Role') }}
            </th>
            <th scope="col" class="relative px-6 py-3">
                <span class="sr-only">{{ __('Edit') }}</span>
            </th>
        </tr>
    </thead>
    <tbody class="bg-white divide-y divide-gray-200">
        @foreach ($users as $user)
            <tr>
                <td class="px-6 py-4 whitespace-nowrap {{ config('app.available_locales.' . app()->getLocale() . '.direction') === 'rtl' ? 'text-right' : 'text-left' }}">
                    {{ $user->name }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap {{ config('app.available_locales.' . app()->getLocale() . '.direction') === 'rtl' ? 'text-right' : 'text-left' }}">
                    {{ $user->email }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap {{ config('app.available_locales.' . app()->getLocale() . '.direction') === 'rtl' ? 'text-right' : 'text-left' }}">
                    {{ $user->role }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <a href="{{ route('users.edit', $user) }}" class="text-indigo-600 hover:text-indigo-900">
                        {{ __('Edit') }}
                    </a>
                </td>
            </tr>
        @endforeach
    </tbody>
</table>
```

### Step 9: Test RTL Support

Test your application with RTL languages to ensure everything works correctly:

1. Switch to an RTL language (e.g., Arabic)
2. Check that text is aligned correctly
3. Verify that UI elements are positioned correctly
4. Test form inputs and validation
5. Check that icons and directional elements are flipped
6. Test navigation and menus
7. Verify that tables and grids are displayed correctly

## Best Practices for RTL Support

1. **Use Logical Properties**: Use CSS logical properties (e.g., `margin-inline-start` instead of `margin-left`) for new CSS
2. **Test with Real Users**: Have native speakers of RTL languages test your application
3. **Consider Cultural Differences**: Be aware of cultural differences in RTL-speaking regions
4. **Use RTL-Friendly Icons**: Use icons that work well in both LTR and RTL contexts
5. **Handle Bidirectional Text**: Use the `dir` attribute for user-generated content
6. **Test with Different Browsers**: Test RTL support in different browsers
7. **Consider Mobile Devices**: Test RTL support on mobile devices
8. **Use RTL-Aware Libraries**: Use libraries that support RTL out of the box

## Common RTL Issues and Solutions

### Text Alignment

**Issue**: Text is not aligned correctly in RTL mode.

**Solution**: Use the `text-align` property with logical values:

```css
[dir="rtl"] .text-left {
    text-align: right;
}
[dir="rtl"] .text-right {
    text-align: left;
}
```

### Icon Direction

**Issue**: Icons are not flipped in RTL mode.

**Solution**: Flip icons using CSS transforms:

```css
[dir="rtl"] .icon-arrow-right {
    transform: scaleX(-1);
}
```

### Form Input Direction

**Issue**: Form inputs don't respect RTL text direction.

**Solution**: Set the `dir` attribute on form inputs:

```php
<input type="text" dir="{{ config('app.available_locales.' . app()->getLocale() . '.direction', 'ltr') }}">
```

### Layout Issues

**Issue**: Layout is broken in RTL mode.

**Solution**: Use CSS Grid or Flexbox with logical properties:

```css
.container {
    display: flex;
    flex-direction: row;
}

[dir="rtl"] .container {
    flex-direction: row-reverse;
}
```

## Next Steps

Now that you've learned how to support RTL languages in your UME application, let's move on to [Date and Time Formatting](./050-date-time-formatting.md) to learn how to format dates and times for different locales.
