# Single Table Inheritance Video Tutorial

<link rel="stylesheet" href="../../css/styles.css">
<link rel="stylesheet" href="../../css/ume-docs-enhancements.css">
<script src="../../js/ume-docs-enhancements.js"></script>

## Overview

This video tutorial explains Single Table Inheritance (STI) in Laravel, a pattern used in the UME system to store different user types in a single database table while maintaining type-specific behavior through inheritance.

## Video Tutorial

<!-- 
Note: In a real implementation, this would be replaced with an actual embedded video.
For this example, we're providing a placeholder and transcript.
-->

<div class="video-container">
    <div class="video-placeholder">
        <div class="video-placeholder-content">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" class="video-placeholder-icon">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <p>Single Table Inheritance in Laravel (10:24)</p>
            <button class="video-placeholder-button">Watch Video</button>
        </div>
    </div>
</div>

## Transcript

### Introduction (0:00 - 1:15)

Hello and welcome to this tutorial on Single Table Inheritance in Laravel. I'm [Instructor Name], and today we'll explore how to implement the Single Table Inheritance pattern in the UME system.

Single Table Inheritance, or STI, is a design pattern that allows you to store different types of models in a single database table while maintaining type-specific behavior through inheritance. This is particularly useful when you have different types of users, such as admins, managers, and practitioners, who share many common attributes but also have type-specific attributes and behaviors.

### What is Single Table Inheritance? (1:16 - 3:30)

Let's start by understanding what Single Table Inheritance is and why it's useful.

In a traditional approach, you might create separate tables for each user type:
- users
- admins
- managers
- practitioners

This approach has several drawbacks:
1. Duplication of common fields across tables
2. Complex joins when querying across user types
3. Difficulty in handling relationships that apply to all user types
4. Challenges in switching a user from one type to another

Single Table Inheritance solves these problems by using a single table with a "type" column to distinguish between different model types. Each type is represented by a separate class that inherits from a base class.

### Database Structure for STI (3:31 - 5:45)

Let's look at how to structure your database for Single Table Inheritance.

First, we need a users table with a type column:

```php
Schema::create('users', function (Blueprint $table) {
    $table->uuid('id')->primary();
    $table->string('name');
    $table->string('email')->unique();
    $table->string('password');
    $table->string('type');  // This will store the user type
    $table->rememberToken();
    $table->timestamps();
    
    // Common fields for all user types
    $table->string('phone')->nullable();
    $table->string('address')->nullable();
    
    // Fields specific to Admin
    $table->boolean('super_admin')->nullable();
    
    // Fields specific to Manager
    $table->string('department')->nullable();
    
    // Fields specific to Practitioner
    $table->string('specialty')->nullable();
    $table->string('license_number')->nullable();
});
```

Notice that we include fields for all user types in a single table. Fields that are only relevant to specific user types will be null for other types.

### Model Structure for STI (5:46 - 8:30)

Now, let's implement the model structure for Single Table Inheritance.

First, we have our base User model:

```php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Foundation\Auth\User as Authenticatable;

class User extends Authenticatable
{
    protected $fillable = [
        'name', 'email', 'password', 'type',
        'phone', 'address',
    ];
    
    protected $hidden = [
        'password', 'remember_token',
    ];
    
    // This method is called when a model is being created
    protected static function booted()
    {
        static::creating(function ($model) {
            // Set the type if it's not already set
            if (empty($model->type)) {
                $model->type = class_basename($model);
            }
        });
    }
}
```

Next, we create our specific user type models:

```php
namespace App\Models;

class Admin extends User
{
    protected $fillable = [
        'super_admin',
    ];
    
    // Admin-specific methods
    public function canAccessAdminPanel()
    {
        return true;
    }
}
```

```php
namespace App\Models;

class Manager extends User
{
    protected $fillable = [
        'department',
    ];
    
    // Manager-specific methods
    public function getDepartmentReports()
    {
        // Implementation
    }
}
```

```php
namespace App\Models;

class Practitioner extends User
{
    protected $fillable = [
        'specialty', 'license_number',
    ];
    
    // Practitioner-specific methods
    public function getPatients()
    {
        // Implementation
    }
}
```

### Using the tightenco/parental Package (8:31 - 10:24)

To simplify the implementation of Single Table Inheritance in Laravel, we can use the tightenco/parental package.

First, install the package:

```bash
composer require tightenco/parental
```

Then, update your models:

```php
namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Tightenco\Parental\HasChildren;

class User extends Authenticatable
{
    use HasChildren;
    
    protected $fillable = [
        'name', 'email', 'password',
        'phone', 'address',
    ];
    
    protected $hidden = [
        'password', 'remember_token',
    ];
    
    // Define the child types
    protected $childTypes = [
        'Admin' => Admin::class,
        'Manager' => Manager::class,
        'Practitioner' => Practitioner::class,
    ];
}
```

