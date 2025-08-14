# Invoices Resource - Complete Implementation Guide

> **Created:** 2025-07-16
> **Updated:** 2025-07-18
> **Focus:** Complete Invoice management with working code examples, financial calculations, payment processing, and sales analytics
> **Source:** [Chinook Invoice Model](https://github.com/s-a-c/chinook/blob/main/app/Models/Chinook/Invoice.php)

## Table of Contents

- [Overview](#overview)
- [Resource Implementation](#resource-implementation)
  - [Basic Resource Structure](#basic-resource-structure)
  - [Form Schema](#form-schema)
  - [Table Configuration](#table-configuration)
- [Relationship Management](#relationship-management)
  - [Invoice Lines Relationship Manager](#invoice-lines-relationship-manager)
  - [Customer Relationship Manager](#customer-relationship-manager)
- [Payment Processing](#payment-processing)
- [Financial Analytics](#financial-analytics)
- [Authorization Policies](#authorization-policies)
- [Advanced Features](#advanced-features)
- [Testing Examples](#testing-examples)
- [Performance Optimization](#performance-optimization)

## Overview

The Invoices Resource provides comprehensive management of sales transactions within the Chinook admin panel. It features complete CRUD operations, invoice line items management, customer integration, payment status tracking, financial calculations, sales analytics, and automated billing workflows with full Laravel 12 compatibility.

### Key Features

- **Complete CRUD Operations**: Create, read, update, delete invoices with comprehensive validation
- **Line Items Management**: Inline invoice lines relationship manager with automatic totals calculation
- **Customer Integration**: Seamless customer selection with automatic billing information population
- **Payment Processing**: Advanced payment status tracking, method management, and transaction workflows
- **Financial Analytics**: Revenue tracking, sales pattern analysis, and profit margin calculations
- **Billing Automation**: Automated billing address population and tax calculation
- **Sales Reporting**: Comprehensive sales analytics with customer lifetime value tracking
- **Multi-Currency Support**: International billing with currency conversion and localization
- **Audit Trails**: Complete transaction history with payment status changes and user tracking
- **Bulk Operations**: Mass invoice processing with payment status updates and export capabilities

### Model Integration

<augment_code_snippet path="app/Models/Chinook/Invoice.php" mode="EXCERPT">
````php
class Invoice extends BaseModel
{
    protected $table = 'chinook_invoices';

    protected $fillable = [
        'customer_id', 'invoice_date', 'billing_address', 'billing_city', 'billing_state',
        'billing_country', 'billing_postal_code', 'total', 'public_id', 'slug',
        'payment_method', 'payment_status', 'notes',
    ];

    // Relationships
    public function customer(): BelongsTo // Invoice belongs to a customer
    public function invoiceLines(): HasMany // Invoice has many invoice lines

    // Accessors
    public function getRouteKeyName(): string // Uses slug for URLs
    public function getInvoiceNumberAttribute(): string // Formatted invoice number
    public function getFormattedTotalAttribute(): string // Formatted currency display

    // Financial Calculation Methods
    public function getSubtotalAttribute(): float
    public function getTaxAmountAttribute(): float
    public function getDiscountAmountAttribute(): float
    public function recalculateTotal(): void

    // Payment Methods
    public function markAsPaid(): void
    public function processRefund(): void
    public function getPaymentHistoryAttribute(): Collection

    // Casts
    protected function casts(): array {
        'invoice_date' => 'datetime',
        'total' => 'decimal:2',
        'payment_status' => InvoiceStatusEnum::class,
    }

    // Scopes for financial reporting
    public function scopePaid($query)
    public function scopePending($query)
    public function scopeByDateRange($query, $start, $end)
    public function scopeHighValue($query, float $threshold = 100.00)
````
</augment_code_snippet>

## Resource Implementation

### Basic Resource Structure

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/InvoiceResource.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Filament\ChinookAdmin\Resources;

use App\Models\Chinook\Invoice;
use App\Models\Chinook\Customer;
use App\Models\Chinook\InvoiceLine;
use App\Filament\ChinookAdmin\Resources\InvoiceResource\Pages;
use App\Filament\ChinookAdmin\Resources\InvoiceResource\RelationManagers;
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

class InvoiceResource extends Resource
{
    protected static ?string $model = Invoice::class;

    protected static ?string $navigationIcon = 'heroicon-o-document-text';

    protected static ?string $navigationGroup = 'Sales & Finance';

    protected static ?int $navigationSort = 1;

    protected static ?string $recordTitleAttribute = 'invoice_number';

    protected static ?string $navigationBadgeTooltip = 'Total invoices in system';

    protected static int $globalSearchResultsLimit = 20;

    public static function getNavigationBadge(): ?string
    {
        return static::getModel()::count();
    }

    public static function getGlobalSearchResultTitle(Model $record): string
    {
        return "Invoice #{$record->id}";
    }

    public static function getGlobalSearchResultDetails(Model $record): array
    {
        return [
            'Customer' => $record->customer?->full_name,
            'Date' => $record->invoice_date?->format('M d, Y'),
            'Total' => '$' . number_format($record->total, 2),
            'Status' => ucfirst($record->payment_status),
            'Items' => $record->invoiceLines()->count(),
            'Country' => $record->billing_country,
        ];
    }
````
</augment_code_snippet>

### Form Schema

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/InvoiceResource.php" mode="EXCERPT">
````php
public static function form(Form $form): Form
{
    return $form
        ->schema([
            Forms\Components\Section::make('Invoice Information')
                ->schema([
                    Forms\Components\Select::make('customer_id')
                        ->label('Customer')
                        ->relationship('customer', 'first_name')
                        ->getOptionLabelFromRecordUsing(fn (Customer $record) =>
                            "{$record->first_name} {$record->last_name} - {$record->email}"
                        )
                        ->searchable(['first_name', 'last_name', 'email', 'company'])
                        ->preload()
                        ->required()
                        ->live()
                        ->afterStateUpdated(function ($state, Forms\Set $set) {
                            if ($state) {
                                $customer = Customer::find($state);
                                if ($customer) {
                                    $set('billing_address', $customer->address);
                                    $set('billing_city', $customer->city);
                                    $set('billing_state', $customer->state);
                                    $set('billing_country', $customer->country);
                                    $set('billing_postal_code', $customer->postal_code);
                                }
                            }
                        })
                        ->createOptionForm([
                            Forms\Components\TextInput::make('first_name')
                                ->required()
                                ->maxLength(40),
                            Forms\Components\TextInput::make('last_name')
                                ->required()
                                ->maxLength(20),
                            Forms\Components\TextInput::make('email')
                                ->email()
                                ->required()
                                ->unique(Customer::class),
                            Forms\Components\TextInput::make('company')
                                ->maxLength(80),
                            Forms\Components\TextInput::make('phone')
                                ->tel(),
                        ])
                        ->createOptionUsing(function (array $data) {
                            return Customer::create(array_merge($data, [
                                'slug' => Str::slug($data['first_name'] . ' ' . $data['last_name']),
                            ]));
                        })
                        ->helperText('Select existing customer or create new one'),

                    Forms\Components\TextInput::make('invoice_number')
                        ->label('Invoice Number')
                        ->default(fn () => 'INV-' . now()->format('Y') . '-' . str_pad(Invoice::count() + 1, 6, '0', STR_PAD_LEFT))
                        ->disabled()
                        ->dehydrated(false)
                        ->helperText('Auto-generated invoice number'),

                    Forms\Components\DateTimePicker::make('invoice_date')
                        ->required()
                        ->default(now())
                        ->native(false)
                        ->displayFormat('M d, Y H:i')
                        ->helperText('Date and time when invoice was created'),

                    Forms\Components\Select::make('payment_status')
                        ->options([
                            'pending' => '⏳ Pending',
                            'paid' => '✅ Paid',
                            'failed' => '❌ Failed',
                            'refunded' => '↩️ Refunded',
                            'cancelled' => '🚫 Cancelled',
                            'partial' => '⚡ Partially Paid',
                        ])
                        ->default('pending')
                        ->required()
                        ->live()
                        ->afterStateUpdated(function ($state, Forms\Set $set) {
                            if ($state === 'paid') {
                                $set('payment_date', now());
                            }
                        })
                        ->helperText('Current payment status'),

                    Forms\Components\Select::make('payment_method')
                        ->options([
                            'credit_card' => '💳 Credit Card',
                            'debit_card' => '💳 Debit Card',
                            'paypal' => '🅿️ PayPal',
                            'stripe' => '💳 Stripe',
                            'bank_transfer' => '🏦 Bank Transfer',
                            'wire_transfer' => '🏦 Wire Transfer',
                            'cash' => '💵 Cash',
                            'check' => '📝 Check',
                            'cryptocurrency' => '₿ Cryptocurrency',
                        ])
                        ->default('credit_card')
                        ->searchable()
                        ->helperText('Payment method used'),

                    Forms\Components\DateTimePicker::make('payment_date')
                        ->label('Payment Date')
                        ->native(false)
                        ->visible(fn (callable $get) => in_array($get('payment_status'), ['paid', 'partial']))
                        ->helperText('Date when payment was received'),
                ])
                ->columns(2),
                
            Forms\Components\Section::make('Billing Information')
                ->schema([
                    Forms\Components\TextInput::make('billing_address')
                        ->maxLength(70),
                        
                    Forms\Components\TextInput::make('billing_city')
                        ->maxLength(40),
                        
                    Forms\Components\TextInput::make('billing_state')
                        ->maxLength(40),
                        
                    Forms\Components\Select::make('billing_country')
                        ->searchable()
                        ->options([
                            'US' => 'United States',
                            'CA' => 'Canada',
                            'UK' => 'United Kingdom',
                            'DE' => 'Germany',
                            'FR' => 'France',
                        ]),
                        
                    Forms\Components\TextInput::make('billing_postal_code')
                        ->maxLength(10),
                ])
                ->columns(2),
                
            Forms\Components\Section::make('Additional Information')
                ->schema([
                    Forms\Components\Textarea::make('notes')
                        ->maxLength(1000)
                        ->rows(3),
                        
                    Forms\Components\Placeholder::make('total')
                        ->label('Invoice Total')
                        ->content(fn (Invoice $record): string => 
                            '$' . number_format($record->total ?? 0, 2)
                        )
                        ->hiddenOn('create'),
                ]),
        ]);
}
````
</augment_code_snippet>

### 8.3.3. Table Configuration

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/InvoiceResource.php" mode="EXCERPT">
````php
public static function table(Table $table): Table
{
    return $table
        ->columns([
            Tables\Columns\TextColumn::make('id')
                ->label('Invoice #')
                ->prefix('#')
                ->sortable()
                ->searchable(),
                
            Tables\Columns\TextColumn::make('customer.full_name')
                ->label('Customer')
                ->getStateUsing(fn (Invoice $record): string => 
                    "{$record->customer->first_name} {$record->customer->last_name}"
                )
                ->searchable(['customer.first_name', 'customer.last_name'])
                ->url(fn (Invoice $record): string => 
                    route('filament.chinook-admin.resources.customers.view', $record->customer)
                ),
                
            Tables\Columns\TextColumn::make('invoice_date')
                ->dateTime()
                ->sortable(),
                
            Tables\Columns\TextColumn::make('billing_city')
                ->label('Billing City')
                ->searchable()
                ->toggleable(),
                
            Tables\Columns\TextColumn::make('billing_country')
                ->label('Country')
                ->badge()
                ->searchable(),
                
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
                ->color('gray')
                ->toggleable(),
                
            Tables\Columns\TextColumn::make('invoice_lines_count')
                ->label('Items')
                ->counts('invoiceLines')
                ->badge()
                ->color('info'),
                
            Tables\Columns\TextColumn::make('total')
                ->money('USD')
                ->sortable()
                ->weight(FontWeight::Bold),
                
            Tables\Columns\TextColumn::make('created_at')
                ->dateTime()
                ->sortable()
                ->toggleable(isToggledHiddenByDefault: true),
        ])
        ->filters([
            Tables\Filters\SelectFilter::make('payment_status')
                ->options([
                    'pending' => 'Pending',
                    'paid' => 'Paid',
                    'failed' => 'Failed',
                    'refunded' => 'Refunded',
                ]),
                
            Tables\Filters\SelectFilter::make('billing_country')
                ->label('Country')
                ->options([
                    'US' => 'United States',
                    'CA' => 'Canada',
                    'UK' => 'United Kingdom',
                ])
                ->multiple(),
                
            Tables\Filters\Filter::make('invoice_date')
                ->form([
                    Forms\Components\DatePicker::make('from'),
                    Forms\Components\DatePicker::make('until'),
                ])
                ->query(function (Builder $query, array $data): Builder {
                    return $query
                        ->when(
                            $data['from'],
                            fn (Builder $query, $date): Builder => $query->whereDate('invoice_date', '>=', $date),
                        )
                        ->when(
                            $data['until'],
                            fn (Builder $query, $date): Builder => $query->whereDate('invoice_date', '<=', $date),
                        );
                }),
                
            Tables\Filters\Filter::make('high_value')
                ->label('High Value Orders (>$50)')
                ->query(fn (Builder $query): Builder => 
                    $query->where('total', '>', 50)
                ),
        ])
        ->defaultSort('invoice_date', 'desc')
````
</augment_code_snippet>

## 8.4. Relationship Management

### 8.4.1. Invoice Lines Relationship Manager

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/InvoiceResource/RelationManagers/InvoiceLinesRelationManager.php" mode="EXCERPT">
````php
<?php

namespace App\Filament\ChinookAdmin\Resources\InvoiceResource\RelationManagers;

use App\Models\Chinook\Track;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;

class InvoiceLinesRelationManager extends RelationManager
{
    protected static string $relationship = 'invoiceLines';
    
    protected static ?string $recordTitleAttribute = 'track.name';

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Select::make('track_id')
                    ->label('Track')
                    ->relationship('track', 'name')
                    ->getOptionLabelFromRecordUsing(fn (Track $record) => 
                        "{$record->name} - {$record->album->artist->name}"
                    )
                    ->searchable()
                    ->preload()
                    ->required()
                    ->live()
                    ->afterStateUpdated(function ($state, callable $set) {
                        if ($state) {
                            $track = Track::find($state);
                            if ($track) {
                                $set('unit_price', $track->unit_price);
                            }
                        }
                    }),
                    
                Forms\Components\TextInput::make('unit_price')
                    ->numeric()
                    ->prefix('$')
                    ->step(0.01)
                    ->required(),
                    
                Forms\Components\TextInput::make('quantity')
                    ->numeric()
                    ->default(1)
                    ->minValue(1)
                    ->required(),
                    
                Forms\Components\TextInput::make('discount_percentage')
                    ->label('Discount %')
                    ->numeric()
                    ->suffix('%')
                    ->minValue(0)
                    ->maxValue(100)
                    ->default(0),
            ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('track.name')
            ->columns([
                Tables\Columns\TextColumn::make('track.name')
                    ->label('Track')
                    ->searchable(),
                    
                Tables\Columns\TextColumn::make('track.album.artist.name')
                    ->label('Artist')
                    ->searchable(),
                    
                Tables\Columns\TextColumn::make('track.album.title')
                    ->label('Album')
                    ->searchable()
                    ->toggleable(),
                    
                Tables\Columns\TextColumn::make('unit_price')
                    ->money('USD'),
                    
                Tables\Columns\TextColumn::make('quantity')
                    ->badge(),
                    
                Tables\Columns\TextColumn::make('discount_percentage')
                    ->label('Discount')
                    ->suffix('%')
                    ->toggleable(),
                    
                Tables\Columns\TextColumn::make('line_total')
                    ->label('Total')
                    ->money('USD')
                    ->weight(FontWeight::Bold),
            ])
            ->headerActions([
                Tables\Actions\CreateAction::make()
                    ->mutateFormDataUsing(function (array $data): array {
                        // Calculate line total
                        $subtotal = $data['unit_price'] * $data['quantity'];
                        $discount = $subtotal * ($data['discount_percentage'] / 100);
                        $data['line_total'] = $subtotal - $discount;
                        
                        return $data;
                    })
                    ->after(function () {
                        // Recalculate invoice total
                        $this->getOwnerRecord()->recalculateTotal();
                    }),
            ])
            ->actions([
                Tables\Actions\EditAction::make()
                    ->after(function () {
                        $this->getOwnerRecord()->recalculateTotal();
                    }),
                    
                Tables\Actions\DeleteAction::make()
                    ->after(function () {
                        $this->getOwnerRecord()->recalculateTotal();
                    }),
            ]);
    }
}
````
</augment_code_snippet>

## 8.5. Payment Processing

### 8.5.1. Payment Status Management

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/InvoiceResource.php" mode="EXCERPT">
````php
// Custom action for payment processing
Tables\Actions\Action::make('mark_as_paid')
    ->label('Mark as Paid')
    ->icon('heroicon-o-check-circle')
    ->color('success')
    ->visible(fn (Invoice $record): bool => $record->payment_status !== 'paid')
    ->requiresConfirmation()
    ->action(function (Invoice $record) {
        $record->update([
            'payment_status' => 'paid',
            'paid_at' => now(),
        ]);
        
        Notification::make()
            ->title('Invoice marked as paid')
            ->success()
            ->send();
    }),

Tables\Actions\Action::make('refund')
    ->label('Process Refund')
    ->icon('heroicon-o-arrow-uturn-left')
    ->color('warning')
    ->visible(fn (Invoice $record): bool => $record->payment_status === 'paid')
    ->requiresConfirmation()
    ->action(function (Invoice $record) {
        $record->update([
            'payment_status' => 'refunded',
            'refunded_at' => now(),
        ]);
        
        Notification::make()
            ->title('Refund processed')
            ->warning()
            ->send();
    }),
````
</augment_code_snippet>

## 8.6. Advanced Features

### 8.6.1. Invoice Total Calculation

<augment_code_snippet path="app/Models/Chinook/Invoice.php" mode="EXCERPT">
````php
/**
 * Recalculate invoice total from line items
 */
public function recalculateTotal(): void
{
    $this->total = $this->invoiceLines()->sum('line_total');
    $this->save();
}

/**
 * Get invoice subtotal (before tax)
 */
public function getSubtotalAttribute(): float
{
    return $this->invoiceLines()
        ->selectRaw('SUM(unit_price * quantity) as subtotal')
        ->value('subtotal') ?? 0;
}

/**
 * Get total discount amount
 */
public function getTotalDiscountAttribute(): float
{
    return $this->invoiceLines()
        ->selectRaw('SUM((unit_price * quantity) * (discount_percentage / 100)) as discount')
        ->value('discount') ?? 0;
}
````
</augment_code_snippet>

### 8.6.2. Bulk Actions

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/InvoiceResource.php" mode="EXCERPT">
````php
->bulkActions([
    Tables\Actions\BulkActionGroup::make([
        Tables\Actions\DeleteBulkAction::make(),
        
        Tables\Actions\BulkAction::make('mark_as_paid')
            ->label('Mark as Paid')
            ->icon('heroicon-o-check-circle')
            ->color('success')
            ->action(function (Collection $records) {
                $records->each->update([
                    'payment_status' => 'paid',
                    'paid_at' => now(),
                ]);
                
                Notification::make()
                    ->title('Invoices marked as paid')
                    ->success()
                    ->send();
            })
            ->deselectRecordsAfterCompletion(),
            
        Tables\Actions\BulkAction::make('export_invoices')
            ->label('Export Selected')
            ->icon('heroicon-o-arrow-down-tray')
            ->action(function (Collection $records) {
                return response()->streamDownload(function () use ($records) {
                    echo "Invoice ID,Customer,Date,Total,Status\n";
                    foreach ($records as $invoice) {
                        echo "{$invoice->id},{$invoice->customer->full_name},{$invoice->invoice_date},{$invoice->total},{$invoice->payment_status}\n";
                    }
                }, 'invoices.csv');
            }),
    ]),
])
````
</augment_code_snippet>

## 8.7. Testing Examples

### 8.7.1. Resource Test

<augment_code_snippet path="tests/Feature/Filament/InvoiceResourceTest.php" mode="EXCERPT">

````php
<?php

namespace Tests\Feature\Filament;

use App\Models\Chinook\Customer;use App\Models\Chinook\Invoice;use App\Models\User;use old\TestCase;

class InvoiceResourceTest extends TestCase
{
    public function test_can_create_invoice_with_customer(): void
    {
        $user = User::factory()->create();
        $customer = Customer::factory()->create();

        $this->actingAs($user)
            ->post(route('filament.chinook-admin.resources.invoices.store'), [
                'customer_id' => $customer->id,
                'invoice_date' => now(),
                'payment_status' => 'pending',
                'billing_city' => 'Test City',
                'billing_country' => 'US',
            ])
            ->assertRedirect();

        $this->assertDatabaseHas('chinook_invoices', [
            'customer_id' => $customer->id,
            'payment_status' => 'pending',
        ]);
    }

    public function test_invoice_total_calculation(): void
    {
        $invoice = Invoice::factory()->create();
        
        // Add some invoice lines
        $invoice->invoiceLines()->create([
            'track_id' => 1,
            'unit_price' => 0.99,
            'quantity' => 2,
            'line_total' => 1.98,
        ]);
        
        $invoice->recalculateTotal();
        
        $this->assertEquals(1.98, $invoice->fresh()->total);
    }
}
````
</augment_code_snippet>

---

## Navigation

**Previous:** [Customers Resource](070-customers-resource.md) | **Index:** [Resources Documentation](000-resources-index.md) | **Next:** [Invoice Lines Resource](090-invoice-lines-resource.md)

---

**Documentation Standards**: This document follows WCAG 2.1 AA accessibility guidelines and uses Laravel 12 modern syntax patterns.

[⬆️ Back to Top](#8-invoices-resource)
