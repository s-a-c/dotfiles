UME TUTORIAL INTERACTIVE CODE EXAMPLES
=======================================

This directory contains interactive code examples for the User Model Enhancements (UME) tutorial.

GETTING STARTED
--------------
1. Start by reading the main index file: index.md
2. For a guide on how to use the interactive examples, see: using-interactive-examples.md
3. For a comprehensive overview of all phases, see: all-phases-summary.md
4. For an example of interactive code examples, see: example.md

IMPLEMENTATION
-------------
The interactive code examples are implemented using:

1. Monaco Editor: The editor that powers VS Code, loaded from CDN
   - File: monaco-loader.js
   - Features: Syntax highlighting, code completion, error checking, dark/light mode support

2. PHP Execution Backend: A Laravel API endpoint for executing PHP code
   - Files: CodeExecutionController.php, routes/api.php
   - Features: Code validation, sandboxed execution, error handling

3. Interactive Examples Integration: JavaScript for processing and creating examples
   - File: interactive-examples.js
   - Features: Custom Markdown syntax, local storage for saving modifications

DIRECTORY STRUCTURE
------------------
- Phase-specific examples are named with the pattern: phase{phase_number}-{example_number}-{descriptive_name}.md
- Each phase has its own index file: phase{phase_number}-index.md
- JavaScript files are in the assets/js directory
- CSS files are in the assets/css directory
- Additional resources are available in the root directory

USAGE
-----
To use the interactive code examples in your documentation, use the following syntax:

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

FILE FORMATS
-----------
- All examples are provided in Markdown format (.md)
- Code snippets within the examples use PHP syntax highlighting
- Diagrams use Mermaid syntax for rendering

BROWSER COMPATIBILITY
-------------------
These examples work best in modern browsers. For details, see:
- browser-compatibility-report.md
- device-compatibility-report.md

SECURITY CONSIDERATIONS
---------------------
The PHP execution backend includes several security measures:

1. Code Validation: The code is validated before execution
2. Sandboxed Environment: The code is executed in a sandboxed environment
3. Disabled Functions: Dangerous functions are disabled
4. Time Limit: A time limit is set to prevent infinite loops
5. Output Buffering: Output is captured to prevent unexpected behavior

LICENSE
-------
All examples are provided under the MIT License. See LICENSE.md for details.

CONTRIBUTING
-----------
Contributions are welcome! See CONTRIBUTORS.md for guidelines.

CHANGELOG
---------
For a history of changes, see CHANGELOG.md.

CONTACT
-------
For questions or support, please open an issue in the repository.
