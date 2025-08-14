#!/usr/bin/env php
<?php
/**
 * Test Suite for PHP Link Validation Tools
 * 
 * Comprehensive test suite to verify functionality of the link validator
 * and rectifier tools with various scenarios and edge cases.
 */

declare(strict_types=1);

echo "🧪 PHP Link Validation Tools Test Suite\n";
echo str_repeat("=", 50) . "\n\n";

$testsPassed = 0;
$testsFailed = 0;
$testResults = [];

/**
 * Run a test and track results
 */
function runTest(string $name, callable $test): void {
    global $testsPassed, $testsFailed, $testResults;
    
    echo "Testing: {$name}... ";
    
    try {
        $result = $test();
        if ($result === true) {
            echo "✅ PASS\n";
            $testsPassed++;
            $testResults[$name] = 'PASS';
        } else {
            echo "❌ FAIL: {$result}\n";
            $testsFailed++;
            $testResults[$name] = "FAIL: {$result}";
        }
    } catch (Throwable $e) {
        echo "💥 ERROR: " . $e->getMessage() . "\n";
        $testsFailed++;
        $testResults[$name] = "ERROR: " . $e->getMessage();
    }
}

// Test 1: Basic class loading
runTest("Class Loading", function() {
    require_once '.ai/tools/LinkValidator/Utils/Logger.php';
    require_once '.ai/tools/LinkValidator/Utils/SecurityValidator.php';
    require_once '.ai/tools/LinkValidator/Core/GitHubAnchorGenerator.php';
    
    $logger = new \LinkValidator\Utils\Logger();
    $security = new \LinkValidator\Utils\SecurityValidator();
    $generator = new \LinkValidator\Core\GitHubAnchorGenerator();
    
    return true;
});

// Test 2: GitHub Anchor Generation
runTest("GitHub Anchor Generation", function() {
    $generator = new \LinkValidator\Core\GitHubAnchorGenerator();
    
    $testCases = [
        ['1. Overview', '1-overview'],
        ['Setup & Configuration', 'setup--configuration'],
        ['SSL/TLS Configuration', 'ssltls-configuration'],
        ['1.1. Enterprise Features', '11-enterprise-features'],
    ];
    
    foreach ($testCases as [$input, $expected]) {
        $actual = $generator->generate($input);
        if ($actual !== $expected) {
            return "Anchor generation failed: '{$input}' → '{$actual}' (expected '{$expected}')";
        }
    }
    
    return true;
});

// Test 3: Anchor Generation Test Suite
runTest("Anchor Generation Test Suite", function() {
    $generator = new \LinkValidator\Core\GitHubAnchorGenerator();
    $results = $generator->runTests();
    
    if ($results['failed'] > 0) {
        return "Test suite failed: {$results['failed']} failures out of " . ($results['passed'] + $results['failed']) . " tests";
    }
    
    return true;
});

// Test 4: Logger Functionality
runTest("Logger Functionality", function() {
    $logger = new \LinkValidator\Utils\Logger();
    
    // Test verbosity levels
    $logger->setVerbosity(\LinkValidator\Utils\Logger::VERBOSE);
    if ($logger->getVerbosity() !== \LinkValidator\Utils\Logger::VERBOSE) {
        return "Verbosity setting failed";
    }
    
    // Test color disabling
    $logger->disableColors();
    
    return true;
});

// Test 5: Security Validator
runTest("Security Validator", function() {
    $security = new \LinkValidator\Utils\SecurityValidator();
    
    // Test path validation
    $validPath = $security->validatePath(__FILE__);
    if ($validPath === null) {
        return "Valid path rejected";
    }
    
    // Test dangerous path rejection
    $dangerousPath = $security->validatePath('../../../etc/passwd');
    if ($dangerousPath !== null) {
        return "Dangerous path not rejected";
    }
    
    // Test input sanitization
    $sanitized = $security->sanitizeInput("test\0input");
    if (str_contains($sanitized, "\0")) {
        return "Null byte not removed";
    }
    
    return true;
});

// Test 6: File Processor
runTest("File Processor", function() {
    require_once '.ai/tools/LinkValidator/Core/FileProcessor.php';
    
    $logger = new \LinkValidator\Utils\Logger();
    $security = new \LinkValidator\Utils\SecurityValidator();
    $processor = new \LinkValidator\Core\FileProcessor($logger, $security);
    
    // Create test files
    $testDir = '.ai/tools/test-files';
    if (!is_dir($testDir)) {
        mkdir($testDir, 0755, true);
    }
    
    file_put_contents("{$testDir}/test1.md", "# Test 1\nContent");
    file_put_contents("{$testDir}/test2.html", "<h1>Test 2</h1>");
    file_put_contents("{$testDir}/test3.txt", "Not markdown");
    
    try {
        $files = $processor->processInputs(
            [$testDir],
            0,      // max_depth
            false,  // include_hidden
            false,  // only_hidden
            []      // exclude_patterns
        );
        
        // Should find 2 files (test1.md and test2.html), not test3.txt
        if (count($files) !== 2) {
            return "Expected 2 files, found " . count($files);
        }
        
        return true;
        
    } finally {
        // Cleanup
        if (is_dir($testDir)) {
            array_map('unlink', glob("{$testDir}/*"));
            rmdir($testDir);
        }
    }
});

