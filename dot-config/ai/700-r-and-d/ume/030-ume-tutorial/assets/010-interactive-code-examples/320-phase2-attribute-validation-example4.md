# Attribute-Based Validation

:::interactive-code
title: Implementing Attribute-Based Validation
description: This example demonstrates how to implement a comprehensive validation system using PHP 8 attributes.
language: php
editable: true
code: |
  <?php
  
  namespace App\Validation;
  
  use Attribute;
  use ReflectionClass;
  use ReflectionProperty;
  
  // Base validation attribute
  #[Attribute(Attribute::TARGET_PROPERTY | Attribute::IS_REPEATABLE)]
  abstract class ValidationRule {
      abstract public function validate($value, string $propertyName): ?string;
  }
  
  // Required validation rule
  #[Attribute(Attribute::TARGET_PROPERTY)]
  class Required extends ValidationRule {
      public function validate($value, string $propertyName): ?string {
          if ($value === null || $value === '') {
              return "The {$propertyName} field is required.";
          }
          
          return null;
      }
  }
  
  // Email validation rule
  #[Attribute(Attribute::TARGET_PROPERTY)]
  class Email extends ValidationRule {
      public function validate($value, string $propertyName): ?string {
          if ($value === null || $value === '') {
              return null; // Skip validation if empty (use Required for required fields)
          }
          
          if (!filter_var($value, FILTER_VALIDATE_EMAIL)) {
              return "The {$propertyName} must be a valid email address.";
          }
          
          return null;
      }
  }
  
  // Min length validation rule
  #[Attribute(Attribute::TARGET_PROPERTY)]
  class MinLength extends ValidationRule {
      private int $length;
      
      public function __construct(int $length) {
          $this->length = $length;
      }
      
      public function validate($value, string $propertyName): ?string {
          if ($value === null || $value === '') {
              return null; // Skip validation if empty
          }
          
          if (strlen($value) < $this->length) {
              return "The {$propertyName} must be at least {$this->length} characters.";
          }
          
          return null;
      }
  }
  
  // Max length validation rule
  #[Attribute(Attribute::TARGET_PROPERTY)]
  class MaxLength extends ValidationRule {
      private int $length;
      
      public function __construct(int $length) {
          $this->length = $length;
      }
      
      public function validate($value, string $propertyName): ?string {
          if ($value === null || $value === '') {
              return null; // Skip validation if empty
          }
          
          if (strlen($value) > $this->length) {
              return "The {$propertyName} must not exceed {$this->length} characters.";
          }
          
          return null;
      }
  }
  
  // Regex pattern validation rule
  #[Attribute(Attribute::TARGET_PROPERTY)]
  class Pattern extends ValidationRule {
      private string $pattern;
      private string $message;
      
      public function __construct(string $pattern, string $message = null) {
          $this->pattern = $pattern;
          $this->message = $message ?? "The :attribute format is invalid.";
      }
      
      public function validate($value, string $propertyName): ?string {
          if ($value === null || $value === '') {
              return null; // Skip validation if empty
          }
          
          if (!preg_match($this->pattern, $value)) {
              return str_replace(':attribute', $propertyName, $this->message);
          }
          
          return null;
      }
  }
  
  // In array validation rule
  #[Attribute(Attribute::TARGET_PROPERTY)]
  class InArray extends ValidationRule {
      private array $values;
      
      public function __construct(array $values) {
          $this->values = $values;
      }
      
      public function validate($value, string $propertyName): ?string {
          if ($value === null || $value === '') {
              return null; // Skip validation if empty
          }
          
          if (!in_array($value, $this->values)) {
              $valuesString = implode(', ', $this->values);
              return "The {$propertyName} must be one of: {$valuesString}.";
          }
          
          return null;
      }
  }
  
  // Confirmed validation rule (for password confirmation)
  #[Attribute(Attribute::TARGET_PROPERTY)]
  class Confirmed extends ValidationRule {
      private string $confirmationField;
      
      public function __construct(string $confirmationField = null) {
          $this->confirmationField = $confirmationField;
      }
      
      public function validate($value, string $propertyName): ?string {
          if ($value === null || $value === '') {
              return null; // Skip validation if empty
          }
          
          $confirmationField = $this->confirmationField ?? "{$propertyName}_confirmation";
          $object = $this->getObject();
          
          if (!property_exists($object, $confirmationField) || $object->$confirmationField !== $value) {
              return "The {$propertyName} confirmation does not match.";
          }
          
          return null;
      }
      
      // This would be set by the validator during validation
      private $object;
      
      public function setObject($object): void {
          $this->object = $object;
      }
      
      private function getObject() {
          return $this->object;
      }
  }
  
  // Validator class
  class Validator {
      /**
       * Validate an object using its property attributes.
       *
       * @param object $object The object to validate
       * @return array The validation errors
       */
      public static function validate(object $object): array {
          $errors = [];
          $reflection = new ReflectionClass($object);
          $properties = $reflection->getProperties(ReflectionProperty::IS_PUBLIC);
          
          foreach ($properties as $property) {
              $propertyName = $property->getName();
              $value = $property->getValue($object);
              
              // Get all validation attributes
              $attributes = $property->getAttributes(
                  ValidationRule::class, 
                  \ReflectionAttribute::IS_INSTANCEOF
              );
              
              foreach ($attributes as $attribute) {
                  $rule = $attribute->newInstance();
                  
                  // For Confirmed rule, set the object
                  if ($rule instanceof Confirmed) {
                      $rule->setObject($object);
                  }
                  
                  // Validate the value
                  $error = $rule->validate($value, $propertyName);
                  
                  if ($error !== null) {
                      if (!isset($errors[$propertyName])) {
                          $errors[$propertyName] = [];
                      }
                      
                      $errors[$propertyName][] = $error;
                  }
              }
          }
          
          return $errors;
      }
  }
  
  // Example form request class
  class RegisterRequest {
      #[Required]
      #[MinLength(2)]
      #[MaxLength(50)]
      public string $name;
      
      #[Required]
      #[Email]
      public string $email;
      
      #[Required]
      #[MinLength(8)]
      #[Pattern('/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$/', 'The password must contain at least one uppercase letter, one lowercase letter, one number, and one special character.')]
      #[Confirmed]
      public string $password;
      
      public string $password_confirmation;
      
      #[InArray(['user', 'admin', 'editor'])]
      public string $role = 'user';
      
      public function __construct(array $data = []) {
          foreach ($data as $key => $value) {
              if (property_exists($this, $key)) {
                  $this->$key = $value;
              }
          }
      }
  }
  
  // Example usage
  
  // Valid data
  $validData = [
      'name' => 'John Doe',
      'email' => 'john@example.com',
      'password' => 'Password123!',
      'password_confirmation' => 'Password123!',
      'role' => 'admin',
  ];
  
  $validRequest = new RegisterRequest($validData);
  $validationErrors = Validator::validate($validRequest);
  
  echo "Validating with valid data:\n";
  if (empty($validationErrors)) {
      echo "Validation passed! No errors.\n";
  } else {
      echo "Validation errors:\n";
      foreach ($validationErrors as $field => $errors) {
          echo "- {$field}:\n";
          foreach ($errors as $error) {
              echo "  - {$error}\n";
          }
      }
  }
  
  // Invalid data
  $invalidData = [
      'name' => 'J', // Too short
      'email' => 'not-an-email', // Invalid email
      'password' => 'password', // Doesn't meet complexity requirements
      'password_confirmation' => 'different', // Doesn't match
      'role' => 'superadmin', // Not in allowed values
  ];
  
  $invalidRequest = new RegisterRequest($invalidData);
  $validationErrors = Validator::validate($invalidRequest);
  
  echo "\nValidating with invalid data:\n";
  if (empty($validationErrors)) {
      echo "Validation passed! No errors.\n";
  } else {
      echo "Validation errors:\n";
      foreach ($validationErrors as $field => $errors) {
          echo "- {$field}:\n";
          foreach ($errors as $error) {
              echo "  - {$error}\n";
          }
      }
  }
