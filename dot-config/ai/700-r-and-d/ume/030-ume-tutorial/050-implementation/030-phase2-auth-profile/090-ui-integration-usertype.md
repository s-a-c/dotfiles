# UI Integration with UserType

The enhanced UserType enum provides rich UI integration capabilities that can be used to create consistent user interfaces throughout your application. This document outlines how to leverage these features.

## Badges and Labels

The UserType enum provides built-in methods to generate badges and labels with appropriate styling:

### Basic Badge Usage

To display a badge for a user's type in a Blade template:

```php
<div class="user-info">
    <span class="user-name">{{ $user->name }}</span>
    {!! $user->getUserType()?->badge() !!}
</div>
```

This will render a badge with appropriate styling based on the user's type:

- **User**: Blue badge
- **Admin**: Red badge
- **Manager**: Amber badge
- **Practitioner**: Emerald badge

### Custom Badge Styling

You can create custom badges by using the color information from the enum:

```php
@php
    $userType = $user->getUserType();
    $color = $userType ? $userType->color() : 'gray';
@endphp

<span class="px-2 py-1 text-xs font-medium rounded-full bg-{{ $color }}-100 text-{{ $color }}-800 dark:bg-{{ $color }}-900 dark:text-{{ $color }}-300">
    {{ $userType?->label() ?? 'Unknown' }}
</span>
```

## Icons

The UserType enum also provides methods to generate appropriate icons:

```php
<div class="user-card">
    <div class="user-icon">
        {!! $user->getUserType()?->icon() !!}
    </div>
    <div class="user-details">
        <h3>{{ $user->name }}</h3>
        <p>{{ $user->email }}</p>
    </div>
</div>
```

Each user type has a specific icon:

- **User**: `user`
- **Admin**: `shield-check`
- **Manager**: `users`
- **Practitioner**: `briefcase-medical`

## Type Selectors

When creating forms that need to select a user type, you can use the enum to generate options:

```php
<div class="form-group">
    <label for="user_type">User Type</label>
    <select id="user_type" name="user_type" class="form-select">
        @foreach(\App\Enums\UserType::cases() as $type)
            <option value="{{ $type->value }}" @selected($user->type === $type->value)>
                {{ $type->label() }}
            </option>
        @endforeach
    </select>
</div>
```

Or with Livewire:

```php
<x-flux-form-label for="userType" label="User Type" />
<x-flux-select id="userType" wire:model="userType" :options="\App\Enums\UserType::toSelectArray()" />
```

## Type-Based UI Conditionals

You can conditionally show UI elements based on user types using the provided Blade directives:

```php
@userType(\App\Models\Admin::class)
    <div class="admin-panel bg-red-50 p-4 rounded-lg">
        <h3 class="text-red-800 font-bold">Admin Controls</h3>
        <!-- Admin-specific controls -->
    </div>
@enduserType

@userType(\App\Models\Manager::class)
    <div class="manager-panel bg-amber-50 p-4 rounded-lg">
        <h3 class="text-amber-800 font-bold">Team Management</h3>
        <!-- Manager-specific controls -->
    </div>
@enduserType
```

Or using the shorthand directives for common types:

```php
@admin
    <!-- Admin-only content -->
@endadmin
```

## Type-Based Navigation

You can customize navigation menus based on user types:

```php
<nav>
    <ul>
        <li><a href="/dashboard">Dashboard</a></li>

        @if(auth()->user()->isType(\App\Enums\UserType::ADMIN))
            <li><a href="/admin/users">User Management</a></li>
            <li><a href="/admin/settings">System Settings</a></li>
        @endif

        @if(auth()->user()->isType(\App\Enums\UserType::MANAGER))
            <li><a href="/teams">Team Management</a></li>
            <li><a href="/reports">Reports</a></li>
        @endif

        @if(auth()->user()->isType(\App\Enums\UserType::PRACTITIONER))
            <li><a href="/clients">Client Management</a></li>
            <li><a href="/schedule">Schedule</a></li>
        @endif
    </ul>
</nav>
```

## User Type Management UI

The User Type Management component provides a complete UI for changing user types:

```php
<div class="mt-6 p-4 bg-white dark:bg-gray-800 rounded-lg shadow">
    <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100">User Type Management</h3>

    <div class="mt-4">
        <livewire:user-type-manager :user="$user" />
    </div>
</div>
```

## User Type Filters

You can create filters for user listings based on user types:

```php
<div class="filters">
    <h4>Filter by Type</h4>
    <div class="flex space-x-2">
        @foreach(\App\Enums\UserType::cases() as $type)
            <a href="?filter={{ $type->value }}"
               class="px-3 py-1 rounded-full text-xs font-medium {{ request('filter') === $type->value ? 'bg-'.$type->color().'-500 text-white' : 'bg-'.$type->color().'-100 text-'.$type->color().'-800' }}">
                {{ $type->label() }}
            </a>
        @endforeach
    </div>
</div>
```

## User Type Statistics

You can display statistics about user types in dashboards:

```php
<div class="grid grid-cols-4 gap-4">
    @foreach(\App\Enums\UserType::cases() as $type)
        @php
            $count = \App\Models\User::where('type', $type->value)->count();
            $color = $type->color();
        @endphp

        <div class="bg-white dark:bg-gray-800 p-4 rounded-lg shadow">
            <div class="flex items-center">
                <div class="p-3 rounded-full bg-{{ $color }}-100 text-{{ $color }}-800 dark:bg-{{ $color }}-900 dark:text-{{ $color }}-300">
                    {!! $type->icon() !!}
                </div>
                <div class="ml-4">
                    <h3 class="text-lg font-semibold">{{ $type->label() }}</h3>
                    <p class="text-2xl font-bold">{{ $count }}</p>
                </div>
            </div>
        </div>
    @endforeach
</div>
```

## Dark Mode Support

All UI elements generated by the UserType enum include dark mode support through Tailwind's dark mode classes:

```php
{!! $user->getUserType()?->badge() !!}
```

The badge method automatically includes both light and dark mode classes:

```html
<span class="px-2 py-1 text-xs font-medium rounded-full bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300">User</span>
```

## Customizing UI Elements

If you need to customize the default UI elements, you can extend the UserType enum with your own methods:

```php
// In UserType.php

/**
 * Create a custom styled badge for this user type
 */
public function customBadge(): string
{
    $styles = match($this) {
        self::USER => 'border-blue-300 bg-gradient-to-r from-blue-50 to-blue-100',
        self::ADMIN => 'border-red-300 bg-gradient-to-r from-red-50 to-red-100',
        self::MANAGER => 'border-amber-300 bg-gradient-to-r from-amber-50 to-amber-100',
        self::PRACTITIONER => 'border-emerald-300 bg-gradient-to-r from-emerald-50 to-emerald-100',
    };

    return '<span class="px-3 py-1 text-sm font-medium rounded-md border ' . $styles . '">' .
           $this->label() .
           '</span>';
}
```

## Conclusion

The UserType enum provides a rich set of UI integration features that make it easy to create consistent, type-aware user interfaces throughout your application. By leveraging these features, you can create a more intuitive and visually consistent user experience that clearly communicates user roles and permissions.

## Exercise

Extend the UI integration with the following features:

1. Create a user type switcher component that allows users to temporarily view the application as a different user type (for testing purposes)
2. Implement a user type comparison table that shows the differences in permissions between types
3. Create a visual hierarchy diagram that shows the relationship between different user types
4. Implement a user type distribution chart that shows the percentage of users in each type
