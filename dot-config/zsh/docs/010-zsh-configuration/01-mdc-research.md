# Research Notes: Markdown Context (.mdc) Format

## Summary

Markdown Context (MDC) files, with a `.mdc` extension, are specialized Markdown documents that provide instructions, context, and coding standards to AI coding assistants. They are not a formal standard but a convention adopted by tools like Cursor AI. The core idea is to create a "rulebook" that guides AI tools to generate code that aligns with a project's specific requirements.

## Key Characteristics

*   **Base Format**: Standard Markdown. This makes them human-readable and easy to maintain.
*   **Purpose**:
    *   **Define Coding Standards**: Enforce style guides, naming conventions, error handling, etc.
    *   **Provide Project Context**: Describe project architecture, frameworks, libraries, and goals.
    *   **Task-Specific Guidelines**: Give instructions for specific tasks like Git workflows or debugging procedures.
    *   **Architectural Patterns**: Teach the AI about the project's established design patterns.
*   **Structure & Organization**:
    *   Often stored in a dedicated directory like `.cursor/rules/`.
    *   Can be modularized to mirror the codebase structure (e.g., `frontend.mdc`, `backend.mdc`).
    *   An `index.mdc` can serve as a central point for general rules.
*   **Metadata and Activation (Tool-Specific)**:
    *   AI tools may use metadata (often in comments or a separate config file) to control when rules are applied.
    *   Common metadata includes:
        *   `description`: A summary of the rule file's purpose.
        *   `globs`: File patterns (e.g., `*.py`, `src/components/**`) that trigger the AI to load this context.
        *   `alwaysApply`: A boolean to keep the context active at all times.
*   **Benefits**:
    *   **Consistency**: Ensures AI-generated code adheres to project standards.
    *   **Efficiency**: Reduces the need for repetitive instructions in prompts.
    *   **Accuracy**: Leads to more relevant and higher-quality AI output.
    *   **Collaboration**: Allows teams to version-control and share a common AI knowledge base.

## Application in this Project

Based on this research, the refactoring will proceed as follows:

1.  **`ai/AI-GUIDELINES.md`**: This main file will be a standard `.md` file. It will contain the high-level overview, principles, and links to the specialized modules. It is primarily for human consumption.
2.  **`ai/AI-GUIDELINES/`**: This directory will contain the specialized modules.
    *   **General Principles**: Files like `philosophy.md` or `general-best-practices.md` will be standard Markdown.
    *   **Project/Tech-Specific Context**: For each category provided by the user (e.g., `php-laravel/`, `javascript-typescript/`, `shell-cli/`), we will create `.mdc` files. These files will contain the specific, actionable context for the AI assistant when working on those types of projects. For example, `javascript-typescript/coding-style.mdc` would contain rules for Prettier, ESLint, and specific framework patterns.
3.  **Orchestration**: The `ai/orchestration-policy.md` will be refactored into the core of the new guidelines, likely informing both the main `.md` file and providing meta-instructions for how the different `.mdc` files should be used by the AI.

This hybrid `.md`/`.mdc` approach will provide a clear separation between human-readable philosophy and machine-actionable context, leveraging the strengths of the `.mdc` convention.
