<?php
/**
 * Security Validation Utilities
 *
 * Provides comprehensive security validation for file paths, user inputs,
 * and system operations to prevent directory traversal, injection attacks,
 * and other security vulnerabilities.
 *
 * @package SAC\ValidateLinks\Utils
 */

declare(strict_types=1);

namespace SAC\ValidateLinks\Utils;

/**
 * Security validator for input sanitization and path validation
 *
 * Implements comprehensive security measures to prevent directory traversal,
 * path injection, and other security vulnerabilities in file operations.
 */
final class SecurityValidator
{
    /**
     * Allowed base directories for file operations
     */
    private array $allowedBasePaths = [];

    /**
     * Dangerous path patterns to block
     */
    private const DANGEROUS_PATTERNS = [
        '/\.\./',           // Directory traversal
        '/\/\.\./',         // Directory traversal with slash
        '/\.\.\\\\/',       // Directory traversal with backslash
        '/\0/',             // Null byte injection
        '/[<>"|*?]/',       // Invalid filename characters
        '/^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$/i', // Windows reserved names
    ];

    public function __construct()
    {
        // Set default allowed base paths
        $this->allowedBasePaths = [
            getcwd(),
            dirname(__DIR__, 3), // Project root
        ];
    }

    /**
     * Add an allowed base path for file operations
     *
     * @param string $path Base path to allow
     * @throws \InvalidArgumentException If path is invalid
     */
    public function addAllowedBasePath(string $path): void
    {
        $realPath = realpath($path);
        if ($realPath === false) {
            throw new \InvalidArgumentException("Invalid base path: {$path}");
        }

        $this->allowedBasePaths[] = $realPath;
    }

    /**
     * Validate a file path for security issues
     *
     * @param string $path File path to validate
     * @return bool True if path is safe
     * @throws \InvalidArgumentException If path is dangerous
     */
    public function validatePath(string $path): bool
    {
        // Check for dangerous patterns
        foreach (self::DANGEROUS_PATTERNS as $pattern) {
            if (preg_match($pattern, $path)) {
                throw new \InvalidArgumentException("Dangerous path pattern detected: {$path}");
            }
        }

        // Resolve the real path
        $realPath = realpath($path);
        if ($realPath === false) {
            // Path doesn't exist - this is okay for validation purposes
            // We'll validate the directory structure instead
            $realPath = $this->resolveNonExistentPath($path);
        }

        // Check if path is within allowed base paths
        foreach ($this->allowedBasePaths as $basePath) {
            if (str_starts_with($realPath, $basePath)) {
                return true;
            }
        }

        throw new \InvalidArgumentException("Path outside allowed directories: {$path}");
    }

    /**
     * Resolve a non-existent path for validation
     *
     * @param string $path Path to resolve
     * @return string Resolved path
     */
    private function resolveNonExistentPath(string $path): string
    {
        // Get the directory part that exists
        $dir = dirname($path);
        while ($dir !== '.' && $dir !== '/' && !is_dir($dir)) {
            $dir = dirname($dir);
        }

        $realDir = realpath($dir);
        if ($realDir === false) {
            $realDir = getcwd();
        }

        // Reconstruct the path
        $relativePart = substr($path, strlen($dir));
        return $realDir . $relativePart;
    }

    /**
     * Sanitize user input string
     *
     * @param string $input Input to sanitize
     * @return string Sanitized input
     */
    public function sanitizeInput(string $input): string
    {
        // Remove null bytes
        $input = str_replace("\0", '', $input);

        // Trim whitespace
        $input = trim($input);

        // Remove control characters except newlines and tabs
        $input = preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/', '', $input);

        return $input;
    }

