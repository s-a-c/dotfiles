# Tracks Resource - Complete Implementation Guide

> **Created:** 2025-07-16
> **Updated:** 2025-07-18
> **Focus:** Complete Track management with working code examples, complex relationship managers, and comprehensive integrations
> **Source:** [Chinook Track Model](https://github.com/s-a-c/chinook/blob/main/app/Models/Chinook/Track.php)

## Table of Contents

- [Overview](#overview)
- [Resource Implementation](#resource-implementation)
  - [Basic Resource Structure](#basic-resource-structure)
  - [Form Schema](#form-schema)
  - [Table Configuration](#table-configuration)
- [Relationship Management](#relationship-management)
  - [Playlists Relationship Manager](#playlists-relationship-manager)
  - [Invoice Lines Relationship Manager](#invoice-lines-relationship-manager)
  - [Album Relationship Manager](#album-relationship-manager)
- [Media Integration](#media-integration)
- [Taxonomy Integration](#taxonomy-integration)
- [Authorization Policies](#authorization-policies)
- [Advanced Features](#advanced-features)
- [Testing Examples](#testing-examples)
- [Performance Optimization](#performance-optimization)

## Overview

The Tracks Resource provides comprehensive management of individual music tracks within the Chinook admin panel. It features complete CRUD operations, complex relationship management with playlists and invoice lines, audio file handling, pricing controls, sales analytics integration, and multi-dimensional taxonomy classification with full Laravel 12 compatibility.

### Key Features

- **Complete CRUD Operations**: Create, read, update, delete tracks with comprehensive validation
- **Complex Relationship Management**: Playlists (many-to-many), Invoice Lines (sales tracking), Album/Artist integration
- **Multi-Taxonomy Integration**: Genre, mood, theme, era, and instrument classification using aliziodev/laravel-taxonomy
- **Media Type Support**: Support for various audio formats with file validation and metadata extraction
- **Pricing Management**: Dynamic pricing with promotional capabilities and bulk price updates
- **Sales Analytics**: Real-time integration with invoice data for sales tracking and reporting
- **Audio File Handling**: Upload and management of audio files with Spatie Media Library
- **Playlist Integration**: Many-to-many track assignment to playlists with ordering
- **Search & Filtering**: Advanced search with album, artist, genre, and sales data filtering
- **Bulk Operations**: Mass operations with permission checking and activity logging

### Model Integration

<augment_code_snippet path="app/Models/Chinook/Track.php" mode="EXCERPT">
````php
class Track extends BaseModel
{
    use HasTaxonomy; // From BaseModel - enables taxonomy relationships

    protected $table = 'chinook_tracks';

    protected $fillable = [
        'name', 'album_id', 'media_type_id', 'public_id', 'slug',
        'composer', 'milliseconds', 'bytes', 'unit_price', 'track_number',
        'disc_number', 'lyrics', 'isrc', 'explicit_content',
    ];

    // Relationships
    public function album(): BelongsTo
    public function mediaType(): BelongsTo
    public function playlists(): BelongsToMany // with pivot position
    public function invoiceLines(): HasMany
    public function artist() // through album

    // Casts
    protected function casts(): array {
        'milliseconds' => 'integer',
        'bytes' => 'integer',
        'unit_price' => 'decimal:2',
        'track_number' => 'integer',
        'disc_number' => 'integer',
        'explicit_content' => 'boolean',
    }

    // Accessors
    public function getFormattedDurationAttribute(): string
    public function getFormattedSizeAttribute(): string
````
</augment_code_snippet>

## Resource Implementation

### Basic Resource Structure

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/TrackResource.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Filament\ChinookAdmin\Resources;

use App\Models\Chinook\Track;
use App\Models\Chinook\Album;
use App\Models\Chinook\MediaType;
use App\Models\Chinook\Playlist;
use App\Filament\ChinookAdmin\Resources\TrackResource\Pages;
use App\Filament\ChinookAdmin\Resources\TrackResource\RelationManagers;
use Aliziodev\LaravelTaxonomy\Models\Taxonomy;
use Aliziodev\LaravelTaxonomy\Models\TaxonomyTerm;
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

class TrackResource extends Resource
{
    protected static ?string $model = Track::class;

    protected static ?string $navigationIcon = 'heroicon-o-play';

    protected static ?string $navigationGroup = 'Music Management';

    protected static ?int $navigationSort = 3;

    protected static ?string $recordTitleAttribute = 'name';

    protected static ?string $navigationBadgeTooltip = 'Total tracks in database';

    protected static int $globalSearchResultsLimit = 20;

    public static function getNavigationBadge(): ?string
    {
        return static::getModel()::count();
    }

    public static function getGlobalSearchResultTitle(Model $record): string
    {
        return $record->name;
    }

    public static function getGlobalSearchResultDetails(Model $record): array
    {
        return [
            'Album' => $record->album?->title,
            'Artist' => $record->album?->artist?->name,
            'Duration' => $record->formatted_duration,
            'Price' => '$' . number_format($record->unit_price, 2),
        ];
    }
````
</augment_code_snippet>

### Form Schema

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/TrackResource.php" mode="EXCERPT">
````php
public static function form(Form $form): Form
{
    return $form
        ->schema([
            Forms\Components\Section::make('Track Information')
                ->schema([
                    Forms\Components\Select::make('album_id')
                        ->label('Album')
                        ->relationship('album', 'title')
                        ->searchable()
                        ->preload()
                        ->required()
                        ->getOptionLabelFromRecordUsing(fn (Album $record) =>
                            "{$record->title} - {$record->artist->name}"
                        )
                        ->createOptionForm([
                            Forms\Components\Select::make('artist_id')
                                ->label('Artist')
                                ->relationship('artist', 'name')
                                ->required()
                                ->searchable()
                                ->preload(),
                            Forms\Components\TextInput::make('title')
                                ->required()
                                ->maxLength(255),
                            Forms\Components\DatePicker::make('release_date')
                                ->native(false),
                            Forms\Components\TextInput::make('label')
                                ->maxLength(255),
                        ])
                        ->createOptionUsing(function (array $data) {
                            return Album::create($data);
                        })
                        ->helperText('Select album or create new one'),

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
                        ->rules(['alpha_dash'])
                        ->helperText('URL-friendly version of the title'),

                    Forms\Components\TextInput::make('composer')
                        ->maxLength(255)
                        ->placeholder('e.g., John Lennon, Paul McCartney')
                        ->helperText('Composer or songwriter name'),
                ])
                ->columns(2),

            Forms\Components\Section::make('Technical Details')
                ->schema([
                    Forms\Components\TextInput::make('track_number')
                        ->numeric()
                        ->required()
                        ->minValue(1)
                        ->maxValue(999)
                        ->helperText('Track position on the album'),

                    Forms\Components\TextInput::make('disc_number')
                        ->numeric()
                        ->default(1)
                        ->minValue(1)
                        ->maxValue(99)
                        ->helperText('Disc number for multi-disc albums'),

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
                                ->maxLength(255)
                                ->placeholder('e.g., audio/mpeg'),
                            Forms\Components\TextInput::make('file_extension')
                                ->maxLength(10)
                                ->placeholder('e.g., mp3'),
                            Forms\Components\Textarea::make('description')
                                ->maxLength(500),
                            Forms\Components\Toggle::make('is_active')
                                ->default(true),
                        ])
                        ->createOptionUsing(function (array $data) {
                            return MediaType::create($data);
                        }),

                    Forms\Components\TextInput::make('milliseconds')
                        ->label('Duration (milliseconds)')
                        ->numeric()
                        ->required()
                        ->minValue(1000) // At least 1 second
                        ->maxValue(3600000) // Max 1 hour
                        ->placeholder('e.g., 180000 for 3 minutes')
                        ->helperText('Track duration in milliseconds'),

                    Forms\Components\TextInput::make('bytes')
                        ->label('File Size (bytes)')
                        ->numeric()
                        ->minValue(1)
                        ->placeholder('Audio file size in bytes')
                        ->helperText('File size in bytes'),

                    Forms\Components\TextInput::make('unit_price')
                        ->label('Unit Price')
                        ->numeric()
                        ->required()
                        ->minValue(0)
                        ->step(0.01)
                        ->prefix('$')
                        ->default(0.99)
                        ->helperText('Price per track purchase'),
                ])
                ->columns(3),

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
                                    return Taxonomy::whereIn('name', [
                                        'music_genre', 'music_style', 'music_era',
                                        'music_mood', 'music_theme', 'music_instrument'
                                    ])->pluck('name', 'id');
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
                        ->helperText('Select or create genres, styles, moods, and themes for this track'),
                ])
                ->collapsible(),

            Forms\Components\Section::make('Content & Metadata')
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

                    Forms\Components\Toggle::make('explicit_content')
                        ->label('Explicit Content')
                        ->helperText('Contains explicit lyrics or content'),

                    Forms\Components\SpatieMediaLibraryFileUpload::make('audio_file')
                        ->label('Audio File')
                        ->collection('audio_files')
                        ->acceptedFileTypes(['audio/mpeg', 'audio/flac', 'audio/wav', 'audio/mp4'])
                        ->maxSize(51200) // 50MB
                        ->downloadable()
                        ->previewable(false)
                        ->helperText('Upload audio file (MP3, FLAC, WAV, or M4A format, max 50MB)'),
                ])
                ->columns(2)
                ->collapsible(),

            Forms\Components\Section::make('Additional Information')
                ->schema([
                    Forms\Components\KeyValue::make('metadata')
                        ->keyLabel('Property')
                        ->valueLabel('Value')
                        ->addActionLabel('Add metadata')
                        ->helperText('Additional track metadata (BPM, key signature, etc.)')
                        ->columnSpanFull(),
                ])
                ->collapsible(),
        ]);
}
````
</augment_code_snippet>

### Table Configuration

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/TrackResource.php" mode="EXCERPT">
````php
public static function table(Table $table): Table
{
    return $table
        ->columns([
            Tables\Columns\TextColumn::make('track_number')
                ->label('#')
                ->sortable()
                ->width(50)
                ->alignCenter(),

            Tables\Columns\TextColumn::make('name')
                ->searchable()
                ->sortable()
                ->weight('bold')
                ->description(fn (Track $record): string =>
                    $record->composer ? "Composer: {$record->composer}" : ''
                ),

            Tables\Columns\TextColumn::make('album.title')
                ->label('Album')
                ->searchable()
                ->sortable()
                ->url(fn (Track $record): string =>
                    route('filament.chinook-admin.resources.albums.view', $record->album)
                )
                ->openUrlInNewTab()
                ->description(fn (Track $record): string =>
                    $record->album?->artist?->name ?? ''
                ),

            Tables\Columns\TextColumn::make('album.artist.name')
                ->label('Artist')
                ->searchable()
                ->sortable()
                ->url(fn (Track $record): string =>
                    route('filament.chinook-admin.resources.artists.view', $record->album->artist)
                )
                ->openUrlInNewTab()
                ->toggleable(),

            Tables\Columns\TextColumn::make('taxonomies.name')
                ->label('Genres')
                ->badge()
                ->color('info')
                ->limit(2)
                ->limitedRemainingText()
                ->searchable(),

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
                ->color('success'),

            Tables\Columns\TextColumn::make('unit_price')
                ->label('Price')
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

            Tables\Columns\TextColumn::make('invoiceLines_count')
                ->counts('invoiceLines')
                ->badge()
                ->color('warning')
                ->label('Sales')
                ->toggleable(),

            Tables\Columns\TextColumn::make('playlists_count')
                ->counts('playlists')
                ->badge()
                ->color('primary')
                ->label('Playlists')
                ->toggleable(),

            Tables\Columns\TextColumn::make('disc_number')
                ->label('Disc')
                ->sortable()
                ->toggleable(isToggledHiddenByDefault: true),

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
            Tables\Filters\SelectFilter::make('album')
                ->relationship('album', 'title')
                ->searchable()
                ->preload()
                ->multiple(),

            Tables\Filters\SelectFilter::make('artist')
                ->relationship('album.artist', 'name')
                ->searchable()
                ->preload()
                ->multiple(),

            Tables\Filters\SelectFilter::make('mediaType')
                ->relationship('mediaType', 'name')
                ->multiple(),

            Tables\Filters\SelectFilter::make('taxonomies')
                ->relationship('taxonomies', 'name')
                ->multiple()
                ->preload()
                ->label('Filter by Genres/Styles'),

            Tables\Filters\Filter::make('explicit_content')
                ->query(fn (Builder $query): Builder => $query->where('explicit_content', true))
                ->label('Explicit Content Only'),

            Tables\Filters\Filter::make('has_lyrics')
                ->query(fn (Builder $query): Builder => $query->whereNotNull('lyrics'))
                ->label('Has Lyrics'),

            Tables\Filters\Filter::make('has_composer')
                ->query(fn (Builder $query): Builder => $query->whereNotNull('composer'))
                ->label('Has Composer'),

            Tables\Filters\Filter::make('price_range')
                ->form([
                    Forms\Components\TextInput::make('price_from')
                        ->label('Min Price')
                        ->numeric()
                        ->prefix('$'),
                    Forms\Components\TextInput::make('price_to')
                        ->label('Max Price')
                        ->numeric()
                        ->prefix('$'),
                ])
                ->query(function (Builder $query, array $data): Builder {
                    return $query
                        ->when($data['price_from'], fn ($q) => $q->where('unit_price', '>=', $data['price_from']))
                        ->when($data['price_to'], fn ($q) => $q->where('unit_price', '<=', $data['price_to']));
                }),

            Tables\Filters\Filter::make('duration_range')
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

            Tables\Filters\Filter::make('popular_tracks')
                ->query(fn (Builder $query): Builder =>
                    $query->has('invoiceLines', '>=', 5)
                )
                ->label('Popular Tracks (5+ sales)'),

            Tables\Filters\TrashedFilter::make(),
        ])
        ->actions([
            Tables\Actions\ViewAction::make(),
            Tables\Actions\EditAction::make(),
            Tables\Actions\DeleteAction::make(),
            Tables\Actions\RestoreAction::make(),
            Tables\Actions\ForceDeleteAction::make(),

            Tables\Actions\Action::make('view_album')
                ->label('View Album')
                ->icon('heroicon-o-musical-note')
                ->url(fn (Track $record): string =>
                    route('filament.chinook-admin.resources.albums.view', $record->album)
                )
                ->openUrlInNewTab(),

            Tables\Actions\Action::make('add_to_playlist')
                ->label('Add to Playlist')
                ->icon('heroicon-o-queue-list')
                ->form([
                    Forms\Components\Select::make('playlist_id')
                        ->label('Playlist')
                        ->relationship('playlists', 'name')
                        ->searchable()
                        ->required(),
                    Forms\Components\TextInput::make('position')
                        ->numeric()
                        ->default(1)
                        ->minValue(1),
                ])
                ->action(function (Track $record, array $data) {
                    $playlist = Playlist::find($data['playlist_id']);
                    $record->playlists()->attach($playlist->id, [
                        'position' => $data['position']
                    ]);
                }),
        ])
        ->bulkActions([
            Tables\Actions\BulkActionGroup::make([
                Tables\Actions\DeleteBulkAction::make(),
                Tables\Actions\RestoreBulkAction::make(),
                Tables\Actions\ForceDeleteBulkAction::make(),

                Tables\Actions\BulkAction::make('assign_taxonomy')
                    ->label('Assign Genre/Style')
                    ->icon('heroicon-o-tag')
                    ->form([
                        Forms\Components\Select::make('taxonomy_term_id')
                            ->label('Genre/Style')
                            ->options(function () {
                                return \Aliziodev\LaravelTaxonomy\Models\TaxonomyTerm::whereHas('taxonomy', function ($q) {
                                    $q->whereIn('name', ['music_genre', 'music_style']);
                                })->pluck('name', 'id');
                            })
                            ->searchable()
                            ->required(),
                    ])
                    ->action(function (Collection $records, array $data) {
                        $term = \Aliziodev\LaravelTaxonomy\Models\TaxonomyTerm::find($data['taxonomy_term_id']);
                        if ($term) {
                            foreach ($records as $record) {
                                $record->taxonomies()->syncWithoutDetaching([$term->id]);
                            }
                        }
                    })
                    ->deselectRecordsAfterCompletion()
                    ->requiresConfirmation(),

                Tables\Actions\BulkAction::make('update_price')
                    ->label('Update Price')
                    ->icon('heroicon-o-currency-dollar')
                    ->form([
                        Forms\Components\TextInput::make('unit_price')
                            ->label('New Price')
                            ->numeric()
                            ->step(0.01)
                            ->prefix('$')
                            ->required(),
                    ])
                    ->action(function (Collection $records, array $data) {
                        $records->each->update(['unit_price' => $data['unit_price']]);
                    })
                    ->deselectRecordsAfterCompletion()
                    ->requiresConfirmation(),

                Tables\Actions\BulkAction::make('add_to_playlist')
                    ->label('Add to Playlist')
                    ->icon('heroicon-o-queue-list')
                    ->form([
                        Forms\Components\Select::make('playlist_id')
                            ->label('Playlist')
                            ->relationship('playlists', 'name')
                            ->searchable()
                            ->required(),
                    ])
                    ->action(function (Collection $records, array $data) {
                        $playlist = Playlist::find($data['playlist_id']);
                        $maxPosition = $playlist->tracks()->max('pivot_position') ?? 0;
                        foreach ($records as $index => $record) {
                            $playlist->tracks()->syncWithoutDetaching([
                                $record->id => ['position' => $maxPosition + $index + 1]
                            ]);
                        }
                    })
                    ->deselectRecordsAfterCompletion(),

                Tables\Actions\BulkAction::make('export')
                    ->label('Export Selected')
                    ->icon('heroicon-o-arrow-down-tray')
                    ->action(function (Collection $records) {
                        return response()->streamDownload(function () use ($records) {
                            echo $records->load(['album.artist', 'mediaType', 'taxonomies'])->toCsv();
                        }, 'tracks.csv');
                    }),
            ]),
        ])
        ->defaultSort('album.title')
        ->defaultSort('track_number')
        ->persistSortInSession()
        ->persistSearchInSession()
        ->persistFiltersInSession();
}
````
</augment_code_snippet>

## Relationship Management

### Playlists Relationship Manager

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/TrackResource/RelationManagers/PlaylistsRelationManager.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Filament\ChinookAdmin\Resources\TrackResource\RelationManagers;

use App\Models\Chinook\Playlist;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class PlaylistsRelationManager extends RelationManager
{
    protected static string $relationship = 'playlists';

    protected static ?string $recordTitleAttribute = 'name';

    protected static ?string $navigationIcon = 'heroicon-o-queue-list';

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('name')
            ->columns([
                Tables\Columns\TextColumn::make('name')
                    ->searchable()
                    ->sortable()
                    ->weight('bold')
                    ->description(fn (Playlist $record): string =>
                        $record->description ?? ''
                    ),

                Tables\Columns\TextColumn::make('pivot.position')
                    ->label('Position')
                    ->sortable()
                    ->alignCenter(),

                Tables\Columns\TextColumn::make('track_count')
                    ->badge()
                    ->color('success')
                    ->label('Total Tracks'),

                Tables\Columns\TextColumn::make('total_duration')
                    ->label('Duration')
                    ->formatStateUsing(function ($state) {
                        if (!$state) return 'Unknown';
                        $totalSeconds = floor($state / 1000);
                        $hours = floor($totalSeconds / 3600);
                        $minutes = floor(($totalSeconds % 3600) / 60);
                        if ($hours > 0) {
                            return sprintf('%d:%02d:%02d', $hours, $minutes, $totalSeconds % 60);
                        }
                        return sprintf('%d:%02d', $minutes, $totalSeconds % 60);
                    }),

                Tables\Columns\IconColumn::make('is_public')
                    ->boolean()
                    ->label('Public'),

                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\Filter::make('is_public')
                    ->query(fn (Builder $query): Builder => $query->where('is_public', true)),
            ])
            ->headerActions([
                Tables\Actions\AttachAction::make()
                    ->form(fn (Tables\Actions\AttachAction $action): array => [
                        $action->getRecordSelect(),
                        Forms\Components\TextInput::make('position')
                            ->numeric()
                            ->default(1)
                            ->minValue(1)
                            ->required(),
                    ]),
            ])
            ->actions([
                Tables\Actions\DetachAction::make(),
                Tables\Actions\Action::make('view_playlist')
                    ->label('View Playlist')
                    ->icon('heroicon-o-eye')
                    ->url(fn (Playlist $record): string =>
                        route('filament.chinook-admin.resources.playlists.view', $record)
                    )
                    ->openUrlInNewTab(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DetachBulkAction::make(),
                ]),
            ])
            ->defaultSort('pivot_position');
    }
}
````
</augment_code_snippet>

### Invoice Lines Relationship Manager

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/TrackResource/RelationManagers/InvoiceLinesRelationManager.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Filament\ChinookAdmin\Resources\TrackResource\RelationManagers;

use App\Models\Chinook\InvoiceLine;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class InvoiceLinesRelationManager extends RelationManager
{
    protected static string $relationship = 'invoiceLines';

    protected static ?string $recordTitleAttribute = 'id';

    protected static ?string $navigationIcon = 'heroicon-o-receipt-percent';

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('id')
            ->columns([
                Tables\Columns\TextColumn::make('invoice.id')
                    ->label('Invoice #')
                    ->sortable()
                    ->url(fn (InvoiceLine $record): string =>
                        route('filament.chinook-admin.resources.invoices.view', $record->invoice)
                    )
                    ->openUrlInNewTab(),

                Tables\Columns\TextColumn::make('invoice.customer.full_name')
                    ->label('Customer')
                    ->searchable()
                    ->sortable()
                    ->url(fn (InvoiceLine $record): string =>
                        route('filament.chinook-admin.resources.customers.view', $record->invoice->customer)
                    )
                    ->openUrlInNewTab(),

                Tables\Columns\TextColumn::make('invoice.invoice_date')
                    ->label('Purchase Date')
                    ->date('M d, Y')
                    ->sortable(),

                Tables\Columns\TextColumn::make('unit_price')
                    ->label('Sale Price')
                    ->money('USD')
                    ->sortable(),

                Tables\Columns\TextColumn::make('quantity')
                    ->label('Qty')
                    ->alignCenter()
                    ->sortable(),

                Tables\Columns\TextColumn::make('total_amount')
                    ->label('Total')
                    ->money('USD')
                    ->getStateUsing(fn (InvoiceLine $record): float =>
                        $record->unit_price * $record->quantity
                    )
                    ->sortable(),

                Tables\Columns\TextColumn::make('invoice.billing_country')
                    ->label('Country')
                    ->badge()
                    ->toggleable(),

                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
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
                                    $query->whereHas('invoice', fn ($q) => $q->whereDate('invoice_date', '>=', $date))
                            )
                            ->when(
                                $data['until'],
                                fn (Builder $query, $date): Builder =>
                                    $query->whereHas('invoice', fn ($q) => $q->whereDate('invoice_date', '<=', $date))
                            );
                    }),

                Tables\Filters\SelectFilter::make('country')
                    ->relationship('invoice', 'billing_country')
                    ->multiple(),
            ])
            ->actions([
                Tables\Actions\Action::make('view_invoice')
                    ->label('View Invoice')
                    ->icon('heroicon-o-document-text')
                    ->url(fn (InvoiceLine $record): string =>
                        route('filament.chinook-admin.resources.invoices.view', $record->invoice)
                    )
                    ->openUrlInNewTab(),
            ])
            ->defaultSort('invoice.invoice_date', 'desc')
            ->paginated([10, 25, 50]);
    }
}
````
</augment_code_snippet>

### Album Relationship Manager

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/TrackResource/RelationManagers/AlbumRelationManager.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Filament\ChinookAdmin\Resources\TrackResource\RelationManagers;

use App\Models\Chinook\Album;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;

class AlbumRelationManager extends RelationManager
{
    protected static string $relationship = 'album';

    protected static ?string $recordTitleAttribute = 'title';

    protected static ?string $navigationIcon = 'heroicon-o-musical-note';

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('title')
            ->columns([
                Tables\Columns\SpatieMediaLibraryImageColumn::make('cover_art')
                    ->label('Cover')
                    ->collection('cover_art')
                    ->circular()
                    ->size(50),

                Tables\Columns\TextColumn::make('title')
                    ->searchable()
                    ->sortable()
                    ->weight('bold'),

                Tables\Columns\TextColumn::make('artist.name')
                    ->label('Artist')
                    ->searchable()
                    ->sortable()
                    ->url(fn (Album $record): string =>
                        route('filament.chinook-admin.resources.artists.view', $record->artist)
                    )
                    ->openUrlInNewTab(),

                Tables\Columns\TextColumn::make('release_date')
                    ->date('M d, Y')
                    ->sortable(),

                Tables\Columns\TextColumn::make('tracks_count')
                    ->counts('tracks')
                    ->badge()
                    ->color('success'),

                Tables\Columns\TextColumn::make('label')
                    ->toggleable(),
            ])
            ->actions([
                Tables\Actions\Action::make('view_album')
                    ->label('View Album')
                    ->icon('heroicon-o-eye')
                    ->url(fn (Album $record): string =>
                        route('filament.chinook-admin.resources.albums.view', $record)
                    )
                    ->openUrlInNewTab(),

                Tables\Actions\Action::make('view_all_tracks')
                    ->label('All Tracks')
                    ->icon('heroicon-o-play')
                    ->url(fn (Album $record): string =>
                        route('filament.chinook-admin.resources.tracks.index', [
                            'tableFilters[album][value]' => $record->id
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

<augment_code_snippet path="app/Models/Chinook/Track.php" mode="EXCERPT">
````php
use Spatie\MediaLibrary\HasMedia;
use Spatie\MediaLibrary\InteractsWithMedia;
use Spatie\MediaLibrary\MediaCollections\Models\Media;

class Track extends BaseModel implements HasMedia
{
    use InteractsWithMedia;

    public function registerMediaCollections(): void
    {
        $this->addMediaCollection('audio_files')
            ->singleFile()
            ->acceptsMimeTypes(['audio/mpeg', 'audio/flac', 'audio/wav', 'audio/mp4']);

        $this->addMediaCollection('artwork')
            ->acceptsMimeTypes(['image/jpeg', 'image/png', 'image/webp']);
    }

    public function registerMediaConversions(Media $media = null): void
    {
        $this->addMediaConversion('waveform')
            ->performOnCollections('audio_files')
            ->nonQueued();
    }

    public function getAudioFileUrlAttribute(): ?string
    {
        return $this->getFirstMediaUrl('audio_files');
    }

    public function getArtworkUrlAttribute(): ?string
    {
        return $this->getFirstMediaUrl('artwork');
    }
}
````
</augment_code_snippet>

## Taxonomy Integration

### Multi-Dimensional Classification

<augment_code_snippet path="app/Models/Chinook/Track.php" mode="EXCERPT">
````php
// Custom scopes for taxonomy filtering
public function scopeWithGenre($query, string $genreName)
{
    return $query->whereHas('taxonomies', function ($q) use ($genreName) {
        $q->where('name', $genreName);
    });
}

public function scopeWithMood($query, string $moodName)
{
    return $query->whereHas('taxonomies', function ($q) use ($moodName) {
        $q->where('name', $moodName)
          ->whereHas('taxonomy', fn($t) => $t->where('name', 'music_mood'));
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
        ->with(['album.artist', 'mediaType', 'taxonomies'])
        ->withCount(['playlists', 'invoiceLines']);
}
````
</augment_code_snippet>
## Authorization Policies

<augment_code_snippet path="app/Policies/Chinook/TrackPolicy.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Policies\Chinook;

use App\Models\Chinook\Track;
use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

class TrackPolicy
{
    use HandlesAuthorization;

    /**
     * Determine whether the user can view any models.
     */
    public function viewAny(User $user): bool
    {
        return $user->can('view_any_chinook::track');
    }

    /**
     * Determine whether the user can view the model.
     */
    public function view(User $user, Track $track): bool
    {
        return $user->can('view_chinook::track');
    }

    /**
     * Determine whether the user can create models.
     */
    public function create(User $user): bool
    {
        return $user->can('create_chinook::track');
    }

    /**
     * Determine whether the user can update the model.
     */
    public function update(User $user, Track $track): bool
    {
        return $user->can('update_chinook::track');
    }

    /**
     * Determine whether the user can delete the model.
     */
    public function delete(User $user, Track $track): bool
    {
        // Prevent deletion if track has sales
        if ($track->invoiceLines()->exists()) {
            return false;
        }

        return $user->can('delete_chinook::track');
    }

    /**
     * Determine whether the user can bulk delete.
     */
    public function deleteAny(User $user): bool
    {
        return $user->can('delete_any_chinook::track');
    }

    /**
     * Determine whether the user can permanently delete.
     */
    public function forceDelete(User $user, Track $track): bool
    {
        return $user->can('force_delete_chinook::track');
    }

    /**
     * Determine whether the user can permanently bulk delete.
     */
    public function forceDeleteAny(User $user): bool
    {
        return $user->can('force_delete_any_chinook::track');
    }

    /**
     * Determine whether the user can restore.
     */
    public function restore(User $user, Track $track): bool
    {
        return $user->can('restore_chinook::track');
    }

    /**
     * Determine whether the user can bulk restore.
     */
    public function restoreAny(User $user): bool
    {
        return $user->can('restore_any_chinook::track');
    }

    /**
     * Determine whether the user can replicate.
     */
    public function replicate(User $user, Track $track): bool
    {
        return $user->can('replicate_chinook::track');
    }

    /**
     * Determine whether the user can reorder.
     */
    public function reorder(User $user): bool
    {
        return $user->can('reorder_chinook::track');
    }
}
````
</augment_code_snippet>
### Resource Pages Configuration

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/TrackResource.php" mode="EXCERPT">
````php
public static function getRelations(): array
{
    return [
        RelationManagers\PlaylistsRelationManager::class,
        RelationManagers\InvoiceLinesRelationManager::class,
        RelationManagers\AlbumRelationManager::class,
    ];
}

public static function getPages(): array
{
    return [
        'index' => Pages\ListTracks::route('/'),
        'create' => Pages\CreateTrack::route('/create'),
        'view' => Pages\ViewTrack::route('/{record}'),
        'edit' => Pages\EditTrack::route('/{record}/edit'),
    ];
}

// Enable soft deletes and optimize queries
public static function getEloquentQuery(): Builder
{
    return parent::getEloquentQuery()
        ->with([
            'album:id,title,artist_id',
            'album.artist:id,name',
            'mediaType:id,name',
            'taxonomies:id,name'
        ])
        ->withCount(['playlists', 'invoiceLines'])
        ->withoutGlobalScopes([
            SoftDeletingScope::class,
        ]);
}
````
</augment_code_snippet>

## Advanced Features

### Sales Analytics Integration

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/TrackResource/Widgets/TrackSalesWidget.php" mode="EXCERPT">
````php
<?php

namespace App\Filament\ChinookAdmin\Resources\TrackResource\Widgets;

use App\Models\Chinook\Track;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class TrackSalesWidget extends BaseWidget
{
    protected function getStats(): array
    {
        return [
            Stat::make('Total Tracks', Track::count())
                ->description('All tracks in database')
                ->descriptionIcon('heroicon-m-arrow-trending-up')
                ->color('success'),

            Stat::make('Tracks with Sales', Track::has('invoiceLines')->count())
                ->description('Tracks that have been purchased')
                ->descriptionIcon('heroicon-m-currency-dollar')
                ->color('primary'),

            Stat::make('In Playlists', Track::has('playlists')->count())
                ->description('Tracks added to playlists')
                ->descriptionIcon('heroicon-m-queue-list')
                ->color('info'),

            Stat::make('Avg Price', '$' . number_format(Track::avg('unit_price'), 2))
                ->description('Average track price')
                ->descriptionIcon('heroicon-m-banknotes')
                ->color('warning'),
        ];
    }
}
````
</augment_code_snippet>

## Testing Examples

### Resource Tests

<augment_code_snippet path="tests/Feature/Filament/TrackResourceTest.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace Tests\Feature\Filament;

use App\Filament\ChinookAdmin\Resources\TrackResource;
use App\Models\Chinook\Track;
use App\Models\Chinook\Album;
use App\Models\Chinook\Artist;
use App\Models\Chinook\MediaType;
use App\Models\User;
use Aliziodev\LaravelTaxonomy\Models\Taxonomy;
use Aliziodev\LaravelTaxonomy\Models\TaxonomyTerm;
use Filament\Testing\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;

class TrackResourceTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Artist $artist;
    protected Album $album;
    protected MediaType $mediaType;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create();
        $this->artist = Artist::factory()->create();
        $this->album = Album::factory()->for($this->artist)->create();
        $this->mediaType = MediaType::factory()->create();
        $this->actingAs($this->user);
    }

    public function test_can_render_track_index_page(): void
    {
        Track::factory()->count(5)->for($this->album)->for($this->mediaType)->create();

        Livewire::test(TrackResource\Pages\ListTracks::class)
            ->assertSuccessful()
            ->assertCanSeeTableRecords(Track::all());
    }

    public function test_can_create_track_with_album_and_media_type(): void
    {
        Livewire::test(TrackResource\Pages\CreateTrack::class)
            ->fillForm([
                'name' => 'Test Track',
                'album_id' => $this->album->id,
                'media_type_id' => $this->mediaType->id,
                'track_number' => 1,
                'milliseconds' => 180000,
                'unit_price' => 0.99,
                'composer' => 'Test Composer',
            ])
            ->call('create')
            ->assertHasNoFormErrors();

        $track = Track::where('name', 'Test Track')->first();
        $this->assertNotNull($track);
        $this->assertEquals($this->album->id, $track->album_id);
        $this->assertEquals($this->mediaType->id, $track->media_type_id);
    }

    public function test_can_edit_track(): void
    {
        $track = Track::factory()->for($this->album)->for($this->mediaType)->create(['name' => 'Original Name']);

        Livewire::test(TrackResource\Pages\EditTrack::class, ['record' => $track->getRouteKey()])
            ->fillForm([
                'name' => 'Updated Name',
                'composer' => 'Updated Composer',
                'unit_price' => 1.29,
            ])
            ->call('save')
            ->assertHasNoFormErrors();

        $this->assertEquals('Updated Name', $track->fresh()->name);
        $this->assertEquals('Updated Composer', $track->fresh()->composer);
        $this->assertEquals(1.29, $track->fresh()->unit_price);
    }

    public function test_can_filter_tracks_by_album(): void
    {
        $otherAlbum = Album::factory()->for($this->artist)->create();
        Track::factory()->for($this->album)->for($this->mediaType)->create(['name' => 'Album 1 Track']);
        Track::factory()->for($otherAlbum)->for($this->mediaType)->create(['name' => 'Album 2 Track']);

        Livewire::test(TrackResource\Pages\ListTracks::class)
            ->filterTable('album', $this->album->id)
            ->assertCanSeeTableRecords(Track::where('album_id', $this->album->id)->get())
            ->assertCanNotSeeTableRecords(Track::where('album_id', $otherAlbum->id)->get());
    }

    public function test_can_filter_tracks_by_media_type(): void
    {
        $otherMediaType = MediaType::factory()->create();
        Track::factory()->for($this->album)->for($this->mediaType)->create(['name' => 'MP3 Track']);
        Track::factory()->for($this->album)->for($otherMediaType)->create(['name' => 'FLAC Track']);

        Livewire::test(TrackResource\Pages\ListTracks::class)
            ->filterTable('mediaType', $this->mediaType->id)
            ->assertCanSeeTableRecords(Track::where('media_type_id', $this->mediaType->id)->get())
            ->assertCanNotSeeTableRecords(Track::where('media_type_id', $otherMediaType->id)->get());
    }

    public function test_can_search_tracks(): void
    {
        Track::factory()->for($this->album)->for($this->mediaType)->create(['name' => 'Yesterday']);
        Track::factory()->for($this->album)->for($this->mediaType)->create(['name' => 'Hey Jude']);

        Livewire::test(TrackResource\Pages\ListTracks::class)
            ->searchTable('Yesterday')
            ->assertCanSeeTableRecords(Track::where('name', 'like', '%Yesterday%')->get())
            ->assertCanNotSeeTableRecords(Track::where('name', 'like', '%Hey Jude%')->get());
    }

    public function test_can_bulk_update_price(): void
    {
        $tracks = Track::factory()->count(3)->for($this->album)->for($this->mediaType)->create(['unit_price' => 0.99]);

        Livewire::test(TrackResource\Pages\ListTracks::class)
            ->selectTableRecords($tracks)
            ->callTableBulkAction('update_price', data: ['unit_price' => 1.29]);

        $tracks->each(function ($track) {
            $this->assertEquals(1.29, $track->fresh()->unit_price);
        });
    }

    public function test_can_assign_taxonomy_to_tracks(): void
    {
        $taxonomy = Taxonomy::factory()->create(['name' => 'music_genre']);
        $genre = TaxonomyTerm::factory()->create([
            'taxonomy_id' => $taxonomy->id,
            'name' => 'Rock',
        ]);
        $tracks = Track::factory()->count(2)->for($this->album)->for($this->mediaType)->create();

        Livewire::test(TrackResource\Pages\ListTracks::class)
            ->selectTableRecords($tracks)
            ->callTableBulkAction('assign_taxonomy', data: ['taxonomy_term_id' => $genre->id]);

        $tracks->each(function ($track) use ($genre) {
            $this->assertTrue($track->fresh()->taxonomies->contains($genre));
        });
    }
}
````
</augment_code_snippet>

## Performance Optimization

### Query Optimization

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/TrackResource.php" mode="EXCERPT">
````php
// Optimized Eloquent query with eager loading
public static function getEloquentQuery(): Builder
{
    return parent::getEloquentQuery()
        ->with([
            'album:id,title,artist_id',
            'album.artist:id,name',
            'mediaType:id,name',
            'taxonomies:id,name,slug',
        ])
        ->withCount([
            'playlists',
            'invoiceLines',
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
        ->poll('120s'); // Auto-refresh every 2 minutes
}
````
</augment_code_snippet>

### Caching Strategies

<augment_code_snippet path="app/Models/Chinook/Track.php" mode="EXCERPT">
````php
// Cache expensive computations
public function getPlaylistsCountAttribute(): int
{
    return cache()->remember(
        "track.{$this->id}.playlists_count",
        now()->addHours(1),
        fn () => $this->playlists()->count()
    );
}

public function getSalesDataAttribute(): array
{
    return cache()->remember(
        "track.{$this->id}.sales_data",
        now()->addHours(6),
        fn () => [
            'total_sales' => $this->invoiceLines()->sum('unit_price'),
            'total_quantity' => $this->invoiceLines()->sum('quantity'),
            'unique_customers' => $this->invoiceLines()
                ->join('invoices', 'invoice_lines.invoice_id', '=', 'invoices.id')
                ->distinct('invoices.customer_id')
                ->count(),
        ]
    );
}

// Clear cache when model is updated
protected static function booted()
{
    static::updated(function ($track) {
        cache()->forget("track.{$track->id}.playlists_count");
        cache()->forget("track.{$track->id}.sales_data");
    });

    static::deleted(function ($track) {
        cache()->forget("track.{$track->id}.playlists_count");
        cache()->forget("track.{$track->id}.sales_data");
    });
}
````
</augment_code_snippet>

### Database Indexing

<augment_code_snippet path="database/migrations/create_chinook_tracks_table.php" mode="EXCERPT">
````php
// Optimized indexes for Filament queries
Schema::create('chinook_tracks', function (Blueprint $table) {
    $table->id();
    $table->string('name')->index(); // For searching and sorting
    $table->foreignId('album_id')->constrained('chinook_albums')->index(); // For filtering
    $table->foreignId('media_type_id')->constrained('chinook_media_types')->index(); // For filtering
    $table->integer('track_number')->index(); // For sorting
    $table->decimal('unit_price', 10, 2)->index(); // For filtering and sorting
    $table->string('public_id')->unique();
    $table->string('slug')->unique();

    // Composite indexes for common queries
    $table->index(['album_id', 'track_number']);
    $table->index(['media_type_id', 'unit_price']);
    $table->index(['name', 'album_id']);
    $table->index(['unit_price', 'milliseconds']);

    // Full-text search index
    $table->fullText(['name', 'composer', 'lyrics']);

    $table->timestamps();
    $table->softDeletes();
});
````
</augment_code_snippet>

---

## Navigation

**← Previous:** [Albums Resource](020-albums-resource.md) | **Next →** [Customers Resource](040-customers-resource.md)

---

## Related Documentation

- [Chinook Models Guide](../../020-database/030-models-guide.md)
- [Album Resource Guide](020-albums-resource.md)
- [Artist Resource Guide](010-artists-resource.md)
- [Playlist Resource Guide](050-playlists-resource.md)
- [Media Library Integration](../020-models/080-media-library-integration.md)
- [Taxonomy Integration Guide](../020-models/090-taxonomy-integration.md)
- [Testing Implementation Examples](../../065-testing/050-testing-implementation-examples.md)
- [Performance Optimization Guide](../../070-performance/000-index.md)

---

**Documentation Standards**: This document follows WCAG 2.1 AA accessibility guidelines and uses Laravel 12 modern syntax patterns.

**Last Updated:** 2025-07-18
**Maintainer:** Technical Documentation Team
**Source:** [GitHub Repository](https://github.com/s-a-c/chinook)

[⬆️ Back to Top](#tracks-resource---complete-implementation-guide)
