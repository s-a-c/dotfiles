# Date and Time Formatting

<link rel="stylesheet" href="../../../../assets/css/styles.css">

## Goal

Learn how to format dates and times for different locales in your UME application, ensuring that users see dates and times in their preferred format.

## Prerequisites

- Completed the [Setting Up Internationalization](./010-setting-up-i18n.md) guide
- Basic understanding of PHP's date and time functions
- Basic understanding of Laravel's localization features

## Understanding Date and Time Formatting

Different regions and languages have different conventions for formatting dates and times:

- **Date Order**: Some regions use MM/DD/YYYY (US), while others use DD/MM/YYYY (Europe) or YYYY/MM/DD (Asia)
- **Date Separators**: Dates can be separated by slashes (/), hyphens (-), or periods (.)
- **Time Format**: Some regions use 12-hour format (AM/PM), while others use 24-hour format
- **First Day of Week**: Some regions consider Sunday as the first day of the week, while others use Monday
- **Month and Day Names**: Month and day names are different in each language

## Implementation Steps

### Step 1: Use Carbon for Date and Time Formatting

Laravel includes the Carbon library, which provides excellent support for date and time formatting with localization:

```php
use Carbon\Carbon;

// Set the locale for Carbon
Carbon::setLocale(app()->getLocale());

// Format a date in the current locale
$date = Carbon::now()->isoFormat('LL');

// Format a date with time in the current locale
$dateTime = Carbon::now()->isoFormat('LLLL');

// Format a relative time in the current locale
$relativeTime = Carbon::now()->subDays(2)->diffForHumans();
```

### Step 2: Create a Date Formatting Service

Create a service to handle date and time formatting consistently across your application:

```bash
php artisan make:class Services/DateFormattingService
```

Edit the service:

```php
<?php

namespace App\Services;

use Carbon\Carbon;
use Illuminate\Support\Facades\App;

class DateFormattingService
{
    /**
     * Format a date for the current locale.
     *
     * @param  \Carbon\Carbon|\DateTimeInterface|string|null  $date
     * @param  string  $format
     * @return string
     */
    public function formatDate($date, $format = 'LL')
    {
        if (is_null($date)) {
            return '';
        }
        
        if (!$date instanceof Carbon) {
            $date = Carbon::parse($date);
        }
        
        $date->setLocale(App::getLocale());
        
        return $date->isoFormat($format);
    }
    
    /**
     * Format a date with time for the current locale.
     *
     * @param  \Carbon\Carbon|\DateTimeInterface|string|null  $date
     * @param  string  $format
     * @return string
     */
    public function formatDateTime($date, $format = 'LLLL')
    {
        if (is_null($date)) {
            return '';
        }
        
        if (!$date instanceof Carbon) {
            $date = Carbon::parse($date);
        }
        
        $date->setLocale(App::getLocale());
        
        return $date->isoFormat($format);
    }
    
    /**
     * Format a time for the current locale.
     *
     * @param  \Carbon\Carbon|\DateTimeInterface|string|null  $date
     * @param  string  $format
     * @return string
     */
    public function formatTime($date, $format = 'LT')
    {
        if (is_null($date)) {
            return '';
        }
        
        if (!$date instanceof Carbon) {
            $date = Carbon::parse($date);
        }
        
        $date->setLocale(App::getLocale());
        
        return $date->isoFormat($format);
    }
    
    /**
     * Format a relative time for the current locale.
     *
     * @param  \Carbon\Carbon|\DateTimeInterface|string|null  $date
     * @return string
     */
    public function formatRelativeTime($date)
    {
        if (is_null($date)) {
            return '';
        }
        
        if (!$date instanceof Carbon) {
            $date = Carbon::parse($date);
        }
        
        $date->setLocale(App::getLocale());
        
        return $date->diffForHumans();
    }
    
    /**
     * Format a date range for the current locale.
     *
     * @param  \Carbon\Carbon|\DateTimeInterface|string|null  $startDate
     * @param  \Carbon\Carbon|\DateTimeInterface|string|null  $endDate
     * @param  string  $format
     * @return string
     */
    public function formatDateRange($startDate, $endDate, $format = 'LL')
    {
        if (is_null($startDate) || is_null($endDate)) {
            return '';
        }
        
        if (!$startDate instanceof Carbon) {
            $startDate = Carbon::parse($startDate);
        }
        
        if (!$endDate instanceof Carbon) {
            $endDate = Carbon::parse($endDate);
        }
        
        $startDate->setLocale(App::getLocale());
        $endDate->setLocale(App::getLocale());
        
        return $startDate->isoFormat($format) . ' - ' . $endDate->isoFormat($format);
    }
}
```

### Step 3: Register the Service in the Service Container

Register the service in the service container for easy access:

```php
// app/Providers/AppServiceProvider.php
public function register()
{
    $this->app->singleton(DateFormattingService::class, function ($app) {
        return new DateFormattingService();
    });
}
```

### Step 4: Create a Blade Directive for Date Formatting

