# PHP 8.4 Features - Exercise 3 Sample Answer

<link rel="stylesheet" href="../../assets/css/styles.css">
<link rel="stylesheet" href="../../assets/css/ume-docs-enhancements.css">
<link rel="stylesheet" href="../../assets/css/interactive-code.css">
<script src="../../assets/js/ume-docs-enhancements.js"></script>
<script src="../../assets/js/interactive-code.js"></script>

<ul class="breadcrumb-navigation">
    <li><a href="../../000-index.md">UME Tutorial</a></li>
    <li><a href="../000-index.md">UME Tutorial</a></li>
    <li><a href="./000-index.md">Sample Answers</a></li>
    <li><a href="./065-php84-features-exercise3.md">PHP 8.4 Features - Exercise 3</a></li>
</ul>

## Exercise 3: Controller with Array Find Functions

### Problem Statement

Create a controller method that uses `array_find()` to search for users with specific criteria, including finding users by role, active status, email domain, and name.

### Solution

#### UserController.php
```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class UserController extends Controller
{
    /**
     * Sample user data
     */
    private array $users = [
        [
            'id' => 1,
            'name' => 'John Doe',
            'email' => 'john.doe@example.com',
            'role' => 'admin',
            'active' => true,
        ],
        [
            'id' => 2,
            'name' => 'Jane Smith',
            'email' => 'jane.smith@company.org',
            'role' => 'user',
            'active' => true,
        ],
        [
            'id' => 3,
            'name' => 'Bob Johnson',
            'email' => 'bob.johnson@example.com',
            'role' => 'manager',
            'active' => false,
        ],
        [
            'id' => 4,
            'name' => 'Alice Brown',
            'email' => 'alice.brown@company.org',
            'role' => 'user',
            'active' => true,
        ],
        [
            'id' => 5,
            'name' => 'Charlie Wilson',
            'email' => 'charlie.wilson@example.com',
            'role' => 'admin',
            'active' => false,
        ],
    ];
    
    /**
     * Search for users based on criteria
     */
    public function search(Request $request): JsonResponse
    {
        // Get search parameters from request
        $role = $request->input('role');
        $active = $request->has('active') ? (bool) $request->input('active') : null;
        $emailDomain = $request->input('email_domain');
        $nameContains = $request->input('name_contains');
        
        // Build search function based on criteria
        $searchFunction = function ($user) use ($role, $active, $emailDomain, $nameContains) {
            // Check role if specified
            if ($role !== null && $user['role'] !== $role) {
                return false;
            }
            
            // Check active status if specified
            if ($active !== null && $user['active'] !== $active) {
                return false;
            }
            
            // Check email domain if specified
            if ($emailDomain !== null) {
                $parts = explode('@', $user['email']);
                $domain = $parts[1] ?? '';
                if ($domain !== $emailDomain) {
                    return false;
                }
            }
            
            // Check name if specified
            if ($nameContains !== null && !str_contains(strtolower($user['name']), strtolower($nameContains))) {
                return false;
            }
            
            // All criteria matched
            return true;
        };
        
        // Find the first matching user
        $user = array_find($this->users, $searchFunction);
        
        // Find the position of the user
        $position = array_find_key($this->users, $searchFunction);
        
        // Return the result
        if ($user) {
            return response()->json([
                'success' => true,
                'user' => $user,
                'position' => $position,
                'total_users' => count($this->users),
            ]);
        } else {
            return response()->json([
                'success' => false,
                'message' => 'No user found matching the criteria',
                'total_users' => count($this->users),
            ]);
        }
    }
    
    /**
     * Search for users by role
     */
    public function searchByRole(Request $request): JsonResponse
    {
        $role = $request->input('role');
        
        if (!$role) {
            return response()->json([
                'success' => false,
                'message' => 'Role parameter is required',
            ]);
        }
        
        $user = array_find($this->users, fn($user) => $user['role'] === $role);
        $position = array_find_key($this->users, fn($user) => $user['role'] === $role);
        
        return $this->buildResponse($user, $position);
    }
    
    /**
     * Search for users by active status
     */
    public function searchByActiveStatus(Request $request): JsonResponse
    {
        $active = (bool) $request->input('active', true);
        
        $user = array_find($this->users, fn($user) => $user['active'] === $active);
        $position = array_find_key($this->users, fn($user) => $user['active'] === $active);
        
        return $this->buildResponse($user, $position);
    }
    
    /**
     * Search for users by email domain
     */
    public function searchByEmailDomain(Request $request): JsonResponse
    {
        $domain = $request->input('domain');
        
        if (!$domain) {
            return response()->json([
                'success' => false,
                'message' => 'Domain parameter is required',
            ]);
        }
        
        $user = array_find($this->users, function ($user) use ($domain) {
            $parts = explode('@', $user['email']);
            return ($parts[1] ?? '') === $domain;
        });
        
        $position = array_find_key($this->users, function ($user) use ($domain) {
            $parts = explode('@', $user['email']);
            return ($parts[1] ?? '') === $domain;
        });
        
        return $this->buildResponse($user, $position);
    }
    
    /**
     * Search for users by name
     */
    public function searchByName(Request $request): JsonResponse
    {
        $name = $request->input('name');
        
        if (!$name) {
            return response()->json([
                'success' => false,
                'message' => 'Name parameter is required',
            ]);
        }
        
        $user = array_find(
            $this->users, 
            fn($user) => str_contains(strtolower($user['name']), strtolower($name))
        );
        
        $position = array_find_key(
            $this->users, 
            fn($user) => str_contains(strtolower($user['name']), strtolower($name))
        );
        
        return $this->buildResponse($user, $position);
    }
    
    /**
     * Build a standard response
     */
    private function buildResponse(?array $user, ?int $position): JsonResponse
    {
        if ($user) {
            return response()->json([
                'success' => true,
                'user' => $user,
                'position' => $position,
                'total_users' => count($this->users),
            ]);
        } else {
            return response()->json([
                'success' => false,
                'message' => 'No user found matching the criteria',
                'total_users' => count($this->users),
            ]);
        }
    }
}
```

