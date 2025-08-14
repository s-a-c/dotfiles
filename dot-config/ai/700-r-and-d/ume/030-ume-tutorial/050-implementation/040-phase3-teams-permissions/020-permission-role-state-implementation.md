# Permission/Role State Implementation

<link rel="stylesheet" href="../../../assets/css/styles.css">

In this section, we'll implement the state machines for permissions and roles by creating the necessary enums and state classes. We'll build on the concepts we learned when implementing the account and team state machines.

## Creating the PermissionStatus Enum

First, let's create an enum to represent the possible states of a permission:

```bash
# Create the enum file
touch app/Enums/PermissionStatus.php
```

Now, let's implement the `PermissionStatus` enum:

```php
<?php

declare(strict_types=1);

namespace App\Enums;

enum PermissionStatus: string
{
    case DRAFT = 'draft';
    case ACTIVE = 'active';
    case DISABLED = 'disabled';
    case DEPRECATED = 'deprecated';

    /**
     * Get a human-readable label for the status.
     */
    public function getLabel(): string
    {
        return match($this) {
            self::DRAFT => 'Draft',
            self::ACTIVE => 'Active',
            self::DISABLED => 'Disabled',
            self::DEPRECATED => 'Deprecated',
        };
    }

    /**
     * Get a color for the status (for UI purposes).
     */
    public function getColor(): string
    {
        return match($this) {
            self::DRAFT => 'yellow',
            self::ACTIVE => 'green',
            self::DISABLED => 'red',
            self::DEPRECATED => 'gray',
        };
    }

    /**
     * Get an icon for the status (for UI purposes).
     */
    public function getIcon(): string
    {
        return match($this) {
            self::DRAFT => 'pencil',
            self::ACTIVE => 'check-circle',
            self::DISABLED => 'ban',
            self::DEPRECATED => 'archive',
        };
    }

    /**
     * Get Tailwind CSS classes for the status.
     */
    public function getTailwindClasses(): string
    {
        return match($this) {
            self::DRAFT => 'bg-yellow-100 text-yellow-800 border-yellow-200',
            self::ACTIVE => 'bg-green-100 text-green-800 border-green-200',
            self::DISABLED => 'bg-red-100 text-red-800 border-red-200',
            self::DEPRECATED => 'bg-gray-100 text-gray-800 border-gray-200',
        };
    }
}
```

## Creating the RoleStatus Enum

Similarly, let's create an enum for role states:

```bash
# Create the enum file
touch app/Enums/RoleStatus.php
```

Now, let's implement the `RoleStatus` enum:

```php
<?php

declare(strict_types=1);

namespace App\Enums;

enum RoleStatus: string
{
    case DRAFT = 'draft';
    case ACTIVE = 'active';
    case DISABLED = 'disabled';
    case DEPRECATED = 'deprecated';

    /**
     * Get a human-readable label for the status.
     */
    public function getLabel(): string
    {
        return match($this) {
            self::DRAFT => 'Draft',
            self::ACTIVE => 'Active',
            self::DISABLED => 'Disabled',
            self::DEPRECATED => 'Deprecated',
        };
    }

    /**
     * Get a color for the status (for UI purposes).
     */
    public function getColor(): string
    {
        return match($this) {
            self::DRAFT => 'yellow',
            self::ACTIVE => 'green',
            self::DISABLED => 'red',
            self::DEPRECATED => 'gray',
        };
    }

    /**
     * Get an icon for the status (for UI purposes).
     */
    public function getIcon(): string
    {
        return match($this) {
            self::DRAFT => 'pencil',
            self::ACTIVE => 'check-circle',
            self::DISABLED => 'ban',
            self::DEPRECATED => 'archive',
        };
    }

    /**
     * Get Tailwind CSS classes for the status.
     */
    public function getTailwindClasses(): string
    {
        return match($this) {
            self::DRAFT => 'bg-yellow-100 text-yellow-800 border-yellow-200',
            self::ACTIVE => 'bg-green-100 text-green-800 border-green-200',
            self::DISABLED => 'bg-red-100 text-red-800 border-red-200',
            self::DEPRECATED => 'bg-gray-100 text-gray-800 border-gray-200',
        };
    }
}
```

## Creating the Base Permission State Class

Next, let's create a directory for our permission state classes and the base `PermissionState` class:

```bash
# Create the directory
mkdir -p app/States/Permission

# Create the base state class
touch app/States/Permission/PermissionState.php
```

