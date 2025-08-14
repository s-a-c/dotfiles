# Permission/Role State Integration (Part 5)

<link rel="stylesheet" href="../../../assets/css/styles.css">

Let's create the create and edit views for permissions:

```blade
<!-- resources/views/admin/permissions/create.blade.php -->
<x-app-layout>
    <x-slot name="header">
        <div class="flex justify-between items-center">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">
                {{ __('Create Permission') }}
            </h2>
            <a href="{{ route('admin.permissions.index') }}" class="inline-flex items-center px-4 py-2 bg-gray-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-gray-700 focus:bg-gray-700 active:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 transition ease-in-out duration-150">
                {{ __('Back to List') }}
            </a>
        </div>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b border-gray-200">
                    <form action="{{ route('admin.permissions.store') }}" method="POST">
                        @csrf

                        <div class="mb-4">
                            <label for="name" class="block text-sm font-medium text-gray-700">{{ __('Name') }}</label>
                            <input type="text" name="name" id="name" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" value="{{ old('name') }}" required>
                            @error('name')
                                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                            @enderror
                        </div>

                        <div class="mb-4">
                            <label for="guard_name" class="block text-sm font-medium text-gray-700">{{ __('Guard Name') }}</label>
                            <input type="text" name="guard_name" id="guard_name" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" value="{{ old('guard_name', 'web') }}" required>
                            @error('guard_name')
                                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                            @enderror
                        </div>

                        <div class="mb-4">
                            <label for="description" class="block text-sm font-medium text-gray-700">{{ __('Description') }}</label>
                            <textarea name="description" id="description" rows="3" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm">{{ old('description') }}</textarea>
                            @error('description')
                                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                            @enderror
                        </div>

                        <div class="mb-4">
                            <label for="team_id" class="block text-sm font-medium text-gray-700">{{ __('Team') }}</label>
                            <select name="team_id" id="team_id" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm">
                                <option value="">{{ __('Global (No Team)') }}</option>
                                @foreach (\App\Models\Team::all() as $team)
                                    <option value="{{ $team->id }}" {{ old('team_id') == $team->id ? 'selected' : '' }}>
                                        {{ $team->name }}
                                    </option>
                                @endforeach
                            </select>
                            @error('team_id')
                                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                            @enderror
                        </div>

                        <div class="mt-6">
                            <button type="submit" class="inline-flex items-center px-4 py-2 bg-blue-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-blue-700 focus:bg-blue-700 active:bg-blue-800 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition ease-in-out duration-150">
                                {{ __('Create Permission') }}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
```

```blade
<!-- resources/views/admin/permissions/edit.blade.php -->
<x-app-layout>
    <x-slot name="header">
        <div class="flex justify-between items-center">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">
                {{ __('Edit Permission') }}
            </h2>
            <div>
                <a href="{{ route('admin.permissions.show', $permission) }}" class="inline-flex items-center px-4 py-2 bg-indigo-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-indigo-700 focus:bg-indigo-700 active:bg-indigo-800 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition ease-in-out duration-150 mr-2">
                    {{ __('View') }}
                </a>
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
                    <form action="{{ route('admin.permissions.update', $permission) }}" method="POST">
                        @csrf
                        @method('PUT')

                        <div class="mb-4">
                            <label for="name" class="block text-sm font-medium text-gray-700">{{ __('Name') }}</label>
                            <input type="text" name="name" id="name" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" value="{{ old('name', $permission->name) }}" required>
                            @error('name')
                                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                            @enderror
                        </div>

                        <div class="mb-4">
                            <label for="guard_name" class="block text-sm font-medium text-gray-700">{{ __('Guard Name') }}</label>
                            <input type="text" name="guard_name" id="guard_name" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" value="{{ old('guard_name', $permission->guard_name) }}" required>
                            @error('guard_name')
                                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                            @enderror
                        </div>

                        <div class="mb-4">
                            <label for="description" class="block text-sm font-medium text-gray-700">{{ __('Description') }}</label>
                            <textarea name="description" id="description" rows="3" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm">{{ old('description', $permission->description) }}</textarea>
                            @error('description')
                                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                            @enderror
                        </div>

                        <div class="mb-4">
                            <label for="team_id" class="block text-sm font-medium text-gray-700">{{ __('Team') }}</label>
                            <select name="team_id" id="team_id" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm">
                                <option value="">{{ __('Global (No Team)') }}</option>
                                @foreach (\App\Models\Team::all() as $team)
                                    <option value="{{ $team->id }}" {{ old('team_id', $permission->team_id) == $team->id ? 'selected' : '' }}>
                                        {{ $team->name }}
                                    </option>
                                @endforeach
                            </select>
                            @error('team_id')
                                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                            @enderror
                        </div>

                        <div class="mt-6">
                            <button type="submit" class="inline-flex items-center px-4 py-2 bg-blue-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-blue-700 focus:bg-blue-700 active:bg-blue-800 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition ease-in-out duration-150">
                                {{ __('Update Permission') }}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
```

## Integration with Filament

If you're using Filament for your admin panel, you can integrate the permission and role state machines with Filament resources:

```php
<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PermissionResource\Pages;
use App\Models\UPermission;
use App\States\Permission\Active;
use App\States\Permission\Deprecated;
use App\States\Permission\Disabled;
use App\States\Permission\Draft;
use App\States\Permission\Transitions\ApprovePermissionTransition;
use App\States\Permission\Transitions\DeprecatePermissionTransition;
use App\States\Permission\Transitions\DisablePermissionTransition;
use App\States\Permission\Transitions\EnablePermissionTransition;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class PermissionResource extends Resource
{
    protected static ?string $model = UPermission::class;

    protected static ?string $navigationIcon = 'heroicon-o-key';

    protected static ?string $navigationGroup = 'Access Management';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::make('name')
                    ->required()
                    ->maxLength(255),
                Forms\Components\TextInput::make('guard_name')
                    ->required()
                    ->default('web')
                    ->maxLength(255),
                Forms\Components\Textarea::make('description')
                    ->maxLength(65535),
                Forms\Components\Select::make('team_id')
                    ->label('Team')
                    ->relationship('team', 'name')
                    ->preload()
                    ->placeholder('Global (No Team)'),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('name')
                    ->searchable(),
                Tables\Columns\TextColumn::make('guard_name')
                    ->searchable(),
                Tables\Columns\TextColumn::make('status')
                    ->formatStateUsing(fn (UPermission $record) => $record->status->label())
                    ->badge()
                    ->color(fn (UPermission $record) => $record->status->color()),
                Tables\Columns\TextColumn::make('team.name')
                    ->label('Team')
                    ->placeholder('Global'),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('updated_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        'draft' => 'Draft',
                        'active' => 'Active',
                        'disabled' => 'Disabled',
                        'deprecated' => 'Deprecated',
                    ]),
                Tables\Filters\SelectFilter::make('team_id')
                    ->label('Team')
                    ->relationship('team', 'name')
                    ->preload()
                    ->placeholder('Global (No Team)'),
            ])
            ->actions([
                Tables\Actions\Action::make('approve')
                    ->visible(fn (UPermission $record) => $record->status instanceof Draft)
                    ->color('success')
                    ->icon('heroicon-o-check')
                    ->requiresConfirmation()
                    ->action(function (UPermission $record) {
                        $record->status->transition(new ApprovePermissionTransition(auth()->user()));
                        $record->save();
                    }),
                Tables\Actions\Action::make('disable')
                    ->visible(fn (UPermission $record) => $record->status instanceof Active)
                    ->color('warning')
                    ->icon('heroicon-o-ban')
                    ->requiresConfirmation()
                    ->form([
                        Forms\Components\TextInput::make('reason')
                            ->label('Reason')
                            ->required(),
                        Forms\Components\Textarea::make('notes')
                            ->label('Notes'),
                    ])
                    ->action(function (UPermission $record, array $data) {
                        $record->status->transition(new DisablePermissionTransition(
                            auth()->user(),
                            $data['reason'],
                            $data['notes'] ?? null
                        ));
                        $record->save();
                    }),
                Tables\Actions\Action::make('enable')
                    ->visible(fn (UPermission $record) => $record->status instanceof Disabled)
                    ->color('success')
                    ->icon('heroicon-o-check')
                    ->requiresConfirmation()
                    ->action(function (UPermission $record) {
                        $record->status->transition(new EnablePermissionTransition(auth()->user()));
                        $record->save();
                    }),
                Tables\Actions\Action::make('deprecate')
                    ->visible(fn (UPermission $record) => $record->status instanceof Active || $record->status instanceof Disabled)
                    ->color('gray')
                    ->icon('heroicon-o-archive-box')
                    ->requiresConfirmation()
                    ->form([
                        Forms\Components\TextInput::make('reason')
                            ->label('Reason')
                            ->required(),
                        Forms\Components\Textarea::make('notes')
                            ->label('Notes'),
                    ])
                    ->action(function (UPermission $record, array $data) {
                        $record->status->transition(new DeprecatePermissionTransition(
                            auth()->user(),
                            $data['reason'],
                            $data['notes'] ?? null
                        ));
                        $record->save();
                    }),
                Tables\Actions\ViewAction::make(),
                Tables\Actions\EditAction::make()
                    ->visible(fn (UPermission $record) => $record->canBeModified()),
                Tables\Actions\DeleteAction::make()
                    ->visible(fn (UPermission $record) => $record->canBeDeleted()),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListPermissions::route('/'),
            'create' => Pages\CreatePermission::route('/create'),
            'edit' => Pages\EditPermission::route('/{record}/edit'),
            'view' => Pages\ViewPermission::route('/{record}'),
        ];
    }
}
```

## Next Steps

Now that we've integrated the permission and role state machines with our application, let's move on to testing the state machines in the [next section](./024-permission-role-state-testing.md).

## Additional Resources

- [Spatie Laravel Model States Documentation](https://spatie.be/docs/laravel-model-states/v2/introduction)
- [Spatie Laravel Permission Documentation](https://spatie.be/docs/laravel-permission/v5/introduction)
- [Laravel Blade Documentation](https://laravel.com/docs/12.x/blade)
- [Filament Documentation](https://filamentphp.com/docs)
