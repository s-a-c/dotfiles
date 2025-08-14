<?php
/**
 * Core Link Validator Class
 *
 * Handles the actual validation of links in documentation files with support for
 * internal links, anchor links, cross-references, and external links using the
 * proven GitHub anchor generation algorithm.
 *
 * @package SAC\ValidateLinks\Core
 */

declare(strict_types=1);

namespace SAC\ValidateLinks\Core;

use SAC\ValidateLinks\Utils\Logger;
use SAC\ValidateLinks\Utils\SecurityValidator;

/**
 * Main link validation engine
 *
 * Processes files and validates all types of links with comprehensive error handling
 * and detailed reporting of validation results.
 */
final class LinkValidator
{
    private readonly Logger $logger;
    private readonly SecurityValidator $securityValidator;
    private readonly GitHubAnchorGenerator $anchorGenerator;

    /**
     * Link validation statistics
     */
    private array $stats = [
        'total_files' => 0,
        'total_links' => 0,
        'internal_links' => 0,
        'anchor_links' => 0,
        'cross_reference_links' => 0,
        'external_links' => 0,
        'broken_internal' => 0,
        'broken_anchors' => 0,
        'broken_cross_references' => 0,
        'broken_external' => 0,
    ];

    public function __construct(Logger $logger, SecurityValidator $securityValidator)
    {
        $this->logger = $logger;
        $this->securityValidator = $securityValidator;
        $this->anchorGenerator = new GitHubAnchorGenerator();
    }

    /**
     * Find files in directory with filtering options
     *
     * @param string $directory Directory to search
     * @param int $maxDepth Maximum depth to search (0 = unlimited)
     * @param bool $includeHidden Include hidden files
     * @param bool $onlyHidden Only include hidden files
     * @param array<string> $excludePatterns Patterns to exclude
     * @return array<string> Array of file paths
     */
    public function findFiles(
        string $directory,
        int $maxDepth = 0,
        bool $includeHidden = false,
        bool $onlyHidden = false,
        array $excludePatterns = []
    ): array {
        if (!$this->securityValidator->isDirectoryAccessible($directory)) {
            $this->logger->warning("Directory not accessible: {$directory}");
            return [];
        }

        $files = [];
        $iterator = new \RecursiveIteratorIterator(
            new \RecursiveDirectoryIterator($directory, \RecursiveDirectoryIterator::SKIP_DOTS),
            \RecursiveIteratorIterator::SELF_FIRST
        );

        if ($maxDepth > 0) {
            $iterator->setMaxDepth($maxDepth - 1);
        }

        foreach ($iterator as $file) {
            if (!$file->isFile()) {
                continue;
            }

            $filePath = $file->getPathname();
            $fileName = $file->getFilename();

            // Handle hidden file filtering
            $isHidden = str_starts_with($fileName, '.');
            if ($onlyHidden && !$isHidden) {
                continue;
            }
            if (!$includeHidden && !$onlyHidden && $isHidden) {
                continue;
            }

            // Check exclude patterns
            if ($this->matchesExcludePatterns($filePath, $excludePatterns)) {
                continue;
            }

            // Only include text-based files
            if ($this->isTextFile($filePath)) {
                $files[] = $filePath;
            }
        }

        return $files;
    }

    /**
     * Check if file matches exclude patterns
     */
    private function matchesExcludePatterns(string $filePath, array $patterns): bool
    {
        foreach ($patterns as $pattern) {
            if (fnmatch($pattern, $filePath) || fnmatch($pattern, basename($filePath))) {
                return true;
            }
        }
        return false;
    }

    /**
     * Check if file is a text file that should be processed
     */
    private function isTextFile(string $filePath): bool
    {
        $allowedExtensions = [
            'md', 'markdown', 'txt', 'html', 'htm', 'rst', 'adoc', 'asciidoc'
        ];

        $extension = strtolower(pathinfo($filePath, PATHINFO_EXTENSION));
        return in_array($extension, $allowedExtensions, true);
    }

