# Testing in Phase 2: Auth & Profile

This document outlines the testing approach for the Auth & Profile phase of the UME tutorial. Comprehensive testing is essential to ensure that our authentication, user profiles, state machines, and avatar management are working correctly.

## Testing Strategy

For the Auth & Profile phase, we'll focus on:

1. **Authentication Tests**: Ensure that authentication works correctly for all user types
2. **Profile Tests**: Verify that user profiles can be created, updated, and retrieved
3. **State Machine Tests**: Test the account status state machine
4. **Avatar Tests**: Verify that avatar uploads and management work correctly
5. **Integration Tests**: Test how these components work together

## Authentication Tests

```php
<?php

namespace Tests\Feature\Auth;

use App\Models\Admin;use App\Models\Manager;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class AuthenticationTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function user_can_login_with_correct_credentials()
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
    public function admin_can_login_with_correct_credentials()
    {
        $admin = Admin::factory()->create([
            'email' => 'admin@example.com',
            'password' => bcrypt('password'),
        ]);
        
        $response = $this->post('/login', [
            'email' => 'admin@example.com',
            'password' => 'password',
        ]);
        
        $response->assertRedirect('/dashboard');
        $this->assertAuthenticatedAs($admin);
    }

    #[Test]
    public function user_cannot_login_with_incorrect_credentials()
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

    #[Test]
    public function user_can_logout()
    {
        $user = User::factory()->create();
        
        $response = $this->actingAs($user)->post('/logout');
        
        $response->assertRedirect('/');
        $this->assertGuest();
    }

    #[Test]
    public function user_can_register()
    {
        $response = $this->post('/register', [
            'given_name' => 'John',
            'family_name' => 'Doe',
            'email' => 'john@example.com',
            'password' => 'password',
            'password_confirmation' => 'password',
        ]);
        
        $response->assertRedirect('/dashboard');
        $this->assertAuthenticated();
        $this->assertDatabaseHas('users', [
            'given_name' => 'John',
            'family_name' => 'Doe',
            'email' => 'john@example.com',
        ]);
    }

    #[Test]
    public function user_cannot_register_with_existing_email()
    {
        User::factory()->create([
            'email' => 'test@example.com',
        ]);
        
        $response = $this->post('/register', [
            'given_name' => 'John',
            'family_name' => 'Doe',
            'email' => 'test@example.com',
            'password' => 'password',
            'password_confirmation' => 'password',
        ]);
        
        $response->assertSessionHasErrors('email');
        $this->assertGuest();
    }

    #[Test]
    public function user_can_request_password_reset()
    {
        User::factory()->create([
            'email' => 'test@example.com',
        ]);
        
        $response = $this->post('/forgot-password', [
            'email' => 'test@example.com',
        ]);
        
        $response->assertSessionHas('status');
        $this->assertGuest();
    }

    #[Test]
    public function different_user_types_can_access_appropriate_routes()
    {
        $user = User::factory()->create();
        $admin = Admin::factory()->create();
        $manager = Manager::factory()->create();
        
        // Regular user can access dashboard
        $this->actingAs($user)->get('/dashboard')->assertStatus(200);
        
        // Admin can access admin dashboard
        $this->actingAs($admin)->get('/admin/dashboard')->assertStatus(200);
        
        // Regular user cannot access admin dashboard
        $this->actingAs($user)->get('/admin/dashboard')->assertStatus(403);
        
        // Manager can access team management
        $this->actingAs($manager)->get('/teams')->assertStatus(200);
        
        // Regular user cannot access team management
        $this->actingAs($user)->get('/teams')->assertStatus(403);
    }
}
```

## Profile Tests

