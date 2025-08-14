# Presence Indicators

:::interactive-code
title: Implementing User Presence Indicators
description: This example demonstrates how to implement real-time user presence indicators using Laravel Reverb and presence channels.
language: php
editable: true
code: |
  <?php
  
  namespace App\Http\Controllers;
  
  use App\Models\Team;
  use App\Models\User;
  use App\Services\PresenceService;
  use Illuminate\Http\Request;
  use Illuminate\Support\Facades\Auth;
  
  class PresenceController extends Controller
  {
      protected $presenceService;
      
      public function __construct(PresenceService $presenceService)
      {
          $this->presenceService = $presenceService;
          $this->middleware('auth');
      }
      
      /**
       * Get online users for a team.
       *
       * @param Request $request
       * @param int $teamId
       * @return \Illuminate\Http\JsonResponse
       */
      public function getOnlineTeamMembers(Request $request, int $teamId)
      {
          $team = Team::findOrFail($teamId);
          
          // Check if user is a member of the team
          if (!$team->hasMember(Auth::user())) {
              return response()->json(['error' => 'Unauthorized'], 403);
          }
          
          $onlineUsers = $this->presenceService->getOnlineTeamMembers($teamId);
          
          return response()->json([
              'online_count' => count($onlineUsers),
              'online_users' => $onlineUsers,
          ]);
      }
      
      /**
       * Update user's status.
       *
       * @param Request $request
       * @return \Illuminate\Http\JsonResponse
       */
      public function updateStatus(Request $request)
      {
          $request->validate([
              'status' => 'required|string|in:online,away,busy,offline',
              'custom_message' => 'nullable|string|max:100',
          ]);
          
          $user = Auth::user();
          $status = $request->input('status');
          $customMessage = $request->input('custom_message');
          
          $this->presenceService->updateUserStatus($user->id, $status, $customMessage);
          
          return response()->json([
              'status' => $status,
              'custom_message' => $customMessage,
          ]);
      }
  }
  
  namespace App\Services;
  
  use App\Events\UserStatusUpdated;
  use App\Models\Team;
  use App\Models\User;
  use Illuminate\Support\Facades\Cache;
  use Illuminate\Support\Facades\Redis;
  
  class PresenceService
  {
      // Cache TTL for presence data (in seconds)
      const PRESENCE_TTL = 300; // 5 minutes
      
      /**
       * Get online team members.
       *
       * @param int $teamId
       * @return array
       */
      public function getOnlineTeamMembers(int $teamId): array
      {
          // In a real app with Reverb, this would use the presence channel data
          // For this example, we'll simulate it using Redis/Cache
          
          $team = Team::findOrFail($teamId);
          $onlineUsers = [];
          
          foreach ($team->members as $member) {
              $presenceData = $this->getUserPresence($member->id);
              
              if ($presenceData && $presenceData['status'] !== 'offline') {
                  $onlineUsers[] = [
                      'id' => $member->id,
                      'name' => $member->name,
                      'avatar' => $member->profile->getAvatarUrl(),
                      'status' => $presenceData['status'],
                      'custom_message' => $presenceData['custom_message'] ?? null,
                      'last_active' => $presenceData['last_active'],
                  ];
              }
          }
          
          return $onlineUsers;
      }
      
      /**
       * Get user presence data.
       *
       * @param int $userId
       * @return array|null
       */
      public function getUserPresence(int $userId): ?array
      {
          $cacheKey = "user_presence:{$userId}";
          
          // Try to get from cache
          $presenceData = Cache::get($cacheKey);
          
          if (!$presenceData) {
              return null;
          }
          
          // Check if the presence data is stale (user might be offline)
          $lastActive = strtotime($presenceData['last_active']);
          $now = time();
          
          if ($now - $lastActive > self::PRESENCE_TTL && $presenceData['status'] !== 'offline') {
              // User has been inactive for too long, mark as offline
              $presenceData['status'] = 'offline';
              $this->updateUserStatus($userId, 'offline');
          }
          
          return $presenceData;
      }
      
      /**
       * Update user status.
       *
       * @param int $userId
       * @param string $status
       * @param string|null $customMessage
       * @return void
       */
      public function updateUserStatus(int $userId, string $status, ?string $customMessage = null): void
      {
          $user = User::findOrFail($userId);
          $cacheKey = "user_presence:{$userId}";
          
          $presenceData = [
              'status' => $status,
              'custom_message' => $customMessage,
              'last_active' => now()->toIso8601String(),
          ];
          
          // Store in cache
          Cache::put($cacheKey, $presenceData, now()->addSeconds(self::PRESENCE_TTL * 2));
          
          // Broadcast the status update
          broadcast(new UserStatusUpdated($user, $status, $customMessage))->toOthers();
      }
      
      /**
       * Update user's last active timestamp.
       *
       * @param int $userId
       * @return void
       */
      public function updateLastActive(int $userId): void
      {
          $cacheKey = "user_presence:{$userId}";
          $presenceData = Cache::get($cacheKey);
          
          if ($presenceData) {
              $presenceData['last_active'] = now()->toIso8601String();
              Cache::put($cacheKey, $presenceData, now()->addSeconds(self::PRESENCE_TTL * 2));
          }
      }
      
      /**
       * Handle user connection.
       *
       * @param int $userId
       * @return void
       */
      public function handleUserConnected(int $userId): void
      {
          $cacheKey = "user_presence:{$userId}";
          $presenceData = Cache::get($cacheKey);
          
          if (!$presenceData || $presenceData['status'] === 'offline') {
              $this->updateUserStatus($userId, 'online');
          } else {
              $this->updateLastActive($userId);
          }
      }
      
      /**
       * Handle user disconnection.
       *
       * @param int $userId
       * @return void
       */
      public function handleUserDisconnected(int $userId): void
      {
          // Don't immediately mark the user as offline
          // They might be refreshing the page or navigating between pages
          // Instead, we'll let the TTL handle it
          $this->updateLastActive($userId);
      }
  }
  
  namespace App\Events;
  
  use App\Models\User;
  use Illuminate\Broadcasting\Channel;
  use Illuminate\Broadcasting\InteractsWithSockets;
  use Illuminate\Broadcasting\PresenceChannel;
  use Illuminate\Broadcasting\PrivateChannel;
  use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
  use Illuminate\Foundation\Events\Dispatchable;
  use Illuminate\Queue\SerializesModels;
  
  class UserStatusUpdated implements ShouldBroadcast
  {
      use Dispatchable, InteractsWithSockets, SerializesModels;
      
      /**
       * Create a new event instance.
       */
      public function __construct(
          public User $user,
          public string $status,
          public ?string $customMessage = null
      ) {
          //
      }
      
      /**
       * Get the channels the event should broadcast on.
       *
       * @return array<Channel>
       */
      public function broadcastOn(): array
      {
          $channels = [
              new PrivateChannel("App.Models.User.{$this->user->id}"),
          ];
          
          // Broadcast to all teams the user is a member of
          foreach ($this->user->teams as $team) {
              $channels[] = new PresenceChannel("team.{$team->id}.presence");
          }
          
          return $channels;
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
              'avatar' => $this->user->profile->getAvatarUrl(),
              'status' => $this->status,
              'custom_message' => $this->customMessage,
              'last_active' => now()->toIso8601String(),
          ];
      }
      
      /**
       * The event's broadcast name.
       */
      public function broadcastAs(): string
      {
          return 'user.status.updated';
      }
  }
  
  namespace App\Http\Middleware;
  
  use App\Services\PresenceService;
  use Closure;
  use Illuminate\Http\Request;
  use Illuminate\Support\Facades\Auth;
  
  class TrackUserActivity
  {
      protected $presenceService;
      
      public function __construct(PresenceService $presenceService)
      {
          $this->presenceService = $presenceService;
      }
      
      /**
       * Handle an incoming request.
       *
       * @param  \Illuminate\Http\Request  $request
       * @param  \Closure  $next
       * @return mixed
       */
      public function handle(Request $request, Closure $next)
      {
          $response = $next($request);
          
          // Update user's last active timestamp
          if (Auth::check()) {
              $this->presenceService->updateLastActive(Auth::id());
          }
          
          return $response;
      }
  }
  
  // Example client-side JavaScript for presence indicators
  
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
  
  // Join the team presence channel
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
  
  // Listen for status updates
  window.Echo.private(`team.${teamId}.presence`)
      .listen('.user.status.updated', (e) => {
          console.log('User status updated:', e);
          updateUserStatus(e.user_id, e.status, e.custom_message);
      });
  
  // Update user status
  function updateUserStatus(status, customMessage = '') {
      fetch('/api/presence/status', {
          method: 'POST',
          headers: {
              'Content-Type': 'application/json',
              'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
          },
          body: JSON.stringify({
              status: status,
              custom_message: customMessage
          })
      })
      .then(response => response.json())
      .then(data => {
          console.log('Status updated:', data);
      })
      .catch(error => {
          console.error('Error updating status:', error);
      });
  }
  
  // Update UI based on user status
  function updateUserStatus(userId, status, customMessage) {
      const userElement = document.querySelector(`.user-item[data-user-id="${userId}"]`);
      
      if (userElement) {
          // Remove all status classes
          userElement.classList.remove('status-online', 'status-away', 'status-busy', 'status-offline');
          
          // Add the new status class
          userElement.classList.add(`status-${status}`);
          
          // Update status indicator
          const statusIndicator = userElement.querySelector('.status-indicator');
          statusIndicator.setAttribute('title', status);
          
          // Update custom message if present
          const customMessageElement = userElement.querySelector('.custom-message');
          if (customMessageElement) {
              customMessageElement.textContent = customMessage || '';
          }
      }
  }
  
  // Handle page visibility changes
  document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'visible') {
          // User is looking at the page, set status to online
          updateUserStatus('online');
      } else {
          // User switched to another tab, set status to away
          updateUserStatus('away');
      }
  });
  
  // Handle before unload event
  window.addEventListener('beforeunload', () => {
      // Use sendBeacon to send a non-blocking request
      const data = new FormData();
      data.append('status', 'offline');
      navigator.sendBeacon('/api/presence/status', data);
  });
  */
