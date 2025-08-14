<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Str;
use Laravel\Passport\HasApiTokens;
use Laravel\Scout\Searchable;
use Spatie\Activitylog\LogOptions;
use Spatie\Activitylog\Traits\LogsActivity;
use Spatie\MediaLibrary\HasMedia;
use Spatie\MediaLibrary\InteractsWithMedia;
use Spatie\MediaLibrary\MediaCollections\Models\Media;
use Spatie\Sluggable\HasSlug;
use Spatie\Sluggable\SlugOptions;
use Spatie\Tags\HasTags;

class User extends Authenticatable implements MustVerifyEmail, HasMedia
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasApiTokens,
        HasFactory,
        HasSlug,
        HasTags,
        InteractsWithMedia,
        LogsActivity,
        Notifiable,
        Searchable,
        SoftDeletes;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'given_name',
        'family_name',
        'email',
        'password',
        'slug',
        'avatar',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    /**
     * Bootstrap the model and its traits.
     *
     * @return void
     */
    protected static function boot()
    {
        parent::boot();

        static::creating(function ($model) {
            if (empty($model->ulid)) {
                $model->ulid = (string) Str::ulid();
            }
        });

        static::saving(function ($model) {
            // Ensure family_name is always set (it's not nullable)
            if (empty($model->family_name)) {
                // If name is set but given_name and family_name are not, split the name
                if (!empty($model->name)) {
                    $nameParts = explode(' ', trim($model->name));

                    if (count($nameParts) === 1) {
                        // Single word name - assign to family_name
                        $model->family_name = $nameParts[0];
                        $model->given_name = null;
                    } else {
                        // Multi-word name - first part is given_name, remainder is family_name
                        $model->given_name = array_shift($nameParts);
                        $model->family_name = implode(' ', $nameParts);
                    }
                } else if (!empty($model->given_name)) {
                    // If only given_name is set, use it as family_name too
                    $model->family_name = $model->given_name;
                } else {
                    // Last resort: use a default value
                    $model->family_name = 'User ' . ($model->id ?? 'New');
                }
            }

            // Update the name field for backward compatibility
            if ($model->given_name || $model->family_name) {
                $name = '';
                if ($model->given_name) {
                    $name .= $model->given_name;
                }
                if ($model->family_name) {
                    $name .= ($name ? ' ' : '') . $model->family_name;
                }
                $model->name = trim($name);
            }
        });
    }

    /**
     * Get the options for generating the slug.
     */
    public function getSlugOptions(): SlugOptions
    {
        return SlugOptions::create()
            ->generateSlugsFrom(function($model) {
                return $model->given_name . ' ' . $model->family_name;
            })
            ->saveSlugsTo('slug')
            ->doNotGenerateSlugsOnUpdate();
    }

    /**
     * Get the user's full name.
     * Combines given_name and family_name, or returns the original name attribute.
     *
     * @return string
     */
    public function getNameAttribute(): string
    {
        if ($this->given_name || $this->family_name) {
            $name = '';
            if ($this->given_name) {
                $name .= $this->given_name;
            }
            if ($this->family_name) {
                $name .= ($name ? ' ' : '') . $this->family_name;
            }
            return trim($name);
        }

        return $this->attributes['name'] ?? '';
    }

    /**
     * Get the user's initials.
     * Takes the first letter of each part of the name, with only first and last capitalized.
     *
     * @return string
     */
    public function getInitials(): string
    {
        $name = $this->name;
        if (empty($name)) {
            return '';
        }

        $parts = explode(' ', $name);
        $initials = '';

        // If only one part, return first letter capitalized
        if (count($parts) === 1) {
            return strtoupper(substr($parts[0], 0, 1));
        }

        // Get first letter of each part
        foreach ($parts as $i => $part) {
            if (empty($part)) continue;

            $initial = substr($part, 0, 1);

            // Capitalize only first and last initials
            if ($i === 0 || $i === count($parts) - 1) {
                $initial = strtoupper($initial);
            } else {
                $initial = strtolower($initial);
            }

            $initials .= $initial;
        }

        return $initials;
    }

    /**
     * Register media collections for the user model.
     */
    public function registerMediaCollections(): void
    {
        $this->addMediaCollection('avatar')
            ->singleFile()
            ->acceptsMimeTypes(['image/jpeg', 'image/png', 'image/gif'])
            ->registerMediaConversions(function (Media $media) {
                $this->addMediaConversion('thumb')
                    ->width(100)
                    ->height(100)
                    ->nonQueued();

                $this->addMediaConversion('medium')
                    ->width(300)
                    ->height(300)
                    ->nonQueued();
            });
    }

    /**
     * Get the user's avatar URL.
     * Returns the media URL if available, otherwise returns the avatar field value.
     *
     * @return string|null
     */
    public function getAvatarUrlAttribute(): ?string
    {
        // If user has media in the avatar collection, return that URL
        if ($this->hasMedia('avatar')) {
            return $this->getFirstMediaUrl('avatar');
        }

        // Otherwise return the avatar field value (URL)
        return $this->attributes['avatar'] ?? null;
    }

    /**
     * Get the user's avatar thumbnail URL.
     *
     * @return string|null
     */
    public function getAvatarThumbUrlAttribute(): ?string
    {
        if ($this->hasMedia('avatar')) {
            return $this->getFirstMediaUrl('avatar', 'thumb');
        }

        return $this->avatar_url;
    }

    /**
     * Find the user instance for the given username.
     */
    public function findForPassport(string $username): User
    {
        return $this->where('username', $username)->first();
    }

    /**
     * Get the indexable data array for the model.
     *
     * @return array<string, mixed>
     */
    public function toSearchableArray()
    {
        return array_merge($this->toArray(),[
            'id' => (string) $this->id,
            'name' => $this->name,
            'given_name' => $this->given_name,
            'family_name' => $this->family_name,
            'email' => $this->email,
            'slug' => $this->slug,
            'avatar_url' => $this->avatar_url,
            'created_at' => $this->created_at->timestamp,
        ]);
    }

    /**
     * Get the name of the index associated with the model.
     */
    public function searchableAs(): string
    {
        return 'users_index';
    }

    /**
     * Get the activity log options for the model.
     */
    public function getActivitylogOptions(): LogOptions
    {
        return LogOptions::defaults()
            ->logAll()
            ->logOnlyDirty()
            ->dontSubmitEmptyLogs();
    }
}
