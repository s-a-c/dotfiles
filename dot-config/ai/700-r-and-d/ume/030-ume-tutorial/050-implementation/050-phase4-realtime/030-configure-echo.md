# Configuring Laravel Echo

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Set up Laravel Echo in our frontend to connect to the Reverb WebSocket server and handle real-time events.

## Prerequisites

- Laravel Reverb installed and configured (from the previous section)
- Node.js and npm installed
- Basic understanding of JavaScript and WebSockets

## Implementation

### Step 1: Install Laravel Echo and the Pusher JS Client

Laravel Echo requires the Pusher JS client to connect to Reverb (Reverb implements the Pusher protocol):

```bash
npm install --save 100-laravel-echo pusher-js
```

### Step 2: Configure Laravel Echo in Your JavaScript

Update your `resources/js/bootstrap.js` file to configure Laravel Echo:

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

### Step 3: Update Your Vite Configuration

Ensure your `vite.config.js` file is configured to expose the environment variables:

```javascript
import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';

export default defineConfig({
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js'],
            refresh: true,
        }),
    ],
    define: {
        'import.meta.env.VITE_REVERB_APP_KEY': JSON.stringify(process.env.VITE_REVERB_APP_KEY),
        'import.meta.env.VITE_REVERB_HOST': JSON.stringify(process.env.VITE_REVERB_HOST),
        'import.meta.env.VITE_REVERB_PORT': JSON.stringify(process.env.VITE_REVERB_PORT),
        'import.meta.env.VITE_REVERB_SCHEME': JSON.stringify(process.env.VITE_REVERB_SCHEME),
    },
});
```

### Step 4: Create a Basic Echo Test

Let's create a simple test to verify that Echo is connecting to Reverb. Add this to your main JavaScript file (e.g., `resources/js/app.js`):

```javascript
// Import our bootstrap file which sets up Echo
import './bootstrap';

// Simple Echo connection test
document.addEventListener('DOMContentLoaded', () => {
    if (window.Echo) {
        console.log('Echo initialized, attempting to connect to Reverb...');
        
        // Listen for connection events
        window.Echo.connector.pusher.connection.bind('connected', () => {
            console.log('Successfully connected to Reverb!');
        });
        
        window.Echo.connector.pusher.connection.bind('error', (error) => {
            console.error('Failed to connect to Reverb:', error);
        });
    } else {
        console.error('Echo not initialized');
    }
});
```

### Step 5: Build Your Assets

Build your assets to include the Echo configuration:

```bash
npm run build
```

### Step 6: Create a Simple Test Event

Let's create a simple event to test our Echo setup:

```bash
php artisan make:event TestEvent
```

Edit the generated file at `app/Events/TestEvent.php`:

```php
<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class TestEvent implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $message;

    /**
     * Create a new event instance.
     */
    public function __construct(string $message)
    {
        $this->message = $message;
    }

    /**
     * Get the channels the event should broadcast on.
     *
     * @return array<int, \Illuminate\Broadcasting\Channel>
     */
    public function broadcastOn(): array
    {
        return [
            new Channel('test-channel'),
        ];
    }
}
```

### Step 7: Create a Test Route to Trigger the Event

Add a test route in `routes/web.php`:

```php
use App\Events\TestEvent;
use Illuminate\Support\Facades\Route;

// Test route for broadcasting
Route::get('/broadcast-test', function () {
    broadcast(new TestEvent('This is a test message from Reverb!'));
    return 'Event broadcasted! Check your browser console.';
})->middleware(['auth']);
```

### Step 8: Listen for the Test Event in JavaScript

Update your JavaScript to listen for the test event:

```javascript
// In resources/js/app.js

// Listen for the test event
window.Echo.channel('test-channel')
    .listen('TestEvent', (e) => {
        console.log('Received test event:', e);
        alert('Received message: ' + e.message);
    });
```

### Step 9: Test the Connection

1. Start the Reverb server if it's not already running:

```bash
php artisan reverb:start
```

2. Open your application in a browser
3. Log in (since our test route requires authentication)
4. Open the browser console
5. Visit the test route: `/broadcast-test`
6. Check the console for connection messages and the received event

## Using Echo with Different Channel Types

Now that we have Echo configured, let's look at how to use it with different channel types:

### Public Channels

Public channels are accessible to anyone without authentication:

```javascript
// Subscribe to a public channel
Echo.channel('public-announcements')
    .listen('AnnouncementCreated', (e) => {
        console.log('New announcement:', e.announcement);
    });
```

### Private Channels

Private channels require authentication:

```javascript
// Subscribe to a private channel
Echo.private(`user.${userId}`)
    .listen('PrivateNotification', (e) => {
        console.log('Private notification:', e.notification);
    });
```

### Presence Channels

Presence channels track who is subscribed:

```javascript
// Subscribe to a presence channel
Echo.join(`presence-team.${teamId}`)
    .here((users) => {
        console.log('Users currently online:', users);
    })
    .joining((user) => {
        console.log('User joined:', user);
    })
    .leaving((user) => {
        console.log('User left:', user);
    })
    .listen('TeamMessage', (e) => {
        console.log('New team message:', e.message);
    });
```

## Understanding Echo's API

Laravel Echo provides several methods for working with channels:

### Channel Subscription

- `Echo.channel(name)`: Subscribe to a public channel
- `Echo.private(name)`: Subscribe to a private channel
- `Echo.join(name)`: Subscribe to a presence channel

### Event Listening

- `.listen(event, callback)`: Listen for a specific event
- `.listenForWhisper(event, callback)`: Listen for client events (whispers)

### Presence Channel Methods

- `.here(callback)`: Called with the current users when joining
- `.joining(callback)`: Called when a user joins
- `.leaving(callback)`: Called when a user leaves

### Client Events (Whispers)

Echo allows clients to send events directly to other clients (without going through the server) using whispers:

```javascript
// Send a whisper
Echo.private(`chat.${roomId}`)
    .whisper('typing', {
        user: currentUser
    });

// Listen for whispers
Echo.private(`chat.${roomId}`)
    .listenForWhisper('typing', (e) => {
        console.log(`${e.user.name} is typing...`);
    });
```

## Verification

To verify that Echo is configured correctly:

1. Check the browser console for connection messages
2. Trigger the test event and confirm it's received
3. Try subscribing to different channel types

## Troubleshooting

### Common Issues

1. **CORS Errors**: If you see CORS errors in the console, check your Reverb CORS configuration
2. **401 Unauthorized**: Make sure your authentication is set up correctly for private/presence channels
3. **Connection Failed**: Verify that Reverb is running and accessible

### Debugging Tips

1. Enable debug mode in Echo:

```javascript
window.Echo = new Echo({
    // ... other options
    debug: true,
});
```

2. Check the Network tab in your browser's developer tools for WebSocket connections
3. Verify that the CSRF token is being sent correctly for authentication

## Next Steps

Now that we have Echo configured, we can implement the presence status backend to track user online status.

[Implement Presence Status Backend →](./040-presence-backend.md)
