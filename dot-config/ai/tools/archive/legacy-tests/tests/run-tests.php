<?php
/**
 * Test Runner for PHP Link Validation and Remediation Tools
 *
 * Runs the complete test suite using Pest.
 */

declare(strict_types=1);

// Check if we're in the correct directory
if (!file_exists(__DIR__ . '/Pest.php')) {
    echo "Error: Must be run from the tests.old directory\n";
    exit(1);
}

// Check PHP version
if (version_compare(PHP_VERSION, '8.1.0', '<')) {
    echo "Error: PHP 8.1.0 or higher is required\n";
    exit(1);
}

// Colors for output
class Colors {
    const RED = "\033[31m";
    const GREEN = "\033[32m";
    const YELLOW = "\033[33m";
    const BLUE = "\033[34m";
    const MAGENTA = "\033[35m";
    const CYAN = "\033[36m";
    const WHITE = "\033[37m";
    const RESET = "\033[0m";
    const BOLD = "\033[1m";
}

function colorize(string $text, string $color): string {
    return $color . $text . Colors::RESET;
}

function printHeader(string $title): void {
    $line = str_repeat('=', 80);
    echo "\n" . colorize($line, Colors::CYAN) . "\n";
    echo colorize($title, Colors::BOLD . Colors::WHITE) . "\n";
    echo colorize($line, Colors::CYAN) . "\n\n";
}

function printSection(string $title): void {
    echo colorize("📋 " . $title, Colors::BLUE . Colors::BOLD) . "\n";
    echo colorize(str_repeat('-', strlen($title) + 3), Colors::BLUE) . "\n";
}

function runCommand(string $command, string $description): bool {
    echo colorize("🔄 " . $description . "...", Colors::YELLOW) . "\n";

    $startTime = microtime(true);
    $output = [];
    $returnCode = 0;

    exec($command . ' 2>&1', $output, $returnCode);

    $endTime = microtime(true);
    $duration = round($endTime - $startTime, 2);

    if ($returnCode === 0) {
        echo colorize("✅ " . $description . " completed successfully ({$duration}s)", Colors::GREEN) . "\n";
        return true;
    } else {
        echo colorize("❌ " . $description . " failed ({$duration}s)", Colors::RED) . "\n";
        echo colorize("Command: " . $command, Colors::RED) . "\n";
        echo colorize("Output:", Colors::RED) . "\n";
        foreach ($output as $line) {
            echo colorize("  " . $line, Colors::RED) . "\n";
        }
        return false;
    }
}

function checkPestInstallation(): bool {
    // Check if Pest is available
    $pestPaths = [
        __DIR__ . '/../vendor/bin/pest',
        __DIR__ . '/../../vendor/bin/pest',
        'pest', // Global installation
    ];

    foreach ($pestPaths as $pestPath) {
        if (file_exists($pestPath) || (is_string($pestPath) && $pestPath === 'pest')) {
            return true;
        }
    }

    return false;
}

function getPestCommand(): string {
    $pestPaths = [
        __DIR__ . '/../vendor/bin/pest',
        __DIR__ . '/../../vendor/bin/pest',
        'pest', // Global installation
    ];

    foreach ($pestPaths as $pestPath) {
        if (file_exists($pestPath)) {
            return $pestPath;
        }
    }

    return 'pest'; // Assume global installation
}

// Main execution
printHeader("PHP Link Validation Tools - Test Suite Runner");

// Parse command line arguments
$options = getopt('', [
    'help',
    'unit',
    'integration',
    'configuration',
    'performance',
    'coverage',
    'verbose',
    'filter:',
    'group:',
]);

if (isset($options['help'])) {
    echo colorize("Usage: php run-tests.old.php [options]", Colors::BOLD) . "\n\n";
    echo colorize("Options:", Colors::BOLD) . "\n";
    echo "  --help           Show this help message\n";
    echo "  --unit           Run only unit tests.old\n";
    echo "  --integration    Run only integration tests.old\n";
    echo "  --configuration  Run only configuration tests.old\n";
    echo "  --performance    Run only performance tests.old\n";
    echo "  --coverage       Generate code coverage report\n";
    echo "  --verbose        Verbose output\n";
    echo "  --filter=<name>  Filter tests.old by name\n";
    echo "  --group=<group>  Run tests.old in specific group\n\n";
    echo colorize("Examples:", Colors::BOLD) . "\n";
    echo "  php run-tests.old.php --unit\n";
    echo "  php run-tests.old.php --configuration --verbose\n";
    echo "  php run-tests.old.php --filter=CLIArgumentParser\n";
    echo "  php run-tests.old.php --group=configuration\n\n";
    exit(0);
}

