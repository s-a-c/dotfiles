# Notifications System

:::interactive-code
title: Implementing a Comprehensive Notifications System
description: This example demonstrates how to implement a complete notifications system with multiple delivery channels, preferences, and real-time updates.
language: php
editable: true
code: |
  <?php
  
  namespace App\Notifications;
  
  use App\Models\Task;
  use Illuminate\Bus\Queueable;
  use Illuminate\Contracts\Queue\ShouldQueue;
  use Illuminate\Notifications\Messages\BroadcastMessage;
  use Illuminate\Notifications\Messages\MailMessage;
  use Illuminate\Notifications\Notification;
  
  class TaskAssigned extends Notification implements ShouldQueue
  {
      use Queueable;
      
      /**
       * Create a new notification instance.
       */
      public function __construct(public Task $task)
      {
          //
      }
      
      /**
       * Get the notification's delivery channels.
       *
       * @return array<int, string>
       */
      public function via(object $notifiable): array
      {
          // Get user's notification preferences
          $preferences = $notifiable->notificationPreferences()
              ->where('notification_type', 'task_assigned')
              ->first();
          
          // Default channels if no preferences are set
          if (!$preferences) {
              return ['database', 'broadcast', 'mail'];
          }
          
          // Get channels from preferences
          $channels = [];
          
          if ($preferences->database_enabled) {
              $channels[] = 'database';
          }
          
          if ($preferences->broadcast_enabled) {
              $channels[] = 'broadcast';
          }
          
          if ($preferences->mail_enabled) {
              $channels[] = 'mail';
          }
          
          if ($preferences->push_enabled) {
              $channels[] = 'pushover';
          }
          
          return $channels;
      }
      
      /**
       * Get the mail representation of the notification.
       */
      public function toMail(object $notifiable): MailMessage
      {
          $url = url("/tasks/{$this->task->id}");
          
          return (new MailMessage)
              ->subject("Task Assigned: {$this->task->title}")
              ->greeting("Hello {$notifiable->name}!")
              ->line("You have been assigned a new task: {$this->task->title}")
              ->line("Priority: {$this->task->priority}")
              ->when($this->task->due_date, function ($message) {
                  return $message->line("Due Date: {$this->task->due_date->format('M d, Y')}");
              })
              ->action('View Task', $url)
              ->line('Thank you for using our application!');
      }
      
      /**
       * Get the database representation of the notification.
       */
      public function toDatabase(object $notifiable): array
      {
          return [
              'task_id' => $this->task->id,
              'task_title' => $this->task->title,
              'priority' => $this->task->priority,
              'due_date' => $this->task->due_date?->format('Y-m-d'),
              'assigned_by' => $this->task->assignedBy?->name ?? 'System',
              'team_id' => $this->task->team_id,
              'team_name' => $this->task->team->name,
          ];
      }
      
      /**
       * Get the broadcast representation of the notification.
       */
      public function toBroadcast(object $notifiable): BroadcastMessage
      {
          return new BroadcastMessage([
              'id' => $this->id,
              'type' => 'task_assigned',
              'task_id' => $this->task->id,
              'task_title' => $this->task->title,
              'priority' => $this->task->priority,
              'due_date' => $this->task->due_date?->format('Y-m-d'),
              'assigned_by' => $this->task->assignedBy?->name ?? 'System',
              'team_id' => $this->task->team_id,
              'team_name' => $this->task->team->name,
              'created_at' => now()->toIso8601String(),
          ]);
      }
      
      /**
       * Get the Pushover representation of the notification.
       */
      public function toPushover(object $notifiable): array
      {
          $url = url("/tasks/{$this->task->id}");
          
          return [
              'title' => "Task Assigned: {$this->task->title}",
              'message' => "You have been assigned a new task with {$this->task->priority} priority.",
              'url' => $url,
              'url_title' => 'View Task',
              'priority' => $this->getPushoverPriority(),
          ];
      }
      
      /**
       * Map task priority to Pushover priority.
       */
      protected function getPushoverPriority(): int
      {
          return match ($this->task->priority) {
              'high' => 1,
              'medium' => 0,
              'low' => -1,
              default => 0,
          };
      }
      
      /**
       * Get the array representation of the notification.
       *
       * @return array<string, mixed>
       */
      public function toArray(object $notifiable): array
      {
          return [
              'task_id' => $this->task->id,
              'task_title' => $this->task->title,
              'priority' => $this->task->priority,
              'due_date' => $this->task->due_date?->format('Y-m-d'),
              'assigned_by' => $this->task->assignedBy?->name ?? 'System',
              'team_id' => $this->task->team_id,
              'team_name' => $this->task->team->name,
          ];
      }
  }
  
  namespace App\Models;
  
  use Illuminate\Database\Eloquent\Model;
  use Illuminate\Database\Eloquent\Relations\BelongsTo;
  
  class NotificationPreference extends Model
  {
      protected $fillable = [
          'user_id',
          'notification_type',
          'database_enabled',
          'broadcast_enabled',
          'mail_enabled',
          'push_enabled',
          'sms_enabled',
          'quiet_hours_enabled',
          'quiet_hours_start',
          'quiet_hours_end',
      ];
      
      protected $casts = [
          'database_enabled' => 'boolean',
          'broadcast_enabled' => 'boolean',
          'mail_enabled' => 'boolean',
          'push_enabled' => 'boolean',
          'sms_enabled' => 'boolean',
          'quiet_hours_enabled' => 'boolean',
          'quiet_hours_start' => 'datetime',
          'quiet_hours_end' => 'datetime',
      ];
      
      /**
       * Get the user that owns the notification preference.
       */
      public function user(): BelongsTo
      {
          return $this->belongsTo(User::class);
      }
      
      /**
       * Check if quiet hours are currently active.
       */
      public function isInQuietHours(): bool
      {
          if (!$this->quiet_hours_enabled) {
              return false;
          }
          
          $now = now();
          $start = $this->quiet_hours_start;
          $end = $this->quiet_hours_end;
          
          // Handle case where quiet hours span midnight
          if ($start > $end) {
              return $now >= $start || $now <= $end;
          }
          
          return $now >= $start && $now <= $end;
      }
      
      /**
       * Get available notification types.
       */
      public static function getNotificationTypes(): array
      {
          return [
              'task_assigned' => 'Task Assigned',
              'task_completed' => 'Task Completed',
              'task_due_soon' => 'Task Due Soon',
              'task_overdue' => 'Task Overdue',
              'comment_added' => 'Comment Added',
              'team_invitation' => 'Team Invitation',
              'team_member_joined' => 'Team Member Joined',
              'team_member_left' => 'Team Member Left',
          ];
      }
  }
  
  namespace App\Models;
  
  use Illuminate\Database\Eloquent\Relations\HasMany;
  use Illuminate\Foundation\Auth\User as Authenticatable;
  use Illuminate\Notifications\Notifiable;
  
  class User extends Authenticatable
  {
      use Notifiable;
      
      // ... other User model code ...
      
      /**
       * Get the notification preferences for the user.
       */
      public function notificationPreferences(): HasMany
      {
          return $this->hasMany(NotificationPreference::class);
      }
      
      /**
       * Get the user's preferred notification channels for a specific notification type.
       */
      public function getNotificationChannels(string $notificationType): array
      {
          $preference = $this->notificationPreferences()
              ->where('notification_type', $notificationType)
              ->first();
          
          if (!$preference) {
              // Default channels if no preference is set
              return ['database', 'broadcast', 'mail'];
          }
          
          // Check if quiet hours are active
          if ($preference->isInQuietHours()) {
              // During quiet hours, only use database and broadcast
              return ['database', 'broadcast'];
          }
          
          $channels = [];
          
          if ($preference->database_enabled) {
              $channels[] = 'database';
          }
          
          if ($preference->broadcast_enabled) {
              $channels[] = 'broadcast';
          }
          
          if ($preference->mail_enabled) {
              $channels[] = 'mail';
          }
          
          if ($preference->push_enabled) {
              $channels[] = 'pushover';
          }
          
          if ($preference->sms_enabled) {
              $channels[] = 'vonage';
          }
          
          return $channels;
      }
      
      /**
       * Route notifications for the Pushover channel.
       */
      public function routeNotificationForPushover()
      {
          return $this->pushover_key;
      }
      
      /**
       * Route notifications for the Vonage channel.
       */
      public function routeNotificationForVonage()
      {
          return $this->phone_number;
      }
  }
  
  namespace App\Http\Controllers;
  
  use App\Models\NotificationPreference;
  use Illuminate\Http\Request;
  use Illuminate\Support\Facades\Auth;
  
  class NotificationPreferenceController extends Controller
  {
      /**
       * Display the user's notification preferences.
       */
      public function index()
      {
          $user = Auth::user();
          $preferences = $user->notificationPreferences;
          $notificationTypes = NotificationPreference::getNotificationTypes();
          
          // Create default preferences for any missing notification types
          foreach ($notificationTypes as $type => $label) {
              if (!$preferences->contains('notification_type', $type)) {
                  $preference = new NotificationPreference([
                      'user_id' => $user->id,
                      'notification_type' => $type,
                      'database_enabled' => true,
                      'broadcast_enabled' => true,
                      'mail_enabled' => true,
                      'push_enabled' => false,
                      'sms_enabled' => false,
                      'quiet_hours_enabled' => false,
                  ]);
                  
                  $preference->save();
                  $preferences->push($preference);
              }
          }
          
          return view('notifications.preferences', [
              'preferences' => $preferences,
              'notificationTypes' => $notificationTypes,
          ]);
      }
      
      /**
       * Update the user's notification preferences.
       */
      public function update(Request $request)
      {
          $user = Auth::user();
          
          $request->validate([
              'preferences' => 'required|array',
              'preferences.*.notification_type' => 'required|string',
              'preferences.*.database_enabled' => 'boolean',
              'preferences.*.broadcast_enabled' => 'boolean',
              'preferences.*.mail_enabled' => 'boolean',
              'preferences.*.push_enabled' => 'boolean',
              'preferences.*.sms_enabled' => 'boolean',
              'preferences.*.quiet_hours_enabled' => 'boolean',
              'preferences.*.quiet_hours_start' => 'nullable|date_format:H:i',
              'preferences.*.quiet_hours_end' => 'nullable|date_format:H:i',
          ]);
          
          foreach ($request->input('preferences') as $data) {
              $preference = $user->notificationPreferences()
                  ->where('notification_type', $data['notification_type'])
                  ->first();
              
              if (!$preference) {
                  $preference = new NotificationPreference([
                      'user_id' => $user->id,
                      'notification_type' => $data['notification_type'],
                  ]);
              }
              
              $preference->database_enabled = $data['database_enabled'] ?? false;
              $preference->broadcast_enabled = $data['broadcast_enabled'] ?? false;
              $preference->mail_enabled = $data['mail_enabled'] ?? false;
              $preference->push_enabled = $data['push_enabled'] ?? false;
              $preference->sms_enabled = $data['sms_enabled'] ?? false;
              $preference->quiet_hours_enabled = $data['quiet_hours_enabled'] ?? false;
              
              if (isset($data['quiet_hours_start']) && isset($data['quiet_hours_end'])) {
                  $preference->quiet_hours_start = $data['quiet_hours_start'];
                  $preference->quiet_hours_end = $data['quiet_hours_end'];
              }
              
              $preference->save();
          }
          
          return redirect()->route('notification.preferences')
              ->with('success', 'Notification preferences updated successfully.');
      }
      
      /**
       * Mark all notifications as read.
       */
      public function markAllAsRead()
      {
          $user = Auth::user();
          $user->unreadNotifications->markAsRead();
          
          return redirect()->back()
              ->with('success', 'All notifications marked as read.');
      }
      
      /**
       * Mark a specific notification as read.
       */
      public function markAsRead(Request $request, string $id)
      {
          $user = Auth::user();
          $notification = $user->notifications()->findOrFail($id);
          $notification->markAsRead();
          
          return redirect()->back()
              ->with('success', 'Notification marked as read.');
      }
  }
  
  namespace App\Console\Commands;
  
  use App\Models\Task;
  use App\Notifications\TaskDueSoon;
  use Illuminate\Console\Command;
  
  class SendTaskReminders extends Command
  {
      /**
       * The name and signature of the console command.
       *
       * @var string
       */
      protected $signature = 'notifications:task-reminders';
      
      /**
       * The console command description.
       *
       * @var string
       */
      protected $description = 'Send reminders for tasks that are due soon';
      
      /**
       * Execute the console command.
       */
      public function handle()
      {
          // Find tasks due in the next 24 hours that haven't had a reminder sent
          $tasks = Task::where('due_date', '>=', now())
              ->where('due_date', '<=', now()->addHours(24))
              ->where('reminder_sent', false)
              ->whereNotNull('assigned_to')
              ->get();
          
          $count = 0;
          
          foreach ($tasks as $task) {
              $user = $task->assignedTo;
              
              if ($user) {
                  $user->notify(new TaskDueSoon($task));
                  
                  // Mark reminder as sent
                  $task->reminder_sent = true;
                  $task->save();
                  
                  $count++;
              }
          }
          
          $this->info("Sent {$count} task reminders.");
          
          return Command::SUCCESS;
      }
  }
  
  namespace App\Channels;
  
  use Illuminate\Notifications\Notification;
  use Illuminate\Support\Facades\Http;
  
  class PushoverChannel
  {
      /**
       * Send the given notification.
       *
       * @param  mixed  $notifiable
       * @param  \Illuminate\Notifications\Notification  $notification
       * @return void
       */
      public function send($notifiable, Notification $notification)
      {
          if (!method_exists($notification, 'toPushover')) {
              throw new \Exception('Notification does not have toPushover method.');
          }
          
          $pushoverKey = $notifiable->routeNotificationForPushover();
          
          if (!$pushoverKey) {
              return;
          }
          
          $message = $notification->toPushover($notifiable);
          
          Http::post('https://api.pushover.net/1/messages.json', [
              'token' => config('services.pushover.token'),
              'user' => $pushoverKey,
              'title' => $message['title'],
              'message' => $message['message'],
              'url' => $message['url'] ?? null,
              'url_title' => $message['url_title'] ?? null,
              'priority' => $message['priority'] ?? 0,
              'sound' => $message['sound'] ?? 'pushover',
          ]);
      }
  }
  
  // Example client-side JavaScript for real-time notifications
  
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
  
  // Notification component
  class NotificationManager {
      constructor() {
          this.notificationsList = document.getElementById('notifications-list');
          this.notificationBadge = document.getElementById('notification-badge');
          this.notificationCount = 0;
          
          this.setupEventListeners();
      }
      
      setupEventListeners() {
          // Listen for notifications
          window.Echo.private(`App.Models.User.${userId}`)
              .notification((notification) => {
                  this.handleNewNotification(notification);
              });
          
          // Mark as read button
          document.addEventListener('click', (e) => {
              if (e.target.classList.contains('mark-as-read')) {
                  e.preventDefault();
                  const id = e.target.dataset.id;
                  this.markAsRead(id);
              }
          });
          
          // Mark all as read button
          const markAllAsReadButton = document.getElementById('mark-all-as-read');
          if (markAllAsReadButton) {
              markAllAsReadButton.addEventListener('click', (e) => {
                  e.preventDefault();
                  this.markAllAsRead();
              });
          }
      }
      
      handleNewNotification(notification) {
          // Add notification to list
          this.addNotification(notification);
          
          // Update count
          this.notificationCount++;
          this.updateBadge();
          
          // Show browser notification if supported
          this.showBrowserNotification(notification);
          
          // Play sound
          this.playNotificationSound();
      }
      
      addNotification(notification) {
          // Create notification element
          const element = document.createElement('div');
          element.className = 'notification-item unread';
          element.dataset.id = notification.id;
          
          // Set content based on notification type
          let content = '';
          
          switch (notification.type) {
              case 'task_assigned':
                  content = `
                      <div class="notification-icon">
                          <i class="fas fa-tasks"></i>
                      </div>
                      <div class="notification-content">
                          <div class="notification-title">Task Assigned: ${notification.task_title}</div>
                          <div class="notification-meta">
                              <span class="priority priority-${notification.priority}">${notification.priority}</span>
                              ${notification.due_date ? `<span class="due-date">Due: ${notification.due_date}</span>` : ''}
                          </div>
                          <div class="notification-actions">
                              <a href="/.ai/tasks/${notification.task_id}" class="btn btn-sm btn-primary">View Task</a>
                              <button class="btn btn-sm btn-secondary mark-as-read" data-id="${notification.id}">Mark as Read</button>
                          </div>
                      </div>
                  `;
                  break;
                  
              // Handle other notification types...
              
              default:
                  content = `
                      <div class="notification-icon">
                          <i class="fas fa-bell"></i>
                      </div>
                      <div class="notification-content">
                          <div class="notification-title">${notification.type}</div>
                          <div class="notification-actions">
                              <button class="btn btn-sm btn-secondary mark-as-read" data-id="${notification.id}">Mark as Read</button>
                          </div>
                      </div>
                  `;
          }
          
          element.innerHTML = content;
          
          // Add to list
          this.notificationsList.prepend(element);
      }
      
      updateBadge() {
          if (this.notificationCount > 0) {
              this.notificationBadge.textContent = this.notificationCount;
              this.notificationBadge.classList.remove('hidden');
          } else {
              this.notificationBadge.classList.add('hidden');
          }
      }
      
      showBrowserNotification(notification) {
          if (!('Notification' in window)) {
              return;
          }
          
          if (Notification.permission === 'granted') {
              let title, body, icon;
              
              switch (notification.type) {
                  case 'task_assigned':
                      title = `Task Assigned: ${notification.task_title}`;
                      body = `Priority: ${notification.priority}${notification.due_date ? `, Due: ${notification.due_date}` : ''}`;
                      icon = '/images/task-icon.png';
                      break;
                      
                  // Handle other notification types...
                  
                  default:
                      title = 'New Notification';
                      body = 'You have a new notification';
                      icon = '/images/notification-icon.png';
              }
              
              const browserNotification = new Notification(title, {
                  body: body,
                  icon: icon
              });
              
              browserNotification.onclick = function() {
                  window.focus();
                  
                  if (notification.task_id) {
                      window.location.href = `/tasks/${notification.task_id}`;
                  }
              };
          } else if (Notification.permission !== 'denied') {
              Notification.requestPermission();
          }
      }
      
      playNotificationSound() {
          const audio = new Audio('/sounds/notification.mp3');
          audio.play();
      }
      
      markAsRead(id) {
          fetch(`/notifications/${id}/read`, {
              method: 'POST',
              headers: {
                  'Content-Type': 'application/json',
                  'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
              }
          })
          .then(response => response.json())
          .then(data => {
              // Update UI
              const element = document.querySelector(`.notification-item[data-id="${id}"]`);
              if (element) {
                  element.classList.remove('unread');
                  element.classList.add('read');
                  
                  // Update count
                  this.notificationCount = Math.max(0, this.notificationCount - 1);
                  this.updateBadge();
              }
          });
      }
      
      markAllAsRead() {
          fetch('/notifications/mark-all-as-read', {
              method: 'POST',
              headers: {
                  'Content-Type': 'application/json',
                  'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
              }
          })
          .then(response => response.json())
          .then(data => {
              // Update UI
              const elements = document.querySelectorAll('.notification-item.unread');
              elements.forEach(element => {
                  element.classList.remove('unread');
                  element.classList.add('read');
              });
              
              // Reset count
              this.notificationCount = 0;
              this.updateBadge();
          });
      }
  }
  
  // Initialize notification manager
  const notificationManager = new NotificationManager();
  
  // Request browser notification permission
  if ('Notification' in window && Notification.permission !== 'granted' && Notification.permission !== 'denied') {
      document.getElementById('enable-notifications').addEventListener('click', () => {
          Notification.requestPermission();
      });
  }
  */
