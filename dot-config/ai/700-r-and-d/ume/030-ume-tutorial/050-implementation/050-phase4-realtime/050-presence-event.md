# Creating the PresenceChanged Broadcast Event

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Create a broadcast event that will be dispatched whenever a user's presence status changes, allowing real-time updates across the application.

## Prerequisites

- Completed the [Presence Status Backend](./040-presence-backend.md) implementation
- Laravel Reverb set up and running
- Laravel Echo configured

## Implementation

We'll create a broadcast event that:

1. Implements the `ShouldBroadcast` interface
2. Contains the user and their new presence status
3. Broadcasts on appropriate channels
4. Formats the data for frontend consumption

### Step 1: Create the Event Class

Generate the event class using Artisan:

```bash
php artisan make:event User/PresenceChanged
```

### Step 2: Implement the Event

Edit the generated file at `app/Events/User/PresenceChanged.php`:

```php
<?php

declare(strict_types=1);

namespace App\Events\User;

use App\Enums\PresenceStatus;
use App\Models\User;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class PresenceChanged implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    /**
     * Create a new event instance.
     */
    public function __construct(
        public User $user,
        public PresenceStatus $status
    ) {}

    /**
     * Get the channels the event should broadcast on.
     *
     * @return array<int, \Illuminate\Broadcasting\Channel>
     */
    public function broadcastOn(): array
    {
        $channels = [];
        
        // Broadcast to all top-level teams the user belongs to
        foreach ($this->user->teams()->whereNull('parent_id')->get() as $team) {
            $channels[] = new PresenceChannel('presence-team.' . $team->id);
        }
        
        // Also broadcast on user's private channel for direct notifications
        $channels[] = new PrivateChannel('user.' . $this->user->id);
        
        return $channels;
    }

    /**
     * The event's broadcast name.
     */
    public function broadcastAs(): string
    {
        return 'user.presence.changed';
    }

    /**
     * Get the data to broadcast.
     *
     * @return array<string, mixed>
     */
    public function broadcastWith(): array
    {
        return [
            'user_id' => $this->user->id,
            'name' => $this->user->name,
            'status' => $this->status->value,
            'last_seen_at' => $this->user->last_seen_at?->toIso8601String(),
            'avatar_url' => $this->user->getFirstMediaUrl('avatar'),
        ];
    }
}
```

### Step 3: Create a Service for Managing Presence

Create a service class to handle presence status changes:

```bash
mkdir -p app/Services
touch app/Services/PresenceService.php
```

Edit the service file:

```php
<?php

declare(strict_types=1);

namespace App\Services;

use App\Enums\PresenceStatus;
use App\Events\User\PresenceChanged;
use App\Models\User;
use Illuminate\Support\Facades\Log;

class PresenceService
{
    /**
     * Update a user's presence status and broadcast the change
     *
     * @param User $user
     * @param PresenceStatus $status
     * @return bool
     */
    public function updatePresence(User $user, PresenceStatus $status): bool
    {
        // Only update if status actually changed or last_seen_at is null
        if ($user->presence_status === $status && $user->last_seen_at !== null) {
            return false;
        }

        try {
            // Update the user's presence status
            $user->forceFill([
                'presence_status' => $status,
                'last_seen_at' => now(),
            ])->saveQuietly(); // Use saveQuietly to avoid triggering other model events

            // Broadcast the presence change
            broadcast(new PresenceChanged($user, $status));

            Log::info('User presence updated', [
                'user_id' => $user->id,
                'status' => $status->value,
            ]);

            return true;
        } catch (\Exception $e) {
            Log::error('Failed to update user presence', [
                'user_id' => $user->id,
                'status' => $status->value,
                'error' => $e->getMessage(),
            ]);

            return false;
        }
    }

    /**
     * Set a user's status to online
     *
     * @param User $user
     * @return bool
     */
    public function markOnline(User $user): bool
    {
        return $this->updatePresence($user, PresenceStatus::ONLINE);
    }

    /**
     * Set a user's status to offline
     *
     * @param User $user
     * @return bool
     */
    public function markOffline(User $user): bool
    {
        return $this->updatePresence($user, PresenceStatus::OFFLINE);
    }

    /**
     * Set a user's status to away
     *
     * @param User $user
     * @return bool
     */
    public function markAway(User $user): bool
    {
        return $this->updatePresence($user, PresenceStatus::AWAY);
    }
}
```

### Step 4: Register Broadcast Channels

Update the `routes/channels.php` file to authorize the broadcast channels:

```php
<?php

use App\Models\Team;
use App\Models\User;
use Illuminate\Support\Facades\Broadcast;

/*
|--------------------------------------------------------------------------
| Broadcast Channels
|--------------------------------------------------------------------------
|
| Here you may register all of the event broadcasting channels that your
| application supports. The given channel authorization callbacks are
| used to check if an authenticated user can listen to the channel.
|
*/

// Private user channel
Broadcast::channel('user.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});

// Presence channel for teams (only for top-level teams)
Broadcast::channel('presence-team.{teamId}', function ($user, $teamId) {
    $team = Team::find($teamId);
    
    // Only allow if team exists, is top-level, and user is a member
    if ($team && $team->parent_id === null && $user->belongsToTeam($team)) {
        // Return user data to identify them in the presence channel
        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'avatar' => $user->getFirstMediaUrl('avatar'),
        ];
    }
    
    return false;
});
```

## Understanding the Implementation

The `PresenceChanged` event is a key component of our real-time presence system:

1. **ShouldBroadcast Interface**: This tells Laravel to broadcast the event over WebSockets.

2. **Multiple Channels**:
   - **Team Presence Channels**: We broadcast to presence channels for each top-level team the user belongs to. This allows team members to see who's online.
   - **User Private Channel**: We also broadcast to the user's private channel, which can be used for direct notifications.

3. **PresenceService**:
   - Centralizes presence management logic
   - Only updates and broadcasts when the status actually changes
   - Uses `saveQuietly()` to avoid triggering other model events
   - Provides convenience methods for common status changes

4. **Channel Authorization**:
   - The `presence-team.{teamId}` channel is restricted to members of that team
   - We only allow presence channels for top-level teams (where `parent_id` is null)
   - We return user data that will be available to other channel subscribers

## Verification

To verify your implementation:

1. Check that the event class is created correctly
2. Ensure the service class is created and properly implemented
3. Verify the channel routes are registered
4. Test the event broadcasting in Tinker:

```bash
php artisan tinker
```

```php
use App\Models\User;
use App\Enums\PresenceStatus;
use App\Services\PresenceService;

$user = User::first();
$service = new PresenceService();
$service->markOnline($user); // Should update status and broadcast event
```

## Next Steps

Now that we have the broadcast event and service for managing presence, we need to:

1. Create listeners for login/logout events to automatically update presence
2. Implement the UI components to display presence indicators

Let's move on to creating the [Login/Logout Presence Listeners](./060-presence-listeners.md).
