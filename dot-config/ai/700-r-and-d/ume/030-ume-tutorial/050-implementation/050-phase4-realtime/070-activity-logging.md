# Understanding Contextual Activity Logging

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Understand how to implement comprehensive activity logging for user actions, including presence status changes, using the `spatie/laravel-activitylog` package.

## Prerequisites

- Completed the previous sections on presence status
- Understanding of Laravel's event system
- Basic knowledge of the `spatie/laravel-activitylog` package

## Introduction to Activity Logging

Activity logging is essential for tracking user actions, auditing changes, and providing a history of what happened in your application. In the context of our User Presence State Machine, we want to log:

1. When a user's presence status changes
2. Who initiated the change (if applicable)
3. The previous and new status values
4. The timestamp of the change

The `spatie/laravel-activitylog` package provides a flexible and powerful way to log these activities.

## Understanding the spatie/laravel-activitylog Package

The `spatie/laravel-activitylog` package allows you to:

1. Log activity on model events (create, update, delete)
2. Log custom activities
3. Associate activities with a subject (the model being changed)
4. Associate activities with a causer (the user who caused the change)
5. Store additional properties with the activity

### Key Concepts

#### Log Names

Activities are grouped by "log names." This allows you to separate different types of activities:

- `auth` for authentication-related activities
- `user` for user-related activities
- `presence` for presence-related activities

#### Subjects and Causers

- **Subject**: The model that the activity is performed on (e.g., the User whose presence changed)
- **Causer**: The model that caused the activity (e.g., the User who initiated the change)

#### Properties

Additional data can be stored with the activity as properties, such as:

- The old and new values
- Context information
- Related model IDs

## Implementation Approaches

There are two main approaches to logging activities:

### 1. Automatic Model Event Logging

The package can automatically log activities when model events occur:

```php
// In your User model
use Spatie\Activitylog\Traits\LogsActivity;
use Spatie\Activitylog\LogOptions;

class User extends Authenticatable
{
    use LogsActivity;
    
    public function getActivitylogOptions(): LogOptions
    {
        return LogOptions::defaults()
            ->logOnly(['presence_status', 'last_seen_at'])
            ->logOnlyDirty()
            ->setDescriptionForEvent(fn(string $eventName) => "User presence was {$eventName}");
    }
}
```

This approach is simple but has limitations for complex scenarios.

### 2. Manual Activity Logging via Events

For more control, you can manually log activities in event listeners:

```php
// In a listener for PresenceChanged
use Spatie\Activitylog\Facades\Activity;

public function handle(PresenceChanged $event)
{
    Activity::withProperties([
        'old_status' => $event->oldStatus->value ?? null,
        'new_status' => $event->status->value,
        'ip_address' => request()->ip(),
    ])
    ->causedBy($event->user)
    ->performedOn($event->user)
    ->log('presence_changed');
}
```

This approach gives you more flexibility and control over what gets logged.

## Contextual Logging for Presence Status

For our User Presence State Machine, we'll use the manual approach to log activities when presence status changes. This allows us to:

1. Include both the old and new status values
2. Add context about how the status changed (login, logout, manual update, inactivity)
3. Format the description based on the context

### Example: Logging Presence Changes

```php
use Spatie\Activitylog\Facades\Activity;
use App\Enums\PresenceStatus;
use App\Events\User\PresenceChanged;

class LogPresenceActivity
{
    public function handle(PresenceChanged $event)
    {
        $description = $this->getDescription($event);
        
        Activity::withProperties([
            'old_status' => $event->oldStatus?->value ?? 'unknown',
            'new_status' => $event->status->value,
            'trigger' => $event->trigger ?? 'manual',
            'ip_address' => request()->ip(),
        ])
        ->causedBy($event->causer ?? $event->user)
        ->performedOn($event->user)
        ->log($description);
    }
    
    private function getDescription(PresenceChanged $event): string
    {
        $userName = $event->user->name;
        $newStatus = $event->status->label();
        
        return match ($event->trigger ?? 'manual') {
            'login' => "{$userName} logged in and is now {$newStatus}",
            'logout' => "{$userName} logged out and is now {$newStatus}",
            'inactivity' => "{$userName} went {$newStatus} due to inactivity",
            'manual' => "{$userName} manually changed status to {$newStatus}",
            default => "{$userName} is now {$newStatus}",
        };
    }
}
```

## Displaying Activity Logs

Once you've logged activities, you'll want to display them in your application. Here's a simple example of how to retrieve and display activity logs:

```php
// In a controller
public function showActivityLog()
{
    $activities = Activity::causedBy(auth()->user())
        ->orWhere(function($query) {
            $query->where('subject_type', User::class)
                  ->where('subject_id', auth()->id());
        })
        ->orderBy('created_at', 'desc')
        ->paginate(20);
    
    return view('activity-log', compact('activities'));
}
```

```blade
<!-- In a Blade view -->
<div class="activity-log">
    @foreach($activities as $activity)
        <div class="activity-item">
            <div class="activity-time">{{ $activity->created_at->diffForHumans() }}</div>
            <div class="activity-description">{{ $activity->description }}</div>
            @if($activity->properties->has('old_status') && $activity->properties->has('new_status'))
                <div class="activity-details">
                    Changed from {{ $activity->properties->get('old_status') }} to {{ $activity->properties->get('new_status') }}
                </div>
            @endif
        </div>
    @endforeach
    
    {{ $activities->links() }}
</div>
```

## Best Practices for Activity Logging

1. **Be Selective**: Log important activities, not everything
2. **Include Context**: Add relevant properties to make logs useful
3. **Use Log Names**: Group related activities under the same log name
4. **Consider Performance**: Logging can impact performance, so use queues for busy applications
5. **Clean Up Old Logs**: Set up a schedule to prune old logs

## Next Steps

Now that we understand how activity logging works, let's implement it for our User Presence State Machine.

[Implement Activity Logging via Listeners →](./080-implement-logging.md)
