# PHP 8 Attributes - Attribute-Based Validation

:::interactive-code
title: Implementing Attribute-Based Validation
description: This example shows how to create and use attributes for form validation in a Laravel-like approach.
language: php
editable: true
code: |
  <?php
  
  // Define validation attribute base class
  #[Attribute(Attribute::TARGET_PROPERTY | Attribute::IS_REPEATABLE)]
  abstract class ValidationRule {
      abstract public function validate($value): bool;
      abstract public function getMessage(): string;
  }
  
  // Required validation rule
  #[Attribute(Attribute::TARGET_PROPERTY)]
  class Required extends ValidationRule {
      public function validate($value): bool {
          return $value !== null && $value !== '';
      }
      
      public function getMessage(): string {
          return 'This field is required';
      }
  }
  
  // Email validation rule
  #[Attribute(Attribute::TARGET_PROPERTY)]
  class Email extends ValidationRule {
      public function validate($value): bool {
          return filter_var($value, FILTER_VALIDATE_EMAIL) !== false;
      }
      
      public function getMessage(): string {
          return 'This field must be a valid email address';
      }
  }
  
  // MinLength validation rule
  #[Attribute(Attribute::TARGET_PROPERTY)]
  class MinLength extends ValidationRule {
      public function __construct(
          private int $length
      ) {}
      
      public function validate($value): bool {
          return strlen($value) >= $this->length;
      }
      
      public function getMessage(): string {
          return "This field must be at least {$this->length} characters long";
      }
  }
  
  // Form request class
  class FormRequest {
      #[Required]
      #[MinLength(3)]
      public string $name;
      
      #[Required]
      #[Email]
      public string $email;
      
      public string $message = ''; // Optional field
      
      public function __construct(array $data) {
          foreach ($data as $key => $value) {
              if (property_exists($this, $key)) {
                  $this->$key = $value;
              }
          }
      }
      
      public function validate(): array {
          $errors = [];
          $reflection = new ReflectionClass($this);
          $properties = $reflection->getProperties(ReflectionProperty::IS_PUBLIC);
          
          foreach ($properties as $property) {
              $name = $property->getName();
              $value = $this->$name;
              
              $attributes = $property->getAttributes(ValidationRule::class, ReflectionAttribute::IS_INSTANCEOF);
              
              foreach ($attributes as $attribute) {
                  $rule = $attribute->newInstance();
                  
                  if (!$rule->validate($value)) {
                      if (!isset($errors[$name])) {
                          $errors[$name] = [];
                      }
                      $errors[$name][] = $rule->getMessage();
                  }
              }
          }
          
          return $errors;
      }
  }
  
  // Example usage
  $formData = [
      'name' => 'Jo', // Too short
      'email' => 'not-an-email', // Invalid email
      'message' => 'Hello, world!' // Valid
  ];
  
  $request = new FormRequest($formData);
  $errors = $request->validate();
  
  if (empty($errors)) {
      echo "Form is valid!\n";
  } else {
      echo "Form has errors:\n";
      
      foreach ($errors as $field => $fieldErrors) {
          echo "- {$field}:\n";
          foreach ($fieldErrors as $error) {
              echo "  - {$error}\n";
          }
      }
  }
explanation: |
  This example demonstrates how to implement attribute-based validation:
  
  1. **Validation Rule Base Class**: We create an abstract `ValidationRule` class that all validation rules extend. It defines the interface for validation rules.
  
  2. **Specific Validation Rules**: We implement concrete validation rules like `Required`, `Email`, and `MinLength`, each with its own validation logic and error message.
  
  3. **Applying Rules to Properties**: We apply validation rules to properties using attributes. Multiple rules can be applied to the same property.
  
  4. **Validation Process**:
     - We use reflection to get all public properties of the form request
     - For each property, we get all validation rule attributes
     - We instantiate each rule and run its validation method
     - We collect error messages for any failed validations
  
  5. **Form Request Class**: The `FormRequest` class provides a convenient way to validate form data. It:
     - Accepts form data in the constructor
     - Provides a `validate()` method that returns validation errors
  
  This approach is similar to how Laravel's form requests work, but simplified for demonstration purposes.
challenges:
  - Add a new MaxLength validation rule that ensures a field doesn't exceed a certain length
  - Create a Numeric validation rule that ensures a field contains only numbers
  - Modify the FormRequest class to return true/false from validate() and provide a separate getErrors() method
  - Add a custom validation rule that checks if a password contains at least one uppercase letter, one lowercase letter, and one number
  - Extend the example to support validation of nested objects or arrays
:::
