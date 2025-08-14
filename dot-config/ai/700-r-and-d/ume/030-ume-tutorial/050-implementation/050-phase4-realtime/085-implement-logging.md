# Implementing Activity Logging via Listeners

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Implement comprehensive activity logging for user presence status changes using the `spatie/laravel-activitylog` package and event listeners.

## Prerequisites

- Completed the previous sections on presence status
- Understanding of Laravel's event system
- `spatie/laravel-activitylog` package installed

## Implementation

### Step 1: Ensure the Activity Log Package is Installed

First, make sure the `spatie/laravel-activitylog` package is installed:

```bash
composer require spatie/100-laravel-activitylog
```

Publish the configuration and migration files:

```bash
php artisan vendor:publish --provider="Spatie\Activitylog\ActivitylogServiceProvider" --tag="activitylog-config"
php artisan vendor:publish --provider="Spatie\Activitylog\ActivitylogServiceProvider" --tag="activitylog-migrations"
```

Run the migrations:

```bash
php artisan migrate
```

### Step 2: Create a Listener for Presence Changed Events

Create a listener for the `PresenceChanged` event:

```bash
php artisan make:listener User/LogPresenceActivity --event=User\\PresenceChanged
```

Edit the generated file at `app/Listeners/User/LogPresenceActivity.php`:

```php
<?php

declare(strict_types=1);

namespace App\Listeners\User;

use App\Events\User\PresenceChanged;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;
use Spatie\Activitylog\Facades\Activity;

class LogPresenceActivity implements ShouldQueue
{
    use InteractsWithQueue;

    /**
     * Handle the event.
     */
    public function handle(PresenceChanged $event): void
    {
        $description = $this->getDescription($event);
        
        Activity::withProperties([
            'old_status' => $event->oldStatus?->value ?? 'unknown',
            'new_status' => $event->status->value,
            'trigger' => $event->trigger ?? 'manual',
            'ip_address' => request()->ip(),
        ])
        ->causedBy($event->causer ?? $event->user)
        ->performedOn($event->user)
        ->log($description);
    }
    
    /**
     * Get a human-readable description of the presence change.
     */
    private function getDescription(PresenceChanged $event): string
    {
        $userName = $event->user->name;
        $newStatus = $event->status->label();
        
        return match ($event->trigger ?? 'manual') {
            'login' => "{$userName} logged in and is now {$newStatus}",
            'logout' => "{$userName} logged out and is now {$newStatus}",
            'inactivity' => "{$userName} went {$newStatus} due to inactivity",
            'manual' => "{$userName} manually changed status to {$newStatus}",
            default => "{$userName} is now {$newStatus}",
        };
    }
}
```

### Step 3: Update the PresenceChanged Event

Update the `PresenceChanged` event to include the old status and trigger:

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
        public PresenceStatus $status,
        public ?PresenceStatus $oldStatus = null,
        public ?string $trigger = null,
        public ?User $causer = null
    ) {}

    // ... rest of the class remains the same
}
```

### Step 4: Update the PresenceService

Update the `PresenceService` to include the old status and trigger:

```php
<?php

declare(strict_types=1);

namespace App\Services;

