# Testing in Phase 1: Core Models

<link rel="stylesheet" href="../../assets/css/styles.css">

**Note:** For detailed test implementations, see the [tests directory](./360-tests/000-index.md).

This document outlines the testing approach for the Core Models phase of the UME tutorial. Comprehensive testing is essential to ensure that our Single Table Inheritance (STI) implementation, traits, and migrations are working correctly.

## Testing Strategy

For the Core Models phase, we'll focus on:

1. **Model Tests**: Ensure that our models are correctly implemented
2. **Trait Tests**: Verify that our traits work as expected
3. **Migration Tests**: Ensure that our database schema is correctly set up
4. **Factory Tests**: Verify that our model factories work correctly
5. **Integration Tests**: Test how models work together

## Model Tests

### Base User Model Test

```php
<?php

namespace Tests\Unit\Models;

use App\Enums\UserType;use App\Models\Admin;use App\Models\Manager;use App\Models\Practitioner;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class UserModelTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_has_correct_type_column()
    {
        $user = User::factory()->create();

        $this->assertEquals(User::class, $user->type);
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'type' => User::class,
        ]);
    }

    #[Test]
    public function it_can_determine_its_type()
    {
        $user = User::factory()->create();
        $admin = Admin::factory()->create();
        $manager = Manager::factory()->create();
        $practitioner = Practitioner::factory()->create();

        $this->assertTrue($user->isA(User::class));
        $this->assertFalse($user->isA(Admin::class));

        $this->assertTrue($admin->isA(Admin::class));
        $this->assertTrue($admin->isA(User::class)); // Admin is also a User

        $this->assertTrue($manager->isA(Manager::class));
        $this->assertTrue($manager->isA(User::class)); // Manager is also a User

        $this->assertTrue($practitioner->isA(Practitioner::class));
        $this->assertTrue($practitioner->isA(User::class)); // Practitioner is also a User
    }

    #[Test]
    public function it_can_get_user_type_enum()
    {
        $user = User::factory()->create();
        $admin = Admin::factory()->create();
        $manager = Manager::factory()->create();
        $practitioner = Practitioner::factory()->create();

        $this->assertEquals(UserType::USER, $user->userType());
        $this->assertEquals(UserType::ADMIN, $admin->userType());
        $this->assertEquals(UserType::MANAGER, $manager->userType());
        $this->assertEquals(UserType::PRACTITIONER, $practitioner->userType());
    }

    #[Test]
    public function it_can_check_if_user_is_specific_type()
    {
        $user = User::factory()->create();
        $admin = Admin::factory()->create();

        $this->assertTrue($user->isUser());
        $this->assertFalse($user->isAdmin());
        $this->assertFalse($user->isManager());
        $this->assertFalse($user->isPractitioner());

        $this->assertFalse($admin->isUser());
        $this->assertTrue($admin->isAdmin());
        $this->assertFalse($admin->isManager());
        $this->assertFalse($admin->isPractitioner());
    }

    #[Test]
    public function it_has_correct_fillable_attributes()
    {
        $user = new User();

        $this->assertContains('name', $user->getFillable());
        $this->assertContains('email', $user->getFillable());
        $this->assertContains('password', $user->getFillable());
        $this->assertContains('type', $user->getFillable());
    }

    #[Test]
    public function it_has_correct_hidden_attributes()
    {
        $user = new User();

        $this->assertContains('password', $user->getHidden());
        $this->assertContains('remember_token', $user->getHidden());
    }

    #[Test]
    public function it_has_correct_casts()
    {
        $user = new User();

        $this->assertEquals('datetime', $user->getCasts()['email_verified_at']);
    }
}
```

### Child Model Tests

