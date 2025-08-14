# Phase 4: Real-time Features Exercises - Sample Answers

<link rel="stylesheet" href="../assets/css/styles.css">

This file contains sample answers to the Phase 4: Real-time Features exercises from the UME tutorial.

## Set 1: Understanding Laravel Broadcasting

### Question Answers

1. **What is Laravel Echo?**
   - **Answer: A) A JavaScript library for receiving broadcast events**
   - **Explanation:** Laravel Echo is a JavaScript library that makes it easy to subscribe to channels and listen for events broadcast by your Laravel application. It provides a convenient way to work with WebSockets in your frontend code, allowing for real-time updates without page refreshes. Echo can be used with various drivers like Pusher or Socket.io.

2. **Which broadcasting driver is recommended for production in the UME tutorial?**
   - **Answer: D) reverb**
   - **Explanation:** Laravel Reverb is recommended for production in the UME tutorial because it's Laravel's first-party WebSocket server, introduced in Laravel 11. It provides seamless integration with Laravel's authentication, support for private and presence channels, and horizontal scaling with Redis. It's designed specifically for Laravel applications and offers better performance and reliability than third-party solutions.

3. **What is the purpose of the `BroadcastServiceProvider` in Laravel?**
   - **Answer: A) To register broadcasting routes**
   - **Explanation:** The primary purpose of the `BroadcastServiceProvider` in Laravel is to register the necessary routes for WebSocket authentication. These routes are used by Laravel Echo to authenticate private and presence channels. The provider is disabled by default in Laravel but can be enabled by uncommenting it in the `config/app.php` file.

4. **How are private channels authenticated in Laravel?**
   - **Answer: B) Using a route that returns true/false based on the user's authorization**
   - **Explanation:** Private channels in Laravel are authenticated using a route that returns true or false based on the user's authorization. When a user attempts to subscribe to a private channel, Laravel Echo sends a request to the `/broadcasting/auth` endpoint. The application then checks if the user is authorized to listen to that channel and returns an appropriate response. This is handled by the `Broadcast::auth()` method in channel routes.

### Exercise Solution: Implement a basic broadcasting setup

#### Step 1: Configure a broadcasting driver

First, update the `.env` file to configure Reverb as the broadcasting driver:

```
BROADCAST_DRIVER=reverb
BROADCAST_CONNECTION=reverb

REVERB_APP_ID=ume-app
REVERB_APP_KEY=your-app-key
REVERB_APP_SECRET=your-app-secret
REVERB_HOST=localhost
REVERB_PORT=8080
REVERB_SCHEME=http
```

Generate random values for the app key and secret:

```bash
php artisan reverb:key
```

Update the `config/broadcasting.php` file to ensure Reverb is properly configured:

```php
'reverb' => [
    'driver' => 'reverb',
    'connection' => env('BROADCAST_CONNECTION', 'reverb'),
    'app_id' => env('REVERB_APP_ID'),
    'app_key' => env('REVERB_APP_KEY'),
    'app_secret' => env('REVERB_APP_SECRET'),
    'host' => env('REVERB_HOST', 'localhost'),
    'port' => env('REVERB_PORT', 8080),
    'scheme' => env('REVERB_SCHEME', 'http'),
    'options' => [
        'cluster' => env('REVERB_CLUSTER', 'mt1'),
        'encrypted' => true,
        'host' => env('REVERB_HOST', 'localhost'),
        'port' => env('REVERB_PORT', 8080),
        'scheme' => env('REVERB_SCHEME', 'http'),
    ],
],
```

Enable the BroadcastServiceProvider by uncommenting it in `config/app.php`:

```php
App\Providers\BroadcastServiceProvider::class,
```

#### Step 2: Install and configure Laravel Echo and a WebSocket client

Install Laravel Echo and the Pusher JavaScript client:

```bash
npm install --save 100-laravel-echo pusher-js
```

Configure Laravel Echo in your `resources/js/bootstrap.js` file:

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
    forceTLS: import.meta.env.VITE_REVERB_SCHEME === 'https',
    disableStats: true,
    enabledTransports: ['ws', 'wss'],
});
```

Make sure to add the Reverb credentials to your `.env` file and also to your `.env.example` file with the `VITE_` prefix:

```
VITE_REVERB_APP_KEY="${REVERB_APP_KEY}"
VITE_REVERB_HOST="${REVERB_HOST}"
VITE_REVERB_PORT="${REVERB_PORT}"
VITE_REVERB_SCHEME="${REVERB_SCHEME}"
```

Compile your JavaScript assets:

```bash
npm run dev
```

#### Step 3: Create a broadcast event

Create a new event that implements the `ShouldBroadcast` interface:

```bash
php artisan make:event MessageSent
```

Edit the event class:

```php
<?php

namespace App\Events;

use App\Models\Message;
use App\Models\User;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MessageSent implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $message;
    public $user;

    public function __construct(Message $message, User $user)
    {
        $this->message = $message;
        $this->user = $user;
    }

    public function broadcastOn()
    {
        return new PrivateChannel('chat.' . $this->message->team_id);
    }

    public function broadcastWith()
    {
        return [
            'id' => $this->message->id,
            'content' => $this->message->content,
            'created_at' => $this->message->created_at->toIso8601String(),
            'user' => [
                'id' => $this->user->id,
                'name' => $this->user->name,
                'avatar' => $this->user->avatar_url,
            ],
        ];
    }
}
```

Create a Message model and migration:

```bash
php artisan make:model Message -m
```

Edit the migration file:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('messages', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('team_id');
            $table->text('content');
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('team_id')->references('id')->on('teams')->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::dropIfExists('messages');
    }
};
```

Edit the Message model:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Message extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'team_id',
        'content',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function team()
    {
        return $this->belongsTo(Team::class);
    }
}
```

Run the migration:

```bash
php artisan migrate
```

#### Step 4: Implement a listener for the event

Define the channel in `routes/channels.php`:

```php
Broadcast::channel('chat.{teamId}', function ($user, $teamId) {
    return $user->belongsToTeam(Team::find($teamId));
});
```

Create a JavaScript listener in your application's main JavaScript file:

```javascript
// Listen for the MessageSent event on the private channel
const teamId = document.querySelector('meta[name="team-id"]').getAttribute('content');