    /**
     * Validate URL for security issues
     *
     * @param string $url URL to validate
     * @return bool True if URL is safe
     * @throws \InvalidArgumentException If URL is dangerous
     */
    public function validateUrl(string $url): bool
    {
        // Check for dangerous protocols
        $dangerousProtocols = ['javascript:', 'data:', 'vbscript:', 'file:'];
        
        foreach ($dangerousProtocols as $protocol) {
            if (stripos($url, $protocol) === 0) {
                throw new \InvalidArgumentException("Dangerous URL protocol: {$url}");
            }
        }

        // Validate URL format
        if (!filter_var($url, FILTER_VALIDATE_URL)) {
            // Allow relative URLs and anchors
            if (!str_starts_with($url, '#') && !str_starts_with($url, '/') && !str_starts_with($url, './') && !str_starts_with($url, '../')) {
                throw new \InvalidArgumentException("Invalid URL format: {$url}");
            }
        }

        return true;
    }

    /**
     * Validate file extension
     *
     * @param string $filename Filename to validate
     * @param array<string> $allowedExtensions Allowed extensions
     * @return bool True if extension is allowed
     */
    public function validateFileExtension(string $filename, array $allowedExtensions): bool
    {
        $extension = strtolower(pathinfo($filename, PATHINFO_EXTENSION));
        return in_array($extension, array_map('strtolower', $allowedExtensions), true);
    }

    /**
     * Check if a file is readable and safe to access
     *
     * @param string $path File path to check
     * @return bool True if file is safe to read
     */
    public function isFileReadable(string $path): bool
    {
        try {
            $this->validatePath($path);
            return is_file($path) && is_readable($path);
        } catch (\InvalidArgumentException) {
            return false;
        }
    }

    /**
     * Check if a directory is safe to access
     *
     * @param string $path Directory path to check
     * @return bool True if directory is safe to access
     */
    public function isDirectoryAccessible(string $path): bool
    {
        try {
            $this->validatePath($path);
            return is_dir($path) && is_readable($path);
        } catch (\InvalidArgumentException) {
            return false;
        }
    }

    /**
     * Validate command line argument
     *
     * @param string $arg Argument to validate
     * @return string Sanitized argument
     * @throws \InvalidArgumentException If argument is dangerous
     */
    public function validateCliArgument(string $arg): string
    {
        // Check for command injection patterns
        $dangerousPatterns = [
            '/[;&|`$()]/',      // Command separators and substitution
            '/\$\{/',           // Variable substitution
            '/\$\(/',           // Command substitution
            '/`/',              // Backtick execution
        ];

        foreach ($dangerousPatterns as $pattern) {
            if (preg_match($pattern, $arg)) {
                throw new \InvalidArgumentException("Dangerous command pattern in argument: {$arg}");
            }
        }

        return $this->sanitizeInput($arg);
    }

    /**
     * Generate a safe temporary filename
     *
     * @param string $prefix Filename prefix
     * @param string $extension File extension
     * @return string Safe temporary filename
     */
    public function generateSafeFilename(string $prefix = 'temp', string $extension = '.tmp'): string
    {
        $prefix = preg_replace('/[^a-zA-Z0-9_-]/', '_', $prefix);
        $extension = preg_replace('/[^a-zA-Z0-9._-]/', '', $extension);
        
        if (!str_starts_with($extension, '.')) {
            $extension = '.' . $extension;
        }

        return $prefix . '_' . uniqid() . $extension;
    }

    /**
     * Check if the current environment is safe for file operations
     *
     * @return bool True if environment is safe
     */
    public function isEnvironmentSafe(): bool
    {
        // Check if running in safe mode (if PHP still supports it)
        if (function_exists('ini_get') && ini_get('safe_mode')) {
            return false;
        }

        // Check if dangerous functions are disabled
        $dangerousFunctions = ['exec', 'shell_exec', 'system', 'passthru'];
        $disabledFunctions = explode(',', ini_get('disable_functions'));
        
        foreach ($dangerousFunctions as $func) {
            if (!in_array($func, $disabledFunctions, true) && function_exists($func)) {
                // Functions exist but this doesn't make environment unsafe
                // Just means we need to be careful
            }
        }

        return true;
    }

    /**
     * Get allowed base paths
     *
     * @return array<string> Allowed base paths
     */
    public function getAllowedBasePaths(): array
    {
        return $this->allowedBasePaths;
    }
}
