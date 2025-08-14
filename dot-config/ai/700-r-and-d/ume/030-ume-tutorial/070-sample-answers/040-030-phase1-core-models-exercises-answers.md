# Phase 1: Core Models & STI Exercises - Sample Answers

<link rel="stylesheet" href="../assets/css/styles.css">

This file contains sample answers to the Phase 1: Core Models & STI exercises from the UME tutorial.

## Set 1: Understanding Single Table Inheritance

### Question Answers

1. **What problem does Single Table Inheritance (STI) solve in the context of user types?**
   - **Answer: B) It allows storing different user types in a single table while maintaining type-specific behavior**
   - **Explanation:** Single Table Inheritance allows different user types (like Admin, Manager, Customer) to be stored in a single database table while still maintaining their type-specific behavior through separate model classes. This approach simplifies database design, avoids complex joins, and makes it easier to add common fields to all user types, while still allowing each type to have its own methods and relationships.

2. **How does the `tightenco/parental` package determine which child model to instantiate?**
   - **Answer: B) It checks the `type` column in the database**
   - **Explanation:** The `tightenco/parental` package uses a `type` column (or another configurable column) in the database to determine which child model to instantiate. When a record is retrieved from the database, Parental checks the value in the `type` column and instantiates the corresponding child model class instead of the parent model.

3. **What trait must be added to the parent model (User) when implementing STI with Parental?**
   - **Answer: B) HasChildren**
   - **Explanation:** The `HasChildren` trait must be added to the parent model (like User) when implementing Single Table Inheritance with the Parental package. This trait provides the functionality needed for the parent model to properly instantiate the appropriate child model based on the `type` column.

4. **What trait must be added to the child models (Admin, Manager, etc.) when implementing STI with Parental?**
   - **Answer: A) HasParent**
   - **Explanation:** The `HasParent` trait must be added to the child models (like Admin, Manager) when implementing Single Table Inheritance with the Parental package. This trait allows the child models to inherit from the parent model while maintaining their own type-specific behavior.

### Exercise Solution: Implement a basic Single Table Inheritance structure

#### Step 1: Create a migration that adds a `type` column to the `vehicles` table

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('vehicles', function (Blueprint $table) {
            $table->id();
            $table->string('type');  // This column will store the class name of the child model
            $table->string('make');
            $table->string('model');
            $table->integer('year');
            $table->string('color');
            $table->decimal('price', 10, 2);
            // Common fields for all vehicle types
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('vehicles');
    }
};
```

#### Step 2: Create the base `Vehicle` model with the `HasChildren` trait

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Tightenco\Parental\HasChildren;

class Vehicle extends Model
{
    use HasFactory, HasChildren;

    protected $fillable = [
        'make',
        'model',
        'year',
        'color',
        'price',
    ];

    // Common methods for all vehicles
    public function getFullNameAttribute()
    {
        return "{$this->year} {$this->make} {$this->model}";
    }

    public function calculateDepreciation($years)
    {
        // Basic depreciation calculation (simplified)
        $depreciationRate = 0.1; // 10% per year
        return $this->price * (1 - $depreciationRate * $years);
    }
}
```

#### Step 3: Create the child models with the `HasParent` trait

```php
<?php

namespace App\Models;

use Tightenco\Parental\HasParent;

class Car extends Vehicle
{
    use HasParent;

    // Override the parent's $fillable if needed
    protected $fillable = [
        'make',
        'model',
        'year',
        'color',
        'price',
        'doors',
        'transmission',
    ];

    // Type-specific method
    public function isDoorCountValid()
    {
        return in_array($this->doors, [2, 4, 5]);
    }
}
```

```php
<?php

namespace App\Models;

use Tightenco\Parental\HasParent;

class Motorcycle extends Vehicle
{
    use HasParent;

    protected $fillable = [
        'make',
        'model',
        'year',
        'color',
        'price',
        'engine_size',
        'has_sidecar',
    ];

    // Type-specific method
    public function isLargeEngine()
    {
        return $this->engine_size >= 1000; // 1000cc or larger is considered a large engine
    }
}
```