```php
<?php

namespace Tests\Unit\Models;

use App\Enums\UserType;use App\Models\Admin;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class AdminModelTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_has_correct_type_column()
    {
        $admin = Admin::factory()->create();

        $this->assertEquals(Admin::class, $admin->type);
        $this->assertDatabaseHas('users', [
            'id' => $admin->id,
            'type' => Admin::class,
        ]);
    }

    #[Test]
    public function it_can_be_retrieved_as_admin_type()
    {
        $admin = Admin::factory()->create();

        $retrievedAdmin = Admin::find($admin->id);

        $this->assertInstanceOf(Admin::class, $retrievedAdmin);
        $this->assertEquals(Admin::class, $retrievedAdmin->type);
    }

    #[Test]
    public function it_inherits_from_user_model()
    {
        $admin = Admin::factory()->create();

        $this->assertInstanceOf(User::class, $admin);
    }

    #[Test]
    public function it_has_correct_user_type_enum()
    {
        $admin = Admin::factory()->create();

        $this->assertEquals(UserType::ADMIN, $admin->userType());
    }

    #[Test]
    public function it_can_be_queried_by_type()
    {
        // Create mixed user types
        User::factory()->count(3)->create();
        Admin::factory()->count(2)->create();

        // Query only admins
        $admins = User::where('type', Admin::class)->get();

        $this->assertCount(2, $admins);
        foreach ($admins as $admin) {
            $this->assertEquals(Admin::class, $admin->type);
            $this->assertInstanceOf(Admin::class, $admin);
        }
    }
}
```

Repeat similar tests for `Manager` and `Practitioner` models.

## Trait Tests

### HasName Trait Test

```php
<?php

namespace Tests\Unit\Traits;

use App\Models\User;use App\Traits\HasName;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class HasNameTraitTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_can_get_full_name()
    {
        $user = User::factory()->create([
            'given_name' => 'John',
            'family_name' => 'Doe',
        ]);

        $this->assertEquals('John Doe', $user->full_name);
    }

    #[Test]
    public function it_can_get_full_name_with_other_names()
    {
        $user = User::factory()->create([
            'given_name' => 'John',
            'family_name' => 'Doe',
            'other_names' => 'Smith',
        ]);

        $this->assertEquals('John Smith Doe', $user->full_name);
    }

    #[Test]
    public function it_can_set_name_from_string()
    {
        $user = new User();
        $user->name = 'John Doe';

        $this->assertEquals('John', $user->given_name);
        $this->assertEquals('Doe', $user->family_name);
        $this->assertNull($user->other_names);
    }

    #[Test]
    public function it_can_set_name_with_multiple_parts()
    {
        $user = new User();
        $user->name = 'John Smith Doe';

        $this->assertEquals('John', $user->given_name);
        $this->assertEquals('Doe', $user->family_name);
        $this->assertEquals('Smith', $user->other_names);
    }

    #[Test]
    public function it_can_set_name_with_many_parts()
    {
        $user = new User();
        $user->name = 'John James Smith Doe';

        $this->assertEquals('John', $user->given_name);
        $this->assertEquals('Doe', $user->family_name);
        $this->assertEquals('James Smith', $user->other_names);
    }

    #[Test]
    public function it_handles_single_name()
    {
        $user = new User();
        $user->name = 'John';

        $this->assertEquals('John', $user->given_name);
        $this->assertNull($user->family_name);
        $this->assertNull($user->other_names);
    }
}
```

### HasChildren Trait Test

