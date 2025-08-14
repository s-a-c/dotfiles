# Phase 3: Teams & Permissions Exercises - Sample Answers

<link rel="stylesheet" href="../assets/css/styles.css">

This file contains sample answers to the Phase 3: Teams & Permissions exercises from the UME tutorial.

## Set 1: Understanding Team-Based Permissions

### Question Answers

1. **What package is used to implement role-based permissions in the UME tutorial?**
   - **Answer: C) spatie/laravel-permission**
   - **Explanation:** The UME tutorial uses the spatie/laravel-permission package to implement role-based permissions. This package provides a flexible way to assign permissions to users and roles, and it integrates well with Laravel's authorization system. It allows for team-specific permissions through a team guard.

2. **What is the difference between a role and a permission in the context of the UME tutorial?**
   - **Answer: B) Roles are collections of permissions**
   - **Explanation:** In the UME tutorial, roles are collections of permissions that can be assigned to users. For example, an "Admin" role might include permissions like "create-user", "edit-user", and "delete-user". This approach simplifies permission management by allowing administrators to assign a single role instead of multiple individual permissions.

3. **How are team-specific permissions implemented in the UME tutorial?**
   - **Answer: B) By using a polymorphic relationship**
   - **Explanation:** Team-specific permissions in the UME tutorial are implemented using polymorphic relationships. This allows permissions to be associated with specific teams, enabling different permission sets for users depending on which team they are currently working with. The spatie/laravel-permission package is extended to support this team-based approach.

4. **What is the purpose of the `HasTeams` trait in the UME tutorial?**
   - **Answer: B) To define the relationship between users and teams**
   - **Explanation:** The `HasTeams` trait in the UME tutorial defines the relationship between users and teams. It provides methods for retrieving a user's teams, checking team membership, and managing the user's current team. This trait is a key component of the team-based permission system, as it allows the application to determine which team context a user is operating in.

### Exercise Solution: Implement a team-based permission system

#### Step 1: Set up the necessary tables using migrations

First, install the spatie/laravel-permission package:

```bash
composer require spatie/100-laravel-permission
```

Publish the package's migration files:

```bash
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"
```

Create a migration to add a team_id column to the roles and permissions tables:

```bash
php artisan make:migration add_team_id_to_permission_tables
```

Edit the migration file:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::table('permissions', function (Blueprint $table) {
            $table->unsignedBigInteger('team_id')->nullable();
            $table->foreign('team_id')->references('id')->on('teams')->onDelete('cascade');
        });

        Schema::table('roles', function (Blueprint $table) {
            $table->unsignedBigInteger('team_id')->nullable();
            $table->foreign('team_id')->references('id')->on('teams')->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::table('permissions', function (Blueprint $table) {
            $table->dropForeign(['team_id']);
            $table->dropColumn('team_id');
        });

        Schema::table('roles', function (Blueprint $table) {
            $table->dropForeign(['team_id']);
            $table->dropColumn('team_id');
        });
    }
};
```

Create a migration for the teams table if it doesn't exist:

```bash
php artisan make:migration create_teams_table
```

Edit the teams migration:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('teams', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->unsignedBigInteger('owner_id');
            $table->foreign('owner_id')->references('id')->on('users')->onDelete('cascade');
            $table->string('slug')->unique();
            $table->text('description')->nullable();
            $table->timestamps();
        });

        Schema::create('team_user', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('team_id');
            $table->unsignedBigInteger('user_id');
            $table->timestamps();

            $table->unique(['team_id', 'user_id']);
            $table->foreign('team_id')->references('id')->on('teams')->onDelete('cascade');
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::dropIfExists('team_user');
        Schema::dropIfExists('teams');
    }
};
```

Run the migrations:

```bash
php artisan migrate
```

#### Step 2: Create Role and Permission models

Create a Team model:

```bash
php artisan make:model Team
```

Edit the Team model:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Team extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'owner_id',
        'description',
    ];

    protected static function boot()
    {
        parent::boot();

        static::creating(function ($team) {
            $team->slug = Str::slug($team->name);
        });
    }

    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function users()
    {
        return $this->belongsToMany(User::class)
            ->withTimestamps();
    }

    public function roles()
    {
        return $this->hasMany(config('permission.models.role'));
    }

    public function permissions()
    {
        return $this->hasMany(config('permission.models.permission'));
    }
}
```

Extend the Role and Permission models from the spatie package to support teams:

```bash
php artisan make:model TeamRole
php artisan make:model TeamPermission
```

Edit the TeamRole model:

```php
<?php

namespace App\Models;

use Spatie\Permission\Models\Role as SpatieRole;

class TeamRole extends SpatieRole
{
    public function team()
    {
        return $this->belongsTo(Team::class);
    }
}
```

Edit the TeamPermission model:

```php
<?php

namespace App\Models;

use Spatie\Permission\Models\Permission as SpatiePermission;

class TeamPermission extends SpatiePermission
{
    public function team()
    {
        return $this->belongsTo(Team::class);
    }
}
```

Update the permission config to use your custom models:

```php
// config/permission.php
'models' => [
    'permission' => App\Models\TeamPermission::class,
    'role' => App\Models\TeamRole::class,
],
```

#### Step 3: Implement a TeamHasPermissions trait

Create a TeamHasPermissions trait:

```php
<?php

namespace App\Traits;

use Illuminate\Database\Eloquent\Relations\MorphToMany;
use Spatie\Permission\Contracts\Permission;
use Spatie\Permission\Contracts\Role;
use Spatie\Permission\Exceptions\GuardDoesNotMatch;
use Spatie\Permission\Exceptions\PermissionDoesNotExist;
use Spatie\Permission\Exceptions\RoleDoesNotExist;
use Spatie\Permission\Guard;
use Spatie\Permission\PermissionRegistrar;

trait TeamHasPermissions
{
    public function permissions(): MorphToMany
    {
        return $this->morphToMany(
            config('permission.models.permission'),
            'model',
            config('permission.table_names.model_has_permissions'),
            config('permission.column_names.model_morph_key'),
            'permission_id'
        );
    }

    public function getPermissionsAttribute()
    {
        return $this->getAllPermissions();
    }

    public function getAllPermissions(): array
    {
        return $this->permissions()->get()->all();
    }

