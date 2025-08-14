# Chinook API Testing - Comprehensive Guide

> **Created:** 2025-07-18  
> **Focus:** Complete API testing strategies with automated testing, performance testing, and security testing

## Table of Contents

- [Overview](#overview)
- [Unit Testing](#unit-testing)
- [Integration Testing](#integration-testing)
- [Performance Testing](#performance-testing)
- [Security Testing](#security-testing)
- [Automated Testing](#automated-testing)
- [Testing Tools](#testing-tools)

## Overview

Comprehensive testing strategy for the Chinook API covering functional testing, performance validation, security testing, and automated test suites.

### Testing Pyramid

```
    /\
   /  \     E2E Tests (10%)
  /____\    Integration Tests (20%)
 /      \   Unit Tests (70%)
/__________\
```

## Unit Testing

### Laravel Feature Tests

```php
<?php
// tests/Feature/Api/ArtistApiTest.php

namespace Tests\Feature\Api;

use App\Models\Chinook\Artist;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use Laravel\Sanctum\Sanctum;use old\TestCase;

class ArtistApiTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->user = User::factory()->create();
        Sanctum::actingAs($this->user, ['read:catalog', 'write:catalog']);
    }

    public function test_can_list_artists(): void
    {
        Artist::factory()->count(5)->create();

        $response = $this->getJson('/api/v1/artists');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    '*' => [
                        'id', 'name', 'slug', 'country', 'is_active',
                        'created_at', 'updated_at'
                    ]
                ],
                'meta' => ['current_page', 'per_page', 'total'],
                'links' => ['first', 'last', 'prev', 'next']
            ]);
    }

    public function test_can_get_single_artist(): void
    {
        $artist = Artist::factory()->create(['name' => 'Test Artist']);

        $response = $this->getJson("/api/v1/artists/{$artist->id}");

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'id' => $artist->id,
                    'name' => 'Test Artist',
                    'slug' => $artist->slug
                ]
            ]);
    }

    public function test_can_create_artist(): void
    {
        $artistData = [
            'name' => 'New Artist',
            'bio' => 'Artist biography',
            'country' => 'USA',
            'is_active' => true
        ];

        $response = $this->postJson('/api/v1/artists', $artistData);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'data' => ['id', 'name', 'slug', 'public_id']
            ]);

        $this->assertDatabaseHas('chinook_artists', [
            'name' => 'New Artist',
            'country' => 'USA'
        ]);
    }

    public function test_validates_required_fields(): void
    {
        $response = $this->postJson('/api/v1/artists', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['name']);
    }

    public function test_can_update_artist(): void
    {
        $artist = Artist::factory()->create();
        $updateData = ['name' => 'Updated Name'];

        $response = $this->putJson("/api/v1/artists/{$artist->id}", $updateData);

        $response->assertStatus(200);
        $this->assertDatabaseHas('chinook_artists', [
            'id' => $artist->id,
            'name' => 'Updated Name'
        ]);
    }

    public function test_can_delete_artist(): void
    {
        $artist = Artist::factory()->create();

        $response = $this->deleteJson("/api/v1/artists/{$artist->id}");

        $response->assertStatus(204);
        $this->assertSoftDeleted('chinook_artists', ['id' => $artist->id]);
    }

    public function test_returns_404_for_nonexistent_artist(): void
    {
        $response = $this->getJson('/api/v1/artists/999');

        $response->assertStatus(404)
            ->assertJson([
                'error' => [
                    'type' => 'not_found_error',
                    'message' => 'Artist not found'
                ]
            ]);
    }

    public function test_requires_authentication(): void
    {
        Sanctum::actingAs(null);

        $response = $this->getJson('/api/v1/artists');

        $response->assertStatus(401);
    }

    public function test_requires_proper_scopes(): void
    {
        Sanctum::actingAs($this->user, ['read:customers']); // Wrong scope

        $response = $this->getJson('/api/v1/artists');

        $response->assertStatus(403);
    }
}
```

### API Resource Testing

```php
<?php
// tests/Feature/Api/SearchApiTest.php

namespace Tests\Feature\Api;

use App\Models\Chinook\Album;use App\Models\Chinook\Artist;use App\Models\Chinook\Track;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use Laravel\Sanctum\Sanctum;use old\TestCase;

class SearchApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        
        $user = User::factory()->create();
        Sanctum::actingAs($user, ['read:catalog']);
    }

    public function test_can_search_across_resources(): void
    {
        $artist = Artist::factory()->create(['name' => 'The Beatles']);
        $album = Album::factory()->for($artist)->create(['title' => 'Abbey Road']);
        Track::factory()->for($album)->create(['name' => 'Come Together']);

        $response = $this->postJson('/api/v1/search', [
            'query' => 'Beatles',
            'filters' => ['type' => ['artist', 'album', 'track']]
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    'artists' => ['*' => ['id', 'name', 'slug']],
                    'albums' => ['*' => ['id', 'title', 'artist']],
                    'tracks' => ['*' => ['id', 'name', 'album']]
                ],
                'meta' => ['total_results', 'search_time']
            ]);
    }

    public function test_search_with_filters(): void
    {
        $response = $this->postJson('/api/v1/search', [
            'query' => 'rock',
            'filters' => [
                'type' => ['track'],
                'genres' => ['Rock'],
                'price_range' => ['min' => 0.99, 'max' => 1.99]
            ]
        ]);

        $response->assertStatus(200);
    }

    public function test_search_pagination(): void
    {
        Artist::factory()->count(50)->create(['name' => 'Rock Artist']);

        $response = $this->postJson('/api/v1/search', [
            'query' => 'Rock Artist',
            'pagination' => ['per_page' => 10, 'page' => 2]
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('meta.current_page', 2)
            ->assertJsonPath('meta.per_page', 10);
    }
}
```

## Integration Testing

### End-to-End Workflow Testing

```php
<?php
// tests/Feature/Api/CustomerOrderWorkflowTest.php

namespace Tests\Feature\Api;

use App\Models\Chinook\Customer;use App\Models\Chinook\Invoice;use App\Models\Chinook\Track;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use Laravel\Sanctum\Sanctum;use old\TestCase;

class CustomerOrderWorkflowTest extends TestCase
{
    use RefreshDatabase;

    public function test_complete_customer_order_workflow(): void
    {
        // Setup
        $user = User::factory()->create();
        Sanctum::actingAs($user, ['read:catalog', 'write:orders']);
        
        $customer = Customer::factory()->create();
        $tracks = Track::factory()->count(3)->create(['unit_price' => 0.99]);

        // Step 1: Browse catalog
        $catalogResponse = $this->getJson('/api/v1/tracks?per_page=10');
        $catalogResponse->assertStatus(200);

        // Step 2: Create shopping cart (playlist)
        $cartResponse = $this->postJson('/api/v1/playlists', [
            'name' => 'Shopping Cart',
            'is_public' => false,
            'track_ids' => $tracks->pluck('id')->toArray()
        ]);
        $cartResponse->assertStatus(201);
        $cartId = $cartResponse->json('data.id');

        // Step 3: Create invoice
        $invoiceResponse = $this->postJson('/api/v1/invoices', [
            'customer_id' => $customer->id,
            'line_items' => $tracks->map(fn($track) => [
                'track_id' => $track->id,
                'quantity' => 1,
                'unit_price' => $track->unit_price
            ])->toArray()
        ]);
        $invoiceResponse->assertStatus(201);
        $invoiceId = $invoiceResponse->json('data.id');

        // Step 4: Process payment
        $paymentResponse = $this->postJson("/api/v1/invoices/{$invoiceId}/payment", [
            'payment_method' => 'credit_card',
            'amount' => 2.97, // 3 tracks × $0.99
            'payment_reference' => 'ch_test_123'
        ]);
        $paymentResponse->assertStatus(200);

        // Step 5: Verify order completion
        $orderResponse = $this->getJson("/api/v1/invoices/{$invoiceId}");
        $orderResponse->assertStatus(200)
            ->assertJsonPath('data.payment_status', 'paid')
            ->assertJsonPath('data.total', 2.97);

        // Verify database state
        $this->assertDatabaseHas('chinook_invoices', [
            'id' => $invoiceId,
            'customer_id' => $customer->id,
            'payment_status' => 'paid',
            'total' => 2.97
        ]);
    }
}
```

## Performance Testing

### Load Testing with Artillery

```yaml
# artillery-config.yml
config:
  target: 'https://api.chinook.example.com'
  phases:
    - duration: 60
      arrivalRate: 10
      name: "Warm up"
    - duration: 120
      arrivalRate: 50
      name: "Ramp up load"
    - duration: 300
      arrivalRate: 100
      name: "Sustained load"
  defaults:
    headers:
      Authorization: 'Bearer {{ $processEnvironment.API_TOKEN }}'
      Content-Type: 'application/json'

scenarios:
  - name: "Browse catalog"
    weight: 40
    flow:
      - get:
          url: "/api/v1/artists?per_page=25"
      - get:
          url: "/api/v1/albums?per_page=25"
      - get:
          url: "/api/v1/tracks?per_page=25"

  - name: "Search functionality"
    weight: 30
    flow:
      - post:
          url: "/api/v1/search"
          json:
            query: "rock music"
            filters:
              type: ["track", "album"]

  - name: "Customer operations"
    weight: 20
    flow:
      - get:
          url: "/api/v1/customers?per_page=10"
      - get:
          url: "/api/v1/customers/{{ $randomInt(1, 100) }}"

  - name: "Order processing"
    weight: 10
    flow:
      - post:
          url: "/api/v1/invoices"
          json:
            customer_id: "{{ $randomInt(1, 50) }}"
            line_items:
              - track_id: "{{ $randomInt(1, 100) }}"
                quantity: 1
                unit_price: 0.99
```

### Performance Benchmarks

```bash
# Run performance tests
artillery run artillery-config.yml

# Expected results:
# - Response time p95: < 200ms
# - Response time p99: < 500ms
# - Error rate: < 1%
# - Throughput: > 1000 req/sec
```

### Database Query Performance

```php
<?php
// tests/Performance/DatabasePerformanceTest.php

namespace Tests\Performance;

use App\Models\Chinook\Track;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Support\Facades\DB;use old\TestCase;

class DatabasePerformanceTest extends TestCase
{
    use RefreshDatabase;

    public function test_track_search_performance(): void
    {
        // Create test data
        Track::factory()->count(10000)->create();

        // Test query performance
        $startTime = microtime(true);
        
        $tracks = Track::with(['album.artist', 'mediaType'])
            ->where('name', 'like', '%rock%')
            ->limit(25)
            ->get();
            
        $endTime = microtime(true);
        $executionTime = ($endTime - $startTime) * 1000; // Convert to milliseconds

        // Assert performance requirements
        $this->assertLessThan(50, $executionTime, 'Query should execute in under 50ms');
        $this->assertLessThan(10, DB::getQueryLog()->count(), 'Should use fewer than 10 queries');
    }

    public function test_pagination_performance(): void
    {
        Track::factory()->count(10000)->create();

        $startTime = microtime(true);
        
        $tracks = Track::cursorPaginate(25);
        
        $endTime = microtime(true);
        $executionTime = ($endTime - $startTime) * 1000;

        $this->assertLessThan(30, $executionTime, 'Cursor pagination should be under 30ms');
    }
}
```

## Security Testing

### Authentication Security Tests

```php
<?php
// tests/Security/AuthenticationSecurityTest.php

namespace Tests\Security;

use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Support\Facades\Hash;use old\TestCase;

class AuthenticationSecurityTest extends TestCase
{
    use RefreshDatabase;

    public function test_prevents_brute_force_attacks(): void
    {
        $user = User::factory()->create([
            'email' => 'test@example.com',
            'password' => Hash::make('correct_password')
        ]);

        // Attempt multiple failed logins
        for ($i = 0; $i < 6; $i++) {
            $response = $this->postJson('/api/auth/login', [
                'email' => 'test@example.com',
                'password' => 'wrong_password',
                'device_name' => 'Test Device'
            ]);
        }

        // Should be rate limited after 5 attempts
        $response->assertStatus(429)
            ->assertJsonStructure([
                'error' => ['type', 'message', 'retry_after']
            ]);
    }

    public function test_token_expiration(): void
    {
        $user = User::factory()->create();
        
        // Create expired token
        $token = $user->createToken('test', ['read:catalog'], now()->subDay());

        $response = $this->getJson('/api/v1/artists', [
            'Authorization' => "Bearer {$token->plainTextToken}"
        ]);

        $response->assertStatus(401);
    }

    public function test_scope_enforcement(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test', ['read:customers']); // Wrong scope

        $response = $this->getJson('/api/v1/artists', [
            'Authorization' => "Bearer {$token->plainTextToken}"
        ]);

        $response->assertStatus(403);
    }

    public function test_sql_injection_prevention(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test', ['read:catalog']);

        // Attempt SQL injection
        $response = $this->getJson("/api/v1/artists?search='; DROP TABLE chinook_artists; --", [
            'Authorization' => "Bearer {$token->plainTextToken}"
        ]);

        $response->assertStatus(200); // Should not crash
        $this->assertDatabaseHas('chinook_artists', []); // Table should still exist
    }
}
```

## Automated Testing

### GitHub Actions CI/CD

```yaml
# .github/workflows/api-tests.yml
name: API Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: password
          MYSQL_DATABASE: chinook_test
        options: >-
          --health-cmd="mysqladmin ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=3

    steps:
    - uses: actions/checkout@v3
    
    - name: Setup PHP
      uses: shivammathur/setup-php@v2
      with:
        php-version: '8.2'
        extensions: mbstring, dom, fileinfo, mysql
        
    - name: Install dependencies
      run: composer install --no-progress --prefer-dist --optimize-autoloader
      
    - name: Copy environment file
      run: cp .env.testing .env
      
    - name: Generate application key
      run: php artisan key:generate
      
    - name: Run migrations
      run: php artisan migrate --force
      
    - name: Seed database
      run: php artisan db:seed --force
      
    - name: Run API tests
      run: php artisan test --testsuite=Feature --filter=Api
      
    - name: Run performance tests
      run: php artisan test --testsuite=Performance
      
    - name: Run security tests
      run: php artisan test --testsuite=Security
```

### Continuous Performance Monitoring

```javascript
// performance-monitor.js
const { performance } = require('perf_hooks');

class ApiPerformanceMonitor {
  constructor(baseUrl, token) {
    this.baseUrl = baseUrl;
    this.token = token;
    this.metrics = [];
  }

  async measureEndpoint(endpoint, method = 'GET', data = null) {
    const start = performance.now();
    
    try {
      const response = await fetch(`${this.baseUrl}${endpoint}`, {
        method,
        headers: {
          'Authorization': `Bearer ${this.token}`,
          'Content-Type': 'application/json'
        },
        body: data ? JSON.stringify(data) : null
      });
      
      const end = performance.now();
      const duration = end - start;
      
      this.metrics.push({
        endpoint,
        method,
        duration,
        status: response.status,
        timestamp: new Date().toISOString()
      });
      
      return { duration, status: response.status };
    } catch (error) {
      const end = performance.now();
      const duration = end - start;
      
      this.metrics.push({
        endpoint,
        method,
        duration,
        status: 'ERROR',
        error: error.message,
        timestamp: new Date().toISOString()
      });
      
      throw error;
    }
  }

  getAverageResponseTime(endpoint) {
    const endpointMetrics = this.metrics.filter(m => m.endpoint === endpoint);
    const total = endpointMetrics.reduce((sum, m) => sum + m.duration, 0);
    return total / endpointMetrics.length;
  }

  generateReport() {
    return {
      total_requests: this.metrics.length,
      average_response_time: this.metrics.reduce((sum, m) => sum + m.duration, 0) / this.metrics.length,
      error_rate: this.metrics.filter(m => m.status === 'ERROR').length / this.metrics.length,
      endpoints: this.getEndpointSummary()
    };
  }

  getEndpointSummary() {
    const summary = {};
    
    this.metrics.forEach(metric => {
      if (!summary[metric.endpoint]) {
        summary[metric.endpoint] = {
          count: 0,
          total_duration: 0,
          errors: 0
        };
      }
      
      summary[metric.endpoint].count++;
      summary[metric.endpoint].total_duration += metric.duration;
      if (metric.status === 'ERROR') {
        summary[metric.endpoint].errors++;
      }
    });
    
    Object.keys(summary).forEach(endpoint => {
      const data = summary[endpoint];
      data.average_duration = data.total_duration / data.count;
      data.error_rate = data.errors / data.count;
    });
    
    return summary;
  }
}

module.exports = ApiPerformanceMonitor;
```

This comprehensive testing guide provides complete coverage for API quality assurance with automated testing, performance validation, and security testing.
