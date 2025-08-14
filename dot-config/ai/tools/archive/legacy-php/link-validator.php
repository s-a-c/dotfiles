#!/usr/bin/env php
<?php
/**
 * PHP Link Validator - Comprehensive Documentation Link Validation Tool
 *
 * A production-ready PHP tool for validating links in markdown and HTML documentation
 * with comprehensive reporting, multiple output formats, and CI/CD integration.
 *
 * Features:
 * - Internal, anchor, cross-reference, and external link validation
 * - Multiple output formats (JSON, Markdown, HTML)
 * - Configurable validation scopes and thresholds
 * - GitHub-compatible anchor generation algorithm
 * - Comprehensive error handling and security measures
 * - PSR-12 compliant code with modern PHP 8.4+ features
 *
 * @author Augment Agent
 * @version 1.0.0
 * @license MIT
 * @requires PHP 8.4+
 */

declare(strict_types=1);

namespace LinkValidator;

require_once __DIR__ . '/LinkValidator/Core/LinkValidator.php';
require_once __DIR__ . '/LinkValidator/Core/FileProcessor.php';
require_once __DIR__ . '/LinkValidator/Core/ReportGenerator.php';
require_once __DIR__ . '/LinkValidator/Core/ConfigurationManager.php';
require_once __DIR__ . '/LinkValidator/Core/CLIArgumentParser.php';
require_once __DIR__ . '/LinkValidator/Utils/Logger.php';
require_once __DIR__ . '/LinkValidator/Utils/SecurityValidator.php';

use LinkValidator\Core\LinkValidator;
use LinkValidator\Core\FileProcessor;
use LinkValidator\Core\ReportGenerator;
use LinkValidator\Core\ConfigurationManager;
use LinkValidator\Core\CLIArgumentParser;
use LinkValidator\Utils\Logger;
use LinkValidator\Utils\SecurityValidator;

/**
 * Main application class for the link validator
 *
 * Orchestrates the validation process including argument parsing, file processing,
 * link validation, and report generation with comprehensive error handling.
 */
final class LinkValidatorApp
{
    private readonly Logger $logger;
    private readonly SecurityValidator $securityValidator;
    private readonly ConfigurationManager $configManager;
    private readonly CLIArgumentParser $cliParser;
    private readonly FileProcessor $fileProcessor;
    private readonly LinkValidator $linkValidator;
    private readonly ReportGenerator $reportGenerator;

    /**
     * Initialize the application with dependency injection
     */
    public function __construct()
    {
        $this->logger = new Logger();
        $this->securityValidator = new SecurityValidator();
        $this->configManager = new ConfigurationManager($this->logger);
        $this->cliParser = new CLIArgumentParser($this->logger);
        $this->fileProcessor = new FileProcessor($this->logger, $this->securityValidator);
        $this->linkValidator = new LinkValidator($this->logger, $this->securityValidator);
        $this->reportGenerator = new ReportGenerator($this->logger);
    }

    /**
     * Main application entry point
     *
     * @param array<string> $argv Command line arguments
     * @return int Exit code (0 = success, 1 = validation failures, 2 = system errors, 3 = config errors)
     */
    public function run(array $argv): int
    {
        try {
            // Parse command line arguments
            $config = $this->cliParser->parse($argv);

            // Load configuration file if specified
            if ($config['config_file'] !== null) {
                $fileConfig = $this->configManager->loadConfigFile($config['config_file']);
                $config = array_merge($fileConfig, $config);
            }

            // Validate configuration
            $this->validateConfiguration($config);

            // Set logger verbosity
            $this->logger->setVerbosity($config['verbosity']);

            // Show help if requested
            if ($config['show_help']) {
                $this->showHelp();
                return 0;
            }

            // Process input files and directories
            $files = $this->fileProcessor->processInputs(
                $config['inputs'],
                $config['max_depth'],
                $config['include_hidden'],
                $config['only_hidden'],
                $config['exclude_patterns']
            );

            if (empty($files)) {
                $this->logger->error('No valid files found to process');
                return 2;
            }

            // Collect and report pre-validation statistics
            $this->logger->info(sprintf('Found %d files to validate', count($files)));
            $preStats = $this->linkValidator->collectStatistics($files, $config['scope']);

            $this->logger->info(sprintf(
                'Validation scope: %d directories, %d files, %d total links (%d in scope: %s)',
                $preStats['total_directories'],
                $preStats['total_files'],
                $preStats['total_links'],
                $preStats['scoped_links'],
                implode(', ', $config['scope'])
            ));

            // Show termination conditions
            $terminationConditions = [];
            if ($config['max_files'] > 0) {
                $terminationConditions[] = sprintf('%d files', $config['max_files']);
            }
            if ($config['max_broken'] > 0) {
                $terminationConditions[] = sprintf('%d broken links', $config['max_broken']);
            }

            if (!empty($terminationConditions)) {
                $this->logger->info(sprintf('Will stop after: %s', implode(' OR ', $terminationConditions)));
            }

            // Handle dry-run mode
            if ($config['dry_run']) {
                $this->logger->info('DRY RUN MODE: Preview of validation scope (no actual validation performed)');
                $this->showDryRunPreview($preStats, $config, $files);
                return 0;
            }

            // Validate links in all files
            $results = $this->linkValidator->validateFiles(
                $files,
                $config['scope'],
                $config['check_external'],
                $config['case_sensitive'],
                $config['timeout'],
                $config['max_broken'],
                $config['max_files']
            );

            // Generate reports
            $this->reportGenerator->generateReports(
                $results,
                $config['format'],
                $config['output'],
                $config['no_color'],
                $config['max_broken']
            );

            // Determine exit code based on validation results
            return $this->determineExitCode($results, $config);

        } catch (ConfigurationException $e) {
            $this->logger->error('Configuration error: ' . $e->getMessage());
            return 3;
        } catch (SecurityException $e) {
            $this->logger->error('Security error: ' . $e->getMessage());
            return 2;
        } catch (ValidationException $e) {
            $this->logger->error('Validation error: ' . $e->getMessage());
            return 1;
        } catch (\Throwable $e) {
            $this->logger->error('Unexpected error: ' . $e->getMessage());
            if ($config['debug'] ?? false) {
                $this->logger->debug($e->getTraceAsString());
            }
            return 2;
        }
    }