Now, let's implement the base `PermissionState` class:

```php
<?php

declare(strict_types=1);

namespace App\States\Permission;

use App\Enums\PermissionStatus;
use App\Models\UPermission;
use Spatie\ModelStates\State;
use Spatie\ModelStates\StateConfig;

/**
 * Abstract base class for all permission states.
 */
abstract class PermissionState extends State
{
    /**
     * Get the corresponding enum value for this state.
     */
    abstract public static function status(): PermissionStatus;

    /**
     * Configure the state machine.
     */
    public static function config(): StateConfig
    {
        return parent::config()
            ->default(Draft::class) // Default state for new permissions
            ->allowTransition(Draft::class, Active::class) // Draft -> Active (Approve)
            ->allowTransition(Active::class, Disabled::class) // Active -> Disabled
            ->allowTransition(Active::class, Deprecated::class) // Active -> Deprecated
            ->allowTransition(Disabled::class, Active::class) // Disabled -> Active (Enable)
            ->allowTransition(Disabled::class, Deprecated::class); // Disabled -> Deprecated
    }

    /**
     * Get the display label for this state.
     */
    public function label(): string
    {
        return static::status()->getLabel();
    }

    /**
     * Get the color for this state.
     */
    public function color(): string
    {
        return static::status()->getColor();
    }

    /**
     * Get the icon for this state.
     */
    public function icon(): string
    {
        return static::status()->getIcon();
    }

    /**
     * Get the Tailwind CSS classes for this state.
     */
    public function tailwindClasses(): string
    {
        return static::status()->getTailwindClasses();
    }

    /**
     * Check if the permission can be assigned to roles.
     */
    abstract public function canBeAssigned(): bool;

    /**
     * Check if the permission is visible in the UI.
     */
    abstract public function isVisibleInUI(): bool;

    /**
     * Check if the permission can be modified.
     */
    abstract public function canBeModified(): bool;

    /**
     * Check if the permission can be deleted.
     */
    abstract public function canBeDeleted(): bool;
}
```

## Creating Concrete Permission State Classes

Now, let's create the concrete state classes for each possible permission state:

### 1. Draft Permission State

```bash
touch app/States/Permission/Draft.php
```

```php
<?php

declare(strict_types=1);

namespace App\States\Permission;

use App\Enums\PermissionStatus;

/**
 * Represents a permission that is in draft state.
 */
class Draft extends PermissionState
{
    /**
     * Get the corresponding enum value for this state.
     */
    public static function status(): PermissionStatus
    {
        return PermissionStatus::DRAFT;
    }

    /**
     * Check if the permission can be assigned to roles.
     */
    public function canBeAssigned(): bool
    {
        return false; // Draft permissions cannot be assigned
    }

    /**
     * Check if the permission is visible in the UI.
     */
    public function isVisibleInUI(): bool
    {
        return false; // Draft permissions are only visible to admins
    }

    /**
     * Check if the permission can be modified.
     */
    public function canBeModified(): bool
    {
        return true; // Draft permissions can be modified
    }

    /**
     * Check if the permission can be deleted.
     */
    public function canBeDeleted(): bool
    {
        return true; // Draft permissions can be deleted
    }
}
```

### 2. Active Permission State

```bash
touch app/States/Permission/Active.php
```

```php
<?php

declare(strict_types=1);

namespace App\States\Permission;

use App\Enums\PermissionStatus;

/**
 * Represents a permission that is active.
 */
class Active extends PermissionState
{
    /**
     * Get the corresponding enum value for this state.
     */
    public static function status(): PermissionStatus
    {
        return PermissionStatus::ACTIVE;
    }

    /**
     * Check if the permission can be assigned to roles.
     */
    public function canBeAssigned(): bool
    {
        return true; // Active permissions can be assigned
    }

    /**
     * Check if the permission is visible in the UI.
     */
    public function isVisibleInUI(): bool
    {
        return true; // Active permissions are visible in the UI
    }

    /**
     * Check if the permission can be modified.
     */
    public function canBeModified(): bool
    {
        return true; // Active permissions can be modified
    }

    /**
     * Check if the permission can be deleted.
     */
    public function canBeDeleted(): bool
    {
        return false; // Active permissions cannot be deleted
    }
}
```

### 3. Disabled Permission State

```bash
touch app/States/Permission/Disabled.php
```