explanation: |
  This example demonstrates a comprehensive notifications system:
  
  1. **Notification Classes**: Creating custom notification classes:
     - Defining notification content for different channels
     - Customizing notification delivery based on user preferences
     - Supporting multiple delivery channels (database, broadcast, mail, push, SMS)
  
  2. **Notification Preferences**: Allowing users to customize their notification experience:
     - Enabling/disabling specific channels for each notification type
     - Setting quiet hours to limit notifications during certain times
     - Storing preferences in a dedicated database table
  
  3. **Custom Channels**: Extending Laravel's notification system with custom channels:
     - Implementing a Pushover channel for push notifications
     - Supporting priority levels for different notification types
     - Routing notifications to the appropriate destination
  
  4. **Real-Time Notifications**: Using Laravel Reverb for real-time notifications:
     - Broadcasting notifications to private user channels
     - Handling notifications in the browser with JavaScript
     - Showing browser notifications and playing sounds
  
  5. **Notification Management**: Providing endpoints to manage notifications:
     - Viewing notification preferences
     - Updating notification preferences
     - Marking notifications as read
  
  6. **Scheduled Notifications**: Using scheduled commands for time-based notifications:
     - Sending reminders for tasks due soon
     - Tracking which notifications have been sent
  
  Key features of the implementation:
  
  - **Multiple Channels**: Supporting database, broadcast, mail, push, and SMS channels
  - **User Preferences**: Allowing users to customize their notification experience
  - **Quiet Hours**: Respecting users' quiet hours for non-urgent notifications
  - **Real-Time Updates**: Delivering notifications in real-time using WebSockets
  - **Browser Notifications**: Using the Web Notifications API for desktop notifications
  - **Sound Alerts**: Playing sounds when notifications are received
  - **Mark as Read**: Allowing users to mark notifications as read
  
  In a real Laravel application:
  - You would implement more notification types for different events
  - You would add more sophisticated notification grouping and batching
  - You would implement notification analytics to track engagement
  - You would add support for more delivery channels (e.g., Slack, Discord)
  - You would implement notification templates for consistent styling
challenges:
  - Implement notification batching to group similar notifications
  - Add support for notification digests (daily/weekly summaries)
  - Create a notification center with filtering and searching
  - Implement notification templates with customizable themes
  - Add support for notification actions that can be performed directly from the notification
:::
