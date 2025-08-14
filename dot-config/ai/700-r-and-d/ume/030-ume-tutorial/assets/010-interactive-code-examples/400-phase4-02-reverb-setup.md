# Reverb Setup

:::interactive-code
title: Setting Up Laravel Reverb for WebSockets
description: This example demonstrates how to set up and configure Laravel Reverb for WebSocket communication in a Laravel application.
language: php
editable: true
code: |
  <?php
  
  namespace App\Providers;
  
  use Illuminate\Support\Facades\Broadcast;
  use Illuminate\Support\ServiceProvider;
  
  class BroadcastServiceProvider extends ServiceProvider
  {
      /**
       * Bootstrap any application services.
       */
      public function boot(): void
      {
          // Register the routes for channel authorization
          Broadcast::routes(['middleware' => ['web', 'auth']]);
          
          // Include the channels file to register all broadcast channels
          require base_path('routes/channels.php');
      }
  }
  
  // Example routes/channels.php file
  
  use App\Models\Team;
  use App\Models\User;
  use Illuminate\Support\Facades\Broadcast;
  
  // Public channel - no authentication required
  Broadcast::channel('announcements', function () {
      return true;
  });
  
  // Private user channel - only the authenticated user can subscribe
  Broadcast::channel('App.Models.User.{id}', function (User $user, int $id) {
      return $user->id === $id;
  });
  
  // Private team channel - only team members can subscribe
  Broadcast::channel('team.{teamId}', function (User $user, int $teamId) {
      return $user->teams->contains(function (Team $team) use ($teamId) {
          return $team->id === $teamId;
      });
  });
  
  // Presence channel - returns user data for all subscribers
  Broadcast::channel('team.{teamId}.presence', function (User $user, int $teamId) {
      $team = Team::find($teamId);
      
      if ($team && $team->members->contains('id', $user->id)) {
          return [
              'id' => $user->id,
              'name' => $user->name,
              'avatar' => $user->profile->getAvatarUrl(),
              'role' => $team->getMemberRole($user),
          ];
      }
      
      return false;
  });
  
  // Example broadcasting event
  
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
      
      /**
       * The message instance.
       */
      public $message;
      
      /**
       * Create a new event instance.
       */
      public function __construct(public Message $message)
      {
          //
      }
      
      /**
       * Get the channels the event should broadcast on.
       *
       * @return array<Channel>
       */
      public function broadcastOn(): array
      {
          return [
              new PrivateChannel("team.{$this->message->team_id}"),
          ];
      }
      
      /**
       * Get the data to broadcast.
       *
       * @return array<string, mixed>
       */
      public function broadcastWith(): array
      {
          return [
              'id' => $this->message->id,
              'content' => $this->message->content,
              'created_at' => $this->message->created_at->toIso8601String(),
              'user' => [
                  'id' => $this->message->user->id,
                  'name' => $this->message->user->name,
                  'avatar' => $this->message->user->profile->getAvatarUrl(),
              ],
          ];
      }
      
      /**
       * The event's broadcast name.
       */
      public function broadcastAs(): string
      {
          return 'message.sent';
      }
  }
  
  // Example Reverb configuration (config/broadcasting.php)
  
  return [
      'default' => env('BROADCAST_DRIVER', 'reverb'),
      
      'connections' => [
          'reverb' => [
              'driver' => 'reverb',
              'app_id' => env('REVERB_APP_ID', 'ume-app'),
              'host' => env('REVERB_HOST', '127.0.0.1'),
              'port' => env('REVERB_PORT', 8080),
              'scheme' => env('REVERB_SCHEME', 'http'),
              'options' => [
                  'tls' => [
                      'verify_peer' => env('REVERB_VERIFY_PEER', true),
                      'verify_peer_name' => env('REVERB_VERIFY_PEER_NAME', true),
                  ],
              ],
              'client_options' => [
                  'timeout' => env('REVERB_CLIENT_TIMEOUT', 5),
                  'retry_on_timeout' => env('REVERB_CLIENT_RETRY_ON_TIMEOUT', true),
                  'retry_attempts' => env('REVERB_CLIENT_RETRY_ATTEMPTS', 3),
              ],
          ],
          
          'pusher' => [
              'driver' => 'pusher',
              'key' => env('PUSHER_APP_KEY'),
              'secret' => env('PUSHER_APP_SECRET'),
              'app_id' => env('PUSHER_APP_ID'),
              'options' => [
                  'cluster' => env('PUSHER_APP_CLUSTER'),
                  'host' => env('PUSHER_HOST') ?: 'api-'.env('PUSHER_APP_CLUSTER', 'mt1').'.pusher.com',
                  'port' => env('PUSHER_PORT', 443),
                  'scheme' => env('PUSHER_SCHEME', 'https'),
                  'encrypted' => true,
                  'useTLS' => env('PUSHER_SCHEME', 'https') === 'https',
              ],
              'client_options' => [
                  // Guzzle client options: https://docs.guzzlephp.org/en/stable/request-options.html
              ],
          ],
      ],
  ];
  
  // Example client-side JavaScript for connecting to Reverb
  
  /*
  // Import Echo
  import Echo from 'laravel-echo';
  import Pusher from 'pusher-js';
  
  // Configure Echo
  window.Echo = new Echo({
      broadcaster: 'reverb',
      key: 'ume-app',
      wsHost: window.location.hostname,
      wsPort: 8080,
      forceTLS: false,
      disableStats: true,
      enabledTransports: ['ws', 'wss'],
  });
  
  // Listen for messages on a private channel
  window.Echo.private(`team.${teamId}`)
      .listen('.message.sent', (e) => {
          console.log('New message received:', e);
          addMessageToChat(e);
      });
  
  // Join a presence channel to see who's online
  window.Echo.join(`team.${teamId}.presence`)
      .here((users) => {
          console.log('Users currently online:', users);
          updateOnlineUsersList(users);
      })
      .joining((user) => {
          console.log('User joined:', user);
          addUserToOnlineList(user);
      })
      .leaving((user) => {
          console.log('User left:', user);
          removeUserFromOnlineList(user);
      });
  */
  
  // Example command to start the Reverb server
  
  /*
  # Start the Reverb server
  php artisan reverb:start
  
  # Start the Reverb server with custom host and port
  php artisan reverb:start --host=0.0.0.0 --port=8080
  
  # Start the Reverb server in debug mode
  php artisan reverb:start --debug
  
  # Start the Reverb server as a daemon (background process)
  php artisan reverb:start --daemon
  */
  
  // Example deployment configuration for production
  
  /*
  # Supervisor configuration (/etc/supervisor/conf.d/reverb.conf)
  [program:reverb]
  process_name=%(program_name)s
  command=php /path/to/your/project/artisan reverb:start
  autostart=true
  autorestart=true
  user=www-data
  redirect_stderr=true
  stdout_logfile=/path/to/your/project/storage/logs/reverb.log
  stopwaitsecs=3600
  */
  
  // Example .env configuration
  
  /*
  # Broadcasting configuration
  BROADCAST_DRIVER=reverb
  REVERB_APP_ID=ume-app
  REVERB_HOST=127.0.0.1
  REVERB_PORT=8080
  REVERB_SCHEME=http
  
  # For production with SSL
  # REVERB_SCHEME=https
  # REVERB_PORT=443
  */