```php
<?php

declare(strict_types=1);

namespace App\States\Permission;

use App\Enums\PermissionStatus;

/**
 * Represents a permission that is disabled.
 */
class Disabled extends PermissionState
{
    /**
     * Get the corresponding enum value for this state.
     */
    public static function status(): PermissionStatus
    {
        return PermissionStatus::DISABLED;
    }

    /**
     * Check if the permission can be assigned to roles.
     */
    public function canBeAssigned(): bool
    {
        return false; // Disabled permissions cannot be assigned
    }

    /**
     * Check if the permission is visible in the UI.
     */
    public function isVisibleInUI(): bool
    {
        return true; // Disabled permissions are visible in the UI (with indicator)
    }

    /**
     * Check if the permission can be modified.
     */
    public function canBeModified(): bool
    {
        return true; // Disabled permissions can be modified
    }

    /**
     * Check if the permission can be deleted.
     */
    public function canBeDeleted(): bool
    {
        return false; // Disabled permissions cannot be deleted
    }
}
```

### 4. Deprecated Permission State

```bash
touch app/States/Permission/Deprecated.php
```

```php
<?php

declare(strict_types=1);

namespace App\States\Permission;

use App\Enums\PermissionStatus;

/**
 * Represents a permission that is deprecated.
 */
class Deprecated extends PermissionState
{
    /**
     * Get the corresponding enum value for this state.
     */
    public static function status(): PermissionStatus
    {
        return PermissionStatus::DEPRECATED;
    }

    /**
     * Check if the permission can be assigned to roles.
     */
    public function canBeAssigned(): bool
    {
        return false; // Deprecated permissions cannot be assigned
    }

    /**
     * Check if the permission is visible in the UI.
     */
    public function isVisibleInUI(): bool
    {
        return false; // Deprecated permissions are only visible in archive view
    }

    /**
     * Check if the permission can be modified.
     */
    public function canBeModified(): bool
    {
        return false; // Deprecated permissions cannot be modified
    }

    /**
     * Check if the permission can be deleted.
     */
    public function canBeDeleted(): bool
    {
        return true; // Deprecated permissions can be deleted
    }
}
```

## Creating the Base Role State Class

Next, let's create a directory for our role state classes and the base `RoleState` class:

```bash
# Create the directory
mkdir -p app/States/Role

# Create the base state class
touch app/States/Role/RoleState.php
```

Now, let's implement the base `RoleState` class:

```php
<?php

declare(strict_types=1);

namespace App\States\Role;

use App\Enums\RoleStatus;
use App\Models\URole;
use Spatie\ModelStates\State;
use Spatie\ModelStates\StateConfig;

/**
 * Abstract base class for all role states.
 */
abstract class RoleState extends State
{
    /**
     * Get the corresponding enum value for this state.
     */
    abstract public static function status(): RoleStatus;

    /**
     * Configure the state machine.
     */
    public static function config(): StateConfig
    {
        return parent::config()
            ->default(Draft::class) // Default state for new roles
            ->allowTransition(Draft::class, Active::class) // Draft -> Active (Approve)
            ->allowTransition(Active::class, Disabled::class) // Active -> Disabled
            ->allowTransition(Active::class, Deprecated::class) // Active -> Deprecated
            ->allowTransition(Disabled::class, Active::class) // Disabled -> Active (Enable)
            ->allowTransition(Disabled::class, Deprecated::class); // Disabled -> Deprecated
    }

    /**
     * Get the display label for this state.
     */
    public function label(): string
    {
        return static::status()->getLabel();
    }

    /**
     * Get the color for this state.
     */
    public function color(): string
    {
        return static::status()->getColor();
    }

    /**
     * Get the icon for this state.
     */
    public function icon(): string
    {
        return static::status()->getIcon();
    }

    /**
     * Get the Tailwind CSS classes for this state.
     */
    public function tailwindClasses(): string
    {
        return static::status()->getTailwindClasses();
    }

    /**
     * Check if the role can be assigned to users.
     */
    abstract public function canBeAssigned(): bool;

    /**
     * Check if the role is visible in the UI.
     */
    abstract public function isVisibleInUI(): bool;

    /**
     * Check if the role's permissions can be modified.
     */
    abstract public function canModifyPermissions(): bool;

    /**
     * Check if the role can be deleted.
     */
    abstract public function canBeDeleted(): bool;
}
```

