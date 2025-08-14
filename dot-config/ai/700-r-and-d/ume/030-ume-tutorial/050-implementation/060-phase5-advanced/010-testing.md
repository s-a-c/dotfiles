# Testing User Model Enhancements

This document covers comprehensive testing strategies for the User Model Enhancements (UME) features implemented in the previous phases. Testing is a critical part of ensuring that our implementation works correctly and continues to work as expected when changes are made.

## Testing Approach

Our testing approach includes:

1. **Unit Tests**: Testing individual components in isolation
2. **Feature Tests**: Testing how components work together
3. **Integration Tests**: Testing the integration with Laravel's authentication system
4. **Browser Tests**: Testing the UI components with Laravel Dusk

## Unit Tests

### Testing the UserType Enum

```php
<?php

namespace Tests\Unit;

use App\Enums\UserType;
use App\Models\Admin;
use App\Models\Manager;
use App\Models\Practitioner;
use App\Models\User;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;

class UserTypeTest extends TestCase
{
    #[Test]
    public function it_returns_correct_labels()
    {
        $this->assertEquals('User', UserType::USER->label());
        $this->assertEquals('Administrator', UserType::ADMIN->label());
        $this->assertEquals('Manager', UserType::MANAGER->label());
        $this->assertEquals('Practitioner', UserType::PRACTITIONER->label());
    }

    #[Test]
    public function it_returns_correct_colors()
    {
        $this->assertEquals('blue', UserType::USER->color());
        $this->assertEquals('red', UserType::ADMIN->color());
        $this->assertEquals('amber', UserType::MANAGER->color());
        $this->assertEquals('emerald', UserType::PRACTITIONER->color());
    }

    #[Test]
    public function it_converts_between_class_and_enum()
    {
        $this->assertEquals(UserType::USER, UserType::fromClass(User::class));
        $this->assertEquals(UserType::ADMIN, UserType::fromClass(Admin::class));
        $this->assertEquals(UserType::MANAGER, UserType::fromClass(Manager::class));
        $this->assertEquals(UserType::PRACTITIONER, UserType::fromClass(Practitioner::class));
    }

    #[Test]
    public function it_validates_class_names()
    {
        $this->assertTrue(UserType::isValid(User::class));
        $this->assertTrue(UserType::isValid(Admin::class));
        $this->assertFalse(UserType::isValid('App\\Models\\InvalidClass'));
        $this->assertFalse(UserType::isValid(''));
    }
}
```

### Testing the HasAdditionalFeatures Trait

```php
<?php

namespace Tests\Unit;

use App\Enums\UserFlag;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class HasAdditionalFeaturesTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_can_set_and_get_flags()
    {
        $user = User::factory()->create();
        
        // Test setting a flag
        $user->setFlag(UserFlag::VERIFIED);
        $this->assertTrue($user->hasFlag(UserFlag::VERIFIED));
        
        // Test setting multiple flags
        $user->setFlag(UserFlag::FEATURED);
        $this->assertTrue($user->hasFlag(UserFlag::VERIFIED));
        $this->assertTrue($user->hasFlag(UserFlag::FEATURED));
        
        // Test removing a flag
        $user->unsetFlag(UserFlag::VERIFIED);
        $this->assertFalse($user->hasFlag(UserFlag::VERIFIED));
        $this->assertTrue($user->hasFlag(UserFlag::FEATURED));
    }

    #[Test]
    public function it_persists_flags_to_database()
    {
        $user = User::factory()->create();
        $user->setFlag(UserFlag::VERIFIED);
        $user->save();
        
        // Reload from database
        $freshUser = User::find($user->id);
        $this->assertTrue($freshUser->hasFlag(UserFlag::VERIFIED));
    }
}
```

## Feature Tests

### Testing User Type Management

```php
<?php

namespace Tests\Feature;

use App\Models\Admin;use App\Models\Manager;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class UserTypeManagementTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function admin_can_change_user_type()
    {
        // Create an admin user
        $admin = Admin::factory()->create();
        $admin->assignRole('admin');
        $admin->givePermissionTo('change user types');
        
        // Create a regular user
        $user = User::factory()->create();
        
        // Admin changes user to manager
        $this->actingAs($admin);
        $response = $this->post(route('users.change-type', $user), [
            'new_type' => Manager::class
        ]);
        
        $response->assertRedirect();
        $response->assertSessionHas('success');
        
        // Verify the user type was changed
        $user->refresh();
        $this->assertEquals(Manager::class, $user->type);
    }

    #[Test]
    public function regular_user_cannot_change_user_type()
    {
        // Create two regular users
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        
        // User1 tries to change User2's type
        $this->actingAs($user1);
        $response = $this->post(route('users.change-type', $user2), [
            'new_type' => Manager::class
        ]);
        
        $response->assertStatus(403); // Forbidden
        
        // Verify the user type was not changed
        $user2->refresh();
        $this->assertEquals(User::class, $user2->type);
    }
}
```

## Integration Tests

### Testing Authentication with Different User Types

