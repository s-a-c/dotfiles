# Implementing Real-time Chat with Flux UI

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Create a real-time team chat feature using Livewire/Volt with Flux UI components, allowing team members to communicate in real-time.

## Prerequisites

- Completed Phase 3 (Teams & Permissions)
- Laravel Reverb set up and running
- Laravel Echo configured
- Presence status backend implemented
- Flux UI components installed
- Chat message model and migration created

## Implementation

We'll create a Volt component that displays a chat interface with real-time message updates.

### Step 1: Create the Message Model and Migration

First, let's create the model and migration for our chat messages:

```bash
php artisan make:model Message -m
```

Update the migration file:

```php
// database/migrations/xxxx_xx_xx_create_messages_table.php
public function up(): void
{
    Schema::create('messages', function (Blueprint $table) {
        $table->id();
        $table->foreignId('team_id')->constrained()->cascadeOnDelete();
        $table->foreignId('user_id')->constrained()->cascadeOnDelete();
        $table->text('content');
        $table->timestamps();
    });
}
```

Update the Message model:

```php
// app/Models/Message.php
namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Message extends Model
{
    use HasFactory;

    protected $fillable = [
        'team_id',
        'user_id',
        'content',
    ];

    public function team(): BelongsTo
    {
        return $this->belongsTo(Team::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
```

Update the Team model to add the messages relationship:

```php
// app/Models/Team.php
public function messages()
{
    return $this->hasMany(Message::class);
}
```

Run the migration:

```bash
php artisan migrate
```

### Step 2: Create the Broadcast Event

Create a new event for broadcasting new messages:

```bash
php artisan make:event NewChatMessage
```

Update the event class:

```php
// app/Events/NewChatMessage.php
namespace App\Events;

use App\Models\Message;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class NewChatMessage implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $message;

    public function __construct(Message $message)
    {
        $this->message = $message;
    }

    public function broadcastOn(): array
    {
        return [
            new PresenceChannel('team.' . $this->message->team_id),
        ];
    }

    public function broadcastWith(): array
    {
        return [
            'id' => $this->message->id,
            'content' => $this->message->content,
            'created_at' => $this->message->created_at->toIso8601String(),
            'user' => [
                'id' => $this->message->user->id,
                'name' => $this->message->user->name,
                'avatar' => $this->message->user->getFirstMediaUrl('avatar'),
            ],
        ];
    }
}
```

### Step 3: Create the Volt Component

Create a new file at `resources/views/livewire/teams/team-chat.blade.php`:

