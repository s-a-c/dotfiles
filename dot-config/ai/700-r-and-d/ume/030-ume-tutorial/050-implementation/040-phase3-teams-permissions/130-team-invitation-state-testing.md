# Team Invitation State Testing

In this section, we'll implement comprehensive tests for our team invitation state machine using Pest PHP. We'll use PHP attributes instead of PHPDocs for our test methods.

## Setting Up the Test Environment

First, let's create a test file for our team invitation state machine:

```php
<?php

namespace Tests\Feature;

use App\Enums\TeamInvitationStatus;use App\Models\Team;use App\Models\TeamInvitation;use App\Models\User;use App\States\TeamInvitation\Accepted;use App\States\TeamInvitation\Expired;use App\States\TeamInvitation\Pending;use App\States\TeamInvitation\Rejected;use App\States\TeamInvitation\Revoked;use App\States\TeamInvitation\Transitions\AcceptInvitationTransition;use App\States\TeamInvitation\Transitions\ExpireInvitationTransition;use App\States\TeamInvitation\Transitions\RejectInvitationTransition;use App\States\TeamInvitation\Transitions\RevokeInvitationTransition;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;use Spatie\ModelStates\Exceptions\TransitionNotFound;

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

## Testing the TeamInvitationController

Let's also create tests for our TeamInvitationController:

```php
<?php

namespace Tests\Feature;

