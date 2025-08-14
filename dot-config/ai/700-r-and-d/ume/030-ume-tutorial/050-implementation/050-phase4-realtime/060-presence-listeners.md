# Creating Login/Logout Presence Listeners

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Create event listeners that automatically update a user's presence status when they log in or log out of the application.

## Prerequisites

- Completed the [Presence Status Backend](./040-presence-backend.md) implementation
- Created the [PresenceChanged Broadcast Event](./050-presence-event.md)
- Understanding of Laravel's event system

## Implementation

We'll create two event listeners:

1. A listener for the `Illuminate\Auth\Events\Login` event to mark users as online
2. A listener for the `Illuminate\Auth\Events\Logout` event to mark users as offline

### Step 1: Create the Login Listener

Generate the listener class using Artisan:

```bash
php artisan make:listener Auth/UpdatePresenceOnLogin --event=Illuminate\\Auth\\Events\\Login
```

Edit the generated file at `app/Listeners/Auth/UpdatePresenceOnLogin.php`:

```php
<?php

declare(strict_types=1);

namespace App\Listeners\Auth;

use App\Enums\PresenceStatus;
use App\Events\User\PresenceChanged;
use App\Models\User;
use App\Services\PresenceService;
use Illuminate\Auth\Events\Login;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Support\Facades\Log;

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

        // Mark the user as online
        $this->presenceService->markOnline($event->user);
    }
}
```

### Step 2: Create the Logout Listener

Generate the listener class using Artisan:

```bash
php artisan make:listener Auth/UpdatePresenceOnLogout --event=Illuminate\\Auth\\Events\\Logout
```

Edit the generated file at `app/Listeners/Auth/UpdatePresenceOnLogout.php`:

```php
<?php

declare(strict_types=1);

namespace App\Listeners\Auth;

use App\Enums\PresenceStatus;
use App\Events\User\PresenceChanged;
use App\Models\User;
use App\Services\PresenceService;
use Illuminate\Auth\Events\Logout;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Support\Facades\Log;

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

        // Mark the user as offline
        $this->presenceService->markOffline($event->user);
    }
}
```

### Step 3: Register the Listeners

Register the listeners in the `app/Providers/EventServiceProvider.php` file:

```php
<?php

namespace App\Providers;

use App\Listeners\Auth\UpdatePresenceOnLogin;
use App\Listeners\Auth\UpdatePresenceOnLogout;
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
        
        // Add these lines
        Login::class => [
            UpdatePresenceOnLogin::class,
        ],
        Logout::class => [
            UpdatePresenceOnLogout::class,
        ],
    ];

    /**
     * Register any events for your application.
     */
    public function boot(): void
    {
        //
    }

    /**
     * Determine if events and listeners should be automatically discovered.
     */
    public function shouldDiscoverEvents(): bool
    {
        return false;
    }
}
```

### Step 4: Create a Controller Method for Manual Status Updates

Create a controller to allow users to manually update their status:

```bash
php artisan make:controller PresenceController
```

Edit the generated file at `app/Http/Controllers/PresenceController.php`:

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
        ]);

        $user = Auth::user();
        $status = PresenceStatus::from($request->status);

        $updated = $this->presenceService->updatePresence($user, $status);

        return response()->json([
            'success' => $updated,
            'status' => $status->value,
            'label' => $status->label(),
        ]);
    }
}
```

### Step 5: Add the Route

Add a route for the controller in `routes/web.php`:

```php
use App\Http\Controllers\PresenceController;

// Add this inside the auth middleware group
Route::middleware(['auth', 'verified'])->group(function () {
    // ... existing routes
    
    // Presence status update route
    Route::put('/presence', [PresenceController::class, 'update'])
        ->name('presence.update');
});
```

### Step 6: Create a JavaScript Helper for Automatic Away Status

Create a JavaScript file to automatically set the user's status to "away" after a period of inactivity:

```bash
touch resources/js/presence.js
```

Edit the file:

```javascript
// resources/js/presence.js

/**
 * Handle user presence status
 */
