<?php
/**
 * Link Fixing Engine
 * 
 * Core engine for automatically fixing broken links with support for fuzzy
 * matching, case corrections, missing extensions, and anchor generation.
 * 
 * @package LinkRectifier\Core
 */

declare(strict_types=1);

namespace LinkRectifier\Core;

use LinkValidator\Utils\Logger;
use LinkValidator\Utils\SecurityValidator;

/**
 * Main link fixing engine with comprehensive repair capabilities
 * 
 * Handles automatic fixing of broken links using various strategies including
 * fuzzy matching, case corrections, and missing file extension detection.
 */
final class LinkFixer
{
    private readonly Logger $logger;
    private readonly SecurityValidator $securityValidator;
    private readonly FuzzyMatcher $fuzzyMatcher;
    private readonly BackupManager $backupManager;
    
    /**
     * Fix statistics
     */
    private array $stats = [
        'attempted' => 0,
        'fixed' => 0,
        'failed' => 0,
        'skipped' => 0,
    ];
    
    public function __construct(
        Logger $logger,
        SecurityValidator $securityValidator,
        FuzzyMatcher $fuzzyMatcher,
        BackupManager $backupManager
    ) {
        $this->logger = $logger;
        $this->securityValidator = $securityValidator;
        $this->fuzzyMatcher = $fuzzyMatcher;
        $this->backupManager = $backupManager;
    }
    
    /**
     * Process fixes for broken links
     * 
     * @param array<array<string, mixed>> $brokenLinks Broken links to fix
     * @param array<string> $allFiles All available files
     * @param array<string, mixed> $config Configuration
     * @return array<string, mixed> Fix results
     */
    public function processFixes(
        array $brokenLinks,
        array $allFiles,
        array $config
    ): array {
        $this->logger->info('Starting link fixing process');
        
        // Reset statistics
        $this->stats = array_fill_keys(array_keys($this->stats), 0);
        
        $fixDetails = [];
        $fileIndex = $this->buildFileIndex($allFiles);
        
        // Group broken links by source file for efficient processing
        $linksByFile = $this->groupLinksByFile($brokenLinks);
        
        foreach ($linksByFile as $sourceFile => $links) {
            $this->logger->debug("Processing fixes for: {$sourceFile}");
            
            $fileFixResults = $this->processFileLinks(
                $sourceFile,
                $links,
                $fileIndex,
                $config
            );
            
            $fixDetails = array_merge($fixDetails, $fileFixResults);
        }
        
        return [
            'attempted' => $this->stats['attempted'],
            'fixed' => $this->stats['fixed'],
            'failed' => $this->stats['failed'],
            'skipped' => $this->stats['skipped'],
            'details' => $fixDetails,
        ];
    }
    
