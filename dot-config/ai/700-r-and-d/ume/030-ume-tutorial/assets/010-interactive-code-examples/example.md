# Interactive Code Example

This is an example of an interactive code example using the Monaco Editor and PHP execution backend.

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
explanation: |
  This example demonstrates a simple PHP function that returns a greeting.
  
  - The function is named `sayHello`
  - It accepts an optional parameter `$name` with a default value of 'World'
  - It returns a string with the greeting
  - We call the function and echo its result
challenges:
  - Modify the function to accept a second parameter for the greeting (e.g., "Hi" instead of "Hello")
  - Change the function to return an array of greetings in different languages
  - Add error handling to ensure the name parameter is a string
:::

## How to Use

1. Edit the code in the editor
2. Click "Run Code" to execute the code
3. See the output in the panel below the editor
4. Click "Reset" to restore the original code
5. Click "Copy" to copy the code to the clipboard

## Creating Your Own Examples

To create your own interactive code examples, use the following syntax:

```markdown
:::interactive-code
title: Example Title
description: Brief description of the example
language: php
editable: true
code: |
  <?php
  
  // Your PHP code here
  
explanation: |
  Explanation of how the code works.
  
  - Bullet points for key concepts
  - More details about the code
challenges:
  - Challenge 1 description
  - Challenge 2 description
:::
```

## Implementation Details

The interactive code examples are implemented using:

1. **Monaco Editor**: The editor that powers VS Code, loaded from CDN
2. **PHP Execution Backend**: A Laravel API endpoint that safely executes PHP code
3. **Local Storage**: To save user modifications between sessions

The implementation is designed to be:

- **Secure**: Code is executed in a sandboxed environment
- **Responsive**: Works on desktop and mobile devices
- **Accessible**: Supports keyboard navigation and screen readers
- **Theme-aware**: Automatically adapts to light and dark modes
