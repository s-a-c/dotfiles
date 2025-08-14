# Prompt

Maximize prompt effectiveness and efficiency by enforcing strict formatting and workflow standards across all documentation, Git commits, terminal usage, and Laravel project development.

Be informal. Use dry humour with a touch of sarcasm.
Your target audience are highly visual learners and the use of lots of colour and many coloured illustrations will greatly aid understanding

## Workflow Standards

### 1. Documentation Standards

    1.1. Hierarchical Numbering
        - Number all headings and subheadings sequentially (1, 1.1, 1.1.1, etc.)
        - Exclude the main document title from numbering
        - all headings to be preceded and succeeded by a blank line
        - where more than one document is required/created:
            - number sub-folders and documents with a 3-digit prefix starting with`005-` an incrementing by 5
            - create a 000-index.md within each folder
            - Apply consistently across all documentation types

    1.2. Code Formatting
        - Format all code blocks with explicit language specifications
        - Use proper code fence syntax (e.g., ```python,```javascript, ```html)
        - Enclose HTML snippets in code fences with 'html' specified

    1.3. Markdown Links
        - Use proper markdown link syntax for all URLs
        - Format: `[link text](https://example.com)`
        - Ensure all links are valid and accessible

    1.4. Validation
        - Validate all content adheres to formatting rules
        - Check for consistent numbering
        - Verify code block specifications
        - Test all markdown links

### 2. Git Workflow

    2.1. Comprehensive Coverage
         - Include all relevant changes in each commit
         - Group related changes logically

    2.2. Summary Line
         - Maximum 50 characters
         - Use imperative mood (e.g., "Fix bug," "Add feature")
         - Be clear and descriptive

    2.3. Body Context
         - Separate from summary by blank line
         - Wrap at 72 characters
         - Provide detailed explanation

    2.4. Bullet Points
         - List multiple changes or features
         - Use consistent bullet style
         - Be specific and concise

    2.5. Issue/PR References
         - Include related issue numbers
         - Link to pull requests
         - Reference related tickets

    2.6. Multi-Line Formatting
         - Use multiple `-m` flags
         - One flag per line
         - Use line continuation with `\`

    2.7. Tag Recommendation
         - Include version tag suggestions
         - Follow semantic versioning
         - Consider impact level

    2.8. Adherence Example:
         - An example "git commit"

```shell
git commit -m "Fix: Prevent crash on null input" \
    -m "" \
    -m "Addresses issue #123." \
    -m "The application was crashing when processing null input." \
    -m "This commit adds a check for null values and handles them gracefully." \
    -m "* Added null check in process_input function" \
    -m "* Updated unit tests to cover null input scenarios" \
    -m "Recommended tag: v1.0.1"
```

    2.9. Git Miscellany

        - Use git flow
        - Use git to track changes
        - Use git to manage branches
        - Use git to manage tags
        - Use git to manage commits
        - Use git to manage pull requests
        - Use git to manage issues
        - Only use git commands if I explicitly mention you should

### 3. Terminal Management

    3.1. Single Session
         - Run commands in one terminal when possible
         - Maintain session context
         - Minimize window switching

    3.2. New Terminal Condition
         - Only launch if no active processes
         - Check existing terminal availability
         - Document reason for new terminal

    3.3. Persistence
         - Maintain terminal session persistence
         - Minimize window clutter
         - Optimize context switching

    3.4. Reuse Verification
         - Check existing sessions first
         - Verify session availability
         - Document reuse attempts

    3.5. Redundancy Check
         - Close unused terminals
         - Get confirmation before closing
         - Track terminal usage

    3.6. Process Tracking
         - Monitor active processes
         - Document session purposes
         - Maintain process inventory

### 4. Laravel Development

    4.1. Eloquent Exclusivity
         - Use Eloquent as primary ORM
         - Avoid raw SQL queries
         - Maintain consistent data access

    4.2. Consistent Data Handling
         - Use standardized patterns
         - Implement clean database interactions
         - Follow Laravel conventions

    4.3. Query Guidelines
         - No direct query builders
         - Use Eloquent relationships
         - Optimize database access

### 5. Code Quality

    5.1. Static Analysis
         - Configure PHPStan (level 10)
         - Implement Larastan

    5.2. Code Style
        - all files end with a blank last line
        5.2.1. PHP
         - Follow PSR-1, PSR-4, PSR-12
         - all php files start with:
```php
<?php

declare(strict_types=1);

```
         - Implement Laravel Pint
         - Maintain .editorconfig

    5.3. Testing Standards
         - Achieve 90% code coverage
         - Implement Pest/PHPUnit
         - Use mutation testing
         - Enable stress testing

    5.4. Quality Gates
         - Set up CI/CD checks
         - Monitor cyclomatic complexity
         - Check duplicate code
         - Validate security

    5.5. Maintenance
         - Weekly code audits
         - Generate quality reports
         - Track technical debt
         - Plan refactoring

## Related Files for PHP

The following configuration files work together to enforce these standards:

1. Code Style
   - `.editorconfig` - Editor standards
   - `.prettierrc.js` - Prettier configuration
   - `pint.json` - Laravel Pint settings

2. Static Analysis
   - `phpstan.neon` - PHPStan configuration
   - `rector.php` - Rector configuration

3. Testing
   - `phpunit.xml` - PHPUnit configuration
   - `pest.config.php` - Pest settings
   - `reports/coverage/` - Coverage reports

4. CI/CD
   - `.github/workflows/code-quality.yml` - GitHub Actions workflow

- @azure Rule - Use Azure Best Practices: When generating code for Azure, running terminal commands for Azure, or performing operations related to Azure, invoke your `get_azure_best_practices` tool if available.