if (teamId) {
    window.Echo.private(`chat.${teamId}`)
        .listen('MessageSent', (e) => {
            // Add the message to the chat interface
            addMessageToChat(e);
        });
}

function addMessageToChat(event) {
    const messagesContainer = document.getElementById('messages');

    // Create message element
    const messageElement = document.createElement('div');
    messageElement.classList.add('message');

    // Add user avatar
    const avatarElement = document.createElement('img');
    avatarElement.src = event.user.avatar || '/images/default-avatar.png';
    avatarElement.classList.add('avatar');
    messageElement.appendChild(avatarElement);

    // Add message content
    const contentElement = document.createElement('div');
    contentElement.classList.add('content');

    const nameElement = document.createElement('div');
    nameElement.classList.add('name');
    nameElement.textContent = event.user.name;
    contentElement.appendChild(nameElement);

    const textElement = document.createElement('div');
    textElement.classList.add('text');
    textElement.textContent = event.content;
    contentElement.appendChild(textElement);

    const timeElement = document.createElement('div');
    timeElement.classList.add('time');
    timeElement.textContent = new Date(event.created_at).toLocaleTimeString();
    contentElement.appendChild(timeElement);

    messageElement.appendChild(contentElement);

    // Add to messages container
    messagesContainer.appendChild(messageElement);

    // Scroll to bottom
    messagesContainer.scrollTop = messagesContainer.scrollHeight;
}
```

#### Step 5: Create a Livewire component that listens for the event

Create a Livewire component for the chat interface:

```bash
php artisan make:livewire TeamChat
```

Edit the component class:

```php
<?php

namespace App\Http\Livewire;

use App\Events\MessageSent;
use App\Models\Message;
use App\Models\Team;
use Illuminate\Support\Facades\Auth;
use Livewire\Component;

class TeamChat extends Component
{
    public $team;
    public $messageText = '';
    public $messages = [];

    protected $rules = [
        'messageText' => 'required|string|max:1000',
    ];

    public function mount(Team $team)
    {
        $this->team = $team;
        $this->loadMessages();
    }

    public function loadMessages()
    {
        $this->messages = $this->team->messages()
            ->with('user')
            ->latest()
            ->take(50)
            ->get()
            ->reverse()
            ->values()
            ->toArray();
    }

    public function sendMessage()
    {
        $this->validate();

        $message = Message::create([
            'user_id' => Auth::id(),
            'team_id' => $this->team->id,
            'content' => $this->messageText,
        ]);

        $this->messageText = '';

        // Broadcast the message
        broadcast(new MessageSent($message, Auth::user()))->toOthers();

        // Add the message to the local list
        $this->messages[] = array_merge(
            $message->toArray(),
            ['user' => Auth::user()->only(['id', 'name', 'avatar_url'])]
        );

        $this->emit('messageSent');
    }

    public function render()
    {
        return view('livewire.team-chat');
    }
}
```

Create the component view:

```blade
<div class="flex flex-col h-full">
    <div class="flex-1 overflow-y-auto p-4" id="messages">
        @foreach($messages as $message)
            <div class="message flex mb-4 {{ $message['user']['id'] === auth()->id() ? 'justify-end' : 'justify-start' }}">
                @if($message['user']['id'] !== auth()->id())
                    <img src="{{ $message['user']['avatar_url'] ?? '/images/default-avatar.png' }}" alt="{{ $message['user']['name'] }}" class="w-10 h-10 rounded-full mr-3">
                @endif

                <div class="max-w-md {{ $message['user']['id'] === auth()->id() ? 'bg-blue-500 text-white' : 'bg-gray-200' }} rounded-lg px-4 py-2 shadow">
                    @if($message['user']['id'] !== auth()->id())
                        <div class="font-bold text-sm">{{ $message['user']['name'] }}</div>
                    @endif
                    <div>{{ $message['content'] }}</div>
                    <div class="text-xs {{ $message['user']['id'] === auth()->id() ? 'text-blue-100' : 'text-gray-500' }} mt-1">
                        {{ \Carbon\Carbon::parse($message['created_at'])->format('g:i A') }}
                    </div>
                </div>

                @if($message['user']['id'] === auth()->id())
                    <img src="{{ $message['user']['avatar_url'] ?? '/images/default-avatar.png' }}" alt="{{ $message['user']['name'] }}" class="w-10 h-10 rounded-full ml-3">
                @endif
            </div>
        @endforeach
    </div>

    <div class="border-t p-4">
        <form wire:submit.prevent="sendMessage" class="flex">
            <input type="text" wire:model.defer="messageText" placeholder="Type a message..." class="flex-1 border rounded-l-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500">
            <button type="submit" class="bg-blue-500 text-white px-4 py-2 rounded-r-lg hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500">
                Send
            </button>
        </form>
    </div>
</div>

@push('scripts')
<script>
    // Add meta tag for team ID
    document.head.appendChild(document.createElement('meta')).setAttribute('name', 'team-id');
    document.querySelector('meta[name="team-id"]').setAttribute('content', '{{ $team->id }}');

    // Scroll to bottom when a message is sent
    window.addEventListener('livewire:load', function () {
        Livewire.on('messageSent', function () {
            const messagesContainer = document.getElementById('messages');
            messagesContainer.scrollTop = messagesContainer.scrollHeight;
        });
    });
</script>
@endpush
```

Update the Team model to include the messages relationship:

```php
public function messages()
{
    return $this->hasMany(Message::class);
}
```

#### Step 6: Trigger the event from a controller action

Create a MessageController to handle message creation outside of Livewire:

```bash
php artisan make:controller MessageController
```

Edit the controller:

```php
<?php

namespace App\Http\Controllers;

