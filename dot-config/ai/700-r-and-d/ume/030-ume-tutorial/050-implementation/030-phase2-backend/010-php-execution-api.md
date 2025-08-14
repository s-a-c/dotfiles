# PHP Execution API

The PHP Execution API provides a secure way to execute PHP code snippets in a sandboxed environment. This API is used by the interactive code examples in the UME tutorial documentation.

## API Endpoint

```
POST /api/run-php-code
```

## Request Parameters

| Parameter | Type   | Required | Description                                |
|-----------|--------|----------|--------------------------------------------|
| code      | string | Yes      | The PHP code to execute                    |
| language  | string | Yes      | The language of the code (only 'php' for now) |

## Response Format

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

## Security Measures

The PHP Execution API implements several security measures to prevent malicious code execution:

1. **Sandboxed Environment**: Code is executed in an isolated environment with limited access to system resources.
2. **Timeout Limits**: Execution is limited to 5 seconds to prevent infinite loops.
3. **Memory Limits**: Memory usage is limited to 128MB to prevent memory exhaustion.
4. **Disabled Functions**: Dangerous functions like `system`, `exec`, `shell_exec`, etc. are disabled.
5. **File System Restrictions**: Access to the file system is restricted to the sandbox directory.
6. **Input Validation**: All input is validated to ensure it meets the required format.

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

## Error Handling

The API handles errors in the following ways:

1. **Validation Errors**: If the request parameters are invalid, the API returns a 422 Unprocessable Entity response with validation errors.
2. **Execution Errors**: If the code execution fails, the API returns a 200 OK response with `success: false` and an error message.
3. **Server Errors**: If there's a server error, the API returns a 500 Internal Server Error response.

## Rate Limiting

To prevent abuse, the API is rate-limited to 60 requests per minute per IP address. If you exceed this limit, you'll receive a 429 Too Many Requests response.

## Implementation Details

The PHP Execution API is implemented using Laravel's controller system. The main components are:

1. **CodeExecutionController**: Handles the API requests and responses.
2. **Sandbox Environment**: A secure environment for executing PHP code.
3. **Security Checks**: Validation and security checks to prevent malicious code execution.

For more details, see the [CodeExecutionController implementation](https://github.com/your-repo/app/Http/Controllers/Api/CodeExecutionController.php).
