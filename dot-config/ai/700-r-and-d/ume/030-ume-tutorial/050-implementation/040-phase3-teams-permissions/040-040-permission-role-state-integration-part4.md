# Permission/Role State Integration (Part 4)

<link rel="stylesheet" href="../../../assets/css/styles.css">

### Role Policy

```php
<?php

namespace App\Policies;

use App\Models\URole;
use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

class RolePolicy
{
    use HandlesAuthorization;

    /**
     * Determine whether the user can view any models.
     */
    public function viewAny(User $user): bool
    {
        return $user->hasPermissionTo('manage-roles');
    }

    /**
     * Determine whether the user can view the model.
     */
    public function view(User $user, URole $role): bool
    {
        if ($user->hasPermissionTo('manage-roles')) {
            return true;
        }

        return $role->isVisibleInUI();
    }

    /**
     * Determine whether the user can create models.
     */
    public function create(User $user): bool
    {
        return $user->hasPermissionTo('manage-roles');
    }

    /**
     * Determine whether the user can update the model.
     */
    public function update(User $user, URole $role): bool
    {
        return $user->hasPermissionTo('manage-roles') && $role->canBeModified();
    }

    /**
     * Determine whether the user can delete the model.
     */
    public function delete(User $user, URole $role): bool
    {
        return $user->hasPermissionTo('manage-roles') && $role->canBeDeleted();
    }

    /**
     * Determine whether the user can approve the role.
     */
    public function approve(User $user, URole $role): bool
    {
        return $user->hasPermissionTo('manage-roles');
    }

    /**
     * Determine whether the user can disable the role.
     */
    public function disable(User $user, URole $role): bool
    {
        return $user->hasPermissionTo('manage-roles');
    }

    /**
     * Determine whether the user can enable the role.
     */
    public function enable(User $user, URole $role): bool
    {
        return $user->hasPermissionTo('manage-roles');
    }

    /**
     * Determine whether the user can deprecate the role.
     */
    public function deprecate(User $user, URole $role): bool
    {
        return $user->hasPermissionTo('manage-roles');
    }
}
```

## Registering the Policies

Register the policies in the `app/Providers/AuthServiceProvider.php` file:

```php
protected $policies = [
    // ... other policies
    \App\Models\UPermission::class => \App\Policies\PermissionPolicy::class,
    \App\Models\URole::class => \App\Policies\RolePolicy::class,
];
```

## Creating Views for Permission Management

Let's create the views for managing permissions. First, let's create the index view:

```blade
<!-- resources/views/admin/permissions/index.blade.php -->
<x-app-layout>
    <x-slot name="header">
        <div class="flex justify-between items-center">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">
                {{ __('Permissions') }}
            </h2>
            <a href="{{ route('admin.permissions.create') }}" class="inline-flex items-center px-4 py-2 bg-blue-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-blue-700 focus:bg-blue-700 active:bg-blue-800 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition ease-in-out duration-150">
                {{ __('Create Permission') }}
            </a>
        </div>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b border-gray-200">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    {{ __('Name') }}
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    {{ __('Guard') }}
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    {{ __('Status') }}
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    {{ __('Team') }}
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    {{ __('Actions') }}
                                </th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            @foreach ($permissions as $permission)
                                <tr>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <div class="text-sm font-medium text-gray-900">
                                            {{ $permission->name }}
                                        </div>
                                        @if ($permission->description)
                                            <div class="text-sm text-gray-500">
                                                {{ $permission->description }}
                                            </div>
                                        @endif
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <div class="text-sm text-gray-900">{{ $permission->guard_name }}</div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full {{ $permission->status->tailwindClasses() }}">
                                            {{ $permission->status->label() }}
                                        </span>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <div class="text-sm text-gray-900">
                                            {{ $permission->team_id ? $permission->team->name : 'Global' }}
                                        </div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                        <a href="{{ route('admin.permissions.show', $permission) }}" class="text-blue-600 hover:text-blue-900 mr-2">
                                            {{ __('View') }}
                                        </a>
                                        @if ($permission->canBeModified())
                                            <a href="{{ route('admin.permissions.edit', $permission) }}" class="text-indigo-600 hover:text-indigo-900 mr-2">
                                                {{ __('Edit') }}
                                            </a>
                                        @endif
                                        @if ($permission->canBeDeleted())
                                            <form action="{{ route('admin.permissions.destroy', $permission) }}" method="POST" class="inline">
                                                @csrf
                                                @method('DELETE')
                                                <button type="submit" class="text-red-600 hover:text-red-900" onclick="return confirm('Are you sure you want to delete this permission?')">
                                                    {{ __('Delete') }}
                                                </button>
                                            </form>
                                        @endif
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
```

Now, let's create the show view for permissions:

```blade
<!-- resources/views/admin/permissions/show.blade.php -->
<x-app-layout>
    <x-slot name="header">
        <div class="flex justify-between items-center">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">
                {{ __('Permission Details') }}
            </h2>
            <div>
                @if ($permission->canBeModified())
                    <a href="{{ route('admin.permissions.edit', $permission) }}" class="inline-flex items-center px-4 py-2 bg-indigo-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-indigo-700 focus:bg-indigo-700 active:bg-indigo-800 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition ease-in-out duration-150 mr-2">
                        {{ __('Edit') }}
                    </a>
                @endif
                <a href="{{ route('admin.permissions.index') }}" class="inline-flex items-center px-4 py-2 bg-gray-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-gray-700 focus:bg-gray-700 active:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 transition ease-in-out duration-150">
                    {{ __('Back to List') }}
                </a>
            </div>
        </div>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b border-gray-200">
                    <div class="mb-6">
                        <h3 class="text-lg font-medium text-gray-900">{{ __('Permission Information') }}</h3>
                        <div class="mt-4 grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                                <p class="text-sm font-medium text-gray-500">{{ __('Name') }}</p>
                                <p class="mt-1 text-sm text-gray-900">{{ $permission->name }}</p>
                            </div>
                            <div>
                                <p class="text-sm font-medium text-gray-500">{{ __('Guard') }}</p>
                                <p class="mt-1 text-sm text-gray-900">{{ $permission->guard_name }}</p>
                            </div>
                            <div>
                                <p class="text-sm font-medium text-gray-500">{{ __('Status') }}</p>
                                <p class="mt-1">
                                    <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full {{ $permission->status->tailwindClasses() }}">
                                        {{ $permission->status->label() }}
                                    </span>
                                </p>
                            </div>
                            <div>
                                <p class="text-sm font-medium text-gray-500">{{ __('Team') }}</p>
                                <p class="mt-1 text-sm text-gray-900">
                                    {{ $permission->team_id ? $permission->team->name : 'Global' }}
                                </p>
                            </div>
                            @if ($permission->description)
                                <div class="col-span-2">
                                    <p class="text-sm font-medium text-gray-500">{{ __('Description') }}</p>
                                    <p class="mt-1 text-sm text-gray-900">{{ $permission->description }}</p>
                                </div>
                            @endif
                        </div>
                    </div>

                    <div class="mt-8 border-t pt-6">
                        <h3 class="text-lg font-medium text-gray-900">{{ __('State Actions') }}</h3>
                        <div class="mt-4 flex flex-wrap gap-4">
                            @if ($permission->status instanceof \App\States\Permission\Draft)
                                <form action="{{ route('admin.permissions.approve', $permission) }}" method="POST">
                                    @csrf
                                    <button type="submit" class="inline-flex items-center px-4 py-2 bg-green-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-green-700 focus:bg-green-700 active:bg-green-800 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 transition ease-in-out duration-150">
                                        {{ __('Approve') }}
                                    </button>
                                </form>
                            @endif

                            @if ($permission->status instanceof \App\States\Permission\Active)
                                <form action="{{ route('admin.permissions.disable', $permission) }}" method="POST" class="inline">
                                    @csrf
                                    <input type="hidden" name="reason" value="Administrative action">
                                    <button type="submit" class="inline-flex items-center px-4 py-2 bg-yellow-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-yellow-700 focus:bg-yellow-700 active:bg-yellow-800 focus:outline-none focus:ring-2 focus:ring-yellow-500 focus:ring-offset-2 transition ease-in-out duration-150">
                                        {{ __('Disable') }}
                                    </button>
                                </form>
                            @endif

                            @if ($permission->status instanceof \App\States\Permission\Disabled)
                                <form action="{{ route('admin.permissions.enable', $permission) }}" method="POST" class="inline">
                                    @csrf
                                    <button type="submit" class="inline-flex items-center px-4 py-2 bg-green-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-green-700 focus:bg-green-700 active:bg-green-800 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 transition ease-in-out duration-150">
                                        {{ __('Enable') }}
                                    </button>
                                </form>
                            @endif

                            @if ($permission->status instanceof \App\States\Permission\Active || $permission->status instanceof \App\States\Permission\Disabled)
                                <form action="{{ route('admin.permissions.deprecate', $permission) }}" method="POST" class="inline">
                                    @csrf
                                    <input type="hidden" name="reason" value="No longer needed">
                                    <button type="submit" class="inline-flex items-center px-4 py-2 bg-gray-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-gray-700 focus:bg-gray-700 active:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 transition ease-in-out duration-150">
                                        {{ __('Deprecate') }}
                                    </button>
                                </form>
                            @endif

                            @if ($permission->canBeDeleted())
                                <form action="{{ route('admin.permissions.destroy', $permission) }}" method="POST" class="inline">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="inline-flex items-center px-4 py-2 bg-red-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-red-700 focus:bg-red-700 active:bg-red-800 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition ease-in-out duration-150" onclick="return confirm('Are you sure you want to delete this permission?')">
                                        {{ __('Delete') }}
                                    </button>
                                </form>
                            @endif
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
```
