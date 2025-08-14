# Phase 3: Teams & Permissions Troubleshooting

<link rel="stylesheet" href="../assets/css/styles.css">
<link rel="stylesheet" href="../assets/css/ume-docs-enhancements.css">
<script src="../assets/js/ume-docs-enhancements.js"></script>

This guide addresses common issues you might encounter during Phase 3 (Teams and Permissions) of the UME tutorial implementation.

## Permission Configuration Issues

<div class="troubleshooting-guide">
    <h2>Spatie Permission Configuration Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Permissions not working with teams</li>
            <li>Unable to assign roles or permissions</li>
            <li>Permission checks failing unexpectedly</li>
            <li>Database errors related to permission tables</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Incorrect package configuration for team support</li>
            <li>Missing or incorrect database migrations</li>
            <li>Not using team-scoped permission methods</li>
            <li>Cache issues with permissions</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Incorrect Team Configuration</h4>
        <p>Update the permission configuration for team support:</p>
        <pre><code>// config/permission.php
'teams' => true,

'team_foreign_key' => 'team_id',

'models' => [
    'team' => App\Models\Team::class,
],</code></pre>
        
        <h4>For Missing or Incorrect Migrations</h4>
        <p>Publish and run the permission migrations:</p>
        <pre><code>php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider" --tag="migrations"
php artisan migrate</code></pre>
        
        <h4>For Not Using Team-Scoped Methods</h4>
        <p>Use the team-scoped permission methods:</p>
        <pre><code>// Assign a role to a user within a team
$user->assignRole('editor', $team);

// Check if a user has a permission within a team
$user->hasPermissionTo('edit articles', 'web', $team);

// Get all permissions for a user within a team
$permissions = $user->getPermissionsViaRoles($team);</code></pre>
        
        <h4>For Cache Issues</h4>
        <p>Clear the permission cache:</p>
        <pre><code>php artisan permission:cache-reset</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Configure the permission package for teams before creating any roles or permissions</li>
            <li>Always use team-scoped methods when working with teams</li>
            <li>Clear the permission cache after making changes to roles or permissions</li>
            <li>Write tests to verify that permissions work correctly with teams</li>
        </ul>
    </div>
</div>

## Permission Seeder Issues

