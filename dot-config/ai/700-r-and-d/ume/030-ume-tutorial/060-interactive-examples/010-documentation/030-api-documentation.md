# API Documentation for Interactive Examples

This document provides detailed information about the API endpoints used by the interactive examples system.

## Overview

The interactive examples system uses a REST API to execute code and return the results. The API is built using Laravel and follows RESTful principles.

## Base URL

All API endpoints are relative to the base URL of your Laravel application. For example, if your application is hosted at `https://example.com`, the full URL for the code execution endpoint would be `https://example.com/api/run-php-code`.

## Authentication

The API does not require authentication for public-facing endpoints. However, rate limiting is applied to prevent abuse.

## Rate Limiting

To prevent abuse, the API is rate-limited to 60 requests per minute per IP address. If you exceed this limit, you'll receive a 429 Too Many Requests response.

## Endpoints

### Execute PHP Code

Executes PHP code in a secure sandbox and returns the results.

```
POST /api/run-php-code
```

#### Request Parameters

| Parameter | Type   | Required | Description                                |
|-----------|--------|----------|--------------------------------------------|
| code      | string | Yes      | The PHP code to execute                    |
| language  | string | Yes      | The language of the code (only 'php' for now) |

#### Example Request

```json
{
  "code": "<?php echo \"Hello, World!\";",
  "language": "php"
}
```

#### Response Format

The API returns a JSON response with the following structure:

```json
{
  "success": true,
  "output": "Hello, World!"
}
```

Or in case of an error:

```json
{
  "success": false,
  "output": "Error: Undefined variable $undefinedVariable on line 1",
  "error": "Execution failed"
}
```

#### Response Codes

| Code | Description                                                  |
|------|--------------------------------------------------------------|
| 200  | Success (even if the code execution failed)                  |
| 400  | Bad Request (missing or invalid parameters)                  |
| 422  | Unprocessable Entity (validation errors)                     |
| 429  | Too Many Requests (rate limit exceeded)                      |
| 500  | Internal Server Error (server-side error)                    |

#### Error Handling

The API handles errors in the following ways:

1. **Validation Errors**: If the request parameters are invalid, the API returns a 422 Unprocessable Entity response with validation errors.
2. **Execution Errors**: If the code execution fails, the API returns a 200 OK response with `success: false` and an error message.
3. **Server Errors**: If there's a server error, the API returns a 500 Internal Server Error response.

### Health Check

Checks if the API is up and running.

```
GET /api/health
```

#### Response Format

```json
{
  "status": "ok"
}
```

## Security Measures

The API implements several security measures to prevent malicious code execution:

1. **Sandboxed Environment**: Code is executed in an isolated environment with limited access to system resources.
2. **Timeout Limits**: Execution is limited to 5 seconds to prevent infinite loops.
3. **Memory Limits**: Memory usage is limited to 128MB to prevent memory exhaustion.
4. **Disabled Functions**: Dangerous functions like `system`, `exec`, `shell_exec`, etc. are disabled.
5. **Input Validation**: All input is validated to ensure it meets the required format.

## Implementation Details

The API is implemented using Laravel's controller system. The main components are:

1. **CodeExecutionController**: Handles the API requests and responses.
2. **Sandbox Environment**: A secure environment for executing PHP code.
3. **Security Checks**: Validation and security checks to prevent malicious code execution.

## Example Usage

### JavaScript

```javascript
fetch('/api/run-php-code', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
    'Accept': 'application/json'
  },
  body: JSON.stringify({
    code: '<?php echo "Hello, World!";',
    language: 'php'
  })
})
.then(response => response.json())
.then(data => {
  if (data.success) {
    console.log('Output:', data.output);
  } else {
    console.error('Error:', data.output);
  }
})
.catch(error => {
  console.error('Fetch error:', error);
});
```

### PHP

```php
$response = Http::post('/api/run-php-code', [
    'code' => '<?php echo "Hello, World!";',
    'language' => 'php'
]);

if ($response->successful()) {
    $data = $response->json();
    if ($data['success']) {
        echo 'Output: ' . $data['output'];
    } else {
        echo 'Error: ' . $data['output'];
    }
} else {
    echo 'HTTP Error: ' . $response->status();
}
```

## Error Codes and Messages

| Error Code | Message                                      | Description                                           |
|------------|----------------------------------------------|-------------------------------------------------------|
| E001       | Missing required parameter: code             | The code parameter is missing                         |
| E002       | Missing required parameter: language         | The language parameter is missing                     |
| E003       | Unsupported language                         | The specified language is not supported               |
| E004       | Code execution timed out                     | The code took too long to execute                     |
| E005       | Memory limit exceeded                        | The code used too much memory                         |
| E006       | Dangerous function detected                  | The code contains a dangerous function                |
| E007       | Execution failed                             | The code execution failed for another reason          |
| E008       | Rate limit exceeded                          | Too many requests in a short period                   |

## Versioning

The API is currently at version 1.0. Future versions will be announced with appropriate deprecation notices for any breaking changes.

## Support

If you encounter any issues with the API, please open an issue on the GitHub repository or contact the development team.
