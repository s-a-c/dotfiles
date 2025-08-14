# 9. Invoice Lines Resource

> **Created:** 2025-07-16  
> **Focus:** Invoice line item management with track integration and pricing calculations  
> **Source:** [Chinook InvoiceLine Model](https://github.com/s-a-c/chinook/blob/main/app/Models/Chinook/InvoiceLine.php)

## 9.1. Table of Contents

- [9.2. Overview](#92-overview)
- [9.3. Resource Implementation](#93-resource-implementation)
  - [9.3.1. Basic Resource Structure](#931-basic-resource-structure)
  - [9.3.2. Form Schema](#932-form-schema)
  - [9.3.3. Table Configuration](#933-table-configuration)
- [9.4. Pricing Calculations](#94-pricing-calculations)
- [9.5. Track Integration](#95-track-integration)
- [9.6. Advanced Features](#96-advanced-features)
- [9.7. Testing Examples](#97-testing-examples)

## 9.2. Overview

The Invoice Lines Resource provides comprehensive management of individual line items within invoices. It features complete CRUD operations, automatic pricing calculations, track integration, discount handling, and real-time total updates for parent invoices.

### 9.2.1. Key Features

- **Complete CRUD Operations**: Create, read, update, delete invoice lines with validation
- **Automatic Calculations**: Real-time line total calculations with discounts
- **Track Integration**: Seamless track selection with automatic price population
- **Discount Management**: Percentage-based discount calculations
- **Invoice Updates**: Automatic parent invoice total recalculation
- **Quantity Management**: Flexible quantity handling with validation

### 9.2.2. Model Integration

<augment_code_snippet path="app/Models/Chinook/InvoiceLine.php" mode="EXCERPT">
````php
class InvoiceLine extends BaseModel
{
    protected $table = 'chinook_invoice_lines';

    protected $fillable = [
        'invoice_id',
        'track_id',
        'unit_price',
        'quantity',
        'discount_percentage',
        'line_total',
        'public_id',
        'slug',
    ];

    /**
     * Invoice line belongs to an invoice
     */
    public function invoice(): BelongsTo
    {
        return $this->belongsTo(Invoice::class, 'invoice_id');
    }

    /**
     * Invoice line belongs to a track
     */
    public function track(): BelongsTo
    {
        return $this->belongsTo(Track::class, 'track_id');
    }

    /**
     * Calculate line total automatically
     */
    protected static function boot()
    {
        parent::boot();

        self::saving(function ($invoiceLine) {
            $subtotal = $invoiceLine->unit_price * $invoiceLine->quantity;
            $discount = $subtotal * ($invoiceLine->discount_percentage / 100);
            $invoiceLine->line_total = $subtotal - $discount;
        });
    }
````
</augment_code_snippet>

## 9.3. Resource Implementation

### 9.3.1. Basic Resource Structure

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/InvoiceLineResource.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Filament\ChinookAdmin\Resources;

use App\Models\Chinook\InvoiceLine;
use App\Models\Chinook\Track;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class InvoiceLineResource extends Resource
{
    protected static ?string $model = InvoiceLine::class;
    
    protected static ?string $navigationIcon = 'heroicon-o-list-bullet';
    
    protected static ?string $navigationGroup = 'Customer Management';
    
    protected static ?int $navigationSort = 3;
    
    protected static ?string $recordTitleAttribute = 'track.name';
    
    protected static ?string $pluralModelLabel = 'Invoice Lines';
    
    protected static bool $shouldRegisterNavigation = false; // Usually managed through invoices
````
</augment_code_snippet>

### 9.3.2. Form Schema

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/InvoiceLineResource.php" mode="EXCERPT">
````php
public static function form(Form $form): Form
{
    return $form
        ->schema([
            Forms\Components\Section::make('Line Item Information')
                ->schema([
                    Forms\Components\Select::make('invoice_id')
                        ->label('Invoice')
                        ->relationship('invoice', 'id')
                        ->getOptionLabelFromRecordUsing(fn ($record) => 
                            "Invoice #{$record->id} - {$record->customer->full_name}"
                        )
                        ->required()
                        ->searchable()
                        ->preload(),
                        
                    Forms\Components\Select::make('track_id')
                        ->label('Track')
                        ->relationship('track', 'name')
                        ->getOptionLabelFromRecordUsing(fn (Track $record) => 
                            "{$record->name} - {$record->album->artist->name} ({$record->album->title})"
                        )
                        ->required()
                        ->searchable()
                        ->preload()
                        ->live()
                        ->afterStateUpdated(function ($state, callable $set) {
                            if ($state) {
                                $track = Track::find($state);
                                if ($track) {
                                    $set('unit_price', $track->unit_price);
                                }
                            }
                        }),
                ])
                ->columns(2),
                
            Forms\Components\Section::make('Pricing & Quantity')
                ->schema([
                    Forms\Components\TextInput::make('unit_price')
                        ->label('Unit Price')
                        ->numeric()
                        ->prefix('$')
                        ->step(0.01)
                        ->minValue(0)
                        ->required()
                        ->live(onBlur: true)
                        ->afterStateUpdated(fn ($state, callable $set, callable $get) => 
                            self::calculateLineTotal($get, $set)
                        ),
                        
                    Forms\Components\TextInput::make('quantity')
                        ->numeric()
                        ->default(1)
                        ->minValue(1)
                        ->required()
                        ->live(onBlur: true)
                        ->afterStateUpdated(fn ($state, callable $set, callable $get) => 
                            self::calculateLineTotal($get, $set)
                        ),
                        
                    Forms\Components\TextInput::make('discount_percentage')
                        ->label('Discount %')
                        ->numeric()
                        ->suffix('%')
                        ->minValue(0)
                        ->maxValue(100)
                        ->default(0)
                        ->live(onBlur: true)
                        ->afterStateUpdated(fn ($state, callable $set, callable $get) => 
                            self::calculateLineTotal($get, $set)
                        ),
                        
                    Forms\Components\Placeholder::make('line_total_display')
                        ->label('Line Total')
                        ->content(function (callable $get): string {
                            $unitPrice = (float) ($get('unit_price') ?? 0);
                            $quantity = (int) ($get('quantity') ?? 1);
                            $discount = (float) ($get('discount_percentage') ?? 0);
                            
                            $subtotal = $unitPrice * $quantity;
                            $discountAmount = $subtotal * ($discount / 100);
                            $total = $subtotal - $discountAmount;
                            
                            return '$' . number_format($total, 2);
                        })
                        ->live(),
                ])
                ->columns(2),
        ]);
}

private static function calculateLineTotal(callable $get, callable $set): void
{
    $unitPrice = (float) ($get('unit_price') ?? 0);
    $quantity = (int) ($get('quantity') ?? 1);
    $discount = (float) ($get('discount_percentage') ?? 0);
    
    $subtotal = $unitPrice * $quantity;
    $discountAmount = $subtotal * ($discount / 100);
    $total = $subtotal - $discountAmount;
    
    $set('line_total', $total);
}
````
</augment_code_snippet>

### 9.3.3. Table Configuration

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/InvoiceLineResource.php" mode="EXCERPT">
````php
public static function table(Table $table): Table
{
    return $table
        ->columns([
            Tables\Columns\TextColumn::make('invoice.id')
                ->label('Invoice #')
                ->prefix('#')
                ->sortable()
                ->url(fn (InvoiceLine $record): string => 
                    route('filament.chinook-admin.resources.invoices.view', $record->invoice)
                ),
                
            Tables\Columns\TextColumn::make('invoice.customer.full_name')
                ->label('Customer')
                ->getStateUsing(fn (InvoiceLine $record): string => 
                    "{$record->invoice->customer->first_name} {$record->invoice->customer->last_name}"
                )
                ->searchable(['invoice.customer.first_name', 'invoice.customer.last_name']),
                
            Tables\Columns\TextColumn::make('track.name')
                ->label('Track')
                ->searchable()
                ->weight(FontWeight::Bold)
                ->url(fn (InvoiceLine $record): string => 
                    route('filament.chinook-admin.resources.tracks.view', $record->track)
                ),
                
            Tables\Columns\TextColumn::make('track.album.artist.name')
                ->label('Artist')
                ->searchable()
                ->toggleable(),
                
            Tables\Columns\TextColumn::make('track.album.title')
                ->label('Album')
                ->searchable()
                ->toggleable(),
                
            Tables\Columns\TextColumn::make('unit_price')
                ->money('USD')
                ->sortable(),
                
            Tables\Columns\TextColumn::make('quantity')
                ->badge()
                ->color('info'),
                
            Tables\Columns\TextColumn::make('discount_percentage')
                ->label('Discount')
                ->suffix('%')
                ->color(fn ($state): string => $state > 0 ? 'warning' : 'gray')
                ->toggleable(),
                
            Tables\Columns\TextColumn::make('line_total')
                ->label('Total')
                ->money('USD')
                ->sortable()
                ->weight(FontWeight::Bold),
                
            Tables\Columns\TextColumn::make('created_at')
                ->dateTime()
                ->sortable()
                ->toggleable(isToggledHiddenByDefault: true),
        ])
        ->filters([
            Tables\Filters\SelectFilter::make('invoice')
                ->relationship('invoice', 'id')
                ->getOptionLabelFromRecordUsing(fn ($record) => 
                    "Invoice #{$record->id}"
                )
                ->searchable(),
                
            Tables\Filters\Filter::make('has_discount')
                ->label('Has Discount')
                ->query(fn (Builder $query): Builder => 
                    $query->where('discount_percentage', '>', 0)
                ),
                
            Tables\Filters\Filter::make('high_value')
                ->label('High Value Items (>$5)')
                ->query(fn (Builder $query): Builder => 
                    $query->where('line_total', '>', 5)
                ),
        ])
        ->defaultSort('created_at', 'desc')
````
</augment_code_snippet>

## 9.4. Pricing Calculations

### 9.4.1. Automatic Line Total Calculation

<augment_code_snippet path="app/Models/Chinook/InvoiceLine.php" mode="EXCERPT">
````php
/**
 * Calculate subtotal before discount
 */
public function getSubtotalAttribute(): float
{
    return $this->unit_price * $this->quantity;
}

/**
 * Calculate discount amount
 */
public function getDiscountAmountAttribute(): float
{
    return $this->subtotal * ($this->discount_percentage / 100);
}

/**
 * Get effective unit price after discount
 */
public function getEffectiveUnitPriceAttribute(): float
{
    if ($this->quantity === 0) {
        return 0;
    }
    
    return $this->line_total / $this->quantity;
}

/**
 * Update parent invoice total when line item changes
 */
protected static function booted()
{
    static::saved(function (InvoiceLine $invoiceLine) {
        $invoiceLine->invoice->recalculateTotal();
    });
    
    static::deleted(function (InvoiceLine $invoiceLine) {
        $invoiceLine->invoice->recalculateTotal();
    });
}
````
</augment_code_snippet>

## 9.5. Track Integration

### 9.5.1. Track Selection with Price Population

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/InvoiceLineResource.php" mode="EXCERPT">
````php
// Enhanced track selection with detailed information
Forms\Components\Select::make('track_id')
    ->label('Track')
    ->options(function () {
        return Track::with(['album.artist'])
            ->get()
            ->mapWithKeys(function (Track $track) {
                $label = "{$track->name} - {$track->album->artist->name}";
                $label .= " ({$track->album->title})";
                $label .= " - $" . number_format($track->unit_price, 2);
                
                return [$track->id => $label];
            });
    })
    ->searchable()
    ->required()
    ->live()
    ->afterStateUpdated(function ($state, callable $set) {
        if ($state) {
            $track = Track::find($state);
            if ($track) {
                $set('unit_price', $track->unit_price);
                // Recalculate total
                self::calculateLineTotal(
                    fn ($key) => match($key) {
                        'unit_price' => $track->unit_price,
                        'quantity' => 1,
                        'discount_percentage' => 0,
                        default => null,
                    },
                    $set
                );
            }
        }
    }),
````
</augment_code_snippet>

## 9.6. Advanced Features

### 9.6.1. Bulk Pricing Updates

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/InvoiceLineResource.php" mode="EXCERPT">
````php
->bulkActions([
    Tables\Actions\BulkActionGroup::make([
        Tables\Actions\DeleteBulkAction::make()
            ->after(function (Collection $records) {
                // Update all affected invoices
                $invoiceIds = $records->pluck('invoice_id')->unique();
                Invoice::whereIn('id', $invoiceIds)
                    ->get()
                    ->each
                    ->recalculateTotal();
            }),
            
        Tables\Actions\BulkAction::make('apply_discount')
            ->label('Apply Discount')
            ->icon('heroicon-o-tag')
            ->form([
                Forms\Components\TextInput::make('discount_percentage')
                    ->label('Discount Percentage')
                    ->numeric()
                    ->suffix('%')
                    ->minValue(0)
                    ->maxValue(100)
                    ->required(),
            ])
            ->action(function (Collection $records, array $data) {
                $records->each(function (InvoiceLine $line) use ($data) {
                    $line->update(['discount_percentage' => $data['discount_percentage']]);
                });
                
                // Update affected invoices
                $invoiceIds = $records->pluck('invoice_id')->unique();
                Invoice::whereIn('id', $invoiceIds)
                    ->get()
                    ->each
                    ->recalculateTotal();
                    
                Notification::make()
                    ->title('Discount applied successfully')
                    ->success()
                    ->send();
            })
            ->deselectRecordsAfterCompletion(),
            
        Tables\Actions\BulkAction::make('update_quantity')
            ->label('Update Quantity')
            ->icon('heroicon-o-calculator')
            ->form([
                Forms\Components\TextInput::make('quantity')
                    ->numeric()
                    ->minValue(1)
                    ->required(),
            ])
            ->action(function (Collection $records, array $data) {
                $records->each(function (InvoiceLine $line) use ($data) {
                    $line->update(['quantity' => $data['quantity']]);
                });
                
                Notification::make()
                    ->title('Quantities updated successfully')
                    ->success()
                    ->send();
            })
            ->deselectRecordsAfterCompletion(),
    ]),
])
````
</augment_code_snippet>

### 9.6.2. Revenue Analytics

<augment_code_snippet path="app/Models/Chinook/InvoiceLine.php" mode="EXCERPT">
````php
/**
 * Get total revenue for a specific track
 */
public static function getTrackRevenue(int $trackId): float
{
    return static::where('track_id', $trackId)
        ->sum('line_total');
}

/**
 * Get best selling tracks
 */
public static function getBestSellingTracks(int $limit = 10): Collection
{
    return static::select('track_id')
        ->selectRaw('SUM(quantity) as total_sold')
        ->selectRaw('SUM(line_total) as total_revenue')
        ->with('track.album.artist')
        ->groupBy('track_id')
        ->orderByDesc('total_sold')
        ->limit($limit)
        ->get();
}
````
</augment_code_snippet>

## 9.7. Testing Examples

### 9.7.1. Resource Test

<augment_code_snippet path="tests/Feature/Filament/InvoiceLineResourceTest.php" mode="EXCERPT">

````php
<?php

namespace Tests\Feature\Filament;

use App\Models\Chinook\Invoice;use App\Models\Chinook\InvoiceLine;use App\Models\Chinook\Track;use old\TestCase;

class InvoiceLineResourceTest extends TestCase
{
    public function test_line_total_calculation(): void
    {
        $track = Track::factory()->create(['unit_price' => 0.99]);
        $invoice = Invoice::factory()->create();
        
        $invoiceLine = InvoiceLine::create([
            'invoice_id' => $invoice->id,
            'track_id' => $track->id,
            'unit_price' => 0.99,
            'quantity' => 2,
            'discount_percentage' => 10,
        ]);
        
        // Subtotal: 0.99 * 2 = 1.98
        // Discount: 1.98 * 0.10 = 0.198
        // Total: 1.98 - 0.198 = 1.782
        $this->assertEquals(1.78, round($invoiceLine->line_total, 2));
    }

    public function test_invoice_total_updates_when_line_item_changes(): void
    {
        $invoice = Invoice::factory()->create(['total' => 0]);
        $track = Track::factory()->create(['unit_price' => 0.99]);
        
        $invoiceLine = InvoiceLine::create([
            'invoice_id' => $invoice->id,
            'track_id' => $track->id,
            'unit_price' => 0.99,
            'quantity' => 1,
            'discount_percentage' => 0,
        ]);
        
        $this->assertEquals(0.99, $invoice->fresh()->total);
        
        $invoiceLine->update(['quantity' => 2]);
        
        $this->assertEquals(1.98, $invoice->fresh()->total);
    }
}
````
</augment_code_snippet>

---

## Navigation

**Previous:** [Invoices Resource](080-invoices-resource.md) | **Index:** [Resources Documentation](000-resources-index.md) | **Next:** [Employees Resource](100-employees-resource.md)

---

**Documentation Standards**: This document follows WCAG 2.1 AA accessibility guidelines and uses Laravel 12 modern syntax patterns.

[⬆️ Back to Top](#9-invoice-lines-resource)
