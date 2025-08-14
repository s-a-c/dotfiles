# Albums Resource - Complete Implementation Guide

> **Created:** 2025-07-16
> **Updated:** 2025-07-18
> **Focus:** Complete Album management with working code examples, tracks relationship manager, and artist integration
> **Source:** [Chinook Album Model](https://github.com/s-a-c/chinook/blob/main/app/Models/Chinook/Album.php)

## Table of Contents

- [Overview](#overview)
- [Resource Implementation](#resource-implementation)
  - [Basic Resource Structure](#basic-resource-structure)
  - [Form Schema](#form-schema)
  - [Table Configuration](#table-configuration)
- [Relationship Management](#relationship-management)
  - [Tracks Relationship Manager](#tracks-relationship-manager)
  - [Artist Relationship Manager](#artist-relationship-manager)
- [Media Integration](#media-integration)
- [Taxonomy Integration](#taxonomy-integration)
- [Authorization Policies](#authorization-policies)
- [Advanced Features](#advanced-features)
- [Testing Examples](#testing-examples)
- [Performance Optimization](#performance-optimization)

## Overview

The Albums Resource provides comprehensive management of music albums within the Chinook admin panel. It features complete CRUD operations, tracks relationship management, artist integration, media library support, and enhanced metadata handling with full Laravel 12 compatibility.

### Key Features

- **Complete CRUD Operations**: Create, read, update, delete albums with comprehensive validation
- **Tracks Management**: Inline tracks relationship manager with duration calculations and media type support
- **Artist Integration**: Seamless artist selection and relationship management with quick creation
- **Media Integration**: Album cover art management with Spatie Media Library
- **Release Information**: Comprehensive metadata including release dates, catalog numbers, and label information
- **Duration Tracking**: Automatic album duration calculation from tracks with real-time updates
- **Taxonomy Support**: Genre and style classification using aliziodev/laravel-taxonomy
- **Search & Filtering**: Full-text search with artist, release date, and taxonomy filtering
- **Bulk Operations**: Mass operations with permission checking and activity logging

### Model Integration

<augment_code_snippet path="app/Models/Chinook/Album.php" mode="EXCERPT">
````php
class Album extends BaseModel
{
    use HasTaxonomy; // From BaseModel - enables taxonomy relationships

    protected $table = 'chinook_albums';

    protected $fillable = [
        'title', 'artist_id', 'public_id', 'slug', 'release_date',
        'label', 'catalog_number', 'total_tracks', 'duration_seconds',
        'description', 'is_compilation',
    ];

    // Relationships
    public function artist(): BelongsTo
    public function tracks(): HasMany

    // Casts
    protected function casts(): array {
        'release_date' => 'date',
        'total_tracks' => 'integer',
        'duration_seconds' => 'integer',
        'is_compilation' => 'boolean',
    }

    // Accessors
    public function getFormattedDurationAttribute(): string
````
</augment_code_snippet>

## Resource Implementation

### Basic Resource Structure

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/AlbumResource.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Filament\ChinookAdmin\Resources;

use App\Models\Chinook\Album;
use App\Models\Chinook\Artist;
use App\Models\Chinook\MediaType;
use App\Filament\ChinookAdmin\Resources\AlbumResource\Pages;
use App\Filament\ChinookAdmin\Resources\AlbumResource\RelationManagers;
use Aliziodev\LaravelTaxonomy\Models\Taxonomy;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Infolists;
use Filament\Infolists\Infolist;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;
use Illuminate\Support\Str;
use Illuminate\Support\Collection;

class AlbumResource extends Resource
{
    protected static ?string $model = Album::class;

    protected static ?string $navigationIcon = 'heroicon-o-musical-note';

    protected static ?string $navigationGroup = 'Music Management';

    protected static ?int $navigationSort = 2;

    protected static ?string $recordTitleAttribute = 'title';

    protected static ?string $navigationBadgeTooltip = 'Total albums in database';

    protected static int $globalSearchResultsLimit = 20;

    public static function getNavigationBadge(): ?string
    {
        return static::getModel()::count();
    }

    public static function getGlobalSearchResultTitle(Model $record): string
    {
        return $record->title;
    }

    public static function getGlobalSearchResultDetails(Model $record): array
    {
        return [
            'Artist' => $record->artist?->name,
            'Release Date' => $record->release_date?->format('Y'),
            'Tracks' => $record->tracks_count ?? $record->tracks()->count(),
        ];
    }
````
</augment_code_snippet>

### Form Schema

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/AlbumResource.php" mode="EXCERPT">
````php
public static function form(Form $form): Form
{
    return $form
        ->schema([
            Forms\Components\Section::make('Album Information')
                ->schema([
                    Forms\Components\TextInput::make('title')
                        ->required()
                        ->maxLength(255)
                        ->live(onBlur: true)
                        ->afterStateUpdated(function (string $context, $state, callable $set) {
                            if ($context === 'create') {
                                $set('slug', Str::slug($state));
                            }
                        })
                        ->helperText('The album title'),

                    Forms\Components\TextInput::make('slug')
                        ->required()
                        ->maxLength(255)
                        ->unique(Album::class, 'slug', ignoreRecord: true)
                        ->rules(['alpha_dash'])
                        ->helperText('URL-friendly version of the title'),

                    Forms\Components\Select::make('artist_id')
                        ->label('Artist')
                        ->relationship('artist', 'name')
                        ->required()
                        ->searchable()
                        ->preload()
                        ->getOptionLabelFromRecordUsing(fn (Artist $record) =>
                            "{$record->name}" . ($record->country ? " ({$record->country})" : '')
                        )
                        ->createOptionForm([
                            Forms\Components\TextInput::make('name')
                                ->required()
                                ->maxLength(255)
                                ->helperText('Artist or band name'),

                            Forms\Components\Select::make('country')
                                ->options([
                                    'US' => 'United States',
                                    'UK' => 'United Kingdom',
                                    'CA' => 'Canada',
                                    'AU' => 'Australia',
                                    'DE' => 'Germany',
                                    'FR' => 'France',
                                    'IT' => 'Italy',
                                    'ES' => 'Spain',
                                    'JP' => 'Japan',
                                ])
                                ->searchable()
                                ->placeholder('Select country'),

                            Forms\Components\Toggle::make('is_active')
                                ->default(true),
                        ])
                        ->createOptionUsing(function (array $data) {
                            return Artist::create($data);
                        }),

                    Forms\Components\DatePicker::make('release_date')
                        ->native(false)
                        ->displayFormat('M d, Y')
                        ->placeholder('Select release date')
                        ->helperText('Official release date'),

                    Forms\Components\Toggle::make('is_compilation')
                        ->label('Compilation Album')
                        ->default(false)
                        ->helperText('Check if this is a compilation or greatest hits album'),
                ])
                ->columns(2),

            Forms\Components\Section::make('Release Details')
                ->schema([
                    Forms\Components\TextInput::make('label')
                        ->label('Record Label')
                        ->maxLength(255)
                        ->placeholder('e.g., Atlantic Records')
                        ->helperText('The record label that released this album'),

                    Forms\Components\TextInput::make('catalog_number')
                        ->maxLength(100)
                        ->placeholder('e.g., ATL-123456')
                        ->helperText('Catalog or product number'),

                    Forms\Components\TextInput::make('total_tracks')
                        ->label('Number of Tracks')
                        ->numeric()
                        ->minValue(1)
                        ->maxValue(999)
                        ->placeholder('Will be calculated from tracks')
                        ->helperText('Total number of tracks (auto-calculated)'),

                    Forms\Components\TextInput::make('duration_seconds')
                        ->label('Duration (seconds)')
                        ->numeric()
                        ->minValue(1)
                        ->placeholder('Will be calculated from tracks')
                        ->helperText('Total duration in seconds (auto-calculated)'),
                ])
                ->columns(2),

            Forms\Components\Section::make('Description & Media')
                ->schema([
                    Forms\Components\Textarea::make('description')
                        ->maxLength(2000)
                        ->rows(4)
                        ->placeholder('Album description, background information, or notes...')
                        ->helperText('Optional description or background information'),

                    Forms\Components\SpatieMediaLibraryFileUpload::make('cover_art')
                        ->label('Album Cover Art')
                        ->collection('cover_art')
                        ->image()
                        ->imageEditor()
                        ->imageEditorAspectRatios([
                            '1:1',
                        ])
                        ->maxSize(5120) // 5MB
                        ->acceptedFileTypes(['image/jpeg', 'image/png', 'image/webp'])
                        ->helperText('Upload album cover art (square format recommended)'),
                ])
                ->collapsible(),
````
</augment_code_snippet>

            // Taxonomy Integration Section
            Forms\Components\Section::make('Classification')
                ->schema([
                    Forms\Components\Select::make('taxonomies')
                        ->label('Genres & Styles')
                        ->relationship('taxonomies', 'name')
                        ->multiple()
                        ->searchable()
                        ->preload()
                        ->optionsLimit(50)
                        ->createOptionForm([
                            Forms\Components\Select::make('taxonomy_id')
                                ->label('Taxonomy Type')
                                ->options(function () {
                                    return Taxonomy::whereIn('name', ['music_genre', 'music_style', 'music_era'])
                                        ->pluck('name', 'id');
                                })
                                ->required(),
                            Forms\Components\TextInput::make('name')
                                ->required()
                                ->maxLength(255),
                            Forms\Components\TextInput::make('slug')
                                ->maxLength(255),
                            Forms\Components\Textarea::make('description')
                                ->maxLength(500),
                        ])
                        ->createOptionUsing(function (array $data) {
                            return \Aliziodev\LaravelTaxonomy\Models\TaxonomyTerm::create($data);
                        })
                        ->helperText('Select or create genres, styles, and eras for this album'),
                ])
                ->collapsible(),
        ]);
}
````
</augment_code_snippet>

### Table Configuration

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/AlbumResource.php" mode="EXCERPT">
````php
public static function table(Table $table): Table
{
    return $table
        ->columns([
            Tables\Columns\SpatieMediaLibraryImageColumn::make('cover_art')
                ->label('Cover')
                ->collection('cover_art')
                ->circular()
                ->defaultImageUrl('/images/default-album.png')
                ->size(50),

            Tables\Columns\TextColumn::make('title')
                ->searchable()
                ->sortable()
                ->weight('bold')
                ->description(fn (Album $record): string =>
                    $record->label ? "Label: {$record->label}" : ''
                ),

            Tables\Columns\TextColumn::make('artist.name')
                ->label('Artist')
                ->searchable()
                ->sortable()
                ->url(fn (Album $record): string =>
                    route('filament.chinook-admin.resources.artists.view', $record->artist)
                )
                ->openUrlInNewTab(),

            Tables\Columns\TextColumn::make('taxonomies.name')
                ->label('Genres')
                ->badge()
                ->color('info')
                ->limit(2)
                ->limitedRemainingText()
                ->searchable(),

            Tables\Columns\TextColumn::make('release_date')
                ->date('M d, Y')
                ->sortable()
                ->placeholder('Unknown')
                ->description(fn (Album $record): string =>
                    $record->release_date ? $record->release_date->diffForHumans() : ''
                ),

            Tables\Columns\TextColumn::make('tracks_count')
                ->counts('tracks')
                ->badge()
                ->color('success')
                ->label('Tracks'),

            Tables\Columns\TextColumn::make('duration_seconds')
                ->label('Duration')
                ->formatStateUsing(function ($state) {
                    if (!$state) return 'Unknown';
                    $minutes = floor($state / 60);
                    $seconds = $state % 60;
                    return sprintf('%d:%02d', $minutes, $seconds);
                })
                ->sortable()
                ->toggleable(),

            Tables\Columns\IconColumn::make('is_compilation')
                ->boolean()
                ->trueIcon('heroicon-o-collection')
                ->falseIcon('heroicon-o-musical-note')
                ->trueColor('warning')
                ->falseColor('primary')
                ->label('Type')
                ->tooltip(fn (Album $record): string =>
                    $record->is_compilation ? 'Compilation Album' : 'Studio Album'
                ),

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
            Tables\Filters\SelectFilter::make('artist')
                ->relationship('artist', 'name')
                ->searchable()
                ->preload()
                ->multiple(),

            Tables\Filters\Filter::make('release_date')
                ->form([
                    Forms\Components\DatePicker::make('released_from')
                        ->label('Released From'),
                    Forms\Components\DatePicker::make('released_until')
                        ->label('Released Until'),
                ])
                ->query(function (Builder $query, array $data): Builder {
                    return $query
                        ->when(
                            $data['released_from'],
                            fn (Builder $query, $date): Builder => $query->whereDate('release_date', '>=', $date),
                        )
                        ->when(
                            $data['released_until'],
                            fn (Builder $query, $date): Builder => $query->whereDate('release_date', '<=', $date),
                        );
                }),

            Tables\Filters\TernaryFilter::make('is_compilation')
                ->label('Compilation Albums')
                ->placeholder('All Albums')
                ->trueLabel('Compilations Only')
                ->falseLabel('Studio Albums Only'),

            Tables\Filters\SelectFilter::make('taxonomies')
                ->relationship('taxonomies', 'name')
                ->multiple()
                ->preload()
                ->label('Filter by Genres'),

            Tables\Filters\Filter::make('has_tracks')
                ->label('Has Tracks')
                ->query(fn (Builder $query): Builder => $query->has('tracks')),

            Tables\Filters\Filter::make('release_decade')
                ->form([
                    Forms\Components\Select::make('decade')
                        ->options([
                            '2020' => '2020s',
                            '2010' => '2010s',
                            '2000' => '2000s',
                            '1990' => '1990s',
                            '1980' => '1980s',
                            '1970' => '1970s',
                            '1960' => '1960s',
                            '1950' => '1950s',
                        ])
                        ->placeholder('Select decade'),
                ])
                ->query(function (Builder $query, array $data): Builder {
                    return $query->when(
                        $data['decade'],
                        fn (Builder $query, $decade): Builder => $query->whereBetween('release_date', [
                            "{$decade}-01-01",
                            ($decade + 9) . "-12-31"
                        ])
                    );
                }),

            Tables\Filters\TrashedFilter::make(),
        ])
````
</augment_code_snippet>

        ->actions([
            Tables\Actions\ViewAction::make(),
            Tables\Actions\EditAction::make(),
            Tables\Actions\DeleteAction::make(),
            Tables\Actions\RestoreAction::make(),
            Tables\Actions\ForceDeleteAction::make(),

            Tables\Actions\Action::make('view_artist')
                ->label('View Artist')
                ->icon('heroicon-o-user')
                ->url(fn (Album $record): string =>
                    route('filament.chinook-admin.resources.artists.view', $record->artist)
                )
                ->openUrlInNewTab(),
        ])
        ->bulkActions([
            Tables\Actions\BulkActionGroup::make([
                Tables\Actions\DeleteBulkAction::make(),
                Tables\Actions\RestoreBulkAction::make(),
                Tables\Actions\ForceDeleteBulkAction::make(),

                Tables\Actions\BulkAction::make('recalculate_duration')
                    ->label('Recalculate Duration')
                    ->icon('heroicon-o-calculator')
                    ->color('info')
                    ->action(function (Collection $records) {
                        $records->each(function (Album $album) {
                            $totalDuration = $album->tracks()->sum('milliseconds') / 1000;
                            $totalTracks = $album->tracks()->count();
                            $album->update([
                                'duration_seconds' => $totalDuration,
                                'total_tracks' => $totalTracks,
                            ]);
                        });
                    })
                    ->deselectRecordsAfterCompletion()
                    ->requiresConfirmation(),

                Tables\Actions\BulkAction::make('mark_compilation')
                    ->label('Mark as Compilation')
                    ->icon('heroicon-o-collection')
                    ->color('warning')
                    ->action(function (Collection $records) {
                        $records->each->update(['is_compilation' => true]);
                    })
                    ->deselectRecordsAfterCompletion()
                    ->requiresConfirmation(),

                Tables\Actions\BulkAction::make('export')
                    ->label('Export Selected')
                    ->icon('heroicon-o-arrow-down-tray')
                    ->action(function (Collection $records) {
                        return response()->streamDownload(function () use ($records) {
                            echo $records->load(['artist', 'tracks'])->toCsv();
                        }, 'albums.csv');
                    }),
            ]),
        ])
        ->defaultSort('release_date', 'desc')
        ->persistSortInSession()
        ->persistSearchInSession()
        ->persistFiltersInSession();
}
````
</augment_code_snippet>

## Relationship Management

### Tracks Relationship Manager

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/AlbumResource/RelationManagers/TracksRelationManager.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Filament\ChinookAdmin\Resources\AlbumResource\RelationManagers;

use App\Models\Chinook\Track;
use App\Models\Chinook\MediaType;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Str;

class TracksRelationManager extends RelationManager
{
    protected static string $relationship = 'tracks';

    protected static ?string $recordTitleAttribute = 'name';

    protected static ?string $navigationIcon = 'heroicon-o-play';

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Track Information')
                    ->schema([
                        Forms\Components\TextInput::make('name')
                            ->required()
                            ->maxLength(255)
                            ->live(onBlur: true)
                            ->afterStateUpdated(function (string $context, $state, callable $set) {
                                if ($context === 'create') {
                                    $set('slug', Str::slug($state));
                                }
                            })
                            ->helperText('Track title'),

                        Forms\Components\TextInput::make('slug')
                            ->required()
                            ->maxLength(255)
                            ->unique(Track::class, 'slug', ignoreRecord: true)
                            ->rules(['alpha_dash']),

                        Forms\Components\TextInput::make('track_number')
                            ->numeric()
                            ->required()
                            ->minValue(1)
                            ->maxValue(999)
                            ->helperText('Track number on the album'),

                        Forms\Components\TextInput::make('disc_number')
                            ->numeric()
                            ->default(1)
                            ->minValue(1)
                            ->maxValue(99)
                            ->helperText('Disc number for multi-disc albums'),

                        Forms\Components\TextInput::make('composer')
                            ->maxLength(255)
                            ->placeholder('e.g., John Lennon, Paul McCartney')
                            ->helperText('Song composer(s)'),
                    ])
                    ->columns(2),

                Forms\Components\Section::make('Technical Details')
                    ->schema([
                        Forms\Components\TextInput::make('milliseconds')
                            ->label('Duration (milliseconds)')
                            ->numeric()
                            ->required()
                            ->minValue(1000) // At least 1 second
                            ->placeholder('e.g., 180000 for 3 minutes')
                            ->helperText('Track duration in milliseconds'),

                        Forms\Components\Select::make('media_type_id')
                            ->label('Media Type')
                            ->relationship('mediaType', 'name')
                            ->required()
                            ->searchable()
                            ->preload()
                            ->createOptionForm([
                                Forms\Components\TextInput::make('name')
                                    ->required()
                                    ->maxLength(255),
                                Forms\Components\TextInput::make('mime_type')
                                    ->maxLength(255),
                                Forms\Components\TextInput::make('file_extension')
                                    ->maxLength(10),
                            ])
                            ->createOptionUsing(function (array $data) {
                                return MediaType::create($data);
                            }),

                        Forms\Components\TextInput::make('unit_price')
                            ->label('Unit Price')
                            ->numeric()
                            ->step(0.01)
                            ->minValue(0)
                            ->default(0.99)
                            ->prefix('$')
                            ->helperText('Price per track'),

                        Forms\Components\TextInput::make('bytes')
                            ->label('File Size (bytes)')
                            ->numeric()
                            ->minValue(1)
                            ->placeholder('File size in bytes')
                            ->helperText('Audio file size'),

                        Forms\Components\Toggle::make('explicit_content')
                            ->label('Explicit Content')
                            ->helperText('Contains explicit lyrics or content'),
                    ])
                    ->columns(2),

                Forms\Components\Section::make('Additional Information')
                    ->schema([
                        Forms\Components\Textarea::make('lyrics')
                            ->maxLength(10000)
                            ->rows(6)
                            ->placeholder('Track lyrics...')
                            ->helperText('Song lyrics (optional)'),

                        Forms\Components\TextInput::make('isrc')
                            ->label('ISRC Code')
                            ->maxLength(12)
                            ->placeholder('e.g., USRC17607839')
                            ->helperText('International Standard Recording Code'),
                    ])
                    ->collapsible(),
            ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('name')
            ->columns([
                Tables\Columns\TextColumn::make('track_number')
                    ->label('#')
                    ->sortable()
                    ->width(50),

                Tables\Columns\TextColumn::make('name')
                    ->searchable()
                    ->sortable()
                    ->weight('bold')
                    ->description(fn (Track $record): string =>
                        $record->composer ? "Composer: {$record->composer}" : ''
                    ),

                Tables\Columns\TextColumn::make('milliseconds')
                    ->label('Duration')
                    ->formatStateUsing(function ($state) {
                        if (!$state) return 'Unknown';
                        $totalSeconds = floor($state / 1000);
                        $minutes = floor($totalSeconds / 60);
                        $seconds = $totalSeconds % 60;
                        return sprintf('%d:%02d', $minutes, $seconds);
                    })
                    ->sortable(),

                Tables\Columns\TextColumn::make('mediaType.name')
                    ->label('Format')
                    ->badge()
                    ->color('info'),

                Tables\Columns\TextColumn::make('unit_price')
                    ->money('USD')
                    ->sortable(),

                Tables\Columns\TextColumn::make('bytes')
                    ->label('Size')
                    ->formatStateUsing(function ($state) {
                        if (!$state) return 'Unknown';
                        if ($state < 1024) return $state . ' B';
                        if ($state < 1048576) return round($state / 1024, 1) . ' KB';
                        return round($state / 1048576, 1) . ' MB';
                    })
                    ->toggleable(),

                Tables\Columns\IconColumn::make('explicit_content')
                    ->boolean()
                    ->trueIcon('heroicon-o-exclamation-triangle')
                    ->falseIcon('heroicon-o-check-circle')
                    ->trueColor('danger')
                    ->falseColor('success')
                    ->label('Content'),

                Tables\Columns\TextColumn::make('disc_number')
                    ->label('Disc')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),

                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('mediaType')
                    ->relationship('mediaType', 'name')
                    ->multiple(),

                Tables\Filters\Filter::make('explicit_content')
                    ->query(fn (Builder $query): Builder => $query->where('explicit_content', true))
                    ->label('Explicit Content Only'),

                Tables\Filters\Filter::make('has_composer')
                    ->query(fn (Builder $query): Builder => $query->whereNotNull('composer'))
                    ->label('Has Composer'),

                Tables\Filters\Filter::make('duration')
                    ->form([
                        Forms\Components\TextInput::make('min_duration')
                            ->label('Min Duration (seconds)')
                            ->numeric(),
                        Forms\Components\TextInput::make('max_duration')
                            ->label('Max Duration (seconds)')
                            ->numeric(),
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return $query
                            ->when(
                                $data['min_duration'],
                                fn (Builder $query, $duration): Builder =>
                                    $query->where('milliseconds', '>=', $duration * 1000)
                            )
                            ->when(
                                $data['max_duration'],
                                fn (Builder $query, $duration): Builder =>
                                    $query->where('milliseconds', '<=', $duration * 1000)
                            );
                    }),
            ])
            ->headerActions([
                Tables\Actions\CreateAction::make()
                    ->mutateFormDataUsing(function (array $data): array {
                        $data['album_id'] = $this->ownerRecord->id;
                        return $data;
                    })
                    ->after(function () {
                        // Recalculate album duration after adding track
                        $this->ownerRecord->refresh();
                        $totalDuration = $this->ownerRecord->tracks()->sum('milliseconds') / 1000;
                        $totalTracks = $this->ownerRecord->tracks()->count();
                        $this->ownerRecord->update([
                            'duration_seconds' => $totalDuration,
                            'total_tracks' => $totalTracks,
                        ]);
                    }),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
                Tables\Actions\EditAction::make()
                    ->after(function () {
                        // Recalculate album duration after editing track
                        $this->ownerRecord->refresh();
                        $totalDuration = $this->ownerRecord->tracks()->sum('milliseconds') / 1000;
                        $totalTracks = $this->ownerRecord->tracks()->count();
                        $this->ownerRecord->update([
                            'duration_seconds' => $totalDuration,
                            'total_tracks' => $totalTracks,
                        ]);
                    }),
                Tables\Actions\DeleteAction::make()
                    ->after(function () {
                        // Recalculate album duration after deleting track
                        $this->ownerRecord->refresh();
                        $totalDuration = $this->ownerRecord->tracks()->sum('milliseconds') / 1000;
                        $totalTracks = $this->ownerRecord->tracks()->count();
                        $this->ownerRecord->update([
                            'duration_seconds' => $totalDuration,
                            'total_tracks' => $totalTracks,
                        ]);
                    }),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make()
                        ->after(function () {
                            // Recalculate album duration after bulk delete
                            $this->ownerRecord->refresh();
                            $totalDuration = $this->ownerRecord->tracks()->sum('milliseconds') / 1000;
                            $totalTracks = $this->ownerRecord->tracks()->count();
                            $this->ownerRecord->update([
                                'duration_seconds' => $totalDuration,
                                'total_tracks' => $totalTracks,
                            ]);
                        }),
                ]),
            ])
            ->defaultSort('track_number')
            ->reorderable('track_number')
            ->paginatedWhileReordering();
    }
}
````
</augment_code_snippet>

### Artist Relationship Manager

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/AlbumResource/RelationManagers/ArtistRelationManager.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Filament\ChinookAdmin\Resources\AlbumResource\RelationManagers;

use App\Models\Chinook\Artist;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;

class ArtistRelationManager extends RelationManager
{
    protected static string $relationship = 'artist';

    protected static ?string $recordTitleAttribute = 'name';

    protected static ?string $navigationIcon = 'heroicon-o-user';

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('name')
            ->columns([
                Tables\Columns\ImageColumn::make('avatar')
                    ->circular()
                    ->defaultImageUrl('/images/default-artist.png')
                    ->size(40),

                Tables\Columns\TextColumn::make('name')
                    ->searchable()
                    ->sortable()
                    ->weight('bold')
                    ->description(fn (Artist $record): string =>
                        $record->country ? "From {$record->country}" : ''
                    ),

                Tables\Columns\TextColumn::make('albums_count')
                    ->counts('albums')
                    ->badge()
                    ->color('success')
                    ->label('Total Albums'),

                Tables\Columns\TextColumn::make('formed_year')
                    ->sortable()
                    ->placeholder('Unknown'),

                Tables\Columns\IconColumn::make('is_active')
                    ->boolean()
                    ->label('Active'),
            ])
            ->actions([
                Tables\Actions\Action::make('view_artist')
                    ->label('View Artist')
                    ->icon('heroicon-o-eye')
                    ->url(fn (Artist $record): string =>
                        route('filament.chinook-admin.resources.artists.view', $record)
                    )
                    ->openUrlInNewTab(),

                Tables\Actions\Action::make('view_all_albums')
                    ->label('All Albums')
                    ->icon('heroicon-o-musical-note')
                    ->url(fn (Artist $record): string =>
                        route('filament.chinook-admin.resources.albums.index', [
                            'tableFilters[artist][value]' => $record->id
                        ])
                    )
                    ->openUrlInNewTab(),
            ]);
    }
}
````
</augment_code_snippet>

## Media Integration

### Spatie Media Library Integration

<augment_code_snippet path="app/Models/Chinook/Album.php" mode="EXCERPT">
````php
use Spatie\MediaLibrary\HasMedia;
use Spatie\MediaLibrary\InteractsWithMedia;
use Spatie\MediaLibrary\MediaCollections\Models\Media;

class Album extends BaseModel implements HasMedia
{
    use InteractsWithMedia;

    public function registerMediaCollections(): void
    {
        $this->addMediaCollection('cover_art')
            ->singleFile()
            ->acceptsMimeTypes(['image/jpeg', 'image/png', 'image/webp']);

        $this->addMediaCollection('booklet')
            ->acceptsMimeTypes(['image/jpeg', 'image/png', 'application/pdf']);
    }

    public function registerMediaConversions(Media $media = null): void
    {
        $this->addMediaConversion('thumb')
            ->width(150)
            ->height(150)
            ->sharpen(10)
            ->performOnCollections('cover_art');

        $this->addMediaConversion('large')
            ->width(800)
            ->height(800)
            ->quality(90)
            ->performOnCollections('cover_art');
    }

    public function getCoverArtUrlAttribute(): ?string
    {
        return $this->getFirstMediaUrl('cover_art');
    }

    public function getCoverArtThumbUrlAttribute(): ?string
    {
        return $this->getFirstMediaUrl('cover_art', 'thumb');
    }
}
````
</augment_code_snippet>

## Taxonomy Integration

### Album Genre Classification

<augment_code_snippet path="app/Models/Chinook/Album.php" mode="EXCERPT">
````php
// Custom scopes for taxonomy filtering
public function scopeWithGenre($query, string $genreName)
{
    return $query->whereHas('taxonomies', function ($q) use ($genreName) {
        $q->where('name', $genreName);
    });
}

public function scopeWithAnyTaxonomy($query, array $taxonomyNames)
{
    return $query->whereHas('taxonomies', function ($q) use ($taxonomyNames) {
        $q->whereIn('name', $taxonomyNames);
    });
}

// Get primary genre
public function getPrimaryGenreAttribute(): ?string
{
    return $this->taxonomies()
        ->whereHas('taxonomy', function ($q) {
            $q->where('name', 'music_genre');
        })
        ->first()?->name;
}

// Usage in resource
public static function getEloquentQuery(): Builder
{
    return parent::getEloquentQuery()
        ->with(['artist', 'taxonomies', 'tracks'])
        ->withCount(['tracks']);
}
````
</augment_code_snippet>

## Authorization Policies

<augment_code_snippet path="app/Policies/Chinook/AlbumPolicy.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Policies\Chinook;

use App\Models\Chinook\Album;
use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

class AlbumPolicy
{
    use HandlesAuthorization;

    /**
     * Determine whether the user can view any models.
     */
    public function viewAny(User $user): bool
    {
        return $user->can('view_any_chinook::album');
    }

    /**
     * Determine whether the user can view the model.
     */
    public function view(User $user, Album $album): bool
    {
        return $user->can('view_chinook::album');
    }

    /**
     * Determine whether the user can create models.
     */
    public function create(User $user): bool
    {
        return $user->can('create_chinook::album');
    }

    /**
     * Determine whether the user can update the model.
     */
    public function update(User $user, Album $album): bool
    {
        return $user->can('update_chinook::album');
    }

    /**
     * Determine whether the user can delete the model.
     */
    public function delete(User $user, Album $album): bool
    {
        // Prevent deletion if album has tracks
        if ($album->tracks()->exists()) {
            return false;
        }

        return $user->can('delete_chinook::album');
    }

    /**
     * Determine whether the user can bulk delete.
     */
    public function deleteAny(User $user): bool
    {
        return $user->can('delete_any_chinook::album');
    }

    /**
     * Determine whether the user can permanently delete.
     */
    public function forceDelete(User $user, Album $album): bool
    {
        return $user->can('force_delete_chinook::album');
    }

    /**
     * Determine whether the user can permanently bulk delete.
     */
    public function forceDeleteAny(User $user): bool
    {
        return $user->can('force_delete_any_chinook::album');
    }

    /**
     * Determine whether the user can restore.
     */
    public function restore(User $user, Album $album): bool
    {
        return $user->can('restore_chinook::album');
    }

    /**
     * Determine whether the user can bulk restore.
     */
    public function restoreAny(User $user): bool
    {
        return $user->can('restore_any_chinook::album');
    }

    /**
     * Determine whether the user can replicate.
     */
    public function replicate(User $user, Album $album): bool
    {
        return $user->can('replicate_chinook::album');
    }

    /**
     * Determine whether the user can reorder.
     */
    public function reorder(User $user): bool
    {
        return $user->can('reorder_chinook::album');
    }
}
````
</augment_code_snippet>

### Resource Pages Configuration

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/AlbumResource.php" mode="EXCERPT">
````php
public static function getRelations(): array
{
    return [
        RelationManagers\TracksRelationManager::class,
        RelationManagers\ArtistRelationManager::class,
    ];
}

public static function getPages(): array
{
    return [
        'index' => Pages\ListAlbums::route('/'),
        'create' => Pages\CreateAlbum::route('/create'),
        'view' => Pages\ViewAlbum::route('/{record}'),
        'edit' => Pages\EditAlbum::route('/{record}/edit'),
    ];
}

// Enable soft deletes and optimize queries
public static function getEloquentQuery(): Builder
{
    return parent::getEloquentQuery()
        ->with(['artist:id,name,country', 'taxonomies:id,name'])
        ->withCount(['tracks'])
        ->withoutGlobalScopes([
            SoftDeletingScope::class,
        ]);
}
````
</augment_code_snippet>

## Advanced Features

### Duration Calculation and Auto-Updates

<augment_code_snippet path="app/Models/Chinook/Album.php" mode="EXCERPT">
````php
/**
 * Get formatted duration
 */
public function getFormattedDurationAttribute(): string
{
    $minutes = floor($this->duration_seconds / 60);
    $seconds = $this->duration_seconds % 60;

    return sprintf('%d:%02d', $minutes, $seconds);
}

/**
 * Calculate total duration from tracks
 */
public function calculateDuration(): void
{
    $this->duration_seconds = $this->tracks()
        ->sum('milliseconds') / 1000;
    $this->save();
}
````
</augment_code_snippet>

### 2.6.2. Bulk Actions

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/AlbumResource.php" mode="EXCERPT">
````php
->bulkActions([
    Tables\Actions\BulkActionGroup::make([
        Tables\Actions\DeleteBulkAction::make(),
        
        Tables\Actions\BulkAction::make('recalculate_duration')
            ->label('Recalculate Duration')
            ->icon('heroicon-o-calculator')
            ->action(fn (Collection $records) => 
                $records->each->calculateDuration()
            )
            ->deselectRecordsAfterCompletion(),
    ]),
])
````
</augment_code_snippet>

## 2.7. Testing Examples

### 2.7.1. Resource Test

<augment_code_snippet path="tests/Feature/Filament/AlbumResourceTest.php" mode="EXCERPT">

````php
<?php

namespace Tests\Feature\Filament;

use App\Models\Chinook\Album;use App\Models\Chinook\Artist;use App\Models\User;use old\TestCase;

class AlbumResourceTest extends TestCase
{
    public function test_can_create_album_with_artist(): void
    {
        $user = User::factory()->create();
        $artist = Artist::factory()->create();

        $this->actingAs($user)
            ->post(route('filament.chinook-admin.resources.albums.store'), [
                'title' => 'Test Album',
                'slug' => 'test-album',
                'artist_id' => $artist->id,
                'release_date' => '2024-01-01',
            ])
            ->assertRedirect();

        $this->assertDatabaseHas('chinook_albums', [
            'title' => 'Test Album',
            'artist_id' => $artist->id,
        ]);
    }
}
````
</augment_code_snippet>

## Performance Optimization

### Query Optimization

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/AlbumResource.php" mode="EXCERPT">
````php
// Optimized Eloquent query with eager loading
public static function getEloquentQuery(): Builder
{
    return parent::getEloquentQuery()
        ->with([
            'artist:id,name,country',
            'taxonomies:id,name,slug',
            'tracks:id,album_id,name,milliseconds',
        ])
        ->withCount([
            'tracks',
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
        ->poll('60s'); // Auto-refresh every minute
}
````
</augment_code_snippet>

### Caching Strategies

<augment_code_snippet path="app/Models/Chinook/Album.php" mode="EXCERPT">
````php
// Cache expensive computations
public function getTracksCountAttribute(): int
{
    return cache()->remember(
        "album.{$this->id}.tracks_count",
        now()->addHours(1),
        fn () => $this->tracks()->count()
    );
}

public function getDurationSecondsAttribute(): int
{
    return cache()->remember(
        "album.{$this->id}.duration_seconds",
        now()->addHours(1),
        fn () => $this->tracks()->sum('milliseconds') / 1000
    );
}

// Clear cache when model is updated
protected static function booted()
{
    static::updated(function ($album) {
        cache()->forget("album.{$album->id}.tracks_count");
        cache()->forget("album.{$album->id}.duration_seconds");
    });

    static::deleted(function ($album) {
        cache()->forget("album.{$album->id}.tracks_count");
        cache()->forget("album.{$album->id}.duration_seconds");
    });
}
````
</augment_code_snippet>

### Database Indexing

<augment_code_snippet path="database/migrations/create_chinook_albums_table.php" mode="EXCERPT">
````php
// Optimized indexes for Filament queries
Schema::create('chinook_albums', function (Blueprint $table) {
    $table->id();
    $table->string('title')->index(); // For searching and sorting
    $table->foreignId('artist_id')->constrained('chinook_artists')->index(); // For filtering
    $table->date('release_date')->nullable()->index(); // For filtering and sorting
    $table->boolean('is_compilation')->default(false)->index(); // For filtering
    $table->string('public_id')->unique();
    $table->string('slug')->unique();

    // Composite indexes for common queries
    $table->index(['artist_id', 'release_date']);
    $table->index(['is_compilation', 'release_date']);
    $table->index(['title', 'artist_id']);

    // Full-text search index
    $table->fullText(['title', 'description']);

    $table->timestamps();
    $table->softDeletes();
});
````
</augment_code_snippet>

---

## Navigation

**← Previous:** [Artists Resource](010-artists-resource.md) | **Next →** [Tracks Resource](030-tracks-resource.md)

---

## Related Documentation

- [Chinook Models Guide](../../020-database/030-models-guide.md)
- [Artist Resource Guide](010-artists-resource.md)
- [Tracks Resource Guide](030-tracks-resource.md)
- [Media Library Integration](../020-models/080-media-library-integration.md)
- [Taxonomy Integration Guide](../020-models/090-taxonomy-integration.md)
- [Testing Implementation Examples](../../065-testing/050-testing-implementation-examples.md)
- [Performance Optimization Guide](../../070-performance/000-index.md)

---

**Documentation Standards**: This document follows WCAG 2.1 AA accessibility guidelines and uses Laravel 12 modern syntax patterns.

**Last Updated:** 2025-07-18
**Maintainer:** Technical Documentation Team
**Source:** [GitHub Repository](https://github.com/s-a-c/chinook)

[⬆️ Back to Top](#albums-resource---complete-implementation-guide)
