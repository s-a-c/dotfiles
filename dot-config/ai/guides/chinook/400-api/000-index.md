# Chinook API Documentation - Complete Guide

> **Created:** 2025-07-18  
> **Focus:** Comprehensive REST API documentation with authentication, endpoints, and integration examples  
> **Source:** [Chinook API Implementation](https://github.com/s-a-c/chinook)

## Table of Contents

- [Overview](#overview)
- [Authentication](#authentication)
- [API Resources](#api-resources)
- [Error Handling](#error-handling)
- [Rate Limiting](#rate-limiting)
- [Pagination](#pagination)
- [Filtering and Searching](#filtering-and-searching)
- [Integration Examples](#integration-examples)
- [SDK and Client Libraries](#sdk-and-client-libraries)

## Overview

The Chinook API provides comprehensive access to the music catalog, customer management, and business operations through a RESTful interface. Built with Laravel 12 and Laravel Sanctum for authentication, the API supports all CRUD operations with advanced filtering, searching, and relationship management.

### Key Features

- **RESTful Design**: Standard HTTP methods with predictable URL patterns
- **JSON API Specification**: Consistent response format with metadata and relationships
- **Authentication**: Laravel Sanctum with token-based authentication
- **Authorization**: Role-based access control with granular permissions
- **Pagination**: Cursor-based pagination for optimal performance
- **Filtering**: Advanced filtering with taxonomy integration
- **Rate Limiting**: Configurable rate limits per endpoint and user type
- **Versioning**: API versioning with backward compatibility
- **Real-time**: WebSocket support for real-time updates
- **Documentation**: Interactive API documentation with Swagger/OpenAPI

### Base URL

```
Production: https://api.chinook.example.com/v1
Staging: https://staging-api.chinook.example.com/v1
Development: http://localhost:8000/api/v1
```

### Response Format

All API responses follow a consistent JSON structure:

```json
{
  "data": {
    // Resource data or array of resources
  },
  "meta": {
    "pagination": {
      "current_page": 1,
      "per_page": 25,
      "total": 150,
      "last_page": 6
    },
    "filters": {
      // Applied filters
    }
  },
  "links": {
    "first": "https://api.chinook.example.com/v1/artists?page=1",
    "last": "https://api.chinook.example.com/v1/artists?page=6",
    "prev": null,
    "next": "https://api.chinook.example.com/v1/artists?page=2"
  }
}
```

## Authentication

### Laravel Sanctum Integration

The Chinook API uses Laravel Sanctum for authentication with support for:

- **Personal Access Tokens**: For server-to-server communication
- **SPA Authentication**: For single-page applications
- **Mobile App Tokens**: For mobile applications with expiration

### Authentication Flow

#### 1. Obtain Access Token

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password",
  "device_name": "iPhone 15 Pro"
}
```

**Response:**
```json
{
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "user@example.com",
      "roles": ["customer"]
    },
    "token": "1|abc123def456...",
    "expires_at": "2025-08-18T10:30:00Z"
  }
}
```

#### 2. Use Token in Requests

```http
GET /api/v1/artists
Authorization: Bearer 1|abc123def456...
Accept: application/json
```

#### 3. Token Management

```http
# Refresh Token
POST /api/auth/refresh
Authorization: Bearer 1|abc123def456...

# Revoke Token
POST /api/auth/logout
Authorization: Bearer 1|abc123def456...

# List User Tokens
GET /api/auth/tokens
Authorization: Bearer 1|abc123def456...
```

### Permission Scopes

Tokens can be issued with specific scopes for granular access control:

- **`read:catalog`**: Read access to music catalog (artists, albums, tracks)
- **`write:catalog`**: Write access to music catalog (admin only)
- **`read:customers`**: Read customer information
- **`write:customers`**: Modify customer information
- **`read:orders`**: Read order and invoice information
- **`write:orders`**: Create and modify orders
- **`read:employees`**: Read employee information (managers and HR)
- **`write:employees`**: Modify employee information (HR only)
- **`admin:all`**: Full administrative access

Example token request with scopes:
```json
{
  "email": "admin@example.com",
  "password": "password",
  "device_name": "Admin Dashboard",
  "scopes": ["read:catalog", "write:catalog", "read:customers"]
}
```

## API Resources

### Artists API

**Base Endpoint:** `/api/v1/artists`

#### List Artists
```http
GET /api/v1/artists
```

**Query Parameters:**
- `page` (integer): Page number for pagination
- `per_page` (integer): Items per page (max 100)
- `search` (string): Search in artist name and bio
- `country` (string): Filter by country
- `genre` (array): Filter by genre taxonomy terms
- `active` (boolean): Filter by active status
- `sort` (string): Sort field (name, created_at, albums_count)
- `order` (string): Sort order (asc, desc)

**Example Response:**
```json
{
  "data": [
    {
      "id": 1,
      "public_id": "ART001",
      "slug": "the-beatles",
      "name": "The Beatles",
      "bio": "English rock band formed in Liverpool in 1960...",
      "country": "UK",
      "formed_year": 1960,
      "is_active": false,
      "social_links": {
        "website": "https://thebeatles.com",
        "spotify": "https://open.spotify.com/artist/3WrFJ7ztbogyGnTHbHJFl2"
      },
      "albums_count": 13,
      "tracks_count": 213,
      "taxonomies": [
        {
          "taxonomy": "music-genres",
          "term": "Rock"
        },
        {
          "taxonomy": "decades",
          "term": "1960s"
        }
      ],
      "created_at": "2025-01-15T10:30:00Z",
      "updated_at": "2025-07-18T14:22:00Z"
    }
  ],
  "meta": {
    "pagination": {
      "current_page": 1,
      "per_page": 25,
      "total": 347,
      "last_page": 14
    }
  }
}
```

#### Get Single Artist
```http
GET /api/v1/artists/{id}
```

**Path Parameters:**
- `id` (string): Artist ID or slug

**Include Relationships:**
```http
GET /api/v1/artists/the-beatles?include=albums,albums.tracks,taxonomies
```

#### Create Artist
```http
POST /api/v1/artists
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "New Artist",
  "bio": "Artist biography...",
  "country": "US",
  "formed_year": 2020,
  "is_active": true,
  "social_links": {
    "website": "https://newartist.com",
    "instagram": "@newartist"
  },
  "taxonomies": [
    {
      "taxonomy": "music-genres",
      "terms": ["Rock", "Alternative"]
    }
  ]
}
```

#### Update Artist
```http
PUT /api/v1/artists/{id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Updated Artist Name",
  "bio": "Updated biography..."
}
```

#### Delete Artist
```http
DELETE /api/v1/artists/{id}
Authorization: Bearer {token}
```

### Albums API

**Base Endpoint:** `/api/v1/albums`

#### List Albums
```http
GET /api/v1/albums?artist_id=1&include=artist,tracks
```

**Query Parameters:**
- `artist_id` (integer): Filter by artist
- `release_year` (integer): Filter by release year
- `genre` (array): Filter by genre taxonomy terms
- `search` (string): Search in album title
- `sort` (string): Sort field (title, release_date, tracks_count)

#### Get Album with Tracks
```http
GET /api/v1/albums/{id}?include=artist,tracks,tracks.mediaType
```

**Example Response:**
```json
{
  "data": {
    "id": 1,
    "public_id": "ALB001",
    "slug": "abbey-road",
    "title": "Abbey Road",
    "release_date": "1969-09-26",
    "total_duration": 2873000,
    "formatted_duration": "47:53",
    "artwork_url": "https://cdn.chinook.com/albums/abbey-road.jpg",
    "artist": {
      "id": 1,
      "name": "The Beatles",
      "slug": "the-beatles"
    },
    "tracks": [
      {
        "id": 1,
        "name": "Come Together",
        "track_number": 1,
        "duration": 259000,
        "unit_price": 0.99,
        "media_type": {
          "name": "MPEG audio file"
        }
      }
    ],
    "tracks_count": 17,
    "created_at": "2025-01-15T10:30:00Z"
  }
}
```

### Tracks API

**Base Endpoint:** `/api/v1/tracks`

#### Advanced Track Search
```http
GET /api/v1/tracks/search
Content-Type: application/json

{
  "query": {
    "name": "Yesterday",
    "artist": "Beatles",
    "album": "Help",
    "composer": "Lennon"
  },
  "filters": {
    "genres": ["Rock", "Pop"],
    "moods": ["Melancholic"],
    "duration": {
      "min": 120,
      "max": 300
    },
    "price": {
      "min": 0.50,
      "max": 1.50
    },
    "release_year": {
      "from": 1960,
      "to": 1970
    }
  },
  "sort": {
    "field": "relevance",
    "order": "desc"
  },
  "pagination": {
    "page": 1,
    "per_page": 50
  }
}
```

### Customers API

**Base Endpoint:** `/api/v1/customers`

#### List Customers
```http
GET /api/v1/customers?include=supportRep,invoices
```

**Query Parameters:**
- `support_rep_id` (integer): Filter by support representative
- `country` (string): Filter by country
- `company` (string): Filter by company
- `search` (string): Search in name, email, company
- `has_orders` (boolean): Filter customers with/without orders

**Example Response:**
```json
{
  "data": [
    {
      "id": 1,
      "public_id": "CUST001",
      "slug": "john-doe",
      "first_name": "John",
      "last_name": "Doe",
      "email": "john.doe@example.com",
      "phone": "555-***-**12",
      "company": "Acme Corp",
      "address": "123 Main St",
      "city": "New York",
      "state": "NY",
      "country": "USA",
      "postal_code": "10001",
      "support_rep": {
        "id": 3,
        "name": "Jane Smith",
        "email": "jane.smith@chinook.com"
      },
      "total_spent": 45.99,
      "orders_count": 5,
      "last_order_date": "2025-07-15T14:30:00Z",
      "created_at": "2025-01-10T09:15:00Z"
    }
  ]
}
```

#### Create Customer
```http
POST /api/v1/customers
Authorization: Bearer {token}
Content-Type: application/json

{
  "first_name": "Alice",
  "last_name": "Johnson",
  "email": "alice.johnson@example.com",
  "phone": "555-0123",
  "company": "Tech Solutions Inc",
  "address": "456 Tech Ave",
  "city": "San Francisco",
  "state": "CA",
  "country": "USA",
  "postal_code": "94105",
  "support_rep_id": 3
}
```

### Employees API

**Base Endpoint:** `/api/v1/employees`

#### List Employees
```http
GET /api/v1/employees?include=manager,subordinates,customers
```

**Query Parameters:**
- `department` (string): Filter by department
- `reports_to` (integer): Filter by manager
- `is_active` (boolean): Filter by active status
- `hire_date_from` (date): Filter by hire date range
- `hire_date_to` (date): Filter by hire date range

#### Employee Hierarchy
```http
GET /api/v1/employees/{id}/hierarchy
```

**Response:**
```json
{
  "data": {
    "employee": {
      "id": 2,
      "name": "Nancy Edwards",
      "title": "Sales Manager",
      "department": "Sales"
    },
    "manager": {
      "id": 1,
      "name": "Andrew Adams",
      "title": "General Manager"
    },
    "subordinates": [
      {
        "id": 3,
        "name": "Jane Peacock",
        "title": "Sales Support Agent",
        "customers_count": 21
      }
    ],
    "reporting_chain": [
      {"id": 2, "name": "Nancy Edwards", "level": 0},
      {"id": 1, "name": "Andrew Adams", "level": 1}
    ]
  }
}
```

### Invoices API

**Base Endpoint:** `/api/v1/invoices`

#### List Invoices
```http
GET /api/v1/invoices?include=customer,invoiceLines.track
```

**Query Parameters:**
- `customer_id` (integer): Filter by customer
- `payment_status` (string): Filter by payment status
- `date_from` (date): Filter by invoice date range
- `date_to` (date): Filter by invoice date range
- `min_total` (decimal): Filter by minimum total
- `max_total` (decimal): Filter by maximum total

#### Invoice with Line Items
```http
GET /api/v1/invoices/{id}?include=customer,invoiceLines.track.album.artist
```

**Response:**
```json
{
  "data": {
    "id": 1,
    "public_id": "INV-2025-000001",
    "invoice_date": "2025-07-18T10:30:00Z",
    "customer": {
      "id": 1,
      "name": "John Doe",
      "email": "john.doe@example.com"
    },
    "billing_address": "123 Main St",
    "billing_city": "New York",
    "billing_country": "USA",
    "subtotal": 8.91,
    "tax_rate": 8.25,
    "tax_amount": 0.74,
    "total": 9.65,
    "payment_status": "paid",
    "payment_method": "credit_card",
    "payment_date": "2025-07-18T10:35:00Z",
    "invoice_lines": [
      {
        "id": 1,
        "track": {
          "id": 1,
          "name": "For Those About To Rock",
          "album": {
            "title": "For Those About To Rock We Salute You",
            "artist": {
              "name": "AC/DC"
            }
          }
        },
        "quantity": 1,
        "unit_price": 0.99,
        "line_total": 0.99
      }
    ],
    "lines_count": 9,
    "created_at": "2025-07-18T10:30:00Z"
  }
}
```

#### Process Payment
```http
POST /api/v1/invoices/{id}/payment
Authorization: Bearer {token}
Content-Type: application/json

{
  "payment_method": "credit_card",
  "payment_reference": "ch_1234567890",
  "amount": 9.65,
  "currency": "USD"
}
```

### Playlists API

**Base Endpoint:** `/api/v1/playlists`

#### List Playlists
```http
GET /api/v1/playlists?include=tracks.album.artist
```

#### Create Playlist
```http
POST /api/v1/playlists
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "My Favorite Rock Songs",
  "description": "A collection of classic rock tracks",
  "is_public": true,
  "track_ids": [1, 5, 12, 23, 45]
}
```

#### Add Tracks to Playlist
```http
POST /api/v1/playlists/{id}/tracks
Authorization: Bearer {token}
Content-Type: application/json

{
  "track_ids": [67, 89, 123],
  "position": "end"
}
```

#### Reorder Playlist Tracks
```http
PUT /api/v1/playlists/{id}/tracks/reorder
Authorization: Bearer {token}
Content-Type: application/json

{
  "track_orders": [
    {"track_id": 1, "position": 1},
    {"track_id": 5, "position": 2},
    {"track_id": 12, "position": 3}
  ]
}
```

## Error Handling

### Standard Error Response Format

```json
{
  "error": {
    "type": "validation_error",
    "message": "The given data was invalid.",
    "details": {
      "email": ["The email field is required."],
      "password": ["The password must be at least 8 characters."]
    },
    "code": "VALIDATION_FAILED",
    "timestamp": "2025-07-18T10:30:00Z",
    "request_id": "req_abc123def456"
  }
}
```

### HTTP Status Codes

| Code | Meaning | Usage |
|------|---------|-------|
| **200** | OK | Successful GET, PUT, PATCH requests |
| **201** | Created | Successful POST requests |
| **204** | No Content | Successful DELETE requests |
| **400** | Bad Request | Invalid request format or parameters |
| **401** | Unauthorized | Missing or invalid authentication |
| **403** | Forbidden | Valid authentication but insufficient permissions |
| **404** | Not Found | Resource does not exist |
| **422** | Unprocessable Entity | Validation errors |
| **429** | Too Many Requests | Rate limit exceeded |
| **500** | Internal Server Error | Server-side errors |

### Error Types

```php
<?php
// app/Exceptions/ApiException.php

namespace App\Exceptions;

use Exception;
use Illuminate\Http\JsonResponse;

class ApiException extends Exception
{
    public const VALIDATION_ERROR = 'validation_error';
    public const AUTHENTICATION_ERROR = 'authentication_error';
    public const AUTHORIZATION_ERROR = 'authorization_error';
    public const NOT_FOUND_ERROR = 'not_found_error';
    public const RATE_LIMIT_ERROR = 'rate_limit_error';
    public const SERVER_ERROR = 'server_error';

    protected string $type;
    protected array $details;
    protected string $errorCode;

    public function __construct(
        string $message,
        string $type = self::SERVER_ERROR,
        array $details = [],
        string $errorCode = 'UNKNOWN_ERROR',
        int $code = 500,
        ?Exception $previous = null
    ) {
        parent::__construct($message, $code, $previous);
        $this->type = $type;
        $this->details = $details;
        $this->errorCode = $errorCode;
    }

    public function render(): JsonResponse
    {
        return response()->json([
            'error' => [
                'type' => $this->type,
                'message' => $this->getMessage(),
                'details' => $this->details,
                'code' => $this->errorCode,
                'timestamp' => now()->toISOString(),
                'request_id' => request()->header('X-Request-ID', 'req_' . uniqid()),
            ]
        ], $this->getCode());
    }
}
```

## Rate Limiting

### Rate Limit Configuration

```php
<?php
// config/rate-limiting.php

return [
    'api' => [
        'guest' => [
            'requests' => 60,
            'per_minute' => 1,
        ],
        'authenticated' => [
            'requests' => 1000,
            'per_minute' => 1,
        ],
        'premium' => [
            'requests' => 5000,
            'per_minute' => 1,
        ],
    ],

    'endpoints' => [
        'search' => [
            'requests' => 100,
            'per_minute' => 1,
        ],
        'upload' => [
            'requests' => 10,
            'per_minute' => 1,
        ],
        'export' => [
            'requests' => 5,
            'per_minute' => 1,
        ],
    ],
];
```

### Rate Limit Headers

All API responses include rate limiting headers:

```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1642694400
Retry-After: 60
```

### Rate Limit Exceeded Response

```json
{
  "error": {
    "type": "rate_limit_error",
    "message": "Too many requests. Please try again later.",
    "code": "RATE_LIMIT_EXCEEDED",
    "retry_after": 60,
    "limit": 1000,
    "remaining": 0,
    "reset_at": "2025-07-18T11:00:00Z"
  }
}
```

## Pagination

### Cursor-Based Pagination

For optimal performance with large datasets, the API uses cursor-based pagination:

```http
GET /api/v1/tracks?cursor=eyJpZCI6MTAwfQ&per_page=25
```

**Response:**
```json
{
  "data": [...],
  "meta": {
    "per_page": 25,
    "next_cursor": "eyJpZCI6MTI1fQ",
    "prev_cursor": "eyJpZCI6NzV9",
    "has_more": true
  },
  "links": {
    "next": "https://api.chinook.example.com/v1/tracks?cursor=eyJpZCI6MTI1fQ&per_page=25",
    "prev": "https://api.chinook.example.com/v1/tracks?cursor=eyJpZCI6NzV9&per_page=25"
  }
}
```

### Offset-Based Pagination

For simpler use cases, traditional offset pagination is also supported:

```http
GET /api/v1/artists?page=2&per_page=50
```

**Response:**
```json
{
  "data": [...],
  "meta": {
    "current_page": 2,
    "per_page": 50,
    "total": 347,
    "last_page": 7,
    "from": 51,
    "to": 100
  },
  "links": {
    "first": "https://api.chinook.example.com/v1/artists?page=1",
    "last": "https://api.chinook.example.com/v1/artists?page=7",
    "prev": "https://api.chinook.example.com/v1/artists?page=1",
    "next": "https://api.chinook.example.com/v1/artists?page=3"
  }
}
```

## Filtering and Searching

### Advanced Filtering

The API supports complex filtering with multiple operators:

```http
GET /api/v1/tracks?filter[unit_price][gte]=0.99&filter[unit_price][lte]=1.99&filter[milliseconds][gte]=180000
```

**Supported Operators:**
- `eq` - Equal to
- `ne` - Not equal to
- `gt` - Greater than
- `gte` - Greater than or equal to
- `lt` - Less than
- `lte` - Less than or equal to
- `in` - In array
- `nin` - Not in array
- `like` - Like (partial match)
- `ilike` - Case-insensitive like

### Full-Text Search

```http
POST /api/v1/search
Content-Type: application/json

{
  "query": "rock music",
  "filters": {
    "type": ["track", "album", "artist"],
    "genres": ["Rock", "Hard Rock"],
    "release_year": {
      "from": 1970,
      "to": 1990
    }
  },
  "sort": {
    "field": "relevance",
    "order": "desc"
  },
  "pagination": {
    "per_page": 20,
    "page": 1
  }
}
```

**Response:**
```json
{
  "data": {
    "tracks": [...],
    "albums": [...],
    "artists": [...]
  },
  "meta": {
    "total_results": 156,
    "search_time": "0.045s",
    "query": "rock music",
    "suggestions": ["rock and roll", "classic rock", "punk rock"]
  }
}
```

### Taxonomy-Based Filtering

```http
GET /api/v1/tracks?taxonomy[music-genres]=Rock,Blues&taxonomy[moods]=Energetic&taxonomy[decades]=1980s
```

## Integration Examples

### JavaScript/Node.js SDK

```javascript
// npm install @chinook/api-client

import { ChinookAPI } from '@chinook/api-client';

const api = new ChinookAPI({
  baseURL: 'https://api.chinook.example.com/v1',
  apiKey: 'your-api-key-here'
});

// Authenticate
const { token } = await api.auth.login({
  email: 'user@example.com',
  password: 'password',
  deviceName: 'My App'
});

// Set authentication token
api.setToken(token);

// Get artists with albums
const artists = await api.artists.list({
  include: ['albums'],
  filter: { country: 'USA' },
  sort: 'name',
  perPage: 50
});

// Search tracks
const searchResults = await api.search.tracks({
  query: 'rock music',
  filters: {
    genres: ['Rock'],
    priceRange: { min: 0.99, max: 1.99 }
  }
});

// Create playlist
const playlist = await api.playlists.create({
  name: 'My Rock Playlist',
  description: 'Best rock songs',
  trackIds: [1, 5, 12, 23]
});

// Handle errors
try {
  const customer = await api.customers.get(999);
} catch (error) {
  if (error.type === 'not_found_error') {
    console.log('Customer not found');
  }
}
```

### Python SDK

```python
# pip install chinook-api-client

from chinook_api import ChinookAPI
from chinook_api.exceptions import NotFoundError, ValidationError

# Initialize client
api = ChinookAPI(
    base_url='https://api.chinook.example.com/v1',
    api_key='your-api-key-here'
)

# Authenticate
auth_response = api.auth.login(
    email='user@example.com',
    password='password',
    device_name='Python App'
)
api.set_token(auth_response['token'])

# Get tracks with relationships
tracks = api.tracks.list(
    include=['album.artist', 'mediaType'],
    filter={'unit_price__gte': 0.99},
    sort='-created_at',
    per_page=100
)

# Advanced search
search_results = api.search.advanced({
    'track_name': 'Yesterday',
    'artist_name': 'Beatles',
    'filters': {
        'genres': ['Rock', 'Pop'],
        'duration': {'min': 120, 'max': 300}
    }
})

# Create customer
try:
    customer = api.customers.create({
        'first_name': 'John',
        'last_name': 'Doe',
        'email': 'john.doe@example.com',
        'country': 'USA'
    })
except ValidationError as e:
    print(f"Validation failed: {e.details}")

# Pagination
for page in api.artists.paginate(per_page=50):
    for artist in page:
        print(f"Artist: {artist['name']}")
```

### PHP SDK

```php
<?php
// composer require chinook/api-client

use Chinook\ApiClient\ChinookAPI;
use Chinook\ApiClient\Exceptions\NotFoundError;
use Chinook\ApiClient\Exceptions\ValidationError;

$api = new ChinookAPI([
    'base_url' => 'https://api.chinook.example.com/v1',
    'api_key' => 'your-api-key-here'
]);

// Authenticate
$authResponse = $api->auth()->login([
    'email' => 'user@example.com',
    'password' => 'password',
    'device_name' => 'PHP App'
]);
$api->setToken($authResponse['token']);

// Get albums with tracks
$albums = $api->albums()->list([
    'include' => ['artist', 'tracks'],
    'filter' => ['release_year' => 2023],
    'sort' => 'title',
    'per_page' => 25
]);

// Create invoice
try {
    $invoice = $api->invoices()->create([
        'customer_id' => 1,
        'invoice_date' => '2025-07-18',
        'line_items' => [
            ['track_id' => 1, 'quantity' => 1, 'unit_price' => 0.99],
            ['track_id' => 5, 'quantity' => 2, 'unit_price' => 0.99]
        ]
    ]);
} catch (ValidationError $e) {
    echo "Validation failed: " . json_encode($e->getDetails());
}

// Process payment
$payment = $api->invoices()->processPayment($invoice['id'], [
    'payment_method' => 'credit_card',
    'amount' => $invoice['total']
]);
```

## SDK and Client Libraries

### Official SDKs

| Language | Package | Installation | Documentation |
|----------|---------|--------------|---------------|
| **JavaScript/Node.js** | `@chinook/api-client` | `npm install @chinook/api-client` | [JS Docs](https://docs.chinook.com/sdk/javascript) |
| **Python** | `chinook-api-client` | `pip install chinook-api-client` | [Python Docs](https://docs.chinook.com/sdk/python) |
| **PHP** | `chinook/api-client` | `composer require chinook/api-client` | [PHP Docs](https://docs.chinook.com/sdk/php) |
| **Ruby** | `chinook-api` | `gem install chinook-api` | [Ruby Docs](https://docs.chinook.com/sdk/ruby) |
| **Go** | `github.com/chinook/go-client` | `go get github.com/chinook/go-client` | [Go Docs](https://docs.chinook.com/sdk/go) |

### Community SDKs

| Language | Package | Maintainer | Status |
|----------|---------|------------|--------|
| **C#/.NET** | `Chinook.ApiClient` | Community | ✅ Active |
| **Java** | `chinook-java-client` | Community | ✅ Active |
| **Swift** | `ChinookAPI` | Community | 🟡 Beta |
| **Kotlin** | `chinook-kotlin` | Community | 🟡 Beta |

### Postman Collection

Import our comprehensive Postman collection for easy API testing:

```bash
# Download collection
curl -o chinook-api.postman_collection.json \
  https://api.chinook.example.com/postman/collection

# Import environment
curl -o chinook-api.postman_environment.json \
  https://api.chinook.example.com/postman/environment
```

### OpenAPI/Swagger Specification

Access the complete OpenAPI 3.0 specification:

- **Interactive Documentation:** [https://api.chinook.example.com/docs](https://api.chinook.example.com/docs)
- **OpenAPI JSON:** [https://api.chinook.example.com/openapi.json](https://api.chinook.example.com/openapi.json)
- **OpenAPI YAML:** [https://api.chinook.example.com/openapi.yaml](https://api.chinook.example.com/openapi.yaml)

---

## API Testing Examples

### Automated Testing with Jest

```javascript
// tests/api/artists.test.js
import { ChinookAPI } from '@chinook/api-client';

describe('Artists API', () => {
  let api;

  beforeAll(async () => {
    api = new ChinookAPI({
      baseURL: process.env.API_BASE_URL,
      apiKey: process.env.API_KEY
    });

    const { token } = await api.auth.login({
      email: process.env.TEST_EMAIL,
      password: process.env.TEST_PASSWORD,
      deviceName: 'Test Suite'
    });

    api.setToken(token);
  });

  test('should list artists with pagination', async () => {
    const response = await api.artists.list({
      perPage: 10,
      page: 1
    });

    expect(response.data).toHaveLength(10);
    expect(response.meta.current_page).toBe(1);
    expect(response.meta.per_page).toBe(10);
  });

  test('should create and delete artist', async () => {
    const artistData = {
      name: 'Test Artist',
      bio: 'Test biography',
      country: 'USA'
    };

    const created = await api.artists.create(artistData);
    expect(created.name).toBe(artistData.name);

    await api.artists.delete(created.id);

    await expect(api.artists.get(created.id))
      .rejects.toThrow('not_found_error');
  });
});
```

This completes the comprehensive API documentation with full endpoint coverage, SDKs, and testing examples.
