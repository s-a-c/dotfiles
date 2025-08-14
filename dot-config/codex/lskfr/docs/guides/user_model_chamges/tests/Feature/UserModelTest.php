<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class UserModelTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_be_created_with_given_and_family_name(): void
    {
        $user = User::factory()->create([
            'given_name' => 'John',
            'family_name' => 'Doe',
        ]);

        $this->assertEquals('John', $user->given_name);
        $this->assertEquals('Doe', $user->family_name);
        $this->assertEquals('John Doe', $user->name);
    }

    public function test_user_name_is_computed_from_given_and_family_name(): void
    {
        $user = User::factory()->create([
            'given_name' => 'Jane',
            'family_name' => 'Smith',
        ]);

        $this->assertEquals('Jane Smith', $user->name);

        // Update given_name
        $user->given_name = 'Janet';
        $user->save();

        $this->assertEquals('Janet Smith', $user->fresh()->name);
    }

    public function test_user_has_slug_generated_from_name(): void
    {
        $user = User::factory()->create([
            'given_name' => 'Alice',
            'family_name' => 'Johnson',
        ]);

        $this->assertEquals('alice-johnson', $user->slug);
    }

    public function test_user_has_ulid_generated(): void
    {
        $user = User::factory()->create();

        $this->assertNotNull($user->ulid);
        $this->assertEquals(26, strlen($user->ulid));
    }

    public function test_user_can_be_found_by_ulid(): void
    {
        $user = User::factory()->create();
        $foundUser = User::where('ulid', $user->ulid)->first();

        $this->assertEquals($user->id, $foundUser->id);
    }

    public function test_registration_works_with_given_and_family_name(): void
    {
        $response = $this->post('/register', [
            'given_name' => 'New',
            'family_name' => 'User',
            'email' => 'newuser@example.com',
            'password' => 'password',
            'password_confirmation' => 'password',
        ]);

        $this->assertAuthenticated();
        $user = User::where('email', 'newuser@example.com')->first();
        $this->assertEquals('New', $user->given_name);
        $this->assertEquals('User', $user->family_name);
        $this->assertEquals('New User', $user->name);
    }

    public function test_profile_update_works_with_given_and_family_name(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user);

        $response = $this->patch('/settings/profile', [
            'given_name' => 'Updated',
            'family_name' => 'Name',
            'email' => $user->email,
        ]);

        $response->assertSessionHasNoErrors();
        $this->assertEquals('Updated', $user->fresh()->given_name);
        $this->assertEquals('Name', $user->fresh()->family_name);
        $this->assertEquals('Updated Name', $user->fresh()->name);
    }
}
