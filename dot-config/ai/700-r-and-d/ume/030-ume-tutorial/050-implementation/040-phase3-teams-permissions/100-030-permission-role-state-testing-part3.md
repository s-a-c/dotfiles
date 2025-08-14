# Permission/Role State Testing (Part 3)

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Creating Feature Tests for Permission and Role Management

Let's create feature tests for the permission and role management controllers:

```bash
php artisan pest:test PermissionControllerTest --feature
php artisan pest:test RoleControllerTest --feature
```

### Permission Controller Feature Test

```php
<?php

use App\Models\UPermission;
use App\Models\User;
use App\States\Permission\Active;
use App\States\Permission\Deprecated;
use App\States\Permission\Disabled;
use App\States\Permission\Draft;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->admin = User::factory()->create();
    $this->admin->givePermissionTo('manage-permissions');
});

test('admin can view permissions index', function () {
    $this->actingAs($this->admin)
        ->get(route('admin.permissions.index'))
        ->assertStatus(200)
        ->assertViewIs('admin.permissions.index');
});

test('admin can create a new permission', function () {
    $this->actingAs($this->admin)
        ->get(route('admin.permissions.create'))
        ->assertStatus(200)
        ->assertViewIs('admin.permissions.create');

    $this->actingAs($this->admin)
        ->post(route('admin.permissions.store'), [
            'name' => 'test-permission',
            'guard_name' => 'web',
            'description' => 'Test permission description',
        ])
        ->assertRedirect(route('admin.permissions.show', 1))
        ->assertSessionHas('success');

    $permission = UPermission::first();
    expect($permission->name)->toBe('test-permission');
    expect($permission->guard_name)->toBe('web');
    expect($permission->description)->toBe('Test permission description');
    expect($permission->status)->toBeInstanceOf(Draft::class);
});

test('admin can view a permission', function () {
    $permission = UPermission::create([
        'name' => 'test-permission',
        'guard_name' => 'web',
    ]);

    $this->actingAs($this->admin)
        ->get(route('admin.permissions.show', $permission))
        ->assertStatus(200)
        ->assertViewIs('admin.permissions.show')
        ->assertSee('test-permission');
});

test('admin can edit a permission', function () {
    $permission = UPermission::create([
        'name' => 'test-permission',
        'guard_name' => 'web',
    ]);

    $this->actingAs($this->admin)
        ->get(route('admin.permissions.edit', $permission))
        ->assertStatus(200)
        ->assertViewIs('admin.permissions.edit')
        ->assertSee('test-permission');

    $this->actingAs($this->admin)
        ->put(route('admin.permissions.update', $permission), [
            'name' => 'updated-permission',
            'guard_name' => 'web',
            'description' => 'Updated description',
        ])
        ->assertRedirect(route('admin.permissions.show', $permission))
        ->assertSessionHas('success');

    $permission->refresh();
    expect($permission->name)->toBe('updated-permission');
    expect($permission->description)->toBe('Updated description');
});

test('admin cannot edit a deprecated permission', function () {
    $permission = UPermission::create([
        'name' => 'test-permission',
        'guard_name' => 'web',
    ]);

    // Approve and then deprecate the permission
    $permission->status = new Active($permission);
    $permission->save();
    $permission->status = new Deprecated($permission);
    $permission->save();

    $this->actingAs($this->admin)
        ->get(route('admin.permissions.edit', $permission))
        ->assertRedirect(route('admin.permissions.show', $permission))
        ->assertSessionHas('error');

    $this->actingAs($this->admin)
        ->put(route('admin.permissions.update', $permission), [
            'name' => 'updated-permission',
            'guard_name' => 'web',
        ])
        ->assertRedirect(route('admin.permissions.show', $permission))
        ->assertSessionHas('error');

    $permission->refresh();
    expect($permission->name)->toBe('test-permission');
});

test('admin can delete a draft permission', function () {
    $permission = UPermission::create([
        'name' => 'test-permission',
        'guard_name' => 'web',
    ]);

    $this->actingAs($this->admin)
        ->delete(route('admin.permissions.destroy', $permission))
        ->assertRedirect(route('admin.permissions.index'))
        ->assertSessionHas('success');

    expect(UPermission::count())->toBe(0);
});

test('admin cannot delete an active permission', function () {
    $permission = UPermission::create([
        'name' => 'test-permission',
        'guard_name' => 'web',
    ]);

    $permission->status = new Active($permission);
    $permission->save();

    $this->actingAs($this->admin)
        ->delete(route('admin.permissions.destroy', $permission))
        ->assertRedirect(route('admin.permissions.show', $permission))
        ->assertSessionHas('error');

    expect(UPermission::count())->toBe(1);
});

test('admin can approve a draft permission', function () {
    $permission = UPermission::create([
        'name' => 'test-permission',
        'guard_name' => 'web',
    ]);

    $this->actingAs($this->admin)
        ->post(route('admin.permissions.approve', $permission), [
            'notes' => 'Approved for testing',
        ])
        ->assertRedirect(route('admin.permissions.show', $permission))
        ->assertSessionHas('success');

    $permission->refresh();
    expect($permission->status)->toBeInstanceOf(Active::class);
});

test('admin can disable an active permission', function () {
    $permission = UPermission::create([
        'name' => 'test-permission',
        'guard_name' => 'web',
    ]);

    $permission->status = new Active($permission);
    $permission->save();

    $this->actingAs($this->admin)
        ->post(route('admin.permissions.disable', $permission), [
            'reason' => 'Security concerns',
            'notes' => 'Disabled for testing',
        ])
        ->assertRedirect(route('admin.permissions.show', $permission))
        ->assertSessionHas('success');

    $permission->refresh();
    expect($permission->status)->toBeInstanceOf(Disabled::class);
});

test('admin can enable a disabled permission', function () {
    $permission = UPermission::create([
        'name' => 'test-permission',
        'guard_name' => 'web',
    ]);

    $permission->status = new Disabled($permission);
    $permission->save();

    $this->actingAs($this->admin)
        ->post(route('admin.permissions.enable', $permission), [
            'notes' => 'Enabled for testing',
        ])
        ->assertRedirect(route('admin.permissions.show', $permission))
        ->assertSessionHas('success');

    $permission->refresh();
    expect($permission->status)->toBeInstanceOf(Active::class);
});

test('admin can deprecate an active permission', function () {
    $permission = UPermission::create([
        'name' => 'test-permission',
        'guard_name' => 'web',
    ]);

    $permission->status = new Active($permission);
    $permission->save();

    $this->actingAs($this->admin)
        ->post(route('admin.permissions.deprecate', $permission), [
            'reason' => 'No longer needed',
            'notes' => 'Deprecated for testing',
        ])
        ->assertRedirect(route('admin.permissions.show', $permission))
        ->assertSessionHas('success');

    $permission->refresh();
    expect($permission->status)->toBeInstanceOf(Deprecated::class);
});

test('admin can deprecate a disabled permission', function () {
    $permission = UPermission::create([
        'name' => 'test-permission',
        'guard_name' => 'web',
    ]);

    $permission->status = new Disabled($permission);
    $permission->save();

    $this->actingAs($this->admin)
        ->post(route('admin.permissions.deprecate', $permission), [
            'reason' => 'No longer needed',
            'notes' => 'Deprecated for testing',
        ])
        ->assertRedirect(route('admin.permissions.show', $permission))
        ->assertSessionHas('success');

    $permission->refresh();
    expect($permission->status)->toBeInstanceOf(Deprecated::class);
});

test('non-admin cannot access permission management', function () {
    $user = User::factory()->create();
    $permission = UPermission::create([
        'name' => 'test-permission',
        'guard_name' => 'web',
    ]);

    $this->actingAs($user)
        ->get(route('admin.permissions.index'))
        ->assertStatus(403);

    $this->actingAs($user)
        ->get(route('admin.permissions.create'))
        ->assertStatus(403);

    $this->actingAs($user)
        ->post(route('admin.permissions.store'), [
            'name' => 'new-permission',
            'guard_name' => 'web',
        ])
        ->assertStatus(403);

    $this->actingAs($user)
        ->get(route('admin.permissions.show', $permission))
        ->assertStatus(403);

    $this->actingAs($user)
        ->get(route('admin.permissions.edit', $permission))
        ->assertStatus(403);

    $this->actingAs($user)
        ->put(route('admin.permissions.update', $permission), [
            'name' => 'updated-permission',
            'guard_name' => 'web',
        ])
        ->assertStatus(403);

    $this->actingAs($user)
        ->delete(route('admin.permissions.destroy', $permission))
        ->assertStatus(403);

    $this->actingAs($user)
        ->post(route('admin.permissions.approve', $permission))
        ->assertStatus(403);

    $this->actingAs($user)
        ->post(route('admin.permissions.disable', $permission), [
            'reason' => 'Security concerns',
        ])
        ->assertStatus(403);

    $this->actingAs($user)
        ->post(route('admin.permissions.enable', $permission))
        ->assertStatus(403);

    $this->actingAs($user)
        ->post(route('admin.permissions.deprecate', $permission), [
            'reason' => 'No longer needed',
        ])
        ->assertStatus(403);
});
```

