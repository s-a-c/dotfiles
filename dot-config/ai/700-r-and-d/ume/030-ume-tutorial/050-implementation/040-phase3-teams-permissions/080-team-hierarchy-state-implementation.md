# Team Hierarchy State Implementation

<link rel="stylesheet" href="../../../assets/css/styles.css">

In this section, we'll implement the team hierarchy state machine by creating the necessary enum and state classes. We'll build on the concepts we learned when implementing the account state machine.

## Creating the TeamHierarchyStatus Enum

First, let's create an enum to represent the possible states of a team in the hierarchy:

```bash
# Create the enum file
touch app/Enums/TeamHierarchyStatus.php
```

Now, let's implement the `TeamHierarchyStatus` enum:

```php
<?php

declare(strict_types=1);

namespace App\Enums;

enum TeamHierarchyStatus: string
{
    case PENDING = 'pending';
    case ACTIVE = 'active';
    case SUSPENDED = 'suspended';
    case ARCHIVED = 'archived';

    /**
     * Get a human-readable label for the status.
     */
    public function getLabel(): string
    {
        return match($this) {
            self::PENDING => 'Pending Approval',
            self::ACTIVE => 'Active',
            self::SUSPENDED => 'Suspended',
            self::ARCHIVED => 'Archived',
        };
    }

    /**
     * Get a color for the status (for UI purposes).
     */
    public function getColor(): string
    {
        return match($this) {
            self::PENDING => 'yellow',
            self::ACTIVE => 'green',
            self::SUSPENDED => 'red',
            self::ARCHIVED => 'gray',
        };
    }

    /**
     * Get an icon for the status (for UI purposes).
     */
    public function getIcon(): string
    {
        return match($this) {
            self::PENDING => 'clock',
            self::ACTIVE => 'check-circle',
            self::SUSPENDED => 'ban',
            self::ARCHIVED => 'archive',
        };
    }

    /**
     * Get Tailwind CSS classes for the status.
     */
    public function getTailwindClasses(): string
    {
        return match($this) {
            self::PENDING => 'bg-yellow-100 text-yellow-800 border-yellow-200',
            self::ACTIVE => 'bg-green-100 text-green-800 border-green-200',
            self::SUSPENDED => 'bg-red-100 text-red-800 border-red-200',
            self::ARCHIVED => 'bg-gray-100 text-gray-800 border-gray-200',
        };
    }
}
```

## Creating the Base State Class

Next, let's create a directory for our team state classes and the base `TeamHierarchyState` class:

```bash
# Create the directory
mkdir -p app/States/Team

# Create the base state class
touch app/States/Team/TeamHierarchyState.php
```

Now, let's implement the base `TeamHierarchyState` class:

```php
<?php

declare(strict_types=1);

namespace App\States\Team;

use App\Enums\TeamHierarchyStatus;
use App\Models\Team;
use Spatie\ModelStates\State;
use Spatie\ModelStates\StateConfig;

/**
 * Abstract base class for all team hierarchy states.
 */
abstract class TeamHierarchyState extends State
{
    /**
     * Get the corresponding enum value for this state.
     */
    abstract public static function status(): TeamHierarchyStatus;

    /**
     * Configure the state machine.
     */
    public static function config(): StateConfig
    {
        return parent::config()
            ->default(Pending::class) // Default state for new teams
            ->allowTransition(Pending::class, Active::class) // Pending -> Active (Approve)
            ->allowTransition(Active::class, Suspended::class) // Active -> Suspended
            ->allowTransition(Active::class, Archived::class) // Active -> Archived
            ->allowTransition(Suspended::class, Active::class) // Suspended -> Active (Reactivate)
            ->allowTransition(Suspended::class, Archived::class) // Suspended -> Archived
            ->allowTransition(Archived::class, Active::class); // Archived -> Active (Restore)
    }

    /**
     * Get the display label for this state.
     */
    public function label(): string
    {
        return static::status()->getLabel();
    }

    /**
     * Get the color for this state.
     */
    public function color(): string
    {
        return static::status()->getColor();
    }

    /**
     * Get the icon for this state.
     */
    public function icon(): string
    {
        return static::status()->getIcon();
    }

    /**
     * Get the Tailwind CSS classes for this state.
     */
    public function tailwindClasses(): string
    {
        return static::status()->getTailwindClasses();
    }

    /**
     * Check if the team can have members added.
     */
    abstract public function canAddMembers(): bool;

    /**
     * Check if the team can create child teams.
     */
    abstract public function canCreateChildTeams(): bool;

    /**
     * Check if the team is visible in the hierarchy.
     */
    abstract public function isVisibleInHierarchy(): bool;

    /**
     * Check if the team can have permissions assigned.
     */
    abstract public function canAssignPermissions(): bool;
}
```

