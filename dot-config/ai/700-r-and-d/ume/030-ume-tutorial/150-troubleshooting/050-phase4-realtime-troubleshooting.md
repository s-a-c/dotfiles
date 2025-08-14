# Phase 4: Real-time Features Troubleshooting

<link rel="stylesheet" href="../assets/css/styles.css">
<link rel="stylesheet" href="../assets/css/ume-docs-enhancements.css">
<script src="../assets/js/ume-docs-enhancements.js"></script>

This guide addresses common issues you might encounter during Phase 4 (Real-time Features) of the UME tutorial implementation.

## WebSocket Server Issues

<div class="troubleshooting-guide">
    <h2>Laravel Reverb Setup Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>WebSocket server fails to start</li>
            <li>Connection errors when trying to connect to WebSocket server</li>
            <li>WebSocket events not being received by clients</li>
            <li>Error messages in Reverb logs</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Reverb not properly installed or configured</li>
            <li>Port conflicts with other services</li>
            <li>Missing or incorrect SSL configuration</li>
            <li>Firewall blocking WebSocket connections</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Improper Installation</h4>
        <p>Ensure Reverb is properly installed and configured:</p>
        <pre><code>composer require laravel/reverb
php artisan reverb:install</code></pre>
        <p>Check your .env file for the correct configuration:</p>
        <pre><code>REVERB_APP_ID=your-app-id
REVERB_APP_KEY=your-app-key
REVERB_APP_SECRET=your-app-secret
REVERB_HOST=127.0.0.1
REVERB_PORT=8080
REVERB_SCHEME=http</code></pre>
        
        <h4>For Port Conflicts</h4>
        <p>Check if the port is already in use and change it if necessary:</p>
        <pre><code># Check if port 8080 is in use
sudo lsof -i :8080

# Change the port in .env
REVERB_PORT=8081</code></pre>
        
        <h4>For SSL Configuration</h4>
        <p>If using SSL, ensure your configuration is correct:</p>
        <pre><code>REVERB_SCHEME=https
REVERB_SSL_CERT=/path/to/cert.pem
REVERB_SSL_KEY=/path/to/key.pem</code></pre>
        
        <h4>For Firewall Issues</h4>
        <p>Ensure your firewall allows WebSocket connections:</p>
        <pre><code># For UFW (Ubuntu)
sudo ufw allow 8080/tcp

# For iptables
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Follow the Reverb installation instructions carefully</li>
            <li>Use a dedicated port for Reverb that doesn't conflict with other services</li>
            <li>Test WebSocket connections in a development environment before deploying</li>
            <li>Monitor Reverb logs for errors and warnings</li>
        </ul>
    </div>
</div>

## Laravel Echo Configuration Issues

<div class="troubleshooting-guide">
    <h2>Echo Client Configuration Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>JavaScript console errors related to Echo</li>
            <li>WebSocket connection attempts failing</li>
            <li>Events not being received by the client</li>
            <li>Authentication errors for private or presence channels</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Echo not properly installed or configured</li>
            <li>Missing or incorrect Echo client configuration</li>
            <li>CSRF token issues</li>
            <li>Authentication issues for private or presence channels</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Improper Installation</h4>
        <p>Ensure Echo is properly installed:</p>
        <pre><code>npm install --save laravel-echo</code></pre>
        
        <h4>For Incorrect Configuration</h4>
        <p>Check your Echo configuration in resources/js/bootstrap.js:</p>
        <pre><code>import Echo from 'laravel-echo';

window.Echo = new Echo({
    broadcaster: 'reverb',
    key: import.meta.env.VITE_REVERB_APP_KEY,
    wsHost: import.meta.env.VITE_REVERB_HOST || window.location.hostname,
    wsPort: import.meta.env.VITE_REVERB_PORT || 8080,
    wssPort: import.meta.env.VITE_REVERB_PORT || 8080,
    forceTLS: (import.meta.env.VITE_REVERB_SCHEME || 'http') === 'https',
    enabledTransports: ['ws', 'wss'],
});</code></pre>
        <p>Ensure your .env file has the corresponding variables:</p>
        <pre><code>VITE_REVERB_APP_KEY="${REVERB_APP_KEY}"
