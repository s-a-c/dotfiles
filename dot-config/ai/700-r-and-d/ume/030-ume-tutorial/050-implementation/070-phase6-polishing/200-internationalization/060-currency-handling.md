# Currency Handling

<link rel="stylesheet" href="../../../../assets/css/styles.css">

## Goal

Learn how to handle currencies in different locales in your UME application, ensuring that monetary values are displayed in a format that is familiar to users.

## Prerequisites

- Completed the [Setting Up Internationalization](./010-setting-up-i18n.md) guide
- Basic understanding of PHP's number formatting functions
- Basic understanding of Laravel's localization features

## Understanding Currency Formatting

Different regions have different conventions for formatting currencies:

- **Currency Symbol**: Each currency has its own symbol (e.g., $, €, £, ¥)
- **Symbol Position**: Some regions place the currency symbol before the amount, others after
- **Decimal Separator**: Some regions use a period (.) as the decimal separator, others use a comma (,)
- **Thousands Separator**: Some regions use a comma (,) as the thousands separator, others use a period (.) or space
- **Number of Decimal Places**: Some currencies are typically displayed with 2 decimal places, others with 0 or more

## Implementation Steps

### Step 1: Create a Currency Formatting Service

Create a service to handle currency formatting consistently across your application:

```bash
php artisan make:class Services/CurrencyFormattingService
```

Edit the service:

```php
<?php

namespace App\Services;

use Illuminate\Support\Facades\App;
use NumberFormatter;

class CurrencyFormattingService
{
    /**
     * Format a monetary value for the current locale.
     *
     * @param  float  $amount
     * @param  string|null  $currencyCode
     * @param  string|null  $locale
     * @return string
     */
    public function formatCurrency($amount, $currencyCode = null, $locale = null)
    {
        $locale = $locale ?? App::getLocale();
        $currencyCode = $currencyCode ?? $this->getDefaultCurrencyCode($locale);
        
        $formatter = new NumberFormatter($locale, NumberFormatter::CURRENCY);
        
        return $formatter->formatCurrency($amount, $currencyCode);
    }
    
    /**
     * Format a monetary value without the currency symbol.
     *
     * @param  float  $amount
     * @param  int  $decimals
     * @param  string|null  $locale
     * @return string
     */
    public function formatNumber($amount, $decimals = 2, $locale = null)
    {
        $locale = $locale ?? App::getLocale();
        
        $formatter = new NumberFormatter($locale, NumberFormatter::DECIMAL);
        $formatter->setAttribute(NumberFormatter::FRACTION_DIGITS, $decimals);
        
        return $formatter->format($amount);
    }
    
    /**
     * Parse a localized monetary value to a float.
     *
     * @param  string  $amount
     * @param  string|null  $locale
     * @return float|false
     */
    public function parseCurrency($amount, $locale = null)
    {
        $locale = $locale ?? App::getLocale();
        
        $formatter = new NumberFormatter($locale, NumberFormatter::DECIMAL);
        
        return $formatter->parse($amount);
    }
    
    /**
     * Get the default currency code for a locale.
     *
     * @param  string  $locale
     * @return string
     */
    protected function getDefaultCurrencyCode($locale)
    {
        $currencyMap = [
            'en' => 'USD',
            'en-US' => 'USD',
            'en-GB' => 'GBP',
            'fr' => 'EUR',
            'fr-FR' => 'EUR',
            'es' => 'EUR',
            'es-ES' => 'EUR',
            'de' => 'EUR',
            'de-DE' => 'EUR',
            'it' => 'EUR',
            'it-IT' => 'EUR',
            'ja' => 'JPY',
            'ja-JP' => 'JPY',
            'zh' => 'CNY',
            'zh-CN' => 'CNY',
            'ar' => 'SAR',
            'ar-SA' => 'SAR',
        ];
        
        return $currencyMap[$locale] ?? 'USD';
    }
}
```

### Step 2: Register the Service in the Service Container

Register the service in the service container for easy access:

```php
// app/Providers/AppServiceProvider.php
public function register()
{
    $this->app->singleton(CurrencyFormattingService::class, function ($app) {
        return new CurrencyFormattingService();
    });
}
```

### Step 3: Create a Blade Directive for Currency Formatting

Create a Blade directive for easy currency formatting in views:

```php
// app/Providers/AppServiceProvider.php
public function boot()
{
    Blade::directive('formatCurrency', function ($expression) {
        return "<?php echo app(App\\Services\\CurrencyFormattingService::class)->formatCurrency($expression); ?>";
    });
    
    Blade::directive('formatNumber', function ($expression) {
        return "<?php echo app(App\\Services\\CurrencyFormattingService::class)->formatNumber($expression); ?>";
    });
}
```