<div class="troubleshooting-guide">
    <h2>Permission Seeder Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Roles or permissions not being created</li>
            <li>Duplicate role or permission errors</li>
            <li>Users not being assigned the correct roles</li>
            <li>Team-specific roles not working correctly</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Incorrect seeder implementation</li>
            <li>Not using team-scoped methods in the seeder</li>
            <li>Running seeders multiple times without checking for existing data</li>
            <li>Not clearing the permission cache after seeding</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Incorrect Seeder Implementation</h4>
        <p>Implement the permission seeder correctly:</p>
        <pre><code>public function run(): void
{
    // Create permissions
    $permissions = [
        'view users',
        'create users',
        'edit users',
        'delete users',
        // Add more permissions as needed
    ];
    
    foreach ($permissions as $permission) {
        Permission::findOrCreate($permission);
    }
    
    // Create roles and assign permissions
    $adminRole = Role::findOrCreate('admin');
    $adminRole->givePermissionTo(Permission::all());
    
    $managerRole = Role::findOrCreate('manager');
    $managerRole->givePermissionTo([
        'view users',
        'create users',
        'edit users',
    ]);
    
    $userRole = Role::findOrCreate('user');
    $userRole->givePermissionTo([
        'view users',
    ]);
    
    // Assign roles to users
    $admin = User::where('email', 'admin@example.com')->first();
    if ($admin) {
        $admin->assignRole('admin');
    }
}</code></pre>
        
        <h4>For Team-Scoped Seeder</h4>
        <p>Implement a team-scoped permission seeder:</p>
        <pre><code>public function run(): void
{
    // Create permissions
    $permissions = [
        'view team users',
        'create team users',
        'edit team users',
        'delete team users',
        // Add more permissions as needed
    ];
    
    foreach ($permissions as $permission) {
        Permission::findOrCreate($permission);
    }
    
    // Create teams
    $teams = Team::all();
    
    foreach ($teams as $team) {
        // Create roles for each team
        $adminRole = Role::findOrCreate('team-admin', 'web', $team->id);
        $adminRole->givePermissionTo(Permission::all());
        
        $memberRole = Role::findOrCreate('team-member', 'web', $team->id);
        $memberRole->givePermissionTo([
            'view team users',
        ]);
        
        // Assign roles to team members
        $teamAdmin = $team->users()->first();
        if ($teamAdmin) {
            $teamAdmin->assignRole($adminRole, $team);
        }
        
        $teamMembers = $team->users()->where('id', '!=', $teamAdmin->id)->get();
        foreach ($teamMembers as $member) {
            $member->assignRole($memberRole, $team);
        }
    }
    
    // Clear permission cache
    $this->command->info('Clearing permission cache...');
    app()->make(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();
}</code></pre>
        
        <h4>For Duplicate Data Issues</h4>
        <p>Check for existing data before creating new records:</p>
        <pre><code>if (!Role::where('name', 'admin')->exists()) {
    $adminRole = Role::create(['name' => 'admin']);
} else {
    $adminRole = Role::where('name', 'admin')->first();
}</code></pre>
        
        <h4>For Cache Issues</h4>
        <p>Clear the permission cache after seeding:</p>
        <pre><code>app()->make(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Use findOrCreate methods to prevent duplicate records</li>
            <li>Clear the permission cache after seeding</li>
            <li>Write idempotent seeders that can be run multiple times</li>
            <li>Test your seeders to ensure they create the expected data</li>
        </ul>
    </div>
</div>

## Team Service Issues

<div class="troubleshooting-guide">
    <h2>Team Service Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Unable to create or update teams</li>
            <li>Team members not being added or removed correctly</li>
            <li>Team roles not being assigned</li>
            <li>Service methods throwing exceptions</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Incorrect service implementation</li>
            <li>Missing or incorrect validation</li>
            <li>Not handling team-specific permissions correctly</li>
            <li>Database transaction issues</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Incorrect Service Implementation</h4>
        <p>Implement the team service correctly:</p>
        <pre><code>class TeamService extends BaseService
{
    public function createTeam(array $data, User $owner): Team
    {
        return DB::transaction(function () use ($data, $owner) {
            $team = Team::create([
                'name' => $data['name'],
                'description' => $data['description'] ?? null,
            ]);
            
            $team->users()->attach($owner->id, ['role' => 'owner']);
            
            // Assign team-admin role to the owner
            $owner->assignRole('team-admin', 'web', $team->id);
            
            return $team;
        });
    }
    
    public function updateTeam(Team $team, array $data): Team
    {
        $team->update([
            'name' => $data['name'],
            'description' => $data['description'] ?? $team->description,
        ]);
        
        return $team;
    }
    
    public function addMember(Team $team, User $user, string $role = 'member'): void
    {
        if ($team->users()->where('user_id', $user->id)->exists()) {
            throw new \Exception('User is already a member of this team.');
        }
        
        $team->users()->attach($user->id, ['role' => $role]);
        
        // Assign team role based on the pivot role
        if ($role === 'owner' || $role === 'admin') {
            $user->assignRole('team-admin', 'web', $team->id);
        } else {
            $user->assignRole('team-member', 'web', $team->id);
        }
    }
    
    public function removeMember(Team $team, User $user): void
    {
        if ($this->isLastOwner($team, $user)) {
            throw new \Exception('Cannot remove the last owner of the team.');
        }
        
        $team->users()->detach($user->id);
        
        // Remove all team-specific roles
        $user->roles()
            ->where('team_id', $team->id)
            ->get()
            ->each(function ($role) use ($user, $team) {
                $user->removeRole($role, $team);
            });
    }
    
    public function changeMemberRole(Team $team, User $user, string $newRole): void
    {
        if ($this->isLastOwner($team, $user) && $newRole !== 'owner') {
            throw new \Exception('Cannot change the role of the last owner.');
        }
        
        $team->users()->updateExistingPivot($user->id, ['role' => $newRole]);
        
        // Update team-specific roles
        $user->roles()
            ->where('team_id', $team->id)
            ->get()
            ->each(function ($role) use ($user, $team) {
                $user->removeRole($role, $team);
            });
        
        if ($newRole === 'owner' || $newRole === 'admin') {
            $user->assignRole('team-admin', 'web', $team->id);
        } else {
            $user->assignRole('team-member', 'web', $team->id);
        }
    }
    
    protected function isLastOwner(Team $team, User $user): bool
    {
        return $team->users()
            ->wherePivot('role', 'owner')
            ->count() === 1 &&
            $team->users()
            ->wherePivot('role', 'owner')
            ->where('user_id', $user->id)
            ->exists();
    }
}</code></pre>
        
        <h4>For Validation Issues</h4>
        <p>Add validation to your service methods:</p>
        <pre><code>public function createTeam(array $data, User $owner): Team
{
    $validator = Validator::make($data, [
        'name' => 'required|string|max:255',
        'description' => 'nullable|string|max:1000',
    ]);
    
    if ($validator->fails()) {
        throw new ValidationException($validator);
    }
    
    // Rest of the method...
}</code></pre>
        
        <h4>For Team Permission Issues</h4>
        <p>Ensure you're using team-scoped permission methods:</p>
        <pre><code>// Assign a role to a user within a team
$user->assignRole('team-admin', 'web', $team->id);

// Check if a user has a permission within a team
if ($user->hasPermissionTo('edit team', 'web', $team->id)) {
    // User can edit the team
}</code></pre>
        
        <h4>For Transaction Issues</h4>
        <p>Use database transactions for operations that affect multiple tables:</p>
        <pre><code>public function createTeam(array $data, User $owner): Team
{
    return DB::transaction(function () use ($data, $owner) {
        // Create team, add members, assign roles, etc.
    });
}</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Use database transactions for operations that affect multiple tables</li>
            <li>Validate input data before processing it</li>
            <li>Handle edge cases like removing the last owner</li>
            <li>Write tests to verify that your service methods work correctly</li>
        </ul>
    </div>
</div>

## Team Management UI Issues

<div class="troubleshooting-guide">
    <h2>Team Management UI Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Team management UI not rendering correctly</li>
            <li>Unable to create or update teams</li>
            <li>Unable to add or remove team members</li>
            <li>Permission errors when accessing team management</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Missing or incorrect Livewire/Volt components</li>
            <li>Authorization issues with team policies</li>
            <li>Form validation errors not being handled</li>
            <li>JavaScript or CSS not loading</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Missing Livewire/Volt Components</h4>
        <p>Create the necessary Livewire/Volt components:</p>
        <pre><code>php artisan make:livewire CreateTeam
php artisan make:livewire UpdateTeam
php artisan make:livewire TeamMembers</code></pre>
        <p>Or for Volt:</p>
        <pre><code>php artisan make:volt CreateTeam
php artisan make:volt UpdateTeam
php artisan make:volt TeamMembers</code></pre>
        
        <h4>For Authorization Issues</h4>
        <p>Create and register a team policy:</p>
        <pre><code>// TeamPolicy.php
class TeamPolicy
{
    public function viewAny(User $user): bool
    {
        return true; // All users can view teams
    }
    
    public function view(User $user, Team $team): bool
    {
        return $team->users()->where('user_id', $user->id)->exists();
    }
    
    public function create(User $user): bool
    {
        return true; // All users can create teams
    }
    
    public function update(User $user, Team $team): bool
    {
        return $team->users()
            ->where('user_id', $user->id)
            ->wherePivotIn('role', ['owner', 'admin'])
            ->exists();
    }
    
    public function delete(User $user, Team $team): bool
    {
        return $team->users()
            ->where('user_id', $user->id)
            ->wherePivot('role', 'owner')
            ->exists();
    }
    
    public function addMember(User $user, Team $team): bool
    {
        return $team->users()
            ->where('user_id', $user->id)
            ->wherePivotIn('role', ['owner', 'admin'])
            ->exists();
    }
    
    public function removeMember(User $user, Team $team, User $targetUser): bool
    {
        // Owners can remove anyone except other owners
        if ($team->users()
            ->where('user_id', $user->id)
            ->wherePivot('role', 'owner')
            ->exists()) {
            
            // Can't remove another owner unless you're an owner
            if ($team->users()
                ->where('user_id', $targetUser->id)
                ->wherePivot('role', 'owner')
                ->exists()) {
                
                return $team->users()
                    ->where('user_id', $user->id)
                    ->wherePivot('role', 'owner')
                    ->exists();
            }
            
            return true;
        }
        
        // Admins can remove regular members
        if ($team->users()
            ->where('user_id', $user->id)
            ->wherePivot('role', 'admin')
            ->exists()) {
            
            return $team->users()
                ->where('user_id', $targetUser->id)
                ->wherePivotIn('role', ['member'])
                ->exists();
        }
        
        return false;
    }
    
    public function changeRole(User $user, Team $team, User $targetUser): bool
    {
        // Only owners can change roles
        return $team->users()
            ->where('user_id', $user->id)
            ->wherePivot('role', 'owner')
            ->exists();
    }
}</code></pre>
        <p>Register the policy in AuthServiceProvider:</p>
        <pre><code>protected $policies = [
    Team::class => TeamPolicy::class,
];</code></pre>
        
        <h4>For Form Validation Issues</h4>
        <p>Handle form validation in your Livewire/Volt components:</p>
        <pre><code>// CreateTeam.php (Livewire)
public string $name = '';
public string $description = '';

protected $rules = [
    'name' => 'required|string|max:255',
    'description' => 'nullable|string|max:1000',
];

public function createTeam(): void
{
    $this->validate();
    
    $teamService = app(TeamService::class);
    $team = $teamService->createTeam([
        'name' => $this->name,
        'description' => $this->description,
    ], auth()->user());
    
    $this->redirect(route('teams.show', $team));
}</code></pre>
        
        <h4>For JavaScript or CSS Issues</h4>
        <p>Ensure all required assets are loaded:</p>
        <pre><code>&lt;!-- In your layout file --&gt;
&lt;head&gt;
    &lt;!-- ... --&gt;
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    @livewireStyles
&lt;/head&gt;
&lt;body&gt;
    &lt;!-- ... --&gt;
    @livewireScripts
&lt;/body&gt;</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Follow the Livewire/Volt and Flux UI documentation</li>
            <li>Create comprehensive policies for authorization</li>
            <li>Handle validation errors properly in your components</li>
            <li>Test your UI components with different user roles</li>
        </ul>
    </div>
</div>

## Middleware Issues

<div class="troubleshooting-guide">
    <h2>Team Role Middleware Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Middleware not restricting access correctly</li>
            <li>Users with correct roles still being denied access</li>
            <li>Redirect loops when using middleware</li>
            <li>Errors when applying middleware to routes</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Incorrect middleware implementation</li>
            <li>Not registering the middleware</li>
            <li>Not using team-scoped permission checks</li>
            <li>Missing or incorrect route parameters</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Incorrect Middleware Implementation</h4>
        <p>Implement the team role middleware correctly:</p>
        <pre><code>class EnsureUserHasTeamRole
{
    public function handle(Request $request, Closure $next, string $role): Response
    {
        $user = $request->user();
        
        if (!$user) {
            return redirect()->route('login');
        }
        
        $teamId = $request->route('team');
        
        if (!$teamId) {
            abort(400, 'Team parameter is required.');
        }
        
        $team = Team::find($teamId);
        
        if (!$team) {
            abort(404, 'Team not found.');
        }
        
        if (!$team->users()->where('user_id', $user->id)->exists()) {
            abort(403, 'You are not a member of this team.');
        }
        
        $userRole = $team->users()
            ->where('user_id', $user->id)
            ->first()
            ->pivot
            ->role;
        
        if ($role === 'owner' && $userRole !== 'owner') {
            abort(403, 'You must be an owner to perform this action.');
        }
        
        if ($role === 'admin' && !in_array($userRole, ['owner', 'admin'])) {
            abort(403, 'You must be an admin or owner to perform this action.');
        }
        
        if ($role === 'member' && !in_array($userRole, ['owner', 'admin', 'member'])) {
            abort(403, 'You must be a member of this team to perform this action.');
        }
        
        return $next($request);
    }
}</code></pre>
        
        <h4>For Middleware Registration</h4>
        <p>Register the middleware in the Kernel.php file:</p>
        <pre><code>protected $routeMiddleware = [
    // Other middleware...
    'team.role' => \App\Http\Middleware\EnsureUserHasTeamRole::class,
];</code></pre>
        
        <h4>For Team-Scoped Permission Checks</h4>
        <p>Use team-scoped permission checks in your middleware:</p>
        <pre><code>class EnsureUserHasTeamPermission
{
    public function handle(Request $request, Closure $next, string $permission): Response
    {
        $user = $request->user();
        
        if (!$user) {
            return redirect()->route('login');
        }
        
        $teamId = $request->route('team');
        
        if (!$teamId) {
            abort(400, 'Team parameter is required.');
        }
        
        $team = Team::find($teamId);
        
        if (!$team) {
            abort(404, 'Team not found.');
        }
        
        if (!$user->hasPermissionTo($permission, 'web', $team->id)) {
            abort(403, 'You do not have the required permission to perform this action.');
        }
        
        return $next($request);
    }
}</code></pre>
        
        <h4>For Route Parameter Issues</h4>
        <p>Ensure your routes are defined correctly:</p>
        <pre><code>Route::middleware(['auth', 'team.role:admin'])
    ->group(function () {
        Route::get('/teams/{team}/settings', [TeamController::class, 'settings'])
            ->name('teams.settings');
    });</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Test your middleware with different user roles</li>
            <li>Use route model binding to automatically resolve team IDs</li>
            <li>Create middleware for both role-based and permission-based checks</li>
            <li>Handle edge cases like missing parameters or non-existent teams</li>
        </ul>
    </div>
</div>

## Common Pitfalls in Phase 3

<div class="common-pitfalls">
    <h3>Common Pitfalls to Avoid</h3>
    <ul>
        <li><strong>Not configuring permissions for teams:</strong> The Spatie Permission package needs to be configured for team support before creating any roles or permissions.</li>
        <li><strong>Using non-team-scoped methods:</strong> When working with teams, always use team-scoped methods for assigning roles and checking permissions.</li>
        <li><strong>Not clearing the permission cache:</strong> After making changes to roles or permissions, clear the permission cache to ensure the changes take effect.</li>
        <li><strong>Not handling the last owner case:</strong> Ensure that a team always has at least one owner by preventing the removal of the last owner.</li>
        <li><strong>Not using database transactions:</strong> Operations that affect multiple tables should be wrapped in database transactions to ensure data consistency.</li>
        <li><strong>Not creating comprehensive policies:</strong> Create policies that cover all possible actions and user roles to ensure proper authorization.</li>
        <li><strong>Not testing with different user roles:</strong> Test your team management features with different user roles to ensure they work correctly for all users.</li>
    </ul>
</div>

## Debugging Techniques for Phase 3

### Testing Team Permissions

Use Laravel's authorization testing helpers to test team permissions:

```php
// Test team creation
$response = $this->actingAs($user)
    ->post('/teams', [
        'name' => 'Test Team',
        'description' => 'A test team',
    ]);

$response->assertRedirect();
$team = Team::where('name', 'Test Team')->first();
$this->assertNotNull($team);
$this->assertTrue($team->users()->where('user_id', $user->id)->exists());

// Test team member management
$response = $this->actingAs($user)
    ->post('/teams/' . $team->id . '/members', [
        'email' => 'member@example.com',
        'role' => 'member',
    ]);

$response->assertRedirect();
$member = User::where('email', 'member@example.com')->first();
$this->assertTrue($team->users()->where('user_id', $member->id)->exists());
```

### Debugging Permission Issues

Use logging to debug permission issues:

```php
// In your controller or middleware
Log::debug('Permission check', [
    'user' => $user->id,
    'team' => $team->id,
    'permission' => $permission,
    'has_permission' => $user->hasPermissionTo($permission, 'web', $team->id),
    'roles' => $user->roles()->where('team_id', $team->id)->get()->pluck('name'),
]);
```

### Testing Middleware

Test your middleware with different user roles:

```php
// Test middleware with owner
$owner = User::factory()->create();
$team = Team::factory()->create();
$team->users()->attach($owner->id, ['role' => 'owner']);

$response = $this->actingAs($owner)
    ->get('/teams/' . $team->id . '/settings');

$response->assertStatus(200);

// Test middleware with member
$member = User::factory()->create();
$team->users()->attach($member->id, ['role' => 'member']);

$response = $this->actingAs($member)
    ->get('/teams/' . $team->id . '/settings');

$response->assertStatus(403);
```

### Debugging Team Service

Use exception handling to debug team service issues:

```php
try {
    $teamService->addMember($team, $user, 'member');
} catch (\Exception $e) {
    Log::error('Failed to add team member', [
        'team' => $team->id,
        'user' => $user->id,
        'role' => 'member',
        'error' => $e->getMessage(),
    ]);
    
    throw $e;
}
```

<div class="page-navigation">
    <a href="./030-phase2-auth-profile-troubleshooting.md" class="prev">Phase 2 Troubleshooting</a>
    <a href="./050-phase4-realtime-troubleshooting.md" class="next">Phase 4 Troubleshooting</a>
</div>
