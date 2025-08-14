# Attribute-Based Model Configuration

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Enhance the developer experience when working with the HasAdditionalFeatures trait by implementing attribute-based configuration, allowing for a more declarative and type-safe approach to configuring model features.

## Overview

PHP 8 attributes provide a powerful way to add metadata to classes, methods, and properties. In this section, we'll implement attribute-based configuration for the HasAdditionalFeatures trait, allowing developers to configure model features using attributes rather than method calls or configuration arrays.

## Step 1: Create Feature Attributes

First, let's create a set of attributes for our model features:

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
     * @param string|null $column The column to store the ULID in
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
     * @param string|null $source The source field for the slug
     * @param string|null $column The column to store the slug in
     * @param bool $updateOnChange Whether to update the slug when the source changes
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
     * @param array|null $types The tag types to enable
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
     * @param array|null $columns Custom column mappings
     */
    public function __construct(
        public ?array $columns = null
    ) {}
}

#[Attribute(Attribute::TARGET_CLASS)]
class HasTranslations
{
    /**
     * Create a new attribute instance.
     *
     * @param array|null $attributes The attributes that should be translatable
     */
    public function __construct(
        public ?array $attributes = null
    ) {}
}

#[Attribute(Attribute::TARGET_CLASS)]
class LogsActivity
{
    /**
     * Create a new attribute instance.
     *
     * @param array|null $logAttributes The attributes to log
     * @param bool $logOnlyDirty Whether to log only dirty attributes
     * @param bool $submitEmptyLogs Whether to submit empty logs
     */
    public function __construct(
        public ?array $logAttributes = null,
        public bool $logOnlyDirty = true,
        public bool $submitEmptyLogs = false
    ) {}
}

#[Attribute(Attribute::TARGET_CLASS)]
class HasComments
{
    /**
     * Create a new attribute instance.
     */
    public function __construct()
    {}
}

#[Attribute(Attribute::TARGET_CLASS)]
class HasFlags
{
    /**
     * Create a new attribute instance.
     *
     * @param string|null $flagsEnum The enum class to use for flags
     */
    public function __construct(
        public ?string $flagsEnum = null
    ) {}
}

#[Attribute(Attribute::TARGET_CLASS)]
class Searchable
{
    /**
     * Create a new attribute instance.
     *
     * @param array|null $searchableAttributes The attributes to make searchable
     */
    public function __construct(
        public ?array $searchableAttributes = null
    ) {}
}

#[Attribute(Attribute::TARGET_CLASS)]
class SoftDeletes
{
    /**
     * Create a new attribute instance.
     *
     * @param string|null $column The column to use for soft deletes
     */
    public function __construct(
        public ?string $column = null
    ) {}
}
```

## Step 2: Update HasAdditionalFeatures Trait

Next, let's update the HasAdditionalFeatures trait to read these attributes:

```php
<?php

namespace App\Models\Traits;

use App\Models\Attributes\HasComments as HasCommentsAttribute;
use App\Models\Attributes\HasFlags as HasFlagsAttribute;
use App\Models\Attributes\HasSlug as HasSlugAttribute;
use App\Models\Attributes\HasTags as HasTagsAttribute;
use App\Models\Attributes\HasTranslations as HasTranslationsAttribute;
use App\Models\Attributes\HasUlid as HasUlidAttribute;
use App\Models\Attributes\HasUserTracking as HasUserTrackingAttribute;
use App\Models\Attributes\LogsActivity as LogsActivityAttribute;
use App\Models\Attributes\Searchable as SearchableAttribute;
use App\Models\Attributes\SoftDeletes as SoftDeletesAttribute;
use App\Models\Traits\Concerns\HasUlid;
use App\Models\Traits\Concerns\HasUserTracking;
use App\Support\FeatureManager;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Laravel\Scout\Searchable;
use ReflectionClass;
use Spatie\Activitylog\LogOptions;
use Spatie\Activitylog\Traits\LogsActivity;
use Spatie\Comments\Models\Concerns\HasComments;
use Spatie\ModelFlags\Models\Concerns\HasFlags;
use Spatie\Sluggable\HasSlug;
use Spatie\Tags\HasTags;
use Spatie\Translatable\HasTranslations;

