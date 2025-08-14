# Implementing Real-time Presence Indicators with Flux UI

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Create a real-time presence indicator component using Livewire/Volt with Flux UI components, showing which team members are currently online.

## Prerequisites

- Completed Phase 3 (Teams & Permissions)
- Laravel Reverb set up and running
- Laravel Echo configured
- Presence status backend implemented
- Flux UI components installed

## Implementation

We'll create a Volt component that displays team members with their online status, updating in real-time as users come online or go offline.

### Step 1: Create the Volt Component

Create a new file at `resources/views/livewire/teams/team-presence.blade.php`:

```php
<?php

use App\Models\Team;
use App\Models\User;
use Illuminate\Support\Collection;
use Livewire\Volt\Component;

new class extends Component {
    public Team $team;
    public Collection $members;
    
    public function mount(Team $team): void
    {
        $this->team = $team;
        $this->loadMembers();
    }
    
    public function loadMembers(): void
    {
        $this->members = $this->team->users()
            ->with('media')
            ->get()
            ->map(function ($user) {
                return [
                    'id' => $user->id,
                    'name' => $user->name,
                    'given_name' => $user->given_name,
                    'family_name' => $user->family_name,
                    'email' => $user->email,
                    'avatar' => $user->getFirstMediaUrl('avatar'),
                    'presence_status' => $user->presence_status,
                    'last_active_at' => $user->last_active_at?->diffForHumans(),
                ];
            });
    }
    
    public function getListeners()
    {
        return [
            "echo-presence:team.{$this->team->id},.here" => 'handleHere',
            "echo-presence:team.{$this->team->id},.joining" => 'handleJoining',
            "echo-presence:team.{$this->team->id},.leaving" => 'handleLeaving',
            'presence-updated' => 'handlePresenceUpdated',
        ];
    }
    
    public function handleHere($users)
    {
        // Update presence status for all users currently in the channel
        foreach ($users as $user) {
            $this->updateMemberPresence($user['id'], 'online');
        }
    }
    
    public function handleJoining($user)
    {
        // Update presence status when a user joins the channel
        $this->updateMemberPresence($user['id'], 'online');
    }
    
    public function handleLeaving($user)
    {
        // Update presence status when a user leaves the channel
        $this->updateMemberPresence($user['id'], 'offline');
    }
    
    public function handlePresenceUpdated($event)
    {
        // Update presence status when a user's status changes
        $this->updateMemberPresence($event['user_id'], $event['status']);
    }
    
    private function updateMemberPresence($userId, $status)
    {
        $this->members = $this->members->map(function ($member) use ($userId, $status) {
            if ($member['id'] === $userId) {
                $member['presence_status'] = $status;
            }
            return $member;
        });
    }
}; ?>

<div>
    <x-flux-card>
        <x-flux-card-header>
            <h2 class="text-lg font-medium">Team Members</h2>
            <p class="mt-1 text-sm text-gray-500">
                Members of {{ $team->name }} and their current status.
            </p>
        </x-flux-card-header>
        
        <x-flux-card-body>
            <ul class="divide-y divide-gray-200">
                @foreach ($members as $member)
                    <li class="py-4 flex items-center justify-between">
                        <div class="flex items-center">
                            <div class="relative">
                                @if ($member['avatar'])
                                    <img 
                                        src="{{ $member['avatar'] }}" 
                                        alt="{{ $member['name'] }}" 
                                        class="h-10 w-10 rounded-full object-cover"
                                    >
                                @else
                                    <x-flux-avatar 
                                        :name="$member['name']" 
                                        class="h-10 w-10"
                                    />
                                @endif
                                
                                <!-- Presence Status Indicator -->
                                <span 
                                    class="absolute bottom-0 right-0 block h-3 w-3 rounded-full ring-2 ring-white 
                                    {{ $member['presence_status'] === 'online' ? 'bg-green-400' : 
                                       ($member['presence_status'] === 'away' ? 'bg-yellow-400' : 'bg-gray-400') }}"
                                ></span>
                            </div>
                            
                            <div class="ml-3">
                                <p class="text-sm font-medium text-gray-900">
                                    {{ $member['given_name'] }} {{ $member['family_name'] }}
                                </p>
                                <p class="text-xs text-gray-500">
                                    {{ $member['email'] }}
                                </p>
                            </div>
                        </div>
                        
                        <div>
                            <x-flux-badge 
                                :variant="$member['presence_status'] === 'online' ? 'success' : 
                                         ($member['presence_status'] === 'away' ? 'warning' : 'secondary')"
                            >
                                {{ ucfirst($member['presence_status']) }}
                            </x-flux-badge>
                            
                            @if ($member['last_active_at'] && $member['presence_status'] !== 'online')
                                <p class="text-xs text-gray-500 mt-1">
                                    Last active {{ $member['last_active_at'] }}
                                </p>
                            @endif
                        </div>
                    </li>
                @endforeach
            </ul>
        </x-flux-card-body>
    </x-flux-card>
</div>
```

