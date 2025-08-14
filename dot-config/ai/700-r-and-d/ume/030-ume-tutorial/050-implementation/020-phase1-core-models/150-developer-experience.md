# Developer Experience Improvements

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Enhance the developer experience when working with the HasAdditionalFeatures trait by adding attribute-based configuration, feature discovery methods, and debug helpers.

## Overview

While the HasAdditionalFeatures trait and FeatureManager provide powerful functionality, we can further improve the developer experience by making the API more intuitive and providing better tools for debugging and discovery.

## Step 1: Implement Attribute-Based Feature Configuration

PHP 8 introduced attributes, which provide a clean way to add metadata to classes, methods, and properties. We can use attributes to configure features at the model level:

First, let's create a set of attributes for our features:

```php
<?php

namespace App\Models\Attributes;

use Attribute;

#[Attribute(Attribute::TARGET_CLASS)]
class HasUlid
{
    /**
     * Create a new attribute instance.
     *
     * @param string|null $column
     */
    public function __construct(
        public ?string $column = null
    ) {}
}

#[Attribute(Attribute::TARGET_CLASS)]
class HasSlug
{
    /**
     * Create a new attribute instance.
     *
     * @param string|null $source
     * @param string|null $column
     * @param bool $updateOnChange
     */
    public function __construct(
        public ?string $source = null,
        public ?string $column = null,
        public bool $updateOnChange = false
    ) {}
}

#[Attribute(Attribute::TARGET_CLASS)]
class HasTags
{
    /**
     * Create a new attribute instance.
     *
     * @param array|null $types
     */
    public function __construct(
        public ?array $types = null
    ) {}
}

#[Attribute(Attribute::TARGET_CLASS)]
class HasUserTracking
{
    /**
     * Create a new attribute instance.
     *
     * @param array|null $columns
     */
    public function __construct(
        public ?array $columns = null
    ) {}
}

// Additional attributes for other features...
```

Next, let's update the HasAdditionalFeatures trait to read these attributes:

```php
<?php

namespace App\Models\Traits;

use App\Models\Attributes\HasSlug;
use App\Models\Attributes\HasTags;
use App\Models\Attributes\HasUlid;
use App\Models\Attributes\HasUserTracking;
use App\Models\Traits\Concerns\HasUlid as HasUlidTrait;
use App\Models\Traits\Concerns\HasUserTracking as HasUserTrackingTrait;
use App\Support\FeatureManager;
use Illuminate\Database\Eloquent\SoftDeletes;
use Laravel\Scout\Searchable;
use ReflectionClass;
use Spatie\Activitylog\LogOptions;
use Spatie\Activitylog\Traits\LogsActivity;
use Spatie\Comments\Models\Concerns\HasComments;
use Spatie\ModelFlags\Models\Concerns\HasFlags;
use Spatie\Sluggable\HasTranslatableSlug;
use Spatie\Tags\HasTags as HasTagsTrait;
use Spatie\Translatable\HasTranslations;

/**
 * Trait HasAdditionalFeatures
 *
 * Provides core model features through composition of smaller concerns.
 */
trait HasAdditionalFeatures
{
    use HasUlidTrait;
    use HasUserTrackingTrait;
    use HasComments;
    use HasFlags;
    use HasTagsTrait;
    use HasTranslatableSlug;
    use HasTranslations;
    use LogsActivity;
    use Searchable;
    use SoftDeletes;

    /**
     * Boot the HasAdditionalFeatures trait.
     *
     * @return void
     */
    public static function bootHasAdditionalFeatures(): void
    {
        // Configure features based on attributes
        static::configureFromAttributes();
    }

    /**
     * Configure features based on attributes.
     *
     * @return void
     */
    protected static function configureFromAttributes(): void
    {
        $reflection = new ReflectionClass(static::class);
        $attributes = $reflection->getAttributes();

        foreach ($attributes as $attribute) {
            $instance = $attribute->newInstance();
            
            switch (get_class($instance)) {
                case HasUlid::class:
                    FeatureManager::enable('ulid', static::class);
                    if ($instance->column) {
                        FeatureManager::configure('ulid', ['column' => $instance->column], static::class);
                    }
                    break;
                
                case HasSlug::class:
                    FeatureManager::enable('sluggable', static::class);
                    $config = [];
                    if ($instance->source) {
                        $config['source'] = $instance->source;
                    }
                    if ($instance->column) {
                        $config['column'] = $instance->column;
                    }
                    $config['update_on_change'] = $instance->updateOnChange;
                    FeatureManager::configure('sluggable', $config, static::class);
                    break;
                
                case HasTags::class:
                    FeatureManager::enable('tags', static::class);
                    if ($instance->types) {
                        FeatureManager::configure('tags', ['types' => $instance->types], static::class);
                    }
                    break;
                
                case HasUserTracking::class:
                    FeatureManager::enable('user_tracking', static::class);
                    if ($instance->columns) {
                        FeatureManager::configure('user_tracking', ['columns' => $instance->columns], static::class);
                    }
                    break;
                
                // Additional cases for other attributes...
            }
        }
    }

    // ... existing methods ...
}
```

