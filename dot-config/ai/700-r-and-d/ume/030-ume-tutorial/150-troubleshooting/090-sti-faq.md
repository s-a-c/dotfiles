# Single Table Inheritance FAQ

<link rel="stylesheet" href="../assets/css/styles.css">
<link rel="stylesheet" href="../assets/css/ume-docs-enhancements.css">
<script src="../assets/js/ume-docs-enhancements.js"></script>

This FAQ addresses common questions about Single Table Inheritance (STI) in the UME implementation.

## Basic Concepts

### What is Single Table Inheritance (STI)?

Single Table Inheritance is a design pattern where multiple model types share a single database table. In the UME implementation, we use STI to store different user types (Admin, Manager, Practitioner) in the same `users` table, with a `type` column to distinguish between them.

The benefits of STI include:
- Simplified database schema
- Easier querying across all user types
- Shared authentication system
- Ability to add type-specific behavior

### How does STI differ from other inheritance patterns?

STI differs from other inheritance patterns in several ways:

1. **Class Table Inheritance (CTI)**: In CTI, each model in the inheritance hierarchy has its own table. This can lead to complex joins but allows for more specific columns for each type.

2. **Concrete Table Inheritance (ConTI)**: In ConTI, each concrete class has its own table with all the columns it needs, including those inherited from parent classes. This leads to duplication of column definitions.

3. **Single Table Inheritance (STI)**: In STI, all models in the inheritance hierarchy share a single table. This simplifies the database schema but can lead to many nullable columns.

### What package does UME use for STI?

UME uses the `calebporzio/parental` package for implementing STI. This package provides two traits:

1. `HasChildren`: Used in the parent model (User)
2. `HasParent`: Used in the child models (Admin, Manager, Practitioner)

## Implementation Questions

### How do I add a new user type?

To add a new user type:

1. Add the new type to the `UserType` enum:
   ```php
   enum UserType: string
   {
       case Admin = 'admin';
       case Manager = 'manager';
       case Practitioner = 'practitioner';
       case Client = 'client'; // New type
   }
   ```

2. Create a new model that extends the base User model:
   ```php
   use Parental\HasParent;

   class Client extends User
   {
       use HasParent;
       
       // Client-specific methods and properties
   }
   ```

3. Update the `$childTypes` array in the User model:
   ```php
   protected $childTypes = [
       'admin' => Admin::class,
       'manager' => Manager::class,
       'practitioner' => Practitioner::class,
       'client' => Client::class, // New type
   ];
   ```

4. Create a factory for the new user type:
   ```php
   class ClientFactory extends Factory
   {
       protected $model = Client::class;
       
       public function definition(): array
       {
           return [
               'type' => 'client',
           ];
       }
   }
   ```

5. Update the `UserTypeService` to handle the new type.

6. Update permissions and roles for the new user type.

### How do I add type-specific columns?

To add type-specific columns:

1. Add the columns to the users table migration:
   ```php
   Schema::table('users', function (Blueprint $table) {
       // Columns for Admin
       $table->string('admin_code')->nullable();
       
       // Columns for Practitioner
       $table->string('license_number')->nullable();
       $table->string('specialty')->nullable();
       
       // Columns for Client
       $table->date('date_of_birth')->nullable();
       $table->string('emergency_contact')->nullable();
   });
   ```

2. Add the columns to the fillable array in the child models:
   ```php
   class Admin extends User
   {
       use HasParent;
       
       protected $fillable = [
           'admin_code',
       ];
   }
   
   class Practitioner extends User
   {
       use HasParent;
       
       protected $fillable = [
           'license_number',
           'specialty',
       ];
   }
   
   class Client extends User
   {
       use HasParent;
       
       protected $fillable = [
           'date_of_birth',
           'emergency_contact',
       ];
   }
   ```

3. Update the factories to generate values for these columns:
   ```php
   class AdminFactory extends Factory
   {
       protected $model = Admin::class;
       
       public function definition(): array
       {
           return [
               'type' => 'admin',
               'admin_code' => $this->faker->unique()->regexify('[A-Z]{3}[0-9]{5}'),
           ];
       }
   }
   ```

### How do I query specific user types?

There are several ways to query specific user types:

1. **Using the child model directly**:
   ```php
   // Get all admins
   $admins = Admin::all();
   
   // Get admins with specific criteria
   $admins = Admin::where('admin_code', 'like', 'ABC%')->get();
   ```

2. **Using the type column in the User model**:
   ```php
   // Get all admins
   $admins = User::where('type', 'admin')->get();
   
   // Get admins and managers
   $users = User::whereIn('type', ['admin', 'manager'])->get();
   ```

3. **Using the UserType enum**:
   ```php
   // Get all admins
   $admins = User::where('type', UserType::Admin->value)->get();
   
   // Get admins and managers
   $users = User::whereIn('type', [
       UserType::Admin->value,
       UserType::Manager->value,
   ])->get();
   ```

### How do I change a user's type?

To change a user's type, use the `UserTypeService`:

```php
// Inject the service
public function changeUserType(UserTypeService $userTypeService, User $user, string $newType)
{
    // Change the user's type
    $userTypeService->changeUserType($user, $newType);
    
    return redirect()->back()->with('status', 'User type changed successfully.');
}
```

The `UserTypeService` handles:
1. Validating that the new type is valid
2. Changing the user's type attribute
3. Dispatching a `UserTypeChanged` event
4. Updating the user's permissions based on the new type

## Advanced Questions

### How does STI affect query performance?

STI can impact query performance in several ways:

1. **Pros**:
   - Single table means simpler queries for retrieving all user types
   - No joins needed for basic user data
   - Indexes work across all user types

2. **Cons**:
   - Table can grow large with many users
   - Type-specific columns may be null for other types
   - Queries for specific user types need a WHERE clause

To optimize performance:
- Use proper indexing (especially on the `type` column)
- Use eager loading to reduce queries
- Consider caching frequently accessed data
- For very large applications, consider using a read replica

### How do I handle type-specific relationships?

There are two approaches to handling type-specific relationships:

1. **Define relationships in the child models**:
   ```php
   class Practitioner extends User
   {
       use HasParent;
       
       public function patients()
       {
           return $this->belongsToMany(Client::class, 'practitioner_client');
       }
   }
   
   class Client extends User
   {
       use HasParent;
       
       public function practitioners()
       {
           return $this->belongsToMany(Practitioner::class, 'practitioner_client');
       }
   }
   ```

2. **Use conditional relationships in the parent model**:
   ```php
   class User extends Authenticatable
   {
       use HasChildren;
       
       public function patients()
       {
           if ($this->type !== 'practitioner') {
               throw new \Exception('Only practitioners can have patients');
           }
           
           return $this->belongsToMany(Client::class, 'practitioner_client', 'practitioner_id', 'client_id');
       }
       
       public function practitioners()
       {
           if ($this->type !== 'client') {
               throw new \Exception('Only clients can have practitioners');
           }
           
           return $this->belongsToMany(Practitioner::class, 'practitioner_client', 'client_id', 'practitioner_id');
       }
   }
   ```

The first approach is generally cleaner and more intuitive.

### How do I handle type-specific validation?

You can implement type-specific validation in several ways:

1. **Create type-specific form requests**:
   ```php
   class UpdateAdminProfileRequest extends FormRequest
   {
       public function rules(): array
       {
           return [
               'first_name' => 'required|string|max:100',
               'last_name' => 'required|string|max:100',
               'email' => 'required|email|unique:users,email,' . $this->user()->id,
               'admin_code' => 'required|string|size:8', // Admin-specific field
           ];
       }
   }
   ```

2. **Use conditional validation in a single form request**:
   ```php
   class UpdateProfileRequest extends FormRequest
   {
       public function rules(): array
       {
           $rules = [
               'first_name' => 'required|string|max:100',
               'last_name' => 'required|string|max:100',
               'email' => 'required|email|unique:users,email,' . $this->user()->id,
           ];
           
           if ($this->user()->type === 'admin') {
               $rules['admin_code'] = 'required|string|size:8';
           } elseif ($this->user()->type === 'practitioner') {
               $rules['license_number'] = 'required|string|max:20';
               $rules['specialty'] = 'required|string|max:100';
           }
           
           return $rules;
       }
   }
   ```

3. **Use attribute-based validation with PHP 8 attributes**.

### How do I handle type-specific authorization?

You can implement type-specific authorization in several ways:

1. **Use type checks in policies**:
   ```php
   class UserPolicy
   {
       public function update(User $user, User $target): bool
       {
           // Admins can update any user
           if ($user->type === 'admin') {
               return true;
           }
           
           // Managers can update practitioners and clients
           if ($user->type === 'manager' && in_array($target->type, ['practitioner', 'client'])) {
               return true;
           }
           
           // Users can update themselves
           return $user->id === $target->id;
       }
   }
   ```

2. **Use instance checks in policies**:
   ```php
   class UserPolicy
   {
       public function update(User $user, User $target): bool
       {
           // Admins can update any user
           if ($user instanceof Admin) {
               return true;
           }
           
           // Managers can update practitioners and clients
           if ($user instanceof Manager && ($target instanceof Practitioner || $target instanceof Client)) {
               return true;
           }
           
           // Users can update themselves
           return $user->id === $target->id;
       }
   }
   ```

3. **Use role-based authorization with Spatie Permission**:
   ```php
   class UserPolicy
   {
       public function update(User $user, User $target): bool
       {
           // Users with the 'edit users' permission can update any user
           if ($user->hasPermissionTo('edit users')) {
               return true;
           }
           
           // Users can update themselves
           return $user->id === $target->id;
       }
   }
   ```

## Common Issues

### Why are my models not resolving to the correct type?

If your models are not resolving to the correct type, check the following:

1. **Type column**: Ensure the `type` column in the database has the correct value.
2. **Child types array**: Ensure the `$childTypes` array in the User model has the correct mappings.
3. **HasChildren trait**: Ensure the User model uses the `HasChildren` trait.
4. **HasParent trait**: Ensure the child models use the `HasParent` trait.
5. **Fresh models**: Ensure you're working with fresh models. If you've changed a model's type, you may need to reload it from the database.

```php
// Check the type value
$user = User::find(1);
echo $user->type; // Should match a key in $childTypes

// Reload the model to ensure it's the correct type
$user = $user->fresh();
echo get_class($user); // Should be the child class
```

### How do I handle migrations for type-specific columns?

When adding type-specific columns, consider the following:

1. **Nullable columns**: Make type-specific columns nullable, as they will be null for other types.
2. **Default values**: Provide default values for non-nullable columns.
3. **Validation**: Add validation to ensure only the correct types have values for type-specific columns.
4. **Indexes**: Add indexes to frequently queried columns.

```php
Schema::table('users', function (Blueprint $table) {
    // Columns for Admin
    $table->string('admin_code')->nullable()->index();
    
    // Columns for Practitioner
    $table->string('license_number')->nullable()->index();
    $table->string('specialty')->nullable();
});
```

### How do I handle factories for different user types?

Create separate factories for each user type:

```php
// UserFactory.php
class UserFactory extends Factory
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
    
    public function admin(): static
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
    }
}

// AdminFactory.php
class AdminFactory extends Factory
{
    protected $model = Admin::class;
    
    public function definition(): array
    {
        return [
            'type' => 'admin',
            'admin_code' => $this->faker->unique()->regexify('[A-Z]{3}[0-9]{5}'),
        ];
    }
}
```

Then use them like this:

```php
// Using the User factory with states
$admin = User::factory()->admin()->create();
$manager = User::factory()->manager()->create();
$practitioner = User::factory()->practitioner()->create();

// Using the child model factories
$admin = Admin::factory()->create();
$practitioner = Practitioner::factory()->create();
```

## Best Practices

### When should I use STI vs. other inheritance patterns?

Use STI when:
- You have a clear inheritance hierarchy
- The child models share most of their fields
- You need to query across all types frequently
- You want to use the same authentication system for all types

Consider other patterns when:
- Child models have many type-specific fields
- You rarely need to query across all types
- The inheritance hierarchy is complex or deep
- Performance is a critical concern for very large tables

### How do I organize my code for STI?

Follow these best practices for organizing your STI code:

1. **Keep models in separate files**: Each model should have its own file.
2. **Use namespaces**: Consider using a namespace for related models.
3. **Create base traits**: Create traits for shared functionality.
4. **Use factories**: Create factories for each model type.
5. **Document relationships**: Clearly document type-specific relationships.

```php
// app/Models/User.php
namespace App\Models;

use Parental\HasChildren;

class User extends Authenticatable
{
    use HasChildren;
    
    // Base User functionality
}

// app/Models/Users/Admin.php
namespace App\Models\Users;

use App\Models\User;
use Parental\HasParent;

class Admin extends User
{
    use HasParent;
    
    // Admin-specific functionality
}
```

### How do I test STI models?

Test your STI models thoroughly:

1. **Test type resolution**: Ensure models resolve to the correct type.
2. **Test type-specific methods**: Test methods that are specific to each type.
3. **Test type changes**: Test changing a user's type.
4. **Test validation**: Test type-specific validation.
5. **Test authorization**: Test type-specific authorization.

```php
// Using Pest
test('user resolves to the correct type', function () {
    // Create users of different types
    $admin = Admin::factory()->create();
    $manager = Manager::factory()->create();
    $practitioner = Practitioner::factory()->create();
    
    // Reload from database
    $admin = User::find($admin->id);
    $manager = User::find($manager->id);
    $practitioner = User::find($practitioner->id);
    
    // Check types
    expect($admin)->toBeInstanceOf(Admin::class);
    expect($manager)->toBeInstanceOf(Manager::class);
    expect($practitioner)->toBeInstanceOf(Practitioner::class);
});

test('changing user type works correctly', function () {
    // Create a practitioner
    $practitioner = Practitioner::factory()->create();
    
    // Change to manager
    $userTypeService = app(UserTypeService::class);
    $userTypeService->changeUserType($practitioner, 'manager');
    
    // Reload from database
    $user = User::find($practitioner->id);
    
    // Check type
    expect($user)->toBeInstanceOf(Manager::class);
    expect($user->type)->toBe('manager');
});
```

## Additional Resources

- [Parental Package Documentation](https://github.com/calebporzio/parental)
- [Laravel Documentation on Eloquent Models](https://laravel.com/docs/eloquent)
- [Martin Fowler on Inheritance Patterns](https://martinfowler.com/eaaCatalog/singleTableInheritance.html)
- [Laravel News: Single Table Inheritance in Laravel](https://laravel-news.com/single-table-inheritance-laravel)

<div class="page-navigation">
    <a href="./080-general-faq.md" class="prev">General FAQ</a>
    <a href="./082-auth-profile-faq.md" class="next">Auth & Profile FAQ</a>
</div>
