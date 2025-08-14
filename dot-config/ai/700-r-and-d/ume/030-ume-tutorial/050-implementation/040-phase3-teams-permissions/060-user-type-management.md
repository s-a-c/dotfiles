# User Type Management Component

This documentation covers the User Type Management component, which provides a powerful and secure way to change a user's type within your Laravel application.

## Overview

The User Type Management component allows authorized administrators to easily change a user's type (e.g., from a regular User to an Admin or Manager) through a simple interface. When a user's type is changed, the component:

- Updates the user's `type` property to the new user type class name
- Synchronizes the user's roles to match the default roles for the new type
- Provides security checks to prevent unauthorized promotions
- Generates appropriate UI feedback and confirmations

This component is ideal for applications requiring dynamic user type management without having to delete and recreate user accounts.

## Component Architecture

The User Type Management functionality is composed of:

1. **Livewire Component Class**: Handles the business logic for type changes
2. **Blade View Template**: Provides the UI interface with dropdowns and modals
3. **Integration with UserType Enum**: Leverages the UserType enum for type information
4. **Role Management**: Works with Spatie Permission package for role synchronization

## Implementation

### Step 1: Create the Livewire Component

First, create a new Livewire component called `UserTypeManager` in your Laravel application using Volt SFC (Single File Component):

```php
<?php

use App\Models\User;
use App\Enums\UserType;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Spatie\Permission\Models\Role;
use Livewire\Volt\Component;
use Livewire\Attributes\Validate;

new class extends Component {
    public User $user;
    public string $newType;
    public bool $confirmingTypeChange = false;
    public ?UserType $currentType = null;

    /**
     * Mount the component with the user and initialize properties
     */
    public function mount(User $user): void
    {
        $this->user = $user;
        $this->newType = $user->type;
        $this->currentType = UserType::fromClass($user->type);
    }

    /**
     * Get available user types for the dropdown
     */
    public function getTypesProperty(): array
    {
        $types = [];

        foreach (UserType::cases() as $type) {
            $types[$type->value] = $type->label();
        }

        return $types;
    }

    /**
     * Open the confirmation dialog
     */
    public function confirmTypeChange(): void
    {
        if ($this->newType === $this->user->type) {
            // No change, no need to confirm
            return;
        }

        // Check if user has permission to change types
        if (! auth()->user()->can('change user types')) {
            $this->addError('newType', 'You do not have permission to change user types.');
            return;
        }

        // Additional security check
        if ($this->user->id === 1 || $this->user->id === auth()->id()) {
            $this->addError('newType', 'Cannot change type of primary admin or yourself.');
            return;
        }

        // Get enum for the new type
        $newTypeEnum = UserType::fromClass($this->newType);

        // Validate the new type
        if (!$newTypeEnum || !UserType::isValid($this->newType)) {
            $this->addError('newType', 'Invalid user type selected.');
            return;
        }

        // Don't allow changes to higher privilege types unless user is admin
        $currentUserTypeEnum = UserType::fromClass(Auth::user()->type);

        if ($newTypeEnum && $currentUserTypeEnum) {
            // Check if new type has higher privileges than current user's type
            if ($newTypeEnum->hasHigherPrivilegesThan($currentUserTypeEnum) &&
                !Auth::user()->hasRole('super-admin')) {
                $this->addError('newType', 'You cannot promote a user to a role with higher privileges than your own.');
                return;
            }
        }

        $this->confirmingTypeChange = true;
    }

    /**
     * Cancel the type change
     */
    public function cancelTypeChange(): void
    {
        $this->confirmingTypeChange = false;
        $this->newType = $this->user->type; // Reset to original value
    }

    /**
     * Process the type change
     */
    public function changeType(): void
    {
        $this->authorize('change user types');

        // Validate the new type
        if (!UserType::isValid($this->newType)) {
            $this->addError('newType', 'Invalid user type selected.');
            $this->confirmingTypeChange = false;
            return;
        }

        try {
            // Get old type for logging
            $oldType = $this->user->type;

            // Update the user's type
            $this->user->type = $this->newType;
            $this->user->save();

            // Get the new type enum
            $newTypeEnum = UserType::fromClass($this->newType);

            // Sync roles based on new type
            if ($newTypeEnum) {
                // Get default roles for the new type
                $defaultRoles = $newTypeEnum->defaultRoles();

                // Get Role models for these role names
                $roles = Role::whereIn('name', $defaultRoles)->get();

                // Sync roles (replace existing roles with the new defaults)
                $this->user->syncRoles($roles);
            }

            // Log the change
            Log::info('User type changed', [
                'user_id' => $this->user->id,
                'old_type' => $oldType,
                'new_type' => $this->newType,
                'changed_by' => Auth::id(),
            ]);

            // Get the new type label for notification
            $newTypeLabel = UserType::fromClass($this->newType)?->label() ?? 'Unknown';

            // Set success message
            $this->dispatch('notify', [
                'type' => 'success',
                'message' => "User type changed to {$newTypeLabel} successfully!"
            ]);

            // Close the dialog
            $this->confirmingTypeChange = false;
        } catch (\Exception $e) {
            Log::error('Error changing user type', [
                'user_id' => $this->user->id,
                'error' => $e->getMessage(),
            ]);

            $this->addError('newType', 'Failed to change user type: ' . $e->getMessage());
            $this->confirmingTypeChange = false;
        }
    }
};
```

