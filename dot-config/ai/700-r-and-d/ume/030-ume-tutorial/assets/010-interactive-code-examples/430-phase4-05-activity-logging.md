# Activity Logging

:::interactive-code
title: Implementing Real-time Activity Logging
description: This example demonstrates how to implement a comprehensive activity logging system with real-time updates using Laravel Reverb.
language: php
editable: true
code: |
  <?php
  
  namespace App\Models;
  
  use Illuminate\Database\Eloquent\Model;
  use Illuminate\Database\Eloquent\Relations\BelongsTo;
  use Illuminate\Database\Eloquent\Relations\MorphTo;
  
  class Activity extends Model
  {
      protected $fillable = [
          'user_id',
          'subject_type',
          'subject_id',
          'action',
          'description',
          'properties',
          'ip_address',
          'user_agent',
      ];
      
      protected $casts = [
          'properties' => 'array',
      ];
      
      /**
       * Get the user that performed the activity.
       */
      public function user(): BelongsTo
      {
          return $this->belongsTo(User::class);
      }
      
      /**
       * Get the subject of the activity.
       */
      public function subject(): MorphTo
      {
          return $this->morphTo();
      }
      
      /**
       * Scope a query to only include activities for a specific subject.
       */
      public function scopeForSubject($query, $subject)
      {
          return $query->where('subject_type', get_class($subject))
              ->where('subject_id', $subject->getKey());
      }
      
      /**
       * Scope a query to only include activities by a specific user.
       */
      public function scopeByUser($query, $user)
      {
          return $query->where('user_id', $user->getKey());
      }
      
      /**
       * Scope a query to only include activities with a specific action.
       */
      public function scopeWithAction($query, $action)
      {
          return $query->where('action', $action);
      }
      
      /**
       * Get a human-readable description of the activity.
       */
      public function getHumanReadableDescription(): string
      {
          $userName = $this->user ? $this->user->name : 'Unknown user';
          
          return match ($this->action) {
              'created' => "{$userName} created this {$this->getSubjectType()}",
              'updated' => "{$userName} updated this {$this->getSubjectType()}",
              'deleted' => "{$userName} deleted this {$this->getSubjectType()}",
              'restored' => "{$userName} restored this {$this->getSubjectType()}",
              'commented' => "{$userName} commented on this {$this->getSubjectType()}",
              'assigned' => "{$userName} assigned this {$this->getSubjectType()} to {$this->properties['assigned_to'] ?? 'someone'}",
              'completed' => "{$userName} marked this {$this->getSubjectType()} as completed",
              'reopened' => "{$userName} reopened this {$this->getSubjectType()}",
              default => $this->description ?: "{$userName} performed {$this->action} on this {$this->getSubjectType()}",
          };
      }
      
      /**
       * Get a human-readable subject type.
       */
      protected function getSubjectType(): string
      {
          return strtolower(class_basename($this->subject_type));
      }
  }
  
  namespace App\Services;
  
  use App\Events\ActivityLogged;
  use App\Models\Activity;
  use Illuminate\Database\Eloquent\Model;
  use Illuminate\Support\Facades\Auth;
  use Illuminate\Support\Facades\Request;
  
  class ActivityLogger
  {
      /**
       * Log an activity.
       *
       * @param string $action
       * @param Model $subject
       * @param array $properties
       * @param string|null $description
       * @return Activity
       */
      public function log(
          string $action,
          Model $subject,
          array $properties = [],
          ?string $description = null
      ): Activity {
          $user = Auth::user();
          
          $activity = Activity::create([
              'user_id' => $user ? $user->getKey() : null,
              'subject_type' => get_class($subject),
              'subject_id' => $subject->getKey(),
              'action' => $action,
              'description' => $description,
              'properties' => $properties,
              'ip_address' => Request::ip(),
              'user_agent' => Request::userAgent(),
          ]);
          
          // Broadcast the activity
          broadcast(new ActivityLogged($activity))->toOthers();
          
          return $activity;
      }
      
      /**
       * Log a created activity.
       *
       * @param Model $subject
       * @param array $properties
       * @return Activity
       */
      public function logCreated(Model $subject, array $properties = []): Activity
      {
          return $this->log('created', $subject, $properties);
      }
      
      /**
       * Log an updated activity.
       *
       * @param Model $subject
       * @param array $properties
       * @return Activity
       */
      public function logUpdated(Model $subject, array $properties = []): Activity
      {
          return $this->log('updated', $subject, $properties);
      }
      
      /**
       * Log a deleted activity.
       *
       * @param Model $subject
       * @param array $properties
       * @return Activity
       */
      public function logDeleted(Model $subject, array $properties = []): Activity
      {
          return $this->log('deleted', $subject, $properties);
      }
      
      /**
       * Log a custom activity.
       *
       * @param string $action
       * @param Model $subject
       * @param array $properties
       * @param string|null $description
       * @return Activity
       */
      public function logCustom(
          string $action,
          Model $subject,
          array $properties = [],
          ?string $description = null
      ): Activity {
          return $this->log($action, $subject, $properties, $description);
      }
  }
  
  namespace App\Traits;
  
  use App\Services\ActivityLogger;
  use Illuminate\Database\Eloquent\Model;
  use Illuminate\Database\Eloquent\Relations\MorphMany;
  use Illuminate\Support\Facades\App;
  
  trait LogsActivity
  {
      /**
       * Boot the trait.
       *
       * @return void
       */
      public static function bootLogsActivity()
      {
          static::created(function (Model $model) {
              $model->logActivity('created');
          });
          
          static::updated(function (Model $model) {
              // Only log if actual attributes (not timestamps) were changed
              if ($model->isDirty($model->getActivityLogAttributes())) {
                  $model->logActivity('updated', [
                      'old' => $model->getOriginal($model->getActivityLogAttributes()),
                      'new' => $model->getAttributes($model->getActivityLogAttributes()),
                      'changed' => $model->getChanges($model->getActivityLogAttributes()),
                  ]);
              }
          });
          
          static::deleted(function (Model $model) {
              $model->logActivity('deleted');
          });
          
          if (method_exists(static::class, 'restored')) {
              static::restored(function (Model $model) {
                  $model->logActivity('restored');
              });
          }
      }
      
      /**
       * Get the activity logger instance.
       *
       * @return ActivityLogger
       */
      protected function getActivityLogger(): ActivityLogger
      {
          return App::make(ActivityLogger::class);
      }
      
      /**
       * Log an activity for this model.
       *
       * @param string $action
       * @param array $properties
       * @param string|null $description
       * @return \App\Models\Activity
       */
      public function logActivity(string $action, array $properties = [], ?string $description = null)
      {
          return $this->getActivityLogger()->log($action, $this, $properties, $description);
      }
      
      /**
       * Get the activities relationship.
       *
       * @return MorphMany
       */
      public function activities(): MorphMany
      {
          return $this->morphMany(\App\Models\Activity::class, 'subject');
      }
      
      /**
       * Get the attributes to log.
       *
       * @return array
       */
      public function getActivityLogAttributes(): array
      {
          return property_exists($this, 'activityLogAttributes')
              ? $this->activityLogAttributes
              : $this->getFillable();
      }
      
      /**
       * Exclude specific attributes from being logged.
       *
       * @return array
       */
      public function getActivityLogExcludedAttributes(): array
      {
          return property_exists($this, 'activityLogExcludedAttributes')
              ? $this->activityLogExcludedAttributes
              : ['password', 'remember_token'];
      }
  }
  
  namespace App\Models;
  
  use App\Traits\LogsActivity;
  use Illuminate\Database\Eloquent\Model;
  
  class Task extends Model
  {
      use LogsActivity;
      
      protected $fillable = [
          'title',
          'description',
          'status',
          'due_date',
          'assigned_to',
          'team_id',
      ];
      
      protected $activityLogAttributes = [
          'title',
          'description',
          'status',
          'due_date',
          'assigned_to',
      ];
      
      /**
       * Get the team that owns the task.
       */
      public function team()
      {
          return $this->belongsTo(Team::class);
      }
      
      /**
       * Get the user that the task is assigned to.
       */
      public function assignedTo()
      {
          return $this->belongsTo(User::class, 'assigned_to');
      }
      
      /**
       * Mark the task as completed.
       *
       * @return $this
       */
      public function complete()
      {
          $this->status = 'completed';
          $this->save();
          
          // Log a custom activity
          $this->logActivity('completed', [
              'completed_at' => now()->toIso8601String(),
          ]);
          
          return $this;
      }
      
      /**
       * Reopen the task.
       *
       * @return $this
       */
      public function reopen()
      {
          $this->status = 'in_progress';
          $this->save();
          
          // Log a custom activity
          $this->logActivity('reopened', [
              'reopened_at' => now()->toIso8601String(),
          ]);
          
          return $this;
      }
      
      /**
       * Assign the task to a user.
       *
       * @param User $user
       * @return $this
       */
      public function assignTo(User $user)
      {
          $oldAssignee = $this->assigned_to;
          $this->assigned_to = $user->id;
          $this->save();
          
          // Log a custom activity
          $this->logActivity('assigned', [
              'assigned_to' => $user->name,
              'assigned_to_id' => $user->id,
              'previous_assignee_id' => $oldAssignee,
          ]);
          
          return $this;
      }
  }
  
  namespace App\Events;
  
  use App\Models\Activity;
  use Illuminate\Broadcasting\Channel;
  use Illuminate\Broadcasting\InteractsWithSockets;
  use Illuminate\Broadcasting\PresenceChannel;
  use Illuminate\Broadcasting\PrivateChannel;
  use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
  use Illuminate\Foundation\Events\Dispatchable;
  use Illuminate\Queue\SerializesModels;
  
  class ActivityLogged implements ShouldBroadcast
  {
      use Dispatchable, InteractsWithSockets, SerializesModels;
      
      /**
       * Create a new event instance.
       */
      public function __construct(public Activity $activity)
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
          $channels = [
              new PrivateChannel("activity.{$this->activity->subject_type}.{$this->activity->subject_id}"),
          ];
          
          // If the subject belongs to a team, also broadcast to the team channel
          if (method_exists($this->activity->subject, 'team') && $this->activity->subject->team) {
              $channels[] = new PrivateChannel("team.{$this->activity->subject->team->id}.activity");
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
              'id' => $this->activity->id,
              'user_id' => $this->activity->user_id,
              'user_name' => $this->activity->user ? $this->activity->user->name : null,
              'subject_type' => $this->activity->subject_type,
              'subject_id' => $this->activity->subject_id,
              'action' => $this->activity->action,
              'description' => $this->activity->getHumanReadableDescription(),
              'properties' => $this->activity->properties,
              'created_at' => $this->activity->created_at->toIso8601String(),
          ];
      }
      
      /**
       * The event's broadcast name.
       */
      public function broadcastAs(): string
      {
          return 'activity.logged';
      }
  }
  
  namespace App\Http\Controllers;
  
  use App\Models\Activity;
  use App\Models\Task;
  use App\Models\Team;
  use Illuminate\Http\Request;
  use Illuminate\Support\Facades\Auth;
  
  class ActivityController extends Controller
  {
      /**
       * Get activities for a specific subject.
       */
      public function getSubjectActivities(Request $request, string $subjectType, int $subjectId)
      {
          // Map subject type to model class
          $modelMap = [
              'task' => Task::class,
              'team' => Team::class,
              // Add more mappings as needed
          ];
          
          if (!isset($modelMap[$subjectType])) {
              return response()->json(['error' => 'Invalid subject type'], 400);
          }
          
          $modelClass = $modelMap[$subjectType];
          $subject = $modelClass::findOrFail($subjectId);
          
          // Check if user has access to the subject
          if ($subjectType === 'task' && !$subject->team->hasMember(Auth::user())) {
              return response()->json(['error' => 'Unauthorized'], 403);
          }
          
          if ($subjectType === 'team' && !$subject->hasMember(Auth::user())) {
              return response()->json(['error' => 'Unauthorized'], 403);
          }
          
          $activities = Activity::forSubject($subject)
              ->with('user:id,name')
              ->latest()
              ->paginate(20);
          
          return response()->json($activities);
      }
      
      /**
       * Get activities for a team.
       */
      public function getTeamActivities(Request $request, Team $team)
      {
          // Check if user is a member of the team
          if (!$team->hasMember(Auth::user())) {
              return response()->json(['error' => 'Unauthorized'], 403);
          }
          
          // Get activities for all tasks in the team
          $activities = Activity::whereHasMorph('subject', [Task::class], function ($query) use ($team) {
              $query->where('team_id', $team->id);
          })
          ->with('user:id,name')
          ->latest()
          ->paginate(20);
          
          return response()->json($activities);
      }
      
      /**
       * Get activities for the authenticated user.
       */
      public function getUserActivities(Request $request)
      {
          $activities = Activity::byUser(Auth::user())
              ->with('user:id,name')
              ->latest()
              ->paginate(20);
          
          return response()->json($activities);
      }
  }
  
  // Example client-side JavaScript for activity feed
  
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
  
  // Activity feed component
  class ActivityFeed {
      constructor(subjectType, subjectId) {
          this.subjectType = subjectType;
          this.subjectId = subjectId;
          this.activities = [];
          
          this.setupEventListeners();
          this.loadActivities();
      }
      
      setupEventListeners() {
          // Listen for new activities
          window.Echo.private(`activity.${this.subjectType}.${this.subjectId}`)
              .listen('.activity.logged', (e) => {
                  this.addActivity(e);
              });
      }
      
      loadActivities() {
          fetch(`/api/activities/${this.subjectType}/${this.subjectId}`)
              .then(response => response.json())
              .then(data => {
                  this.activities = data.data;
                  this.renderActivities();
              });
      }
      
      addActivity(activity) {
          this.activities.unshift(activity);
          this.renderActivities();
      }
      
      renderActivities() {
          const container = document.getElementById('activity-feed');
          
          let html = '';
          this.activities.forEach(activity => {
              const date = new Date(activity.created_at).toLocaleString();
              
              html += `
                  <div class="activity-item">
                      <div class="activity-icon activity-${activity.action}"></div>
                      <div class="activity-content">
                          <div class="activity-description">${activity.description}</div>
                          <div class="activity-meta">
                              <span class="activity-time">${date}</span>
                          </div>
                      </div>
                  </div>
              `;
          });
          
          container.innerHTML = html;
      }
  }
  
  // Initialize activity feed
  const activityFeed = new ActivityFeed('task', taskId);
  */