use App\Enums\PresenceStatus;
use App\Events\User\PresenceChanged;
use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class PresenceService
{
    /**
     * Update a user's presence status and broadcast the change
     *
     * @param User $user
     * @param PresenceStatus $status
     * @param string|null $trigger
     * @param User|null $causer
     * @return bool
     */
    public function updatePresence(
        User $user, 
        PresenceStatus $status, 
        ?string $trigger = null,
        ?User $causer = null
    ): bool
    {
        // Get the old status before updating
        $oldStatus = $user->presence_status;
        
        // Only update if status actually changed or last_seen_at is null
        if ($oldStatus === $status && $user->last_seen_at !== null) {
            return false;
        }

        try {
            // Update the user's presence status
            $user->forceFill([
                'presence_status' => $status,
                'last_seen_at' => now(),
            ])->saveQuietly(); // Use saveQuietly to avoid triggering other model events

            // Broadcast the presence change
            broadcast(new PresenceChanged(
                user: $user,
                status: $status,
                oldStatus: $oldStatus,
                trigger: $trigger,
                causer: $causer ?? Auth::user()
            ));

            Log::info('User presence updated', [
                'user_id' => $user->id,
                'old_status' => $oldStatus?->value ?? 'unknown',
                'new_status' => $status->value,
                'trigger' => $trigger,
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
     * @param string|null $trigger
     * @param User|null $causer
     * @return bool
     */
    public function markOnline(User $user, ?string $trigger = null, ?User $causer = null): bool
    {
        return $this->updatePresence($user, PresenceStatus::ONLINE, $trigger, $causer);
    }

    /**
     * Set a user's status to offline
     *
     * @param User $user
     * @param string|null $trigger
     * @param User|null $causer
     * @return bool
     */
    public function markOffline(User $user, ?string $trigger = null, ?User $causer = null): bool
    {
        return $this->updatePresence($user, PresenceStatus::OFFLINE, $trigger, $causer);
    }

    /**
     * Set a user's status to away
     *
     * @param User $user
     * @param string|null $trigger
     * @param User|null $causer
     * @return bool
     */
    public function markAway(User $user, ?string $trigger = null, ?User $causer = null): bool
    {
        return $this->updatePresence($user, PresenceStatus::AWAY, $trigger, $causer);
    }
}
```

### Step 5: Update the Login/Logout Listeners

Update the login and logout listeners to include the trigger:

```php
<?php

declare(strict_types=1);

namespace App\Listeners\Auth;

use App\Models\User;
use App\Services\PresenceService;
use Illuminate\Auth\Events\Login;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;

class UpdatePresenceOnLogin implements ShouldQueue
{
    use InteractsWithQueue;

    /**
     * Create the event listener.
     */
    public function __construct(
        private PresenceService $presenceService
    ) {}

    /**
     * Handle the event.
     */
    public function handle(Login $event): void
    {
        // Only handle User model logins
        if (!$event->user instanceof User) {
            return;
        }

        // Mark the user as online with 'login' trigger
        $this->presenceService->markOnline($event->user, 'login');
    }
}
```

```php
<?php

declare(strict_types=1);

namespace App\Listeners\Auth;

use App\Models\User;
use App\Services\PresenceService;
use Illuminate\Auth\Events\Logout;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;

class UpdatePresenceOnLogout implements ShouldQueue
{
    use InteractsWithQueue;

    /**
     * Create the event listener.
     */
    public function __construct(
        private PresenceService $presenceService
    ) {}

    /**
     * Handle the event.
     */
    public function handle(Logout $event): void
    {
        // Only handle User model logouts
        if (!$event->user instanceof User) {
            return;
        }

        // Mark the user as offline with 'logout' trigger
        $this->presenceService->markOffline($event->user, 'logout');
    }
}
```

### Step 6: Update the PresenceController

Update the `PresenceController` to include the trigger:

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Enums\PresenceStatus;
use App\Services\PresenceService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class PresenceController extends Controller
{
    /**
     * Create a new controller instance.
     */
    public function __construct(
        private PresenceService $presenceService
    ) {}

    /**
     * Update the authenticated user's presence status.
     */
    public function update(Request $request): JsonResponse
    {
        $request->validate([
            'status' => ['required', 'string', 'in:online,offline,away'],
            'trigger' => ['nullable', 'string', 'in:manual,inactivity,reconnect'],
        ]);

        $user = Auth::user();
        $status = PresenceStatus::from($request->status);
        $trigger = $request->trigger ?? 'manual';

        $updated = $this->presenceService->updatePresence($user, $status, $trigger);

        return response()->json([
            'success' => $updated,
            'status' => $status->value,
            'label' => $status->label(),
        ]);
    }
}
```

### Step 7: Update the JavaScript Helper

Update the JavaScript helper to include the trigger:

```javascript
// resources/js/presence.js

// Update the user's presence status
const updatePresence = (status, trigger = 'manual') => {
    fetch(PRESENCE_UPDATE_URL, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content,
            'Accept': 'application/json',
        },
        body: JSON.stringify({ status, trigger }),
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            console.log(`Presence updated to: ${data.label}`);
        }
    })
    .catch(error => {
        console.error('Error updating presence:', error);
    });
};

// Update the event handlers
document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') {
        updatePresence('online', 'reconnect');
        isAway = false;
        resetAwayTimeout();
    } else {
        updatePresence('away', 'inactivity');
        isAway = true;
        clearTimeout(awayTimeout);
    }
});

// In the resetAwayTimeout function
awayTimeout = setTimeout(() => {
    updatePresence('away', 'inactivity');
    isAway = true;
}, AWAY_TIMEOUT);
```

### Step 8: Register the Listener in EventServiceProvider

Register the `LogPresenceActivity` listener in `app/Providers/EventServiceProvider.php`:

```php
<?php

namespace App\Providers;

use App\Events\User\PresenceChanged;
use App\Listeners\Auth\UpdatePresenceOnLogin;
use App\Listeners\Auth\UpdatePresenceOnLogout;
use App\Listeners\User\LogPresenceActivity;
use Illuminate\Auth\Events\Login;
use Illuminate\Auth\Events\Logout;
use Illuminate\Auth\Events\Registered;
use Illuminate\Auth\Listeners\SendEmailVerificationNotification;
use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;
use Illuminate\Support\Facades\Event;

class EventServiceProvider extends ServiceProvider
{
    /**
     * The event to listener mappings for the application.
     *
     * @var array<class-string, array<int, class-string>>
     */
    protected $listen = [
        Registered::class => [
            SendEmailVerificationNotification::class,
        ],
        
        Login::class => [
            UpdatePresenceOnLogin::class,
        ],
        
        Logout::class => [
            UpdatePresenceOnLogout::class,
        ],
        
        PresenceChanged::class => [
            LogPresenceActivity::class,
        ],
    ];

    // ... rest of the class
}
```

### Step 9: Create a Controller and View for Viewing Activity Logs

Create a controller for viewing activity logs:

```bash
php artisan make:controller ActivityLogController
```

Edit the generated file at `app/Http/Controllers/ActivityLogController.php`:

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Spatie\Activitylog\Models\Activity;

class ActivityLogController extends Controller
{
    /**
     * Display the user's activity log.
     */
    public function index(Request $request)
    {
        $activities = Activity::causedBy(auth()->user())
            ->orWhere(function($query) {
                $query->where('subject_type', User::class)
                      ->where('subject_id', auth()->id());
            })
            ->orderBy('created_at', 'desc')
            ->paginate(20);
        
        return view('activity-log.index', compact('activities'));
    }
    
    /**
     * Display the team's activity log.
     */
    public function team(Request $request, $teamId)
    {
        $team = auth()->user()->teams()->findOrFail($teamId);
        
        $activities = Activity::query()
            ->whereHasMorph('subject', [User::class], function($query) use ($team) {
                $query->whereHas('teams', function($query) use ($team) {
                    $query->where('teams.id', $team->id);
                });
            })
            ->orderBy('created_at', 'desc')
            ->paginate(20);
        
        return view('activity-log.team', compact('activities', 'team'));
    }
}
```

Create the views for displaying activity logs:

```bash
mkdir -p resources/views/activity-log
touch resources/views/activity-log/index.blade.php
touch resources/views/activity-log/team.blade.php
```

Edit `resources/views/activity-log/index.blade.php`:

```blade
<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('My Activity Log') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b border-gray-200">
                    <div class="space-y-4">
                        @forelse($activities as $activity)
                            <div class="border-l-4 pl-4 py-2 {{ $activity->description == 'created' ? 'border-green-500' : 'border-blue-500' }}">
                                <div class="flex justify-between">
                                    <div class="text-sm font-medium text-gray-900">
                                        {{ $activity->description }}
                                    </div>
                                    <div class="text-sm text-gray-500">
                                        {{ $activity->created_at->diffForHumans() }}
                                    </div>
                                </div>
                                
                                @if($activity->properties->count() > 0)
                                    <div class="mt-2">
                                        <div class="text-xs font-medium text-gray-500 uppercase tracking-wider">
                                            Details
                                        </div>
                                        <div class="mt-1 text-sm text-gray-900">
                                            @if($activity->properties->has('old_status') && $activity->properties->has('new_status'))
                                                <div>
                                                    Status changed from 
                                                    <span class="font-medium">{{ ucfirst($activity->properties->get('old_status')) }}</span> 
                                                    to 
                                                    <span class="font-medium">{{ ucfirst($activity->properties->get('new_status')) }}</span>
                                                </div>
                                            @endif
                                            
                                            @if($activity->properties->has('trigger'))
                                                <div>
                                                    Trigger: {{ ucfirst($activity->properties->get('trigger')) }}
                                                </div>
                                            @endif
                                        </div>
                                    </div>
                                @endif
                            </div>
                        @empty
                            <div class="text-gray-500">
                                No activity recorded yet.
                            </div>
                        @endforelse
                    </div>
                    
                    <div class="mt-4">
                        {{ $activities->links() }}
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
```

Edit `resources/views/activity-log/team.blade.php`:

```blade
<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Team Activity Log') }}: {{ $team->name }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b border-gray-200">
                    <div class="space-y-4">
                        @forelse($activities as $activity)
                            <div class="border-l-4 pl-4 py-2 {{ $activity->description == 'created' ? 'border-green-500' : 'border-blue-500' }}">
                                <div class="flex justify-between">
                                    <div class="text-sm font-medium text-gray-900">
                                        {{ $activity->description }}
                                    </div>
                                    <div class="text-sm text-gray-500">
                                        {{ $activity->created_at->diffForHumans() }}
                                    </div>
                                </div>
                                
                                @if($activity->causer)
                                    <div class="mt-1 text-sm text-gray-600">
                                        By: {{ $activity->causer->name }}
                                    </div>
                                @endif
                                
                                @if($activity->properties->count() > 0)
                                    <div class="mt-2">
                                        <div class="text-xs font-medium text-gray-500 uppercase tracking-wider">
                                            Details
                                        </div>
                                        <div class="mt-1 text-sm text-gray-900">
                                            @if($activity->properties->has('old_status') && $activity->properties->has('new_status'))
                                                <div>
                                                    Status changed from 
                                                    <span class="font-medium">{{ ucfirst($activity->properties->get('old_status')) }}</span> 
                                                    to 
                                                    <span class="font-medium">{{ ucfirst($activity->properties->get('new_status')) }}</span>
                                                </div>
                                            @endif
                                            
                                            @if($activity->properties->has('trigger'))
                                                <div>
                                                    Trigger: {{ ucfirst($activity->properties->get('trigger')) }}
                                                </div>
                                            @endif
                                        </div>
                                    </div>
                                @endif
                            </div>
                        @empty
                            <div class="text-gray-500">
                                No activity recorded yet.
                            </div>
                        @endforelse
                    </div>
                    
                    <div class="mt-4">
                        {{ $activities->links() }}
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
```

### Step 10: Add Routes for Activity Logs

Add routes for the activity log controller in `routes/web.php`:

```php
use App\Http\Controllers\ActivityLogController;

// Add these inside the auth middleware group
Route::middleware(['auth', 'verified'])->group(function () {
    // ... existing routes
    
    // Activity log routes
    Route::get('/activity-log', [ActivityLogController::class, 'index'])
        ->name('activity-log.index');
    
    Route::get('/teams/{team}/activity-log', [ActivityLogController::class, 'team'])
        ->name('activity-log.team');
});
```

### Step 11: Add Navigation Links

Update your navigation to include links to the activity logs:

```blade
<!-- In resources/views/layouts/navigation.blade.php -->
<div class="hidden space-x-8 sm:-my-px sm:ml-10 sm:flex">
    <!-- ... existing links -->
    
    <x-nav-link :href="route('activity-log.index')" :active="request()->routeIs('activity-log.index')">
        {{ __('My Activity') }}
    </x-nav-link>
    
    @if(auth()->user()->currentTeam)
        <x-nav-link :href="route('activity-log.team', auth()->user()->currentTeam)" :active="request()->routeIs('activity-log.team')">
            {{ __('Team Activity') }}
        </x-nav-link>
    @endif
</div>
```

## Understanding the Implementation

Our activity logging implementation:

1. **Captures Context**: We log the old status, new status, trigger, and IP address
2. **Identifies Actors**: We track both the subject (user whose status changed) and causer (user who initiated the change)
3. **Provides Human-Readable Descriptions**: We generate descriptive messages based on the trigger
4. **Uses Queues**: The listener implements `ShouldQueue` for better performance
5. **Offers Multiple Views**: We provide both personal and team-based activity log views

## Verification

To verify your implementation:

1. Log in to the application
2. Change your presence status manually
3. Log out and log back in
4. Visit the activity log page
5. Verify that all status changes are logged with the correct information

## Next Steps

Now that we have implemented comprehensive activity logging for our User Presence State Machine, let's commit our changes to Git.

[Phase 4 Git Commit →](./090-git-commit.md)
