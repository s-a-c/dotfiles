#!/usr/bin/env php
<?php
/**
 * PHP Link Rectifier - Automatic Link Fixing and Remediation Tool
 * 
 * A production-ready PHP tool for automatically fixing broken links in markdown
 * and HTML documentation with comprehensive backup, rollback, and safety features.
 * 
 * Features:
 * - Automatic link fixing with fuzzy matching
 * - Comprehensive backup and rollback system
 * - Dry-run mode with unified diff preview
 * - Interactive and batch processing modes
 * - Anchor generation for missing targets
 * - Case sensitivity corrections
 * - Missing file extension fixes
 * - Levenshtein distance-based suggestions
 * 
 * @author Augment Agent
 * @version 1.0.0
 * @license MIT
 * @requires PHP 8.4+
 */

declare(strict_types=1);

namespace LinkRectifier;

require_once __DIR__ . '/LinkValidator/Core/LinkValidator.php';
require_once __DIR__ . '/LinkValidator/Core/FileProcessor.php';
require_once __DIR__ . '/LinkValidator/Core/GitHubAnchorGenerator.php';
require_once __DIR__ . '/LinkValidator/Utils/Logger.php';
require_once __DIR__ . '/LinkValidator/Utils/SecurityValidator.php';
require_once __DIR__ . '/LinkRectifier/Core/LinkFixer.php';
require_once __DIR__ . '/LinkRectifier/Core/BackupManager.php';
require_once __DIR__ . '/LinkRectifier/Core/FuzzyMatcher.php';
require_once __DIR__ . '/LinkRectifier/Core/RectifierCLI.php';

use LinkValidator\Core\LinkValidator;
use LinkValidator\Core\FileProcessor;
use LinkValidator\Utils\Logger;
use LinkValidator\Utils\SecurityValidator;
use LinkRectifier\Core\LinkFixer;
use LinkRectifier\Core\BackupManager;
use LinkRectifier\Core\FuzzyMatcher;
use LinkRectifier\Core\RectifierCLI;

/**
 * Main application class for the link rectifier
 * 
 * Orchestrates the link fixing process including validation, backup creation,
 * automatic fixes, and rollback capabilities with comprehensive safety measures.
 */
final class LinkRectifierApp
{
    private readonly Logger $logger;
    private readonly SecurityValidator $securityValidator;
    private readonly RectifierCLI $cliParser;
    private readonly FileProcessor $fileProcessor;
    private readonly LinkValidator $linkValidator;
    private readonly LinkFixer $linkFixer;
    private readonly BackupManager $backupManager;
    private readonly FuzzyMatcher $fuzzyMatcher;
    
    /**
     * Initialize the application with dependency injection
     */
    public function __construct()
    {
        $this->logger = new Logger();
        $this->securityValidator = new SecurityValidator();
        $this->cliParser = new RectifierCLI($this->logger);
        $this->fileProcessor = new FileProcessor($this->logger, $this->securityValidator);
        $this->linkValidator = new LinkValidator($this->logger, $this->securityValidator);
        $this->backupManager = new BackupManager($this->logger, $this->securityValidator);
        $this->fuzzyMatcher = new FuzzyMatcher($this->logger);
        $this->linkFixer = new LinkFixer(
            $this->logger,
            $this->securityValidator,
            $this->fuzzyMatcher,
            $this->backupManager
        );
    }
    
