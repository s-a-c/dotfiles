# PHP 8 Attributes Cheat Sheet

<link rel="stylesheet" href="../../css/styles.css">
<link rel="stylesheet" href="../../css/ume-docs-enhancements.css">
<script src="../../js/ume-docs-enhancements.js"></script>

## Overview

This cheat sheet provides a quick reference for PHP 8 Attributes, which are used extensively in the UME system to provide metadata and configuration for classes, methods, properties, and parameters.

## Basic Syntax

```php
// Class attribute
#[AttributeName]
class MyClass
{
    // Property attribute
    #[PropertyAttribute]
    public $property;
    
    // Method attribute
    #[MethodAttribute]
    public function myMethod(
        // Parameter attribute
        #[ParamAttribute]
        $parameter
    ) {
        // Method implementation
    }
}
```

## Attribute Declaration

```php
// Basic attribute declaration
#[Attribute]
class MyAttribute
{
    public function __construct(
        public string $value = ''
    ) {}
}

// Attribute with targets
#[Attribute(Attribute::TARGET_CLASS | Attribute::TARGET_METHOD)]
class TargetedAttribute
{
    public function __construct(
        public string $value = ''
    ) {}
}

// Repeatable attribute
#[Attribute(Attribute::IS_REPEATABLE)]
class RepeatableAttribute
{
    public function __construct(
        public string $value = ''
    ) {}
}
```

## Common Attribute Targets

| Target Constant | Description |
|-----------------|-------------|
| `Attribute::TARGET_CLASS` | Can be applied to classes |
| `Attribute::TARGET_METHOD` | Can be applied to methods |
| `Attribute::TARGET_PROPERTY` | Can be applied to properties |
| `Attribute::TARGET_PARAMETER` | Can be applied to parameters |
| `Attribute::TARGET_FUNCTION` | Can be applied to functions |
| `Attribute::TARGET_CLASS_CONSTANT` | Can be applied to class constants |
| `Attribute::TARGET_ALL` | Can be applied to any element |
| `Attribute::IS_REPEATABLE` | Attribute can be used multiple times on the same element |

## Reading Attributes with Reflection

```php
// Get class attributes
$reflectionClass = new ReflectionClass(MyClass::class);
$attributes = $reflectionClass->getAttributes();

// Get method attributes
$reflectionMethod = $reflectionClass->getMethod('myMethod');
$methodAttributes = $reflectionMethod->getAttributes();

// Get property attributes
$reflectionProperty = $reflectionClass->getProperty('property');
$propertyAttributes = $reflectionProperty->getAttributes();

// Get parameter attributes
$reflectionParameter = $reflectionMethod->getParameters()[0];
$parameterAttributes = $reflectionParameter->getAttributes();

// Get attributes of a specific type
$specificAttributes = $reflectionClass->getAttributes(MyAttribute::class);

// Instantiate an attribute
$attribute = $specificAttributes[0]->newInstance();
$value = $attribute->value;
```

## UME Attribute Examples

### Model Attributes

```php
// User type attribute
#[UserType('admin')]
class Admin extends User
{
    // Implementation
}

// HasUlid trait configuration
#[HasUlid(prefix: 'usr')]
class User extends Model
{
    use HasUlid;
    
    // Implementation
}

// HasUserTracking trait configuration
#[HasUserTracking(
    created_by: 'created_by_id',
    updated_by: 'updated_by_id',
    deleted_by: 'deleted_by_id'
)]
class Team extends Model
{
    use HasUserTracking;
    
    // Implementation
}
```

### Validation Attributes

```php
class UserRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            #[Required]
            #[String]
            #[Max(255)]
            'name' => [],
            
            #[Required]
            #[Email]
            #[Unique('users', 'email')]
            'email' => [],
            
            #[Required]
            #[String]
            #[Min(8)]
            #[Confirmed]
            'password' => [],
        ];
    }
}
```

### Route Attributes

```php
class UserController extends Controller
{
    #[Get('users')]
    #[Middleware(['auth', 'verified'])]
    public function index()
    {
        // Implementation
    }
    
    #[Post('users')]
    #[Middleware(['auth', 'verified'])]
    public function store(
        #[FromRequest] UserRequest $request
    ) {
        // Implementation
    }
    
    #[Get('users/{user}')]
    #[Middleware(['auth', 'verified'])]
    public function show(
        #[FromRoute] User $user
    ) {
        // Implementation
    }
}
```

