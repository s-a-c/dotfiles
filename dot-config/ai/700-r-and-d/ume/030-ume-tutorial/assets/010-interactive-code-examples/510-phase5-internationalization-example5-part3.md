# Internationalization (Continued)

:::interactive-code
title: Implementing Comprehensive Internationalization (Part 3)
description: This example continues the demonstration of a robust internationalization system, focusing on controllers, views, and JavaScript integration.
language: php
editable: true
code: |
  <?php
  
  namespace App\Http\Controllers;
  
  use App\Models\Product;
  use App\Services\LocaleService;
  use Illuminate\Http\Request;
  use Illuminate\Support\Facades\App;
  use Illuminate\Support\Facades\Auth;
  
  class LocaleController extends Controller
  {
      protected $localeService;
      
      public function __construct(LocaleService $localeService)
      {
          $this->localeService = $localeService;
      }
      
      /**
       * Change the application locale.
       *
       * @param  \Illuminate\Http\Request  $request
       * @param  string  $locale
       * @return \Illuminate\Http\Response
       */
      public function changeLocale(Request $request, string $locale)
      {
          // Validate the locale
          if (!$this->localeService->isValidLocale($locale)) {
              return redirect()->back()->with('error', 'Invalid locale.');
          }
          
          // Update the user's locale preference if authenticated
          if (Auth::check()) {
              $user = Auth::user();
              $user->locale = $locale;
              $user->save();
          }
          
          // Store the locale in the session
          session(['locale' => $locale]);
          
          // Redirect back with a success message
          return redirect()->back()->with('success', __('locale.changed_successfully'));
      }
      
      /**
       * Display the language selector.
       *
       * @return \Illuminate\Http\Response
       */
      public function selector()
      {
          $availableLocales = $this->localeService->getAvailableLocales();
          $currentLocale = App::getLocale();
          
          return view('locale.selector', [
              'availableLocales' => $availableLocales,
              'currentLocale' => $currentLocale,
          ]);
      }
  }
  
  namespace App\Http\Controllers;
  
  use App\Models\Product;
  use App\Services\LocaleService;
  use Illuminate\Http\Request;
  use Illuminate\Support\Facades\App;
  
  class ProductController extends Controller
  {
      protected $localeService;
      
      public function __construct(LocaleService $localeService)
      {
          $this->localeService = $localeService;
          $this->middleware('auth')->except(['index', 'show']);
      }
      
      /**
       * Display a listing of products.
       *
       * @return \Illuminate\Http\Response
       */
      public function index()
      {
          $products = Product::where('is_active', true)->get();
          
          return view('products.index', [
              'products' => $products,
          ]);
      }
      
      /**
       * Display the specified product.
       *
       * @param  \App\Models\Product  $product
       * @return \Illuminate\Http\Response
       */
      public function show(Product $product)
      {
          return view('products.show', [
              'product' => $product,
          ]);
      }
      
      /**
       * Show the form for editing the specified product.
       *
       * @param  \App\Models\Product  $product
       * @return \Illuminate\Http\Response
       */
      public function edit(Product $product)
      {
          $availableLocales = $this->localeService->getAvailableLocales();
          
          return view('products.edit', [
              'product' => $product,
              'availableLocales' => $availableLocales,
          ]);
      }
      
      /**
       * Update the specified product.
       *
       * @param  \Illuminate\Http\Request  $request
       * @param  \App\Models\Product  $product
       * @return \Illuminate\Http\Response
       */
      public function update(Request $request, Product $product)
      {
          $request->validate([
              'name' => 'required|string|max:255',
              'description' => 'required|string',
              'price' => 'required|numeric|min:0',
              'category_id' => 'required|exists:categories,id',
              'is_active' => 'boolean',
              'translations' => 'array',
          ]);
          
          // Update the base product (in the default locale)
          $product->update($request->except('translations'));
          
          // Update translations
          if ($request->has('translations')) {
              foreach ($request->input('translations') as $locale => $fields) {
                  foreach ($fields as $field => $value) {
                      if ($product->isTranslatable($field)) {
                          $product->setTranslation($field, $value, $locale);
                      }
                  }
              }
          }
          
          return redirect()->route('products.show', $product)
              ->with('success', __('product.updated_successfully'));
      }
  }
  
  // Example Blade view for product editing (products/edit.blade.php)
  
  /*
  @extends('layouts.app')
  
  @section('content')
      <div class="container">
          <h1>{{ __('product.edit_product') }}</h1>
          
          <form action="{{ route('products.update', $product) }}" method="POST">
              @csrf
              @method('PUT')
              
              <div class="card mb-4">
                  <div class="card-header">
                      <h2>{{ __('product.base_information') }}</h2>
                      <small>{{ __('product.base_information_description') }}</small>
                  </div>
                  <div class="card-body">
                      <div class="form-group">
                          <label for="name">{{ __('product.name') }}</label>
                          <input type="text" class="form-control" id="name" name="name" value="{{ old('name', $product->name) }}" required>
                      </div>
                      
                      <div class="form-group">
                          <label for="description">{{ __('product.description') }}</label>
                          <textarea class="form-control" id="description" name="description" rows="3" required>{{ old('description', $product->description) }}</textarea>
                      </div>
                      
                      <div class="form-group">
                          <label for="price">{{ __('product.price') }}</label>
                          <input type="number" class="form-control" id="price" name="price" value="{{ old('price', $product->price) }}" step="0.01" min="0" required>
                      </div>
                      
                      <div class="form-group">
                          <label for="category_id">{{ __('product.category') }}</label>
                          <select class="form-control" id="category_id" name="category_id" required>
                              @foreach($categories as $category)
                                  <option value="{{ $category->id }}" {{ old('category_id', $product->category_id) == $category->id ? 'selected' : '' }}>
                                      {{ $category->name }}
                                  </option>
                              @endforeach
                          </select>
                      </div>
                      
                      <div class="form-check">
                          <input type="checkbox" class="form-check-input" id="is_active" name="is_active" value="1" {{ old('is_active', $product->is_active) ? 'checked' : '' }}>
                          <label class="form-check-label" for="is_active">{{ __('product.is_active') }}</label>
                      </div>
                  </div>
              </div>
              
              <div class="card mb-4">
                  <div class="card-header">
                      <h2>{{ __('product.translations') }}</h2>
                      <small>{{ __('product.translations_description') }}</small>
                  </div>
                  <div class="card-body">
                      <ul class="nav nav-tabs" id="translationTabs" role="tablist">
                          @foreach($availableLocales as $locale => $localeName)
                              @if($locale != config('app.fallback_locale'))
                                  <li class="nav-item">
                                      <a class="nav-link {{ $loop->first ? 'active' : '' }}" id="{{ $locale }}-tab" data-toggle="tab" href="#{{ $locale }}" role="tab" aria-controls="{{ $locale }}" aria-selected="{{ $loop->first ? 'true' : 'false' }}">
                                          {{ $localeName }}
                                      </a>
                                  </li>
                              @endif
                          @endforeach
                      </ul>
                      
                      <div class="tab-content mt-3" id="translationTabsContent">
                          @foreach($availableLocales as $locale => $localeName)
                              @if($locale != config('app.fallback_locale'))
                                  <div class="tab-pane fade {{ $loop->first ? 'show active' : '' }}" id="{{ $locale }}" role="tabpanel" aria-labelledby="{{ $locale }}-tab">
                                      <div class="form-group">
                                          <label for="{{ $locale }}_name">{{ __('product.name') }}</label>
                                          <input type="text" class="form-control" id="{{ $locale }}_name" name="translations[{{ $locale }}][name]" value="{{ old("translations.$locale.name", $product->translate('name', $locale)) }}">
                                      </div>
                                      
                                      <div class="form-group">
                                          <label for="{{ $locale }}_description">{{ __('product.description') }}</label>
                                          <textarea class="form-control" id="{{ $locale }}_description" name="translations[{{ $locale }}][description]" rows="3">{{ old("translations.$locale.description", $product->translate('description', $locale)) }}</textarea>
                                      </div>
                                  </div>
                              @endif
                          @endforeach
                      </div>
                  </div>
              </div>
              
              <button type="submit" class="btn btn-primary">{{ __('common.save') }}</button>
              <a href="{{ route('products.show', $product) }}" class="btn btn-secondary">{{ __('common.cancel') }}</a>
          </form>
      </div>
  @endsection
  */
  
  // Example JavaScript for handling internationalization on the client side
  
  /*
  // app.js
  
  // Get the current locale from the cookie or HTML lang attribute
  const locale = document.cookie.split('; ').find(row => row.startsWith('locale='))
      ? document.cookie.split('; ').find(row => row.startsWith('locale=')).split('=')[1]
      : document.documentElement.lang;
  
  // Import the appropriate locale file
  import(`./lang/${locale}.js`).then(module => {
      // Set up the translation function
      window.__ = function(key, replacements = {}) {
          let translation = module.default[key] || key;
          
          // Replace placeholders
          Object.keys(replacements).forEach(placeholder => {
              translation = translation.replace(`:${placeholder}`, replacements[placeholder]);
          });
          
          return translation;
      };
      
      // Initialize components that need translations
      initializeComponents();
  }).catch(() => {
      // Fallback if the locale file couldn't be loaded
      window.__ = function(key) {
          return key;
      };
      
      initializeComponents();
  });
  
  // Initialize components that need translations
  function initializeComponents() {
      // Example: Initialize date formatting
      document.querySelectorAll('[data-format-date]').forEach(element => {
          const date = new Date(element.getAttribute('data-date'));
          element.textContent = formatDate(date, locale);
      });
      
      // Example: Initialize currency formatting
      document.querySelectorAll('[data-format-currency]').forEach(element => {
          const amount = parseFloat(element.getAttribute('data-amount'));
          element.textContent = formatCurrency(amount, locale);
      });
  }
  
  // Format a date according to the locale
  function formatDate(date, locale) {
      return new Intl.DateTimeFormat(locale, {
          year: 'numeric',
          month: 'long',
          day: 'numeric'
      }).format(date);
  }
  
  // Format a currency amount according to the locale
  function formatCurrency(amount, locale) {
      const currency = document.documentElement.getAttribute('data-currency') || 'USD';
      
      return new Intl.NumberFormat(locale, {
          style: 'currency',
          currency: currency
      }).format(amount);
  }
  */