/**
 * Trait HasAdditionalFeatures
 *
 * Provides core model features through composition of smaller concerns.
 */
trait HasAdditionalFeatures
{
    use HasUlid;
    use HasUserTracking;
    use HasComments;
    use HasFlags;
    use HasTags;
    use HasSlug;
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
        
        // Process HasUlid attribute
        $ulidAttributes = $reflection->getAttributes(HasUlidAttribute::class);
        foreach ($ulidAttributes as $attribute) {
            $instance = $attribute->newInstance();
            static::configureFeatures(function ($features) use ($instance) {
                $features->enable('ulid');
                if ($instance->column) {
                    $features->configure('ulid', ['column' => $instance->column]);
                }
            });
        }
        
        // Process HasSlug attribute
        $slugAttributes = $reflection->getAttributes(HasSlugAttribute::class);
        foreach ($slugAttributes as $attribute) {
            $instance = $attribute->newInstance();
            static::configureFeatures(function ($features) use ($instance) {
                $features->enable('sluggable');
                $config = [];
                if ($instance->source) {
                    $config['source'] = $instance->source;
                }
                if ($instance->column) {
                    $config['column'] = $instance->column;
                }
                $config['updateOnChange'] = $instance->updateOnChange;
                $features->configure('sluggable', $config);
            });
        }
        
        // Process HasTags attribute
        $tagsAttributes = $reflection->getAttributes(HasTagsAttribute::class);
        foreach ($tagsAttributes as $attribute) {
            $instance = $attribute->newInstance();
            static::configureFeatures(function ($features) use ($instance) {
                $features->enable('tags');
                if ($instance->types) {
                    $features->configure('tags', ['types' => $instance->types]);
                }
            });
        }
        
        // Process HasUserTracking attribute
        $userTrackingAttributes = $reflection->getAttributes(HasUserTrackingAttribute::class);
        foreach ($userTrackingAttributes as $attribute) {
            $instance = $attribute->newInstance();
            static::configureFeatures(function ($features) use ($instance) {
                $features->enable('user_tracking');
                if ($instance->columns) {
                    $features->configure('user_tracking', ['columns' => $instance->columns]);
                }
            });
        }
        
        // Process HasTranslations attribute
        $translationsAttributes = $reflection->getAttributes(HasTranslationsAttribute::class);
        foreach ($translationsAttributes as $attribute) {
            $instance = $attribute->newInstance();
            static::configureFeatures(function ($features) use ($instance) {
                $features->enable('translatable');
                if ($instance->attributes) {
                    $features->configure('translatable', ['attributes' => $instance->attributes]);
                }
            });
        }
        
        // Process LogsActivity attribute
        $logsActivityAttributes = $reflection->getAttributes(LogsActivityAttribute::class);
        foreach ($logsActivityAttributes as $attribute) {
            $instance = $attribute->newInstance();
            static::configureFeatures(function ($features) use ($instance) {
                $features->enable('activity_log');
                $config = [
                    'log_only_dirty' => $instance->logOnlyDirty,
                    'submit_empty_logs' => $instance->submitEmptyLogs,
                ];
                if ($instance->logAttributes) {
                    $config['log_attributes'] = $instance->logAttributes;
                }
                $features->configure('activity_log', $config);
            });
        }
        
        // Process HasComments attribute
        $commentsAttributes = $reflection->getAttributes(HasCommentsAttribute::class);
        foreach ($commentsAttributes as $attribute) {
            static::configureFeatures(function ($features) {
                $features->enable('comments');
            });
        }
        
