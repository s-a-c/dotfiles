# Real-time Features Quick Reference

<link rel="stylesheet" href="../../css/styles.css">
<link rel="stylesheet" href="../../css/ume-docs-enhancements.css">
<script src="../../js/ume-docs-enhancements.js"></script>

## Overview

Real-time features in the UME system enable live updates and interactive experiences for users. This quick reference guide covers the essential concepts and implementation details for working with WebSockets, event broadcasting, and real-time features.

## Key Concepts

| Concept | Description |
|---------|-------------|
| **WebSocket** | A communication protocol that provides full-duplex communication over a single TCP connection |
| **Event Broadcasting** | The process of sending events to connected clients in real-time |
| **Channel** | A named route for delivering messages to specific clients |
| **Presence Channel** | A channel that tracks which users are currently connected |
| **Private Channel** | A secure channel that requires authentication |
| **Echo** | Laravel's JavaScript library for WebSocket interactions |
| **Reverb** | Laravel's WebSocket server |

## Implementation with Laravel Reverb and Echo

The UME system uses Laravel Reverb for the WebSocket server and Laravel Echo for the client-side WebSocket interactions.

### Server-Side Setup

```php
// 1. Install Laravel Reverb
// composer require laravel/reverb

// 2. Configure broadcasting in config/broadcasting.php
'reverb' => [
    'driver' => 'reverb',
    'app_id' => env('REVERB_APP_ID'),
    'app_key' => env('REVERB_APP_KEY'),
    'app_secret' => env('REVERB_APP_SECRET'),
    'options' => [
        'host' => env('REVERB_HOST', '127.0.0.1'),
        'port' => env('REVERB_PORT', 8080),
        'scheme' => env('REVERB_SCHEME', 'http'),
    ],
],

// 3. Set up event broadcasting in .env
BROADCAST_DRIVER=reverb
REVERB_APP_ID=your-app-id
REVERB_APP_KEY=your-app-key
REVERB_APP_SECRET=your-app-secret
REVERB_HOST=127.0.0.1
REVERB_PORT=8080
REVERB_SCHEME=http
```

### Client-Side Setup

```javascript
// 1. Install Laravel Echo and Socket.IO client
// npm install 100-laravel-echo socket.io-client

// 2. Configure Echo in resources/js/bootstrap.js
import Echo from '100-laravel-echo';
import io from 'socket.io-client';

window.io = io;
window.Echo = new Echo({
    broadcaster: 'socket.io',
    host: window.location.hostname + ':8080',
    key: 'your-app-key',
});
```

## Broadcasting Events

```php
// 1. Create a broadcastable event
class NewMessage implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $message;

    public function __construct($message)
    {
        $this->message = $message;
    }

    public function broadcastOn()
    {
        return new PrivateChannel('chat.' . $this->message->chat_id);
    }
}

// 2. Dispatch the event
event(new NewMessage($message));

// 3. Listen for the event in JavaScript
Echo.private('chat.' + chatId)
    .listen('NewMessage', (e) => {
        console.log(e.message);
        // Update UI with new message
    });
```

## Common Real-time Patterns

### User Presence

```php
// 1. Create a presence channel in routes/channels.php
Broadcast::channel('team.{teamId}', function ($user, $teamId) {
    if ($user->belongsToTeam($teamId)) {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'avatar' => $user->avatar_url,
        ];
    }
});

// 2. Join the presence channel in JavaScript
const channel = Echo.040-real-time-features.mdjoin('team.' + teamId)
    .here((users) => {
        // Initial list of users in the channel
        console.log(users);
    })
    .joining((user) => {
        // User joined the channel
        console.log(user.name + ' joined');
    })
    .leaving((user) => {
        // User left the channel
        console.log(user.name + ' left');
    });
```

### Activity Logging

```php
// 1. Create an activity event
class UserActivity implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $user;
    public $action;
    public $timestamp;

    public function __construct($user, $action)
    {
        $this->user = $user;
        $this->action = $action;
        $this->timestamp = now();
    }

    public function broadcastOn()
    {
        return new PrivateChannel('activity');
    }
}

// 2. Log and broadcast activity
event(new UserActivity($user, 'created a new post'));

// 3. Listen for activity events
Echo.private('activity')
    .listen('UserActivity', (e) => {
        // Add activity to feed
        activityFeed.push({
            user: e.user,
            action: e.action,
            timestamp: e.timestamp
        });
    });
```

### Real-time Notifications

