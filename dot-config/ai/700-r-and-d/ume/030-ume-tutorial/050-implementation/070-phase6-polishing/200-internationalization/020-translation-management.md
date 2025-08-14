# Translation Management

<link rel="stylesheet" href="../../../../assets/css/styles.css">

## Goal

Learn how to effectively manage translations in your Laravel application, including adding, updating, and organizing translation strings.

## Prerequisites

- Completed the [Setting Up Internationalization](./010-setting-up-i18n.md) guide
- Basic understanding of Laravel's translation system

## Implementation Steps

### Step 1: Organize Translation Files

Organize your translation files by context to make them easier to manage:

```
resources/lang/
    en/
        auth.php         # Authentication-related translations
        messages.php     # General messages
        navigation.php   # Navigation items
        profile.php      # Profile-related translations
        teams.php        # Team-related translations
        validation.php   # Validation messages
    es/
        auth.php
        messages.php
        navigation.php
        profile.php
        teams.php
        validation.php
    // Other languages...
```

Example of a well-organized translation file:

```php
// resources/lang/en/profile.php
return [
    'title' => 'User Profile',
    'personal_info' => [
        'title' => 'Personal Information',
        'name' => 'Name',
        'email' => 'Email Address',
        'phone' => 'Phone Number',
    ],
    'security' => [
        'title' => 'Security',
        'password' => 'Password',
        'two_factor' => 'Two-Factor Authentication',
    ],
    'preferences' => [
        'title' => 'Preferences',
        'language' => 'Language',
        'notifications' => 'Notifications',
        'theme' => 'Theme',
    ],
    'actions' => [
        'save' => 'Save Changes',
        'cancel' => 'Cancel',
        'delete' => 'Delete Account',
    ],
];
```

### Step 2: Use JSON Translation Files for Simple Strings

For simple strings, you can use JSON translation files:

```json
// resources/lang/es.json
{
    "Welcome to our application": "Bienvenido a nuestra aplicación",
    "Log in": "Iniciar sesión",
    "Register": "Registrarse",
    "Log out": "Cerrar sesión",
    "Profile": "Perfil",
    "Settings": "Configuración",
    "Dashboard": "Tablero"
}
```

Using JSON translations in your views:

```php
<h1>{{ __('Welcome to our application') }}</h1>
```

### Step 3: Implement Database-Driven Translations (Optional)

If you installed the `spatie/laravel-translation-loader` package, you can store translations in the database:

#### Create a Translation Management Interface

Create a controller for managing translations:

```bash
php artisan make:controller TranslationController
```

Edit the controller:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Spatie\TranslationLoader\LanguageLine;

class TranslationController extends Controller
{
    public function index()
    {
        $translations = LanguageLine::all();
        
        return view('admin.translations.index', [
            'translations' => $translations,
        ]);
    }
    
    public function create()
    {
        return view('admin.translations.create');
    }
    
    public function store(Request $request)
    {
        $validated = $request->validate([
            'group' => 'required|string',
            'key' => 'required|string',
            'text' => 'required|array',
        ]);
        
        LanguageLine::create([
            'group' => $validated['group'],
            'key' => $validated['key'],
            'text' => $validated['text'],
        ]);
        
        return redirect()->route('admin.translations.index')
            ->with('success', 'Translation created successfully.');
    }
    
    public function edit(LanguageLine $translation)
    {
        return view('admin.translations.edit', [
            'translation' => $translation,
        ]);
    }
    
    public function update(Request $request, LanguageLine $translation)
    {
        $validated = $request->validate([
            'text' => 'required|array',
        ]);
        
        $translation->update([
            'text' => $validated['text'],
        ]);
        
        return redirect()->route('admin.translations.index')
            ->with('success', 'Translation updated successfully.');
    }
    
