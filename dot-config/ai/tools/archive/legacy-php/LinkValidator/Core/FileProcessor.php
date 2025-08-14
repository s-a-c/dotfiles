<?php
/**
 * File Processing and Input Handling
 * 
 * Handles file discovery, filtering, and validation with comprehensive
 * security measures and support for glob patterns, exclusions, and depth limits.
 * 
 * @package LinkValidator\Core
 */

declare(strict_types=1);

namespace LinkValidator\Core;

use LinkValidator\Utils\Logger;
use LinkValidator\Utils\SecurityValidator;

/**
 * File processor for handling input files and directories
 * 
 * Provides secure file discovery with support for glob patterns, exclusions,
 * depth limits, and hidden file handling.
 */
final class FileProcessor
{
    private readonly Logger $logger;
    private readonly SecurityValidator $securityValidator;
    
    /**
     * Supported file extensions (case-insensitive)
     */
    private const SUPPORTED_EXTENSIONS = ['.md', '.html', '.htm'];
    
    public function __construct(Logger $logger, SecurityValidator $securityValidator)
    {
        $this->logger = $logger;
        $this->securityValidator = $securityValidator;
    }
    
    /**
     * Process input files and directories
     * 
     * @param array<string> $inputs Input files and directories
     * @param int $maxDepth Maximum directory traversal depth
     * @param bool $includeHidden Include hidden files and directories
     * @param bool $onlyHidden Process only hidden files
     * @param array<string> $excludePatterns Exclude patterns
     * @return array<string> List of valid file paths
     * @throws \InvalidArgumentException If inputs are invalid
     */
    public function processInputs(
        array $inputs,
        int $maxDepth,
        bool $includeHidden,
        bool $onlyHidden,
        array $excludePatterns
    ): array {
        if (empty($inputs)) {
            throw new \InvalidArgumentException('No input files or directories specified');
        }
        
        $this->logger->debug('Processing inputs', [
            'inputs' => $inputs,
            'max_depth' => $maxDepth,
            'include_hidden' => $includeHidden,
            'only_hidden' => $onlyHidden,
            'exclude_patterns' => $excludePatterns,
        ]);
        
        $files = [];
        
        foreach ($inputs as $input) {
            $input = trim($input);
            if (empty($input)) {
                continue;
            }
            
            // Validate and normalize path
            $normalizedPath = $this->securityValidator->validatePath($input);
            if (!$normalizedPath) {
                $this->logger->warning("Invalid or inaccessible path: {$input}");
                continue;
            }
            
            if (is_file($normalizedPath)) {
                if ($this->isValidFile($normalizedPath, $includeHidden, $onlyHidden, $excludePatterns)) {
                    $files[] = $normalizedPath;
                }
            } elseif (is_dir($normalizedPath)) {
                $dirFiles = $this->processDirectory(
                    $normalizedPath,
                    $maxDepth,
                    $includeHidden,
                    $onlyHidden,
                    $excludePatterns
                );
                $files = array_merge($files, $dirFiles);
            } else {
                // Try glob pattern
                $globFiles = $this->processGlobPattern(
                    $input,
                    $includeHidden,
                    $onlyHidden,
                    $excludePatterns
                );
                $files = array_merge($files, $globFiles);
            }
        }
        
        // Remove duplicates and sort
        $files = array_unique($files);
        sort($files);
        
        $this->logger->info("Found {count} files to process", ['count' => count($files)]);
        
        return $files;
    }
    
    /**
     * Process a directory recursively
     * 
     * @param string $directory Directory path
     * @param int $maxDepth Maximum depth (0 = unlimited)
     * @param bool $includeHidden Include hidden files
     * @param bool $onlyHidden Process only hidden files
     * @param array<string> $excludePatterns Exclude patterns
     * @param int $currentDepth Current recursion depth
     * @return array<string> List of files
     */
    private function processDirectory(
        string $directory,
        int $maxDepth,
        bool $includeHidden,
        bool $onlyHidden,
        array $excludePatterns,
        int $currentDepth = 0
    ): array {
        $files = [];
        
        // Check depth limit
        if ($maxDepth > 0 && $currentDepth >= $maxDepth) {
            return $files;
        }
        
        try {
            $iterator = new \DirectoryIterator($directory);
            
            foreach ($iterator as $fileInfo) {
                if ($fileInfo->isDot()) {
                    continue;
                }
                
                $filePath = $fileInfo->getPathname();
                $fileName = $fileInfo->getFilename();
                
                // Handle hidden files/directories
                $isHidden = str_starts_with($fileName, '.');
                if ($isHidden && !$includeHidden && !$onlyHidden) {
                    continue;
                }
                if (!$isHidden && $onlyHidden) {
                    continue;
                }
                
                // Check exclusion patterns
                if ($this->isExcluded($filePath, $excludePatterns)) {
                    $this->logger->debug("Excluded: {$filePath}");
                    continue;
                }
                
                if ($fileInfo->isFile()) {
                    if ($this->isSupportedFile($filePath)) {
                        $files[] = $filePath;
                    }
                } elseif ($fileInfo->isDir()) {
                    $subFiles = $this->processDirectory(
                        $filePath,
                        $maxDepth,
                        $includeHidden,
                        $onlyHidden,
                        $excludePatterns,
                        $currentDepth + 1
                    );
                    $files = array_merge($files, $subFiles);
                }
            }
            
        } catch (\Throwable $e) {
            $this->logger->error("Error processing directory {$directory}: " . $e->getMessage());
        }
        
        return $files;
    }
    