    /**
     * Validate the configuration parameters
     *
     * @param array<string, mixed> $config Configuration array
     * @throws ConfigurationException If configuration is invalid
     */
    private function validateConfiguration(array $config): void
    {
        // Validate required parameters
        if (empty($config['inputs'])) {
            throw new ConfigurationException('No input files or directories specified');
        }

        // Validate scope values
        $validScopes = ['internal', 'anchor', 'cross-reference', 'external', 'all'];
        foreach ($config['scope'] as $scope) {
            if (!in_array($scope, $validScopes, true)) {
                throw new ConfigurationException("Invalid scope: {$scope}");
            }
        }

        // Validate format
        $validFormats = ['json', 'markdown', 'html', 'console'];
        if (!in_array($config['format'], $validFormats, true)) {
            throw new ConfigurationException("Invalid format: {$config['format']}");
        }

        // Validate numeric parameters
        if ($config['max_depth'] < 0) {
            throw new ConfigurationException('max_depth must be non-negative');
        }

        if ($config['timeout'] <= 0) {
            throw new ConfigurationException('timeout must be positive');
        }

        if ($config['max_broken'] < 0) {
            throw new ConfigurationException('max_broken must be non-negative');
        }
    }

    /**
     * Determine the appropriate exit code based on validation results
     *
     * @param array<string, mixed> $results Validation results
     * @param array<string, mixed> $config Configuration
     * @return int Exit code
     */
    private function determineExitCode(array $results, array $config): int
    {
        $totalBroken = $results['summary']['broken_links'] ?? 0;

        if ($totalBroken > $config['max_broken']) {
            return 1; // Validation failures
        }

        return 0; // Success
    }

    /**
     * Display comprehensive help information
     */
    private function showHelp(): void
    {
        echo <<<'HELP'
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

    /**
     * Show dry-run preview of what would be validated
     *
     * @param array<string, mixed> $preStats Pre-validation statistics
     * @param array<string, mixed> $config Configuration
     * @param array<string> $files List of files to validate
     */
    private function showDryRunPreview(array $preStats, array $config, array $files): void
    {
        $this->logger->info('📋 Validation Preview:');
        $this->logger->info('==================');

        // Show scope information
        $this->logger->info(sprintf('📁 Directories: %d', $preStats['total_directories']));
        $this->logger->info(sprintf('📄 Files: %d', $preStats['total_files']));
        $this->logger->info(sprintf('🔗 Total Links: %d', $preStats['total_links']));
        $this->logger->info(sprintf('🎯 Scoped Links: %d (%s)', $preStats['scoped_links'], implode(', ', $config['scope'])));

        // Show termination conditions
        $terminationConditions = [];
        if ($config['max_files'] > 0) {
            $terminationConditions[] = sprintf('%d files', $config['max_files']);
        }
        if ($config['max_broken'] > 0) {
            $terminationConditions[] = sprintf('%d broken links', $config['max_broken']);
        }

        if (!empty($terminationConditions)) {
            $this->logger->info(sprintf('⏹️  Would stop after: %s', implode(' OR ', $terminationConditions)));
        }

        // Show link type breakdown
        $this->logger->info('');
        $this->logger->info('🔍 Link Type Breakdown:');
        foreach ($preStats['links_by_type'] as $type => $count) {
            $inScope = in_array($type, $config['scope']) || in_array('all', $config['scope']);
            $status = $inScope ? '✅' : '⏭️ ';
            $this->logger->info(sprintf('  %s %s: %d links', $status, ucfirst($type), $count));
        }

        // Show sample files (first 5)
        $this->logger->info('');
        $this->logger->info('📝 Sample Files to Process:');
        $sampleFiles = array_slice($files, 0, min(5, count($files)));
        foreach ($sampleFiles as $i => $file) {
            $this->logger->info(sprintf('  %d. %s', $i + 1, $file));
        }

        if (count($files) > 5) {
            $this->logger->info(sprintf('  ... and %d more files', count($files) - 5));
        }

        $this->logger->info('');
        $this->logger->info('💡 To perform actual validation, remove --dry-run flag');
    }
}

// Custom exception classes
class ConfigurationException extends \Exception {}
class SecurityException extends \Exception {}
class ValidationException extends \Exception {}

// Application entry point
if (basename(__FILE__) === basename($_SERVER['SCRIPT_NAME'])) {
    $app = new LinkValidatorApp();
    $exitCode = $app->run($argv);
    exit($exitCode);
}