    public function destroy(LanguageLine $translation)
    {
        $translation->delete();
        
        return redirect()->route('admin.translations.index')
            ->with('success', 'Translation deleted successfully.');
    }
}
```

Create the views for managing translations:

```php
<!-- resources/views/admin/translations/index.blade.php -->
<x-app-layout>
    <x-slot name="header">
        <h2 class="text-xl font-semibold leading-tight text-gray-800">
            {{ __('Translations') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="mx-auto max-w-7xl sm:px-6 lg:px-8">
            <div class="overflow-hidden bg-white shadow-xl sm:rounded-lg">
                <div class="p-6">
                    <div class="mb-4">
                        <a href="{{ route('admin.translations.create') }}" class="inline-flex items-center px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition bg-gray-800 border border-transparent rounded-md hover:bg-gray-700">
                            {{ __('Add Translation') }}
                        </a>
                    </div>

                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th scope="col" class="px-6 py-3 text-xs font-medium tracking-wider text-left text-gray-500 uppercase">
                                    {{ __('Group') }}
                                </th>
                                <th scope="col" class="px-6 py-3 text-xs font-medium tracking-wider text-left text-gray-500 uppercase">
                                    {{ __('Key') }}
                                </th>
                                <th scope="col" class="px-6 py-3 text-xs font-medium tracking-wider text-left text-gray-500 uppercase">
                                    {{ __('Text') }}
                                </th>
                                <th scope="col" class="px-6 py-3 text-xs font-medium tracking-wider text-left text-gray-500 uppercase">
                                    {{ __('Actions') }}
                                </th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            @foreach($translations as $translation)
                                <tr>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        {{ $translation->group }}
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        {{ $translation->key }}
                                    </td>
                                    <td class="px-6 py-4">
                                        @foreach($translation->text as $locale => $text)
                                            <div class="mb-1">
                                                <span class="font-semibold">{{ strtoupper($locale) }}:</span> {{ $text }}
                                            </div>
                                        @endforeach
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <a href="{{ route('admin.translations.edit', $translation) }}" class="text-indigo-600 hover:text-indigo-900">
                                            {{ __('Edit') }}
                                        </a>
                                        <form action="{{ route('admin.translations.destroy', $translation) }}" method="POST" class="inline ml-2">
                                            @csrf
                                            @method('DELETE')
                                            <button type="submit" class="text-red-600 hover:text-red-900" onclick="return confirm('Are you sure you want to delete this translation?')">
                                                {{ __('Delete') }}
                                            </button>
                                        </form>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
```

Add routes for the translation management interface:

```php
// routes/web.php
Route::middleware(['auth', 'admin'])->prefix('admin')->name('admin.')->group(function () {
    Route::resource('translations', TranslationController::class);
});
```

### Step 4: Implement Translation Import/Export

Create commands for importing and exporting translations:

```bash
php artisan make:command TranslationExport
php artisan make:command TranslationImport
```

Edit the export command:

```php
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Spatie\TranslationLoader\LanguageLine;

class TranslationExport extends Command
{
    protected $signature = 'translations:export {--format=csv : The export format (csv or json)}';
    protected $description = 'Export translations to CSV or JSON';

    public function handle()
    {
        $format = $this->option('format');
        $translations = LanguageLine::all();
        
        if ($format === 'csv') {
            $this->exportToCsv($translations);
        } elseif ($format === 'json') {
            $this->exportToJson($translations);
        } else {
            $this->error("Unsupported format: {$format}");
            return 1;
        }
        
        return 0;
    }
    
    protected function exportToCsv($translations)
    {
        $path = storage_path('app/translations.csv');
        $file = fopen($path, 'w');
        
        // Write header
        fputcsv($file, ['Group', 'Key', 'Locale', 'Text']);
        
        // Write data
        foreach ($translations as $translation) {
            foreach ($translation->text as $locale => $text) {
                fputcsv($file, [
                    $translation->group,
                    $translation->key,
                    $locale,
                    $text,
                ]);
            }
        }
        
        fclose($file);
        
        $this->info("Translations exported to {$path}");
    }
    
    protected function exportToJson($translations)
    {
        $data = [];
        
        foreach ($translations as $translation) {
            if (!isset($data[$translation->group])) {
                $data[$translation->group] = [];
            }
            
            $data[$translation->group][$translation->key] = $translation->text;
        }
        
        $path = storage_path('app/translations.json');
        File::put($path, json_encode($data, JSON_PRETTY_PRINT));
        
        $this->info("Translations exported to {$path}");
    }
}
```

Edit the import command:

```php
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Spatie\TranslationLoader\LanguageLine;

class TranslationImport extends Command
{
    protected $signature = 'translations:import {file} {--format=csv : The import format (csv or json)}';
    protected $description = 'Import translations from CSV or JSON';

    public function handle()
    {
        $file = $this->argument('file');
        $format = $this->option('format');
        
        if (!File::exists($file)) {
            $this->error("File not found: {$file}");
            return 1;
        }
        
        if ($format === 'csv') {
            $this->importFromCsv($file);
        } elseif ($format === 'json') {
            $this->importFromJson($file);
        } else {
            $this->error("Unsupported format: {$format}");
            return 1;
        }
        
        return 0;
    }
    
    protected function importFromCsv($file)
    {
        $handle = fopen($file, 'r');
        
        // Skip header
        fgetcsv($handle);
        
        $count = 0;
        $translations = [];
        
        while (($data = fgetcsv($handle)) !== false) {
            [$group, $key, $locale, $text] = $data;
            
            if (!isset($translations["{$group}.{$key}"])) {
                $translations["{$group}.{$key}"] = [
                    'group' => $group,
                    'key' => $key,
                    'text' => [],
                ];
            }
            
            $translations["{$group}.{$key}"]['text'][$locale] = $text;
        }
        
        fclose($handle);
        
        foreach ($translations as $translation) {
            LanguageLine::updateOrCreate(
                ['group' => $translation['group'], 'key' => $translation['key']],
                ['text' => $translation['text']]
            );
            $count++;
        }
        
        $this->info("{$count} translations imported");
    }
    
    protected function importFromJson($file)
    {
        $data = json_decode(File::get($file), true);
        $count = 0;
        
        foreach ($data as $group => $keys) {
            foreach ($keys as $key => $text) {
                LanguageLine::updateOrCreate(
                    ['group' => $group, 'key' => $key],
                    ['text' => $text]
                );
                $count++;
            }
        }
        
        $this->info("{$count} translations imported");
    }
}
```

### Step 5: Implement a Missing Translations Scanner

Create a command to scan for missing translations:

```bash
php artisan make:command ScanMissingTranslations
```

Edit the command:

```php
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;

class ScanMissingTranslations extends Command
{
    protected $signature = 'translations:scan {--add : Add missing translations to language files}';
    protected $description = 'Scan for missing translations in the application';

    protected $patterns = [
        // Blade translation functions
        '/@lang\([\'"](.+?)[\'"]\)/',
        '/\{\{\s*__\([\'"](.+?)[\'"](,.*?)?\)\s*\}\}/',
        '/trans\([\'"](.+?)[\'"](,.*?)?\)/',
        '/trans_choice\([\'"](.+?)[\'"](,.*?)?\)/',
        
        // PHP translation functions
        '/->lang\([\'"](.+?)[\'"]\)/',
        '/Lang::get\([\'"](.+?)[\'"](,.*?)?\)/',
        '/Lang::choice\([\'"](.+?)[\'"](,.*?)?\)/',
        '/__\([\'"](.+?)[\'"](,.*?)?\)/',
        '/trans\([\'"](.+?)[\'"](,.*?)?\)/',
        '/trans_choice\([\'"](.+?)[\'"](,.*?)?\)/',
        
        // JavaScript translation functions
        '/\$t\([\'"](.+?)[\'"](,.*?)?\)/',
        '/i18n\.t\([\'"](.+?)[\'"](,.*?)?\)/',
        '/i18n\.[\'"](.+?)[\'"](,.*?)?\)/',
    ];

    public function handle()
    {
        $this->info('Scanning for missing translations...');
        
        $translations = $this->scanTranslations();
        $existingTranslations = $this->getExistingTranslations();
        $missingTranslations = $this->findMissingTranslations($translations, $existingTranslations);
        
        if (empty($missingTranslations)) {
            $this->info('No missing translations found.');
            return 0;
        }
        
        $this->displayMissingTranslations($missingTranslations);
        
        if ($this->option('add')) {
            $this->addMissingTranslations($missingTranslations);
        }
        
        return 0;
    }
    
    protected function scanTranslations()
    {
        $translations = [];
        
        $directories = [
            app_path(),
            resource_path('views'),
            resource_path('js'),
        ];
        
        foreach ($directories as $directory) {
            $this->scanDirectory($directory, $translations);
        }
        
        return $translations;
    }
    
    protected function scanDirectory($directory, &$translations)
    {
        if (!File::isDirectory($directory)) {
            return;
        }
        
        $files = File::allFiles($directory);
        
        foreach ($files as $file) {
            $extension = $file->getExtension();
            
            if (in_array($extension, ['php', 'js', 'vue', 'jsx', 'tsx'])) {
                $content = File::get($file->getPathname());
                
                foreach ($this->patterns as $pattern) {
                    preg_match_all($pattern, $content, $matches);
                    
                    if (!empty($matches[1])) {
                        foreach ($matches[1] as $match) {
                            // Skip dynamic keys
                            if (Str::contains($match, ['$', '{', '}'])) {
                                continue;
                            }
                            
                            // Handle dot notation (e.g., 'messages.custom')
                            if (Str::contains($match, '.')) {
                                list($group, $key) = explode('.', $match, 2);
                                $translations[$group][$key] = $key;
                            } else {
                                // JSON translations
                                $translations['json'][$match] = $match;
                            }
                        }
                    }
                }
            }
        }
    }
    
    protected function getExistingTranslations()
    {
        $existingTranslations = [];
        $langPath = resource_path('lang');
        
        // Get PHP translations
        $directories = File::directories($langPath);
        
        foreach ($directories as $directory) {
            $locale = basename($directory);
            $files = File::files($directory);
            
            foreach ($files as $file) {
                $group = basename($file->getFilename(), '.php');
                $translations = include $file->getPathname();
                
                $this->flattenTranslations($translations, $group, $existingTranslations[$locale] ?? []);
            }
        }
        
        // Get JSON translations
        $jsonFiles = File::glob("{$langPath}/*.json");
        
        foreach ($jsonFiles as $file) {
            $locale = basename($file, '.json');
            $translations = json_decode(File::get($file), true) ?? [];
            
            foreach ($translations as $key => $value) {
                $existingTranslations[$locale]['json'][$key] = $value;
            }
        }
        
        return $existingTranslations;
    }
    
    protected function flattenTranslations($translations, $group, &$result, $prefix = '')
    {
        foreach ($translations as $key => $value) {
            $fullKey = $prefix ? "{$prefix}.{$key}" : $key;
            
            if (is_array($value)) {
                $this->flattenTranslations($value, $group, $result, $fullKey);
            } else {
                $result[$group][$fullKey] = $value;
            }
        }
    }
    
    protected function findMissingTranslations($translations, $existingTranslations)
    {
        $missingTranslations = [];
        $locales = array_keys($existingTranslations);
        
        if (empty($locales)) {
            $locales = [config('app.locale')];
        }
        
        foreach ($translations as $group => $keys) {
            foreach ($keys as $key => $value) {
                foreach ($locales as $locale) {
                    if ($group === 'json') {
                        if (!isset($existingTranslations[$locale]['json'][$key])) {
                            $missingTranslations[$locale]['json'][$key] = $key;
                        }
                    } else {
                        if (!isset($existingTranslations[$locale][$group][$key])) {
                            $missingTranslations[$locale][$group][$key] = $key;
                        }
                    }
                }
            }
        }
        
        return $missingTranslations;
    }
    
    protected function displayMissingTranslations($missingTranslations)
    {
        $this->info('Missing translations:');
        
        foreach ($missingTranslations as $locale => $groups) {
            $this->line("\nLocale: {$locale}");
            
            foreach ($groups as $group => $keys) {
                $this->line("\n  Group: {$group}");
                
                foreach ($keys as $key => $value) {
                    $this->line("    {$key}");
                }
            }
        }
    }
    
    protected function addMissingTranslations($missingTranslations)
    {
        $this->info('Adding missing translations...');
        
        foreach ($missingTranslations as $locale => $groups) {
            foreach ($groups as $group => $keys) {
                if ($group === 'json') {
                    $this->addMissingJsonTranslations($locale, $keys);
                } else {
                    $this->addMissingPhpTranslations($locale, $group, $keys);
                }
            }
        }
        
        $this->info('Missing translations added successfully.');
    }
    
    protected function addMissingJsonTranslations($locale, $keys)
    {
        $path = resource_path("lang/{$locale}.json");
        $translations = [];
        
        if (File::exists($path)) {
            $translations = json_decode(File::get($path), true) ?? [];
        }
        
        foreach ($keys as $key => $value) {
            $translations[$key] = $value;
        }
        
        File::put($path, json_encode($translations, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
    }
    
    protected function addMissingPhpTranslations($locale, $group, $keys)
    {
        $directory = resource_path("lang/{$locale}");
        
        if (!File::isDirectory($directory)) {
            File::makeDirectory($directory, 0755, true);
        }
        
        $path = "{$directory}/{$group}.php";
        $translations = [];
        
        if (File::exists($path)) {
            $translations = include $path;
        }
        
        foreach ($keys as $key => $value) {
            $this->setArrayValue($translations, $key, $value);
        }
        
        $content = "<?php\n\nreturn " . var_export($translations, true) . ";\n";
        File::put($path, $content);
    }
    
    protected function setArrayValue(&$array, $key, $value)
    {
        if (Str::contains($key, '.')) {
            $keys = explode('.', $key);
            $lastKey = array_pop($keys);
            $current = &$array;
            
            foreach ($keys as $nestedKey) {
                if (!isset($current[$nestedKey]) || !is_array($current[$nestedKey])) {
                    $current[$nestedKey] = [];
                }
                
                $current = &$current[$nestedKey];
            }
            
            $current[$lastKey] = $value;
        } else {
            $array[$key] = $value;
        }
    }
}
```

## Best Practices for Translation Management

1. **Use Descriptive Keys**: Use descriptive keys that indicate the context of the translation
2. **Organize by Context**: Group translations by context (auth, profile, teams, etc.)
3. **Use Placeholders**: Use placeholders for dynamic content
4. **Handle Pluralization**: Use pluralization rules for countable items
5. **Keep Translations Up-to-Date**: Regularly scan for missing translations
6. **Provide Context for Translators**: Add comments to explain the context of translations
7. **Use Translation Management Tools**: Consider using tools like Crowdin, Lokalise, or POEditor for larger projects
8. **Automate Translation Workflows**: Use commands to import/export translations
9. **Test with Real Users**: Have native speakers review translations
10. **Document Translation Processes**: Create documentation for translators

## Next Steps

Now that you know how to manage translations effectively, let's move on to [Localizing UME Features](./030-localizing-ume-features.md) to see examples of localizing specific features in the UME application.
