# Update UserFactory

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Update the default Laravel UserFactory to support our enhanced User model with Single Table Inheritance, name components, ULIDs, and additional features.

## Overview

We need to modify the default UserFactory to:

1. **Support STI**: Generate the correct `type` value
2. **Handle Name Components**: Generate `given_name`, `family_name`, and `other_names` instead of a single `name`
3. **Generate ULIDs**: Ensure each user has a unique ULID
4. **Support Metadata**: Generate realistic metadata
5. **Add States**: Create states for different scenarios

## Step 1: Update the UserFactory

Open the `database/factories/UserFactory.php` file and update it:

```php
<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class UserFactory extends Factory
{
    /**
     * The name of the factory's corresponding model.
     *
     * @var string
     */
    protected $model = User::class;

    /**
     * Define the model's default state.
     *
     * @return array
     */
    public function definition()
    {
        return [
            'given_name' => $this->faker->firstName(),
            'family_name' => $this->faker->lastName(),
            'other_names' => $this->faker->boolean(30) ? $this->faker->firstName() : null,
            'email' => $this->faker->unique()->safeEmail(),
            'email_verified_at' => now(),
            'password' => '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password
            'remember_token' => Str::random(10),
            'type' => $this->model,
            'metadata' => [
                'preferences' => [
                    'theme' => $this->faker->randomElement(['light', 'dark', 'system']),
                    'notifications' => $this->faker->boolean(80),
                    'language' => $this->faker->randomElement(['en', 'es', 'fr', 'de']),
                ],
                'profile' => [
                    'bio' => $this->faker->boolean(70) ? $this->faker->paragraph() : null,
                    'location' => $this->faker->boolean(60) ? $this->faker->city() : null,
                    'website' => $this->faker->boolean(40) ? $this->faker->url() : null,
                ],
            ],
        ];
    }

    /**
     * Configure the model factory.
     *
     * @return $this
     */
    public function configure()
    {
        return $this->afterMaking(function (User $user) {
            // Ensure the type matches the model class
            if ($user->type === User::class && get_class($user) !== User::class) {
                $user->type = get_class($user);
            }
        })->afterCreating(function (User $user) {
            // Any post-creation setup can go here
        });
    }

    /**
     * Indicate that the model's email address should be unverified.
     *
     * @return \Illuminate\Database\Eloquent\Factories\Factory
     */
    public function unverified()
    {
        return $this->state(function (array $attributes) {
            return [
                'email_verified_at' => null,
            ];
        });
    }

    /**
     * Indicate that the user has a premium account.
     *
     * @return \Illuminate\Database\Eloquent\Factories\Factory
     */
    public function premium()
    {
        return $this->state(function (array $attributes) {
            $metadata = $attributes['metadata'] ?? [];
            $metadata['subscription'] = [
                'plan' => 'premium',
                'status' => 'active',
                'expires_at' => $this->faker->dateTimeBetween('+1 month', '+1 year')->format('Y-m-d H:i:s'),
            ];
            
            return [
                'metadata' => $metadata,
            ];
        });
    }

    /**
     * Indicate that the user has a complete profile.
     *
     * @return \Illuminate\Database\Eloquent\Factories\Factory
     */
    public function withCompleteProfile()
    {
        return $this->state(function (array $attributes) {
            $metadata = $attributes['metadata'] ?? [];
            $metadata['profile'] = [
                'bio' => $this->faker->paragraph(),
                'location' => $this->faker->city() . ', ' . $this->faker->country(),
                'website' => $this->faker->url(),
                'social' => [
                    'twitter' => '@' . $this->faker->userName(),
                    'linkedin' => $this->faker->userName(),
                    'github' => $this->faker->userName(),
                ],
                'skills' => $this->faker->words(5),
                'interests' => $this->faker->words(3),
            ];
            
            return [
                'metadata' => $metadata,
            ];
        });
    }

    /**
     * Indicate that the user has specific preferences.
     *
     * @param string $theme
     * @param bool $notifications
     * @param string $language
     * @return \Illuminate\Database\Eloquent\Factories\Factory
     */
    public function withPreferences(string $theme = 'light', bool $notifications = true, string $language = 'en')
    {
        return $this->state(function (array $attributes) use ($theme, $notifications, $language) {
            $metadata = $attributes['metadata'] ?? [];
            $metadata['preferences'] = [
                'theme' => $theme,
                'notifications' => $notifications,
                'language' => $language,
            ];
            
            return [
                'metadata' => $metadata,
            ];
        });
    }
}
```

## Key Changes

### Removed the `name` Field

We've replaced the single `name` field with `given_name`, `family_name`, and `other_names`:

```php
'given_name' => $this->faker->firstName(),
'family_name' => $this->faker->lastName(),
'other_names' => $this->faker->boolean(30) ? $this->faker->firstName() : null,
```

