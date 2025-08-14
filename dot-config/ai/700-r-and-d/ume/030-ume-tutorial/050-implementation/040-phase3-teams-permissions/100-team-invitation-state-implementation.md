# Team Invitation State Implementation

In this section, we'll implement the team invitation state machine by creating the necessary enum, state classes, and integrating them with our TeamInvitation model.

## Creating the TeamInvitationStatus Enum

First, let's create an enum to represent the possible states of a team invitation:

```php
<?php

declare(strict_types=1);

namespace App\Enums;

use Filament\Support\Contracts\HasLabel;
use Filament\Support\Contracts\HasColor;
use Filament\Support\Contracts\HasIcon;

enum TeamInvitationStatus: string implements HasLabel, HasColor, HasIcon
{
    case PENDING = 'pending';
    case ACCEPTED = 'accepted';
    case REJECTED = 'rejected';
    case EXPIRED = 'expired';
    case REVOKED = 'revoked';

    /**
     * Get a human-readable label for the status.
     */
    public function getLabel(): ?string
    {
        return match ($this) {
            self::PENDING => 'Pending',
            self::ACCEPTED => 'Accepted',
            self::REJECTED => 'Rejected',
            self::EXPIRED => 'Expired',
            self::REVOKED => 'Revoked',
        };
    }

    /**
     * Get a color for the status (for UI purposes).
     */
    public function getColor(): string
    {
        return match ($this) {
            self::PENDING => 'yellow',
            self::ACCEPTED => 'green',
            self::REJECTED => 'red',
            self::EXPIRED => 'gray',
            self::REVOKED => 'purple',
        };
    }

    /**
     * Get an icon for the status (for UI purposes).
     */
    public function getIcon(): string
    {
        return match ($this) {
            self::PENDING => 'heroicon-o-clock',
            self::ACCEPTED => 'heroicon-o-check-circle',
            self::REJECTED => 'heroicon-o-x-circle',
            self::EXPIRED => 'heroicon-o-calendar',
            self::REVOKED => 'heroicon-o-ban',
        };
    }

    /**
     * Get Tailwind CSS classes for the status.
     */
    public function getTailwindClasses(): string
    {
        return match ($this) {
            self::PENDING => 'bg-yellow-100 text-yellow-800 border-yellow-200',
            self::ACCEPTED => 'bg-green-100 text-green-800 border-green-200',
            self::REJECTED => 'bg-red-100 text-red-800 border-red-200',
            self::EXPIRED => 'bg-gray-100 text-gray-800 border-gray-200',
            self::REVOKED => 'bg-purple-100 text-purple-800 border-purple-200',
        };
    }
}
```

## Creating the Base State Class

Next, let's create a directory for our team invitation state classes and the base `TeamInvitationState` class:

```php
<?php

declare(strict_types=1);

namespace App\States\TeamInvitation;

use App\Enums\TeamInvitationStatus;
use Spatie\ModelStates\State;
use Spatie\ModelStates\StateConfig;

/**
 * Abstract base class for all team invitation states.
 */
abstract class TeamInvitationState extends State
{
    /**
     * Get the corresponding enum value for this state.
     */
    abstract public static function status(): TeamInvitationStatus;

    /**
     * Configure the state machine.
     */
    public static function config(): StateConfig
    {
        return parent::config()
            ->default(Pending::class) // Default state for new invitations
            ->allowTransition(Pending::class, Accepted::class, Transitions\AcceptInvitationTransition::class)
            ->allowTransition(Pending::class, Rejected::class, Transitions\RejectInvitationTransition::class)
            ->allowTransition(Pending::class, Expired::class, Transitions\ExpireInvitationTransition::class)
            ->allowTransition(Pending::class, Revoked::class, Transitions\RevokeInvitationTransition::class);
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
}
```

## Implementing the Concrete State Classes

Now, let's implement each concrete state class:

### Pending State

```php
<?php

declare(strict_types=1);

namespace App\States\TeamInvitation;

use App\Enums\TeamInvitationStatus;

/**
 * Represents a pending team invitation.
 */
class Pending extends TeamInvitationState
{
    /**
     * Get the corresponding enum value for this state.
     */
    public static function status(): TeamInvitationStatus
    {
        return TeamInvitationStatus::PENDING;
    }

    /**
     * Check if the invitation can be accepted.
     */
    public function canBeAccepted(): bool
    {
        return true;
    }

    /**
     * Check if the invitation can be rejected.
     */
    public function canBeRejected(): bool
    {
        return true;
    }

    /**
     * Check if the invitation can be revoked.
     */
    public function canBeRevoked(): bool
    {
        return true;
    }

    /**
     * Check if the invitation can expire.
     */
    public function canExpire(): bool
    {
        return true;
    }
}
```

### Accepted State

```php
<?php

declare(strict_types=1);

namespace App\States\TeamInvitation;

use App\Enums\TeamInvitationStatus;

/**
 * Represents an accepted team invitation.
 */
class Accepted extends TeamInvitationState
{
    /**
     * Get the corresponding enum value for this state.
     */
    public static function status(): TeamInvitationStatus
    {
        return TeamInvitationStatus::ACCEPTED;
    }

    /**
     * Check if the invitation can be accepted.
     */
    public function canBeAccepted(): bool
    {
        return false; // Already accepted
    }

    /**
     * Check if the invitation can be rejected.
     */
    public function canBeRejected(): bool
    {
        return false; // Already accepted
    }

    /**
     * Check if the invitation can be revoked.
     */
    public function canBeRevoked(): bool
    {
        return false; // Already accepted
    }

    /**
     * Check if the invitation can expire.
     */
    public function canExpire(): bool
    {
        return false; // Already accepted
    }
}
```

