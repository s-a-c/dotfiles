# 6. Media Types Resource

> **Created:** 2025-07-16  
> **Focus:** Media type management with track relationships and format specifications  
> **Source:** [Chinook MediaType Model](https://github.com/s-a-c/chinook/blob/main/app/Models/Chinook/MediaType.php)

## 6.1. Table of Contents

- [6.2. Overview](#62-overview)
- [6.3. Resource Implementation](#63-resource-implementation)
  - [6.3.1. Basic Resource Structure](#631-basic-resource-structure)
  - [6.3.2. Form Schema](#632-form-schema)
  - [6.3.3. Table Configuration](#633-table-configuration)
- [6.4. Track Integration](#64-track-integration)
- [6.5. Format Validation](#65-format-validation)
- [6.6. Advanced Features](#66-advanced-features)
- [6.7. Testing Examples](#67-testing-examples)

## 6.2. Overview

The Media Types Resource provides comprehensive management of audio file formats and media types within the Chinook admin panel. It features complete CRUD operations, track relationship management, MIME type validation, and file extension handling for various audio formats.

### 6.2.1. Key Features

- **Complete CRUD Operations**: Create, read, update, delete media types with validation
- **Format Specifications**: MIME type and file extension management
- **Track Integration**: View and manage tracks using each media type
- **Usage Statistics**: Track count and usage analytics per media type
- **Format Validation**: Ensure valid MIME types and file extensions
- **Active/Inactive States**: Enable/disable media types for new tracks

### 6.2.2. Model Integration

<augment_code_snippet path="app/Models/Chinook/MediaType.php" mode="EXCERPT">
````php
class MediaType extends BaseModel
{
    protected $table = 'chinook_media_types';

    protected $fillable = [
        'name',
        'public_id',
        'slug',
        'mime_type',
        'file_extension',
        'description',
        'is_active',
    ];

    /**
     * Media type has many tracks
     */
    public function tracks(): HasMany
    {
        return $this->hasMany(Track::class, 'media_type_id');
    }
````
</augment_code_snippet>

## 6.3. Resource Implementation

### 6.3.1. Basic Resource Structure

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/MediaTypeResource.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Filament\ChinookAdmin\Resources;

use App\Models\Chinook\MediaType;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class MediaTypeResource extends Resource
{
    protected static ?string $model = MediaType::class;
    
    protected static ?string $navigationIcon = 'heroicon-o-document-audio';
    
    protected static ?string $navigationGroup = 'Music Management';
    
    protected static ?int $navigationSort = 6;
    
    protected static ?string $recordTitleAttribute = 'name';
    
    protected static ?string $pluralModelLabel = 'Media Types';
````
</augment_code_snippet>

### 6.3.2. Form Schema

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/MediaTypeResource.php" mode="EXCERPT">
````php
public static function form(Form $form): Form
{
    return $form
        ->schema([
            Forms\Components\Section::make('Media Type Information')
                ->schema([
                    Forms\Components\TextInput::make('name')
                        ->required()
                        ->maxLength(255)
                        ->live(onBlur: true)
                        ->afterStateUpdated(fn (string $context, $state, callable $set) => 
                            $context === 'create' ? $set('slug', Str::slug($state)) : null
                        ),
                        
                    Forms\Components\TextInput::make('slug')
                        ->required()
                        ->maxLength(255)
                        ->unique(ignoreRecord: true)
                        ->rules(['alpha_dash']),
                        
                    Forms\Components\Select::make('mime_type')
                        ->required()
                        ->options([
                            'audio/mpeg' => 'audio/mpeg (MP3)',
                            'audio/mp4' => 'audio/mp4 (M4A)',
                            'audio/flac' => 'audio/flac (FLAC)',
                            'audio/wav' => 'audio/wav (WAV)',
                            'audio/ogg' => 'audio/ogg (OGG)',
                            'audio/aac' => 'audio/aac (AAC)',
                            'audio/wma' => 'audio/wma (WMA)',
                        ])
                        ->searchable()
                        ->live()
                        ->afterStateUpdated(function ($state, callable $set) {
                            $extensions = [
                                'audio/mpeg' => 'mp3',
                                'audio/mp4' => 'm4a',
                                'audio/flac' => 'flac',
                                'audio/wav' => 'wav',
                                'audio/ogg' => 'ogg',
                                'audio/aac' => 'aac',
                                'audio/wma' => 'wma',
                            ];
                            
                            if (isset($extensions[$state])) {
                                $set('file_extension', $extensions[$state]);
                            }
                        }),
                        
                    Forms\Components\TextInput::make('file_extension')
                        ->required()
                        ->maxLength(10)
                        ->prefix('.')
                        ->rules(['alpha_num']),
                        
                    Forms\Components\Toggle::make('is_active')
                        ->default(true)
                        ->helperText('Inactive media types cannot be used for new tracks'),
                ])
                ->columns(2),
                
            Forms\Components\Section::make('Description')
                ->schema([
                    Forms\Components\Textarea::make('description')
                        ->maxLength(1000)
                        ->rows(3)
                        ->helperText('Optional description of the media type and its characteristics'),
                ]),
        ]);
}
````
</augment_code_snippet>

### 6.3.3. Table Configuration

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/MediaTypeResource.php" mode="EXCERPT">
````php
public static function table(Table $table): Table
{
    return $table
        ->columns([
            Tables\Columns\TextColumn::make('name')
                ->searchable()
                ->sortable()
                ->weight(FontWeight::Bold),
                
            Tables\Columns\TextColumn::make('mime_type')
                ->label('MIME Type')
                ->badge()
                ->color('info')
                ->searchable(),
                
            Tables\Columns\TextColumn::make('file_extension')
                ->label('Extension')
                ->formatStateUsing(fn (string $state): string => ".{$state}")
                ->badge()
                ->color('gray'),
                
            Tables\Columns\TextColumn::make('tracks_count')
                ->label('Tracks')
                ->counts('tracks')
                ->badge()
                ->color('success')
                ->sortable(),
                
            Tables\Columns\IconColumn::make('is_active')
                ->boolean()
                ->trueIcon('heroicon-o-check-circle')
                ->falseIcon('heroicon-o-x-circle')
                ->trueColor('success')
                ->falseColor('danger'),
                
            Tables\Columns\TextColumn::make('created_at')
                ->dateTime()
                ->sortable()
                ->toggleable(isToggledHiddenByDefault: true),
        ])
        ->filters([
            Tables\Filters\TernaryFilter::make('is_active')
                ->label('Status')
                ->trueLabel('Active Only')
                ->falseLabel('Inactive Only')
                ->native(false),
                
            Tables\Filters\SelectFilter::make('mime_type')
                ->label('MIME Type')
                ->options([
                    'audio/mpeg' => 'MP3',
                    'audio/mp4' => 'M4A',
                    'audio/flac' => 'FLAC',
                    'audio/wav' => 'WAV',
                    'audio/ogg' => 'OGG',
                ]),
                
            Tables\Filters\Filter::make('has_tracks')
                ->label('Has Tracks')
                ->query(fn (Builder $query): Builder => 
                    $query->has('tracks')
                ),
        ])
        ->actions([
            Tables\Actions\ViewAction::make(),
            Tables\Actions\EditAction::make(),
            Tables\Actions\DeleteAction::make()
                ->requiresConfirmation()
                ->action(function (MediaType $record) {
                    if ($record->tracks()->count() > 0) {
                        Notification::make()
                            ->title('Cannot delete media type')
                            ->body('This media type is used by existing tracks.')
                            ->danger()
                            ->send();
                        return;
                    }
                    
                    $record->delete();
                }),
        ])
````
</augment_code_snippet>

## 6.4. Track Integration

### 6.4.1. Tracks Relationship Manager

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/MediaTypeResource/RelationManagers/TracksRelationManager.php" mode="EXCERPT">
````php
<?php

namespace App\Filament\ChinookAdmin\Resources\MediaTypeResource\RelationManagers;

use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;

class TracksRelationManager extends RelationManager
{
    protected static string $relationship = 'tracks';
    
    protected static ?string $recordTitleAttribute = 'name';

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('name')
            ->columns([
                Tables\Columns\TextColumn::make('name')
                    ->searchable()
                    ->sortable(),
                    
                Tables\Columns\TextColumn::make('album.artist.name')
                    ->label('Artist')
                    ->searchable(),
                    
                Tables\Columns\TextColumn::make('album.title')
                    ->label('Album')
                    ->searchable(),
                    
                Tables\Columns\TextColumn::make('milliseconds')
                    ->label('Duration')
                    ->formatStateUsing(fn (int $state): string => 
                        gmdate('i:s', intval($state / 1000))
                    ),
                    
                Tables\Columns\TextColumn::make('unit_price')
                    ->money('USD')
                    ->sortable(),
            ])
            ->actions([
                Tables\Actions\ViewAction::make()
                    ->url(fn ($record) => 
                        route('filament.chinook-admin.resources.tracks.view', $record)
                    ),
            ]);
    }
}
````
</augment_code_snippet>

## 6.5. Format Validation

### 6.5.1. Custom Validation Rules

<augment_code_snippet path="app/Rules/ValidMimeType.php" mode="EXCERPT">
````php
<?php

namespace App\Rules;

use Illuminate\Contracts\Validation\Rule;

class ValidMimeType implements Rule
{
    private array $allowedMimeTypes = [
        'audio/mpeg',
        'audio/mp4',
        'audio/flac',
        'audio/wav',
        'audio/ogg',
        'audio/aac',
        'audio/wma',
    ];

    public function passes($attribute, $value): bool
    {
        return in_array($value, $this->allowedMimeTypes);
    }

    public function message(): string
    {
        return 'The :attribute must be a valid audio MIME type.';
    }
}
````
</augment_code_snippet>

## 6.6. Advanced Features

### 6.6.1. Usage Statistics

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/MediaTypeResource.php" mode="EXCERPT">
````php
// Add usage statistics to the view page
public static function infolist(Infolist $infolist): Infolist
{
    return $infolist
        ->schema([
            Infolists\Components\Section::make('Media Type Details')
                ->schema([
                    Infolists\Components\TextEntry::make('name'),
                    Infolists\Components\TextEntry::make('mime_type'),
                    Infolists\Components\TextEntry::make('file_extension')
                        ->formatStateUsing(fn (string $state): string => ".{$state}"),
                    Infolists\Components\IconEntry::make('is_active')
                        ->boolean(),
                ])
                ->columns(2),
                
            Infolists\Components\Section::make('Usage Statistics')
                ->schema([
                    Infolists\Components\TextEntry::make('tracks_count')
                        ->label('Total Tracks')
                        ->getStateUsing(fn (MediaType $record): int => 
                            $record->tracks()->count()
                        ),
                        
                    Infolists\Components\TextEntry::make('total_duration')
                        ->label('Total Duration')
                        ->getStateUsing(fn (MediaType $record): string => {
                            $totalMs = $record->tracks()->sum('milliseconds');
                            return gmdate('H:i:s', intval($totalMs / 1000));
                        }),
                ])
                ->columns(2),
        ]);
}
````
</augment_code_snippet>

### 6.6.2. Bulk Actions

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/MediaTypeResource.php" mode="EXCERPT">
````php
->bulkActions([
    Tables\Actions\BulkActionGroup::make([
        Tables\Actions\DeleteBulkAction::make()
            ->action(function (Collection $records) {
                $cannotDelete = $records->filter(fn (MediaType $record) => 
                    $record->tracks()->count() > 0
                );
                
                if ($cannotDelete->count() > 0) {
                    Notification::make()
                        ->title('Some media types cannot be deleted')
                        ->body('Media types with existing tracks cannot be deleted.')
                        ->warning()
                        ->send();
                        
                    $records = $records->diff($cannotDelete);
                }
                
                $records->each->delete();
            }),
            
        Tables\Actions\BulkAction::make('activate')
            ->label('Activate Selected')
            ->icon('heroicon-o-check-circle')
            ->action(fn (Collection $records) => 
                $records->each->update(['is_active' => true])
            )
            ->deselectRecordsAfterCompletion(),
            
        Tables\Actions\BulkAction::make('deactivate')
            ->label('Deactivate Selected')
            ->icon('heroicon-o-x-circle')
            ->action(fn (Collection $records) => 
                $records->each->update(['is_active' => false])
            )
            ->deselectRecordsAfterCompletion(),
    ]),
])
````
</augment_code_snippet>

## 6.7. Testing Examples

### 6.7.1. Resource Test

<augment_code_snippet path="tests/Feature/Filament/MediaTypeResourceTest.php" mode="EXCERPT">

````php
<?php

namespace Tests\Feature\Filament;

use App\Models\Chinook\MediaType;use App\Models\Chinook\Track;use App\Models\User;use old\TestCase;

class MediaTypeResourceTest extends TestCase
{
    public function test_can_create_media_type(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)
            ->post(route('filament.chinook-admin.resources.media-types.store'), [
                'name' => 'MP3 Audio',
                'slug' => 'mp3-audio',
                'mime_type' => 'audio/mpeg',
                'file_extension' => 'mp3',
                'is_active' => true,
            ])
            ->assertRedirect();

        $this->assertDatabaseHas('chinook_media_types', [
            'name' => 'MP3 Audio',
            'mime_type' => 'audio/mpeg',
        ]);
    }

    public function test_cannot_delete_media_type_with_tracks(): void
    {
        $user = User::factory()->create();
        $mediaType = MediaType::factory()->create();
        Track::factory()->create(['media_type_id' => $mediaType->id]);

        $response = $this->actingAs($user)
            ->delete(route('filament.chinook-admin.resources.media-types.destroy', $mediaType));

        $this->assertDatabaseHas('chinook_media_types', [
            'id' => $mediaType->id,
        ]);
    }
}
````
</augment_code_snippet>

---

## Navigation

**Previous:** [Playlists Resource](050-playlists-resource.md) | **Index:** [Resources Documentation](000-resources-index.md) | **Next:** [Customers Resource](070-customers-resource.md)

---

**Documentation Standards**: This document follows WCAG 2.1 AA accessibility guidelines and uses Laravel 12 modern syntax patterns.

[⬆️ Back to Top](#6-media-types-resource)
