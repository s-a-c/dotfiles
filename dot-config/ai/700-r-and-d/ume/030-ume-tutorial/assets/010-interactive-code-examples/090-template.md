# Interactive Code Example Template

This template provides a standardized structure for creating interactive code examples in the UME tutorial documentation.

## Basic Structure

Each interactive code example should include:

1. **Title**: Clear, descriptive title of what the example demonstrates
2. **Description**: Brief explanation of the concept being demonstrated
3. **Code Editor**: Interactive editor with the code example
4. **Expected Output**: What the user should expect to see when running the code
5. **Explanation**: Detailed explanation of how the code works
6. **Challenges**: Optional exercises for the user to modify the code

## HTML Template

```html
<div class="interactive-code-example">
  <h3 class="example-title">Example: [Title]</h3>
  
  <div class="example-description">
    <p>[Brief description of what this example demonstrates]</p>
  </div>
  
  <div class="code-editor-container" data-language="php" data-editable="true">
    <div class="editor-toolbar">
      <button class="run-button">Run Code</button>
      <button class="reset-button">Reset</button>
      <button class="copy-button">Copy</button>
      <div class="editor-status"></div>
    </div>
    
    <div class="monaco-editor" data-code="[Initial code goes here]"></div>
    
    <div class="output-panel">
      <div class="output-header">Output</div>
      <div class="output-content"></div>
    </div>
  </div>
  
  <div class="example-explanation">
    <h4>How it works</h4>
    <p>[Detailed explanation of the code]</p>
    <ul>
      <li>[Key point 1]</li>
      <li>[Key point 2]</li>
      <li>[Key point 3]</li>
    </ul>
  </div>
  
  <div class="example-challenges">
    <h4>Challenges</h4>
    <ol>
      <li>[Challenge 1]</li>
      <li>[Challenge 2]</li>
    </ol>
  </div>
</div>
```

## Markdown Usage

In Markdown files, the interactive code example can be included using a custom syntax:

```markdown
:::interactive-code
title: Example Title
description: Brief description of the example
language: php
editable: true
code: |
  <?php
  
  function example() {
      return "Hello, World!";
  }
  
  echo example();
explanation: |
  This example demonstrates a simple PHP function that returns a greeting.
  
  - The function is named `example`
  - It returns a string
  - We call the function and echo its result
challenges:
  - Modify the function to accept a name parameter
  - Change the greeting to "Hello, [name]!"
:::
```

## CSS Styling

The interactive code examples should be styled to match the UME documentation theme, with support for both light and dark modes.

```css
.interactive-code-example {
  border: 1px solid var(--border-color);
  border-radius: 8px;
  margin: 2em 0;
  overflow: hidden;
}

.example-title {
  background-color: var(--primary-color);
  color: white;
  margin: 0;
  padding: 0.75em 1em;
}

.example-description {
  padding: 1em;
  background-color: var(--code-background);
  border-bottom: 1px solid var(--border-color);
}

.code-editor-container {
  height: 300px;
  position: relative;
}

.editor-toolbar {
  display: flex;
  padding: 0.5em;
  background-color: var(--code-background);
  border-bottom: 1px solid var(--border-color);
}

.monaco-editor {
  height: calc(100% - 40px - 150px);
}

.output-panel {
  height: 150px;
  border-top: 1px solid var(--border-color);
  background-color: var(--code-background);
  overflow: auto;
}

.output-header {
  padding: 0.5em;
  font-weight: bold;
  border-bottom: 1px solid var(--border-color);
}

.output-content {
  padding: 0.5em;
  font-family: monospace;
  white-space: pre-wrap;
}

.example-explanation, .example-challenges {
  padding: 1em;
  border-top: 1px solid var(--border-color);
}

/* Button styling */
.editor-toolbar button {
  margin-right: 0.5em;
  padding: 0.25em 0.75em;
  border-radius: 4px;
  border: 1px solid var(--border-color);
  background-color: var(--background-color);
  cursor: pointer;
}

.run-button {
  background-color: var(--secondary-color) !important;
  color: white;
}

/* Dark mode adjustments handled by CSS variables */
```

## JavaScript Implementation

The interactive code examples require JavaScript to:

1. Initialize the Monaco Editor
2. Handle the Run, Reset, and Copy buttons
3. Process and display the output
4. Save user modifications

This functionality will be implemented in a dedicated JavaScript file.

## Example Usage

Here's a complete example of how to use the interactive code example template:

```markdown
# PHP 8 Attributes Example

:::interactive-code
title: Creating a Custom Attribute
description: This example demonstrates how to create and use a custom PHP 8 attribute.
language: php
editable: true
code: |
  <?php
  
  #[Attribute]
  class Route {
      public function __construct(
          public string $method,
          public string $path
      ) {}
  }
  
  #[Route(method: 'GET', path: '/users')]
  function getUsers() {
      return 'This would return users';
  }
  
  // Using reflection to read the attribute
  $reflection = new ReflectionFunction('getUsers');
  $attributes = $reflection->getAttributes(Route::class);
  
  foreach ($attributes as $attribute) {
      $route = $attribute->newInstance();
      echo "Method: {$route->method}, Path: {$route->path}";
  }
explanation: |
  This example shows how to:
  
  1. Define a custom attribute class `Route` with the `#[Attribute]` attribute
  2. Apply the attribute to a function with parameters
  3. Use reflection to read the attribute at runtime
  4. Access the attribute's properties
challenges:
  - Add a new parameter to the Route attribute for middleware
  - Create a second function with a different route and display both routes
  - Modify the attribute to be repeatable and apply multiple routes to one function
:::
```
