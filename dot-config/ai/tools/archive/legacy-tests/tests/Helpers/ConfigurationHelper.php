<?php
/**
 * Configuration Test Helper
 * 
 * Provides utilities for testing configuration parsing, validation, and hierarchy.
 */

declare(strict_types=1);

class ConfigurationHelper
{
    /**
     * Generate valid configuration data
     */
    public static function getValidConfig(): array
    {
        return [
            'scope' => ['internal', 'anchor'],
            'max_broken' => 10,
            'max_files' => 5,
            'timeout' => 30,
            'format' => 'console',
            'check_external' => false,
            'case_sensitive' => false,
            'max_depth' => 5,
            'exclude_patterns' => ['*.tmp', 'temp/*'],
            'include_hidden' => false,
            'only_hidden' => false,
            'no_color' => false,
            'dry_run' => false,
        ];
    }

    /**
     * Generate configuration with invalid types
     */
    public static function getInvalidTypeConfig(): array
    {
        return [
            'scope' => 'invalid_string_should_be_array',
            'max_broken' => 'invalid_string_should_be_int',
            'max_files' => -1, // Invalid negative value
            'timeout' => 'invalid_string_should_be_int',
            'format' => 123, // Invalid int should be string
            'check_external' => 'invalid_string_should_be_bool',
            'case_sensitive' => 'yes', // Invalid string should be bool
            'exclude_patterns' => 'invalid_string_should_be_array',
        ];
    }

    /**
     * Generate configuration with null values
     */
    public static function getNullValueConfig(): array
    {
        return [
            'scope' => null,
            'max_broken' => null,
            'max_files' => null,
            'timeout' => null,
            'format' => null,
            'check_external' => null,
            'notification_webhook' => null, // This caused the original error
            'output_file' => null,
        ];
    }

    /**
     * Generate configuration with missing required keys
     */
    public static function getIncompleteConfig(): array
    {
        return [
            'max_broken' => 10,
            // Missing scope, format, etc.
        ];
    }

    /**
     * Generate configuration with edge case values
     */
    public static function getEdgeCaseConfig(): array
    {
        return [
            'scope' => [], // Empty array
            'max_broken' => 0, // Zero value
            'max_files' => 999999, // Very large value
            'timeout' => 1, // Minimum value
            'format' => '', // Empty string
            'exclude_patterns' => [''], // Array with empty string
        ];
    }

    /**
     * Generate malformed JSON strings
     */
    public static function getMalformedJsonStrings(): array
    {
        return [
            '{"scope": ["internal"', // Missing closing bracket and brace
            '{"scope": ["internal"],}', // Trailing comma
            '{scope: ["internal"]}', // Unquoted key
            '{"scope": [internal]}', // Unquoted string value
            '{"scope": ["internal"]; "format": "console"}', // Semicolon instead of comma
            '', // Empty string
            'not json at all', // Plain text
            '{"scope": ["internal"], "max_broken": 01}', // Leading zero in number
        ];
    }

    /**
     * Generate environment variable test cases
     */
    public static function getEnvironmentVariableTestCases(): array
    {
        return [
            'valid_scope' => [
                'LINK_VALIDATOR_SCOPE' => 'internal,anchor',
                'expected' => ['internal', 'anchor']
            ],
            'valid_max_broken' => [
                'LINK_VALIDATOR_MAX_BROKEN' => '25',
                'expected' => 25
            ],
            'valid_max_files' => [
                'LINK_VALIDATOR_MAX_FILES' => '10',
                'expected' => 10
            ],
            'valid_boolean_true' => [
                'LINK_VALIDATOR_CHECK_EXTERNAL' => 'true',
                'expected' => true
            ],
            'valid_boolean_false' => [
                'LINK_VALIDATOR_CHECK_EXTERNAL' => 'false',
                'expected' => false
            ],
            'valid_boolean_1' => [
                'LINK_VALIDATOR_CHECK_EXTERNAL' => '1',
                'expected' => true
            ],
            'valid_boolean_0' => [
                'LINK_VALIDATOR_CHECK_EXTERNAL' => '0',
                'expected' => false
            ],
            'invalid_scope_empty' => [
                'LINK_VALIDATOR_SCOPE' => '',
                'expected' => ['']
            ],
            'invalid_number_string' => [
                'LINK_VALIDATOR_MAX_BROKEN' => 'not_a_number',
                'expected' => 0
            ],
        ];
    }

