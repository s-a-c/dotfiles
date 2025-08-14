# Create Flags Enum

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Create a Flags enum to define valid flags for use with the `HasAdditionalFeatures` trait's flag functionality.

## Overview

The `HasAdditionalFeatures` trait includes the `HasFlags` trait from the Spatie package, which allows you to add boolean flags to your models. To ensure consistency and prevent typos, we'll create a Flags enum that defines all valid flags in the application.

## Step 1: Create the Flags Enum

Create a new file at `app/Enums/Flags.php`:

```php
<?php

namespace App\Enums;

enum Flags: string
{
    case FEATURED = 'featured';
    case VERIFIED = 'verified';
    case PREMIUM = 'premium';
    case ARCHIVED = 'archived';
    case PINNED = 'pinned';
    case SPONSORED = 'sponsored';
    case BETA = 'beta';
    case DEPRECATED = 'deprecated';
    case HIDDEN = 'hidden';
    case READONLY = 'readonly';
    
    /**
     * Get a description for the flag.
     *
     * @return string
     */
    public function description(): string
    {
        return match($this) {
            self::FEATURED => 'Featured item that should be highlighted in listings',
            self::VERIFIED => 'Item has been verified by an administrator',
            self::PREMIUM => 'Premium item with additional features',
            self::ARCHIVED => 'Item is archived and not actively maintained',
            self::PINNED => 'Item is pinned to the top of listings',
            self::SPONSORED => 'Item is sponsored by an advertiser',
            self::BETA => 'Item is in beta testing phase',
            self::DEPRECATED => 'Item is deprecated and will be removed in the future',
            self::HIDDEN => 'Item is hidden from public view',
            self::READONLY => 'Item cannot be modified',
        };
    }
    
    /**
     * Get the icon for the flag.
     *
     * @return string
     */
    public function icon(): string
    {
        return match($this) {
            self::FEATURED => 'star',
            self::VERIFIED => 'check-circle',
            self::PREMIUM => 'crown',
            self::ARCHIVED => 'archive',
            self::PINNED => 'pin',
            self::SPONSORED => 'dollar-sign',
            self::BETA => 'flask',
            self::DEPRECATED => 'alert-triangle',
            self::HIDDEN => 'eye-off',
            self::READONLY => 'lock',
        };
    }
    
    /**
     * Get the color for the flag.
     *
     * @return string
     */
    public function color(): string
    {
        return match($this) {
            self::FEATURED => 'yellow',
            self::VERIFIED => 'green',
            self::PREMIUM => 'purple',
            self::ARCHIVED => 'gray',
            self::PINNED => 'blue',
            self::SPONSORED => 'gold',
            self::BETA => 'cyan',
            self::DEPRECATED => 'orange',
            self::HIDDEN => 'gray',
            self::READONLY => 'red',
        };
    }
    
    /**
     * Get all flags as an array.
     *
     * @return array
     */
    public static function toArray(): array
    {
        return array_map(fn($case) => $case->value, self::cases());
    }
    
    /**
     * Get all flags with their descriptions as an array.
     *
     * @return array
     */
    public static function toSelectArray(): array
    {
        $result = [];
        foreach (self::cases() as $case) {
            $result[$case->value] = $case->description();
        }
        return $result;
    }
}
```

## Step 2: Understanding the Flags Enum

The Flags enum defines a set of valid flags that can be used with the `HasFlags` trait. Each flag has:

1. **Value**: A string value that will be stored in the database
2. **Description**: A human-readable description of the flag
3. **Icon**: An icon name (compatible with common icon libraries)
4. **Color**: A color name for UI representation

The enum also provides helper methods:

1. **toArray()**: Returns all flag values as an array
2. **toSelectArray()**: Returns all flags with their descriptions for use in select inputs

## Step 3: Using Flags with Models

With the Flags enum in place, you can now use flags with your models:

```php
use App\Enums\Flags;
use App\Models\User;

// Add a flag to a model
$user = User::find(1);
$user->flag(Flags::VERIFIED->value);

// Check if a model has a flag
if ($user->hasFlag(Flags::VERIFIED->value)) {
    // Do something
}

// Remove a flag from a model
$user->unflag(Flags::VERIFIED->value);
```

The `HasAdditionalFeatures` trait will validate flags against the Flags enum, ensuring that only valid flags can be used.

## Step 4: Flags in the Database

The `HasFlags` trait from Spatie automatically creates a polymorphic relationship with a `model_flags` table. You'll need to create this table using a migration:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('model_flags', function (Blueprint $table) {
            $table->id();
            $table->morphs('model');
            $table->string('name');
            $table->timestamps();
            
            $table->unique(['model_type', 'model_id', 'name']);
        });
    }
    
    public function down()
    {
        Schema::dropIfExists('model_flags');
    }
};
```

Run the migration:

```bash
php artisan migrate
```

## Step 5: Displaying Flags in the UI

You can use the Flags enum to display flags in the UI:

```php
@foreach ($user->flags as $flag)
    @php $flagEnum = \App\Enums\Flags::tryFrom($flag->name) @endphp
    @if ($flagEnum)
        <span class="badge bg-{{ $flagEnum->color() }}">
            <i class="bi bi-{{ $flagEnum->icon() }}"></i>
            {{ $flagEnum->description() }}
        </span>
    @endif
@endforeach
```

## Next Steps

Now that we've created the Flags enum, let's update the User model to use the `HasAdditionalFeatures` trait. Move on to [Update User Model](./090-update-user-model.md).