    public function hasPermissionTo($permission, $guardName = null): bool
    {
        $permissionClass = $this->getPermissionClass();

        if (is_string($permission)) {
            $permission = $permissionClass->findByName(
                $permission,
                $guardName ?? $this->getDefaultGuardName()
            );
        }

        if (is_int($permission)) {
            $permission = $permissionClass->findById(
                $permission,
                $guardName ?? $this->getDefaultGuardName()
            );
        }

        if (! $permission instanceof Permission) {
            throw new PermissionDoesNotExist();
        }

        return $this->hasDirectPermission($permission);
    }

    public function hasDirectPermission($permission): bool
    {
        $permissionClass = $this->getPermissionClass();

        if (is_string($permission)) {
            $permission = $permissionClass->findByName($permission, $this->getDefaultGuardName());
        }

        if (is_int($permission)) {
            $permission = $permissionClass->findById($permission, $this->getDefaultGuardName());
        }

        if (! $permission instanceof Permission) {
            throw new PermissionDoesNotExist();
        }

        return $this->permissions->contains('id', $permission->id);
    }

    public function givePermissionTo(...$permissions)
    {
        $permissions = collect($permissions)
            ->flatten()
            ->map(function ($permission) {
                if (empty($permission)) {
                    return false;
                }

                return $this->getStoredPermission($permission);
            })
            ->filter(function ($permission) {
                return $permission instanceof Permission;
            })
            ->each(function ($permission) {
                $this->ensureModelSharesGuard($permission);
            })
            ->map->id
            ->all();

        $model = $this->getModel();

        if ($model->exists) {
            $this->permissions()->sync($permissions, false);
            $model->load('permissions');
        } else {
            $class = \get_class($model);

            $class::saved(
                function ($object) use ($permissions, $model) {
                    if ($model->getKey() != $object->getKey()) {
                        return;
                    }
                    $object->permissions()->sync($permissions, false);
                    $object->load('permissions');
                }
            );
        }

        return $this;
    }

    public function revokePermissionTo(...$permissions)
    {
        $permissions = collect($permissions)
            ->flatten()
            ->map(function ($permission) {
                if (empty($permission)) {
                    return false;
                }

                return $this->getStoredPermission($permission);
            })
            ->filter(function ($permission) {
                return $permission instanceof Permission;
            })
            ->map->id
            ->all();

        $this->permissions()->detach($permissions);

        return $this;
    }

    protected function getStoredPermission($permission): Permission
    {
        $permissionClass = $this->getPermissionClass();

        if (is_string($permission)) {
            return $permissionClass->findByName($permission, $this->getDefaultGuardName());
        }

        if (is_int($permission)) {
            return $permissionClass->findById($permission, $this->getDefaultGuardName());
        }

        return $permission;
    }

    protected function getPermissionClass()
    {
        return app(PermissionRegistrar::class)->getPermissionClass();
    }

    protected function getDefaultGuardName(): string
    {
        return Guard::getDefaultName($this);
    }

    protected function ensureModelSharesGuard($permission)
    {
        if (! $permission instanceof Permission) {
            return;
        }

        if ($permission->guard_name !== $this->getDefaultGuardName()) {
            throw GuardDoesNotMatch::create($permission->guard_name, $this->getDefaultGuardName());
        }
    }
}
```

Create a HasTeams trait for the User model:

```php
<?php

namespace App\Traits;

use App\Models\Team;

trait HasTeams
{
    public function teams()
    {
        return $this->belongsToMany(Team::class)
            ->withTimestamps();
    }

    public function ownedTeams()
    {
        return $this->hasMany(Team::class, 'owner_id');
    }

    public function currentTeam()
    {
        return $this->belongsTo(Team::class, 'current_team_id');
    }

    public function isCurrentTeam($team)
    {
        return $this->current_team_id === $team->id;
    }

    public function switchTeam($team)
    {
        if (! $this->belongsToTeam($team)) {
            return false;
        }

        $this->forceFill([
            'current_team_id' => $team->id,
        ])->save();

        return true;
    }

    public function belongsToTeam($team)
    {
        return $this->teams->contains(function ($t) use ($team) {
            return $t->id === $team->id;
        });
    }

    public function hasTeamPermission($team, $permission)
    {
        return $this->belongsToTeam($team) && $team->hasPermissionTo($permission);
    }

    public function hasTeamRole($team, $role)
    {
        return $this->belongsToTeam($team) && $this->roles->contains(function ($r) use ($role, $team) {
            return $r->name === $role && $r->team_id === $team->id;
        });
    }
}
```

#### Step 4: Create methods to assign and check permissions in a team context

Update the User model to use the HasTeams trait:

```php
<?php

namespace App\Models;

use App\Traits\HasTeams;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable
{
    use HasRoles, HasTeams, Notifiable;

    // ...
}
```

Create a TeamPermissionController to manage team permissions:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Team;
use App\Models\TeamPermission;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class TeamPermissionController extends Controller
{
    public function index(Team $team)
    {
        Gate::authorize('view-team-permissions', $team);

        $permissions = $team->permissions;

        return view('teams.permissions.index', compact('team', 'permissions'));
    }

    public function create(Team $team)
    {
        Gate::authorize('create-team-permissions', $team);

        return view('teams.permissions.create', compact('team'));
    }

    public function store(Request $request, Team $team)
    {
        Gate::authorize('create-team-permissions', $team);

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'guard_name' => 'required|string|max:255',
        ]);

        $permission = TeamPermission::create([
            'name' => $validated['name'],
            'guard_name' => $validated['guard_name'],
            'team_id' => $team->id,
        ]);

        return redirect()->route('teams.permissions.index', $team)
            ->with('success', 'Permission created successfully.');
    }

    public function edit(Team $team, TeamPermission $permission)
    {
        Gate::authorize('update-team-permissions', $team);

        return view('teams.permissions.edit', compact('team', 'permission'));
    }

    public function update(Request $request, Team $team, TeamPermission $permission)
    {
        Gate::authorize('update-team-permissions', $team);

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'guard_name' => 'required|string|max:255',
        ]);

        $permission->update([
            'name' => $validated['name'],
            'guard_name' => $validated['guard_name'],
        ]);

        return redirect()->route('teams.permissions.index', $team)
            ->with('success', 'Permission updated successfully.');
    }

    public function destroy(Team $team, TeamPermission $permission)
    {
        Gate::authorize('delete-team-permissions', $team);

        $permission->delete();

        return redirect()->route('teams.permissions.index', $team)
            ->with('success', 'Permission deleted successfully.');
    }

    public function assignToTeam(Request $request, Team $team)
    {
        Gate::authorize('update-team-permissions', $team);

        $validated = $request->validate([
            'permission_id' => 'required|exists:permissions,id',
        ]);

        $permission = TeamPermission::findById($validated['permission_id']);
        $team->givePermissionTo($permission);

        return redirect()->route('teams.permissions.index', $team)
            ->with('success', 'Permission assigned to team successfully.');
    }

    public function revokeFromTeam(Request $request, Team $team, TeamPermission $permission)
    {
        Gate::authorize('update-team-permissions', $team);

        $team->revokePermissionTo($permission);

        return redirect()->route('teams.permissions.index', $team)
            ->with('success', 'Permission revoked from team successfully.');
    }
}
```

