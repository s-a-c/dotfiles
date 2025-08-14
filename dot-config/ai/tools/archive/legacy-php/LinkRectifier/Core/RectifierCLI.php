<?php
/**
 * Link Rectifier CLI Argument Parser
 *
 * Specialized CLI argument parser for the link rectifier with support for
 * fixing-specific options, backup management, and interactive modes.
 *
 * @package LinkRectifier\Core
 */

declare(strict_types=1);

namespace LinkRectifier\Core;

use LinkValidator\Utils\Logger;

/**
 * CLI argument parser for link rectifier
 *
 * Handles parsing of command line arguments specific to link fixing operations
 * including dry-run mode, interactive mode, and backup management.
 */
final class RectifierCLI
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
        'fix_scope' => ['all'],
        'fix_files' => [],
        'similarity_threshold' => 0.8,
        'dry_run' => false,
        'interactive' => false,
        'batch' => true,
        'backup_dir' => '.ai/backups',
        'rollback_timestamp' => null,
        'case_sensitive' => false,
        'no_color' => false,
        'verbosity' => Logger::NORMAL,
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
        'fix-scope:',
        'fix-files:',
        'similarity-threshold:',
        'dry-run',
        'interactive',
        'batch',
        'backup-dir:',
        'rollback:',
        'case-sensitive',
        'no-color',
        'quiet',
        'verbose',
        'debug',
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
        $config = self::DEFAULTS;

        // Parse options using getopt (don't remove script name first)
        $options = getopt('', self::LONG_OPTIONS, $optind);

        if ($options === false) {
            throw new \InvalidArgumentException('Failed to parse command line arguments');
        }

        // Process parsed options
        $config = $this->processOptions($options, $config);

        // Get remaining arguments as input files/directories (skip script name)
        $inputs = array_slice($argv, $optind);
        if (!empty($inputs)) {
            $config['inputs'] = array_merge($config['inputs'], $inputs);
        }

        // Validate configuration
        $this->validateConfiguration($config);

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
                'fix-scope' => $config['fix_scope'] = $this->parseCommaSeparated($value),
                'fix-files' => $config['fix_files'] = $this->parseCommaSeparated($value),
                'similarity-threshold' => $config['similarity_threshold'] = $this->parseFloat($value, 'similarity-threshold'),
                'dry-run' => $config['dry_run'] = true,
                'interactive' => $config['interactive'] = true,
                'batch' => $config['batch'] = true,
                'backup-dir' => $config['backup_dir'] = $this->parseString($value, 'backup-dir'),
                'rollback' => $config['rollback_timestamp'] = $this->parseString($value, 'rollback'),
                'case-sensitive' => $config['case_sensitive'] = true,
                'no-color' => $config['no_color'] = true,
                'quiet' => $config['verbosity'] = Logger::QUIET,
                'verbose' => $config['verbosity'] = Logger::VERBOSE,
                'debug' => $config['verbosity'] = Logger::DEBUG,
                'help' => $config['show_help'] = true,
                default => throw new \InvalidArgumentException("Unknown option: {$option}"),
            };
        }

        // Handle mutually exclusive options
        if ($config['interactive'] && $config['batch']) {
            // If both are specified, interactive takes precedence
            $config['batch'] = false;
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
     * Parse a float value
     *
     * @param mixed $value Value to parse
     * @param string $option Option name for error messages
     * @return float Parsed float
     * @throws \InvalidArgumentException If value is invalid
     */
    private function parseFloat(mixed $value, string $option): float
    {
        if (!is_numeric($value)) {
            throw new \InvalidArgumentException("Option --{$option} requires a numeric value");
        }

        $floatValue = (float) $value;

        if ($floatValue < 0.0 || $floatValue > 1.0) {
            throw new \InvalidArgumentException("Option --{$option} must be between 0.0 and 1.0");
        }

        return $floatValue;
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
        // Validate fix scope values
        $validScopes = ['internal', 'anchor', 'cross-reference', 'all'];
        foreach ($config['fix_scope'] as $scope) {
            if (!in_array($scope, $validScopes, true)) {
                throw new \InvalidArgumentException("Invalid fix scope: {$scope}. Valid scopes: " . implode(', ', $validScopes));
            }
        }

        // Validate similarity threshold
        if ($config['similarity_threshold'] < 0.0 || $config['similarity_threshold'] > 1.0) {
            throw new \InvalidArgumentException('Similarity threshold must be between 0.0 and 1.0');
        }

        // Validate max_depth
        if ($config['max_depth'] < 0) {
            throw new \InvalidArgumentException('Max depth must be non-negative');
        }

        // Validate conflicting options
        if ($config['include_hidden'] && $config['only_hidden']) {
            throw new \InvalidArgumentException('Cannot use both --include-hidden and --only-hidden');
        }

        // Validate rollback timestamp format if provided
        if ($config['rollback_timestamp'] !== null) {
            if (!preg_match('/^\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}$/', $config['rollback_timestamp'])) {
                throw new \InvalidArgumentException('Rollback timestamp must be in format: YYYY-MM-DD-HH-MM-SS');
            }

            // For rollback operations, we don't need input files
            return;
        }

        // Validate inputs (unless showing help or doing rollback)
        if (!$config['show_help'] && $config['rollback_timestamp'] === null) {
            if (empty($config['inputs']) && empty($config['fix_files'])) {
                throw new \InvalidArgumentException('No input files or directories specified');
            }
        }

        // Validate backup directory
        if (!empty($config['backup_dir'])) {
            $backupDir = dirname($config['backup_dir']);
            if (!is_dir($backupDir) && !mkdir($backupDir, 0755, true)) {
                throw new \InvalidArgumentException("Cannot create backup directory: {$backupDir}");
            }
        }

        // Validate fix files if specified
        if (!empty($config['fix_files'])) {
            foreach ($config['fix_files'] as $file) {
                if (!file_exists($file)) {
                    throw new \InvalidArgumentException("Fix file not found: {$file}");
                }
                if (!is_readable($file)) {
                    throw new \InvalidArgumentException("Fix file not readable: {$file}");
                }
            }
        }
    }

    /**
     * Get usage information
     *
     * @return string Usage string
     */
    public function getUsage(): string
    {
        return 'php link-rectifier.php [OPTIONS] <files_or_directories>...';
    }

    /**
     * Get detailed help information
     *
     * @return string Help text
     */
    public function getHelp(): string
    {
        return <<<'HELP'
PHP Link Rectifier - Automatic Link Fixing and Remediation Tool

USAGE:
    php link-rectifier.php [OPTIONS] <files_or_directories>...

DESCRIPTION:
    Automatically fixes broken links in markdown and HTML documentation files
    with comprehensive backup, rollback, and safety features. Supports fuzzy
    matching, case corrections, and missing file extension fixes.

OPTIONS:
    Input and Processing:
        --max-depth=N           Maximum directory traversal depth (default: unlimited)
        --include-hidden        Include hidden files and directories
        --only-hidden          Process only hidden files
        --exclude=PATTERNS     Comma-separated exclude patterns

    Fixing Scope:
        --fix-scope=TYPES      Comma-separated link types to fix:
                              internal,anchor,cross-reference,all (default: all)
        --fix-files=FILES      Comma-separated list of specific files to fix
        --similarity-threshold=N  Fuzzy matching threshold 0.0-1.0 (default: 0.8)

    Operation Modes:
        --dry-run              Preview changes without applying them
        --interactive          Prompt for confirmation before each fix
        --batch                Apply all fixes automatically (default)

    Backup and Safety:
        --backup-dir=DIR       Backup directory (default: .ai/backups/)
        --rollback=TIMESTAMP   Rollback to specific backup (format: YYYY-MM-DD-HH-MM-SS)

    Output and Reporting:
        --no-color            Disable colored output
        --quiet               Suppress all output except errors
        --verbose             Enable verbose output
        --debug               Enable debug output

    Configuration:
        --case-sensitive       Enable case-sensitive matching
        --help                Show this help message

EXAMPLES:
    # Preview fixes for all files in docs directory
    php link-rectifier.php docs/ --dry-run

    # Fix broken links interactively
    php link-rectifier.php docs/ --interactive

    # Fix only internal and anchor links in batch mode
    php link-rectifier.php docs/ --fix-scope=internal,anchor --batch

    # Fix specific files with custom similarity threshold
    php link-rectifier.php --fix-files="file1.md,file2.md" --similarity-threshold=0.9

    # Rollback to previous backup
    php link-rectifier.php --rollback=2024-01-15-14-30-00

BACKUP SYSTEM:
    - Automatic timestamped backups before any modifications
    - Backup location: .ai/backups/YYYY-MM-DD-HH-MM-SS/
    - Rollback capability to any previous backup
    - Atomic operations to prevent corruption

FIXING CAPABILITIES:
    - Case sensitivity corrections (File.md vs file.md)
    - Missing file extensions (.md vs .html)
    - Fuzzy matching for similar filenames
    - Anchor generation for missing heading targets
    - Relative path corrections
    - Cross-reference link updates

EXIT CODES:
    0    Success - all fixes applied successfully
    1    Fixing failures - some fixes could not be applied
    2    System errors - file access, backup, or runtime errors
    3    Configuration errors - invalid arguments or config

For more information and examples, visit:
https://github.com/your-org/php-link-rectifier

HELP;
    }
}
