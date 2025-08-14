# Permission/Role State Machine Exercises - Sample Answers (Part 4)

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Exercise 3: Creating a Permission History Feature (continued)

### Step 2: Create the PermissionHistory model

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PermissionHistory extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'permission_id',
        'user_id',
        'from_state',
        'to_state',
        'transition_type',
        'reason',
        'notes',
        'additional_data',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'additional_data' => 'array',
    ];

    /**
     * Get the permission that owns the history entry.
     */
    public function permission(): BelongsTo
    {
        return $this->belongsTo(UPermission::class, 'permission_id');
    }

    /**
     * Get the user who performed the transition.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
```

### Step 3: Update the UPermission model to include the history relationship

```php
<?php

namespace App\Models;

use App\Enums\PermissionStatus;
use App\States\Permission\PermissionState;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Spatie\ModelStates\HasStates;
use Spatie\Permission\Models\Permission;

class UPermission extends Permission
{
    use HasFactory, SoftDeletes, HasStates;

    // ... existing code ...

    /**
     * Get the history entries for the permission.
     */
    public function history(): HasMany
    {
        return $this->hasMany(PermissionHistory::class, 'permission_id');
    }
}
```

### Step 4: Update the transition classes to record history entries

Here's an example for the ApprovePermissionTransition class:

```php
<?php

declare(strict_types=1);

namespace App\States\Permission\Transitions;

use App\Models\PermissionHistory;
use App\Models\UPermission;
use App\Models\User;
use App\States\Permission\Active;
use App\States\Permission\Draft;
use Illuminate\Support\Facades\Log;
use Spatie\ModelStates\Transition;

/**
 * Transition from Draft to Active when a permission is approved.
 */
class ApprovePermissionTransition extends Transition
{
    /**
     * Constructor.
     */
    public function __construct(
        private ?User $approvedBy = null,
        private ?string $notes = null
    ) {}

    /**
     * Handle the transition.
     */
    public function handle(UPermission $permission, Draft $currentState): Active
    {
        // Log the transition
        Log::info("Permission {$permission->id} ({$permission->name}) was approved by " . 
            ($this->approvedBy ? "User {$this->approvedBy->id}" : "system") . 
            ($this->notes ? " with notes: {$this->notes}" : ""));

        // Record the approval in activity log
        activity()
            ->performedOn($permission)
            ->causedBy($this->approvedBy ?? auth()->user())
            ->withProperties([
                'notes' => $this->notes,
                'from_state' => 'draft',
                'to_state' => 'active',
            ])
            ->log('permission_approved');

        // Record the history entry
        PermissionHistory::create([
            'permission_id' => $permission->id,
            'user_id' => $this->approvedBy ? $this->approvedBy->id : null,
            'from_state' => 'draft',
            'to_state' => 'active',
            'transition_type' => 'approve',
            'notes' => $this->notes,
        ]);

        // Return the new state
        return new Active($permission);
    }
}
```