```php
<?php

namespace App\Models;

use Tightenco\Parental\HasParent;

class Truck extends Vehicle
{
    use HasParent;

    protected $fillable = [
        'make',
        'model',
        'year',
        'color',
        'price',
        'payload_capacity',
        'towing_capacity',
    ];

    // Type-specific method
    public function isHeavyDuty()
    {
        return $this->payload_capacity >= 2000; // 2000kg or more is considered heavy duty
    }
}
```

#### Step 4: Create a simple factory for each vehicle type

```php
<?php

namespace Database\Factories;

use App\Models\Vehicle;
use Illuminate\Database\Eloquent\Factories\Factory;

class VehicleFactory extends Factory
{
    protected $model = Vehicle::class;

    public function definition()
    {
        return [
            'make' => $this->faker->randomElement(['Toyota', 'Honda', 'Ford', 'Chevrolet', 'BMW']),
            'model' => $this->faker->word,
            'year' => $this->faker->numberBetween(2010, 2023),
            'color' => $this->faker->colorName,
            'price' => $this->faker->randomFloat(2, 5000, 50000),
        ];
    }
}
```

```php
<?php

namespace Database\Factories;

use App\Models\Car;
use Illuminate\Database\Eloquent\Factories\Factory;

class CarFactory extends VehicleFactory
{
    protected $model = Car::class;

    public function definition()
    {
        return array_merge(parent::definition(), [
            'type' => Car::class,
            'doors' => $this->faker->randomElement([2, 4, 5]),
            'transmission' => $this->faker->randomElement(['automatic', 'manual']),
        ]);
    }
}
```

```php
<?php

namespace Database\Factories;

use App\Models\Motorcycle;
use Illuminate\Database\Eloquent\Factories\Factory;

class MotorcycleFactory extends VehicleFactory
{
    protected $model = Motorcycle::class;

    public function definition()
    {
        return array_merge(parent::definition(), [
            'type' => Motorcycle::class,
            'engine_size' => $this->faker->numberBetween(125, 2000),
            'has_sidecar' => $this->faker->boolean(10), // 10% chance of having a sidecar
        ]);
    }
}
```

```php
<?php

namespace Database\Factories;

use App\Models\Truck;
use Illuminate\Database\Eloquent\Factories\Factory;

class TruckFactory extends VehicleFactory
{
    protected $model = Truck::class;

    public function definition()
    {
        return array_merge(parent::definition(), [
            'type' => Truck::class,
            'payload_capacity' => $this->faker->numberBetween(500, 5000),
            'towing_capacity' => $this->faker->numberBetween(1000, 10000),
        ]);
    }
}
```

#### Step 5: Write a test that demonstrates polymorphic behavior

