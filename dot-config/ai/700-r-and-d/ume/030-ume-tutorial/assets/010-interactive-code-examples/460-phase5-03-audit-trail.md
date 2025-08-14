# Audit Trail Implementation

:::interactive-code
title: Implementing a Comprehensive Audit Trail System
description: This example demonstrates how to implement a robust audit trail system to track all changes to models, with support for viewing, filtering, and exporting audit logs.
language: php
editable: true
code: |
  <?php
  
  namespace App\Models;
  
  use Illuminate\Database\Eloquent\Model;
  use Illuminate\Database\Eloquent\Relations\BelongsTo;
  use Illuminate\Database\Eloquent\Relations\MorphTo;
  
  class AuditLog extends Model
  {
      protected $fillable = [
          'user_id',
          'action',
          'auditable_type',
          'auditable_id',
          'old_values',
          'new_values',
          'ip_address',
          'user_agent',
          'tags',
      ];
      
      protected $casts = [
          'old_values' => 'array',
          'new_values' => 'array',
          'tags' => 'array',
      ];
      
      /**
       * Get the user that performed the action.
       */
      public function user(): BelongsTo
      {
          return $this->belongsTo(User::class);
      }
      
      /**
       * Get the auditable model.
       */
      public function auditable(): MorphTo
      {
          return $this->morphTo();
      }
      
      /**
       * Scope a query to only include logs for a specific auditable model.
       */
      public function scopeForAuditable($query, $auditable)
      {
          return $query->where('auditable_type', get_class($auditable))
              ->where('auditable_id', $auditable->getKey());
      }
      
      /**
       * Scope a query to only include logs by a specific user.
       */
      public function scopeByUser($query, $user)
      {
          return $query->where('user_id', $user->getKey());
      }
      
      /**
       * Scope a query to only include logs with a specific action.
       */
      public function scopeWithAction($query, $action)
      {
          return $query->where('action', $action);
      }
      
      /**
       * Scope a query to only include logs with specific tags.
       */
      public function scopeWithTags($query, array $tags)
      {
          foreach ($tags as $tag) {
              $query->whereJsonContains('tags', $tag);
          }
          
          return $query;
      }
      
      /**
       * Scope a query to only include logs within a date range.
       */
      public function scopeWithinDateRange($query, $startDate, $endDate)
      {
          return $query->whereBetween('created_at', [$startDate, $endDate]);
      }
      
      /**
       * Get a human-readable description of the audit log.
       */
      public function getDescription(): string
      {
          $userName = $this->user ? $this->user->name : 'System';
          $modelType = class_basename($this->auditable_type);
          
          return match ($this->action) {
              'created' => "{$userName} created a new {$modelType}",
              'updated' => "{$userName} updated a {$modelType}",
              'deleted' => "{$userName} deleted a {$modelType}",
              'restored' => "{$userName} restored a {$modelType}",
              'login' => "{$userName} logged in",
              'logout' => "{$userName} logged out",
              'login_failed' => "Failed login attempt for {$this->old_values['email'] ?? 'unknown'}",
              default => "{$userName} performed {$this->action} on a {$modelType}",
          };
      }
      
      /**
       * Get the changes made in this audit log.
       */
      public function getChanges(): array
      {
          if ($this->action !== 'updated') {
              return [];
          }
          
          $changes = [];
          
          foreach ($this->new_values as $key => $newValue) {
              $oldValue = $this->old_values[$key] ?? null;
              
              if ($newValue !== $oldValue) {
                  $changes[$key] = [
                      'old' => $oldValue,
                      'new' => $newValue,
                  ];
              }
          }
          
          return $changes;
      }
  }
  
  namespace App\Services;
  
  use App\Models\AuditLog;
  use Illuminate\Database\Eloquent\Model;
  use Illuminate\Support\Facades\Auth;
  use Illuminate\Support\Facades\Request;
  
  class AuditService
  {
      /**
       * Log an audit event.
       *
       * @param string $action
       * @param Model|null $model
       * @param array $oldValues
       * @param array $newValues
       * @param array $tags
       * @return AuditLog
       */
      public function log(
          string $action,
          ?Model $model = null,
          array $oldValues = [],
          array $newValues = [],
          array $tags = []
      ): AuditLog {
          $user = Auth::user();
          
          $data = [
              'user_id' => $user ? $user->getKey() : null,
              'action' => $action,
              'old_values' => $oldValues,
              'new_values' => $newValues,
              'ip_address' => Request::ip(),
              'user_agent' => Request::userAgent(),
              'tags' => $tags,
          ];
          
          if ($model) {
              $data['auditable_type'] = get_class($model);
              $data['auditable_id'] = $model->getKey();
          }
          
          return AuditLog::create($data);
      }
      
      /**
       * Log a model creation event.
       *
       * @param Model $model
       * @param array $tags
       * @return AuditLog
       */
      public function logCreated(Model $model, array $tags = []): AuditLog
      {
          return $this->log(
              'created',
              $model,
              [],
              $this->getModelAttributes($model),
              $tags
          );
      }
      
      /**
       * Log a model update event.
       *
       * @param Model $model
       * @param array $oldValues
       * @param array $tags
       * @return AuditLog
       */
      public function logUpdated(Model $model, array $oldValues, array $tags = []): AuditLog
      {
          return $this->log(
              'updated',
              $model,
              $oldValues,
              $this->getModelAttributes($model),
              $tags
          );
      }
      
      /**
       * Log a model deletion event.
       *
       * @param Model $model
       * @param array $tags
       * @return AuditLog
       */
      public function logDeleted(Model $model, array $tags = []): AuditLog
      {
          return $this->log(
              'deleted',
              $model,
              $this->getModelAttributes($model),
              [],
              $tags
          );
      }
      
      /**
       * Log a model restoration event.
       *
       * @param Model $model
       * @param array $tags
       * @return AuditLog
       */
      public function logRestored(Model $model, array $tags = []): AuditLog
      {
          return $this->log(
              'restored',
              $model,
              [],
              $this->getModelAttributes($model),
              $tags
          );
      }
      
      /**
       * Log a user login event.
       *
       * @param User $user
       * @param array $tags
       * @return AuditLog
       */
      public function logLogin($user, array $tags = []): AuditLog
      {
          return $this->log(
              'login',
              $user,
              [],
              [
                  'id' => $user->id,
                  'email' => $user->email,
              ],
              $tags
          );
      }
      
      /**
       * Log a user logout event.
       *
       * @param User $user
       * @param array $tags
       * @return AuditLog
       */
      public function logLogout($user, array $tags = []): AuditLog
      {
          return $this->log(
              'logout',
              $user,
              [
                  'id' => $user->id,
                  'email' => $user->email,
              ],
              [],
              $tags
          );
      }
      
      /**
       * Log a failed login attempt.
       *
       * @param string $email
       * @param array $tags
       * @return AuditLog
       */
      public function logLoginFailed(string $email, array $tags = []): AuditLog
      {
          return $this->log(
              'login_failed',
              null,
              ['email' => $email],
              [],
              $tags
          );
      }
      
      /**
       * Get the attributes of a model.
       *
       * @param Model $model
       * @return array
       */
      protected function getModelAttributes(Model $model): array
      {
          $attributes = $model->getAttributes();
          
          // Remove any attributes that shouldn't be logged
          if (method_exists($model, 'getAuditExcludedAttributes')) {
              $excluded = $model->getAuditExcludedAttributes();
              foreach ($excluded as $attribute) {
                  unset($attributes[$attribute]);
              }
          } else {
              // Default excluded attributes
              unset($attributes['password'], $attributes['remember_token']);
          }
          
          return $attributes;
      }
  }
  
  namespace App\Traits;
  
  use App\Services\AuditService;
  use Illuminate\Database\Eloquent\Model;
  use Illuminate\Database\Eloquent\Relations\MorphMany;
  use Illuminate\Support\Facades\App;
  
  trait Auditable
  {
      /**
       * Boot the trait.
       *
       * @return void
       */
      public static function bootAuditable()
      {
          static::created(function (Model $model) {
              $model->auditCreated();
          });
          
          static::updated(function (Model $model) {
              $model->auditUpdated();
          });
          
          static::deleted(function (Model $model) {
              $model->auditDeleted();
          });
          
          if (method_exists(static::class, 'restored')) {
              static::restored(function (Model $model) {
                  $model->auditRestored();
              });
          }
      }
      
      /**
       * Get the audit service instance.
       *
       * @return AuditService
       */
      protected function getAuditService(): AuditService
      {
          return App::make(AuditService::class);
      }
      
      /**
       * Audit a created event.
       *
       * @return void
       */
      public function auditCreated()
      {
          $this->getAuditService()->logCreated($this, $this->getAuditTags());
      }
      
      /**
       * Audit an updated event.
       *
       * @return void
       */
      public function auditUpdated()
      {
          // Only audit if auditable attributes have changed
          if ($this->isDirty($this->getAuditableAttributes())) {
              $this->getAuditService()->logUpdated(
                  $this,
                  $this->getOriginal($this->getAuditableAttributes()),
                  $this->getAuditTags()
              );
          }
      }
      
      /**
       * Audit a deleted event.
       *
       * @return void
       */
      public function auditDeleted()
      {
          $this->getAuditService()->logDeleted($this, $this->getAuditTags());
      }
      
      /**
       * Audit a restored event.
       *
       * @return void
       */
      public function auditRestored()
      {
          $this->getAuditService()->logRestored($this, $this->getAuditTags());
      }
      
      /**
       * Get the audit logs relationship.
       *
       * @return MorphMany
       */
      public function auditLogs(): MorphMany
      {
          return $this->morphMany(AuditLog::class, 'auditable');
      }
      
      /**
       * Get the attributes to audit.
       *
       * @return array
       */
      public function getAuditableAttributes(): array
      {
          return property_exists($this, 'auditableAttributes')
              ? $this->auditableAttributes
              : $this->getFillable();
      }
      
      /**
       * Get the attributes to exclude from auditing.
       *
       * @return array
       */
      public function getAuditExcludedAttributes(): array
      {
          return property_exists($this, 'auditExcludedAttributes')
              ? $this->auditExcludedAttributes
              : ['password', 'remember_token'];
      }
      
      /**
       * Get tags for audit logs.
       *
       * @return array
       */
      public function getAuditTags(): array
      {
          return property_exists($this, 'auditTags')
              ? $this->auditTags
              : [];
      }
  }
  
  namespace App\Http\Controllers;
  
  use App\Exports\AuditLogExport;
  use App\Models\AuditLog;
  use Illuminate\Http\Request;
  use Illuminate\Support\Facades\Auth;
  use Maatwebsite\Excel\Facades\Excel;
  
  class AuditLogController extends Controller
  {
      /**
       * Display a listing of audit logs.
       */
      public function index(Request $request)
      {
          // Check permissions
          if (!Auth::user()->can('view audit logs')) {
              abort(403);
          }
          
          $query = AuditLog::with('user');
          
          // Apply filters
          if ($request->filled('user_id')) {
              $query->where('user_id', $request->input('user_id'));
          }
          
          if ($request->filled('action')) {
              $query->where('action', $request->input('action'));
          }
          
          if ($request->filled('auditable_type')) {
              $query->where('auditable_type', $request->input('auditable_type'));
          }
          
          if ($request->filled('auditable_id')) {
              $query->where('auditable_id', $request->input('auditable_id'));
          }
          
          if ($request->filled('tags')) {
              $tags = explode(',', $request->input('tags'));
              $query->withTags($tags);
          }
          
          if ($request->filled('start_date') && $request->filled('end_date')) {
              $query->withinDateRange(
                  $request->input('start_date'),
                  $request->input('end_date')
              );
          }
          
          // Apply sorting
          $sortField = $request->input('sort_by', 'created_at');
          $sortDirection = $request->input('sort_direction', 'desc');
          $query->orderBy($sortField, $sortDirection);
          
          // Paginate results
          $perPage = $request->input('per_page', 25);
          $auditLogs = $query->paginate($perPage);
          
          // Get available actions and types for filtering
          $actions = AuditLog::distinct('action')->pluck('action');
          $types = AuditLog::distinct('auditable_type')->pluck('auditable_type');
          
          return view('audit.index', [
              'auditLogs' => $auditLogs,
              'actions' => $actions,
              'types' => $types,
              'filters' => $request->all(),
          ]);
      }
      
      /**
       * Display the specified audit log.
       */
      public function show(AuditLog $auditLog)
      {
          // Check permissions
          if (!Auth::user()->can('view audit logs')) {
              abort(403);
          }
          
          // Load relationships
          $auditLog->load('user');
          
          return view('audit.show', [
              'auditLog' => $auditLog,
          ]);
      }
      
      /**
       * Export audit logs to Excel.
       */
      public function export(Request $request)
      {
          // Check permissions
          if (!Auth::user()->can('export audit logs')) {
              abort(403);
          }
          
          $fileName = 'audit_logs_' . now()->format('Y-m-d_H-i-s') . '.xlsx';
          
          return Excel::download(new AuditLogExport($request->all()), $fileName);
      }
  }
  
  namespace App\Exports;
  
  use App\Models\AuditLog;
  use Maatwebsite\Excel\Concerns\FromQuery;
  use Maatwebsite\Excel\Concerns\WithHeadings;
  use Maatwebsite\Excel\Concerns\WithMapping;
  
  class AuditLogExport implements FromQuery, WithHeadings, WithMapping
  {
      protected $filters;
      
      public function __construct(array $filters = [])
      {
          $this->filters = $filters;
      }
      
      /**
       * @return \Illuminate\Database\Eloquent\Builder
       */
      public function query()
      {
          $query = AuditLog::with('user');
          
          // Apply filters
          if (isset($this->filters['user_id'])) {
              $query->where('user_id', $this->filters['user_id']);
          }
          
          if (isset($this->filters['action'])) {
              $query->where('action', $this->filters['action']);
          }
          
          if (isset($this->filters['auditable_type'])) {
              $query->where('auditable_type', $this->filters['auditable_type']);
          }
          
          if (isset($this->filters['auditable_id'])) {
              $query->where('auditable_id', $this->filters['auditable_id']);
          }
          
          if (isset($this->filters['tags'])) {
              $tags = explode(',', $this->filters['tags']);
              $query->withTags($tags);
          }
          
          if (isset($this->filters['start_date']) && isset($this->filters['end_date'])) {
              $query->withinDateRange(
                  $this->filters['start_date'],
                  $this->filters['end_date']
              );
          }
          
          // Apply sorting
          $sortField = $this->filters['sort_by'] ?? 'created_at';
          $sortDirection = $this->filters['sort_direction'] ?? 'desc';
          $query->orderBy($sortField, $sortDirection);
          
          return $query;
      }
      
      /**
       * @var AuditLog $auditLog
       */
      public function map($auditLog): array
      {
          return [
              $auditLog->id,
              $auditLog->created_at->format('Y-m-d H:i:s'),
              $auditLog->user ? $auditLog->user->name : 'System',
              $auditLog->action,
              class_basename($auditLog->auditable_type),
              $auditLog->auditable_id,
              $auditLog->ip_address,
              json_encode($auditLog->old_values),
              json_encode($auditLog->new_values),
              implode(', ', $auditLog->tags ?? []),
          ];
      }
      
      public function headings(): array
      {
          return [
              'ID',
              'Timestamp',
              'User',
              'Action',
              'Model Type',
              'Model ID',
              'IP Address',
              'Old Values',
              'New Values',
              'Tags',
          ];
      }
  }
  
  namespace App\Listeners;
  
  use App\Services\AuditService;
  use Illuminate\Auth\Events\Failed;
  use Illuminate\Auth\Events\Login;
  use Illuminate\Auth\Events\Logout;
  
  class AuthEventSubscriber
  {
      protected $auditService;
      
      public function __construct(AuditService $auditService)
      {
          $this->auditService = $auditService;
      }
      
      /**
       * Handle user login events.
       */
      public function handleUserLogin($event)
      {
          $this->auditService->logLogin($event->user, ['auth']);
      }
      
      /**
       * Handle user logout events.
       */
      public function handleUserLogout($event)
      {
          if ($event->user) {
              $this->auditService->logLogout($event->user, ['auth']);
          }
      }
      
      /**
       * Handle failed login attempts.
       */
      public function handleFailedLogin($event)
      {
          $this->auditService->logLoginFailed($event->credentials['email'], ['auth', 'security']);
      }
      
      /**
       * Register the listeners for the subscriber.
       *
       * @param \Illuminate\Events\Dispatcher $events
       * @return void
       */
      public function subscribe($events)
      {
          $events->listen(
              Login::class,
              [AuthEventSubscriber::class, 'handleUserLogin']
          );
          
          $events->listen(
              Logout::class,
              [AuthEventSubscriber::class, 'handleUserLogout']
          );
          
          $events->listen(
              Failed::class,
              [AuthEventSubscriber::class, 'handleFailedLogin']
          );
      }
  }
  
  namespace App\Models;
  
  use App\Traits\Auditable;
  use Illuminate\Database\Eloquent\Model;
  
  class Task extends Model
  {
      use Auditable;
      
      protected $fillable = [
          'title',
          'description',
          'status',
          'priority',
          'due_date',
          'assigned_to',
          'team_id',
      ];
      
      protected $auditableAttributes = [
          'title',
          'description',
          'status',
          'priority',
          'due_date',
          'assigned_to',
          'team_id',
      ];
      
      protected $auditTags = ['task'];
      
      // Rest of the model...
  }