```php
<?php

namespace Tests\Unit\Traits;

use App\Models\Admin;use App\Models\Manager;use App\Models\User;use App\Traits\HasChildren;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class HasChildrenTraitTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_can_get_child_types()
    {
        $childTypes = User::getChildTypes();

        $this->assertIsArray($childTypes);
        $this->assertContains(Admin::class, $childTypes);
        $this->assertContains(Manager::class, $childTypes);
    }

    #[Test]
    public function it_can_check_if_model_is_child_type()
    {
        $this->assertTrue(User::isChildType(Admin::class));
        $this->assertTrue(User::isChildType(Manager::class));
        $this->assertFalse(User::isChildType(User::class));
        $this->assertFalse(User::isChildType('InvalidClass'));
    }

    #[Test]
    public function it_can_get_child_type_from_string()
    {
        $this->assertEquals(Admin::class, User::getChildTypeFromString('admin'));
        $this->assertEquals(Manager::class, User::getChildTypeFromString('manager'));
        $this->assertNull(User::getChildTypeFromString('invalid'));
    }

    #[Test]
    public function it_can_convert_to_child_type()
    {
        $user = User::factory()->create();

        $admin = $user->convertToChildType(Admin::class);

        $this->assertInstanceOf(Admin::class, $admin);
        $this->assertEquals(Admin::class, $admin->type);
        $this->assertEquals($user->id, $admin->id);
    }

    #[Test]
    public function it_throws_exception_for_invalid_child_type()
    {
        $user = User::factory()->create();

        $this->expectException(\InvalidArgumentException::class);

        $user->convertToChildType('InvalidClass');
    }
}
```

### HasAdditionalFeatures Trait Test

```php
<?php

namespace Tests\Unit\Traits;

use App\Enums\Flags;use App\Models\Team;use App\Models\Traits\HasAdditionalFeatures;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class HasAdditionalFeaturesTraitTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_generates_ulid_on_creation()
    {
        $user = User::factory()->create();

        $this->assertNotNull($user->ulid);
        $this->assertEquals(26, strlen($user->ulid));
    }

    #[Test]
    public function it_can_get_display_name()
    {
        $user = User::factory()->create([
            'given_name' => 'John',
            'family_name' => 'Doe',
        ]);

        $this->assertEquals('John Doe', $user->getDisplayName());
    }

    #[Test]
    public function it_can_get_route_key_name()
    {
        $user = User::factory()->create();

        // Should return 'ulid' or 'slug' based on configuration
        $this->assertContains($user->getRouteKeyName(), ['ulid', 'slug', 'id']);
    }

    #[Test]
    public function it_can_check_if_feature_is_enabled()
    {
        // This test assumes that ULID is enabled in the configuration
        $this->assertTrue(User::isFeatureEnabled('ulid'));
    }

    #[Test]
    public function it_can_temporarily_disable_features()
    {
        $result = User::withoutFeatures(function () {
            return User::isFeatureEnabled('ulid');
        });

        $this->assertFalse($result);

        // Features should be re-enabled outside the callback
        $this->assertTrue(User::isFeatureEnabled('ulid'));
    }

    #[Test]
    public function it_can_add_and_check_flags()
    {
        $user = User::factory()->create();

        // Add a flag
        $user->flag(Flags::VERIFIED->value);

        // Check if the flag exists
        $this->assertTrue($user->hasFlag(Flags::VERIFIED->value));
        $this->assertFalse($user->hasFlag(Flags::FEATURED->value));

        // Remove the flag
        $user->unflag(Flags::VERIFIED->value);

        // Check if the flag is removed
        $this->assertFalse($user->hasFlag(Flags::VERIFIED->value));
    }

    #[Test]
    public function it_validates_flags_against_enum()
    {
        $user = User::factory()->create();

        // This should work fine
        $user->flag(Flags::VERIFIED->value);

        // This should throw an exception
        $this->expectException(\InvalidArgumentException::class);
        $user->flag('invalid_flag');
    }

    #[Test]
    public function it_can_use_scopes_for_published_status()
    {
        // Create published and unpublished users
        $publishedUser = User::factory()->create(['published' => true]);
        $unpublishedUser = User::factory()->create(['published' => false]);

        // Query published users
        $publishedUsers = User::published()->get();

        // Query unpublished users
        $unpublishedUsers = User::draft()->get();

        // Check results
        $this->assertTrue($publishedUsers->contains($publishedUser));
        $this->assertFalse($publishedUsers->contains($unpublishedUser));

        $this->assertFalse($unpublishedUsers->contains($publishedUser));
        $this->assertTrue($unpublishedUsers->contains($unpublishedUser));
    }

    #[Test]
    public function it_can_add_and_query_tags()
    {
        $user = User::factory()->create();

        // Add tags
        $user->attachTag('developer');
        $user->attachTag('admin', 'role');

        // Check if tags exist
        $this->assertTrue($user->hasTag('developer'));
        $this->assertTrue($user->hasTag('admin', 'role'));

        // Query by tags
        $usersWithDeveloperTag = User::withAllTags(['developer'])->get();
        $usersWithAdminRoleTag = User::withAllTags(['admin'], 'role')->get();

        // Check results
        $this->assertTrue($usersWithDeveloperTag->contains($user));
        $this->assertTrue($usersWithAdminRoleTag->contains($user));

        // Remove a tag
        $user->detachTag('developer');

        // Check if tag is removed
        $this->assertFalse($user->fresh()->hasTag('developer'));
        $this->assertTrue($user->fresh()->hasTag('admin', 'role'));
    }

    #[Test]
    public function it_can_get_tags_with_type()
    {
        $user = User::factory()->create();

        // Add tags with different types
        $user->attachTag('developer', 'profession');
        $user->attachTag('admin', 'role');

        // Get tags with specific type
        $professionTags = $user->tagsWithType('profession');
        $roleTags = $user->tagsWithType('role');

        // Check results
        $this->assertCount(1, $professionTags);
        $this->assertEquals('developer', $professionTags->first()->name);

        $this->assertCount(1, $roleTags);
        $this->assertEquals('admin', $roleTags->first()->name);
    }

    #[Test]
    public function it_can_get_searchable_array()
    {
        $user = User::factory()->create([
            'given_name' => 'John',
            'family_name' => 'Doe',
        ]);

        // Add a tag
        $user->attachTag('developer');

        // Get searchable array
        $searchableArray = $user->toSearchableArray();

        // Check array contents
        $this->assertArrayHasKey('id', $searchableArray);
        $this->assertArrayHasKey('name', $searchableArray);
        $this->assertEquals($user->id, $searchableArray['id']);
        $this->assertEquals('John Doe', $searchableArray['name']);

        // Check if tags are included if configured
        if (User::isFeatureEnabled('tags') && in_array('tags', config('additional-features.search.default_fields', []))) {
            $this->assertArrayHasKey('tags', $searchableArray);
            $this->assertContains('developer', $searchableArray['tags']);
        }
    }
}
```