    /**
     * Collect comprehensive statistics before validation
     *
     * @param array<string> $files Array of file paths to validate
     * @param array<string> $scope Link types to validate
     * @return array<string, mixed> Pre-validation statistics
     */
    public function collectStatistics(array $files, array $scope): array
    {
        $stats = [
            'total_directories' => 0,
            'total_files' => count($files),
            'total_links' => 0,
            'links_by_type' => [
                'internal' => 0,
                'anchor' => 0,
                'cross_reference' => 0,
                'external' => 0,
            ],
            'scoped_links' => 0,
            'directories' => [],
            'file_sizes' => [],
        ];

        $directories = [];

        foreach ($files as $filePath) {
            // Track directories
            $dir = dirname($filePath);
            if (!in_array($dir, $directories)) {
                $directories[] = $dir;
            }

            // Track file size
            $stats['file_sizes'][] = file_exists($filePath) ? filesize($filePath) : 0;

            // Count links in file
            try {
                $content = file_get_contents($filePath);
                if ($content !== false) {
                    $links = $this->extractLinks($content);
                    $stats['total_links'] += count($links);

                    foreach ($links as $link) {
                        $linkType = $this->categorizeLink($link['url']);
                        $stats['links_by_type'][$linkType]++;

                        // Count scoped links
                        if (in_array($linkType, $scope) || in_array('all', $scope)) {
                            $stats['scoped_links']++;
                        }
                    }
                }
            } catch (\Throwable $e) {
                $this->logger->warning("Could not read file for statistics: {$filePath}");
            }
        }

        $stats['total_directories'] = count($directories);
        $stats['directories'] = $directories;
        $stats['average_file_size'] = count($stats['file_sizes']) > 0
            ? (int) (array_sum($stats['file_sizes']) / count($stats['file_sizes']))
            : 0;

        return $stats;
    }

    /**
     * Validate links in multiple files
     *
     * @param array<string> $files List of file paths to validate
     * @param array<string> $scope Link types to validate
     * @param bool $checkExternal Whether to validate external links
     * @param bool $caseSensitive Whether to use case-sensitive validation
     * @param int $timeout Timeout for external link validation
     * @param int $maxBroken Maximum broken links before stopping (0 = unlimited)
     * @param int $maxFiles Maximum files to process before stopping (0 = unlimited)
     * @return array<string, mixed> Validation results
     */
    public function validateFiles(
        array $files,
        array $scope,
        bool $checkExternal,
        bool $caseSensitive,
        int $timeout,
        int $maxBroken = 0,
        int $maxFiles = 0
    ): array {
        $this->logger->info('Starting link validation process');
        $startTime = microtime(true);

        // Reset statistics
        $this->stats = array_fill_keys(array_keys($this->stats), 0);
        $this->stats['total_files'] = count($files);

        $results = [];
        $allFiles = $this->buildFileIndex($files);
        $totalBrokenLinks = 0;
        $filesProcessed = 0;
        $totalFiles = count($files);

        foreach ($files as $filePath) {
            // Check if we've exceeded the max files threshold
            if ($maxFiles > 0 && $filesProcessed >= $maxFiles) {
                $this->logger->info("Stopping validation: reached max files threshold ({$maxFiles})");
                break;
            }

            // Check if we've exceeded the max broken links threshold
            if ($maxBroken > 0 && $totalBrokenLinks >= $maxBroken) {
                $this->logger->info("Stopping validation: reached max broken links threshold ({$maxBroken})");
                break;
            }

            $filesProcessed++;
            $this->logger->debug("Validating file: {$filePath}");

            // In verbose mode, show progress
            if ($this->logger->getVerbosity() >= Logger::VERBOSE) {
                $totalLinksProcessed = array_sum(array_map(fn($r) => $r['total_links'] ?? 0, $results));
                $this->logger->info("Processing file {$filesProcessed} of {$totalFiles} ({$totalLinksProcessed} links processed so far)");
            }

            $fileResult = $this->validateFile(
                $filePath,
                $allFiles,
                $scope,
                $checkExternal,
                $caseSensitive,
                $timeout
            );

            $results[$filePath] = $fileResult;

            // Update broken links count for early termination
            if (isset($fileResult['broken_links'])) {
                $totalBrokenLinks += count($fileResult['broken_links']);
            }
        }

        $executionTime = microtime(true) - $startTime;

        return [
            'summary' => $this->generateSummary($executionTime, $filesProcessed, $totalFiles),
            'results' => $results,
            'timestamp' => date('c'),
            'execution_time' => $executionTime,
        ];
    }

