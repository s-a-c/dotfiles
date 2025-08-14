# Permission/Role State Machine Exercises - Sample Answers (Part 5)

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Exercise 3: Creating a Permission History Feature (continued)

### Step 5: Create a controller method to display the history of a permission

```php
<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\UPermission;
use Illuminate\Http\Request;

class PermissionHistoryController extends Controller
{
    /**
     * Display the history of a permission.
     */
    public function show(UPermission $permission)
    {
        $history = $permission->history()
            ->with('user')
            ->orderBy('created_at', 'desc')
            ->paginate(10);
        
        return view('admin.permissions.history', compact('permission', 'history'));
    }
}
```

### Step 6: Create a view to display the permission history

```blade
<!-- resources/views/admin/permissions/history.blade.php -->
<x-app-layout>
    <x-slot name="header">
        <div class="flex justify-between items-center">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">
                {{ __('Permission History') }}: {{ $permission->name }}
            </h2>
            <a href="{{ route('admin.permissions.show', $permission) }}" class="inline-flex items-center px-4 py-2 bg-gray-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-gray-700 focus:bg-gray-700 active:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 transition ease-in-out duration-150">
                {{ __('Back to Permission') }}
            </a>
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
                                <p class="text-sm font-medium text-gray-500">{{ __('Current Status') }}</p>
                                <p class="mt-1">
                                    <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full {{ $permission->status->tailwindClasses() }}">
                                        {{ $permission->status->label() }}
                                    </span>
                                </p>
                            </div>
                        </div>
                    </div>

                    <div class="mt-8">
                        <h3 class="text-lg font-medium text-gray-900">{{ __('History') }}</h3>
                        <div class="mt-4 overflow-x-auto">
                            <table class="min-w-full divide-y divide-gray-200">
                                <thead class="bg-gray-50">
                                    <tr>
                                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                            {{ __('Date') }}
                                        </th>
                                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                            {{ __('User') }}
                                        </th>
                                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                            {{ __('Transition') }}
                                        </th>
                                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                            {{ __('From') }}
                                        </th>
                                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                            {{ __('To') }}
                                        </th>
                                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                            {{ __('Notes') }}
                                        </th>
                                    </tr>
                                </thead>
                                <tbody class="bg-white divide-y divide-gray-200">
                                    @foreach ($history as $entry)
                                        <tr>
                                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                                {{ $entry->created_at->format('Y-m-d H:i:s') }}
                                            </td>
                                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                                {{ $entry->user ? $entry->user->name : 'System' }}
                                            </td>
                                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                                {{ ucfirst($entry->transition_type) }}
                                            </td>
                                            <td class="px-6 py-4 whitespace-nowrap">
                                                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full {{ App\Enums\PermissionStatus::from($entry->from_state)->getTailwindClasses() }}">
                                                    {{ App\Enums\PermissionStatus::from($entry->from_state)->getLabel() }}
                                                </span>
                                            </td>
                                            <td class="px-6 py-4 whitespace-nowrap">
                                                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full {{ App\Enums\PermissionStatus::from($entry->to_state)->getTailwindClasses() }}">
                                                    {{ App\Enums\PermissionStatus::from($entry->to_state)->getLabel() }}
                                                </span>
                                            </td>
                                            <td class="px-6 py-4 text-sm text-gray-500">
                                                {{ $entry->notes }}
                                            </td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>

                        <div class="mt-4">
                            {{ $history->links() }}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
```

### Step 7: Add a route for the history controller

```php
// routes/web.php
Route::middleware(['auth', 'can:manage-permissions'])->prefix('admin')->name('admin.')->group(function () {
    // ... existing routes ...
    
    // Permission history route
    Route::get('permissions/{permission}/history', [App\Http\Controllers\Admin\PermissionHistoryController::class, 'show'])
        ->name('permissions.history');
});
```