## Running the Tests

To run the tests, use the following command:

```bash
php artisan test --filter=PermissionStateTest
php artisan test --filter=RoleStateTest
php artisan test --filter=PermissionControllerTest
php artisan test --filter=RoleControllerTest
```

Or, if you're using Pest:

```bash
./vendor/bin/pest --filter=PermissionStateTest
./vendor/bin/pest --filter=RoleStateTest
./vendor/bin/pest --filter=PermissionControllerTest
./vendor/bin/pest --filter=RoleControllerTest
```

## Conclusion

In this section, we've created comprehensive tests for the permission and role state machines. These tests ensure that:

1. Permissions and roles start in the correct initial state (Draft)
2. State transitions work correctly and enforce the allowed transitions
3. State-specific behaviors are correctly implemented
4. The controllers correctly handle state transitions
5. Authorization is properly enforced

By thoroughly testing our state machines, we can be confident that they will work correctly in our application.

## Next Steps

Now that we've implemented and tested the permission and role state machines, we can move on to the next phase of our application development. In the next sections, we'll:

1. Create a permission seeder to seed roles and permissions based on team/user type
2. Implement the team service class
3. Implement the team hierarchy state machine

## Additional Resources

- [Pest PHP Documentation](https://pestphp.com/docs/introduction)
- [Laravel Testing Documentation](https://laravel.com/docs/12.x/testing)
- [Spatie Laravel Model States Documentation](https://spatie.be/docs/laravel-model-states/v2/introduction)
- [Spatie Laravel Permission Documentation](https://spatie.be/docs/laravel-permission/v5/introduction)
