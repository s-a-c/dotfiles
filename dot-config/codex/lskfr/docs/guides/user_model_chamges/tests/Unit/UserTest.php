<?php

namespace Tests\Unit;

use App\Models\User;
use Tests\TestCase;

class UserTest extends TestCase
{
    public function test_family_name_is_automatically_set_when_not_provided()
    {
        // When only given_name is provided
        $user = new User();
        $user->given_name = 'John';
        $user->email = 'john@example.com';
        $user->password = 'password';
        $user->save();

        $this->assertNotNull($user->family_name);
        $this->assertEquals('John', $user->family_name); // family_name should be set to given_name

        // When neither given_name nor family_name is provided
        $user = new User();
        $user->email = 'anonymous@example.com';
        $user->password = 'password';
        $user->save();

        $this->assertNotNull($user->family_name);
        $this->assertStringContainsString('User', $user->family_name); // Should contain 'User' and possibly the ID
    }

    public function test_name_is_split_correctly_when_saving()
    {
        $user = new User();
        $user->name = 'John Doe';
        $user->email = 'john@example.com';
        $user->password = 'password';
        $user->save();

        $this->assertEquals('John', $user->given_name);
        $this->assertEquals('Doe', $user->family_name);
        $this->assertEquals('John Doe', $user->name);
    }

    public function test_single_word_name_is_assigned_to_family_name()
    {
        $user = new User();
        $user->name = 'Cher';
        $user->email = 'cher@example.com';
        $user->password = 'password';
        $user->save();

        $this->assertNull($user->given_name);
        $this->assertEquals('Cher', $user->family_name);
        $this->assertEquals('Cher', $user->name);
    }

    public function test_multi_part_name_splits_first_part_and_remainder()
    {
        $user = new User();
        $user->name = 'John James Smith Jr.';
        $user->email = 'john.smith@example.com';
        $user->password = 'password';
        $user->save();

        $this->assertEquals('John', $user->given_name);
        $this->assertEquals('James Smith Jr.', $user->family_name);
        $this->assertEquals('John James Smith Jr.', $user->name);
    }

    public function test_initials_are_generated_correctly()
    {
        $user = new User();

        // Single word name
        $user->name = 'Madonna';
        $this->assertEquals('M', $user->getInitials());

        // Two word name
        $user->name = 'John Doe';
        $this->assertEquals('JD', $user->getInitials());

        // Multi-part name
        $user->name = 'John James Smith Jr.';
        $this->assertEquals('JjsJ', $user->getInitials());

        // Only first and last initials are capitalized
        $user->name = 'John van der Waals';
        $this->assertEquals('JvdW', $user->getInitials());
    }

    public function test_name_is_generated_from_given_and_family_name()
    {
        $user = new User();

        // Both given_name and family_name
        $user->given_name = 'John';
        $user->family_name = 'Doe';
        $this->assertEquals('John Doe', $user->name);

        // Only given_name - family_name will be set automatically in the saving event
        // This is a direct test of the getter method
        $user->given_name = 'Madonna';
        $user->family_name = '';
        $this->assertEquals('Madonna', $user->name);

        // Only family_name
        $user->given_name = null;
        $user->family_name = 'Cher';
        $this->assertEquals('Cher', $user->name);

        // Neither given_name nor family_name
        $user->given_name = null;
        $user->family_name = null;
        $user->attributes['name'] = 'Legacy Name';
        $this->assertEquals('Legacy Name', $user->name);
    }
}
