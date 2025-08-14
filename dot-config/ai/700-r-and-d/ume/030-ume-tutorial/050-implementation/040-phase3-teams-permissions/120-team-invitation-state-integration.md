# Team Invitation State Integration

In this section, we'll integrate our team invitation state machine with the rest of our application by implementing controllers, policies, and views.

## Updating the TeamInvitationController

Let's update our TeamInvitationController to use the state machine:

```php
<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreTeamInvitationRequest;
use App\Models\Team;
use App\Models\TeamInvitation;
use App\Models\User;
use App\Notifications\TeamInvitation as TeamInvitationNotification;
use App\States\TeamInvitation\Pending;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Gate;

class TeamInvitationController extends Controller
{
    /**
     * Store a newly created invitation.
     */
    public function store(StoreTeamInvitationRequest $request, Team $team)
    {
        $validated = $request->validated();

        // Check if the user is already on the team
        $user = User::where('email', $validated['email'])->first();
        if ($user && $team->users->contains($user)) {
            return back()->withErrors([
                'email' => 'This user is already on the team.',
            ]);
        }

        // Check if there's already a pending invitation
        $existingInvitation = TeamInvitation::where('team_id', $team->id)
            ->where('email', $validated['email'])
            ->whereState('state', Pending::class)
            ->first();

        if ($existingInvitation) {
            return back()->withErrors([
                'email' => 'An invitation has already been sent to this email address.',
            ]);
        }

        // Create the invitation
        $invitation = TeamInvitation::create([
            'team_id' => $team->id,
            'email' => $validated['email'],
            'role' => $validated['role'] ?? 'member',
            'created_by' => Auth::id(),
            'expires_at' => now()->addDays(7),
        ]);

        // Send the invitation email
        $user = User::where('email', $validated['email'])->first();
        if ($user) {
            $user->notify(new TeamInvitationNotification($invitation));
        } else {
            // Send invitation to non-registered user
            // This would typically involve sending an email with registration instructions
            // and the invitation token
        }

        return back()->with('success', 'Invitation sent successfully.');
    }

    /**
     * Accept an invitation.
     */
    public function accept(Request $request, $token)
    {
        $invitation = TeamInvitation::where('token', $token)->firstOrFail();

        // If the user is not logged in, redirect to login
        if (! Auth::check()) {
            return redirect()->route('login', ['invitation' => $token]);
        }

        $user = Auth::user();

        try {
            // Accept the invitation using the state transition
            $invitation->accept($user);

            return redirect()->route('teams.show', $invitation->team)
                ->with('success', 'You have joined the team successfully.');
        } catch (\Exception $e) {
            return back()->withErrors([
                'invitation' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Reject an invitation.
     */
    public function reject(Request $request, $token)
    {
        $invitation = TeamInvitation::where('token', $token)->firstOrFail();

        // If the user is not logged in, redirect to login
        if (! Auth::check()) {
            return redirect()->route('login', ['invitation' => $token]);
        }

        $user = Auth::user();

        try {
            // Reject the invitation using the state transition
            $invitation->reject($user, $request->input('reason'));

            return redirect()->route('dashboard')
                ->with('success', 'You have rejected the team invitation.');
        } catch (\Exception $e) {
            return back()->withErrors([
                'invitation' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Revoke an invitation.
     */
    public function revoke(Request $request, Team $team, TeamInvitation $invitation)
    {
        Gate::authorize('revokeInvitation', [$team, $invitation]);

        try {
            // Revoke the invitation using the state transition
            $invitation->revoke(Auth::user(), $request->input('reason'));

            return back()->with('success', 'Invitation revoked successfully.');
        } catch (\Exception $e) {
            return back()->withErrors([
                'invitation' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Resend an invitation.
     */
    public function resend(Team $team, TeamInvitation $invitation)
    {
        Gate::authorize('resendInvitation', [$team, $invitation]);

        // Check if the invitation is still pending
        if (! $invitation->isPending()) {
            return back()->withErrors([
                'invitation' => 'This invitation cannot be resent because it is not pending.',
            ]);
        }

        // Update the expiration date
        $invitation->update([
            'expires_at' => now()->addDays(7),
        ]);

        // Resend the invitation email
        $user = User::where('email', $invitation->email)->first();
        if ($user) {
            $user->notify(new TeamInvitationNotification($invitation));
        } else {
            // Send invitation to non-registered user
        }

        return back()->with('success', 'Invitation resent successfully.');
    }
}
```

## Creating the TeamInvitationPolicy