#### Step 5: Implement middleware to check team permissions

Create a CheckTeamPermission middleware:

```bash
php artisan make:middleware CheckTeamPermission
```

Edit the middleware:

```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class CheckTeamPermission
{
    public function handle(Request $request, Closure $next, $permission)
    {
        if (! Auth::check()) {
            return redirect()->route('login');
        }

        $user = Auth::user();
        $team = $user->currentTeam();

        if (! $team) {
            abort(403, 'You must be part of a team to access this resource.');
        }

        if (! $user->hasTeamPermission($team, $permission)) {
            abort(403, 'You do not have the required permission to access this resource.');
        }

        return $next($request);
    }
}
```

Register the middleware in the `app/Http/Kernel.php` file:

```php
protected $routeMiddleware = [
    // ...
    'team.permission' => \App\Http\Middleware\CheckTeamPermission::class,
];
```

Use the middleware in routes:

```php
Route::middleware(['auth', 'team.permission:view-team-dashboard'])
    ->get('/teams/{team}/dashboard', [TeamDashboardController::class, 'index'])
    ->name('teams.dashboard');
```

#### Step 6: Create a simple UI for managing team permissions

Create a Livewire component for managing team permissions:

```bash
php artisan make:livewire Teams/ManagePermissions
```

Edit the component class:

```php
<?php

namespace App\Http\Livewire\Teams;

use App\Models\Team;
use App\Models\TeamPermission;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Livewire\Component;

class ManagePermissions extends Component
{
    use AuthorizesRequests;

    public $team;
    public $permissionName = '';
    public $guardName = 'web';
    public $availablePermissions = [];
    public $selectedPermission = null;

    protected $rules = [
        'permissionName' => 'required|string|max:255',
        'guardName' => 'required|string|max:255',
    ];

    public function mount(Team $team)
    {
        $this->team = $team;
        $this->loadAvailablePermissions();
    }

    public function loadAvailablePermissions()
    {
        $this->availablePermissions = TeamPermission::whereNull('team_id')
            ->orWhere('team_id', '!=', $this->team->id)
            ->get();
    }

    public function createPermission()
    {
        $this->authorize('create-team-permissions', $this->team);

        $this->validate();

        TeamPermission::create([
            'name' => $this->permissionName,
            'guard_name' => $this->guardName,
            'team_id' => $this->team->id,
        ]);

        $this->reset(['permissionName', 'guardName']);
        $this->emit('permissionCreated');
    }

    public function assignPermission()
    {
        $this->authorize('update-team-permissions', $this->team);

        $this->validate([
            'selectedPermission' => 'required',
        ]);

        $permission = TeamPermission::findById($this->selectedPermission);
        $this->team->givePermissionTo($permission);

        $this->reset(['selectedPermission']);
        $this->emit('permissionAssigned');
    }

    public function revokePermission($permissionId)
    {
        $this->authorize('update-team-permissions', $this->team);

        $permission = TeamPermission::findById($permissionId);
        $this->team->revokePermissionTo($permission);

        $this->emit('permissionRevoked');
    }

    public function render()
    {
        return view('livewire.teams.manage-permissions', [
            'teamPermissions' => $this->team->permissions,
        ]);
    }
}
```

Create the component view:

```blade
<div>
    <div class="mt-10 sm:mt-0">
        <div class="md:grid md:grid-cols-3 md:gap-6">
            <div class="md:col-span-1">
                <div class="px-4 sm:px-0">
                    <h3 class="text-lg font-medium leading-6 text-gray-900">Team Permissions</h3>
                    <p class="mt-1 text-sm text-gray-600">
                        Manage permissions for this team.
                    </p>
                </div>
            </div>
            <div class="mt-5 md:mt-0 md:col-span-2">
                <div class="shadow overflow-hidden sm:rounded-md">
                    <div class="px-4 py-5 bg-white sm:p-6">
                        <div class="grid grid-cols-6 gap-6">
                            <div class="col-span-6 sm:col-span-4">
                                <h4 class="text-md font-medium text-gray-900 mb-4">Current Permissions</h4>

                                @if($teamPermissions->isEmpty())
                                    <p class="text-sm text-gray-500">This team has no permissions.</p>
                                @else
                                    <ul class="divide-y divide-gray-200">
                                        @foreach($teamPermissions as $permission)
                                            <li class="py-3 flex justify-between">
                                                <div>
                                                    <span class="text-sm font-medium text-gray-900">{{ $permission->name }}</span>
                                                    <span class="text-xs text-gray-500 ml-2">({{ $permission->guard_name }})</span>
                                                </div>
                                                <button wire:click="revokePermission({{ $permission->id }})" type="button" class="text-red-600 hover:text-red-900 text-sm font-medium">
                                                    Revoke
                                                </button>
                                            </li>
                                        @endforeach
                                    </ul>
                                @endif
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="hidden sm:block" aria-hidden="true">
        <div class="py-5">
            <div class="border-t border-gray-200"></div>
        </div>
    </div>

    <div class="mt-10 sm:mt-0">
        <div class="md:grid md:grid-cols-3 md:gap-6">
            <div class="md:col-span-1">
                <div class="px-4 sm:px-0">
                    <h3 class="text-lg font-medium leading-6 text-gray-900">Create New Permission</h3>
                    <p class="mt-1 text-sm text-gray-600">
                        Create a new permission for this team.
                    </p>
                </div>
            </div>
            <div class="mt-5 md:mt-0 md:col-span-2">
                <form wire:submit.prevent="createPermission">
                    <div class="shadow overflow-hidden sm:rounded-md">
                        <div class="px-4 py-5 bg-white sm:p-6">
                            <div class="grid grid-cols-6 gap-6">
                                <div class="col-span-6 sm:col-span-4">
                                    <label for="permission-name" class="block text-sm font-medium text-gray-700">Permission Name</label>
                                    <input type="text" wire:model="permissionName" id="permission-name" class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md">
                                    @error('permissionName') <span class="text-red-500 text-xs">{{ $message }}</span> @enderror
                                </div>

                                <div class="col-span-6 sm:col-span-4">
                                    <label for="guard-name" class="block text-sm font-medium text-gray-700">Guard Name</label>
                                    <input type="text" wire:model="guardName" id="guard-name" class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md">
                                    @error('guardName') <span class="text-red-500 text-xs">{{ $message }}</span> @enderror
                                </div>
                            </div>
                        </div>
                        <div class="px-4 py-3 bg-gray-50 text-right sm:px-6">
                            <button type="submit" class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                                Create Permission
                            </button>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <div class="hidden sm:block" aria-hidden="true">
        <div class="py-5">
            <div class="border-t border-gray-200"></div>
        </div>
    </div>

    <div class="mt-10 sm:mt-0">
        <div class="md:grid md:grid-cols-3 md:gap-6">
            <div class="md:col-span-1">
                <div class="px-4 sm:px-0">
                    <h3 class="text-lg font-medium leading-6 text-gray-900">Assign Existing Permission</h3>
                    <p class="mt-1 text-sm text-gray-600">
                        Assign an existing permission to this team.
                    </p>
                </div>
            </div>
            <div class="mt-5 md:mt-0 md:col-span-2">
                <form wire:submit.prevent="assignPermission">
                    <div class="shadow overflow-hidden sm:rounded-md">
                        <div class="px-4 py-5 bg-white sm:p-6">
                            <div class="grid grid-cols-6 gap-6">
                                <div class="col-span-6 sm:col-span-4">
                                    <label for="permission-select" class="block text-sm font-medium text-gray-700">Select Permission</label>
                                    <select wire:model="selectedPermission" id="permission-select" class="mt-1 block w-full py-2 px-3 border border-gray-300 bg-white rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
                                        <option value="">Select a permission</option>
                                        @foreach($availablePermissions as $permission)
                                            <option value="{{ $permission->id }}">{{ $permission->name }} ({{ $permission->guard_name }})</option>
                                        @endforeach
                                    </select>
                                    @error('selectedPermission') <span class="text-red-500 text-xs">{{ $message }}</span> @enderror
                                </div>
                            </div>
                        </div>
                        <div class="px-4 py-3 bg-gray-50 text-right sm:px-6">
                            <button type="submit" class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                                Assign Permission
                            </button>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
```

