<?php
/**
 * Main Application Class
 *
 * Orchestrates the complete link validation and remediation workflow.
 * Integrates LinkValidator and LinkRectifier with enhanced CLI interface.
 *
 * @package SAC\ValidateLinks\Core
 */

declare(strict_types=1);

namespace SAC\ValidateLinks\Core;

use SAC\ValidateLinks\Utils\Logger;
use SAC\ValidateLinks\Utils\SecurityValidator;

/**
 * Main application class for link validation and remediation
 *
 * Provides the primary entry point for the validate-links tool,
 * orchestrating validation and optional fixing workflows.
 */
final class Application
{
    private readonly Logger $logger;
    private readonly SecurityValidator $securityValidator;
    private readonly CLIArgumentParser $argumentParser;
    private readonly LinkValidator $linkValidator;
    private readonly ReportGenerator $reportGenerator;

    public function __construct()
    {
        $this->logger = new Logger();
        $this->securityValidator = new SecurityValidator();

        // Add common base paths for validation
        $this->securityValidator->addAllowedBasePath(getcwd());

        // Add project root paths
        $projectRoots = [
            dirname(__DIR__, 4), // From package to project root
            dirname(__DIR__, 3), // Alternative project root
            dirname(__DIR__, 2), // Package root
        ];

        foreach ($projectRoots as $root) {
            if (is_dir($root)) {
                try {
                    $this->securityValidator->addAllowedBasePath($root);
                } catch (\InvalidArgumentException $e) {
                    // Ignore invalid paths
                }
            }
        }

        $this->argumentParser = new CLIArgumentParser($this->logger);
        $this->linkValidator = new LinkValidator($this->logger, $this->securityValidator);
        $this->reportGenerator = new ReportGenerator($this->logger);
    }

    /**
     * Run the application with command line arguments
     *
     * @param array<string> $argv Command line arguments
     * @return int Exit code (0 = success, 1 = validation errors, 2 = configuration errors)
     */
    public function run(array $argv): int
    {
        try {
            // Parse configuration
            $config = $this->argumentParser->parse($argv);

            // Configure logger
            $this->configureLogger($config);

            // Show help if requested
            if ($config['show_help']) {
                $this->argumentParser->showHelp();
                return 0;
            }

            // Validate inputs
            $files = $this->validateAndCollectFiles($config);

            // Collect pre-validation statistics
            $preStats = $this->linkValidator->collectStatistics($files, $config['scope']);
            $this->logPreValidationInfo($config, $preStats);

            // Handle dry-run mode
            if ($config['dry_run']) {
                return $this->handleDryRun($config, $preStats, $files);
            }

            // Perform validation
            $this->logger->info('Starting link validation...');
            $validationResults = $this->linkValidator->validateFiles(
                $files,
                $config['scope'],
                $config['check_external'],
                $config['case_sensitive'],
                $config['timeout'],
                $config['max_broken'],
                $config['max_files']
            );

            // Handle fixing if requested
            if ($config['fix']) {
                $validationResults = $this->handleFixing($config, $validationResults);
            }

            // Generate reports
            $this->reportGenerator->generateReports(
                $validationResults,
                $config['format'],
                $config['output'],
                $config['no_color'],
                $config['max_broken']
            );

            // Determine exit code
            return $this->determineExitCode($validationResults);

        } catch (\InvalidArgumentException $e) {
            $this->logger->error('Configuration error: ' . $e->getMessage());
            return 2;
        } catch (\Throwable $e) {
            $this->logger->error('Unexpected error: ' . $e->getMessage());
            if ($this->logger->getVerbosity() >= Logger::DEBUG) {
                $this->logger->debug('Stack trace: ' . $e->getTraceAsString());
            }
            return 2;
        }
    }

    /**
     * Configure logger based on configuration
     */
    private function configureLogger(array $config): void
    {
        $this->logger->setVerbosity($config['verbosity']);

        if ($config['no_color']) {
            $this->logger->disableColors();
        }
    }

