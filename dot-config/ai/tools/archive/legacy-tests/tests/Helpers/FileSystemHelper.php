<?php
/**
 * File System Test Helper
 *
 * Provides utilities for creating test file structures, symlinks, and fixtures.
 */

declare(strict_types=1);

class FileSystemHelper
{
    /**
     * Create a test documentation structure
     */
    public static function createTestDocumentationStructure(): string
    {
        $baseDir = TEMP_DIR . '/' . uniqid('docs_');
        mkdir($baseDir, 0755, true);

        // Create directory structure
        $dirs = [
            'getting-started',
            'api',
            'guides',
            'reference',
            'hidden/.secret',
            'temp'
        ];

        foreach ($dirs as $dir) {
            mkdir($baseDir . '/' . $dir, 0755, true);
        }

        // Create test files with various link types
        $files = [
            'README.md' => self::getReadmeContent(),
            'getting-started/index.md' => self::getGettingStartedContent(),
            'getting-started/installation.md' => self::getInstallationContent(),
            'api/overview.md' => self::getApiOverviewContent(),
            'api/endpoints.md' => self::getApiEndpointsContent(),
            'guides/tutorial.md' => self::getTutorialContent(),
            'reference/config.md' => self::getConfigReferenceContent(),
            'hidden/.secret/private.md' => self::getPrivateContent(),
            'temp/backup.md' => self::getBackupContent(),
            'broken-links.md' => self::getBrokenLinksContent(),
            'external-links.md' => self::getExternalLinksContent(),
        ];

        foreach ($files as $filename => $content) {
            $filepath = $baseDir . '/' . $filename;
            file_put_contents($filepath, $content);
        }

        return $baseDir;
    }

    /**
     * Create a symlinked documentation structure
     */
    public static function createSymlinkedDocumentationStructure(): array
    {
        $realDir = self::createTestDocumentationStructure();
        $symlinkDir = TEMP_DIR . '/' . uniqid('symlink_docs_');

        symlink($realDir, $symlinkDir);

        return [
            'real_path' => $realDir,
            'symlink_path' => $symlinkDir
        ];
    }

    /**
     * Create files with various encodings and formats
     */
    public static function createEncodingTestFiles(): array
    {
        $files = [];

        // UTF-8 file
        $files['utf8.md'] = createTempFile("# UTF-8 Test\n[Link](test.md)\n");

        // UTF-8 with BOM
        $files['utf8_bom.md'] = createTempFile("\xEF\xBB\xBF# UTF-8 BOM Test\n[Link](test.md)\n");

        // Binary file (should be skipped)
        $files['binary.bin'] = createTempFile(pack('H*', '89504e470d0a1a0a'), '.bin');

        // Empty file
        $files['empty.md'] = createTempFile('');

        // Very large file
        $largeContent = str_repeat("# Large File\n[Link](test.md)\n", 1000);
        $files['large.md'] = createTempFile($largeContent);

        return $files;
    }

    /**
     * Create files with permission issues
     */
    public static function createPermissionTestFiles(): array
    {
        $files = [];

        // Unreadable file
        $files['unreadable.md'] = createTempFile("# Unreadable\n[Link](test.md)\n");
        chmod($files['unreadable.md'], 0000);

        // Read-only file
        $files['readonly.md'] = createTempFile("# Read Only\n[Link](test.md)\n");
        chmod($files['readonly.md'], 0444);

        return $files;
    }

