<?php
/**
 * Command Line Interface Argument Parser
 *
 * Provides comprehensive CLI argument parsing with support for long options,
 * input validation, security measures, and detailed help documentation.
 *
 * @package LinkValidator\Core
 */

declare(strict_types=1);

namespace LinkValidator\Core;

use LinkValidator\Utils\Logger;

/**
 * CLI argument parser with comprehensive validation and help system
 *
 * Handles parsing of command line arguments with support for long options,
 * input validation, and comprehensive error handling.
 */
final class CLIArgumentParser
{
    private readonly Logger $logger;

    /**
     * Default configuration values
     */
    private const DEFAULTS = [
        'inputs' => [],
        'max_depth' => 0,
        'include_hidden' => false,
        'only_hidden' => false,
        'exclude_patterns' => [],
        'scope' => ['all'],
        'check_external' => false,
        'case_sensitive' => false,
        'timeout' => 30,
        'format' => 'console',
        'output' => null,
        'no_color' => false,
        'verbosity' => Logger::NORMAL,
        'max_broken' => 50, // Default of 50 prevents runaway validation in CI
        'max_files' => 0, // 0 = unlimited files for backward compatibility
        'dry_run' => false, // Preview mode - show what would be validated without validating
        'config_file' => null,
        'show_help' => false,
    ];

    /**
     * Long option definitions
     */
    private const LONG_OPTIONS = [
        'max-depth:',
        'include-hidden',
        'only-hidden',
        'exclude:',
        'scope:',
        'check-external',
        'case-sensitive',
        'timeout:',
        'format:',
        'output:',
        'no-color',
        'quiet',
        'verbose',
        'debug',
        'max-broken:',
        'max-files:',
        'dry-run',
        'config:',
        'help',
    ];

    public function __construct(Logger $logger)
    {
        $this->logger = $logger;
    }

    /**
     * Parse command line arguments
     *
     * @param array<string> $argv Command line arguments
     * @return array<string, mixed> Parsed configuration
     * @throws \InvalidArgumentException If arguments are invalid
     */
    public function parse(array $argv): array
    {
        // Step 1: Start with defaults
        $config = self::DEFAULTS;

        // Step 2: Apply environment variables (lowest priority)
        $config = $this->applyEnvironmentVariables($config);

        // Step 3: Parse command line to find config file
        $configFile = $this->extractConfigFile($argv);

        // Step 4: Apply config file if specified (medium priority)
        if ($configFile !== null) {
            $config['config_file'] = $configFile;
            // Note: Config file loading happens in main application
        }

        // Step 5: Apply command line arguments (highest priority)
        $config = $this->parseCommandLineArguments($argv, $config);

        // Validate final configuration
        $this->validateConfiguration($config);

        return $config;
    }

    /**
     * Apply environment variables to configuration
     */
    private function applyEnvironmentVariables(array $config): array
    {
        $envMappings = [
            'LINK_VALIDATOR_SCOPE' => 'scope',
            'LINK_VALIDATOR_MAX_BROKEN' => 'max_broken',
            'LINK_VALIDATOR_MAX_FILES' => 'max_files',
            'LINK_VALIDATOR_TIMEOUT' => 'timeout',
            'LINK_VALIDATOR_FORMAT' => 'format',
            'LINK_VALIDATOR_CHECK_EXTERNAL' => 'check_external',
            'LINK_VALIDATOR_CASE_SENSITIVE' => 'case_sensitive',
            'LINK_VALIDATOR_MAX_DEPTH' => 'max_depth',
        ];

        foreach ($envMappings as $envVar => $configKey) {
            $value = getenv($envVar);
            if ($value !== false) {
                $config[$configKey] = match ($configKey) {
                    'scope' => $this->parseCommaSeparated($value),
                    'max_broken', 'max_files', 'timeout', 'max_depth' => (int) $value,
                    'check_external', 'case_sensitive' => filter_var($value, FILTER_VALIDATE_BOOLEAN),
                    default => $value,
                };
            }
        }

        return $config;
    }

    /**
     * Extract config file from command line arguments
     */
    private function extractConfigFile(array $argv): ?string
    {
        for ($i = 1; $i < count($argv); $i++) {
            $arg = $argv[$i];
            if (str_starts_with($arg, '--config=')) {
                return substr($arg, 9); // Remove --config=
            }
        }
        return null;
    }

