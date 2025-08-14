<?php
/**
 * Fixture Helper
 *
 * Provides utilities for creating and managing test fixtures.
 */

declare(strict_types=1);

class FixtureHelper
{
    /**
     * Create a complete test documentation project
     */
    public static function createCompleteTestProject(): string
    {
        $projectDir = TEMP_DIR . '/' . uniqid('test_project_');
        mkdir($projectDir, 0755, true);

        // Create directory structure
        $structure = [
            'docs' => [
                'getting-started' => [
                    'index.md',
                    'installation.md',
                    'quickstart.md'
                ],
                'api' => [
                    'overview.md',
                    'authentication.md',
                    'endpoints' => [
                        'users.md',
                        'posts.md',
                        'comments.md'
                    ]
                ],
                'guides' => [
                    'tutorial.md',
                    'best-practices.md',
                    'troubleshooting.md'
                ],
                'reference' => [
                    'configuration.md',
                    'cli.md',
                    'api-reference.md'
                ]
            ],
            'examples' => [
                'basic-usage.md',
                'advanced-usage.md'
            ],
            '.github' => [
                'CONTRIBUTING.md',
                'ISSUE_TEMPLATE.md'
            ]
        ];

        self::createDirectoryStructure($projectDir, $structure);
        self::populateProjectFiles($projectDir);

        return $projectDir;
    }

    /**
     * Create directory structure recursively
     */
    private static function createDirectoryStructure(string $basePath, array $structure): void
    {
        foreach ($structure as $name => $content) {
            $path = $basePath . '/' . $name;
            
            if (is_array($content)) {
                mkdir($path, 0755, true);
                self::createDirectoryStructure($path, $content);
            } else {
                // It's a file
                touch($path);
            }
        }
    }

    /**
     * Populate project files with realistic content
     */
    private static function populateProjectFiles(string $projectDir): void
    {
        $files = [
            'README.md' => self::getReadmeContent(),
            'docs/index.md' => self::getDocsIndexContent(),
            'docs/getting-started/index.md' => self::getGettingStartedIndexContent(),
            'docs/getting-started/installation.md' => self::getInstallationContent(),
            'docs/getting-started/quickstart.md' => self::getQuickstartContent(),
            'docs/api/overview.md' => self::getApiOverviewContent(),
            'docs/api/authentication.md' => self::getAuthenticationContent(),
            'docs/api/endpoints/users.md' => self::getUsersEndpointContent(),
            'docs/api/endpoints/posts.md' => self::getPostsEndpointContent(),
            'docs/api/endpoints/comments.md' => self::getCommentsEndpointContent(),
            'docs/guides/tutorial.md' => self::getTutorialContent(),
            'docs/guides/best-practices.md' => self::getBestPracticesContent(),
            'docs/guides/troubleshooting.md' => self::getTroubleshootingContent(),
            'docs/reference/configuration.md' => self::getConfigurationContent(),
            'docs/reference/cli.md' => self::getCliContent(),
            'docs/reference/api-reference.md' => self::getApiReferenceContent(),
            'examples/basic-usage.md' => self::getBasicUsageContent(),
            'examples/advanced-usage.md' => self::getAdvancedUsageContent(),
            '.github/CONTRIBUTING.md' => self::getContributingContent(),
            '.github/ISSUE_TEMPLATE.md' => self::getIssueTemplateContent(),
        ];

        foreach ($files as $relativePath => $content) {
            $fullPath = $projectDir . '/' . $relativePath;
            file_put_contents($fullPath, $content);
        }
    }

    /**
     * Get README.md content
     */
    private static function getReadmeContent(): string
    {
        return <<<'MD'
# Test Project

A comprehensive test project for link validation.

## Quick Start

1. [Installation](docs/getting-started/installation.md)
2. [Quickstart Guide](docs/getting-started/quickstart.md)
3. [Tutorial](docs/guides/tutorial.md)

## Documentation

- [Getting Started](docs/getting-started/index.md)
- [API Documentation](docs/api/overview.md)
- [Guides](docs/guides/tutorial.md)
- [Reference](docs/reference/configuration.md)

## Examples

- [Basic Usage](examples/basic-usage.md)
- [Advanced Usage](examples/advanced-usage.md)

## Contributing

See [CONTRIBUTING.md](.github/CONTRIBUTING.md) for guidelines.

## Support

If you encounter issues, check our [troubleshooting guide](docs/guides/troubleshooting.md).
MD;
    }

    /**
     * Get docs/index.md content
     */
    private static function getDocsIndexContent(): string
    {
        return <<<'MD'
# Documentation

Welcome to the comprehensive documentation.

## Sections

### [Getting Started](getting-started/index.md)
New to the project? Start here.

### [API Documentation](api/overview.md)
Complete API reference and guides.

### [Guides](guides/tutorial.md)
Step-by-step tutorials and best practices.

### [Reference](reference/configuration.md)
Detailed reference documentation.

## Quick Links

- [Installation](getting-started/installation.md)
- [Authentication](api/authentication.md)
- [Configuration](reference/configuration.md)
- [Troubleshooting](guides/troubleshooting.md)
MD;
    }

