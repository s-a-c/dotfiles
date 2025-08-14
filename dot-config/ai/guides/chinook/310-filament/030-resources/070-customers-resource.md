# Customers Resource - Complete Implementation Guide

> **Created:** 2025-07-16
> **Updated:** 2025-07-18
> **Focus:** Complete Customer management with working code examples, invoice relationship managers, and support representative integration
> **Source:** [Chinook Customer Model](https://github.com/s-a-c/chinook/blob/main/app/Models/Chinook/Customer.php)

## Table of Contents

- [Overview](#overview)
- [Resource Implementation](#resource-implementation)
  - [Basic Resource Structure](#basic-resource-structure)
  - [Form Schema](#form-schema)
  - [Table Configuration](#table-configuration)
- [Relationship Management](#relationship-management)
  - [Invoices Relationship Manager](#invoices-relationship-manager)
  - [Support Representative Relationship Manager](#support-representative-relationship-manager)
- [Customer Analytics](#customer-analytics)
- [Authorization Policies](#authorization-policies)
- [Advanced Features](#advanced-features)
- [Testing Examples](#testing-examples)
- [Performance Optimization](#performance-optimization)

## Overview

The Customers Resource provides comprehensive management of customer records within the Chinook admin panel. It features complete CRUD operations, invoice relationship management, support representative assignment, customer analytics, and enhanced customer data including contact information, purchase history, and GDPR-compliant marketing consent tracking with full Laravel 12 compatibility.

### Key Features

- **Complete CRUD Operations**: Create, read, update, delete customers with comprehensive validation
- **Invoice Management**: Inline invoices relationship manager with purchase history and analytics
- **Support Representative**: Assignment and management of customer support relationships with workload balancing
- **Contact Information**: Comprehensive address and contact data management with international support
- **Purchase Analytics**: Customer lifetime value, purchase pattern analysis, and sales reporting
- **Marketing Consent**: GDPR-compliant marketing consent tracking with audit trails
- **Customer Segmentation**: Advanced filtering and segmentation based on purchase behavior
- **Communication Tracking**: Integration with support tickets and communication history
- **Search & Filtering**: Advanced search with support rep, country, and purchase behavior filtering
- **Bulk Operations**: Mass operations with permission checking and activity logging

### Model Integration

<augment_code_snippet path="app/Models/Chinook/Customer.php" mode="EXCERPT">
````php
class Customer extends BaseModel
{
    use HasTaxonomy; // From BaseModel - enables customer segmentation

    protected $table = 'chinook_customers';

    protected $fillable = [
        'first_name', 'last_name', 'company', 'address', 'city', 'state',
        'country', 'postal_code', 'phone', 'fax', 'email', 'support_rep_id',
        'public_id', 'slug', 'date_of_birth', 'preferred_language', 'marketing_consent',
    ];

    // Relationships
    public function supportRep(): BelongsTo // Employee who supports this customer
    public function invoices(): HasMany // Customer's purchase history

    // Accessors
    public function getFullNameAttribute(): string
    public function getRouteKeyName(): string // Uses slug for URLs

    // Analytics Methods
    public function getLifetimeValueAttribute(): float
    public function getAverageOrderValueAttribute(): float
    public function getLastPurchaseDateAttribute(): ?Carbon
    public function getTotalOrdersAttribute(): int

    // Casts
    protected function casts(): array {
        'date_of_birth' => 'date',
        'marketing_consent' => 'boolean',
    }

    // Scopes for customer segmentation
    public function scopeHighValue($query, float $threshold = 100.00)
    public function scopeRecentCustomers($query, int $days = 30)
    public function scopeWithSupportRep($query, int $supportRepId)
    public function scopeByCountry($query, string $country)
````
</augment_code_snippet>

## Resource Implementation

### Basic Resource Structure

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/CustomerResource.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Filament\ChinookAdmin\Resources;

use App\Models\Chinook\Customer;
use App\Models\Chinook\Employee;
use App\Models\Chinook\Invoice;
use App\Filament\ChinookAdmin\Resources\CustomerResource\Pages;
use App\Filament\ChinookAdmin\Resources\CustomerResource\RelationManagers;
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

class CustomerResource extends Resource
{
    protected static ?string $model = Customer::class;

    protected static ?string $navigationIcon = 'heroicon-o-users';

    protected static ?string $navigationGroup = 'Customer Management';

    protected static ?int $navigationSort = 1;

    protected static ?string $recordTitleAttribute = 'full_name';

    protected static ?string $navigationBadgeTooltip = 'Total customers in database';

    protected static int $globalSearchResultsLimit = 20;

    public static function getNavigationBadge(): ?string
    {
        return static::getModel()::count();
    }

    public static function getGlobalSearchResultTitle(Model $record): string
    {
        return $record->full_name;
    }

    public static function getGlobalSearchResultDetails(Model $record): array
    {
        return [
            'Email' => $record->email,
            'Company' => $record->company,
            'Country' => $record->country,
            'Support Rep' => $record->supportRep?->full_name,
            'Total Orders' => $record->invoices_count ?? $record->invoices()->count(),
            'Lifetime Value' => '$' . number_format($record->lifetime_value ?? 0, 2),
        ];
    }
````
</augment_code_snippet>

### Form Schema

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/CustomerResource.php" mode="EXCERPT">
````php
public static function form(Form $form): Form
{
    return $form
        ->schema([
            Forms\Components\Section::make('Personal Information')
                ->schema([
                    Forms\Components\TextInput::make('first_name')
                        ->required()
                        ->maxLength(40)
                        ->live(onBlur: true)
                        ->afterStateUpdated(function (string $context, $state, callable $set, callable $get) {
                            if ($context === 'create' && $state && $get('last_name')) {
                                $fullName = $state . ' ' . $get('last_name');
                                $set('slug', Str::slug($fullName));
                            }
                        })
                        ->helperText('Customer\'s first name'),

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
                        ->helperText('Customer\'s last name'),

                    Forms\Components\TextInput::make('slug')
                        ->required()
                        ->maxLength(255)
                        ->unique(Customer::class, 'slug', ignoreRecord: true)
                        ->rules(['alpha_dash'])
                        ->helperText('URL-friendly version of the customer name'),

                    Forms\Components\TextInput::make('company')
                        ->maxLength(80)
                        ->placeholder('e.g., Apple Inc.')
                        ->helperText('Company or organization name (optional)'),

                    Forms\Components\TextInput::make('email')
                        ->email()
                        ->required()
                        ->maxLength(60)
                        ->unique(Customer::class, 'email', ignoreRecord: true)
                        ->suffixIcon('heroicon-m-envelope')
                        ->helperText('Primary email address for communication'),

                    Forms\Components\DatePicker::make('date_of_birth')
                        ->native(false)
                        ->maxDate(now()->subYears(13))
                        ->displayFormat('M d, Y')
                        ->helperText('Must be at least 13 years old'),

                    Forms\Components\Select::make('preferred_language')
                        ->options([
                            'en' => '🇺🇸 English',
                            'fr' => '🇫🇷 French',
                            'de' => '🇩🇪 German',
                            'es' => '🇪🇸 Spanish',
                            'pt' => '🇵🇹 Portuguese',
                            'it' => '🇮🇹 Italian',
                            'ja' => '🇯🇵 Japanese',
                            'zh' => '🇨🇳 Chinese',
                        ])
                        ->default('en')
                        ->searchable()
                        ->helperText('Preferred language for communications'),
                ])
                ->columns(2),

            Forms\Components\Section::make('Contact Information')
                ->schema([
                    Forms\Components\TextInput::make('address')
                        ->maxLength(70)
                        ->placeholder('123 Main Street')
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
                            'IT' => '🇮🇹 Italy',
                            'ES' => '🇪🇸 Spain',
                            'AU' => '🇦🇺 Australia',
                            'JP' => '🇯🇵 Japan',
                            'BR' => '🇧🇷 Brazil',
                            'IN' => '🇮🇳 India',
                            'CN' => '🇨🇳 China',
                            'MX' => '🇲🇽 Mexico',
                            'NL' => '🇳🇱 Netherlands',
                            'SE' => '🇸🇪 Sweden',
                            'NO' => '🇳🇴 Norway',
                            'DK' => '🇩🇰 Denmark',
                            'FI' => '🇫🇮 Finland',
                            'CH' => '🇨🇭 Switzerland',
                            'AT' => '🇦🇹 Austria',
                        ])
                        ->default('US')
                        ->helperText('Customer\'s country'),

                    Forms\Components\TextInput::make('postal_code')
                        ->maxLength(10)
                        ->placeholder('10001')
                        ->helperText('ZIP or postal code'),

                    Forms\Components\TextInput::make('phone')
                        ->tel()
                        ->maxLength(24)
                        ->placeholder('+1 (555) 123-4567')
                        ->suffixIcon('heroicon-m-phone')
                        ->helperText('Primary phone number'),

                    Forms\Components\TextInput::make('fax')
                        ->maxLength(24)
                        ->placeholder('+1 (555) 123-4568')
                        ->suffixIcon('heroicon-m-printer')
                        ->helperText('Fax number (optional)'),
                ])
                ->columns(2),

            Forms\Components\Section::make('Support & Preferences')
                ->schema([
                    Forms\Components\Select::make('support_rep_id')
                        ->label('Support Representative')
                        ->relationship('supportRep', 'first_name')
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
                            Forms\Components\Select::make('reports_to')
                                ->label('Manager')
                                ->relationship('manager', 'first_name')
                                ->getOptionLabelFromRecordUsing(fn (Employee $record) =>
                                    "{$record->first_name} {$record->last_name}"
                                ),
                        ])
                        ->createOptionUsing(function (array $data) {
                            return Employee::create($data);
                        })
                        ->helperText('Assign a support representative to this customer'),

                    Forms\Components\Toggle::make('marketing_consent')
                        ->label('Marketing Consent')
                        ->helperText('Customer has consented to receive marketing communications (GDPR compliant)')
                        ->live()
                        ->afterStateUpdated(function ($state, callable $set) {
                            if ($state) {
                                $set('marketing_consent_date', now());
                            }
                        }),

                    Forms\Components\DateTimePicker::make('marketing_consent_date')
                        ->label('Consent Date')
                        ->native(false)
                        ->visible(fn (callable $get) => $get('marketing_consent'))
                        ->disabled()
                        ->helperText('Date when marketing consent was given'),
                ])
                ->columns(2),

            Forms\Components\Section::make('Additional Information')
                ->schema([
                    Forms\Components\KeyValue::make('custom_fields')
                        ->keyLabel('Field Name')
                        ->valueLabel('Value')
                        ->addActionLabel('Add custom field')
                        ->helperText('Additional customer information and preferences')
                        ->columnSpanFull(),
                ])
                ->collapsible(),
        ]);
}
````
</augment_code_snippet>

### Table Configuration

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/CustomerResource.php" mode="EXCERPT">
````php
public static function table(Table $table): Table
{
    return $table
        ->columns([
            Tables\Columns\TextColumn::make('full_name')
                ->label('Customer Name')
                ->getStateUsing(fn (Customer $record): string =>
                    "{$record->first_name} {$record->last_name}"
                )
                ->searchable(['first_name', 'last_name'])
                ->sortable(['first_name', 'last_name'])
                ->weight('bold')
                ->description(fn (Customer $record): string =>
                    $record->company ? "Company: {$record->company}" : ''
                ),

            Tables\Columns\TextColumn::make('email')
                ->searchable()
                ->sortable()
                ->copyable()
                ->icon('heroicon-m-envelope')
                ->iconColor('primary'),

            Tables\Columns\TextColumn::make('city')
                ->searchable()
                ->sortable()
                ->description(fn (Customer $record): string =>
                    $record->state ? "{$record->state}, {$record->country}" : $record->country ?? ''
                )
                ->toggleable(),

            Tables\Columns\TextColumn::make('country')
                ->badge()
                ->searchable()
                ->sortable()
                ->formatStateUsing(function ($state) {
                    $flags = [
                        'US' => '🇺🇸', 'CA' => '🇨🇦', 'GB' => '🇬🇧', 'DE' => '🇩🇪',
                        'FR' => '🇫🇷', 'IT' => '🇮🇹', 'ES' => '🇪🇸', 'AU' => '🇦🇺',
                        'JP' => '🇯🇵', 'BR' => '🇧🇷', 'IN' => '🇮🇳', 'CN' => '🇨🇳',
                    ];
                    $flag = $flags[$state] ?? '';
                    return $flag . ' ' . $state;
                }),

            Tables\Columns\TextColumn::make('supportRep.full_name')
                ->label('Support Rep')
                ->getStateUsing(fn (Customer $record): ?string =>
                    $record->supportRep ?
                    "{$record->supportRep->first_name} {$record->supportRep->last_name}" :
                    'Unassigned'
                )
                ->url(fn (Customer $record): ?string =>
                    $record->supportRep ?
                    route('filament.chinook-admin.resources.employees.view', $record->supportRep) :
                    null
                )
                ->openUrlInNewTab()
                ->badge()
                ->color(fn (Customer $record): string =>
                    $record->supportRep ? 'success' : 'warning'
                )
                ->toggleable(),

            Tables\Columns\TextColumn::make('invoices_count')
                ->label('Orders')
                ->counts('invoices')
                ->badge()
                ->color('info')
                ->sortable(),

            Tables\Columns\TextColumn::make('lifetime_value')
                ->label('Lifetime Value')
                ->getStateUsing(fn (Customer $record): string =>
                    '$' . number_format($record->invoices()->sum('total'), 2)
                )
                ->sortable()
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
                ->sortable()
                ->toggleable(),

            Tables\Columns\IconColumn::make('marketing_consent')
                ->boolean()
                ->trueIcon('heroicon-o-check-circle')
                ->falseIcon('heroicon-o-x-circle')
                ->trueColor('success')
                ->falseColor('danger')
                ->label('Marketing')
                ->toggleable(),

            Tables\Columns\TextColumn::make('phone')
                ->searchable()
                ->copyable()
                ->icon('heroicon-m-phone')
                ->toggleable(isToggledHiddenByDefault: true),

            Tables\Columns\TextColumn::make('preferred_language')
                ->badge()
                ->formatStateUsing(function ($state) {
                    $languages = [
                        'en' => '🇺🇸 EN', 'fr' => '🇫🇷 FR', 'de' => '🇩🇪 DE',
                        'es' => '🇪🇸 ES', 'pt' => '🇵🇹 PT', 'it' => '🇮🇹 IT',
                    ];
                    return $languages[$state] ?? strtoupper($state);
                })
                ->toggleable(isToggledHiddenByDefault: true),

            Tables\Columns\TextColumn::make('created_at')
                ->label('Registered')
                ->dateTime('M d, Y')
                ->sortable()
                ->toggleable(isToggledHiddenByDefault: true),

            Tables\Columns\TextColumn::make('updated_at')
                ->dateTime()
                ->sortable()
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
                    'IT' => '🇮🇹 Italy',
                    'ES' => '🇪🇸 Spain',
                    'AU' => '🇦🇺 Australia',
                    'JP' => '🇯🇵 Japan',
                    'BR' => '🇧🇷 Brazil',
                ])
                ->multiple()
                ->searchable(),

            Tables\Filters\SelectFilter::make('support_rep_id')
                ->label('Support Representative')
                ->relationship('supportRep', 'first_name')
                ->getOptionLabelFromRecordUsing(fn (Employee $record) =>
                    "{$record->first_name} {$record->last_name} - {$record->title}"
                )
                ->multiple()
                ->searchable(),

            Tables\Filters\TernaryFilter::make('marketing_consent')
                ->label('Marketing Consent')
                ->trueLabel('Consented')
                ->falseLabel('Not Consented')
                ->native(false),

            Tables\Filters\Filter::make('has_orders')
                ->label('Has Orders')
                ->query(fn (Builder $query): Builder =>
                    $query->has('invoices')
                ),

            Tables\Filters\Filter::make('no_support_rep')
                ->label('No Support Rep')
                ->query(fn (Builder $query): Builder =>
                    $query->whereNull('support_rep_id')
                ),

            Tables\Filters\Filter::make('high_value_customers')
                ->label('High Value (>$100)')
                ->query(fn (Builder $query): Builder =>
                    $query->whereHas('invoices', function ($q) {
                        $q->havingRaw('SUM(total) > 100');
                    })
                ),

            Tables\Filters\Filter::make('recent_customers')
                ->label('Recent (30 days)')
                ->query(fn (Builder $query): Builder =>
                    $query->where('created_at', '>=', now()->subDays(30))
                ),

            Tables\Filters\Filter::make('inactive_customers')
                ->label('Inactive (No orders in 90 days)')
                ->query(fn (Builder $query): Builder =>
                    $query->whereDoesntHave('invoices', function ($q) {
                        $q->where('invoice_date', '>=', now()->subDays(90));
                    })
                ),

            Tables\Filters\SelectFilter::make('preferred_language')
                ->options([
                    'en' => '🇺🇸 English',
                    'fr' => '🇫🇷 French',
                    'de' => '🇩🇪 German',
                    'es' => '🇪🇸 Spanish',
                    'pt' => '🇵🇹 Portuguese',
                ])
                ->multiple(),

            Tables\Filters\Filter::make('lifetime_value_range')
                ->form([
                    Forms\Components\TextInput::make('min_value')
                        ->label('Min Lifetime Value')
                        ->numeric()
                        ->prefix('$'),
                    Forms\Components\TextInput::make('max_value')
                        ->label('Max Lifetime Value')
                        ->numeric()
                        ->prefix('$'),
                ])
                ->query(function (Builder $query, array $data): Builder {
                    return $query
                        ->when($data['min_value'], function ($q) use ($data) {
                            $q->whereHas('invoices', function ($invoiceQuery) use ($data) {
                                $invoiceQuery->havingRaw('SUM(total) >= ?', [$data['min_value']]);
                            });
                        })
                        ->when($data['max_value'], function ($q) use ($data) {
                            $q->whereHas('invoices', function ($invoiceQuery) use ($data) {
                                $invoiceQuery->havingRaw('SUM(total) <= ?', [$data['max_value']]);
                            });
                        });
                }),

            Tables\Filters\TrashedFilter::make(),
        ])
        ->actions([
            Tables\Actions\ViewAction::make(),
            Tables\Actions\EditAction::make(),
            Tables\Actions\DeleteAction::make(),
            Tables\Actions\RestoreAction::make(),
            Tables\Actions\ForceDeleteAction::make(),

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
                        ->title('Email sent successfully')
                        ->success()
                        ->send();
                })
                ->visible(fn (Customer $record): bool => $record->marketing_consent),
        ])

        ->bulkActions([
            Tables\Actions\BulkActionGroup::make([
                Tables\Actions\DeleteBulkAction::make(),
                Tables\Actions\RestoreBulkAction::make(),
                Tables\Actions\ForceDeleteBulkAction::make(),

                Tables\Actions\BulkAction::make('assign_support_rep')
                    ->label('Assign Support Rep')
                    ->icon('heroicon-o-user-plus')
                    ->form([
                        Forms\Components\Select::make('support_rep_id')
                            ->label('Support Representative')
                            ->relationship('supportRep', 'first_name')
                            ->getOptionLabelFromRecordUsing(fn (Employee $record) =>
                                "{$record->first_name} {$record->last_name} - {$record->title}"
                            )
                            ->required()
                            ->searchable(),
                    ])
                    ->action(function (Collection $records, array $data) {
                        $records->each(function (Customer $customer) use ($data) {
                            $customer->update(['support_rep_id' => $data['support_rep_id']]);
                        });

                        Notification::make()
                            ->title('Support representatives assigned successfully')
                            ->success()
                            ->send();
                    })
                    ->deselectRecordsAfterCompletion()
                    ->requiresConfirmation(),

                Tables\Actions\BulkAction::make('update_marketing_consent')
                    ->label('Update Marketing Consent')
                    ->icon('heroicon-o-envelope')
                    ->form([
                        Forms\Components\Toggle::make('marketing_consent')
                            ->label('Marketing Consent')
                            ->required(),
                    ])
                    ->action(function (Collection $records, array $data) {
                        $records->each->update([
                            'marketing_consent' => $data['marketing_consent'],
                            'marketing_consent_date' => $data['marketing_consent'] ? now() : null,
                        ]);
                    })
                    ->deselectRecordsAfterCompletion()
                    ->requiresConfirmation(),

                Tables\Actions\BulkAction::make('export_customers')
                    ->label('Export Selected')
                    ->icon('heroicon-o-arrow-down-tray')
                    ->action(function (Collection $records) {
                        return response()->streamDownload(function () use ($records) {
                            echo "Name,Email,Company,Country,Support Rep,Total Orders,Lifetime Value\n";
                            foreach ($records as $customer) {
                                $supportRep = $customer->supportRep ?
                                    "{$customer->supportRep->first_name} {$customer->supportRep->last_name}" :
                                    'Unassigned';
                                $lifetimeValue = $customer->invoices()->sum('total');
                                echo "\"{$customer->full_name}\",\"{$customer->email}\",\"{$customer->company}\",\"{$customer->country}\",\"{$supportRep}\",{$customer->invoices()->count()},\${$lifetimeValue}\n";
                            }
                        }, 'customers-export.csv');
                    }),
            ]),
        ])
        ->defaultSort('created_at', 'desc')
        ->persistSortInSession()
        ->persistSearchInSession()
        ->persistFiltersInSession();
}
````
</augment_code_snippet>

## Relationship Management

### Invoices Relationship Manager

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/CustomerResource/RelationManagers/InvoicesRelationManager.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Filament\ChinookAdmin\Resources\CustomerResource\RelationManagers;

use App\Models\Chinook\Invoice;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class InvoicesRelationManager extends RelationManager
{
    protected static string $relationship = 'invoices';

    protected static ?string $recordTitleAttribute = 'id';

    protected static ?string $navigationIcon = 'heroicon-o-shopping-bag';

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('id')
            ->columns([
                Tables\Columns\TextColumn::make('id')
                    ->label('Invoice #')
                    ->prefix('#')
                    ->sortable()
                    ->searchable()
                    ->weight('bold'),

                Tables\Columns\TextColumn::make('invoice_date')
                    ->label('Date')
                    ->date('M d, Y')
                    ->sortable()
                    ->description(fn (Invoice $record): string =>
                        $record->invoice_date->diffForHumans()
                    ),

                Tables\Columns\TextColumn::make('billing_city')
                    ->label('Billing Location')
                    ->searchable()
                    ->description(fn (Invoice $record): string =>
                        "{$record->billing_state}, {$record->billing_country}"
                    ),

                Tables\Columns\TextColumn::make('billing_country')
                    ->label('Country')
                    ->badge()
                    ->formatStateUsing(function ($state) {
                        $flags = [
                            'US' => '🇺🇸', 'CA' => '🇨🇦', 'GB' => '🇬🇧', 'DE' => '🇩🇪',
                            'FR' => '🇫🇷', 'IT' => '🇮🇹', 'ES' => '🇪🇸', 'AU' => '🇦🇺',
                        ];
                        $flag = $flags[$state] ?? '';
                        return $flag . ' ' . $state;
                    }),

                Tables\Columns\TextColumn::make('total')
                    ->money('USD')
                    ->sortable()
                    ->weight('bold')
                    ->color('success'),

                Tables\Columns\TextColumn::make('payment_status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'paid' => 'success',
                        'pending' => 'warning',
                        'failed' => 'danger',
                        'refunded' => 'info',
                        default => 'gray',
                    }),

                Tables\Columns\TextColumn::make('payment_method')
                    ->badge()
                    ->color('info')
                    ->toggleable(),

                Tables\Columns\TextColumn::make('invoice_lines_count')
                    ->label('Items')
                    ->counts('invoiceLines')
                    ->badge()
                    ->color('primary'),

                Tables\Columns\TextColumn::make('notes')
                    ->limit(50)
                    ->tooltip(function (Invoice $record): ?string {
                        return $record->notes;
                    })
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('payment_status')
                    ->options([
                        'paid' => 'Paid',
                        'pending' => 'Pending',
                        'failed' => 'Failed',
                        'refunded' => 'Refunded',
                    ])
                    ->multiple(),

                Tables\Filters\SelectFilter::make('billing_country')
                    ->options([
                        'US' => '🇺🇸 United States',
                        'CA' => '🇨🇦 Canada',
                        'GB' => '🇬🇧 United Kingdom',
                        'DE' => '🇩🇪 Germany',
                        'FR' => '🇫🇷 France',
                    ])
                    ->multiple(),

                Tables\Filters\Filter::make('date_range')
                    ->form([
                        Forms\Components\DatePicker::make('from')
                            ->label('From Date'),
                        Forms\Components\DatePicker::make('until')
                            ->label('Until Date'),
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return $query
                            ->when(
                                $data['from'],
                                fn (Builder $query, $date): Builder =>
                                    $query->whereDate('invoice_date', '>=', $date)
                            )
                            ->when(
                                $data['until'],
                                fn (Builder $query, $date): Builder =>
                                    $query->whereDate('invoice_date', '<=', $date)
                            );
                    }),

                Tables\Filters\Filter::make('high_value')
                    ->label('High Value (>$50)')
                    ->query(fn (Builder $query): Builder =>
                        $query->where('total', '>', 50)
                    ),
            ])
            ->headerActions([
                Tables\Actions\CreateAction::make()
                    ->form([
                        Forms\Components\DatePicker::make('invoice_date')
                            ->required()
                            ->default(now()),
                        Forms\Components\TextInput::make('billing_address')
                            ->maxLength(70),
                        Forms\Components\TextInput::make('billing_city')
                            ->maxLength(40),
                        Forms\Components\TextInput::make('billing_state')
                            ->maxLength(40),
                        Forms\Components\Select::make('billing_country')
                            ->options([
                                'US' => 'United States',
                                'CA' => 'Canada',
                                'GB' => 'United Kingdom',
                            ])
                            ->required(),
                        Forms\Components\TextInput::make('billing_postal_code')
                            ->maxLength(10),
                        Forms\Components\Select::make('payment_method')
                            ->options([
                                'credit_card' => 'Credit Card',
                                'paypal' => 'PayPal',
                                'bank_transfer' => 'Bank Transfer',
                            ])
                            ->default('credit_card'),
                        Forms\Components\Select::make('payment_status')
                            ->options([
                                'pending' => 'Pending',
                                'paid' => 'Paid',
                                'failed' => 'Failed',
                            ])
                            ->default('pending'),
                        Forms\Components\Textarea::make('notes')
                            ->maxLength(500),
                    ]),
            ])
            ->actions([
                Tables\Actions\ViewAction::make()
                    ->url(fn (Invoice $record): string =>
                        route('filament.chinook-admin.resources.invoices.view', $record)
                    )
                    ->openUrlInNewTab(),

                Tables\Actions\EditAction::make()
                    ->form([
                        Forms\Components\Select::make('payment_status')
                            ->options([
                                'pending' => 'Pending',
                                'paid' => 'Paid',
                                'failed' => 'Failed',
                                'refunded' => 'Refunded',
                            ])
                            ->required(),
                        Forms\Components\Textarea::make('notes')
                            ->maxLength(500),
                    ]),

                Tables\Actions\Action::make('view_items')
                    ->label('View Items')
                    ->icon('heroicon-o-list-bullet')
                    ->url(fn (Invoice $record): string =>
                        route('filament.chinook-admin.resources.invoice-lines.index', [
                            'tableFilters[invoice][value]' => $record->id
                        ])
                    )
                    ->openUrlInNewTab(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\BulkAction::make('mark_paid')
                        ->label('Mark as Paid')
                        ->icon('heroicon-o-check-circle')
                        ->action(fn (Collection $records) =>
                            $records->each->update(['payment_status' => 'paid'])
                        )
                        ->requiresConfirmation()
                        ->color('success'),

                    Tables\Actions\BulkAction::make('export_invoices')
                        ->label('Export Selected')
                        ->icon('heroicon-o-arrow-down-tray')
                        ->action(function (Collection $records) {
                            return response()->streamDownload(function () use ($records) {
                                echo "Invoice ID,Date,Total,Status,Country\n";
                                foreach ($records as $invoice) {
                                    echo "#{$invoice->id},{$invoice->invoice_date->format('Y-m-d')},\${$invoice->total},{$invoice->payment_status},{$invoice->billing_country}\n";
                                }
                            }, 'customer-invoices.csv');
                        }),
                ]),
            ])
            ->defaultSort('invoice_date', 'desc')
            ->paginated([10, 25, 50]);
    }
}
````
</augment_code_snippet>

### Support Representative Relationship Manager

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/CustomerResource/RelationManagers/SupportRepRelationManager.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Filament\ChinookAdmin\Resources\CustomerResource\RelationManagers;

use App\Models\Chinook\Employee;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;

class SupportRepRelationManager extends RelationManager
{
    protected static string $relationship = 'supportRep';

    protected static ?string $recordTitleAttribute = 'full_name';

    protected static ?string $navigationIcon = 'heroicon-o-user-circle';

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('full_name')
            ->columns([
                Tables\Columns\TextColumn::make('full_name')
                    ->label('Name')
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

                Tables\Columns\TextColumn::make('phone')
                    ->copyable()
                    ->icon('heroicon-m-phone'),

                Tables\Columns\TextColumn::make('department')
                    ->badge()
                    ->color('info'),

                Tables\Columns\TextColumn::make('customers_count')
                    ->label('Total Customers')
                    ->counts('customers')
                    ->badge()
                    ->color('success'),

                Tables\Columns\TextColumn::make('manager.full_name')
                    ->label('Manager')
                    ->getStateUsing(fn (Employee $record): ?string =>
                        $record->manager ?
                        "{$record->manager->first_name} {$record->manager->last_name}" :
                        null
                    ),

                Tables\Columns\IconColumn::make('is_active')
                    ->boolean()
                    ->label('Active'),

                Tables\Columns\TextColumn::make('hire_date')
                    ->date('M d, Y')
                    ->sortable(),
            ])
            ->actions([
                Tables\Actions\Action::make('view_employee')
                    ->label('View Employee')
                    ->icon('heroicon-o-eye')
                    ->url(fn (Employee $record): string =>
                        route('filament.chinook-admin.resources.employees.view', $record)
                    )
                    ->openUrlInNewTab(),

                Tables\Actions\Action::make('view_all_customers')
                    ->label('All Customers')
                    ->icon('heroicon-o-users')
                    ->url(fn (Employee $record): string =>
                        route('filament.chinook-admin.resources.customers.index', [
                            'tableFilters[support_rep_id][value]' => $record->id
                        ])
                    )
                    ->openUrlInNewTab(),

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
            ]);
    }
}
````
</augment_code_snippet>

## Customer Analytics

### Customer Metrics and Insights

<augment_code_snippet path="app/Models/Chinook/Customer.php" mode="EXCERPT">
````php
// Enhanced customer analytics methods
public function getLifetimeValueAttribute(): float
{
    return cache()->remember(
        "customer.{$this->id}.lifetime_value",
        now()->addHours(1),
        fn () => $this->invoices()->sum('total')
    );
}

public function getAverageOrderValueAttribute(): float
{
    return cache()->remember(
        "customer.{$this->id}.average_order_value",
        now()->addHours(1),
        function () {
            $invoiceCount = $this->invoices()->count();
            if ($invoiceCount === 0) return 0;
            return $this->invoices()->sum('total') / $invoiceCount;
        }
    );
}

public function getLastPurchaseDateAttribute(): ?Carbon
{
    return cache()->remember(
        "customer.{$this->id}.last_purchase_date",
        now()->addHours(1),
        fn () => $this->invoices()
            ->latest('invoice_date')
            ->first()
            ?->invoice_date
    );
}

public function getTotalOrdersAttribute(): int
{
    return cache()->remember(
        "customer.{$this->id}.total_orders",
        now()->addHours(1),
        fn () => $this->invoices()->count()
    );
}

public function getCustomerSegmentAttribute(): string
{
    $lifetimeValue = $this->lifetime_value;
    $totalOrders = $this->total_orders;

    if ($lifetimeValue >= 200 && $totalOrders >= 10) return 'VIP';
    if ($lifetimeValue >= 100 && $totalOrders >= 5) return 'High Value';
    if ($lifetimeValue >= 50 && $totalOrders >= 3) return 'Regular';
    if ($totalOrders >= 1) return 'New Customer';
    return 'Prospect';
}

public function getDaysSinceLastPurchaseAttribute(): ?int
{
    if (!$this->last_purchase_date) return null;
    return $this->last_purchase_date->diffInDays(now());
}

public function getCustomerStatusAttribute(): string
{
    $daysSinceLastPurchase = $this->days_since_last_purchase;

    if ($daysSinceLastPurchase === null) return 'Never Purchased';
    if ($daysSinceLastPurchase <= 30) return 'Active';
    if ($daysSinceLastPurchase <= 90) return 'At Risk';
    return 'Inactive';
}

// Scopes for customer segmentation
public function scopeHighValue($query, float $threshold = 100.00)
{
    return $query->whereHas('invoices', function ($q) use ($threshold) {
        $q->havingRaw('SUM(total) >= ?', [$threshold]);
    });
}

public function scopeRecentCustomers($query, int $days = 30)
{
    return $query->where('created_at', '>=', now()->subDays($days));
}

public function scopeWithSupportRep($query, int $supportRepId)
{
    return $query->where('support_rep_id', $supportRepId);
}

public function scopeByCountry($query, string $country)
{
    return $query->where('country', $country);
}

public function scopeInactive($query, int $days = 90)
{
    return $query->whereDoesntHave('invoices', function ($q) use ($days) {
        $q->where('invoice_date', '>=', now()->subDays($days));
    });
}

// Clear cache when customer data changes
protected static function booted()
{
    static::updated(function ($customer) {
        cache()->forget("customer.{$customer->id}.lifetime_value");
        cache()->forget("customer.{$customer->id}.average_order_value");
        cache()->forget("customer.{$customer->id}.last_purchase_date");
        cache()->forget("customer.{$customer->id}.total_orders");
    });
}
````
</augment_code_snippet>

### Customer Analytics Widget

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/CustomerResource/Widgets/CustomerAnalyticsWidget.php" mode="EXCERPT">
````php
<?php

namespace App\Filament\ChinookAdmin\Resources\CustomerResource\Widgets;

use App\Models\Chinook\Customer;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class CustomerAnalyticsWidget extends BaseWidget
{
    protected function getStats(): array
    {
        return [
            Stat::make('Total Customers', Customer::count())
                ->description('All registered customers')
                ->descriptionIcon('heroicon-m-arrow-trending-up')
                ->color('success'),

            Stat::make('Active Customers', Customer::whereHas('invoices', function ($q) {
                    $q->where('invoice_date', '>=', now()->subDays(90));
                })->count())
                ->description('Purchased in last 90 days')
                ->descriptionIcon('heroicon-m-shopping-bag')
                ->color('primary'),

            Stat::make('High Value Customers', Customer::highValue(100)->count())
                ->description('Lifetime value > $100')
                ->descriptionIcon('heroicon-m-currency-dollar')
                ->color('warning'),

            Stat::make('Avg Lifetime Value', '$' . number_format(Customer::whereHas('invoices')->get()->avg('lifetime_value'), 2))
                ->description('Average customer value')
                ->descriptionIcon('heroicon-m-banknotes')
                ->color('info'),

            Stat::make('New This Month', Customer::where('created_at', '>=', now()->startOfMonth())->count())
                ->description('Customers registered this month')
                ->descriptionIcon('heroicon-m-user-plus')
                ->color('success'),

            Stat::make('At Risk Customers', Customer::inactive(90)->count())
                ->description('No purchases in 90+ days')
                ->descriptionIcon('heroicon-m-exclamation-triangle')
                ->color('danger'),
        ];
    }
}
````
</augment_code_snippet>

## Authorization Policies

<augment_code_snippet path="app/Policies/Chinook/CustomerPolicy.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Policies\Chinook;

use App\Models\Chinook\Customer;
use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

class CustomerPolicy
{
    use HandlesAuthorization;

    /**
     * Determine whether the user can view any models.
     */
    public function viewAny(User $user): bool
    {
        return $user->can('view_any_chinook::customer');
    }

    /**
     * Determine whether the user can view the model.
     */
    public function view(User $user, Customer $customer): bool
    {
        return $user->can('view_chinook::customer');
    }

    /**
     * Determine whether the user can create models.
     */
    public function create(User $user): bool
    {
        return $user->can('create_chinook::customer');
    }

    /**
     * Determine whether the user can update the model.
     */
    public function update(User $user, Customer $customer): bool
    {
        return $user->can('update_chinook::customer');
    }

    /**
     * Determine whether the user can delete the model.
     */
    public function delete(User $user, Customer $customer): bool
    {
        // Prevent deletion if customer has invoices
        if ($customer->invoices()->exists()) {
            return false;
        }

        return $user->can('delete_chinook::customer');
    }

    /**
     * Determine whether the user can bulk delete.
     */
    public function deleteAny(User $user): bool
    {
        return $user->can('delete_any_chinook::customer');
    }

    /**
     * Determine whether the user can permanently delete.
     */
    public function forceDelete(User $user, Customer $customer): bool
    {
        return $user->can('force_delete_chinook::customer');
    }

    /**
     * Determine whether the user can permanently bulk delete.
     */
    public function forceDeleteAny(User $user): bool
    {
        return $user->can('force_delete_any_chinook::customer');
    }

    /**
     * Determine whether the user can restore.
     */
    public function restore(User $user, Customer $customer): bool
    {
        return $user->can('restore_chinook::customer');
    }

    /**
     * Determine whether the user can bulk restore.
     */
    public function restoreAny(User $user): bool
    {
        return $user->can('restore_any_chinook::customer');
    }

    /**
     * Determine whether the user can replicate.
     */
    public function replicate(User $user, Customer $customer): bool
    {
        return $user->can('replicate_chinook::customer');
    }

    /**
     * Determine whether the user can reorder.
     */
    public function reorder(User $user): bool
    {
        return $user->can('reorder_chinook::customer');
    }

    /**
     * Determine whether the user can send marketing emails.
     */
    public function sendMarketingEmail(User $user, Customer $customer): bool
    {
        // Only allow if customer has given marketing consent
        if (!$customer->marketing_consent) {
            return false;
        }

        return $user->can('send_marketing_email_chinook::customer');
    }

    /**
     * Determine whether the user can assign support representatives.
     */
    public function assignSupportRep(User $user): bool
    {
        return $user->can('assign_support_rep_chinook::customer');
    }

    /**
     * Determine whether the user can view customer analytics.
     */
    public function viewAnalytics(User $user): bool
    {
        return $user->can('view_analytics_chinook::customer');
    }
}
````
</augment_code_snippet>

## Advanced Features

### Resource Pages Configuration

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/CustomerResource.php" mode="EXCERPT">
````php
public static function getRelations(): array
{
    return [
        RelationManagers\InvoicesRelationManager::class,
        RelationManagers\SupportRepRelationManager::class,
    ];
}

public static function getPages(): array
{
    return [
        'index' => Pages\ListCustomers::route('/'),
        'create' => Pages\CreateCustomer::route('/create'),
        'view' => Pages\ViewCustomer::route('/{record}'),
        'edit' => Pages\EditCustomer::route('/{record}/edit'),
    ];
}

public static function getWidgets(): array
{
    return [
        Widgets\CustomerAnalyticsWidget::class,
    ];
}

// Enable soft deletes and optimize queries
public static function getEloquentQuery(): Builder
{
    return parent::getEloquentQuery()
        ->with([
            'supportRep:id,first_name,last_name,title',
            'invoices:id,customer_id,total,invoice_date'
        ])
        ->withCount(['invoices'])
        ->withoutGlobalScopes([
            SoftDeletingScope::class,
        ]);
}
````
</augment_code_snippet>

### Customer Segmentation

<augment_code_snippet path="app/Services/CustomerSegmentationService.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Chinook\Customer;
use Illuminate\Support\Collection;

class CustomerSegmentationService
{
    public function getCustomerSegments(): array
    {
        return [
            'vip' => $this->getVipCustomers(),
            'high_value' => $this->getHighValueCustomers(),
            'regular' => $this->getRegularCustomers(),
            'at_risk' => $this->getAtRiskCustomers(),
            'inactive' => $this->getInactiveCustomers(),
            'new' => $this->getNewCustomers(),
        ];
    }

    public function getVipCustomers(): Collection
    {
        return Customer::whereHas('invoices', function ($q) {
            $q->havingRaw('SUM(total) >= 200')
              ->havingRaw('COUNT(*) >= 10');
        })->get();
    }

    public function getHighValueCustomers(): Collection
    {
        return Customer::whereHas('invoices', function ($q) {
            $q->havingRaw('SUM(total) >= 100')
              ->havingRaw('SUM(total) < 200');
        })->get();
    }

    public function getAtRiskCustomers(): Collection
    {
        return Customer::whereHas('invoices', function ($q) {
            $q->where('invoice_date', '<=', now()->subDays(60))
              ->where('invoice_date', '>', now()->subDays(90));
        })->get();
    }

    public function getInactiveCustomers(): Collection
    {
        return Customer::whereDoesntHave('invoices', function ($q) {
            $q->where('invoice_date', '>=', now()->subDays(90));
        })->get();
    }

    public function getNewCustomers(): Collection
    {
        return Customer::where('created_at', '>=', now()->subDays(30))->get();
    }

    public function getRegularCustomers(): Collection
    {
        return Customer::whereHas('invoices', function ($q) {
            $q->havingRaw('SUM(total) >= 50')
              ->havingRaw('SUM(total) < 100');
        })->get();
    }

    public function getCustomerMetrics(Customer $customer): array
    {
        return [
            'lifetime_value' => $customer->lifetime_value,
            'average_order_value' => $customer->average_order_value,
            'total_orders' => $customer->total_orders,
            'last_purchase_date' => $customer->last_purchase_date,
            'days_since_last_purchase' => $customer->days_since_last_purchase,
            'customer_segment' => $customer->customer_segment,
            'customer_status' => $customer->customer_status,
        ];
    }
}
````
</augment_code_snippet>

## Testing Examples

### Comprehensive Resource Tests

<augment_code_snippet path="tests/Feature/Filament/CustomerResourceTest.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace Tests\Feature\Filament;

use App\Filament\ChinookAdmin\Resources\CustomerResource;
use App\Models\Chinook\Customer;
use App\Models\Chinook\Employee;
use App\Models\Chinook\Invoice;
use App\Models\User;
use Filament\Testing\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;

class CustomerResourceTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Employee $supportRep;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create();
        $this->supportRep = Employee::factory()->create();
        $this->actingAs($this->user);
    }

    public function test_can_render_customer_index_page(): void
    {
        Customer::factory()->count(5)->create();

        Livewire::test(CustomerResource\Pages\ListCustomers::class)
            ->assertSuccessful()
            ->assertCanSeeTableRecords(Customer::all());
    }

    public function test_can_create_customer_with_support_rep(): void
    {
        Livewire::test(CustomerResource\Pages\CreateCustomer::class)
            ->fillForm([
                'first_name' => 'John',
                'last_name' => 'Doe',
                'email' => 'john.doe@example.com',
                'support_rep_id' => $this->supportRep->id,
                'marketing_consent' => true,
                'country' => 'US',
                'preferred_language' => 'en',
            ])
            ->call('create')
            ->assertHasNoFormErrors();

        $customer = Customer::where('email', 'john.doe@example.com')->first();
        $this->assertNotNull($customer);
        $this->assertEquals('John', $customer->first_name);
        $this->assertEquals('Doe', $customer->last_name);
        $this->assertEquals($this->supportRep->id, $customer->support_rep_id);
        $this->assertTrue($customer->marketing_consent);
    }

    public function test_can_edit_customer(): void
    {
        $customer = Customer::factory()->create([
            'first_name' => 'Jane',
            'last_name' => 'Smith',
            'email' => 'jane.smith@example.com',
        ]);

        Livewire::test(CustomerResource\Pages\EditCustomer::class, ['record' => $customer->getRouteKey()])
            ->fillForm([
                'first_name' => 'Jane Updated',
                'company' => 'Updated Company',
                'marketing_consent' => true,
            ])
            ->call('save')
            ->assertHasNoFormErrors();

        $this->assertEquals('Jane Updated', $customer->fresh()->first_name);
        $this->assertEquals('Updated Company', $customer->fresh()->company);
        $this->assertTrue($customer->fresh()->marketing_consent);
    }

    public function test_can_filter_customers_by_country(): void
    {
        Customer::factory()->create(['country' => 'US', 'first_name' => 'American']);
        Customer::factory()->create(['country' => 'CA', 'first_name' => 'Canadian']);

        Livewire::test(CustomerResource\Pages\ListCustomers::class)
            ->filterTable('country', ['US'])
            ->assertCanSeeTableRecords(Customer::where('country', 'US')->get())
            ->assertCanNotSeeTableRecords(Customer::where('country', 'CA')->get());
    }

    public function test_can_filter_customers_by_support_rep(): void
    {
        $otherSupportRep = Employee::factory()->create();
        Customer::factory()->for($this->supportRep, 'supportRep')->create(['first_name' => 'Supported']);
        Customer::factory()->for($otherSupportRep, 'supportRep')->create(['first_name' => 'Other']);

        Livewire::test(CustomerResource\Pages\ListCustomers::class)
            ->filterTable('support_rep_id', [$this->supportRep->id])
            ->assertCanSeeTableRecords(Customer::where('support_rep_id', $this->supportRep->id)->get())
            ->assertCanNotSeeTableRecords(Customer::where('support_rep_id', $otherSupportRep->id)->get());
    }

    public function test_can_search_customers(): void
    {
        Customer::factory()->create(['first_name' => 'John', 'last_name' => 'Doe']);
        Customer::factory()->create(['first_name' => 'Jane', 'last_name' => 'Smith']);

        Livewire::test(CustomerResource\Pages\ListCustomers::class)
            ->searchTable('John')
            ->assertCanSeeTableRecords(Customer::where('first_name', 'like', '%John%')->get())
            ->assertCanNotSeeTableRecords(Customer::where('first_name', 'like', '%Jane%')->get());
    }

    public function test_can_bulk_assign_support_rep(): void
    {
        $customers = Customer::factory()->count(3)->create(['support_rep_id' => null]);

        Livewire::test(CustomerResource\Pages\ListCustomers::class)
            ->selectTableRecords($customers)
            ->callTableBulkAction('assign_support_rep', data: ['support_rep_id' => $this->supportRep->id]);

        $customers->each(function ($customer) {
            $this->assertEquals($this->supportRep->id, $customer->fresh()->support_rep_id);
        });
    }

    public function test_can_bulk_update_marketing_consent(): void
    {
        $customers = Customer::factory()->count(3)->create(['marketing_consent' => false]);

        Livewire::test(CustomerResource\Pages\ListCustomers::class)
            ->selectTableRecords($customers)
            ->callTableBulkAction('update_marketing_consent', data: ['marketing_consent' => true]);

        $customers->each(function ($customer) {
            $this->assertTrue($customer->fresh()->marketing_consent);
        });
    }

    public function test_customer_lifetime_value_calculation(): void
    {
        $customer = Customer::factory()->create();
        Invoice::factory()->for($customer)->create(['total' => 50.00]);
        Invoice::factory()->for($customer)->create(['total' => 75.00]);

        $this->assertEquals(125.00, $customer->lifetime_value);
    }

    public function test_customer_average_order_value_calculation(): void
    {
        $customer = Customer::factory()->create();
        Invoice::factory()->for($customer)->create(['total' => 50.00]);
        Invoice::factory()->for($customer)->create(['total' => 100.00]);

        $this->assertEquals(75.00, $customer->average_order_value);
    }

    public function test_customer_segmentation(): void
    {
        $customer = Customer::factory()->create();
        Invoice::factory()->for($customer)->count(5)->create(['total' => 25.00]); // $125 total

        $this->assertEquals('High Value', $customer->customer_segment);
    }

    public function test_cannot_delete_customer_with_invoices(): void
    {
        $customer = Customer::factory()->create();
        Invoice::factory()->for($customer)->create();

        $this->assertFalse($this->user->can('delete', $customer));
    }

    public function test_can_delete_customer_without_invoices(): void
    {
        $customer = Customer::factory()->create();

        $this->assertTrue($this->user->can('delete', $customer));
    }
}
````
</augment_code_snippet>

## Performance Optimization

### Query Optimization

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/CustomerResource.php" mode="EXCERPT">
````php
// Optimized Eloquent query with eager loading
public static function getEloquentQuery(): Builder
{
    return parent::getEloquentQuery()
        ->with([
            'supportRep:id,first_name,last_name,title,email',
            'invoices:id,customer_id,total,invoice_date,payment_status',
        ])
        ->withCount([
            'invoices',
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
        ->poll('300s'); // Auto-refresh every 5 minutes
}
````
</augment_code_snippet>

### Database Indexing

<augment_code_snippet path="database/migrations/create_chinook_customers_table.php" mode="EXCERPT">
````php
// Optimized indexes for Filament queries
Schema::create('chinook_customers', function (Blueprint $table) {
    $table->id();
    $table->string('first_name', 40)->index(); // For searching and sorting
    $table->string('last_name', 20)->index(); // For searching and sorting
    $table->string('email', 60)->unique(); // For searching and uniqueness
    $table->string('country', 2)->index(); // For filtering
    $table->foreignId('support_rep_id')->nullable()->constrained('chinook_employees')->index(); // For filtering
    $table->boolean('marketing_consent')->default(false)->index(); // For filtering
    $table->string('public_id')->unique();
    $table->string('slug')->unique();

    // Composite indexes for common queries
    $table->index(['country', 'support_rep_id']);
    $table->index(['first_name', 'last_name']);
    $table->index(['marketing_consent', 'country']);
    $table->index(['created_at', 'country']);

    // Full-text search index
    $table->fullText(['first_name', 'last_name', 'email', 'company']);

    $table->timestamps();
    $table->softDeletes();
});
````
</augment_code_snippet>

---

## Navigation

**← Previous:** [Tracks Resource](030-tracks-resource.md) | **Next →** [Invoices Resource](080-invoices-resource.md)

---

## Related Documentation

- [Chinook Models Guide](../../020-database/030-models-guide.md)
- [Employee Resource Guide](100-employees-resource.md)
- [Invoice Resource Guide](080-invoices-resource.md)
- [Invoice Lines Resource Guide](090-invoice-lines-resource.md)
- [Customer Analytics Implementation](../../065-testing/050-testing-implementation-examples.md)
- [Performance Optimization Guide](../../070-performance/000-index.md)
- [Authorization Policies Guide](../../050-security/020-authorization-policies.md)

---

**Documentation Standards**: This document follows WCAG 2.1 AA accessibility guidelines and uses Laravel 12 modern syntax patterns.

**Last Updated:** 2025-07-18
**Maintainer:** Technical Documentation Team
**Source:** [GitHub Repository](https://github.com/s-a-c/chinook)

[⬆️ Back to Top](#customers-resource---complete-implementation-guide)
