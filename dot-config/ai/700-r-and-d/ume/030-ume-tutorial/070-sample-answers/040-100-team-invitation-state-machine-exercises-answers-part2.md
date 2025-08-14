# Team Invitation State Machine Exercises - Sample Answers (Part 2)

## Exercise 2: Implementing a Custom Transition

**Implement a new transition called `ResendInvitationTransition` that extends the expiration date of a pending invitation and logs the action.**

```php
<?php

declare(strict_types=1);

namespace App\States\TeamInvitation\Transitions;

use App\Models\TeamInvitation;
use App\Models\User;
use App\States\TeamInvitation\Pending;
use Illuminate\Support\Facades\Log;
use Spatie\ModelStates\Transition;

class ResendInvitationTransition extends Transition
{
    public function __construct(
        private User $resendBy,
        private ?string $notes = null
    ) {}

    /**
     * Handle the transition.
     */
    public function handle(TeamInvitation $invitation, Pending $currentState): Pending
    {
        // Check if the user has permission to resend the invitation
        if (! $invitation->team->users()->where('user_id', $this->resendBy->id)->exists() &&
            $invitation->team->owner_id !== $this->resendBy->id) {
            throw new \Exception('You do not have permission to resend this invitation.');
        }

        // Extend the expiration date by 7 days from now
        $invitation->expires_at = now()->addDays(7);
        $invitation->save();

        // Log the transition
        Log::info("Team invitation {$invitation->id} was resent by User {$this->resendBy->id}" . 
            ($this->notes ? " with notes: {$this->notes}" : ""));

        // Record the action in activity log
        activity()
            ->performedOn($invitation)
            ->causedBy($this->resendBy)
            ->withProperties([
                'notes' => $this->notes,
                'state' => 'pending',
                'team_id' => $invitation->team_id,
                'new_expires_at' => $invitation->expires_at->toDateTimeString(),
            ])
            ->log('team_invitation_resent');

        // Return the same state (Pending) since we're not changing states
        return $currentState;
    }
}
```

Now, let's add a method to the TeamInvitation model to make it easier to use this transition:

```php
/**
 * Resend the invitation.
 */
public function resend(User $resendBy, ?string $notes = null): self
{
    $this->state->transition(ResendInvitationTransition::class, $resendBy, $notes);
    return $this;
}
```

Don't forget to update the TeamInvitationState class to allow this transition:

```php
public static function config(): StateConfig
{
    return parent::config()
        ->default(Pending::class) // Default state for new invitations
        ->allowTransition(Pending::class, Accepted::class, Transitions\AcceptInvitationTransition::class)
        ->allowTransition(Pending::class, Rejected::class, Transitions\RejectInvitationTransition::class)
        ->allowTransition(Pending::class, Expired::class, Transitions\ExpireInvitationTransition::class)
        ->allowTransition(Pending::class, Revoked::class, Transitions\RevokeInvitationTransition::class)
        ->allowTransition(Pending::class, Pending::class, Transitions\ResendInvitationTransition::class); // Add this line
}
```