        // Process HasFlags attribute
        $flagsAttributes = $reflection->getAttributes(HasFlagsAttribute::class);
        foreach ($flagsAttributes as $attribute) {
            $instance = $attribute->newInstance();
            static::configureFeatures(function ($features) use ($instance) {
                $features->enable('flags');
                if ($instance->flagsEnum) {
                    $features->configure('flags', ['enum' => $instance->flagsEnum]);
                }
            });
        }
        
        // Process Searchable attribute
        $searchableAttributes = $reflection->getAttributes(SearchableAttribute::class);
        foreach ($searchableAttributes as $attribute) {
            $instance = $attribute->newInstance();
            static::configureFeatures(function ($features) use ($instance) {
                $features->enable('searchable');
                if ($instance->searchableAttributes) {
                    $features->configure('searchable', ['attributes' => $instance->searchableAttributes]);
                }
            });
        }
        
        // Process SoftDeletes attribute
        $softDeletesAttributes = $reflection->getAttributes(SoftDeletesAttribute::class);
        foreach ($softDeletesAttributes as $attribute) {
            $instance = $attribute->newInstance();
            static::configureFeatures(function ($features) use ($instance) {
                $features->enable('soft_deletes');
                if ($instance->column) {
                    $features->configure('soft_deletes', ['column' => $instance->column]);
                }
            });
        }
    }

    /**
     * Get the activity log options for the model.
     */
    public function getActivitylogOptions(): LogOptions
    {
        $options = LogOptions::defaults();
        
        $config = static::getFeatureConfig('activity_log');
        
        if (isset($config['log_attributes'])) {
            $options->logOnly($config['log_attributes']);
        }
        
        if (isset($config['log_only_dirty']) && $config['log_only_dirty']) {
            $options->logOnlyDirty();
        }
        
        if (isset($config['submit_empty_logs']) && !$config['submit_empty_logs']) {
            $options->dontSubmitEmptyLogs();
        }
        
        return $options;
    }

    // ... rest of the trait implementation
}
```

## Step 3: Using Attribute-Based Configuration

Now, we can configure our models using attributes:

```php
<?php

namespace App\Models;

use App\Models\Attributes\HasSlug;
use App\Models\Attributes\HasTags;
use App\Models\Attributes\HasUlid;
use App\Models\Attributes\HasUserTracking;
use App\Models\Attributes\LogsActivity;
use App\Models\Attributes\Searchable;
use App\Models\Traits\HasAdditionalFeatures;
use Illuminate\Database\Eloquent\Model;

#[HasUlid]
#[HasSlug(source: 'title', column: 'slug', updateOnChange: true)]
#[HasTags(types: ['category', 'tag'])]
#[HasUserTracking]
#[LogsActivity(logAttributes: ['title', 'content', 'published'], logOnlyDirty: true)]
#[Searchable(searchableAttributes: ['title', 'content'])]
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

## Benefits of Attribute-Based Configuration

Using attributes for model configuration offers several benefits:

1. **Declarative Configuration**: The model's features are clearly visible at the class level
2. **Type Safety**: Attribute parameters are type-checked
3. **IDE Support**: Modern IDEs provide autocompletion and validation for attributes
4. **Centralized Logic**: Feature implementation details are encapsulated in the trait
5. **Reduced Boilerplate**: No need for lengthy configuration methods in each model
6. **Self-Documenting**: The model's capabilities are clearly visible in its definition

## Performance Considerations

Reading attributes via reflection can be expensive, especially if done frequently. To mitigate this, consider:

1. **Caching Attribute Configuration**: Cache the attribute configuration in a static property
2. **Lazy Loading**: Only read attributes when needed
3. **Batch Processing**: Process all attributes at once rather than individually

## Conclusion

Attribute-based configuration provides a clean, declarative way to configure model features. By leveraging PHP 8 attributes, we can create a more intuitive and type-safe API for our models, improving developer experience and reducing the likelihood of configuration errors.