    /**
     * Process a glob pattern
     * 
     * @param string $pattern Glob pattern
     * @param bool $includeHidden Include hidden files
     * @param bool $onlyHidden Process only hidden files
     * @param array<string> $excludePatterns Exclude patterns
     * @return array<string> List of files
     */
    private function processGlobPattern(
        string $pattern,
        bool $includeHidden,
        bool $onlyHidden,
        array $excludePatterns
    ): array {
        $files = [];
        
        try {
            $matches = glob($pattern, GLOB_BRACE);
            if ($matches === false) {
                $this->logger->warning("Invalid glob pattern: {$pattern}");
                return $files;
            }
            
            foreach ($matches as $match) {
                if (is_file($match) && $this->isValidFile($match, $includeHidden, $onlyHidden, $excludePatterns)) {
                    $files[] = $match;
                }
            }
            
        } catch (\Throwable $e) {
            $this->logger->error("Error processing glob pattern {$pattern}: " . $e->getMessage());
        }
        
        return $files;
    }
    
    /**
     * Check if a file is valid for processing
     * 
     * @param string $filePath File path
     * @param bool $includeHidden Include hidden files
     * @param bool $onlyHidden Process only hidden files
     * @param array<string> $excludePatterns Exclude patterns
     * @return bool True if file is valid
     */
    private function isValidFile(
        string $filePath,
        bool $includeHidden,
        bool $onlyHidden,
        array $excludePatterns
    ): bool {
        $fileName = basename($filePath);
        
        // Check hidden file rules
        $isHidden = str_starts_with($fileName, '.');
        if ($isHidden && !$includeHidden && !$onlyHidden) {
            return false;
        }
        if (!$isHidden && $onlyHidden) {
            return false;
        }
        
        // Check if file is supported
        if (!$this->isSupportedFile($filePath)) {
            return false;
        }
        
        // Check exclusion patterns
        if ($this->isExcluded($filePath, $excludePatterns)) {
            return false;
        }
        
        // Check if file is readable
        if (!is_readable($filePath)) {
            $this->logger->warning("File not readable: {$filePath}");
            return false;
        }
        
        return true;
    }
    
    /**
     * Check if a file has a supported extension
     * 
     * @param string $filePath File path
     * @return bool True if supported
     */
    private function isSupportedFile(string $filePath): bool
    {
        $extension = strtolower(pathinfo($filePath, PATHINFO_EXTENSION));
        return in_array(".{$extension}", self::SUPPORTED_EXTENSIONS, true);
    }
    
    /**
     * Check if a path matches any exclusion pattern
     * 
     * @param string $path Path to check
     * @param array<string> $patterns Exclusion patterns
     * @return bool True if excluded
     */
    private function isExcluded(string $path, array $patterns): bool
    {
        foreach ($patterns as $pattern) {
            $pattern = trim($pattern);
            if (empty($pattern)) {
                continue;
            }
            
            // Convert simple patterns to regex
            $regex = $this->patternToRegex($pattern);
            if (preg_match($regex, $path)) {
                return true;
            }
        }
        
        return false;
    }
    
    /**
     * Convert a simple pattern to regex
     * 
     * @param string $pattern Simple pattern with * and ?
     * @return string Regex pattern
     */
    private function patternToRegex(string $pattern): string
    {
        // Escape special regex characters except * and ?
        $escaped = preg_quote($pattern, '/');
        
        // Convert * to .* and ? to .
        $regex = str_replace(['\*', '\?'], ['.*', '.'], $escaped);
        
        return "/^{$regex}$/i";
    }
}