VITE_REVERB_HOST="${REVERB_HOST}"
VITE_REVERB_PORT="${REVERB_PORT}"
VITE_REVERB_SCHEME="${REVERB_SCHEME}"</code></pre>
        
        <h4>For CSRF Token Issues</h4>
        <p>Ensure the CSRF token is properly set:</p>
        <pre><code>// In your layout file
&lt;meta name="csrf-token" content="{{ csrf_token() }}"&gt;

// In your JavaScript
window.axios.defaults.headers.common['X-CSRF-TOKEN'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content');</code></pre>
        
        <h4>For Authentication Issues</h4>
        <p>Check your channel authentication route and middleware:</p>
        <pre><code>// In routes/channels.php
Broadcast::channel('presence.users', function ($user) {
    return $user ? ['id' => $user->id, 'name' => $user->name] : false;
});

// In config/broadcasting.php
'options' => [
    'middleware' => ['web', 'auth'],
],</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Follow the Echo installation and configuration instructions carefully</li>
            <li>Test WebSocket connections in a development environment</li>
            <li>Use browser developer tools to debug WebSocket connections</li>
            <li>Check for JavaScript errors in the console</li>
        </ul>
    </div>
</div>

## Presence Status Issues

<div class="troubleshooting-guide">
    <h2>User Presence Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>User presence status not updating</li>
            <li>Presence events not being broadcast</li>
            <li>Incorrect presence status displayed</li>
            <li>Presence status not persisting in the database</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Missing or incorrect presence status enum</li>
            <li>Presence events not being dispatched</li>
            <li>Presence channel authentication issues</li>
            <li>Missing or incorrect database column for presence status</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Presence Status Enum Issues</h4>
        <p>Ensure your presence status enum is correctly defined:</p>
        <pre><code>enum PresenceStatus: string
{
    case Online = 'online';
    case Away = 'away';
    case Busy = 'busy';
    case Offline = 'offline';
}</code></pre>
        
        <h4>For Presence Events Issues</h4>
        <p>Ensure presence events are being dispatched correctly:</p>
        <pre><code>// In your controller or service
public function updatePresence(User $user, PresenceStatus $status): void
{
    $oldStatus = $user->presence_status;
    $user->presence_status = $status;
    $user->save();
    
    event(new PresenceChanged($user, $oldStatus, $status));
}</code></pre>
        <p>Check your event class:</p>
        <pre><code>class PresenceChanged implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;
    
    public function __construct(
        public User $user,
        public ?PresenceStatus $oldStatus,
        public PresenceStatus $newStatus
    ) {}
    
    public function broadcastOn(): array
    {
        return [
            new PresenceChannel('presence.users'),
        ];
    }
    
    public function broadcastAs(): string
    {
        return 'presence.changed';
    }
    
    public function broadcastWith(): array
    {
        return [
            'user_id' => $this->user->id,
            'old_status' => $this->oldStatus?->value,
            'new_status' => $this->newStatus->value,
        ];
    }
}</code></pre>
        
        <h4>For Presence Channel Authentication</h4>
        <p>Check your channel authentication:</p>
        <pre><code>// In routes/channels.php
Broadcast::channel('presence.users', function ($user) {
    return $user ? [
        'id' => $user->id,
        'name' => $user->name,
        'presence_status' => $user->presence_status->value,
    ] : false;
});</code></pre>
        
        <h4>For Database Column Issues</h4>
        <p>Ensure your users table has a presence_status column:</p>
        <pre><code>Schema::table('users', function (Blueprint $table) {
    $table->string('presence_status')->default('offline');
});</code></pre>
        <p>And that it's properly cast in your User model:</p>
        <pre><code>protected $casts = [
    'email_verified_at' => 'datetime',
    'password' => 'hashed',
    'presence_status' => PresenceStatus::class,
];</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Use enums for presence status to ensure valid values</li>
            <li>Dispatch events when presence status changes</li>
            <li>Test presence channels in a development environment</li>
            <li>Use proper casts for presence status in your model</li>
        </ul>
    </div>
