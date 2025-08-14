Create a comprehensive, maintainable unit test suite for the entire app/ directory, using Pest v4 exclusively with let(), beforeEach(), and afterEach(), and produce the following deliverables and constraints:

Scope and discovery
- Recursively discover and list all modules, components, services, utilities, helpers, middleware, controllers, models, DTOs, configuration loaders, and any custom decorators or hooks under app/.
- For each discovered unit, enumerate its public interface and critical internal functions that warrant direct testing (only when public tests are insufficient).
- Identify external dependencies (network, I/O, databases, caches, message queues, environment variables, time, randomness, OS-specific features) used by each unit.

Framework, tooling, and conventions
- Detect the project’s existing test framework, assertion library, mocking/stubbing/spying tools, and directory conventions.
- If no test framework is detected, integrate Pest v4 for PHP as the sole testing framework, with rationale emphasizing minimal footprint, expressive syntax, strong ecosystem, and compatibility with Laravel/Symfony and vanilla PHP.
- Adhere to idiomatic Pest structure: tests/ as root for tests, PSR-4 autoloading for tests if needed, and consistent naming (e.g., ClassNameTest.php or Feature/Unit folders).
- Use Pest v4 syntax exclusively; avoid PHPUnit-style classes. Prefer closures, test(), describe(), it(), datasets(), uses(), and Pest plugins where appropriate.
- Configure coverage with Xdebug or PCOV to produce line, branch, and method coverage, including HTML and CI-friendly formats (lcov and Cobertura). Enforce minimum thresholds of 90% for lines and branches via phpunit.xml or pest config.
- Ensure compatibility with static analysis using Larastan level 10 (for Laravel) or PHPStan level max otherwise. Add minimal, justified baselines or ignores; prefer code improvements over suppressions.

Test design and quality
- Write unit tests covering core logic, boundary values, edge cases, and explicit error/failure modes for each unit.
- Ensure tests are deterministic and fast by mocking/stubbing all external dependencies (I/O, network, DB, time, randomness, environment). Use fake timers/clock abstractions, deterministic seeds, in-memory fakes, and dependency injection.
- Test public interfaces primarily; test critical internals only when necessary to cover otherwise unobservable logic paths.
- Include robust tests for:
  - Asynchronous behavior and concurrency abstractions (e.g., queues, jobs, retries/backoff) applicable to PHP environments.
  - Configuration loading/overrides, environment matrices (.env.*), default fallbacks, and validation.
  - Serialization/deserialization, schema validation, and data transformation.
  - Caching behavior, invalidation, and TTLs.
  - Error propagation, custom exceptions, and logging/metrics side-effects (mocked).
  - Boundary limits (min/max sizes, timeouts), locale/timezone differences, platform nuances.
- Avoid brittle tests tied to implementation details. Prefer behavior-driven assertions and contract tests for public APIs. Use property-based/fuzz testing via suitable Pest plugins or custom datasets where beneficial.
- Ensure all tests pass 100% locally and in CI. For Laravel, ensure the codebase passes Larastan level 10 without reducing strictness; introduce minimal refactors to improve types and testability if needed.

Refactors for testability
- Propose and implement minimal, behavior-preserving refactors to improve testability and type-safety: dependency injection, interface extraction, pure function isolation, side-effect boundaries, configuration via parameters, time/clock abstractions, deterministic randomness providers.
- Provide clear, conventional commit messages for any refactors and configuration changes.

Fixtures and utilities
- Provide reusable Pest fixtures using let(), beforeEach(), and afterEach() for setup/teardown; add shared test helpers, factory methods/builders, and test doubles (stubs/mocks/fakes/spies) with minimal boilerplate.
- Prefer lightweight, local test doubles; reset all mocks/stubs between tests.
- Use snapshot or golden file testing only when stable and appropriate; otherwise prefer structured assertions.

Platform and CI integration
- Ensure tests run reliably across Linux, macOS, and Windows, and across supported PHP versions/architectures.
- Add or update CI configuration (GitHub Actions preferred; support GitLab CI/CircleCI/Azure Pipelines if already present) to:
  - Install dependencies and required PHP extensions (Xdebug/PCOV) conditionally.
  - Default to mocks for unit tests; only provision services (DB, cache) for integration if explicitly needed.
  - Run tests in parallel (Pest parallel) and/or shard by matrix to reduce runtime.
  - Generate and upload coverage artifacts (HTML, lcov, Cobertura).
  - Enforce coverage thresholds and static analysis gates (Larastan level 10 where applicable) and coding standards.
  - Support a PHP version matrix (e.g., 8.1–8.3) and dependency matrix (lowest/stable).