### Step 2: Create the Volt Template

Next, create the Volt template for the component. This will provide the UI for changing user types:

```php
<div>
    <div class="mb-4">
        <x-flux-form-label for="newType" label="Change User Type" />
        <x-flux-select id="newType" wire:model="newType" :options="$this->types" />
        @error('newType') <p class="mt-1 text-sm text-red-500">{{ $message }}</p> @enderror
    </div>

    <div class="flex justify-end">
        <x-flux-button wire:click="confirmTypeChange" color="primary">
            Change Type
        </x-flux-button>
    </div>

    <!-- Confirmation Modal -->
    <x-flux-modal wire:model="confirmingTypeChange">
        <x-slot name="title">
            Confirm Type Change
        </x-slot>

        <x-slot name="content">
            <p class="mb-4 text-sm text-gray-600 dark:text-gray-400">
                Are you sure you want to change this user's type to
                <span class="font-medium">{{ UserType::fromClass($newType)?->label() }}</span>?
            </p>

            <p class="mb-2 text-sm text-gray-600 dark:text-gray-400">
                This will update the user's permissions and roles accordingly.
            </p>

            @if($currentType && $newTypeEnum = UserType::fromClass($newType))
                <div class="mt-4">
                    <h4 class="text-sm font-medium text-gray-700 dark:text-gray-300">Role Changes:</h4>
                    <ul class="mt-1 text-sm text-gray-600 dark:text-gray-400 space-y-1">
                        <li>
                            <span class="font-medium">Current roles:</span>
                            {{ implode(', ', $currentType->defaultRoles()) }}
                        </li>
                        <li>
                            <span class="font-medium">New roles:</span>
                            {{ implode(', ', $newTypeEnum->defaultRoles()) }}
                        </li>
                    </ul>
                </div>
            @endif
        </x-slot>

        <x-slot name="footer">
            <x-secondary-button wire:click="cancelTypeChange" wire:loading.attr="disabled">
                Cancel
            </x-secondary-button>

            <x-danger-button class="ml-3" wire:click="changeType" wire:loading.attr="disabled">
                Change Type
            </x-danger-button>
        </x-slot>
    </x-flux-modal>
</div>
```

### Step 3: Implement the UserType Enum Methods

Ensure your `UserType` enum has the necessary methods to support type management:

```php
/**
 * Get default roles associated with this user type.
 * For use with Spatie Permission package integration.
 *
 * @return array<string> Array of role names
 */
public function defaultRoles(): array
{
    return match($this) {
        self::USER => ['user'],
        self::ADMIN => ['admin', 'super-admin'],
        self::MANAGER => ['manager', 'team-lead'],
        self::PRACTITIONER => ['practitioner', 'professional'],
    };
}

/**
 * Get default permissions associated with this user type.
 *
 * @return array<string> Array of permission names
 */
public function defaultPermissions(): array
{
    return match($this) {
        self::USER => [
            'profile.view.own',
            'profile.edit.own',
            'comments.create',
            'comments.view',
        ],
        self::ADMIN => [
            'admin.access',
            'users.manage',
            'roles.manage',
            'permissions.manage',
            'settings.manage',
            'teams.manage',
            'logs.view',
            'system.manage',
        ],
        self::MANAGER => [
            'team.manage',
            'team.view',
            'team-members.invite',
            'team-members.remove',
            'team-settings.edit',
            'reports.view',
        ],
        self::PRACTITIONER => [
            'practice.access',
            'clients.view',
            'clients.manage',
            'schedule.view',
            'schedule.manage',
        ],
    };
}

/**
 * Check if this type has higher privileges than another type
 * Used for security checks when changing user types
 *
 * @param UserType $otherType The type to compare against
 * @return bool True if this type has higher privileges
 */
public function hasHigherPrivilegesThan(UserType $otherType): bool
{
    // Define privilege hierarchy (higher index = higher privileges)
    $privilegeRanking = [
        self::USER->value => 1,
        self::PRACTITIONER->value => 2,
        self::MANAGER->value => 3,
        self::ADMIN->value => 4,
    ];

    // Compare privilege rankings
    return ($privilegeRanking[$this->value] ?? 0) > ($privilegeRanking[$otherType->value] ?? 0);
}

/**
 * Create a badge HTML for this user type
 *
 * @return string HTML for the badge
 */
public function badge(): string
{
    $colorClass = match($this) {
        self::USER => 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300',
        self::ADMIN => 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300',
        self::MANAGER => 'bg-amber-100 text-amber-800 dark:bg-amber-900 dark:text-amber-300',
        self::PRACTITIONER => 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900 dark:text-emerald-300',
    };

    return '<span class="px-2 py-1 text-xs font-medium rounded-full ' . $colorClass . '">' .
           $this->label() .
           '</span>';
}
```