explanation: |
  This example demonstrates a comprehensive audit trail system:
  
  1. **Audit Log Model**: A central model that stores all audit data:
     - Who performed the action (user)
     - What action was performed
     - What model was affected
     - What values changed (old and new)
     - Additional context (IP address, user agent, tags)
  
  2. **Audit Service**: A service that handles logging audit events:
     - Creating audit log records
     - Providing convenience methods for common actions
     - Handling special cases like authentication events
  
  3. **Auditable Trait**: A reusable trait that can be added to any model:
     - Automatically logs created, updated, deleted, and restored events
     - Allows customizing which attributes are audited
     - Provides methods for accessing audit logs
  
  4. **Authentication Auditing**: Tracking authentication-related events:
     - User logins
     - User logouts
     - Failed login attempts
  
  5. **Audit Log Management**: Providing endpoints to view and export audit logs:
     - Viewing audit logs with filtering and pagination
     - Exporting audit logs to Excel
     - Detailed view of individual audit logs
  
  6. **Filtering and Searching**: Advanced filtering options for audit logs:
     - By user
     - By action
     - By model type
     - By model ID
     - By tags
     - By date range
  
  Key features of the implementation:
  
  - **Comprehensive Tracking**: Tracking all changes to models
  - **Attribute Filtering**: Controlling which attributes are audited
  - **Tagging System**: Adding tags to audit logs for better categorization
  - **Change Tracking**: Storing both old and new values for updates
  - **Security Context**: Capturing IP address and user agent
  - **Export Functionality**: Exporting audit logs to Excel
  
  In a real Laravel application:
  - You would implement more sophisticated access control
  - You might add audit log aggregation for high-volume models
  - You would implement audit log cleanup for old records
  - You would add more detailed audit log visualization
  - You would implement audit log notifications for security events
challenges:
  - Implement audit log aggregation (e.g., "User edited this task 5 times today")
  - Add support for audit log comments (allowing admins to add notes to audit logs)
  - Create a dashboard that shows audit statistics and trends
  - Implement a system to detect suspicious activity based on audit logs
  - Add support for comparing different versions of a model based on audit logs
:::