use App\Enums\TeamInvitationStatus;use App\Models\Team;use App\Models\TeamInvitation;use App\Models\User;use App\Notifications\TeamInvitation as TeamInvitationNotification;use App\States\TeamInvitation\Accepted;use App\States\TeamInvitation\Pending;use App\States\TeamInvitation\Rejected;use App\States\TeamInvitation\Revoked;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Support\Facades\Notification;use Illuminate\Support\Facades\URL;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class TeamInvitationControllerTest extends TestCase
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
    public function owner_can_send_invitation()
    {
        Notification::fake();

        $response = $this->actingAs($this->owner)
            ->post(route('team-invitations.store', $this->team), [
                'email' => 'newuser@example.com',
                'role' => 'member',
            ]);

        $response->assertSessionHasNoErrors();
        $response->assertSessionHas('success');

        $this->assertDatabaseHas('team_invitations', [
            'team_id' => $this->team->id,
            'email' => 'newuser@example.com',
            'role' => 'member',
        ]);

        // Check that the invitation is in the pending state
        $invitation = TeamInvitation::where('email', 'newuser@example.com')->first();
        $this->assertTrue($invitation->state instanceof Pending);
    }

    #[Test]
    public function cannot_invite_existing_team_member()
    {
        // Add the invitee to the team
        $this->team->users()->attach($this->invitee->id, ['role' => 'member']);

        $response = $this->actingAs($this->owner)
            ->post(route('team-invitations.store', $this->team), [
                'email' => $this->invitee->email,
                'role' => 'member',
            ]);

        $response->assertSessionHasErrors('email');
        $this->assertEquals(
            'This user is already on the team.',
            session('errors')->get('email')[0]
        );
    }

    #[Test]
    public function cannot_send_duplicate_invitation()
    {
        $response = $this->actingAs($this->owner)
            ->post(route('team-invitations.store', $this->team), [
                'email' => $this->invitee->email,
                'role' => 'member',
            ]);

        $response->assertSessionHasErrors('email');
        $this->assertEquals(
            'An invitation has already been sent to this email address.',
            session('errors')->get('email')[0]
        );
    }

    #[Test]
    public function user_can_accept_invitation()
    {
        $url = URL::signedRoute('team-invitations.accept', [
            'token' => $this->invitation->token,
        ]);

        $response = $this->actingAs($this->invitee)
            ->get($url);

        $response->assertRedirect(route('teams.show', $this->team));
        $response->assertSessionHas('success');

        // Check that the invitation is in the accepted state
        $this->invitation->refresh();
        $this->assertTrue($this->invitation->state instanceof Accepted);

        // Check that the user was added to the team
        $this->assertTrue($this->team->users->contains($this->invitee));
    }

    #[Test]
    public function user_can_reject_invitation()
    {
        $url = URL::signedRoute('team-invitations.reject', [
            'token' => $this->invitation->token,
        ]);

        $response = $this->actingAs($this->invitee)
            ->get($url);

        $response->assertRedirect(route('dashboard'));
        $response->assertSessionHas('success');

        // Check that the invitation is in the rejected state
        $this->invitation->refresh();
        $this->assertTrue($this->invitation->state instanceof Rejected);

        // Check that the user was not added to the team
        $this->assertFalse($this->team->users->contains($this->invitee));
    }

    #[Test]
    public function owner_can_revoke_invitation()
    {
        $response = $this->actingAs($this->owner)
            ->delete(route('team-invitations.revoke', [$this->team, $this->invitation]), [
                'reason' => 'No longer needed',
            ]);

        $response->assertSessionHas('success');

        // Check that the invitation is in the revoked state
        $this->invitation->refresh();
        $this->assertTrue($this->invitation->state instanceof Revoked);
    }

    #[Test]
    public function owner_can_resend_invitation()
    {
        Notification::fake();

        $response = $this->actingAs($this->owner)
            ->post(route('team-invitations.resend', [$this->team, $this->invitation]));

        $response->assertSessionHas('success');

        // Check that the invitation is still in the pending state
        $this->invitation->refresh();
        $this->assertTrue($this->invitation->state instanceof Pending);

        // Check that the expiration date was updated
        $this->assertTrue($this->invitation->expires_at->isAfter(now()->addDays(6)));

        // Check that the notification was sent
        Notification::assertSentTo(
            $this->invitee,
            TeamInvitationNotification::class
        );
    }

    #[Test]
    public function non_owner_cannot_revoke_invitation()
    {
        $otherUser = User::factory()->create();
        $this->team->users()->attach($otherUser->id, ['role' => 'member']);

        $response = $this->actingAs($otherUser)
            ->delete(route('team-invitations.revoke', [$this->team, $this->invitation]));

        $response->assertForbidden();

        // Check that the invitation is still in the pending state
        $this->invitation->refresh();
        $this->assertTrue($this->invitation->state instanceof Pending);
    }

    #[Test]
    public function cannot_accept_invitation_for_different_user()
    {
        $otherUser = User::factory()->create();

        $url = URL::signedRoute('team-invitations.accept', [
            'token' => $this->invitation->token,
        ]);

        $response = $this->actingAs($otherUser)
            ->get($url);

        $response->assertSessionHasErrors('invitation');

        // Check that the invitation is still in the pending state
        $this->invitation->refresh();
        $this->assertTrue($this->invitation->state instanceof Pending);

        // Check that the user was not added to the team
        $this->assertFalse($this->team->users->contains($otherUser));
    }

    #[Test]
    public function cannot_accept_expired_invitation()
    {
        // Update the invitation to be expired
        $this->invitation->update([
            'expires_at' => now()->subDay(),
        ]);

        $url = URL::signedRoute('team-invitations.accept', [
            'token' => $this->invitation->token,
        ]);

        $response = $this->actingAs($this->invitee)
            ->get($url);

        $response->assertSessionHasErrors('invitation');

        // Check that the user was not added to the team
        $this->assertFalse($this->team->users->contains($this->invitee));
    }
}
```

## Testing the Livewire Components

Let's also create tests for our Livewire components:

```php
<?php

namespace Tests\Feature\Livewire;

use App\Enums\TeamInvitationStatus;use App\Http\Livewire\Teams\InviteMember;use App\Models\Team;use App\Models\TeamInvitation;use App\Models\User;use App\Notifications\TeamInvitation as TeamInvitationNotification;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Support\Facades\Notification;use Livewire\Livewire;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class InviteMemberTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function can_invite_team_member()
    {
        Notification::fake();

        $owner = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $owner->id]);

        Livewire::actingAs($owner)
            ->test(InviteMember::class, ['team' => $team])
            ->set('email', 'newuser@example.com')
            ->set('role', 'member')
            ->call('invite')
            ->assertHasNoErrors()
            ->assertEmitted('invitationSent');

        $this->assertDatabaseHas('team_invitations', [
            'team_id' => $team->id,
            'email' => 'newuser@example.com',
            'role' => 'member',
        ]);
    }

    #[Test]
    public function cannot_invite_with_invalid_email()
    {
        $owner = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $owner->id]);

        Livewire::actingAs($owner)
            ->test(InviteMember::class, ['team' => $team])
            ->set('email', 'not-an-email')
            ->set('role', 'member')
            ->call('invite')
            ->assertHasErrors(['email' => 'email']);
    }

    #[Test]
    public function cannot_invite_existing_team_member()
    {
        $owner = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $owner->id]);
        $member = User::factory()->create();
        $team->users()->attach($member->id, ['role' => 'member']);

        Livewire::actingAs($owner)
            ->test(InviteMember::class, ['team' => $team])
            ->set('email', $member->email)
            ->set('role', 'member')
            ->call('invite')
            ->assertHasErrors('email');
    }
}
```

```php
<?php