## Migration Tests

```php
<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Support\Facades\Schema;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class MigrationTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function users_table_has_required_columns()
    {
        $this->assertTrue(Schema::hasTable('users'));

        $this->assertTrue(Schema::hasColumns('users', [
            'id',
            'given_name',
            'family_name',
            'other_names',
            'email',
            'email_verified_at',
            'password',
            'type',
            'metadata',
            'remember_token',
            'created_at',
            'updated_at',
        ]));
    }

    #[Test]
    public function users_table_has_correct_column_types()
    {
        $connection = Schema::getConnection();
        $columns = $connection->getDoctrineSchemaManager()->listTableColumns('users');

        $this->assertEquals('string', $columns['given_name']->getType()->getName());
        $this->assertEquals('string', $columns['family_name']->getType()->getName());
        $this->assertEquals('string', $columns['other_names']->getType()->getName());
        $this->assertEquals('string', $columns['email']->getType()->getName());
        $this->assertEquals('datetime', $columns['email_verified_at']->getType()->getName());
        $this->assertEquals('string', $columns['password']->getType()->getName());
        $this->assertEquals('string', $columns['type']->getType()->getName());
        $this->assertEquals('json', $columns['metadata']->getType()->getName());
    }

    #[Test]
    public function users_table_has_correct_indexes()
    {
        $indexes = Schema::getConnection()->getDoctrineSchemaManager()->listTableIndexes('users');

        // Check email is unique
        $this->assertArrayHasKey('users_email_unique', $indexes);
        $this->assertTrue($indexes['users_email_unique']->isUnique());
        $this->assertEquals(['email'], $indexes['users_email_unique']->getColumns());

        // Check type has an index
        $this->assertArrayHasKey('users_type_index', $indexes);
        $this->assertEquals(['type'], $indexes['users_type_index']->getColumns());
    }
}
```

