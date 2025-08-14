# Attribute-Based Validation

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Implement attribute-based validation for form requests, providing a more type-safe and declarative approach to defining validation rules.

## Overview

Laravel's form request validation typically uses the `rules()` method to define validation rules as an array. While this approach works well, it lacks type safety and can be verbose. PHP 8 attributes offer a more elegant solution, allowing us to define validation rules directly on the properties of our form request classes.

## Step 1: Create Validation Attributes

First, let's create a set of validation attributes:

```php
<?php

namespace App\Http\Attributes\Validation;

use Attribute;

#[Attribute(Attribute::TARGET_PROPERTY)]
class Required
{
}

#[Attribute(Attribute::TARGET_PROPERTY)]
class Email
{
    public function __construct(
        public bool $dns = false,
        public bool $spoof = false,
        public bool $filter = true
    ) {}
}

#[Attribute(Attribute::TARGET_PROPERTY)]
class Min
{
    public function __construct(
        public int $value
    ) {}
}

#[Attribute(Attribute::TARGET_PROPERTY)]
class Max
{
    public function __construct(
        public int $value
    ) {}
}

#[Attribute(Attribute::TARGET_PROPERTY)]
class Between
{
    public function __construct(
        public int $min,
        public int $max
    ) {}
}

#[Attribute(Attribute::TARGET_PROPERTY)]
class Confirmed
{
}

#[Attribute(Attribute::TARGET_PROPERTY)]
class Unique
{
    public function __construct(
        public string $table,
        public ?string $column = null,
        public ?string $except = null,
        public ?string $idColumn = null
    ) {}
}

#[Attribute(Attribute::TARGET_PROPERTY)]
class Exists
{
    public function __construct(
        public string $table,
        public ?string $column = null
    ) {}
}

#[Attribute(Attribute::TARGET_PROPERTY)]
class In
{
    public function __construct(
        public array $values
    ) {}
}

#[Attribute(Attribute::TARGET_PROPERTY)]
class NotIn
{
    public function __construct(
        public array $values
    ) {}
}

#[Attribute(Attribute::TARGET_PROPERTY)]
class Regex
{
    public function __construct(
        public string $pattern
    ) {}
}

#[Attribute(Attribute::TARGET_PROPERTY)]
class Url
{
}

#[Attribute(Attribute::TARGET_PROPERTY)]
class Image
{
}

#[Attribute(Attribute::TARGET_PROPERTY)]
class Mimes
{
    public function __construct(
        public array $types
    ) {}
}

#[Attribute(Attribute::TARGET_PROPERTY)]
class Date
{
}

#[Attribute(Attribute::TARGET_PROPERTY)]
class DateFormat
{
    public function __construct(
        public string $format
    ) {}
}

#[Attribute(Attribute::TARGET_PROPERTY)]
class After
{
    public function __construct(
        public string $date
    ) {}
}

#[Attribute(Attribute::TARGET_PROPERTY)]
class Before
{
    public function __construct(
        public string $date
    ) {}
}

#[Attribute(Attribute::TARGET_PROPERTY)]
class AfterOrEqual
{
    public function __construct(
        public string $date
    ) {}
}

#[Attribute(Attribute::TARGET_PROPERTY)]
class BeforeOrEqual
{
    public function __construct(
        public string $date
    ) {}
}

#[Attribute(Attribute::TARGET_PROPERTY)]
class Password
{
    public function __construct(
        public int $min = 8,
        public bool $letters = false,
        public bool $mixedCase = false,
        public bool $numbers = false,
        public bool $symbols = false,
        public bool $uncompromised = false,
        public int $uncompromisedThreshold = 0
    ) {}
}
```

## Step 2: Create a Base Form Request Class

Next, let's create a base form request class that processes these attributes:

```php
<?php

namespace App\Http\Requests;

use App\Http\Attributes\Validation\After;
use App\Http\Attributes\Validation\AfterOrEqual;
use App\Http\Attributes\Validation\Before;
use App\Http\Attributes\Validation\BeforeOrEqual;
use App\Http\Attributes\Validation\Between;
use App\Http\Attributes\Validation\Confirmed;
use App\Http\Attributes\Validation\Date;
use App\Http\Attributes\Validation\DateFormat;
use App\Http\Attributes\Validation\Email;
use App\Http\Attributes\Validation\Exists;
use App\Http\Attributes\Validation\Image;
use App\Http\Attributes\Validation\In;
use App\Http\Attributes\Validation\Max;
use App\Http\Attributes\Validation\Mimes;
use App\Http\Attributes\Validation\Min;
use App\Http\Attributes\Validation\NotIn;
use App\Http\Attributes\Validation\Password;
use App\Http\Attributes\Validation\Regex;
use App\Http\Attributes\Validation\Required;
use App\Http\Attributes\Validation\Unique;
use App\Http\Attributes\Validation\Url;
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
            $rules[$name] = $this->getPropertyRules($property);
        }

        return $rules;
    }

    /**
     * Get the validation rules for a property.
     *
     * @param ReflectionProperty $property
     * @return array
     */
    protected function getPropertyRules(ReflectionProperty $property): array
    {
        $rules = [];
        $attributes = $property->getAttributes();

        foreach ($attributes as $attribute) {
            $attributeName = $attribute->getName();
            $attributeInstance = $attribute->newInstance();

            switch ($attributeName) {
                case Required::class:
                    $rules[] = 'required';
                    break;
                case Email::class:
                    $rule = 'email';
                    if ($attributeInstance->dns) {
                        $rule .= ':dns';
                    }
                    if ($attributeInstance->spoof) {
                        $rule .= ',spoof';
                    }
                    if ($attributeInstance->filter) {
                        $rule .= ',filter';
                    }
                    $rules[] = $rule;
                    break;
                case Min::class:
                    $rules[] = 'min:' . $attributeInstance->value;
                    break;
                case Max::class:
                    $rules[] = 'max:' . $attributeInstance->value;
                    break;
                case Between::class:
                    $rules[] = 'between:' . $attributeInstance->min . ',' . $attributeInstance->max;
                    break;
                case Confirmed::class:
                    $rules[] = 'confirmed';
                    break;
                case Unique::class:
                    $rule = 'unique:' . $attributeInstance->table;
                    if ($attributeInstance->column) {
                        $rule .= ',' . $attributeInstance->column;
                    }
                    if ($attributeInstance->except) {
                        $rule .= ',' . $attributeInstance->except;
                    }
                    if ($attributeInstance->idColumn) {
                        $rule .= ',' . $attributeInstance->idColumn;
                    }
                    $rules[] = $rule;
                    break;
                case Exists::class:
                    $rule = 'exists:' . $attributeInstance->table;
                    if ($attributeInstance->column) {
                        $rule .= ',' . $attributeInstance->column;
                    }
                    $rules[] = $rule;
                    break;
                case In::class:
                    $rules[] = 'in:' . implode(',', $attributeInstance->values);
                    break;
                case NotIn::class:
                    $rules[] = 'not_in:' . implode(',', $attributeInstance->values);
                    break;
                case Regex::class:
                    $rules[] = 'regex:' . $attributeInstance->pattern;
                    break;
                case Url::class:
                    $rules[] = 'url';
                    break;
                case Image::class:
                    $rules[] = 'image';
                    break;
                case Mimes::class:
                    $rules[] = 'mimes:' . implode(',', $attributeInstance->types);
                    break;
                case Date::class:
                    $rules[] = 'date';
                    break;
                case DateFormat::class:
                    $rules[] = 'date_format:' . $attributeInstance->format;
                    break;
                case After::class:
                    $rules[] = 'after:' . $attributeInstance->date;
                    break;
                case Before::class:
                    $rules[] = 'before:' . $attributeInstance->date;
                    break;
                case AfterOrEqual::class:
                    $rules[] = 'after_or_equal:' . $attributeInstance->date;
                    break;
                case BeforeOrEqual::class:
                    $rules[] = 'before_or_equal:' . $attributeInstance->date;
                    break;
                case Password::class:
                    $rule = 'password:';
                    $options = [];
                    if ($attributeInstance->min > 0) {
                        $options[] = 'min=' . $attributeInstance->min;
                    }
                    if ($attributeInstance->letters) {
                        $options[] = 'letters';
                    }
                    if ($attributeInstance->mixedCase) {
                        $options[] = 'mixed';
                    }
                    if ($attributeInstance->numbers) {
                        $options[] = 'numbers';
                    }
                    if ($attributeInstance->symbols) {
                        $options[] = 'symbols';
                    }
                    if ($attributeInstance->uncompromised) {
                        $options[] = 'uncompromised';
                        if ($attributeInstance->uncompromisedThreshold > 0) {
                            $options[count($options) - 1] .= ',' . $attributeInstance->uncompromisedThreshold;
                        }
                    }
                    $rule .= implode(',', $options);
                    $rules[] = $rule;
                    break;
            }
        }

        return $rules;
    }
}
```

## Step 3: Using Attribute-Based Validation

Now, we can create form requests with attribute-based validation:

```php
<?php

namespace App\Http\Requests\Auth;

use App\Http\Attributes\Validation\Confirmed;
use App\Http\Attributes\Validation\Email;
use App\Http\Attributes\Validation\Min;
use App\Http\Attributes\Validation\Password;
use App\Http\Attributes\Validation\Required;
use App\Http\Attributes\Validation\Unique;
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
    #[Email(dns: true)]
    #[Unique(table: 'users')]
    public string $email;

    #[Required]
    #[Confirmed]
    #[Password(min: 8, letters: true, mixedCase: true, numbers: true, symbols: true)]
    public string $password;
}
```

## Benefits of Attribute-Based Validation

Using attributes for validation offers several benefits:

1. **Type Safety**: Properties are explicitly typed, catching type errors at compile time
2. **Self-Documenting**: Validation rules are directly attached to the properties they validate
3. **IDE Support**: Modern IDEs provide autocompletion and validation for attributes
4. **Reduced Boilerplate**: No need for lengthy rules() methods
5. **Centralized Logic**: Validation logic is encapsulated in the base FormRequest class

## Performance Considerations

Reading attributes via reflection can be expensive, especially if done frequently. To mitigate this, consider:

1. **Caching Validation Rules**: Cache the generated validation rules
2. **Lazy Loading**: Only generate validation rules when needed
3. **Batch Processing**: Process all attributes at once rather than individually

## Conclusion

Attribute-based validation provides a clean, declarative way to define validation rules for form requests. By leveraging PHP 8 attributes, we can create a more intuitive and type-safe API for our form requests, improving developer experience and reducing the likelihood of validation errors.
