# 5. Playlists Resource

> **Created:** 2025-07-16  
> **Focus:** Playlist management with tracks relationship manager and ordering  
> **Source:** [Chinook Playlist Model](https://github.com/s-a-c/chinook/blob/main/app/Models/Chinook/Playlist.php)

## 5.1. Table of Contents

- [5.2. Overview](#52-overview)
- [5.3. Resource Implementation](#53-resource-implementation)
  - [5.3.1. Basic Resource Structure](#531-basic-resource-structure)
  - [5.3.2. Form Schema](#532-form-schema)
  - [5.3.3. Table Configuration](#533-table-configuration)
- [5.4. Relationship Management](#54-relationship-management)
  - [5.4.1. Tracks Relationship Manager](#541-tracks-relationship-manager)
- [5.5. Track Ordering](#55-track-ordering)
- [5.6. Advanced Features](#56-advanced-features)
- [5.7. Testing Examples](#57-testing-examples)

## 5.2. Overview

The Playlists Resource provides comprehensive management of music playlists within the Chinook admin panel. It features complete CRUD operations, tracks relationship management with ordering, duration calculations, and public/private playlist controls.

### 5.2.1. Key Features

- **Complete CRUD Operations**: Create, read, update, delete playlists with validation
- **Track Management**: Inline tracks relationship manager with position ordering
- **Duration Tracking**: Automatic playlist duration calculation from tracks
- **Visibility Controls**: Public/private playlist management
- **Track Ordering**: Drag-and-drop track reordering within playlists
- **Search & Filtering**: Full-text search with visibility and duration filtering

### 5.2.2. Model Integration

<augment_code_snippet path="app/Models/Chinook/Playlist.php" mode="EXCERPT">
````php
class Playlist extends BaseModel
{
    protected $table = 'chinook_playlists';

    protected $fillable = [
        'name',
        'public_id',
        'slug',
        'description',
        'is_public',
        'total_duration',
        'track_count',
    ];

    /**
     * Playlist belongs to many tracks
     */
    public function tracks(): BelongsToMany
    {
        return $this->belongsToMany(Track::class, 'chinook_playlist_track', 'playlist_id', 'track_id')
            ->withPivot('position')
            ->withTimestamps()
            ->orderBy('pivot_position');
    }
````
</augment_code_snippet>

## 5.3. Resource Implementation

### 5.3.1. Basic Resource Structure

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/PlaylistResource.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Filament\ChinookAdmin\Resources;

use App\Models\Chinook\Playlist;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class PlaylistResource extends Resource
{
    protected static ?string $model = Playlist::class;
    
    protected static ?string $navigationIcon = 'heroicon-o-queue-list';
    
    protected static ?string $navigationGroup = 'Music Management';
    
    protected static ?int $navigationSort = 5;
    
    protected static ?string $recordTitleAttribute = 'name';
````
</augment_code_snippet>

### 5.3.2. Form Schema

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/PlaylistResource.php" mode="EXCERPT">
````php
public static function form(Form $form): Form
{
    return $form
        ->schema([
            Forms\Components\Section::make('Playlist Information')
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
                        
                    Forms\Components\Textarea::make('description')
                        ->maxLength(1000)
                        ->rows(3),
                        
                    Forms\Components\Toggle::make('is_public')
                        ->label('Public Playlist')
                        ->default(false)
                        ->helperText('Public playlists are visible to all users'),
                ])
                ->columns(2),
                
            Forms\Components\Section::make('Statistics')
                ->schema([
                    Forms\Components\Placeholder::make('track_count')
                        ->label('Total Tracks')
                        ->content(fn (Playlist $record): string => 
                            number_format($record->track_count ?? 0)
                        ),
                        
                    Forms\Components\Placeholder::make('formatted_duration')
                        ->label('Total Duration')
                        ->content(fn (Playlist $record): string => 
                            $record->getFormattedDurationAttribute()
                        ),
                ])
                ->columns(2)
                ->hiddenOn('create'),
        ]);
}
````
</augment_code_snippet>

### 5.3.3. Table Configuration

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/PlaylistResource.php" mode="EXCERPT">
````php
public static function table(Table $table): Table
{
    return $table
        ->columns([
            Tables\Columns\TextColumn::make('name')
                ->searchable()
                ->sortable()
                ->weight(FontWeight::Bold),
                
            Tables\Columns\TextColumn::make('description')
                ->limit(50)
                ->toggleable(),
                
            Tables\Columns\IconColumn::make('is_public')
                ->boolean()
                ->trueIcon('heroicon-o-globe-alt')
                ->falseIcon('heroicon-o-lock-closed')
                ->trueColor('success')
                ->falseColor('warning'),
                
            Tables\Columns\TextColumn::make('track_count')
                ->label('Tracks')
                ->badge()
                ->color('info'),
                
            Tables\Columns\TextColumn::make('formatted_duration')
                ->label('Duration')
                ->getStateUsing(fn (Playlist $record): string => 
                    $record->getFormattedDurationAttribute()
                ),
                
            Tables\Columns\TextColumn::make('created_at')
                ->dateTime()
                ->sortable()
                ->toggleable(isToggledHiddenByDefault: true),
        ])
        ->filters([
            Tables\Filters\TernaryFilter::make('is_public')
                ->label('Visibility')
                ->trueLabel('Public Only')
                ->falseLabel('Private Only')
                ->native(false),
                
            Tables\Filters\Filter::make('has_tracks')
                ->label('Has Tracks')
                ->query(fn (Builder $query): Builder => 
                    $query->where('track_count', '>', 0)
                ),
        ])
````
</augment_code_snippet>

## 5.4. Relationship Management

### 5.4.1. Tracks Relationship Manager

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/PlaylistResource/RelationManagers/TracksRelationManager.php" mode="EXCERPT">
````php
<?php

namespace App\Filament\ChinookAdmin\Resources\PlaylistResource\RelationManagers;

use App\Models\Chinook\Track;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;

class TracksRelationManager extends RelationManager
{
    protected static string $relationship = 'tracks';
    
    protected static ?string $recordTitleAttribute = 'name';

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Select::make('track_id')
                    ->label('Track')
                    ->relationship('track', 'name')
                    ->searchable()
                    ->preload()
                    ->getOptionLabelFromRecordUsing(fn (Track $record) => 
                        "{$record->name} - {$record->album->artist->name}"
                    )
                    ->required(),
                    
                Forms\Components\TextInput::make('position')
                    ->numeric()
                    ->default(fn () => $this->getOwnerRecord()->tracks()->count() + 1)
                    ->minValue(1)
                    ->required(),
            ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('name')
            ->columns([
                Tables\Columns\TextColumn::make('pivot.position')
                    ->label('#')
                    ->sortable(),
                    
                Tables\Columns\TextColumn::make('name')
                    ->searchable()
                    ->sortable(),
                    
                Tables\Columns\TextColumn::make('album.artist.name')
                    ->label('Artist')
                    ->searchable(),
                    
                Tables\Columns\TextColumn::make('album.title')
                    ->label('Album')
                    ->searchable()
                    ->toggleable(),
                    
                Tables\Columns\TextColumn::make('milliseconds')
                    ->label('Duration')
                    ->formatStateUsing(fn (int $state): string => 
                        gmdate('i:s', intval($state / 1000))
                    ),
            ])
            ->defaultSort('pivot.position')
            ->reorderable('pivot.position')
            ->headerActions([
                Tables\Actions\AttachAction::make()
                    ->form(fn (Tables\Actions\AttachAction $action): array => [
                        $action->getRecordSelect()
                            ->searchable()
                            ->getOptionLabelFromRecordUsing(fn (Track $record) => 
                                "{$record->name} - {$record->album->artist->name}"
                            ),
                            
                        Forms\Components\TextInput::make('position')
                            ->numeric()
                            ->default($this->getOwnerRecord()->tracks()->count() + 1)
                            ->minValue(1)
                            ->required(),
                    ]),
            ])
            ->actions([
                Tables\Actions\DetachAction::make(),
            ]);
    }
}
````
</augment_code_snippet>

## 5.5. Track Ordering

### 5.5.1. Reorder Functionality

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/PlaylistResource.php" mode="EXCERPT">
````php
// Enable reordering in the tracks relationship manager
->reorderable('pivot.position')

// Custom reorder action
Tables\Actions\Action::make('reorder_tracks')
    ->label('Reorder Tracks')
    ->icon('heroicon-o-arrows-up-down')
    ->action(function (Playlist $record) {
        // Custom reordering logic
        $tracks = $record->tracks()->orderBy('pivot.position')->get();
        
        foreach ($tracks as $index => $track) {
            $record->tracks()->updateExistingPivot($track->id, [
                'position' => $index + 1
            ]);
        }
        
        Notification::make()
            ->title('Tracks reordered successfully')
            ->success()
            ->send();
    }),
````
</augment_code_snippet>

## 5.6. Advanced Features

### 5.6.1. Duration Calculation

<augment_code_snippet path="app/Models/Chinook/Playlist.php" mode="EXCERPT">
````php
/**
 * Get formatted duration
 */
public function getFormattedDurationAttribute(): string
{
    $totalSeconds = floor($this->total_duration / 1000);
    $hours = floor($totalSeconds / 3600);
    $minutes = floor(($totalSeconds % 3600) / 60);
    $seconds = $totalSeconds % 60;

    if ($hours > 0) {
        return sprintf('%d:%02d:%02d', $hours, $minutes, $seconds);
    }

    return sprintf('%d:%02d', $minutes, $seconds);
}

/**
 * Update playlist statistics
 */
public function updateStatistics(): void
{
    $this->track_count = $this->tracks()->count();
    $this->total_duration = $this->tracks()->sum('milliseconds');
    $this->save();
}
````
</augment_code_snippet>

### 5.6.2. Bulk Actions

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/PlaylistResource.php" mode="EXCERPT">
````php
->bulkActions([
    Tables\Actions\BulkActionGroup::make([
        Tables\Actions\DeleteBulkAction::make(),
        
        Tables\Actions\BulkAction::make('make_public')
            ->label('Make Public')
            ->icon('heroicon-o-globe-alt')
            ->action(fn (Collection $records) => 
                $records->each->update(['is_public' => true])
            )
            ->deselectRecordsAfterCompletion(),
            
        Tables\Actions\BulkAction::make('make_private')
            ->label('Make Private')
            ->icon('heroicon-o-lock-closed')
            ->action(fn (Collection $records) => 
                $records->each->update(['is_public' => false])
            )
            ->deselectRecordsAfterCompletion(),
            
        Tables\Actions\BulkAction::make('update_statistics')
            ->label('Update Statistics')
            ->icon('heroicon-o-calculator')
            ->action(fn (Collection $records) => 
                $records->each->updateStatistics()
            )
            ->deselectRecordsAfterCompletion(),
    ]),
])
````
</augment_code_snippet>

## 5.7. Testing Examples

### 5.7.1. Resource Test

<augment_code_snippet path="tests/Feature/Filament/PlaylistResourceTest.php" mode="EXCERPT">

````php
<?php

namespace Tests\Feature\Filament;

use App\Models\Chinook\Playlist;use App\Models\Chinook\Track;use App\Models\User;use old\TestCase;

class PlaylistResourceTest extends TestCase
{
    public function test_can_create_playlist(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)
            ->post(route('filament.chinook-admin.resources.playlists.store'), [
                'name' => 'Test Playlist',
                'slug' => 'test-playlist',
                'description' => 'A test playlist',
                'is_public' => true,
            ])
            ->assertRedirect();

        $this->assertDatabaseHas('chinook_playlists', [
            'name' => 'Test Playlist',
            'is_public' => true,
        ]);
    }

    public function test_can_attach_tracks_to_playlist(): void
    {
        $user = User::factory()->create();
        $playlist = Playlist::factory()->create();
        $track = Track::factory()->create();

        $this->actingAs($user)
            ->post(route('filament.chinook-admin.resources.playlists.tracks.attach', $playlist), [
                'track_id' => $track->id,
                'position' => 1,
            ])
            ->assertRedirect();

        $this->assertDatabaseHas('chinook_playlist_track', [
            'playlist_id' => $playlist->id,
            'track_id' => $track->id,
            'position' => 1,
        ]);
    }
}
````
</augment_code_snippet>

---

## Navigation

**Previous:** [Media Types Resource](060-media-types-resource.md) | **Index:** [Resources Documentation](000-resources-index.md) | **Next:** [Customers Resource](070-customers-resource.md)

---

**Documentation Standards**: This document follows WCAG 2.1 AA accessibility guidelines and uses Laravel 12 modern syntax patterns.

[⬆️ Back to Top](#5-playlists-resource)