</div>

## Broadcast Event Issues

<div class="troubleshooting-guide">
    <h2>Event Broadcasting Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Events not being broadcast</li>
            <li>Events not being received by clients</li>
            <li>Broadcasting queue jobs failing</li>
            <li>Missing or incorrect event data</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Broadcasting not enabled in config</li>
            <li>Missing ShouldBroadcast interface</li>
            <li>Incorrect channel configuration</li>
            <li>Queue worker not running</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Broadcasting Configuration</h4>
        <p>Ensure broadcasting is enabled in your .env file:</p>
        <pre><code>BROADCAST_DRIVER=reverb</code></pre>
        <p>And in your config/broadcasting.php file:</p>
        <pre><code>'default' => env('BROADCAST_DRIVER', 'null'),

'connections' => [
    'reverb' => [
        'driver' => 'reverb',
        'app_id' => env('REVERB_APP_ID'),
        'app_key' => env('REVERB_APP_KEY'),
        'app_secret' => env('REVERB_APP_SECRET'),
        'host' => env('REVERB_HOST', '127.0.0.1'),
        'port' => env('REVERB_PORT', 8080),
        'scheme' => env('REVERB_SCHEME', 'http'),
        'options' => [
            'cluster' => env('REVERB_CLUSTER', 'mt1'),
            'encrypted' => true,
            'host' => env('REVERB_HOST', '127.0.0.1'),
            'port' => env('REVERB_PORT', 8080),
            'scheme' => env('REVERB_SCHEME', 'http'),
        ],
    ],
],</code></pre>
        
        <h4>For ShouldBroadcast Interface</h4>
        <p>Ensure your event implements the ShouldBroadcast interface:</p>
        <pre><code>use Illuminate\Contracts\Broadcasting\ShouldBroadcast;

class PresenceChanged implements ShouldBroadcast
{
    // Event implementation
}</code></pre>
        
        <h4>For Channel Configuration</h4>
        <p>Check your broadcastOn method:</p>
        <pre><code>public function broadcastOn(): array
{
    return [
        new PresenceChannel('presence.users'),
    ];
}</code></pre>
        <p>And your channel authentication in routes/channels.php:</p>
        <pre><code>Broadcast::channel('presence.users', function ($user) {
    return $user ? [
        'id' => $user->id,
        'name' => $user->name,
    ] : false;
});</code></pre>
        
        <h4>For Queue Worker</h4>
        <p>If you're using queues for broadcasting, ensure the queue worker is running:</p>
        <pre><code>php artisan queue:work</code></pre>
        <p>Or use the sync driver for testing:</p>
        <pre><code>QUEUE_CONNECTION=sync</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Implement the ShouldBroadcast interface for all broadcast events</li>
            <li>Test broadcasting in a development environment</li>
            <li>Use the sync queue driver during development for easier debugging</li>
            <li>Monitor queue workers in production</li>
        </ul>
    </div>
</div>

## Activity Logging Issues

<div class="troubleshooting-guide">
    <h2>Activity Logging Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Activities not being logged</li>
            <li>Missing or incorrect activity data</li>
            <li>Activity logs not being displayed</li>
            <li>Performance issues with activity logging</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Missing or incorrect activity model configuration</li>
            <li>Events not being dispatched</li>
            <li>Listeners not registered</li>
            <li>Database issues with activity log table</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Activity Model Configuration</h4>
        <p>Ensure your model is configured for activity logging:</p>
        <pre><code>use Spatie\Activitylog\Traits\LogsActivity;
use Spatie\Activitylog\LogOptions;

class User extends Authenticatable
{
    use LogsActivity;
    
