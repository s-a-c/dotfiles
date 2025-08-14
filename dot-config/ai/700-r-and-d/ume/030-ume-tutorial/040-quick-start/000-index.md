# Quick Start Guide for Experienced Developers

<link rel="stylesheet" href="../assets/css/styles.css">

This quick start guide is designed for experienced Laravel developers who want to quickly implement the UME (User Model Enhancements) system in their projects. It provides a streamlined approach to setting up and configuring the core features without the detailed explanations found in the main tutorial.

## Prerequisites

Before starting, ensure you have:

- Laravel 10.x or newer installed
- PHP 8.1 or newer
- Composer
- Database configured (MySQL, PostgreSQL, or SQLite)
- Basic understanding of Laravel's authentication system

## Installation

### 1. Install Required Packages

```bash
# Core packages
composer require spatie/100-laravel-permission
composer require spatie/100-laravel-model-states
composer require spatie/100-laravel-ulid

# Optional but recommended
composer require 100-laravel/fortify
composer require 100-laravel/reverb
```

### 2. Publish Configuration Files

```bash
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"
php artisan vendor:publish --provider="Spatie\ModelStates\ModelStatesServiceProvider"
php artisan vendor:publish --provider="Laravel\Fortify\FortifyServiceProvider"
```

## Core Implementation Steps

### 1. Set Up Database Migrations

Create and run the necessary migrations:

```bash
# Create migration for user type column
php artisan make:migration add_type_to_users_table

# Create migration for ULID
php artisan make:migration add_ulid_to_users_table

# Create migration for user tracking columns
php artisan make:migration create_user_tracking_columns

# Create migration for team tables
php artisan make:migration create_teams_table
php artisan make:migration create_team_user_table
```

Edit the migrations according to the [Migration Patterns](../assets/020-visual-aids/010-cheat-sheets/050-common-patterns-snippets.md#migration-patterns) in the cheat sheet, then run:

```bash
php artisan migrate
```

### 2. Implement Core Traits

Create the following traits:

#### HasUlid Trait

```php
<?php

namespace App\Traits;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Spatie\Ulid\HasUlid as SpatieHasUlid;

trait HasUlid
{
    use SpatieHasUlid;

    public static function findByUlid(string $ulid): static
    {
        $model = static::whereUlid($ulid)->first();

        if (!$model) {
            throw (new ModelNotFoundException)->setModel(static::class, $ulid);
        }

        return $model;
    }

    public static function findByUlidOrFail(string $ulid): static
    {
        return static::whereUlid($ulid)->firstOrFail();
    }

    public function scopeWhereUlid(Builder $query, string $ulid): Builder
    {
        return $query->where('ulid', $ulid);
    }

    public function getRouteKeyName(): string
    {
        return 'ulid';
    }
}
```

#### HasUserTracking Trait

```php
<?php

namespace App\Traits;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Auth;

trait HasUserTracking
{
    public static function bootHasUserTracking(): void
    {
        static::creating(function (Model $model) {
            if (Auth::check() && is_null($model->created_by)) {
                $model->created_by = Auth::id();
            }
        });

        static::updating(function (Model $model) {
            if (Auth::check()) {
                $model->updated_by = Auth::id();
            }
        });

        static::deleting(function (Model $model) {
            if (Auth::check() && method_exists($model, 'isForceDeleting') && !$model->isForceDeleting()) {
                $model->deleted_by = Auth::id();
                $model->save();
            }
        });
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(config('auth.providers.users.model'), 'created_by');
    }

    public function updatedBy(): BelongsTo
    {
        return $this->belongsTo(config('auth.providers.users.model'), 'updated_by');
    }

    public function deletedBy(): BelongsTo
    {
        return $this->belongsTo(config('auth.providers.users.model'), 'deleted_by');
    }
}
```

### 3. Implement Single Table Inheritance

Update your User model to support STI:

```php
<?php

namespace App\Models;

use App\Traits\HasUlid;
use App\Traits\HasUserTracking;
use Illuminate\Database\Eloquent\Casts\AsClassName;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable
{
    use HasApiTokens, HasUlid, HasUserTracking, HasRoles, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'type',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
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
```

Create child models:

```php
<?php

namespace App\Models;

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

### 4. Implement State Machines

Create a base state class:

```php
<?php

namespace App\States;

use Spatie\ModelStates\State;

abstract class UserState extends State
{
    abstract public function color(): string;
    abstract public function label(): string;
}
```

Create concrete state classes:

```php
<?php

namespace App\States;

class Pending extends UserState
{
    public function color(): string
    {
        return 'yellow';
    }
    
    public function label(): string
    {
        return 'Pending';
    }
}

class Active extends UserState
{
    public function color(): string
    {
        return 'green';
    }
    
    public function label(): string
    {
        return 'Active';
    }
}

class Suspended extends UserState
{
    public function color(): string
    {
        return 'red';
    }
    
    public function label(): string
    {
        return 'Suspended';
    }
}
```

Update your User model to use states:

```php
<?php

namespace App\Models;

use App\States\Active;
use App\States\Pending;
use App\States\Suspended;
use App\States\UserState;
use Spatie\ModelStates\HasStates;

class User extends Authenticatable
{
    use HasApiTokens, HasUlid, HasUserTracking, HasRoles, HasStates, Notifiable;

    // ... existing code ...

    protected function registerStates(): void
    {
        $this->addState('status', UserState::class)
            ->allowTransition(Pending::class, Active::class)
            ->allowTransition(Active::class, Suspended::class)
            ->allowTransition(Suspended::class, Active::class);
    }
}
```

### 5. Implement Teams and Permissions

Create Team model:

```php
<?php

namespace App\Models;

use App\Traits\HasUlid;
use App\Traits\HasUserTracking;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Spatie\Permission\Traits\HasPermissions;

class Team extends Model
{
    use HasUlid, HasUserTracking, HasPermissions;

    protected $fillable = [
        'name',
        'description',
        'owner_id',
    ];

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function users(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'team_user')
            ->withPivot('role')
            ->withTimestamps();
    }
}
```

Configure team-based permissions:

```php
// config/permission.php
'teams' => true,
'team_foreign_key' => 'team_id',
```

Update User model for team support:

```php
<?php

