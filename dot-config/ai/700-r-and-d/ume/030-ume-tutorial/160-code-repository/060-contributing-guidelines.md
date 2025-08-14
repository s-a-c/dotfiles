# Contributing Guidelines

<link rel="stylesheet" href="../assets/css/styles.css">

Thank you for your interest in contributing to the UME project! This guide provides detailed information on how to contribute effectively, from reporting bugs to submitting pull requests and participating in the development process.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [How to Contribute](#how-to-contribute)
4. [Reporting Bugs](#reporting-bugs)
5. [Suggesting Features](#suggesting-features)
6. [Development Workflow](#development-workflow)
7. [Pull Request Process](#pull-request-process)
8. [Coding Standards](#coding-standards)
9. [Testing Guidelines](#testing-guidelines)
10. [Documentation Guidelines](#documentation-guidelines)
11. [Community Contributions](#community-contributions)
12. [Recognition](#recognition)

## Code of Conduct

The UME project is committed to fostering an open and welcoming environment. By participating, you are expected to uphold our [Code of Conduct](070-code-of-conduct.md), which includes:

- Using welcoming and inclusive language
- Being respectful of differing viewpoints and experiences
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

## Getting Started

### Prerequisites

Before you begin contributing, ensure you have:

- PHP 8.1 or higher
- Composer
- Node.js and NPM
- Git
- A GitHub account
- Familiarity with Laravel

### Setting Up the Development Environment

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/ume-core.git
   cd ume-core
   ```

3. Add the original repository as an upstream remote:
   ```bash
   git remote add upstream https://github.com/ume-tutorial/ume-core.git
   ```

4. Install dependencies:
   ```bash
   composer install
   npm install
   ```

5. Set up the environment:
   ```bash
   cp .env.example .env
   php artisan key:generate
   ```

6. Run migrations:
   ```bash
   php artisan migrate
   ```

7. Start the development server:
   ```bash
   php artisan serve
   ```

## How to Contribute

There are many ways to contribute to the UME project:

### 1. Code Contributions

- Fixing bugs
- Implementing new features
- Improving existing functionality
- Optimizing performance
- Enhancing security

### 2. Documentation

- Improving existing documentation
- Adding missing documentation
- Translating documentation
- Creating tutorials or guides

### 3. Testing

- Writing unit tests
- Creating feature tests
- Performing manual testing
- Reporting test results

### 4. Design

- Improving UI/UX
- Creating visual assets
- Designing new interfaces
- Enhancing accessibility

### 5. Community Support

- Answering questions in discussions
- Helping new contributors
- Reviewing pull requests
- Participating in planning

## Reporting Bugs

When reporting bugs, please include:

1. **Clear Title**: A descriptive title that summarizes the issue
2. **Environment Details**:
   - UME version
   - Laravel version
   - PHP version
   - Browser (if applicable)
   - Operating system

3. **Steps to Reproduce**:
   - Detailed steps to reproduce the bug
   - Code examples if applicable
   - Configuration details

4. **Expected Behavior**: What you expected to happen

5. **Actual Behavior**: What actually happened
   - Include screenshots if applicable
   - Include error messages and stack traces

6. **Possible Solution**: If you have suggestions on how to fix the issue

Use the [Issue Tracker](https://github.com/ume-tutorial/ume-core/issues) with the "bug" label.

## Suggesting Features

Feature suggestions are welcome! When suggesting features:

1. **Check Existing Suggestions**: Ensure the feature hasn't already been suggested
2. **Clear Description**: Provide a clear description of the feature
3. **Use Case**: Explain the use case and benefits
4. **Implementation Ideas**: If you have ideas on how to implement it
5. **Mockups**: Include mockups or diagrams if applicable

Use the [Issue Tracker](https://github.com/ume-tutorial/ume-core/issues) with the "enhancement" label.

## Development Workflow

The UME project follows a Git workflow based on feature branches:

1. **Main Branches**:
   - `main`: Production-ready code
   - `develop`: Integration branch for features

2. **Feature Branches**:
   - Create branches from `develop`
   - Use naming convention: `feature/feature-name`
   - Example: `feature/team-permissions`

3. **Bug Fix Branches**:
   - Create branches from `develop` or the affected release branch
   - Use naming convention: `bugfix/bug-description`
   - Example: `bugfix/auth-redirect-issue`

4. **Release Branches**:
   - Created from `develop` when preparing a release
   - Use naming convention: `release/version`
   - Example: `release/1.0.0`

5. **Hotfix Branches**:
   - Created from `main` for critical fixes
   - Use naming convention: `hotfix/description`
   - Example: `hotfix/security-vulnerability`

### Keeping Your Fork Updated

Regularly update your fork with changes from the upstream repository:

```bash
git checkout develop
git fetch upstream
git merge upstream/develop
git push origin develop
```

## Pull Request Process

1. **Create a Feature Branch**:
   ```bash
   git checkout develop
   git pull upstream develop
   git checkout -b feature/your-feature-name
   ```

2. **Make Your Changes**:
   - Follow coding standards
   - Write tests for your changes
   - Update documentation as needed

3. **Commit Your Changes**:
   - Use clear commit messages
   - Reference issue numbers if applicable
   - Follow the [Conventional Commits](https://www.conventionalcommits.org/) format:
     ```
     type(scope): description
     
     [optional body]
     
     [optional footer]
     ```
   - Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
   - Example: `feat(teams): add team hierarchy functionality`

4. **Push to Your Fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

5. **Create a Pull Request**:
   - Go to the original repository on GitHub
   - Click "New Pull Request"
   - Select your branch
   - Fill out the PR template
   - Reference related issues

6. **Code Review Process**:
   - Maintainers will review your PR
   - Address any feedback or requested changes
   - Update your branch as needed

7. **Merge Requirements**:
   - All tests must pass
   - Code must meet coding standards
   - Documentation must be updated
   - At least one maintainer approval is required

## Coding Standards

The UME project follows the [PSR-12](https://www.php-fig.org/psr/psr-12/) coding standard and Laravel best practices:

### PHP Code Style

- Use PSR-12 coding style
- Follow Laravel naming conventions
- Use type hints and return types
- Use PHP 8 features appropriately
- Document code with PHPDoc comments

### JavaScript Code Style

- Follow Airbnb JavaScript Style Guide
- Use ES6+ features
- Document complex functions

### CSS/SCSS Style

- Use BEM naming convention
- Follow component-based structure
- Maintain responsive design principles

### Tools

We use the following tools to enforce coding standards:

- PHP_CodeSniffer for PHP code style
- ESLint for JavaScript
- StyleLint for CSS/SCSS

Run the linters before submitting a PR:

```bash
composer run lint
npm run lint
```

## Testing Guidelines

All contributions should include appropriate tests:

### Types of Tests

1. **Unit Tests**: Test individual components in isolation
2. **Feature Tests**: Test complete features
3. **Integration Tests**: Test component interactions
4. **Browser Tests**: Test UI interactions with Laravel Dusk

### Testing Requirements

- Maintain or improve test coverage
- Tests must pass before merging
- New features require new tests
- Bug fixes should include regression tests

### Running Tests

```bash
# Run all tests
php artisan test

# Run specific test suite
php artisan test --testsuite=Feature

# Run specific test
php artisan test --filter=TeamTest
```

## Documentation Guidelines

Documentation is crucial for the UME project:

### Code Documentation

- Use PHPDoc comments for classes, methods, and properties
- Document complex logic with inline comments
- Keep comments up-to-date with code changes

### User Documentation

- Write clear, concise documentation
- Include examples and use cases
- Use proper Markdown formatting
- Include screenshots or diagrams when helpful

### Documentation Structure

- Follow the established documentation structure
- Place documentation in the appropriate section
- Link related documentation

## Community Contributions

We welcome contributions from the community beyond code:

### Translation

- Help translate the UI and documentation
- Follow the translation guidelines
- Use the provided translation tools

### Support

- Help answer questions in discussions
- Provide guidance to new contributors
- Share your knowledge and experience

### Advocacy

- Promote the UME project
- Write blog posts or tutorials
- Give talks or presentations

## Recognition

Contributors are recognized in several ways:

- All contributors are listed in the [CONTRIBUTORS.md](https://github.com/ume-tutorial/ume-core/blob/main/CONTRIBUTORS.md) file
- Significant contributions are highlighted in release notes
- Regular contributors may be invited to join the core team

## Communication Channels

- **GitHub Issues**: For bug reports and feature requests
- **GitHub Discussions**: For questions and general discussion
- **Slack Channel**: For real-time communication
- **Monthly Video Calls**: For planning and coordination

## License

By contributing to the UME project, you agree that your contributions will be licensed under the project's [MIT License](https://github.com/ume-tutorial/ume-core/blob/main/LICENSE).

## Questions?

If you have any questions about contributing, please reach out to the maintainers at [contributors@ume-tutorial.com](mailto:contributors@ume-tutorial.com) or open a discussion on GitHub.
