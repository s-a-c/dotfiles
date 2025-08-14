# Phase 1: Core Models & STI Troubleshooting

<link rel="stylesheet" href="../assets/css/styles.css">
<link rel="stylesheet" href="../assets/css/ume-docs-enhancements.css">
<script src="../assets/js/ume-docs-enhancements.js"></script>

This guide addresses common issues you might encounter during Phase 1 (Core Models & Single Table Inheritance) of the UME tutorial implementation.

## Single Table Inheritance Issues

<div class="troubleshooting-guide">
    <h2>STI Model Type Resolution Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Models not resolving to the correct child type</li>
            <li>All models returning as the base User class</li>
            <li>Type column not being set correctly</li>
            <li>Errors when trying to access child-specific methods</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Missing or incorrect HasChildren trait configuration</li>
            <li>Type column not defined in the database</li>
            <li>Child models not using HasParent trait</li>
            <li>Incorrect type values in the database</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Missing or Incorrect HasChildren Configuration</h4>
        <p>Ensure your User model is configured correctly with the HasChildren trait:</p>
        <pre><code>use Parental\HasChildren;

class User extends Authenticatable
{
    use HasChildren;
    
    protected $childColumn = 'type';
    
    protected $childTypes = [
        'admin' => Admin::class,
        'manager' => Manager::class,
        'practitioner' => Practitioner::class,
    ];
}</code></pre>
        
        <h4>For Missing Type Column</h4>
        <p>Check that your users table migration includes the type column:</p>
        <pre><code>Schema::table('users', function (Blueprint $table) {
    $table->string('type')->default('user');
});</code></pre>
        
        <h4>For Child Models Not Using HasParent</h4>
        <p>Ensure each child model uses the HasParent trait:</p>
        <pre><code>use Parental\HasParent;

class Admin extends User
{
    use HasParent;
}</code></pre>
        
        <h4>For Incorrect Type Values</h4>
        <p>Verify that the type values in your database match the keys in the $childTypes array:</p>
        <pre><code>// Check database values
DB::table('users')->select('id', 'type')->get();

// Update incorrect values
DB::table('users')
    ->where('id', $userId)
    ->update(['type' => 'admin']); // Use the correct type key</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Use an enum for user types to ensure consistency</li>
            <li>Create factory methods for each user type</li>
            <li>Add validation to ensure only valid types are stored</li>
            <li>Write tests to verify type resolution works correctly</li>
        </ul>
    </div>
</div>

## Trait Implementation Issues

<div class="troubleshooting-guide">
    <h2>HasUlid Trait Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>ULIDs not being generated for new models</li>
            <li>Duplicate ULID errors</li>
            <li>ULIDs not being used as the route key</li>
            <li>Database queries failing when searching by ULID</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Missing ulid column in the database table</li>
            <li>Trait not properly implemented in the model</li>
            <li>Conflicts with other ID generation methods</li>
            <li>Missing getRouteKeyName method override</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Missing ULID Column</h4>
        <p>Add the ulid column to your migration:</p>
        <pre><code>Schema::table('users', function (Blueprint $table) {
    $table->ulid('ulid')->unique();
});</code></pre>
        
        <h4>For Improper Trait Implementation</h4>
        <p>Ensure the HasUlid trait is properly implemented in your model:</p>
        <pre><code>use App\Models\Traits\HasUlid;

class User extends Authenticatable
{
    use HasUlid;
}</code></pre>
        
        <h4>For Conflicts with Other ID Methods</h4>
        <p>Check for conflicts with other ID generation methods and ensure the boot method is properly implemented:</p>
        <pre><code>protected static function bootHasUlid()
{
    static::creating(function ($model) {
        if (empty($model->ulid)) {
            $model->ulid = (string) Str::ulid();
        }
    });
}</code></pre>
        
        <h4>For Missing Route Key Name Override</h4>
        <p>Ensure the getRouteKeyName method is properly overridden:</p>
        <pre><code>public function getRouteKeyName()
{
    return 'ulid';
}</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Always include the ulid column in your migrations</li>
            <li>Create a base model that includes the HasUlid trait</li>
            <li>Write tests to verify ULID generation and routing</li>
            <li>Use route model binding with ULIDs in your controllers</li>
        </ul>
    </div>
</div>