export default function setupPresence() {
    // Constants
    const AWAY_TIMEOUT = 5 * 60 * 1000; // 5 minutes in milliseconds
    const PRESENCE_UPDATE_URL = '/presence';
    
    // Variables
    let awayTimeout;
    let isAway = false;
    
    // Reset the away timeout
    const resetAwayTimeout = () => {
        clearTimeout(awayTimeout);
        
        // If user was away, set them back to online
        if (isAway) {
            updatePresence('online');
            isAway = false;
        }
        
        // Set a new timeout to mark user as away
        awayTimeout = setTimeout(() => {
            updatePresence('away');
            isAway = true;
        }, AWAY_TIMEOUT);
    };
    
    // Update the user's presence status
    const updatePresence = (status) => {
        fetch(PRESENCE_UPDATE_URL, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content,
                'Accept': 'application/json',
            },
            body: JSON.stringify({ status }),
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
    
    // Set up event listeners for user activity
    const setupActivityListeners = () => {
        // User activity events
        const activityEvents = [
            'mousedown', 'mousemove', 'keydown',
            'scroll', 'touchstart', 'click', 'keypress'
        ];
        
        // Add listeners for each activity event
        activityEvents.forEach(eventName => {
            document.addEventListener(eventName, resetAwayTimeout, true);
        });
        
        // Handle page visibility changes
        document.addEventListener('visibilitychange', () => {
            if (document.visibilityState === 'visible') {
                updatePresence('online');
                isAway = false;
                resetAwayTimeout();
            } else {
                updatePresence('away');
                isAway = true;
                clearTimeout(awayTimeout);
            }
        });
        
        // Handle page unload (close/navigate away)
        window.addEventListener('beforeunload', () => {
            // Use sendBeacon for more reliable delivery during page unload
            const data = new FormData();
            data.append('_method', 'PUT');
            data.append('status', 'offline');
            
            navigator.sendBeacon(PRESENCE_UPDATE_URL, data);
        });
    };
    
    // Initialize
    const init = () => {
        // Only set up for authenticated users
        if (!document.body.classList.contains('user-authenticated')) {
            return;
        }
        
        setupActivityListeners();
        resetAwayTimeout();
        
        // Set initial status to online
        updatePresence('online');
    };
    
    // Run initialization when DOM is loaded
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
}
```

### Step 7: Import and Initialize the Presence Helper

Update your main JavaScript file (e.g., `resources/js/app.js`) to import and initialize the presence helper:

```javascript
// resources/js/app.js

import './bootstrap';
import setupPresence from './presence';

// Initialize presence tracking
setupPresence();
```

### Step 8: Update the Layout to Add the Authentication Class

Update your main layout file to add a class to the body when the user is authenticated:

```blade
<body class="{{ auth()->check() ? 'user-authenticated' : '' }}">
    <!-- Your layout content -->
</body>
```

## Understanding the Implementation

Our presence system now automatically updates a user's status based on their authentication state and activity:

1. **Login/Logout Listeners**:
   - When a user logs in, they're automatically marked as online
   - When a user logs out, they're automatically marked as offline
   - Both listeners use the `PresenceService` to update status and broadcast changes

2. **Manual Status Updates**:
   - The `PresenceController` allows users to manually update their status
   - This can be used for UI elements like a status dropdown

3. **Automatic Away Status**:
   - The JavaScript helper monitors user activity
   - After 5 minutes of inactivity, the user is marked as away
   - When activity resumes, they're marked as online again
   - When the page is hidden (tab switched, etc.), they're marked as away
   - When the page is closed, they're marked as offline

4. **ShouldQueue Interface**:
   - Both listeners implement `ShouldQueue` for better performance
   - Status updates are processed in the background

## Verification

To verify your implementation:

1. Ensure the listeners are registered in `EventServiceProvider`
2. Test logging in and out to see if status updates automatically
3. Test the manual status update endpoint:

```bash
# Using curl (replace the token and cookie with your own)
curl -X PUT \
  http://localhost:8000/presence \
  -H 'Content-Type: application/json' \
  -H 'X-CSRF-TOKEN: your-csrf-token' \
  -H 'Cookie: your-session-cookie' \
  -d '{"status":"away"}'
```

4. Check the database to verify the status is updated:

```bash
php artisan tinker
```

```php
\App\Models\User::first()->presence_status; // Should reflect the current status
```

## Next Steps

Now that we have the backend infrastructure and event listeners for presence status, we can move on to implementing the UI components to display presence indicators.

Let's look at how to [Implement Real-time Presence UI with Flux UI](./050-flux-ui-presence-indicator.md).
