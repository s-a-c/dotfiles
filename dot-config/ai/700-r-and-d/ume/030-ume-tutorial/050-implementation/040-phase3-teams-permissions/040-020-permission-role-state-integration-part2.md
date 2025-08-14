# Permission/Role State Integration (Part 2)

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Role Controller

```php
<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\UPermission;
use App\Models\URole;
use App\States\Role\Active;
use App\States\Role\Deprecated;
use App\States\Role\Disabled;
use App\States\Role\Draft;
use App\States\Role\Transitions\ApproveRoleTransition;
use App\States\Role\Transitions\DeprecateRoleTransition;
use App\States\Role\Transitions\DisableRoleTransition;
use App\States\Role\Transitions\EnableRoleTransition;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class RoleController extends Controller
{
    /**
     * Display a listing of the roles.
     */
    public function index()
    {
        $roles = URole::all();
        
        return view('admin.roles.index', compact('roles'));
    }

    /**
     * Show the form for creating a new role.
     */
    public function create()
    {
        $permissions = UPermission::where(function ($query) {
            $query->whereHas('status', function ($q) {
                $q->where('status', 'active');
            });
        })->get();

        return view('admin.roles.create', compact('permissions'));
    }

    /**
     * Store a newly created role in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255', 'unique:roles'],
            'guard_name' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'team_id' => ['nullable', 'exists:teams,id'],
            'permissions' => ['nullable', 'array'],
            'permissions.*' => ['exists:permissions,id'],
        ]);

        $role = URole::create([
            'name' => $validated['name'],
            'guard_name' => $validated['guard_name'],
            'description' => $validated['description'] ?? null,
            'team_id' => $validated['team_id'] ?? null,
        ]);

        if (isset($validated['permissions'])) {
            $role->permissions()->sync($validated['permissions']);
        }

        return redirect()->route('admin.roles.show', $role)
            ->with('success', 'Role created successfully.');
    }

    /**
     * Display the specified role.
     */
    public function show(URole $role)
    {
        $role->load('permissions');
        
        return view('admin.roles.show', compact('role'));
    }

    /**
     * Show the form for editing the specified role.
     */
    public function edit(URole $role)
    {
        if (!$role->canBeModified()) {
            return redirect()->route('admin.roles.show', $role)
                ->with('error', 'This role cannot be modified in its current state.');
        }

        $permissions = UPermission::where(function ($query) {
            $query->whereHas('status', function ($q) {
                $q->where('status', 'active');
            });
        })->get();

        $role->load('permissions');

        return view('admin.roles.edit', compact('role', 'permissions'));
    }

    /**
     * Update the specified role in storage.
     */
    public function update(Request $request, URole $role)
    {
        if (!$role->canBeModified()) {
            return redirect()->route('admin.roles.show', $role)
                ->with('error', 'This role cannot be modified in its current state.');
        }

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255', Rule::unique('roles')->ignore($role->id)],
            'guard_name' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'team_id' => ['nullable', 'exists:teams,id'],
            'permissions' => ['nullable', 'array'],
            'permissions.*' => ['exists:permissions,id'],
        ]);

        $role->update([
            'name' => $validated['name'],
            'guard_name' => $validated['guard_name'],
            'description' => $validated['description'] ?? null,
            'team_id' => $validated['team_id'] ?? null,
        ]);

        if (isset($validated['permissions']) && $role->canModifyPermissions()) {
            $role->permissions()->sync($validated['permissions']);
        }

        return redirect()->route('admin.roles.show', $role)
            ->with('success', 'Role updated successfully.');
    }

    /**
     * Remove the specified role from storage.
     */
    public function destroy(URole $role)
    {
        if (!$role->canBeDeleted()) {
            return redirect()->route('admin.roles.show', $role)
                ->with('error', 'This role cannot be deleted in its current state.');
        }

        $role->delete();

        return redirect()->route('admin.roles.index')
            ->with('success', 'Role deleted successfully.');
    }

    /**
     * Approve a draft role.
     */
    public function approve(URole $role, Request $request)
    {
        try {
            if (!($role->status instanceof Draft)) {
                return redirect()->route('admin.roles.show', $role)
                    ->with('error', 'Only draft roles can be approved.');
            }

            $validated = $request->validate([
                'notes' => ['nullable', 'string'],
            ]);

            $role->status->transition(new ApproveRoleTransition(
                auth()->user(),
                $validated['notes'] ?? null
            ));
            $role->save();

            return redirect()->route('admin.roles.show', $role)
                ->with('success', 'Role approved successfully.');
        } catch (\Exception $e) {
            return redirect()->route('admin.roles.show', $role)
                ->with('error', 'Failed to approve role: ' . $e->getMessage());
        }
    }

    /**
     * Disable an active role.
     */
    public function disable(URole $role, Request $request)
    {
        try {
            if (!($role->status instanceof Active)) {
                return redirect()->route('admin.roles.show', $role)
                    ->with('error', 'Only active roles can be disabled.');
            }

            $validated = $request->validate([
                'reason' => ['required', 'string'],
                'notes' => ['nullable', 'string'],
            ]);

            $role->status->transition(new DisableRoleTransition(
                auth()->user(),
                $validated['reason'],
                $validated['notes'] ?? null
            ));
            $role->save();

            return redirect()->route('admin.roles.show', $role)
                ->with('success', 'Role disabled successfully.');
        } catch (\Exception $e) {
            return redirect()->route('admin.roles.show', $role)
                ->with('error', 'Failed to disable role: ' . $e->getMessage());
        }
    }

    /**
     * Enable a disabled role.
     */
    public function enable(URole $role, Request $request)
    {
        try {
            if (!($role->status instanceof Disabled)) {
                return redirect()->route('admin.roles.show', $role)
                    ->with('error', 'Only disabled roles can be enabled.');
            }

            $validated = $request->validate([
                'notes' => ['nullable', 'string'],
            ]);

            $role->status->transition(new EnableRoleTransition(
                auth()->user(),
                $validated['notes'] ?? null
            ));
            $role->save();

            return redirect()->route('admin.roles.show', $role)
                ->with('success', 'Role enabled successfully.');
        } catch (\Exception $e) {
            return redirect()->route('admin.roles.show', $role)
                ->with('error', 'Failed to enable role: ' . $e->getMessage());
        }
    }

    /**
     * Deprecate a role.
     */
    public function deprecate(URole $role, Request $request)
    {
        try {
            if ($role->status instanceof Deprecated) {
                return redirect()->route('admin.roles.show', $role)
                    ->with('error', 'Role is already deprecated.');
            }

            if (!($role->status instanceof Active || $role->status instanceof Disabled)) {
                return redirect()->route('admin.roles.show', $role)
                    ->with('error', 'Only active or disabled roles can be deprecated.');
            }

            $validated = $request->validate([
                'reason' => ['required', 'string'],
                'notes' => ['nullable', 'string'],
            ]);

            $role->status->transition(new DeprecateRoleTransition(
                auth()->user(),
                $validated['reason'],
                $validated['notes'] ?? null
            ));
            $role->save();

            return redirect()->route('admin.roles.show', $role)
                ->with('success', 'Role deprecated successfully.');
        } catch (\Exception $e) {
            return redirect()->route('admin.roles.show', $role)
                ->with('error', 'Failed to deprecate role: ' . $e->getMessage());
        }
    }
}
```
