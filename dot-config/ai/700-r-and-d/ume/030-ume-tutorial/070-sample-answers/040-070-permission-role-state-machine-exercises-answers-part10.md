# Permission/Role State Machine Exercises - Sample Answers (Part 10)

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Exercise 5: Creating a Permission Approval Workflow (continued)

### Step 5: Create the notification classes

```php
<?php

namespace App\Notifications;

use App\Models\UPermission;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class PermissionSubmittedForApproval extends Notification implements ShouldQueue
{
    use Queueable;

    /**
     * Create a new notification instance.
     */
    public function __construct(
        public UPermission $permission,
        public string $level // 'first' or 'second'
    ) {}

    /**
     * Get the notification's delivery channels.
     *
     * @return array<int, string>
     */
    public function via(object $notifiable): array
    {
        return ['mail', 'database'];
    }

    /**
     * Get the mail representation of the notification.
     */
    public function toMail(object $notifiable): MailMessage
    {
        $levelText = $this->level === 'first' ? 'First' : 'Second';
        
        return (new MailMessage)
            ->subject("Permission Requires {$levelText} Level Approval")
            ->greeting("Hello {$notifiable->name},")
            ->line("A permission requires your approval.")
            ->line("Permission Name: {$this->permission->name}")
            ->line("Description: {$this->permission->description}")
            ->action('Review Permission', url(route('admin.permissions.show', $this->permission)))
            ->line('Thank you for your attention to this matter.');
    }

    /**
     * Get the array representation of the notification.
     *
     * @return array<string, mixed>
     */
    public function toArray(object $notifiable): array
    {
        $levelText = $this->level === 'first' ? 'First' : 'Second';
        
        return [
            'permission_id' => $this->permission->id,
            'permission_name' => $this->permission->name,
            'level' => $this->level,
            'message' => "Permission {$this->permission->name} requires {$levelText} level approval",
        ];
    }
}
```

### Step 6: Update the permission controller to handle the approval workflow

