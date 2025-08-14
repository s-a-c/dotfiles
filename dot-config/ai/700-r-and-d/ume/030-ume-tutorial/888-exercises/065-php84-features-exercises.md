# PHP 8.4 Features Exercises

<link rel="stylesheet" href="../../assets/css/styles.css">
<link rel="stylesheet" href="../../assets/css/ume-docs-enhancements.css">

<ul class="breadcrumb-navigation">
    <li><a href="../../000-index.md">UME Tutorial</a></li>
    <li><a href="../000-index.md">UME Tutorial</a></li>
    <li><a href="./000-index.md">Exercises</a></li>
    <li><a href="./065-php84-features-exercises.md">PHP 8.4 Features Exercises</a></li>
</ul>

## Exercise 1: Property Hooks for User Class

Create a `User` class that uses property hooks for validation and transformation of name, email, and age properties with the following requirements:

1. The `name` property should:
   - Be trimmed of whitespace
   - Be capitalized (first letter of each word uppercase)
   - Be at least 2 characters long
   - Throw an exception if empty or too short

2. The `email` property should:
   - Be trimmed of whitespace
   - Be converted to lowercase
   - Be validated as a valid email address
   - Throw an exception if invalid

3. The `age` property should:
   - Be validated to be between 18 and 120
   - Be converted to an integer
   - Throw an exception if outside the valid range

4. Create a method `toArray()` that returns all properties as an array

## Exercise 2: Service Provider with Class Instantiation Without Parentheses

Implement a service provider that registers services using class instantiation without parentheses:

1. Create the following classes:
   - `Logger` (no constructor parameters)
   - `UserRepository` (no constructor parameters)
   - `EmailService` (requires a Logger in the constructor)
   - `UserService` (requires both UserRepository and EmailService in the constructor)

2. Create a `ServiceProvider` class that:
   - Registers all services using the appropriate instantiation syntax
   - Uses class instantiation without parentheses where appropriate
   - Uses the correct syntax for classes with required constructor parameters

## Exercise 3: Controller with Array Find Functions

Create a controller method that uses `array_find()` to search for users with specific criteria:

1. Create a `UserController` class with a `search` method that:
   - Takes a `Request` object as a parameter
   - Uses `array_find()` to find the first user matching the search criteria
   - Uses `array_find_key()` to find the position of the user in the array
   - Returns both the user and their position

2. Implement the following search criteria:
   - Find users by role (admin, user, manager)
   - Find users by active status
   - Find users by email domain
   - Find users with a name containing a specific string

## Exercise 4: Performance Comparison

Compare the performance of `array_find()` with Laravel's `Collection::first()` method for different array sizes:

1. Create a benchmark script that:
   - Generates arrays of different sizes (100, 1,000, 10,000, 100,000 elements)
   - Measures the time it takes to find an element using `array_find()`
   - Measures the time it takes to find an element using `Collection::first()`
   - Compares the results and outputs them in a table

2. Test with different search conditions:
   - Simple condition (e.g., `id === 5000`)
   - Complex condition (e.g., `role === 'admin' && active && email.endsWith('@example.com')`)

## Exercise 5: Form Request with Property Hooks

Create a form request class that uses property hooks for data normalization before validation:

1. Create a `UserRequest` class that extends Laravel's `FormRequest` class
2. Add property hooks for normalizing input data:
   - Trim whitespace from string inputs
   - Convert email addresses to lowercase
   - Format phone numbers consistently
   - Convert dates to a standard format
3. Implement validation rules that work with the normalized data
4. Add a method to retrieve the normalized data as an array

## Submission Guidelines

- Create a separate PHP file for each exercise
- Include comments explaining your code
- Ensure all code follows PSR-12 coding standards
- Test your code to make sure it works as expected
- Submit your solutions as a ZIP file containing all PHP files