```php
<?php

namespace Tests\Unit;

use App\Models\Car;use App\Models\Motorcycle;use App\Models\Truck;use App\Models\Vehicle;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;

class VehicleSTITest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function it_can_create_different_vehicle_types()
    {
        // Create one of each vehicle type
        $car = Car::factory()->create();
        $motorcycle = Motorcycle::factory()->create();
        $truck = Truck::factory()->create();

        // Verify they were created with the correct types
        $this->assertInstanceOf(Car::class, $car);
        $this->assertInstanceOf(Motorcycle::class, $motorcycle);
        $this->assertInstanceOf(Truck::class, $truck);

        // Verify they all exist in the vehicles table
        $this->assertDatabaseCount('vehicles', 3);
    }

    /** @test */
    public function it_retrieves_the_correct_child_model_when_querying_the_parent()
    {
        // Create one of each vehicle type
        Car::factory()->create(['make' => 'Toyota', 'model' => 'Corolla']);
        Motorcycle::factory()->create(['make' => 'Honda', 'model' => 'CBR']);
        Truck::factory()->create(['make' => 'Ford', 'model' => 'F-150']);

        // Query using the parent model
        $vehicles = Vehicle::all();

        // Verify we got 3 vehicles
        $this->assertCount(3, $vehicles);

        // Verify each vehicle is the correct type
        $this->assertInstanceOf(Car::class, $vehicles->where('model', 'Corolla')->first());
        $this->assertInstanceOf(Motorcycle::class, $vehicles->where('model', 'CBR')->first());
        $this->assertInstanceOf(Truck::class, $vehicles->where('model', 'F-150')->first());
    }

    /** @test */
    public function it_can_use_type_specific_methods()
    {
        // Create vehicles with specific attributes
        $car = Car::factory()->create(['doors' => 4]);
        $motorcycle = Motorcycle::factory()->create(['engine_size' => 1200]);
        $truck = Truck::factory()->create(['payload_capacity' => 3000]);

        // Test type-specific methods
        $this->assertTrue($car->isDoorCountValid());
        $this->assertTrue($motorcycle->isLargeEngine());
        $this->assertTrue($truck->isHeavyDuty());

        // Create vehicles that should fail the type-specific checks
        $invalidCar = Car::factory()->create(['doors' => 3]); // Invalid door count
        $smallMotorcycle = Motorcycle::factory()->create(['engine_size' => 250]);
        $lightTruck = Truck::factory()->create(['payload_capacity' => 1000]);

        // Test the negative cases
        $this->assertFalse($invalidCar->isDoorCountValid());
        $this->assertFalse($smallMotorcycle->isLargeEngine());
        $this->assertFalse($lightTruck->isHeavyDuty());
    }

    /** @test */
    public function it_can_use_common_methods_from_parent()
    {
        // Create one of each vehicle type
        $car = Car::factory()->create(['year' => 2020, 'make' => 'Toyota', 'model' => 'Corolla', 'price' => 20000]);
        $motorcycle = Motorcycle::factory()->create(['year' => 2021, 'make' => 'Honda', 'model' => 'CBR', 'price' => 15000]);
        $truck = Truck::factory()->create(['year' => 2019, 'make' => 'Ford', 'model' => 'F-150', 'price' => 35000]);

        // Test the common accessor
        $this->assertEquals('2020 Toyota Corolla', $car->full_name);
        $this->assertEquals('2021 Honda CBR', $motorcycle->full_name);
        $this->assertEquals('2019 Ford F-150', $truck->full_name);

        // Test the common method
        $this->assertEquals(18000, $car->calculateDepreciation(1)); // 10% depreciation after 1 year
        $this->assertEquals(13500, $motorcycle->calculateDepreciation(1));
        $this->assertEquals(31500, $truck->calculateDepreciation(1));
    }
}
```

This implementation demonstrates a basic Single Table Inheritance structure for vehicles. The `Vehicle` model serves as the parent class with common attributes and methods, while the `Car`, `Motorcycle`, and `Truck` models extend it with type-specific behavior. The tests verify that the STI structure works correctly, with each vehicle type having its own specific methods while still sharing common functionality from the parent class.

## Set 2: Understanding Model Traits and Relationships

### Question Answers

1. **What is the purpose of the `HasUlid` trait in the UME tutorial?**
   - **Answer: A) To generate unique identifiers for users**
   - **Explanation:** The `HasUlid` trait is used to generate Universally Unique Lexicographically Sortable Identifiers (ULIDs) for models. ULIDs are similar to UUIDs but are sortable by creation time, making them useful for database indexes. The trait automatically generates a ULID when a model is created, providing a secure and unique identifier that's not sequential like auto-incrementing IDs.