### Usage Example

In a Laravel application, you would define routes for these controller methods:

```php
// routes/web.php or routes/api.php
Route::get('/users/search', [UserController::class, 'search']);
Route::get('/users/search/role', [UserController::class, 'searchByRole']);
Route::get('/users/search/active', [UserController::class, 'searchByActiveStatus']);
Route::get('/users/search/email-domain', [UserController::class, 'searchByEmailDomain']);
Route::get('/users/search/name', [UserController::class, 'searchByName']);
```

You could then make requests like:

```
GET /users/search?role=admin&active=1&email_domain=example.com&name_contains=john
GET /users/search/role?role=manager
GET /users/search/active?active=0
GET /users/search/email-domain?domain=company.org
GET /users/search/name?name=alice
```

### Example Responses

#### Successful search:
```json
{
    "success": true,
    "user": {
        "id": 1,
        "name": "John Doe",
        "email": "john.doe@example.com",
        "role": "admin",
        "active": true
    },
    "position": 0,
    "total_users": 5
}
```

#### No results:
```json
{
    "success": false,
    "message": "No user found matching the criteria",
    "total_users": 5
}
```

### Explanation

1. **Controller Structure**:
   - The `UserController` class has a main `search` method that handles multiple criteria.
   - It also has specialized methods for searching by specific criteria.
   - A private `buildResponse` method standardizes the response format.

2. **Array Find Functions**:
   - `array_find()` is used to find the first user matching the criteria.
   - `array_find_key()` is used to find the position of the user in the array.
   - Both functions use the same callback for consistency.

3. **Search Criteria**:
   - **Role**: Exact match on the user's role.
   - **Active Status**: Boolean comparison of the active flag.
   - **Email Domain**: Extracts the domain part of the email and compares it.
   - **Name Contains**: Case-insensitive partial match on the user's name.

4. **Response Format**:
   - Returns a JSON response with success status, user data, position, and total count.
   - Provides a clear error message when no user is found.

### Key Concepts

1. **Array Find Functions**: PHP 8.4's `array_find()` and `array_find_key()` provide a clean way to find elements in arrays.
2. **Callback Functions**: The search logic is encapsulated in callback functions.
3. **Request Handling**: The controller extracts search parameters from the request.
4. **Response Building**: The controller builds a standardized JSON response.
5. **Error Handling**: The controller handles the case when no user is found.

### Best Practices

1. **Separate Concerns**: Each search method focuses on a specific type of search.
2. **Reuse Code**: Common response building logic is extracted to a separate method.
3. **Validate Input**: Check that required parameters are provided.
4. **Consistent Response Format**: Use a consistent format for all responses.
5. **Clear Error Messages**: Provide clear error messages when something goes wrong.

### Variations

You could extend this solution in several ways:

1. **Database Integration**: Replace the in-memory array with database queries.
2. **Pagination**: Add support for paginating results.
3. **Sorting**: Add support for sorting results.
4. **Multiple Results**: Return all matching users instead of just the first one.
5. **Advanced Filtering**: Add support for more complex filtering options.