## Factory Tests

```php
<?php

namespace Tests\Unit\Factories;

use App\Models\Admin;use App\Models\Manager;use App\Models\Practitioner;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class UserFactoryTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_can_create_user()
    {
        $user = User::factory()->create();

        $this->assertInstanceOf(User::class, $user);
        $this->assertEquals(User::class, $user->type);
        $this->assertNotNull($user->given_name);
        $this->assertNotNull($user->family_name);
        $this->assertNotNull($user->email);
        $this->assertNotNull($user->password);
    }

    #[Test]
    public function it_can_create_admin()
    {
        $admin = Admin::factory()->create();

        $this->assertInstanceOf(Admin::class, $admin);
        $this->assertEquals(Admin::class, $admin->type);
        $this->assertNotNull($admin->given_name);
        $this->assertNotNull($admin->family_name);
        $this->assertNotNull($admin->email);
        $this->assertNotNull($admin->password);
    }

    #[Test]
    public function it_can_create_manager()
    {
        $manager = Manager::factory()->create();

        $this->assertInstanceOf(Manager::class, $manager);
        $this->assertEquals(Manager::class, $manager->type);
        $this->assertNotNull($manager->given_name);
        $this->assertNotNull($manager->family_name);
        $this->assertNotNull($manager->email);
        $this->assertNotNull($manager->password);
    }

    #[Test]
    public function it_can_create_practitioner()
    {
        $practitioner = Practitioner::factory()->create();

        $this->assertInstanceOf(Practitioner::class, $practitioner);
        $this->assertEquals(Practitioner::class, $practitioner->type);
        $this->assertNotNull($practitioner->given_name);
        $this->assertNotNull($practitioner->family_name);
        $this->assertNotNull($practitioner->email);
        $this->assertNotNull($practitioner->password);
    }

    #[Test]
    public function it_can_override_factory_attributes()
    {
        $user = User::factory()->create([
            'given_name' => 'Custom',
            'family_name' => 'Name',
            'email' => 'custom@example.com',
        ]);

        $this->assertEquals('Custom', $user->given_name);
        $this->assertEquals('Name', $user->family_name);
        $this->assertEquals('custom@example.com', $user->email);
    }

    #[Test]
    public function it_can_create_multiple_users()
    {
        $users = User::factory()->count(5)->create();

        $this->assertCount(5, $users);
        foreach ($users as $user) {
            $this->assertInstanceOf(User::class, $user);
        }
    }
}
```

## Integration Tests