<div class="troubleshooting-guide">
    <h2>HasUserTracking Trait Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Created by and updated by fields not being populated</li>
            <li>Null values in user tracking columns</li>
            <li>Errors when accessing creator or updater relationships</li>
            <li>Inconsistent tracking behavior</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Missing user tracking columns in the database</li>
            <li>No authenticated user when creating/updating records</li>
            <li>Using methods that bypass Eloquent events</li>
            <li>Incorrect relationship definitions</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Missing User Tracking Columns</h4>
        <p>Add the required columns to your migration:</p>
        <pre><code>Schema::table('users', function (Blueprint $table) {
    $table->foreignId('created_by')->nullable()->constrained('users');
    $table->foreignId('updated_by')->nullable()->constrained('users');
    $table->foreignId('deleted_by')->nullable()->constrained('users');
});</code></pre>
        
        <h4>For No Authenticated User</h4>
        <p>Ensure a user is authenticated when creating/updating records, or provide a default user:</p>
        <pre><code>// In your trait
protected static function bootHasUserTracking()
{
    static::creating(function ($model) {
        if (empty($model->created_by) && Auth::check()) {
            $model->created_by = Auth::id();
        }
        
        if (empty($model->updated_by) && Auth::check()) {
            $model->updated_by = Auth::id();
        }
    });
    
    static::updating(function ($model) {
        if (Auth::check()) {
            $model->updated_by = Auth::id();
        }
    });
    
    static::deleting(function ($model) {
        if (method_exists($model, 'isForceDeleting') && !$model->isForceDeleting() && Auth::check()) {
            $model->deleted_by = Auth::id();
            $model->save();
        }
    });
}</code></pre>
        
        <h4>For Methods Bypassing Eloquent Events</h4>
        <p>Avoid using methods that bypass Eloquent events, such as:</p>
        <ul>
            <li>DB::table()->insert()</li>
            <li>DB::table()->update()</li>
            <li>Model::insert()</li>
            <li>Query Builder update() methods</li>
        </ul>
        <p>Instead, use Eloquent's create(), save(), or update() methods.</p>
        
        <h4>For Incorrect Relationship Definitions</h4>
        <p>Ensure your relationship definitions are correct:</p>
        <pre><code>public function creator()
{
    return $this->belongsTo(User::class, 'created_by');
}

public function updater()
{
    return $this->belongsTo(User::class, 'updated_by');
}

public function deleter()
{
    return $this->belongsTo(User::class, 'deleted_by');
}</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Always include user tracking columns in your migrations</li>
            <li>Use Eloquent methods instead of query builder methods</li>
            <li>Write tests to verify user tracking behavior</li>
            <li>Consider using a base model that includes the HasUserTracking trait</li>
        </ul>
    </div>
</div>

## Database Migration Issues

<div class="troubleshooting-guide">
    <h2>Enhanced Users Table Migration Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Migration fails with SQL errors</li>
            <li>Foreign key constraint failures</li>
            <li>Missing columns after migration</li>
            <li>Data type issues with existing data</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Conflicts with existing columns</li>
            <li>Missing foreign key references</li>
            <li>Incorrect data types for columns</li>
            <li>Trying to add non-nullable columns to a table with existing data</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Conflicts with Existing Columns</h4>
        <p>Check if columns already exist before adding them:</p>
        <pre><code>Schema::table('users', function (Blueprint $table) {
    if (!Schema::hasColumn('users', 'type')) {
        $table->string('type')->default('user');
    }
});</code></pre>
        
        <h4>For Missing Foreign Key References</h4>
        <p>Ensure referenced tables exist before adding foreign keys:</p>
        <pre><code>// Create the referenced table first
Schema::create('teams', function (Blueprint $table) {
    $table->id();
    $table->string('name');
    $table->timestamps();
});