    /**
     * Main application entry point
     * 
     * @param array<string> $argv Command line arguments
     * @return int Exit code (0 = success, 1 = fixes failed, 2 = system errors, 3 = config errors)
     */
    public function run(array $argv): int
    {
        try {
            // Parse command line arguments
            $config = $this->cliParser->parse($argv);
            
            // Set logger verbosity
            $this->logger->setVerbosity($config['verbosity']);
            
            // Disable colors if requested
            if ($config['no_color']) {
                $this->logger->disableColors();
            }
            
            // Show help if requested
            if ($config['show_help']) {
                $this->showHelp();
                return 0;
            }
            
            // Handle rollback operation
            if ($config['rollback_timestamp'] !== null) {
                return $this->handleRollback($config['rollback_timestamp']);
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
            
            $this->logger->info(sprintf('Found %d files to process', count($files)));
            
            // Validate links to identify issues
            $this->logger->info('Analyzing links for potential fixes...');
            $validationResults = $this->linkValidator->validateFiles(
                $files,
                $config['fix_scope'],
                false, // Don't check external links for fixing
                $config['case_sensitive'],
                30 // Default timeout
            );
            
            $brokenLinks = $this->extractBrokenLinks($validationResults['results']);
            
            if (empty($brokenLinks)) {
                $this->logger->info('No broken links found that can be automatically fixed');
                return 0;
            }
            
            $this->logger->info(sprintf('Found %d broken links that may be fixable', count($brokenLinks)));
            
            // Create backup if not in dry-run mode
            $backupId = null;
            if (!$config['dry_run']) {
                $backupId = $this->backupManager->createBackup(
                    $files,
                    $config['backup_dir']
                );
                $this->logger->info("Backup created: {$backupId}");
            }
            
            // Process fixes
            $fixResults = $this->linkFixer->processFixes(
                $brokenLinks,
                $files,
                $config
            );
            
            // Generate fix report
            $this->generateFixReport($fixResults, $config);
            
            // Determine exit code
            return $this->determineExitCode($fixResults, $config);
            
        } catch (ConfigurationException $e) {
            $this->logger->error('Configuration error: ' . $e->getMessage());
            return 3;
        } catch (SecurityException $e) {
            $this->logger->error('Security error: ' . $e->getMessage());
            return 2;
        } catch (FixingException $e) {
            $this->logger->error('Fixing error: ' . $e->getMessage());
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
     * Handle rollback operation
     * 
     * @param string $timestamp Backup timestamp to rollback to
     * @return int Exit code
     */
    private function handleRollback(string $timestamp): int
    {
        try {
            $this->logger->info("Rolling back to backup: {$timestamp}");
            
            $restoredFiles = $this->backupManager->rollback($timestamp);
            
            $this->logger->info(sprintf('Successfully restored %d files', count($restoredFiles)));
            
            foreach ($restoredFiles as $file) {
                $this->logger->debug("Restored: {$file}");
            }
            
            return 0;
            
        } catch (\Throwable $e) {
            $this->logger->error('Rollback failed: ' . $e->getMessage());
            return 2;
        }
    }
    
    /**
     * Extract broken links from validation results
     * 
     * @param array<string, mixed> $results Validation results
     * @return array<array<string, mixed>> Broken links with file context
     */
    private function extractBrokenLinks(array $results): array
    {
        $brokenLinks = [];
        
        foreach ($results as $filePath => $fileResult) {
            foreach ($fileResult['broken_links'] as $brokenLink) {
                $brokenLinks[] = array_merge($brokenLink, [
                    'source_file' => $filePath,
                ]);
            }
        }
        
        return $brokenLinks;
    }
    
    /**
     * Generate fix report
     * 
     * @param array<string, mixed> $fixResults Fix results
     * @param array<string, mixed> $config Configuration
     */
    private function generateFixReport(array $fixResults, array $config): void
    {
        $totalAttempted = $fixResults['attempted'];
        $totalFixed = $fixResults['fixed'];
        $totalFailed = $fixResults['failed'];
        
        $this->logger->info('Fix Summary:');
        $this->logger->info("  Attempted: {$totalAttempted}");
        $this->logger->info("  Fixed: {$totalFixed}");
        $this->logger->info("  Failed: {$totalFailed}");
        
        if ($config['dry_run']) {
            $this->logger->info('This was a dry run - no files were actually modified');
        }
        
        // Show detailed results if verbose
        if ($this->logger->getVerbosity() >= Logger::VERBOSE) {
            foreach ($fixResults['details'] as $detail) {
                $status = $detail['success'] ? '✓' : '✗';
                $this->logger->info("  {$status} {$detail['file']}: {$detail['description']}");
            }
        }
    }
    
    /**
     * Determine the appropriate exit code based on fix results
     * 
     * @param array<string, mixed> $fixResults Fix results
     * @param array<string, mixed> $config Configuration
     * @return int Exit code
     */
    private function determineExitCode(array $fixResults, array $config): int
    {
        if ($fixResults['failed'] > 0) {
            return 1; // Some fixes failed
        }
        
        return 0; // Success
    }
    
    /**
     * Display comprehensive help information
     */
    private function showHelp(): void
    {
        echo <<<'HELP'
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

SAFETY FEATURES:
    - Comprehensive input validation and sanitization
    - Path traversal protection
    - Atomic file operations
    - Backup verification
    - Rollback testing
    - Dry-run mode for safe preview

For more information and examples, visit:
https://github.com/your-org/php-link-rectifier

HELP;
    }
}

// Custom exception classes
class ConfigurationException extends \Exception {}
class SecurityException extends \Exception {}
class FixingException extends \Exception {}

// Application entry point
if (basename(__FILE__) === basename($_SERVER['SCRIPT_NAME'])) {
    $app = new LinkRectifierApp();
    $exitCode = $app->run($argv);
    exit($exitCode);
}