```php
<?php

namespace Tests\Feature\Profile;

use App\Models\Profile;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class ProfileTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function user_can_view_profile()
    {
        $user = User::factory()->create();
        
        $response = $this->actingAs($user)->get('/profile');
        
        $response->assertStatus(200);
        $response->assertSee($user->full_name);
        $response->assertSee($user->email);
    }

    #[Test]
    public function user_can_update_profile()
    {
        $user = User::factory()->create();
        
        $response = $this->actingAs($user)->put('/profile', [
            'given_name' => 'Updated',
            'family_name' => 'Name',
            'email' => 'updated@example.com',
        ]);
        
        $response->assertRedirect('/profile');
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'given_name' => 'Updated',
            'family_name' => 'Name',
            'email' => 'updated@example.com',
        ]);
    }

    #[Test]
    public function user_can_update_password()
    {
        $user = User::factory()->create([
            'password' => bcrypt('old-password'),
        ]);
        
        $response = $this->actingAs($user)->put('/user/password', [
            'current_password' => 'old-password',
            'password' => 'new-password',
            'password_confirmation' => 'new-password',
        ]);
        
        $response->assertSessionHasNoErrors();
        
        // Attempt to login with new password
        $this->post('/logout');
        $loginResponse = $this->post('/login', [
            'email' => $user->email,
            'password' => 'new-password',
        ]);
        
        $loginResponse->assertRedirect('/dashboard');
        $this->assertAuthenticatedAs($user);
    }

    #[Test]
    public function user_cannot_update_password_with_incorrect_current_password()
    {
        $user = User::factory()->create([
            'password' => bcrypt('correct-password'),
        ]);
        
        $response = $this->actingAs($user)->put('/user/password', [
            'current_password' => 'wrong-password',
            'password' => 'new-password',
            'password_confirmation' => 'new-password',
        ]);
        
        $response->assertSessionHasErrors('current_password');
    }

    #[Test]
    public function user_can_create_profile_with_additional_information()
    {
        $user = User::factory()->create();
        
        $response = $this->actingAs($user)->post('/profile/additional', [
            'bio' => 'This is my bio',
            'location' => 'New York',
            'website' => 'https://example.com',
            'birthday' => '1990-01-01',
        ]);
        
        $response->assertRedirect('/profile');
        $this->assertDatabaseHas('profiles', [
            'user_id' => $user->id,
            'bio' => 'This is my bio',
            'location' => 'New York',
            'website' => 'https://example.com',
            'birthday' => '1990-01-01',
        ]);
    }

    #[Test]
    public function user_can_update_profile_additional_information()
    {
        $user = User::factory()->create();
        $profile = Profile::factory()->create([
            'user_id' => $user->id,
            'bio' => 'Old bio',
            'location' => 'Old location',
        ]);
        
        $response = $this->actingAs($user)->put('/profile/additional', [
            'bio' => 'Updated bio',
            'location' => 'Updated location',
            'website' => 'https://updated.com',
        ]);
        
        $response->assertRedirect('/profile');
        $this->assertDatabaseHas('profiles', [
            'id' => $profile->id,
            'user_id' => $user->id,
            'bio' => 'Updated bio',
            'location' => 'Updated location',
            'website' => 'https://updated.com',
        ]);
    }

    #[Test]
    public function user_can_delete_profile_additional_information()
    {
        $user = User::factory()->create();
        $profile = Profile::factory()->create([
            'user_id' => $user->id,
        ]);
        
        $response = $this->actingAs($user)->delete('/profile/additional');
        
        $response->assertRedirect('/profile');
        $this->assertDatabaseMissing('profiles', [
            'id' => $profile->id,
        ]);
    }
}
```

## State Machine Tests