Now, we can configure features using attributes:

```php
<?php

namespace App\Models;

use App\Models\Attributes\HasSlug;
use App\Models\Attributes\HasTags;
use App\Models\Attributes\HasUlid;
use App\Models\Attributes\HasUserTracking;
use App\Models\Traits\HasAdditionalFeatures;
use Illuminate\Database\Eloquent\Model;

#[HasUlid]
#[HasSlug(source: 'title', column: 'slug')]
#[HasTags(types: ['category', 'tag'])]
#[HasUserTracking(columns: ['created_by' => 'author_id'])]
class Post extends Model
{
    use HasAdditionalFeatures;

    /**
     * The attributes that are mass assignable.
     *
     * @var array
     */
    protected $fillable = [
        'title',
        'content',
        'published',
    ];
}
```

## Step 2: Add Feature Discovery Methods

Let's add methods to discover available features and their configuration:

```php
<?php

namespace App\Models\Traits;

// ... existing imports ...

trait HasAdditionalFeatures
{
    // ... existing trait implementation ...

    /**
     * Get all available features.
     *
     * @return array
     */
    public static function getAvailableFeatures(): array
    {
        return array_keys(config('additional-features.enabled', []));
    }

    /**
     * Get enabled features for this model.
     *
     * @return array
     */
    public static function getEnabledFeatures(): array
    {
        return array_filter(static::getAvailableFeatures(), fn($feature) => 
            static::isFeatureEnabled($feature)
        );
    }

    /**
     * Get the configuration for all features.
     *
     * @return array
     */
    public static function getFeatureConfigurations(): array
    {
        $configurations = [];
        
        foreach (static::getAvailableFeatures() as $feature) {
            $configurations[$feature] = FeatureManager::getConfiguration($feature, static::class);
        }
        
        return $configurations;
    }

    /**
     * Check if a model uses a specific feature.
     *
     * @param string $feature
     * @return bool
     */
    public static function usesFeature(string $feature): bool
    {
        return in_array($feature, static::getEnabledFeatures());
    }
}
```

## Step 3: Add Debug Helpers

Let's add debug helpers to troubleshoot feature issues:

```php
<?php

namespace App\Models\Traits;

// ... existing imports ...

trait HasAdditionalFeatures
{
    // ... existing trait implementation ...

    /**
     * Dump the feature status for this model.
     *
     * @return void
     */
    public static function dumpFeatureStatus(): void
    {
        dump([
            'model' => static::class,
            'enabled_features' => static::getEnabledFeatures(),
            'configurations' => static::getFeatureConfigurations(),
        ]);
    }

    /**
     * Get a string representation of the feature status.
     *
     * @return string
     */
    public static function getFeatureStatusString(): string
    {
        $enabled = static::getEnabledFeatures();
        $disabled = array_diff(static::getAvailableFeatures(), $enabled);
        
        $result = "Feature Status for " . static::class . ":\n\n";
        
        $result .= "Enabled Features:\n";
        foreach ($enabled as $feature) {
            $result .= "- {$feature}\n";
        }
        
        $result .= "\nDisabled Features:\n";
        foreach ($disabled as $feature) {
            $result .= "- {$feature}\n";
        }
        
        return $result;
    }

    /**
     * Log the feature status for this model.
     *
     * @return void
     */
    public static function logFeatureStatus(): void
    {
        \Illuminate\Support\Facades\Log::info(static::getFeatureStatusString());
    }
}
```

## Step 4: Create a Feature Documentation Generator Command

Let's create a command to generate documentation for all features:

```php
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;

class GenerateFeatureDocumentation extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'additional-features:docs {--output=docs/additional-features}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Generate 010-consolidated-starter-kits for all additional features';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $outputPath = $this->option('output');
        
        // Create the output directory if it doesn't exist
        if (!File::exists($outputPath)) {
            File::makeDirectory($outputPath, 0755, true);
        }
        
        // Get all available features
        $features = array_keys(Config::get('additional-features.enabled', []));
        
        // Generate the index file
        $this->generateIndexFile($outputPath, $features);
        
        // Generate 010-consolidated-starter-kits for each feature
        foreach ($features as $feature) {
            $this->generateFeatureDocumentation($outputPath, $feature);
        }
        
        $this->info('Feature 010-consolidated-starter-kits generated successfully!');
        
        return Command::SUCCESS;
    }

    /**
     * Generate the index file.
     *
     * @param string $outputPath
     * @param array $features
     * @return void
     */
    protected function generateIndexFile(string $outputPath, array $features): void
    {
        $content = "# Additional Features Documentation\n\n";
        $content .= "This 010-consolidated-starter-kits provides information about all available features in the HasAdditionalFeatures trait.\n\n";
        $content .= "## Available Features\n\n";
        
        foreach ($features as $feature) {
            $title = Str::title(str_replace('_', ' ', $feature));
            $content .= "- [{$title}](./{$feature}.md)\n";
        }
        
        File::put("{$outputPath}/index.md", $content);
    }

    /**
     * Generate 010-consolidated-starter-kits for a specific feature.
     *
     * @param string $outputPath
     * @param string $feature
     * @return void
     */
    protected function generateFeatureDocumentation(string $outputPath, string $feature): void
    {
        $title = Str::title(str_replace('_', ' ', $feature));
        $config = Config::get("additional-features.{$feature}", []);
        
        $content = "# {$title}\n\n";
        $content .= "## Overview\n\n";
        $content .= $this->getFeatureDescription($feature) . "\n\n";
        $content .= "## Configuration\n\n";
        $content .= "```php\n";
        $content .= "// In config/additional-features.php\n";
        $content .= "'{$feature}' => " . var_export($config, true) . ",\n";
        $content .= "```\n\n";
        $content .= "## Usage\n\n";
        $content .= $this->getFeatureUsage($feature) . "\n\n";
        $content .= "## Methods\n\n";
        $content .= $this->getFeatureMethods($feature) . "\n\n";
        
        File::put("{$outputPath}/{$feature}.md", $content);
    }

    /**
     * Get the description for a feature.
     *
     * @param string $feature
     * @return string
     */
    protected function getFeatureDescription(string $feature): string
    {
        $descriptions = [
            'ulid' => 'The ULID feature automatically generates Universally Unique Lexicographically Sortable Identifiers for models.',
            'user_tracking' => 'The User Tracking feature tracks which users created, updated, and deleted models.',
            'sluggable' => 'The Sluggable feature creates URL-friendly slugs for models.',
            'translatable' => 'The Translatable feature supports multilingual content with automatic translations.',
            'activity_log' => 'The Activity Log feature tracks all changes to models.',
            'comments' => 'The Comments feature adds commenting functionality to models.',
            'tags' => 'The Tags feature allows tagging models with categories or keywords.',
            'flags' => 'The Flags feature adds boolean flags to models with enum validation.',
            'searchable' => 'The Searchable feature makes models searchable with Laravel Scout.',
            'soft_deletes' => 'The Soft Deletes feature implements soft delete functionality.',
        ];
        
        return $descriptions[$feature] ?? "The {$title} feature provides additional functionality for models.";
    }

    /**
     * Get the usage examples for a feature.
     *
     * @param string $feature
     * @return string
     */
    protected function getFeatureUsage(string $feature): string
    {
        $usages = [
            'ulid' => "```php\n// Find a model by its ULID\n\$model = YourModel::findByUlid('01ABCDEF');\n\n// Get the ULID column name\n\$ulidColumn = YourModel::getUlidColumn();\n```",
            'user_tracking' => "```php\n// Get the user who created the model\n\$creator = \$model->creator;\n\n// Get the user who last updated the model\n\$updater = \$model->updater;\n\n// Get the user who deleted the model (for soft deletes)\n\$deleter = \$model->deleter;\n\n// Query models created by a specific user\n\$modelsCreatedByUser = YourModel::createdBy(\$user->id)->get();\n```",
            // ... other features ...
        ];
        
        return $usages[$feature] ?? "```php\n// Enable the feature\nYourModel::configureFeatures(function (\$features) {\n    \$features->enable('{$feature}');\n});\n\n// Check if the feature is enabled\nif (YourModel::isFeatureEnabled('{$feature}')) {\n    // Use the feature\n}\n```";
    }

    /**
     * Get the methods for a feature.
     *
     * @param string $feature
     * @return string
     */
    protected function getFeatureMethods(string $feature): string
    {
        $methods = [
            'ulid' => "- `findByUlid(string \$ulid, array \$columns = ['*'])`: Find a model by its ULID\n- `findByUlidOrFail(string \$ulid, array \$columns = ['*'])`: Find a model by its ULID or fail\n- `getUlidColumn()`: Get the ULID column name",
            'user_tracking' => "- `creator()`: Get the user who created the model\n- `updater()`: Get the user who last updated the model\n- `deleter()`: Get the user who deleted the model\n- `scopeCreatedBy(Builder \$query, int \$userId)`: Scope to get models created by a specific user\n- `scopeUpdatedBy(Builder \$query, int \$userId)`: Scope to get models updated by a specific user\n- `scopeDeletedBy(Builder \$query, int \$userId)`: Scope to get models deleted by a specific user",
            // ... other features ...
        ];
        
        return $methods[$feature] ?? "- `isFeatureEnabled('{$feature}')`: Check if the feature is enabled\n- `configureFeatures(callable \$callback)`: Configure features for the model";
    }
}
```

## Step 5: Create an Interactive Configuration Helper Command

Let's create an interactive command to configure features:

```php
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\File;