### Rejected State

```php
<?php

declare(strict_types=1);

namespace App\States\TeamInvitation;

use App\Enums\TeamInvitationStatus;

/**
 * Represents a rejected team invitation.
 */
class Rejected extends TeamInvitationState
{
    /**
     * Get the corresponding enum value for this state.
     */
    public static function status(): TeamInvitationStatus
    {
        return TeamInvitationStatus::REJECTED;
    }

    /**
     * Check if the invitation can be accepted.
     */
    public function canBeAccepted(): bool
    {
        return false; // Already rejected
    }

    /**
     * Check if the invitation can be rejected.
     */
    public function canBeRejected(): bool
    {
        return false; // Already rejected
    }

    /**
     * Check if the invitation can be revoked.
     */
    public function canBeRevoked(): bool
    {
        return false; // Already rejected
    }

    /**
     * Check if the invitation can expire.
     */
    public function canExpire(): bool
    {
        return false; // Already rejected
    }
}
```

### Expired State

```php
<?php

declare(strict_types=1);

namespace App\States\TeamInvitation;

use App\Enums\TeamInvitationStatus;

/**
 * Represents an expired team invitation.
 */
class Expired extends TeamInvitationState
{
    /**
     * Get the corresponding enum value for this state.
     */
    public static function status(): TeamInvitationStatus
    {
        return TeamInvitationStatus::EXPIRED;
    }

    /**
     * Check if the invitation can be accepted.
     */
    public function canBeAccepted(): bool
    {
        return false; // Already expired
    }

    /**
     * Check if the invitation can be rejected.
     */
    public function canBeRejected(): bool
    {
        return false; // Already expired
    }

    /**
     * Check if the invitation can be revoked.
     */
    public function canBeRevoked(): bool
    {
        return false; // Already expired
    }

    /**
     * Check if the invitation can expire.
     */
    public function canExpire(): bool
    {
        return false; // Already expired
    }
}
```

### Revoked State

```php
<?php

declare(strict_types=1);

namespace App\States\TeamInvitation;

use App\Enums\TeamInvitationStatus;

/**
 * Represents a revoked team invitation.
 */
class Revoked extends TeamInvitationState
{
    /**
     * Get the corresponding enum value for this state.
     */
    public static function status(): TeamInvitationStatus
    {
        return TeamInvitationStatus::REVOKED;
    }

    /**
     * Check if the invitation can be accepted.
     */
    public function canBeAccepted(): bool
    {
        return false; // Already revoked
    }

    /**
     * Check if the invitation can be rejected.
     */
    public function canBeRejected(): bool
    {
        return false; // Already revoked
    }

    /**
     * Check if the invitation can be revoked.
     */
    public function canBeRevoked(): bool
    {
        return false; // Already revoked
    }

    /**
     * Check if the invitation can expire.
     */
    public function canExpire(): bool
    {
        return false; // Already revoked
    }
}
```

## Updating the TeamInvitation Model

Now, let's update our TeamInvitation model to use the state machine:

```php
<?php

namespace App\Models;

use App\Enums\TeamInvitationStatus;
use App\States\TeamInvitation\TeamInvitationState;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;
use Spatie\ModelStates\HasStates;

class TeamInvitation extends Model
{
    use HasFactory, HasStates;

    protected $fillable = [
        'team_id',
        'email',
        'role',
        'token',
        'expires_at',
        'state',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
        'state' => TeamInvitationState::class,
    ];

    protected static function boot()
    {
        parent::boot();

        static::creating(function ($invitation) {
            $invitation->token = $invitation->token ?? Str::random(40);
            $invitation->expires_at = $invitation->expires_at ?? now()->addDays(7);
            
            // Set default state if not provided
            if (is_null($invitation->state)) {
                $invitation->state = TeamInvitationStatus::PENDING;
            }
        });
    }

    /**
     * Get the team that owns the invitation.
     */
    public function team(): BelongsTo
    {
        return $this->belongsTo(Team::class);
    }

    /**
     * Get the user who created the invitation.
     */
    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    /**
     * Check if the invitation has expired.
     */
    public function hasExpired(): bool
    {
        return $this->expires_at->isPast();
    }

    /**
     * Check if the invitation is still valid.
     */
    public function isValid(): bool
    {
        return $this->state->equals(TeamInvitationStatus::PENDING) && !$this->hasExpired();
    }
}
```

## Creating the Migration

Let's create a migration to add the state column to the team_invitations table:

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
        Schema::create('team_invitations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('team_id')->constrained()->cascadeOnDelete();
            $table->string('email');
            $table->string('role')->nullable();
            $table->string('token', 40)->unique();
            $table->string('state')->default('pending');
            $table->timestamp('expires_at')->nullable();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->unique(['team_id', 'email']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('team_invitations');
    }
};
```

In the next section, we'll implement the transition classes for our team invitation state machine.
