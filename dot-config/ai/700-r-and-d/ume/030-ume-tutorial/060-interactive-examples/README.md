# Interactive Examples for UME Tutorial

This directory contains the interactive code examples system for the UME tutorial documentation.

## Overview

The interactive examples system allows users to experiment with PHP code directly in their browser. It provides a rich code editing experience with syntax highlighting, error checking, and immediate execution.

## Features

- **Monaco Editor Integration**: Powerful code editor with syntax highlighting and error checking
- **PHP Code Execution**: Secure execution of PHP code in a sandboxed environment
- **Local Storage**: Persistence of user modifications between sessions
- **Responsive Design**: Works on desktop and mobile devices
- **Accessibility**: Keyboard navigation, screen reader support, and high contrast mode
- **Cross-Browser Compatibility**: Works in all modern browsers

## Directory Structure

```
interactive-examples/
├── 010-documentation/       # System documentation
│   ├── 010-system-overview.md
│   ├── 020-developer-guidelines.md
│   ├── 030-api-documentation.md
│   ├── 040-user-guide.md
│   ├── 050-deployment-guide.md
│   └── 060-maintenance-guide.md
├── samples/                 # Sample interactive examples
│   ├── php8-attributes.md
│   └── ...
├── templates/               # Templates for creating new examples
│   └── basic-example.md
└── README.md                # This file
```

## Getting Started

To use the interactive examples in your documentation:

1. Include the required JavaScript and CSS files in your HTML:

```html
<link rel="stylesheet" href="/assets/css/interactive/interactive.css">
<script src="/assets/js/interactive/editor/monaco-loader.js"></script>
<script src="/assets/js/code-executor.js"></script>
<script src="/assets/js/interactive-examples.js"></script>
```

2. Add an interactive example to your markdown:

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

3. The processor will automatically convert this to an interactive example.

## Documentation

For more information, see the documentation in the `010-documentation/` directory:

- [System Overview](010-documentation/010-system-overview.md): High-level overview of the system
- [Developer Guidelines](010-documentation/020-developer-guidelines.md): Guidelines for adding and modifying examples
- [API Documentation](010-documentation/030-api-documentation.md): Details about the API endpoints
- [User Guide](010-documentation/040-user-guide.md): Guide for users of the interactive examples
- [Deployment Guide](010-documentation/050-deployment-guide.md): Instructions for deploying the system
- [Maintenance Guide](010-documentation/060-maintenance-guide.md): Guide for maintaining the system

## Contributing

To contribute to the interactive examples system:

1. Fork the repository
2. Create a branch for your changes
3. Make your changes following the [Developer Guidelines](010-documentation/020-developer-guidelines.md)
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