#### Step 7: Write tests to verify the permission system works correctly

Create a test for the team permission system:

```bash
php artisan make:test TeamPermissionTest
```

Edit the test file:

```php
<?php

namespace Tests\Feature;

use App\Models\Team;use App\Models\TeamPermission;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;

class TeamPermissionTest extends TestCase
{
    use RefreshDatabase;

    public function test_team_can_be_assigned_permissions()
    {
        $user = User::factory()->create();
        $team = Team::create([
            'name' => 'Test Team',
            'owner_id' => $user->id,
        ]);

        $permission = TeamPermission::create([
            'name' => 'test-permission',
            'guard_name' => 'web',
        ]);

        $team->givePermissionTo($permission);

        $this->assertTrue($team->hasPermissionTo('test-permission'));
    }

    public function test_user_can_check_team_permissions()
    {
        $user = User::factory()->create();
        $team = Team::create([
            'name' => 'Test Team',
            'owner_id' => $user->id,
        ]);

        $team->users()->attach($user);
        $user->switchTeam($team);

        $permission = TeamPermission::create([
            'name' => 'test-permission',
            'guard_name' => 'web',
        ]);

        $team->givePermissionTo($permission);

        $this->assertTrue($user->hasTeamPermission($team, 'test-permission'));
    }

    public function test_middleware_blocks_unauthorized_access()
    {
        $user = User::factory()->create();
        $team = Team::create([
            'name' => 'Test Team',
            'owner_id' => $user->id,
        ]);

        $team->users()->attach($user);
        $user->switchTeam($team);

        $permission = TeamPermission::create([
            'name' => 'view-dashboard',
            'guard_name' => 'web',
        ]);

        // User doesn't have the required permission
        $response = $this->actingAs($user)
            ->get(route('teams.dashboard', $team));

        $response->assertStatus(403);

        // Give the permission and try again
        $team->givePermissionTo($permission);

        $response = $this->actingAs($user)
            ->get(route('teams.dashboard', $team));

        $response->assertStatus(200);
    }

    public function test_livewire_component_can_manage_permissions()
    {
        $user = User::factory()->create();
        $team = Team::create([
            'name' => 'Test Team',
            'owner_id' => $user->id,
        ]);

        $this->actingAs($user);

        // Test creating a permission
        Livewire::test('teams.manage-permissions', ['team' => $team])
            ->set('permissionName', 'test-permission')
            ->set('guardName', 'web')
            ->call('createPermission')
            ->assertEmitted('permissionCreated');

        $this->assertTrue($team->fresh()->permissions->contains('name', 'test-permission'));

        // Test revoking a permission
        $permission = TeamPermission::where('name', 'test-permission')->first();

        Livewire::test('teams.manage-permissions', ['team' => $team])
            ->call('revokePermission', $permission->id)
            ->assertEmitted('permissionRevoked');

        $this->assertFalse($team->fresh()->permissions->contains('name', 'test-permission'));
    }
}
```

### Implementation Choices Explanation

1. **Using spatie/laravel-permission as the Base**:
   - The spatie/laravel-permission package provides a solid foundation for role-based permissions.
   - By extending it with team-specific functionality, we leverage its well-tested core while adding the team context we need.

2. **Polymorphic Relationships for Team Permissions**:
   - Using polymorphic relationships allows permissions to be associated with different models (users, teams).
   - This approach is more flexible than adding a team_id column to the permissions table, as it allows for global permissions as well as team-specific ones.

3. **Middleware for Permission Checks**:
   - The middleware approach centralizes permission checking logic.
   - It makes routes more declarative and reduces duplication of authorization code.
   - It's easy to apply to multiple routes that require the same permissions.

4. **Livewire for UI Components**:
   - Livewire provides a reactive UI without writing JavaScript.
   - It handles form validation and real-time updates seamlessly.
   - The component-based approach makes the code more maintainable and testable.

5. **Comprehensive Testing**:
   - Tests cover both the model relationships and the middleware functionality.
   - Livewire component tests ensure the UI works correctly.
   - Testing different scenarios (with and without permissions) ensures the system behaves as expected in all cases.

## Set 2: Team Management and Invitations

### Question Answers