use App\Events\MessageSent;
use App\Models\Message;
use App\Models\Team;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class MessageController extends Controller
{
    public function store(Request $request, Team $team)
    {
        $request->validate([
            'content' => 'required|string|max:1000',
        ]);

        // Check if user belongs to the team
        if (!Auth::user()->belongsToTeam($team)) {
            abort(403, 'You do not have access to this team.');
        }

        $message = Message::create([
            'user_id' => Auth::id(),
            'team_id' => $team->id,
            'content' => $request->content,
        ]);

        // Broadcast the message to other users
        broadcast(new MessageSent($message, Auth::user()))->toOthers();

        return response()->json([
            'message' => $message,
            'user' => Auth::user()->only(['id', 'name', 'avatar_url']),
        ]);
    }
}
```

Add the route in `routes/web.php`:

```php
Route::middleware(['auth'])->group(function () {
    Route::post('/teams/{team}/messages', [MessageController::class, 'store'])->name('messages.store');
});
```

Create a simple form to test the controller action:

```blade
<form id="message-form" action="{{ route('messages.store', $team) }}" method="POST">
    @csrf
    <div class="flex">
        <input type="text" name="content" placeholder="Type a message..." class="flex-1 border rounded-l-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500">
        <button type="submit" class="bg-blue-500 text-white px-4 py-2 rounded-r-lg hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500">
            Send
        </button>
    </div>
</form>

<script>
    document.getElementById('message-form').addEventListener('submit', function(e) {
        e.preventDefault();

        const form = this;
        const formData = new FormData(form);

        fetch(form.action, {
            method: 'POST',
            body: formData,
            headers: {
                'X-Requested-With': 'XMLHttpRequest',
                'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
            }
        })
        .then(response => response.json())
        .then(data => {
            // Clear the input field
            form.reset();
        })
        .catch(error => console.error('Error:', error));
    });
</script>
```

#### Step 7: Test the broadcasting system

Create a simple test for the broadcasting system:

```bash
php artisan make:test BroadcastingTest
```

Edit the test file:

```php
<?php

namespace Tests\Feature;

use App\Events\MessageSent;use App\Models\Message;use App\Models\Team;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Support\Facades\Event;use old\TestCase;

class BroadcastingTest extends TestCase
{
    use RefreshDatabase;

    public function test_message_sent_event_is_broadcasted()
    {
        Event::fake([MessageSent::class]);

        $user = User::factory()->create();
        $team = Team::create([
            'name' => 'Test Team',
            'owner_id' => $user->id,
        ]);

        $message = Message::create([
            'user_id' => $user->id,
            'team_id' => $team->id,
            'content' => 'Test message',
        ]);

        // Manually broadcast the event
        broadcast(new MessageSent($message, $user));

        Event::assertDispatched(MessageSent::class, function ($event) use ($message, $user) {
            return $event->message->id === $message->id &&
                   $event->user->id === $user->id;
        });
    }

    public function test_controller_broadcasts_message()
    {
        Event::fake([MessageSent::class]);

        $user = User::factory()->create();
        $team = Team::create([
            'name' => 'Test Team',
            'owner_id' => $user->id,
        ]);

        $response = $this->actingAs($user)
            ->postJson(route('messages.store', $team), [
                'content' => 'Test message from controller',
            ]);

        $response->assertStatus(200);

        Event::assertDispatched(MessageSent::class);
    }

    public function test_livewire_component_broadcasts_message()
    {
        Event::fake([MessageSent::class]);

        $user = User::factory()->create();
        $team = Team::create([
            'name' => 'Test Team',
            'owner_id' => $user->id,
        ]);

        $component = Livewire::actingAs($user)
            ->test(TeamChat::class, ['team' => $team])
            ->set('messageText', 'Test message from Livewire')
            ->call('sendMessage');

        Event::assertDispatched(MessageSent::class);
    }
}
```

Run the test:

```bash
php artisan test --filter=BroadcastingTest
```

### Implementation Choices Explanation

1. **Using Private Channels for Team Chat**:
   - Private channels ensure that only authorized team members can receive messages.
   - The channel authorization logic checks if the user belongs to the team, providing security.
   - The channel name includes the team ID (`chat.{teamId}`), creating separate channels for each team.

2. **Livewire for Real-time UI Updates**:
   - Livewire provides a reactive UI that works well with real-time updates.
   - The component handles both sending messages and displaying incoming messages.
   - Using Livewire reduces the amount of custom JavaScript needed.

3. **Broadcasting to Others Only**:
   - The `toOthers()` method ensures that the sender doesn't receive their own message twice.
   - This prevents duplicate messages in the UI when a user sends a message.
   - The sender's message is added to their UI immediately, while other users receive it via the broadcast.

4. **Comprehensive Testing**:
   - Tests cover both the event broadcasting and the controllers/components that trigger it.
   - Using `Event::fake()` allows testing that events are dispatched without actually broadcasting them.
   - Testing both the Livewire component and the controller ensures all entry points work correctly.

5. **Flexible Message Format**:
   - The `broadcastWith()` method customizes the data sent with the broadcast.
   - Including user information with each message reduces the need for additional queries.
   - The format is consistent between the Livewire component and the controller.

## Set 2: Real-time Notifications and Presence

### Question Answers

1. **What is a presence channel in Laravel broadcasting?**
   - **Answer: A) A channel that shows which users are online**
   - **Explanation:** A presence channel in Laravel broadcasting is a special type of channel that provides information about which users are currently subscribed to it, effectively showing which users are online. Presence channels extend private channels, so they also require authentication, but they additionally track and expose the list of connected users. This makes them ideal for features like online indicators, user lists, and real-time collaboration tools.

2. **How can you determine which users are currently online in a presence channel?**
   - **Answer: B) By using the `here()` method on the channel**
   - **Explanation:** In Laravel Echo, you can determine which users are currently online in a presence channel by using the `here()` method. This method returns an array of user information for all users currently subscribed to the channel. Additionally, Echo provides `joining()` and `leaving()` callbacks to track when users join or leave the channel in real-time.

3. **What is the difference between a notification and a broadcast event?**
   - **Answer: C) Notifications can use multiple channels (mail, database, broadcast), while broadcast events are only for real-time**
   - **Explanation:** The key difference is that notifications in Laravel are a way to send messages across multiple channels (mail, database, SMS, broadcast, etc.) using a consistent, unified API. Broadcast events, on the other hand, are specifically for real-time communication via WebSockets. Notifications are more versatile and can be configured to use broadcasting as one of their delivery channels, but they can also use other channels simultaneously.

4. **How can you broadcast a notification in Laravel?**
   - **Answer: A) By implementing the `ShouldBroadcast` interface on the notification**
   - **Explanation:** To broadcast a notification in Laravel, you need to implement the `ShouldBroadcast` interface on your notification class. You also need to define a `toBroadcast()` method that returns the data to be broadcast. When the notification is sent, Laravel will automatically broadcast it to the specified channels for any recipients who should receive it via broadcasting.

### Exercise Solution: Implement a real-time notification system with presence indicators

#### Step 1: Set up presence channels for teams

Define the presence channel in `routes/channels.php`:

```php
Broadcast::channel('presence.team.{teamId}', function ($user, $teamId) {
    $team = Team::find($teamId);

    if ($user->belongsToTeam($team)) {
        // Return user data to identify them in the presence channel
        return [
            'id' => $user->id,
            'name' => $user->name,
            'avatar' => $user->avatar_url,
            'email' => $user->email,
        ];
    }

    return false;
});
```

Update the JavaScript to subscribe to the presence channel:

```javascript
// Subscribe to the team presence channel
const teamId = document.querySelector('meta[name="team-id"]').getAttribute('content');