```php
<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\UPermission;
use App\States\Permission\Active;
use App\States\Permission\Deprecated;
use App\States\Permission\Disabled;
use App\States\Permission\Draft;
use App\States\Permission\PendingFirstApproval;
use App\States\Permission\PendingSecondApproval;
use App\States\Permission\Transitions\ApproveFirstLevelTransition;
use App\States\Permission\Transitions\ApproveSecondLevelTransition;
use App\States\Permission\Transitions\DeprecatePermissionTransition;
use App\States\Permission\Transitions\DisablePermissionTransition;
use App\States\Permission\Transitions\EnablePermissionTransition;
use App\States\Permission\Transitions\RejectFirstApprovalTransition;
use App\States\Permission\Transitions\RejectSecondApprovalTransition;
use App\States\Permission\Transitions\SubmitForFirstApprovalTransition;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class PermissionController extends Controller
{
    // ... existing methods ...

    /**
     * Submit a permission for first-level approval.
     */
    public function submitForFirstApproval(UPermission $permission, Request $request)
    {
        try {
            if (!($permission->status instanceof Draft)) {
                return redirect()->route('admin.permissions.show', $permission)
                    ->with('error', 'Only draft permissions can be submitted for approval.');
            }

            $validated = $request->validate([
                'notes' => ['nullable', 'string'],
            ]);

            $permission->status->transition(new SubmitForFirstApprovalTransition(
                auth()->user(),
                $validated['notes'] ?? null
            ));
            $permission->save();

            return redirect()->route('admin.permissions.show', $permission)
                ->with('success', 'Permission submitted for first-level approval.');
        } catch (\Exception $e) {
            return redirect()->route('admin.permissions.show', $permission)
                ->with('error', 'Failed to submit permission for approval: ' . $e->getMessage());
        }
    }

    /**
     * Approve a permission at the first level.
     */
    public function approveFirstLevel(UPermission $permission, Request $request)
    {
        try {
            if (!($permission->status instanceof PendingFirstApproval)) {
                return redirect()->route('admin.permissions.show', $permission)
                    ->with('error', 'Only permissions pending first-level approval can be approved at this level.');
            }

            if (!auth()->user()->hasPermissionTo('approve-permissions-first-level')) {
                return redirect()->route('admin.permissions.show', $permission)
                    ->with('error', 'You do not have permission to approve at this level.');
            }

            $validated = $request->validate([
                'notes' => ['nullable', 'string'],
            ]);

            $permission->status->transition(new ApproveFirstLevelTransition(
                auth()->user(),
                $validated['notes'] ?? null
            ));
            $permission->save();

            return redirect()->route('admin.permissions.show', $permission)
                ->with('success', 'Permission approved at first level and submitted for second-level approval.');
        } catch (\Exception $e) {
            return redirect()->route('admin.permissions.show', $permission)
                ->with('error', 'Failed to approve permission: ' . $e->getMessage());
        }
    }

    /**
     * Reject a permission at the first level.
     */
    public function rejectFirstLevel(UPermission $permission, Request $request)
    {
        try {
            if (!($permission->status instanceof PendingFirstApproval)) {
                return redirect()->route('admin.permissions.show', $permission)
                    ->with('error', 'Only permissions pending first-level approval can be rejected at this level.');
            }

            if (!auth()->user()->hasPermissionTo('approve-permissions-first-level')) {
                return redirect()->route('admin.permissions.show', $permission)
                    ->with('error', 'You do not have permission to reject at this level.');
            }

            $validated = $request->validate([
                'reason' => ['required', 'string'],
                'notes' => ['nullable', 'string'],
            ]);

            $permission->status->transition(new RejectFirstApprovalTransition(
                auth()->user(),
                $validated['reason'],
                $validated['notes'] ?? null
            ));
            $permission->save();

            return redirect()->route('admin.permissions.show', $permission)
                ->with('success', 'Permission rejected at first level and returned to draft.');
        } catch (\Exception $e) {
            return redirect()->route('admin.permissions.show', $permission)
                ->with('error', 'Failed to reject permission: ' . $e->getMessage());
        }
    }

    /**
     * Approve a permission at the second level.
     */
    public function approveSecondLevel(UPermission $permission, Request $request)
    {
        try {
            if (!($permission->status instanceof PendingSecondApproval)) {
                return redirect()->route('admin.permissions.show', $permission)
                    ->with('error', 'Only permissions pending second-level approval can be approved at this level.');
            }

            if (!auth()->user()->hasPermissionTo('approve-permissions-second-level')) {
                return redirect()->route('admin.permissions.show', $permission)
                    ->with('error', 'You do not have permission to approve at this level.');
            }

            $validated = $request->validate([
                'notes' => ['nullable', 'string'],
            ]);

            $permission->status->transition(new ApproveSecondLevelTransition(
                auth()->user(),
                $validated['notes'] ?? null
            ));
            $permission->save();

            return redirect()->route('admin.permissions.show', $permission)
                ->with('success', 'Permission fully approved and is now active.');
        } catch (\Exception $e) {
            return redirect()->route('admin.permissions.show', $permission)
                ->with('error', 'Failed to approve permission: ' . $e->getMessage());
        }
    }

    /**
     * Reject a permission at the second level.
     */
    public function rejectSecondLevel(UPermission $permission, Request $request)
    {
        try {
            if (!($permission->status instanceof PendingSecondApproval)) {
                return redirect()->route('admin.permissions.show', $permission)
                    ->with('error', 'Only permissions pending second-level approval can be rejected at this level.');
            }

            if (!auth()->user()->hasPermissionTo('approve-permissions-second-level')) {
                return redirect()->route('admin.permissions.show', $permission)
                    ->with('error', 'You do not have permission to reject at this level.');
            }

            $validated = $request->validate([
                'reason' => ['required', 'string'],
                'notes' => ['nullable', 'string'],
            ]);

            $permission->status->transition(new RejectSecondApprovalTransition(
                auth()->user(),
                $validated['reason'],
                $validated['notes'] ?? null
            ));
            $permission->save();

            return redirect()->route('admin.permissions.show', $permission)
                ->with('success', 'Permission rejected at second level and returned to first-level approval.');
        } catch (\Exception $e) {
            return redirect()->route('admin.permissions.show', $permission)
                ->with('error', 'Failed to reject permission: ' . $e->getMessage());
        }
    }
}
```
