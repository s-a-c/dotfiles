# Internationalization (Continued)

:::interactive-code
title: Implementing Comprehensive Internationalization (Part 4)
description: This example concludes the demonstration of a robust internationalization system, focusing on advanced features like translation management and regional content.
language: php
editable: true
code: |
  <?php
  
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
  
  namespace App\Http\Controllers;
  
  use App\Models\Translation;
  use App\Services\LocaleService;
  use Illuminate\Http\Request;
  use Illuminate\Support\Facades\Auth;
  use Illuminate\Support\Facades\File;
  
  class TranslationController extends Controller
  {
      protected $localeService;
      
      public function __construct(LocaleService $localeService)
      {
          $this->localeService = $localeService;
          $this->middleware('auth');
          $this->middleware('can:manage translations');
      }
      
      /**
       * Display a listing of translations.
       *
       * @param  \Illuminate\Http\Request  $request
       * @return \Illuminate\Http\Response
       */
      public function index(Request $request)
      {
          $availableLocales = $this->localeService->getAvailableLocales();
          $defaultLocale = config('app.fallback_locale');
          
          // Get the selected locale
          $selectedLocale = $request->input('locale', array_key_first($availableLocales));
          
          // Get the selected file
          $selectedFile = $request->input('file', 'app');
          
          // Get available translation files
          $availableFiles = $this->getAvailableTranslationFiles();
          
          // Get translations for the selected file and locale
          $translations = $this->getTranslations($selectedFile, $selectedLocale, $defaultLocale);
          
          return view('translations.index', [
              'availableLocales' => $availableLocales,
              'availableFiles' => $availableFiles,
              'selectedLocale' => $selectedLocale,
              'selectedFile' => $selectedFile,
              'defaultLocale' => $defaultLocale,
              'translations' => $translations,
          ]);
      }
      
      /**
       * Update translations.
       *
       * @param  \Illuminate\Http\Request  $request
       * @return \Illuminate\Http\Response
       */
      public function update(Request $request)
      {
          $request->validate([
              'locale' => 'required|string',
              'file' => 'required|string',
              'translations' => 'required|array',
          ]);
          
          $locale = $request->input('locale');
          $file = $request->input('file');
          $translations = $request->input('translations');
          
          // Update the translations
          $this->updateTranslations($file, $locale, $translations);
          
          return redirect()->route('translations.index', [
              'locale' => $locale,
              'file' => $file,
          ])->with('success', __('translations.updated_successfully'));
      }
      
      /**
       * Export translations to a CSV file.
       *
       * @param  \Illuminate\Http\Request  $request
       * @return \Illuminate\Http\Response
       */
      public function export(Request $request)
      {
          $request->validate([
              'locale' => 'required|string',
              'file' => 'required|string',
          ]);
          
          $locale = $request->input('locale');
          $file = $request->input('file');
          $defaultLocale = config('app.fallback_locale');
          
          // Get translations for the selected file and locale
          $translations = $this->getTranslations($file, $locale, $defaultLocale);
          
          // Create CSV content
          $csv = "Key,{$defaultLocale},{$locale}\n";
          
          foreach ($translations as $key => $translation) {
              $defaultValue = str_replace('"', '""', $translation['default']);
              $localeValue = str_replace('"', '""', $translation['value']);
              
              $csv .= "\"{$key}\",\"{$defaultValue}\",\"{$localeValue}\"\n";
          }
          
          // Set headers for download
          $headers = [
              'Content-Type' => 'text/csv',
              'Content-Disposition' => "attachment; filename=\"translations_{$file}_{$locale}.csv\"",
          ];
          
          return response($csv, 200, $headers);
      }
      
      /**
       * Import translations from a CSV file.
       *
       * @param  \Illuminate\Http\Request  $request
       * @return \Illuminate\Http\Response
       */
      public function import(Request $request)
      {
          $request->validate([
              'locale' => 'required|string',
              'file' => 'required|string',
              'csv_file' => 'required|file|mimes:csv,txt',
          ]);
          
          $locale = $request->input('locale');
          $file = $request->input('file');
          
          // Read the CSV file
          $csvFile = $request->file('csv_file');
          $csvData = file_get_contents($csvFile->getRealPath());
          $rows = array_map('str_getcsv', explode("\n", $csvData));
          
          // Remove header row
          array_shift($rows);
          
          // Process the CSV data
          $translations = [];
          
          foreach ($rows as $row) {
              if (count($row) >= 3) {
                  $key = $row[0];
                  $value = $row[2];
                  
                  if (!empty($key)) {
                      $translations[$key] = $value;
                  }
              }
          }
          
          // Update the translations
          $this->updateTranslations($file, $locale, $translations);
          
          return redirect()->route('translations.index', [
              'locale' => $locale,
              'file' => $file,
          ])->with('success', __('translations.imported_successfully'));
      }
      
      /**
       * Get available translation files.
       *
       * @return array
       */
      protected function getAvailableTranslationFiles(): array
      {
          $files = [];
          
          // Check PHP translation files
          $phpPath = resource_path('lang/' . config('app.fallback_locale'));
          if (File::isDirectory($phpPath)) {
              $phpFiles = File::glob("{$phpPath}/*.php");
              
              foreach ($phpFiles as $file) {
                  $name = basename($file, '.php');
                  $files[$name] = $name;
              }
          }
          
          // Add JSON translations
          $files['json'] = 'JSON';
          
          return $files;
      }
      
      /**
       * Get translations for a file and locale.
       *
       * @param  string  $file
       * @param  string  $locale
       * @param  string  $defaultLocale
       * @return array
       */
      protected function getTranslations(string $file, string $locale, string $defaultLocale): array
      {
          $translations = [];
          
          if ($file === 'json') {
              // Get JSON translations
              $defaultJsonPath = resource_path("lang/{$defaultLocale}.json");
              $localeJsonPath = resource_path("lang/{$locale}.json");
              
              $defaultTranslations = [];
              if (File::exists($defaultJsonPath)) {
                  $defaultTranslations = json_decode(File::get($defaultJsonPath), true) ?? [];
              }
              
              $localeTranslations = [];
              if (File::exists($localeJsonPath)) {
                  $localeTranslations = json_decode(File::get($localeJsonPath), true) ?? [];
              }
              
              foreach ($defaultTranslations as $key => $value) {
                  $translations[$key] = [
                      'default' => $value,
                      'value' => $localeTranslations[$key] ?? '',
                  ];
              }
          } else {
              // Get PHP translations
              $defaultPhpPath = resource_path("lang/{$defaultLocale}/{$file}.php");
              $localePhpPath = resource_path("lang/{$locale}/{$file}.php");
              
              $defaultTranslations = [];
              if (File::exists($defaultPhpPath)) {
                  $defaultTranslations = require $defaultPhpPath;
              }
              
              $localeTranslations = [];
              if (File::exists($localePhpPath)) {
                  $localeTranslations = require $localePhpPath;
              }
              
              // Flatten the translations arrays
              $defaultTranslations = $this->flattenArray($defaultTranslations);
              $localeTranslations = $this->flattenArray($localeTranslations);
              
              foreach ($defaultTranslations as $key => $value) {
                  $translations[$key] = [
                      'default' => $value,
                      'value' => $localeTranslations[$key] ?? '',
                  ];
              }
          }
          
          return $translations;
      }
      
      /**
       * Update translations for a file and locale.
       *
       * @param  string  $file
       * @param  string  $locale
       * @param  array  $translations
       * @return void
       */
      protected function updateTranslations(string $file, string $locale, array $translations): void
      {
          if ($file === 'json') {
              // Update JSON translations
              $jsonPath = resource_path("lang/{$locale}.json");
              
              // Create the directory if it doesn't exist
              if (!File::isDirectory(dirname($jsonPath))) {
                  File::makeDirectory(dirname($jsonPath), 0755, true);
              }
              
              // Get existing translations
              $existingTranslations = [];
              if (File::exists($jsonPath)) {
                  $existingTranslations = json_decode(File::get($jsonPath), true) ?? [];
              }
              
              // Update translations
              $updatedTranslations = array_merge($existingTranslations, $translations);
              
              // Sort translations alphabetically
              ksort($updatedTranslations);
              
              // Save the translations
              File::put($jsonPath, json_encode($updatedTranslations, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
          } else {
              // Update PHP translations
              $phpPath = resource_path("lang/{$locale}/{$file}.php");
              
              // Create the directory if it doesn't exist
              if (!File::isDirectory(dirname($phpPath))) {
                  File::makeDirectory(dirname($phpPath), 0755, true);
              }
              
              // Get existing translations
              $existingTranslations = [];
              if (File::exists($phpPath)) {
                  $existingTranslations = require $phpPath;
              }
              
              // Convert flat translations back to nested array
              $nestedTranslations = $this->unflattenArray($translations);
              
              // Merge with existing translations
              $updatedTranslations = array_replace_recursive($existingTranslations, $nestedTranslations);
              
              // Save the translations
              $content = "<?php\n\nreturn " . var_export($updatedTranslations, true) . ";\n";
              File::put($phpPath, $content);
          }
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
       * Convert a flattened array back to a nested array.
       *
       * @param  array  $array
       * @return array
       */
      protected function unflattenArray(array $array): array
      {
          $result = [];
          
          foreach ($array as $key => $value) {
              $keys = explode('.', $key);
              $current = &$result;
              
              foreach ($keys as $i => $k) {
                  if ($i === count($keys) - 1) {
                      $current[$k] = $value;
                  } else {
                      if (!isset($current[$k]) || !is_array($current[$k])) {
                          $current[$k] = [];
                      }
                      
                      $current = &$current[$k];
                  }
              }
          }
          
          return $result;
      }
  }
explanation: |
  This final part of the internationalization example demonstrates advanced features:
  
  1. **Translation Management**: A comprehensive system for managing translations:
     - Viewing and editing translations through a web interface
     - Exporting translations to CSV for external translation
     - Importing translations from CSV after translation
     - Organizing translations by file and locale
  
  2. **Missing Translations Scanner**: A command to scan for missing translations:
     - Finding all translation strings in the application
     - Comparing them with existing translations
     - Adding missing translations automatically
     - Supporting both JSON and PHP translation files
  
  3. **Translation File Handling**: Utilities for working with translation files:
     - Reading and writing JSON translation files
     - Reading and writing PHP translation files
     - Flattening and unflattening nested translation arrays
     - Sorting translations for better organization
  
  4. **Translation Workflow**: Supporting a complete translation workflow:
     - Developers add translation keys in the code
     - The scanner finds missing translations
     - Translators edit translations through the web interface or CSV
     - Translations are automatically applied to the application
  
  Key features of the implementation:
  
  - **Comprehensive Management**: Tools for every aspect of translation management
  - **CSV Import/Export**: Support for working with external translators
  - **Automatic Scanning**: Finding missing translations automatically
  - **Nested Translations**: Support for both flat and nested translation structures
  - **Permission Control**: Restricting translation management to authorized users
  
  In a real Laravel application:
  - You would implement more sophisticated translation management
  - You might integrate with professional translation services
  - You would add support for translation memory and glossaries
  - You would implement translation versioning and history
  - You would add support for translation comments and context
challenges:
  - Implement a translation memory system to reuse existing translations
  - Add support for machine translation suggestions
  - Create a system for translation quality assurance
  - Implement translation versioning and rollback
  - Add support for translation comments and context for translators
:::