// Test 7: CLI Argument Parser
runTest("CLI Argument Parser", function() {
    require_once '.ai/tools/LinkValidator/Core/CLIArgumentParser.php';
    
    $logger = new \LinkValidator\Utils\Logger();
    $parser = new \LinkValidator\Core\CLIArgumentParser($logger);
    
    // Test basic argument parsing
    $config = $parser->parse(['script.php', '--help']);
    
    if (!$config['show_help']) {
        return "Help flag not parsed correctly";
    }
    
    return true;
});

// Test 8: Configuration Manager
runTest("Configuration Manager", function() {
    require_once '.ai/tools/LinkValidator/Core/ConfigurationManager.php';
    
    $logger = new \LinkValidator\Utils\Logger();
    $manager = new \LinkValidator\Core\ConfigurationManager($logger);
    
    // Test example config generation
    $example = $manager->generateExampleConfig();
    $decoded = json_decode($example, true);
    
    if (json_last_error() !== JSON_ERROR_NONE) {
        return "Example config is not valid JSON";
    }
    
    if (!isset($decoded['scope']) || !is_array($decoded['scope'])) {
        return "Example config missing required fields";
    }
    
    return true;
});

// Test 9: Report Generator
runTest("Report Generator", function() {
    require_once '.ai/tools/LinkValidator/Core/ReportGenerator.php';
    
    $logger = new \LinkValidator\Utils\Logger();
    $generator = new \LinkValidator\Core\ReportGenerator($logger);
    
    // Test report generation with sample data
    $sampleResults = [
        'timestamp' => date('c'),
        'execution_time' => 1.23,
        'summary' => [
            'total_files' => 5,
            'total_links' => 20,
            'broken_links' => 2,
            'success_rate' => 90.0,
            'internal_links' => 15,
            'anchor_links' => 3,
            'cross_reference_links' => 1,
            'external_links' => 1,
            'broken_internal' => 1,
            'broken_anchors' => 1,
            'broken_cross_references' => 0,
            'broken_external' => 0,
        ],
        'results' => [
            'test.md' => [
                'file' => 'test.md',
                'total_links' => 2,
                'broken_links' => [
                    [
                        'text' => 'Broken Link',
                        'url' => 'nonexistent.md',
                        'type' => 'internal',
                        'status' => 'File not found'
                    ]
                ],
                'working_links' => []
            ]
        ]
    ];
    
    // Test JSON generation
    $tempFile = tempnam(sys_get_temp_dir(), 'test_report_');
    try {
        $generator->generateReports($sampleResults, 'json', $tempFile, true);
        
        if (!file_exists($tempFile)) {
            return "Report file not created";
        }
        
        $content = file_get_contents($tempFile);
        $decoded = json_decode($content, true);
        
        if (json_last_error() !== JSON_ERROR_NONE) {
            return "Generated report is not valid JSON";
        }
        
        return true;
        
    } finally {
        if (file_exists($tempFile)) {
            unlink($tempFile);
        }
    }
});

// Test 10: Fuzzy Matcher
runTest("Fuzzy Matcher", function() {
    require_once '.ai/tools/LinkRectifier/Core/FuzzyMatcher.php';
    
    $logger = new \LinkValidator\Utils\Logger();
    $matcher = new \LinkValidator\Core\FuzzyMatcher($logger);
    
    $candidates = ['setup.md', 'configuration.md', 'setup-guide.md', 'install.md'];
    
    // Test exact match
    $match = $matcher->findBestMatch('setup.md', $candidates, 0.8);
    if ($match !== 'setup.md') {
        return "Exact match failed";
    }
    
    // Test fuzzy match
    $match = $matcher->findBestMatch('setup', $candidates, 0.5);
    if (!in_array($match, ['setup.md', 'setup-guide.md'])) {
        return "Fuzzy match failed: got '{$match}'";
    }
    
    // Test similarity calculation
    $similarity = $matcher->calculateSimilarity('setup', 'setup.md');
    if ($similarity < 0.5) {
        return "Similarity calculation too low: {$similarity}";
    }
    
    return true;
});

// Print test summary
echo "\n" . str_repeat("=", 50) . "\n";
echo "📊 Test Results Summary\n";
echo str_repeat("-", 30) . "\n";
echo "✅ Passed: {$testsPassed}\n";
echo "❌ Failed: {$testsFailed}\n";
echo "📈 Success Rate: " . round(($testsPassed / ($testsPassed + $testsFailed)) * 100, 1) . "%\n\n";

if ($testsFailed > 0) {
    echo "❌ Failed Tests:\n";
    foreach ($testResults as $name => $result) {
        if (str_starts_with($result, 'FAIL') || str_starts_with($result, 'ERROR')) {
            echo "  • {$name}: {$result}\n";
        }
    }
    echo "\n";
}

// Exit with appropriate code
exit($testsFailed > 0 ? 1 : 0);
