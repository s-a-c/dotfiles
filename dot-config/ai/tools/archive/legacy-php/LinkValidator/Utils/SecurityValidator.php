<?php
/**
 * Security Validation Utilities
 *
 * Provides comprehensive security validation for file paths, user inputs,
 * and system operations to prevent directory traversal, injection attacks,
 * and other security vulnerabilities.
 *
 * @package LinkValidator\Utils
 */

declare(strict_types=1);

namespace LinkValidator\Utils;

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
     */
    public function addAllowedBasePath(string $path): void
    {
        $realPath = realpath($path);
        if ($realPath !== false) {
            $this->allowedBasePaths[] = $realPath;
        }
    }

    /**
     * Validate and normalize a file path
     *
     * @param string $path Path to validate
     * @return string|null Normalized path or null if invalid
     */
    public function validatePath(string $path): ?string
    {
        if (empty($path)) {
            return null;
        }

        // Check for dangerous patterns
        foreach (self::DANGEROUS_PATTERNS as $pattern) {
            if (preg_match($pattern, $path)) {
                return null;
            }
        }

        // Normalize path separators
        $normalizedPath = str_replace(['\\', '/'], DIRECTORY_SEPARATOR, $path);

        // Remove multiple consecutive separators
        $normalizedPath = preg_replace('/[' . preg_quote(DIRECTORY_SEPARATOR, '/') . ']+/', DIRECTORY_SEPARATOR, $normalizedPath);

        // If path is relative, make it absolute
        if (!$this->isAbsolutePath($normalizedPath)) {
            $normalizedPath = getcwd() . DIRECTORY_SEPARATOR . $normalizedPath;
        }

        // Get real path (resolves symlinks and relative components)
        $realPath = realpath($normalizedPath);

        // If realpath fails, try to validate the path manually
        if ($realPath === false) {
            // For non-existent files, validate the directory part
            $directory = dirname($normalizedPath);
            $realDirectory = realpath($directory);

            if ($realDirectory === false) {
                return null;
            }

            $filename = basename($normalizedPath);
            if (!$this->isValidFilename($filename)) {
                return null;
            }

            $realPath = $realDirectory . DIRECTORY_SEPARATOR . $filename;
        }

        // Ensure we have a valid string path
        if (!is_string($realPath)) {
            return null;
        }

        // Check if path is within allowed base paths
        if (!$this->isPathAllowed($realPath)) {
            return null;
        }

        return $realPath;
    }

    /**
     * Check if a path is absolute
     *
     * @param string $path Path to check
     * @return bool True if absolute
     */
    private function isAbsolutePath(string $path): bool
    {
        // Unix/Linux absolute path
        if (str_starts_with($path, '/')) {
            return true;
        }

        // Windows absolute path
        if (preg_match('/^[A-Za-z]:[\\\\\/]/', $path)) {
            return true;
        }

        return false;
    }

    /**
     * Check if a filename is valid
     *
     * @param string $filename Filename to check
     * @return bool True if valid
     */
    private function isValidFilename(string $filename): bool
    {
        if (empty($filename) || $filename === '.' || $filename === '..') {
            return false;
        }

        // Check for invalid characters
        if (preg_match('/[<>:"|*?\\x00-\\x1f]/', $filename)) {
            return false;
        }

        // Check for Windows reserved names
        $nameWithoutExt = pathinfo($filename, PATHINFO_FILENAME);
        if (preg_match('/^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$/i', $nameWithoutExt)) {
            return false;
        }

        // Check length (most filesystems have a 255 byte limit)
        if (strlen($filename) > 255) {
            return false;
        }

        return true;
    }

    /**
     * Check if a path is within allowed base paths
     *
     * @param string $path Path to check
     * @return bool True if allowed
     */
    private function isPathAllowed(string $path): bool
    {
        foreach ($this->allowedBasePaths as $basePath) {
            if (str_starts_with($path, $basePath . DIRECTORY_SEPARATOR) || $path === $basePath) {
                return true;
            }
        }

        return false;
    }

    /**
     * Sanitize user input string
     *
     * @param string $input Input to sanitize
     * @param int $maxLength Maximum allowed length
     * @return string Sanitized input
     */
    public function sanitizeInput(string $input, int $maxLength = 1000): string
    {
        // Remove null bytes
        $sanitized = str_replace("\0", '', $input);

        // Trim whitespace
        $sanitized = trim($sanitized);

        // Limit length
        if (strlen($sanitized) > $maxLength) {
            $sanitized = substr($sanitized, 0, $maxLength);
        }

        return $sanitized;
    }

    /**
     * Validate URL for external link checking
     *
     * @param string $url URL to validate
     * @return bool True if URL is safe to check
     */
    public function validateUrl(string $url): bool
    {
        // Basic URL validation
        if (!filter_var($url, FILTER_VALIDATE_URL)) {
            return false;
        }

        $parsedUrl = parse_url($url);
        if ($parsedUrl === false) {
            return false;
        }

        // Only allow HTTP and HTTPS
        if (!isset($parsedUrl['scheme']) || !in_array($parsedUrl['scheme'], ['http', 'https'], true)) {
            return false;
        }

        // Block localhost and private IP ranges
        if (isset($parsedUrl['host'])) {
            $host = $parsedUrl['host'];

            // Block localhost
            if (in_array(strtolower($host), ['localhost', '127.0.0.1', '::1'], true)) {
                return false;
            }

            // Block private IP ranges
            if (filter_var($host, FILTER_VALIDATE_IP)) {
                if (!filter_var($host, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE)) {
                    return false;
                }
            }
        }

        return true;
    }

    /**
     * Validate command line argument
     *
     * @param string $arg Argument to validate
     * @return string Validated argument
     * @throws \InvalidArgumentException If argument is invalid
     */
    public function validateArgument(string $arg): string
    {
        // Remove null bytes and control characters
        $sanitized = preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/', '', $arg);

        if ($sanitized === null) {
            throw new \InvalidArgumentException('Invalid argument: contains invalid characters');
        }

        // Limit length
        if (strlen($sanitized) > 4096) {
            throw new \InvalidArgumentException('Argument too long');
        }

        return trim($sanitized);
    }

    /**
     * Check if a file operation is safe
     *
     * @param string $operation Operation type (read, write, delete)
     * @param string $path File path
     * @return bool True if operation is safe
     */
    public function isOperationSafe(string $operation, string $path): bool
    {
        $validatedPath = $this->validatePath($path);
        if ($validatedPath === null) {
            return false;
        }

        return match ($operation) {
            'read' => is_readable($validatedPath),
            'write' => is_writable(dirname($validatedPath)),
            'delete' => is_writable($validatedPath) && is_writable(dirname($validatedPath)),
            default => false,
        };
    }

    /**
     * Create a secure temporary file
     *
     * @param string $prefix Filename prefix
     * @param string $suffix Filename suffix
     * @return string|null Temporary file path or null on failure
     */
    public function createSecureTempFile(string $prefix = 'link_validator_', string $suffix = '.tmp'): ?string
    {
        $tempDir = sys_get_temp_dir();
        $validatedTempDir = $this->validatePath($tempDir);

        if ($validatedTempDir === null || !is_writable($validatedTempDir)) {
            return null;
        }

        $tempFile = tempnam($validatedTempDir, $prefix);
        if ($tempFile === false) {
            return null;
        }

        // Add suffix if specified
        if (!empty($suffix) && $suffix !== '.tmp') {
            $newTempFile = $tempFile . $suffix;
            if (rename($tempFile, $newTempFile)) {
                $tempFile = $newTempFile;
            }
        }

        return $tempFile;
    }
}
