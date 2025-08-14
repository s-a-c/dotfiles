<?php
/**
 * Link Validation Test Helper
 * 
 * Provides utilities for testing link validation accuracy and behavior.
 */

declare(strict_types=1);

class LinkValidationHelper
{
    /**
     * Create test cases for link categorization
     */
    public static function getLinkCategorizationTestCases(): array
    {
        return [
            // Internal links (same directory)
            'internal_simple' => [
                'url' => 'other.md',
                'expected_type' => 'internal'
            ],
            'internal_with_extension' => [
                'url' => 'document.html',
                'expected_type' => 'internal'
            ],
            
            // Anchor links
            'anchor_simple' => [
                'url' => '#section',
                'expected_type' => 'anchor'
            ],
            'anchor_with_dashes' => [
                'url' => '#section-with-dashes',
                'expected_type' => 'anchor'
            ],
            'anchor_with_numbers' => [
                'url' => '#section-1',
                'expected_type' => 'anchor'
            ],
            
            // Cross-reference links (with paths)
            'cross_ref_relative' => [
                'url' => '../parent.md',
                'expected_type' => 'cross_reference'
            ],
            'cross_ref_deep' => [
                'url' => 'path/to/file.md',
                'expected_type' => 'cross_reference'
            ],
            'cross_ref_with_anchor' => [
                'url' => 'path/file.md#section',
                'expected_type' => 'cross_reference'
            ],
            'cross_ref_html' => [
                'url' => 'docs/index.html',
                'expected_type' => 'cross_reference'
            ],
            
            // External links
            'external_https' => [
                'url' => 'https://example.com',
                'expected_type' => 'external'
            ],
            'external_http' => [
                'url' => 'http://example.com',
                'expected_type' => 'external'
            ],
            'external_mailto' => [
                'url' => 'mailto:test@example.com',
                'expected_type' => 'external'
            ],
            'external_tel' => [
                'url' => 'tel:+1234567890',
                'expected_type' => 'external'
            ],
            'external_ftp' => [
                'url' => 'ftp://files.example.com',
                'expected_type' => 'external'
            ],
            
            // Edge cases
            'internal_no_extension' => [
                'url' => 'file-without-extension',
                'expected_type' => 'internal'
            ],
            'anchor_empty' => [
                'url' => '#',
                'expected_type' => 'anchor'
            ],
            'relative_current_dir' => [
                'url' => './file.md',
                'expected_type' => 'cross_reference'
            ],
        ];
    }

    /**
     * Create test cases for anchor validation
     */
    public static function getAnchorValidationTestCases(): array
    {
        return [
            'valid_heading_h1' => [
                'content' => "# Main Heading\nContent here.",
                'anchor' => '#main-heading',
                'should_exist' => true
            ],
            'valid_heading_h2' => [
                'content' => "## Sub Heading\nContent here.",
                'anchor' => '#sub-heading',
                'should_exist' => true
            ],
            'valid_heading_with_numbers' => [
                'content' => "# Section 1\nContent here.",
                'anchor' => '#section-1',
                'should_exist' => true
            ],
            'valid_heading_with_special_chars' => [
                'content' => "# API & Configuration\nContent here.",
                'anchor' => '#api--configuration',
                'should_exist' => true
            ],
            'invalid_anchor' => [
                'content' => "# Main Heading\nContent here.",
                'anchor' => '#non-existent',
                'should_exist' => false
            ],
            'case_sensitive_mismatch' => [
                'content' => "# Main Heading\nContent here.",
                'anchor' => '#Main-Heading', // Wrong case
                'should_exist' => false
            ],
            'multiple_headings' => [
                'content' => "# First\n## Second\n### Third\nContent.",
                'anchor' => '#second',
                'should_exist' => true
            ],
        ];
    }

    /**
     * Create test cases for external link validation
     */
    public static function getExternalLinkTestCases(): array
    {
        return [
            'valid_https' => [
                'url' => 'https://httpbin.org/status/200',
                'expected_status' => 200,
                'should_be_valid' => true
            ],
            'valid_http' => [
                'url' => 'http://httpbin.org/status/200',
                'expected_status' => 200,
                'should_be_valid' => true
            ],
            'not_found' => [
                'url' => 'https://httpbin.org/status/404',
                'expected_status' => 404,
                'should_be_valid' => false
            ],
            'server_error' => [
                'url' => 'https://httpbin.org/status/500',
                'expected_status' => 500,
                'should_be_valid' => false
            ],
            'redirect' => [
                'url' => 'https://httpbin.org/redirect/1',
                'expected_status' => 200, // Should follow redirect
                'should_be_valid' => true
            ],
            'timeout_simulation' => [
                'url' => 'https://httpbin.org/delay/10',
                'timeout' => 1, // 1 second timeout
                'should_timeout' => true,
                'should_be_valid' => false
            ],
            'invalid_domain' => [
                'url' => 'https://this-domain-definitely-does-not-exist-12345.com',
                'should_be_valid' => false
            ],
            'malformed_url' => [
                'url' => 'not-a-valid-url',
                'should_be_valid' => false
            ],
        ];
    }

