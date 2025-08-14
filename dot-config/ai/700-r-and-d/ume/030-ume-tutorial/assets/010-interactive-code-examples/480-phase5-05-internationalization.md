# Internationalization

:::interactive-code
title: Implementing Comprehensive Internationalization
description: This example demonstrates how to implement a robust internationalization system with language detection, user preferences, dynamic content translation, and translation management.
language: php
editable: true
code: |
  <?php
  
  namespace App\Http\Middleware;
  
  use App\Services\LocaleService;
  use Closure;
  use Illuminate\Http\Request;
  use Illuminate\Support\Facades\App;
  use Illuminate\Support\Facades\Auth;
  use Illuminate\Support\Facades\Session;
  
  class SetLocale
  {
      protected $localeService;
      
      public function __construct(LocaleService $localeService)
      {
          $this->localeService = $localeService;
      }
      
      /**
       * Handle an incoming request.
       *
       * @param  \Illuminate\Http\Request  $request
       * @param  \Closure  $next
       * @return mixed
       */
      public function handle(Request $request, Closure $next)
      {
          // Priority order for locale determination:
          // 1. URL parameter (e.g., ?locale=fr)
          // 2. User preference (if authenticated)
          // 3. Session
          // 4. Browser preference
          // 5. Default locale
          
          $locale = $this->determineLocale($request);
          
          // Set the application locale
          App::setLocale($locale);
          
          // Store the locale in session for future requests
          Session::put('locale', $locale);
          
          // Set locale for Carbon dates
          if (class_exists('Carbon\Carbon')) {
              \Carbon\Carbon::setLocale($locale);
          }
          
          // Set locale for JavaScript (via a cookie)
          if (!$request->cookie('locale') || $request->cookie('locale') !== $locale) {
              $response = $next($request);
              return $response->withCookie(cookie()->forever('locale', $locale));
          }
          
          return $next($request);
      }
      
      /**
       * Determine the locale for the current request.
       *
       * @param  \Illuminate\Http\Request  $request
       * @return string
       */
      protected function determineLocale(Request $request): string
      {
          // Check URL parameter
          $localeParam = $request->query('locale');
          if ($localeParam && $this->localeService->isValidLocale($localeParam)) {
              return $localeParam;
          }
          
          // Check user preference
          if (Auth::check() && Auth::user()->locale) {
              return Auth::user()->locale;
          }
          
          // Check session
          $sessionLocale = Session::get('locale');
          if ($sessionLocale && $this->localeService->isValidLocale($sessionLocale)) {
              return $sessionLocale;
          }
          
          // Check browser preference
          $browserLocale = $this->localeService->getBrowserLocale($request);
          if ($browserLocale) {
              return $browserLocale;
          }
          
          // Default locale
          return config('app.locale');
      }
  }
  
  namespace App\Services;
  
  use Illuminate\Http\Request;
  use Illuminate\Support\Facades\Cache;
  use Illuminate\Support\Facades\File;
  
  class LocaleService
  {
      /**
       * Get all available locales.
       *
       * @return array
       */
      public function getAvailableLocales(): array
      {
          return Cache::remember('available_locales', 3600, function () {
              $locales = [];
              
              // Get locales from language files
              $langPath = resource_path('lang');
              
              if (File::exists($langPath)) {
                  $directories = File::directories($langPath);
                  
                  foreach ($directories as $directory) {
                      $locale = basename($directory);
                      $locales[$locale] = $this->getLocaleNativeName($locale);
                  }
              }
              
              // Get locales from JSON files (Laravel 5.4+)
              $jsonFiles = File::glob(resource_path('lang') . '/*.json');
              
              foreach ($jsonFiles as $file) {
                  $locale = pathinfo($file, PATHINFO_FILENAME);
                  if (!isset($locales[$locale])) {
                      $locales[$locale] = $this->getLocaleNativeName($locale);
                  }
              }
              
              return $locales;
          });
      }
      
      /**
       * Check if a locale is valid.
       *
       * @param  string  $locale
       * @return bool
       */
      public function isValidLocale(string $locale): bool
      {
          $availableLocales = $this->getAvailableLocales();
          return isset($availableLocales[$locale]);
      }
      
      /**
       * Get the browser's preferred locale.
       *
       * @param  \Illuminate\Http\Request  $request
       * @return string|null
       */
      public function getBrowserLocale(Request $request): ?string
      {
          $languages = $request->getLanguages();
          $availableLocales = $this->getAvailableLocales();
          
          foreach ($languages as $language) {
              // Extract the language code (e.g., 'en-US' -> 'en')
              $locale = strtolower(substr($language, 0, 2));
              
              if (isset($availableLocales[$locale])) {
                  return $locale;
              }
          }
          
          return null;
      }
      
      /**
       * Get the native name of a locale.
       *
       * @param  string  $locale
       * @return string
       */
      public function getLocaleNativeName(string $locale): string
      {
          $localeNames = [
              'ar' => 'العربية',
              'bn' => 'বাংলা',
              'de' => 'Deutsch',
              'en' => 'English',
              'es' => 'Español',
              'fr' => 'Français',
              'hi' => 'हिन्दी',
              'it' => 'Italiano',
              'ja' => '日本語',
              'ko' => '한국어',
              'nl' => 'Nederlands',
              'pt' => 'Português',
              'ru' => 'Русский',
              'tr' => 'Türkçe',
              'zh' => '中文',
          ];
          
          return $localeNames[$locale] ?? $locale;
      }
      
      /**
       * Get the text direction for a locale.
       *
       * @param  string  $locale
       * @return string
       */
      public function getTextDirection(string $locale): string
      {
          $rtlLocales = ['ar', 'fa', 'he', 'ur'];
          
          return in_array($locale, $rtlLocales) ? 'rtl' : 'ltr';
      }
      
      /**
       * Get the locale's region.
       *
       * @param  string  $locale
       * @return string|null
       */
      public function getLocaleRegion(string $locale): ?string
      {
          $localeToRegion = [
              'ar' => 'ME', // Middle East
              'bn' => 'AS', // Asia
              'de' => 'EU', // Europe
              'en' => 'NA', // North America (default)
              'es' => 'EU', // Europe (Spain)
              'fr' => 'EU', // Europe
              'hi' => 'AS', // Asia
              'it' => 'EU', // Europe
              'ja' => 'AS', // Asia
              'ko' => 'AS', // Asia
              'nl' => 'EU', // Europe
              'pt' => 'EU', // Europe (Portugal)
              'ru' => 'EU', // Europe
              'tr' => 'EU', // Europe
              'zh' => 'AS', // Asia
          ];
          
          return $localeToRegion[$locale] ?? null;
      }
  }
  
  namespace App\Models;
  
  use Illuminate\Database\Eloquent\Model;
  use Illuminate\Database\Eloquent\Relations\MorphTo;
  
  class Translation extends Model
  {
      protected $fillable = [
          'translatable_type',
          'translatable_id',
          'locale',
          'field',
          'value',
      ];
      
      /**
       * Get the translatable model.
       */
      public function translatable(): MorphTo
      {
          return $this->morphTo();
      }
      
      /**
       * Scope a query to only include translations for a specific locale.
       */
      public function scopeForLocale($query, string $locale)
      {
          return $query->where('locale', $locale);
      }
      
      /**
       * Scope a query to only include translations for a specific field.
       */
      public function scopeForField($query, string $field)
      {
          return $query->where('field', $field);
      }
  }
  
  namespace App\Traits;
  
  use App\Models\Translation;
  use Illuminate\Database\Eloquent\Relations\MorphMany;
  use Illuminate\Support\Facades\App;
  
  trait Translatable
  {
      /**
       * Get all translations for this model.
       */
      public function translations(): MorphMany
      {
          return $this->morphMany(Translation::class, 'translatable');
      }
      
      /**
       * Get the specified field in the specified locale.
       *
       * @param  string  $field
       * @param  string|null  $locale
       * @return mixed
       */
      public function translate(string $field, ?string $locale = null)
      {
          $locale = $locale ?: App::getLocale();
          $fallbackLocale = config('app.fallback_locale');
          
          // If the requested locale is the default locale, return the original value
          if ($locale === $fallbackLocale) {
              return $this->getAttribute($field);
          }
          
          // Get the translation for the requested locale
          $translation = $this->translations()
              ->forLocale($locale)
              ->forField($field)
              ->first();
          
          // If a translation exists, return it
          if ($translation) {
              return $translation->value;
          }
          
          // If no translation exists and the locale is not the fallback locale,
          // try to get the translation in the fallback locale
          if ($locale !== $fallbackLocale) {
              $fallbackTranslation = $this->translations()
                  ->forLocale($fallbackLocale)
                  ->forField($field)
                  ->first();
              
              if ($fallbackTranslation) {
                  return $fallbackTranslation->value;
              }
          }
          
          // If no translation exists in any locale, return the original value
          return $this->getAttribute($field);
      }
      
      /**
       * Set a translation for the specified field in the specified locale.
       *
       * @param  string  $field
       * @param  string  $value
       * @param  string|null  $locale
       * @return $this
       */
      public function setTranslation(string $field, string $value, ?string $locale = null)
      {
          $locale = $locale ?: App::getLocale();
          
          // If the locale is the default locale, update the original field
          if ($locale === config('app.fallback_locale')) {
              $this->setAttribute($field, $value);
              return $this;
          }
          
          // Find or create the translation
          $translation = $this->translations()
              ->forLocale($locale)
              ->forField($field)
              ->first();
          
          if ($translation) {
              $translation->update(['value' => $value]);
          } else {
              $this->translations()->create([
                  'locale' => $locale,
                  'field' => $field,
                  'value' => $value,
              ]);
          }
          
          return $this;
      }
      
      /**
       * Get all available translations for the specified field.
       *
       * @param  string  $field
       * @return array
       */
      public function getTranslations(string $field): array
      {
          $translations = $this->translations()
              ->forField($field)
              ->get()
              ->mapWithKeys(function ($translation) {
                  return [$translation->locale => $translation->value];
              })
              ->toArray();
          
          // Add the default value
          $translations[config('app.fallback_locale')] = $this->getAttribute($field);
          
          return $translations;
      }
      
      /**
       * Delete all translations for the specified field.
       *
       * @param  string  $field
       * @param  string|null  $locale
       * @return $this
       */
      public function deleteTranslations(string $field, ?string $locale = null)
      {
          $query = $this->translations()->forField($field);
          
          if ($locale) {
              $query->forLocale($locale);
          }
          
          $query->delete();
          
          return $this;
      }
      
      /**
       * Get the translatable fields for this model.
       *
       * @return array
       */
      public function getTranslatableFields(): array
      {
          return $this->translatableFields ?? [];
      }
      
      /**
       * Check if a field is translatable.
       *
       * @param  string  $field
       * @return bool
       */
      public function isTranslatable(string $field): bool
      {
          return in_array($field, $this->getTranslatableFields());
      }
      
      /**
       * Boot the trait.
       *
       * @return void
       */
      public static function bootTranslatable()
      {
          // Delete translations when the model is deleted
          static::deleting(function ($model) {
              if (method_exists($model, 'isForceDeleting') && !$model->isForceDeleting()) {
                  return;
              }
              
              $model->translations()->delete();
          });
      }
  }
  
  namespace App\Models;
  
  use App\Traits\Translatable;
  use Illuminate\Database\Eloquent\Model;
  
  class Product extends Model
  {
      use Translatable;
      
      protected $fillable = [
          'name',
          'description',
          'price',
          'category_id',
          'is_active',
      ];
      
      protected $translatableFields = [
          'name',
          'description',
      ];
      
      /**
       * Get the product's name in the current locale.
       *
       * @return string
       */
      public function getLocalizedNameAttribute(): string
      {
          return $this->translate('name');
      }
      
      /**
       * Get the product's description in the current locale.
       *
       * @return string
       */
      public function getLocalizedDescriptionAttribute(): string
      {
          return $this->translate('description');
      }
  }
  
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
  
  namespace App\Console\Commands;
  
  use App\Services\LocaleService;
  use Illuminate\Console\Command;
  use Illuminate\Support\Facades\File;
  
  class ScanMissingTranslations extends Command
  {
      /**
       * The name and signature of the console command.
       *
       * @var string
       */
      protected $signature = 'translations:scan {--locale=all : The locale to scan for missing translations}';
      
      /**
       * The console command description.
       *
       * @var string
       */
      protected $description = 'Scan the application for missing translations';
      
      /**
       * The locale service instance.
       *
       * @var \App\Services\LocaleService
       */
      protected $localeService;
      
      /**
       * Create a new command instance.
       *
       * @param  \App\Services\LocaleService  $localeService
       * @return void
       */
      public function __construct(LocaleService $localeService)
      {
          parent::__construct();
          $this->localeService = $localeService;
      }
      
      /**
       * Execute the console command.
       *
       * @return int
       */
      public function handle()
      {
          $localeOption = $this->option('locale');
          $defaultLocale = config('app.fallback_locale');
          
          // Get all available locales
          $availableLocales = $this->localeService->getAvailableLocales();
          
          // Determine which locales to scan
          $localesToScan = $localeOption === 'all'
              ? array_keys($availableLocales)
              : [$localeOption];
          
          // Remove the default locale from the list
          $localesToScan = array_filter($localesToScan, function ($locale) use ($defaultLocale) {
              return $locale !== $defaultLocale;
          });
          
          if (empty($localesToScan)) {
              $this->error('No locales to scan.');
              return Command::FAILURE;
          }
          
          // Scan for translation strings in the application
          $this->info('Scanning for translation strings...');
          $translationStrings = $this->scanForTranslationStrings();
          $this->info('Found ' . count($translationStrings) . ' unique translation strings.');
          
          // Check each locale for missing translations
          foreach ($localesToScan as $locale) {
              $this->info("Checking locale: {$locale}");
              
              // Get existing translations for this locale
              $existingTranslations = $this->getExistingTranslations($locale);
              
              // Find missing translations
              $missingTranslations = array_diff_key($translationStrings, $existingTranslations);
              
              if (empty($missingTranslations)) {
                  $this->info("No missing translations for {$locale}.");
                  continue;
              }
              
              $this->info("Found " . count($missingTranslations) . " missing translations for {$locale}.");
              
              // Ask if we should add the missing translations
              if ($this->confirm("Do you want to add the missing translations for {$locale}?")) {
                  $this->addMissingTranslations($locale, $missingTranslations);
                  $this->info("Added missing translations for {$locale}.");
              }
          }
          
          return Command::SUCCESS;
      }
      
      /**
       * Scan the application for translation strings.
       *
       * @return array
       */
      protected function scanForTranslationStrings(): array
      {
          $strings = [];
          
          // Directories to scan
          $directories = [
              app_path(),
              resource_path('views'),
          ];
          
          // File patterns to scan
          $patterns = [
              '*.php',
              '*.blade.php',
          ];
          
          // Regular expressions to match translation functions
          $regexes = [
              '/__\([\'"](.+?)[\'"](,|\))/', // __('key') or __("key")
              '/trans\([\'"](.+?)[\'"](,|\))/', // trans('key') or trans("key")
              '/@lang\([\'"](.+?)[\'"]\)/', // @lang('key') or @lang("key")
              '/Lang::get\([\'"](.+?)[\'"](,|\))/', // Lang::get('key') or Lang::get("key")
              '/trans_choice\([\'"](.+?)[\'"](,|\))/', // trans_choice('key') or trans_choice("key")
          ];
          
          // Scan each directory
          foreach ($directories as $directory) {
              foreach ($patterns as $pattern) {
                  $files = File::glob("{$directory}/**/{$pattern}");
                  
                  foreach ($files as $file) {
                      $content = File::get($file);
                      
                      // Apply each regex to find translation strings
                      foreach ($regexes as $regex) {
                          if (preg_match_all($regex, $content, $matches)) {
                              foreach ($matches[1] as $key) {
                                  $strings[$key] = $key;
                              }
                          }
                      }
                  }
              }
          }
          
          return $strings;
      }
      
      /**
       * Get existing translations for a locale.
       *
       * @param  string  $locale
       * @return array
       */
      protected function getExistingTranslations(string $locale): array
      {
          $translations = [];
          
          // Check JSON translations
          $jsonPath = resource_path("lang/{$locale}.json");
          if (File::exists($jsonPath)) {
              $jsonTranslations = json_decode(File::get($jsonPath), true);
              if (is_array($jsonTranslations)) {
                  $translations = array_merge($translations, $jsonTranslations);
              }
          }
          
          // Check PHP translations
          $phpPath = resource_path("lang/{$locale}");
          if (File::isDirectory($phpPath)) {
              $phpFiles = File::glob("{$phpPath}/*.php");
              
              foreach ($phpFiles as $file) {
                  $fileTranslations = require $file;
                  $prefix = basename($file, '.php') . '.';
                  
                  // Flatten the translations array
                  $flattenedTranslations = $this->flattenArray($fileTranslations, $prefix);
                  $translations = array_merge($translations, $flattenedTranslations);
              }
          }
          
          return $translations;
      }
      
      /**
       * Flatten a multi-dimensional array with dot notation.
       *
       * @param  array  $array
       * @param  string  $prefix
       * @return array
       */
      protected function flattenArray(array $array, string $prefix = ''): array
      {
          $result = [];
          
          foreach ($array as $key => $value) {
              if (is_array($value)) {
                  $result = array_merge($result, $this->flattenArray($value, $prefix . $key . '.'));
              } else {
                  $result[$prefix . $key] = $value;
              }
          }
          
          return $result;
      }
      
      /**
       * Add missing translations for a locale.
       *
       * @param  string  $locale
       * @param  array  $missingTranslations
       * @return void
       */
      protected function addMissingTranslations(string $locale, array $missingTranslations): void
      {
          // Path to the JSON translation file
          $jsonPath = resource_path("lang/{$locale}.json");
          
          // Create the directory if it doesn't exist
          if (!File::isDirectory(dirname($jsonPath))) {
              File::makeDirectory(dirname($jsonPath), 0755, true);
          }
          
          // Get existing translations
          $translations = [];
          if (File::exists($jsonPath)) {
              $translations = json_decode(File::get($jsonPath), true) ?? [];
          }
          
          // Add missing translations
          foreach ($missingTranslations as $key => $value) {
              // For demonstration, we'll just use the key as the value
              // In a real app, you might want to use a translation API or prompt for input
              $translations[$key] = $key;
          }
          
          // Sort translations alphabetically
          ksort($translations);
          
          // Save the translations
          File::put($jsonPath, json_encode($translations, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
      }
  }
  
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
  
  5. **Missing Translations Scanner**: A command to scan for missing translations:
     - Finding all translation strings in the application
     - Comparing them with existing translations
     - Adding missing translations automatically
     - Supporting both JSON and PHP translation files
  
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
  - **Automatic Scanning**: Finding missing translations automatically
  - **Translation Workflow**: Supporting a complete translation workflow
  
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
