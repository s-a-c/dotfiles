# Permission/Role State Testing

<link rel="stylesheet" href="../../../assets/css/styles.css">

In this section, we'll create comprehensive tests for the permission and role state machines. We'll use Pest PHP for testing and PHP attributes for test annotations.

## Creating Permission State Tests

Let's start by creating a test file for the permission state machine:

```bash
php artisan pest:test PermissionStateTest
```

Now, let's implement the test:

```php
<?php

use App\Models\UPermission;
use App\Models\User;
use App\States\Permission\Active;
use App\States\Permission\Deprecated;
use App\States\Permission\Disabled;
use App\States\Permission\Draft;
use App\States\Permission\Transitions\ApprovePermissionTransition;
use App\States\Permission\Transitions\DeprecatePermissionTransition;
use App\States\Permission\Transitions\DisablePermissionTransition;
use App\States\Permission\Transitions\EnablePermissionTransition;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\ModelStates\Exceptions\TransitionNotFound;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->admin = User::factory()->create();
    $this->admin->givePermissionTo('manage-permissions');
});

test('a permission starts in draft state', function () {
    $permission = UPermission::create([
        'name' => 'test-permission',
        'guard_name' => 'web',
    ]);

    expect($permission->status)->toBeInstanceOf(Draft::class);
    expect($permission->canBeAssigned())->toBeFalse();
    expect($permission->isVisibleInUI())->toBeFalse();
    expect($permission->canBeModified())->toBeTrue();
    expect($permission->canBeDeleted())->toBeTrue();
});

test('a draft permission can be approved', function () {
    $permission = UPermission::create([
        'name' => 'test-permission',
        'guard_name' => 'web',
    ]);

    $permission->status->transition(new ApprovePermissionTransition($this->admin, 'Test approval'));
    $permission->save();

    $permission->refresh();
    expect($permission->status)->toBeInstanceOf(Active::class);
    expect($permission->canBeAssigned())->toBeTrue();
    expect($permission->isVisibleInUI())->toBeTrue();
    expect($permission->canBeModified())->toBeTrue();
    expect($permission->canBeDeleted())->toBeFalse();
});

test('an active permission can be disabled', function () {
    $permission = UPermission::create([
        'name' => 'test-permission',
        'guard_name' => 'web',
    ]);

    $permission->status->transition(new ApprovePermissionTransition($this->admin));
    $permission->save();

    $permission->refresh();
    $permission->status->transition(new DisablePermissionTransition($this->admin, 'Security concerns'));
    $permission->save();

    $permission->refresh();
    expect($permission->status)->toBeInstanceOf(Disabled::class);
    expect($permission->canBeAssigned())->toBeFalse();
    expect($permission->isVisibleInUI())->toBeTrue();
    expect($permission->canBeModified())->toBeTrue();
    expect($permission->canBeDeleted())->toBeFalse();
});

test('a disabled permission can be enabled', function () {
    $permission = UPermission::create([
        'name' => 'test-permission',
        'guard_name' => 'web',
    ]);

    $permission->status->transition(new ApprovePermissionTransition($this->admin));
    $permission->save();

    $permission->refresh();
    $permission->status->transition(new DisablePermissionTransition($this->admin, 'Security concerns'));
    $permission->save();

    $permission->refresh();
    $permission->status->transition(new EnablePermissionTransition($this->admin));
    $permission->save();

    $permission->refresh();
    expect($permission->status)->toBeInstanceOf(Active::class);
    expect($permission->canBeAssigned())->toBeTrue();
    expect($permission->isVisibleInUI())->toBeTrue();
    expect($permission->canBeModified())->toBeTrue();
    expect($permission->canBeDeleted())->toBeFalse();
});

test('an active permission can be deprecated', function () {
    $permission = UPermission::create([
        'name' => 'test-permission',
        'guard_name' => 'web',
    ]);

    $permission->status->transition(new ApprovePermissionTransition($this->admin));
    $permission->save();

    $permission->refresh();
    $permission->status->transition(new DeprecatePermissionTransition($this->admin, 'No longer needed'));
    $permission->save();

    $permission->refresh();
    expect($permission->status)->toBeInstanceOf(Deprecated::class);
    expect($permission->canBeAssigned())->toBeFalse();
    expect($permission->isVisibleInUI())->toBeFalse();
    expect($permission->canBeModified())->toBeFalse();
    expect($permission->canBeDeleted())->toBeTrue();
});

test('a disabled permission can be deprecated', function () {
    $permission = UPermission::create([
        'name' => 'test-permission',
        'guard_name' => 'web',
    ]);

    $permission->status->transition(new ApprovePermissionTransition($this->admin));
    $permission->save();

    $permission->refresh();
    $permission->status->transition(new DisablePermissionTransition($this->admin, 'Security concerns'));
    $permission->save();

    $permission->refresh();
    $permission->status->transition(new DeprecatePermissionTransition($this->admin, 'No longer needed'));
    $permission->save();

    $permission->refresh();
    expect($permission->status)->toBeInstanceOf(Deprecated::class);
    expect($permission->canBeAssigned())->toBeFalse();
    expect($permission->isVisibleInUI())->toBeFalse();
    expect($permission->canBeModified())->toBeFalse();
    expect($permission->canBeDeleted())->toBeTrue();
});

test('a draft permission cannot be disabled', function () {
    $permission = UPermission::create([
        'name' => 'test-permission',
        'guard_name' => 'web',
    ]);

    expect(fn () => $permission->status->transition(new DisablePermissionTransition($this->admin, 'Security concerns')))
        ->toThrow(TransitionNotFound::class);
});

test('a draft permission cannot be deprecated', function () {
    $permission = UPermission::create([
        'name' => 'test-permission',
        'guard_name' => 'web',
    ]);

    expect(fn () => $permission->status->transition(new DeprecatePermissionTransition($this->admin, 'No longer needed')))
        ->toThrow(TransitionNotFound::class);
});

test('a deprecated permission cannot be enabled', function () {
    $permission = UPermission::create([
        'name' => 'test-permission',
        'guard_name' => 'web',
    ]);

    $permission->status->transition(new ApprovePermissionTransition($this->admin));
    $permission->save();

    $permission->refresh();
    $permission->status->transition(new DeprecatePermissionTransition($this->admin, 'No longer needed'));
    $permission->save();

    $permission->refresh();
    expect(fn () => $permission->status->transition(new EnablePermissionTransition($this->admin)))
        ->toThrow(TransitionNotFound::class);
});

test('the permission controller can approve a draft permission', function () {
    $permission = UPermission::create([
        'name' => 'test-permission',
        'guard_name' => 'web',
    ]);

    $this->actingAs($this->admin)
        ->post(route('admin.permissions.approve', $permission))
        ->assertRedirect(route('admin.permissions.show', $permission))
        ->assertSessionHas('success');

    $permission->refresh();
    expect($permission->status)->toBeInstanceOf(Active::class);
});

test('the permission controller can disable an active permission', function () {
    $permission = UPermission::create([
        'name' => 'test-permission',
        'guard_name' => 'web',
    ]);

    $permission->status->transition(new ApprovePermissionTransition($this->admin));
    $permission->save();

    $this->actingAs($this->admin)
        ->post(route('admin.permissions.disable', $permission), [
            'reason' => 'Security concerns',
        ])
        ->assertRedirect(route('admin.permissions.show', $permission))
        ->assertSessionHas('success');

    $permission->refresh();
    expect($permission->status)->toBeInstanceOf(Disabled::class);
});

test('the permission controller can enable a disabled permission', function () {
    $permission = UPermission::create([
        'name' => 'test-permission',
        'guard_name' => 'web',
    ]);

    $permission->status->transition(new ApprovePermissionTransition($this->admin));
    $permission->save();

    $permission->refresh();
    $permission->status->transition(new DisablePermissionTransition($this->admin, 'Security concerns'));
    $permission->save();

    $this->actingAs($this->admin)
        ->post(route('admin.permissions.enable', $permission))
        ->assertRedirect(route('admin.permissions.show', $permission))
        ->assertSessionHas('success');

    $permission->refresh();
    expect($permission->status)->toBeInstanceOf(Active::class);
});

test('the permission controller can deprecate an active permission', function () {
    $permission = UPermission::create([
        'name' => 'test-permission',
        'guard_name' => 'web',
    ]);

    $permission->status->transition(new ApprovePermissionTransition($this->admin));
    $permission->save();

    $this->actingAs($this->admin)
        ->post(route('admin.permissions.deprecate', $permission), [
            'reason' => 'No longer needed',
        ])
        ->assertRedirect(route('admin.permissions.show', $permission))
        ->assertSessionHas('success');

    $permission->refresh();
    expect($permission->status)->toBeInstanceOf(Deprecated::class);
});
```
