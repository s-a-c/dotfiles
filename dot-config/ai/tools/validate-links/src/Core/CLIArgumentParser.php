<?php
/**
 * Command Line Interface Argument Parser
 *
 * Provides comprehensive CLI argument parsing with support for long options,
 * input validation, security measures, and detailed help documentation.
 *
 * @package SAC\ValidateLinks\Core
 */

declare(strict_types=1);

namespace SAC\ValidateLinks\Core;

use SAC\ValidateLinks\Utils\Logger;

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
        'fix' => false, // Enable LinkRectifier functionality
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
        'fix',
        'config:',
        'help',
    ];

    /**
     * Valid scope values
     */
    private const VALID_SCOPES = [
        'all',
        'internal',
        'anchor',
        'cross_reference',
        'external',
    ];

    /**
     * Valid format values
     */
    private const VALID_FORMATS = [
        'console',
        'json',
        'markdown',
        'html',
    ];

    /**
     * Environment variable mappings
     */
    private const ENV_MAPPINGS = [
        'LINK_VALIDATOR_SCOPE' => 'scope',
        'LINK_VALIDATOR_MAX_BROKEN' => 'max_broken',
        'LINK_VALIDATOR_MAX_FILES' => 'max_files',
        'LINK_VALIDATOR_TIMEOUT' => 'timeout',
        'LINK_VALIDATOR_FORMAT' => 'format',
        'LINK_VALIDATOR_CHECK_EXTERNAL' => 'check_external',
        'LINK_VALIDATOR_CASE_SENSITIVE' => 'case_sensitive',
        'LINK_VALIDATOR_MAX_DEPTH' => 'max_depth',
        'LINK_VALIDATOR_INCLUDE_HIDDEN' => 'include_hidden',
        'LINK_VALIDATOR_ONLY_HIDDEN' => 'only_hidden',
        'LINK_VALIDATOR_NO_COLOR' => 'no_color',
        'LINK_VALIDATOR_DRY_RUN' => 'dry_run',
        'LINK_VALIDATOR_FIX' => 'fix',
    ];

    public function __construct(Logger $logger)
    {
        $this->logger = $logger;
    }

    /**
     * Parse command line arguments and return configuration array
     *
     * @param array<string> $argv Command line arguments
     * @return array<string, mixed> Parsed configuration
     * @throws \InvalidArgumentException On invalid arguments
     */
    public function parse(array $argv): array
    {
        try {
            // Start with defaults
            $config = self::DEFAULTS;

            // Apply environment variables first (lowest priority)
            $this->applyEnvironmentVariables($config);

            // Parse command line options
            $options = getopt('', self::LONG_OPTIONS);
            if ($options === false) {
                throw new \InvalidArgumentException('Failed to parse command line options');
            }

            // Debug: log what options were parsed
            $this->logger->debug('Parsed options: ' . json_encode($options));

            // Apply command line options (highest priority)
            $this->applyCommandLineOptions($config, $options);

            // Extract input files from remaining arguments
            $this->extractInputFiles($config, $argv, $options);

            // Validate configuration
            $this->validateConfiguration($config);

            return $config;
        } catch (\Throwable $e) {
            throw new \InvalidArgumentException('Configuration error: ' . $e->getMessage(), 0, $e);
        }
    }

    /**
     * Apply environment variables to configuration
     */
    private function applyEnvironmentVariables(array &$config): void
    {
        foreach (self::ENV_MAPPINGS as $envVar => $configKey) {
            $value = getenv($envVar);
            if ($value !== false && $value !== '') {
                $config[$configKey] = $this->parseEnvironmentValue($configKey, $value);
            }
        }
    }

    /**
     * Parse environment variable value based on configuration key
     */
    private function parseEnvironmentValue(string $key, string $value): mixed
    {
        return match ($key) {
            'scope' => $this->parseScope($value),
            'max_broken', 'max_files', 'timeout', 'max_depth' => $this->parseInteger($value, $key),
            'check_external', 'case_sensitive', 'include_hidden', 'only_hidden', 'no_color', 'dry_run', 'fix' => $this->parseBoolean($value),
            default => $value,
        };
    }

    /**
     * Apply command line options to configuration
     */
    private function applyCommandLineOptions(array &$config, array $options): void
    {
        foreach ($options as $option => $value) {
            match ($option) {
                'max-depth' => $config['max_depth'] = $this->parseInteger($value, 'max-depth'),
                'include-hidden' => $config['include_hidden'] = true,
                'only-hidden' => $config['only_hidden'] = true,
                'exclude' => $config['exclude_patterns'] = $this->parseExcludePatterns($value),
                'scope' => $config['scope'] = $this->parseScope($value),
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
                'fix' => $config['fix'] = true,
                'config' => $config['config_file'] = $this->parseString($value, 'config'),
                'help' => $config['show_help'] = true,
                default => throw new \InvalidArgumentException("Unknown option: {$option}"),
            };
        }
    }

    /**
     * Extract input files from command line arguments
     */
    private function extractInputFiles(array &$config, array $argv, array $options): void
    {
        // Remove script name
        array_shift($argv);

        // Remove processed options
        $filteredArgv = [];
        $skipNext = false;

        for ($i = 0; $i < count($argv); $i++) {
            $arg = $argv[$i];

            if ($skipNext) {
                $skipNext = false;
                continue;
            }

            // Check if this is an option
            if (str_starts_with($arg, '--')) {
                $optionName = substr($arg, 2);

                // Handle --option=value format
                if (str_contains($optionName, '=')) {
                    $optionName = explode('=', $optionName, 2)[0];
                }

                // Check if this option was processed
                if (array_key_exists($optionName, $options)) {
                    // Skip this option
                    // If it's not in --option=value format and the option expects a value,
                    // also skip the next argument
                    if (!str_contains($arg, '=') && isset($argv[$i + 1]) && !str_starts_with($argv[$i + 1], '--')) {
                        // Check if this option expects a value
                        $expectsValue = in_array($optionName . ':', self::LONG_OPTIONS);
                        if ($expectsValue) {
                            $skipNext = true;
                        }
                    }
                    continue;
                }
            }

            // This is not an option, so it's an input file
            $filteredArgv[] = $arg;
        }

        // Remaining arguments are input files
        $config['inputs'] = $filteredArgv;
    }

    /**
     * Validate the final configuration
     */
    private function validateConfiguration(array $config): void
    {
        // Validate inputs
        if (empty($config['inputs']) && !$config['show_help']) {
            throw new \InvalidArgumentException('No input files or directories specified');
        }

        // Validate scope
        foreach ($config['scope'] as $scope) {
            if (!in_array($scope, self::VALID_SCOPES, true)) {
                throw new \InvalidArgumentException("Invalid scope: {$scope}. Valid scopes: " . implode(', ', self::VALID_SCOPES));
            }
        }

        // Validate format
        if (!in_array($config['format'], self::VALID_FORMATS, true)) {
            throw new \InvalidArgumentException("Invalid format: {$config['format']}. Valid formats: " . implode(', ', self::VALID_FORMATS));
        }

        // Validate timeout
        if ($config['timeout'] <= 0) {
            throw new \InvalidArgumentException('Timeout must be positive');
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

        // Validate fix + dry-run combination (this is allowed for preview mode)
        // No validation needed - this is a valid combination for showing what would be fixed
    }

    /**
     * Parse scope string into array
     */
    private function parseScope(string $scope): array
    {
        if (empty($scope)) {
            return [''];
        }

        return array_map('trim', explode(',', $scope));
    }

    /**
     * Parse exclude patterns
     */
    private function parseExcludePatterns(string|array $patterns): array
    {
        if (is_array($patterns)) {
            return $patterns;
        }

        return array_map('trim', explode(',', $patterns));
    }

    /**
     * Parse integer value with validation
     */
    private function parseInteger(string $value, string $option): int
    {
        if (!is_numeric($value)) {
            return 0; // Graceful fallback for environment variables
        }

        $int = (int) $value;

        // Validate based on option type
        if (str_contains($option, 'max-') && $int < 0) {
            throw new \InvalidArgumentException("Option --{$option} must be non-negative");
        }

        if ($option === 'timeout' && $int <= 0) {
            throw new \InvalidArgumentException('Timeout must be positive');
        }

        return $int;
    }

    /**
     * Parse string value
     */
    private function parseString(string $value, string $option): string
    {
        return $value;
    }

    /**
     * Parse boolean value from string
     */
    private function parseBoolean(string $value): bool
    {
        return match (strtolower($value)) {
            'true', '1', 'yes', 'on' => true,
            'false', '0', 'no', 'off' => false,
            default => false,
        };
    }

    /**
     * Display help information
     */
    public function showHelp(): void
    {
        echo $this->getHelpText();
    }

    /**
     * Get help text
     */
    public function getHelpText(): string
    {
        return <<<'HELP'
PHP Link Validation and Remediation Tools

USAGE:
    validate-links [OPTIONS] <files-or-directories>...

DESCRIPTION:
    Comprehensive tool for validating and fixing broken links in documentation.
    Supports Markdown, HTML, and other text-based formats with advanced
    filtering, reporting, and automatic link remediation capabilities.

VALIDATION OPTIONS:
    --scope=<types>         Link types to validate (default: all)
                           Values: all, internal, anchor, cross_reference, external
                           Multiple: --scope=internal,anchor

    --check-external       Validate external HTTP/HTTPS links (slower)
    --case-sensitive       Use case-sensitive file path validation
    --timeout=<seconds>    Timeout for external link validation (default: 30)

FILTERING OPTIONS:
    --max-depth=<n>        Maximum directory depth to scan (0 = unlimited)
    --include-hidden       Include hidden files and directories
    --only-hidden          Process only hidden files and directories
    --exclude=<patterns>   Exclude files matching patterns (glob syntax)
                          Multiple: --exclude="*.tmp,temp/*"

TERMINATION OPTIONS:
    --max-broken=<n>       Stop after finding N broken links (default: 50, 0 = unlimited)
    --max-files=<n>        Stop after processing N files (default: 0 = unlimited)

OUTPUT OPTIONS:
    --format=<type>        Output format: console, json, markdown, html (default: console)
    --output=<file>        Write output to file instead of stdout
    --no-color            Disable colored output
    --quiet               Minimal output (errors only)
    --verbose             Detailed progress information
    --debug               Maximum verbosity with debug information

REMEDIATION OPTIONS:
    --fix                 Enable automatic link fixing after validation
    --dry-run             Preview mode - show what would be done without making changes

CONFIGURATION:
    --config=<file>       Load configuration from JSON file

BEHAVIOR:
    Without --fix:        Only validation is performed (current behavior)
    With --fix:           Validation first, then automatic link fixing
    With --fix --dry-run: Show what fixes would be applied (preview mode)
    With --dry-run only:  Show validation scope preview

EXAMPLES:
    # Basic validation
    validate-links docs/

    # Validate with scope filtering
    validate-links docs/ --scope=internal,anchor

    # Validate and fix broken links
    validate-links docs/ --fix

    # Preview what would be fixed
    validate-links docs/ --fix --dry-run

    # CI/CD friendly validation
    validate-links docs/ --max-broken=0 --format=json --quiet

    # Performance optimized validation
    validate-links docs/ --max-files=10 --scope=internal

ENVIRONMENT VARIABLES:
    LINK_VALIDATOR_SCOPE            Default scope
    LINK_VALIDATOR_MAX_BROKEN       Default max broken links
    LINK_VALIDATOR_MAX_FILES        Default max files
    LINK_VALIDATOR_CHECK_EXTERNAL   Enable external link checking
    LINK_VALIDATOR_FIX              Enable automatic fixing

For more information and examples, visit:
https://github.com/s-a-c/validate-links

HELP;
    }
}