### Step 4: Add Helper Methods to the User Model

Add the following methods to your `User` model to support type management:

```php
/**
 * Convert this user to a different user type
 *
 * @param string $newType The class name of the new type
 * @return bool Whether the conversion was successful
 */
public function convertToType(string $newType): bool
{
    // Validate the new type
    if (!UserType::isValid($newType)) {
        throw new \InvalidArgumentException("Invalid user type: {$newType}");
    }

    // Get old type for comparison
    $oldType = $this->type;

    // No change needed if types are the same
    if ($oldType === $newType) {
        return true;
    }

    // Begin transaction
    DB::beginTransaction();

    try {
        // Update the type
        $this->type = $newType;
        $this->save();

        // Get the new type enum
        $newTypeEnum = UserType::fromClass($newType);

        // Sync roles based on new type
        if ($newTypeEnum) {
            // Get default roles for the new type
            $defaultRoles = $newTypeEnum->defaultRoles();

            // Get Role models for these role names
            $roles = Role::whereIn('name', $defaultRoles)->get();

            // Sync roles (replace existing roles with the new defaults)
            $this->syncRoles($roles);
        }

        // Commit transaction
        DB::commit();

        return true;
    } catch (\Exception $e) {
        // Rollback on error
        DB::rollBack();

        // Log the error
        Log::error('Error converting user type', [
            'user_id' => $this->id,
            'old_type' => $oldType,
            'new_type' => $newType,
            'error' => $e->getMessage(),
        ]);

        throw $e;
    }
}
```

### Step 5: Register the Component

Register the Livewire component in your `AppServiceProvider` or a dedicated `LivewireServiceProvider`:

```php
use Livewire\Livewire;
use App\Livewire\UserTypeManager;

// In the boot method
Livewire::component('user-type-manager', UserTypeManager::class);
```

### Step 6: Add the Component to Your User Management UI

Include the component in your user management interface:

```php
<div class="mt-6 p-4 bg-white dark:bg-gray-800 rounded-lg shadow">
    <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100">User Type Management</h3>

    <div class="mt-4">
        <livewire:user-type-manager :user="$user" />
    </div>
</div>
```

## Security Considerations

The User Type Management component implements several security measures to prevent unauthorized type changes:

1. **Permission Checks**: Users must have the `change user types` permission to modify user types.

2. **Self-Modification Prevention**: Users cannot change their own type to prevent privilege escalation.

3. **Primary Admin Protection**: The system prevents modification of the primary admin account (typically user ID 1).

4. **Privilege Escalation Prevention**: Users cannot promote others to types with higher privileges than their own unless they have the `super-admin` role.

5. **Transaction Safety**: Type changes are wrapped in database transactions to ensure data consistency.

6. **Audit Logging**: All type changes are logged for security auditing purposes.

## Usage Examples

### Basic Usage

To include the User Type Manager in a user profile or admin panel:

```php
<div class="user-management-section">
    <livewire:user-type-manager :user="$user" />
</div>
```

### Programmatic Type Change

To change a user's type programmatically in your controllers or services:

```php
public function promoteToManager(User $user)
{
    if (auth()->user()->can('change user types')) {
        try {
            $user->convertToType(\App\Models\Manager::class);
            return redirect()->back()->with('success', 'User promoted to Manager successfully!');
        } catch (\Exception $e) {
            return redirect()->back()->with('error', 'Failed to change user type: ' . $e->getMessage());
        }
    }

    return redirect()->back()->with('error', 'You do not have permission to change user types.');
}
```