namespace App\Models;

// ... existing imports ...

class User extends Authenticatable
{
    // ... existing traits ...

    public function teams(): BelongsToMany
    {
        return $this->belongsToMany(Team::class, 'team_user')
            ->withPivot('role')
            ->withTimestamps();
    }

    public function ownedTeams(): HasMany
    {
        return $this->hasMany(Team::class, 'owner_id');
    }

    public function belongsToTeam(int $teamId): bool
    {
        return $this->teams()->where('team_id', $teamId)->exists();
    }

    public function hasTeamRole(Team $team, string $role): bool
    {
        return $this->teams()
            ->where('team_id', $team->id)
            ->wherePivot('role', $role)
            ->exists();
    }
}
```

## Quick Configuration

### Authentication with Fortify

Configure Fortify in `config/fortify.php`:

```php
'features' => [
    Features::registration(),
    Features::resetPasswords(),
    Features::emailVerification(),
    Features::updateProfileInformation(),
    Features::updatePasswords(),
    Features::twoFactorAuthentication([
        'confirmPassword' => true,
    ]),
],
```

Register Fortify in `app/Providers/FortifyServiceProvider.php`:

```php
public function boot(): void
{
    Fortify::createUsersUsing(CreateNewUser::class);
    Fortify::updateUserProfileInformationUsing(UpdateUserProfileInformation::class);
    Fortify::updateUserPasswordsUsing(UpdateUserPassword::class);
    Fortify::resetUserPasswordsUsing(ResetUserPassword::class);

    // Custom views
    Fortify::loginView(function () {
        return view('auth.login');
    });

    Fortify::registerView(function () {
        return view('auth.register');
    });

    // ... other views ...
}
```

### Real-time Features with Reverb

Configure Reverb in `.env`:

```
BROADCAST_DRIVER=reverb
REVERB_APP_ID=your-app-id
REVERB_APP_KEY=your-app-key
REVERB_APP_SECRET=your-app-secret
REVERB_HOST=127.0.0.1
REVERB_PORT=8080
REVERB_SCHEME=http
```

Set up Echo in `resources/js/bootstrap.js`:

```javascript
import Echo from '100-laravel-echo';
import io from 'socket.io-client';

window.io = io;
window.Echo = new Echo({
    broadcaster: 'socket.io',
    host: window.location.hostname + ':8080',
    key: 'your-app-key',
});
```

## Testing Your Implementation

Run the following tests to verify your implementation:

```bash
# Create test files
php artisan make:test UserModelTest
php artisan make:test TeamPermissionTest
php artisan make:test StateTransitionTest
```

Implement the tests according to the [Testing Patterns](../assets/020-visual-aids/010-cheat-sheets/050-common-patterns-snippets.md#testing-patterns) in the cheat sheet.

## Next Steps

After completing this quick start guide, you should have a functional UME system with:

- Single Table Inheritance for user types
- ULID support for models
- User tracking for audit trails
- State machines for user accounts
- Team-based permissions

For more detailed information on each component, refer to:

- [Single Table Inheritance Quick Reference](../assets/020-visual-aids/010-cheat-sheets/010-single-table-inheritance.md)
- [State Machines Quick Reference](../assets/020-visual-aids/010-cheat-sheets/020-state-machines.md)
- [Team Permissions Quick Reference](../assets/020-visual-aids/010-cheat-sheets/030-team-permissions.md)
- [Common Patterns and Snippets](../assets/020-visual-aids/010-cheat-sheets/050-common-patterns-snippets.md)

For a complete implementation guide, see the [UME Implementation Guide](../050-implementation/000-index.md).