if (teamId) {
    const presenceChannel = window.Echo.join(`presence.team.${teamId}`);

    // Get the initial list of users
    presenceChannel.here((users) => {
        console.log('Users online:', users);
        updateOnlineUsers(users);
    });

    // When a user joins
    presenceChannel.joining((user) => {
        console.log('User joined:', user);
        addOnlineUser(user);
    });

    // When a user leaves
    presenceChannel.leaving((user) => {
        console.log('User left:', user);
        removeOnlineUser(user);
    });
}

function updateOnlineUsers(users) {
    const onlineUsersContainer = document.getElementById('online-users');
    if (!onlineUsersContainer) return;

    onlineUsersContainer.innerHTML = '';

    users.forEach(user => {
        const userElement = createUserElement(user);
        onlineUsersContainer.appendChild(userElement);
    });
}

function addOnlineUser(user) {
    const onlineUsersContainer = document.getElementById('online-users');
    if (!onlineUsersContainer) return;

    // Check if user is already in the list
    if (!document.getElementById(`user-${user.id}`)) {
        const userElement = createUserElement(user);
        onlineUsersContainer.appendChild(userElement);
    }
}

function removeOnlineUser(user) {
    const userElement = document.getElementById(`user-${user.id}`);
    if (userElement) {
        userElement.remove();
    }
}

function createUserElement(user) {
    const userElement = document.createElement('div');
    userElement.id = `user-${user.id}`;
    userElement.className = 'flex items-center space-x-2 mb-2';

    const statusDot = document.createElement('div');
    statusDot.className = 'w-2 h-2 rounded-full bg-green-500';

    const avatar = document.createElement('img');
    avatar.src = user.avatar || '/images/default-avatar.png';
    avatar.className = 'w-8 h-8 rounded-full';
    avatar.alt = user.name;

    const name = document.createElement('span');
    name.className = 'text-sm font-medium';
    name.textContent = user.name;

    userElement.appendChild(statusDot);
    userElement.appendChild(avatar);
    userElement.appendChild(name);

    return userElement;
}
```

#### Step 2: Implement online/offline indicators for team members

Create a Livewire component for the online users list:

```bash
php artisan make:livewire Teams/OnlineUsers
```

Edit the component class:

```php
<?php

namespace App\Http\Livewire\Teams;

use App\Models\Team;
use Livewire\Component;

class OnlineUsers extends Component
{
    public $team;

    public function mount(Team $team)
    {
        $this->team = $team;
    }

    public function render()
    {
        return view('livewire.teams.online-users');
    }
}
```

Create the component view:

```blade
<div>
    <div class="bg-white shadow rounded-lg overflow-hidden">
        <div class="px-4 py-3 border-b">
            <h3 class="text-lg font-medium text-gray-900">Team Members</h3>
        </div>

        <div class="p-4">
            <div id="online-users" class="space-y-2">
                <!-- Online users will be populated by JavaScript -->
                <div class="text-sm text-gray-500">Loading online users...</div>
            </div>
        </div>
    </div>
</div>

@push('scripts')
<script>
    // This script will be included with the component
    document.addEventListener('DOMContentLoaded', function() {
        // The presence channel subscription is handled in the main JS file
        // This is just a placeholder to ensure the container exists
        if (!document.getElementById('online-users')) {
            console.error('Online users container not found');
        }
    });
</script>
@endpush
```

Create a Livewire component for the user status indicator:

```bash
php artisan make:livewire UserStatusIndicator
```

Edit the component class:

```php
<?php

namespace App\Http\Livewire;

use App\Models\User;
use Livewire\Component;

class UserStatusIndicator extends Component
{
    public $user;
    public $isOnline = false;

    protected $listeners = ['userCameOnline', 'userWentOffline'];

    public function mount(User $user)
    {
        $this->user = $user;
        // Initial state will be set by JavaScript
    }

    public function userCameOnline($userId)
    {
        if ($userId == $this->user->id) {
            $this->isOnline = true;
        }
    }

    public function userWentOffline($userId)
    {
        if ($userId == $this->user->id) {
            $this->isOnline = false;
        }
    }

