# PHP 8 Attributes - Attribute Targets

:::interactive-code
title: Specifying Attribute Targets
description: This example shows how to restrict where attributes can be applied using target flags.
language: php
editable: true
code: |
  <?php
  
  // Define an attribute that can only be applied to classes
  #[Attribute(Attribute::TARGET_CLASS)]
  class ClassOnly {
      public function __construct(
          public string $name
      ) {}
  }
  
  // Define an attribute that can only be applied to methods
  #[Attribute(Attribute::TARGET_METHOD)]
  class MethodOnly {
      public function __construct(
          public string $name
      ) {}
  }
  
  // Define an attribute that can be applied to both classes and properties
  #[Attribute(Attribute::TARGET_CLASS | Attribute::TARGET_PROPERTY)]
  class ClassOrProperty {
      public function __construct(
          public string $name
      ) {}
  }
  
  // Apply attributes to different targets
  #[ClassOnly(name: 'ExampleClass')]
  class Example {
      #[ClassOrProperty(name: 'exampleProperty')]
      public string $property;
      
      #[MethodOnly(name: 'exampleMethod')]
      public function method() {
          return 'Hello';
      }
  }
  
  // Use reflection to read and validate the attributes
  $classReflection = new ReflectionClass(Example::class);
  $propertyReflection = $classReflection->getProperty('property');
  $methodReflection = $classReflection->getMethod('method');
  
  // Check class attributes
  $classAttributes = $classReflection->getAttributes();
  echo "Class attributes:\n";
  foreach ($classAttributes as $attribute) {
      echo "- " . $attribute->getName() . "\n";
  }
  
  // Check property attributes
  $propertyAttributes = $propertyReflection->getAttributes();
  echo "\nProperty attributes:\n";
  foreach ($propertyAttributes as $attribute) {
      echo "- " . $attribute->getName() . "\n";
  }
  
  // Check method attributes
  $methodAttributes = $methodReflection->getAttributes();
  echo "\nMethod attributes:\n";
  foreach ($methodAttributes as $attribute) {
      echo "- " . $attribute->getName() . "\n";
  }
explanation: |
  This example demonstrates how to specify where attributes can be applied:
  
  1. **Target Flags**: The `Attribute` constructor accepts flags that specify where the attribute can be applied:
     - `Attribute::TARGET_CLASS`: Can be applied to classes
     - `Attribute::TARGET_METHOD`: Can be applied to methods
     - `Attribute::TARGET_PROPERTY`: Can be applied to properties
     - `Attribute::TARGET_PARAMETER`: Can be applied to function/method parameters
     - `Attribute::TARGET_FUNCTION`: Can be applied to functions
     - `Attribute::TARGET_CLASS_CONSTANT`: Can be applied to class constants
     
  2. **Combining Targets**: You can combine targets using the bitwise OR operator (`|`) to allow an attribute to be applied to multiple targets.
  
  3. **Validation**: PHP will validate attribute usage at compile time. If you try to apply an attribute to a target that isn't allowed, PHP will raise a compile-time error.
  
  4. **Reflection**: You can use the Reflection API to read attributes from different elements (classes, methods, properties, etc.).
challenges:
  - Create a new attribute that can only be applied to parameters and apply it to a method parameter
  - Modify the ClassOrProperty attribute to also allow it on methods
  - Try applying an attribute to a target that isn't allowed and observe the error
  - Create an attribute that can be applied anywhere using Attribute::TARGET_ALL
  - Add a method to validate that attributes are applied to the correct targets
:::