Let's create a policy to control who can manage team invitations:

```php
<?php

namespace App\Policies;

use App\Models\Team;
use App\Models\TeamInvitation;
use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

class TeamInvitationPolicy
{
    use HandlesAuthorization;

    /**
     * Determine whether the user can view any invitations.
     */
    public function viewAny(User $user, Team $team): bool
    {
        return $user->belongsToTeam($team);
    }

    /**
     * Determine whether the user can create invitations.
     */
    public function create(User $user, Team $team): bool
    {
        return $user->ownsTeam($team) || 
               $user->hasTeamPermission($team, 'team:invite');
    }

    /**
     * Determine whether the user can revoke an invitation.
     */
    public function revoke(User $user, Team $team, TeamInvitation $invitation): bool
    {
        return $invitation->team_id === $team->id && 
               ($user->ownsTeam($team) || 
                $user->hasTeamPermission($team, 'team:invite') || 
                $user->id === $invitation->created_by);
    }

    /**
     * Determine whether the user can resend an invitation.
     */
    public function resend(User $user, Team $team, TeamInvitation $invitation): bool
    {
        return $invitation->team_id === $team->id && 
               ($user->ownsTeam($team) || 
                $user->hasTeamPermission($team, 'team:invite') || 
                $user->id === $invitation->created_by);
    }
}
```

Don't forget to register this policy in the `app/Providers/AuthServiceProvider.php` file:

```php
protected $policies = [
    // ... other policies ...
    TeamInvitation::class => TeamInvitationPolicy::class,
];
```

## Updating the TeamInvitation Notification

Let's update our TeamInvitation notification to include the state:

```php
<?php

namespace App\Notifications;

use App\Models\TeamInvitation as TeamInvitationModel;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;
use Illuminate\Support\Facades\URL;

class TeamInvitation extends Notification implements ShouldQueue
{
    use Queueable;

    protected $invitation;

    public function __construct(TeamInvitationModel $invitation)
    {
        $this->invitation = $invitation;
    }

    public function via($notifiable)
    {
        return ['mail', 'database'];
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
            ->subject('Team Invitation')
            ->greeting('Hello!')
            ->line('You have been invited to join the ' . $this->invitation->team->name . ' team.')
            ->line('This invitation will expire on ' . $this->invitation->expires_at->format('F j, Y'))
            ->action('Accept Invitation', $acceptUrl)
            ->line('If you do not wish to join this team, you can ignore this email or click the link below:')
            ->line('[Reject Invitation](' . $rejectUrl . ')')
            ->line('Thank you for using our application!');
    }

    public function toDatabase($notifiable)
    {
        return [
            'team_id' => $this->invitation->team_id,
            'team_name' => $this->invitation->team->name,
            'invitation_id' => $this->invitation->id,
            'invitation_state' => $this->invitation->state->status()->value,
            'expires_at' => $this->invitation->expires_at->toDateTimeString(),
        ];
    }
}
```

## Creating Livewire Components for Invitation Management

Let's create Livewire components to manage team invitations:

### InviteMember Component

```php
<?php

namespace App\Http\Livewire\Teams;

use App\Models\Team;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Livewire\Component;

class InviteMember extends Component
{
    use AuthorizesRequests;

    public Team $team;
    public string $email = '';
    public string $role = 'member';

    protected $rules = [
        'email' => 'required|email',
        'role' => 'required|string',
    ];

    public function invite()
    {
        $this->authorize('create', [TeamInvitation::class, $this->team]);

        $this->validate();

        $controller = app(TeamInvitationController::class);
        $request = new StoreTeamInvitationRequest([
            'email' => $this->email,
            'role' => $this->role,
        ]);

        $response = $controller->store($request, $this->team);

        if ($response->getSession()->has('errors')) {
            $this->addError('email', $response->getSession()->get('errors')->first('email'));
            return;
        }

        $this->reset(['email']);
        $this->emit('invitationSent');
    }

    public function render()
    {
        return view('livewire.teams.invite-member');
    }
}
```

### PendingInvitations Component