// Check Pest installation
printSection("Environment Check");
if (!checkPestInstallation()) {
    echo colorize("❌ Pest testing framework not found", Colors::RED) . "\n";
    echo colorize("Please install Pest: composer require pestphp/pest --dev", Colors::YELLOW) . "\n";
    exit(1);
}
echo colorize("✅ Pest testing framework found", Colors::GREEN) . "\n";

// Check PHP extensions
$requiredExtensions = ['json', 'mbstring', 'curl'];
foreach ($requiredExtensions as $extension) {
    if (extension_loaded($extension)) {
        echo colorize("✅ PHP extension '{$extension}' loaded", Colors::GREEN) . "\n";
    } else {
        echo colorize("❌ PHP extension '{$extension}' not loaded", Colors::RED) . "\n";
        exit(1);
    }
}

// Setup test environment
printSection("Test Environment Setup");
echo colorize("🔧 Setting up test environment...", Colors::YELLOW) . "\n";

// Ensure temp directory exists and is clean
$tempDir = __DIR__ . '/temp';
if (is_dir($tempDir)) {
    array_map('unlink', glob($tempDir . '/*'));
} else {
    mkdir($tempDir, 0755, true);
}
echo colorize("✅ Test temp directory prepared", Colors::GREEN) . "\n";

// Build Pest command
$pestCommand = getPestCommand();
$pestArgs = [];

// Add verbosity
if (isset($options['verbose'])) {
    $pestArgs[] = '--verbose';
}

// Add coverage
if (isset($options['coverage'])) {
    $pestArgs[] = '--coverage';
    $pestArgs[] = '--coverage-html=coverage-html';
}

// Add filter
if (isset($options['filter'])) {
    $pestArgs[] = '--filter=' . escapeshellarg($options['filter']);
}

// Add group
if (isset($options['group'])) {
    $pestArgs[] = '--group=' . escapeshellarg($options['group']);
}

// Determine which test suites to run
$testSuites = [];
if (isset($options['unit'])) {
    $testSuites[] = 'Unit';
} elseif (isset($options['integration'])) {
    $testSuites[] = 'Integration';
} elseif (isset($options['configuration'])) {
    $testSuites[] = 'Configuration';
} elseif (isset($options['performance'])) {
    $testSuites[] = 'Performance';
} else {
    // Run all test suites
    $testSuites = ['Configuration', 'Unit', 'Integration', 'Performance'];
}

// Run tests
printSection("Running Tests");
$allPassed = true;
$totalStartTime = microtime(true);

foreach ($testSuites as $suite) {
    $suiteDir = __DIR__ . '/' . $suite;
    if (!is_dir($suiteDir)) {
        echo colorize("⚠️  Test suite directory not found: {$suite}", Colors::YELLOW) . "\n";
        continue;
    }

    $command = $pestCommand . ' ' . escapeshellarg($suiteDir) . ' ' . implode(' ', $pestArgs);
    $success = runCommand($command, "Running {$suite} tests.old");

    if (!$success) {
        $allPassed = false;
    }
}

$totalEndTime = microtime(true);
$totalDuration = round($totalEndTime - $totalStartTime, 2);

// Summary
printSection("Test Results Summary");
if ($allPassed) {
    echo colorize("🎉 All tests.old passed! ({$totalDuration}s total)", Colors::GREEN . Colors::BOLD) . "\n";

    if (isset($options['coverage'])) {
        echo colorize("📊 Coverage report generated in coverage-html/", Colors::BLUE) . "\n";
    }

    exit(0);
} else {
    echo colorize("💥 Some tests.old failed! ({$totalDuration}s total)", Colors::RED . Colors::BOLD) . "\n";
    echo colorize("Please review the output above for details.", Colors::YELLOW) . "\n";
    exit(1);
}
