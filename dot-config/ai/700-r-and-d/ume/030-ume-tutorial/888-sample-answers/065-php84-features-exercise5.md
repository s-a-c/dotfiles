# PHP 8.4 Features - Exercise 5 Sample Answer

<link rel="stylesheet" href="../../assets/css/styles.css">
<link rel="stylesheet" href="../../assets/css/ume-docs-enhancements.css">
<link rel="stylesheet" href="../../assets/css/interactive-code.css">
<script src="../../assets/js/ume-docs-enhancements.js"></script>
<script src="../../assets/js/interactive-code.js"></script>

<ul class="breadcrumb-navigation">
    <li><a href="../../000-index.md">UME Tutorial</a></li>
    <li><a href="../000-index.md">UME Tutorial</a></li>
    <li><a href="./000-index.md">Sample Answers</a></li>
    <li><a href="./065-php84-features-exercise5.md">PHP 8.4 Features - Exercise 5</a></li>
</ul>

## Exercise 5: Form Request with Property Hooks

### Problem Statement

Create a form request class that uses property hooks for data normalization before validation, including trimming whitespace, converting email addresses to lowercase, formatting phone numbers, and standardizing dates.

### Solution

#### UserRequest.php
```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Carbon\Carbon;
use InvalidArgumentException;

class UserRequest extends FormRequest
{
    private string $_name = '';
    private string $_email = '';
    private string $_phone = '';
    private string $_birthdate = '';
    private array $_address = [];
    private array $_preferences = [];
    
    /**
     * Determine if the user is authorized to make this request
     */
    public function authorize(): bool
    {
        return true;
    }
    
    /**
     * Get the validation rules that apply to the request
     */
    public function rules(): array
    {
        return [
            'name' => 'required|string|min:2|max:255',
            'email' => 'required|email|max:255',
            'phone' => 'required|string|min:10',
            'birthdate' => 'required|date|before:today',
            'address' => 'required|array',
            'address.street' => 'required|string|max:255',
            'address.city' => 'required|string|max:255',
            'address.state' => 'required|string|size:2',
            'address.zip' => 'required|string|min:5|max:10',
            'preferences' => 'sometimes|array',
            'preferences.newsletter' => 'sometimes|boolean',
            'preferences.marketing' => 'sometimes|boolean',
        ];
    }
    
    /**
     * Prepare the data for validation
     */
    protected function prepareForValidation(): void
    {
        // Set properties using hooks for normalization
        if ($this->has('name')) {
            $this->name = $this->input('name');
        }
        
        if ($this->has('email')) {
            $this->email = $this->input('email');
        }
        
        if ($this->has('phone')) {
            $this->phone = $this->input('phone');
        }
        
        if ($this->has('birthdate')) {
            $this->birthdate = $this->input('birthdate');
        }
        
        if ($this->has('address')) {
            $this->address = $this->input('address');
        }
        
        if ($this->has('preferences')) {
            $this->preferences = $this->input('preferences');
        }
        
        // Merge normalized data back into request
        $this->merge([
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'birthdate' => $this->birthdate,
            'address' => $this->address,
            'preferences' => $this->preferences,
        ]);
    }
    
    /**
     * Get hook for name property
     */
    #[Hook\Get]
    public function name(string $value): string
    {
        return $value;
    }
    
    /**
     * Set hook for name property
     * Trims whitespace and normalizes capitalization
     */
    #[Hook\Set]
    public function name(string $value): string
    {
        // Trim whitespace
        $value = trim($value);
        
        // Normalize capitalization (first letter of each word uppercase)
        return ucwords(strtolower($value));
    }
    
    /**
     * Get hook for email property
     */
    #[Hook\Get]
    public function email(string $value): string
    {
        return $value;
    }
    
    /**
     * Set hook for email property
     * Trims whitespace and converts to lowercase
     */
    #[Hook\Set]
    public function email(string $value): string
    {
        // Trim whitespace and convert to lowercase
        return strtolower(trim($value));
    }
    
    /**
     * Get hook for phone property
     */
    #[Hook\Get]
    public function phone(string $value): string
    {
        return $value;
    }
    
    /**
     * Set hook for phone property
     * Formats phone number consistently
     */
    #[Hook\Set]
    public function phone(string $value): string
    {
        // Remove all non-numeric characters
        $digits = preg_replace('/[^0-9]/', '', $value);
        
        // Ensure we have at least 10 digits
        if (strlen($digits) < 10) {
            return $value; // Return original value, validation will fail
        }
        
        // Format as (XXX) XXX-XXXX if 10 digits
        if (strlen($digits) === 10) {
            return sprintf('(%s) %s-%s',
                substr($digits, 0, 3),
                substr($digits, 3, 3),
                substr($digits, 6, 4)
            );
        }
        
        // Format as +X (XXX) XXX-XXXX if more than 10 digits
        return sprintf('+%s (%s) %s-%s',
            substr($digits, 0, strlen($digits) - 10),
            substr($digits, -10, 3),
            substr($digits, -7, 3),
            substr($digits, -4)
        );
    }
    
    /**
     * Get hook for birthdate property
     */
    #[Hook\Get]
    public function birthdate(string $value): string
    {
        return $value;
    }
    
    /**
     * Set hook for birthdate property
     * Converts date to standard format (Y-m-d)
     */
    #[Hook\Set]
    public function birthdate(string $value): string
    {
        // Trim whitespace
        $value = trim($value);
        
        try {
            // Parse date using Carbon
            $date = Carbon::parse($value);
            
            // Return in standard format
            return $date->format('Y-m-d');
        } catch (\Exception $e) {
            // If parsing fails, return original value (validation will fail)
            return $value;
        }
    }
    
    /**
     * Get hook for address property
     */
    #[Hook\Get]
    public function address(array $value): array
    {
        return $value;
    }
    
    /**
     * Set hook for address property
     * Normalizes address fields
     */
    #[Hook\Set]
    public function address(array $value): array
    {
        $normalized = [];
        
        // Normalize street
        if (isset($value['street'])) {
            $normalized['street'] = trim($value['street']);
        }
        
        // Normalize city (capitalize first letter of each word)
        if (isset($value['city'])) {
            $normalized['city'] = ucwords(strtolower(trim($value['city'])));
        }
        
        // Normalize state (uppercase)
        if (isset($value['state'])) {
            $normalized['state'] = strtoupper(trim($value['state']));
        }
        
        // Normalize zip (remove non-alphanumeric characters)
        if (isset($value['zip'])) {
            $normalized['zip'] = preg_replace('/[^a-zA-Z0-9]/', '', trim($value['zip']));
        }
        
        return array_merge($value, $normalized);
    }
    
    /**
     * Get hook for preferences property
     */
    #[Hook\Get]
    public function preferences(array $value): array
    {
        return $value;
    }
    
    /**
     * Set hook for preferences property
     * Converts preference values to booleans
     */
    #[Hook\Set]
    public function preferences(array $value): array
    {
        $normalized = [];
        
        // Convert newsletter preference to boolean
        if (isset($value['newsletter'])) {
            $normalized['newsletter'] = filter_var($value['newsletter'], FILTER_VALIDATE_BOOLEAN);
        }
        
        // Convert marketing preference to boolean
        if (isset($value['marketing'])) {
            $normalized['marketing'] = filter_var($value['marketing'], FILTER_VALIDATE_BOOLEAN);
        }
        
        return array_merge($value, $normalized);
    }
    
    /**
     * Get the normalized data as an array
     */
    public function normalizedData(): array
    {
        return [
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'birthdate' => $this->birthdate,
            'address' => $this->address,
            'preferences' => $this->preferences,
        ];
    }
}
```

