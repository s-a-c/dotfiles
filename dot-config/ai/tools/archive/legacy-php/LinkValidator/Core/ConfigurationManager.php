<?php
/**
 * Configuration Management System
 * 
 * Handles loading and validation of configuration files with support for
 * JSON configuration, environment variables, and project-specific settings.
 * 
 * @package LinkValidator\Core
 */

declare(strict_types=1);

namespace LinkValidator\Core;

use LinkValidator\Utils\Logger;

/**
 * Configuration manager for handling project settings
 * 
 * Provides comprehensive configuration management with support for JSON files,
 * environment variables, and validation of configuration parameters.
 */
final class ConfigurationManager
{
    private readonly Logger $logger;
    
    /**
     * Default configuration file names to search for
     */
    private const CONFIG_FILENAMES = [
        '.link-validator.json',
        'link-validator.json',
        '.ai/config/link-validator.json',
    ];
    
    /**
     * Configuration schema for validation
     */
    private const SCHEMA = [
        'scope' => ['type' => 'array', 'items' => 'string', 'default' => ['all']],
        'max_broken' => ['type' => 'integer', 'min' => 0, 'default' => 0],
        'exclude_patterns' => ['type' => 'array', 'items' => 'string', 'default' => []],
        'check_external' => ['type' => 'boolean', 'default' => false],
        'timeout' => ['type' => 'integer', 'min' => 1, 'default' => 30],
        'max_depth' => ['type' => 'integer', 'min' => 0, 'default' => 0],
        'include_hidden' => ['type' => 'boolean', 'default' => false],
        'only_hidden' => ['type' => 'boolean', 'default' => false],
        'case_sensitive' => ['type' => 'boolean', 'default' => false],
        'format' => ['type' => 'string', 'enum' => ['json', 'markdown', 'html', 'console'], 'default' => 'console'],
        'no_color' => ['type' => 'boolean', 'default' => false],
        'verbosity' => ['type' => 'integer', 'min' => 0, 'max' => 3, 'default' => 1],
        'critical_files' => ['type' => 'array', 'items' => 'string', 'default' => []],
        'notification_webhook' => ['type' => 'string', 'default' => null],
        'report_directory' => ['type' => 'string', 'default' => '.ai/reports/automated'],
        'history_retention_days' => ['type' => 'integer', 'min' => 1, 'default' => 30],
    ];
    
    public function __construct(Logger $logger)
    {
        $this->logger = $logger;
    }
    
    /**
     * Load configuration from file
     * 
     * @param string $configFile Path to configuration file
     * @return array<string, mixed> Loaded configuration
     * @throws \InvalidArgumentException If configuration is invalid
     */
    public function loadConfigFile(string $configFile): array
    {
        if (!is_readable($configFile)) {
            throw new \InvalidArgumentException("Configuration file not readable: {$configFile}");
        }
        
        $this->logger->debug("Loading configuration from: {$configFile}");
        
        $content = file_get_contents($configFile);
        if ($content === false) {
            throw new \InvalidArgumentException("Cannot read configuration file: {$configFile}");
        }
        
        $config = json_decode($content, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            throw new \InvalidArgumentException(
                "Invalid JSON in configuration file: " . json_last_error_msg()
            );
        }
        
        if (!is_array($config)) {
            throw new \InvalidArgumentException("Configuration file must contain a JSON object");
        }
        
        return $this->validateAndNormalizeConfig($config);
    }
    
    /**
     * Auto-discover and load configuration file
     * 
     * @param string $startDirectory Directory to start searching from
     * @return array<string, mixed>|null Loaded configuration or null if not found
     */
    public function autoLoadConfig(string $startDirectory = '.'): ?array
    {
        $searchPaths = $this->getConfigSearchPaths($startDirectory);
        
        foreach ($searchPaths as $configFile) {
            if (is_readable($configFile)) {
                $this->logger->debug("Auto-discovered configuration: {$configFile}");
                try {
                    return $this->loadConfigFile($configFile);
                } catch (\Throwable $e) {
                    $this->logger->warning("Failed to load auto-discovered config {$configFile}: " . $e->getMessage());
                }
            }
        }
        
        return null;
    }
    
    /**
     * Load configuration from environment variables
     * 
     * @return array<string, mixed> Configuration from environment
     */
    public function loadFromEnvironment(): array
    {
        $config = [];
        
        // Map environment variables to configuration keys
        $envMapping = [
            'LINK_VALIDATOR_SCOPE' => 'scope',
            'LINK_VALIDATOR_MAX_BROKEN' => 'max_broken',
            'LINK_VALIDATOR_CHECK_EXTERNAL' => 'check_external',
            'LINK_VALIDATOR_TIMEOUT' => 'timeout',
            'LINK_VALIDATOR_MAX_DEPTH' => 'max_depth',
            'LINK_VALIDATOR_FORMAT' => 'format',
            'LINK_VALIDATOR_WEBHOOK' => 'notification_webhook',
            'LINK_VALIDATOR_REPORT_DIR' => 'report_directory',
        ];
        
        foreach ($envMapping as $envVar => $configKey) {
            $value = getenv($envVar);
            if ($value !== false) {
                $config[$configKey] = $this->parseEnvironmentValue($value, $configKey);
            }
        }
        
        return $this->validateAndNormalizeConfig($config);
    }
    
    /**
     * Merge multiple configuration sources
     * 
     * @param array<array<string, mixed>> $configs Configuration arrays to merge
     * @return array<string, mixed> Merged configuration
     */
    public function mergeConfigs(array $configs): array
    {
        $merged = [];
        
        foreach ($configs as $config) {
            $merged = array_merge($merged, $config);
        }
        
        return $this->validateAndNormalizeConfig($merged);
    }
    