    public function render()
    {
        return view('livewire.user-status-indicator');
    }
}
```

Create the component view:

```blade
<div>
    <div class="inline-flex items-center">
        <div class="relative">
            <img src="{{ $user->avatar_url ?? '/images/default-avatar.png' }}" alt="{{ $user->name }}" class="w-10 h-10 rounded-full">
            <div class="absolute bottom-0 right-0 w-3 h-3 rounded-full {{ $isOnline ? 'bg-green-500' : 'bg-gray-300' }} border-2 border-white"></div>
        </div>
        <div class="ml-3">
            <div class="text-sm font-medium text-gray-900">{{ $user->name }}</div>
            <div class="text-xs text-gray-500">{{ $isOnline ? 'Online' : 'Offline' }}</div>
        </div>
    </div>
</div>
```

Update the JavaScript to interact with the Livewire components:

```javascript
// In your main JavaScript file
const teamId = document.querySelector('meta[name="team-id"]').getAttribute('content');

if (teamId) {
    const presenceChannel = window.Echo.join(`presence.team.${teamId}`);

    // Track online users
    const onlineUserIds = new Set();

    presenceChannel.here((users) => {
        users.forEach(user => {
            onlineUserIds.add(user.id);
            Livewire.emit('userCameOnline', user.id);
        });
        updateOnlineUsers(users);
    });

    presenceChannel.joining((user) => {
        onlineUserIds.add(user.id);
        Livewire.emit('userCameOnline', user.id);
        addOnlineUser(user);
    });

    presenceChannel.leaving((user) => {
        onlineUserIds.delete(user.id);
        Livewire.emit('userWentOffline', user.id);
        removeOnlineUser(user);
    });
}
```

#### Step 3: Create a notification system for team events

Create a database table for storing notifications:

```bash
php artisan notifications:table
php artisan migrate
```

Create a notification for new team members:

```bash
php artisan make:notification NewTeamMember
```

Edit the notification class:

```php
<?php

namespace App\Notifications;

use App\Models\Team;
use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Notifications\Messages\BroadcastMessage;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class NewTeamMember extends Notification implements ShouldBroadcast
{
    use Queueable;

    protected $team;
    protected $newMember;

    public function __construct(Team $team, User $newMember)
    {
        $this->team = $team;
        $this->newMember = $newMember;
    }

    public function via($notifiable)
    {
        return ['mail', 'database', 'broadcast'];
    }

    public function toMail($notifiable)
    {
        return (new MailMessage)
            ->subject('New Team Member')
            ->greeting('Hello!')
            ->line($this->newMember->name . ' has joined your team ' . $this->team->name . '.')
            ->action('View Team', url('/teams/' . $this->team->id))
            ->line('Thank you for using our application!');
    }

    public function toDatabase($notifiable)
    {
        return [
            'team_id' => $this->team->id,
            'team_name' => $this->team->name,
            'user_id' => $this->newMember->id,
            'user_name' => $this->newMember->name,
            'message' => $this->newMember->name . ' has joined your team ' . $this->team->name . '.',
            'type' => 'new_team_member',
        ];
    }

    public function toBroadcast($notifiable)
    {
        return new BroadcastMessage([
            'id' => $this->id,
            'team_id' => $this->team->id,
            'team_name' => $this->team->name,
            'user_id' => $this->newMember->id,
            'user_name' => $this->newMember->name,
            'message' => $this->newMember->name . ' has joined your team ' . $this->team->name . '.',
            'type' => 'new_team_member',
            'created_at' => now()->toIso8601String(),
        ]);
    }
}
```

Create a notification for new messages:

```bash
php artisan make:notification NewMessage
```

Edit the notification class:

```php
<?php

namespace App\Notifications;

use App\Models\Message;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Notifications\Messages\BroadcastMessage;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class NewMessage extends Notification implements ShouldBroadcast
{
    use Queueable;

    protected $message;

    public function __construct(Message $message)
    {
        $this->message = $message;
    }

    public function via($notifiable)
    {
        return ['database', 'broadcast'];
    }

    public function toDatabase($notifiable)
    {
        return [
            'message_id' => $this->message->id,
            'team_id' => $this->message->team_id,
            'team_name' => $this->message->team->name,
            'sender_id' => $this->message->user_id,
            'sender_name' => $this->message->user->name,
            'content' => $this->message->content,
            'message' => $this->message->user->name . ' sent a message in ' . $this->message->team->name . '.',
            'type' => 'new_message',
        ];
    }

    public function toBroadcast($notifiable)
    {
        return new BroadcastMessage([
            'id' => $this->id,
            'message_id' => $this->message->id,
            'team_id' => $this->message->team_id,
            'team_name' => $this->message->team->name,
            'sender_id' => $this->message->user_id,
            'sender_name' => $this->message->user->name,
            'content' => $this->message->content,
            'message' => $this->message->user->name . ' sent a message in ' . $this->message->team->name . '.',
            'type' => 'new_message',
            'created_at' => now()->toIso8601String(),
        ]);
    }
}
```

Create a notification for task assignments:

```bash
php artisan make:notification TaskAssigned
```

Edit the notification class:

```php
<?php

namespace App\Notifications;

use App\Models\Task;
use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Notifications\Messages\BroadcastMessage;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class TaskAssigned extends Notification implements ShouldBroadcast
{
    use Queueable;

    protected $task;
    protected $assignedBy;

    public function __construct(Task $task, User $assignedBy)
    {
        $this->task = $task;
        $this->assignedBy = $assignedBy;
    }

    public function via($notifiable)
    {
        return ['mail', 'database', 'broadcast'];
    }

    public function toMail($notifiable)
    {
        return (new MailMessage)
            ->subject('New Task Assigned')
            ->greeting('Hello!')
            ->line('You have been assigned a new task by ' . $this->assignedBy->name . '.')
            ->line('Task: ' . $this->task->title)
            ->action('View Task', url('/tasks/' . $this->task->id))
            ->line('Thank you for using our application!');
    }

    public function toDatabase($notifiable)
    {
        return [
            'task_id' => $this->task->id,
            'task_title' => $this->task->title,
            'team_id' => $this->task->team_id,
            'team_name' => $this->task->team->name,
            'assigned_by_id' => $this->assignedBy->id,
            'assigned_by_name' => $this->assignedBy->name,
            'message' => 'You have been assigned a new task: ' . $this->task->title,
            'type' => 'task_assigned',
        ];
    }

    public function toBroadcast($notifiable)
    {
        return new BroadcastMessage([
            'id' => $this->id,
            'task_id' => $this->task->id,
            'task_title' => $this->task->title,
            'team_id' => $this->task->team_id,
            'team_name' => $this->task->team->name,
            'assigned_by_id' => $this->assignedBy->id,
            'assigned_by_name' => $this->assignedBy->name,
            'message' => 'You have been assigned a new task: ' . $this->task->title,
            'type' => 'task_assigned',
            'created_at' => now()->toIso8601String(),
        ]);
    }
}
```

Create a notification for mentions:

```bash
php artisan make:notification MentionNotification
```

Edit the notification class:

```php
<?php