Create a Blade directive for easy date formatting in views:

```php
// app/Providers/AppServiceProvider.php
public function boot()
{
    Blade::directive('formatDate', function ($expression) {
        return "<?php echo app(App\\Services\\DateFormattingService::class)->formatDate($expression); ?>";
    });
    
    Blade::directive('formatDateTime', function ($expression) {
        return "<?php echo app(App\\Services\\DateFormattingService::class)->formatDateTime($expression); ?>";
    });
    
    Blade::directive('formatTime', function ($expression) {
        return "<?php echo app(App\\Services\\DateFormattingService::class)->formatTime($expression); ?>";
    });
    
    Blade::directive('formatRelativeTime', function ($expression) {
        return "<?php echo app(App\\Services\\DateFormattingService::class)->formatRelativeTime($expression); ?>";
    });
    
    Blade::directive('formatDateRange', function ($expression) {
        return "<?php echo app(App\\Services\\DateFormattingService::class)->formatDateRange($expression); ?>";
    });
}
```

### Step 5: Use the Date Formatting Service in Views

Use the date formatting service in your views:

```php
<div class="mt-2 text-sm text-gray-500">
    {{ __('Created at') }}: @formatDate($user->created_at)
</div>

<div class="mt-2 text-sm text-gray-500">
    {{ __('Last updated') }}: @formatRelativeTime($user->updated_at)
</div>

<div class="mt-2 text-sm text-gray-500">
    {{ __('Event period') }}: @formatDateRange($event->start_date, $event->end_date)
</div>
```

### Step 6: Create a Livewire Component for Date Formatting

Create a Livewire component for dynamic date formatting:

```bash
php artisan make:livewire FormattedDate
```

Edit the component class:

```php
<?php

namespace App\Http\Livewire;

use App\Services\DateFormattingService;
use Livewire\Component;

class FormattedDate extends Component
{
    public $date;
    public $format = 'LL';
    public $type = 'date';
    
    public function mount($date, $format = null, $type = 'date')
    {
        $this->date = $date;
        
        if ($format) {
            $this->format = $format;
        }
        
        $this->type = $type;
    }
    
    public function render()
    {
        $dateFormattingService = app(DateFormattingService::class);
        
        $formattedDate = '';
        
        switch ($this->type) {
            case 'date':
                $formattedDate = $dateFormattingService->formatDate($this->date, $this->format);
                break;
            case 'datetime':
                $formattedDate = $dateFormattingService->formatDateTime($this->date, $this->format);
                break;
            case 'time':
                $formattedDate = $dateFormattingService->formatTime($this->date, $this->format);
                break;
            case 'relative':
                $formattedDate = $dateFormattingService->formatRelativeTime($this->date);
                break;
        }
        
        return view('livewire.formatted-date', [
            'formattedDate' => $formattedDate,
        ]);
    }
}
```

Create the component view:

```php
<!-- resources/views/livewire/formatted-date.blade.php -->
<span>{{ $formattedDate }}</span>
```

Use the component in your views:

```php
<div class="mt-2 text-sm text-gray-500">
    {{ __('Created at') }}: @livewire('formatted-date', ['date' => $user->created_at])
</div>

<div class="mt-2 text-sm text-gray-500">
    {{ __('Last updated') }}: @livewire('formatted-date', ['date' => $user->updated_at, 'type' => 'relative'])
</div>
```

### Step 7: Handle Date Formatting in JavaScript

For client-side date formatting, use the Intl.DateTimeFormat API:

```javascript
// resources/js/date-formatting.js
export function formatDate(date, locale = document.documentElement.lang) {
    return new Intl.DateTimeFormat(locale, {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    }).format(new Date(date));
}

export function formatDateTime(date, locale = document.documentElement.lang) {
    return new Intl.DateTimeFormat(locale, {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: 'numeric',
        minute: 'numeric'
    }).format(new Date(date));
}

export function formatTime(date, locale = document.documentElement.lang) {
    return new Intl.DateTimeFormat(locale, {
        hour: 'numeric',
        minute: 'numeric'
    }).format(new Date(date));
}

export function formatRelativeTime(date, locale = document.documentElement.lang) {
    const now = new Date();
    const then = new Date(date);
    const diffInSeconds = Math.floor((now - then) / 1000);
    
    const units = {
        year: 24 * 60 * 60 * 365,
        month: 24 * 60 * 60 * 30,
        week: 24 * 60 * 60 * 7,
        day: 24 * 60 * 60,
        hour: 60 * 60,
        minute: 60,
        second: 1
    };
    
    let unit;
    let value;
    
    for (const [unitName, secondsInUnit] of Object.entries(units)) {
        if (diffInSeconds >= secondsInUnit || unitName === 'second') {
            unit = unitName;
            value = Math.floor(diffInSeconds / secondsInUnit);
            break;
        }
    }
    
    const rtf = new Intl.RelativeTimeFormat(locale, { numeric: 'auto' });
    return rtf.format(-value, unit);
}
```

