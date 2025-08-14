# PHP 8 Attributes Exercises - Sample Answers (Part 3)

<link rel="stylesheet" href="../assets/css/styles.css">

This file contains sample answers for the third set of PHP 8 attributes exercises. For additional parts, see the related files.

## Set 3: Attribute-Based Validation

### Question Answers

1. **What is the purpose of attribute-based validation in Laravel?**
   - **Answer: B) To define validation rules directly on form request properties**
   - Explanation: Attribute-based validation allows developers to define validation rules directly on form request properties, making the code more self-documenting and reducing the need for lengthy rules() methods.

2. **How do attribute-based validation rules differ from the traditional `rules()` method?**
   - **Answer: B) They are applied to properties rather than defined in a method**
   - Explanation: Attribute-based validation rules are applied directly to the properties they validate, whereas traditional validation rules are defined in the rules() method as an array.

3. **Which of the following is a valid attribute for requiring a field?**
   - **Answer: A) `#[Required]`**
   - Explanation: In the UME tutorial, the `#[Required]` attribute is used to mark a property as required in a form request.

4. **How are attribute-based validation rules processed in a form request?**
   - **Answer: B) A custom base FormRequest class uses reflection to convert them to Laravel validation rules**
   - Explanation: A custom base FormRequest class uses PHP's Reflection API to read attributes from properties and convert them to Laravel validation rules.

5. **What is a potential performance concern with attribute-based validation?**
   - **Answer: B) Reading attributes via reflection can be expensive**
   - Explanation: Reading attributes via reflection can be computationally expensive, especially if done frequently. This can be mitigated by caching the results.

### Exercise: Create a form request with attribute-based validation

Here's a sample implementation of a `RegisterRequest` form request class using attribute-based validation:

First, let's create a custom attribute for password strength:

```php
<?php

namespace App\Http\Attributes\Validation;

use Attribute;

#[Attribute(Attribute::TARGET_PROPERTY)]
class StrongPassword
{
    /**
     * Create a new attribute instance.
     *
     * @param int $minLength The minimum password length
     * @param bool $requireUppercase Whether to require uppercase letters
     * @param bool $requireLowercase Whether to require lowercase letters
     * @param bool $requireNumbers Whether to require numbers
     * @param bool $requireSpecialChars Whether to require special characters
     */
    public function __construct(
        public int $minLength = 8,
        public bool $requireUppercase = true,
        public bool $requireLowercase = true,
        public bool $requireNumbers = true,
        public bool $requireSpecialChars = true
    ) {}
}
```

Now, let's create the base FormRequest class that processes validation attributes:

```php
<?php

namespace App\Http\Requests;

use App\Http\Attributes\Validation\Required;
use App\Http\Attributes\Validation\Email;
use App\Http\Attributes\Validation\Min;
use App\Http\Attributes\Validation\Unique;
use App\Http\Attributes\Validation\Confirmed;
use App\Http\Attributes\Validation\StrongPassword;
use Illuminate\Foundation\Http\FormRequest as BaseFormRequest;
use Illuminate\Validation\Rules\Password;
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
            $propertyRules = [];

            // Process Required attribute
            $requiredAttributes = $property->getAttributes(Required::class);
            if (!empty($requiredAttributes)) {
                $propertyRules[] = 'required';
            }

            // Process Min attribute
            $minAttributes = $property->getAttributes(Min::class);
            foreach ($minAttributes as $attribute) {
                $instance = $attribute->newInstance();
                $propertyRules[] = "min:{$instance->value}";
            }

            // Process Email attribute
            $emailAttributes = $property->getAttributes(Email::class);
            if (!empty($emailAttributes)) {
                $propertyRules[] = 'email';
            }

            // Process Unique attribute
            $uniqueAttributes = $property->getAttributes(Unique::class);
            foreach ($uniqueAttributes as $attribute) {
                $instance = $attribute->newInstance();
                $propertyRules[] = "unique:{$instance->table},{$instance->column}";
            }

            // Process Confirmed attribute
            $confirmedAttributes = $property->getAttributes(Confirmed::class);
            if (!empty($confirmedAttributes)) {
                $propertyRules[] = 'confirmed';
            }

            // Process StrongPassword attribute
            $strongPasswordAttributes = $property->getAttributes(StrongPassword::class);
            foreach ($strongPasswordAttributes as $attribute) {
                $instance = $attribute->newInstance();
                $password = Password::min($instance->minLength);
                
                if ($instance->requireUppercase) {
                    $password->mixedCase();
                }
                
                if ($instance->requireNumbers) {
                    $password->numbers();
                }
                
                if ($instance->requireSpecialChars) {
                    $password->symbols();
                }
                
                $propertyRules[] = $password;
            }

            if (!empty($propertyRules)) {
                $rules[$name] = $propertyRules;
            }
        }

        return $rules;
    }
}
```

Finally, let's create the RegisterRequest class:

```php
<?php

namespace App\Http\Requests\Auth;

use App\Http\Attributes\Validation\Required;
use App\Http\Attributes\Validation\Email;
use App\Http\Attributes\Validation\Min;
use App\Http\Attributes\Validation\Unique;
use App\Http\Attributes\Validation\Confirmed;
use App\Http\Attributes\Validation\StrongPassword;
use App\Http\Requests\FormRequest;

class RegisterRequest extends FormRequest
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

    #[Required]
    #[Min(2)]
    public string $name;

    #[Required]
    #[Email]
    #[Unique(table: 'users', column: 'email')]
    public string $email;

    #[Required]
    #[Confirmed]
    #[StrongPassword(minLength: 8, requireUppercase: true, requireNumbers: true, requireSpecialChars: true)]
    public string $password;
}
```

This implementation:
1. Defines validation rules directly on the properties they validate
2. Uses a custom attribute for password strength validation
3. Processes attributes using reflection to generate Laravel validation rules
4. Provides type safety through PHP's type system

The key benefits of this approach are:
- Validation rules are colocated with the properties they validate
- The code is more self-documenting
- Type safety is improved through PHP's type system
- IDE support is better with attributes than with PHPDoc annotations

To mitigate the performance impact of using reflection, you could cache the generated validation rules:

```php
public function rules(): array
{
    $cacheKey = static::class . '_validation_rules';
    
    return cache()->remember($cacheKey, now()->addDay(), function () {
        // Generate rules using reflection as shown above
    });
}
```