    /**
     * Validate and normalize configuration
     * 
     * @param array<string, mixed> $config Configuration to validate
     * @return array<string, mixed> Validated configuration
     * @throws \InvalidArgumentException If configuration is invalid
     */
    private function validateAndNormalizeConfig(array $config): array
    {
        $normalized = [];
        
        foreach (self::SCHEMA as $key => $schema) {
            $value = $config[$key] ?? $schema['default'];
            
            // Type validation
            if (!$this->validateType($value, $schema)) {
                throw new \InvalidArgumentException(
                    "Configuration key '{$key}' has invalid type. Expected: {$schema['type']}"
                );
            }
            
            // Range validation
            if (isset($schema['min']) && is_numeric($value) && $value < $schema['min']) {
                throw new \InvalidArgumentException(
                    "Configuration key '{$key}' must be at least {$schema['min']}"
                );
            }
            
            if (isset($schema['max']) && is_numeric($value) && $value > $schema['max']) {
                throw new \InvalidArgumentException(
                    "Configuration key '{$key}' must be at most {$schema['max']}"
                );
            }
            
            // Enum validation
            if (isset($schema['enum']) && !in_array($value, $schema['enum'], true)) {
                throw new \InvalidArgumentException(
                    "Configuration key '{$key}' must be one of: " . implode(', ', $schema['enum'])
                );
            }
            
            // Array items validation
            if ($schema['type'] === 'array' && isset($schema['items']) && is_array($value)) {
                foreach ($value as $item) {
                    if (!$this->validateType($item, ['type' => $schema['items']])) {
                        throw new \InvalidArgumentException(
                            "Configuration key '{$key}' array items must be of type: {$schema['items']}"
                        );
                    }
                }
            }
            
            $normalized[$key] = $value;
        }
        
        // Additional validation rules
        $this->validateAdditionalRules($normalized);
        
        return $normalized;
    }
    
    /**
     * Validate type of a value
     * 
     * @param mixed $value Value to validate
     * @param array<string, mixed> $schema Schema definition
     * @return bool True if valid
     */
    private function validateType(mixed $value, array $schema): bool
    {
        return match ($schema['type']) {
            'string' => is_string($value),
            'integer' => is_int($value),
            'boolean' => is_bool($value),
            'array' => is_array($value),
            'null' => $value === null,
            default => false,
        };
    }
    
    /**
     * Validate additional configuration rules
     * 
     * @param array<string, mixed> $config Configuration to validate
     * @throws \InvalidArgumentException If validation fails
     */
    private function validateAdditionalRules(array $config): void
    {
        // Validate scope values
        $validScopes = ['internal', 'anchor', 'cross-reference', 'external', 'all'];
        foreach ($config['scope'] as $scope) {
            if (!in_array($scope, $validScopes, true)) {
                throw new \InvalidArgumentException("Invalid scope: {$scope}");
            }
        }
        
        // Validate conflicting options
        if ($config['include_hidden'] && $config['only_hidden']) {
            throw new \InvalidArgumentException('Cannot enable both include_hidden and only_hidden');
        }
        
        // Validate webhook URL if provided
        if ($config['notification_webhook'] !== null) {
            if (!filter_var($config['notification_webhook'], FILTER_VALIDATE_URL)) {
                throw new \InvalidArgumentException('Invalid webhook URL');
            }
        }
    }
    
    /**
     * Parse environment variable value
     * 
     * @param string $value Environment variable value
     * @param string $key Configuration key
     * @return mixed Parsed value
     */
    private function parseEnvironmentValue(string $value, string $key): mixed
    {
        $schema = self::SCHEMA[$key] ?? ['type' => 'string'];
        
        return match ($schema['type']) {
            'boolean' => in_array(strtolower($value), ['true', '1', 'yes', 'on'], true),
            'integer' => (int) $value,
            'array' => array_filter(array_map('trim', explode(',', $value))),
            default => $value,
        };
    }
    
    /**
     * Get configuration file search paths
     * 
     * @param string $startDirectory Starting directory
     * @return array<string> Search paths
     */
    private function getConfigSearchPaths(string $startDirectory): array
    {
        $paths = [];
        $currentDir = realpath($startDirectory) ?: $startDirectory;
        
        // Search up the directory tree
        while ($currentDir !== dirname($currentDir)) {
            foreach (self::CONFIG_FILENAMES as $filename) {
                $paths[] = $currentDir . DIRECTORY_SEPARATOR . $filename;
            }
            $currentDir = dirname($currentDir);
        }
        
        return $paths;
    }
    
    /**
     * Generate example configuration file
     * 
     * @return string JSON configuration example
     */
    public function generateExampleConfig(): string
    {
        $example = [
            '_comment' => 'PHP Link Validator Configuration',
            'scope' => ['internal', 'anchor'],
            'max_broken' => 10,
            'exclude_patterns' => ['*.backup.md', 'temp/*', 'node_modules/*'],
            'check_external' => false,
            'timeout' => 30,
            'max_depth' => 5,
            'include_hidden' => false,
            'case_sensitive' => false,
            'format' => 'console',
            'critical_files' => [
                'README.md',
                'docs/index.md',
                'docs/getting-started.md',
            ],
            'report_directory' => '.ai/reports/automated',
            'history_retention_days' => 30,
        ];
        
        return json_encode($example, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
    }
}