#### UserController.php
```php
<?php

namespace App\Http\Controllers;

use App\Http\Requests\UserRequest;
use Illuminate\Http\JsonResponse;

class UserController extends Controller
{
    /**
     * Store a new user
     */
    public function store(UserRequest $request): JsonResponse
    {
        // The request has already been validated and normalized
        
        // Get the normalized data
        $normalizedData = $request->normalizedData();
        
        // In a real application, you would save the user to the database here
        // $user = User::create($normalizedData);
        
        // Return the normalized data
        return response()->json([
            'success' => true,
            'message' => 'User created successfully',
            'data' => $normalizedData,
        ]);
    }
}
```

### Usage Example

In a Laravel application, you would define a route for the controller method:

```php
// routes/web.php or routes/api.php
Route::post('/users', [UserController::class, 'store']);
```

You could then make a request like:

```json
{
    "name": "  john doe  ",
    "email": "  JOHN.DOE@EXAMPLE.COM  ",
    "phone": "123-456-7890",
    "birthdate": "01/15/1990",
    "address": {
        "street": "  123 Main St  ",
        "city": "  new YORK  ",
        "state": "ny",
        "zip": "10001-1234"
    },
    "preferences": {
        "newsletter": "yes",
        "marketing": "0"
    }
}
```

### Example Response

