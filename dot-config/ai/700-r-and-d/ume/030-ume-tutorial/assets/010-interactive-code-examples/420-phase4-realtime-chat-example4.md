# Real-time Chat Implementation

:::interactive-code
title: Implementing a Real-time Chat System
description: This example demonstrates how to implement a complete real-time chat system with Laravel Reverb, including message broadcasting, typing indicators, and offline message handling.
language: php
editable: true
code: |
  <?php
  
  namespace App\Models;
  
  use Illuminate\Database\Eloquent\Model;
  use Illuminate\Database\Eloquent\Relations\BelongsTo;
  use Illuminate\Database\Eloquent\SoftDeletes;
  
  class ChatMessage extends Model
  {
      use SoftDeletes;
      
      protected $fillable = [
          'chat_room_id',
          'user_id',
          'content',
          'type',
          'metadata',
      ];
      
      protected $casts = [
          'metadata' => 'array',
          'read_at' => 'datetime',
      ];
      
      /**
       * Get the chat room that the message belongs to.
       */
      public function chatRoom(): BelongsTo
      {
          return $this->belongsTo(ChatRoom::class);
      }
      
      /**
       * Get the user that sent the message.
       */
      public function user(): BelongsTo
      {
          return $this->belongsTo(User::class);
      }
      
      /**
       * Mark the message as read.
       */
      public function markAsRead(): self
      {
          if (!$this->read_at) {
              $this->read_at = now();
              $this->save();
          }
          
          return $this;
      }
      
      /**
       * Check if the message is read.
       */
      public function isRead(): bool
      {
          return $this->read_at !== null;
      }
  }
  
  namespace App\Models;
  
  use Illuminate\Database\Eloquent\Model;
  use Illuminate\Database\Eloquent\Relations\BelongsTo;
  use Illuminate\Database\Eloquent\Relations\BelongsToMany;
  use Illuminate\Database\Eloquent\Relations\HasMany;
  
  class ChatRoom extends Model
  {
      protected $fillable = [
          'name',
          'type',
          'team_id',
          'created_by',
      ];
      
      /**
       * The users that belong to the chat room.
       */
      public function users(): BelongsToMany
      {
          return $this->belongsToMany(User::class, 'chat_room_user')
              ->withPivot('role')
              ->withTimestamps();
      }
      
      /**
       * Get the messages for the chat room.
       */
      public function messages(): HasMany
      {
          return $this->hasMany(ChatMessage::class);
      }
      
      /**
       * Get the team that the chat room belongs to.
       */
      public function team(): BelongsTo
      {
          return $this->belongsTo(Team::class);
      }
      
      /**
       * Get the user that created the chat room.
       */
      public function createdBy(): BelongsTo
      {
          return $this->belongsTo(User::class, 'created_by');
      }
      
      /**
       * Check if the chat room is a direct message.
       */
      public function isDirectMessage(): bool
      {
          return $this->type === 'direct';
      }
      
      /**
       * Check if the chat room is a group chat.
       */
      public function isGroupChat(): bool
      {
          return $this->type === 'group';
      }
      
      /**
       * Check if the chat room is a team channel.
       */
      public function isTeamChannel(): bool
      {
          return $this->type === 'team';
      }
      
      /**
       * Get the channel name for broadcasting.
       */
      public function getChannelName(): string
      {
          return "chat.room.{$this->id}";
      }
  }
  
  namespace App\Http\Controllers;
  
  use App\Events\MessageSent;
  use App\Events\UserTyping;
  use App\Models\ChatMessage;
  use App\Models\ChatRoom;
  use Illuminate\Http\Request;
  use Illuminate\Support\Facades\Auth;
  
  class ChatController extends Controller
  {
      /**
       * Get chat rooms for the authenticated user.
       */
      public function getRooms(Request $request)
      {
          $user = Auth::user();
          $rooms = $user->chatRooms()
              ->with(['users:id,name', 'messages' => function ($query) {
                  $query->latest()->limit(1);
              }])
              ->get()
              ->map(function ($room) use ($user) {
                  $lastMessage = $room->messages->first();
                  $unreadCount = $room->messages()
                      ->whereNull('read_at')
                      ->where('user_id', '!=', $user->id)
                      ->count();
                  
                  return [
                      'id' => $room->id,
                      'name' => $room->name,
                      'type' => $room->type,
                      'users' => $room->users,
                      'last_message' => $lastMessage ? [
                          'content' => $lastMessage->content,
                          'user_id' => $lastMessage->user_id,
                          'created_at' => $lastMessage->created_at,
                      ] : null,
                      'unread_count' => $unreadCount,
                  ];
              });
          
          return response()->json($rooms);
      }
      
      /**
       * Get messages for a chat room.
       */
      public function getMessages(Request $request, ChatRoom $chatRoom)
      {
          // Check if user is a member of the chat room
          if (!$chatRoom->users->contains(Auth::id())) {
              return response()->json(['error' => 'Unauthorized'], 403);
          }
          
          $limit = $request->input('limit', 50);
          $before = $request->input('before');
          
          $query = $chatRoom->messages()
              ->with('user:id,name')
              ->latest('id');
          
          if ($before) {
              $query->where('id', '<', $before);
          }
          
          $messages = $query->limit($limit)->get()->reverse()->values();
          
          // Mark messages as read
          $chatRoom->messages()
              ->whereNull('read_at')
              ->where('user_id', '!=', Auth::id())
              ->update(['read_at' => now()]);
          
          return response()->json($messages);
      }
      
      /**
       * Send a message to a chat room.
       */
      public function sendMessage(Request $request, ChatRoom $chatRoom)
      {
          // Check if user is a member of the chat room
          if (!$chatRoom->users->contains(Auth::id())) {
              return response()->json(['error' => 'Unauthorized'], 403);
          }
          
          $request->validate([
              'content' => 'required|string',
              'type' => 'nullable|string|in:text,image,file',
              'metadata' => 'nullable|array',
          ]);
          
          $message = new ChatMessage([
              'chat_room_id' => $chatRoom->id,
              'user_id' => Auth::id(),
              'content' => $request->input('content'),
              'type' => $request->input('type', 'text'),
              'metadata' => $request->input('metadata'),
          ]);
          
          $message->save();
          
          // Load the user relationship
          $message->load('user:id,name');
          
          // Broadcast the message
          broadcast(new MessageSent($message))->toOthers();
          
          return response()->json($message);
      }
      
      /**
       * Mark messages as read.
       */
      public function markAsRead(Request $request, ChatRoom $chatRoom)
      {
          // Check if user is a member of the chat room
          if (!$chatRoom->users->contains(Auth::id())) {
              return response()->json(['error' => 'Unauthorized'], 403);
          }
          
          $chatRoom->messages()
              ->whereNull('read_at')
              ->where('user_id', '!=', Auth::id())
              ->update(['read_at' => now()]);
          
          return response()->json(['success' => true]);
      }
      
      /**
       * Broadcast typing indicator.
       */
      public function typing(Request $request, ChatRoom $chatRoom)
      {
          // Check if user is a member of the chat room
          if (!$chatRoom->users->contains(Auth::id())) {
              return response()->json(['error' => 'Unauthorized'], 403);
          }
          
          $user = Auth::user();
          
          broadcast(new UserTyping($chatRoom, $user))->toOthers();
          
          return response()->json(['success' => true]);
      }
      
      /**
       * Create a new chat room.
       */
      public function createRoom(Request $request)
      {
          $request->validate([
              'name' => 'required_if:type,group,team|string|max:255',
              'type' => 'required|string|in:direct,group,team',
              'user_ids' => 'required_if:type,direct,group|array',
              'user_ids.*' => 'exists:users,id',
              'team_id' => 'required_if:type,team|exists:teams,id',
          ]);
          
          $user = Auth::user();
          $type = $request->input('type');
          $userIds = $request->input('user_ids', []);
          
          // Add the current user to the list of users
          if (!in_array($user->id, $userIds)) {
              $userIds[] = $user->id;
          }
          
          // For direct messages, ensure there are exactly 2 users
          if ($type === 'direct' && count($userIds) !== 2) {
              return response()->json(['error' => 'Direct messages must have exactly 2 users'], 422);
          }
          
          // For direct messages, check if a chat room already exists
          if ($type === 'direct') {
              $otherUserId = $userIds[0] === $user->id ? $userIds[1] : $userIds[0];
              
              $existingRoom = $user->chatRooms()
                  ->where('type', 'direct')
                  ->whereHas('users', function ($query) use ($otherUserId) {
                      $query->where('users.id', $otherUserId);
                  })
                  ->first();
              
              if ($existingRoom) {
                  return response()->json([
                      'message' => 'Chat room already exists',
                      'room' => $existingRoom,
                  ]);
              }
          }
          
          // Create the chat room
          $chatRoom = new ChatRoom([
              'name' => $request->input('name', ''),
              'type' => $type,
              'team_id' => $request->input('team_id'),
              'created_by' => $user->id,
          ]);
          
          // For direct messages, set the name to the other user's name
          if ($type === 'direct') {
              $otherUserId = $userIds[0] === $user->id ? $userIds[1] : $userIds[0];
              $otherUser = User::find($otherUserId);
              $chatRoom->name = $otherUser->name;
          }
          
          $chatRoom->save();
          
          // Add users to the chat room
          $userRoles = [];
          foreach ($userIds as $userId) {
              $role = $userId === $user->id ? 'admin' : 'member';
              $userRoles[$userId] = ['role' => $role];
          }
          
          $chatRoom->users()->attach($userRoles);
          
          // Load relationships
          $chatRoom->load('users:id,name');
          
          return response()->json($chatRoom);
      }
  }
  
  namespace App\Events;
  
  use App\Models\ChatMessage;
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
       * Create a new event instance.
       */
      public function __construct(public ChatMessage $message)
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
              new PrivateChannel($this->message->chatRoom->getChannelName()),
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
              'chat_room_id' => $this->message->chat_room_id,
              'user_id' => $this->message->user_id,
              'user' => [
                  'id' => $this->message->user->id,
                  'name' => $this->message->user->name,
              ],
              'content' => $this->message->content,
              'type' => $this->message->type,
              'metadata' => $this->message->metadata,
              'created_at' => $this->message->created_at->toIso8601String(),
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
  
  namespace App\Events;
  
  use App\Models\ChatRoom;
  use App\Models\User;
  use Illuminate\Broadcasting\Channel;
  use Illuminate\Broadcasting\InteractsWithSockets;
  use Illuminate\Broadcasting\PresenceChannel;
  use Illuminate\Broadcasting\PrivateChannel;
  use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
  use Illuminate\Foundation\Events\Dispatchable;
  use Illuminate\Queue\SerializesModels;
  
  class UserTyping implements ShouldBroadcast
  {
      use Dispatchable, InteractsWithSockets, SerializesModels;
      
      /**
       * Create a new event instance.
       */
      public function __construct(public ChatRoom $chatRoom, public User $user)
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
              new PrivateChannel($this->chatRoom->getChannelName()),
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
              'user_id' => $this->user->id,
              'user_name' => $this->user->name,
              'chat_room_id' => $this->chatRoom->id,
              'timestamp' => now()->toIso8601String(),
          ];
      }
      
      /**
       * The event's broadcast name.
       */
      public function broadcastAs(): string
      {
          return 'user.typing';
      }
  }
  
  // Example client-side JavaScript for the chat system
  
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
  
  // Chat room component
  class ChatRoom {
      constructor(roomId) {
          this.roomId = roomId;
          this.messages = [];
          this.typingUsers = {};
          this.typingTimeout = null;
          
          this.setupEventListeners();
      }
      
      setupEventListeners() {
          // Listen for new messages
          window.Echo.private(`chat.room.${this.roomId}`)
              .listen('.message.sent', (e) => {
                  this.addMessage(e);
                  this.removeTypingIndicator(e.user_id);
              })
              .listen('.user.typing', (e) => {
                  this.showTypingIndicator(e.user_id, e.user_name);
              });
          
          // Set up typing indicator
          document.getElementById('message-input').addEventListener('input', () => {
              this.sendTypingIndicator();
          });
      }
      
      loadMessages() {
          fetch(`/api/chat/rooms/${this.roomId}/messages`)
              .then(response => response.json())
              .then(data => {
                  this.messages = data;
                  this.renderMessages();
                  this.markAsRead();
              });
      }
      
      sendMessage(content) {
          fetch(`/api/chat/rooms/${this.roomId}/messages`, {
              method: 'POST',
              headers: {
                  'Content-Type': 'application/json',
                  'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
              },
              body: JSON.stringify({
                  content: content,
                  type: 'text'
              })
          })
          .then(response => response.json())
          .then(data => {
              this.addMessage(data);
              document.getElementById('message-input').value = '';
          });
      }
      
      addMessage(message) {
          this.messages.push(message);
          this.renderMessages();
          this.markAsRead();
      }
      
      renderMessages() {
          const container = document.getElementById('messages-container');
          
          // Render messages
          let html = '';
          this.messages.forEach(message => {
              const isCurrentUser = message.user_id === currentUserId;
              const messageClass = isCurrentUser ? 'message-sent' : 'message-received';
              
              html += `
                  <div class="message ${messageClass}">
                      <div class="message-header">
                          <span class="message-sender">${message.user.name}</span>
                          <span class="message-time">${new Date(message.created_at).toLocaleTimeString()}</span>
                      </div>
                      <div class="message-content">${message.content}</div>
                  </div>
              `;
          });
          
          container.innerHTML = html;
          
          // Scroll to bottom
          container.scrollTop = container.scrollHeight;
      }
      
      markAsRead() {
          fetch(`/api/chat/rooms/${this.roomId}/read`, {
              method: 'POST',
              headers: {
                  'Content-Type': 'application/json',
                  'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
              }
          });
      }
      
      sendTypingIndicator() {
          // Clear existing timeout
          if (this.typingTimeout) {
              clearTimeout(this.typingTimeout);
          }
          
          // Send typing indicator
          fetch(`/api/chat/rooms/${this.roomId}/typing`, {
              method: 'POST',
              headers: {
                  'Content-Type': 'application/json',
                  'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
              }
          });
          
          // Set timeout to clear typing indicator
          this.typingTimeout = setTimeout(() => {
              this.typingTimeout = null;
          }, 3000);
      }
      
      showTypingIndicator(userId, userName) {
          // Add user to typing users
          this.typingUsers[userId] = {
              name: userName,
              timestamp: new Date()
          };
          
          // Update typing indicator
          this.updateTypingIndicator();
          
          // Set timeout to remove typing indicator
          setTimeout(() => {
              this.removeTypingIndicator(userId);
          }, 3000);
      }
      
      removeTypingIndicator(userId) {
          // Remove user from typing users
          delete this.typingUsers[userId];
          
          // Update typing indicator
          this.updateTypingIndicator();
      }
      
      updateTypingIndicator() {
          const typingIndicator = document.getElementById('typing-indicator');
          const typingUsers = Object.values(this.typingUsers);
          
          if (typingUsers.length === 0) {
              typingIndicator.style.display = 'none';
              return;
          }
          
          let text = '';
          if (typingUsers.length === 1) {
              text = `${typingUsers[0].name} is typing...`;
          } else if (typingUsers.length === 2) {
              text = `${typingUsers[0].name} and ${typingUsers[1].name} are typing...`;
          } else {
              text = 'Several people are typing...';
          }
          
          typingIndicator.textContent = text;
          typingIndicator.style.display = 'block';
      }
  }
  
  // Initialize chat room
  const chatRoom = new ChatRoom(roomId);
  chatRoom.loadMessages();
  
  // Send message when form is submitted
  document.getElementById('message-form').addEventListener('submit', (e) => {
      e.preventDefault();
      const input = document.getElementById('message-input');
      const content = input.value.trim();
      
      if (content) {
          chatRoom.sendMessage(content);
      }
  });
  */