    /**
     * Generate CLI argument test cases
     */
    public static function getCLIArgumentTestCases(): array
    {
        return [
            'basic_options' => [
                'argv' => ['script.php', 'file.md', '--scope=internal', '--max-broken=5'],
                'expected' => [
                    'inputs' => ['file.md'],
                    'scope' => ['internal'],
                    'max_broken' => 5
                ]
            ],
            'multiple_scopes' => [
                'argv' => ['script.php', 'file.md', '--scope=internal,anchor,external'],
                'expected' => [
                    'scope' => ['internal', 'anchor', 'external']
                ]
            ],
            'boolean_flags' => [
                'argv' => ['script.php', 'file.md', '--check-external', '--case-sensitive', '--dry-run'],
                'expected' => [
                    'check_external' => true,
                    'case_sensitive' => true,
                    'dry_run' => true
                ]
            ],
            'mixed_options_and_files' => [
                'argv' => ['script.php', 'file1.md', '--scope=internal', 'file2.md', '--max-files=3'],
                'expected' => [
                    'inputs' => ['file1.md', 'file2.md'],
                    'scope' => ['internal'],
                    'max_files' => 3
                ]
            ],
            'verbosity_levels' => [
                'argv' => ['script.php', 'file.md', '--verbose'],
                'expected' => [
                    'verbosity' => 2 // Logger::VERBOSE
                ]
            ],
        ];
    }

    /**
     * Generate configuration hierarchy test cases
     */
    public static function getConfigurationHierarchyTestCases(): array
    {
        return [
            'env_only' => [
                'env' => ['LINK_VALIDATOR_SCOPE' => 'internal'],
                'config_file' => null,
                'cli_args' => ['script.php', 'file.md'],
                'expected_scope' => ['internal']
            ],
            'config_file_only' => [
                'env' => [],
                'config_file' => ['scope' => ['anchor']],
                'cli_args' => ['script.php', 'file.md'],
                'expected_scope' => ['anchor']
            ],
            'cli_only' => [
                'env' => [],
                'config_file' => null,
                'cli_args' => ['script.php', 'file.md', '--scope=external'],
                'expected_scope' => ['external']
            ],
            'env_and_config_file' => [
                'env' => ['LINK_VALIDATOR_SCOPE' => 'internal'],
                'config_file' => ['scope' => ['anchor']],
                'cli_args' => ['script.php', 'file.md'],
                'expected_scope' => ['anchor'] // Config file overrides env
            ],
            'all_three_sources' => [
                'env' => ['LINK_VALIDATOR_SCOPE' => 'internal'],
                'config_file' => ['scope' => ['anchor']],
                'cli_args' => ['script.php', 'file.md', '--scope=external'],
                'expected_scope' => ['external'] // CLI overrides all
            ],
        ];
    }

    /**
     * Create a temporary config file with given content
     */
    public static function createTempConfigFile(array $config): string
    {
        $filename = TEMP_DIR . '/' . uniqid('config_') . '.json';
        file_put_contents($filename, json_encode($config, JSON_PRETTY_PRINT));
        return $filename;
    }

    /**
     * Create a malformed config file
     */
    public static function createMalformedConfigFile(string $content): string
    {
        $filename = TEMP_DIR . '/' . uniqid('malformed_config_') . '.json';
        file_put_contents($filename, $content);
        return $filename;
    }

    /**
     * Set environment variables for testing
     */
    public static function setEnvironmentVariables(array $vars): void
    {
        foreach ($vars as $key => $value) {
            putenv("{$key}={$value}");
        }
    }

    /**
     * Clear environment variables
     */
    public static function clearEnvironmentVariables(array $keys): void
    {
        foreach ($keys as $key) {
            putenv($key);
        }
    }
}
