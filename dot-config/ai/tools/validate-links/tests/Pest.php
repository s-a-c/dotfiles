<?php
/**
 * Pest Configuration for PHP Link Validation and Remediation Tools
 *
 * Sets up the testing environment, autoloading, and test utilities for Pest.
 */

declare(strict_types=1);

use Pest\TestSuite;

// Define test constants
define('TEST_ROOT', __DIR__);
define('PROJECT_ROOT', dirname(__DIR__));
define('FIXTURES_DIR', TEST_ROOT . '/fixtures');
define('TEMP_DIR', TEST_ROOT . '/temp');

// Ensure directories exist
if (!is_dir(TEMP_DIR)) {
    mkdir(TEMP_DIR, 0755, true);
}
if (!is_dir(FIXTURES_DIR)) {
    mkdir(FIXTURES_DIR, 0755, true);
}

// Autoload project classes
spl_autoload_register(function ($class) {
    // Handle SAC\ValidateLinks namespace
    if (str_starts_with($class, 'SAC\\ValidateLinks\\')) {
        $file = PROJECT_ROOT . '/src/' . str_replace(['SAC\\ValidateLinks\\', '\\'], ['', '/'], $class) . '.php';
        if (file_exists($file)) {
            require_once $file;
            return;
        }
    }
});

// Test helpers and utilities
require_once TEST_ROOT . '/Helpers/ConfigurationHelper.php';
require_once TEST_ROOT . '/Helpers/FileSystemHelper.php';
require_once TEST_ROOT . '/Helpers/LinkValidationHelper.php';
require_once TEST_ROOT . '/Helpers/FixtureHelper.php';

// Global test setup
uses()->beforeEach(function () {
    // Clean temp directory before each test
    if (is_dir(TEMP_DIR)) {
        array_map('unlink', glob(TEMP_DIR . '/*'));
    }

    // Reset environment variables
    putenv('LINK_VALIDATOR_SCOPE=');
    putenv('LINK_VALIDATOR_MAX_BROKEN=');
    putenv('LINK_VALIDATOR_MAX_FILES=');
    putenv('LINK_VALIDATOR_TIMEOUT=');
    putenv('LINK_VALIDATOR_FORMAT=');
    putenv('LINK_VALIDATOR_CHECK_EXTERNAL=');
    putenv('LINK_VALIDATOR_CASE_SENSITIVE=');
    putenv('LINK_VALIDATOR_MAX_DEPTH=');
})->in('Unit', 'Integration', 'Configuration', 'Performance');

// Global test teardown
uses()->afterEach(function () {
    // Clean up any test files
    if (is_dir(TEMP_DIR)) {
        array_map('unlink', glob(TEMP_DIR . '/*'));
    }
})->in('Unit', 'Integration', 'Configuration', 'Performance');

// Test suite configuration
uses()->group('unit')->in('Unit');
uses()->group('integration')->in('Integration');
uses()->group('configuration')->in('Configuration');
uses()->group('performance')->in('Performance');

// Custom expectations
expect()->extend('toBeValidConfiguration', function () {
    return $this->toBeArray()
                ->and($this->value)->toHaveKeys([
                    'inputs', 'max_depth', 'scope', 'format', 'max_broken', 'max_files'
                ]);
});

expect()->extend('toBeValidLinkValidationResult', function () {
    return $this->toBeArray()
                ->and($this->value)->toHaveKeys([
                    'summary', 'results', 'timestamp', 'execution_time'
                ]);
});

expect()->extend('toBeValidFileList', function () {
    return $this->toBeArray()
                ->and($this->value)->each->toBeString()
                ->and($this->value)->each->toMatch('/\.md$/');
});

// Helper functions available in all tests
function createTempFile(string $content, string $extension = '.md'): string
{
    $filename = TEMP_DIR . '/' . uniqid('test_') . $extension;
    file_put_contents($filename, $content);
    return $filename;
}

function createTempDirectory(array $files = []): string
{
    $dirname = TEMP_DIR . '/' . uniqid('test_dir_');
    mkdir($dirname, 0755, true);

    foreach ($files as $filename => $content) {
        file_put_contents($dirname . '/' . $filename, $content);
    }

    return $dirname;
}

function createConfigFile(array $config): string
{
    $filename = TEMP_DIR . '/' . uniqid('config_') . '.json';
    file_put_contents($filename, json_encode($config, JSON_PRETTY_PRINT));
    return $filename;
}

function getLogger(): SAC\ValidateLinks\Utils\Logger
{
    return new SAC\ValidateLinks\Utils\Logger();
}

function getSecurityValidator(): SAC\ValidateLinks\Utils\SecurityValidator
{
    return new SAC\ValidateLinks\Utils\SecurityValidator();
}

function getCLIArgumentParser(): SAC\ValidateLinks\Core\CLIArgumentParser
{
    return new SAC\ValidateLinks\Core\CLIArgumentParser(getLogger());
}

function getLinkValidator(): SAC\ValidateLinks\Core\LinkValidator
{
    return new SAC\ValidateLinks\Core\LinkValidator(getLogger(), getSecurityValidator());
}

function getReportGenerator(): SAC\ValidateLinks\Core\ReportGenerator
{
    return new SAC\ValidateLinks\Core\ReportGenerator(getLogger());
}

echo "Pest Test Suite for PHP Link Validation Tools Initialized\n";
