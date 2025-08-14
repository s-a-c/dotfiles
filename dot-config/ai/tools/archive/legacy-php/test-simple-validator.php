#!/usr/bin/env php
<?php
/**
 * Simple test for link validator functionality
 */

declare(strict_types=1);

echo "Testing Link Validator with sample markdown...\n";

// Create a test markdown file
$testContent = <<<'MD'
# Test Document

This is a test document with various links:

- [Valid internal link](test-simple-validator.php)
- [Broken internal link](nonexistent.md)
- [Valid anchor](#test-document)
- [Broken anchor](#nonexistent-heading)
- [External link](https://example.com)

## Another Section

Some more content here.
MD;

$testFile = '.ai/tools/test-sample.md';
file_put_contents($testFile, $testContent);

try {
    // Load required classes
    require_once '.ai/tools/LinkValidator/Utils/Logger.php';
    require_once '.ai/tools/LinkValidator/Utils/SecurityValidator.php';
    require_once '.ai/tools/LinkValidator/Core/GitHubAnchorGenerator.php';
    require_once '.ai/tools/LinkValidator/Core/LinkValidator.php';
    
    $logger = new \LinkValidator\Utils\Logger();
    $securityValidator = new \LinkValidator\Utils\SecurityValidator();
    $linkValidator = new \LinkValidator\Core\LinkValidator($logger, $securityValidator);
    
    echo "✓ Classes loaded successfully\n";
    
    // Test validation
    $results = $linkValidator->validateFiles(
        [$testFile],
        ['all'],
        false, // Don't check external links
        false, // Case insensitive
        30     // Timeout
    );
    
    echo "✓ Validation completed\n";
    echo "Summary:\n";
    echo "  Total files: " . $results['summary']['total_files'] . "\n";
    echo "  Total links: " . $results['summary']['total_links'] . "\n";
    echo "  Broken links: " . $results['summary']['broken_links'] . "\n";
    echo "  Success rate: " . $results['summary']['success_rate'] . "%\n";
    
    // Show broken links
    if ($results['summary']['broken_links'] > 0) {
        echo "\nBroken links found:\n";
        foreach ($results['results'][$testFile]['broken_links'] as $brokenLink) {
            echo "  - [{$brokenLink['text']}]({$brokenLink['url']}) - {$brokenLink['status']}\n";
        }
    }
    
} catch (Throwable $e) {
    echo "✗ Error: " . $e->getMessage() . "\n";
    echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
} finally {
    // Clean up test file
    if (file_exists($testFile)) {
        unlink($testFile);
    }
}

echo "\nTest completed.\n";