    /**
     * Validate inputs and collect files to process
     */
    private function validateAndCollectFiles(array $config): array
    {
        $files = [];

        foreach ($config['inputs'] as $input) {
            if (!$this->securityValidator->isFileReadable($input) && !$this->securityValidator->isDirectoryAccessible($input)) {
                $this->logger->warning("Skipping inaccessible path: {$input}");
                continue;
            }

            if (is_file($input)) {
                $files[] = $input;
            } elseif (is_dir($input)) {
                $dirFiles = $this->linkValidator->findFiles(
                    $input,
                    $config['max_depth'],
                    $config['include_hidden'],
                    $config['only_hidden'],
                    $config['exclude_patterns']
                );
                $files = array_merge($files, $dirFiles);
            }
        }

        if (empty($files)) {
            throw new \InvalidArgumentException('No valid files found to process');
        }

        return $files;
    }

    /**
     * Log pre-validation information
     */
    private function logPreValidationInfo(array $config, array $preStats): void
    {
        $this->logger->info(sprintf('Found %d files in %d directories',
            $preStats['total_files'],
            $preStats['total_directories']
        ));

        $this->logger->info(sprintf('Total links found: %d', $preStats['total_links']));
        $this->logger->info(sprintf('Links in scope (%s): %d',
            implode(', ', $config['scope']),
            $preStats['scoped_links']
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
    }

    /**
     * Handle dry-run mode
     */
    private function handleDryRun(array $config, array $preStats, array $files): int
    {
        if ($config['fix']) {
            $this->logger->info('🔍 DRY RUN MODE: Preview of validation and fixing scope (no changes will be made)');
            $this->showFixingPreview($preStats, $config, $files);
        } else {
            $this->logger->info('🔍 DRY RUN MODE: Preview of validation scope (no actual validation performed)');
            $this->showValidationPreview($preStats, $config, $files);
        }

        return 0;
    }

    /**
     * Show validation preview for dry-run mode
     */
    private function showValidationPreview(array $preStats, array $config, array $files): void
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

    /**
     * Show fixing preview for dry-run mode with --fix
     */
    private function showFixingPreview(array $preStats, array $config, array $files): void
    {
        $this->showValidationPreview($preStats, $config, $files);

        $this->logger->info('');
        $this->logger->info('🔧 Fixing Preview:');
        $this->logger->info('================');
        $this->logger->info('After validation completes, the following fixing actions would be performed:');
        $this->logger->info('');
        $this->logger->info('🔍 Link Analysis:');
        $this->logger->info('  • Identify broken internal links');
        $this->logger->info('  • Search for similar existing files');
        $this->logger->info('  • Calculate similarity scores');
        $this->logger->info('');
        $this->logger->info('🔧 Automatic Fixes:');
        $this->logger->info('  • Fix case mismatches in file paths');
        $this->logger->info('  • Correct file extensions (.md vs .html)');
        $this->logger->info('  • Update moved file references');
        $this->logger->info('  • Fix anchor link formatting');
        $this->logger->info('');
        $this->logger->info('📋 Interactive Fixes:');
        $this->logger->info('  • Suggest replacements for broken links');
        $this->logger->info('  • Prompt for user confirmation on ambiguous fixes');
        $this->logger->info('  • Create backup files before modifications');
        $this->logger->info('');
        $this->logger->info('💡 To perform actual validation and fixing, remove --dry-run flag');
    }

    /**
     * Handle fixing workflow
     */
    private function handleFixing(array $config, array $validationResults): array
    {
        $this->logger->info('🔧 Starting link fixing...');

        // TODO: Implement LinkRectifier integration
        // For now, just log that fixing would happen
        $brokenLinks = $validationResults['summary']['broken_links'] ?? 0;

        if ($brokenLinks > 0) {
            $this->logger->info(sprintf('Found %d broken links that could be fixed', $brokenLinks));
            $this->logger->warning('Link fixing functionality will be implemented in the next phase');
        } else {
            $this->logger->info('No broken links found - nothing to fix');
        }

        return $validationResults;
    }

    /**
     * Determine exit code based on validation results
     */
    private function determineExitCode(array $validationResults): int
    {
        $brokenLinks = $validationResults['summary']['broken_links'] ?? 0;

        if ($brokenLinks > 0) {
            $this->logger->info(sprintf('Validation completed with %d broken links', $brokenLinks));
            return 1; // Validation errors found
        }

        $this->logger->info('Validation completed successfully - no broken links found');
        return 0; // Success
    }
}