```php
<?php

namespace Tests\Unit\States;

use App\Models\User;use App\States\Account\AccountState;use App\States\Account\Active;use App\States\Account\Inactive;use App\States\Account\Suspended;use App\States\Account\Transitions\ActivateAccount;use App\States\Account\Transitions\DeactivateAccount;use App\States\Account\Transitions\SuspendAccount;use App\States\Account\Transitions\UnsuspendAccount;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class AccountStateTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function user_has_default_account_state()
    {
        $user = User::factory()->create();
        
        $this->assertInstanceOf(AccountState::class, $user->accountState);
        $this->assertInstanceOf(Active::class, $user->accountState);
    }

    #[Test]
    public function user_can_transition_from_active_to_inactive()
    {
        $user = User::factory()->create();
        
        $user->accountState->transition(new DeactivateAccount($user));
        
        $this->assertInstanceOf(Inactive::class, $user->accountState);
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'account_state' => Inactive::class,
        ]);
    }

    #[Test]
    public function user_can_transition_from_inactive_to_active()
    {
        $user = User::factory()->create([
            'account_state' => Inactive::class,
        ]);
        
        $user->accountState->transition(new ActivateAccount($user));
        
        $this->assertInstanceOf(Active::class, $user->accountState);
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'account_state' => Active::class,
        ]);
    }

    #[Test]
    public function user_can_transition_from_active_to_suspended()
    {
        $user = User::factory()->create();
        
        $user->accountState->transition(new SuspendAccount($user, 'Violation of terms'));
        
        $this->assertInstanceOf(Suspended::class, $user->accountState);
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'account_state' => Suspended::class,
        ]);
    }

    #[Test]
    public function user_can_transition_from_suspended_to_active()
    {
        $user = User::factory()->create([
            'account_state' => Suspended::class,
        ]);
        
        $user->accountState->transition(new UnsuspendAccount($user));
        
        $this->assertInstanceOf(Active::class, $user->accountState);
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'account_state' => Active::class,
        ]);
    }

    #[Test]
    public function invalid_transition_throws_exception()
    {
        $user = User::factory()->create([
            'account_state' => Inactive::class,
        ]);
        
        $this->expectException(\Spatie\ModelStates\Exceptions\TransitionNotFound::class);
        
        $user->accountState->transition(new SuspendAccount($user, 'Violation of terms'));
    }

    #[Test]
    public function suspended_user_cannot_login()
    {
        $user = User::factory()->create([
            'email' => 'suspended@example.com',
            'password' => bcrypt('password'),
            'account_state' => Suspended::class,
        ]);
        
        $response = $this->post('/login', [
            'email' => 'suspended@example.com',
            'password' => 'password',
        ]);
        
        $response->assertSessionHasErrors('email');
        $this->assertGuest();
    }

    #[Test]
    public function inactive_user_cannot_login()
    {
        $user = User::factory()->create([
            'email' => 'inactive@example.com',
            'password' => bcrypt('password'),
            'account_state' => Inactive::class,
        ]);
        
        $response = $this->post('/login', [
            'email' => 'inactive@example.com',
            'password' => 'password',
        ]);
        
        $response->assertSessionHasErrors('email');
        $this->assertGuest();
    }

    #[Test]
    public function state_transitions_are_logged()
    {
        $user = User::factory()->create();
        
        $user->accountState->transition(new DeactivateAccount($user));
        
        $this->assertDatabaseHas('activity_log', [
            'subject_type' => User::class,
            'subject_id' => $user->id,
            'description' => 'Account deactivated',
        ]);
    }
}
```

## Avatar Tests