```php
<?php

namespace App\Http\Livewire\Teams;

use App\Models\Team;
use App\Models\TeamInvitation;
use App\States\TeamInvitation\Pending;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Livewire\Component;

class PendingInvitations extends Component
{
    use AuthorizesRequests;

    public Team $team;
    public $invitations;

    protected $listeners = ['invitationSent' => '$refresh'];

    public function mount(Team $team)
    {
        $this->team = $team;
        $this->loadInvitations();
    }

    public function loadInvitations()
    {
        $this->authorize('viewAny', [TeamInvitation::class, $this->team]);

        $this->invitations = TeamInvitation::where('team_id', $this->team->id)
            ->whereState('state', Pending::class)
            ->orderBy('created_at', 'desc')
            ->get();
    }

    public function revoke(TeamInvitation $invitation, $reason = null)
    {
        $this->authorize('revoke', [$this->team, $invitation]);

        try {
            $invitation->revoke(auth()->user(), $reason);
            $this->loadInvitations();
            $this->emit('invitationRevoked');
        } catch (\Exception $e) {
            $this->addError('revoke', $e->getMessage());
        }
    }

    public function resend(TeamInvitation $invitation)
    {
        $this->authorize('resend', [$this->team, $invitation]);

        try {
            $controller = app(TeamInvitationController::class);
            $controller->resend($this->team, $invitation);
            $this->emit('invitationResent');
        } catch (\Exception $e) {
            $this->addError('resend', $e->getMessage());
        }
    }

    public function render()
    {
        return view('livewire.teams.pending-invitations');
    }
}
```

## Adding Routes

Let's add the necessary routes to our `routes/web.php` file:

```php
// Team invitation routes
Route::get('/team-invitations/{token}', [TeamInvitationController::class, 'accept'])
    ->middleware(['signed'])
    ->name('team-invitations.accept');

Route::get('/team-invitations/{token}/reject', [TeamInvitationController::class, 'reject'])
    ->middleware(['signed'])
    ->name('team-invitations.reject');

Route::middleware(['auth'])->group(function () {
    Route::post('/teams/{team}/invitations', [TeamInvitationController::class, 'store'])
        ->name('team-invitations.store');

    Route::delete('/teams/{team}/invitations/{invitation}', [TeamInvitationController::class, 'revoke'])
        ->name('team-invitations.revoke');

    Route::post('/teams/{team}/invitations/{invitation}/resend', [TeamInvitationController::class, 'resend'])
        ->name('team-invitations.resend');
});
```

## Creating Views

Let's create the necessary views for our Livewire components:

### Invite Member View

```blade
<div>
    <div class="bg-white rounded-lg shadow p-6">
        <h3 class="text-lg font-medium text-gray-900">Invite Team Member</h3>
        
        <form wire:submit.prevent="invite" class="mt-4">
            <div>
                <label for="email" class="block text-sm font-medium text-gray-700">Email</label>
                <input type="email" id="email" wire:model.defer="email" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm">
                @error('email') <span class="text-red-500 text-xs">{{ $message }}</span> @enderror
            </div>

            <div class="mt-4">
                <label for="role" class="block text-sm font-medium text-gray-700">Role</label>
                <select id="role" wire:model.defer="role" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm">
                    <option value="member">Member</option>
                    <option value="admin">Admin</option>
                </select>
                @error('role') <span class="text-red-500 text-xs">{{ $message }}</span> @enderror
            </div>

            <div class="mt-6">
                <button type="submit" class="inline-flex items-center px-4 py-2 bg-indigo-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-indigo-700 focus:bg-indigo-700 active:bg-indigo-900 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition ease-in-out duration-150">
                    Send Invitation
                </button>
            </div>
        </form>
    </div>
</div>
```

### Pending Invitations View

```blade
<div>
    <div class="bg-white rounded-lg shadow p-6">
        <h3 class="text-lg font-medium text-gray-900">Pending Invitations</h3>
        
        @if($invitations->isEmpty())
            <p class="mt-4 text-sm text-gray-500">No pending invitations.</p>
        @else
            <div class="mt-4 overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                        <tr>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Role</th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Expires</th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="bg-white divide-y divide-gray-200">
                        @foreach($invitations as $invitation)
                            <tr>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ $invitation->email }}</td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ ucfirst($invitation->role) }}</td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ $invitation->expires_at->diffForHumans() }}</td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                    <button wire:click="resend({{ $invitation->id }})" class="text-indigo-600 hover:text-indigo-900 mr-3">Resend</button>
                                    <button wire:click="revoke({{ $invitation->id }})" class="text-red-600 hover:text-red-900">Revoke</button>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @endif
        
        @error('revoke') <div class="mt-4 text-red-500 text-sm">{{ $message }}</div> @enderror
        @error('resend') <div class="mt-4 text-red-500 text-sm">{{ $message }}</div> @enderror
    </div>
</div>
```

In the next section, we'll implement tests for our team invitation state machine.