    /**
     * Process fixes for links in a single file
     * 
     * @param string $sourceFile Source file path
     * @param array<array<string, mixed>> $links Broken links in the file
     * @param array<string> $fileIndex File index for matching
     * @param array<string, mixed> $config Configuration
     * @return array<array<string, mixed>> Fix details
     */
    private function processFileLinks(
        string $sourceFile,
        array $links,
        array $fileIndex,
        array $config
    ): array {
        $fixDetails = [];
        
        try {
            $content = file_get_contents($sourceFile);
            if ($content === false) {
                throw new \RuntimeException("Cannot read file: {$sourceFile}");
            }
            
            $originalContent = $content;
            $modified = false;
            
            foreach ($links as $link) {
                $this->stats['attempted']++;
                
                $fixResult = $this->attemptLinkFix(
                    $link,
                    $sourceFile,
                    $fileIndex,
                    $config
                );
                
                if ($fixResult['success']) {
                    // Apply the fix to the content
                    $content = $this->applyFix($content, $link, $fixResult['fixed_url']);
                    $modified = true;
                    $this->stats['fixed']++;
                    
                    $fixDetails[] = [
                        'file' => $sourceFile,
                        'original_url' => $link['url'],
                        'fixed_url' => $fixResult['fixed_url'],
                        'method' => $fixResult['method'],
                        'description' => $fixResult['description'],
                        'success' => true,
                    ];
                    
                    $this->logger->info("Fixed: {$link['url']} → {$fixResult['fixed_url']} ({$fixResult['method']})");
                } else {
                    $this->stats['failed']++;
                    
                    $fixDetails[] = [
                        'file' => $sourceFile,
                        'original_url' => $link['url'],
                        'error' => $fixResult['error'],
                        'description' => "Failed to fix: {$fixResult['error']}",
                        'success' => false,
                    ];
                    
                    $this->logger->warning("Failed to fix: {$link['url']} - {$fixResult['error']}");
                }
            }
            
            // Write modified content back to file (if not dry-run)
            if ($modified && !$config['dry_run']) {
                if ($config['interactive']) {
                    if (!$this->confirmFileModification($sourceFile, $originalContent, $content)) {
                        $this->logger->info("Skipped modifications to: {$sourceFile}");
                        return $fixDetails;
                    }
                }
                
                if (file_put_contents($sourceFile, $content) === false) {
                    throw new \RuntimeException("Cannot write to file: {$sourceFile}");
                }
                
                $this->logger->info("Updated file: {$sourceFile}");
            } elseif ($modified && $config['dry_run']) {
                $this->showDryRunDiff($sourceFile, $originalContent, $content);
            }
            
        } catch (\Throwable $e) {
            $this->logger->error("Error processing file {$sourceFile}: " . $e->getMessage());
            
            foreach ($links as $link) {
                $fixDetails[] = [
                    'file' => $sourceFile,
                    'original_url' => $link['url'],
                    'error' => $e->getMessage(),
                    'description' => "File processing error: {$e->getMessage()}",
                    'success' => false,
                ];
            }
        }
        
        return $fixDetails;
    }
    
    /**
     * Attempt to fix a single broken link
     * 
     * @param array<string, mixed> $link Broken link information
     * @param string $sourceFile Source file path
     * @param array<string> $fileIndex File index for matching
     * @param array<string, mixed> $config Configuration
     * @return array<string, mixed> Fix result
     */
    private function attemptLinkFix(
        array $link,
        string $sourceFile,
        array $fileIndex,
        array $config
    ): array {
        $url = $link['url'];
        $type = $link['type'];
        
        // Try different fixing strategies based on link type
        return match ($type) {
            'internal' => $this->fixInternalLink($url, $sourceFile, $fileIndex, $config),
            'anchor' => $this->fixAnchorLink($url, $sourceFile, $config),
            'cross_reference' => $this->fixCrossReferenceLink($url, $fileIndex, $config),
            default => ['success' => false, 'error' => "Unsupported link type: {$type}"],
        };
    }
    
    /**
     * Fix internal link (relative path)
     * 
     * @param string $url Original URL
     * @param string $sourceFile Source file path
     * @param array<string> $fileIndex File index
     * @param array<string, mixed> $config Configuration
     * @return array<string, mixed> Fix result
     */
    private function fixInternalLink(
        string $url,
        string $sourceFile,
        array $fileIndex,
        array $config
    ): array {
        $sourceDir = dirname($sourceFile);
        $targetFile = $url;
        $anchor = null;
        
        // Handle anchor in URL
        if (str_contains($url, '#')) {
            [$targetFile, $anchor] = explode('#', $url, 2);
        }
        
        // Try case-insensitive match
        $targetPath = $sourceDir . DIRECTORY_SEPARATOR . $targetFile;
        $realPath = realpath($targetPath);
        
        if ($realPath === false) {
            // Try adding common extensions
            $extensions = ['.md', '.html', '.htm'];
            foreach ($extensions as $ext) {
                $testPath = $targetPath . $ext;
                if (file_exists($testPath)) {
                    $fixedUrl = $targetFile . $ext . ($anchor ? "#{$anchor}" : '');
                    return [
                        'success' => true,
                        'fixed_url' => $fixedUrl,
                        'method' => 'extension_addition',
                        'description' => "Added missing extension: {$ext}",
                    ];
                }
            }
            
            // Try fuzzy matching
            $fuzzyMatch = $this->fuzzyMatcher->findBestMatch(
                $targetFile,
                $fileIndex,
                $config['similarity_threshold']
            );
            
            if ($fuzzyMatch !== null) {
                $relativePath = $this->getRelativePath($sourceDir, $fuzzyMatch);
                $fixedUrl = $relativePath . ($anchor ? "#{$anchor}" : '');
                return [
                    'success' => true,
                    'fixed_url' => $fixedUrl,
                    'method' => 'fuzzy_match',
                    'description' => "Fuzzy matched to: {$fuzzyMatch}",
                ];
            }
        }
        
        return ['success' => false, 'error' => 'No suitable fix found'];
    }
    
