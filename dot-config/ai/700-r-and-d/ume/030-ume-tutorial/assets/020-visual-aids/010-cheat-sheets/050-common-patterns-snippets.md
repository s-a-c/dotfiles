# Common Patterns and Snippets

<link rel="stylesheet" href="../../css/styles.css">
<link rel="stylesheet" href="../../css/ume-docs-enhancements.css">
<script src="../../js/ume-docs-enhancements.js"></script>

## Overview

This cheat sheet provides a collection of common patterns and code snippets used throughout the UME system. These patterns represent best practices and solutions to common problems you'll encounter when working with enhanced user models.

## Database Patterns

### Migration Patterns

```php
// Adding user type column with default value
Schema::table('users', function (Blueprint $table) {
    $table->string('type')->default('App\\Models\\User')->after('id');
});

// Adding ULID column
Schema::table('users', function (Blueprint $table) {
    $table->ulid('ulid')->after('id')->unique();
});

// Adding user tracking columns
Schema::table('posts', function (Blueprint $table) {
    $table->foreignId('created_by')->nullable()->constrained('users');
    $table->foreignId('updated_by')->nullable()->constrained('users');
    $table->foreignId('deleted_by')->nullable()->constrained('users');
});

// Adding state column
Schema::table('users', function (Blueprint $table) {
    $table->string('status')->default('pending');
});

// Adding team membership table
Schema::create('team_user', function (Blueprint $table) {
    $table->id();
    $table->foreignId('team_id')->constrained()->cascadeOnDelete();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->string('role')->default('member');
    $table->timestamps();
    
    $table->unique(['team_id', 'user_id']);
});
```

### Eloquent Query Patterns

```php
// Query by user type
$admins = User::where('type', Admin::class)->get();

// Query by state
$activeUsers = User::whereState('status', Active::class)->get();

// Query with team relationship
$teamMembers = User::whereHas('teams', function ($query) use ($teamId) {
    $query->where('teams.id', $teamId);
})->get();

// Query with permission
$usersWithPermission = User::permission('edit-posts')->get();

// Query with team permission
$usersWithTeamPermission = User::whereHas('teams', function ($query) use ($teamId, $permission) {
    $query->where('teams.id', $teamId)
          ->whereHas('permissions', function ($q) use ($permission) {
              $q->where('name', $permission);
          });
})->get();
```

## Model Patterns

### Single Table Inheritance

```php
// Base User model
class User extends Authenticatable
{
    protected $fillable = [
        'name', 'email', 'password', 'type',
    ];
    
    protected $casts = [
        'type' => AsClassName::class,
    ];
    
    public function newInstance($attributes = [], $exists = false)
    {
        $model = isset($attributes['type']) 
            ? new $attributes['type'] 
            : new static;
            
        $model->exists = $exists;
        $model->setTable($this->getTable());
        $model->fill((array) $attributes);
        
        return $model;
    }
}

// Child model
class Admin extends User
{
    protected $attributes = [
        'type' => Admin::class,
    ];
    
    public function canAccessAdminPanel(): bool
    {
        return true;
    }
}
```

### HasUlid Trait

```php
// Using the HasUlid trait
class User extends Authenticatable
{
    use HasUlid;
    
    // The rest of your model...
}

// Finding a model by ULID
$user = User::findByUlid('01FXYZ123456789ABCDEFGHIJK');

// Using ULID in routes
Route::get('/users/{user:ulid}', [UserController::class, 'show']);
```

### HasUserTracking Trait

```php
// Using the HasUserTracking trait
class Post extends Model
{
    use HasUserTracking;
    
    // The rest of your model...
}

// Creating a model with tracking
$post = Post::create([
    'title' => 'New Post',
    'content' => 'Post content',
]);
// created_by is automatically set to the current user

// Updating a model with tracking
$post->update([
    'title' => 'Updated Title',
]);
// updated_by is automatically set to the current user

// Soft deleting with tracking
$post->delete();
// deleted_by is automatically set to the current user
```

### State Machine Patterns

```php
// Using the HasStates trait
class User extends Authenticatable
{
    use HasStates;
    
    protected function registerStates(): void
    {
        $this->addState('status', UserState::class)
            ->allowTransition(Pending::class, Active::class, VerifyEmailTransition::class)
            ->allowTransition(Active::class, Suspended::class)
            ->allowTransition(Suspended::class, Active::class);
    }
}

// Transitioning states
$user->status->transitionTo(Active::class);

// Checking current state
if ($user->status instanceof Active) {
    // User is active
}

// Conditional logic based on state
$canLogin = $user->status->canLogin();
```

## Authentication Patterns

### Registration