```php
<?php

namespace Tests\Feature\Profile;

use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Http\UploadedFile;use Illuminate\Support\Facades\Storage;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class AvatarTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
    }

    #[Test]
    public function user_can_upload_avatar()
    {
        $user = User::factory()->create();
        
        $file = UploadedFile::fake()->image('avatar.jpg');
        
        $response = $this->actingAs($user)->post('/profile/avatar', [
            'avatar' => $file,
        ]);
        
        $response->assertRedirect('/profile');
        
        // Check that the file was stored
        Storage::disk('public')->assertExists('avatars/' . $file->hashName());
        
        // Check that the user has the avatar
        $this->assertNotNull($user->fresh()->getFirstMedia('avatars'));
    }

    #[Test]
    public function user_can_update_avatar()
    {
        $user = User::factory()->create();
        
        // Upload initial avatar
        $file1 = UploadedFile::fake()->image('avatar1.jpg');
        $this->actingAs($user)->post('/profile/avatar', [
            'avatar' => $file1,
        ]);
        
        // Get the initial avatar path
        $initialAvatar = $user->fresh()->getFirstMedia('avatars');
        
        // Upload new avatar
        $file2 = UploadedFile::fake()->image('avatar2.jpg');
        $response = $this->actingAs($user)->post('/profile/avatar', [
            'avatar' => $file2,
        ]);
        
        $response->assertRedirect('/profile');
        
        // Check that the new file was stored
        Storage::disk('public')->assertExists('avatars/' . $file2->hashName());
        
        // Check that the user has only one avatar
        $this->assertCount(1, $user->fresh()->getMedia('avatars'));
        
        // Check that the avatar was updated
        $newAvatar = $user->fresh()->getFirstMedia('avatars');
        $this->assertNotEquals($initialAvatar->id, $newAvatar->id);
    }

    #[Test]
    public function user_can_delete_avatar()
    {
        $user = User::factory()->create();
        
        // Upload avatar
        $file = UploadedFile::fake()->image('avatar.jpg');
        $this->actingAs($user)->post('/profile/avatar', [
            'avatar' => $file,
        ]);
        
        // Delete avatar
        $response = $this->actingAs($user)->delete('/profile/avatar');
        
        $response->assertRedirect('/profile');
        
        // Check that the user has no avatar
        $this->assertCount(0, $user->fresh()->getMedia('avatars'));
    }

    #[Test]
    public function avatar_must_be_an_image()
    {
        $user = User::factory()->create();
        
        $file = UploadedFile::fake()->create('document.pdf');
        
        $response = $this->actingAs($user)->post('/profile/avatar', [
            'avatar' => $file,
        ]);
        
        $response->assertSessionHasErrors('avatar');
        
        // Check that no file was stored
        Storage::disk('public')->assertMissing('avatars/' . $file->hashName());
    }

    #[Test]
    public function avatar_must_not_exceed_maximum_size()
    {
        $user = User::factory()->create();
        
        $file = UploadedFile::fake()->image('avatar.jpg')->size(2049); // 2MB + 1KB
        
        $response = $this->actingAs($user)->post('/profile/avatar', [
            'avatar' => $file,
        ]);
        
        $response->assertSessionHasErrors('avatar');
        
        // Check that no file was stored
        Storage::disk('public')->assertMissing('avatars/' . $file->hashName());
    }

    #[Test]
    public function avatar_is_converted_to_correct_formats()
    {
        $user = User::factory()->create();
        
        $file = UploadedFile::fake()->image('avatar.jpg');
        
        $this->actingAs($user)->post('/profile/avatar', [
            'avatar' => $file,
        ]);
        
        $media = $user->fresh()->getFirstMedia('avatars');
        
        // Check that conversions were generated
        $this->assertTrue($media->hasGeneratedConversion('thumb'));
        $this->assertTrue($media->hasGeneratedConversion('medium'));
        
        // Check that conversion files exist
        Storage::disk('public')->assertExists($media->getPath('thumb'));
        Storage::disk('public')->assertExists($media->getPath('medium'));
    }
}
```

## Integration Tests