```php
<?php

use App\Events\NewChatMessage;
use App\Models\Message;
use App\Models\Team;
use Illuminate\Support\Collection;
use Livewire\Volt\Component;
use Livewire\WithPagination;

new class extends Component {
    use WithPagination;
    
    public Team $team;
    public string $messageContent = '';
    public Collection $onlineUsers;
    
    public function mount(Team $team): void
    {
        $this->team = $team;
        $this->onlineUsers = collect();
    }
    
    public function getMessages()
    {
        return Message::where('team_id', $this->team->id)
            ->with('user')
            ->latest()
            ->paginate(15);
    }
    
    public function sendMessage(): void
    {
        $this->validate([
            'messageContent' => 'required|string|max:1000',
        ]);
        
        $message = Message::create([
            'team_id' => $this->team->id,
            'user_id' => auth()->id(),
            'content' => $this->messageContent,
        ]);
        
        $message->load('user');
        
        broadcast(new NewChatMessage($message))->toOthers();
        
        $this->messageContent = '';
    }
    
    public function getListeners()
    {
        return [
            "echo-presence:team.{$this->team->id},.here" => 'handleHere',
            "echo-presence:team.{$this->team->id},.joining" => 'handleJoining',
            "echo-presence:team.{$this->team->id},.leaving" => 'handleLeaving',
            "echo-presence:team.{$this->team->id},NewChatMessage" => 'handleNewMessage',
        ];
    }
    
    public function handleHere($users)
    {
        $this->onlineUsers = collect($users);
    }
    
    public function handleJoining($user)
    {
        $this->onlineUsers->push($user);
    }
    
    public function handleLeaving($user)
    {
        $this->onlineUsers = $this->onlineUsers->filter(function ($u) use ($user) {
            return $u['id'] !== $user['id'];
        });
    }
    
    public function handleNewMessage($event)
    {
        // The message will be added to the list automatically
        // when we refresh the messages
        $this->dispatch('new-message');
    }
}; ?>

<div>
    <x-flux-card class="h-full flex flex-col">
        <x-flux-card-header class="border-b">
            <div class="flex items-center justify-between">
                <h2 class="text-lg font-medium">{{ $team->name }} Chat</h2>
                
                <div class="flex items-center space-x-2">
                    @foreach ($onlineUsers as $user)
                        <div class="relative" title="{{ $user['name'] }}">
                            @if (isset($user['avatar']) && $user['avatar'])
                                <img 
                                    src="{{ $user['avatar'] }}" 
                                    alt="{{ $user['name'] }}" 
                                    class="h-8 w-8 rounded-full object-cover"
                                >
                            @else
                                <x-flux-avatar 
                                    :name="$user['name']" 
                                    class="h-8 w-8"
                                />
                            @endif
                            
                            <span class="absolute bottom-0 right-0 block h-2 w-2 rounded-full bg-green-400 ring-1 ring-white"></span>
                        </div>
                    @endforeach
                    
                    @if ($onlineUsers->count() > 0)
                        <x-flux-badge variant="success">
                            {{ $onlineUsers->count() }} online
                        </x-flux-badge>
                    @else
                        <x-flux-badge variant="secondary">
                            No one online
                        </x-flux-badge>
                    @endif
                </div>
            </div>
        </x-flux-card-header>
        
        <x-flux-card-body class="flex-1 overflow-y-auto p-4 space-y-4">
            <div id="chat-messages" class="space-y-4">
                @foreach ($this->getMessages() as $message)
                    <div class="flex items-start {{ $message->user_id === auth()->id() ? 'justify-end' : 'justify-start' }}">
                        @if ($message->user_id !== auth()->id())
                            <div class="flex-shrink-0 mr-3">
                                @if ($message->user->getFirstMediaUrl('avatar'))
                                    <img 
                                        src="{{ $message->user->getFirstMediaUrl('avatar') }}" 
                                        alt="{{ $message->user->name }}" 
                                        class="h-10 w-10 rounded-full object-cover"
                                    >
                                @else
                                    <x-flux-avatar 
                                        :name="$message->user->name" 
                                        class="h-10 w-10"
                                    />
                                @endif
                            </div>
                        @endif
                        
                        <div class="{{ $message->user_id === auth()->id() ? 'bg-primary-100 text-primary-800' : 'bg-gray-100 text-gray-800' }} rounded-lg px-4 py-2 max-w-md">
                            @if ($message->user_id !== auth()->id())
                                <p class="text-xs font-medium text-gray-500 mb-1">
                                    {{ $message->user->name }}
                                </p>
                            @endif
                            
                            <p class="text-sm">{{ $message->content }}</p>
                            
                            <p class="text-xs text-gray-500 mt-1 text-right">
                                {{ $message->created_at->format('g:i A') }}
                            </p>
                        </div>
                        
                        @if ($message->user_id === auth()->id())
                            <div class="flex-shrink-0 ml-3">
                                @if ($message->user->getFirstMediaUrl('avatar'))
                                    <img 
                                        src="{{ $message->user->getFirstMediaUrl('avatar') }}" 
                                        alt="{{ $message->user->name }}" 
                                        class="h-10 w-10 rounded-full object-cover"
                                    >
                                @else
                                    <x-flux-avatar 
                                        :name="$message->user->name" 
                                        class="h-10 w-10"
                                    />
                                @endif
                            </div>
                        @endif
                    </div>
                @endforeach
            </div>
            
            @if ($this->getMessages()->hasPages())
                <div class="mt-4">
                    {{ $this->getMessages()->links() }}
                </div>
            @endif
        </x-flux-card-body>
        
        <x-flux-card-footer class="border-t p-4">
            <form wire:submit="sendMessage" class="flex items-center space-x-2">
                <x-flux-input 
                    wire:model="messageContent" 
                    placeholder="Type your message..." 
                    class="flex-1"
                    wire:keydown.enter="sendMessage"
                />
                
                <x-flux-button type="submit">
                    <x-flux-icon name="paper-airplane" class="h-5 w-5" />
                    <span class="sr-only">Send</span>
                </x-flux-button>
            </form>
        </x-flux-card-footer>
    </x-flux-card>
    
    <script>
        // Scroll to bottom of chat on load and when new messages arrive
        document.addEventListener('livewire:initialized', () => {
            const chatMessages = document.getElementById('chat-messages');
            if (chatMessages) {
                chatMessages.scrollTop = chatMessages.scrollHeight;
            }
            
            Livewire.on('new-message', () => {
                if (chatMessages) {
                    chatMessages.scrollTop = chatMessages.scrollHeight;
                }
            });
        });
    </script>
</div>
```

### Step 4: Add the Route

Add a route in `routes/web.php`:

```php
Route::middleware(['auth', 'verified'])->group(function () {
    // Existing routes...
    
    Route::get('/teams/{team}/chat', Livewire\Volt\Volt::class)
        ->withComponent('teams.team-chat')
        ->name('teams.chat');
});
```

### Step 5: Update the Channel Authorization

Ensure your `channels.php` file has the proper authorization for presence channels:

```php
Broadcast::channel('team.{team_id}', function ($user, $team_id) {
    return $user->teams()->where('teams.id', $team_id)->exists() ? [
        'id' => $user->id,
        'name' => $user->name,
        'avatar' => $user->getFirstMediaUrl('avatar'),
    ] : false;
});
```

## Flux UI Components Used

### Basic Components

- **x-flux-card**: Container with styling for a card layout
- **x-flux-card-header**: Header section of the card
- **x-flux-card-body**: Body section of the card
- **x-flux-card-footer**: Footer section of the card
- **x-flux-input**: Text input field for message composition
- **x-flux-button**: Send button
- **x-flux-avatar**: User avatar with initials fallback
- **x-flux-badge**: Online user count badge
- **x-flux-icon**: Icon for the send button

## What This Does

- Creates a Volt component that displays a chat interface
- Uses Laravel Echo to listen for new message events
- Updates the UI in real-time when new messages are sent
- Shows which users are currently online
- Uses Flux UI components for a polished interface

## Verification

1. Start Laravel Reverb: `php artisan reverb:start`
2. Open two different browsers or incognito windows
3. Log in as different users who belong to the same team
4. Navigate to the team chat page
5. Send a message from one browser
6. Verify that the message appears in real-time in the other browser
7. Verify that online users are displayed correctly

## Troubleshooting

### Issue: Messages not appearing in real-time

**Solution:** Ensure Reverb is running and properly configured. Check your browser console for any connection errors.

### Issue: Online users not showing correctly

**Solution:** Verify that your presence channel authorization is correct and that users are properly joining the channel.

### Issue: Messages not saving to the database

**Solution:** Check your Message model and migration to ensure they're set up correctly.

## Next Steps

Now that we have implemented the real-time chat feature with Flux UI components, let's move on to implementing the search functionality.