class ConfigureAdditionalFeatures extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'additional-features:configure';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Configure additional features interactively';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $this->info('Welcome to the Additional Features Configuration Helper!');
        $this->info('This command will help you configure the additional features for your application.');
        
        // Get all available features
        $features = array_keys(Config::get('additional-features.enabled', []));
        
        // Configure each feature
        $configuration = [];
        $configuration['enabled'] = [];
        
        foreach ($features as $feature) {
            $enabled = $this->confirm("Enable the {$feature} feature?", true);
            $configuration['enabled'][$feature] = $enabled;
            
            if ($enabled) {
                $this->configureFeature($feature, $configuration);
            }
        }
        
        // Save the configuration
        $this->saveConfiguration($configuration);
        
        $this->info('Configuration saved successfully!');
        
        return Command::SUCCESS;
    }

    /**
     * Configure a specific feature.
     *
     * @param string $feature
     * @param array &$configuration
     * @return void
     */
    protected function configureFeature(string $feature, array &$configuration): void
    {
        $this->info("Configuring the {$feature} feature...");
        
        switch ($feature) {
            case 'ulid':
                $configuration['ulid'] = [
                    'column' => $this->ask('ULID column name?', 'ulid'),
                    'auto_generate' => $this->confirm('Auto-generate ULIDs?', true),
                ];
                break;
            
            case 'user_tracking':
                $configuration['user_tracking'] = [
                    'user_model' => $this->ask('User model class?', '\\App\\Models\\User'),
                    'columns' => [
                        'created_by' => $this->ask('Created by column?', 'created_by'),
                        'updated_by' => $this->ask('Updated by column?', 'updated_by'),
                        'deleted_by' => $this->ask('Deleted by column?', 'deleted_by'),
                    ],
                ];
                break;
            
            case 'sluggable':
                $configuration['sluggable'] = [
                    'column' => $this->ask('Slug column name?', 'slug'),
                    'source' => $this->ask('Source attribute?', 'name'),
                    'update_on_change' => $this->confirm('Update slug when source changes?', false),
                ];
                break;
            
            // ... other features ...
        }
    }

    /**
     * Save the configuration.
     *
     * @param array $configuration
     * @return void
     */
    protected function saveConfiguration(array $configuration): void
    {
        $configPath = config_path('additional-features.php');
        
        // Create the configuration file if it doesn't exist
        if (!File::exists($configPath)) {
            $stub = File::get(__DIR__ . '/stubs/additional-features.stub');
            File::put($configPath, $stub);
        }
        
        // Get the current configuration
        $currentConfig = include $configPath;
        
        // Merge the configurations
        $newConfig = array_merge($currentConfig, $configuration);
        
        // Generate the configuration file content
        $content = "<?php\n\nreturn " . var_export($newConfig, true) . ";\n";
        
        // Save the configuration file
        File::put($configPath, $content);
    }
}
```

## Benefits of Developer Experience Improvements

These developer experience improvements provide several benefits:

1. **Declarative Configuration**: Attribute-based configuration makes it clear which features a model uses.
2. **Self-Documentation**: Feature discovery methods make it easy to understand what features are available and enabled.
3. **Easier Debugging**: Debug helpers make it easier to troubleshoot feature issues.
4. **Better Documentation**: The documentation generator ensures that all features are well-documented.
5. **Simplified Configuration**: The interactive configuration helper makes it easy to configure features.

## Next Steps

Now that we've added developer experience improvements, we can move on to implementing performance optimizations such as lazy loading and configuration caching. Let's continue to [Performance Optimizations](./090-performance-optimizations.md).