explanation: |
  This example demonstrates a comprehensive internationalization system:
  
  1. **Locale Middleware**: A middleware that determines and sets the application locale:
     - Checking URL parameters, user preferences, session, and browser settings
     - Setting the locale for the application, Carbon dates, and JavaScript
     - Storing the locale in session and cookies for persistence
  
  2. **Locale Service**: A service that manages locale-related functionality:
     - Getting available locales from language files
     - Validating locales
     - Detecting browser locales
     - Providing locale metadata (native names, text direction, region)
  
  3. **Translatable Models**: A trait that adds translation capabilities to models:
     - Storing translations in a dedicated table
     - Retrieving translations with fallback support
     - Setting and deleting translations
     - Defining which fields are translatable
  
  4. **Controllers**: Controllers that handle locale-related actions:
     - Changing the application locale
     - Displaying a language selector
     - Managing translatable content
  
  5. **Views**: Blade views that support internationalization:
     - Using translation helpers for static text
     - Displaying and editing content in multiple languages
     - Organizing translations in tabs for better user experience
  
  6. **JavaScript Integration**: Client-side support for internationalization:
     - Loading locale-specific JavaScript files
     - Providing a translation function similar to Laravel's
     - Formatting dates and currencies according to the locale
  
  Key features of the implementation:
  
  - **Flexible Locale Detection**: Multiple sources for determining the user's preferred locale
  - **User Preferences**: Storing and respecting user language preferences
  - **Content Translation**: Translating dynamic content stored in the database
  - **Fallback Support**: Using fallback locales when translations are missing
  - **RTL Support**: Handling right-to-left languages
  - **Locale Metadata**: Providing additional information about locales
  
  In a real Laravel application:
  - You would implement more sophisticated translation management
  - You might add translation caching for better performance
  - You would implement translation import/export for working with translators
  - You would add support for pluralization and gender-specific translations
  - You would implement region-specific formatting for dates, numbers, and currencies
challenges:
  - Implement a translation management interface for non-technical users
  - Add support for automatic translation using a translation API
  - Create a system for tracking missing translations
  - Implement locale-specific validation rules
  - Add support for translating Eloquent model attributes and validation messages
:::