// Then add the foreign key
Schema::table('users', function (Blueprint $table) {
    $table->foreignId('team_id')->nullable()->constrained();
});</code></pre>
        
        <h4>For Incorrect Data Types</h4>
        <p>Use appropriate data types for your columns:</p>
        <pre><code>Schema::table('users', function (Blueprint $table) {
    $table->string('first_name', 100)->nullable();
    $table->string('last_name', 100)->nullable();
    $table->string('type', 50)->default('user');
    $table->ulid('ulid')->unique();
    $table->json('preferences')->nullable();
});</code></pre>
        
        <h4>For Non-nullable Columns with Existing Data</h4>
        <p>Either make the column nullable or provide a default value:</p>
        <pre><code>Schema::table('users', function (Blueprint $table) {
    $table->string('type')->default('user')->nullable(false);
});</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Plan your database schema carefully before implementation</li>
            <li>Use migrations to make incremental changes</li>
            <li>Test migrations on a copy of production data</li>
            <li>Use the --pretend flag to preview migration SQL</li>
        </ul>
    </div>
</div>

## Model Relationship Issues

<div class="troubleshooting-guide">
    <h2>Team Relationship Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Unable to access team members</li>
            <li>Unable to add users to teams</li>
            <li>Relationship methods returning null or incorrect results</li>
            <li>Pivot data not being saved or retrieved correctly</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Incorrect relationship definitions</li>
            <li>Missing pivot table</li>
            <li>Incorrect pivot table structure</li>
            <li>Not using the proper methods to manage relationships</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Incorrect Relationship Definitions</h4>
        <p>Ensure your relationship definitions are correct:</p>
        <pre><code>// In User model
public function teams()
{
    return $this->belongsToMany(Team::class)
        ->withPivot('role')
        ->withTimestamps();
}

// In Team model
public function users()
{
    return $this->belongsToMany(User::class)
        ->withPivot('role')
        ->withTimestamps();
}</code></pre>
        
        <h4>For Missing Pivot Table</h4>
        <p>Create the pivot table with the correct structure:</p>
        <pre><code>Schema::create('team_user', function (Blueprint $table) {
    $table->id();
    $table->foreignId('team_id')->constrained()->onDelete('cascade');
    $table->foreignId('user_id')->constrained()->onDelete('cascade');
    $table->string('role')->default('member');
    $table->timestamps();
    
    $table->unique(['team_id', 'user_id']);
});</code></pre>
        
        <h4>For Incorrect Pivot Table Structure</h4>
        <p>Ensure your pivot table follows Laravel's naming conventions (alphabetical order of model names) and has the correct columns.</p>
        
        <h4>For Improper Relationship Management</h4>
        <p>Use the proper methods to manage many-to-many relationships:</p>
        <pre><code>// Add a user to a team
$team->users()->attach($userId, ['role' => 'member']);

// Add multiple users to a team
$team->users()->attach([
    $user1Id => ['role' => 'member'],
    $user2Id => ['role' => 'admin'],
]);

// Remove a user from a team
$team->users()->detach($userId);

// Sync team members (removes users not in the array)
$team->users()->sync([
    $user1Id => ['role' => 'member'],
    $user2Id => ['role' => 'admin'],
]);

// Update pivot data
$user->teams()->updateExistingPivot($teamId, ['role' => 'admin']);</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Follow Laravel's naming conventions for pivot tables</li>
            <li>Use migrations to create pivot tables with the correct structure</li>
            <li>Use the proper methods to manage many-to-many relationships</li>
            <li>Write tests to verify relationship behavior</li>
        </ul>
    </div>
</div>

## Factory and Seeder Issues

<div class="troubleshooting-guide">
    <h2>User Factory Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Factory not creating users with the correct type</li>
            <li>Child model factories not working</li>
            <li>Missing or incorrect data in factory-created models</li>
            <li>Errors when running seeders</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Incorrect factory definition</li>
            <li>Missing state methods for different user types</li>
            <li>Not using the correct factory for child models</li>
            <li>Seeder not using factories correctly</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Incorrect Factory Definition</h4>
        <p>Ensure your User factory is defined correctly:</p>
        <pre><code>class UserFactory extends Factory
{
    public function definition(): array
    {
        return [
            'name' => fake()->name(),
            'first_name' => fake()->firstName(),
            'last_name' => fake()->lastName(),
            'email' => fake()->unique()->safeEmail(),
            'email_verified_at' => now(),
            'password' => Hash::make('password'),
            'remember_token' => Str::random(10),
            'type' => 'user',
            'ulid' => (string) Str::ulid(),
        ];
    }
}</code></pre>
        
        <h4>For Missing State Methods</h4>
        <p>Add state methods for different user types:</p>
        <pre><code>public function admin(): static
{
    return $this->state(fn (array $attributes) => [
        'type' => 'admin',
    ]);
}