## Creating Concrete State Classes

Now, let's create the concrete state classes for each possible state:

### 1. Pending State

```bash
touch app/States/Team/Pending.php
```

```php
<?php

declare(strict_types=1);

namespace App\States\Team;

use App\Enums\TeamHierarchyStatus;

/**
 * Represents a team that is pending approval.
 */
class Pending extends TeamHierarchyState
{
    /**
     * Get the corresponding enum value for this state.
     */
    public static function status(): TeamHierarchyStatus
    {
        return TeamHierarchyStatus::PENDING;
    }

    /**
     * Check if the team can have members added.
     */
    public function canAddMembers(): bool
    {
        return false; // Pending teams cannot have members added
    }

    /**
     * Check if the team can create child teams.
     */
    public function canCreateChildTeams(): bool
    {
        return false; // Pending teams cannot create child teams
    }

    /**
     * Check if the team is visible in the hierarchy.
     */
    public function isVisibleInHierarchy(): bool
    {
        return false; // Pending teams are only visible to admins
    }

    /**
     * Check if the team can have permissions assigned.
     */
    public function canAssignPermissions(): bool
    {
        return false; // Pending teams cannot have permissions assigned
    }
}
```

### 2. Active State

```bash
touch app/States/Team/Active.php
```

```php
<?php

declare(strict_types=1);

namespace App\States\Team;

use App\Enums\TeamHierarchyStatus;

/**
 * Represents an active team.
 */
class Active extends TeamHierarchyState
{
    /**
     * Get the corresponding enum value for this state.
     */
    public static function status(): TeamHierarchyStatus
    {
        return TeamHierarchyStatus::ACTIVE;
    }

    /**
     * Check if the team can have members added.
     */
    public function canAddMembers(): bool
    {
        return true; // Active teams can have members added
    }

    /**
     * Check if the team can create child teams.
     */
    public function canCreateChildTeams(): bool
    {
        return true; // Active teams can create child teams
    }

    /**
     * Check if the team is visible in the hierarchy.
     */
    public function isVisibleInHierarchy(): bool
    {
        return true; // Active teams are visible in the hierarchy
    }

    /**
     * Check if the team can have permissions assigned.
     */
    public function canAssignPermissions(): bool
    {
        return true; // Active teams can have permissions assigned
    }
}
```

### 3. Suspended State

```bash
touch app/States/Team/Suspended.php
```

```php
<?php

declare(strict_types=1);

namespace App\States\Team;

use App\Enums\TeamHierarchyStatus;

/**
 * Represents a suspended team.
 */
class Suspended extends TeamHierarchyState
{
    /**
     * Get the corresponding enum value for this state.
     */
    public static function status(): TeamHierarchyStatus
    {
        return TeamHierarchyStatus::SUSPENDED;
    }

    /**
     * Check if the team can have members added.
     */
    public function canAddMembers(): bool
    {
        return false; // Suspended teams cannot have members added
    }

    /**
     * Check if the team can create child teams.
     */
    public function canCreateChildTeams(): bool
    {
        return false; // Suspended teams cannot create child teams
    }

    /**
     * Check if the team is visible in the hierarchy.
     */
    public function isVisibleInHierarchy(): bool
    {
        return true; // Suspended teams are visible in the hierarchy (with indicator)
    }

    /**
     * Check if the team can have permissions assigned.
     */
    public function canAssignPermissions(): bool
    {
        return false; // Suspended teams cannot have permissions assigned
    }
}
```