### Step 2: Add the Route

Add a route in `routes/web.php`:

```php
Route::middleware(['auth', 'verified'])->group(function () {
    // Existing routes...
    
    Route::get('/teams/{team}/presence', Livewire\Volt\Volt::class)
        ->withComponent('teams.team-presence')
        ->name('teams.presence');
});
```

### Step 3: Update the Channel Authorization

Ensure your `channels.php` file has the proper authorization for presence channels:

```php
Broadcast::channel('team.{team_id}', function ($user, $team_id) {
    return $user->teams()->where('teams.id', $team_id)->exists() ? [
        'id' => $user->id,
        'name' => $user->name,
    ] : false;
});
```

### Step 4: Add JavaScript for Echo

Ensure your `resources/js/bootstrap.js` file has Echo configured:

```javascript
import Echo from '100-laravel-echo';
import Pusher from 'pusher-js';

window.Pusher = Pusher;

window.Echo = new Echo({
    broadcaster: 'reverb',
    key: import.meta.env.VITE_REVERB_APP_KEY,
    wsHost: import.meta.env.VITE_REVERB_HOST,
    wsPort: import.meta.env.VITE_REVERB_PORT,
    wssPort: import.meta.env.VITE_REVERB_PORT,
    forceTLS: false,
    disableStats: true,
    enabledTransports: ['ws', 'wss'],
});

// Join presence channel for the current team
document.addEventListener('DOMContentLoaded', () => {
    const teamId = document.body.getAttribute('data-team-id');
    
    if (teamId) {
        window.Echo.join(`team.${teamId}`)
            .here((users) => {
                console.log('Users currently online:', users);
            })
            .joining((user) => {
                console.log('User joined:', user);
            })
            .leaving((user) => {
                console.log('User left:', user);
            });
    }
});
```

### Step 5: Add Team ID to Body

Update your layout file to include the current team ID:

```php
<body 
    class="font-sans antialiased" 
    @if(auth()->check() && auth()->user()->currentTeam)
        data-team-id="{{ auth()->user()->currentTeam->id }}"
    @endif
>
    {{ $slot }}
</body>
```

## Flux UI Components Used

### Basic Components

- **x-flux-card**: Container with styling for a card layout
- **x-flux-card-header**: Header section of the card
- **x-flux-card-body**: Body section of the card
- **x-flux-avatar**: User avatar with initials fallback
- **x-flux-badge**: Status indicator badge

## What This Does

- Creates a Volt component that displays team members with their online status
- Uses Laravel Echo to listen for presence events on a team channel
- Updates the UI in real-time when users come online or go offline
- Uses Flux UI components for a polished interface

## Verification

1. Start Laravel Reverb: `php artisan reverb:start`
2. Open two different browsers or incognito windows
3. Log in as different users who belong to the same team
4. Navigate to the team presence page
5. Verify that users show as online when they're viewing the page
6. Close one browser and verify that the user shows as offline in the other browser

## Troubleshooting

### Issue: Presence events not firing

**Solution:** Ensure Reverb is running and properly configured. Check your browser console for any connection errors.

### Issue: Users not showing correct status

**Solution:** Verify that your presence channel authorization is correct and that users are properly joining the channel.

### Issue: Real-time updates not working

**Solution:** Check that your Echo configuration matches your Reverb setup and that you're listening for the correct events.

## Next Steps

Now that we have implemented the real-time presence indicator with Flux UI components, let's move on to implementing the real-time chat feature.