    /**
     * Create test files with known link validation results
     */
    public static function createKnownValidationTestFiles(): array
    {
        $files = [];
        
        // File with all valid links
        $files['all_valid.md'] = createTempFile(<<<'MD'
# All Valid Links
[Anchor](#section)
[GitHub](https://github.com)
## Section
Content here.
MD);
        
        // File with all broken links
        $files['all_broken.md'] = createTempFile(<<<'MD'
# All Broken Links
[Missing file](nonexistent.md)
[Bad anchor](#nonexistent)
[Bad external](https://this-does-not-exist-12345.com)
MD);
        
        // File with mixed valid/broken links
        $files['mixed_validity.md'] = createTempFile(<<<'MD'
# Mixed Validity
[Valid anchor](#section)
[Broken file](missing.md)
[Valid external](https://github.com)
[Broken anchor](#missing)
## Section
Content here.
MD);
        
        // Create target files for internal link testing
        $files['target1.md'] = createTempFile('# Target 1\nContent.');
        $files['target2.md'] = createTempFile('# Target 2\nContent.');
        
        // File with valid internal links
        $files['valid_internal.md'] = createTempFile(<<<'MD'
# Valid Internal Links
[Target 1](target1.md)
[Target 2](target2.md)
MD);
        
        return $files;
    }

    /**
     * Create performance test files
     */
    public static function createPerformanceTestFiles(int $fileCount, int $linksPerFile): array
    {
        $files = [];
        
        for ($i = 0; $i < $fileCount; $i++) {
            $content = "# Performance Test File {$i}\n\n";
            
            for ($j = 0; $j < $linksPerFile; $j++) {
                $content .= "[Link {$j}](file{$j}.md)\n";
            }
            
            $content .= "\n## Section\nContent here.";
            
            $files["perf_test_{$i}.md"] = createTempFile($content);
        }
        
        return $files;
    }

    /**
     * Validate link categorization accuracy
     */
    public static function validateLinkCategorization(LinkValidator\Core\LinkValidator $validator, array $testCases): array
    {
        $results = [];
        
        foreach ($testCases as $testName => $testCase) {
            $reflection = new ReflectionClass($validator);
            $method = $reflection->getMethod('categorizeLink');
            $method->setAccessible(true);
            
            $actualType = $method->invoke($validator, $testCase['url']);
            $expectedType = $testCase['expected_type'];
            
            $results[$testName] = [
                'url' => $testCase['url'],
                'expected' => $expectedType,
                'actual' => $actualType,
                'passed' => $actualType === $expectedType
            ];
        }
        
        return $results;
    }

    /**
     * Generate anchor test content with known anchors
     */
    public static function generateAnchorTestContent(): array
    {
        return [
            'content' => <<<'MD'
# Main Title
This is the main content.

## Getting Started
Instructions for getting started.

### Prerequisites
What you need before starting.

### Installation Steps
1. Download
2. Install
3. Configure

## API Reference
Documentation for the API.

### Authentication
How to authenticate.

### Endpoints
Available endpoints.

#### GET /users
Get all users.

#### POST /users
Create a new user.

## Configuration
How to configure the system.

### Basic Settings
Basic configuration options.

### Advanced Settings
Advanced configuration options.
MD,
            'expected_anchors' => [
                '#main-title',
                '#getting-started',
                '#prerequisites',
                '#installation-steps',
                '#api-reference',
                '#authentication',
                '#endpoints',
                '#get-users',
                '#post-users',
                '#configuration',
                '#basic-settings',
                '#advanced-settings',
            ],
            'invalid_anchors' => [
                '#non-existent',
                '#wrong-case',
                '#missing-section',
                '#typo-in-name',
            ]
        ];
    }

    /**
     * Create stress test scenarios
     */
    public static function createStressTestScenarios(): array
    {
        return [
            'many_files_few_links' => [
                'file_count' => 100,
                'links_per_file' => 5,
                'description' => 'Many files with few links each'
            ],
            'few_files_many_links' => [
                'file_count' => 5,
                'links_per_file' => 100,
                'description' => 'Few files with many links each'
            ],
            'balanced_load' => [
                'file_count' => 20,
                'links_per_file' => 20,
                'description' => 'Balanced file and link count'
            ],
            'single_large_file' => [
                'file_count' => 1,
                'links_per_file' => 1000,
                'description' => 'Single file with many links'
            ],
        ];
    }

    /**
     * Measure validation performance
     */
    public static function measureValidationPerformance(
        LinkValidator\Core\LinkValidator $validator,
        array $files,
        array $scope
    ): array {
        $startTime = microtime(true);
        $startMemory = memory_get_usage(true);
        
        $results = $validator->validateFiles(
            $files,
            $scope,
            false, // No external validation for performance tests
            false,
            30,
            0,
            0
        );
        
        $endTime = microtime(true);
        $endMemory = memory_get_usage(true);
        
        return [
            'execution_time' => $endTime - $startTime,
            'memory_used' => $endMemory - $startMemory,
            'files_processed' => $results['summary']['files_processed'],
            'links_processed' => $results['summary']['total_links'],
            'links_per_second' => $results['summary']['total_links'] / ($endTime - $startTime),
            'memory_per_file' => ($endMemory - $startMemory) / count($files),
        ];
    }
}