### 4. Archived State

```bash
touch app/States/Team/Archived.php
```

```php
<?php

declare(strict_types=1);

namespace App\States\Team;

use App\Enums\TeamHierarchyStatus;

/**
 * Represents an archived team.
 */
class Archived extends TeamHierarchyState
{
    /**
     * Get the corresponding enum value for this state.
     */
    public static function status(): TeamHierarchyStatus
    {
        return TeamHierarchyStatus::ARCHIVED;
    }

    /**
     * Check if the team can have members added.
     */
    public function canAddMembers(): bool
    {
        return false; // Archived teams cannot have members added
    }

    /**
     * Check if the team can create child teams.
     */
    public function canCreateChildTeams(): bool
    {
        return false; // Archived teams cannot create child teams
    }

    /**
     * Check if the team is visible in the hierarchy.
     */
    public function isVisibleInHierarchy(): bool
    {
        return false; // Archived teams are only visible in archive view
    }

    /**
     * Check if the team can have permissions assigned.
     */
    public function canAssignPermissions(): bool
    {
        return false; // Archived teams cannot have permissions assigned
    }
}
```

## Updating the Team Model

Now, let's update the Team model to use our state machine:

```php
<?php

declare(strict_types=1);

namespace App\Models;

use App\Enums\TeamHierarchyStatus;
use App\States\Team\TeamHierarchyState;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Spatie\ModelStates\HasStates;

// Traits
use App\Models\Traits\HasUlid;
use App\Models\Traits\HasUserTracking;

// Spatie Packages
use Spatie\Sluggable\HasSlug;
use Spatie\Sluggable\SlugOptions;
use Spatie\Activitylog\Traits\LogsActivity;
use Spatie\Activitylog\LogOptions;

class Team extends Model
{
    use HasFactory, SoftDeletes, HasUlid, HasUserTracking, HasSlug, LogsActivity, HasStates;

    protected $fillable = [
        'ulid', 'owner_id', 'parent_id', 'name', 'slug', 'description', 'personal_team', 'hierarchy_state',
    ];

    protected $casts = [
        'personal_team' => 'boolean',
        'hierarchy_state' => TeamHierarchyState::class, // Cast to our state class
    ];

    /**
     * The "booted" method of the model.
     */
    protected static function booted(): void
    {
        // Set default state for new teams
        static::creating(function (Team $team) {
            if (is_null($team->hierarchy_state)) {
                $team->hierarchy_state = TeamHierarchyStatus::PENDING;
            }
        });
    }

    // ... existing methods ...

    /**
     * Check if the team can have members added.
     */
    public function canAddMembers(): bool
    {
        return $this->hierarchy_state->canAddMembers();
    }

    /**
     * Check if the team can create child teams.
     */
    public function canCreateChildTeams(): bool
    {
        return $this->hierarchy_state->canCreateChildTeams();
    }

    /**
     * Check if the team is visible in the hierarchy.
     */
    public function isVisibleInHierarchy(): bool
    {
        return $this->hierarchy_state->isVisibleInHierarchy();
    }

    /**
     * Check if the team can have permissions assigned.
     */
    public function canAssignPermissions(): bool
    {
        return $this->hierarchy_state->canAssignPermissions();
    }
}
```

## Adding a Migration

We need to add the `hierarchy_state` column to the teams table:

```bash
php artisan make:migration add_hierarchy_state_to_teams_table
```

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('teams', function (Blueprint $table) {
            $table->string('hierarchy_state')->default('pending');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('teams', function (Blueprint $table) {
            $table->dropColumn('hierarchy_state');
        });
    }
};
```

## Next Steps

Now that we've implemented the basic state machine for team hierarchies, let's move on to creating transition classes for more complex transitions in the [next section](./047-team-hierarchy-state-transitions.md).

## Additional Resources

- [Spatie Laravel Model States Documentation](https://spatie.be/docs/laravel-model-states/v2/introduction)
- [Laravel Eloquent: Mutators & Casting](https://laravel.com/docs/12.x/eloquent-mutators)
- [PHP 8.1 Enums Documentation](https://www.php.net/manual/en/language.enumerations.php)