    /**
     * Parse command line arguments
     */
    private function parseCommandLineArguments(array $argv, array $config): array
    {
        $options = [];
        $inputs = [];

        // Skip script name
        for ($i = 1; $i < count($argv); $i++) {
            $arg = $argv[$i];

            if (str_starts_with($arg, '--')) {
                // Handle long options
                if (str_contains($arg, '=')) {
                    [$option, $value] = explode('=', $arg, 2);
                    $option = substr($option, 2); // Remove --
                    $options[$option] = $value;
                } else {
                    $option = substr($arg, 2); // Remove --
                    $options[$option] = true;
                }
            } else {
                // Non-option argument (input file/directory)
                $inputs[] = $arg;
            }
        }

        // Process parsed options
        $config = $this->processOptions($options, $config);

        // Set input files/directories
        if (!empty($inputs)) {
            $config['inputs'] = array_merge($config['inputs'], $inputs);
        }

        return $config;
    }

    /**
     * Process parsed options into configuration
     *
     * @param array<string, mixed> $options Parsed options
     * @param array<string, mixed> $config Current configuration
     * @return array<string, mixed> Updated configuration
     */
    private function processOptions(array $options, array $config): array
    {
        foreach ($options as $option => $value) {
            match ($option) {
                'max-depth' => $config['max_depth'] = $this->parseInteger($value, 'max-depth'),
                'include-hidden' => $config['include_hidden'] = true,
                'only-hidden' => $config['only_hidden'] = true,
                'exclude' => $config['exclude_patterns'] = $this->parseCommaSeparated($value),
                'scope' => $config['scope'] = $this->parseCommaSeparated($value),
                'check-external' => $config['check_external'] = true,
                'case-sensitive' => $config['case_sensitive'] = true,
                'timeout' => $config['timeout'] = $this->parseInteger($value, 'timeout'),
                'format' => $config['format'] = $this->parseString($value, 'format'),
                'output' => $config['output'] = $this->parseString($value, 'output'),
                'no-color' => $config['no_color'] = true,
                'quiet' => $config['verbosity'] = Logger::QUIET,
                'verbose' => $config['verbosity'] = Logger::VERBOSE,
                'debug' => $config['verbosity'] = Logger::DEBUG,
                'max-broken' => $config['max_broken'] = $this->parseInteger($value, 'max-broken'),
                'max-files' => $config['max_files'] = $this->parseInteger($value, 'max-files'),
                'dry-run' => $config['dry_run'] = true,
                'config' => $config['config_file'] = $this->parseString($value, 'config'),
                'help' => $config['show_help'] = true,
                default => throw new \InvalidArgumentException("Unknown option: {$option}"),
            };
        }

        return $config;
    }

    /**
     * Parse an integer value
     *
     * @param mixed $value Value to parse
     * @param string $option Option name for error messages
     * @return int Parsed integer
     * @throws \InvalidArgumentException If value is invalid
     */
    private function parseInteger(mixed $value, string $option): int
    {
        if (!is_numeric($value)) {
            throw new \InvalidArgumentException("Option --{$option} requires a numeric value");
        }

        $intValue = (int) $value;

        if ($intValue < 0) {
            throw new \InvalidArgumentException("Option --{$option} must be non-negative");
        }

        return $intValue;
    }

    /**
     * Parse a string value
     *
     * @param mixed $value Value to parse
     * @param string $option Option name for error messages
     * @return string Parsed string
     * @throws \InvalidArgumentException If value is invalid
     */
    private function parseString(mixed $value, string $option): string
    {
        if (!is_string($value)) {
            throw new \InvalidArgumentException("Option --{$option} requires a string value");
        }

        $trimmed = trim($value);

        if (empty($trimmed)) {
            throw new \InvalidArgumentException("Option --{$option} cannot be empty");
        }

        return $trimmed;
    }

    /**
     * Parse comma-separated values
     *
     * @param mixed $value Value to parse
     * @return array<string> Parsed values
     */
    private function parseCommaSeparated(mixed $value): array
    {
        if (!is_string($value)) {
            return [];
        }

        $values = explode(',', $value);
        $trimmed = array_map('trim', $values);

        return array_filter($trimmed, fn($v) => !empty($v));
    }

