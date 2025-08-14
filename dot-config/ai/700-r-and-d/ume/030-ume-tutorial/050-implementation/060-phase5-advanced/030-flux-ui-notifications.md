# Implementing Notifications with Flux UI

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Create a real-time notification system using Livewire/Volt with Flux UI components, allowing users to receive and manage notifications.

## Prerequisites

- Completed Phase 4 (Real-time Features)
- Laravel Reverb set up and running
- Laravel Echo configured
- Flux UI components installed

## Implementation

We'll create a notification system that includes:

1. A notification bell in the navigation bar
2. A dropdown to display notifications
3. Real-time updates when new notifications arrive
4. Ability to mark notifications as read

### Step 1: Create the Notification Model

Laravel already provides a notifications table migration. Run it if you haven't already:

```bash
php artisan notifications:table
php artisan migrate
```

### Step 2: Create a Custom Notification

Create a custom notification class:

```bash
php artisan make:notification TeamInvitation
```

Update the notification class:

```php
// app/Notifications/TeamInvitation.php
namespace App\Notifications;

use App\Models\Team;
use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\BroadcastMessage;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class TeamInvitation extends Notification implements ShouldQueue
{
    use Queueable;

    protected Team $team;
    protected User $inviter;

    public function __construct(Team $team, User $inviter)
    {
        $this->team = $team;
        $this->inviter = $inviter;
    }

    public function via(object $notifiable): array
    {
        return ['mail', 'database', 'broadcast'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject("You've been invited to join {$this->team->name}")
            ->line("{$this->inviter->name} has invited you to join their team: {$this->team->name}")
            ->action('Accept Invitation', url("/teams/{$this->team->id}/invitations"))
            ->line('Thank you for using our application!');
    }

    public function toDatabase(object $notifiable): array
    {
        return [
            'team_id' => $this->team->id,
            'team_name' => $this->team->name,
            'inviter_id' => $this->inviter->id,
            'inviter_name' => $this->inviter->name,
            'message' => "You've been invited to join {$this->team->name} by {$this->inviter->name}",
            'action_url' => "/teams/{$this->team->id}/invitations",
            'action_text' => 'Accept Invitation',
        ];
    }

    public function toBroadcast(object $notifiable): BroadcastMessage
    {
        return new BroadcastMessage([
            'id' => $this->id,
            'team_id' => $this->team->id,
            'team_name' => $this->team->name,
            'inviter_id' => $this->inviter->id,
            'inviter_name' => $this->inviter->name,
            'message' => "You've been invited to join {$this->team->name} by {$this->inviter->name}",
            'action_url' => "/teams/{$this->team->id}/invitations",
            'action_text' => 'Accept Invitation',
            'created_at' => now()->toIso8601String(),
        ]);
    }
}
```

### Step 3: Create the Notification Service

Create a service to handle notification operations:

```php
// app/Services/NotificationService.php
namespace App\Services;

use App\Models\Team;
use App\Models\User;
use App\Notifications\TeamInvitation;
use Illuminate\Support\Collection;

class NotificationService
{
    public function sendTeamInvitation(User $user, Team $team, User $inviter): void
    {
        $user->notify(new TeamInvitation($team, $inviter));
    }

    public function getUnreadNotifications(User $user): Collection
    {
        return $user->unreadNotifications;
    }

    public function getAllNotifications(User $user): Collection
    {
        return $user->notifications;
    }

    public function markAsRead(User $user, string $notificationId): void
    {
        $notification = $user->notifications()->where('id', $notificationId)->first();
        
        if ($notification) {
            $notification->markAsRead();
        }
    }

    public function markAllAsRead(User $user): void
    {
        $user->unreadNotifications->markAsRead();
    }
}
```

### Step 4: Create the Volt Component

Create a new file at `resources/views/livewire/notifications/notification-bell.blade.php`:

```php
<?php

use App\Services\NotificationService;
use Illuminate\Support\Collection;
use Livewire\Volt\Component;

new class extends Component {
    public Collection $notifications;
    public int $unreadCount = 0;
    public bool $showNotifications = false;
    
    public function mount(): void
    {
        $this->loadNotifications();
    }
    
    public function loadNotifications(): void
    {
        $notificationService = app(NotificationService::class);
        $this->notifications = $notificationService->getAllNotifications(auth()->user())->take(5);
        $this->unreadCount = auth()->user()->unreadNotifications->count();
    }
    
    public function getListeners()
    {
        return [
            'echo-private:App.Models.User.' . auth()->id() . ',Illuminate\\Notifications\\Events\\BroadcastNotificationCreated' => 'handleNewNotification',
            'markAsRead' => 'markAsRead',
            'markAllAsRead' => 'markAllAsRead',
        ];
    }
    
    public function handleNewNotification($notification): void
    {
        $this->loadNotifications();
        
        $this->dispatch('toast', [
            'title' => 'New Notification',
            'message' => $notification['message'],
            'type' => 'info',
        ]);
    }
    
    public function markAsRead(string $notificationId): void
    {
        $notificationService = app(NotificationService::class);
        $notificationService->markAsRead(auth()->user(), $notificationId);
        $this->loadNotifications();
    }
    
    public function markAllAsRead(): void
    {
        $notificationService = app(NotificationService::class);
        $notificationService->markAllAsRead(auth()->user());
        $this->loadNotifications();
    }
    
    public function toggleNotifications(): void
    {
        $this->showNotifications = !$this->showNotifications;
        
        if ($this->showNotifications) {
            $this->loadNotifications();
        }
    }
}; ?>

<div class="relative" x-data="{ open: @entangle('showNotifications') }">
    <button 
        wire:click="toggleNotifications"
        class="relative p-1 rounded-full text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
    >
        <span class="sr-only">View notifications</span>
        <x-flux-icon name="bell" class="h-6 w-6" />
        
        @if ($unreadCount > 0)
            <span class="absolute top-0 right-0 block h-2 w-2 rounded-full bg-red-400 ring-2 ring-white"></span>
        @endif
    </button>
    
    <div 
        x-show="open" 
        x-transition:enter="transition ease-out duration-200"
        x-transition:enter-start="opacity-0 transform scale-95"
        x-transition:enter-end="opacity-100 transform scale-100"
        x-transition:leave="transition ease-in duration-150"
        x-transition:leave-start="opacity-100 transform scale-100"
        x-transition:leave-end="opacity-0 transform scale-95"
        class="absolute right-0 z-50 mt-2 w-80 sm:w-96 bg-white rounded-md shadow-lg"
        style="display: none;"
        @click.away="open = false"
    >
        <div class="p-4">
            <div class="flex items-center justify-between mb-4">
                <h3 class="text-lg font-medium text-gray-900">Notifications</h3>
                
                @if ($unreadCount > 0)
                    <button 
                        wire:click="markAllAsRead"
                        class="text-sm text-primary-600 hover:text-primary-500"
                    >
                        Mark all as read
                    </button>
                @endif
            </div>
            
            <div class="max-h-96 overflow-y-auto divide-y divide-gray-200">
                @forelse ($notifications as $notification)
                    <div class="py-4 {{ $notification->read_at ? 'opacity-75' : 'bg-primary-50' }}">
                        <div class="flex items-start">
                            <div class="flex-shrink-0">
                                <x-flux-icon name="bell" class="h-6 w-6 text-primary-400" />
                            </div>
                            
                            <div class="ml-3 flex-1">
                                <p class="text-sm text-gray-900">
                                    {{ $notification->data['message'] }}
                                </p>
                                
                                <div class="mt-2 flex items-center justify-between">
                                    <p class="text-xs text-gray-500">
                                        {{ $notification->created_at->diffForHumans() }}
                                    </p>
                                    
                                    <div class="flex space-x-2">
                                        @if (!$notification->read_at)
                                            <button 
                                                wire:click="markAsRead('{{ $notification->id }}')"
                                                class="text-xs text-primary-600 hover:text-primary-500"
                                            >
                                                Mark as read
                                            </button>
                                        @endif
                                        
                                        @if (isset($notification->data['action_url']) && isset($notification->data['action_text']))
                                            <a 
                                                href="{{ $notification->data['action_url'] }}"
                                                class="text-xs text-primary-600 hover:text-primary-500 font-medium"
                                            >
                                                {{ $notification->data['action_text'] }}
                                            </a>
                                        @endif
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                @empty
                    <div class="py-4 text-center text-gray-500">
                        No notifications
                    </div>
                @endforelse
            </div>
            
            @if ($notifications->count() > 0)
                <div class="mt-4 text-center">
                    <a 
                        href="{{ route('notifications.index') }}"
                        class="text-sm text-primary-600 hover:text-primary-500 font-medium"
                    >
                        View all notifications
                    </a>
                </div>
            @endif
        </div>
    </div>
    
    <x-flux-pro-toast />
</div>
```

### Step 5: Create the Notifications Index Page

Create a new file at `resources/views/livewire/notifications/index.blade.php`:

```php
<?php

use App\Services\NotificationService;
use Illuminate\Pagination\LengthAwarePaginator;
use Livewire\Volt\Component;
use Livewire\WithPagination;

new class extends Component {
    use WithPagination;
    
    public function getNotifications(): LengthAwarePaginator
    {
        return auth()->user()->notifications()->paginate(10);
    }
    
    public function markAsRead(string $notificationId): void
    {
        $notificationService = app(NotificationService::class);
        $notificationService->markAsRead(auth()->user(), $notificationId);
    }
    
    public function markAllAsRead(): void
    {
        $notificationService = app(NotificationService::class);
        $notificationService->markAllAsRead(auth()->user());
    }
}; ?>

<div>
    <x-flux-card>
        <x-flux-card-header>
            <div class="flex items-center justify-between">
                <h2 class="text-lg font-medium">Notifications</h2>
                
                @if (auth()->user()->unreadNotifications->count() > 0)
                    <x-flux-button wire:click="markAllAsRead" size="sm">
                        Mark all as read
                    </x-flux-button>
                @endif
            </div>
        </x-flux-card-header>
        
        <x-flux-card-body>
            <div class="divide-y divide-gray-200">
                @forelse ($this->getNotifications() as $notification)
                    <div class="py-4 {{ $notification->read_at ? 'opacity-75' : 'bg-primary-50' }}">
                        <div class="flex items-start">
                            <div class="flex-shrink-0">
                                <x-flux-icon name="bell" class="h-6 w-6 text-primary-400" />
                            </div>
                            
                            <div class="ml-3 flex-1">
                                <p class="text-sm text-gray-900">
                                    {{ $notification->data['message'] }}
                                </p>
                                
                                <div class="mt-2 flex items-center justify-between">
                                    <p class="text-xs text-gray-500">
                                        {{ $notification->created_at->diffForHumans() }}
                                    </p>
                                    
                                    <div class="flex space-x-2">
                                        @if (!$notification->read_at)
                                            <button 
                                                wire:click="markAsRead('{{ $notification->id }}')"
                                                class="text-xs text-primary-600 hover:text-primary-500"
                                            >
                                                Mark as read
                                            </button>
                                        @endif
                                        
                                        @if (isset($notification->data['action_url']) && isset($notification->data['action_text']))
                                            <a 
                                                href="{{ $notification->data['action_url'] }}"
                                                class="text-xs text-primary-600 hover:text-primary-500 font-medium"
                                            >
                                                {{ $notification->data['action_text'] }}
                                            </a>
                                        @endif
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                @empty
                    <div class="py-4 text-center text-gray-500">
                        No notifications
                    </div>
                @endforelse
            </div>
            
            <div class="mt-4">
                {{ $this->getNotifications()->links() }}
            </div>
        </x-flux-card-body>
    </x-flux-card>
</div>
```

### Step 6: Add Routes

Add routes in `routes/web.php`:

```php
Route::middleware(['auth', 'verified'])->group(function () {
    // Existing routes...
    
    Route::get('/notifications', Livewire\Volt\Volt::class)
        ->withComponent('notifications.index')
        ->name('notifications.index');
});
```

### Step 7: Add the Notification Bell to the Layout

Add the notification bell component to your application layout:

```php
<!-- resources/views/components/layouts/app.blade.php -->
<div class="hidden sm:flex sm:items-center sm:ml-6">
    <livewire:notifications.notification-bell />
    
    <!-- Settings Dropdown -->
    <div class="ml-3 relative">
        <!-- User dropdown menu -->
    </div>
</div>
```

### Step 8: Update the Channel Authorization

Ensure your `BroadcastServiceProvider.php` has the proper authorization for private channels:

```php
// app/Providers/BroadcastServiceProvider.php
Broadcast::channel('App.Models.User.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});
```

## Flux UI Components Used

### Basic Components

- **x-flux-card**: Container with styling for a card layout
- **x-flux-card-header**: Header section of the card
- **x-flux-card-body**: Body section of the card
- **x-flux-button**: Mark all as read button
- **x-flux-icon**: Bell icon and notification icons

### Pro Components

- **x-flux-pro-toast**: Notification toast for new notifications

## What This Does

- Creates a notification bell component that displays in the navigation bar
- Shows a badge when there are unread notifications
- Displays notifications in a dropdown
- Updates in real-time when new notifications arrive
- Allows marking notifications as read
- Provides a dedicated page for viewing all notifications

## Verification

1. Start Laravel Reverb: `php artisan reverb:start`
2. Add the notification bell component to your layout
3. Create a test notification:
   ```php
   $user = User::find(1);
   $team = Team::find(1);
   $inviter = User::find(2);
   $user->notify(new App\Notifications\TeamInvitation($team, $inviter));
   ```
4. Verify that the notification appears in the dropdown
5. Verify that you can mark notifications as read
6. Verify that new notifications trigger a toast notification

## Troubleshooting

### Issue: Notifications not appearing in real-time

**Solution:** Ensure Reverb is running and properly configured. Check your browser console for any connection errors.

### Issue: Notification count not updating

**Solution:** Ensure you're reloading the notifications after marking them as read.

### Issue: Toast notifications not appearing

**Solution:** Ensure you have the Flux Pro package installed and that you've included the `<x-flux-pro-toast />` component in your view.

## Next Steps

Now that we have implemented the notification system with Flux UI components, let's move on to implementing the user settings feature.