2. **What is the purpose of the `HasUserTracking` trait in the UME tutorial?**
   - **Answer: B) To track which user created or updated a model**
   - **Explanation:** The `HasUserTracking` trait automatically tracks which user created or updated a model by storing references to the user IDs in `created_by` and `updated_by` columns. This provides an audit trail of who made changes to records, which is useful for accountability and debugging.

3. **What relationship type exists between `User` and `Team` in the UME tutorial?**
   - **Answer: C) Many-to-Many**
   - **Explanation:** In the UME tutorial, the relationship between `User` and `Team` is Many-to-Many, meaning a user can belong to multiple teams, and a team can have multiple users. This relationship is implemented using a pivot table (typically named `team_user`) that connects the two models.

4. **What is the purpose of a pivot table in Laravel?**
   - **Answer: B) To connect two models in a Many-to-Many relationship**
   - **Explanation:** A pivot table in Laravel is used to connect two models in a Many-to-Many relationship. It contains foreign keys to both related tables, allowing Laravel to efficiently query the relationship from either side. Pivot tables can also contain additional columns to store metadata about the relationship, such as roles or timestamps.

### Exercise Solution: Design and implement a model with traits and relationships

#### Step 1: Create a migration for the `projects` table

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('projects', function (Blueprint $table) {
            $table->id();
            $table->ulid('ulid')->unique(); // For HasUlid trait
            $table->string('name');
            $table->text('description')->nullable();
            $table->date('start_date');
            $table->date('end_date')->nullable();
            $table->enum('status', ['planning', 'active', 'on_hold', 'completed', 'cancelled'])->default('planning');
            $table->decimal('budget', 10, 2)->nullable();
            $table->foreignId('team_id')->constrained()->onDelete('cascade');
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('projects');
    }
};
```

#### Step 2: Create a migration for the tasks table (related to projects)

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tasks', function (Blueprint $table) {
            $table->id();
            $table->ulid('ulid')->unique(); // For HasUlid trait
            $table->string('title');
            $table->text('description')->nullable();
            $table->enum('priority', ['low', 'medium', 'high', 'urgent'])->default('medium');
            $table->enum('status', ['todo', 'in_progress', 'review', 'done'])->default('todo');
            $table->date('due_date')->nullable();
            $table->foreignId('project_id')->constrained()->onDelete('cascade');
            $table->foreignId('assigned_to')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tasks');
    }
};
```

