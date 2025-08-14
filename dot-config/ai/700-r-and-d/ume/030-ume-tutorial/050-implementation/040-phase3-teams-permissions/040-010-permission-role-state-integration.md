# Permission/Role State Integration

<link rel="stylesheet" href="../../../assets/css/styles.css">

In this section, we'll integrate the permission and role state machines with our application. We'll create controllers, middleware, and views to manage permission and role states.

## Creating Controllers for Permission and Role Management

Let's start by creating controllers to manage permissions and roles:

```bash
php artisan make:controller Admin/PermissionController
php artisan make:controller Admin/RoleController
```

### Permission Controller

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
use Illuminate\Validation\Rule;

class PermissionController extends Controller
{
    /**
     * Display a listing of the permissions.
     */
    public function index()
    {
        $permissions = UPermission::all();
        
        return view('admin.permissions.index', compact('permissions'));
    }

    /**
     * Show the form for creating a new permission.
     */
    public function create()
    {
        return view('admin.permissions.create');
    }

    /**
     * Store a newly created permission in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255', 'unique:permissions'],
            'guard_name' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'team_id' => ['nullable', 'exists:teams,id'],
        ]);

        $permission = UPermission::create($validated);

        return redirect()->route('admin.permissions.show', $permission)
            ->with('success', 'Permission created successfully.');
    }

    /**
     * Display the specified permission.
     */
    public function show(UPermission $permission)
    {
        return view('admin.permissions.show', compact('permission'));
    }

    /**
     * Show the form for editing the specified permission.
     */
    public function edit(UPermission $permission)
    {
        if (!$permission->canBeModified()) {
            return redirect()->route('admin.permissions.show', $permission)
                ->with('error', 'This permission cannot be modified in its current state.');
        }

        return view('admin.permissions.edit', compact('permission'));
    }

    /**
     * Update the specified permission in storage.
     */
    public function update(Request $request, UPermission $permission)
    {
        if (!$permission->canBeModified()) {
            return redirect()->route('admin.permissions.show', $permission)
                ->with('error', 'This permission cannot be modified in its current state.');
        }

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255', Rule::unique('permissions')->ignore($permission->id)],
            'guard_name' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'team_id' => ['nullable', 'exists:teams,id'],
        ]);

        $permission->update($validated);

        return redirect()->route('admin.permissions.show', $permission)
            ->with('success', 'Permission updated successfully.');
    }

    /**
     * Remove the specified permission from storage.
     */
    public function destroy(UPermission $permission)
    {
        if (!$permission->canBeDeleted()) {
            return redirect()->route('admin.permissions.show', $permission)
                ->with('error', 'This permission cannot be deleted in its current state.');
        }

        $permission->delete();

        return redirect()->route('admin.permissions.index')
            ->with('success', 'Permission deleted successfully.');
    }

    /**
     * Approve a draft permission.
     */
    public function approve(UPermission $permission, Request $request)
    {
        try {
            if (!($permission->status instanceof Draft)) {
                return redirect()->route('admin.permissions.show', $permission)
                    ->with('error', 'Only draft permissions can be approved.');
            }

            $validated = $request->validate([
                'notes' => ['nullable', 'string'],
            ]);

            $permission->status->transition(new ApprovePermissionTransition(
                auth()->user(),
                $validated['notes'] ?? null
            ));
            $permission->save();

            return redirect()->route('admin.permissions.show', $permission)
                ->with('success', 'Permission approved successfully.');
        } catch (\Exception $e) {
            return redirect()->route('admin.permissions.show', $permission)
                ->with('error', 'Failed to approve permission: ' . $e->getMessage());
        }
    }

    /**
     * Disable an active permission.
     */
    public function disable(UPermission $permission, Request $request)
    {
        try {
            if (!($permission->status instanceof Active)) {
                return redirect()->route('admin.permissions.show', $permission)
                    ->with('error', 'Only active permissions can be disabled.');
            }

            $validated = $request->validate([
                'reason' => ['required', 'string'],
                'notes' => ['nullable', 'string'],
            ]);

            $permission->status->transition(new DisablePermissionTransition(
                auth()->user(),
                $validated['reason'],
                $validated['notes'] ?? null
            ));
            $permission->save();

            return redirect()->route('admin.permissions.show', $permission)
                ->with('success', 'Permission disabled successfully.');
        } catch (\Exception $e) {
            return redirect()->route('admin.permissions.show', $permission)
                ->with('error', 'Failed to disable permission: ' . $e->getMessage());
        }
    }

    /**
     * Enable a disabled permission.
     */
    public function enable(UPermission $permission, Request $request)
    {
        try {
            if (!($permission->status instanceof Disabled)) {
                return redirect()->route('admin.permissions.show', $permission)
                    ->with('error', 'Only disabled permissions can be enabled.');
            }

            $validated = $request->validate([
                'notes' => ['nullable', 'string'],
            ]);

            $permission->status->transition(new EnablePermissionTransition(
                auth()->user(),
                $validated['notes'] ?? null
            ));
            $permission->save();

            return redirect()->route('admin.permissions.show', $permission)
                ->with('success', 'Permission enabled successfully.');
        } catch (\Exception $e) {
            return redirect()->route('admin.permissions.show', $permission)
                ->with('error', 'Failed to enable permission: ' . $e->getMessage());
        }
    }

    /**
     * Deprecate a permission.
     */
    public function deprecate(UPermission $permission, Request $request)
    {
        try {
            if ($permission->status instanceof Deprecated) {
                return redirect()->route('admin.permissions.show', $permission)
                    ->with('error', 'Permission is already deprecated.');
            }

            if (!($permission->status instanceof Active || $permission->status instanceof Disabled)) {
                return redirect()->route('admin.permissions.show', $permission)
                    ->with('error', 'Only active or disabled permissions can be deprecated.');
            }

            $validated = $request->validate([
                'reason' => ['required', 'string'],
                'notes' => ['nullable', 'string'],
            ]);

            $permission->status->transition(new DeprecatePermissionTransition(
                auth()->user(),
                $validated['reason'],
                $validated['notes'] ?? null
            ));
            $permission->save();

            return redirect()->route('admin.permissions.show', $permission)
                ->with('success', 'Permission deprecated successfully.');
        } catch (\Exception $e) {
            return redirect()->route('admin.permissions.show', $permission)
                ->with('error', 'Failed to deprecate permission: ' . $e->getMessage());
        }
    }
}
```