```json
{
    "success": true,
    "message": "User created successfully",
    "data": {
        "name": "John Doe",
        "email": "john.doe@example.com",
        "phone": "(123) 456-7890",
        "birthdate": "1990-01-15",
        "address": {
            "street": "123 Main St",
            "city": "New York",
            "state": "NY",
            "zip": "100011234"
        },
        "preferences": {
            "newsletter": true,
            "marketing": false
        }
    }
}
```

### Explanation

1. **Form Request Structure**:
   - The `UserRequest` class extends Laravel's `FormRequest` class.
   - It defines validation rules for all fields.
   - It uses property hooks to normalize data before validation.
   - It provides a method to get the normalized data.

2. **Property Hooks Implementation**:
   - Each property has its own set of hooks with specific normalization logic.
   - The hooks are applied in the `prepareForValidation` method.
   - The normalized data is merged back into the request.

3. **Data Normalization**:
   - **Name**: Trims whitespace and normalizes capitalization.
   - **Email**: Trims whitespace and converts to lowercase.
   - **Phone**: Formats phone numbers consistently.
   - **Birthdate**: Converts dates to a standard format.
   - **Address**: Normalizes each address field.
   - **Preferences**: Converts preference values to booleans.

4. **Controller Integration**:
   - The controller uses the form request for validation and normalization.
   - It gets the normalized data from the request.
   - It returns the normalized data in the response.

### Key Concepts

1. **Property Hooks**: PHP 8.4's property hooks provide a clean way to normalize data.
2. **Form Request Validation**: Laravel's form request validation ensures data is valid.
3. **Data Normalization**: Normalizing data before validation ensures consistent validation.
4. **Type Safety**: Type declarations in method signatures provide better type safety.
5. **Error Handling**: Laravel's validation system handles validation errors.

### Best Practices

1. **Normalize Early**: Normalize data before validation to ensure consistent validation.
2. **Use Type Hints**: Always use type hints for better type safety.
3. **Handle Edge Cases**: Handle edge cases gracefully, falling back to original values when normalization fails.
4. **Document Normalization**: Clearly document what normalization is being applied.
5. **Provide Access to Normalized Data**: Provide a method to get the normalized data.

### Variations

You could extend this solution in several ways:

1. **Custom Validation Rules**: Add custom validation rules that work with the normalized data.
2. **More Complex Normalization**: Add more complex normalization logic for specific fields.
3. **Localization Support**: Add support for different date formats based on locale.
4. **Custom Error Messages**: Add custom error messages for validation failures.
5. **Conditional Validation**: Add conditional validation rules based on other fields.