## Testing

Here's how to test the User Type Manager component:

### Feature Tests

Create a feature test for the UserTypeManager component to ensure it works correctly:

```php
<?php

namespace Tests\Feature\Livewire;

use App\Livewire\UserTypeManager;use App\Models\Admin;use App\Models\Manager;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use Livewire\Livewire;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class UserTypeManagerTest extends TestCase
{
    use RefreshDatabase;

    protected User $adminUser;
    protected User $regularUser;
    protected User $targetUser;

    public function setUp(): void
    {
        parent::setUp();

        // Create an admin user with permissions
        $this->adminUser = Admin::factory()->create();
        $this->adminUser->assignRole('admin');
        $this->adminUser->givePermissionTo('change user types');

        // Create a regular user without permissions
        $this->regularUser = User::factory()->create();

        // Create a target user to modify
        $this->targetUser = User::factory()->create();
    }

    #[Test]
    public function it_shows_the_confirmation_dialog_when_changing_user_type()
    {
        $this->actingAs($this->adminUser);

        Livewire::test(UserTypeManager::class, ['user' => $this->targetUser])
            ->set('newType', Manager::class)
            ->call('confirmTypeChange')
            ->assertSet('confirmingTypeChange', true)
            ->assertSee('Confirm Type Change')
            ->assertSee('Are you sure you want to change this user\'s type to Manager');
    }

    #[Test]
    public function it_does_not_show_confirmation_dialog_when_selected_type_is_the_same()
    {
        $this->actingAs($this->adminUser);

        Livewire::test(UserTypeManager::class, ['user' => $this->targetUser])
            ->set('newType', User::class) // Same as current type
            ->call('confirmTypeChange')
            ->assertSet('confirmingTypeChange', false); // Should not open dialog
    }

    #[Test]
    public function it_cancels_type_change_when_user_clicks_cancel()
    {
        $this->actingAs($this->adminUser);

        Livewire::test(UserTypeManager::class, ['user' => $this->targetUser])
            ->set('newType', Manager::class)
            ->call('confirmTypeChange')
            ->assertSet('confirmingTypeChange', true)
            ->call('cancelTypeChange')
            ->assertSet('confirmingTypeChange', false)
            ->assertSet('newType', User::class); // Should reset to original value
    }

    #[Test]
    public function it_prevents_regular_users_from_changing_user_types()
    {
        $this->actingAs($this->regularUser); // Regular user without permissions

        Livewire::test(UserTypeManager::class, ['user' => $this->targetUser])
            ->set('newType', Manager::class)
            ->call('confirmTypeChange')
            ->assertSet('confirmingTypeChange', false)
            ->assertHasErrors('newType');
    }

    #[Test]
    public function it_successfully_changes_user_type()
    {
        $this->actingAs($this->adminUser);

        Livewire::test(UserTypeManager::class, ['user' => $this->targetUser])
            ->set('newType', Manager::class)
            ->call('changeType')
            ->assertHasNoErrors();

        // Refresh the user from the database
        $this->targetUser->refresh();

        // Assert the type was changed
        $this->assertEquals(Manager::class, $this->targetUser->type);

        // Assert the user has the correct roles
        $this->assertTrue($this->targetUser->hasRole('manager'));
    }

    #[Test]
    public function it_prevents_changing_primary_admin_type()
    {
        // Create a primary admin (ID 1)
        $primaryAdmin = Admin::factory()->create(['id' => 1]);
        $primaryAdmin->assignRole('super-admin');

        $this->actingAs($this->adminUser);

        Livewire::test(UserTypeManager::class, ['user' => $primaryAdmin])
            ->set('newType', User::class)
            ->call('confirmTypeChange')
            ->assertSet('confirmingTypeChange', false)
            ->assertHasErrors('newType');
    }
}
```

### Unit Tests