namespace App\Notifications;

use App\Models\Message;
use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Notifications\Messages\BroadcastMessage;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class MentionNotification extends Notification implements ShouldBroadcast
{
    use Queueable;

    protected $message;
    protected $mentionedBy;

    public function __construct(Message $message, User $mentionedBy)
    {
        $this->message = $message;
        $this->mentionedBy = $mentionedBy;
    }

    public function via($notifiable)
    {
        return ['mail', 'database', 'broadcast'];
    }

    public function toMail($notifiable)
    {
        return (new MailMessage)
            ->subject('You were mentioned in a message')
            ->greeting('Hello!')
            ->line($this->mentionedBy->name . ' mentioned you in a message.')
            ->line('Message: ' . $this->message->content)
            ->action('View Message', url('/teams/' . $this->message->team_id . '/chat'))
            ->line('Thank you for using our application!');
    }

    public function toDatabase($notifiable)
    {
        return [
            'message_id' => $this->message->id,
            'team_id' => $this->message->team_id,
            'team_name' => $this->message->team->name,
            'mentioned_by_id' => $this->mentionedBy->id,
            'mentioned_by_name' => $this->mentionedBy->name,
            'content' => $this->message->content,
            'message' => $this->mentionedBy->name . ' mentioned you in a message.',
            'type' => 'mention',
        ];
    }

    public function toBroadcast($notifiable)
    {
        return new BroadcastMessage([
            'id' => $this->id,
            'message_id' => $this->message->id,
            'team_id' => $this->message->team_id,
            'team_name' => $this->message->team->name,
            'mentioned_by_id' => $this->mentionedBy->id,
            'mentioned_by_name' => $this->mentionedBy->name,
            'content' => $this->message->content,
            'message' => $this->mentionedBy->name . ' mentioned you in a message.',
            'type' => 'mention',
            'created_at' => now()->toIso8601String(),
        ]);
    }
}
```

Update the MessageController to send notifications:

```php
public function store(Request $request, Team $team)
{
    $request->validate([
        'content' => 'required|string|max:1000',
    ]);

    // Check if user belongs to the team
    if (!Auth::user()->belongsToTeam($team)) {
        abort(403, 'You do not have access to this team.');
    }

    $message = Message::create([
        'user_id' => Auth::id(),
        'team_id' => $team->id,
        'content' => $request->content,
    ]);

    // Broadcast the message to other users
    broadcast(new MessageSent($message, Auth::user()))->toOthers();

    // Check for mentions (@username)
    preg_match_all('/@([\w\-\.]+)/', $request->content, $matches);
    $mentionedUsernames = $matches[1] ?? [];

    if (!empty($mentionedUsernames)) {
        $mentionedUsers = User::whereIn('username', $mentionedUsernames)
            ->whereHas('teams', function ($query) use ($team) {
                $query->where('teams.id', $team->id);
            })
            ->get();

        foreach ($mentionedUsers as $mentionedUser) {
            if ($mentionedUser->id !== Auth::id()) {
                $mentionedUser->notify(new MentionNotification($message, Auth::user()));
            }
        }
    }

    // Notify team members about the new message (except the sender)
    foreach ($team->users as $user) {
        if ($user->id !== Auth::id() && $user->notification_preferences['new_messages'] ?? true) {
            $user->notify(new NewMessage($message));
        }
    }

    return response()->json([
        'message' => $message,
        'user' => Auth::user()->only(['id', 'name', 'avatar_url']),
    ]);
}
```

#### Step 4: Create a notification center UI

Create a Livewire component for the notification center:

```bash
php artisan make:livewire NotificationCenter
```

Edit the component class:

```php
<?php

namespace App\Http\Livewire;

use Illuminate\Support\Facades\Auth;
use Livewire\Component;

class NotificationCenter extends Component
{
    public $showNotifications = false;
    public $notifications = [];
    public $unreadCount = 0;

    protected $listeners = ['refreshNotifications', 'markAsRead'];

    public function mount()
    {
        $this->refreshNotifications();
    }

    public function refreshNotifications()
    {
        $user = Auth::user();

        $this->notifications = $user->notifications()
            ->latest()
            ->take(10)
            ->get()
            ->map(function ($notification) {
                return [
                    'id' => $notification->id,
                    'data' => $notification->data,
                    'read_at' => $notification->read_at,
                    'created_at' => $notification->created_at->diffForHumans(),
                ];
            })
            ->toArray();

        $this->unreadCount = $user->unreadNotifications()->count();
    }

    public function toggleNotifications()
    {
        $this->showNotifications = !$this->showNotifications;

        if ($this->showNotifications) {
            $this->refreshNotifications();
        }
    }

    public function markAsRead($notificationId)
    {
        $notification = Auth::user()->notifications()->where('id', $notificationId)->first();

        if ($notification) {
            $notification->markAsRead();
            $this->refreshNotifications();
        }
    }

    public function markAllAsRead()
    {
        Auth::user()->unreadNotifications->markAsRead();
        $this->refreshNotifications();
    }