### Step 4: Use the Currency Formatting Service in Views

Use the currency formatting service in your views:

```php
<div class="mt-2 text-sm text-gray-500">
    {{ __('Price') }}: @formatCurrency($product->price)
</div>

<div class="mt-2 text-sm text-gray-500">
    {{ __('Total') }}: @formatCurrency($order->total, 'EUR')
</div>
```

### Step 5: Create a Livewire Component for Currency Formatting

Create a Livewire component for dynamic currency formatting:

```bash
php artisan make:livewire FormattedCurrency
```

Edit the component class:

```php
<?php

namespace App\Http\Livewire;

use App\Services\CurrencyFormattingService;
use Livewire\Component;

class FormattedCurrency extends Component
{
    public $amount;
    public $currencyCode;
    
    public function mount($amount, $currencyCode = null)
    {
        $this->amount = $amount;
        $this->currencyCode = $currencyCode;
    }
    
    public function render()
    {
        $currencyFormattingService = app(CurrencyFormattingService::class);
        
        $formattedAmount = $currencyFormattingService->formatCurrency(
            $this->amount,
            $this->currencyCode
        );
        
        return view('livewire.formatted-currency', [
            'formattedAmount' => $formattedAmount,
        ]);
    }
}
```

Create the component view:

```php
<!-- resources/views/livewire/formatted-currency.blade.php -->
<span>{{ $formattedAmount }}</span>
```

Use the component in your views:

```php
<div class="mt-2 text-sm text-gray-500">
    {{ __('Price') }}: @livewire('formatted-currency', ['amount' => $product->price])
</div>

<div class="mt-2 text-sm text-gray-500">
    {{ __('Total') }}: @livewire('formatted-currency', ['amount' => $order->total, 'currencyCode' => 'EUR'])
</div>
```

### Step 6: Handle Currency Formatting in JavaScript

For client-side currency formatting, use the Intl.NumberFormat API:

```javascript
// resources/js/currency-formatting.js
export function formatCurrency(amount, currencyCode = 'USD', locale = document.documentElement.lang) {
    return new Intl.NumberFormat(locale, {
        style: 'currency',
        currency: currencyCode
    }).format(amount);
}

export function formatNumber(amount, decimals = 2, locale = document.documentElement.lang) {
    return new Intl.NumberFormat(locale, {
        style: 'decimal',
        minimumFractionDigits: decimals,
        maximumFractionDigits: decimals
    }).format(amount);
}
```

Use the JavaScript currency formatting functions in your components:

```javascript
// resources/js/components/FormattedCurrency.js
import { formatCurrency } from '../currency-formatting';

export default {
    props: {
        amount: {
            type: Number,
            required: true
        },
        currencyCode: {
            type: String,
            default: 'USD'
        }
    },
    computed: {
        formattedAmount() {
            return formatCurrency(this.amount, this.currencyCode);
        }
    },
    template: `<span>{{ formattedAmount }}</span>`
};
```

### Step 7: Handle Currency Input in Forms

For currency input in forms, make sure to convert between the user's locale format and the application's internal format:

```php
// app/Http/Controllers/ProductController.php
public function store(Request $request)
{
    $validated = $request->validate([
        'name' => 'required|string|max:255',
        'description' => 'nullable|string',
        'price' => 'required|string',
    ]);
    
    // Convert price from user's locale format to database format
    $currencyFormattingService = app(CurrencyFormattingService::class);
    $price = $currencyFormattingService->parseCurrency($validated['price']);
    
    $product = Product::create([
        'name' => $validated['name'],
        'description' => $validated['description'],
        'price' => $price,
        'user_id' => auth()->id(),
    ]);
    
    return redirect()->route('products.show', $product)
        ->with('success', __('Product created successfully.'));
}
```

### Step 8: Create a Currency Input Component

Create a Livewire component for currency input:

```bash
php artisan make:livewire CurrencyInput
```

Edit the component class:

```php
<?php

namespace App\Http\Livewire;

use App\Services\CurrencyFormattingService;
use Livewire\Component;

class CurrencyInput extends Component
{
    public $name;
    public $value;
    public $currencyCode;
    public $placeholder;
    public $required = false;
    
    public function mount($name, $value = null, $currencyCode = null, $placeholder = null, $required = false)
    {
        $this->name = $name;
        $this->currencyCode = $currencyCode;
        $this->placeholder = $placeholder;
        $this->required = $required;
        
        if ($value) {
            $currencyFormattingService = app(CurrencyFormattingService::class);
            $this->value = $currencyFormattingService->formatNumber($value);
        } else {
            $this->value = '';
        }
    }
    
    public function render()
    {
        return view('livewire.currency-input');
    }
}
```

