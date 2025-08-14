<?php

declare(strict_types=1);

namespace App\Models\Traits;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Laravel\Scout\Searchable;
use Spatie\Activitylog\LogOptions;
use Spatie\Activitylog\Traits\LogsActivity;
use Spatie\Comments\Models\Concerns\HasComments;
use Spatie\Sluggable\HasSlug;
use Spatie\Sluggable\SlugOptions;
use Spatie\Tags\HasTags;
use Illuminate\Support\Str;

/**
 * Trait HasBaseModelFeatures
 *
 * Provides core model features: ULID generation, slugging, activity logging,
 * comments, tagging, search indexing, and soft deletes.
 */
trait HasBaseModelFeatures
{
    use SoftDeletes, LogsActivity, HasComments, HasSlug, HasTags, Searchable;

    /**
     * Boot the HasBaseModelFeatures trait.
     */
    protected static function bootHasBaseModelFeatures(): void
    {
        static::creating(function (Model $model): void {
            if (empty($model->ulid) && property_exists($model, 'ulid')) {
                $model->ulid = (string) Str::ulid();
            }
        });
    }

    /**
     * Configure slug generation options.
     */
    public function getSlugOptions(): SlugOptions
    {
        return SlugOptions::create()
            ->generateSlugsFrom('name')
            ->saveSlugsTo('slug')
            ->doNotGenerateSlugsOnUpdate();
    }

    /**
     * Configure activity log options.
     */
    public function getActivitylogOptions(): LogOptions
    {
        return LogOptions::defaults()
            ->logAll()
            ->logOnlyDirty()
            ->dontSubmitEmptyLogs();
    }

    /**
     * Provide a URL for comments (used by HasComments trait).
     */
    public function commentUrl(): string
    {
        $slugField = property_exists($this, 'slug') ? 'slug' : $this->getKeyName();
        return url(Str::plural(Str::kebab(class_basename($this))) . '/' . $this->{$slugField});
    }

    /**
     * Provide a friendly name for comments (used by HasComments trait).
     */
    public function commentName(): string
    {
        // Use the model's display name for comments
        if (method_exists($this, 'getDisplayName')) {
            return $this->getDisplayName();
        }
        // Fallback: ULID or primary key
        return (string) ($this->ulid ?? $this->getKey());
    }
    
    /**
     * Provide a friendly name for comments (alias for commentName).
     * Implementing abstract method required by HasComments trait.
     */
    public function commentableName(): string
    {
        return $this->commentName();
    }
}