Use the JavaScript date formatting functions in your components:

```javascript
// resources/js/components/FormattedDate.js
import { formatDate, formatDateTime, formatTime, formatRelativeTime } from '../date-formatting';

export default {
    props: {
        date: {
            type: String,
            required: true
        },
        format: {
            type: String,
            default: 'date'
        }
    },
    computed: {
        formattedDate() {
            switch (this.format) {
                case 'date':
                    return formatDate(this.date);
                case 'datetime':
                    return formatDateTime(this.date);
                case 'time':
                    return formatTime(this.date);
                case 'relative':
                    return formatRelativeTime(this.date);
                default:
                    return formatDate(this.date);
            }
        }
    },
    template: `<span>{{ formattedDate }}</span>`
};
```

### Step 8: Handle Date Input in Forms

For date input in forms, make sure to convert between the user's locale format and the application's internal format:

```php
// app/Http/Controllers/EventController.php
public function store(Request $request)
{
    $validated = $request->validate([
        'title' => 'required|string|max:255',
        'description' => 'nullable|string',
        'start_date' => 'required|date_format:' . $this->getDateFormat(),
        'end_date' => 'required|date_format:' . $this->getDateFormat() . '|after:start_date',
    ]);
    
    // Convert dates from user's locale format to database format
    $startDate = Carbon::createFromFormat($this->getDateFormat(), $validated['start_date'])->format('Y-m-d');
    $endDate = Carbon::createFromFormat($this->getDateFormat(), $validated['end_date'])->format('Y-m-d');
    
    $event = Event::create([
        'title' => $validated['title'],
        'description' => $validated['description'],
        'start_date' => $startDate,
        'end_date' => $endDate,
        'user_id' => auth()->id(),
    ]);
    
    return redirect()->route('events.show', $event)
        ->with('success', __('Event created successfully.'));
}

protected function getDateFormat()
{
    // Return the date format for the current locale
    switch (app()->getLocale()) {
        case 'en':
            return 'm/d/Y';
        case 'fr':
        case 'es':
            return 'd/m/Y';
        default:
            return 'Y-m-d';
    }
}
```

## Common Date and Time Formats by Locale

Here are some common date and time formats for different locales:

| Locale | Date Format | Time Format | DateTime Format |
|--------|-------------|-------------|-----------------|
| en-US  | MM/DD/YYYY  | h:mm A      | MM/DD/YYYY h:mm A |
| en-GB  | DD/MM/YYYY  | HH:mm       | DD/MM/YYYY HH:mm |
| fr-FR  | DD/MM/YYYY  | HH:mm       | DD/MM/YYYY HH:mm |
| es-ES  | DD/MM/YYYY  | HH:mm       | DD/MM/YYYY HH:mm |
| de-DE  | DD.MM.YYYY  | HH:mm       | DD.MM.YYYY HH:mm |
| it-IT  | DD/MM/YYYY  | HH:mm       | DD/MM/YYYY HH:mm |
| ja-JP  | YYYY/MM/DD  | HH:mm       | YYYY/MM/DD HH:mm |
| zh-CN  | YYYY/MM/DD  | HH:mm       | YYYY/MM/DD HH:mm |
| ar-SA  | DD/MM/YYYY  | hh:mm a     | DD/MM/YYYY hh:mm a |

## Best Practices for Date and Time Formatting

1. **Use Carbon for PHP**: Carbon provides excellent support for date and time formatting with localization
2. **Use Intl.DateTimeFormat for JavaScript**: The Intl.DateTimeFormat API provides native support for date and time formatting in different locales
3. **Store Dates in a Standard Format**: Store dates in a standard format (e.g., ISO 8601) in your database
4. **Format Dates for Display**: Format dates for display based on the user's locale
5. **Handle Date Input Carefully**: When accepting date input from users, make sure to validate and convert between the user's locale format and the application's internal format
6. **Consider Time Zones**: Be aware of time zones when displaying dates and times
7. **Use Relative Time When Appropriate**: Use relative time (e.g., "2 hours ago") for recent dates
8. **Test with Different Locales**: Test date and time formatting with different locales to ensure it works correctly

## Verification

To verify that date and time formatting is working correctly:

1. Switch between different locales and check that dates and times are formatted correctly
2. Test date input in forms to ensure that dates are validated and stored correctly
3. Test relative time formatting to ensure that it works correctly
4. Test with different time zones to ensure that dates and times are displayed correctly

## Troubleshooting

### Incorrect Date Format

If dates are not formatted correctly:

1. Check that the locale is set correctly
2. Verify that Carbon's locale is set to match the application locale
3. Check that the date format is appropriate for the current locale

### Date Input Validation Errors

If date input validation is failing:

1. Check that the date format in the validation rule matches the format expected by the user's locale
2. Verify that the date input field is using the correct format
3. Consider using a date picker that supports different locale formats

## Next Steps

Now that you've learned how to format dates and times for different locales, let's move on to [Currency Handling](./060-currency-handling.md) to learn how to handle currencies in different locales.