For the child models:

```php
namespace App\Models;

use Tightenco\Parental\HasParent;

class Admin extends User
{
    use HasParent;
    
    protected $fillable = [
        'super_admin',
    ];
    
    // Admin-specific methods
    public function canAccessAdminPanel()
    {
        return true;
    }
}
```

With this setup, when you retrieve a user from the database, the parental package will automatically return the correct child class based on the type column.

### Conclusion

That's it for our introduction to Single Table Inheritance in Laravel! We've covered:
- What Single Table Inheritance is and why it's useful
- How to structure your database for STI
- How to implement the model hierarchy
- How to simplify implementation with the tightenco/parental package

In the next video, we'll explore more advanced topics like querying specific user types, handling type-specific relationships, and managing type transitions.

Thanks for watching!

## Key Concepts

1. **Single Table Inheritance (STI)**: A design pattern that stores different model types in a single database table while maintaining type-specific behavior through inheritance.

2. **Type Column**: A column in the database table that identifies the specific model type for each record.

3. **Model Hierarchy**: A class hierarchy where specific model types inherit from a base model class.

4. **Automatic Type Assignment**: Setting the type column automatically based on the class name when creating new models.

5. **Type-Specific Methods**: Methods that are only available on specific model types, providing type-specific behavior.

6. **tightenco/parental Package**: A Laravel package that simplifies the implementation of Single Table Inheritance.

## Code Examples

### Migration for Users Table

```php
Schema::create('users', function (Blueprint $table) {
    $table->uuid('id')->primary();
    $table->string('name');
    $table->string('email')->unique();
    $table->string('password');
    $table->string('type');  // This will store the user type
    $table->rememberToken();
    $table->timestamps();
    
    // Common fields for all user types
    $table->string('phone')->nullable();
    $table->string('address')->nullable();
    
    // Fields specific to Admin
    $table->boolean('super_admin')->nullable();
    
    // Fields specific to Manager
    $table->string('department')->nullable();
    
    // Fields specific to Practitioner
    $table->string('specialty')->nullable();
    $table->string('license_number')->nullable();
});
```

### Base User Model

```php
namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Tightenco\Parental\HasChildren;

class User extends Authenticatable
{
    use HasChildren;
    
    protected $fillable = [
        'name', 'email', 'password',
        'phone', 'address',
    ];
    
    protected $hidden = [
        'password', 'remember_token',
    ];
    
    // Define the child types
    protected $childTypes = [
        'Admin' => Admin::class,
        'Manager' => Manager::class,
        'Practitioner' => Practitioner::class,
    ];
}
```

### Admin Model

```php
namespace App\Models;

use Tightenco\Parental\HasParent;

class Admin extends User
{
    use HasParent;
    
    protected $fillable = [
        'super_admin',
    ];
    
    // Admin-specific methods
    public function canAccessAdminPanel()
    {
        return true;
    }
}
```

### Manager Model

```php
namespace App\Models;

use Tightenco\Parental\HasParent;

class Manager extends User
{
    use HasParent;
    
    protected $fillable = [
        'department',
    ];
    
    // Manager-specific methods
    public function getDepartmentReports()
    {
        // Implementation
    }
}
```

### Practitioner Model

```php
namespace App\Models;

use Tightenco\Parental\HasParent;

class Practitioner extends User
{
    use HasParent;
    
    protected $fillable = [
        'specialty', 'license_number',
    ];
    
    // Practitioner-specific methods
    public function getPatients()
    {
        // Implementation
    }
}
```

### Using the Models

```php
// Create a new Admin
$admin = Admin::create([
    'name' => 'Admin User',
    'email' => 'admin@example.com',
    'password' => Hash::make('password'),
    'super_admin' => true,
]);

// Create a new Manager
$manager = Manager::create([
    'name' => 'Manager User',
    'email' => 'manager@example.com',
    'password' => Hash::make('password'),
    'department' => 'Sales',
]);

// Retrieve a user and it will be the correct type
$user = User::find($admin->id); // $user will be an Admin instance
$user->canAccessAdminPanel(); // This works because $user is an Admin

// Query specific user types
$admins = Admin::all(); // Only get Admin users
$managers = Manager::all(); // Only get Manager users
```

## Additional Resources

- [Single Table Inheritance Implementation](../../../050-implementation/020-phase1-core-models/020-single-table-inheritance.md)
- [tightenco/parental Package Documentation](https://github.com/tighten/parental)
- [Laravel Eloquent Documentation](https://laravel.com/docs/eloquent)
- [Model Inheritance Hierarchy Diagram](../model-inheritance-hierarchy.md)
- [Diagram Style Guide](../diagram-style-guide.md)
