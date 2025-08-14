# Team Invitation State Machine Exercises - Sample Answers (Part 8)

## Exercise 8: Implementing Invitation Reminders

**Implement a feature to send reminder emails for pending invitations.**

First, let's create a notification class for the reminder:

```php
<?php

namespace App\Notifications;

use App\Models\TeamInvitation;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;
use Illuminate\Support\Facades\URL;

class TeamInvitationReminder extends Notification implements ShouldQueue
{
    use Queueable;

    protected $invitation;

    public function __construct(TeamInvitation $invitation)
    {
        $this->invitation = $invitation;
    }

    public function via($notifiable)
    {
        return ['mail'];
    }

    public function toMail($notifiable)
    {
        $acceptUrl = URL::signedRoute('team-invitations.accept', [
            'token' => $this->invitation->token,
        ]);

        $rejectUrl = URL::signedRoute('team-invitations.reject', [
            'token' => $this->invitation->token,
        ]);

        return (new MailMessage)
            ->subject('Reminder: Team Invitation')
            ->greeting('Hello!')
            ->line('This is a reminder that you have been invited to join the ' . $this->invitation->team->name . ' team.')
            ->line('This invitation will expire on ' . $this->invitation->expires_at->format('F j, Y') . ' (' . $this->invitation->expires_at->diffForHumans() . ').')
            ->action('Accept Invitation', $acceptUrl)
            ->line('If you do not wish to join this team, you can ignore this email or click the link below:')
            ->line('[Reject Invitation](' . $rejectUrl . ')')
            ->line('Thank you for using our application!');
    }
}
```

Next, let's create a command to send reminders for invitations that are about to expire:

```php
<?php

namespace App\Console\Commands;

use App\Models\TeamInvitation;
use App\Models\User;
use App\Notifications\TeamInvitationReminder;
use App\States\TeamInvitation\Pending;
use Illuminate\Console\Command;

class SendTeamInvitationReminders extends Command
{
    protected $signature = 'team-invitations:remind {days=2 : Number of days before expiration to send reminders}';
    protected $description = 'Send reminders for team invitations that are about to expire';

    public function handle()
    {
        $days = (int) $this->argument('days');
        $expirationDate = now()->addDays($days);

        // Find invitations that are about to expire
        $invitations = TeamInvitation::whereState('state', Pending::class)
            ->where('expires_at', '>=', $expirationDate->startOfDay())
            ->where('expires_at', '<=', $expirationDate->endOfDay())
            ->where(function ($query) {
                // Only include invitations that haven't had too many reminders
                $query->where('reminder_count', '<', 3)
                    ->orWhereNull('reminder_count');
            })
            ->get();

        $count = 0;
        foreach ($invitations as $invitation) {
            try {
                // Find the user if they exist
                $user = User::where('email', $invitation->email)->first();
                
                if ($user) {
                    $user->notify(new TeamInvitationReminder($invitation));
                } else {
                    // Send to non-registered user
                    // This would typically involve sending an email directly
                }

                // Increment the reminder count
                $invitation->increment('reminder_count');
                $invitation->update(['last_reminder_at' => now()]);
                
                $count++;
            } catch (\Exception $e) {
                $this->error("Failed to send reminder for invitation {$invitation->id}: {$e->getMessage()}");
            }
        }

        $this->info("Sent {$count} invitation reminders.");

        return Command::SUCCESS;
    }
}
```

Let's add the necessary columns to the team_invitations table:

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
        Schema::table('team_invitations', function (Blueprint $table) {
            $table->unsignedInteger('reminder_count')->default(0)->after('expires_at');
            $table->timestamp('last_reminder_at')->nullable()->after('reminder_count');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('team_invitations', function (Blueprint $table) {
            $table->dropColumn(['reminder_count', 'last_reminder_at']);
        });
    }
};
```

Now, let's schedule the command to run daily in the `app/Console/Kernel.php` file:

```php
protected function schedule(Schedule $schedule)
{
    // ... other scheduled commands ...
    $schedule->command('team-invitations:expire')->daily();
    $schedule->command('team-invitations:remind')->daily();
}
```

Finally, let's add a method to the TeamInvitationController to manually send reminders:

```php
/**
 * Send a reminder for an invitation.
 */
public function sendReminder(Team $team, TeamInvitation $invitation)
{
    Gate::authorize('sendReminder', [$team, $invitation]);

    // Check if the invitation is still pending
    if (! $invitation->isPending()) {
        return back()->withErrors([
            'invitation' => 'This invitation cannot be reminded because it is not pending.',
        ]);
    }

    // Check if a reminder was sent recently
    if ($invitation->last_reminder_at && $invitation->last_reminder_at->isAfter(now()->subHours(24))) {
        return back()->withErrors([
            'invitation' => 'A reminder was already sent in the last 24 hours.',
        ]);
    }

    // Check if too many reminders have been sent
    if ($invitation->reminder_count >= 3) {
        return back()->withErrors([
            'invitation' => 'The maximum number of reminders has been reached for this invitation.',
        ]);
    }

    // Send the reminder
    $user = User::where('email', $invitation->email)->first();
    if ($user) {
        $user->notify(new TeamInvitationReminder($invitation));
    } else {
        // Send to non-registered user
    }

    // Update the reminder count and timestamp
    $invitation->increment('reminder_count');
    $invitation->update(['last_reminder_at' => now()]);

    return back()->with('success', 'Reminder sent successfully.');
}
```

And add the route:

```php
Route::post('/teams/{team}/invitations/{invitation}/remind', [TeamInvitationController::class, 'sendReminder'])
    ->name('team-invitations.remind');
```

Update the TeamInvitationPolicy to include the sendReminder method:

```php
/**
 * Determine whether the user can send a reminder for an invitation.
 */
public function sendReminder(User $user, Team $team, TeamInvitation $invitation): bool
{
    return $invitation->team_id === $team->id && 
           ($user->ownsTeam($team) || 
            $user->hasTeamPermission($team, 'team:invite') || 
            $user->id === $invitation->created_by);
}
```

Finally, let's add a "Send Reminder" button to our PendingInvitations component:

```php
public function sendReminder(TeamInvitation $invitation)
{
    $this->authorize('sendReminder', [$this->team, $invitation]);

    try {
        app(TeamInvitationController::class)->sendReminder($this->team, $invitation);
        $this->emit('reminderSent');
    } catch (\Exception $e) {
        $this->addError('reminder', $e->getMessage());
    }
}
```

And update the view:

```blade
@if($invitation->isPending())
    @can('resend', [$team, $invitation])
        <button wire:click="resend({{ $invitation->id }})" class="text-indigo-600 hover:text-indigo-900 mr-3">Resend</button>
    @endcan
    
    @can('sendReminder', [$team, $invitation])
        <button wire:click="sendReminder({{ $invitation->id }})" class="text-blue-600 hover:text-blue-900 mr-3">
            Send Reminder
            @if($invitation->reminder_count > 0)
                ({{ $invitation->reminder_count }}/3)
            @endif
        </button>
    @endcan
    
    @can('revoke', [$team, $invitation])
        <button wire:click="revoke({{ $invitation->id }})" class="text-red-600 hover:text-red-900">Revoke</button>
    @endcan
@else
    <span class="text-gray-400">No actions available</span>
@endif
```
