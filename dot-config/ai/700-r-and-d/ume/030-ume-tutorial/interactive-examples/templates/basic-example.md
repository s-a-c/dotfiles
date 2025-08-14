# Basic Interactive Example Template

This template demonstrates a basic interactive code example using the Markdown-based approach.

## Example Usage

```markdown
:::interactive-code
title: Example Title
description: Brief description of the example
language: php
editable: true
code: |
  <?php
  
  // Your PHP code here
  echo "Hello, World!";
explanation: |
  Explanation of how the code works.
  
  - Bullet points for key concepts
  - More details about the code
challenges: |
  - Challenge 1 description
  - Challenge 2 description
:::
```

## Parameters

### Required Parameters

- `title`: The title of the example
- `description`: A brief description of the example
- `code`: The initial code for the example
- `explanation`: Explanation of how the code works

### Optional Parameters

- `language`: The programming language (default: "php")
- `editable`: Whether the code can be edited (default: true)
- `challenges`: Optional challenges for the user

## Example

:::interactive-code
title: Hello World Example
description: A simple PHP example that prints "Hello, World!"
language: php
editable: true
code: |
  <?php
  
  function sayHello($name = 'World') {
      return "Hello, $name!";
  }
  
  echo sayHello();
  echo "\n";
  echo sayHello('PHP');
explanation: |
  This example demonstrates a simple PHP function:
  
  - The `sayHello()` function takes an optional parameter `$name`
  - If no name is provided, it defaults to 'World'
  - The function returns a greeting string
  - We call the function twice, once with the default parameter and once with 'PHP'
challenges: |
  - Modify the function to accept multiple names and greet all of them
  - Add a parameter to customize the greeting (e.g., "Hi" instead of "Hello")
  - Make the function capitalize the first letter of each name
:::

## Best Practices

1. Keep examples focused on a single concept
2. Provide clear explanations
3. Include meaningful challenges
4. Ensure code is complete and runnable
5. Use proper formatting and indentation