explanation: |
  This example demonstrates a comprehensive activity logging system with real-time updates:
  
  1. **Activity Model**: A central model that stores all activity data:
     - Who performed the action (user)
     - What was affected (subject)
     - What action was performed
     - Additional properties and context
  
  2. **ActivityLogger Service**: A service that handles logging activities:
     - Creating activity records
     - Broadcasting activities in real-time
     - Providing convenience methods for common actions
  
  3. **LogsActivity Trait**: A reusable trait that can be added to any model:
     - Automatically logs created, updated, and deleted events
     - Allows customizing which attributes are logged
     - Provides methods for logging custom activities
  
  4. **Real-Time Broadcasting**: Using Laravel Reverb to broadcast activities:
     - Broadcasting to subject-specific channels
     - Broadcasting to team channels for team-wide activities
     - Customizing the broadcast data
  
  5. **API Endpoints**: Providing endpoints to retrieve activities:
     - Get activities for a specific subject
     - Get activities for a team
     - Get activities for the current user
  
  6. **Client-Side Implementation**: Using Laravel Echo to receive real-time updates:
     - Subscribing to activity channels
     - Adding new activities to the feed in real-time
     - Rendering the activity feed
  
  Key features of the implementation:
  
  - **Polymorphic Relationships**: Activities can be related to any model type
  - **Attribute Tracking**: Tracking which attributes changed during updates
  - **Custom Activities**: Support for logging custom actions beyond CRUD
  - **Human-Readable Descriptions**: Generating readable descriptions of activities
  - **Contextual Information**: Storing IP address and user agent for audit purposes
  - **Real-Time Updates**: Broadcasting activities as they happen
  
  In a real Laravel application:
  - You would implement more sophisticated access control
  - You might add activity aggregation for high-volume activities
  - You would implement activity cleanup for old records
  - You would add more detailed activity visualization
  - You would implement activity notifications
challenges:
  - Implement activity aggregation (e.g., "User edited this task 5 times today")
  - Add support for activity comments (allowing users to comment on activities)
  - Create a notification system that alerts users about relevant activities
  - Implement activity filtering and searching
  - Add support for undoing actions based on activity records
:::
