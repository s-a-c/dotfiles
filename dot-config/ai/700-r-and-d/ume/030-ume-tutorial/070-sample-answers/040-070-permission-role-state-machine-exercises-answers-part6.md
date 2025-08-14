# Permission/Role State Machine Exercises - Sample Answers (Part 6)

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Exercise 4: Implementing Batch State Transitions

### Step 1: Create a controller for batch operations

```php
<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\UPermission;
use App\States\Permission\Active;
use App\States\Permission\Deprecated;
use App\States\Permission\Disabled;
use App\States\Permission\Draft;
use App\States\Permission\Transitions\ApprovePermissionTransition;
use App\States\Permission\Transitions\DeprecatePermissionTransition;
use App\States\Permission\Transitions\DisablePermissionTransition;
use App\States\Permission\Transitions\EnablePermissionTransition;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class BatchPermissionController extends Controller
{
    /**
     * Show the form for batch operations.
     */
    public function index()
    {
        $permissions = UPermission::all();
        
        return view('admin.permissions.batch', compact('permissions'));
    }

    /**
     * Process the batch operation.
     */
    public function process(Request $request)
    {
        $validated = $request->validate([
            'permissions' => ['required', 'array'],
            'permissions.*' => ['exists:permissions,id'],
            'action' => ['required', Rule::in(['approve', 'disable', 'enable', 'deprecate'])],
            'reason' => ['required_if:action,disable,deprecate', 'nullable', 'string'],
            'notes' => ['nullable', 'string'],
        ]);

        $permissions = UPermission::whereIn('id', $validated['permissions'])->get();
        $action = $validated['action'];
        $reason = $validated['reason'] ?? null;
        $notes = $validated['notes'] ?? null;
        
        $results = [
            'success' => [],
            'error' => [],
        ];

        DB::beginTransaction();

        try {
            foreach ($permissions as $permission) {
                try {
                    switch ($action) {
                        case 'approve':
                            if ($permission->status instanceof Draft) {
                                $permission->status->transition(new ApprovePermissionTransition(
                                    auth()->user(),
                                    $notes
                                ));
                                $permission->save();
                                $results['success'][] = "Approved permission: {$permission->name}";
                            } else {
                                $results['error'][] = "Cannot approve permission {$permission->name}: not in draft state";
                            }
                            break;
                        
                        case 'disable':
                            if ($permission->status instanceof Active) {
                                $permission->status->transition(new DisablePermissionTransition(
                                    auth()->user(),
                                    $reason,
                                    $notes
                                ));
                                $permission->save();
                                $results['success'][] = "Disabled permission: {$permission->name}";
                            } else {
                                $results['error'][] = "Cannot disable permission {$permission->name}: not in active state";
                            }
                            break;
                        
                        case 'enable':
                            if ($permission->status instanceof Disabled) {
                                $permission->status->transition(new EnablePermissionTransition(
                                    auth()->user(),
                                    $notes
                                ));
                                $permission->save();
                                $results['success'][] = "Enabled permission: {$permission->name}";
                            } else {
                                $results['error'][] = "Cannot enable permission {$permission->name}: not in disabled state";
                            }
                            break;
                        
                        case 'deprecate':
                            if ($permission->status instanceof Active || $permission->status instanceof Disabled) {
                                $permission->status->transition(new DeprecatePermissionTransition(
                                    auth()->user(),
                                    $reason,
                                    $notes
                                ));
                                $permission->save();
                                $results['success'][] = "Deprecated permission: {$permission->name}";
                            } else {
                                $results['error'][] = "Cannot deprecate permission {$permission->name}: not in active or disabled state";
                            }
                            break;
                    }
                } catch (\Exception $e) {
                    $results['error'][] = "Error processing permission {$permission->name}: {$e->getMessage()}";
                }
            }

            DB::commit();
        } catch (\Exception $e) {
            DB::rollBack();
            return redirect()->route('admin.permissions.batch')
                ->with('error', 'An error occurred during batch processing: ' . $e->getMessage());
        }

        return view('admin.permissions.batch-results', compact('results'));
    }
}
```