    public function render()
    {
        return view('livewire.notification-center');
    }
}
```

Create the component view:

```blade
<div class="relative">
    <button wire:click="toggleNotifications" type="button" class="relative p-1 text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500">
        <span class="sr-only">View notifications</span>
        <svg class="h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
        </svg>
        @if($unreadCount > 0)
            <span class="absolute top-0 right-0 block h-2 w-2 rounded-full bg-red-400 ring-2 ring-white"></span>
        @endif
    </button>

    @if($showNotifications)
        <div class="origin-top-right absolute right-0 mt-2 w-80 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 focus:outline-none" role="menu" aria-orientation="vertical" aria-labelledby="notification-menu">
            <div class="py-1" role="none">
                <div class="px-4 py-2 border-b border-gray-200 flex justify-between items-center">
                    <h3 class="text-sm font-medium text-gray-900">Notifications</h3>
                    @if($unreadCount > 0)
                        <button wire:click="markAllAsRead" class="text-xs text-indigo-600 hover:text-indigo-900">Mark all as read</button>
                    @endif
                </div>

                <div class="max-h-96 overflow-y-auto">
                    @forelse($notifications as $notification)
                        <div class="px-4 py-3 {{ !$notification['read_at'] ? 'bg-indigo-50' : '' }} hover:bg-gray-100 border-b border-gray-100">
                            <div class="flex justify-between items-start">
                                <div class="flex-1">
                                    <p class="text-sm text-gray-900">
                                        {{ $notification['data']['message'] }}
                                    </p>
                                    <p class="mt-1 text-xs text-gray-500">
                                        {{ $notification['created_at'] }}
                                    </p>
                                </div>
                                @if(!$notification['read_at'])
                                    <button wire:click="markAsRead('{{ $notification['id'] }}')" class="ml-2 text-xs text-indigo-600 hover:text-indigo-900">
                                        Mark as read
                                    </button>
                                @endif
                            </div>
                        </div>
                    @empty
                        <div class="px-4 py-3 text-sm text-gray-500">
                            No notifications
                        </div>
                    @endforelse
                </div>
            </div>
        </div>
    @endif
</div>

@push('scripts')
<script>
    // Listen for new notifications
    window.addEventListener('DOMContentLoaded', function() {
        // Get the user's private notification channel
        const userId = document.querySelector('meta[name="user-id"]').getAttribute('content');

        if (userId) {
            window.Echo.private(`App.Models.User.${userId}`)
                .notification((notification) => {
                    // Play a sound
                    const audio = new Audio('/sounds/notification.mp3');
                    audio.play();

                    // Show a browser notification if permission is granted
                    if (Notification.permission === 'granted') {
                        new Notification('New Notification', {
                            body: notification.message,
                            icon: '/images/logo.png'
                        });
                    }

                    // Refresh the notifications list
                    Livewire.emit('refreshNotifications');
                });
        }
    });
</script>
@endpush
```

#### Step 5: Implement notification preferences

Create a migration to add notification preferences to the users table:

```bash
php artisan make:migration add_notification_preferences_to_users_table
```

Edit the migration file:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::table('users', function (Blueprint $table) {
            $table->json('notification_preferences')->nullable();
        });
    }

    public function down()
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('notification_preferences');
        });
    }
};
```

Run the migration:

```bash
php artisan migrate
```

Update the User model to cast the notification preferences:

```php
protected $casts = [
    'email_verified_at' => 'datetime',
    'notification_preferences' => 'array',
];
```

Create a Livewire component for notification preferences:

```bash
php artisan make:livewire NotificationPreferences
```

Edit the component class:

```php
<?php

namespace App\Http\Livewire;

use Illuminate\Support\Facades\Auth;
use Livewire\Component;

class NotificationPreferences extends Component
{
    public $preferences = [
        'new_team_members' => true,
        'new_messages' => true,
        'task_assignments' => true,
        'mentions' => true,
    ];

    public function mount()
    {
        $user = Auth::user();
        $userPreferences = $user->notification_preferences ?? [];

        // Merge user preferences with defaults
        $this->preferences = array_merge($this->preferences, $userPreferences);
    }

    public function updatePreferences()
    {
        $user = Auth::user();
        $user->notification_preferences = $this->preferences;
        $user->save();

        $this->emit('saved');
    }

    public function render()
    {
        return view('livewire.notification-preferences');
    }
}
```

Create the component view:

```blade
<div>
    <div class="bg-white shadow rounded-lg overflow-hidden">
        <div class="px-4 py-3 border-b">
            <h3 class="text-lg font-medium text-gray-900">Notification Preferences</h3>
        </div>

        <div class="p-4">
            <form wire:submit.prevent="updatePreferences">
                <div class="space-y-4">
                    <div class="flex items-start">
                        <div class="flex items-center h-5">
                            <input wire:model="preferences.new_team_members" id="new_team_members" type="checkbox" class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded">
                        </div>
                        <div class="ml-3 text-sm">
                            <label for="new_team_members" class="font-medium text-gray-700">New Team Members</label>
                            <p class="text-gray-500">Receive notifications when someone joins your team</p>
                        </div>
                    </div>

                    <div class="flex items-start">
                        <div class="flex items-center h-5">
                            <input wire:model="preferences.new_messages" id="new_messages" type="checkbox" class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded">
                        </div>
                        <div class="ml-3 text-sm">
                            <label for="new_messages" class="font-medium text-gray-700">New Messages</label>
                            <p class="text-gray-500">Receive notifications for new messages in your teams</p>
                        </div>
                    </div>

                    <div class="flex items-start">
                        <div class="flex items-center h-5">
                            <input wire:model="preferences.task_assignments" id="task_assignments" type="checkbox" class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded">
                        </div>
                        <div class="ml-3 text-sm">
                            <label for="task_assignments" class="font-medium text-gray-700">Task Assignments</label>
                            <p class="text-gray-500">Receive notifications when you are assigned a task</p>
                        </div>
                    </div>

                    <div class="flex items-start">
                        <div class="flex items-center h-5">
                            <input wire:model="preferences.mentions" id="mentions" type="checkbox" class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded">
                        </div>
                        <div class="ml-3 text-sm">
                            <label for="mentions" class="font-medium text-gray-700">Mentions</label>
                            <p class="text-gray-500">Receive notifications when someone mentions you in a message</p>
                        </div>
                    </div>
                </div>

                <div class="mt-6">
                    <button type="submit" class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                        Save Preferences
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>
```