1. **How are team invitations handled in the UME tutorial?**
   - **Answer: B) By creating an invitation record and sending an email with a token**
   - **Explanation:** In the UME tutorial, team invitations are handled by creating an invitation record in the database and sending an email to the invitee with a unique token. When the invitee clicks the link in the email, they are taken to a page where they can accept or reject the invitation. This approach provides a secure way to manage invitations and allows for tracking pending invitations.

2. **What is the purpose of the team_user pivot table?**
   - **Answer: B) To track which users belong to which teams**
   - **Explanation:** The team_user pivot table is used to establish a many-to-many relationship between users and teams. It tracks which users belong to which teams, allowing a user to be a member of multiple teams and a team to have multiple members. This table typically includes user_id and team_id columns, and may also include additional information such as the user's role within the team.

3. **What role does the current_team_id column serve in the users table?**
   - **Answer: B) It indicates which team the user is currently viewing/working with**
   - **Explanation:** The current_team_id column in the users table indicates which team the user is currently viewing or working with. This allows the application to show team-specific content and apply team-specific permissions based on the user's current context. Users can switch between teams they belong to, and this column keeps track of their current selection.

4. **How can a user switch between teams in the UME tutorial?**
   - **Answer: B) By using the team switcher in the UI**
   - **Explanation:** In the UME tutorial, users can switch between teams using a team switcher component in the UI. This component typically appears in the navigation bar or sidebar and shows a list of teams the user belongs to. When the user selects a different team, the application updates the user's current_team_id and refreshes the content to show the selected team's context.

### Exercise Solution: Implement a team invitation system

#### Step 1: Create a migration for the team_invitations table

```bash
php artisan make:migration create_team_invitations_table
```

Edit the migration file:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('team_invitations', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('team_id');
            $table->string('email');
            $table->string('role')->nullable();
            $table->string('token', 40)->unique();
            $table->timestamps();

            $table->foreign('team_id')->references('id')->on('teams')->onDelete('cascade');
            $table->unique(['team_id', 'email']);
        });
    }

    public function down()
    {
        Schema::dropIfExists('team_invitations');
    }
};
```

Run the migration:

```bash
php artisan migrate
```

#### Step 2: Implement a TeamInvitation model

```bash
php artisan make:model TeamInvitation
```

Edit the TeamInvitation model:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class TeamInvitation extends Model
{
    use HasFactory;

    protected $fillable = [
        'team_id',
        'email',
        'role',
    ];

    protected static function boot()
    {
        parent::boot();

        static::creating(function ($invitation) {
            $invitation->token = Str::random(40);
        });
    }

    public function team()
    {
        return $this->belongsTo(Team::class);
    }

    public function accept(User $user)
    {
        $user->teams()->attach($this->team_id, ['role' => $this->role]);

        if (! $user->current_team_id) {
            $user->forceFill(['current_team_id' => $this->team_id])->save();
        }

        $this->delete();

        return $this->team;
    }

    public function reject()
    {
        $this->delete();
    }
}
```

#### Step 3: Create a controller for sending and accepting invitations

```bash
php artisan make:controller TeamInvitationController
```

Edit the TeamInvitationController:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Team;
use App\Models\TeamInvitation;
use App\Models\User;
use App\Notifications\TeamInvitation as TeamInvitationNotification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Gate;

class TeamInvitationController extends Controller
{
    public function store(Request $request, Team $team)
    {
        Gate::authorize('invite', $team);

        $validated = $request->validate([
            'email' => 'required|email',
            'role' => 'nullable|string',
        ]);

        // Check if the user is already on the team
        $user = User::where('email', $validated['email'])->first();
        if ($user && $team->users->contains($user)) {
            return back()->withErrors([
                'email' => 'This user is already on the team.',
            ]);
        }

        // Check if there's already an invitation
        $existingInvitation = TeamInvitation::where('team_id', $team->id)
            ->where('email', $validated['email'])
            ->first();

        if ($existingInvitation) {
            return back()->withErrors([
                'email' => 'An invitation has already been sent to this email address.',
            ]);
        }

        $invitation = TeamInvitation::create([
            'team_id' => $team->id,
            'email' => $validated['email'],
            'role' => $validated['role'] ?? null,
        ]);

        // Send the invitation email
        $user = User::where('email', $validated['email'])->first();
        if ($user) {
            $user->notify(new TeamInvitationNotification($invitation));
        } else {
            // Send invitation to non-registered user
            // This would typically involve sending an email with registration instructions
            // and the invitation token
        }

        return back()->with('success', 'Invitation sent successfully.');
    }

    public function accept(Request $request, $token)
    {
        $invitation = TeamInvitation::where('token', $token)->firstOrFail();

        // If the user is not logged in, redirect to login
        if (! Auth::check()) {
            return redirect()->route('login', ['invitation' => $token]);
        }

        $user = Auth::user();

        // Check if the invitation email matches the authenticated user
        if ($invitation->email !== $user->email) {
            return redirect()->route('dashboard')->withErrors([
                'invitation' => 'This invitation is not for your account.',
            ]);
        }

        $team = $invitation->accept($user);

        return redirect()->route('teams.show', $team)
            ->with('success', 'You have joined the team successfully.');
    }

    public function reject(Request $request, $token)
    {
        $invitation = TeamInvitation::where('token', $token)->firstOrFail();

        // If the user is not logged in, redirect to login
        if (! Auth::check()) {
            return redirect()->route('login', ['invitation' => $token]);
        }

        $user = Auth::user();

        // Check if the invitation email matches the authenticated user
        if ($invitation->email !== $user->email) {
            return redirect()->route('dashboard')->withErrors([
                'invitation' => 'This invitation is not for your account.',
            ]);
        }

        $invitation->reject();

        return redirect()->route('dashboard')
            ->with('success', 'You have rejected the team invitation.');
    }

    public function destroy(Team $team, TeamInvitation $invitation)
    {
        Gate::authorize('removeInvitation', [$team, $invitation]);

        $invitation->delete();

        return back()->with('success', 'Invitation cancelled successfully.');
    }
}
```

#### Step 4: Implement email notifications for invitations

```bash
php artisan make:notification TeamInvitation
```

Edit the notification class:

```php
<?php

namespace App\Notifications;

use App\Models\TeamInvitation as TeamInvitationModel;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;
use Illuminate\Support\Facades\URL;

class TeamInvitation extends Notification implements ShouldQueue
{
    use Queueable;

    protected $invitation;

    public function __construct(TeamInvitationModel $invitation)
    {
        $this->invitation = $invitation;
    }

    public function via($notifiable)
    {
        return ['mail'];
    }