Create the component view:

```php
<!-- resources/views/livewire/currency-input.blade.php -->
<div>
    <div class="relative rounded-md shadow-sm">
        @if($currencyCode)
            <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
                <span class="text-gray-500 sm:text-sm">
                    {{ $currencyCode === 'USD' ? '$' : ($currencyCode === 'EUR' ? '€' : ($currencyCode === 'GBP' ? '£' : $currencyCode)) }}
                </span>
            </div>
        @endif
        
        <input
            type="text"
            name="{{ $name }}"
            id="{{ $name }}"
            class="block w-full {{ $currencyCode ? 'pl-7' : '' }} pr-12 border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
            placeholder="{{ $placeholder }}"
            value="{{ $value }}"
            {{ $required ? 'required' : '' }}
        >
        
        @if($currencyCode)
            <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                <span class="text-gray-500 sm:text-sm">
                    {{ $currencyCode }}
                </span>
            </div>
        @endif
    </div>
</div>
```

Use the component in your forms:

```php
<form action="{{ route('products.store') }}" method="POST">
    @csrf
    
    <div class="mb-4">
        <label for="name" class="block text-sm font-medium text-gray-700">
            {{ __('Name') }}
        </label>
        <input type="text" name="name" id="name" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" required>
    </div>
    
    <div class="mb-4">
        <label for="description" class="block text-sm font-medium text-gray-700">
            {{ __('Description') }}
        </label>
        <textarea name="description" id="description" rows="3" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"></textarea>
    </div>
    
    <div class="mb-4">
        <label for="price" class="block text-sm font-medium text-gray-700">
            {{ __('Price') }}
        </label>
        @livewire('currency-input', ['name' => 'price', 'currencyCode' => 'USD', 'required' => true])
    </div>
    
    <div class="flex justify-end">
        <button type="submit" class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
            {{ __('Create Product') }}
        </button>
    </div>
</form>
```

## Common Currency Formats by Locale

Here are some common currency formats for different locales:

| Locale | Currency | Format Example | Decimal Separator | Thousands Separator |
|--------|----------|----------------|-------------------|---------------------|
| en-US  | USD      | $1,234.56      | .                 | ,                   |
| en-GB  | GBP      | £1,234.56      | .                 | ,                   |
| fr-FR  | EUR      | 1 234,56 €     | ,                 | space               |
| es-ES  | EUR      | 1.234,56 €     | ,                 | .                   |
| de-DE  | EUR      | 1.234,56 €     | ,                 | .                   |
| it-IT  | EUR      | 1.234,56 €     | ,                 | .                   |
| ja-JP  | JPY      | ¥1,235         | .                 | ,                   |
| zh-CN  | CNY      | ¥1,234.56      | .                 | ,                   |
| ar-SA  | SAR      | ١٬٢٣٤٫٥٦ ر.س.‏ | .                 | ,                   |

## Best Practices for Currency Handling

1. **Use NumberFormatter for PHP**: The NumberFormatter class provides excellent support for currency formatting with localization
2. **Use Intl.NumberFormat for JavaScript**: The Intl.NumberFormat API provides native support for currency formatting in different locales
3. **Store Monetary Values as Integers or Decimals**: Store monetary values in a standard format (e.g., cents as integers or dollars as decimals) in your database
4. **Format Currencies for Display**: Format currencies for display based on the user's locale
5. **Handle Currency Input Carefully**: When accepting currency input from users, make sure to validate and convert between the user's locale format and the application's internal format
6. **Consider Exchange Rates**: Be aware of exchange rates when displaying prices in different currencies
7. **Use Currency Symbols Appropriately**: Use the appropriate currency symbol for each currency
8. **Test with Different Locales**: Test currency formatting with different locales to ensure it works correctly

## Verification

To verify that currency handling is working correctly:

1. Switch between different locales and check that currencies are formatted correctly
2. Test currency input in forms to ensure that values are validated and stored correctly
3. Test with different currencies to ensure that the correct symbols and formats are used
4. Test with large numbers to ensure that thousands separators are displayed correctly

## Troubleshooting

### Incorrect Currency Format

If currencies are not formatted correctly:

1. Check that the locale is set correctly
2. Verify that the NumberFormatter is configured correctly
3. Check that the currency code is valid

### Currency Input Validation Errors

If currency input validation is failing:

1. Check that the input field is using the correct format for the user's locale
2. Verify that the parsing function is handling the user's locale format correctly
3. Consider using a currency input component that handles formatting automatically

## Next Steps

Now that you've learned how to handle currencies in different locales, let's move on to [Pluralization Rules](./070-pluralization-rules.md) to learn how to handle pluralization in different languages.
