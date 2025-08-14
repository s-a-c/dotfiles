# Artists Resource - Complete Implementation Guide

> **Created:** 2025-07-16
> **Updated:** 2025-07-18
> **Focus:** Complete Artist management with working code examples, relationship managers, and taxonomy integration
> **Source:** [Chinook Artist Model](https://github.com/s-a-c/chinook/blob/main/app/Models/Chinook/Artist.php)

## Table of Contents

- [Overview](#overview)
- [Resource Implementation](#resource-implementation)
  - [Basic Resource Structure](#basic-resource-structure)
  - [Form Schema](#form-schema)
  - [Table Configuration](#table-configuration)
- [Relationship Management](#relationship-management)
  - [Albums Relationship Manager](#albums-relationship-manager)
  - [Tracks Relationship Manager](#tracks-relationship-manager)
- [Taxonomy Integration](#taxonomy-integration)
- [Authorization Policies](#authorization-policies)
- [Advanced Features](#advanced-features)
- [Testing Examples](#testing-examples)
- [Performance Optimization](#performance-optimization)

## Overview

The Artists Resource provides comprehensive management of music artists within the Chinook admin panel. It features complete CRUD operations, albums relationship management, taxonomy integration for genre classification, and enhanced metadata handling with full Laravel 12 compatibility.

### Key Features

- **Complete CRUD Operations**: Create, read, update, delete artists with comprehensive validation
- **Albums Management**: Inline albums relationship manager with track counts and media integration
- **Taxonomy Integration**: Genre, style, and era classification using aliziodev/laravel-taxonomy
- **Enhanced Metadata**: Biography, website, social links, country information, and formation year
- **Search & Filtering**: Full-text search with taxonomy-based filtering and country filters
- **Bulk Operations**: Mass operations with permission checking and activity logging
- **Media Integration**: Artist avatar and gallery management with Spatie Media Library
- **Authorization**: Role-based access control with granular permissions

### Model Integration

<augment_code_snippet path="app/Models/Chinook/Artist.php" mode="EXCERPT">
````php
class Artist extends BaseModel
{
    use HasTaxonomy; // From BaseModel - enables taxonomy relationships

    protected $table = 'chinook_artists';

    protected $fillable = [
        'name', 'public_id', 'slug', 'bio', 'website',
        'social_links', 'country', 'formed_year', 'is_active',
    ];

    // Relationships
    public function albums(): HasMany
    public function tracks() // Through albums

    // Casts
    protected function casts(): array {
        'social_links' => 'array',
        'formed_year' => 'integer',
        'is_active' => 'boolean',
    }
````
</augment_code_snippet>

## Resource Implementation

### Basic Resource Structure

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/ArtistResource.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Filament\ChinookAdmin\Resources;

use App\Models\Chinook\Artist;
use App\Filament\ChinookAdmin\Resources\ArtistResource\Pages;
use App\Filament\ChinookAdmin\Resources\ArtistResource\RelationManagers;
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

class ArtistResource extends Resource
{
    protected static ?string $model = Artist::class;

    protected static ?string $navigationIcon = 'heroicon-o-microphone';

    protected static ?string $navigationGroup = 'Music Management';

    protected static ?int $navigationSort = 1;

    protected static ?string $recordTitleAttribute = 'name';

    protected static ?string $navigationBadgeTooltip = 'Total active artists';

    protected static int $globalSearchResultsLimit = 20;

    public static function getNavigationBadge(): ?string
    {
        return static::getModel()::where('is_active', true)->count();
    }

    public static function getGlobalSearchResultTitle(Model $record): string
    {
        return $record->name;
    }

    public static function getGlobalSearchResultDetails(Model $record): array
    {
        return [
            'Country' => $record->country,
            'Albums' => $record->albums_count ?? $record->albums()->count(),
        ];
    }
````
</augment_code_snippet>

### Form Schema

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/ArtistResource.php" mode="EXCERPT">
````php
public static function form(Form $form): Form
{
    return $form
        ->schema([
            Forms\Components\Section::make('Basic Information')
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
                        ->helperText('The artist or band name'),

                    Forms\Components\TextInput::make('slug')
                        ->required()
                        ->maxLength(255)
                        ->unique(ignoreRecord: true)
                        ->rules(['alpha_dash'])
                        ->helperText('URL-friendly version of the name'),

                    Forms\Components\Select::make('country')
                        ->searchable()
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
                            'BR' => 'Brazil',
                            'MX' => 'Mexico',
                            'AR' => 'Argentina',
                            'SE' => 'Sweden',
                            'NO' => 'Norway',
                            'DK' => 'Denmark',
                            'FI' => 'Finland',
                            'NL' => 'Netherlands',
                            'BE' => 'Belgium',
                            'CH' => 'Switzerland',
                            'AT' => 'Austria',
                        ])
                        ->placeholder('Select country'),

                    Forms\Components\TextInput::make('formed_year')
                        ->numeric()
                        ->minValue(1900)
                        ->maxValue(date('Y'))
                        ->placeholder('e.g., 1965')
                        ->helperText('Year the artist/band was formed'),

                    Forms\Components\Toggle::make('is_active')
                        ->default(true)
                        ->helperText('Whether this artist is currently active'),
                ])
                ->columns(2),

            Forms\Components\Section::make('Biography & Links')
                ->schema([
                    Forms\Components\Textarea::make('bio')
                        ->label('Biography')
                        ->rows(4)
                        ->maxLength(2000)
                        ->placeholder('Artist biography and background information...'),

                    Forms\Components\TextInput::make('website')
                        ->url()
                        ->placeholder('https://example.com')
                        ->helperText('Official website URL'),

                    Forms\Components\Repeater::make('social_links')
                        ->label('Social Media Links')
                        ->schema([
                            Forms\Components\Select::make('platform')
                                ->options([
                                    'twitter' => 'Twitter',
                                    'instagram' => 'Instagram',
                                    'facebook' => 'Facebook',
                                    'youtube' => 'YouTube',
                                    'spotify' => 'Spotify',
                                    'apple_music' => 'Apple Music',
                                    'bandcamp' => 'Bandcamp',
                                    'soundcloud' => 'SoundCloud',
                                ])
                                ->required(),
                            Forms\Components\TextInput::make('url')
                                ->url()
                                ->required()
                                ->placeholder('https://...'),
                        ])
                        ->columns(2)
                        ->collapsible()
                        ->defaultItems(0)
                        ->addActionLabel('Add Social Link'),
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
                        ->helperText('Select or create genres, styles, and eras for this artist'),
                ])
                ->collapsible(),
        ]);
}
````
</augment_code_snippet>

### Table Configuration

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/ArtistResource.php" mode="EXCERPT">
````php
public static function table(Table $table): Table
{
    return $table
        ->columns([
            Tables\Columns\ImageColumn::make('avatar')
                ->label('Avatar')
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

            Tables\Columns\TextColumn::make('taxonomies.name')
                ->label('Genres')
                ->badge()
                ->color('info')
                ->limit(3)
                ->limitedRemainingText()
                ->searchable(),

            Tables\Columns\TextColumn::make('albums_count')
                ->counts('albums')
                ->badge()
                ->color('success')
                ->label('Albums'),

            Tables\Columns\TextColumn::make('tracks_count')
                ->counts('tracks')
                ->badge()
                ->color('primary')
                ->label('Tracks'),

            Tables\Columns\TextColumn::make('formed_year')
                ->sortable()
                ->toggleable()
                ->placeholder('Unknown'),

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

            Tables\Columns\TextColumn::make('updated_at')
                ->dateTime()
                ->sortable()
                ->toggleable(isToggledHiddenByDefault: true),
        ])
        ->filters([
            Tables\Filters\SelectFilter::make('country')
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
                ->multiple(),

            Tables\Filters\Filter::make('is_active')
                ->label('Active Only')
                ->query(fn (Builder $query): Builder => $query->where('is_active', true))
                ->default(),

            Tables\Filters\Filter::make('has_albums')
                ->label('Has Albums')
                ->query(fn (Builder $query): Builder => $query->has('albums')),

            Tables\Filters\SelectFilter::make('taxonomies')
                ->relationship('taxonomies', 'name')
                ->multiple()
                ->preload(),

            Tables\Filters\Filter::make('formed_year')
                ->form([
                    Forms\Components\DatePicker::make('formed_from')
                        ->label('Formed From'),
                    Forms\Components\DatePicker::make('formed_until')
                        ->label('Formed Until'),
                ])
                ->query(function (Builder $query, array $data): Builder {
                    return $query
                        ->when(
                            $data['formed_from'],
                            fn (Builder $query, $date): Builder => $query->whereDate('formed_year', '>=', $date),
                        )
                        ->when(
                            $data['formed_until'],
                            fn (Builder $query, $date): Builder => $query->whereDate('formed_year', '<=', $date),
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
        ])
        ->bulkActions([
            Tables\Actions\BulkActionGroup::make([
                Tables\Actions\DeleteBulkAction::make(),
                Tables\Actions\RestoreBulkAction::make(),
                Tables\Actions\ForceDeleteBulkAction::make(),

                Tables\Actions\BulkAction::make('activate')
                    ->label('Activate Selected')
                    ->icon('heroicon-o-check-circle')
                    ->color('success')
                    ->action(function (Collection $records) {
                        $records->each->update(['is_active' => true]);
                    })
                    ->deselectRecordsAfterCompletion()
                    ->requiresConfirmation(),

                Tables\Actions\BulkAction::make('deactivate')
                    ->label('Deactivate Selected')
                    ->icon('heroicon-o-x-circle')
                    ->color('danger')
                    ->action(function (Collection $records) {
                        $records->each->update(['is_active' => false]);
                    })
                    ->deselectRecordsAfterCompletion()
                    ->requiresConfirmation(),

                Tables\Actions\BulkAction::make('export')
                    ->label('Export Selected')
                    ->icon('heroicon-o-arrow-down-tray')
                    ->action(function (Collection $records) {
                        // Export logic here
                        return response()->streamDownload(function () use ($records) {
                            echo $records->toCsv();
                        }, 'artists.csv');
                    }),
            ]),
        ])
        ->defaultSort('name')
        ->persistSortInSession()
        ->persistSearchInSession()
        ->persistFiltersInSession();
}
````
</augment_code_snippet>

## Relationship Management

### Albums Relationship Manager

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/ArtistResource/RelationManagers/AlbumsRelationManager.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Filament\ChinookAdmin\Resources\ArtistResource\RelationManagers;

use App\Models\Chinook\Album;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Str;

class AlbumsRelationManager extends RelationManager
{
    protected static string $relationship = 'albums';

    protected static ?string $recordTitleAttribute = 'title';

    protected static ?string $navigationIcon = 'heroicon-o-musical-note';

    public function form(Form $form): Form
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
                            }),

                        Forms\Components\TextInput::make('slug')
                            ->required()
                            ->maxLength(255)
                            ->unique(Album::class, 'slug', ignoreRecord: true)
                            ->rules(['alpha_dash']),

                        Forms\Components\DatePicker::make('release_date')
                            ->native(false)
                            ->displayFormat('M d, Y'),

                        Forms\Components\TextInput::make('label')
                            ->label('Record Label')
                            ->maxLength(255)
                            ->placeholder('e.g., Atlantic Records'),

                        Forms\Components\TextInput::make('catalog_number')
                            ->maxLength(100)
                            ->placeholder('e.g., ATL-123456'),

                        Forms\Components\Toggle::make('is_compilation')
                            ->label('Compilation Album')
                            ->helperText('Check if this is a compilation or greatest hits album'),
                    ])
                    ->columns(2),

                Forms\Components\Section::make('Additional Information')
                    ->schema([
                        Forms\Components\Textarea::make('description')
                            ->maxLength(1000)
                            ->rows(3)
                            ->placeholder('Album description, background, or notes...'),

                        Forms\Components\TextInput::make('total_tracks')
                            ->numeric()
                            ->minValue(1)
                            ->maxValue(999)
                            ->placeholder('Number of tracks'),

                        Forms\Components\TextInput::make('duration_seconds')
                            ->numeric()
                            ->minValue(1)
                            ->placeholder('Total duration in seconds')
                            ->helperText('Will be calculated automatically from tracks'),
                    ])
                    ->collapsible(),
            ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('title')
            ->columns([
                Tables\Columns\ImageColumn::make('cover_art')
                    ->label('Cover')
                    ->circular()
                    ->defaultImageUrl('/images/default-album.png')
                    ->size(40),

                Tables\Columns\TextColumn::make('title')
                    ->searchable()
                    ->sortable()
                    ->weight('bold')
                    ->description(fn (Album $record): string =>
                        $record->label ? "Label: {$record->label}" : ''
                    ),

                Tables\Columns\TextColumn::make('release_date')
                    ->date('M d, Y')
                    ->sortable()
                    ->placeholder('Unknown'),

                Tables\Columns\TextColumn::make('tracks_count')
                    ->counts('tracks')
                    ->badge()
                    ->color('success')
                    ->label('Tracks'),

                Tables\Columns\TextColumn::make('duration_seconds')
                    ->label('Duration')
                    ->formatStateUsing(fn ($state) => $state ? gmdate('H:i:s', $state) : 'Unknown')
                    ->sortable(),

                Tables\Columns\IconColumn::make('is_compilation')
                    ->boolean()
                    ->trueIcon('heroicon-o-collection')
                    ->falseIcon('heroicon-o-musical-note')
                    ->label('Type'),

                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\Filter::make('has_tracks')
                    ->query(fn (Builder $query): Builder => $query->has('tracks')),

                Tables\Filters\Filter::make('is_compilation')
                    ->query(fn (Builder $query): Builder => $query->where('is_compilation', true)),

                Tables\Filters\Filter::make('release_year')
                    ->form([
                        Forms\Components\Select::make('year')
                            ->options(function () {
                                $currentYear = date('Y');
                                $years = [];
                                for ($year = $currentYear; $year >= 1950; $year--) {
                                    $years[$year] = $year;
                                }
                                return $years;
                            })
                            ->placeholder('Select year'),
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return $query->when(
                            $data['year'],
                            fn (Builder $query, $year): Builder => $query->whereYear('release_date', $year)
                        );
                    }),
            ])
            ->headerActions([
                Tables\Actions\CreateAction::make()
                    ->mutateFormDataUsing(function (array $data): array {
                        $data['artist_id'] = $this->ownerRecord->id;
                        return $data;
                    }),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ])
            ->defaultSort('release_date', 'desc');
    }
}
````
</augment_code_snippet>

### Tracks Relationship Manager

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/ArtistResource/RelationManagers/TracksRelationManager.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Filament\ChinookAdmin\Resources\ArtistResource\RelationManagers;

use App\Models\Chinook\Track;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class TracksRelationManager extends RelationManager
{
    protected static string $relationship = 'tracks';

    protected static ?string $recordTitleAttribute = 'name';

    protected static ?string $navigationIcon = 'heroicon-o-play';

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('name')
            ->columns([
                Tables\Columns\TextColumn::make('name')
                    ->searchable()
                    ->sortable()
                    ->weight('bold'),

                Tables\Columns\TextColumn::make('album.title')
                    ->label('Album')
                    ->searchable()
                    ->sortable()
                    ->url(fn (Track $record): string =>
                        route('filament.chinook-admin.resources.albums.view', $record->album)
                    ),

                Tables\Columns\TextColumn::make('track_number')
                    ->label('#')
                    ->sortable(),

                Tables\Columns\TextColumn::make('milliseconds')
                    ->label('Duration')
                    ->formatStateUsing(fn ($state) => $state ? gmdate('i:s', $state / 1000) : 'Unknown')
                    ->sortable(),

                Tables\Columns\TextColumn::make('unit_price')
                    ->money('USD')
                    ->sortable(),

                Tables\Columns\TextColumn::make('mediaType.name')
                    ->label('Format')
                    ->badge(),

                Tables\Columns\IconColumn::make('explicit_content')
                    ->boolean()
                    ->label('Explicit'),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('album')
                    ->relationship('album', 'title')
                    ->searchable()
                    ->preload(),

                Tables\Filters\SelectFilter::make('mediaType')
                    ->relationship('mediaType', 'name'),

                Tables\Filters\Filter::make('explicit_content')
                    ->query(fn (Builder $query): Builder => $query->where('explicit_content', true)),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
            ])
            ->defaultSort('album.release_date', 'desc')
            ->defaultSort('track_number', 'asc');
    }
}
````
</augment_code_snippet>

## Taxonomy Integration

### Taxonomy Form Component

The taxonomy integration is already included in the form schema above. Here's how to work with taxonomies in the Artist resource:

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/ArtistResource.php" mode="EXCERPT">
````php
// Taxonomy filtering in table
Tables\Filters\SelectFilter::make('taxonomies')
    ->relationship('taxonomies', 'name')
    ->multiple()
    ->preload()
    ->label('Filter by Genres/Styles'),

// Taxonomy display in table
Tables\Columns\TextColumn::make('taxonomies.name')
    ->label('Genres')
    ->badge()
    ->color('info')
    ->limit(3)
    ->limitedRemainingText()
    ->searchable(),

// Taxonomy management in forms (already shown in form schema)
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
    ->helperText('Select or create genres, styles, and eras for this artist'),
````
</augment_code_snippet>

### Taxonomy Scopes and Queries

<augment_code_snippet path="app/Models/Chinook/Artist.php" mode="EXCERPT">
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

// Usage in resource
public static function getEloquentQuery(): Builder
{
    return parent::getEloquentQuery()
        ->with(['taxonomies', 'albums'])
        ->withCount(['albums', 'tracks']);
}
````
</augment_code_snippet>

## Authorization Policies

<augment_code_snippet path="app/Policies/Chinook/ArtistPolicy.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace App\Policies\Chinook;

use App\Models\Chinook\Artist;
use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

class ArtistPolicy
{
    use HandlesAuthorization;

    /**
     * Determine whether the user can view any models.
     */
    public function viewAny(User $user): bool
    {
        return $user->can('view_any_chinook::artist');
    }

    /**
     * Determine whether the user can view the model.
     */
    public function view(User $user, Artist $artist): bool
    {
        return $user->can('view_chinook::artist');
    }

    /**
     * Determine whether the user can create models.
     */
    public function create(User $user): bool
    {
        return $user->can('create_chinook::artist');
    }

    /**
     * Determine whether the user can update the model.
     */
    public function update(User $user, Artist $artist): bool
    {
        return $user->can('update_chinook::artist');
    }

    /**
     * Determine whether the user can delete the model.
     */
    public function delete(User $user, Artist $artist): bool
    {
        return $user->can('delete_chinook::artist');
    }

    /**
     * Determine whether the user can bulk delete.
     */
    public function deleteAny(User $user): bool
    {
        return $user->can('delete_any_chinook::artist');
    }

    /**
     * Determine whether the user can permanently delete.
     */
    public function forceDelete(User $user, Artist $artist): bool
    {
        return $user->can('force_delete_chinook::artist');
    }

    /**
     * Determine whether the user can permanently bulk delete.
     */
    public function forceDeleteAny(User $user): bool
    {
        return $user->can('force_delete_any_chinook::artist');
    }

    /**
     * Determine whether the user can restore.
     */
    public function restore(User $user, Artist $artist): bool
    {
        return $user->can('restore_chinook::artist');
    }

    /**
     * Determine whether the user can bulk restore.
     */
    public function restoreAny(User $user): bool
    {
        return $user->can('restore_any_chinook::artist');
    }

    /**
     * Determine whether the user can replicate.
     */
    public function replicate(User $user, Artist $artist): bool
    {
        return $user->can('replicate_chinook::artist');
    }

    /**
     * Determine whether the user can reorder.
     */
    public function reorder(User $user): bool
    {
        return $user->can('reorder_chinook::artist');
    }
}
````
</augment_code_snippet>

### Resource Pages Configuration

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/ArtistResource.php" mode="EXCERPT">
````php
public static function getRelations(): array
{
    return [
        RelationManagers\AlbumsRelationManager::class,
        RelationManagers\TracksRelationManager::class,
    ];
}

public static function getPages(): array
{
    return [
        'index' => Pages\ListArtists::route('/'),
        'create' => Pages\CreateArtist::route('/create'),
        'view' => Pages\ViewArtist::route('/{record}'),
        'edit' => Pages\EditArtist::route('/{record}/edit'),
    ];
}

// Enable soft deletes
public static function getEloquentQuery(): Builder
{
    return parent::getEloquentQuery()
        ->withoutGlobalScopes([
            SoftDeletingScope::class,
        ]);
}
````
</augment_code_snippet>

## Advanced Features

### Bulk Actions

The bulk actions are already included in the table configuration above. Here are additional advanced features:

### Custom Actions

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/ArtistResource.php" mode="EXCERPT">
````php
// Custom header actions
->headerActions([
    Tables\Actions\Action::make('import')
        ->label('Import Artists')
        ->icon('heroicon-o-arrow-up-tray')
        ->form([
            Forms\Components\FileUpload::make('file')
                ->acceptedFileTypes(['text/csv', 'application/csv'])
                ->required(),
        ])
        ->action(function (array $data) {
            // Import logic here
            $this->importArtists($data['file']);
        }),

    Tables\Actions\Action::make('export')
        ->label('Export All')
        ->icon('heroicon-o-arrow-down-tray')
        ->action(function () {
            return response()->streamDownload(function () {
                echo Artist::with(['taxonomies', 'albums'])->get()->toCsv();
            }, 'artists-export.csv');
        }),
])

// Custom table actions
->actions([
    Tables\Actions\Action::make('duplicate')
        ->label('Duplicate')
        ->icon('heroicon-o-document-duplicate')
        ->action(function (Artist $record) {
            $newArtist = $record->replicate();
            $newArtist->name = $record->name . ' (Copy)';
            $newArtist->slug = null; // Will be auto-generated
            $newArtist->public_id = null; // Will be auto-generated
            $newArtist->save();

            // Copy taxonomies
            $newArtist->taxonomies()->sync($record->taxonomies->pluck('id'));

            return redirect()->route('filament.chinook-admin.resources.artists.edit', $newArtist);
        })
        ->requiresConfirmation(),

    Tables\Actions\Action::make('view_albums')
        ->label('View Albums')
        ->icon('heroicon-o-musical-note')
        ->url(fn (Artist $record): string =>
            route('filament.chinook-admin.resources.albums.index', ['tableFilters[artist][value]' => $record->id])
        )
        ->openUrlInNewTab(),
])
````
</augment_code_snippet>

### Widgets Integration

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/ArtistResource/Widgets/ArtistStatsWidget.php" mode="EXCERPT">
````php
<?php

namespace App\Filament\ChinookAdmin\Resources\ArtistResource\Widgets;

use App\Models\Chinook\Artist;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class ArtistStatsWidget extends BaseWidget
{
    protected function getStats(): array
    {
        return [
            Stat::make('Total Artists', Artist::count())
                ->description('All artists in database')
                ->descriptionIcon('heroicon-m-arrow-trending-up')
                ->color('success'),

            Stat::make('Active Artists', Artist::where('is_active', true)->count())
                ->description('Currently active artists')
                ->descriptionIcon('heroicon-m-check-circle')
                ->color('primary'),

            Stat::make('With Albums', Artist::has('albums')->count())
                ->description('Artists with at least one album')
                ->descriptionIcon('heroicon-m-musical-note')
                ->color('info'),

            Stat::make('This Month', Artist::whereMonth('created_at', now()->month)->count())
                ->description('New artists added this month')
                ->descriptionIcon('heroicon-m-calendar')
                ->color('warning'),
        ];
    }
}
````
</augment_code_snippet>

## Testing Examples

### Resource Tests

<augment_code_snippet path="tests/Feature/Filament/ArtistResourceTest.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace Tests\Feature\Filament;

use App\Filament\ChinookAdmin\Resources\ArtistResource;
use App\Models\Chinook\Artist;
use App\Models\User;
use Aliziodev\LaravelTaxonomy\Models\Taxonomy;
use Aliziodev\LaravelTaxonomy\Models\TaxonomyTerm;
use Filament\Testing\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;

class ArtistResourceTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create();
        $this->actingAs($this->user);
    }

    public function test_can_render_artist_index_page(): void
    {
        Artist::factory()->count(5)->create();

        Livewire::test(ArtistResource\Pages\ListArtists::class)
            ->assertSuccessful()
            ->assertCanSeeTableRecords(Artist::all());
    }

    public function test_can_create_artist_with_taxonomies(): void
    {
        $taxonomy = Taxonomy::factory()->create(['name' => 'music_genre']);
        $genre = TaxonomyTerm::factory()->create([
            'taxonomy_id' => $taxonomy->id,
            'name' => 'Rock',
        ]);

        Livewire::test(ArtistResource\Pages\CreateArtist::class)
            ->fillForm([
                'name' => 'Test Artist',
                'country' => 'US',
                'formed_year' => 1990,
                'is_active' => true,
                'bio' => 'Test biography',
                'taxonomies' => [$genre->id],
            ])
            ->call('create')
            ->assertHasNoFormErrors();

        $artist = Artist::where('name', 'Test Artist')->first();
        $this->assertNotNull($artist);
        $this->assertTrue($artist->taxonomies->contains($genre));
    }

    public function test_can_edit_artist(): void
    {
        $artist = Artist::factory()->create(['name' => 'Original Name']);

        Livewire::test(ArtistResource\Pages\EditArtist::class, ['record' => $artist->getRouteKey()])
            ->fillForm([
                'name' => 'Updated Name',
                'country' => 'UK',
            ])
            ->call('save')
            ->assertHasNoFormErrors();

        $this->assertEquals('Updated Name', $artist->fresh()->name);
        $this->assertEquals('UK', $artist->fresh()->country);
    }

    public function test_can_delete_artist(): void
    {
        $artist = Artist::factory()->create();

        Livewire::test(ArtistResource\Pages\ListArtists::class)
            ->callTableAction('delete', $artist);

        $this->assertSoftDeleted($artist);
    }

    public function test_can_filter_artists_by_country(): void
    {
        Artist::factory()->create(['country' => 'US', 'name' => 'US Artist']);
        Artist::factory()->create(['country' => 'UK', 'name' => 'UK Artist']);

        Livewire::test(ArtistResource\Pages\ListArtists::class)
            ->filterTable('country', 'US')
            ->assertCanSeeTableRecords(Artist::where('country', 'US')->get())
            ->assertCanNotSeeTableRecords(Artist::where('country', 'UK')->get());
    }

    public function test_can_search_artists(): void
    {
        Artist::factory()->create(['name' => 'The Beatles']);
        Artist::factory()->create(['name' => 'Led Zeppelin']);

        Livewire::test(ArtistResource\Pages\ListArtists::class)
            ->searchTable('Beatles')
            ->assertCanSeeTableRecords(Artist::where('name', 'like', '%Beatles%')->get())
            ->assertCanNotSeeTableRecords(Artist::where('name', 'like', '%Zeppelin%')->get());
    }

    public function test_can_bulk_activate_artists(): void
    {
        $artists = Artist::factory()->count(3)->create(['is_active' => false]);

        Livewire::test(ArtistResource\Pages\ListArtists::class)
            ->selectTableRecords($artists)
            ->callTableBulkAction('activate');

        $artists->each(function ($artist) {
            $this->assertTrue($artist->fresh()->is_active);
        });
    }
}
````
</augment_code_snippet>

### Relationship Manager Tests

<augment_code_snippet path="tests/Feature/Filament/ArtistAlbumsRelationManagerTest.php" mode="EXCERPT">
````php
<?php

declare(strict_types=1);

namespace Tests\Feature\Filament;

use App\Filament\ChinookAdmin\Resources\ArtistResource\RelationManagers\AlbumsRelationManager;
use App\Models\Chinook\Album;
use App\Models\Chinook\Artist;
use App\Models\User;
use Filament\Testing\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;

class ArtistAlbumsRelationManagerTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Artist $artist;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create();
        $this->artist = Artist::factory()->create();
        $this->actingAs($this->user);
    }

    public function test_can_list_artist_albums(): void
    {
        $albums = Album::factory()->count(3)->create(['artist_id' => $this->artist->id]);

        Livewire::test(AlbumsRelationManager::class, [
            'ownerRecord' => $this->artist,
            'pageClass' => \App\Filament\ChinookAdmin\Resources\ArtistResource\Pages\EditArtist::class,
        ])
            ->assertSuccessful()
            ->assertCanSeeTableRecords($albums);
    }

    public function test_can_create_album_for_artist(): void
    {
        Livewire::test(AlbumsRelationManager::class, [
            'ownerRecord' => $this->artist,
            'pageClass' => \App\Filament\ChinookAdmin\Resources\ArtistResource\Pages\EditArtist::class,
        ])
            ->callTableAction('create', data: [
                'title' => 'New Album',
                'release_date' => '2023-01-01',
                'label' => 'Test Records',
            ])
            ->assertHasNoTableActionErrors();

        $this->assertDatabaseHas('chinook_albums', [
            'title' => 'New Album',
            'artist_id' => $this->artist->id,
        ]);
    }
}
````
</augment_code_snippet>

## Performance Optimization

### Query Optimization

<augment_code_snippet path="app/Filament/ChinookAdmin/Resources/ArtistResource.php" mode="EXCERPT">
````php
// Optimized Eloquent query with eager loading
public static function getEloquentQuery(): Builder
{
    return parent::getEloquentQuery()
        ->with([
            'taxonomies:id,name,slug',
            'albums:id,artist_id,title,release_date',
        ])
        ->withCount([
            'albums',
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
        ->poll('30s'); // Auto-refresh every 30 seconds
}
````
</augment_code_snippet>

### Caching Strategies

<augment_code_snippet path="app/Models/Chinook/Artist.php" mode="EXCERPT">
````php
// Cache expensive computations
public function getAlbumsCountAttribute(): int
{
    return cache()->remember(
        "artist.{$this->id}.albums_count",
        now()->addHours(1),
        fn () => $this->albums()->count()
    );
}

public function getPopularTracksAttribute()
{
    return cache()->remember(
        "artist.{$this->id}.popular_tracks",
        now()->addHours(6),
        fn () => $this->tracks()
            ->orderByDesc('play_count')
            ->limit(10)
            ->get()
    );
}

// Clear cache when model is updated
protected static function booted()
{
    static::updated(function ($artist) {
        cache()->forget("artist.{$artist->id}.albums_count");
        cache()->forget("artist.{$artist->id}.popular_tracks");
    });
}
````
</augment_code_snippet>

### Database Indexing

<augment_code_snippet path="database/migrations/create_chinook_artists_table.php" mode="EXCERPT">
````php
// Optimized indexes for Filament queries
Schema::create('chinook_artists', function (Blueprint $table) {
    $table->id();
    $table->string('name')->index(); // For searching and sorting
    $table->string('country')->nullable()->index(); // For filtering
    $table->integer('formed_year')->nullable()->index(); // For filtering
    $table->boolean('is_active')->default(true)->index(); // For filtering
    $table->string('public_id')->unique();
    $table->string('slug')->unique();

    // Composite indexes for common queries
    $table->index(['is_active', 'country']);
    $table->index(['is_active', 'formed_year']);
    $table->index(['name', 'is_active']);

    // Full-text search index
    $table->fullText(['name', 'bio']);

    $table->timestamps();
    $table->softDeletes();
});
````
</augment_code_snippet>

---

## Navigation

**← Previous:** [Filament Resources Index](000-index.md) | **Next →** [Albums Resource](020-albums-resource.md)

---

## Related Documentation

- [Chinook Models Guide](../../020-database/030-models-guide.md)
- [Taxonomy Integration Guide](../020-models/090-taxonomy-integration.md)
- [Testing Implementation Examples](../../065-testing/050-testing-implementation-examples.md)
- [Performance Optimization Guide](../../070-performance/000-index.md)

---

**Documentation Standards**: This document follows WCAG 2.1 AA accessibility guidelines and uses Laravel 12 modern syntax patterns.

**Last Updated:** 2025-07-18
**Maintainer:** Technical Documentation Team
**Source:** [GitHub Repository](https://github.com/s-a-c/chinook)

[⬆️ Back to Top](#artists-resource---complete-implementation-guide)