    /**
     * Get getting-started/index.md content
     */
    private static function getGettingStartedIndexContent(): string
    {
        return <<<'MD'
# Getting Started

Welcome! This section will help you get up and running quickly.

## Steps

1. **[Installation](installation.md)** - Install the software
2. **[Quickstart](quickstart.md)** - Get running in 5 minutes
3. **[Tutorial](../guides/tutorial.md)** - Complete walkthrough

## Prerequisites

Before you begin, ensure you have:
- Basic knowledge of the system
- Required dependencies installed

## Next Steps

After completing the getting started guide:
- Explore the [API documentation](../api/overview.md)
- Read the [best practices guide](../guides/best-practices.md)
- Check out [examples](../../examples/basic-usage.md)
MD;
    }

    /**
     * Get installation.md content
     */
    private static function getInstallationContent(): string
    {
        return <<<'MD'
# Installation

## System Requirements

- Operating System: Linux, macOS, or Windows
- Memory: 4GB RAM minimum
- Storage: 1GB available space

## Installation Steps

### Step 1: Download

Download the latest release from our website.

### Step 2: Install

Follow the platform-specific instructions:

#### Linux/macOS
```bash
./install.sh
```

#### Windows
```cmd
install.bat
```

### Step 3: Verify

Verify the installation:
```bash
app --version
```

## Next Steps

- [Quickstart Guide](quickstart.md)
- [Configuration](../reference/configuration.md)
- [Tutorial](../guides/tutorial.md)

## Troubleshooting

If you encounter issues, see the [troubleshooting guide](../guides/troubleshooting.md).
MD;
    }

    /**
     * Get quickstart.md content
     */
    private static function getQuickstartContent(): string
    {
        return <<<'MD'
# Quickstart Guide

Get up and running in 5 minutes!

## Prerequisites

Make sure you've completed the [installation](installation.md).

## Quick Setup

1. **Initialize**: Run the setup command
2. **Configure**: Edit the configuration file
3. **Test**: Run a test command

## Basic Usage

```bash
app init
app configure
app test
```

## What's Next?

- [Complete Tutorial](../guides/tutorial.md)
- [API Overview](../api/overview.md)
- [Configuration Reference](../reference/configuration.md)

## Need Help?

- [Troubleshooting](../guides/troubleshooting.md)
- [Best Practices](../guides/best-practices.md)
MD;
    }

    // Additional content methods would continue here...
    // For brevity, I'll include a few more key ones:

    private static function getApiOverviewContent(): string
    {
        return <<<'MD'
# API Overview

Complete API documentation and guides.

## Authentication

Before using the API, you need to [authenticate](authentication.md).

## Endpoints

### Core Resources
- [Users](endpoints/users.md)
- [Posts](endpoints/posts.md)
- [Comments](endpoints/comments.md)

## Getting Started

1. [Set up authentication](authentication.md)
2. [Make your first request](../guides/tutorial.md#api-usage)
3. [Explore endpoints](endpoints/users.md)

## Reference

For complete API reference, see [API Reference](../reference/api-reference.md).
MD;
    }

    private static function getTutorialContent(): string
    {
        return <<<'MD'
# Tutorial

Complete step-by-step tutorial.

## Prerequisites

- [Installation completed](../getting-started/installation.md)
- [Quickstart guide completed](../getting-started/quickstart.md)

## Steps

### Step 1: Basic Setup
Follow the [installation guide](../getting-started/installation.md).

### Step 2: Configuration
Configure the system using the [configuration guide](../reference/configuration.md).

### Step 3: API Usage
Learn to use the API with our [API overview](../api/overview.md).

## Examples

- [Basic Usage](../../examples/basic-usage.md)
- [Advanced Usage](../../examples/advanced-usage.md)

## Next Steps

- [Best Practices](best-practices.md)
- [API Reference](../reference/api-reference.md)
MD;
    }

    private static function getContributingContent(): string
    {
        return <<<'MD'
# Contributing

Thank you for your interest in contributing!

## Getting Started

1. Read the [documentation](../docs/index.md)
2. Check the [troubleshooting guide](../docs/guides/troubleshooting.md)
3. Review [best practices](../docs/guides/best-practices.md)

## Development Setup

Follow the [installation guide](../docs/getting-started/installation.md) for development setup.

## Guidelines

- Follow coding standards
- Write tests.old
- Update documentation

## Questions?

Check our [troubleshooting guide](../docs/guides/troubleshooting.md) first.
MD;
    }

    // Placeholder methods for remaining content
    private static function getAuthenticationContent(): string { return "# Authentication\nAPI authentication guide."; }
    private static function getUsersEndpointContent(): string { return "# Users Endpoint\nUsers API documentation."; }
    private static function getPostsEndpointContent(): string { return "# Posts Endpoint\nPosts API documentation."; }
    private static function getCommentsEndpointContent(): string { return "# Comments Endpoint\nComments API documentation."; }
    private static function getBestPracticesContent(): string { return "# Best Practices\nBest practices guide."; }
    private static function getTroubleshootingContent(): string { return "# Troubleshooting\nCommon issues and solutions."; }
    private static function getConfigurationContent(): string { return "# Configuration\nConfiguration reference."; }
    private static function getCliContent(): string { return "# CLI Reference\nCommand line interface reference."; }
    private static function getApiReferenceContent(): string { return "# API Reference\nComplete API reference."; }
    private static function getBasicUsageContent(): string { return "# Basic Usage\nBasic usage examples."; }
    private static function getAdvancedUsageContent(): string { return "# Advanced Usage\nAdvanced usage examples."; }
    private static function getIssueTemplateContent(): string { return "# Issue Template\nTemplate for reporting issues."; }
}