explanation: |
  This example demonstrates how to set up Laravel Reverb for WebSocket communication:
  
  1. **Broadcast Service Provider**: Registers routes for channel authorization and loads channel definitions.
  
  2. **Channel Definitions**: Defines different types of channels:
     - **Public Channels**: Open to all users without authentication
     - **Private Channels**: Require authentication and authorization
     - **Presence Channels**: Track and share user presence information
  
  3. **Broadcasting Events**: Creating events that implement `ShouldBroadcast`:
     - Specifying which channels to broadcast on
     - Customizing the broadcast data
     - Setting a custom event name
  
  4. **Reverb Configuration**: Configuring Reverb in `config/broadcasting.php`:
     - Setting the app ID, host, port, and scheme
     - Configuring TLS options for secure connections
     - Setting client options like timeout and retry behavior
  
  5. **Client-Side Integration**: Using Laravel Echo to connect to Reverb:
     - Configuring Echo to use Reverb
     - Listening for events on private channels
     - Joining presence channels to track user presence
  
  6. **Server Management**: Starting and managing the Reverb server:
     - Using Artisan commands to start the server
     - Configuring Supervisor for production deployment
     - Setting environment variables
  
  Key Reverb features illustrated:
  
  - **Channel Authorization**: Ensuring users can only subscribe to channels they have access to
  - **Presence Channels**: Tracking which users are online and sharing user information
  - **Custom Event Data**: Customizing the data that gets broadcast with events
  - **Secure Connections**: Configuring TLS for secure WebSocket connections
  - **Production Deployment**: Using Supervisor to keep the Reverb server running
  
  In a real Laravel application:
  - You would implement proper authentication and authorization
  - You would handle reconnection and error scenarios
  - You might use a load balancer for high-availability setups
  - You would implement proper logging and monitoring
challenges:
  - Implement a chat system using private channels for direct messages
  - Create a notification system that broadcasts to specific users
  - Add support for file uploads through WebSockets
  - Implement a typing indicator using presence channels
  - Create a dashboard that shows real-time statistics using WebSockets
:::