Create unit tests for the UserType enum methods:

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
    public function it_returns_correct_default_roles()
    {
        $this->assertEquals(['user'], UserType::USER->defaultRoles());
        $this->assertEquals(['admin', 'super-admin'], UserType::ADMIN->defaultRoles());
        $this->assertEquals(['manager', 'team-lead'], UserType::MANAGER->defaultRoles());
        $this->assertEquals(['practitioner', 'professional'], UserType::PRACTITIONER->defaultRoles());
    }

    #[Test]
    public function it_correctly_determines_privilege_hierarchy()
    {
        // Admin has higher privileges than all others
        $this->assertTrue(UserType::ADMIN->hasHigherPrivilegesThan(UserType::USER));
        $this->assertTrue(UserType::ADMIN->hasHigherPrivilegesThan(UserType::MANAGER));
        $this->assertTrue(UserType::ADMIN->hasHigherPrivilegesThan(UserType::PRACTITIONER));

        // Manager has higher privileges than User and Practitioner
        $this->assertTrue(UserType::MANAGER->hasHigherPrivilegesThan(UserType::USER));
        $this->assertTrue(UserType::MANAGER->hasHigherPrivilegesThan(UserType::PRACTITIONER));
        $this->assertFalse(UserType::MANAGER->hasHigherPrivilegesThan(UserType::ADMIN));

        // Practitioner has higher privileges than User only
        $this->assertTrue(UserType::PRACTITIONER->hasHigherPrivilegesThan(UserType::USER));
        $this->assertFalse(UserType::PRACTITIONER->hasHigherPrivilegesThan(UserType::MANAGER));
        $this->assertFalse(UserType::PRACTITIONER->hasHigherPrivilegesThan(UserType::ADMIN));

        // User has no higher privileges
        $this->assertFalse(UserType::USER->hasHigherPrivilegesThan(UserType::ADMIN));
        $this->assertFalse(UserType::USER->hasHigherPrivilegesThan(UserType::MANAGER));
        $this->assertFalse(UserType::USER->hasHigherPrivilegesThan(UserType::PRACTITIONER));
    }

    #[Test]
    public function it_creates_correct_badge_html()
    {
        // Test that each type generates HTML with the correct class and label
        $this->assertStringContainsString('bg-blue-100', UserType::USER->badge());
        $this->assertStringContainsString('User', UserType::USER->badge());

        $this->assertStringContainsString('bg-red-100', UserType::ADMIN->badge());
        $this->assertStringContainsString('Administrator', UserType::ADMIN->badge());

        $this->assertStringContainsString('bg-amber-100', UserType::MANAGER->badge());
        $this->assertStringContainsString('Manager', UserType::MANAGER->badge());

        $this->assertStringContainsString('bg-emerald-100', UserType::PRACTITIONER->badge());
        $this->assertStringContainsString('Practitioner', UserType::PRACTITIONER->badge());
    }
}
```

## Troubleshooting

Here are solutions to common issues you might encounter when implementing the User Type Management component:

### Issue: Type Changes Not Persisting

**Symptoms**: User type appears to change in the UI but reverts back when the page is refreshed.

**Solutions**:

1. Check that your database transaction is committing properly.
2. Verify that the `save()` method is being called on the user model.
3. Ensure there are no validation rules preventing the type column from being updated.

### Issue: Role Synchronization Failures

**Symptoms**: User type changes, but roles are not updated correctly.

**Solutions**:

1. Verify that the roles defined in `defaultRoles()` actually exist in your database.
2. Check that the `syncRoles()` method is being called correctly.
3. Ensure your Spatie Permission package is properly configured.

### Issue: Permission Errors

**Symptoms**: Users with appropriate permissions still can't change user types.

**Solutions**:

1. Verify that the permission 'change user types' exists and is assigned to the appropriate roles.
2. Check that you're using `auth()->user()->can('change user types')` for permission checks.
3. Ensure the middleware for permissions is properly configured.

### Issue: Security Checks Too Restrictive

**Symptoms**: Legitimate type changes are being blocked by security checks.

**Solutions**:

1. Review the `hasHigherPrivilegesThan()` method to ensure the privilege hierarchy is correct.
2. Adjust the security checks in the `confirmTypeChange()` method if needed.
3. Consider adding a bypass mechanism for super-admins if appropriate.

## Conclusion

The User Type Management component provides a robust and secure way to change user types in your Laravel application. By leveraging the UserType enum and Spatie Permission package, it ensures that user roles and permissions are properly synchronized when a user's type changes.

This component is particularly useful in applications with complex user hierarchies where users may need to be promoted or demoted between different types without losing their account history or having to create new accounts.

## Exercise

Extend the User Type Management component with the following features:

1. Add a history tracking feature that records all type changes for a user.
2. Implement a cooldown period to prevent frequent type changes (e.g., limit to one change per week).
3. Create an approval workflow where type changes require approval from a super-admin before taking effect.
4. Add email notifications to inform users when their type has been changed.