```php
<?php

namespace Tests\Feature;

use App\Models\User;use App\States\Account\Active;use App\States\Account\Inactive;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Http\UploadedFile;use Illuminate\Support\Facades\Storage;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class AuthProfileIntegrationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
    }

    #[Test]
    public function complete_user_registration_and_profile_setup_flow()
    {
        // Step 1: Register a new user
        $response = $this->post('/register', [
            'given_name' => 'John',
            'family_name' => 'Doe',
            'email' => 'john@example.com',
            'password' => 'password',
            'password_confirmation' => 'password',
        ]);
        
        $response->assertRedirect('/dashboard');
        $this->assertAuthenticated();
        
        $user = User::where('email', 'john@example.com')->first();
        $this->assertNotNull($user);
        
        // Step 2: Verify email
        $this->actingAs($user)->get('/email/verify');
        $user->markEmailAsVerified();
        
        // Step 3: Update profile
        $this->actingAs($user)->put('/profile', [
            'given_name' => 'Johnny',
            'family_name' => 'Doe',
            'other_names' => 'Smith',
        ]);
        
        $user->refresh();
        $this->assertEquals('Johnny', $user->given_name);
        $this->assertEquals('Smith', $user->other_names);
        
        // Step 4: Add additional profile information
        $this->actingAs($user)->post('/profile/additional', [
            'bio' => 'This is my bio',
            'location' => 'New York',
            'website' => 'https://example.com',
        ]);
        
        $this->assertDatabaseHas('profiles', [
            'user_id' => $user->id,
            'bio' => 'This is my bio',
        ]);
        
        // Step 5: Upload avatar
        $file = UploadedFile::fake()->image('avatar.jpg');
        $this->actingAs($user)->post('/profile/avatar', [
            'avatar' => $file,
        ]);
        
        $this->assertNotNull($user->fresh()->getFirstMedia('avatars'));
        
        // Step 6: Logout
        $this->actingAs($user)->post('/logout');
        $this->assertGuest();
        
        // Step 7: Login again
        $this->post('/login', [
            'email' => 'john@example.com',
            'password' => 'password',
        ]);
        
        $this->assertAuthenticatedAs($user);
    }

    #[Test]
    public function account_state_affects_authentication_and_access()
    {
        // Create a user
        $user = User::factory()->create([
            'email' => 'test@example.com',
            'password' => bcrypt('password'),
        ]);
        
        // Verify user can login with active state
        $this->post('/login', [
            'email' => 'test@example.com',
            'password' => 'password',
        ]);
        
        $this->assertAuthenticatedAs($user);
        $this->post('/logout');
        
        // Deactivate account
        $user->accountState = new Inactive($user);
        $user->save();
        
        // Verify user cannot login with inactive state
        $this->post('/login', [
            'email' => 'test@example.com',
            'password' => 'password',
        ]);
        
        $this->assertGuest();
        
        // Reactivate account
        $user->accountState = new Active($user);
        $user->save();
        
        // Verify user can login again
        $this->post('/login', [
            'email' => 'test@example.com',
            'password' => 'password',
        ]);
        
        $this->assertAuthenticatedAs($user);
    }

    #[Test]
    public function profile_and_avatar_are_displayed_correctly()
    {
        $user = User::factory()->create();
        
        // Add profile information
        $this->actingAs($user)->post('/profile/additional', [
            'bio' => 'This is my bio',
            'location' => 'New York',
        ]);
        
        // Upload avatar
        $file = UploadedFile::fake()->image('avatar.jpg');
        $this->actingAs($user)->post('/profile/avatar', [
            'avatar' => $file,
        ]);
        
        // Visit profile page
        $response = $this->actingAs($user)->get('/profile');
        
        // Check that profile information is displayed
        $response->assertSee($user->full_name);
        $response->assertSee('This is my bio');
        $response->assertSee('New York');
        
        // Check that avatar is displayed
        $avatarUrl = $user->fresh()->getFirstMediaUrl('avatars');
        $response->assertSee($avatarUrl);
    }

    #[Test]
    public function email_verification_affects_account_access()
    {
        // Create user with unverified email
        $user = User::factory()->create([
            'email_verified_at' => null,
        ]);
        
        // Login
        $this->actingAs($user);
        
        // Try to access protected route
        $response = $this->get('/dashboard');
        
        // Should be redirected to email verification notice
        $response->assertRedirect('/email/verify');
        
        // Verify email
        $user->markEmailAsVerified();
        
        // Try to access protected route again
        $response = $this->get('/dashboard');
        
        // Should be able to access now
        $response->assertStatus(200);
    }
}
```

## Running the Tests

To run the tests for the Auth & Profile phase, use the following command:

```bash
php artisan test --filter=AuthenticationTest,ProfileTest,AccountStateTest,AvatarTest,AuthProfileIntegrationTest
```

Or run all tests with:

```bash
php artisan test
```

## Test Coverage

To ensure comprehensive test coverage for the Auth & Profile phase, make sure your tests cover:

1. All authentication flows (login, logout, registration, password reset)
2. Profile creation, updating, and deletion
3. Account state transitions and their effects on authentication
4. Avatar upload, update, and deletion
5. Integration between these components

## Best Practices

1. **Use PHP Attributes**: Always use PHP 8 attributes (`#[Test]`) instead of PHPDoc annotations (`/** @test */`).
2. **Test Authentication Flows**: Verify that users can register, login, and logout.
3. **Test Profile Management**: Ensure that users can create, update, and delete their profiles.
4. **Test State Machines**: Verify that account states transition correctly and affect authentication.
5. **Test File Uploads**: Ensure that avatar uploads work correctly and generate the required conversions.
6. **Test Integration**: Verify that these components work together correctly.
7. **Use Fake Storage**: Use Storage::fake() to test file uploads without affecting the real filesystem.

By following these guidelines, you'll ensure that your Auth & Profile phase is thoroughly tested and ready for the next phases of the UME tutorial.