    /**
     * Fix anchor link
     * 
     * @param string $url Original URL
     * @param string $sourceFile Source file path
     * @param array<string, mixed> $config Configuration
     * @return array<string, mixed> Fix result
     */
    private function fixAnchorLink(
        string $url,
        string $sourceFile,
        array $config
    ): array {
        // For now, anchor fixing is limited to suggesting heading creation
        // This would require more complex content analysis and modification
        return [
            'success' => false,
            'error' => 'Anchor fixing not yet implemented - consider creating the missing heading',
        ];
    }
    
    /**
     * Fix cross-reference link
     * 
     * @param string $url Original URL
     * @param array<string> $fileIndex File index
     * @param array<string, mixed> $config Configuration
     * @return array<string, mixed> Fix result
     */
    private function fixCrossReferenceLink(
        string $url,
        array $fileIndex,
        array $config
    ): array {
        $targetFile = $url;
        $anchor = null;
        
        // Handle anchor in URL
        if (str_contains($url, '#')) {
            [$targetFile, $anchor] = explode('#', $url, 2);
        }
        
        // Try fuzzy matching against all files
        $fuzzyMatch = $this->fuzzyMatcher->findBestMatch(
            $targetFile,
            $fileIndex,
            $config['similarity_threshold']
        );
        
        if ($fuzzyMatch !== null) {
            $fixedUrl = basename($fuzzyMatch) . ($anchor ? "#{$anchor}" : '');
            return [
                'success' => true,
                'fixed_url' => $fixedUrl,
                'method' => 'cross_reference_fuzzy',
                'description' => "Cross-reference fuzzy matched to: {$fuzzyMatch}",
            ];
        }
        
        return ['success' => false, 'error' => 'No suitable cross-reference found'];
    }
    
    /**
     * Apply a fix to file content
     * 
     * @param string $content File content
     * @param array<string, mixed> $link Original link
     * @param string $fixedUrl Fixed URL
     * @return string Modified content
     */
    private function applyFix(string $content, array $link, string $fixedUrl): string
    {
        $originalUrl = $link['url'];
        $linkText = $link['text'];
        
        // Create patterns for both markdown and HTML links
        $patterns = [
            // Markdown: [text](url)
            '/\[' . preg_quote($linkText, '/') . '\]\(' . preg_quote($originalUrl, '/') . '\)/',
            // HTML: <a href="url">text</a>
            '/<a\s+[^>]*href=["\']' . preg_quote($originalUrl, '/') . '["\'][^>]*>' . preg_quote($linkText, '/') . '<\/a>/i',
        ];
        
        $replacements = [
            "[{$linkText}]({$fixedUrl})",
            "<a href=\"{$fixedUrl}\">{$linkText}</a>",
        ];
        
        foreach ($patterns as $i => $pattern) {
            $newContent = preg_replace($pattern, $replacements[$i], $content);
            if ($newContent !== null && $newContent !== $content) {
                return $newContent;
            }
        }
        
        return $content;
    }
    