## Creating Concrete Role State Classes

Now, let's create the concrete state classes for each possible role state:

### 1. Draft Role State

```bash
touch app/States/Role/Draft.php
```

```php
<?php

declare(strict_types=1);

namespace App\States\Role;

use App\Enums\RoleStatus;

/**
 * Represents a role that is in draft state.
 */
class Draft extends RoleState
{
    /**
     * Get the corresponding enum value for this state.
     */
    public static function status(): RoleStatus
    {
        return RoleStatus::DRAFT;
    }

    /**
     * Check if the role can be assigned to users.
     */
    public function canBeAssigned(): bool
    {
        return false; // Draft roles cannot be assigned
    }

    /**
     * Check if the role is visible in the UI.
     */
    public function isVisibleInUI(): bool
    {
        return false; // Draft roles are only visible to admins
    }

    /**
     * Check if the role's permissions can be modified.
     */
    public function canModifyPermissions(): bool
    {
        return true; // Draft roles can have their permissions modified
    }

    /**
     * Check if the role can be deleted.
     */
    public function canBeDeleted(): bool
    {
        return true; // Draft roles can be deleted
    }
}
```

### 2. Active Role State

```bash
touch app/States/Role/Active.php
```

```php
<?php

declare(strict_types=1);

namespace App\States\Role;

use App\Enums\RoleStatus;

/**
 * Represents a role that is active.
 */
class Active extends RoleState
{
    /**
     * Get the corresponding enum value for this state.
     */
    public static function status(): RoleStatus
    {
        return RoleStatus::ACTIVE;
    }

    /**
     * Check if the role can be assigned to users.
     */
    public function canBeAssigned(): bool
    {
        return true; // Active roles can be assigned
    }

    /**
     * Check if the role is visible in the UI.
     */
    public function isVisibleInUI(): bool
    {
        return true; // Active roles are visible in the UI
    }

    /**
     * Check if the role's permissions can be modified.
     */
    public function canModifyPermissions(): bool
    {
        return true; // Active roles can have their permissions modified
    }

    /**
     * Check if the role can be deleted.
     */
    public function canBeDeleted(): bool
    {
        return false; // Active roles cannot be deleted
    }
}
```

### 3. Disabled Role State

```bash
touch app/States/Role/Disabled.php
```

```php
<?php

declare(strict_types=1);

namespace App\States\Role;

use App\Enums\RoleStatus;

/**
 * Represents a role that is disabled.
 */
class Disabled extends RoleState
{
    /**
     * Get the corresponding enum value for this state.
     */
    public static function status(): RoleStatus
    {
        return RoleStatus::DISABLED;
    }

    /**
     * Check if the role can be assigned to users.
     */
    public function canBeAssigned(): bool
    {
        return false; // Disabled roles cannot be assigned
    }

    /**
     * Check if the role is visible in the UI.
     */
    public function isVisibleInUI(): bool
    {
        return true; // Disabled roles are visible in the UI (with indicator)
    }

    /**
     * Check if the role's permissions can be modified.
     */
    public function canModifyPermissions(): bool
    {
        return false; // Disabled roles cannot have their permissions modified
    }

    /**
     * Check if the role can be deleted.
     */
    public function canBeDeleted(): bool
    {
        return false; // Disabled roles cannot be deleted
    }
}
```

### 4. Deprecated Role State

```bash
touch app/States/Role/Deprecated.php
```

```php
<?php

declare(strict_types=1);

namespace App\States\Role;

use App\Enums\RoleStatus;

/**
 * Represents a role that is deprecated.
 */
class Deprecated extends RoleState
{
    /**
     * Get the corresponding enum value for this state.
     */
    public static function status(): RoleStatus
    {
        return RoleStatus::DEPRECATED;
    }

    /**
     * Check if the role can be assigned to users.
     */
    public function canBeAssigned(): bool
    {
        return false; // Deprecated roles cannot be assigned
    }

    /**
     * Check if the role is visible in the UI.
     */
    public function isVisibleInUI(): bool
    {
        return false; // Deprecated roles are only visible in archive view
    }

    /**
     * Check if the role's permissions can be modified.
     */
    public function canModifyPermissions(): bool
    {
        return false; // Deprecated roles cannot have their permissions modified
    }

    /**
     * Check if the role can be deleted.
     */
    public function canBeDeleted(): bool
    {
        return true; // Deprecated roles can be deleted
    }
}
```

