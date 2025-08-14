# Internationalization

:::interactive-code
title: Implementing Comprehensive Internationalization
description: This example demonstrates how to implement a robust internationalization system with language detection, user preferences, and dynamic content translation.
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
:::