    /**
     * Validate links in a single file
     *
     * @param string $filePath Path to the file to validate
     * @param array<string> $allFiles Index of all available files
     * @param array<string> $scope Link types to validate
     * @param bool $checkExternal Whether to validate external links
     * @param bool $caseSensitive Whether to use case-sensitive validation
     * @param int $timeout Timeout for external link validation
     * @return array<string, mixed> File validation results
     */
    private function validateFile(
        string $filePath,
        array $allFiles,
        array $scope,
        bool $checkExternal,
        bool $caseSensitive,
        int $timeout
    ): array {
        $results = [
            'file' => $filePath,
            'total_links' => 0,
            'internal_links' => 0,
            'anchor_links' => 0,
            'cross_reference_links' => 0,
            'external_links' => 0,
            'broken_links' => [],
            'working_links' => [],
        ];

        try {
            $content = file_get_contents($filePath);
            if ($content === false) {
                throw new \RuntimeException("Cannot read file: {$filePath}");
            }

            $links = $this->extractLinks($content);
            $scopedLinksCount = 0;

            foreach ($links as $link) {
                $linkType = $this->categorizeLink($link['url']);

                // Skip validation if not in scope
                if (!in_array($linkType, $scope) && !in_array('all', $scope)) {
                    continue;
                }

                $scopedLinksCount++;
                $results["{$linkType}_links"]++;
                $this->stats["{$linkType}_links"]++;

                $isValid = $this->validateLink(
                    $filePath,
                    $link,
                    $linkType,
                    $allFiles,
                    $checkExternal,
                    $caseSensitive,
                    $timeout
                );

                if ($isValid['valid']) {
                    $results['working_links'][] = array_merge($link, [
                        'type' => $linkType,
                        'status' => $isValid['message'],
                    ]);
                } else {
                    $results['broken_links'][] = array_merge($link, [
                        'type' => $linkType,
                        'status' => $isValid['message'],
                    ]);

                    // Map link types to stats keys
                    $statsKey = match ($linkType) {
                        'cross_reference' => 'broken_cross_references',
                        'anchor' => 'broken_anchors',
                        default => "broken_{$linkType}",
                    };

                    if (isset($this->stats[$statsKey])) {
                        $this->stats[$statsKey]++;
                    }
                }
            }

            // Set total links count based on scoped links only
            $results['total_links'] = $scopedLinksCount;
            $this->stats['total_links'] += $scopedLinksCount;

        } catch (\Throwable $e) {
            $this->logger->error("Error validating file {$filePath}: " . $e->getMessage());
            $results['error'] = $e->getMessage();
        }

        return $results;
    }

    /**
     * Extract links from file content
     *
     * @param string $content File content
     * @return array<array<string, mixed>> Array of link information
     */
    private function extractLinks(string $content): array
    {
        $links = [];

        // Markdown links: [text](url)
        if (preg_match_all('/\[([^\]]*)\]\(([^)]+)\)/', $content, $matches, PREG_SET_ORDER | PREG_OFFSET_CAPTURE)) {
            foreach ($matches as $match) {
                $links[] = [
                    'text' => $match[1][0],
                    'url' => $match[2][0],
                    'line' => substr_count($content, "\n", 0, $match[0][1]) + 1,
                    'column' => $match[0][1] - strrpos(substr($content, 0, $match[0][1]), "\n"),
                    'format' => 'markdown',
                ];
            }
        }

        // HTML links: <a href="url">text</a>
        if (preg_match_all('/<a\s+[^>]*href=["\']([^"\']+)["\'][^>]*>([^<]*)<\/a>/i', $content, $matches, PREG_SET_ORDER | PREG_OFFSET_CAPTURE)) {
            foreach ($matches as $match) {
                $links[] = [
                    'text' => $match[2][0],
                    'url' => $match[1][0],
                    'line' => substr_count($content, "\n", 0, $match[0][1]) + 1,
                    'column' => $match[0][1] - strrpos(substr($content, 0, $match[0][1]), "\n"),
                    'format' => 'html',
                ];
            }
        }

        return $links;
    }

    /**
     * Categorize a link by type
     *
     * @param string $url URL to categorize
     * @return string Link type (internal, anchor, cross_reference, external)
     */
    private function categorizeLink(string $url): string
    {
        // Anchor links start with #
        if (str_starts_with($url, '#')) {
            return 'anchor';
        }

        // External links have protocols
        if (preg_match('/^[a-z][a-z0-9+.-]*:/i', $url)) {
            return 'external';
        }

        // Cross-reference links contain path separators
        if (str_contains($url, '/') || str_starts_with($url, '../') || str_starts_with($url, './')) {
            return 'cross_reference';
        }

        // Everything else is internal
        return 'internal';
    }