```php
<?php

namespace Tests\Feature;

use App\Models\Admin;use App\Models\Manager;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class AuthenticationTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function different_user_types_can_login()
    {
        // Test regular user login
        $user = User::factory()->create([
            'email' => 'user@example.com',
            'password' => bcrypt('password'),
        ]);
        
        $response = $this->post('/login', [
            'email' => 'user@example.com',
            'password' => 'password',
        ]);
        
        $response->assertRedirect('/dashboard');
        $this->assertAuthenticatedAs($user);
        
        // Logout
        $this->post('/logout');
        
        // Test admin login
        $admin = Admin::factory()->create([
            'email' => 'admin@example.com',
            'password' => bcrypt('password'),
        ]);
        
        $response = $this->post('/login', [
            'email' => 'admin@example.com',
            'password' => 'password',
        ]);
        
        $response->assertRedirect('/admin/dashboard');
        $this->assertAuthenticatedAs($admin);
    }

    #[Test]
    public function user_types_have_correct_permissions()
    {
        // Create users of different types
        $user = User::factory()->create();
        $manager = Manager::factory()->create();
        $admin = Admin::factory()->create();
        
        // Assign default roles
        $user->assignRole('user');
        $manager->assignRole('manager');
        $admin->assignRole('admin');
        
        // Test user permissions
        $this->actingAs($user);
        $response = $this->get('/admin/users');
        $response->assertStatus(403); // Forbidden
        
        // Test manager permissions
        $this->actingAs($manager);
        $response = $this->get('/teams');
        $response->assertStatus(200); // Allowed
        $response = $this->get('/admin/settings');
        $response->assertStatus(403); // Forbidden
        
        // Test admin permissions
        $this->actingAs($admin);
        $response = $this->get('/admin/users');
        $response->assertStatus(200); // Allowed
        $response = $this->get('/admin/settings');
        $response->assertStatus(200); // Allowed
    }
}
```

## Browser Tests with Laravel Dusk

### Testing UI Components

```php
<?php

namespace Tests\Browser;

use App\Models\Admin;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseMigrations;
use Laravel\Dusk\Browser;
use PHPUnit\Framework\Attributes\Test;
use Tests\DuskTestCase;

class UserTypeUITest extends DuskTestCase
{
    use DatabaseMigrations;

    #[Test]
    public function admin_can_change_user_type_through_ui()
    {
        // Create an admin user
        $admin = Admin::factory()->create([
            'email' => 'admin@example.com',
            'password' => bcrypt('password'),
        ]);
        $admin->assignRole('admin');
        $admin->givePermissionTo('change user types');
        
        // Create a regular user
        $user = User::factory()->create();
        
        $this->browse(function (Browser $browser) use ($admin, $user) {
            $browser->loginAs($admin)
                    ->visit('/admin/users/' . $user->id . '/edit')
                    ->select('newType', 'App\\Models\\Manager')
                    ->click('@change-type-button')
                    ->waitForText('Confirm Type Change')
                    ->click('@confirm-change-button')
                    ->waitForText('User type changed to Manager successfully!')
                    ->assertSee('Manager');
        });
        
        // Verify the user type was changed in the database
        $user->refresh();
        $this->assertEquals('App\\Models\\Manager', $user->type);
    }

    #[Test]
    public function user_type_badges_display_correctly()
    {
        // Create users of different types
        $user = User::factory()->create();
        $admin = Admin::factory()->create();
        
        $this->browse(function (Browser $browser) use ($user, $admin) {
            $browser->loginAs($admin)
                    ->visit('/admin/users')
                    ->assertSeeIn('@user-' . $user->id . '-badge', 'User')
                    ->assertSeeIn('@user-' . $admin->id . '-badge', 'Administrator');
        });
    }
}
```

## Test Coverage

To ensure comprehensive test coverage, we should aim to test:

1. All methods in the UserType enum
2. All traits (HasUlid, HasUserTracking, HasAdditionalFeatures)
3. All user type models (User, Admin, Manager, Practitioner)
4. All UI components related to user types
5. All permission-based access controls
6. Edge cases and error handling

## Continuous Integration

Set up GitHub Actions to run tests automatically on every push and pull request:

```yaml
name: Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  tests:
    runs-on: ubuntu-latest
    
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: password
          MYSQL_DATABASE: testing
        ports:
          - 3306:3306
        options: --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=3
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup PHP
      uses: shivammathur/setup-php@v2
      with:
        php-version: '8.2'
        extensions: mbstring, dom, fileinfo, mysql
        coverage: xdebug
    
    - name: Copy .env
      run: cp .env.example .env.testing
    
    - name: Install Composer dependencies
      run: composer install --prefer-dist --no-interaction
    
    - name: Generate key
      run: php artisan key:generate --env=testing
    
    - name: Run migrations
      run: php artisan migrate --env=testing
    
    - name: Run PHPUnit tests
      run: vendor/bin/phpunit --coverage-html coverage
    
    - name: Upload coverage reports
      uses: actions/upload-artifact@v3
      with:
        name: coverage-report
        path: coverage
```

## Conclusion

A comprehensive testing strategy ensures that our User Model Enhancements implementation is robust and maintainable. By combining unit tests, feature tests, integration tests, and browser tests, we can have confidence that our code works as expected and will continue to work as the application evolves.

## Exercise

Extend the testing suite with the following:

1. Create tests for the HasUlid trait to ensure ULIDs are generated correctly
2. Write tests for the HasUserTracking trait to verify created_by, updated_by, and deleted_by are tracked correctly
3. Implement tests for the Blade directives (@userType, @admin, etc.)
4. Create tests for the user type statistics dashboard component
