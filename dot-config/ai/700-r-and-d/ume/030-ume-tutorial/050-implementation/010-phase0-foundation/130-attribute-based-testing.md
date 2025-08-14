# Attribute-Based Testing

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Implement attribute-based testing using PHP 8 attributes instead of PHPDoc annotations, providing a more type-safe and standardized approach to defining test methods and their properties.

## Overview

PHPUnit traditionally uses PHPDoc annotations to mark test methods and define their properties. PHP 8 attributes offer a more elegant and type-safe alternative, allowing us to define test methods and their properties using native language features rather than documentation conventions.

## Step 1: Understanding PHPUnit Attributes

PHPUnit 10+ supports PHP 8 attributes for defining test methods and their properties. Here are the most commonly used attributes:

```php
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Depends;
use PHPUnit\Framework\Attributes\Group;
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\CoversFunction;
use PHPUnit\Framework\Attributes\UsesClass;
```

## Step 2: Using Attributes in Tests

Let's create a test class that uses PHP 8 attributes:

```php
<?php

namespace Tests\Unit\Traits;

use App\Models\Team;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\CoversClass;use PHPUnit\Framework\Attributes\Group;use PHPUnit\Framework\Attributes\Test;

#[CoversClass(Team::class)]
#[Group('traits')]
class HasUserTrackingTraitTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    #[Group('user-tracking')]
    public function it_sets_created_by_when_creating_model()
    {
        $user = User::factory()->create();
        $this->actingAs($user);

        $team = Team::create([
            'name' => 'Test Team',
            'description' => 'A team for testing',
        ]);

        $this->assertEquals($user->id, $team->created_by);
    }

    #[Test]
    #[Group('user-tracking')]
    public function it_sets_updated_by_when_updating_model()
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        $this->actingAs($user1);

        $team = Team::create([
            'name' => 'Test Team',
            'description' => 'A team for testing',
        ]);

        $this->assertEquals($user1->id, $team->created_by);

        $this->actingAs($user2);

        $team->update([
            'name' => 'Updated Team',
        ]);

        $this->assertEquals($user2->id, $team->updated_by);
    }

    #[Test]
    #[Group('user-tracking')]
    public function it_sets_deleted_by_when_soft_deleting_model()
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        $this->actingAs($user1);

        $team = Team::create([
            'name' => 'Test Team',
            'description' => 'A team for testing',
        ]);

        $this->assertEquals($user1->id, $team->created_by);

        $this->actingAs($user2);

        $team->delete();

        $this->assertEquals($user2->id, $team->deleted_by);
    }
}
```

## Step 3: Using Data Providers with Attributes

Data providers allow you to run the same test with different sets of data. Here's how to use them with attributes:

```php
<?php

namespace Tests\Unit\Models;

use App\Models\User;use App\Models\UserType;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\DataProvider;use PHPUnit\Framework\Attributes\Test;

class UserTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    #[DataProvider('userTypesProvider')]
    public function it_creates_user_with_correct_type(string $type, string $class)
    {
        $user = User::factory()->create([
            'type' => $type,
        ]);

        $this->assertInstanceOf($class, $user);
        $this->assertEquals($type, $user->type);
    }

    public static function userTypesProvider(): array
    {
        return [
            'admin' => [UserType::ADMIN->value, \App\Models\Admin::class],
            'customer' => [UserType::CUSTOMER->value, \App\Models\Customer::class],
            'employee' => [UserType::EMPLOYEE->value, \App\Models\Employee::class],
        ];
    }
}
```

## Step 4: Using Dependency Attributes

You can use the `Depends` attribute to indicate that a test depends on another test:

```php
<?php

namespace Tests\Unit\Services;

use App\Services\PaymentService;use old\TestCase;use PHPUnit\Framework\Attributes\Depends;use PHPUnit\Framework\Attributes\Test;

class PaymentServiceTest extends TestCase
{
    private PaymentService $paymentService;

    protected function setUp(): void
    {
        parent::setUp();
        $this->paymentService = new PaymentService();
    }

    #[Test]
    public function it_creates_payment_intent()
    {
        $intent = $this->paymentService->createIntent(100, 'usd');
        $this->assertNotNull($intent->id);
        return $intent;
    }

    #[Test]
    #[Depends('it_creates_payment_intent')]
    public function it_confirms_payment_intent($intent)
    {
        $confirmed = $this->paymentService->confirmIntent($intent->id);
        $this->assertTrue($confirmed);
    }
}
```

## Step 5: Using Group Attributes

You can use the `Group` attribute to organize tests into groups:

```php
<?php

namespace Tests\Feature;

use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Group;use PHPUnit\Framework\Attributes\Test;

#[Group('auth')]
class AuthenticationTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    #[Group('login')]
    public function it_authenticates_user_with_valid_credentials()
    {
        $user = User::factory()->create([
            'email' => 'test@example.com',
            'password' => bcrypt('password'),
        ]);

        $response = $this->post('/login', [
            'email' => 'test@example.com',
            'password' => 'password',
        ]);

        $response->assertRedirect('/dashboard');
        $this->assertAuthenticatedAs($user);
    }

    #[Test]
    #[Group('login')]
    public function it_does_not_authenticate_user_with_invalid_credentials()
    {
        User::factory()->create([
            'email' => 'test@example.com',
            'password' => bcrypt('password'),
        ]);

        $response = $this->post('/login', [
            'email' => 'test@example.com',
            'password' => 'wrong-password',
        ]);

        $response->assertSessionHasErrors('email');
        $this->assertGuest();
    }
}
```

## Step 6: Using Coverage Attributes

You can use the `CoversClass` and `CoversFunction` attributes to specify which classes or functions are covered by a test:

```php
<?php

namespace Tests\Unit\Services;

use App\Models\User;use App\Services\UserService;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\CoversClass;use PHPUnit\Framework\Attributes\CoversFunction;use PHPUnit\Framework\Attributes\Test;

#[CoversClass(UserService::class)]
class UserServiceTest extends TestCase
{
    use RefreshDatabase;

    private UserService $userService;

    protected function setUp(): void
    {
        parent::setUp();
        $this->userService = new UserService();
    }

    #[Test]
    #[CoversFunction('App\Services\UserService::createUser')]
    public function it_creates_user()
    {
        $user = $this->userService->createUser([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password',
        ]);

        $this->assertInstanceOf(User::class, $user);
        $this->assertEquals('John Doe', $user->name);
        $this->assertEquals('john@example.com', $user->email);
    }
}
```

## Benefits of Attribute-Based Testing

Using attributes for testing offers several benefits:

1. **Type Safety**: Attributes are validated at compile time, catching errors early
2. **IDE Support**: Better autocompletion and validation in modern IDEs
3. **Standardization**: A consistent, language-level feature rather than a documentation convention
4. **Refactoring Support**: IDEs can refactor attributes more reliably than PHPDoc annotations
5. **Cleaner Code**: Attributes are more concise and readable than PHPDoc annotations

## PHPDoc vs. Attributes Comparison

| Feature | PHPDoc Annotation | PHP 8 Attribute |
|---------|------------------|-----------------|
| Test Method | `/** @test */` | `#[Test]` |
| Data Provider | `/** @dataProvider provider */` | `#[DataProvider('provider')]` |
| Depends | `/** @depends testMethod */` | `#[Depends('testMethod')]` |
| Group | `/** @group groupName */` | `#[Group('groupName')]` |
| Covers Class | `/** @covers \Namespace\Class */` | `#[CoversClass(Class::class)]` |
| Covers Function | `/** @covers \Namespace\Class::method */` | `#[CoversFunction('Namespace\Class::method')]` |

## Conclusion

PHP 8 attributes provide a powerful, type-safe way to define test methods and their properties. By using attributes instead of PHPDoc annotations, we create tests that are more maintainable, more type-safe, and better supported by modern development tools.

In the UME tutorial, we'll consistently use PHP 8 attributes for all our tests, ensuring a clean, modern, and type-safe testing approach.