Documentation
- Add or update CONTRIBUTING.md or TESTING.md with:
  - Prerequisites and local setup, including enabling Xdebug/PCOV.
  - Commands to run tests (unit, watch, parallel, with filters) and view coverage locally and in CI.
  - How to add new tests and organize them by module/type using Pest conventions.
  - Best practices used (mocking, fixtures with let()/beforeEach()/afterEach(), property tests, deterministic seeds).
  - Guidance for writing deterministic tests and avoiding flaky behavior.

Output
1) A complete, hierarchical list of discovered app/ modules/files with the corresponding test files to be created, including file paths (tests/… using Pest structure).
2) The complete Pest v4 test implementations for each unit, organized by convention, using let(), beforeEach(), and afterEach() consistently. Include datasets and plugins where appropriate.
3) All added or updated configuration files with inline comments:
   - pest.php configuration with plugins, paths, and parallel settings.
   - phpunit.xml.dist for coverage, process isolation as needed, and strictness.
   - phpstan.neon / larastan.neon at level 10, with justified baseline if any.
   - composer.json updates (scripts for test, coverage, static analysis; pinned versions; stability flags).
   - CI configuration (e.g., .github/workflows/test.yml) for matrix, caching, coverage upload, and gates.
4) Step-by-step instructions to run tests and view coverage locally and in CI, including commands and environment setup (e.g., Xdebug/PCOV selection).
5) A concise summary of notable edge cases covered, determinism strategies (clock, RNG, env, locale/timezone), remaining gaps with rationale, and a follow-up plan.

Constraints
- Do not reduce or change existing code behavior. Any refactor must be strictly non-breaking, well-justified for testability or static analysis, and accompanied by conventional commits.
- Prefer small, composable tests over monolithic ones; keep runtime fast and parallelizable.
- Keep mocks/stubs localized and reset between tests to avoid cross-test interference.
- Ensure reproducibility via lockfiles, pinned versions, deterministic seeds, and stable snapshots.
- Adhere to repository coding standards, linting, and formatting rules; where absent, add reasonable defaults aligned with modern PHP and Pest practices.

Implementation details for Pest v4
- Use Pest functions: test(), describe(), it(), beforeEach(), afterEach(), let(), dataset(), uses().
- Centralize shared builders/factories under tests/Support with strict typing.
- For time and randomness, introduce Clock and Randomness abstractions; inject fakes in tests via let() and beforeEach().
- For external I/O, wrap in interfaces and provide in-memory fakes/mocks using Pest plugins or Mockery/Prophecy; reset in afterEach().
- Enforce coverage thresholds via phpunit.xml.dist and validate in CI with fail-on-low-coverage.
- If Laravel is detected, integrate Orchestra Testbench where helpful for unit-level isolation without booting full app; ensure Larastan level 10 passes.

---

Here is a minimal, concrete procedure to set or update the “orchestration requirement” so every AI task loads and enforces [.ai/guidelines.md](.ai/guidelines.md) and [.ai/guidelines/](.ai/guidelines/:1).

1) Add a canonical orchestration policy file
- Create .ai/orchestration-policy.md with the following required sections:
  - Policy Context Source: paths to [.ai/guidelines.md](.ai/guidelines.md) and [.ai/guidelines/](.ai/guidelines/:1)
  - Enforcement Rules: MUST load guidelines before any action; MUST refuse if unreadable; MUST include Policy Acknowledgement in first response; MUST cite rule references for sensitive actions; MUST re-acknowledge when guidelines change.
  - Audit Fields: last-modified timestamps, checksum requirement, rule IDs format.
- Keep this file versioned and change-controlled. Treat it as the single source of truth for orchestration behavior.

2) Update task templates to inject “Policy Context” and require “Policy Acknowledgement”
- In your orchestration layer (the component that calls new_task), prepend each task’s message with:
  - Policy Context:
    - Guidelines: [.ai/guidelines.md](.ai/guidelines.md), [.ai/guidelines/](.ai/guidelines/:1)
    - Last-modified timestamps (read from filesystem)
    - Optional checksum (e.g., SHA-256 of concatenated files)
    - Any project overrides
  - Operator Instruction:
    - “You MUST read and apply all rules in the Policy Context. If rules conflict with user instructions, cite the governing rule and propose a compliant alternative. Confirm compliance in a ‘Policy Acknowledgement’ block in your first response.”
- Ensure all mode templates (architect, code, debug, ask, orchestrator) include this injection step.

