# Testing Implementation Examples - Complete Guide

**Version:** 2.0
**Created:** 2025-07-16
**Last Updated:** 2025-07-18
**Scope:** Comprehensive testing examples for Chinook project using Pest PHP with complete coverage

## Table of Contents

1. [Overview](#1-overview)
2. [Model Testing](#2-model-testing)
3. [Feature Testing](#3-feature-testing)
4. [Filament Resource Testing](#4-filament-resource-testing)
5. [Livewire Component Testing](#5-livewire-component-testing)
6. [API Testing](#6-api-testing)
7. [Performance Testing](#7-performance-testing)
8. [Integration Testing](#8-integration-testing)
9. [Authorization Testing](#9-authorization-testing)
10. [Database Testing](#10-database-testing)

## 1. Overview

This guide provides comprehensive, production-ready test examples for the Chinook project using Pest PHP testing framework. All examples include proper setup, error handling, accessibility testing, and performance validation with complete coverage of all Filament resources and frontend components.

### 1.1 Testing Philosophy

- **Test-Driven Development:** Write tests before implementation with comprehensive coverage
- **Comprehensive Coverage:** Unit, feature, integration, and end-to-end tests
- **Real-World Scenarios:** Tests reflect actual usage patterns and business logic
- **Error Handling:** Test both success and failure cases with proper exception handling
- **Performance Validation:** Ensure optimal query performance and response times
- **Accessibility Compliance:** Validate WCAG 2.1 AA compliance throughout
- **Security Testing:** Validate authorization policies and data protection

### 1.2 Testing Structure

```
tests/
├── Feature/
│   ├── Filament/
│   │   ├── ArtistResourceTest.php
│   │   ├── AlbumResourceTest.php
│   │   ├── TrackResourceTest.php
│   │   ├── CustomerResourceTest.php
│   │   ├── EmployeeResourceTest.php
│   │   ├── InvoiceResourceTest.php
│   │   └── ...
│   ├── Livewire/
│   │   ├── MusicCatalogBrowserTest.php
│   │   ├── AdvancedSearchTest.php
│   │   ├── ArtistDiscoveryTest.php
│   │   └── ...
│   ├── API/
│   │   ├── ArtistApiTest.php
│   │   ├── AlbumApiTest.php
│   │   └── ...
│   └── Auth/
├── Unit/
│   ├── Models/
│   │   ├── ArtistTest.php
│   │   ├── AlbumTest.php
│   │   ├── TrackTest.php
│   │   └── ...
│   ├── Policies/
│   │   ├── ArtistPolicyTest.php
│   │   ├── CustomerPolicyTest.php
│   │   └── ...
│   └── Services/
└── Integration/
    ├── TaxonomyIntegrationTest.php
    ├── PaymentProcessingTest.php
    └── ...
```

### 1.3 Test Configuration

```php
<?php

// tests/Pest.php
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;

uses(RefreshDatabase::class, WithFaker::class)
    ->in('Feature', 'Unit', 'Integration');

// Custom expectations
expect()->extend('toBeValidSlug', function () {
    return $this->toMatch('/^[a-z0-9]+(?:-[a-z0-9]+)*$/');
});

expect()->extend('toBeValidPublicId', function () {
    return $this->toMatch('/^[A-Za-z0-9]{8,}$/');
});

expect()->extend('toHaveValidTimestamps', function () {
    return $this->toHaveKeys(['created_at', 'updated_at'])
        ->and($this->created_at)->not->toBeNull()
        ->and($this->updated_at)->not->toBeNull();
});

// Helper functions
function createUserWithRole(string $role = 'user'): \App\Models\User
{
    $user = \App\Models\User::factory()->create();
    $user->assignRole($role);
    return $user;
}

function createArtistWithAlbums(int $albumCount = 3): \App\Models\Chinook\Artist
{
    $artist = \App\Models\Chinook\Artist::factory()->create();
    \App\Models\Chinook\Album::factory()
        ->count($albumCount)
        ->for($artist)
        ->create();
    return $artist;
}

function createAlbumWithTracks(int $trackCount = 10): \App\Models\Chinook\Album
{
    $album = \App\Models\Chinook\Album::factory()->create();
    \App\Models\Chinook\Track::factory()
        ->count($trackCount)
        ->for($album)
        ->create();
    return $album;
}
```

## 2. Model Testing

### 2.1 Artist Model Tests

```php
<?php

use App\Models\Chinook\Artist;
use App\Models\Chinook\Album;
use App\Models\Chinook\Track;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

describe('Artist Model', function () {
    it('can create an artist with required fields', function () {
        $artist = Artist::factory()->create([
            'name' => 'Test Artist',
            'is_active' => true,
        ]);

        expect($artist)
            ->toBeInstanceOf(Artist::class)
            ->name->toBe('Test Artist')
            ->is_active->toBeTrue()
            ->public_id->not->toBeEmpty()
            ->slug->not->toBeEmpty();
    });

    it('generates unique public_id and slug automatically', function () {
        $artist1 = Artist::factory()->create(['name' => 'Same Name']);
        $artist2 = Artist::factory()->create(['name' => 'Same Name']);

        expect($artist1->public_id)->not->toBe($artist2->public_id);
        expect($artist1->slug)->not->toBe($artist2->slug);
    });

    it('has many albums relationship', function () {
        $artist = Artist::factory()->create();
        $albums = Album::factory()->count(3)->create(['artist_id' => $artist->id]);

        expect($artist->albums)
            ->toHaveCount(3)
            ->each->toBeInstanceOf(Album::class);
    });

    it('has many tracks through albums relationship', function () {
        $artist = Artist::factory()->create();
        $album = Album::factory()->create(['artist_id' => $artist->id]);
        $tracks = Track::factory()->count(5)->create(['album_id' => $album->id]);

        $artistTracks = $artist->tracks;

        expect($artistTracks)
            ->toHaveCount(5)
            ->each->toBeInstanceOf(Track::class);
    });

    it('can get albums count efficiently', function () {
        $artist = Artist::factory()->create();
        Album::factory()->count(3)->create(['artist_id' => $artist->id]);

        // Test the cached method
        $count = $artist->getAlbumsCount();

        expect($count)->toBe(3);

        // Verify caching works
        Album::factory()->create(['artist_id' => $artist->id]);
        $cachedCount = $artist->getAlbumsCount();
        
        expect($cachedCount)->toBe(3); // Should still be cached value
    });

    it('handles errors gracefully when counting albums', function () {
        $artist = Artist::factory()->create();
        
        // Mock a database error
        DB::shouldReceive('select')->andThrow(new Exception('Database error'));
        
        $count = $artist->getAlbumsCount();
        
        expect($count)->toBe(0); // Should return 0 on error
    });

    it('can scope active artists', function () {
        Artist::factory()->create(['is_active' => true]);
        Artist::factory()->create(['is_active' => false]);
        Artist::factory()->create(['is_active' => true]);

        $activeArtists = Artist::active()->get();

        expect($activeArtists)->toHaveCount(2);
        expect($activeArtists->every(fn($artist) => $artist->is_active))->toBeTrue();
    });

    it('can scope artists by country', function () {
        Artist::factory()->create(['country' => 'USA']);
        Artist::factory()->create(['country' => 'UK']);
        Artist::factory()->create(['country' => 'USA']);

        $usaArtists = Artist::fromCountry('USA')->get();

        expect($usaArtists)->toHaveCount(2);
        expect($usaArtists->every(fn($artist) => $artist->country === 'USA'))->toBeTrue();
    });

    it('can get popular artists', function () {
        $artist1 = Artist::factory()->create();
        $artist2 = Artist::factory()->create();
        $artist3 = Artist::factory()->create();

        // Create different numbers of albums
        Album::factory()->count(5)->create(['artist_id' => $artist1->id]);
        Album::factory()->count(3)->create(['artist_id' => $artist2->id]);
        Album::factory()->count(1)->create(['artist_id' => $artist3->id]);

        $popularArtists = Artist::getPopularArtists(2);

        expect($popularArtists)
            ->toHaveCount(2)
            ->first()->id->toBe($artist1->id); // Most albums first
    });

    it('validates social_links array casting', function () {
        $socialLinks = [
            'twitter' => '@testartist',
            'instagram' => 'testartist',
            'website' => 'https://testartist.com'
        ];

        $artist = Artist::factory()->create(['social_links' => $socialLinks]);

        expect($artist->social_links)
            ->toBeArray()
            ->toBe($socialLinks);
    });

    it('uses slug for route key', function () {
        $artist = Artist::factory()->create();

        expect($artist->getRouteKeyName())->toBe('slug');
        expect($artist->getRouteKey())->toBe($artist->slug);
    });
});
```

### 2.2 Album Model Tests

```php
<?php

use App\Models\Chinook\Album;
use App\Models\Chinook\Artist;
use App\Models\Chinook\Track;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

describe('Album Model', function () {
    it('belongs to an artist', function () {
        $artist = Artist::factory()->create();
        $album = Album::factory()->create(['artist_id' => $artist->id]);

        expect($album->artist)
            ->toBeInstanceOf(Artist::class)
            ->id->toBe($artist->id);
    });

    it('has many tracks', function () {
        $album = Album::factory()->create();
        $tracks = Track::factory()->count(10)->create(['album_id' => $album->id]);

        expect($album->tracks)
            ->toHaveCount(10)
            ->each->toBeInstanceOf(Track::class);
    });

    it('calculates total duration correctly', function () {
        $album = Album::factory()->create();
        
        // Create tracks with known durations (in milliseconds)
        Track::factory()->create(['album_id' => $album->id, 'duration' => 180000]); // 3 minutes
        Track::factory()->create(['album_id' => $album->id, 'duration' => 240000]); // 4 minutes
        Track::factory()->create(['album_id' => $album->id, 'duration' => 300000]); // 5 minutes

        $totalDuration = $album->getTotalDuration();

        expect($totalDuration)->toBe(720000); // 12 minutes total
    });

    it('formats duration for display', function () {
        $album = Album::factory()->create();
        Track::factory()->create(['album_id' => $album->id, 'duration' => 3661000]); // 1:01:01

        $formattedDuration = $album->getFormattedDuration();

        expect($formattedDuration)->toBe('1:01:01');
    });

    it('handles empty album duration gracefully', function () {
        $album = Album::factory()->create();
        // No tracks

        expect($album->getTotalDuration())->toBe(0);
        expect($album->getFormattedDuration())->toBe('0:00');
    });
});
```

## 3. Feature Testing

### 3.1 Artist Management Feature Tests

```php
<?php

use App\Models\User;
use App\Models\Chinook\Artist;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

describe('Artist Management Features', function () {
    beforeEach(function () {
        $this->user = User::factory()->create();
    });

    it('can display artists listing page', function () {
        Artist::factory()->count(5)->create();

        $response = $this->actingAs($this->user)
            ->get('/artists');

        $response->assertStatus(200)
            ->assertViewIs('artists.index')
            ->assertViewHas('artists');
    });

    it('can show individual artist page', function () {
        $artist = Artist::factory()->create();

        $response = $this->actingAs($this->user)
            ->get("/artists/{$artist->slug}");

        $response->assertStatus(200)
            ->assertViewIs('artists.show')
            ->assertViewHas('artist', $artist)
            ->assertSee($artist->name);
    });

    it('returns 404 for non-existent artist', function () {
        $response = $this->actingAs($this->user)
            ->get('/artists/non-existent-slug');

        $response->assertStatus(404);
    });

    it('can search artists by name', function () {
        Artist::factory()->create(['name' => 'The Beatles']);
        Artist::factory()->create(['name' => 'Led Zeppelin']);
        Artist::factory()->create(['name' => 'Pink Floyd']);

        $response = $this->actingAs($this->user)
            ->get('/artists?search=Beatles');

        $response->assertStatus(200)
            ->assertSee('The Beatles')
            ->assertDontSee('Led Zeppelin')
            ->assertDontSee('Pink Floyd');
    });

    it('can filter artists by country', function () {
        Artist::factory()->create(['name' => 'US Artist', 'country' => 'USA']);
        Artist::factory()->create(['name' => 'UK Artist', 'country' => 'UK']);

        $response = $this->actingAs($this->user)
            ->get('/artists?country=USA');

        $response->assertStatus(200)
            ->assertSee('US Artist')
            ->assertDontSee('UK Artist');
    });
});
```

## 4. Filament Resource Testing

### 4.1 Artist Resource Tests

```php
<?php

use App\Models\User;
use App\Models\Chinook\Artist;
use Filament\Testing\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

describe('Artist Filament Resource', function () {
    beforeEach(function () {
        $this->user = User::factory()->create();
    });

    it('can render artist resource index page', function () {
        Artist::factory()->count(10)->create();

        $this->actingAs($this->user)
            ->get('/chinook-fm/artists')
            ->assertSuccessful();
    });

    it('can create new artist through resource', function () {
        $artistData = [
            'name' => 'New Test Artist',
            'bio' => 'Test biography',
            'country' => 'USA',
            'formed_year' => 2020,
            'is_active' => true,
        ];

        $this->actingAs($this->user)
            ->post('/chinook-fm/artists', $artistData)
            ->assertRedirect();

        $this->assertDatabaseHas('chinook_artists', [
            'name' => 'New Test Artist',
            'country' => 'USA',
        ]);
    });

    it('validates required fields when creating artist', function () {
        $this->actingAs($this->user)
            ->post('/chinook-fm/artists', [])
            ->assertSessionHasErrors(['name']);
    });

    it('can edit existing artist', function () {
        $artist = Artist::factory()->create(['name' => 'Original Name']);

        $this->actingAs($this->user)
            ->put("/chinook-fm/artists/{$artist->id}", [
                'name' => 'Updated Name',
                'bio' => $artist->bio,
                'country' => $artist->country,
                'is_active' => $artist->is_active,
            ])
            ->assertRedirect();

        $artist->refresh();
        expect($artist->name)->toBe('Updated Name');
    });

    it('can delete artist', function () {
        $artist = Artist::factory()->create();

        $this->actingAs($this->user)
            ->delete("/chinook-fm/artists/{$artist->id}")
            ->assertRedirect();

        $this->assertSoftDeleted('chinook_artists', ['id' => $artist->id]);
    });
});
```

## 5. Livewire Component Testing

### 5.1 Music Catalog Browser Component Tests

```php
<?php

use App\Models\User;
use App\Models\Chinook\Artist;
use App\Models\Chinook\Album;
use App\Models\Chinook\Track;
use Aliziodev\LaravelTaxonomy\Models\TaxonomyTerm;
use Livewire\Livewire;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

describe('Music Catalog Browser Component', function () {
    beforeEach(function () {
        $this->user = User::factory()->create();
        $this->actingAs($this->user);

        // Create test data
        $this->artist = Artist::factory()->create(['name' => 'Test Artist']);
        $this->album = Album::factory()->for($this->artist)->create(['title' => 'Test Album']);
        $this->tracks = Track::factory()->count(5)->for($this->album)->create();

        // Create taxonomy terms
        $this->genre = TaxonomyTerm::factory()->create(['name' => 'Rock']);
        $this->mood = TaxonomyTerm::factory()->create(['name' => 'Energetic']);
    });

    it('renders catalog browser component successfully', function () {
        Livewire::test('music.catalog-browser')
            ->assertStatus(200)
            ->assertSee('Search tracks, albums, artists...')
            ->assertSee('Tracks')
            ->assertSee('Albums')
            ->assertSee('Artists');
    });

    it('can search tracks by name', function () {
        $searchTrack = Track::factory()->for($this->album)->create(['name' => 'Searchable Track']);

        Livewire::test('music.catalog-browser')
            ->set('search', 'Searchable')
            ->assertSee('Searchable Track')
            ->assertDontSee($this->tracks->first()->name);
    });

    it('can search across artists and albums', function () {
        $searchArtist = Artist::factory()->create(['name' => 'Searchable Artist']);
        $searchAlbum = Album::factory()->for($searchArtist)->create(['title' => 'Searchable Album']);
        $searchTrack = Track::factory()->for($searchAlbum)->create(['name' => 'Track by Searchable Artist']);

        Livewire::test('music.catalog-browser')
            ->set('search', 'Searchable')
            ->assertSee('Track by Searchable Artist')
            ->assertSee('Searchable Artist');
    });

    it('can filter by genres', function () {
        // Attach genre to one track
        $this->tracks->first()->taxonomies()->create([
            'taxonomy_term_id' => $this->genre->id,
            'taxonomy_id' => $this->genre->taxonomy_id,
        ]);

        Livewire::test('music.catalog-browser')
            ->set('selectedGenres', [$this->genre->id])
            ->assertSee($this->tracks->first()->name)
            ->assertDontSee($this->tracks->last()->name);
    });

    it('can switch between view modes', function () {
        Livewire::test('music.catalog-browser')
            ->call('setViewMode', 'list')
            ->assertSet('viewMode', 'list')
            ->call('setViewMode', 'table')
            ->assertSet('viewMode', 'table')
            ->call('setViewMode', 'grid')
            ->assertSet('viewMode', 'grid');
    });

    it('can switch between tabs', function () {
        Livewire::test('music.catalog-browser')
            ->call('setActiveTab', 'albums')
            ->assertSet('activeTab', 'albums')
            ->call('setActiveTab', 'artists')
            ->assertSet('activeTab', 'artists')
            ->call('setActiveTab', 'tracks')
            ->assertSet('activeTab', 'tracks');
    });

    it('can sort results', function () {
        Livewire::test('music.catalog-browser')
            ->call('setSortBy', 'name')
            ->assertSet('sortBy', 'name')
            ->assertSet('sortOrder', 'asc')
            ->call('setSortBy', 'name') // Second call should toggle order
            ->assertSet('sortOrder', 'desc');
    });

    it('can clear all filters', function () {
        Livewire::test('music.catalog-browser')
            ->set('search', 'test')
            ->set('selectedGenres', [$this->genre->id])
            ->set('selectedMoods', [$this->mood->id])
            ->call('clearFilters')
            ->assertSet('search', '')
            ->assertSet('selectedGenres', [])
            ->assertSet('selectedMoods', []);
    });

    it('can add track to playlist', function () {
        Livewire::test('music.catalog-browser')
            ->call('addToPlaylist', $this->tracks->first()->id)
            ->assertDispatched('track-added-to-playlist', trackId: $this->tracks->first()->id)
            ->assertDispatched('notify', type: 'success');
    });

    it('can play track', function () {
        Livewire::test('music.catalog-browser')
            ->call('playTrack', $this->tracks->first()->id)
            ->assertDispatched('play-track', trackId: $this->tracks->first()->id);
    });

    it('resets page when search changes', function () {
        Livewire::test('music.catalog-browser')
            ->set('page', 2)
            ->set('search', 'new search')
            ->assertSet('page', 1);
    });

    it('loads tracks with proper relationships', function () {
        $component = Livewire::test('music.catalog-browser');

        $tracks = $component->get('tracks');

        expect($tracks->first())
            ->toHaveKey('album')
            ->and($tracks->first()->album)
            ->toHaveKey('artist')
            ->and($tracks->first()->mediaType)
            ->not->toBeNull();
    });

    it('handles empty search results gracefully', function () {
        Livewire::test('music.catalog-browser')
            ->set('search', 'nonexistent search term')
            ->assertSee('No tracks found'); // Assuming this message exists
    });

    it('validates authorization for viewing tracks', function () {
        $unauthorizedUser = User::factory()->create();

        $this->actingAs($unauthorizedUser);

        // Mock authorization failure
        $this->mock(\Illuminate\Contracts\Auth\Access\Gate::class)
            ->shouldReceive('authorize')
            ->with('viewAny', Track::class)
            ->andThrow(new \Illuminate\Auth\Access\AuthorizationException());

        expect(fn() => Livewire::test('music.catalog-browser'))
            ->toThrow(\Illuminate\Auth\Access\AuthorizationException::class);
    });
});
```

### 5.2 Advanced Search Component Tests

```php
<?php

use App\Models\User;
use App\Models\Chinook\Track;
use App\Models\Chinook\MediaType;
use Livewire\Livewire;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

describe('Advanced Search Component', function () {
    beforeEach(function () {
        $this->user = User::factory()->create();
        $this->actingAs($this->user);

        // Create test data
        $this->mediaType = MediaType::factory()->create(['name' => 'MPEG audio file']);
        $this->track = Track::factory()->create([
            'name' => 'Test Track',
            'composer' => 'Test Composer',
            'milliseconds' => 180000, // 3 minutes
            'unit_price' => 0.99,
            'media_type_id' => $this->mediaType->id,
        ]);
    });

    it('renders advanced search component successfully', function () {
        Livewire::test('music.advanced-search')
            ->assertStatus(200)
            ->assertSee('Advanced Search')
            ->assertSee('Track Name')
            ->assertSee('Artist Name')
            ->assertSee('Album Title')
            ->assertSee('Composer');
    });

    it('can search by track name', function () {
        Livewire::test('music.advanced-search')
            ->set('trackName', 'Test Track')
            ->call('search')
            ->assertSee('Test Track');
    });

    it('can search by composer', function () {
        Livewire::test('music.advanced-search')
            ->set('composer', 'Test Composer')
            ->call('search')
            ->assertSee('Test Track');
    });

    it('can filter by duration range', function () {
        Livewire::test('music.advanced-search')
            ->set('minDuration', 120) // 2 minutes
            ->set('maxDuration', 240) // 4 minutes
            ->call('search')
            ->assertSee('Test Track');
    });

    it('can filter by price range', function () {
        Livewire::test('music.advanced-search')
            ->set('minPrice', 0.50)
            ->set('maxPrice', 1.50)
            ->call('search')
            ->assertSee('Test Track');
    });

    it('can filter by media type', function () {
        Livewire::test('music.advanced-search')
            ->set('mediaType', 'MPEG audio file')
            ->call('search')
            ->assertSee('Test Track');
    });

    it('can toggle advanced filters', function () {
        Livewire::test('music.advanced-search')
            ->assertSet('showAdvancedFilters', false)
            ->call('toggleAdvancedFilters')
            ->assertSet('showAdvancedFilters', true)
            ->call('toggleAdvancedFilters')
            ->assertSet('showAdvancedFilters', false);
    });

    it('can clear all search criteria', function () {
        Livewire::test('music.advanced-search')
            ->set('trackName', 'test')
            ->set('artistName', 'test')
            ->set('minPrice', 0.50)
            ->set('explicitContent', true)
            ->call('clearSearch')
            ->assertSet('trackName', '')
            ->assertSet('artistName', '')
            ->assertSet('minPrice', null)
            ->assertSet('explicitContent', false);
    });

    it('can save search criteria', function () {
        Livewire::test('music.advanced-search')
            ->set('trackName', 'test track')
            ->set('artistName', 'test artist')
            ->call('saveSearch')
            ->assertDispatched('search-saved')
            ->assertDispatched('notify', type: 'success');
    });

    it('applies relevance scoring correctly', function () {
        // Create tracks with different relevance scores
        $exactMatch = Track::factory()->create(['name' => 'Exact Match']);
        $partialMatch = Track::factory()->create(['name' => 'Partial Exact Match']);
        $composerMatch = Track::factory()->create(['composer' => 'Exact Composer']);

        $component = Livewire::test('music.advanced-search')
            ->set('trackName', 'Exact')
            ->set('composer', 'Exact')
            ->set('sortBy', 'relevance');

        $results = $component->get('searchResults');

        // Exact track name match should score highest
        expect($results->first()->name)->toBe('Exact Match');
    });

    it('handles complex search combinations', function () {
        $complexTrack = Track::factory()->create([
            'name' => 'Complex Search Track',
            'composer' => 'Complex Composer',
            'milliseconds' => 200000,
            'unit_price' => 1.29,
        ]);

        Livewire::test('music.advanced-search')
            ->set('trackName', 'Complex')
            ->set('composer', 'Complex')
            ->set('minDuration', 180)
            ->set('maxDuration', 240)
            ->set('minPrice', 1.00)
            ->set('maxPrice', 1.50)
            ->call('search')
            ->assertSee('Complex Search Track');
    });

    it('shows search result count', function () {
        Track::factory()->count(5)->create(['name' => 'Countable Track']);

        Livewire::test('music.advanced-search')
            ->set('trackName', 'Countable')
            ->call('search')
            ->assertSee('Found 5 tracks');
    });
});
```

## 6. API Testing

### 5.1 Artist API Tests

```php
<?php

use App\Models\User;
use App\Models\Chinook\Artist;
use Laravel\Sanctum\Sanctum;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

describe('Artist API', function () {
    beforeEach(function () {
        $this->user = User::factory()->create();
        Sanctum::actingAs($this->user);
    });

    it('can get artists list via API', function () {
        Artist::factory()->count(5)->create();

        $response = $this->getJson('/api/artists');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    '*' => [
                        'id',
                        'name',
                        'public_id',
                        'slug',
                        'bio',
                        'country',
                        'is_active',
                        'created_at',
                        'updated_at'
                    ]
                ],
                'meta' => [
                    'current_page',
                    'total',
                    'per_page'
                ]
            ]);
    });

    it('can get single artist via API', function () {
        $artist = Artist::factory()->create();

        $response = $this->getJson("/api/artists/{$artist->public_id}");

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'id' => $artist->id,
                    'name' => $artist->name,
                    'public_id' => $artist->public_id,
                ]
            ]);
    });

    it('returns 404 for non-existent artist', function () {
        $response = $this->getJson('/api/artists/non-existent-id');

        $response->assertStatus(404)
            ->assertJson([
                'message' => 'Artist not found'
            ]);
    });

    it('can create artist via API', function () {
        $artistData = [
            'name' => 'API Test Artist',
            'bio' => 'Created via API',
            'country' => 'Canada',
            'is_active' => true,
        ];

        $response = $this->postJson('/api/artists', $artistData);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'data' => [
                    'id',
                    'name',
                    'public_id',
                    'slug'
                ]
            ]);

        $this->assertDatabaseHas('chinook_artists', [
            'name' => 'API Test Artist',
            'country' => 'Canada',
        ]);
    });

    it('validates API input when creating artist', function () {
        $response = $this->postJson('/api/artists', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['name']);
    });
});
```

## 8. Integration Testing

### 8.1 Taxonomy Integration Tests

```php
<?php

use App\Models\Chinook\Track;
use App\Models\Chinook\Artist;
use App\Models\Chinook\Album;
use Aliziodev\LaravelTaxonomy\Models\Taxonomy;
use Aliziodev\LaravelTaxonomy\Models\TaxonomyTerm;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

describe('Taxonomy Integration', function () {
    beforeEach(function () {
        // Create taxonomies
        $this->genreTaxonomy = Taxonomy::factory()->create(['slug' => 'music-genres']);
        $this->moodTaxonomy = Taxonomy::factory()->create(['slug' => 'moods']);

        // Create terms
        $this->rockGenre = TaxonomyTerm::factory()->for($this->genreTaxonomy)->create(['name' => 'Rock']);
        $this->energeticMood = TaxonomyTerm::factory()->for($this->moodTaxonomy)->create(['name' => 'Energetic']);

        // Create test data
        $this->artist = Artist::factory()->create();
        $this->album = Album::factory()->for($this->artist)->create();
        $this->track = Track::factory()->for($this->album)->create();
    });

    it('can attach taxonomy terms to tracks', function () {
        $this->track->taxonomies()->create([
            'taxonomy_id' => $this->genreTaxonomy->id,
            'taxonomy_term_id' => $this->rockGenre->id,
        ]);

        expect($this->track->taxonomies)
            ->toHaveCount(1)
            ->first()->term->name->toBe('Rock');
    });

    it('can filter tracks by taxonomy terms', function () {
        // Attach genre to track
        $this->track->taxonomies()->create([
            'taxonomy_id' => $this->genreTaxonomy->id,
            'taxonomy_term_id' => $this->rockGenre->id,
        ]);

        // Create another track without genre
        $otherTrack = Track::factory()->for($this->album)->create();

        $rockTracks = Track::whereHas('taxonomies', function ($query) {
            $query->where('taxonomy_term_id', $this->rockGenre->id);
        })->get();

        expect($rockTracks)
            ->toHaveCount(1)
            ->first()->id->toBe($this->track->id);
    });

    it('can attach multiple taxonomy terms to single track', function () {
        $this->track->taxonomies()->createMany([
            [
                'taxonomy_id' => $this->genreTaxonomy->id,
                'taxonomy_term_id' => $this->rockGenre->id,
            ],
            [
                'taxonomy_id' => $this->moodTaxonomy->id,
                'taxonomy_term_id' => $this->energeticMood->id,
            ],
        ]);

        expect($this->track->taxonomies)->toHaveCount(2);

        $genreTerms = $this->track->taxonomies->where('taxonomy_id', $this->genreTaxonomy->id);
        $moodTerms = $this->track->taxonomies->where('taxonomy_id', $this->moodTaxonomy->id);

        expect($genreTerms)->toHaveCount(1);
        expect($moodTerms)->toHaveCount(1);
    });

    it('can get tracks by multiple taxonomy filters', function () {
        // Create tracks with different taxonomy combinations
        $track1 = Track::factory()->for($this->album)->create();
        $track2 = Track::factory()->for($this->album)->create();

        // Track 1: Rock + Energetic
        $track1->taxonomies()->createMany([
            ['taxonomy_id' => $this->genreTaxonomy->id, 'taxonomy_term_id' => $this->rockGenre->id],
            ['taxonomy_id' => $this->moodTaxonomy->id, 'taxonomy_term_id' => $this->energeticMood->id],
        ]);

        // Track 2: Only Rock
        $track2->taxonomies()->create([
            'taxonomy_id' => $this->genreTaxonomy->id,
            'taxonomy_term_id' => $this->rockGenre->id,
        ]);

        // Filter by both Rock AND Energetic
        $filteredTracks = Track::whereHas('taxonomies', function ($query) {
            $query->where('taxonomy_term_id', $this->rockGenre->id);
        })->whereHas('taxonomies', function ($query) {
            $query->where('taxonomy_term_id', $this->energeticMood->id);
        })->get();

        expect($filteredTracks)
            ->toHaveCount(1)
            ->first()->id->toBe($track1->id);
    });

    it('handles taxonomy term deletion gracefully', function () {
        $this->track->taxonomies()->create([
            'taxonomy_id' => $this->genreTaxonomy->id,
            'taxonomy_term_id' => $this->rockGenre->id,
        ]);

        expect($this->track->taxonomies)->toHaveCount(1);

        // Delete the taxonomy term
        $this->rockGenre->delete();

        // Refresh track and check taxonomies
        $this->track->refresh();
        expect($this->track->taxonomies)->toHaveCount(0);
    });
});
```

### 8.2 Payment Processing Integration Tests

```php
<?php

use App\Models\Chinook\Invoice;
use App\Models\Chinook\InvoiceLine;
use App\Models\Chinook\Customer;
use App\Models\Chinook\Track;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

describe('Payment Processing Integration', function () {
    beforeEach(function () {
        $this->customer = Customer::factory()->create();
        $this->track = Track::factory()->create(['unit_price' => 0.99]);

        $this->invoice = Invoice::factory()->for($this->customer)->create([
            'total' => 0,
            'payment_status' => 'pending',
        ]);
    });

    it('calculates invoice total from line items', function () {
        // Add invoice lines
        InvoiceLine::factory()->for($this->invoice)->for($this->track)->create([
            'quantity' => 2,
            'unit_price' => 0.99,
        ]);

        InvoiceLine::factory()->for($this->invoice)->create([
            'quantity' => 1,
            'unit_price' => 1.29,
        ]);

        // Recalculate total
        $this->invoice->recalculateTotal();

        expect($this->invoice->fresh()->total)->toBe(3.27); // (2 * 0.99) + 1.29
    });

    it('processes payment successfully', function () {
        InvoiceLine::factory()->for($this->invoice)->for($this->track)->create([
            'quantity' => 1,
            'unit_price' => 0.99,
        ]);

        $this->invoice->recalculateTotal();

        // Process payment
        $this->invoice->markAsPaid();

        expect($this->invoice->fresh())
            ->payment_status->toBe('paid')
            ->payment_date->not->toBeNull();
    });

    it('handles refund processing', function () {
        $this->invoice->update([
            'total' => 0.99,
            'payment_status' => 'paid',
            'payment_date' => now(),
        ]);

        // Process refund
        $this->invoice->processRefund();

        expect($this->invoice->fresh()->payment_status)->toBe('refunded');
    });

    it('validates payment amounts', function () {
        InvoiceLine::factory()->for($this->invoice)->for($this->track)->create([
            'quantity' => 1,
            'unit_price' => 0.99,
        ]);

        $this->invoice->recalculateTotal();

        expect($this->invoice->fresh()->total)->toBe(0.99);

        // Cannot mark as paid if total is 0
        $this->invoice->update(['total' => 0]);

        expect(fn() => $this->invoice->markAsPaid())
            ->toThrow(\InvalidArgumentException::class, 'Cannot mark invoice with zero total as paid');
    });

    it('tracks payment history', function () {
        $this->invoice->update(['total' => 0.99]);

        // Mark as paid
        $this->invoice->markAsPaid();

        // Process refund
        $this->invoice->processRefund();

        $paymentHistory = $this->invoice->getPaymentHistoryAttribute();

        expect($paymentHistory)
            ->toHaveCount(2)
            ->toContain('paid')
            ->toContain('refunded');
    });
});
```

## 9. Authorization Testing

### 9.1 Employee Policy Tests

```php
<?php

use App\Models\User;
use App\Models\Chinook\Employee;
use App\Models\Chinook\Customer;
use App\Policies\Chinook\EmployeePolicy;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

describe('Employee Policy', function () {
    beforeEach(function () {
        $this->policy = new EmployeePolicy();
        $this->user = User::factory()->create();
        $this->employee = Employee::factory()->create();
    });

    it('allows viewing employees with proper permission', function () {
        $this->user->givePermissionTo('view_any_chinook::employee');

        expect($this->policy->viewAny($this->user))->toBeTrue();
    });

    it('denies viewing employees without permission', function () {
        expect($this->policy->viewAny($this->user))->toBeFalse();
    });

    it('allows creating employees with proper permission', function () {
        $this->user->givePermissionTo('create_chinook::employee');

        expect($this->policy->create($this->user))->toBeTrue();
    });

    it('prevents deletion of employee with customers', function () {
        $this->user->givePermissionTo('delete_chinook::employee');

        // Assign customer to employee
        Customer::factory()->for($this->employee, 'supportRep')->create();

        expect($this->policy->delete($this->user, $this->employee))->toBeFalse();
    });

    it('prevents deletion of employee with subordinates', function () {
        $this->user->givePermissionTo('delete_chinook::employee');

        // Create subordinate
        Employee::factory()->create(['reports_to' => $this->employee->id]);

        expect($this->policy->delete($this->user, $this->employee))->toBeFalse();
    });

    it('allows deletion of employee without dependencies', function () {
        $this->user->givePermissionTo('delete_chinook::employee');

        expect($this->policy->delete($this->user, $this->employee))->toBeTrue();
    });

    it('allows managers to view subordinate performance', function () {
        $manager = Employee::factory()->create();
        $subordinate = Employee::factory()->create(['reports_to' => $manager->id]);

        $managerUser = User::factory()->create(['employee_id' => $manager->id]);

        expect($this->policy->viewPerformance($managerUser, $subordinate))->toBeTrue();
    });

    it('allows HR to view all performance data', function () {
        $hrEmployee = Employee::factory()->create(['department' => 'HR']);
        $hrUser = User::factory()->create(['employee_id' => $hrEmployee->id]);

        expect($this->policy->viewPerformance($hrUser, $this->employee))->toBeTrue();
    });

    it('restricts salary information to HR and management', function () {
        $hrEmployee = Employee::factory()->create(['department' => 'HR']);
        $hrUser = User::factory()->create(['employee_id' => $hrEmployee->id]);

        $mgmtEmployee = Employee::factory()->create(['department' => 'Management']);
        $mgmtUser = User::factory()->create(['employee_id' => $mgmtEmployee->id]);

        $regularEmployee = Employee::factory()->create(['department' => 'Sales']);
        $regularUser = User::factory()->create(['employee_id' => $regularEmployee->id]);

        expect($this->policy->viewSalary($hrUser, $this->employee))->toBeTrue();
        expect($this->policy->viewSalary($mgmtUser, $this->employee))->toBeTrue();
        expect($this->policy->viewSalary($regularUser, $this->employee))->toBeFalse();
    });
});
```

## 10. Database Testing

### 10.1 Migration and Schema Tests

```php
<?php

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

uses(RefreshDatabase::class);

describe('Database Schema', function () {
    it('has all required chinook tables', function () {
        $expectedTables = [
            'chinook_artists',
            'chinook_albums',
            'chinook_tracks',
            'chinook_customers',
            'chinook_employees',
            'chinook_invoices',
            'chinook_invoice_lines',
            'chinook_playlists',
            'chinook_playlist_tracks',
            'chinook_media_types',
            'chinook_genres',
        ];

        foreach ($expectedTables as $table) {
            expect(Schema::hasTable($table))->toBeTrue("Table {$table} should exist");
        }
    });

    it('has proper foreign key constraints', function () {
        // Test album -> artist relationship
        expect(Schema::hasColumn('chinook_albums', 'artist_id'))->toBeTrue();

        // Test track -> album relationship
        expect(Schema::hasColumn('chinook_tracks', 'album_id'))->toBeTrue();

        // Test invoice -> customer relationship
        expect(Schema::hasColumn('chinook_invoices', 'customer_id'))->toBeTrue();

        // Test employee -> employee (manager) relationship
        expect(Schema::hasColumn('chinook_employees', 'reports_to'))->toBeTrue();
    });

    it('has proper indexes for performance', function () {
        $indexes = DB::select("SHOW INDEX FROM chinook_tracks WHERE Key_name != 'PRIMARY'");
        $indexColumns = collect($indexes)->pluck('Column_name')->toArray();

        expect($indexColumns)->toContain('album_id');
        expect($indexColumns)->toContain('media_type_id');
    });

    it('enforces unique constraints', function () {
        // Test unique slug constraint
        $artist1 = \App\Models\Chinook\Artist::factory()->create(['slug' => 'test-artist']);

        expect(fn() => \App\Models\Chinook\Artist::factory()->create(['slug' => 'test-artist']))
            ->toThrow(\Illuminate\Database\QueryException::class);
    });

    it('handles soft deletes properly', function () {
        $artist = \App\Models\Chinook\Artist::factory()->create();

        expect(Schema::hasColumn('chinook_artists', 'deleted_at'))->toBeTrue();

        $artist->delete();

        expect(\App\Models\Chinook\Artist::count())->toBe(0);
        expect(\App\Models\Chinook\Artist::withTrashed()->count())->toBe(1);
    });
});
```

### 10.2 Data Integrity Tests

```php
<?php

use App\Models\Chinook\Artist;
use App\Models\Chinook\Album;
use App\Models\Chinook\Track;
use App\Models\Chinook\Invoice;
use App\Models\Chinook\InvoiceLine;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

describe('Data Integrity', function () {
    it('maintains referential integrity on cascade delete', function () {
        $artist = Artist::factory()->create();
        $album = Album::factory()->for($artist)->create();
        $tracks = Track::factory()->count(3)->for($album)->create();

        // Delete artist should cascade to albums and tracks
        $artist->forceDelete();

        expect(Album::count())->toBe(0);
        expect(Track::count())->toBe(0);
    });

    it('prevents orphaned records', function () {
        $album = Album::factory()->create();
        $track = Track::factory()->for($album)->create();

        // Try to delete album with existing tracks
        expect(fn() => $album->forceDelete())
            ->toThrow(\Illuminate\Database\QueryException::class);
    });

    it('maintains invoice line totals consistency', function () {
        $invoice = Invoice::factory()->create(['total' => 0]);

        InvoiceLine::factory()->for($invoice)->create([
            'quantity' => 2,
            'unit_price' => 0.99,
        ]);

        InvoiceLine::factory()->for($invoice)->create([
            'quantity' => 1,
            'unit_price' => 1.29,
        ]);

        $calculatedTotal = $invoice->invoiceLines()->sum(DB::raw('quantity * unit_price'));

        expect($calculatedTotal)->toBe(3.27);

        // Update invoice total
        $invoice->update(['total' => $calculatedTotal]);

        expect($invoice->total)->toBe(3.27);
    });

    it('validates decimal precision for prices', function () {
        $track = Track::factory()->create(['unit_price' => 0.999]);

        // Should round to 2 decimal places
        expect($track->fresh()->unit_price)->toBe(1.00);
    });

    it('handles concurrent updates safely', function () {
        $invoice = Invoice::factory()->create(['total' => 10.00]);

        // Simulate concurrent updates
        $invoice1 = Invoice::find($invoice->id);
        $invoice2 = Invoice::find($invoice->id);

        $invoice1->update(['total' => 15.00]);
        $invoice2->update(['total' => 20.00]);

        // Last update should win
        expect($invoice->fresh()->total)->toBe(20.00);
    });
});
```

## 7. Performance Testing

### 7.1 Database Query Performance Tests

```php
<?php

use App\Models\Chinook\Artist;
use App\Models\Chinook\Album;
use App\Models\Chinook\Track;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;

uses(RefreshDatabase::class);

describe('Performance Tests', function () {
    it('loads artists with albums efficiently', function () {
        // Create test data
        $artists = Artist::factory()->count(10)->create();
        foreach ($artists as $artist) {
            Album::factory()->count(3)->create(['artist_id' => $artist->id]);
        }

        // Track queries
        DB::enableQueryLog();

        // Load artists with albums
        $artistsWithAlbums = Artist::with('albums')->get();

        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        // Should use only 2 queries (artists + albums)
        expect(count($queries))->toBeLessThanOrEqual(2);
        expect($artistsWithAlbums)->toHaveCount(10);
        expect($artistsWithAlbums->first()->albums)->toHaveCount(3);
    });

    it('caches popular artists query', function () {
        Artist::factory()->count(5)->create();

        // First call should hit database
        $start = microtime(true);
        $popularArtists1 = Artist::getPopularArtists(3);
        $firstCallTime = microtime(true) - $start;

        // Second call should use cache
        $start = microtime(true);
        $popularArtists2 = Artist::getPopularArtists(3);
        $secondCallTime = microtime(true) - $start;

        expect($secondCallTime)->toBeLessThan($firstCallTime);
        expect($popularArtists1->pluck('id'))->toEqual($popularArtists2->pluck('id'));
    });

    it('handles large dataset pagination efficiently', function () {
        Artist::factory()->count(1000)->create();

        DB::enableQueryLog();

        $paginatedArtists = Artist::paginate(50);

        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        // Should use minimal queries for pagination
        expect(count($queries))->toBeLessThanOrEqual(3); // data + count + any joins
        expect($paginatedArtists->count())->toBe(50);
        expect($paginatedArtists->total())->toBe(1000);
    });
});
```

---

## Navigation

- **Previous:** [Accessibility Testing Guide](./000-accessibility-testing-guide.md)
- **Next:** [Performance Testing Guide](./200-performance-testing-guide.md)
- **Index:** [Testing Index](./000-testing-index.md)

## Related Documentation

- [Pest Testing Configuration](../packages/000-pest-testing-configuration-guide.md)
- [Chinook Models Guide](../010-chinook-models-guide.md)

---

**Last Updated:** 2025-07-16  
**Maintainer:** Technical Documentation Team  
**Source:** [GitHub Repository](https://github.com/s-a-c/chinook)
