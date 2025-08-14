<?php
/**
 * PHPUnit Bootstrap File for PHP Link Validation and Remediation Tools
 * 
 * Sets up the testing environment, autoloading, and test utilities.
 */

declare(strict_types=1);

// Set error reporting for tests
error_reporting(E_ALL);
ini_set('display_errors', '1');

// Define test constants
define('TEST_ROOT', __DIR__);
define('PROJECT_ROOT', dirname(__DIR__));
define('FIXTURES_DIR', TEST_ROOT . '/fixtures');
define('TEMP_DIR', TEST_ROOT . '/temp');

// Ensure temp directory exists
if (!is_dir(TEMP_DIR)) {
    mkdir(TEMP_DIR, 0755, true);
}

// Clean temp directory before tests
array_map('unlink', glob(TEMP_DIR . '/*'));

// Autoload project classes
spl_autoload_register(function ($class) {
    // Handle LinkValidator namespace
    if (str_starts_with($class, 'LinkValidator\\')) {
        $file = PROJECT_ROOT . '/' . str_replace('\\', '/', $class) . '.php';
        if (file_exists($file)) {
            require_once $file;
            return;
        }
    }
    
    // Handle LinkRectifier namespace
    if (str_starts_with($class, 'LinkRectifier\\')) {
        $file = PROJECT_ROOT . '/' . str_replace('\\', '/', $class) . '.php';
        if (file_exists($file)) {
            require_once $file;
            return;
        }
    }
    
    // Handle test classes
    if (str_contains($class, 'Test')) {
        $file = TEST_ROOT . '/' . str_replace('\\', '/', $class) . '.php';
        if (file_exists($file)) {
            require_once $file;
            return;
        }
    }
});

// Test utilities and helpers
require_once TEST_ROOT . '/TestCase.php';
require_once TEST_ROOT . '/Helpers/ConfigurationTestHelper.php';
require_once TEST_ROOT . '/Helpers/FileSystemTestHelper.php';
require_once TEST_ROOT . '/Helpers/LinkValidationTestHelper.php';

// Set up test environment variables
putenv('LINK_VALIDATOR_TEST_MODE=true');
putenv('LINK_VALIDATOR_SCOPE=all');
putenv('LINK_VALIDATOR_MAX_BROKEN=0');
putenv('LINK_VALIDATOR_MAX_FILES=0');

// Register cleanup function
register_shutdown_function(function () {
    // Clean up temp files after all tests
    if (is_dir(TEMP_DIR)) {
        array_map('unlink', glob(TEMP_DIR . '/*'));
    }
});

echo "PHP Link Validation Tools Test Suite Bootstrap Complete\n";
echo "Test Root: " . TEST_ROOT . "\n";
echo "Project Root: " . PROJECT_ROOT . "\n";
echo "Fixtures Directory: " . FIXTURES_DIR . "\n";
echo "Temp Directory: " . TEMP_DIR . "\n";