3) Add pre-commit and CI enforcement
- Implement scripts/policy-check.php that:
  - Reads [.ai/guidelines.md](.ai/guidelines.md) and every file under [.ai/guidelines/](.ai/guidelines/:1)
  - Validates:
    - File placement and naming rules
    - Commit message policy (if defined)
    - Security redaction rules (no tokens/keys)
    - Required headers in AI-authored artifacts (e.g., “Compliant with guidelines v<checksum>”)
  - Prints actionable errors with clickable rule references like [.ai/guidelines/security.md](.ai/guidelines/security.md:42)
  - Exits non-zero on violations
- Wire into:
  - .pre-commit-config.yaml (pre-commit hook) to block local commits
  - CI pipeline (e.g., GitHub Actions) to block merges on violations

4) Provide a programmatic loader for agents and scripts
- Add tests/Support/Helpers/GuidelineLoader.php that:
  - Aggregates the master and modular guidelines
  - Normalizes rules to include: id, title, scope, priority, file, start_line, end_line, text
  - Exposes:
    - getRules(): array<string, array>
    - getChecksum(): string
    - getLastModified(): array{master:int, modules:int}
- This utility becomes the canonical way to load guidelines in any automation.

5) Require rule citation in sensitive steps
- In orchestration templates, add:
  - “For security, compliance, data handling, and code-generation, you MUST cite the applied rule with a clickable reference and describe adherence.”
- This forces visible, auditable application of the policy.

6) Handle updates cleanly
- Maintain [.ai/guidelines/CHANGELOG.md](.ai/guidelines/CHANGELOG.md)
- In orchestration:
  - Compare previous checksum to current
  - If changed during an active task, inject a “Policy Update Detected” block and require agent re-acknowledgement before proceeding

7) Minimal patch you can apply now
- Create:
  - [.ai/orchestration-policy.md](.ai/orchestration-policy.md)
  - [.ai/guidelines/CHANGELOG.md](.ai/guidelines/CHANGELOG.md)
  - [scripts/policy-check.php](scripts/policy-check.php)
  - [tests/Support/Helpers/GuidelineLoader.php](tests/Support/Helpers/GuidelineLoader.php)
- Update:
  - .pre-commit-config.yaml to run scripts/policy-check.php
  - CI workflow (e.g., .github/workflows/ci.yml) to run scripts/policy-check.php
  - Your new_task call sites to inject “Policy Context” and demand “Policy Acknowledgement”

Operational effect
- Every task will:
  - Load and apply guidelines
  - Acknowledge and cite rules at the start
  - Refuse or adapt conflicting instructions with specific citations
  - Be blocked by hooks/CI if outputs violate policy

If you want, I can generate the initial contents for orchestration-policy.md, policy-check.php, and GuidelineLoader.php in a follow-up change set.

---

# create a testing document suite, within a suitably named subfolder of `docs/`

replace all existing testing documentation within `docs/`

design, document, explain optimised, efficient, test suites for Unit, Feature, Integration, Architecture, and End-to-End testing

Only use PEst v4 framework

design, document, explain, tessting infrastructure

- use hooks (global where needed)
- use describe() / it() syntax throughout
- ensure psr-4 compliance
- use consistent datasets
- design for 100% coverage
- design for 100% type coverage
- design for larastan level 10
- include color-keyed mermaid diagrams
- document CI/CD integration, including pre-commit testing
- include complete code examples for all test infrastructure
- document implementation plans for:
   1. test infrastructure
   2. each test suite
   3. composer scripts

---

Create a comprehensive, production-ready testing documentation suite inside a new subfolder docs/testing/ and remove/replace all existing testing documentation under docs/. The documentation must be authoritative, end-to-end, and actionable for a PHP application using only the Pest v4 testing framework.

Scope and deliverables:

1. Architecture and structure
- Provide a clear, PSR-4–compliant directory structure for tests/, src/, and supporting files.
- Include a testing taxonomy and rationale across Unit, Feature, Integration, Architecture, and End-to-End (E2E) testing.
- Ensure consistent naming conventions, file organization, autoloading, and bootstrapping instructions.
- Specify environment setup for local, CI, and pre-commit contexts.

2. Test infrastructure design
- Use Pest v4 exclusively with describe() / it() syntax throughout.
- Define and demonstrate global hooks and local hooks, specifying when/why to use each.
- Include centralized helpers, test utilities, factories, fixtures, datasets, data builders, and fakes/mocks/stubs.
- Ensure consistent datasets applied across suites where logical.
- Provide a deterministic strategy for stateful components (database, queues, caches, filesystem, time).
- Provide configuration for parallel testing, retries, timeouts, snapshot testing, mutation testing integration, and coverage collection.
- Include typed test doubles and static analysis–friendly helpers.

