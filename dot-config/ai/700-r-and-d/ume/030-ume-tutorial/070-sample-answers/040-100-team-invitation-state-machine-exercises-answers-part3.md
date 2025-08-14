# Team Invitation State Machine Exercises - Sample Answers (Part 3)

## Exercise 3: Adding a New State

**Implement a new state called `Canceled` for team invitations.**

First, let's add the new state to the TeamInvitationStatus enum:

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
    case CANCELED = 'canceled'; // Add this line

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
            self::CANCELED => 'Canceled', // Add this line
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
            self::CANCELED => 'blue', // Add this line
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
            self::CANCELED => 'heroicon-o-x-mark', // Add this line
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
            self::CANCELED => 'bg-blue-100 text-blue-800 border-blue-200', // Add this line
        };
    }
}
```

Next, let's create the concrete state class:

```php
<?php

declare(strict_types=1);

namespace App\States\TeamInvitation;

use App\Enums\TeamInvitationStatus;

/**
 * Represents a canceled team invitation.
 */
class Canceled extends TeamInvitationState
{
    /**
     * Get the corresponding enum value for this state.
     */
    public static function status(): TeamInvitationStatus
    {
        return TeamInvitationStatus::CANCELED;
    }

    /**
     * Check if the invitation can be accepted.
     */
    public function canBeAccepted(): bool
    {
        return false; // Already canceled
    }

    /**
     * Check if the invitation can be rejected.
     */
    public function canBeRejected(): bool
    {
        return false; // Already canceled
    }

    /**
     * Check if the invitation can be revoked.
     */
    public function canBeRevoked(): bool
    {
        return false; // Already canceled
    }

    /**
     * Check if the invitation can expire.
     */
    public function canExpire(): bool
    {
        return false; // Already canceled
    }
}
```

Now, let's create a transition class for the new state:

```php
<?php

declare(strict_types=1);

namespace App\States\TeamInvitation\Transitions;

use App\Models\TeamInvitation;
use App\Models\User;
use App\States\TeamInvitation\Canceled;
use App\States\TeamInvitation\Pending;
use Illuminate\Support\Facades\Log;
use Spatie\ModelStates\Transition;

class CancelInvitationTransition extends Transition
{
    public function __construct(
        private User $canceledBy,
        private ?string $reason = null,
        private ?string $notes = null
    ) {}

    /**
     * Handle the transition.
     */
    public function handle(TeamInvitation $invitation, Pending $currentState): Canceled
    {
        // Check if the user has permission to cancel the invitation
        if ($invitation->email !== $this->canceledBy->email) {
            throw new \Exception('You can only cancel invitations sent to your email address.');
        }

        // Log the transition
        Log::info("Team invitation {$invitation->id} was canceled by User {$this->canceledBy->id}" . 
            ($this->reason ? " for reason: {$this->reason}" : "") .
            ($this->notes ? " with notes: {$this->notes}" : ""));

        // Record the action in activity log
        activity()
            ->performedOn($invitation)
            ->causedBy($this->canceledBy)
            ->withProperties([
                'reason' => $this->reason,
                'notes' => $this->notes,
                'from_state' => 'pending',
                'to_state' => 'canceled',
                'team_id' => $invitation->team_id,
            ])
            ->log('team_invitation_canceled');

        return new Canceled($invitation);
    }
}
```

Finally, let's update the TeamInvitationState class to allow the new transition:

```php
public static function config(): StateConfig
{
    return parent::config()
        ->default(Pending::class) // Default state for new invitations
        ->allowTransition(Pending::class, Accepted::class, Transitions\AcceptInvitationTransition::class)
        ->allowTransition(Pending::class, Rejected::class, Transitions\RejectInvitationTransition::class)
        ->allowTransition(Pending::class, Expired::class, Transitions\ExpireInvitationTransition::class)
        ->allowTransition(Pending::class, Revoked::class, Transitions\RevokeInvitationTransition::class)
        ->allowTransition(Pending::class, Canceled::class, Transitions\CancelInvitationTransition::class); // Add this line
}
```

And add a helper method to the TeamInvitation model:

```php
/**
 * Cancel the invitation.
 */
public function cancel(User $canceledBy, ?string $reason = null, ?string $notes = null): self
{
    $this->state->transition(CancelInvitationTransition::class, $canceledBy, $reason, $notes);
    return $this;
}

/**
 * Check if the invitation is canceled.
 */
public function isCanceled(): bool
{
    return $this->isInState(TeamInvitationStatus::CANCELED);
}
```