    public function getActivitylogOptions(): LogOptions
    {
        return LogOptions::defaults()
            ->logOnly(['name', 'email', 'type', 'presence_status'])
            ->logOnlyDirty()
            ->dontSubmitEmptyLogs();
    }
}</code></pre>
        
        <h4>For Event Dispatching</h4>
        <p>If you're using custom events for activity logging, ensure they're being dispatched:</p>
        <pre><code>event(new UserActivity($user, 'logged_in'));</code></pre>
        
        <h4>For Listener Registration</h4>
        <p>Ensure your listeners are registered in the EventServiceProvider:</p>
        <pre><code>protected $listen = [
    \Illuminate\Auth\Events\Login::class => [
        \App\Listeners\LogUserLogin::class,
    ],
    \Illuminate\Auth\Events\Logout::class => [
        \App\Listeners\LogUserLogout::class,
    ],
];</code></pre>
        
        <h4>For Database Issues</h4>
        <p>Ensure the activity_log table exists and has the correct structure:</p>
        <pre><code>php artisan vendor:publish --provider="Spatie\Activitylog\ActivitylogServiceProvider" --tag="migrations"
php artisan migrate</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Use the LogsActivity trait for automatic activity logging</li>
            <li>Create listeners for authentication events</li>
            <li>Test activity logging in a development environment</li>
            <li>Monitor the size of your activity log table</li>
        </ul>
    </div>
</div>

## Common Pitfalls in Phase 4

<div class="common-pitfalls">
    <h3>Common Pitfalls to Avoid</h3>
    <ul>
        <li><strong>Not starting the WebSocket server:</strong> The WebSocket server needs to be running for real-time features to work. Use Laravel Reverb and ensure it's properly configured.</li>
        <li><strong>Forgetting to configure Echo:</strong> Laravel Echo needs to be properly configured on the client side to connect to the WebSocket server.</li>
        <li><strong>Not authenticating channels:</strong> Private and presence channels require authentication. Ensure your channel routes are properly defined.</li>
        <li><strong>Using the wrong broadcast driver:</strong> Make sure you're using the correct broadcast driver in your .env file (reverb for Laravel Reverb).</li>
        <li><strong>Not implementing ShouldBroadcast:</strong> Events that should be broadcast need to implement the ShouldBroadcast interface.</li>
        <li><strong>Forgetting to run queue workers:</strong> If you're using queues for broadcasting, ensure the queue workers are running.</li>
        <li><strong>Not handling reconnection:</strong> WebSocket connections can drop. Ensure your client code handles reconnection gracefully.</li>
        <li><strong>Overloading the WebSocket server:</strong> Broadcasting too many events can overload the WebSocket server. Consider throttling or batching events.</li>
    </ul>
</div>

## Debugging Techniques for Phase 4

### Debugging WebSocket Connections

Use browser developer tools to debug WebSocket connections:

1. Open the Network tab in your browser's developer tools
2. Filter for WebSocket connections (WS)
3. Examine the connection details and messages

### Monitoring Reverb

Monitor the Reverb WebSocket server:

```bash
# View Reverb logs
tail -f storage/logs/reverb.log

# Check if Reverb is running
ps aux | grep reverb
```

### Testing Broadcast Events

Test broadcast events with the Event Browser in Laravel Telescope:

```bash
# Install Laravel Telescope
composer require 100-laravel/telescope --dev
php artisan telescope:install
php artisan migrate

# Access Telescope at /telescope/events
```

### Debugging Activity Logging

Check the activity log table for logged activities:

```php
// In Tinker
\Spatie\Activitylog\Models\Activity::all();

// Filter by subject
\Spatie\Activitylog\Models\Activity::where('subject_type', User::class)->get();
```

### Testing Presence Channels

Test presence channels with a simple JavaScript snippet:

```javascript
// Join a presence channel
const channel = Echo.join('presence.users');

// Listen for join events
channel.here((users) => {
    console.log('Users currently online:', users);
});

channel.joining((user) => {
    console.log('User joined:', user);
});

channel.leaving((user) => {
    console.log('User left:', user);
});

// Listen for custom events
channel.listen('presence.changed', (e) => {
    console.log('User presence changed:', e);
});
```

<div class="page-navigation">
    <a href="./040-phase3-teams-permissions-troubleshooting.md" class="prev">Phase 3 Troubleshooting</a>
    <a href="./060-phase5-advanced-troubleshooting.md" class="next">Phase 5 Troubleshooting</a>
</div>