    /**
     * Get README.md content with various link types
     */
    private static function getReadmeContent(): string
    {
        return <<<'MD'
# Test Documentation

Welcome to the test documentation.

## Internal Links
- [Getting Started](getting-started/index.md)
- [API Overview](api/overview.md)
- [Tutorial](guides/tutorial.md)

## Anchor Links
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)

## Cross-Reference Links
- [API Endpoints](api/endpoints.md#list-endpoints)
- [Config Reference](reference/config.md#basic-settings)

## External Links
- [GitHub](https://github.com)
- [Documentation](https://docs.example.com)

## Installation

Installation instructions here.

## Configuration

Configuration details here.

## Usage

Usage examples here.
MD;
    }

    /**
     * Get getting-started/index.md content
     */
    private static function getGettingStartedContent(): string
    {
        return <<<'MD'
# Getting Started

Quick start guide.

## Next Steps
- [Installation](installation.md)
- [Back to main](../README.md)

## External Resources
- [Official Site](https://example.com)
MD;
    }

    /**
     * Get installation.md content
     */
    private static function getInstallationContent(): string
    {
        return <<<'MD'
# Installation

## Prerequisites
See the [main documentation](../README.md#installation).

## Steps
1. Download
2. Install
3. Configure

## Next
- [API Overview](../api/overview.md)
MD;
    }

    /**
     * Get API overview content
     */
    private static function getApiOverviewContent(): string
    {
        return <<<'MD'
# API Overview

## Endpoints
See [endpoints documentation](endpoints.md).

## Authentication
Details about authentication.

## Rate Limiting
Information about rate limits.
MD;
    }

    /**
     * Get API endpoints content
     */
    private static function getApiEndpointsContent(): string
    {
        return <<<'MD'
# API Endpoints

## List Endpoints

### GET /api/items
Returns a list of items.

### POST /api/items
Creates a new item.

## Authentication Endpoints

### POST /auth/login
User login endpoint.

## Back to Overview
See [API Overview](overview.md).
MD;
    }

    /**
     * Get tutorial content
     */
    private static function getTutorialContent(): string
    {
        return <<<'MD'
# Tutorial

Step-by-step tutorial.

## Prerequisites
Make sure you've completed [installation](../getting-started/installation.md).

## Steps

### Step 1
First step details.

### Step 2
Second step details.

## Next Steps
- [API Reference](../api/overview.md)
- [Configuration](../reference/config.md)
MD;
    }

    /**
     * Get config reference content
     */
    private static function getConfigReferenceContent(): string
    {
        return <<<'MD'
# Configuration Reference

## Basic Settings

Configuration options:

- `option1`: Description
- `option2`: Description

## Advanced Settings

Advanced configuration options.

## Examples
See the [tutorial](../guides/tutorial.md) for examples.
MD;
    }

    /**
     * Get private content (hidden file)
     */
    private static function getPrivateContent(): string
    {
        return <<<'MD'
# Private Documentation

This is hidden documentation.

[Link to public docs](../../README.md)
MD;
    }

    /**
     * Get backup content (temp file)
     */
    private static function getBackupContent(): string
    {
        return <<<'MD'
# Backup File

This is a temporary backup file.

[Link to original](../README.md)
MD;
    }

    /**
     * Get content with broken links
     */
    private static function getBrokenLinksContent(): string
    {
        return <<<'MD'
# Broken Links Test

## Internal Broken Links
- [Non-existent file](non-existent.md)
- [Wrong path](wrong/path/file.md)
- [Missing extension](file-without-extension)

## Broken Anchors
- [Non-existent anchor](#non-existent-anchor)
- [Wrong anchor in file](README.md#wrong-anchor)

## Broken Cross-References
- [Non-existent file with anchor](missing/file.md#anchor)
- [Wrong path with anchor](wrong/path.md#section)
MD;
    }

    /**
     * Get content with external links
     */
    private static function getExternalLinksContent(): string
    {
        return <<<'MD'
# External Links Test

## Valid External Links
- [Google](https://www.google.com)
- [GitHub](https://github.com)
- [Stack Overflow](https://stackoverflow.com)

## Invalid External Links
- [Non-existent domain](https://this-domain-does-not-exist-12345.com)
- [Invalid protocol](ftp://invalid-ftp-server.com)
- [Malformed URL](http://malformed url with spaces)

## Special Protocols
- [Email](mailto:test@example.com)
- [Phone](tel:+1234567890)
- [JavaScript](javascript:void(0))
MD;
    }

    /**
     * Create test files with specific link patterns for testing
     */
    public static function createLinkPatternTestFiles(): array
    {
        $files = [];

        // File with only internal links
        $files['internal_only.md'] = createTempFile(<<<'MD'
# Internal Links Only
[File 1](file1.md)
[File 2](file2.md)
[Relative](../parent.md)
MD);

        // File with only anchor links
        $files['anchors_only.md'] = createTempFile(<<<'MD'
# Anchor Links Only
[Section 1](#section-1)
[Section 2](#section-2)
## Section 1
Content
## Section 2
More content
MD);

        // File with only cross-reference links
        $files['cross_ref_only.md'] = createTempFile(<<<'MD'
# Cross-Reference Links Only
[Deep file](path/to/deep/file.md)
[With anchor](path/file.md#section)
[Another path](different/path/file.md)
MD);

        // File with only external links
        $files['external_only.md'] = createTempFile(<<<'MD'
# External Links Only
[Website](https://example.com)
[GitHub](https://github.com)
[Email](mailto:test@example.com)
MD);

        // File with mixed link types
        $files['mixed_links.md'] = createTempFile(<<<'MD'
# Mixed Link Types
[Internal](other.md)
[Anchor](#section)
[Cross-ref](path/file.md)
[External](https://example.com)
## Section
Content here.
MD);

        return $files;
    }

    /**
     * Clean up created test files and directories
     */
    public static function cleanup(): void
    {
        if (is_dir(TEMP_DIR)) {
            self::removeDirectory(TEMP_DIR);
            mkdir(TEMP_DIR, 0755, true);
        }
    }

    /**
     * Recursively remove a directory
     */
    private static function removeDirectory(string $dir): void
    {
        if (!is_dir($dir)) {
            return;
        }

        $files = array_diff(scandir($dir), ['.', '..']);
        foreach ($files as $file) {
            $path = $dir . '/' . $file;
            if (is_dir($path)) {
                self::removeDirectory($path);
            } else {
                unlink($path);
            }
        }
        rmdir($dir);
    }
}