explanation: |
  This example demonstrates a comprehensive attribute-based validation system:
  
  1. **Validation Rules as Attributes**: Each validation rule is implemented as a PHP 8 attribute that can be applied to class properties.
  
  2. **Base Validation Rule**: All validation rules extend the abstract `ValidationRule` class, which defines the common interface.
  
  3. **Validation Logic**: Each rule implements its own validation logic in the `validate` method, which returns an error message if validation fails.
  
  4. **Multiple Rules per Property**: Properties can have multiple validation rules applied to them, and all rules will be checked.
  
  5. **Validator Class**: The `Validator` class uses reflection to find all validation attributes on an object's properties and validate them.
  
  6. **Form Request Class**: The `RegisterRequest` class demonstrates how to use validation attributes to define validation rules for a registration form.
  
  The example includes several common validation rules:
  - **Required**: Ensures a field is not empty
  - **Email**: Validates email format
  - **MinLength/MaxLength**: Validates string length
  - **Pattern**: Validates against a regex pattern
  - **InArray**: Ensures a value is in a list of allowed values
  - **Confirmed**: Ensures a field matches its confirmation field (for passwords)
  
  In a real Laravel application:
  - This could be integrated with Laravel's form request validation
  - You could add support for conditional validation
  - The validator could be extended to support custom error messages
  - You could add support for validating nested objects and arrays
challenges:
  - Add a new validation rule for numeric values with min/max constraints
  - Implement a "Different" rule that ensures a field is different from another field
  - Create a "Date" validation rule that validates date formats
  - Add support for conditional validation (e.g., a field is required only if another field has a certain value)
  - Implement a custom error message system that allows overriding the default error messages
:::