```php
// Custom registration with user type
public function register(Request $request)
{
    $request->validate([
        'name' => ['required', 'string', 'max:255'],
        'email' => ['required', 'string', 'email', 'max:255', 'unique:users'],
        'password' => ['required', 'string', 'min:8', 'confirmed'],
        'user_type' => ['required', 'string', 'in:customer,vendor'],
    ]);
    
    $userClass = $request->user_type === 'customer' 
        ? Customer::class 
        : Vendor::class;
    
    $user = $userClass::create([
        'name' => $request->name,
        'email' => $request->email,
        'password' => Hash::make($request->password),
        'type' => $userClass,
    ]);
    
    event(new Registered($user));
    
    Auth::login($user);
    
    return redirect(RouteServiceProvider::HOME);
}
```

### Two-Factor Authentication

```php
// Enable 2FA
public function enableTwoFactorAuth(Request $request)
{
    $user = $request->user();
    
    // Generate a secret
    $secret = Google2FA::generateSecretKey();
    
    // Store the secret
    $user->two_factor_secret = $secret;
    $user->save();
    
    // Generate QR code
    $qrCode = Google2FA::getQRCodeInline(
        config('app.name'),
        $user->email,
        $secret
    );
    
    return view('auth.two-factor.enable', [
        'qrCode' => $qrCode,
        'secret' => $secret,
    ]);
}

// Verify 2FA code
public function verifyTwoFactorAuth(Request $request)
{
    $request->validate([
        'code' => ['required', 'numeric', 'digits:6'],
    ]);
    
    $user = $request->user();
    
    $valid = Google2FA::verifyKey(
        $user->two_factor_secret,
        $request->code
    );
    
    if ($valid) {
        $user->two_factor_enabled = true;
        $user->save();
        
        return redirect()->route('profile.show')
            ->with('status', 'Two-factor authentication has been enabled.');
    }
    
    return back()->withErrors([
        'code' => 'The provided code is invalid.',
    ]);
}
```

## Team and Permission Patterns

### Team Creation

```php
// Create a team
public function store(Request $request)
{
    $request->validate([
        'name' => ['required', 'string', 'max:255'],
    ]);
    
    $team = Team::create([
        'name' => $request->name,
        'owner_id' => $request->user()->id,
    ]);
    
    $request->user()->teams()->attach($team, ['role' => 'owner']);
    
    return redirect()->route('teams.show', $team)
        ->with('status', 'Team created successfully.');
}
```

### Team Membership

```php
// Add a member to a team
public function addMember(Team $team, Request $request)
{
    $request->validate([
        'email' => ['required', 'email', 'exists:users,email'],
        'role' => ['required', 'string', 'in:member,admin'],
    ]);
    
    $user = User::where('email', $request->email)->first();
    
    // Check if already a member
    if ($team->users()->where('user_id', $user->id)->exists()) {
        return back()->withErrors([
            'email' => 'This user is already a member of the team.',
        ]);
    }
    
    $team->users()->attach($user, ['role' => $request->role]);
    
    return back()->with('status', 'Team member added successfully.');
}

// Remove a member from a team
public function removeMember(Team $team, User $user)
{
    // Prevent removing the team owner
    if ($team->owner_id === $user->id) {
        return back()->withErrors([
            'error' => 'You cannot remove the team owner.',
        ]);
    }
    
    $team->users()->detach($user);
    
    return back()->with('status', 'Team member removed successfully.');
}
```

### Permission Assignment

```php
// Assign permissions to a role
public function assignPermissions(Role $role, Request $request)
{
    $request->validate([
        'permissions' => ['required', 'array'],
        'permissions.*' => ['exists:permissions,id'],
    ]);
    
    $role->syncPermissions($request->permissions);
    
    return back()->with('status', 'Permissions assigned successfully.');
}

// Assign a role to a user in a team
public function assignRole(Team $team, User $user, Request $request)
{
    $request->validate([
        'role' => ['required', 'string', 'exists:roles,name'],
    ]);
    
    $team->users()->updateExistingPivot($user->id, [
        'role' => $request->role,
    ]);
    
    return back()->with('status', 'Role assigned successfully.');
}
```

## UI Patterns

### Livewire Component Patterns

```php
// User profile component
class ProfileForm extends Component
{
    public User $user;
    
    public string $name = '';
    public string $email = '';
    
    protected $rules = [
        'name' => 'required|string|max:255',
        'email' => 'required|email|max:255|unique:users,email',
    ];
    
    public function mount()
    {
        $this->user = auth()->user();
        $this->name = $this->user->name;
        $this->email = $this->user->email;
        
        $this->rules['email'] .= ',' . $this->user->id;
    }
    
    public function save()
    {
        $this->validate();
        
        $this->user->update([
            'name' => $this->name,
            'email' => $this->email,
        ]);
        
        $this->emit('profile-updated');
        
        session()->flash('status', 'Profile updated successfully.');
    }
    
    public function render()
    {
        return view('livewire.profile-form');
    }
}
```

### Volt Component Patterns

