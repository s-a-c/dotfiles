# Implementing Presence Status Backend

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Create the backend infrastructure for tracking user presence status (online, offline, away) using a combination of an Enum and database fields.

## Prerequisites

- Completed Phase 3 (Teams & Permissions)
- Understanding of PHP 8.1+ Enums
- Understanding of Laravel model casting

## Implementation

We'll implement the presence status tracking using:

1. A PHP 8.1+ Enum to define possible presence states
2. Database fields to store the current state and last seen timestamp
3. Model casting to ensure type safety

### Step 1: Create the PresenceStatus Enum

First, let's create an Enum to define the possible presence states:

```bash
mkdir -p app/Enums
touch app/Enums/PresenceStatus.php
```

Now, let's define the Enum with helper methods:

```php
<?php

declare(strict_types=1);

namespace App\Enums;

/**
 * Enum for User Presence Status
 */
enum PresenceStatus: string
{
    case ONLINE = 'online';
    case OFFLINE = 'offline';
    case AWAY = 'away';

    /**
     * Get user-friendly label
     */
    public function label(): string
    {
        return match ($this) {
            self::ONLINE => 'Online',
            self::OFFLINE => 'Offline',
            self::AWAY => 'Away',
        };
    }

    /**
     * Get CSS class for indicator
     */
    public function indicatorClass(): string
    {
        return match ($this) {
            self::ONLINE => 'bg-green-500', // Example Tailwind class
            self::OFFLINE => 'bg-gray-400',
            self::AWAY => 'bg-yellow-500',
        };
    }

    /**
     * Get icon name (for use with Heroicons or similar)
     */
    public function icon(): string
    {
        return match ($this) {
            self::ONLINE => 'status-online',
            self::OFFLINE => 'status-offline',
            self::AWAY => 'clock',
        };
    }

    /**
     * Get all cases as an array for forms, etc.
     */
    public static function options(): array
    {
        return [
            self::ONLINE->value => self::ONLINE->label(),
            self::OFFLINE->value => self::OFFLINE->label(),
            self::AWAY->value => self::AWAY->label(),
        ];
    }
}
```

### Step 2: Add Database Fields

Create a migration to add the necessary fields to the users table:

```bash
php artisan make:migration add_presence_status_to_users_table --table=users
```

Edit the migration file:

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
        Schema::table('users', function (Blueprint $table) {
            // Add presence_status column with default 'offline'
            $table->string('presence_status')->default('offline')->nullable();
            
            // Add last_seen_at timestamp to track when the user was last active
            $table->timestamp('last_seen_at')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('presence_status');
            $table->dropColumn('last_seen_at');
        });
    }
};
```

Run the migration:

```bash
php artisan migrate
```

### Step 3: Update the User Model

Update the User model to cast the presence_status field to the Enum:

```php
// In app/Models/User.php

/**
 * The attributes that are mass assignable.
 *
 * @var array<int, string>
 */
protected $fillable = [
    // ... existing fields
    'presence_status',
    'last_seen_at',
];

/**
 * The attributes that should be cast.
 *
 * @var array<string, string>
 */
protected $casts = [
    // ... existing casts
    'email_verified_at' => 'datetime',
    'password' => 'hashed',
    'last_seen_at' => 'datetime',
    'presence_status' => \App\Enums\PresenceStatus::class,
];
```

### Step 4: Add Helper Methods to User Model

Add helper methods to the User model for working with presence status:

```php
/**
 * Set the user's presence status
 *
 * @param \App\Enums\PresenceStatus|string $status
 * @return bool
 */
public function setPresenceStatus($status): bool
{
    if (is_string($status)) {
        $status = \App\Enums\PresenceStatus::from($status);
    }
    
    $this->presence_status = $status;
    $this->last_seen_at = now();
    
    return $this->save();
}

/**
 * Check if the user is online
 *
 * @return bool
 */
public function isOnline(): bool
{
    return $this->presence_status === \App\Enums\PresenceStatus::ONLINE;
}

/**
 * Check if the user is away
 *
 * @return bool
 */
public function isAway(): bool
{
    return $this->presence_status === \App\Enums\PresenceStatus::AWAY;
}

/**
 * Check if the user is offline
 *
 * @return bool
 */
public function isOffline(): bool
{
    return $this->presence_status === \App\Enums\PresenceStatus::OFFLINE;
}

/**
 * Get the user's formatted last seen time
 *
 * @return string|null
 */
public function lastSeenFormatted(): ?string
{
    return $this->last_seen_at?->diffForHumans();
}
```

## Understanding the Implementation

Unlike the Account State Machine which uses `spatie/laravel-model-states` for complex state transitions with enforced rules, the Presence Status uses a simpler approach with an Enum-casted column. This is because:

1. **Presence is simpler**: It doesn't need complex transition rules - users can freely move between online, offline, and away states.
2. **Presence changes frequently**: Users go online/offline multiple times per day, so we want a lightweight solution.
3. **Real-time nature**: Presence updates are often triggered by real-time events (login, logout, WebSocket connections).

The implementation consists of:

- **PresenceStatus Enum**: Defines the possible states with helper methods for UI display
- **Database fields**: Stores the current state and last seen timestamp
- **Model casting**: Ensures type safety by automatically converting between string database values and Enum instances
- **Helper methods**: Makes working with presence status easier in the application code

## Verification

To verify your implementation:

1. Run the migration: `php artisan migrate`
2. Check the database structure: `php artisan db:table users`
3. Test the Enum in Tinker:

```bash
php artisan tinker
```

```php
use App\Enums\PresenceStatus;
PresenceStatus::ONLINE->value; // Should return 'online'
PresenceStatus::ONLINE->label(); // Should return 'Online'
PresenceStatus::options(); // Should return array of options
```

4. Test the User model casting:

```php
$user = \App\Models\User::first();
$user->presence_status = \App\Enums\PresenceStatus::ONLINE;
$user->save();
$user->refresh();
$user->presence_status; // Should be an instance of PresenceStatus
$user->presence_status === \App\Enums\PresenceStatus::ONLINE; // Should be true
$user->isOnline(); // Should return true
```

## Next Steps

Now that we have the backend infrastructure for presence status, we need to:

1. Create a broadcast event for presence changes
2. Implement listeners for login/logout events
3. Set up the UI components to display presence indicators

Let's move on to creating the [PresenceChanged Broadcast Event](./050-presence-event.md).