### Policy Attributes

```php
#[Policy(User::class)]
class UserPolicy
{
    #[Can('viewAny')]
    public function viewAny(User $user): bool
    {
        return true;
    }
    
    #[Can('view')]
    public function view(User $user, User $model): bool
    {
        return $user->id === $model->id || $user->isAdmin();
    }
    
    #[Can('create')]
    public function create(User $user): bool
    {
        return $user->isAdmin();
    }
}
```

## Common Patterns

### Attribute-Based Configuration

```php
#[Config(key: 'value')]
class MyClass
{
    // Implementation
}

// Reading configuration
$reflectionClass = new ReflectionClass(MyClass::class);
$configAttributes = $reflectionClass->getAttributes(Config::class);
$config = $configAttributes[0]->newInstance();
$value = $config->key;
```

### Attribute-Based Validation

```php
class MyRequest extends FormRequest
{
    #[Validate]
    public string $name;
    
    #[Validate([
        new Required(),
        new Email(),
        new Unique('users', 'email')
    ])]
    public string $email;
    
    #[Validate([
        new Required(),
        new Min(8),
        new Confirmed()
    ])]
    public string $password;
}
```

### Attribute-Based Routing

```php
#[Controller]
#[Prefix('api/v1')]
#[Middleware(['api', 'auth:sanctum'])]
class ApiController
{
    #[Get('users')]
    public function index()
    {
        // Implementation
    }
    
    #[Post('users')]
    public function store()
    {
        // Implementation
    }
    
    #[Get('users/{id}')]
    public function show($id)
    {
        // Implementation
    }
}
```

## Best Practices

1. **Use Attributes for Configuration**: Prefer attributes over PHPDoc annotations for configuration.

2. **Keep Attributes Simple**: Attributes should be simple data containers, not complex logic.

3. **Document Attributes**: Clearly document what each attribute does and how it should be used.

4. **Validate Attribute Values**: Validate attribute values in the constructor to fail fast.

5. **Use Type Hints**: Use type hints in attribute constructors to ensure correct usage.

6. **Target Restrictions**: Use target restrictions to prevent misuse of attributes.

7. **Namespace Attributes**: Place attributes in a dedicated namespace to avoid conflicts.

8. **Cache Reflection**: Cache reflection results to avoid performance issues.

9. **Provide Defaults**: Provide sensible defaults for attribute parameters.

10. **Consistent Naming**: Use consistent naming conventions for attributes.

## Common Pitfalls

1. **Performance Impact**: Excessive use of reflection can impact performance.

2. **Attribute Overuse**: Using attributes for everything can make code harder to understand.

3. **Missing Validation**: Not validating attribute values can lead to runtime errors.

4. **Circular Dependencies**: Attributes that reference each other can create circular dependencies.

5. **Tight Coupling**: Attributes can create tight coupling between components.

6. **Inheritance Issues**: Attributes are not automatically inherited by child classes.

7. **Namespace Conflicts**: Attributes without proper namespacing can conflict with other code.

8. **Reflection Overhead**: Reflection has overhead, especially when used frequently.

9. **Debugging Difficulty**: Attributes can be harder to debug than regular code.

10. **IDE Support**: Some IDEs may have limited support for attributes.

## Quick Reference

### Attribute Declaration

```php
#[Attribute(
    Attribute::TARGET_CLASS | Attribute::TARGET_METHOD,
    Attribute::IS_REPEATABLE
)]
class MyAttribute
{
    public function __construct(
        public string $value = ''
    ) {}
}
```

### Attribute Usage

```php
#[MyAttribute('value')]
class MyClass {}

#[MyAttribute('value1')]
#[MyAttribute('value2')]
public function myMethod() {}
```

### Attribute Reflection

```php
// Get all attributes
$attributes = $reflection->getAttributes();

// Get specific attribute
$attributes = $reflection->getAttributes(MyAttribute::class);

// Instantiate attribute
$attribute = $attributes[0]->newInstance();

// Get attribute value
$value = $attribute->value;
```

## Related Resources

- [PHP 8 Attributes Documentation](https://www.php.net/manual/en/language.attributes.php)
- [PHP Reflection API Documentation](https://www.php.net/manual/en/book.reflection.php)
- [UME Attributes Implementation](../../../050-implementation/010-phase0-foundation/060-php8-attributes.md)
- [Diagram Style Guide](../diagram-style-guide.md)
