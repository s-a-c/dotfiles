# Team Invitation State Machine Exercises - Sample Answers (Part 7)

## Exercise 7: Testing State Transitions

**Write comprehensive tests for the team invitation state machine.**

```php
<?php

namespace Tests\Feature;

use App\Enums\TeamInvitationStatus;use App\Models\Team;use App\Models\TeamInvitation;use App\Models\User;use App\States\TeamInvitation\Accepted;use App\States\TeamInvitation\Expired;use App\States\TeamInvitation\Pending;use App\States\TeamInvitation\Rejected;use App\States\TeamInvitation\Revoked;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;use Spatie\ModelStates\Exceptions\TransitionNotFound;

class TeamInvitationStateTest extends TestCase
{
    use RefreshDatabase;

    protected Team $team;
    protected User $owner;
    protected User $invitee;
    protected TeamInvitation $invitation;

    protected function setUp(): void
    {
        parent::setUp();

        // Create a team owner
        $this->owner = User::factory()->create();

        // Create a team
        $this->team = Team::factory()->create([
            'owner_id' => $this->owner->id,
        ]);

        // Create a user to invite
        $this->invitee = User::factory()->create();

        // Create a pending invitation
        $this->invitation = TeamInvitation::factory()->create([
            'team_id' => $this->team->id,
            'email' => $this->invitee->email,
            'role' => 'member',
            'created_by' => $this->owner->id,
            'expires_at' => now()->addDays(7),
            'state' => TeamInvitationStatus::PENDING,
        ]);
    }

    #[Test]
    public function it_creates_invitation_with_pending_state()
    {
        $invitation = TeamInvitation::factory()->create([
            'team_id' => $this->team->id,
            'email' => 'newuser@example.com',
        ]);

        $this->assertTrue($invitation->state instanceof Pending);
        $this->assertEquals(TeamInvitationStatus::PENDING, $invitation->state->status());
    }

    #[Test]
    public function it_can_transition_from_pending_to_accepted()
    {
        $this->invitation->accept($this->invitee);

        $this->invitation->refresh();
        $this->assertTrue($this->invitation->state instanceof Accepted);
        $this->assertEquals(TeamInvitationStatus::ACCEPTED, $this->invitation->state->status());
        
        // Check that the user was added to the team
        $this->assertTrue($this->team->users->contains($this->invitee));
    }

    #[Test]
    public function it_can_transition_from_pending_to_rejected()
    {
        $this->invitation->reject($this->invitee, 'Not interested');

        $this->invitation->refresh();
        $this->assertTrue($this->invitation->state instanceof Rejected);
        $this->assertEquals(TeamInvitationStatus::REJECTED, $this->invitation->state->status());
        
        // Check that the user was not added to the team
        $this->assertFalse($this->team->users->contains($this->invitee));
    }

    #[Test]
    public function it_can_transition_from_pending_to_expired()
    {
        // Update the invitation to be expired
        $this->invitation->update([
            'expires_at' => now()->subDay(),
        ]);

        $this->invitation->expire();

        $this->invitation->refresh();
        $this->assertTrue($this->invitation->state instanceof Expired);
        $this->assertEquals(TeamInvitationStatus::EXPIRED, $this->invitation->state->status());
    }

    #[Test]
    public function it_can_transition_from_pending_to_revoked()
    {
        $this->invitation->revoke($this->owner, 'No longer needed');

        $this->invitation->refresh();
        $this->assertTrue($this->invitation->state instanceof Revoked);
        $this->assertEquals(TeamInvitationStatus::REVOKED, $this->invitation->state->status());
    }

    #[Test]
    public function it_cannot_accept_invitation_for_different_user()
    {
        $otherUser = User::factory()->create();

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('This invitation is not for you.');

        $this->invitation->accept($otherUser);
    }

    #[Test]
    public function it_cannot_accept_expired_invitation()
    {
        // Update the invitation to be expired
        $this->invitation->update([
            'expires_at' => now()->subDay(),
        ]);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('This invitation has expired.');

        $this->invitation->accept($this->invitee);
    }

    #[Test]
    public function it_cannot_transition_from_accepted_to_any_other_state()
    {
        // First accept the invitation
        $this->invitation->accept($this->invitee);
        $this->invitation->refresh();

        // Try to reject it
        $this->expectException(TransitionNotFound::class);
        $this->invitation->reject($this->invitee);
    }

    #[Test]
    public function it_cannot_transition_from_rejected_to_any_other_state()
    {
        // First reject the invitation
        $this->invitation->reject($this->invitee);
        $this->invitation->refresh();

        // Try to accept it
        $this->expectException(TransitionNotFound::class);
        $this->invitation->accept($this->invitee);
    }

    #[Test]
    public function it_cannot_transition_from_expired_to_any_other_state()
    {
        // First expire the invitation
        $this->invitation->update([
            'expires_at' => now()->subDay(),
        ]);
        $this->invitation->expire();
        $this->invitation->refresh();

        // Try to accept it
        $this->expectException(TransitionNotFound::class);
        $this->invitation->accept($this->invitee);
    }

    #[Test]
    public function it_cannot_transition_from_revoked_to_any_other_state()
    {
        // First revoke the invitation
        $this->invitation->revoke($this->owner);
        $this->invitation->refresh();

        // Try to accept it
        $this->expectException(TransitionNotFound::class);
        $this->invitation->accept($this->invitee);
    }

    #[Test]
    public function it_cannot_expire_invitation_that_is_not_expired()
    {
        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('This invitation has not expired yet.');

        $this->invitation->expire();
    }

    #[Test]
    public function it_cannot_revoke_invitation_without_permission()
    {
        $otherUser = User::factory()->create();

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('You do not have permission to revoke this invitation.');

        $this->invitation->revoke($otherUser);
    }

    #[Test]
    public function it_can_check_if_invitation_is_in_specific_state()
    {
        $this->assertTrue($this->invitation->isPending());
        $this->assertFalse($this->invitation->isAccepted());
        $this->assertFalse($this->invitation->isRejected());
        $this->assertFalse($this->invitation->isExpired());
        $this->assertFalse($this->invitation->isRevoked());

        $this->invitation->accept($this->invitee);
        $this->invitation->refresh();

        $this->assertFalse($this->invitation->isPending());
        $this->assertTrue($this->invitation->isAccepted());
        $this->assertFalse($this->invitation->isRejected());
        $this->assertFalse($this->invitation->isExpired());
        $this->assertFalse($this->invitation->isRevoked());
    }

    #[Test]
    public function it_can_check_if_invitation_has_expired()
    {
        $this->assertFalse($this->invitation->hasExpired());

        $this->invitation->update([
            'expires_at' => now()->subDay(),
        ]);

        $this->assertTrue($this->invitation->hasExpired());
    }

    #[Test]
    public function it_can_check_if_invitation_is_valid()
    {
        $this->assertTrue($this->invitation->isValid());

        // Expire the invitation
        $this->invitation->update([
            'expires_at' => now()->subDay(),
        ]);

        $this->assertFalse($this->invitation->isValid());

        // Reset expiration but change state
        $this->invitation->update([
            'expires_at' => now()->addDay(),
        ]);
        $this->invitation->reject($this->invitee);
        $this->invitation->refresh();

        $this->assertFalse($this->invitation->isValid());
    }
}
```