### Added the `type` Field

We've added the `type` field to support Single Table Inheritance:

```php
'type' => $this->model,
```

### Added Metadata

We've added a `metadata` field with realistic preferences and profile information:

```php
'metadata' => [
    'preferences' => [
        'theme' => $this->faker->randomElement(['light', 'dark', 'system']),
        'notifications' => $this->faker->boolean(80),
        'language' => $this->faker->randomElement(['en', 'es', 'fr', 'de']),
    ],
    'profile' => [
        'bio' => $this->faker->boolean(70) ? $this->faker->paragraph() : null,
        'location' => $this->faker->boolean(60) ? $this->faker->city() : null,
        'website' => $this->faker->boolean(40) ? $this->faker->url() : null,
    ],
],
```

### Added Configuration Callbacks

We've added callbacks to ensure the `type` field is set correctly:

```php
public function configure()
{
    return $this->afterMaking(function (User $user) {
        // Ensure the type matches the model class
        if ($user->type === User::class && get_class($user) !== User::class) {
            $user->type = get_class($user);
        }
    })->afterCreating(function (User $user) {
        // Any post-creation setup can go here
    });
}
```

### Added States

We've added several states for different scenarios:

- `unverified()`: For users with unverified email addresses
- `premium()`: For users with premium subscriptions
- `withCompleteProfile()`: For users with complete profile information
- `withPreferences()`: For users with specific preferences

## Testing the Updated UserFactory

Let's create a test to ensure our updated UserFactory works correctly:

```php
<?php

namespace Tests\Unit\Factories;

use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class UserFactoryTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_creates_user_with_name_components()
    {
        $user = User::factory()->create();
        
        $this->assertNotNull($user->given_name);
        $this->assertNotNull($user->family_name);
        $this->assertNotNull($user->full_name);
    }

    #[Test]
    public function it_creates_user_with_correct_type()
    {
        $user = User::factory()->create();
        
        $this->assertEquals(User::class, $user->type);
    }

    #[Test]
    public function it_creates_user_with_metadata()
    {
        $user = User::factory()->create();
        
        $this->assertIsArray($user->metadata);
        $this->assertArrayHasKey('preferences', $user->metadata);
        $this->assertArrayHasKey('profile', $user->metadata);
    }

    #[Test]
    public function it_creates_unverified_user()
    {
        $user = User::factory()->unverified()->create();
        
        $this->assertNull($user->email_verified_at);
    }

    #[Test]
    public function it_creates_premium_user()
    {
        $user = User::factory()->premium()->create();
        
        $this->assertArrayHasKey('subscription', $user->metadata);
        $this->assertEquals('premium', $user->metadata['subscription']['plan']);
        $this->assertEquals('active', $user->metadata['subscription']['status']);
    }

    #[Test]
    public function it_creates_user_with_complete_profile()
    {
        $user = User::factory()->withCompleteProfile()->create();
        
        $this->assertArrayHasKey('profile', $user->metadata);
        $this->assertNotNull($user->metadata['profile']['bio']);
        $this->assertNotNull($user->metadata['profile']['location']);
        $this->assertNotNull($user->metadata['profile']['website']);
        $this->assertArrayHasKey('social', $user->metadata['profile']);
        $this->assertArrayHasKey('skills', $user->metadata['profile']);
    }

    #[Test]
    public function it_creates_user_with_specific_preferences()
    {
        $user = User::factory()->withPreferences('dark', false, 'fr')->create();
        
        $this->assertEquals('dark', $user->metadata['preferences']['theme']);
        $this->assertFalse($user->metadata['preferences']['notifications']);
        $this->assertEquals('fr', $user->metadata['preferences']['language']);
    }
}
```

## Using the Updated UserFactory

Here are some examples of how to use the updated UserFactory:

### Creating a Basic User

```php
$user = User::factory()->create();
```

### Creating a User with Specific Attributes

```php
$user = User::factory()->create([
    'given_name' => 'John',
    'family_name' => 'Doe',
    'email' => 'john@example.com',
]);
```

### Creating an Unverified User

```php
$user = User::factory()->unverified()->create();
```

### Creating a Premium User

```php
$user = User::factory()->premium()->create();
```

### Creating a User with a Complete Profile

```php
$user = User::factory()->withCompleteProfile()->create();
```

### Creating a User with Specific Preferences

```php
$user = User::factory()->withPreferences('dark', true, 'es')->create();
```

### Combining States

```php
$user = User::factory()
    ->unverified()
    ->premium()
    ->withCompleteProfile()
    ->create();
```

## Next Steps

Now that we've updated the UserFactory, let's move on to [Create Child Model Factories](./150-child-model-factories.md) to implement factories for our specialized user types.