```php
// 1. Create a notification
class NewCommentNotification extends Notification implements ShouldBroadcast
{
    use Queueable;

    public $comment;

    public function __construct($comment)
    {
        $this->comment = $comment;
    }

    public function via($notifiable)
    {
        return ['database', 'broadcast'];
    }

    public function toBroadcast($notifiable)
    {
        return new BroadcastMessage([
            'id' => $this->id,
            'comment' => $this->comment,
            'user' => $this->comment->user,
            'post' => $this->comment->post,
            'time' => now()->toIso8601String(),
        ]);
    }
}

// 2. Send the notification
$user->notify(new NewCommentNotification($comment));

// 3. Listen for notifications
Echo.private('App.Models.User.' + userId)
    .notification((notification) => {
        // Display notification
        showNotification(notification);
    });
```

## Best Practices

1. **Use Private Channels for Sensitive Data**: Ensure that sensitive data is only broadcast on authenticated channels
2. **Implement Proper Authorization**: Verify that users are authorized to join channels
3. **Optimize Payload Size**: Keep broadcast payloads small to reduce bandwidth usage
4. **Handle Connection Failures**: Implement reconnection logic for WebSocket connections
5. **Use Queued Broadcasting**: Queue broadcast events to improve performance
6. **Implement Fallbacks**: Provide fallbacks for users who can't establish WebSocket connections
7. **Monitor WebSocket Server**: Set up monitoring for your WebSocket server

## Common Pitfalls

1. **Broadcasting Too Much Data**: Sending large payloads that slow down the application
2. **Missing Authentication**: Not properly securing channels that contain sensitive data
3. **Overusing Presence Channels**: Using presence channels when private channels would suffice
4. **Not Handling Disconnections**: Failing to handle WebSocket disconnections gracefully
5. **Ignoring Scale Considerations**: Not planning for scaling WebSocket connections

## Code Examples

### Typing Indicators

```php
// 1. Create a typing event
class UserTyping implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $user;
    public $chatId;
    public $isTyping;

    public function __construct($user, $chatId, $isTyping)
    {
        $this->user = $user;
        $this->chatId = $chatId;
        $this->isTyping = $isTyping;
    }

    public function broadcastOn()
    {
        return new PrivateChannel('chat.' . $this->chatId);
    }
}

// 2. Broadcast typing status
event(new UserTyping($user, $chatId, true));

// 3. Listen for typing events
Echo.private('chat.' + chatId)
    .listen('UserTyping', (e) => {
        if (e.isTyping) {
            showTypingIndicator(e.user);
        } else {
            hideTypingIndicator(e.user);
        }
    });

// 4. Implement debouncing on the client side
let typingTimer;
const doneTypingInterval = 1000;

$('#message-input').on('keydown', function() {
    if (!isTyping) {
        isTyping = true;
        axios.post('/chat/typing', {
            chat_id: chatId,
            is_typing: true
        });
    }
    
    clearTimeout(typingTimer);
    
    typingTimer = setTimeout(function() {
        isTyping = false;
        axios.post('/chat/typing', {
            chat_id: chatId,
            is_typing: false
        });
    }, doneTypingInterval);
});
```

### Real-time Collaboration

```php
// 1. Create a document update event
class DocumentUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $documentId;
    public $content;
    public $user;
    public $version;

    public function __construct($documentId, $content, $user, $version)
    {
        $this->documentId = $documentId;
        $this->content = $content;
        $this->user = $user;
        $this->version = $version;
    }

    public function broadcastOn()
    {
        return new PrivateChannel('document.' . $this->documentId);
    }
}

// 2. Broadcast document updates
event(new DocumentUpdated($documentId, $content, $user, $version));

// 3. Listen for document updates
Echo.private('document.' + documentId)
    .listen('DocumentUpdated', (e) => {
        // Only update if the received version is newer
        if (e.version > currentVersion) {
            updateDocument(e.content, e.version);
            showUserActivity(e.user, 'updated the document');
        }
    });
```

## Related Resources

- [WebSockets Overview](../../../050-implementation/050-phase4-realtime/010-websockets-overview.md)
- [Laravel Reverb Setup](../../../050-implementation/050-phase4-realtime/020-reverb-setup.md)
- [Event Broadcasting](../../../050-implementation/050-phase4-realtime/030-event-broadcasting.md)
- [User Presence](../../../050-implementation/050-phase4-realtime/040-user-presence.md)
- [Activity Logging](../../../050-implementation/050-phase4-realtime/050-activity-logging.md)
- [Laravel Broadcasting Documentation](https://laravel.com/docs/broadcasting)
- [Laravel Reverb Documentation](https://laravel.com/docs/reverb)