    /**
     * Build file index for matching
     * 
     * @param array<string> $files List of files
     * @return array<string> File index
     */
    private function buildFileIndex(array $files): array
    {
        $index = [];
        foreach ($files as $file) {
            $index[] = $file;
            $index[] = basename($file);
        }
        return array_unique($index);
    }
    
    /**
     * Group broken links by source file
     * 
     * @param array<array<string, mixed>> $brokenLinks Broken links
     * @return array<string, array<array<string, mixed>>> Links grouped by file
     */
    private function groupLinksByFile(array $brokenLinks): array
    {
        $grouped = [];
        foreach ($brokenLinks as $link) {
            $sourceFile = $link['source_file'];
            if (!isset($grouped[$sourceFile])) {
                $grouped[$sourceFile] = [];
            }
            $grouped[$sourceFile][] = $link;
        }
        return $grouped;
    }
    
    /**
     * Get relative path from source to target
     * 
     * @param string $sourceDir Source directory
     * @param string $targetFile Target file
     * @return string Relative path
     */
    private function getRelativePath(string $sourceDir, string $targetFile): string
    {
        $sourceParts = explode(DIRECTORY_SEPARATOR, realpath($sourceDir));
        $targetParts = explode(DIRECTORY_SEPARATOR, realpath(dirname($targetFile)));
        
        // Find common path
        $commonLength = 0;
        $minLength = min(count($sourceParts), count($targetParts));
        
        for ($i = 0; $i < $minLength; $i++) {
            if ($sourceParts[$i] === $targetParts[$i]) {
                $commonLength++;
            } else {
                break;
            }
        }
        
        // Build relative path
        $relativeParts = [];
        
        // Add .. for each directory we need to go up
        for ($i = $commonLength; $i < count($sourceParts); $i++) {
            $relativeParts[] = '..';
        }
        
        // Add path down to target
        for ($i = $commonLength; $i < count($targetParts); $i++) {
            $relativeParts[] = $targetParts[$i];
        }
        
        // Add filename
        $relativeParts[] = basename($targetFile);
        
        return implode('/', $relativeParts);
    }
    
    /**
     * Confirm file modification in interactive mode
     * 
     * @param string $filePath File path
     * @param string $originalContent Original content
     * @param string $modifiedContent Modified content
     * @return bool True if confirmed
     */
    private function confirmFileModification(
        string $filePath,
        string $originalContent,
        string $modifiedContent
    ): bool {
        echo "\nProposed changes for: {$filePath}\n";
        echo str_repeat("-", 50) . "\n";
        
        $this->showDiff($originalContent, $modifiedContent);
        
        echo "\nApply these changes? [y/N]: ";
        $response = trim(fgets(STDIN));
        
        return strtolower($response) === 'y' || strtolower($response) === 'yes';
    }
    
    /**
     * Show dry-run diff
     * 
     * @param string $filePath File path
     * @param string $originalContent Original content
     * @param string $modifiedContent Modified content
     */
    private function showDryRunDiff(
        string $filePath,
        string $originalContent,
        string $modifiedContent
    ): void {
        echo "\nDry-run changes for: {$filePath}\n";
        echo str_repeat("-", 50) . "\n";
        
        $this->showDiff($originalContent, $modifiedContent);
    }
    
    /**
     * Show unified diff between two content strings
     * 
     * @param string $original Original content
     * @param string $modified Modified content
     */
    private function showDiff(string $original, string $modified): void
    {
        $originalLines = explode("\n", $original);
        $modifiedLines = explode("\n", $modified);
        
        // Simple diff implementation - could be enhanced with proper diff algorithm
        $maxLines = max(count($originalLines), count($modifiedLines));
        
        for ($i = 0; $i < $maxLines; $i++) {
            $originalLine = $originalLines[$i] ?? '';
            $modifiedLine = $modifiedLines[$i] ?? '';
            
            if ($originalLine !== $modifiedLine) {
                if (!empty($originalLine)) {
                    echo "- {$originalLine}\n";
                }
                if (!empty($modifiedLine)) {
                    echo "+ {$modifiedLine}\n";
                }
            }
        }
    }
}