    public function toMail($notifiable)
    {
        $acceptUrl = URL::signedRoute('team-invitations.accept', [
            'token' => $this->invitation->token,
        ]);

        $rejectUrl = URL::signedRoute('team-invitations.reject', [
            'token' => $this->invitation->token,
        ]);

        return (new MailMessage)
            ->subject('Team Invitation')
            ->greeting('Hello!')
            ->line('You have been invited to join the ' . $this->invitation->team->name . ' team.')
            ->action('Accept Invitation', $acceptUrl)
            ->line('If you do not wish to join this team, you can ignore this email or click the link below:')
            ->line('[Reject Invitation](' . $rejectUrl . ')')
            ->line('Thank you for using our application!');
    }

    public function toArray($notifiable)
    {
        return [
            'team_id' => $this->invitation->team_id,
            'team_name' => $this->invitation->team->name,
            'invitation_id' => $this->invitation->id,
        ];
    }
}
```

Add the routes for handling invitations in `routes/web.php`:

```php
Route::get('/team-invitations/{token}', [TeamInvitationController::class, 'accept'])
    ->middleware(['signed'])
    ->name('team-invitations.accept');

Route::get('/team-invitations/{token}/reject', [TeamInvitationController::class, 'reject'])
    ->middleware(['signed'])
    ->name('team-invitations.reject');

Route::middleware(['auth'])->group(function () {
    Route::post('/teams/{team}/invitations', [TeamInvitationController::class, 'store'])
        ->name('team-invitations.store');

    Route::delete('/teams/{team}/invitations/{invitation}', [TeamInvitationController::class, 'destroy'])
        ->name('team-invitations.destroy');
});
```

#### Step 5: Create Livewire components for invitation management

Create a Livewire component for sending invitations:

```bash
php artisan make:livewire Teams/InviteMember
```

Edit the component class:

```php
<?php

namespace App\Http\Livewire\Teams;

use App\Models\Team;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Livewire\Component;

class InviteMember extends Component
{
    use AuthorizesRequests;

    public $team;
    public $email = '';
    public $role = '';
    public $availableRoles = [
        'member' => 'Member',
        'admin' => 'Admin',
    ];

    protected $rules = [
        'email' => 'required|email',
        'role' => 'required|string',
    ];

    public function mount(Team $team)
    {
        $this->team = $team;
        $this->role = 'member';
    }

    public function invite()
    {
        $this->authorize('invite', $this->team);

        $this->validate();

        $response = app(TeamInvitationController::class)->store(
            request: new \Illuminate\Http\Request([
                'email' => $this->email,
                'role' => $this->role,
            ]),
            team: $this->team
        );

        if ($response->getSession()->has('errors')) {
            $this->addError('email', $response->getSession()->get('errors')->first('email'));
            return;
        }

        $this->reset(['email']);
        $this->emit('invitationSent');
    }

    public function render()
    {
        return view('livewire.teams.invite-member');
    }
}
```

Create the component view:

```blade
<div>
    <div class="mt-10 sm:mt-0">
        <div class="md:grid md:grid-cols-3 md:gap-6">
            <div class="md:col-span-1">
                <div class="px-4 sm:px-0">
                    <h3 class="text-lg font-medium leading-6 text-gray-900">Invite Team Member</h3>
                    <p class="mt-1 text-sm text-gray-600">
                        Invite a new member to your team.
                    </p>
                </div>
            </div>
            <div class="mt-5 md:mt-0 md:col-span-2">
                <form wire:submit.prevent="invite">
                    <div class="shadow overflow-hidden sm:rounded-md">
                        <div class="px-4 py-5 bg-white sm:p-6">
                            <div class="grid grid-cols-6 gap-6">
                                <div class="col-span-6 sm:col-span-4">
                                    <label for="email" class="block text-sm font-medium text-gray-700">Email address</label>
                                    <input type="email" wire:model.defer="email" id="email" class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md">
                                    @error('email') <span class="text-red-500 text-xs">{{ $message }}</span> @enderror
                                </div>

                                <div class="col-span-6 sm:col-span-4">
                                    <label for="role" class="block text-sm font-medium text-gray-700">Role</label>
                                    <select wire:model.defer="role" id="role" class="mt-1 block w-full py-2 px-3 border border-gray-300 bg-white rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
                                        @foreach($availableRoles as $value => $label)
                                            <option value="{{ $value }}">{{ $label }}</option>
                                        @endforeach
                                    </select>
                                    @error('role') <span class="text-red-500 text-xs">{{ $message }}</span> @enderror
                                </div>
                            </div>
                        </div>
                        <div class="px-4 py-3 bg-gray-50 text-right sm:px-6">
                            <button type="submit" class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                                Send Invitation
                            </button>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
```

Create a Livewire component for listing pending invitations:

```bash
php artisan make:livewire Teams/PendingInvitations
```

Edit the component class:

```php
<?php

namespace App\Http\Livewire\Teams;

use App\Models\Team;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Livewire\Component;

class PendingInvitations extends Component
{
    use AuthorizesRequests;

    public $team;

    protected $listeners = [
        'invitationSent' => '$refresh',
        'invitationCancelled' => '$refresh',
    ];

    public function mount(Team $team)
    {
        $this->team = $team;
    }

    public function cancelInvitation($invitationId)
    {
        $invitation = $this->team->invitations()->findOrFail($invitationId);

        $this->authorize('removeInvitation', [$this->team, $invitation]);

        $invitation->delete();

        $this->emit('invitationCancelled');
    }

    public function render()
    {
        return view('livewire.teams.pending-invitations', [
            'invitations' => $this->team->invitations,
        ]);
    }
}
```

Create the component view:

```blade
<div>
    <div class="mt-10 sm:mt-0">
        <div class="md:grid md:grid-cols-3 md:gap-6">
            <div class="md:col-span-1">
                <div class="px-4 sm:px-0">
                    <h3 class="text-lg font-medium leading-6 text-gray-900">Pending Invitations</h3>
                    <p class="mt-1 text-sm text-gray-600">
                        Manage pending team invitations.
                    </p>
                </div>
            </div>
            <div class="mt-5 md:mt-0 md:col-span-2">
                <div class="shadow overflow-hidden sm:rounded-md">
                    <div class="px-4 py-5 bg-white sm:p-6">
                        @if($invitations->isEmpty())
                            <p class="text-sm text-gray-500">There are no pending invitations.</p>
                        @else
                            <ul class="divide-y divide-gray-200">
                                @foreach($invitations as $invitation)
                                    <li class="py-3 flex justify-between">
                                        <div>
                                            <span class="text-sm font-medium text-gray-900">{{ $invitation->email }}</span>
                                            @if($invitation->role)
                                                <span class="text-xs text-gray-500 ml-2">({{ ucfirst($invitation->role) }})</span>
                                            @endif
                                            <span class="text-xs text-gray-500 block">Invited {{ $invitation->created_at->diffForHumans() }}</span>
                                        </div>
                                        <button wire:click="cancelInvitation({{ $invitation->id }})" type="button" class="text-red-600 hover:text-red-900 text-sm font-medium">
                                            Cancel
                                        </button>
                                    </li>
                                @endforeach
                            </ul>
                        @endif
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
```

Create a Livewire component for accepting/rejecting invitations:

```bash
php artisan make:livewire Teams/AcceptInvitation
```

Edit the component class:

```php
<?php

