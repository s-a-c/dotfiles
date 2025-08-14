# Developer Guidelines for Interactive Examples

This document provides guidelines for developers who want to add or modify interactive code examples in the UME tutorial documentation.

## Adding New Interactive Examples

### Markdown Syntax

Interactive examples are defined in markdown files using a special syntax:

```markdown
:::interactive-code
title: Example Title
description: A brief description of the example
language: php
editable: true
code: |
  <?php
  // Your PHP code here
  echo "Hello, World!";
explanation: |
  This example demonstrates a basic PHP script that outputs "Hello, World!".
  
  Key points to understand:
  - The `echo` statement is used to output text
  - PHP statements end with a semicolon
challenges: |
  - Modify the code to output your name instead
  - Add another echo statement to output a second line
  - Use a variable to store the message before outputting it
:::
```

### Required Parameters

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| title | The title of the example | Yes | - |
| description | A brief description of what the example demonstrates | Yes | - |
| language | The programming language (currently only 'php' is supported) | Yes | - |
| editable | Whether the code can be edited by the user | No | true |
| code | The initial code to display in the editor | Yes | - |
| explanation | An explanation of how the code works | Yes | - |
| challenges | A list of challenges for the user to try | No | [] |

### Best Practices

1. **Keep Examples Focused**: Each example should demonstrate a single concept or technique.
2. **Start Simple**: Begin with the simplest possible implementation of a concept.
3. **Provide Context**: Explain why the technique is useful and when to use it.
4. **Include Challenges**: Give users tasks to modify the code and experiment.
5. **Consider Edge Cases**: Include examples of error handling and edge cases.
6. **Be Consistent**: Follow the same style and structure across all examples.
7. **Test Thoroughly**: Ensure the code works as expected before adding it.

### Code Style

All PHP code in interactive examples should follow the [PSR-12](https://www.php-fig.org/psr/psr-12/) coding standard. Additionally:

- Use meaningful variable and function names
- Include comments to explain complex logic
- Use proper indentation (4 spaces)
- Keep lines under 80 characters when possible
- Use type hints for function parameters and return types

## Modifying Existing Examples

When modifying existing examples, follow these guidelines:

1. **Preserve Intent**: Ensure the example still demonstrates the original concept.
2. **Maintain Difficulty Level**: Don't make examples significantly harder or easier.
3. **Update Explanations**: Ensure explanations match the modified code.
4. **Test Changes**: Verify the modified example works correctly.
5. **Document Changes**: Note significant changes in the commit message.

## Creating Example Sets

For complex topics, consider creating a set of related examples that build on each other:

1. **Basic Example**: Introduce the fundamental concept.
2. **Intermediate Example**: Show more advanced usage.
3. **Advanced Example**: Demonstrate complex scenarios or edge cases.
4. **Real-World Example**: Show how the concept is used in a realistic application.

## Security Considerations

When creating examples, be mindful of security:

1. **Avoid Dangerous Functions**: Don't use functions like `eval`, `exec`, `system`, etc.
2. **Demonstrate Secure Practices**: Show proper input validation and output escaping.
3. **Don't Include Sensitive Data**: Even in examples, don't use real credentials or personal data.
4. **Highlight Security Implications**: Note when a technique has security considerations.

## Performance Considerations

Consider performance when creating examples:

1. **Keep Examples Efficient**: Avoid unnecessarily complex or resource-intensive code.
2. **Highlight Performance Implications**: Note when a technique has performance considerations.
3. **Show Optimizations**: When relevant, demonstrate how to optimize code.

## Accessibility Considerations

Ensure examples are accessible to all users:

1. **Use Clear Language**: Avoid jargon and explain technical terms.
2. **Provide Context**: Don't assume prior knowledge without explanation.
3. **Consider Screen Readers**: Ensure explanations make sense when read aloud.
4. **Use Proper Markup**: Follow HTML best practices in output examples.

## Testing Your Examples

Before submitting a new or modified example:

1. **Run the Code**: Ensure it executes without errors.
2. **Try the Challenges**: Verify that the challenges are doable and educational.
3. **Check in Different Browsers**: Test in Chrome, Firefox, and Safari at minimum.
4. **Test on Mobile**: Ensure the example works on smaller screens.
5. **Validate Accessibility**: Check that the example is accessible to all users.

## Submission Process

To submit a new or modified example:

1. Fork the repository
2. Create a branch for your changes
3. Add or modify the example following these guidelines
4. Test thoroughly
5. Submit a pull request with a clear description of your changes

Your submission will be reviewed for code quality, educational value, and adherence to these guidelines.
