<?php

declare(strict_types=1);

namespace App\Models;

use App\Models\Traits\HasBaseModelFeatures;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Team extends Model
{
    use HasFactory, HasBaseModelFeatures;

    /**
     * The attributes that are mass assignable.
     *
     * @var string[]
     */
    protected $fillable = [
        'name',
        'slug',
        'ulid',
        'description',
        'owner_id',
        'parent_id',
        'is_active',
        'allow_subteams',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string,string>
     */
    protected $casts = [
        'is_active'      => 'boolean',
        'allow_subteams' => 'boolean',
    ];

    /**
     * Get the display name for the model.
     * Used by HasBaseModelFeatures trait for comments.
     */
    public function getDisplayName(): string
    {
        return $this->name;
    }

    /**
     * Get the route key for the model.
     */
    public function getRouteKeyName(): string
    {
        return 'ulid';
    }

    /**
     * Get the attributes that should be included in search indexing.
     * Required by the Searchable trait.
     */
    public function toSearchableArray(): array
    {
        return [
            'id' => $this->id,
            'ulid' => $this->ulid,
            'name' => $this->name,
            'description' => $this->description,
            'is_active' => $this->is_active,
        ];
    }

    /**
     * Parent team in the hierarchy.
     */
    public function parent(): BelongsTo
    {
        return $this->belongsTo(self::class, 'parent_id');
    }

    /**
     * Child teams of this team.
     */
    public function children(): HasMany
    {
        return $this->hasMany(self::class, 'parent_id');
    }

    /**
     * Members of the team via pivot table.
     */
    public function members(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'team_users')
                    ->using(TeamUser::class)
                    ->withPivot('role')
                    ->withTimestamps();
    }

    /**
     * Get all ancestor teams up to the root.
     */
    public function ancestors(): Collection
    {
        $ancestors = collect();
        $parent = $this->parent;
        while ($parent) {
            $ancestors->push($parent);
            $parent = $parent->parent;
        }
        return $ancestors;
    }

    /**
     * Get all descendant teams recursively.
     */
    public function descendants(): Collection
    {
        $descendants = collect();
        foreach ($this->children as $child) {
            $descendants->push($child);
            $descendants = $descendants->merge($child->descendants());
        }
        return $descendants;
    }

    /**
     * Add a user to the team.
     */
    public function addMember(User $user, string $role = 'member'): void
    {
        if (! $this->hasMember($user)) {
            $this->members()->attach($user->id, ['role' => $role]);
        }
    }

    /**
     * Remove a user from the team.
     */
    public function removeMember(User $user): void
    {
        $this->members()->detach($user->id);
    }

    /**
     * Check if a user is a member of this team.
     */
    public function hasMember(User $user): bool
    {
        return $this->members()->where('user_id', $user->id)->exists();
    }

    /**
     * Check membership within this team and its ancestors.
     */
    public function hasMemberInHierarchy(User $user): bool
    {
        if ($this->hasMember($user)) {
            return true;
        }
        foreach ($this->ancestors() as $ancestor) {
            if ($ancestor->hasMember($user)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Whether this team allows creation of subteams.
     */
    public function allowsSubteams(): bool
    {
        return $this->allow_subteams;
    }

    /**
     * Whether this is a root-level team.
     */
    public function isRootLevel(): bool
    {
        return $this->parent_id === null;
    }

    /**
     * Create a subteam under this team.
     *
     * @return self
     *
     * @throws \Exception
     */
    public function createSubteam(array $attributes): self
    {
        if (! $this->allowsSubteams()) {
            throw new \Exception('Subteam creation is not allowed for this team.');
        }
        $attributes['parent_id'] = $this->id;
        return self::create($attributes);
    }
}
