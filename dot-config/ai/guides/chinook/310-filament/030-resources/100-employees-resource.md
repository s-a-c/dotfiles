# Employees Resource - Complete Implementation Guide

> **Created:** 2025-07-16
> **Updated:** 2025-07-18
> **Focus:** Complete Employee management with working code examples, hierarchical relationships, customer support integration, and performance tracking
> **Source:** [Chinook Employee Model](https://github.com/s-a-c/chinook/blob/main/app/Models/Chinook/Employee.php)

## Table of Contents

- [Overview](#overview)
- [Resource Implementation](#resource-implementation)
  - [Basic Resource Structure](#basic-resource-structure)
  - [Form Schema](#form-schema)
  - [Table Configuration](#table-configuration)
- [Hierarchical Management](#hierarchical-management)
  - [Organization Chart](#organization-chart)
  - [Subordinates Relationship Manager](#subordinates-relationship-manager)
  - [Manager Relationship Manager](#manager-relationship-manager)
- [Customer Support Integration](#customer-support-integration)
- [Performance Tracking](#performance-tracking)
- [Authorization Policies](#authorization-policies)
- [Advanced Features](#advanced-features)
- [Testing Examples](#testing-examples)
- [Performance Optimization](#performance-optimization)

## Overview

The Employees Resource provides comprehensive management of company employees within the Chinook admin panel. It features complete CRUD operations, hierarchical manager-subordinate relationships, customer support assignment, performance tracking, role-based access control integration, and organizational chart visualization with full Laravel 12 compatibility.

### Key Features

- **Complete CRUD Operations**: Create, read, update, delete employees with comprehensive validation
- **Hierarchical Structure**: Manager-subordinate relationships with reporting chains and organizational chart
- **Customer Support**: Assignment of customers to support representatives with workload balancing
- **Performance Tracking**: Sales metrics, customer satisfaction tracking, and KPI monitoring
- **Role Management**: Integration with spatie/laravel-permission for RBAC and department-based access
- **Contact Information**: Comprehensive employee contact and personal data management
- **Organizational Chart**: Visual representation of company hierarchy with interactive navigation
- **Workload Management**: Customer assignment balancing and support rep performance analytics
- **Department Management**: Department-based filtering, reporting, and organizational structure
- **Employee Analytics**: Performance metrics, sales tracking, and customer satisfaction monitoring

### Model Integration

<augment_code_snippet path="app/Models/Chinook/Employee.php" mode="EXCERPT">
````php
class Employee extends BaseModel
{
    use HasTaxonomy; // From BaseModel - enables employee classification

    protected $table = 'chinook_employees';

    protected $fillable = [
        'last_name', 'first_name', 'title', 'reports_to', 'birth_date', 'hire_date',
        'address', 'city', 'state', 'country', 'postal_code', 'phone', 'fax', 'email',
        'public_id', 'slug', 'department', 'salary', 'is_active',
    ];

    // Relationships
    public function manager(): BelongsTo // Employee reports to another employee (manager)
    public function subordinates(): HasMany // Employee has many subordinates
    public function customers(): HasMany // Employee supports many customers

    // Accessors
    public function getFullNameAttribute(): string
    public function getRouteKeyName(): string // Uses slug for URLs

    // Performance Analytics Methods
    public function getTotalSalesAttribute(): float
    public function getCustomerSatisfactionAttribute(): float
    public function getReportingChain(): Collection
    public function getDirectReportsCountAttribute(): int
    public function getCustomerWorkloadAttribute(): int

    // Casts
    protected function casts(): array {
        'birth_date' => 'date',
        'hire_date' => 'date',
        'salary' => 'integer',
        'is_active' => 'boolean',
    }

    // Scopes for employee management
    public function scopeActive($query)
    public function scopeByDepartment($query, string $department)
    public function scopeManagers($query)
    public function scopeWithCustomers($query)
    public function scopeHighPerformers($query)
````
</augment_code_snippet>

## Resource Implementation

### Basic Resource Structure

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/EmployeeResource.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Filament\ChinookAdmin\Resources;

use App\Models\Chinook\Employee;
use App\Models\Chinook\Customer;
use App\Filament\ChinookAdmin\Resources\EmployeeResource\Pages;
use App\Filament\ChinookAdmin\Resources\EmployeeResource\RelationManagers;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Infolists;
use Filament\Infolists\Infolist;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;
use Illuminate\Support\Collection;
use Illuminate\Support\Str;

class EmployeeResource extends Resource
{
    protected static ?string $model = Employee::class;

    protected static ?string $navigationIcon = 'heroicon-o-user-group';

    protected static ?string $navigationGroup = 'Administration';

    protected static ?int $navigationSort = 1;

    protected static ?string $recordTitleAttribute = 'full_name';

    protected static ?string $navigationBadgeTooltip = 'Total employees in company';

    protected static int $globalSearchResultsLimit = 20;

    public static function getNavigationBadge(): ?string
    {
        return static::getModel()::where('is_active', true)->count();
    }

    public static function getGlobalSearchResultTitle(Model $record): string
    {
        return $record->full_name;
    }

    public static function getGlobalSearchResultDetails(Model $record): array
    {
        return [
            'Title' => $record->title,
            'Department' => $record->department,
            'Manager' => $record->manager?->full_name,
            'Direct Reports' => $record->subordinates()->count(),
            'Customers' => $record->customers()->count(),
            'Hire Date' => $record->hire_date?->format('M d, Y'),
        ];
    }
````
</augment_code_snippet>

### Form Schema

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/EmployeeResource.php" mode="EXCERPT">
````php
public static function form(Form $form): Form
{
    return $form
        ->schema([
            Forms\Components\Section::make('Personal Information')
                ->schema([
                    Forms\Components\TextInput::make('first_name')
                        ->required()
                        ->maxLength(20)
                        ->live(onBlur: true)
                        ->afterStateUpdated(function (string $context, $state, callable $set, callable $get) {
                            if ($context === 'create' && $state && $get('last_name')) {
                                $fullName = $state . ' ' . $get('last_name');
                                $set('slug', Str::slug($fullName));
                            }
                        })
                        ->helperText('Employee\'s first name'),

                    Forms\Components\TextInput::make('last_name')
                        ->required()
                        ->maxLength(20)
                        ->live(onBlur: true)
                        ->afterStateUpdated(function (string $context, $state, callable $set, callable $get) {
                            if ($context === 'create' && $state && $get('first_name')) {
                                $fullName = $get('first_name') . ' ' . $state;
                                $set('slug', Str::slug($fullName));
                            }
                        })
                        ->helperText('Employee\'s last name'),

                    Forms\Components\TextInput::make('slug')
                        ->required()
                        ->maxLength(255)
                        ->unique(Employee::class, 'slug', ignoreRecord: true)
                        ->rules(['alpha_dash'])
                        ->helperText('URL-friendly version of the employee name'),

                    Forms\Components\TextInput::make('email')
                        ->email()
                        ->required()
                        ->maxLength(60)
                        ->unique(Employee::class, 'email', ignoreRecord: true)
                        ->suffixIcon('heroicon-m-envelope')
                        ->helperText('Company email address'),

                    Forms\Components\DatePicker::make('birth_date')
                        ->native(false)
                        ->maxDate(now()->subYears(18))
                        ->displayFormat('M d, Y')
                        ->helperText('Must be at least 18 years old'),

                    Forms\Components\DatePicker::make('hire_date')
                        ->native(false)
                        ->default(now())
                        ->maxDate(now())
                        ->required()
                        ->displayFormat('M d, Y')
                        ->helperText('Employee start date'),
                ])
                ->columns(2),

            Forms\Components\Section::make('Employment Details')
                ->schema([
                    Forms\Components\TextInput::make('title')
                        ->required()
                        ->maxLength(30)
                        ->placeholder('e.g., Sales Representative, Manager')
                        ->helperText('Employee job title'),

                    Forms\Components\Select::make('department')
                        ->options([
                            'Sales' => '💼 Sales',
                            'Support' => '🎧 Support',
                            'Management' => '👔 Management',
                            'IT' => '💻 Information Technology',
                            'HR' => '👥 Human Resources',
                            'Finance' => '💰 Finance',
                            'Marketing' => '📢 Marketing',
                            'Operations' => '⚙️ Operations',
                            'Legal' => '⚖️ Legal',
                            'R&D' => '🔬 Research & Development',
                        ])
                        ->required()
                        ->searchable()
                        ->helperText('Employee department'),

                    Forms\Components\Select::make('reports_to')
                        ->label('Manager')
                        ->relationship('manager', 'first_name')
                        ->getOptionLabelFromRecordUsing(fn (Employee $record) =>
                            "{$record->first_name} {$record->last_name} - {$record->title}"
                        )
                        ->searchable()
                        ->preload()
                        ->createOptionForm([
                            Forms\Components\TextInput::make('first_name')
                                ->required()
                                ->maxLength(20),
                            Forms\Components\TextInput::make('last_name')
                                ->required()
                                ->maxLength(20),
                            Forms\Components\TextInput::make('title')
                                ->required()
                                ->maxLength(30),
                            Forms\Components\TextInput::make('email')
                                ->email()
                                ->required(),
                            Forms\Components\Select::make('department')
                                ->options([
                                    'Management' => 'Management',
                                    'Sales' => 'Sales',
                                    'Support' => 'Support',
                                    'IT' => 'IT',
                                ])
                                ->required(),
                        ])
                        ->createOptionUsing(function (array $data) {
                            return Employee::create(array_merge($data, [
                                'hire_date' => now(),
                                'is_active' => true,
                            ]));
                        })
                        ->helperText('Select or create a manager for this employee'),

                    Forms\Components\TextInput::make('salary')
                        ->numeric()
                        ->prefix('$')
                        ->minValue(0)
                        ->step(1000)
                        ->placeholder('50000')
                        ->helperText('Annual salary in USD'),

                    Forms\Components\Toggle::make('is_active')
                        ->default(true)
                        ->helperText('Inactive employees cannot be assigned new customers or access systems')
                        ->live()
                        ->afterStateUpdated(function ($state, callable $set) {
                            if (!$state) {
                                $set('termination_date', now());
                            } else {
                                $set('termination_date', null);
                            }
                        }),

                    Forms\Components\DatePicker::make('termination_date')
                        ->label('Termination Date')
                        ->native(false)
                        ->visible(fn (callable $get) => !$get('is_active'))
                        ->helperText('Date when employment ended'),
                ])
                ->columns(2),

            Forms\Components\Section::make('Contact Information')
                ->schema([
                    Forms\Components\TextInput::make('address')
                        ->maxLength(70)
                        ->placeholder('123 Business Street')
                        ->helperText('Street address'),

                    Forms\Components\TextInput::make('city')
                        ->maxLength(40)
                        ->placeholder('New York')
                        ->helperText('City name'),

                    Forms\Components\TextInput::make('state')
                        ->maxLength(40)
                        ->placeholder('NY')
                        ->helperText('State or province'),

                    Forms\Components\Select::make('country')
                        ->searchable()
                        ->options([
                            'US' => '🇺🇸 United States',
                            'CA' => '🇨🇦 Canada',
                            'GB' => '🇬🇧 United Kingdom',
                            'DE' => '🇩🇪 Germany',
                            'FR' => '🇫🇷 France',
                            'AU' => '🇦🇺 Australia',
                            'JP' => '🇯🇵 Japan',
                            'BR' => '🇧🇷 Brazil',
                            'IN' => '🇮🇳 India',
                            'MX' => '🇲🇽 Mexico',
                        ])
                        ->default('US')
                        ->helperText('Employee\'s country'),

                    Forms\Components\TextInput::make('postal_code')
                        ->maxLength(10)
                        ->placeholder('10001')
                        ->helperText('ZIP or postal code'),

                    Forms\Components\TextInput::make('phone')
                        ->tel()
                        ->maxLength(24)
                        ->placeholder('+1 (555) 123-4567')
                        ->suffixIcon('heroicon-m-phone')
                        ->helperText('Business phone number'),

                    Forms\Components\TextInput::make('fax')
                        ->maxLength(24)
                        ->placeholder('+1 (555) 123-4568')
                        ->suffixIcon('heroicon-m-printer')
                        ->helperText('Fax number (optional)'),
                ])
                ->columns(2),

            Forms\Components\Section::make('Performance & Goals')
                ->schema([
                    Forms\Components\Textarea::make('performance_notes')
                        ->maxLength(1000)
                        ->rows(3)
                        ->placeholder('Performance notes, goals, and achievements...')
                        ->helperText('Performance tracking and goal setting'),

                    Forms\Components\KeyValue::make('kpis')
                        ->label('Key Performance Indicators')
                        ->keyLabel('KPI Name')
                        ->valueLabel('Target/Current')
                        ->addActionLabel('Add KPI')
                        ->helperText('Track employee KPIs and performance metrics')
                        ->columnSpanFull(),
                ])
                ->collapsible(),

            Forms\Components\Section::make('Additional Information')
                ->schema([
                    Forms\Components\KeyValue::make('emergency_contacts')
                        ->keyLabel('Contact Name')
                        ->valueLabel('Phone Number')
                        ->addActionLabel('Add emergency contact')
                        ->helperText('Emergency contact information'),

                    Forms\Components\KeyValue::make('certifications')
                        ->keyLabel('Certification')
                        ->valueLabel('Expiry Date')
                        ->addActionLabel('Add certification')
                        ->helperText('Professional certifications and licenses'),
                ])
                ->columns(2)
                ->collapsible(),
        ]);
}
````
</augment_code_snippet>

### Table Configuration

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/EmployeeResource.php" mode="EXCERPT">
````php
public static function table(Table $table): Table
{
    return $table
        ->columns([
            Tables\Columns\TextColumn::make('full_name')
                ->label('Employee Name')
                ->getStateUsing(fn (Employee $record): string =>
                    "{$record->first_name} {$record->last_name}"
                )
                ->searchable(['first_name', 'last_name'])
                ->sortable(['first_name', 'last_name'])
                ->weight('bold')
                ->description(fn (Employee $record): string =>
                    $record->email ?? ''
                ),

            Tables\Columns\TextColumn::make('title')
                ->searchable()
                ->sortable()
                ->badge()
                ->color('info')
                ->description(fn (Employee $record): string =>
                    "ID: {$record->public_id}"
                ),

            Tables\Columns\TextColumn::make('department')
                ->badge()
                ->searchable()
                ->sortable()
                ->color(fn (string $state): string => match ($state) {
                    'Sales' => 'success',
                    'Support' => 'warning',
                    'Management' => 'danger',
                    'IT' => 'info',
                    'HR' => 'primary',
                    'Finance' => 'secondary',
                    'Marketing' => 'purple',
                    'Operations' => 'orange',
                    default => 'gray',
                })
                ->formatStateUsing(function ($state) {
                    $icons = [
                        'Sales' => '💼', 'Support' => '🎧', 'Management' => '👔',
                        'IT' => '💻', 'HR' => '👥', 'Finance' => '💰',
                        'Marketing' => '📢', 'Operations' => '⚙️',
                    ];
                    $icon = $icons[$state] ?? '';
                    return $icon . ' ' . $state;
                }),

            Tables\Columns\TextColumn::make('manager.full_name')
                ->label('Manager')
                ->getStateUsing(fn (Employee $record): ?string =>
                    $record->manager ?
                    "{$record->manager->first_name} {$record->manager->last_name}" :
                    'No Manager'
                )
                ->url(fn (Employee $record): ?string =>
                    $record->manager ?
                    route('filament.chinook-admin.resources.employees.view', $record->manager) :
                    null
                )
                ->openUrlInNewTab()
                ->badge()
                ->color(fn (Employee $record): string =>
                    $record->manager ? 'success' : 'warning'
                )
                ->toggleable(),

            Tables\Columns\TextColumn::make('subordinates_count')
                ->label('Direct Reports')
                ->counts('subordinates')
                ->badge()
                ->color('success')
                ->sortable()
                ->url(fn (Employee $record): string =>
                    route('filament.chinook-admin.resources.employees.index', [
                        'tableFilters[reports_to][value]' => $record->id
                    ])
                )
                ->openUrlInNewTab(),

            Tables\Columns\TextColumn::make('customers_count')
                ->label('Customers')
                ->counts('customers')
                ->badge()
                ->color('info')
                ->sortable()
                ->url(fn (Employee $record): string =>
                    route('filament.chinook-admin.resources.customers.index', [
                        'tableFilters[support_rep_id][value]' => $record->id
                    ])
                )
                ->openUrlInNewTab(),

            Tables\Columns\TextColumn::make('total_sales')
                ->label('Total Sales')
                ->getStateUsing(fn (Employee $record): string =>
                    '$' . number_format($record->customers()
                        ->join('chinook_invoices', 'chinook_customers.id', '=', 'chinook_invoices.customer_id')
                        ->sum('chinook_invoices.total'), 2)
                )
                ->sortable()
                ->badge()
                ->color(function ($state): string {
                    $value = (float) str_replace(['$', ','], '', $state);
                    if ($value >= 10000) return 'success';
                    if ($value >= 5000) return 'warning';
                    return 'gray';
                })
                ->toggleable(),

            Tables\Columns\TextColumn::make('hire_date')
                ->date('M d, Y')
                ->sortable()
                ->description(fn (Employee $record): string =>
                    $record->hire_date ? $record->hire_date->diffForHumans() : ''
                )
                ->toggleable(),

            Tables\Columns\TextColumn::make('salary')
                ->money('USD')
                ->sortable()
                ->toggleable(isToggledHiddenByDefault: true),

            Tables\Columns\IconColumn::make('is_active')
                ->boolean()
                ->trueIcon('heroicon-o-check-circle')
                ->falseIcon('heroicon-o-x-circle')
                ->trueColor('success')
                ->falseColor('danger')
                ->label('Status'),

            Tables\Columns\TextColumn::make('phone')
                ->searchable()
                ->copyable()
                ->icon('heroicon-m-phone')
                ->toggleable(isToggledHiddenByDefault: true),

            Tables\Columns\TextColumn::make('created_at')
                ->label('Added')
                ->dateTime('M d, Y')
                ->sortable()
                ->toggleable(isToggledHiddenByDefault: true),

            Tables\Columns\TextColumn::make('updated_at')
                ->dateTime()
                ->sortable()
                ->toggleable(isToggledHiddenByDefault: true),
        ])
        ->filters([
            Tables\Filters\SelectFilter::make('department')
                ->options([
                    'Sales' => '💼 Sales',
                    'Support' => '🎧 Support',
                    'Management' => '👔 Management',
                    'IT' => '💻 IT',
                    'HR' => '👥 HR',
                    'Finance' => '💰 Finance',
                    'Marketing' => '📢 Marketing',
                    'Operations' => '⚙️ Operations',
                ])
                ->multiple()
                ->searchable(),

            Tables\Filters\SelectFilter::make('reports_to')
                ->label('Manager')
                ->relationship('manager', 'first_name')
                ->getOptionLabelFromRecordUsing(fn (Employee $record) =>
                    "{$record->first_name} {$record->last_name} - {$record->title}"
                )
                ->multiple()
                ->searchable(),

            Tables\Filters\TernaryFilter::make('is_active')
                ->label('Employment Status')
                ->trueLabel('Active Only')
                ->falseLabel('Inactive Only')
                ->native(false),

            Tables\Filters\Filter::make('has_subordinates')
                ->label('Has Direct Reports')
                ->query(fn (Builder $query): Builder =>
                    $query->has('subordinates')
                ),

            Tables\Filters\Filter::make('has_customers')
                ->label('Has Customers')
                ->query(fn (Builder $query): Builder =>
                    $query->has('customers')
                ),

            Tables\Filters\Filter::make('managers_only')
                ->label('Managers Only')
                ->query(fn (Builder $query): Builder =>
                    $query->has('subordinates')
                ),

            Tables\Filters\Filter::make('high_performers')
                ->label('High Performers (>$5k sales)')
                ->query(fn (Builder $query): Builder =>
                    $query->whereHas('customers', function ($q) {
                        $q->join('chinook_invoices', 'chinook_customers.id', '=', 'chinook_invoices.customer_id')
                          ->havingRaw('SUM(chinook_invoices.total) > 5000');
                    })
                ),

            Tables\Filters\Filter::make('recent_hires')
                ->label('Recent Hires (90 days)')
                ->query(fn (Builder $query): Builder =>
                    $query->where('hire_date', '>=', now()->subDays(90))
                ),

            Tables\Filters\Filter::make('salary_range')
                ->form([
                    Forms\Components\TextInput::make('min_salary')
                        ->label('Min Salary')
                        ->numeric()
                        ->prefix('$'),
                    Forms\Components\TextInput::make('max_salary')
                        ->label('Max Salary')
                        ->numeric()
                        ->prefix('$'),
                ])
                ->query(function (Builder $query, array $data): Builder {
                    return $query
                        ->when($data['min_salary'], fn ($q) => $q->where('salary', '>=', $data['min_salary']))
                        ->when($data['max_salary'], fn ($q) => $q->where('salary', '<=', $data['max_salary']));
                }),

            Tables\Filters\TrashedFilter::make(),
        ])
        ->actions([
            Tables\Actions\ViewAction::make(),
            Tables\Actions\EditAction::make(),
            Tables\Actions\DeleteAction::make(),
            Tables\Actions\RestoreAction::make(),
            Tables\Actions\ForceDeleteAction::make(),

            Tables\Actions\Action::make('view_customers')
                ->label('View Customers')
                ->icon('heroicon-o-users')
                ->url(fn (Employee $record): string =>
                    route('filament.chinook-admin.resources.customers.index', [
                        'tableFilters[support_rep_id][value]' => $record->id
                    ])
                )
                ->openUrlInNewTab()
                ->visible(fn (Employee $record): bool => $record->customers()->exists()),

            Tables\Actions\Action::make('view_subordinates')
                ->label('View Team')
                ->icon('heroicon-o-user-group')
                ->url(fn (Employee $record): string =>
                    route('filament.chinook-admin.resources.employees.index', [
                        'tableFilters[reports_to][value]' => $record->id
                    ])
                )
                ->openUrlInNewTab()
                ->visible(fn (Employee $record): bool => $record->subordinates()->exists()),

            Tables\Actions\Action::make('send_message')
                ->label('Send Message')
                ->icon('heroicon-o-chat-bubble-left-right')
                ->form([
                    Forms\Components\TextInput::make('subject')
                        ->required()
                        ->maxLength(255),
                    Forms\Components\Textarea::make('message')
                        ->required()
                        ->rows(4),
                ])
                ->action(function (Employee $record, array $data) {
                    // Message sending logic here
                    Notification::make()
                        ->title('Message sent to ' . $record->full_name)
                        ->success()
                        ->send();
                }),
        ])

        ->bulkActions([
            Tables\Actions\BulkActionGroup::make([
                Tables\Actions\DeleteBulkAction::make(),
                Tables\Actions\RestoreBulkAction::make(),
                Tables\Actions\ForceDeleteBulkAction::make(),

                Tables\Actions\BulkAction::make('assign_manager')
                    ->label('Assign Manager')
                    ->icon('heroicon-o-user-plus')
                    ->form([
                        Forms\Components\Select::make('reports_to')
                            ->label('Manager')
                            ->relationship('manager', 'first_name')
                            ->getOptionLabelFromRecordUsing(fn (Employee $record) =>
                                "{$record->first_name} {$record->last_name} - {$record->title}"
                            )
                            ->required()
                            ->searchable(),
                    ])
                    ->action(function (Collection $records, array $data) {
                        $records->each->update(['reports_to' => $data['reports_to']]);

                        Notification::make()
                            ->title('Manager assigned successfully')
                            ->success()
                            ->send();
                    })
                    ->deselectRecordsAfterCompletion()
                    ->requiresConfirmation(),

                Tables\Actions\BulkAction::make('update_department')
                    ->label('Update Department')
                    ->icon('heroicon-o-building-office')
                    ->form([
                        Forms\Components\Select::make('department')
                            ->options([
                                'Sales' => '💼 Sales',
                                'Support' => '🎧 Support',
                                'Management' => '👔 Management',
                                'IT' => '💻 IT',
                                'HR' => '👥 HR',
                                'Finance' => '💰 Finance',
                            ])
                            ->required(),
                    ])
                    ->action(function (Collection $records, array $data) {
                        $records->each->update(['department' => $data['department']]);
                    })
                    ->deselectRecordsAfterCompletion()
                    ->requiresConfirmation(),

                Tables\Actions\BulkAction::make('update_status')
                    ->label('Update Status')
                    ->icon('heroicon-o-user-circle')
                    ->form([
                        Forms\Components\Toggle::make('is_active')
                            ->label('Active Status')
                            ->required(),
                    ])
                    ->action(function (Collection $records, array $data) {
                        $records->each->update(['is_active' => $data['is_active']]);
                    })
                    ->deselectRecordsAfterCompletion()
                    ->requiresConfirmation(),

                Tables\Actions\BulkAction::make('export_employees')
                    ->label('Export Selected')
                    ->icon('heroicon-o-arrow-down-tray')
                    ->action(function (Collection $records) {
                        return response()->streamDownload(function () use ($records) {
                            echo "Name,Title,Department,Manager,Customers,Total Sales,Hire Date\n";
                            foreach ($records as $employee) {
                                $manager = $employee->manager ?
                                    "{$employee->manager->first_name} {$employee->manager->last_name}" :
                                    'No Manager';
                                $totalSales = $employee->customers()
                                    ->join('chinook_invoices', 'chinook_customers.id', '=', 'chinook_invoices.customer_id')
                                    ->sum('chinook_invoices.total');
                                echo "\"{$employee->full_name}\",\"{$employee->title}\",\"{$employee->department}\",\"{$manager}\",{$employee->customers()->count()},\${$totalSales},{$employee->hire_date->format('Y-m-d')}\n";
                            }
                        }, 'employees-export.csv');
                    }),
            ]),
        ])
        ->defaultSort('hire_date', 'desc')
        ->persistSortInSession()
        ->persistSearchInSession()
        ->persistFiltersInSession();
}
````
</augment_code_snippet>

## Hierarchical Management

### Organization Chart

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/EmployeeResource/Pages/OrganizationChart.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Filament\ChinookAdmin\Resources\EmployeeResource\Pages;

use App\Filament\ChinookAdmin\Resources\EmployeeResource;
use App\Models\Chinook\Employee;
use Filament\Resources\Pages\Page;
use Illuminate\Contracts\View\View;

class OrganizationChart extends Page
{
    protected static string $resource = EmployeeResource::class;

    protected static string $view = 'filament.resources.employee-resource.pages.organization-chart';

    protected static ?string $title = 'Organization Chart';

    protected static ?string $navigationIcon = 'heroicon-o-building-office-2';

    protected static ?string $navigationGroup = 'Administration';

    public function getViewData(): array
    {
        $employees = Employee::with(['manager', 'subordinates', 'customers'])
            ->where('is_active', true)
            ->get();

        // Build hierarchical structure
        $hierarchy = $this->buildHierarchy($employees);

        return [
            'employees' => $employees,
            'hierarchy' => $hierarchy,
            'departments' => $employees->groupBy('department'),
            'stats' => [
                'total_employees' => $employees->count(),
                'managers' => $employees->filter(fn($e) => $e->subordinates->isNotEmpty())->count(),
                'departments' => $employees->pluck('department')->unique()->count(),
                'avg_team_size' => $employees->filter(fn($e) => $e->subordinates->isNotEmpty())
                    ->avg(fn($e) => $e->subordinates->count()),
            ],
        ];
    }

    private function buildHierarchy($employees): array
    {
        $hierarchy = [];
        $employeeMap = $employees->keyBy('id');

        // Find top-level employees (no manager)
        $topLevel = $employees->whereNull('reports_to');

        foreach ($topLevel as $employee) {
            $hierarchy[] = $this->buildEmployeeTree($employee, $employeeMap);
        }

        return $hierarchy;
    }

    private function buildEmployeeTree($employee, $employeeMap): array
    {
        $node = [
            'employee' => $employee,
            'children' => [],
        ];

        foreach ($employee->subordinates as $subordinate) {
            $node['children'][] = $this->buildEmployeeTree($subordinate, $employeeMap);
        }

        return $node;
    }
}
````
</augment_code_snippet>

### Subordinates Relationship Manager

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/EmployeeResource/RelationManagers/SubordinatesRelationManager.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Filament\ChinookAdmin\Resources\EmployeeResource\RelationManagers;

use App\Models\Chinook\Employee;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class SubordinatesRelationManager extends RelationManager
{
    protected static string $relationship = 'subordinates';

    protected static ?string $recordTitleAttribute = 'full_name';

    protected static ?string $navigationIcon = 'heroicon-o-user-group';

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('full_name')
            ->columns([
                Tables\Columns\TextColumn::make('full_name')
                    ->label('Employee Name')
                    ->getStateUsing(fn (Employee $record): string =>
                        "{$record->first_name} {$record->last_name}"
                    )
                    ->weight('bold')
                    ->description(fn (Employee $record): string =>
                        $record->email ?? ''
                    ),

                Tables\Columns\TextColumn::make('title')
                    ->badge()
                    ->color('info'),

                Tables\Columns\TextColumn::make('department')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'Sales' => 'success',
                        'Support' => 'warning',
                        'Management' => 'danger',
                        'IT' => 'info',
                        default => 'gray',
                    }),

                Tables\Columns\TextColumn::make('customers_count')
                    ->label('Customers')
                    ->counts('customers')
                    ->badge()
                    ->color('primary'),

                Tables\Columns\TextColumn::make('subordinates_count')
                    ->label('Team Size')
                    ->counts('subordinates')
                    ->badge()
                    ->color('success'),

                Tables\Columns\TextColumn::make('total_sales')
                    ->label('Sales')
                    ->getStateUsing(fn (Employee $record): string =>
                        '$' . number_format($record->customers()
                            ->join('chinook_invoices', 'chinook_customers.id', '=', 'chinook_invoices.customer_id')
                            ->sum('chinook_invoices.total'), 2)
                    )
                    ->badge()
                    ->color('warning'),

                Tables\Columns\TextColumn::make('hire_date')
                    ->date('M d, Y')
                    ->sortable()
                    ->description(fn (Employee $record): string =>
                        $record->hire_date ? $record->hire_date->diffForHumans() : ''
                    ),

                Tables\Columns\IconColumn::make('is_active')
                    ->boolean()
                    ->trueIcon('heroicon-o-check-circle')
                    ->falseIcon('heroicon-o-x-circle')
                    ->trueColor('success')
                    ->falseColor('danger')
                    ->label('Status'),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('department')
                    ->options([
                        'Sales' => 'Sales',
                        'Support' => 'Support',
                        'IT' => 'IT',
                        'HR' => 'HR',
                    ])
                    ->multiple(),

                Tables\Filters\TernaryFilter::make('is_active')
                    ->label('Status')
                    ->trueLabel('Active Only')
                    ->falseLabel('Inactive Only'),

                Tables\Filters\Filter::make('has_customers')
                    ->label('Has Customers')
                    ->query(fn (Builder $query): Builder =>
                        $query->has('customers')
                    ),
            ])
            ->headerActions([
                Tables\Actions\CreateAction::make()
                    ->form([
                        Forms\Components\TextInput::make('first_name')
                            ->required()
                            ->maxLength(20),
                        Forms\Components\TextInput::make('last_name')
                            ->required()
                            ->maxLength(20),
                        Forms\Components\TextInput::make('email')
                            ->email()
                            ->required()
                            ->unique(Employee::class),
                        Forms\Components\TextInput::make('title')
                            ->required()
                            ->maxLength(30),
                        Forms\Components\Select::make('department')
                            ->options([
                                'Sales' => 'Sales',
                                'Support' => 'Support',
                                'IT' => 'IT',
                                'HR' => 'HR',
                            ])
                            ->required(),
                        Forms\Components\DatePicker::make('hire_date')
                            ->required()
                            ->default(now()),
                        Forms\Components\Toggle::make('is_active')
                            ->default(true),
                    ])
                    ->mutateFormDataUsing(function (array $data): array {
                        $data['reports_to'] = $this->ownerRecord->id;
                        return $data;
                    }),
            ])
            ->actions([
                Tables\Actions\ViewAction::make()
                    ->url(fn (Employee $record): string =>
                        route('filament.chinook-admin.resources.employees.view', $record)
                    )
                    ->openUrlInNewTab(),

                Tables\Actions\EditAction::make()
                    ->form([
                        Forms\Components\TextInput::make('title')
                            ->required()
                            ->maxLength(30),
                        Forms\Components\Select::make('department')
                            ->options([
                                'Sales' => 'Sales',
                                'Support' => 'Support',
                                'IT' => 'IT',
                                'HR' => 'HR',
                            ])
                            ->required(),
                        Forms\Components\TextInput::make('salary')
                            ->numeric()
                            ->prefix('$'),
                        Forms\Components\Toggle::make('is_active'),
                    ]),

                Tables\Actions\Action::make('view_customers')
                    ->label('View Customers')
                    ->icon('heroicon-o-users')
                    ->url(fn (Employee $record): string =>
                        route('filament.chinook-admin.resources.customers.index', [
                            'tableFilters[support_rep_id][value]' => $record->id
                        ])
                    )
                    ->openUrlInNewTab()
                    ->visible(fn (Employee $record): bool => $record->customers()->exists()),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\BulkAction::make('update_department')
                        ->label('Update Department')
                        ->icon('heroicon-o-building-office')
                        ->form([
                            Forms\Components\Select::make('department')
                                ->options([
                                    'Sales' => 'Sales',
                                    'Support' => 'Support',
                                    'IT' => 'IT',
                                    'HR' => 'HR',
                                ])
                                ->required(),
                        ])
                        ->action(function (Collection $records, array $data) {
                            $records->each->update(['department' => $data['department']]);
                        }),
                ]),
            ])
            ->defaultSort('hire_date', 'desc');
    }
}
````
</augment_code_snippet>

### Manager Relationship Manager

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/EmployeeResource/RelationManagers/ManagerRelationManager.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Filament\ChinookAdmin\Resources\EmployeeResource\RelationManagers;

use App\Models\Chinook\Employee;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;

class ManagerRelationManager extends RelationManager
{
    protected static string $relationship = 'manager';

    protected static ?string $recordTitleAttribute = 'full_name';

    protected static ?string $navigationIcon = 'heroicon-o-user-circle';

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('full_name')
            ->columns([
                Tables\Columns\TextColumn::make('full_name')
                    ->label('Manager Name')
                    ->getStateUsing(fn (Employee $record): string =>
                        "{$record->first_name} {$record->last_name}"
                    )
                    ->weight('bold')
                    ->description(fn (Employee $record): string =>
                        $record->title ?? ''
                    ),

                Tables\Columns\TextColumn::make('email')
                    ->copyable()
                    ->icon('heroicon-m-envelope'),

                Tables\Columns\TextColumn::make('department')
                    ->badge()
                    ->color('info'),

                Tables\Columns\TextColumn::make('subordinates_count')
                    ->label('Total Reports')
                    ->counts('subordinates')
                    ->badge()
                    ->color('success'),

                Tables\Columns\TextColumn::make('phone')
                    ->copyable()
                    ->icon('heroicon-m-phone'),

                Tables\Columns\TextColumn::make('hire_date')
                    ->date('M d, Y')
                    ->description(fn (Employee $record): string =>
                        $record->hire_date ? $record->hire_date->diffForHumans() : ''
                    ),
            ])
            ->actions([
                Tables\Actions\Action::make('view_manager')
                    ->label('View Manager')
                    ->icon('heroicon-o-eye')
                    ->url(fn (Employee $record): string =>
                        route('filament.chinook-admin.resources.employees.view', $record)
                    )
                    ->openUrlInNewTab(),

                Tables\Actions\Action::make('view_org_chart')
                    ->label('View Org Chart')
                    ->icon('heroicon-o-building-office-2')
                    ->url(fn (Employee $record): string =>
                        route('filament.chinook-admin.resources.employees.organization-chart')
                    )
                    ->openUrlInNewTab(),
            ]);
    }
}
````
</augment_code_snippet>

## Customer Support Integration

### Customers Relationship Manager

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/EmployeeResource/RelationManagers/CustomersRelationManager.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Filament\ChinookAdmin\Resources\EmployeeResource\RelationManagers;

use App\Models\Chinook\Customer;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class CustomersRelationManager extends RelationManager
{
    protected static string $relationship = 'customers';

    protected static ?string $recordTitleAttribute = 'full_name';

    protected static ?string $navigationIcon = 'heroicon-o-users';

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('full_name')
            ->columns([
                Tables\Columns\TextColumn::make('full_name')
                    ->label('Customer Name')
                    ->getStateUsing(fn (Customer $record): string =>
                        "{$record->first_name} {$record->last_name}"
                    )
                    ->searchable(['first_name', 'last_name'])
                    ->weight('bold')
                    ->description(fn (Customer $record): string =>
                        $record->company ? "Company: {$record->company}" : ''
                    ),

                Tables\Columns\TextColumn::make('email')
                    ->searchable()
                    ->copyable()
                    ->icon('heroicon-m-envelope'),

                Tables\Columns\TextColumn::make('country')
                    ->badge()
                    ->formatStateUsing(function ($state) {
                        $flags = [
                            'US' => '🇺🇸', 'CA' => '🇨🇦', 'GB' => '🇬🇧', 'DE' => '🇩🇪',
                            'FR' => '🇫🇷', 'IT' => '🇮🇹', 'ES' => '🇪🇸', 'AU' => '🇦🇺',
                        ];
                        $flag = $flags[$state] ?? '';
                        return $flag . ' ' . $state;
                    }),

                Tables\Columns\TextColumn::make('invoices_count')
                    ->label('Orders')
                    ->counts('invoices')
                    ->badge()
                    ->color('info'),

                Tables\Columns\TextColumn::make('lifetime_value')
                    ->label('Lifetime Value')
                    ->getStateUsing(fn (Customer $record): string =>
                        '$' . number_format($record->invoices()->sum('total'), 2)
                    )
                    ->badge()
                    ->color(function ($state): string {
                        $value = (float) str_replace(['$', ','], '', $state);
                        if ($value >= 100) return 'success';
                        if ($value >= 50) return 'warning';
                        return 'gray';
                    }),

                Tables\Columns\TextColumn::make('last_purchase_date')
                    ->label('Last Purchase')
                    ->getStateUsing(fn (Customer $record): ?string =>
                        $record->invoices()->latest('invoice_date')->first()?->invoice_date?->format('M d, Y')
                    )
                    ->description(fn (Customer $record): string => {
                        $lastPurchase = $record->invoices()->latest('invoice_date')->first()?->invoice_date;
                        return $lastPurchase ? $lastPurchase->diffForHumans() : 'Never';
                    }),

                Tables\Columns\IconColumn::make('marketing_consent')
                    ->boolean()
                    ->trueIcon('heroicon-o-check-circle')
                    ->falseIcon('heroicon-o-x-circle')
                    ->trueColor('success')
                    ->falseColor('danger')
                    ->label('Marketing'),

                Tables\Columns\TextColumn::make('phone')
                    ->searchable()
                    ->copyable()
                    ->icon('heroicon-m-phone')
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('country')
                    ->options([
                        'US' => '🇺🇸 United States',
                        'CA' => '🇨🇦 Canada',
                        'GB' => '🇬🇧 United Kingdom',
                        'DE' => '🇩🇪 Germany',
                        'FR' => '🇫🇷 France',
                    ])
                    ->multiple(),

                Tables\Filters\TernaryFilter::make('marketing_consent')
                    ->label('Marketing Consent'),

                Tables\Filters\Filter::make('high_value')
                    ->label('High Value (>$100)')
                    ->query(fn (Builder $query): Builder =>
                        $query->whereHas('invoices', function ($q) {
                            $q->havingRaw('SUM(total) > 100');
                        })
                    ),

                Tables\Filters\Filter::make('recent_customers')
                    ->label('Recent (30 days)')
                    ->query(fn (Builder $query): Builder =>
                        $query->whereHas('invoices', function ($q) {
                            $q->where('invoice_date', '>=', now()->subDays(30));
                        })
                    ),
            ])
            ->headerActions([
                Tables\Actions\AttachAction::make()
                    ->form(fn (Tables\Actions\AttachAction $action): array => [
                        $action->getRecordSelect(),
                        Forms\Components\Textarea::make('assignment_notes')
                            ->label('Assignment Notes')
                            ->maxLength(500)
                            ->placeholder('Reason for assignment, special instructions, etc.'),
                    ]),
            ])
            ->actions([
                Tables\Actions\ViewAction::make()
                    ->url(fn (Customer $record): string =>
                        route('filament.chinook-admin.resources.customers.view', $record)
                    )
                    ->openUrlInNewTab(),

                Tables\Actions\DetachAction::make()
                    ->requiresConfirmation(),

                Tables\Actions\Action::make('view_invoices')
                    ->label('View Orders')
                    ->icon('heroicon-o-shopping-bag')
                    ->url(fn (Customer $record): string =>
                        route('filament.chinook-admin.resources.invoices.index', [
                            'tableFilters[customer][value]' => $record->id
                        ])
                    )
                    ->openUrlInNewTab(),

                Tables\Actions\Action::make('send_email')
                    ->label('Send Email')
                    ->icon('heroicon-o-envelope')
                    ->form([
                        Forms\Components\TextInput::make('subject')
                            ->required()
                            ->maxLength(255),
                        Forms\Components\Textarea::make('message')
                            ->required()
                            ->rows(5),
                    ])
                    ->action(function (Customer $record, array $data) {
                        // Email sending logic here
                        Notification::make()
                            ->title('Email sent to ' . $record->full_name)
                            ->success()
                            ->send();
                    })
                    ->visible(fn (Customer $record): bool => $record->marketing_consent),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DetachBulkAction::make(),

                    Tables\Actions\BulkAction::make('send_bulk_email')
                        ->label('Send Bulk Email')
                        ->icon('heroicon-o-envelope')
                        ->form([
                            Forms\Components\TextInput::make('subject')
                                ->required()
                                ->maxLength(255),
                            Forms\Components\Textarea::make('message')
                                ->required()
                                ->rows(5),
                        ])
                        ->action(function (Collection $records, array $data) {
                            $consentedCustomers = $records->filter(fn($c) => $c->marketing_consent);
                            // Bulk email logic here
                            Notification::make()
                                ->title("Email sent to {$consentedCustomers->count()} customers")
                                ->success()
                                ->send();
                        })
                        ->requiresConfirmation(),
                ]),
            ])
            ->defaultSort('created_at', 'desc')
            ->paginated([10, 25, 50]);
    }
}
````
</augment_code_snippet>

## Performance Tracking

### Employee Performance Analytics

<augment_code_snippet path="app/Models/Chinook/Employee.php" mode="EXCERPT">
````php
// Enhanced performance tracking methods
public function getTotalSalesAttribute(): float
{
    return cache()->remember(
        "employee.{$this->id}.total_sales",
        now()->addHours(1),
        fn () => $this->customers()
            ->join('chinook_invoices', 'chinook_customers.id', '=', 'chinook_invoices.customer_id')
            ->sum('chinook_invoices.total')
    );
}

public function getCustomerSatisfactionAttribute(): float
{
    return cache()->remember(
        "employee.{$this->id}.customer_satisfaction",
        now()->addHours(6),
        function () {
            // Calculate based on customer feedback, return rates, etc.
            $totalCustomers = $this->customers()->count();
            if ($totalCustomers === 0) return 0;

            // Placeholder calculation - would integrate with actual satisfaction system
            $baseRating = 4.0;
            $salesBonus = min($this->total_sales / 10000, 0.5); // Up to 0.5 bonus for high sales
            $customerBonus = min($totalCustomers / 50, 0.3); // Up to 0.3 bonus for many customers

            return min($baseRating + $salesBonus + $customerBonus, 5.0);
        }
    );
}

public function getReportingChain(): Collection
{
    return cache()->remember(
        "employee.{$this->id}.reporting_chain",
        now()->addHours(24),
        function () {
            $chain = collect([$this]);
            $current = $this;

            while ($current->manager && !$chain->contains('id', $current->manager->id)) {
                $current = $current->manager;
                $chain->push($current);
            }

            return $chain;
        }
    );
}

public function getDirectReportsCountAttribute(): int
{
    return cache()->remember(
        "employee.{$this->id}.direct_reports_count",
        now()->addHours(1),
        fn () => $this->subordinates()->count()
    );
}

public function getCustomerWorkloadAttribute(): int
{
    return cache()->remember(
        "employee.{$this->id}.customer_workload",
        now()->addHours(1),
        fn () => $this->customers()->count()
    );
}

public function getPerformanceScoreAttribute(): float
{
    $salesScore = min($this->total_sales / 5000, 1.0) * 40; // 40% weight
    $satisfactionScore = ($this->customer_satisfaction / 5.0) * 30; // 30% weight
    $workloadScore = min($this->customer_workload / 20, 1.0) * 20; // 20% weight
    $teamScore = min($this->direct_reports_count / 5, 1.0) * 10; // 10% weight

    return $salesScore + $satisfactionScore + $workloadScore + $teamScore;
}

public function getPerformanceGradeAttribute(): string
{
    $score = $this->performance_score;

    if ($score >= 90) return 'A+';
    if ($score >= 85) return 'A';
    if ($score >= 80) return 'B+';
    if ($score >= 75) return 'B';
    if ($score >= 70) return 'C+';
    if ($score >= 65) return 'C';
    return 'D';
}

// Clear cache when employee data changes
protected static function booted()
{
    static::updated(function ($employee) {
        cache()->forget("employee.{$employee->id}.total_sales");
        cache()->forget("employee.{$employee->id}.customer_satisfaction");
        cache()->forget("employee.{$employee->id}.reporting_chain");
        cache()->forget("employee.{$employee->id}.direct_reports_count");
        cache()->forget("employee.{$employee->id}.customer_workload");
    });
}
````
</augment_code_snippet>

## Authorization Policies

<augment_code_snippet path="app/Policies/Chinook/EmployeePolicy.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Policies\Chinook;

use App\Models\Chinook\Employee;
use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

class EmployeePolicy
{
    use HandlesAuthorization;

    /**
     * Determine whether the user can view any models.
     */
    public function viewAny(User $user): bool
    {
        return $user->can('view_any_chinook::employee');
    }

    /**
     * Determine whether the user can view the model.
     */
    public function view(User $user, Employee $employee): bool
    {
        return $user->can('view_chinook::employee');
    }

    /**
     * Determine whether the user can create models.
     */
    public function create(User $user): bool
    {
        return $user->can('create_chinook::employee');
    }

    /**
     * Determine whether the user can update the model.
     */
    public function update(User $user, Employee $employee): bool
    {
        return $user->can('update_chinook::employee');
    }

    /**
     * Determine whether the user can delete the model.
     */
    public function delete(User $user, Employee $employee): bool
    {
        // Prevent deletion if employee has customers assigned
        if ($employee->customers()->exists()) {
            return false;
        }

        // Prevent deletion if employee has subordinates
        if ($employee->subordinates()->exists()) {
            return false;
        }

        return $user->can('delete_chinook::employee');
    }

    /**
     * Determine whether the user can bulk delete.
     */
    public function deleteAny(User $user): bool
    {
        return $user->can('delete_any_chinook::employee');
    }

    /**
     * Determine whether the user can permanently delete.
     */
    public function forceDelete(User $user, Employee $employee): bool
    {
        return $user->can('force_delete_chinook::employee');
    }

    /**
     * Determine whether the user can permanently bulk delete.
     */
    public function forceDeleteAny(User $user): bool
    {
        return $user->can('force_delete_any_chinook::employee');
    }

    /**
     * Determine whether the user can restore.
     */
    public function restore(User $user, Employee $employee): bool
    {
        return $user->can('restore_chinook::employee');
    }

    /**
     * Determine whether the user can bulk restore.
     */
    public function restoreAny(User $user): bool
    {
        return $user->can('restore_any_chinook::employee');
    }

    /**
     * Determine whether the user can replicate.
     */
    public function replicate(User $user, Employee $employee): bool
    {
        return $user->can('replicate_chinook::employee');
    }

    /**
     * Determine whether the user can reorder.
     */
    public function reorder(User $user): bool
    {
        return $user->can('reorder_chinook::employee');
    }

    /**
     * Determine whether the user can assign customers to employees.
     */
    public function assignCustomers(User $user): bool
    {
        return $user->can('assign_customers_chinook::employee');
    }

    /**
     * Determine whether the user can manage organizational hierarchy.
     */
    public function manageHierarchy(User $user): bool
    {
        return $user->can('manage_hierarchy_chinook::employee');
    }

    /**
     * Determine whether the user can view employee performance data.
     */
    public function viewPerformance(User $user, Employee $employee): bool
    {
        // Managers can view their subordinates' performance
        if ($employee->manager_id === $user->employee?->id) {
            return true;
        }

        // HR can view all performance data
        if ($user->employee?->department === 'HR') {
            return true;
        }

        return $user->can('view_performance_chinook::employee');
    }

    /**
     * Determine whether the user can view salary information.
     */
    public function viewSalary(User $user, Employee $employee): bool
    {
        // Only HR and senior management can view salary information
        if (in_array($user->employee?->department, ['HR', 'Management'])) {
            return true;
        }

        return $user->can('view_salary_chinook::employee');
    }
}
````
</augment_code_snippet>

## 10.7. Testing Examples

### 10.7.1. Resource Test

<augment_code_snippet path="tests/Feature/Filament/EmployeeResourceTest.php" mode="EXCERPT">

````php
<?php

namespace Tests\Feature\Filament;

use App\Models\Chinook\Employee;use App\Models\User;use old\TestCase;

class EmployeeResourceTest extends TestCase
{
    public function test_can_create_employee_with_manager(): void
    {
        $user = User::factory()->create();
        $manager = Employee::factory()->create();

        $this->actingAs($user)
            ->post(route('filament.chinook-admin.resources.employees.store'), [
                'first_name' => 'John',
                'last_name' => 'Doe',
                'email' => 'john.doe@company.com',
                'title' => 'Sales Representative',
                'department' => 'Sales',
                'reports_to' => $manager->id,
                'hire_date' => now()->format('Y-m-d'),
                'is_active' => true,
            ])
            ->assertRedirect();

        $this->assertDatabaseHas('chinook_employees', [
            'first_name' => 'John',
            'last_name' => 'Doe',
            'reports_to' => $manager->id,
        ]);
    }

    public function test_employee_reporting_chain(): void
    {
        $ceo = Employee::factory()->create(['title' => 'CEO']);
        $manager = Employee::factory()->create([
            'title' => 'Manager',
            'reports_to' => $ceo->id,
        ]);
        $employee = Employee::factory()->create([
            'title' => 'Employee',
            'reports_to' => $manager->id,
        ]);

        $chain = $employee->getReportingChain();

        $this->assertCount(3, $chain);
        $this->assertEquals($employee->id, $chain->first()->id);
        $this->assertEquals($ceo->id, $chain->last()->id);
    }

    public function test_employee_performance_calculations(): void
    {
        $employee = Employee::factory()->create();
        Customer::factory()->count(5)->for($employee, 'supportRep')->create();

        $this->assertEquals(5, $employee->customer_workload);
        $this->assertIsFloat($employee->performance_score);
        $this->assertIsString($employee->performance_grade);
    }

    public function test_cannot_delete_employee_with_customers(): void
    {
        $employee = Employee::factory()->create();
        Customer::factory()->for($employee, 'supportRep')->create();

        $this->assertFalse($this->user->can('delete', $employee));
    }

    public function test_cannot_delete_employee_with_subordinates(): void
    {
        $manager = Employee::factory()->create();
        Employee::factory()->for($manager, 'manager')->create();

        $this->assertFalse($this->user->can('delete', $manager));
    }
}
````
</augment_code_snippet>

## Performance Optimization

### Query Optimization

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/EmployeeResource.php" mode="EXCERPT">
````php
// Optimized Eloquent query with eager loading
public static function getEloquentQuery(): Builder
{
    return parent::getEloquentQuery()
        ->with([
            'manager:id,first_name,last_name,title,department',
            'subordinates:id,first_name,last_name,title,reports_to',
            'customers:id,first_name,last_name,email,support_rep_id',
        ])
        ->withCount([
            'subordinates',
            'customers',
        ])
        ->withoutGlobalScopes([
            SoftDeletingScope::class,
        ]);
}

// Optimized table query
public static function table(Table $table): Table
{
    return $table
        ->deferLoading() // Improve initial page load
        ->persistSearchInSession()
        ->persistSortInSession()
        ->persistFiltersInSession()
        ->defaultPaginationPageOption(25)
        ->paginationPageOptions([10, 25, 50, 100])
        ->extremePaginationLinks()
        ->poll('600s'); // Auto-refresh every 10 minutes
}
````
</augment_code_snippet>

### Database Indexing

<augment_code_snippet path="database/migrations/create_chinook_employees_table.php" mode="EXCERPT">
````php
// Optimized indexes for Filament queries
Schema::create('chinook_employees', function (Blueprint $table) {
    $table->id();
    $table->string('first_name', 20)->index(); // For searching and sorting
    $table->string('last_name', 20)->index(); // For searching and sorting
    $table->string('email', 60)->unique(); // For searching and uniqueness
    $table->string('department', 50)->index(); // For filtering
    $table->foreignId('reports_to')->nullable()->constrained('chinook_employees')->index(); // For hierarchical queries
    $table->boolean('is_active')->default(true)->index(); // For filtering
    $table->string('public_id')->unique();
    $table->string('slug')->unique();

    // Composite indexes for common queries
    $table->index(['department', 'is_active']);
    $table->index(['reports_to', 'is_active']);
    $table->index(['first_name', 'last_name']);
    $table->index(['hire_date', 'department']);

    // Full-text search index
    $table->fullText(['first_name', 'last_name', 'email', 'title']);

    $table->timestamps();
    $table->softDeletes();
});
````
</augment_code_snippet>

---

## Navigation

**← Previous:** [Customers Resource](070-customers-resource.md) | **Next →** [Invoices Resource](080-invoices-resource.md)

---

## Related Documentation

- [Chinook Models Guide](../../020-database/030-models-guide.md)
- [Customer Resource Guide](070-customers-resource.md)
- [Invoice Resource Guide](080-invoices-resource.md)
- [Authorization Policies Guide](../../050-security/020-authorization-policies.md)
- [Performance Optimization Guide](../../070-performance/000-index.md)
- [Hierarchical Data Management](../../020-database/040-advanced-relationships.md)
- [Employee Performance Tracking](../../065-testing/050-testing-implementation-examples.md)

---

**Documentation Standards**: This document follows WCAG 2.1 AA accessibility guidelines and uses Laravel 12 modern syntax patterns.

**Last Updated:** 2025-07-18
**Maintainer:** Technical Documentation Team
**Source:** [GitHub Repository](https://github.com/s-a-c/chinook)

[⬆️ Back to Top](#employees-resource---complete-implementation-guide)