    /**
     * Build file index for quick lookups
     *
     * @param array<string> $files Array of file paths
     * @return array<string> Normalized file index
     */
    private function buildFileIndex(array $files): array
    {
        $index = [];
        foreach ($files as $file) {
            $normalized = $this->normalizePath($file);
            $index[$normalized] = $file;

            // Also index by basename for internal links
            $basename = basename($file);
            if (!isset($index[$basename])) {
                $index[$basename] = $file;
            }
        }
        return $index;
    }

    /**
     * Normalize file path for comparison
     *
     * @param string $path File path to normalize
     * @return string Normalized path
     */
    private function normalizePath(string $path): string
    {
        return str_replace('\\', '/', realpath($path) ?: $path);
    }

    /**
     * Validate a single link
     *
     * @param string $filePath Path of the file containing the link
     * @param array<string, mixed> $link Link information
     * @param string $linkType Type of link
     * @param array<string> $allFiles Index of all files
     * @param bool $checkExternal Whether to check external links
     * @param bool $caseSensitive Whether to use case-sensitive validation
     * @param int $timeout Timeout for external validation
     * @return array<string, mixed> Validation result
     */
    private function validateLink(
        string $filePath,
        array $link,
        string $linkType,
        array $allFiles,
        bool $checkExternal,
        bool $caseSensitive,
        int $timeout
    ): array {
        return match ($linkType) {
            'internal' => $this->validateInternalLink($filePath, $link, $allFiles, $caseSensitive),
            'anchor' => $this->validateAnchorLink($filePath, $link),
            'cross_reference' => $this->validateCrossReferenceLink($filePath, $link, $allFiles, $caseSensitive),
            'external' => $checkExternal
                ? $this->validateExternalLink($link, $timeout)
                : ['valid' => true, 'message' => 'External link validation skipped'],
            default => ['valid' => false, 'message' => 'Unknown link type'],
        };
    }

    /**
     * Validate internal link (same directory)
     */
    private function validateInternalLink(string $filePath, array $link, array $allFiles, bool $caseSensitive): array
    {
        $url = $link['url'];
        $baseDir = dirname($filePath);
        $targetPath = $baseDir . '/' . $url;

        // Check if file exists
        if (isset($allFiles[basename($url)])) {
            return ['valid' => true, 'message' => 'Internal link valid'];
        }

        // Try case-insensitive match if not case-sensitive
        if (!$caseSensitive) {
            foreach ($allFiles as $file) {
                if (strcasecmp(basename($file), basename($url)) === 0) {
                    return ['valid' => true, 'message' => 'Internal link valid (case mismatch)'];
                }
            }
        }

        return ['valid' => false, 'message' => 'Internal link target not found'];
    }

    /**
     * Validate anchor link
     */
    private function validateAnchorLink(string $filePath, array $link): array
    {
        $anchor = ltrim($link['url'], '#');

        if (empty($anchor)) {
            return ['valid' => true, 'message' => 'Empty anchor (top of page)'];
        }

        try {
            $content = file_get_contents($filePath);
            if ($content === false) {
                return ['valid' => false, 'message' => 'Cannot read file for anchor validation'];
            }

            $headings = $this->extractHeadings($content);
            $generatedAnchors = array_map([$this->anchorGenerator, 'generate'], $headings);

            if (in_array($anchor, $generatedAnchors, true)) {
                return ['valid' => true, 'message' => 'Anchor link valid'];
            }

            return ['valid' => false, 'message' => 'Anchor not found in file'];

        } catch (\Throwable $e) {
            return ['valid' => false, 'message' => 'Error validating anchor: ' . $e->getMessage()];
        }
    }

    /**
     * Validate cross-reference link
     */
    private function validateCrossReferenceLink(string $filePath, array $link, array $allFiles, bool $caseSensitive): array
    {
        $url = $link['url'];
        $baseDir = dirname($filePath);

        // Split URL and anchor
        $parts = explode('#', $url, 2);
        $targetPath = $parts[0];
        $anchor = $parts[1] ?? null;

        // Resolve relative path
        $fullPath = $this->resolvePath($baseDir, $targetPath);

        // Check if target file exists
        $targetExists = false;
        foreach ($allFiles as $file) {
            if ($this->pathsMatch($file, $fullPath, $caseSensitive)) {
                $targetExists = true;
                $fullPath = $file; // Use the actual file path
                break;
            }
        }

        if (!$targetExists) {
            return ['valid' => false, 'message' => 'Cross-reference target file not found'];
        }

        // If there's an anchor, validate it
        if ($anchor !== null) {
            try {
                $content = file_get_contents($fullPath);
                if ($content === false) {
                    return ['valid' => false, 'message' => 'Cannot read target file for anchor validation'];
                }

                $headings = $this->extractHeadings($content);
                $generatedAnchors = array_map([$this->anchorGenerator, 'generate'], $headings);

                if (!in_array($anchor, $generatedAnchors, true)) {
                    return ['valid' => false, 'message' => 'Anchor not found in target file'];
                }
            } catch (\Throwable $e) {
                return ['valid' => false, 'message' => 'Error validating anchor in target file: ' . $e->getMessage()];
            }
        }

        return ['valid' => true, 'message' => 'Cross-reference link valid'];
    }

