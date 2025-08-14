# 11. Users Resource

> **Created:** 2025-07-16  
> **Focus:** User management with RBAC integration and authentication controls  
> **Source:** [Laravel User Model](https://github.com/s-a-c/chinook/blob/main/app/Models/User.php)

## 11.1. Table of Contents

- [11.2. Overview](#112-overview)
- [11.3. Resource Implementation](#113-resource-implementation)
  - [11.3.1. Basic Resource Structure](#1131-basic-resource-structure)
  - [11.3.2. Form Schema](#1132-form-schema)
  - [11.3.3. Table Configuration](#1133-table-configuration)
- [11.4. RBAC Integration](#114-rbac-integration)
- [11.5. Authentication Controls](#115-authentication-controls)
- [11.6. Advanced Features](#116-advanced-features)
- [11.7. Testing Examples](#117-testing-examples)

## 11.2. Overview

The Users Resource provides comprehensive management of system users within the Chinook admin panel. It features complete CRUD operations, role-based access control (RBAC) integration, permission management, and authentication controls for admin panel access.

### 11.2.1. Key Features

- **Complete CRUD Operations**: Create, read, update, delete users with validation
- **RBAC Integration**: Role and permission management using spatie/laravel-permission
- **Authentication Controls**: Password management and account status controls
- **Profile Management**: User profile information and preferences
- **Activity Tracking**: User activity logging and session management
- **Security Features**: Two-factor authentication and password policies

### 11.2.2. Model Integration

<augment_code_snippet path="app/Models/User.php" mode="EXCERPT">
````php
<?php

namespace App\Models;

use Aliziodev\LaravelTaxonomy\Traits\HasTaxonomy;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable
{
    use HasFactory;
    use HasRoles;
    use HasTaxonomy;
    use Notifiable;

    /**
     * The attributes that are mass assignable.
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'email_verified_at',
        'is_active',
        'last_login_at',
        'profile_photo_path',
    ];

    /**
     * The attributes that should be hidden for serialization.
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_active' => 'boolean',
            'last_login_at' => 'datetime',
        ];
    }
}
````
</augment_code_snippet>

## 11.3. Resource Implementation

### 11.3.1. Basic Resource Structure

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/UserResource.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Filament\ChinookAdmin\Resources;

use App\Models\User;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Role;

class UserResource extends Resource
{
    protected static ?string $model = User::class;
    
    protected static ?string $navigationIcon = 'heroicon-o-users';
    
    protected static ?string $navigationGroup = 'Administration';
    
    protected static ?int $navigationSort = 2;
    
    protected static ?string $recordTitleAttribute = 'name';
    
    protected static ?string $globalSearchResultsLimit = 20;
````
</augment_code_snippet>

### 11.3.2. Form Schema

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/UserResource.php" mode="EXCERPT">
````php
public static function form(Form $form): Form
{
    return $form
        ->schema([
            Forms\Components\Section::make('User Information')
                ->schema([
                    Forms\Components\TextInput::make('name')
                        ->required()
                        ->maxLength(255),
                        
                    Forms\Components\TextInput::make('email')
                        ->email()
                        ->required()
                        ->maxLength(255)
                        ->unique(ignoreRecord: true),
                        
                    Forms\Components\FileUpload::make('profile_photo_path')
                        ->label('Profile Photo')
                        ->image()
                        ->imageEditor()
                        ->imageEditorAspectRatios(['1:1'])
                        ->directory('profile-photos')
                        ->visibility('private')
                        ->maxSize(2048),
                        
                    Forms\Components\Toggle::make('is_active')
                        ->label('Active')
                        ->default(true)
                        ->helperText('Inactive users cannot access the admin panel'),
                ])
                ->columns(2),
                
            Forms\Components\Section::make('Password')
                ->schema([
                    Forms\Components\TextInput::make('password')
                        ->password()
                        ->dehydrateStateUsing(fn ($state) => 
                            filled($state) ? Hash::make($state) : null
                        )
                        ->dehydrated(fn ($state) => filled($state))
                        ->required(fn (string $context): bool => $context === 'create')
                        ->minLength(8)
                        ->rules(['confirmed'])
                        ->helperText('Leave blank to keep current password'),
                        
                    Forms\Components\TextInput::make('password_confirmation')
                        ->password()
                        ->dehydrated(false)
                        ->required(fn (callable $get): bool => filled($get('password'))),
                ])
                ->columns(2)
                ->hiddenOn('view'),
                
            Forms\Components\Section::make('Roles & Permissions')
                ->schema([
                    Forms\Components\CheckboxList::make('roles')
                        ->relationship('roles', 'name')
                        ->options(Role::all()->pluck('name', 'name'))
                        ->descriptions(
                            Role::all()->pluck('name', 'name')->map(fn ($role) => 
                                "Assign {$role} role to this user"
                            )
                        )
                        ->columns(2),
                        
                    Forms\Components\Placeholder::make('permissions_info')
                        ->label('Permissions')
                        ->content('Permissions are inherited from assigned roles. Use roles for permission management.')
                        ->hiddenOn('create'),
                ])
                ->collapsible(),
                
            Forms\Components\Section::make('Account Status')
                ->schema([
                    Forms\Components\Placeholder::make('email_verified_at')
                        ->label('Email Verified')
                        ->content(fn (User $record): string => 
                            $record->email_verified_at ? 
                            $record->email_verified_at->format('M j, Y g:i A') : 
                            'Not verified'
                        ),
                        
                    Forms\Components\Placeholder::make('last_login_at')
                        ->label('Last Login')
                        ->content(fn (User $record): string => 
                            $record->last_login_at ? 
                            $record->last_login_at->format('M j, Y g:i A') : 
                            'Never'
                        ),
                ])
                ->columns(2)
                ->hiddenOn('create'),
        ]);
}
````
</augment_code_snippet>

### 11.3.3. Table Configuration

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/UserResource.php" mode="EXCERPT">
````php
public static function table(Table $table): Table
{
    return $table
        ->columns([
            Tables\Columns\ImageColumn::make('profile_photo_path')
                ->label('Photo')
                ->circular()
                ->defaultImageUrl(url('/images/default-avatar.png')),
                
            Tables\Columns\TextColumn::make('name')
                ->searchable()
                ->sortable()
                ->weight(FontWeight::Bold),
                
            Tables\Columns\TextColumn::make('email')
                ->searchable()
                ->copyable()
                ->icon('heroicon-m-envelope'),
                
            Tables\Columns\TextColumn::make('roles.name')
                ->label('Roles')
                ->badge()
                ->color('info')
                ->separator(','),
                
            Tables\Columns\IconColumn::make('email_verified_at')
                ->label('Verified')
                ->boolean()
                ->getStateUsing(fn (User $record): bool => 
                    $record->email_verified_at !== null
                )
                ->trueIcon('heroicon-o-check-badge')
                ->falseIcon('heroicon-o-x-circle')
                ->trueColor('success')
                ->falseColor('danger'),
                
            Tables\Columns\IconColumn::make('is_active')
                ->label('Active')
                ->boolean()
                ->trueIcon('heroicon-o-check-circle')
                ->falseIcon('heroicon-o-x-circle')
                ->trueColor('success')
                ->falseColor('danger'),
                
            Tables\Columns\TextColumn::make('last_login_at')
                ->label('Last Login')
                ->dateTime()
                ->sortable()
                ->placeholder('Never')
                ->toggleable(),
                
            Tables\Columns\TextColumn::make('created_at')
                ->dateTime()
                ->sortable()
                ->toggleable(isToggledHiddenByDefault: true),
        ])
        ->filters([
            Tables\Filters\SelectFilter::make('roles')
                ->relationship('roles', 'name')
                ->multiple()
                ->preload(),
                
            Tables\Filters\TernaryFilter::make('is_active')
                ->label('Status')
                ->trueLabel('Active Only')
                ->falseLabel('Inactive Only'),
                
            Tables\Filters\TernaryFilter::make('email_verified_at')
                ->label('Email Verification')
                ->trueLabel('Verified Only')
                ->falseLabel('Unverified Only')
                ->queries(
                    true: fn (Builder $query) => $query->whereNotNull('email_verified_at'),
                    false: fn (Builder $query) => $query->whereNull('email_verified_at'),
                ),
                
            Tables\Filters\Filter::make('recent_login')
                ->label('Recent Login (30 days)')
                ->query(fn (Builder $query): Builder => 
                    $query->where('last_login_at', '>=', now()->subDays(30))
                ),
        ])
        ->actions([
            Tables\Actions\ViewAction::make(),
            Tables\Actions\EditAction::make(),
            
            Tables\Actions\Action::make('impersonate')
                ->label('Impersonate')
                ->icon('heroicon-o-user-circle')
                ->color('warning')
                ->visible(fn (User $record): bool => 
                    auth()->user()->can('impersonate users') && 
                    auth()->id() !== $record->id
                )
                ->action(function (User $record) {
                    session(['impersonated_by' => auth()->id()]);
                    auth()->login($record);
                    
                    return redirect()->route('filament.chinook-admin.pages.dashboard');
                }),
                
            Tables\Actions\DeleteAction::make()
                ->visible(fn (User $record): bool => 
                    auth()->id() !== $record->id
                ),
        ])
````
</augment_code_snippet>

## 11.4. RBAC Integration

### 11.4.1. Role Management

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/UserResource.php" mode="EXCERPT">
````php
// Custom action for role assignment
Tables\Actions\Action::make('assign_role')
    ->label('Assign Role')
    ->icon('heroicon-o-shield-check')
    ->form([
        Forms\Components\Select::make('role')
            ->options(Role::all()->pluck('name', 'name'))
            ->required(),
    ])
    ->action(function (User $record, array $data) {
        $record->assignRole($data['role']);
        
        Notification::make()
            ->title('Role assigned successfully')
            ->success()
            ->send();
    }),

// Bulk role assignment
Tables\Actions\BulkAction::make('assign_role_bulk')
    ->label('Assign Role')
    ->icon('heroicon-o-shield-check')
    ->form([
        Forms\Components\Select::make('role')
            ->options(Role::all()->pluck('name', 'name'))
            ->required(),
    ])
    ->action(function (Collection $records, array $data) {
        $records->each(function (User $user) use ($data) {
            $user->assignRole($data['role']);
        });
        
        Notification::make()
            ->title('Roles assigned successfully')
            ->success()
            ->send();
    })
    ->deselectRecordsAfterCompletion(),
````
</augment_code_snippet>

## 11.5. Authentication Controls

### 11.5.1. Account Management Actions

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/UserResource.php" mode="EXCERPT">
````php
Tables\Actions\Action::make('reset_password')
    ->label('Reset Password')
    ->icon('heroicon-o-key')
    ->color('warning')
    ->requiresConfirmation()
    ->form([
        Forms\Components\TextInput::make('new_password')
            ->label('New Password')
            ->password()
            ->required()
            ->minLength(8),
    ])
    ->action(function (User $record, array $data) {
        $record->update([
            'password' => Hash::make($data['new_password']),
        ]);
        
        Notification::make()
            ->title('Password reset successfully')
            ->success()
            ->send();
    }),

Tables\Actions\Action::make('verify_email')
    ->label('Verify Email')
    ->icon('heroicon-o-check-badge')
    ->color('success')
    ->visible(fn (User $record): bool => $record->email_verified_at === null)
    ->action(function (User $record) {
        $record->update(['email_verified_at' => now()]);
        
        Notification::make()
            ->title('Email verified successfully')
            ->success()
            ->send();
    }),

Tables\Actions\Action::make('deactivate')
    ->label('Deactivate')
    ->icon('heroicon-o-x-circle')
    ->color('danger')
    ->visible(fn (User $record): bool => $record->is_active)
    ->requiresConfirmation()
    ->action(function (User $record) {
        $record->update(['is_active' => false]);
        
        Notification::make()
            ->title('User deactivated')
            ->warning()
            ->send();
    }),
````
</augment_code_snippet>

## 11.6. Advanced Features

### 11.6.1. User Activity Tracking

<augment_code_snippet path="app/Models/User.php" mode="EXCERPT">
````php
/**
 * Update last login timestamp
 */
public function updateLastLogin(): void
{
    $this->update(['last_login_at' => now()]);
}

/**
 * Check if user has been active recently
 */
public function isRecentlyActive(int $days = 30): bool
{
    return $this->last_login_at && 
           $this->last_login_at->isAfter(now()->subDays($days));
}

/**
 * Get user's permissions through roles
 */
public function getAllPermissionsAttribute(): Collection
{
    return $this->getPermissionsViaRoles();
}

/**
 * Check if user can access admin panel
 */
public function canAccessPanel(): bool
{
    return $this->is_active && 
           $this->email_verified_at !== null &&
           $this->hasAnyRole(['admin', 'manager', 'employee']);
}
````
</augment_code_snippet>

### 11.6.2. Bulk Actions

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/UserResource.php" mode="EXCERPT">
````php
->bulkActions([
    Tables\Actions\BulkActionGroup::make([
        Tables\Actions\DeleteBulkAction::make()
            ->action(function (Collection $records) {
                // Prevent deleting current user
                $records = $records->filter(fn (User $user) => 
                    $user->id !== auth()->id()
                );
                
                $records->each->delete();
            }),
            
        Tables\Actions\BulkAction::make('activate')
            ->label('Activate Selected')
            ->icon('heroicon-o-check-circle')
            ->color('success')
            ->action(fn (Collection $records) => 
                $records->each->update(['is_active' => true])
            )
            ->deselectRecordsAfterCompletion(),
            
        Tables\Actions\BulkAction::make('deactivate')
            ->label('Deactivate Selected')
            ->icon('heroicon-o-x-circle')
            ->color('danger')
            ->action(function (Collection $records) {
                // Prevent deactivating current user
                $records = $records->filter(fn (User $user) => 
                    $user->id !== auth()->id()
                );
                
                $records->each->update(['is_active' => false]);
            })
            ->deselectRecordsAfterCompletion(),
            
        Tables\Actions\BulkAction::make('verify_emails')
            ->label('Verify Emails')
            ->icon('heroicon-o-check-badge')
            ->color('success')
            ->action(fn (Collection $records) => 
                $records->each->update(['email_verified_at' => now()])
            )
            ->deselectRecordsAfterCompletion(),
    ]),
])
````
</augment_code_snippet>

## 11.7. Testing Examples

### 11.7.1. Resource Test

<augment_code_snippet path="tests/Feature/Filament/UserResourceTest.php" mode="EXCERPT">

````php
<?php

namespace Tests\Feature\Filament;

use App\Models\User;use old\TestCase;use Spatie\Permission\Models\Role;

class UserResourceTest extends TestCase
{
    public function test_can_create_user_with_role(): void
    {
        $admin = User::factory()->create();
        $role = Role::create(['name' => 'manager']);

        $this->actingAs($admin)
            ->post(route('filament.chinook-admin.resources.users.store'), [
                'name' => 'Test User',
                'email' => 'test@example.com',
                'password' => 'password123',
                'password_confirmation' => 'password123',
                'is_active' => true,
                'roles' => ['manager'],
            ])
            ->assertRedirect();

        $user = User::where('email', 'test@example.com')->first();
        $this->assertTrue($user->hasRole('manager'));
    }

    public function test_cannot_delete_current_user(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)
            ->delete(route('filament.chinook-admin.resources.users.destroy', $user));

        $this->assertDatabaseHas('users', ['id' => $user->id]);
    }

    public function test_user_can_access_panel_check(): void
    {
        $role = Role::create(['name' => 'admin']);
        
        $user = User::factory()->create([
            'is_active' => true,
            'email_verified_at' => now(),
        ]);
        
        $user->assignRole($role);

        $this->assertTrue($user->canAccessPanel());
    }
}
````
</augment_code_snippet>

---

## Navigation

**Previous:** [Employees Resource](100-employees-resource.md) | **Index:** [Resources Documentation](000-resources-index.md) | **Next:** [Advanced Features](../features/000-features-index.md)

---

**Documentation Standards**: This document follows WCAG 2.1 AA accessibility guidelines and uses Laravel 12 modern syntax patterns.

[⬆️ Back to Top](#11-users-resource)