namespace App\Http\Livewire\Teams;

use App\Models\TeamInvitation;
use Illuminate\Support\Facades\Auth;
use Livewire\Component;

class AcceptInvitation extends Component
{
    public $invitation;
    public $token;

    public function mount($token)
    {
        $this->token = $token;
        $this->invitation = TeamInvitation::where('token', $token)->firstOrFail();
    }

    public function accept()
    {
        if (! Auth::check()) {
            return redirect()->route('login', ['invitation' => $this->token]);
        }

        $user = Auth::user();

        if ($this->invitation->email !== $user->email) {
            $this->addError('email', 'This invitation is not for your account.');
            return;
        }

        $team = $this->invitation->accept($user);

        return redirect()->route('teams.show', $team)
            ->with('success', 'You have joined the team successfully.');
    }

    public function reject()
    {
        if (! Auth::check()) {
            return redirect()->route('login', ['invitation' => $this->token]);
        }

        $user = Auth::user();

        if ($this->invitation->email !== $user->email) {
            $this->addError('email', 'This invitation is not for your account.');
            return;
        }

        $this->invitation->reject();

        return redirect()->route('dashboard')
            ->with('success', 'You have rejected the team invitation.');
    }

    public function render()
    {
        return view('livewire.teams.accept-invitation', [
            'team' => $this->invitation->team,
        ]);
    }
}
```

Create the component view:

```blade
<div>
    <div class="bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:px-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900">Team Invitation</h3>
            <p class="mt-1 max-w-2xl text-sm text-gray-500">You have been invited to join a team.</p>
        </div>
        <div class="border-t border-gray-200">
            <dl>
                <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                    <dt class="text-sm font-medium text-gray-500">Team</dt>
                    <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">{{ $team->name }}</dd>
                </div>
                <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                    <dt class="text-sm font-medium text-gray-500">Invited by</dt>
                    <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">{{ $team->owner->name }}</dd>
                </div>
                <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                    <dt class="text-sm font-medium text-gray-500">Email</dt>
                    <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">{{ $invitation->email }}</dd>
                </div>
                @if($invitation->role)
                    <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                        <dt class="text-sm font-medium text-gray-500">Role</dt>
                        <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">{{ ucfirst($invitation->role) }}</dd>
                    </div>
                @endif
                @error('email')
                    <div class="bg-red-50 px-4 py-5 sm:px-6">
                        <p class="text-sm text-red-600">{{ $message }}</p>
                    </div>
                @enderror
            </dl>
        </div>
        <div class="px-4 py-3 bg-gray-50 text-right sm:px-6">
            <button wire:click="reject" type="button" class="inline-flex justify-center py-2 px-4 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 mr-2">
                Reject
            </button>
            <button wire:click="accept" type="button" class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                Accept
            </button>
        </div>
    </div>
</div>
```

#### Step 6: Add validation and error handling

Create a form request for team invitations:

```bash
php artisan make:request TeamInvitationRequest
```

Edit the request class:

```php
<?php

namespace App\Http\Requests;

use App\Models\Team;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Gate;

class TeamInvitationRequest extends FormRequest
{
    public function authorize()
    {
        return Gate::allows('invite', $this->route('team'));
    }

    public function rules()
    {
        return [
            'email' => [
                'required',
                'email',
                function ($attribute, $value, $fail) {
                    $team = $this->route('team');

                    // Check if the user is already on the team
                    $userExists = $team->users()->whereHas('user', function ($query) use ($value) {
                        $query->where('email', $value);
                    })->exists();

                    if ($userExists) {
                        $fail('This user is already on the team.');
                    }

                    // Check if there's already an invitation
                    $invitationExists = $team->invitations()->where('email', $value)->exists();

                    if ($invitationExists) {
                        $fail('An invitation has already been sent to this email address.');
                    }
                },
            ],
            'role' => 'nullable|string|in:member,admin',
        ];
    }

    public function messages()
    {
        return [
            'email.required' => 'Please enter an email address.',
            'email.email' => 'Please enter a valid email address.',
            'role.in' => 'The selected role is invalid.',
        ];
    }
}
```

Update the TeamInvitationController to use the form request:

```php
public function store(TeamInvitationRequest $request, Team $team)
{
    $validated = $request->validated();

    $invitation = TeamInvitation::create([
        'team_id' => $team->id,
        'email' => $validated['email'],
        'role' => $validated['role'] ?? null,
    ]);

    // Send the invitation email
    $user = User::where('email', $validated['email'])->first();
    if ($user) {
        $user->notify(new TeamInvitationNotification($invitation));
    } else {
        // Send invitation to non-registered user
        // This would typically involve sending an email with registration instructions
        // and the invitation token
    }

    return back()->with('success', 'Invitation sent successfully.');
}
```

#### Step 7: Implement authorization policies for team management

Create a policy for teams:

```bash
php artisan make:policy TeamPolicy --model=Team
```

Edit the policy:

```php
<?php

namespace App\Policies;

use App\Models\Team;
use App\Models\TeamInvitation;
use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

class TeamPolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user)
    {
        return true;
    }

    public function view(User $user, Team $team)
    {
        return $user->belongsToTeam($team);
    }

    public function create(User $user)
    {
        return true;
    }

    public function update(User $user, Team $team)
    {
        return $user->id === $team->owner_id || $user->hasTeamRole($team, 'admin');
    }

    public function delete(User $user, Team $team)
    {
        return $user->id === $team->owner_id;
    }

    public function invite(User $user, Team $team)
    {
        return $user->id === $team->owner_id || $user->hasTeamRole($team, 'admin');
    }

    public function removeInvitation(User $user, Team $team, TeamInvitation $invitation)
    {
        return $invitation->team_id === $team->id &&
               ($user->id === $team->owner_id || $user->hasTeamRole($team, 'admin'));
    }

    public function addMember(User $user, Team $team)
    {
        return $user->id === $team->owner_id || $user->hasTeamRole($team, 'admin');
    }

    public function removeMember(User $user, Team $team, User $targetUser)
    {
        // Can't remove the team owner
        if ($targetUser->id === $team->owner_id) {
            return false;
        }

        // Team owner can remove anyone
        if ($user->id === $team->owner_id) {
            return true;
        }

        // Admins can remove regular members but not other admins
        return $user->hasTeamRole($team, 'admin') &&
               !$targetUser->hasTeamRole($team, 'admin');
    }
}
```

Register the policy in `AuthServiceProvider.php`:

```php
protected $policies = [
    Team::class => TeamPolicy::class,
];
```

#### Step 8: Write tests for the invitation system

Create a test for the team invitation system:

```bash
php artisan make:test TeamInvitationTest
```

Edit the test file:

```php
<?php

namespace Tests\Feature;

use App\Models\Team;use App\Models\TeamInvitation;use App\Models\User;use App\Notifications\TeamInvitation as TeamInvitationNotification;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Support\Facades\Notification;use Livewire\Livewire;use old\TestCase;

class TeamInvitationTest extends TestCase
{
    use RefreshDatabase;

    public function test_team_owner_can_send_invitations()
    {
        Notification::fake();

        $user = User::factory()->create();
        $team = Team::create([
            'name' => 'Test Team',
            'owner_id' => $user->id,
        ]);

        $response = $this->actingAs($user)
            ->post(route('team-invitations.store', $team), [
                'email' => 'test@example.com',
                'role' => 'member',
            ]);

        $response->assertSessionHasNoErrors();
        $this->assertDatabaseHas('team_invitations', [
            'team_id' => $team->id,
            'email' => 'test@example.com',
            'role' => 'member',
        ]);

        Notification::assertNothingSent();
    }

    public function test_existing_user_receives_invitation_notification()
    {
        Notification::fake();

        $owner = User::factory()->create();
        $user = User::factory()->create();
        $team = Team::create([
            'name' => 'Test Team',
            'owner_id' => $owner->id,
        ]);

        $response = $this->actingAs($owner)
            ->post(route('team-invitations.store', $team), [
                'email' => $user->email,
                'role' => 'member',
            ]);

        $response->assertSessionHasNoErrors();

        $invitation = TeamInvitation::where('email', $user->email)->first();
        $this->assertNotNull($invitation);

        Notification::assertSentTo($user, TeamInvitationNotification::class);
    }

    public function test_user_cannot_invite_already_team_member()
    {
        $owner = User::factory()->create();
        $user = User::factory()->create();
        $team = Team::create([
            'name' => 'Test Team',
            'owner_id' => $owner->id,
        ]);

        $team->users()->attach($user);

        $response = $this->actingAs($owner)
            ->post(route('team-invitations.store', $team), [
                'email' => $user->email,
                'role' => 'member',
            ]);

        $response->assertSessionHasErrors('email');
    }

    public function test_user_can_accept_invitation()
    {
        $owner = User::factory()->create();
        $user = User::factory()->create();
        $team = Team::create([
            'name' => 'Test Team',
            'owner_id' => $owner->id,
        ]);

        $invitation = TeamInvitation::create([
            'team_id' => $team->id,
            'email' => $user->email,
            'role' => 'member',
        ]);

        $response = $this->actingAs($user)
            ->get(route('team-invitations.accept', $invitation->token));

        $response->assertRedirect(route('teams.show', $team));
        $this->assertTrue($user->belongsToTeam($team));
        $this->assertDatabaseMissing('team_invitations', [
            'id' => $invitation->id,
        ]);
    }

    public function test_user_can_reject_invitation()
    {
        $owner = User::factory()->create();
        $user = User::factory()->create();
        $team = Team::create([
            'name' => 'Test Team',
            'owner_id' => $owner->id,
        ]);

        $invitation = TeamInvitation::create([
            'team_id' => $team->id,
            'email' => $user->email,
            'role' => 'member',
        ]);

        $response = $this->actingAs($user)
            ->get(route('team-invitations.reject', $invitation->token));

        $response->assertRedirect(route('dashboard'));
        $this->assertFalse($user->belongsToTeam($team));
        $this->assertDatabaseMissing('team_invitations', [
            'id' => $invitation->id,
        ]);
    }

    public function test_livewire_component_can_send_invitation()
    {
        Notification::fake();

        $user = User::factory()->create();
        $team = Team::create([
            'name' => 'Test Team',
            'owner_id' => $user->id,
        ]);

        Livewire::actingAs($user)
            ->test('teams.invite-member', ['team' => $team])
            ->set('email', 'test@example.com')
            ->set('role', 'member')
            ->call('invite')
            ->assertEmitted('invitationSent');

        $this->assertDatabaseHas('team_invitations', [
            'team_id' => $team->id,
            'email' => 'test@example.com',
            'role' => 'member',
        ]);
    }
}
```

### Implementation Choices Explanation

1. **Using a Dedicated TeamInvitation Model**:
   - The TeamInvitation model provides a clean way to track and manage invitations.
   - It includes methods for accepting and rejecting invitations, encapsulating this logic within the model.
   - The model automatically generates a secure token upon creation.

2. **Email Notifications for Invitations**:
   - Using Laravel's notification system provides a standardized way to send invitation emails.
   - The notification includes both accept and reject links, giving users clear options.
   - Implementing the ShouldQueue interface ensures that sending emails doesn't block the application.

3. **Livewire Components for UI**:
   - Livewire components provide a reactive UI without writing JavaScript.
   - The components handle form validation and real-time updates.
   - Separating the UI into distinct components (InviteMember, PendingInvitations, AcceptInvitation) follows the single responsibility principle.

4. **Authorization Policies**:
   - The TeamPolicy centralizes authorization logic, making it easier to maintain and update.
   - It covers various team-related actions, including invitation management.
   - The policy ensures that only authorized users can perform sensitive actions.

5. **Comprehensive Testing**:
   - Tests cover the entire invitation flow, from sending to accepting/rejecting.
   - They verify both controller actions and Livewire components.
   - Edge cases like inviting existing team members are also tested.

6. **Validation and Error Handling**:
   - Form requests provide a clean way to validate input and handle authorization.
   - Custom validation rules ensure that invitations are only sent to valid recipients.
   - Clear error messages help users understand and resolve issues.
