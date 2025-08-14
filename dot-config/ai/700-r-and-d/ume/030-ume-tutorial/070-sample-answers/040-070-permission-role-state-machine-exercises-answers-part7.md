# Permission/Role State Machine Exercises - Sample Answers (Part 7)

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Exercise 4: Implementing Batch State Transitions (continued)

### Step 2: Create a view for the batch operations form

```blade
<!-- resources/views/admin/permissions/batch.blade.php -->
<x-app-layout>
    <x-slot name="header">
        <div class="flex justify-between items-center">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">
                {{ __('Batch Permission Operations') }}
            </h2>
            <a href="{{ route('admin.permissions.index') }}" class="inline-flex items-center px-4 py-2 bg-gray-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-gray-700 focus:bg-gray-700 active:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 transition ease-in-out duration-150">
                {{ __('Back to Permissions') }}
            </a>
        </div>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b border-gray-200">
                    <form action="{{ route('admin.permissions.batch.process') }}" method="POST">
                        @csrf

                        <div class="mb-6">
                            <h3 class="text-lg font-medium text-gray-900">{{ __('Select Permissions') }}</h3>
                            <div class="mt-4 grid grid-cols-1 md:grid-cols-3 gap-4">
                                @foreach ($permissions as $permission)
                                    <div class="flex items-center">
                                        <input type="checkbox" name="permissions[]" id="permission-{{ $permission->id }}" value="{{ $permission->id }}" class="rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50">
                                        <label for="permission-{{ $permission->id }}" class="ml-2 text-sm text-gray-700">
                                            {{ $permission->name }}
                                            <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full {{ $permission->status->tailwindClasses() }}">
                                                {{ $permission->status->label() }}
                                            </span>
                                        </label>
                                    </div>
                                @endforeach
                            </div>
                            @error('permissions')
                                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                            @enderror
                        </div>

                        <div class="mb-6">
                            <h3 class="text-lg font-medium text-gray-900">{{ __('Select Action') }}</h3>
                            <div class="mt-4">
                                <div class="flex items-center mb-2">
                                    <input type="radio" name="action" id="action-approve" value="approve" class="rounded-full border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50">
                                    <label for="action-approve" class="ml-2 text-sm text-gray-700">{{ __('Approve') }}</label>
                                </div>
                                <div class="flex items-center mb-2">
                                    <input type="radio" name="action" id="action-disable" value="disable" class="rounded-full border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50">
                                    <label for="action-disable" class="ml-2 text-sm text-gray-700">{{ __('Disable') }}</label>
                                </div>
                                <div class="flex items-center mb-2">
                                    <input type="radio" name="action" id="action-enable" value="enable" class="rounded-full border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50">
                                    <label for="action-enable" class="ml-2 text-sm text-gray-700">{{ __('Enable') }}</label>
                                </div>
                                <div class="flex items-center">
                                    <input type="radio" name="action" id="action-deprecate" value="deprecate" class="rounded-full border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50">
                                    <label for="action-deprecate" class="ml-2 text-sm text-gray-700">{{ __('Deprecate') }}</label>
                                </div>
                            </div>
                            @error('action')
                                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                            @enderror
                        </div>

                        <div class="mb-6">
                            <label for="reason" class="block text-sm font-medium text-gray-700">{{ __('Reason (required for Disable and Deprecate)') }}</label>
                            <input type="text" name="reason" id="reason" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" value="{{ old('reason') }}">
                            @error('reason')
                                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                            @enderror
                        </div>

                        <div class="mb-6">
                            <label for="notes" class="block text-sm font-medium text-gray-700">{{ __('Notes') }}</label>
                            <textarea name="notes" id="notes" rows="3" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm">{{ old('notes') }}</textarea>
                            @error('notes')
                                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                            @enderror
                        </div>

                        <div class="mt-6">
                            <button type="submit" class="inline-flex items-center px-4 py-2 bg-blue-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-blue-700 focus:bg-blue-700 active:bg-blue-800 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition ease-in-out duration-150">
                                {{ __('Process Batch') }}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
```
