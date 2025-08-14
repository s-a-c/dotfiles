#!/usr/bin/env php
<?php
/**
 * Test script for the link validator
 */

declare(strict_types=1);

echo "Testing PHP Link Validator...\n";

// Test basic PHP functionality
echo "PHP Version: " . PHP_VERSION . "\n";

// Test file existence
$files = [
    '.ai/tools/LinkValidator/Utils/Logger.php',
    '.ai/tools/LinkValidator/Utils/SecurityValidator.php',
    '.ai/tools/LinkValidator/Core/GitHubAnchorGenerator.php',
    '.ai/tools/LinkValidator/Core/LinkValidator.php',
];

foreach ($files as $file) {
    if (file_exists($file)) {
        echo "✓ Found: {$file}\n";
    } else {
        echo "✗ Missing: {$file}\n";
    }
}

// Test basic class loading
try {
    require_once '.ai/tools/LinkValidator/Utils/Logger.php';
    echo "✓ Logger class loaded\n";
    
    $logger = new \LinkValidator\Utils\Logger();
    echo "✓ Logger instance created\n";
    
} catch (Throwable $e) {
    echo "✗ Logger error: " . $e->getMessage() . "\n";
}

try {
    require_once '.ai/tools/LinkValidator/Core/GitHubAnchorGenerator.php';
    echo "✓ GitHubAnchorGenerator class loaded\n";
    
    $generator = new \LinkValidator\Core\GitHubAnchorGenerator();
    echo "✓ GitHubAnchorGenerator instance created\n";
    
    // Test anchor generation
    $anchor = $generator->generate('1. Overview');
    echo "✓ Anchor generation test: '1. Overview' → '{$anchor}'\n";
    
} catch (Throwable $e) {
    echo "✗ GitHubAnchorGenerator error: " . $e->getMessage() . "\n";
}

echo "Test completed.\n";