    /**
     * Validate the parsed configuration
     *
     * @param array<string, mixed> $config Configuration to validate
     * @throws \InvalidArgumentException If configuration is invalid
     */
    private function validateConfiguration(array $config): void
    {
        // Validate scope values
        $validScopes = ['internal', 'anchor', 'cross-reference', 'external', 'all'];
        foreach ($config['scope'] as $scope) {
            if (!in_array($scope, $validScopes, true)) {
                throw new \InvalidArgumentException("Invalid scope: {$scope}. Valid scopes: " . implode(', ', $validScopes));
            }
        }

        // Validate format
        $validFormats = ['json', 'markdown', 'html', 'console'];
        if (!in_array($config['format'], $validFormats, true)) {
            throw new \InvalidArgumentException("Invalid format: {$config['format']}. Valid formats: " . implode(', ', $validFormats));
        }

        // Validate timeout
        if ($config['timeout'] <= 0) {
            throw new \InvalidArgumentException('Timeout must be positive');
        }

        // Validate max_depth
        if ($config['max_depth'] < 0) {
            throw new \InvalidArgumentException('Max depth must be non-negative');
        }

        // Validate max_broken
        if ($config['max_broken'] < 0) {
            throw new \InvalidArgumentException('Max broken links must be non-negative');
        }

        // Validate max_files
        if ($config['max_files'] < 0) {
            throw new \InvalidArgumentException('Max files must be non-negative');
        }

        // Validate conflicting options
        if ($config['include_hidden'] && $config['only_hidden']) {
            throw new \InvalidArgumentException('Cannot use both --include-hidden and --only-hidden');
        }

        // Validate inputs (unless showing help)
        if (!$config['show_help'] && empty($config['inputs'])) {
            throw new \InvalidArgumentException('No input files or directories specified');
        }

        // Validate output file if specified
        if ($config['output'] !== null) {
            $outputDir = dirname($config['output']);
            if (!is_dir($outputDir) || !is_writable($outputDir)) {
                throw new \InvalidArgumentException("Output directory is not writable: {$outputDir}");
            }
        }

        // Validate config file if specified
        if ($config['config_file'] !== null && !is_readable($config['config_file'])) {
            throw new \InvalidArgumentException("Config file is not readable: {$config['config_file']}");
        }
    }

    /**
     * Get usage information
     *
     * @return string Usage string
     */
    public function getUsage(): string
    {
        return 'php link-validator.php [OPTIONS] <files_or_directories>...';
    }

    /**
     * Get detailed help information
     *
     * @return string Help text
     */
    public function getHelp(): string
    {
        return <<<'HELP'
PHP Link Validator - Comprehensive Documentation Link Validation Tool

USAGE:
    php link-validator.php [OPTIONS] <files_or_directories>...

DESCRIPTION:
    Validates links in markdown and HTML documentation files with comprehensive
    reporting and multiple output formats. Supports internal links, anchor links,
    cross-references, and external links with configurable validation scopes.

OPTIONS:
    Input and Processing:
        --max-depth=N           Maximum directory traversal depth (default: unlimited)
        --include-hidden        Include hidden files and directories
        --only-hidden          Process only hidden files
        --exclude=PATTERNS     Comma-separated exclude patterns (e.g., "*.backup.md,temp/*")

    Validation Scope:
        --scope=TYPES          Comma-separated link types to validate:
                              internal,anchor,cross-reference,external,all (default: all)
        --check-external       Validate external HTTP/HTTPS links (slower)
        --case-sensitive       Enable case-sensitive link checking
        --timeout=SECONDS      Timeout for external link validation (default: 30)

    Output and Reporting:
        --format=FORMAT        Output format: json,markdown,html,console (default: console)
        --output=FILE          Output file path (default: stdout)
        --no-color            Disable colored output
        --quiet               Suppress all output except errors
        --verbose             Enable verbose output
        --debug               Enable debug output with stack traces

    Validation Thresholds:
        --max-broken=N         Maximum allowed broken links (default: 0)

    Configuration:
        --config=FILE          Load configuration from JSON file
        --help                Show this help message

EXAMPLES:
    # Validate all markdown files in docs directory
    php link-validator.php docs/

    # Validate specific files with JSON output
    php link-validator.php file1.md file2.md --format=json --output=report.json

    # Validate only internal and anchor links
    php link-validator.php docs/ --scope=internal,anchor

    # Validate with custom exclusions and depth limit
    php link-validator.php docs/ --exclude="*.backup.md,temp/*" --max-depth=3

    # CI/CD integration with error threshold
    php link-validator.php docs/ --max-broken=5 --quiet

EXIT CODES:
    0    Success - all links valid or within threshold
    1    Validation failures - broken links exceed threshold
    2    System errors - file access, network, or runtime errors
    3    Configuration errors - invalid arguments or config

CONFIGURATION FILE:
    Create .link-validator.json in your project root:
    {
        "scope": ["internal", "anchor"],
        "max_broken": 10,
        "exclude_patterns": ["*.backup.md", "temp/*"],
        "check_external": false,
        "timeout": 30
    }

For more information and examples, visit:
https://github.com/your-org/php-link-validator

HELP;
    }
}
