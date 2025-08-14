# PHP 8 Attributes Exercises - Sample Answers (Part 1)

<link rel="stylesheet" href="../assets/css/styles.css">

This file contains sample answers for the first set of PHP 8 attributes exercises. For additional parts, see the related files.

## Set 1: Understanding PHP 8 Attributes

### Question Answers

1. **What are PHP 8 attributes?**
   - **Answer: B) A way to add metadata to classes, methods, properties, and other code elements**
   - Explanation: PHP 8 attributes provide a native way to add metadata to various code elements. They are similar to annotations in other languages and replace the PHPDoc annotation approach previously used in PHP.

2. **What is the syntax for defining a PHP 8 attribute?**
   - **Answer: B) `#[Attribute]`**
   - Explanation: PHP 8 attributes use the `#[AttributeName]` syntax. This is different from PHPDoc annotations which use `/** @AnnotationName */` syntax.

3. **Which of the following is NOT a valid target for PHP 8 attributes?**
   - **Answer: C) Variables inside methods**
   - Explanation: PHP 8 attributes can be applied to classes, methods, properties, parameters, functions, and class constants, but not to variables inside methods.

4. **What is the main advantage of PHP 8 attributes over PHPDoc annotations?**
   - **Answer: B) They are validated at compile time**
   - Explanation: PHP 8 attributes are validated at compile time, which means errors in attribute usage are caught early. PHPDoc annotations are just comments and are not validated until they're processed at runtime.

5. **How do you specify where an attribute can be applied?**
   - **Answer: B) By using the `Attribute::TARGET_*` constants in the attribute constructor**
   - Explanation: When defining an attribute class, you can use the `Attribute::TARGET_*` constants to specify where the attribute can be applied (e.g., `Attribute::TARGET_CLASS`, `Attribute::TARGET_METHOD`, etc.).

### Exercise: Create a custom attribute for model validation

Here's a sample implementation of the `ValidatedProperty` attribute:

```php
<?php

namespace App\Attributes;

use Attribute;

#[Attribute(Attribute::TARGET_PROPERTY | Attribute::IS_REPEATABLE)]
class ValidatedProperty
{
    /**
     * The validation rules.
     *
     * @var array
     */
    protected array $rules = [];

    /**
     * Create a new attribute instance.
     */
    public function __construct(
        bool $required = false,
        ?int $min = null,
        ?int $max = null,
        bool $email = false,
        ?string $unique = null,
        ?string $regex = null,
        bool $confirmed = false
    ) {
        if ($required) {
            $this->rules[] = 'required';
        }

        if ($min !== null) {
            $this->rules[] = "min:{$min}";
        }

        if ($max !== null) {
            $this->rules[] = "max:{$max}";
        }

        if ($email) {
            $this->rules[] = 'email';
        }

        if ($unique !== null) {
            $this->rules[] = "unique:{$unique}";
        }

        if ($regex !== null) {
            $this->rules[] = "regex:{$regex}";
        }

        if ($confirmed) {
            $this->rules[] = 'confirmed';
        }
    }

    /**
     * Get the validation rules.
     *
     * @return array
     */
    public function getRules(): array
    {
        return $this->rules;
    }
}
```

To use this attribute with Laravel validation, you would need to create a trait or base form request class that processes these attributes:

```php
<?php

namespace App\Http\Requests;

use App\Attributes\ValidatedProperty;
use Illuminate\Foundation\Http\FormRequest as BaseFormRequest;
use ReflectionClass;
use ReflectionProperty;

abstract class FormRequest extends BaseFormRequest
{
    /**
     * Get the validation rules that apply to the request.
     *
     * @return array
     */
    public function rules(): array
    {
        $rules = [];
        $reflection = new ReflectionClass($this);
        $properties = $reflection->getProperties(ReflectionProperty::IS_PUBLIC);

        foreach ($properties as $property) {
            $name = $property->getName();
            $attributes = $property->getAttributes(ValidatedProperty::class);
            
            if (empty($attributes)) {
                continue;
            }

            $propertyRules = [];
            
            foreach ($attributes as $attribute) {
                $instance = $attribute->newInstance();
                $propertyRules = array_merge($propertyRules, $instance->getRules());
            }
            
            if (!empty($propertyRules)) {
                $rules[$name] = $propertyRules;
            }
        }

        return $rules;
    }
}
```

Example usage:

```php
<?php

namespace App\Http\Requests;

use App\Attributes\ValidatedProperty;

class UserRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     *
     * @return bool
     */
    public function authorize(): bool
    {
        return true;
    }

    #[ValidatedProperty(required: true, min: 3, max: 255)]
    public string $name;

    #[ValidatedProperty(required: true, email: true)]
    #[ValidatedProperty(unique: 'users')]
    public string $email;
}
```

This implementation allows for:
1. Applying multiple validation rules to a property using a single attribute
2. Applying multiple attributes to the same property for more complex validation
3. Converting attributes to Laravel validation rules automatically
4. Type safety through PHP's type system

The key benefits of this approach are:
- Validation rules are colocated with the properties they validate
- The code is more self-documenting
- Type safety is improved through PHP's type system
- IDE support is better with attributes than with PHPDoc annotations