explanation: |
  This example demonstrates a comprehensive real-time chat system:
  
  1. **Data Models**: The system defines two main models:
     - **ChatRoom**: Represents a conversation space (direct message, group chat, or team channel)
     - **ChatMessage**: Represents individual messages within a chat room
  
  2. **Chat Room Types**:
     - **Direct Messages**: Private conversations between two users
     - **Group Chats**: Conversations between multiple users
     - **Team Channels**: Public channels within a team
  
  3. **Real-Time Features**:
     - **Message Broadcasting**: New messages are broadcast in real-time to all chat room members
     - **Typing Indicators**: Users can see when others are typing
     - **Read Receipts**: Messages are marked as read when viewed
  
  4. **API Endpoints**:
     - Get chat rooms for the current user
     - Get messages for a specific chat room
     - Send a message to a chat room
     - Mark messages as read
     - Broadcast typing indicators
     - Create new chat rooms
  
  5. **Broadcasting Events**:
     - **MessageSent**: Broadcast when a new message is sent
     - **UserTyping**: Broadcast when a user is typing
  
  6. **Client-Side Implementation**:
     - Connecting to WebSocket server using Laravel Echo
     - Listening for real-time events
     - Sending messages and typing indicators
     - Rendering messages and typing indicators
     - Handling read receipts
  
  Key features of the implementation:
  
  - **Private Channels**: Using private channels to ensure only authorized users can subscribe
  - **Message Types**: Supporting different message types (text, image, file)
  - **Metadata**: Allowing additional metadata for messages
  - **Soft Deletes**: Using soft deletes for messages to allow recovery
  - **Typing Timeouts**: Automatically clearing typing indicators after a timeout
  - **Unread Counts**: Tracking unread message counts for each chat room
  
  In a real Laravel application:
  - You would implement file uploads for image and file messages
  - You would add message reactions and replies
  - You would implement message search functionality
  - You would add message editing and deletion
  - You would implement message delivery status (sent, delivered, read)
challenges:
  - Implement message reactions (like, love, laugh, etc.)
  - Add support for message replies and threads
  - Create a message search functionality
  - Implement message editing and deletion
  - Add support for message formatting (bold, italic, code, etc.)
:::
