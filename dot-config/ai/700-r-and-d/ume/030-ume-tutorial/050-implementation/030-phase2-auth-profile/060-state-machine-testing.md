# Testing the Account State Machine

<link rel="stylesheet" href="../../assets/css/styles.css">

In this section, we'll learn how to thoroughly test our account state machine implementation. Testing is crucial to ensure that our state machine works correctly and that invalid transitions are properly prevented.

## Why Test State Machines?

State machines have several aspects that need testing:

1. **Initial State**: Ensure new objects start in the correct state
2. **Valid Transitions**: Verify that valid transitions work correctly
3. **Invalid Transitions**: Confirm that invalid transitions are prevented
4. **Side Effects**: Test that transitions trigger the expected side effects
5. **State-Specific Behavior**: Verify that objects behave differently based on their state

## Setting Up the Test Environment

Before writing tests, make sure your testing environment is properly configured:

```bash
# Run the migrations in the testing environment
php artisan migrate --env=testing

# Create a test database if needed
touch database/testing.sqlite
```

## Testing the Account State Machine

Let's create a comprehensive test for our account state machine:

```php
<?php

namespace Tests\Unit\States;

use App\Models\User;use App\States\User\Active;use App\States\User\Deactivated;use App\States\User\PendingValidation;use App\States\User\Suspended;use App\States\User\Transitions\VerifyEmailTransition;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;use Spatie\ModelStates\Exceptions\TransitionNotFound;

class AccountStateTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function new_users_have_pending_validation_state()
    {
        $user = User::factory()->create();
        
        $this->assertInstanceOf(PendingValidation::class, $user->account_state);
        $this->assertFalse($user->canLogin());
    }

    #[Test]
    public function users_can_transition_from_pending_to_active()
    {
        $user = User::factory()->create();
        
        $user->account_state->transition(Active::class);
        $user->save();
        
        $this->assertInstanceOf(Active::class, $user->account_state);
        $this->assertTrue($user->canLogin());
    }

    #[Test]
    public function users_can_transition_using_transition_class()
    {
        $user = User::factory()->create();
        
        $user->account_state->transition(new VerifyEmailTransition());
        $user->save();
        
        $this->assertInstanceOf(Active::class, $user->account_state);
    }

    #[Test]
    public function active_users_can_be_suspended()
    {
        $user = User::factory()->create();
        $user->account_state->transition(Active::class);
        $user->save();
        
        $user->account_state->transition(Suspended::class);
        $user->save();
        
        $this->assertInstanceOf(Suspended::class, $user->account_state);
        $this->assertFalse($user->canLogin());
    }

    #[Test]
    public function active_users_can_be_deactivated()
    {
        $user = User::factory()->create();
        $user->account_state->transition(Active::class);
        $user->save();
        
        $user->account_state->transition(Deactivated::class);
        $user->save();
        
        $this->assertInstanceOf(Deactivated::class, $user->account_state);
        $this->assertFalse($user->canLogin());
    }

    #[Test]
    public function suspended_users_can_be_reactivated()
    {
        $user = User::factory()->create();
        $user->account_state->transition(Active::class);
        $user->save();
        
        $user->account_state->transition(Suspended::class);
        $user->save();
        
        $user->account_state->transition(Active::class);
        $user->save();
        
        $this->assertInstanceOf(Active::class, $user->account_state);
        $this->assertTrue($user->canLogin());
    }

    #[Test]
    public function deactivated_users_can_be_reactivated()
    {
        $user = User::factory()->create();
        $user->account_state->transition(Active::class);
        $user->save();
        
        $user->account_state->transition(Deactivated::class);
        $user->save();
        
        $user->account_state->transition(Active::class);
        $user->save();
        
        $this->assertInstanceOf(Active::class, $user->account_state);
        $this->assertTrue($user->canLogin());
    }

    #[Test]
    public function invalid_transitions_throw_exceptions()
    {
        $this->expectException(TransitionNotFound::class);
        
        $user = User::factory()->create();
        
        // This should throw an exception because we can't go directly from PendingValidation to Suspended
        $user->account_state->transition(Suspended::class);
    }
}
```

## Testing Email Verification Integration

Let's also test the integration with email verification:

```php
<?php

namespace Tests\Feature;

use App\Models\User;use App\States\User\Active;use App\States\User\PendingValidation;use Illuminate\Auth\Events\Verified;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Support\Facades\Event;use Illuminate\Support\Facades\URL;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class EmailVerificationTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function email_verification_transitions_account_state()
    {
        Event::fake();

        $user = User::factory()->create([
            'email_verified_at' => null,
        ]);

        $this->assertInstanceOf(PendingValidation::class, $user->account_state);

        $verificationUrl = URL::temporarySignedRoute(
            'verification.verify',
            now()->addMinutes(60),
            ['id' => $user->id, 'hash' => sha1($user->email)]
        );

        $response = $this->actingAs($user)->get($verificationUrl);

        Event::assertDispatched(Verified::class);

        $user->refresh();

        $this->assertNotNull($user->email_verified_at);
        $this->assertInstanceOf(Active::class, $user->account_state);

        $response->assertRedirect(route('dashboard') . '?verified=1');
    }
}
```

## Testing the Account State Middleware

Let's test our middleware that restricts access based on account state:

```php
<?php

namespace Tests\Feature;

use App\Models\User;use App\States\User\Active;use App\States\User\Deactivated;use App\States\User\Suspended;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class AccountStateMiddlewareTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function active_users_can_access_dashboard()
    {
        $user = User::factory()->create();
        $user->account_state->transition(Active::class);
        $user->save();

        $response = $this->actingAs($user)->get(route('dashboard'));

        $response->assertStatus(200);
    }

    #[Test]
    public function suspended_users_cannot_access_dashboard()
    {
        $user = User::factory()->create();
        $user->account_state->transition(Active::class);
        $user->save();

        $user->account_state->transition(Suspended::class);
        $user->save();

        $response = $this->actingAs($user)->get(route('dashboard'));

        $response->assertViewIs('auth.suspended');
    }

    #[Test]
    public function deactivated_users_cannot_access_dashboard()
    {
        $user = User::factory()->create();
        $user->account_state->transition(Active::class);
        $user->save();

        $user->account_state->transition(Deactivated::class);
        $user->save();

        $response = $this->actingAs($user)->get(route('dashboard'));

        $response->assertViewIs('auth.deactivated');
    }
}
```

## Testing Account Actions

Finally, let's test the account actions like reactivation and deactivation:

```php
<?php

namespace Tests\Feature;

use App\Models\User;use App\States\User\Active;use App\States\User\Deactivated;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class AccountActionsTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function users_can_deactivate_their_account()
    {
        $user = User::factory()->create();
        $user->account_state->transition(Active::class);
        $user->save();

        $response = $this->actingAs($user)->post(route('account.deactivate'));

        $user->refresh();

        $this->assertInstanceOf(Deactivated::class, $user->account_state);

        $response->assertRedirect(route('login'));
        $response->assertSessionHas('status', 'account-deactivated');
    }

    #[Test]
    public function users_can_reactivate_their_account()
    {
        $user = User::factory()->create();
        $user->account_state->transition(Active::class);
        $user->save();

        $user->account_state->transition(Deactivated::class);
        $user->save();

        $response = $this->actingAs($user)->post(route('account.reactivate'));

        $user->refresh();

        $this->assertInstanceOf(Active::class, $user->account_state);

        $response->assertRedirect(route('dashboard'));
        $response->assertSessionHas('status', 'account-reactivated');
    }
}
```

## Running the Tests

To run these tests, use the following command:

```bash
php artisan test --filter=AccountStateTest,EmailVerificationTest,AccountStateMiddlewareTest,AccountActionsTest
```

## Best Practices for Testing State Machines

1. **Test Each Transition**: Write a test for each allowed transition
2. **Test Invalid Transitions**: Ensure that invalid transitions throw exceptions
3. **Test Side Effects**: Verify that transitions trigger the expected side effects
4. **Test State-Specific Behavior**: Check that objects behave differently based on their state
5. **Use PHP Attributes**: Use PHP 8 attributes (`#[Test]`) instead of PHPDoc annotations
6. **Use Descriptive Test Names**: Make test names clear and descriptive
7. **Isolate Tests**: Each test should be independent of others

## Next Steps

Now that we've thoroughly tested our state machine implementation, we can be confident that it works correctly. In the next section, we'll learn about two-factor authentication and how to implement it in our application.

Let's move on to [Understanding Two-Factor Authentication](./080-2fa.md).

## Additional Resources

- [Laravel Testing Documentation](https://laravel.com/docs/12.x/testing)
- [PHPUnit Documentation](https://phpunit.de/documentation.html)
- [Spatie Laravel Model States Testing](https://spatie.be/docs/laravel-model-states/v2/working-with-states/testing)