public function manager(): static
{
    return $this->state(fn (array $attributes) => [
        'type' => 'manager',
    ]);
}

public function practitioner(): static
{
    return $this->state(fn (array $attributes) => [
        'type' => 'practitioner',
    ]);
}</code></pre>
        
        <h4>For Child Model Factories</h4>
        <p>Create separate factories for child models:</p>
        <pre><code>class AdminFactory extends Factory
{
    protected $model = Admin::class;
    
    public function definition(): array
    {
        return [
            'type' => 'admin',
        ];
    }
}

// Then use it like this
Admin::factory()->create();</code></pre>
        
        <h4>For Seeder Issues</h4>
        <p>Ensure your seeder is using factories correctly:</p>
        <pre><code>public function run(): void
{
    // Create an admin user
    Admin::factory()->create([
        'email' => 'admin@example.com',
        'name' => 'Admin User',
    ]);
    
    // Create manager users
    Manager::factory(5)->create();
    
    // Create practitioner users
    Practitioner::factory(10)->create();
}</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Create a base factory for the User model</li>
            <li>Create separate factories for each child model</li>
            <li>Use state methods for common variations</li>
            <li>Test your factories and seeders to ensure they create the expected data</li>
        </ul>
    </div>
</div>

## Common Pitfalls in Phase 1

<div class="common-pitfalls">
    <h3>Common Pitfalls to Avoid</h3>
    <ul>
        <li><strong>Not understanding Single Table Inheritance:</strong> Make sure you understand how STI works before implementing it. The parent model needs the HasChildren trait, and child models need the HasParent trait.</li>
        <li><strong>Forgetting to add the type column:</strong> The type column is essential for STI to work. Make sure it's added to your users table.</li>
        <li><strong>Using incorrect type values:</strong> The type values in the database must match the keys in the $childTypes array in your User model.</li>
        <li><strong>Not implementing traits correctly:</strong> Ensure that your traits are properly implemented with the correct boot methods and that they don't conflict with each other.</li>
        <li><strong>Creating circular dependencies:</strong> Be careful not to create circular dependencies in your migrations, especially with foreign keys.</li>
        <li><strong>Using methods that bypass Eloquent events:</strong> Traits like HasUserTracking rely on Eloquent events. Using methods that bypass these events will cause issues.</li>
        <li><strong>Not testing your models and relationships:</strong> Write tests to verify that your models, relationships, and traits work as expected.</li>
    </ul>
</div>

## Debugging Techniques for Phase 1

### Using Model Factories for Testing

Model factories are a great way to test your models and relationships:

```php
// Create a user with a specific type
$user = User::factory()->state(['type' => 'admin'])->create();

// Verify the user is an instance of the Admin class
$this->assertInstanceOf(Admin::class, $user->fresh());

// Test relationships
$team = Team::factory()->create();
$user->teams()->attach($team->id, ['role' => 'member']);
$this->assertTrue($user->teams->contains($team));
```

### Inspecting Database Queries

Use the DB::listen method to inspect the queries being executed:

```php
DB::listen(function ($query) {
    Log::info($query->sql, $query->bindings);
});
```

### Using Model Events for Debugging

Add event listeners to debug model events:

```php
User::creating(function ($user) {
    Log::info('Creating user', ['attributes' => $user->getAttributes()]);
});

User::created(function ($user) {
    Log::info('User created', ['id' => $user->id, 'type' => $user->type]);
});
```

### Testing Trait Functionality

Write tests to verify that your traits are working correctly:

```php
// Test HasUlid trait
$user = User::factory()->create();
$this->assertNotNull($user->ulid);
$this->assertIsString($user->ulid);

// Test HasUserTracking trait
$admin = Admin::factory()->create();
$user = User::factory()->create();
$this->actingAs($admin);
$user->update(['name' => 'Updated Name']);
$this->assertEquals($admin->id, $user->fresh()->updated_by);
```

<div class="page-navigation">
    <a href="./010-phase0-foundation-troubleshooting.md" class="prev">Phase 0 Troubleshooting</a>
    <a href="./030-phase2-auth-profile-troubleshooting.md" class="next">Phase 2 Troubleshooting</a>
</div>