namespace Tests\Feature\Livewire;

use App\Enums\TeamInvitationStatus;use App\Http\Livewire\Teams\PendingInvitations;use App\Models\Team;use App\Models\TeamInvitation;use App\Models\User;use App\States\TeamInvitation\Pending;use App\States\TeamInvitation\Revoked;use Illuminate\Foundation\Testing\RefreshDatabase;use Livewire\Livewire;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class PendingInvitationsTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function can_see_pending_invitations()
    {
        $owner = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $owner->id]);
        $invitation = TeamInvitation::factory()->create([
            'team_id' => $team->id,
            'email' => 'user@example.com',
            'state' => TeamInvitationStatus::PENDING,
        ]);

        Livewire::actingAs($owner)
            ->test(PendingInvitations::class, ['team' => $team])
            ->assertSee('user@example.com');
    }

    #[Test]
    public function can_revoke_invitation()
    {
        $owner = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $owner->id]);
        $invitation = TeamInvitation::factory()->create([
            'team_id' => $team->id,
            'email' => 'user@example.com',
            'state' => TeamInvitationStatus::PENDING,
        ]);

        Livewire::actingAs($owner)
            ->test(PendingInvitations::class, ['team' => $team])
            ->call('revoke', $invitation->id)
            ->assertEmitted('invitationRevoked');

        $invitation->refresh();
        $this->assertTrue($invitation->state instanceof Revoked);
    }

    #[Test]
    public function non_owner_cannot_revoke_invitation()
    {
        $owner = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $owner->id]);
        $invitation = TeamInvitation::factory()->create([
            'team_id' => $team->id,
            'email' => 'user@example.com',
            'state' => TeamInvitationStatus::PENDING,
        ]);

        $otherUser = User::factory()->create();
        $team->users()->attach($otherUser->id, ['role' => 'member']);

        Livewire::actingAs($otherUser)
            ->test(PendingInvitations::class, ['team' => $team])
            ->call('revoke', $invitation->id)
            ->assertHasErrors('revoke');

        $invitation->refresh();
        $this->assertTrue($invitation->state instanceof Pending);
    }
}
```

## Creating a Factory for TeamInvitation

To make testing easier, let's create a factory for the TeamInvitation model:

```php
<?php

namespace Database\Factories;

use App\Enums\TeamInvitationStatus;
use App\Models\Team;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class TeamInvitationFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'team_id' => Team::factory(),
            'email' => $this->faker->unique()->safeEmail(),
            'role' => 'member',
            'token' => Str::random(40),
            'expires_at' => now()->addDays(7),
            'created_by' => User::factory(),
            'state' => TeamInvitationStatus::PENDING,
        ];
    }

    /**
     * Indicate that the invitation is accepted.
     */
    public function accepted(): self
    {
        return $this->state(function (array $attributes) {
            return [
                'state' => TeamInvitationStatus::ACCEPTED,
            ];
        });
    }

    /**
     * Indicate that the invitation is rejected.
     */
    public function rejected(): self
    {
        return $this->state(function (array $attributes) {
            return [
                'state' => TeamInvitationStatus::REJECTED,
            ];
        });
    }

    /**
     * Indicate that the invitation is expired.
     */
    public function expired(): self
    {
        return $this->state(function (array $attributes) {
            return [
                'state' => TeamInvitationStatus::EXPIRED,
                'expires_at' => now()->subDays(1),
            ];
        });
    }

    /**
     * Indicate that the invitation is revoked.
     */
    public function revoked(): self
    {
        return $this->state(function (array $attributes) {
            return [
                'state' => TeamInvitationStatus::REVOKED,
            ];
        });
    }
}
```

In the next section, we'll create exercises and sample answers for the team invitation state machine.