```php
<?php

namespace Tests\Feature;

use App\Models\Admin;use App\Models\Manager;use App\Models\Practitioner;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class CoreModelsIntegrationTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_can_query_all_user_types_together()
    {
        // Create different user types
        User::factory()->create();
        Admin::factory()->create();
        Manager::factory()->create();
        Practitioner::factory()->create();

        // Query all users
        $users = User::all();

        // Should return all 4 users
        $this->assertCount(4, $users);

        // Check that each user is the correct instance type
        $this->assertInstanceOf(User::class, $users->where('type', User::class)->first());
        $this->assertInstanceOf(Admin::class, $users->where('type', Admin::class)->first());
        $this->assertInstanceOf(Manager::class, $users->where('type', Manager::class)->first());
        $this->assertInstanceOf(Practitioner::class, $users->where('type', Practitioner::class)->first());
    }

    #[Test]
    public function it_can_query_specific_user_types()
    {
        // Create different user types
        User::factory()->create();
        Admin::factory()->create();
        Manager::factory()->create();
        Practitioner::factory()->create();

        // Query specific types
        $regularUsers = User::where('type', User::class)->get();
        $admins = User::where('type', Admin::class)->get();
        $managers = User::where('type', Manager::class)->get();
        $practitioners = User::where('type', Practitioner::class)->get();

        // Check counts
        $this->assertCount(1, $regularUsers);
        $this->assertCount(1, $admins);
        $this->assertCount(1, $managers);
        $this->assertCount(1, $practitioners);

        // Check instance types
        $this->assertInstanceOf(User::class, $regularUsers->first());
        $this->assertInstanceOf(Admin::class, $admins->first());
        $this->assertInstanceOf(Manager::class, $managers->first());
        $this->assertInstanceOf(Practitioner::class, $practitioners->first());
    }

    #[Test]
    public function it_can_convert_between_user_types()
    {
        // Create a regular user
        $user = User::factory()->create();

        // Convert to Admin
        $admin = $user->convertToChildType(Admin::class);
        $admin->save();

        // Check conversion
        $this->assertInstanceOf(Admin::class, $admin);
        $this->assertEquals(Admin::class, $admin->type);
        $this->assertEquals($user->id, $admin->id);

        // Convert to Manager
        $manager = $admin->convertToChildType(Manager::class);
        $manager->save();

        // Check conversion
        $this->assertInstanceOf(Manager::class, $manager);
        $this->assertEquals(Manager::class, $manager->type);
        $this->assertEquals($user->id, $manager->id);

        // Convert back to User
        $regularUser = $manager->convertToChildType(User::class);
        $regularUser->save();

        // Check conversion
        $this->assertInstanceOf(User::class, $regularUser);
        $this->assertEquals(User::class, $regularUser->type);
        $this->assertEquals($user->id, $regularUser->id);
    }

    #[Test]
    public function it_preserves_data_when_converting_between_types()
    {
        // Create a user with metadata
        $user = User::factory()->create([
            'given_name' => 'John',
            'family_name' => 'Doe',
            'email' => 'john@example.com',
        ]);

        $user->setMetadata('preferences', ['theme' => 'dark']);
        $user->save();

        // Convert to Admin
        $admin = $user->convertToChildType(Admin::class);
        $admin->save();

        // Check data is preserved
        $this->assertEquals('John', $admin->given_name);
        $this->assertEquals('Doe', $admin->family_name);
        $this->assertEquals('john@example.com', $admin->email);
        $this->assertEquals(['theme' => 'dark'], $admin->getMetadata('preferences'));

        // Convert to Manager
        $manager = $admin->convertToChildType(Manager::class);
        $manager->save();

        // Check data is preserved
        $this->assertEquals('John', $manager->given_name);
        $this->assertEquals('Doe', $manager->family_name);
        $this->assertEquals('john@example.com', $manager->email);
        $this->assertEquals(['theme' => 'dark'], $manager->getMetadata('preferences'));
    }
}
```

## Running the Tests

To run the tests for the Core Models phase, use the following command:

```bash
php artisan test --filter=UserModelTest,AdminModelTest,HasNameTraitTest,HasChildrenTraitTest,HasAdditionalFeaturesTraitTest,MigrationTest,UserFactoryTest,CoreModelsIntegrationTest,FlagsTest
```

Or run all tests with:

```bash
php artisan test
```

## Test Coverage

To ensure comprehensive test coverage for the Core Models phase, make sure your tests cover:

1. All model classes and their methods
2. All trait functionality
3. Database schema and migrations
4. Model factories
5. Integration between different models and components

## Best Practices

1. **Use PHP Attributes**: Always use PHP 8 attributes (`#[Test]`) instead of PHPDoc annotations (`/** @test */`).
2. **Test Each Model Type**: Create separate test classes for each model type.
3. **Test Trait Functionality**: Create dedicated test classes for each trait.
4. **Test Database Schema**: Verify that migrations create the correct database schema.
5. **Test Model Factories**: Ensure that factories create valid model instances.
6. **Test Integration**: Verify that models work together correctly.
7. **Use RefreshDatabase**: Use the RefreshDatabase trait to ensure a clean database state for each test.

By following these guidelines, you'll ensure that your Core Models phase is thoroughly tested and ready for the next phases of the UME tutorial.