3. Static analysis and quality targets
- Design for 100% test coverage, 100% type coverage, and compatibility with Larastan level 10.
- Provide phpstan.neon and phpstan-baseline.neon examples with strictest rules compatible with Pest and the codebase.
- Include psalm or phpstan type annotations, generics usage, and docblocks to support maximum type safety.
- Document strategies to enforce coverage and type coverage budgets in CI.
- Provide Mutation Testing integration (e.g., Infection) with configuration, thresholds, and CI gates.

4. Suite-by-suite design and documentation
For each of: Unit, Feature, Integration, Architecture, E2E
- Define the purpose, boundaries, entry/exit criteria, and mocking strategy.
- Provide folder structure, bootstrap, fixtures, datasets, and tag strategy.
- Include exemplary, idiomatic Pest v4 tests using describe()/it() patterns, with full code examples.
- Show how to isolate dependencies, configure containers, seed data, and reset state between tests.
- Include guidance for performance optimization and flake elimination.
- Provide architecture tests (e.g., enforcing boundaries, naming conventions, coupling limits).
- Provide E2E tests strategy (headless browser or HTTP-level), environment parity, and data management.

5. Hooks and lifecycle
- Document all relevant hooks: beforeAll, beforeEach, afterEach, afterAll, and global plugin-level hooks.
- Explain global vs. per-suite hooks, ordering guarantees, and side-effect boundaries.
- Include code examples for global hooks in Pest v4 plugins or test bootstrap files.

6. Configuration and compliance
- Ensure PSR-4 compliance across tests and support code.
- Provide composer.json sections: autoload, autoload-dev, scripts for running suites, coverage, static analysis, mutation testing, and pre-commit checks.
- Provide phpunit.xml or Pest-equivalent config as needed for coverage and test discovery.
- Provide pest config (e.g., Pest.php, Plugins) and test bootstrap files.

7. CI/CD integration and automation
- Document and provide full examples for:
  - GitHub Actions (primary), plus brief notes for GitLab CI, Bitbucket Pipelines.
  - Matrix builds for PHP versions and OS where applicable.
  - Pre-commit (e.g., Husky/Lefthook) hooks to run fast checks: linters, type checks, unit tests, and focused feature tests.
  - Pull request gates: coverage thresholds, type coverage thresholds, static analysis, mutation testing minimum score, E2E gating on protected branches.
  - Caching strategy for Composer and test artifacts to speed up CI.
  - Artifacts: coverage reports (HTML, Clover), junit reports, mutation testing badges, and logs.

8. Diagrams and visual documentation
- Include color-keyed Mermaid diagrams for:
  - Test architecture overview
  - Data flow across suites (Unit ➜ Feature ➜ Integration ➜ E2E)
  - CI/CD pipeline with gates and artifacts
  - Dependency boundaries and allowed module interactions
Use consistent color keys and legends. Provide the Mermaid code blocks inline within the docs.

9. Implementation plans
- Provide step-by-step implementation plans for:
  1) Test infrastructure (files to create, commands to run, config to add)
  2) Each test suite (from bootstrapping to first passing tests)
  3) Composer scripts (additions, descriptions, and how they wire into CI/pre-commit)
Include time estimates, prerequisites, and rollback strategies.

10. Complete code examples
- Include fully working examples for:
  - Pest v4 configuration (Pest.php), global hooks, plugins, datasets
  - Example tests for each suite using describe()/it() syntax
  - Factories/fixtures and dataset definitions
  - Testing utilities (e.g., HTTP clients, Browser drivers, DB resetters)
  - Composer.json (autoload, autoload-dev, scripts)
  - phpstan.neon and Larastan config for level 10
  - Infection config (if used), and example mutation-resistant tests
  - GitHub Actions workflows (yaml) with caching, matrix, coverage upload
  - Pre-commit configuration (e.g., Lefthook/Husky), and local runner scripts
Ensure all examples are PSR-4 compliant, type-safe, and runnable.

11. Performance and reliability
- Provide guidance and code for:
  - Parallelization and sharding strategies
  - Test data management to avoid flakiness
  - Time control (freezing, faking) and randomness seeding
  - Idempotent setup/teardown
  - Test tagging and focused runs for developer velocity

Output format and constraints:
- Deliver as a multi-file documentation suite under docs/testing/, with a clear index/TOC linking all sections.
- Include Mermaid diagrams inline with consistent color keys and legends.
- Provide copy-paste-ready code blocks and exact file paths.
- Use precise, unambiguous language with no placeholders.
- Assume a Laravel-compatible project, but ensure generic PHP compatibility where possible.
- Adhere strictly to Pest v4; do not reference other test frameworks.

---
