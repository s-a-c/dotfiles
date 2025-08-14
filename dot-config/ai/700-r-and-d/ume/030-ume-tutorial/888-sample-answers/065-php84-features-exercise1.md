# PHP 8.4 Features - Exercise 1 Sample Answer

<link rel="stylesheet" href="../../assets/css/styles.css">
<link rel="stylesheet" href="../../assets/css/ume-docs-enhancements.css">
<link rel="stylesheet" href="../../assets/css/interactive-code.css">
<script src="../../assets/js/ume-docs-enhancements.js"></script>
<script src="../../assets/js/interactive-code.js"></script>

<ul class="breadcrumb-navigation">
    <li><a href="../../000-index.md">UME Tutorial</a></li>
    <li><a href="../000-index.md">UME Tutorial</a></li>
    <li><a href="./000-index.md">Sample Answers</a></li>
    <li><a href="./065-php84-features-exercise1.md">PHP 8.4 Features - Exercise 1</a></li>
</ul>

## Exercise 1: Property Hooks for User Class

### Problem Statement

Create a `User` class that uses property hooks for validation and transformation of name, email, and age properties with specific requirements for each property.

### Solution

```php
<?php

class User
{
    private string $_name = '';
    private string $_email = '';
    private int $_age = 0;
    
    /**
     * Get hook for name property
     * Returns the name with proper capitalization
     */
    #[Hook\Get]
    public function name(string $value): string
    {
        return ucwords($value);
    }
    
    /**
     * Set hook for name property
     * Validates and normalizes the name
     * 
     * @throws InvalidArgumentException If name is empty or too short
     */
    #[Hook\Set]
    public function name(string $value): string
    {
        $value = trim($value);
        
        if (empty($value)) {
            throw new InvalidArgumentException('Name cannot be empty');
        }
        
        if (strlen($value) < 2) {
            throw new InvalidArgumentException('Name must be at least 2 characters long');
        }
        
        return $value;
    }
    
    /**
     * Get hook for email property
     * Returns the email as is
     */
    #[Hook\Get]
    public function email(string $value): string
    {
        return $value;
    }
    
    /**
     * Set hook for email property
     * Validates and normalizes the email
     * 
     * @throws InvalidArgumentException If email is invalid
     */
    #[Hook\Set]
    public function email(string $value): string
    {
        $value = strtolower(trim($value));
        
        if (!filter_var($value, FILTER_VALIDATE_EMAIL)) {
            throw new InvalidArgumentException('Invalid email address');
        }
        
        return $value;
    }
    
    /**
     * Get hook for age property
     * Returns the age as is
     */
    #[Hook\Get]
    public function age(int $value): int
    {
        return $value;
    }
    
    /**
     * Set hook for age property
     * Validates and normalizes the age
     * 
     * @throws InvalidArgumentException If age is outside the valid range
     */
    #[Hook\Set]
    public function age(int|string $value): int
    {
        // Convert to integer if string
        $value = is_string($value) ? (int) $value : $value;
        
        if ($value < 18) {
            throw new InvalidArgumentException('Age must be at least 18');
        }
        
        if ($value > 120) {
            throw new InvalidArgumentException('Age must be at most 120');
        }
        
        return $value;
    }
    
    /**
     * Returns all properties as an array
     */
    public function toArray(): array
    {
        return [
            'name' => $this->name,
            'email' => $this->email,
            'age' => $this->age,
        ];
    }
}
```

### Usage Example

```php
// Create a new user
$user = new User();

try {
    // Set properties with validation and transformation
    $user->name = '  john doe  ';
    $user->email = '  John.Doe@Example.com  ';
    $user->age = '25';
    
    // Output the user data
    echo "User created successfully:\n";
    echo "Name: {$user->name}\n";
    echo "Email: {$user->email}\n";
    echo "Age: {$user->age}\n";
    
    // Get all properties as an array
    $userData = $user->toArray();
    echo "\nUser data as array:\n";
    print_r($userData);
    
    // Test validation errors
    echo "\nTesting validation errors:\n";
    
    try {
        $user->name = 'J';  // Too short
    } catch (InvalidArgumentException $e) {
        echo "Name error: {$e->getMessage()}\n";
    }
    
    try {
        $user->email = 'invalid-email';  // Invalid email
    } catch (InvalidArgumentException $e) {
        echo "Email error: {$e->getMessage()}\n";
    }
    
    try {
        $user->age = 15;  // Too young
    } catch (InvalidArgumentException $e) {
        echo "Age error: {$e->getMessage()}\n";
    }
    
    try {
        $user->age = 130;  // Too old
    } catch (InvalidArgumentException $e) {
        echo "Age error: {$e->getMessage()}\n";
    }
    
} catch (InvalidArgumentException $e) {
    echo "Error: {$e->getMessage()}\n";
}
```

### Expected Output

```
User created successfully:
Name: John Doe
Email: john.doe@example.com
Age: 25

User data as array:
Array
(
    [name] => John Doe
    [email] => john.doe@example.com
    [age] => 25
)

Testing validation errors:
Name error: Name must be at least 2 characters long
Email error: Invalid email address
Age error: Age must be at least 18
Age error: Age must be at most 120
```

### Explanation

1. **Property Hooks Implementation**:
   - We use `#[Hook\Get]` and `#[Hook\Set]` attributes to intercept property access and modification.
   - Each property has its own set of hooks with specific validation and transformation logic.

2. **Name Property**:
   - The set hook trims whitespace and validates the length.
   - The get hook capitalizes the first letter of each word using `ucwords()`.

3. **Email Property**:
   - The set hook trims whitespace, converts to lowercase, and validates the email format.
   - The get hook returns the email as is.

4. **Age Property**:
   - The set hook converts string values to integers and validates the range.
   - The get hook returns the age as is.

5. **toArray Method**:
   - Returns all properties as an associative array.
   - The property hooks are applied when accessing the properties.

6. **Error Handling**:
   - Each validation error throws an `InvalidArgumentException` with a descriptive message.
   - The example code demonstrates how to handle these exceptions.

### Key Concepts

1. **Property Hooks**: PHP 8.4's property hooks provide a clean way to intercept property access and modification.
2. **Type Safety**: We use type declarations in method signatures for better type safety.
3. **Validation**: Property hooks are ideal for validating data before it's stored.
4. **Transformation**: Property hooks can transform data on both get and set operations.
5. **Error Handling**: Throwing exceptions for validation errors provides clear feedback.

### Best Practices

1. **Use Private Backing Properties**: Store the actual data in private properties with a leading underscore.
2. **Document Your Hooks**: Add PHPDoc comments to explain what each hook does.
3. **Validate Early**: Perform validation in the set hook before storing the value.
4. **Transform Consistently**: Apply consistent transformations to ensure data integrity.
5. **Handle Exceptions**: Always catch and handle exceptions when setting properties.

### Variations

You could extend this solution in several ways:

1. **Additional Properties**: Add more properties with their own hooks.
2. **Custom Validation Rules**: Implement more complex validation rules.
3. **Database Integration**: Extend the class to work with a database.
4. **Serialization**: Implement `JsonSerializable` interface for JSON serialization.
5. **Immutability**: Create an immutable version where properties can only be set in the constructor.
