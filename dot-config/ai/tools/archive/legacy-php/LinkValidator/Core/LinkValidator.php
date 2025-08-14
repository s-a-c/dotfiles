<?php
/**
 * Core Link Validator Class
 *
 * Handles the actual validation of links in documentation files with support for
 * internal links, anchor links, cross-references, and external links using the
 * proven GitHub anchor generation algorithm.
 *
 * @package LinkValidator\Core
 */

declare(strict_types=1);

namespace LinkValidator\Core;

use LinkValidator\Utils\Logger;
use LinkValidator\Utils\SecurityValidator;

require_once __DIR__ . '/GitHubAnchorGenerator.php';

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
     * Extract all links from file content
     *
     * @param string $content File content
     * @return array<array<string, string>> Array of links with text and url
     */
    private function extractLinks(string $content): array
    {
        $links = [];

        // Markdown links: [text](url)
        if (preg_match_all('/\[([^\]]*)\]\(([^)]+)\)/', $content, $matches, PREG_SET_ORDER)) {
            foreach ($matches as $match) {
                $links[] = [
                    'text' => trim($match[1]),
                    'url' => trim($match[2]),
                ];
            }
        }

        // HTML links: <a href="url">text</a>
        if (preg_match_all('/<a\s+[^>]*href=["\']([^"\']+)["\'][^>]*>([^<]*)<\/a>/i', $content, $matches, PREG_SET_ORDER)) {
            foreach ($matches as $match) {
                $links[] = [
                    'text' => trim(strip_tags($match[2])),
                    'url' => trim($match[1]),
                ];
            }
        }

        return $links;
    }

    /**
     * Categorize a link by its type
     *
     * @param string $url The URL to categorize
     * @return string Link type: internal, anchor, cross_reference, or external
     */
    private function categorizeLink(string $url): string
    {
        if (str_starts_with($url, 'http://') || str_starts_with($url, 'https://')) {
            return 'external';
        }

        if (str_starts_with($url, '#')) {
            return 'anchor';
        }

        if (str_starts_with($url, 'mailto:') || str_starts_with($url, 'tel:')) {
            return 'external';
        }

        // Check if it's a cross-reference (links to other documentation files)
        // Cross-reference: contains path separators (/ or \) AND has documentation extensions
        if ((str_contains($url, '/') || str_contains($url, '\\')) &&
            (str_contains($url, '.md') || str_contains($url, '.html'))) {
            return 'cross_reference';
        }

        // Internal: same-directory files or relative paths without separators
        if (str_contains($url, '.md') || str_contains($url, '.html')) {
            return 'internal';
        }

        return 'internal';
    }

    /**
     * Validate a single link
     *
     * @param string $filePath Source file path
     * @param array<string, string> $link Link information
     * @param string $linkType Type of link
     * @param array<string> $allFiles Index of all files
     * @param bool $checkExternal Whether to validate external links
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
        $url = $link['url'];

        return match ($linkType) {
            'anchor' => $this->validateAnchorLink($filePath, $url),
            'internal' => $this->validateInternalLink($filePath, $url, $caseSensitive),
            'cross_reference' => $this->validateCrossReferenceLink($filePath, $url, $allFiles, $caseSensitive),
            'external' => $checkExternal
                ? $this->validateExternalLink($url, $timeout)
                : ['valid' => true, 'message' => 'External link (not validated)'],
            default => ['valid' => false, 'message' => "Unknown link type: {$linkType}"],
        };
    }

    /**
     * Build an index of all available files for cross-reference validation
     *
     * @param array<string> $files List of file paths
     * @return array<string> Normalized file index
     */
    private function buildFileIndex(array $files): array
    {
        $index = [];
        foreach ($files as $file) {
            $normalized = str_replace('\\', '/', $file);
            $index[basename($normalized)] = $normalized;
            $index[$normalized] = $normalized;
        }
        return $index;
    }

    /**
     * Validate an anchor link within the same file
     *
     * @param string $filePath Source file path
     * @param string $anchor Anchor URL (e.g., "#heading-name")
     * @return array<string, mixed> Validation result
     */
    private function validateAnchorLink(string $filePath, string $anchor): array
    {
        try {
            $content = file_get_contents($filePath);
            if ($content === false) {
                return ['valid' => false, 'message' => 'Cannot read source file'];
            }

            // Extract headings from the file
            $headings = $this->extractHeadings($content);

            // Remove the # from the anchor for comparison
            $targetAnchor = ltrim($anchor, '#');

            // Check if any heading generates the target anchor
            foreach ($headings as $heading) {
                $generatedAnchor = $this->anchorGenerator->generate($heading);
                if ($generatedAnchor === $targetAnchor) {
                    return [
                        'valid' => true,
                        'message' => "Anchor found: {$heading} → #{$generatedAnchor}"
                    ];
                }
            }

            // Show available anchors for debugging (first 3)
            $availableAnchors = array_slice(
                array_map([$this->anchorGenerator, 'generate'], $headings),
                0,
                3
            );

            return [
                'valid' => false,
                'message' => "Anchor not found: #{$targetAnchor} (available: " .
                           implode(', ', array_map(fn($a) => "#{$a}", $availableAnchors)) . '...)'
            ];

        } catch (\Throwable $e) {
            return ['valid' => false, 'message' => 'Error checking anchor: ' . $e->getMessage()];
        }
    }

    /**
     * Validate an internal link (relative path within same directory)
     *
     * @param string $filePath Source file path
     * @param string $url Internal URL
     * @param bool $caseSensitive Whether to use case-sensitive validation
     * @return array<string, mixed> Validation result
     */
    private function validateInternalLink(string $filePath, string $url, bool $caseSensitive): array
    {
        try {
            // Handle anchor links in the URL
            $targetFile = $url;
            $anchor = null;
            if (str_contains($url, '#')) {
                [$targetFile, $anchor] = explode('#', $url, 2);
            }

            // Resolve relative path
            $sourceDir = dirname($filePath);
            $fullPath = $sourceDir . DIRECTORY_SEPARATOR . $targetFile;
            $realPath = realpath($fullPath);

            if ($realPath === false) {
                return ['valid' => false, 'message' => "File not found: {$targetFile}"];
            }

            $targetPath = $this->securityValidator->validatePath($realPath);

            if (!$targetPath || !file_exists($targetPath)) {
                return ['valid' => false, 'message' => "File not found: {$targetFile}"];
            }

            // If there's an anchor, validate it in the target file
            if ($anchor !== null) {
                $anchorResult = $this->validateAnchorLink($targetPath, "#{$anchor}");
                if (!$anchorResult['valid']) {
                    return [
                        'valid' => false,
                        'message' => "File exists but anchor not found: {$targetFile}#{$anchor}"
                    ];
                }
            }

            return ['valid' => true, 'message' => "File exists: {$targetFile}"];

        } catch (\Throwable $e) {
            return ['valid' => false, 'message' => 'Error validating internal link: ' . $e->getMessage()];
        }
    }

    /**
     * Validate a cross-reference link (link to other documentation files)
     *
     * @param string $filePath Source file path
     * @param string $url Cross-reference URL
     * @param array<string> $allFiles Index of all files
     * @param bool $caseSensitive Whether to use case-sensitive validation
     * @return array<string, mixed> Validation result
     */
    private function validateCrossReferenceLink(
        string $filePath,
        string $url,
        array $allFiles,
        bool $caseSensitive
    ): array {
        try {
            // Handle anchor links in the URL
            $targetFile = $url;
            $anchor = null;
            if (str_contains($url, '#')) {
                [$targetFile, $anchor] = explode('#', $url, 2);
            }

            // Check if file exists in the index
            $found = false;
            $actualPath = null;

            foreach ($allFiles as $indexedFile) {
                $comparison = $caseSensitive
                    ? (str_ends_with($indexedFile, $targetFile))
                    : (str_ends_with(strtolower($indexedFile), strtolower($targetFile)));

                if ($comparison) {
                    $found = true;
                    $actualPath = $indexedFile;
                    break;
                }
            }

            if (!$found) {
                return ['valid' => false, 'message' => "Cross-reference file not found: {$targetFile}"];
            }

            // If there's an anchor, validate it in the target file
            if ($anchor !== null && $actualPath !== null) {
                $anchorResult = $this->validateAnchorLink($actualPath, "#{$anchor}");
                if (!$anchorResult['valid']) {
                    return [
                        'valid' => false,
                        'message' => "Cross-reference file exists but anchor not found: {$targetFile}#{$anchor}"
                    ];
                }
            }

            return ['valid' => true, 'message' => "Cross-reference file exists: {$targetFile}"];

        } catch (\Throwable $e) {
            return ['valid' => false, 'message' => 'Error validating cross-reference: ' . $e->getMessage()];
        }
    }

    /**
     * Validate an external link (HTTP/HTTPS)
     *
     * @param string $url External URL
     * @param int $timeout Timeout in seconds
     * @return array<string, mixed> Validation result
     */
    private function validateExternalLink(string $url, int $timeout): array
    {
        try {
            $context = stream_context_create([
                'http' => [
                    'timeout' => $timeout,
                    'method' => 'HEAD',
                    'user_agent' => 'PHP Link Validator 1.0',
                    'follow_location' => true,
                    'max_redirects' => 5,
                ],
            ]);

            $headers = @get_headers($url, false, $context);

            if ($headers === false) {
                return ['valid' => false, 'message' => 'External link unreachable'];
            }

            $statusCode = $this->extractStatusCode($headers[0] ?? '');

            if ($statusCode >= 200 && $statusCode < 400) {
                return ['valid' => true, 'message' => "External link accessible (HTTP {$statusCode})"];
            }

            return ['valid' => false, 'message' => "External link error (HTTP {$statusCode})"];

        } catch (\Throwable $e) {
            return ['valid' => false, 'message' => 'External link validation error: ' . $e->getMessage()];
        }
    }

    /**
     * Extract headings from file content
     *
     * @param string $content File content
     * @return array<string> Array of heading texts
     */
    private function extractHeadings(string $content): array
    {
        $headings = [];

        // Markdown headings: # Heading
        if (preg_match_all('/^#+\s+(.+)$/m', $content, $matches)) {
            $headings = array_merge($headings, $matches[1]);
        }

        // HTML headings: <h1>Heading</h1>
        if (preg_match_all('/<h[1-6][^>]*>([^<]+)<\/h[1-6]>/i', $content, $matches)) {
            $headings = array_merge($headings, array_map('strip_tags', $matches[1]));
        }

        return array_map('trim', $headings);
    }

    /**
     * Extract HTTP status code from response header
     *
     * @param string $header HTTP response header
     * @return int Status code
     */
    private function extractStatusCode(string $header): int
    {
        if (preg_match('/HTTP\/\d\.\d\s+(\d+)/', $header, $matches)) {
            return (int) $matches[1];
        }
        return 0;
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