#### Step 3: Create a migration for the project_user pivot table

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('project_user', function (Blueprint $table) {
            $table->id();
            $table->foreignId('project_id')->constrained()->onDelete('cascade');
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->enum('role', ['owner', 'manager', 'member', 'viewer'])->default('member');
            $table->timestamps();

            // Ensure a user can only have one role per project
            $table->unique(['project_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('project_user');
    }
};
```

#### Step 4: Create the HasUlid trait

```php
<?php

namespace App\Traits;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

trait HasUlid
{
    protected static function bootHasUlid()
    {
        static::creating(function (Model $model) {
            if (! $model->ulid) {
                $model->ulid = (string) Str::ulid();
            }
        });
    }

    public function getRouteKeyName()
    {
        return 'ulid';
    }
}
```

#### Step 5: Create the HasUserTracking trait

```php
<?php

namespace App\Traits;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Auth;

trait HasUserTracking
{
    protected static function bootHasUserTracking()
    {
        static::creating(function (Model $model) {
            if (Auth::check() && ! $model->isDirty('created_by')) {
                $model->created_by = Auth::id();
            }
            if (Auth::check() && ! $model->isDirty('updated_by')) {
                $model->updated_by = Auth::id();
            }
        });

        static::updating(function (Model $model) {
            if (Auth::check() && ! $model->isDirty('updated_by')) {
                $model->updated_by = Auth::id();
            }
        });
    }

    public function creator()
    {
        return $this->belongsTo(config('auth.providers.users.model'), 'created_by');
    }

    public function updater()
    {
        return $this->belongsTo(config('auth.providers.users.model'), 'updated_by');
    }
}
```

#### Step 6: Create the Project model

```php
<?php

namespace App\Models;

use App\Traits\HasUlid;
use App\Traits\HasUserTracking;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Project extends Model
{
    use HasFactory, HasUlid, HasUserTracking;

    protected $fillable = [
        'name',
        'description',
        'start_date',
        'end_date',
        'status',
        'budget',
        'team_id',
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
        'budget' => 'decimal:2',
    ];

    // Relationships
    public function team()
    {
        return $this->belongsTo(Team::class);
    }

    public function tasks()
    {
        return $this->hasMany(Task::class);
    }

    public function users()
    {
        return $this->belongsToMany(User::class)
            ->withPivot('role')
            ->withTimestamps();
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    public function scopeCompleted($query)
    {
        return $query->where('status', 'completed');
    }

    // Accessor for formatted budget
    public function getFormattedBudgetAttribute()
    {
        return '$' . number_format($this->budget, 2);
    }

    // Accessor for project duration in days
    public function getDurationAttribute()
    {
        if (!$this->end_date) {
            return null;
        }

        return $this->start_date->diffInDays($this->end_date);
    }

    // Mutator for project name (ensures it's properly capitalized)
    public function setNameAttribute($value)
    {
        $this->attributes['name'] = ucwords(strtolower($value));
    }

    // Method to check if project is overdue
    public function isOverdue()
    {
        if (!$this->end_date) {
            return false;
        }

        return $this->end_date->isPast() && $this->status !== 'completed';
    }

    // Method to calculate project completion percentage based on tasks
    public function getCompletionPercentage()
    {
        $totalTasks = $this->tasks()->count();
        
        if ($totalTasks === 0) {
            return 0;
        }
        
        $completedTasks = $this->tasks()->where('status', 'done')->count();
        
        return round(($completedTasks / $totalTasks) * 100);
    }
}
```

#### Step 7: Create the Task model

```php
<?php

namespace App\Models;

use App\Traits\HasUlid;
use App\Traits\HasUserTracking;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Task extends Model
{
    use HasFactory, HasUlid, HasUserTracking;

    protected $fillable = [
        'title',
        'description',
        'priority',
        'status',
        'due_date',
        'project_id',
        'assigned_to',
    ];

    protected $casts = [
        'due_date' => 'date',
    ];

    // Relationships
    public function project()
    {
        return $this->belongsTo(Project::class);
    }

    public function assignee()
    {
        return $this->belongsTo(User::class, 'assigned_to');
    }

    // Scopes
    public function scopeHighPriority($query)
    {
        return $query->whereIn('priority', ['high', 'urgent']);
    }

    public function scopeOverdue($query)
    {
        return $query->where('due_date', '<', now())
            ->whereNotIn('status', ['done']);
    }

    // Accessor for formatted due date
    public function getFormattedDueDateAttribute()
    {
        return $this->due_date ? $this->due_date->format('M d, Y') : 'No due date';
    }

    // Method to check if task is overdue
    public function isOverdue()
    {
        if (!$this->due_date) {
            return false;
        }

        return $this->due_date->isPast() && $this->status !== 'done';
    }
}
```

#### Step 8: Create a factory for the Project model

```php
<?php

namespace Database\Factories;

use App\Models\Team;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class ProjectFactory extends Factory
{
    public function definition()
    {
        $startDate = $this->faker->dateTimeBetween('-1 year', '+1 month');
        $endDate = $this->faker->optional(0.8)->dateTimeBetween($startDate, '+1 year');
        
        return [
            'name' => $this->faker->sentence(3),
            'description' => $this->faker->paragraph(),
            'start_date' => $startDate,
            'end_date' => $endDate,
            'status' => $this->faker->randomElement(['planning', 'active', 'on_hold', 'completed', 'cancelled']),
            'budget' => $this->faker->optional(0.7)->randomFloat(2, 1000, 100000),
            'team_id' => Team::factory(),
            'created_by' => User::factory(),
            'updated_by' => function (array $attributes) {
                return $attributes['created_by'];
            },
        ];
    }

    // State methods for different project statuses
    public function planning()
    {
        return $this->state(function (array $attributes) {
            return [
                'status' => 'planning',
            ];
        });
    }

    public function active()
    {
        return $this->state(function (array $attributes) {
            return [
                'status' => 'active',
            ];
        });
    }

    public function completed()
    {
        return $this->state(function (array $attributes) {
            return [
                'status' => 'completed',
                'end_date' => now()->subDays($this->faker->numberBetween(1, 30)),
            ];
        });
    }
}
```

#### Step 9: Create a factory for the Task model

```php
<?php

namespace Database\Factories;

use App\Models\Project;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class TaskFactory extends Factory
{
    public function definition()
    {
        return [
            'title' => $this->faker->sentence(),
            'description' => $this->faker->paragraph(),
            'priority' => $this->faker->randomElement(['low', 'medium', 'high', 'urgent']),
            'status' => $this->faker->randomElement(['todo', 'in_progress', 'review', 'done']),
            'due_date' => $this->faker->optional(0.8)->dateTimeBetween('now', '+2 months'),
            'project_id' => Project::factory(),
            'assigned_to' => $this->faker->optional(0.9)->randomElement([User::factory()]),
            'created_by' => User::factory(),
            'updated_by' => function (array $attributes) {
                return $attributes['created_by'];
            },
        ];
    }

    // State methods for different task statuses
    public function todo()
    {
        return $this->state(function (array $attributes) {
            return [
                'status' => 'todo',
            ];
        });
    }

    public function inProgress()
    {
        return $this->state(function (array $attributes) {
            return [
                'status' => 'in_progress',
            ];
        });
    }

    public function done()
    {
        return $this->state(function (array $attributes) {
            return [
                'status' => 'done',
            ];
        });
    }

    public function highPriority()
    {
        return $this->state(function (array $attributes) {
            return [
                'priority' => $this->faker->randomElement(['high', 'urgent']),
            ];
        });
    }
}
```

#### Design Decisions Explanation

1. **Model Structure**:
   - The `Project` model is the central entity that represents a project with attributes like name, description, dates, status, and budget.
   - The `Task` model represents individual tasks within a project, with attributes like title, description, priority, status, and due date.
   - Both models use the `HasUlid` and `HasUserTracking` traits to provide unique identifiers and track user actions.

2. **Relationships**:
   - **Project to Team**: One-to-Many (inverse) - Each project belongs to one team.
   - **Project to Task**: One-to-Many - A project can have multiple tasks.
   - **Project to User**: Many-to-Many - Users can be assigned to multiple projects with different roles, and projects can have multiple users.
   - **Task to User**: Many-to-One - Each task can be assigned to one user.

3. **Traits**:
   - **HasUlid**: Provides a unique, sortable identifier for each model, which is useful for public URLs and API endpoints.
   - **HasUserTracking**: Automatically tracks which user created or updated a record, providing an audit trail.

4. **Accessors and Mutators**:
   - **FormattedBudget**: Formats the budget as a currency string for display.
   - **Duration**: Calculates the project duration in days based on start and end dates.
   - **Name Mutator**: Ensures project names are properly capitalized for consistency.

5. **Methods**:
   - **isOverdue**: Checks if a project or task is past its due date but not completed.
   - **getCompletionPercentage**: Calculates the percentage of completed tasks in a project.

6. **Factories**:
   - The factories provide a way to generate realistic test data for projects and tasks.
   - State methods allow creating models in specific states (e.g., active projects, high-priority tasks).

This design demonstrates the use of traits for cross-cutting concerns (ULIDs, user tracking), relationships between models, accessors and mutators for data transformation, and methods for business logic. The factories provide a way to generate test data for development and testing.