explanation: |
  This example demonstrates a comprehensive user presence system:
  
  1. **Presence Service**: A central service that manages user presence data:
     - Tracking user status (online, away, busy, offline)
     - Storing custom status messages
     - Managing last active timestamps
     - Handling user connections and disconnections
  
  2. **Presence Channels**: Using Laravel Reverb's presence channels to:
     - Track which users are currently connected
     - Notify when users join or leave
     - Share user information with all channel subscribers
  
  3. **Status Broadcasting**: Broadcasting status updates to relevant channels:
     - User's private channel for personal notifications
     - Team presence channels for team-wide awareness
  
  4. **Activity Tracking**: Middleware that updates the user's last active timestamp on each request
  
  5. **Automatic Status Updates**: Handling various scenarios:
     - Marking users as away when they switch tabs
     - Marking users as offline when they close the browser
     - Automatically updating status based on inactivity
  
  6. **Cache Integration**: Using Laravel's cache to store presence data:
     - Setting appropriate TTLs to handle disconnections
     - Efficiently retrieving presence information
  
  7. **API Endpoints**: Providing endpoints to:
     - Get online team members
     - Update user status
  
  Key features of the implementation:
  
  - **Multi-Device Support**: The system handles users connected from multiple devices
  - **Graceful Disconnection**: Users aren't immediately marked offline when disconnected
  - **Custom Status Messages**: Users can set custom status messages
  - **Real-Time Updates**: Status changes are broadcast in real-time
  - **Efficient Caching**: Presence data is cached for performance
  
  In a real Laravel application:
  - You would integrate with Laravel Reverb's actual presence channel data
  - You might use Redis for distributed presence tracking
  - You would implement proper error handling and logging
  - You would add more sophisticated UI components
challenges:
  - Implement an "idle" status that's automatically set after a period of inactivity
  - Add support for scheduled status changes (e.g., "In a meeting until 3 PM")
  - Create a "Do Not Disturb" mode that suppresses notifications
  - Implement location sharing as part of the presence system
  - Add support for device-specific status (e.g., "On mobile" vs "At computer")
:::
