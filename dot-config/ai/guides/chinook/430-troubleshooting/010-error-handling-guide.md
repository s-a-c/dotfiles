# Error Handling Guide

**Version:** 1.0  
**Created:** 2025-07-16  
**Last Updated:** 2025-07-16  
**Scope:** Comprehensive error handling patterns for Chinook project

## Table of Contents

1. [Overview](#1-overview)
2. [Exception Handling Patterns](#2-exception-handling-patterns)
3. [Model Error Handling](#3-model-error-handling)
4. [API Error Responses](#4-api-error-responses)
5. [Filament Error Handling](#5-filament-error-handling)
6. [Logging and Monitoring](#6-logging-and-monitoring)

## 1. Overview

This guide establishes consistent error handling patterns across the Chinook project, ensuring graceful degradation and proper user feedback in all error scenarios.

### 1.1 Error Handling Principles

- **Graceful Degradation:** Application continues functioning when possible
- **User-Friendly Messages:** Clear, actionable error messages for users
- **Comprehensive Logging:** Detailed error information for developers
- **Security Awareness:** No sensitive information in user-facing errors

### 1.2 Error Categories

- **Validation Errors:** User input validation failures
- **Business Logic Errors:** Domain-specific rule violations
- **System Errors:** Database, network, or infrastructure failures
- **Authentication/Authorization Errors:** Access control violations

## 2. Exception Handling Patterns

### 2.1 Custom Exception Classes

```php
<?php

namespace App\Exceptions\Chinook;

use Exception;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Base exception for all Chinook-specific errors
 */
abstract class ChinookException extends Exception
{
    protected string $userMessage;
    protected array $context = [];

    public function __construct(
        string $message = '',
        string $userMessage = '',
        array $context = [],
        int $code = 0,
        ?Exception $previous = null
    ) {
        parent::__construct($message, $code, $previous);
        $this->userMessage = $userMessage ?: 'An error occurred. Please try again.';
        $this->context = $context;
    }

    /**
     * Get user-friendly error message
     */
    public function getUserMessage(): string
    {
        return $this->userMessage;
    }

    /**
     * Get error context for logging
     */
    public function getContext(): array
    {
        return $this->context;
    }

    /**
     * Render exception for HTTP response
     */
    public function render(Request $request): JsonResponse
    {
        if ($request->expectsJson()) {
            return response()->json([
                'error' => [
                    'message' => $this->getUserMessage(),
                    'code' => $this->getCode(),
                    'type' => class_basename($this),
                ],
            ], $this->getStatusCode());
        }

        return response()->json(['error' => 'An error occurred'], 500);
    }

    /**
     * Get HTTP status code for this exception
     */
    abstract protected function getStatusCode(): int;
}

/**
 * Artist-specific exceptions
 */
class ArtistNotFoundException extends ChinookException
{
    public function __construct(string $identifier, ?Exception $previous = null)
    {
        parent::__construct(
            message: "Artist not found: {$identifier}",
            userMessage: 'The requested artist could not be found.',
            context: ['identifier' => $identifier],
            code: 404,
            previous: $previous
        );
    }

    protected function getStatusCode(): int
    {
        return 404;
    }
}

class ArtistValidationException extends ChinookException
{
    public function __construct(array $errors, ?Exception $previous = null)
    {
        parent::__construct(
            message: 'Artist validation failed',
            userMessage: 'Please check your input and try again.',
            context: ['validation_errors' => $errors],
            code: 422,
            previous: $previous
        );
    }

    protected function getStatusCode(): int
    {
        return 422;
    }
}

class ArtistServiceException extends ChinookException
{
    public function __construct(string $operation, ?Exception $previous = null)
    {
        parent::__construct(
            message: "Artist service error during: {$operation}",
            userMessage: 'Unable to complete the requested operation. Please try again later.',
            context: ['operation' => $operation],
            code: 500,
            previous: $previous
        );
    }

    protected function getStatusCode(): int
    {
        return 500;
    }
}
```

### 2.2 Global Exception Handler

```php
<?php

namespace App\Exceptions;

use App\Exceptions\Chinook\ChinookException;
use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;
use Throwable;

class Handler extends ExceptionHandler
{
    /**
     * The list of the inputs that are never flashed to the session on validation exceptions.
     */
    protected $dontFlash = [
        'current_password',
        'password',
        'password_confirmation',
    ];

    /**
     * Register the exception handling callbacks for the application.
     */
    public function register(): void
    {
        $this->reportable(function (Throwable $e) {
            // Custom logging for Chinook exceptions
            if ($e instanceof ChinookException) {
                Log::error('Chinook Exception: ' . $e->getMessage(), [
                    'exception' => get_class($e),
                    'context' => $e->getContext(),
                    'user_id' => auth()->id(),
                    'request_url' => request()->fullUrl(),
                    'user_agent' => request()->userAgent(),
                    'ip_address' => request()->ip(),
                ]);
            }
        });

        $this->renderable(function (ChinookException $e, Request $request) {
            return $e->render($request);
        });
    }

    /**
     * Render an exception into an HTTP response.
     */
    public function render($request, Throwable $e): Response
    {
        // Handle Chinook exceptions
        if ($e instanceof ChinookException) {
            return $e->render($request);
        }

        // Handle validation exceptions for API requests
        if ($request->expectsJson() && $e instanceof \Illuminate\Validation\ValidationException) {
            return response()->json([
                'error' => [
                    'message' => 'Validation failed',
                    'errors' => $e->errors(),
                ],
            ], 422);
        }

        return parent::render($request, $e);
    }
}
```

## 3. Model Error Handling

### 3.1 Enhanced Artist Model with Error Handling

```php
<?php

namespace App\Models\Chinook;

use App\Exceptions\Chinook\ArtistNotFoundException;
use App\Exceptions\Chinook\ArtistServiceException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Facades\Log;
use Exception;

class Artist extends BaseModel
{
    // ... existing code ...

    /**
     * Find artist by slug with proper error handling
     * 
     * @param string $slug
     * @return Artist
     * @throws ArtistNotFoundException
     */
    public static function findBySlugOrFail(string $slug): Artist
    {
        try {
            return static::where('slug', $slug)->firstOrFail();
        } catch (ModelNotFoundException $e) {
            throw new ArtistNotFoundException($slug, $e);
        }
    }

    /**
     * Get albums count with error handling
     * 
     * @return int
     */
    public function getAlbumsCount(): int
    {
        try {
            return Cache::remember(
                "artist_{$this->id}_albums_count",
                now()->addHour(),
                fn() => $this->albums()->count()
            );
        } catch (Exception $e) {
            Log::error('Failed to count artist albums', [
                'artist_id' => $this->id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            
            // Return 0 as graceful fallback
            return 0;
        }
    }

    /**
     * Update artist with validation and error handling
     * 
     * @param array $data
     * @return bool
     * @throws ArtistServiceException
     */
    public function updateSafely(array $data): bool
    {
        try {
            // Validate data
            $validated = validator($data, [
                'name' => 'sometimes|string|max:255',
                'bio' => 'sometimes|string|max:5000',
                'website' => 'sometimes|url|max:255',
                'country' => 'sometimes|string|max:100',
                'formed_year' => 'sometimes|integer|min:1900|max:' . date('Y'),
                'is_active' => 'sometimes|boolean',
            ])->validate();

            return $this->update($validated);
        } catch (\Illuminate\Validation\ValidationException $e) {
            throw new ArtistValidationException($e->errors(), $e);
        } catch (Exception $e) {
            Log::error('Failed to update artist', [
                'artist_id' => $this->id,
                'data' => $data,
                'error' => $e->getMessage(),
            ]);
            
            throw new ArtistServiceException('update', $e);
        }
    }

    /**
     * Delete artist with dependency checks
     * 
     * @return bool
     * @throws ArtistServiceException
     */
    public function deleteSafely(): bool
    {
        try {
            // Check for dependencies
            if ($this->albums()->exists()) {
                throw new ArtistServiceException(
                    'Cannot delete artist with existing albums'
                );
            }

            return $this->delete();
        } catch (Exception $e) {
            Log::error('Failed to delete artist', [
                'artist_id' => $this->id,
                'error' => $e->getMessage(),
            ]);
            
            throw new ArtistServiceException('delete', $e);
        }
    }
}
```

## 4. API Error Responses

### 4.1 Standardized API Error Format

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Chinook\Artist;
use App\Exceptions\Chinook\ArtistNotFoundException;
use App\Exceptions\Chinook\ArtistServiceException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ArtistController extends Controller
{
    /**
     * Display the specified artist
     * 
     * @param string $publicId
     * @return JsonResponse
     */
    public function show(string $publicId): JsonResponse
    {
        try {
            $artist = Artist::where('public_id', $publicId)->firstOrFail();
            
            return response()->json([
                'data' => [
                    'id' => $artist->id,
                    'public_id' => $artist->public_id,
                    'name' => $artist->name,
                    'slug' => $artist->slug,
                    'bio' => $artist->bio,
                    'country' => $artist->country,
                    'is_active' => $artist->is_active,
                    'albums_count' => $artist->getAlbumsCount(),
                    'created_at' => $artist->created_at,
                    'updated_at' => $artist->updated_at,
                ],
            ]);
        } catch (ModelNotFoundException $e) {
            throw new ArtistNotFoundException($publicId, $e);
        } catch (Exception $e) {
            throw new ArtistServiceException('retrieve', $e);
        }
    }

    /**
     * Update the specified artist
     * 
     * @param Request $request
     * @param string $publicId
     * @return JsonResponse
     */
    public function update(Request $request, string $publicId): JsonResponse
    {
        try {
            $artist = Artist::where('public_id', $publicId)->firstOrFail();
            
            $artist->updateSafely($request->all());
            
            return response()->json([
                'data' => [
                    'id' => $artist->id,
                    'public_id' => $artist->public_id,
                    'name' => $artist->name,
                    'updated_at' => $artist->updated_at,
                ],
                'message' => 'Artist updated successfully',
            ]);
        } catch (ModelNotFoundException $e) {
            throw new ArtistNotFoundException($publicId, $e);
        }
        // ArtistServiceException and ArtistValidationException 
        // are handled by the global exception handler
    }
}
```

---

## Navigation

- **Previous:** [Testing Implementation Examples](./testing/100-testing-implementation-examples.md)
- **Next:** [Troubleshooting Guide](./300-troubleshooting-guide.md)
- **Index:** [Chinook Documentation Index](./000-chinook-index.md)

## Related Documentation

- [Chinook Models Guide](./010-chinook-models-guide.md)
- [API Documentation](./api/000-api-index.md)

---

**Last Updated:** 2025-07-16  
**Maintainer:** Technical Documentation Team  
**Source:** [GitHub Repository](https://github.com/s-a-c/chinook)
