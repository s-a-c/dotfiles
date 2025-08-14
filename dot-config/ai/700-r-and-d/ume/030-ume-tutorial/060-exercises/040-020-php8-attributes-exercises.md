# PHP 8 Attributes Exercises

<link rel="stylesheet" href="../assets/css/styles.css">

These exercises are designed to test your understanding of PHP 8 attributes and how they're used in the UME tutorial. Each set contains questions and practical exercises.

## Set 1: Understanding PHP 8 Attributes

### Questions

1. **What are PHP 8 attributes?**
   - A) A type of variable declaration
   - B) A way to add metadata to classes, methods, properties, and other code elements
   - C) A replacement for PHP interfaces
   - D) A form of dependency injection

2. **What is the syntax for defining a PHP 8 attribute?**
   - A) `@Attribute`
   - B) `#[Attribute]`
   - C) `{Attribute}`
   - D) `<Attribute>`

3. **Which of the following is NOT a valid target for PHP 8 attributes?**
   - A) Classes
   - B) Methods
   - C) Variables inside methods
   - D) Properties

4. **What is the main advantage of PHP 8 attributes over PHPDoc annotations?**
   - A) They are more colorful in IDEs
   - B) They are validated at compile time
   - C) They can contain more information
   - D) They are easier to write

5. **How do you specify where an attribute can be applied?**
   - A) By using the `@target` annotation
   - B) By using the `Attribute::TARGET_*` constants in the attribute constructor
   - C) By extending different base classes
   - D) It's not possible to restrict where attributes can be applied

### Exercise

**Create a custom attribute for model validation.**

Create a custom attribute called `ValidatedProperty` that can be applied to class properties. The attribute should:

1. Accept parameters for validation rules (required, min, max, etc.)
2. Be repeatable (can be applied multiple times to the same property)
3. Include a method to convert the attribute to Laravel validation rules

Example usage:
```php
class User
{
    #[ValidatedProperty(required: true, min: 3, max: 255)]
    public string $name;

    #[ValidatedProperty(required: true, email: true)]
    #[ValidatedProperty(unique: 'users')]
    public string $email;
}
```

## Set 2: Attribute-Based Model Configuration

### Questions

1. **What is the purpose of attribute-based model configuration in the UME tutorial?**
   - A) To replace database migrations
   - B) To provide a declarative way to configure model features
   - C) To generate model documentation
   - D) To create database indexes automatically

2. **Which of the following is a valid attribute for configuring a model with ULID support?**
   - A) `#[HasUlid]`
   - B) `#[Ulid]`
   - C) `#[GeneratesUlid]`
   - D) `#[UlidSupport]`

3. **How does the HasAdditionalFeatures trait process attributes?**
   - A) It doesn't; attributes are processed by Laravel itself
   - B) It uses the Reflection API to read attributes at runtime
   - C) It compiles attributes into a configuration file
   - D) It converts attributes to PHPDoc annotations

4. **What happens if you apply both the `#[HasUlid]` attribute and manually configure ULID in the model's boot method?**
   - A) The attribute takes precedence
   - B) The manual configuration takes precedence
   - C) It causes a runtime error
   - D) Both configurations are merged

5. **Which of the following is NOT a benefit of using attribute-based configuration for models?**
   - A) Improved type safety
   - B) Better IDE support
   - C) Faster database queries
   - D) More declarative code

### Exercise

**Implement attribute-based configuration for a model.**

Create a `Post` model that uses attribute-based configuration with the `HasAdditionalFeatures` trait. The model should:

1. Use ULID as its primary key
2. Generate slugs from the title field
3. Support tagging with categories and tags
4. Track which users created, updated, and deleted the model
5. Log activity for specific fields

Include the necessary attribute declarations and explain how each attribute configures the model's behavior.

## Set 3: Attribute-Based Validation

### Questions

1. **What is the purpose of attribute-based validation in Laravel?**
   - A) To validate database schema
   - B) To define validation rules directly on form request properties
   - C) To validate route parameters
   - D) To validate environment variables

2. **How do attribute-based validation rules differ from the traditional `rules()` method?**
   - A) They are more limited in functionality
   - B) They are applied to properties rather than defined in a method
   - C) They cannot be used with form requests
   - D) They require more code

3. **Which of the following is a valid attribute for requiring a field?**
   - A) `#[Required]`
   - B) `#[Validate('required')]`
   - C) `#[Rule('required')]`
   - D) `#[NotNull]`

4. **How are attribute-based validation rules processed in a form request?**
   - A) They are automatically processed by Laravel
   - B) A custom base FormRequest class uses reflection to convert them to Laravel validation rules
   - C) They are compiled into a validation configuration file
   - D) They are converted to JavaScript for client-side validation

