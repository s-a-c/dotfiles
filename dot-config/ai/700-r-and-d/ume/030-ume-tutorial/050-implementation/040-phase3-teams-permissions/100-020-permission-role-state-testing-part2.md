# Permission/Role State Testing (Part 2)

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Creating Role State Tests

Now, let's create a test file for the role state machine:

```bash
php artisan pest:test RoleStateTest
```

Now, let's implement the test:

```php
<?php

use App\Models\URole;
use App\Models\User;
use App\States\Role\Active;
use App\States\Role\Deprecated;
use App\States\Role\Disabled;
use App\States\Role\Draft;
use App\States\Role\Transitions\ApproveRoleTransition;
use App\States\Role\Transitions\DeprecateRoleTransition;
use App\States\Role\Transitions\DisableRoleTransition;
use App\States\Role\Transitions\EnableRoleTransition;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\ModelStates\Exceptions\TransitionNotFound;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->admin = User::factory()->create();
    $this->admin->givePermissionTo('manage-roles');
});

test('a role starts in draft state', function () {
    $role = URole::create([
        'name' => 'test-role',
        'guard_name' => 'web',
    ]);

    expect($role->status)->toBeInstanceOf(Draft::class);
    expect($role->canBeAssigned())->toBeFalse();
    expect($role->isVisibleInUI())->toBeFalse();
    expect($role->canModifyPermissions())->toBeTrue();
    expect($role->canBeDeleted())->toBeTrue();
});

test('a draft role can be approved', function () {
    $role = URole::create([
        'name' => 'test-role',
        'guard_name' => 'web',
    ]);

    $role->status->transition(new ApproveRoleTransition($this->admin, 'Test approval'));
    $role->save();

    $role->refresh();
    expect($role->status)->toBeInstanceOf(Active::class);
    expect($role->canBeAssigned())->toBeTrue();
    expect($role->isVisibleInUI())->toBeTrue();
    expect($role->canModifyPermissions())->toBeTrue();
    expect($role->canBeDeleted())->toBeFalse();
});

test('an active role can be disabled', function () {
    $role = URole::create([
        'name' => 'test-role',
        'guard_name' => 'web',
    ]);

    $role->status->transition(new ApproveRoleTransition($this->admin));
    $role->save();

    $role->refresh();
    $role->status->transition(new DisableRoleTransition($this->admin, 'Organizational restructuring'));
    $role->save();

    $role->refresh();
    expect($role->status)->toBeInstanceOf(Disabled::class);
    expect($role->canBeAssigned())->toBeFalse();
    expect($role->isVisibleInUI())->toBeTrue();
    expect($role->canModifyPermissions())->toBeFalse();
    expect($role->canBeDeleted())->toBeFalse();
});

test('a disabled role can be enabled', function () {
    $role = URole::create([
        'name' => 'test-role',
        'guard_name' => 'web',
    ]);

    $role->status->transition(new ApproveRoleTransition($this->admin));
    $role->save();

    $role->refresh();
    $role->status->transition(new DisableRoleTransition($this->admin, 'Organizational restructuring'));
    $role->save();

    $role->refresh();
    $role->status->transition(new EnableRoleTransition($this->admin));
    $role->save();

    $role->refresh();
    expect($role->status)->toBeInstanceOf(Active::class);
    expect($role->canBeAssigned())->toBeTrue();
    expect($role->isVisibleInUI())->toBeTrue();
    expect($role->canModifyPermissions())->toBeTrue();
    expect($role->canBeDeleted())->toBeFalse();
});

test('an active role can be deprecated', function () {
    $role = URole::create([
        'name' => 'test-role',
        'guard_name' => 'web',
    ]);

    $role->status->transition(new ApproveRoleTransition($this->admin));
    $role->save();

    $role->refresh();
    $role->status->transition(new DeprecateRoleTransition($this->admin, 'No longer needed'));
    $role->save();

    $role->refresh();
    expect($role->status)->toBeInstanceOf(Deprecated::class);
    expect($role->canBeAssigned())->toBeFalse();
    expect($role->isVisibleInUI())->toBeFalse();
    expect($role->canModifyPermissions())->toBeFalse();
    expect($role->canBeDeleted())->toBeTrue();
});

test('a disabled role can be deprecated', function () {
    $role = URole::create([
        'name' => 'test-role',
        'guard_name' => 'web',
    ]);

    $role->status->transition(new ApproveRoleTransition($this->admin));
    $role->save();

    $role->refresh();
    $role->status->transition(new DisableRoleTransition($this->admin, 'Organizational restructuring'));
    $role->save();

    $role->refresh();
    $role->status->transition(new DeprecateRoleTransition($this->admin, 'No longer needed'));
    $role->save();

    $role->refresh();
    expect($role->status)->toBeInstanceOf(Deprecated::class);
    expect($role->canBeAssigned())->toBeFalse();
    expect($role->isVisibleInUI())->toBeFalse();
    expect($role->canModifyPermissions())->toBeFalse();
    expect($role->canBeDeleted())->toBeTrue();
});

test('a draft role cannot be disabled', function () {
    $role = URole::create([
        'name' => 'test-role',
        'guard_name' => 'web',
    ]);

    expect(fn () => $role->status->transition(new DisableRoleTransition($this->admin, 'Organizational restructuring')))
        ->toThrow(TransitionNotFound::class);
});

test('a draft role cannot be deprecated', function () {
    $role = URole::create([
        'name' => 'test-role',
        'guard_name' => 'web',
    ]);

    expect(fn () => $role->status->transition(new DeprecateRoleTransition($this->admin, 'No longer needed')))
        ->toThrow(TransitionNotFound::class);
});

test('a deprecated role cannot be enabled', function () {
    $role = URole::create([
        'name' => 'test-role',
        'guard_name' => 'web',
    ]);

    $role->status->transition(new ApproveRoleTransition($this->admin));
    $role->save();

    $role->refresh();
    $role->status->transition(new DeprecateRoleTransition($this->admin, 'No longer needed'));
    $role->save();

    $role->refresh();
    expect(fn () => $role->status->transition(new EnableRoleTransition($this->admin)))
        ->toThrow(TransitionNotFound::class);
});

test('the role controller can approve a draft role', function () {
    $role = URole::create([
        'name' => 'test-role',
        'guard_name' => 'web',
    ]);

    $this->actingAs($this->admin)
        ->post(route('admin.roles.approve', $role))
        ->assertRedirect(route('admin.roles.show', $role))
        ->assertSessionHas('success');

    $role->refresh();
    expect($role->status)->toBeInstanceOf(Active::class);
});

test('the role controller can disable an active role', function () {
    $role = URole::create([
        'name' => 'test-role',
        'guard_name' => 'web',
    ]);

    $role->status->transition(new ApproveRoleTransition($this->admin));
    $role->save();

    $this->actingAs($this->admin)
        ->post(route('admin.roles.disable', $role), [
            'reason' => 'Organizational restructuring',
        ])
        ->assertRedirect(route('admin.roles.show', $role))
        ->assertSessionHas('success');

    $role->refresh();
    expect($role->status)->toBeInstanceOf(Disabled::class);
});

test('the role controller can enable a disabled role', function () {
    $role = URole::create([
        'name' => 'test-role',
        'guard_name' => 'web',
    ]);

    $role->status->transition(new ApproveRoleTransition($this->admin));
    $role->save();

    $role->refresh();
    $role->status->transition(new DisableRoleTransition($this->admin, 'Organizational restructuring'));
    $role->save();

    $this->actingAs($this->admin)
        ->post(route('admin.roles.enable', $role))
        ->assertRedirect(route('admin.roles.show', $role))
        ->assertSessionHas('success');

    $role->refresh();
    expect($role->status)->toBeInstanceOf(Active::class);
});

test('the role controller can deprecate an active role', function () {
    $role = URole::create([
        'name' => 'test-role',
        'guard_name' => 'web',
    ]);

    $role->status->transition(new ApproveRoleTransition($this->admin));
    $role->save();

    $this->actingAs($this->admin)
        ->post(route('admin.roles.deprecate', $role), [
            'reason' => 'No longer needed',
        ])
        ->assertRedirect(route('admin.roles.show', $role))
        ->assertSessionHas('success');

    $role->refresh();
    expect($role->status)->toBeInstanceOf(Deprecated::class);
});
```