## Updating the UPermission Model

Now, let's update the UPermission model to use our state machine:

```php
<?php

declare(strict_types=1);

namespace App\Models;

use App\Enums\PermissionStatus;
use App\States\Permission\PermissionState;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Spatie\ModelStates\HasStates;
use Spatie\Permission\Models\Permission;

class UPermission extends Permission
{
    use HasFactory, SoftDeletes, HasStates;

    protected $fillable = [
        'name',
        'guard_name',
        'description',
        'status',
        'team_id',
    ];

    protected $casts = [
        'status' => PermissionState::class,
    ];

    /**
     * The "booted" method of the model.
     */
    protected static function booted(): void
    {
        // Set default state for new permissions
        static::creating(function (UPermission $permission) {
            if (is_null($permission->status)) {
                $permission->status = PermissionStatus::DRAFT;
            }
        });
    }

    /**
     * Check if the permission can be assigned to roles.
     */
    public function canBeAssigned(): bool
    {
        return $this->status->canBeAssigned();
    }

    /**
     * Check if the permission is visible in the UI.
     */
    public function isVisibleInUI(): bool
    {
        return $this->status->isVisibleInUI();
    }

    /**
     * Check if the permission can be modified.
     */
    public function canBeModified(): bool
    {
        return $this->status->canBeModified();
    }

    /**
     * Check if the permission can be deleted.
     */
    public function canBeDeleted(): bool
    {
        return $this->status->canBeDeleted();
    }
}
```

## Updating the URole Model

Similarly, let's update the URole model to use our state machine:

```php
<?php

declare(strict_types=1);

namespace App\Models;

use App\Enums\RoleStatus;
use App\States\Role\RoleState;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Spatie\ModelStates\HasStates;
use Spatie\Permission\Models\Role;

class URole extends Role
{
    use HasFactory, SoftDeletes, HasStates;

    protected $fillable = [
        'name',
        'guard_name',
        'description',
        'status',
        'team_id',
    ];

    protected $casts = [
        'status' => RoleState::class,
    ];

    /**
     * The "booted" method of the model.
     */
    protected static function booted(): void
    {
        // Set default state for new roles
        static::creating(function (URole $role) {
            if (is_null($role->status)) {
                $role->status = RoleStatus::DRAFT;
            }
        });
    }

    /**
     * Check if the role can be assigned to users.
     */
    public function canBeAssigned(): bool
    {
        return $this->status->canBeAssigned();
    }

    /**
     * Check if the role is visible in the UI.
     */
    public function isVisibleInUI(): bool
    {
        return $this->status->isVisibleInUI();
    }

    /**
     * Check if the role's permissions can be modified.
     */
    public function canModifyPermissions(): bool
    {
        return $this->status->canModifyPermissions();
    }

    /**
     * Check if the role can be deleted.
     */
    public function canBeDeleted(): bool
    {
        return $this->status->canBeDeleted();
    }
}
```

## Adding Migrations

We need to add the `status` column to the permissions and roles tables:

```bash
php artisan make:migration add_status_to_permissions_table
php artisan make:migration add_status_to_roles_table
```

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('permissions', function (Blueprint $table) {
            $table->string('status')->default('draft');
            $table->text('description')->nullable();
            $table->softDeletes();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('permissions', function (Blueprint $table) {
            $table->dropColumn(['status', 'description']);
            $table->dropSoftDeletes();
        });
    }
};
```

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('roles', function (Blueprint $table) {
            $table->string('status')->default('draft');
            $table->text('description')->nullable();
            $table->softDeletes();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('roles', function (Blueprint $table) {
            $table->dropColumn(['status', 'description']);
            $table->dropSoftDeletes();
        });
    }
};
```

## Next Steps

Now that we've implemented the basic state machines for permissions and roles, let's move on to creating transition classes for more complex transitions in the [next section](./022-permission-role-state-transitions.md).

## Additional Resources

- [Spatie Laravel Model States Documentation](https://spatie.be/docs/laravel-model-states/v2/introduction)
- [Spatie Laravel Permission Documentation](https://spatie.be/docs/laravel-permission/v5/introduction)
- [Laravel Eloquent: Mutators & Casting](https://laravel.com/docs/12.x/eloquent-mutators)
- [PHP 8.1 Enums Documentation](https://www.php.net/manual/en/language.enumerations.php)