```php
<?php

use function Livewire\Volt\{state, mount, computed, rules};

state([
    'name' => '',
    'email' => '',
    'user' => null,
]);

rules([
    'name' => 'required|string|max:255',
    'email' => 'required|email|max:255|unique:users,email',
]);

mount(function () {
    $this->user = auth()->user();
    $this->name = $this->user->name;
    $this->email = $this->user->email;
    
    $this->rules['email'] .= ',' . $this->user->id;
});

$save = function () {
    $this->validate();
    
    $this->user->update([
        'name' => $this->name,
        'email' => $this->email,
    ]);
    
    $this->dispatch('profile-updated');
    
    session()->flash('status', 'Profile updated successfully.');
};

?>

<div>
    <form wire:submit="save">
        <div>
            <label for="name">Name</label>
            <input id="name" type="text" wire:model="name" />
            @error('name') <span class="error">{{ $message }}</span> @enderror
        </div>
        
        <div>
            <label for="email">Email</label>
            <input id="email" type="email" wire:model="email" />
            @error('email') <span class="error">{{ $message }}</span> @enderror
        </div>
        
        <button type="submit">Save</button>
    </form>
</div>
```

## Real-time Patterns

### Event Broadcasting

```php
// Broadcastable event
class TeamMemberAdded implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $team;
    public $user;

    public function __construct(Team $team, User $user)
    {
        $this->team = $team;
        $this->user = $user;
    }

    public function broadcastOn()
    {
        return new PrivateChannel('team.' . $this->team->id);
    }
}

// Dispatching the event
event(new TeamMemberAdded($team, $user));

// Listening for the event in JavaScript
Echo.private('team.' + teamId)
    .listen('TeamMemberAdded', (e) => {
        // Update UI with new team member
        addTeamMemberToList(e.user);
    });
```

### User Presence

```php
// Channel authorization
Broadcast::channel('team.{teamId}.presence', function ($user, $teamId) {
    if ($user->belongsToTeam($teamId)) {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'avatar' => $user->avatar_url,
        ];
    }
});

// Joining a presence channel
const presenceChannel = Echo.050-common-patterns-snippets.mdjoin('team.' + teamId + '.presence')
    .here((users) => {
        // Initial list of users
        setOnlineUsers(users);
    })
    .joining((user) => {
        // User joined
        addOnlineUser(user);
    })
    .leaving((user) => {
        // User left
        removeOnlineUser(user);
    });
```

## Testing Patterns

### Model Testing

```php
// Testing STI
public function test_it_creates_correct_user_type()
{
    $admin = Admin::create([
        'name' => 'Admin User',
        'email' => 'admin@example.com',
        'password' => Hash::make('password'),
    ]);
    
    $this->assertInstanceOf(Admin::class, $admin);
    $this->assertEquals(Admin::class, $admin->type);
    
    $retrievedAdmin = User::find($admin->id);
    $this->assertInstanceOf(Admin::class, $retrievedAdmin);
}

// Testing HasUlid trait
public function test_it_generates_ulid_on_creation()
{
    $user = User::create([
        'name' => 'Test User',
        'email' => 'test@example.com',
        'password' => Hash::make('password'),
    ]);
    
    $this->assertNotNull($user->ulid);
    $this->assertEquals(26, strlen($user->ulid));
}

// Testing HasUserTracking trait
public function test_it_tracks_user_who_created_model()
{
    $user = User::factory()->create();
    
    $this->actingAs($user);
    
    $post = Post::create([
        'title' => 'Test Post',
        'content' => 'Test content',
    ]);
    
    $this->assertEquals($user->id, $post->created_by);
}
```

### Feature Testing

```php
// Testing team creation
public function test_user_can_create_team()
{
    $user = User::factory()->create();
    
    $response = $this->actingAs($user)
        ->post(route('teams.store'), [
            'name' => 'Test Team',
        ]);
    
    $response->assertRedirect();
    
    $this->assertDatabaseHas('teams', [
        'name' => 'Test Team',
        'owner_id' => $user->id,
    ]);
    
    $team = Team::where('name', 'Test Team')->first();
    
    $this->assertDatabaseHas('team_user', [
        'team_id' => $team->id,
        'user_id' => $user->id,
        'role' => 'owner',
    ]);
}

// Testing permissions
public function test_user_with_permission_can_access_protected_route()
{
    $user = User::factory()->create();
    $permission = Permission::create(['name' => 'edit-posts']);
    
    $user->givePermissionTo($permission);
    
    $response = $this->actingAs($user)
        ->get(route('posts.edit', 1));
    
    $response->assertStatus(200);
}

// Testing state transitions
public function test_user_can_transition_from_pending_to_active()
{
    $user = User::factory()->create([
        'status' => Pending::class,
    ]);
    
    $user->status->transitionTo(Active::class);
    
    $this->assertInstanceOf(Active::class, $user->fresh()->status);
}
```

## Related Resources

- [PHP 8 Attributes Quick Reference](010-php8-attributes.md)
- [Single Table Inheritance Quick Reference](010-single-table-inheritance.md)
- [State Machines Quick Reference](020-state-machines.md)
- [Team Permissions Quick Reference](030-team-permissions.md)
- [Real-time Features Quick Reference](040-real-time-features.md)
- [UME Implementation Guide](../../../050-implementation/000-index.md)