    /**
     * Validate external link
     */
    private function validateExternalLink(array $link, int $timeout): array
    {
        $url = $link['url'];

        // Basic URL validation
        if (!filter_var($url, FILTER_VALIDATE_URL)) {
            return ['valid' => false, 'message' => 'Invalid URL format'];
        }

        try {
            $context = stream_context_create([
                'http' => [
                    'timeout' => $timeout,
                    'method' => 'HEAD',
                    'user_agent' => 'Link Validator/1.0',
                    'follow_location' => true,
                    'max_redirects' => 5,
                ],
            ]);

            $headers = @get_headers($url, 1, $context);

            if ($headers === false) {
                return ['valid' => false, 'message' => 'Failed to connect to external URL'];
            }

            $statusLine = $headers[0];
            $statusCode = (int) preg_replace('/HTTP\/\d\.\d\s+(\d+).*/', '$1', $statusLine);

            if ($statusCode >= 200 && $statusCode < 400) {
                return ['valid' => true, 'message' => "External link valid (HTTP {$statusCode})"];
            }

            return ['valid' => false, 'message' => "External link failed (HTTP {$statusCode})"];

        } catch (\Throwable $e) {
            return ['valid' => false, 'message' => 'External link validation error: ' . $e->getMessage()];
        }
    }

    /**
     * Extract headings from content
     */
    private function extractHeadings(string $content): array
    {
        $headings = [];

        // Markdown headings
        if (preg_match_all('/^(#{1,6})\s+(.+)$/m', $content, $matches)) {
            foreach ($matches[2] as $heading) {
                $headings[] = trim($heading);
            }
        }

        // HTML headings
        if (preg_match_all('/<h[1-6][^>]*>([^<]+)<\/h[1-6]>/i', $content, $matches)) {
            foreach ($matches[1] as $heading) {
                $headings[] = trim(strip_tags($heading));
            }
        }

        return $headings;
    }

    /**
     * Resolve relative path
     */
    private function resolvePath(string $basePath, string $relativePath): string
    {
        $path = $basePath . '/' . $relativePath;
        $parts = explode('/', $path);
        $resolved = [];

        foreach ($parts as $part) {
            if ($part === '..') {
                array_pop($resolved);
            } elseif ($part !== '.' && $part !== '') {
                $resolved[] = $part;
            }
        }

        return implode('/', $resolved);
    }

    /**
     * Check if two paths match
     */
    private function pathsMatch(string $path1, string $path2, bool $caseSensitive): bool
    {
        $normalized1 = $this->normalizePath($path1);
        $normalized2 = $this->normalizePath($path2);

        return $caseSensitive
            ? $normalized1 === $normalized2
            : strcasecmp($normalized1, $normalized2) === 0;
    }

    /**
     * Generate validation summary statistics
     *
     * @param float $executionTime Total execution time
     * @param int $filesProcessed Number of files actually processed
     * @param int $totalFiles Total number of files available for processing
     * @return array<string, mixed> Summary statistics
     */
    private function generateSummary(float $executionTime, int $filesProcessed, int $totalFiles): array
    {
        $totalBroken = $this->stats['broken_internal'] +
                      $this->stats['broken_anchors'] +
                      $this->stats['broken_cross_references'] +
                      $this->stats['broken_external'];

        $successRate = $this->stats['total_links'] > 0
            ? (($this->stats['total_links'] - $totalBroken) / $this->stats['total_links']) * 100
            : 100.0;

        return array_merge($this->stats, [
            'broken_links' => $totalBroken,
            'success_rate' => round($successRate, 2),
            'execution_time' => round($executionTime, 3),
            'files_processed' => $filesProcessed,
            'total_files_available' => $totalFiles,
        ]);
    }
}
