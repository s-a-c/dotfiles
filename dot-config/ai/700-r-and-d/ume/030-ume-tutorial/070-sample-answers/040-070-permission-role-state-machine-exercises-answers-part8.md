# Permission/Role State Machine Exercises - Sample Answers (Part 8)

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Exercise 4: Implementing Batch State Transitions (continued)

### Step 3: Create a view for the batch operation results

```blade
<!-- resources/views/admin/permissions/batch-results.blade.php -->
<x-app-layout>
    <x-slot name="header">
        <div class="flex justify-between items-center">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">
                {{ __('Batch Operation Results') }}
            </h2>
            <div>
                <a href="{{ route('admin.permissions.batch') }}" class="inline-flex items-center px-4 py-2 bg-indigo-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-indigo-700 focus:bg-indigo-700 active:bg-indigo-800 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition ease-in-out duration-150 mr-2">
                    {{ __('New Batch Operation') }}
                </a>
                <a href="{{ route('admin.permissions.index') }}" class="inline-flex items-center px-4 py-2 bg-gray-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-gray-700 focus:bg-gray-700 active:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 transition ease-in-out duration-150">
                    {{ __('Back to Permissions') }}
                </a>
            </div>
        </div>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b border-gray-200">
                    <div class="mb-6">
                        <h3 class="text-lg font-medium text-gray-900">{{ __('Batch Operation Summary') }}</h3>
                        <div class="mt-4">
                            <p class="text-sm text-gray-700">
                                {{ __('Successful operations') }}: {{ count($results['success']) }}
                            </p>
                            <p class="text-sm text-gray-700">
                                {{ __('Failed operations') }}: {{ count($results['error']) }}
                            </p>
                        </div>
                    </div>

                    @if (count($results['success']) > 0)
                        <div class="mb-6">
                            <h3 class="text-lg font-medium text-green-600">{{ __('Successful Operations') }}</h3>
                            <div class="mt-4 bg-green-50 p-4 rounded-md">
                                <ul class="list-disc list-inside text-sm text-green-700">
                                    @foreach ($results['success'] as $message)
                                        <li>{{ $message }}</li>
                                    @endforeach
                                </ul>
                            </div>
                        </div>
                    @endif

                    @if (count($results['error']) > 0)
                        <div class="mb-6">
                            <h3 class="text-lg font-medium text-red-600">{{ __('Failed Operations') }}</h3>
                            <div class="mt-4 bg-red-50 p-4 rounded-md">
                                <ul class="list-disc list-inside text-sm text-red-700">
                                    @foreach ($results['error'] as $message)
                                        <li>{{ $message }}</li>
                                    @endforeach
                                </ul>
                            </div>
                        </div>
                    @endif
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
```

### Step 4: Add routes for the batch operations

```php
// routes/web.php
Route::middleware(['auth', 'can:manage-permissions'])->prefix('admin')->name('admin.')->group(function () {
    // ... existing routes ...
    
    // Batch permission operations
    Route::get('permissions/batch', [App\Http\Controllers\Admin\BatchPermissionController::class, 'index'])
        ->name('permissions.batch');
    Route::post('permissions/batch/process', [App\Http\Controllers\Admin\BatchPermissionController::class, 'process'])
        ->name('permissions.batch.process');
});
```

## Exercise 5: Creating a Permission Approval Workflow

### Step 1: Update the PermissionStatus enum to include additional approval states

```php
<?php

declare(strict_types=1);

namespace App\Enums;

enum PermissionStatus: string
{
    case DRAFT = 'draft';
    case PENDING_FIRST_APPROVAL = 'pending_first_approval';
    case PENDING_SECOND_APPROVAL = 'pending_second_approval';
    case ACTIVE = 'active';
    case DISABLED = 'disabled';
    case DEPRECATED = 'deprecated';

    /**
     * Get a human-readable label for the status.
     */
    public function getLabel(): string
    {
        return match($this) {
            self::DRAFT => 'Draft',
            self::PENDING_FIRST_APPROVAL => 'Pending First Approval',
            self::PENDING_SECOND_APPROVAL => 'Pending Second Approval',
            self::ACTIVE => 'Active',
            self::DISABLED => 'Disabled',
            self::DEPRECATED => 'Deprecated',
        };
    }

    /**
     * Get a color for the status (for UI purposes).
     */
    public function getColor(): string
    {
        return match($this) {
            self::DRAFT => 'yellow',
            self::PENDING_FIRST_APPROVAL => 'blue',
            self::PENDING_SECOND_APPROVAL => 'purple',
            self::ACTIVE => 'green',
            self::DISABLED => 'red',
            self::DEPRECATED => 'gray',
        };
    }

    /**
     * Get an icon for the status (for UI purposes).
     */
    public function getIcon(): string
    {
        return match($this) {
            self::DRAFT => 'pencil',
            self::PENDING_FIRST_APPROVAL => 'clock',
            self::PENDING_SECOND_APPROVAL => 'clipboard-check',
            self::ACTIVE => 'check-circle',
            self::DISABLED => 'ban',
            self::DEPRECATED => 'archive',
        };
    }

    /**
     * Get Tailwind CSS classes for the status.
     */
    public function getTailwindClasses(): string
    {
        return match($this) {
            self::DRAFT => 'bg-yellow-100 text-yellow-800 border-yellow-200',
            self::PENDING_FIRST_APPROVAL => 'bg-blue-100 text-blue-800 border-blue-200',
            self::PENDING_SECOND_APPROVAL => 'bg-purple-100 text-purple-800 border-purple-200',
            self::ACTIVE => 'bg-green-100 text-green-800 border-green-200',
            self::DISABLED => 'bg-red-100 text-red-800 border-red-200',
            self::DEPRECATED => 'bg-gray-100 text-gray-800 border-gray-200',
        };
    }
}
```