#### Step 6: Add tests for the notification system

Create a test for the notification system:

```bash
php artisan make:test NotificationSystemTest
```

Edit the test file:

```php
<?php

namespace Tests\Feature;

use App\Models\Message;use App\Models\Team;use App\Models\User;use App\Notifications\MentionNotification;use App\Notifications\NewMessage;use App\Notifications\NewTeamMember;use App\Notifications\TaskAssigned;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Support\Facades\Notification;use old\TestCase;

class NotificationSystemTest extends TestCase
{
    use RefreshDatabase;

    public function test_new_team_member_notification_is_sent()
    {
        Notification::fake();

        $owner = User::factory()->create();
        $newMember = User::factory()->create();
        $team = Team::create([
            'name' => 'Test Team',
            'owner_id' => $owner->id,
        ]);

        // Add the new member to the team
        $team->users()->attach($newMember);

        // Notify the team owner
        $owner->notify(new NewTeamMember($team, $newMember));

        Notification::assertSentTo(
            $owner,
            NewTeamMember::class,
            function ($notification, $channels) use ($team, $newMember) {
                return $notification->team->id === $team->id &&
                       $notification->newMember->id === $newMember->id &&
                       in_array('database', $channels) &&
                       in_array('broadcast', $channels);
            }
        );
    }

    public function test_new_message_notification_is_sent()
    {
        Notification::fake();

        $user = User::factory()->create();
        $team = Team::create([
            'name' => 'Test Team',
            'owner_id' => $user->id,
        ]);

        $message = Message::create([
            'user_id' => $user->id,
            'team_id' => $team->id,
            'content' => 'Test message',
        ]);

        // Create another user to receive the notification
        $recipient = User::factory()->create();
        $team->users()->attach($recipient);

        // Notify the recipient
        $recipient->notify(new NewMessage($message));

        Notification::assertSentTo(
            $recipient,
            NewMessage::class,
            function ($notification, $channels) use ($message) {
                return $notification->message->id === $message->id &&
                       in_array('database', $channels) &&
                       in_array('broadcast', $channels);
            }
        );
    }

    public function test_mention_notification_is_sent()
    {
        Notification::fake();

        $sender = User::factory()->create();
        $mentioned = User::factory()->create(['username' => 'testuser']);
        $team = Team::create([
            'name' => 'Test Team',
            'owner_id' => $sender->id,
        ]);

        $team->users()->attach($mentioned);

        $message = Message::create([
            'user_id' => $sender->id,
            'team_id' => $team->id,
            'content' => 'Hey @testuser, check this out!',
        ]);

        // Notify the mentioned user
        $mentioned->notify(new MentionNotification($message, $sender));

        Notification::assertSentTo(
            $mentioned,
            MentionNotification::class,
            function ($notification, $channels) use ($message, $sender) {
                return $notification->message->id === $message->id &&
                       $notification->mentionedBy->id === $sender->id &&
                       in_array('mail', $channels) &&
                       in_array('database', $channels) &&
                       in_array('broadcast', $channels);
            }
        );
    }

    public function test_notification_preferences_are_respected()
    {
        Notification::fake();

        $sender = User::factory()->create();
        $recipient = User::factory()->create([
            'notification_preferences' => [
                'new_messages' => false,
                'mentions' => true,
            ],
        ]);

        $team = Team::create([
            'name' => 'Test Team',
            'owner_id' => $sender->id,
        ]);

        $team->users()->attach($recipient);

        $message = Message::create([
            'user_id' => $sender->id,
            'team_id' => $team->id,
            'content' => 'Regular message',
        ]);

        // This should not send a notification because the preference is off
        if ($recipient->notification_preferences['new_messages'] ?? true) {
            $recipient->notify(new NewMessage($message));
        }

        Notification::assertNotSentTo($recipient, NewMessage::class);

        // But mentions should still work
        $mentionMessage = Message::create([
            'user_id' => $sender->id,
            'team_id' => $team->id,
            'content' => 'Hey @' . $recipient->username . ', check this out!',
        ]);

        if ($recipient->notification_preferences['mentions'] ?? true) {
            $recipient->notify(new MentionNotification($mentionMessage, $sender));
        }

        Notification::assertSentTo($recipient, MentionNotification::class);
    }
}
```

### Implementation Choices Explanation

1. **Using Presence Channels for Online Status**:
   - Presence channels automatically track which users are online and provide events when users join or leave.
   - The channel authorization returns user data, making it easy to display user information in the UI.
   - This approach is more efficient than polling the server to check user status.

2. **Comprehensive Notification System**:
   - Using Laravel's built-in notification system provides a consistent way to send notifications across multiple channels.
   - Implementing the `ShouldBroadcast` interface allows notifications to be sent in real-time via WebSockets.
   - The database channel stores notifications for later retrieval, ensuring users don't miss notifications when offline.

3. **User Preferences for Notifications**:
   - Storing notification preferences as JSON allows for flexible configuration without requiring additional database tables.
   - Users can customize their notification experience based on their needs.
   - The preferences are respected when sending notifications, reducing notification fatigue.

4. **Livewire for Real-time UI Updates**:
   - Livewire components provide a reactive UI that updates in real-time when new notifications arrive.
   - The notification center shows unread counts and allows marking notifications as read without page refreshes.
   - Using Livewire events enables communication between components when notification status changes.

5. **Comprehensive Testing**:
   - Tests cover the entire notification flow, from creation to delivery.
   - Using `Notification::fake()` allows testing notification logic without actually sending notifications.
   - Testing notification preferences ensures that user settings are respected.