5. **What is a potential performance concern with attribute-based validation?**
   - A) It uses more memory
   - B) Reading attributes via reflection can be expensive
   - C) It requires more database queries
   - D) It cannot be cached

### Exercise

**Create a form request with attribute-based validation.**

Create a `RegisterRequest` form request class that uses attribute-based validation for user registration. The form request should:

1. Validate a user's name (required, min: 2 characters)
2. Validate a user's email (required, valid email, unique in users table)
3. Validate a user's password (required, min: 8 characters, must be confirmed)
4. Include a custom validation attribute for checking password strength

Implement the necessary attributes and explain how they are processed to generate Laravel validation rules.

## Set 4: Attribute-Based Testing

### Questions

1. **What is the purpose of using PHP 8 attributes for testing?**
   - A) To make tests run faster
   - B) To replace PHPUnit with a custom testing framework
   - C) To mark test methods and define their properties using native language features
   - D) To generate test documentation

2. **Which attribute is used to mark a method as a test in PHPUnit 10+?**
   - A) `#[Test]`
   - B) `#[TestMethod]`
   - C) `#[IsTest]`
   - D) `#[PHPUnitTest]`

3. **How do you specify that a test depends on another test using attributes?**
   - A) `#[DependsOn('testMethod')]`
   - B) `#[Depends('testMethod')]`
   - C) `#[After('testMethod')]`
   - D) `#[Requires('testMethod')]`

4. **Which attribute is used to specify a data provider for a test?**
   - A) `#[WithData('providerMethod')]`
   - B) `#[TestWith('providerMethod')]`
   - C) `#[DataProvider('providerMethod')]`
   - D) `#[Provider('providerMethod')]`

5. **What is the attribute for specifying which class is covered by a test?**
   - A) `#[Covers(MyClass::class)]`
   - B) `#[CoversClass(MyClass::class)]`
   - C) `#[TestsClass(MyClass::class)]`
   - D) `#[ForClass(MyClass::class)]`

### Exercise

**Create a test class using PHP 8 attributes.**

Create a test class for a `Calculator` class that uses PHP 8 attributes. The test class should:

1. Use the `#[CoversClass]` attribute to specify that it covers the `Calculator` class
2. Include test methods marked with the `#[Test]` attribute
3. Include a test method that uses a data provider for testing multiple calculations
4. Include a test method that depends on another test method
5. Group related tests using the `#[Group]` attribute

Implement the necessary attributes and explain how they improve the testing experience compared to PHPDoc annotations.

## Set 5: Attribute-Based API Endpoints

### Questions

1. **What is the purpose of attribute-based API endpoint configuration?**
   - A) To generate API documentation
   - B) To define API routes directly on controller methods
   - C) To validate API requests
   - D) To authenticate API users

2. **Which attribute would you use to define an API route on a controller method?**
   - A) `#[ApiRoute]`
   - B) `#[Endpoint]`
   - C) `#[Route]`
   - D) `#[ApiEndpoint]`

3. **How do you specify middleware for an API endpoint using attributes?**
   - A) `#[UseMiddleware('auth:sanctum')]`
   - B) `#[WithMiddleware('auth:sanctum')]`
   - C) `#[Middleware('auth:sanctum')]`
   - D) `#[ApplyMiddleware('auth:sanctum')]`

4. **What component is needed to process attribute-based API endpoints?**
   - A) A route scanner service
   - B) A middleware processor
   - C) A controller factory
   - D) An attribute compiler

5. **Which of the following is NOT a benefit of attribute-based API endpoints?**
   - A) Colocation of route definitions with their handlers
   - B) Improved type safety
   - C) Faster API response times
   - D) More self-documenting code

### Exercise

**Create a controller with attribute-based API endpoints.**

Create a `ProductController` that uses attribute-based API endpoints. The controller should:

1. Use the `#[ApiController]` attribute to define a prefix and middleware for all routes
2. Include methods for listing, showing, creating, updating, and deleting products
3. Use the `#[Route]` attribute to define the HTTP method, URI, and name for each endpoint
4. Apply appropriate middleware using the `#[Middleware]` attribute
5. Specify response types using the `#[ResponseType]` attribute

Implement the necessary attributes and explain how they improve the API development experience compared to traditional route definitions.

## Additional Resources

- [PHP 8 Attributes Documentation](https://www.php.net/manual/en/language.attributes.overview.php)
- [Laravel Documentation](https://laravel.com/docs)
- [PHPUnit Documentation](https://phpunit.de/documentation.html)
- [Reflection API Documentation](https://www.php.net/manual/en/book.reflection.php)
