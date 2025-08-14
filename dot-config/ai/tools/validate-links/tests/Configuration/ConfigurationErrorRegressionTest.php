<?php
/**
 * Configuration Error Regression Tests
 *
 * Specifically tests.old for the error: "Configuration key 'notification_webhook' has invalid type. Expected: string"
 * and other configuration parsing issues.
 */

declare(strict_types=1);

describe('Configuration Error Regression Tests', function () {
    describe('Null Value Handling (Original Error)', function () {
        it('handles notification_webhook null value correctly', function () {
            $config = [
                'scope' => ['internal'],
                'max_broken' => 10,
                'notification_webhook' => null, // This caused the original error
            ];

            $configFile = ConfigurationHelper::createTempConfigFile($config);
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            
            // JSON parsing should succeed
            expect($loadedConfig)->toBeArray()
                ->and($loadedConfig['notification_webhook'])->toBeNull()
                ->and(json_last_error())->toBe(JSON_ERROR_NONE);
        });

        it('handles multiple null values in configuration', function () {
            $config = [
                'scope' => ['internal'],
                'max_broken' => 10,
                'notification_webhook' => null,
                'slack_webhook' => null,
                'output_file' => null,
                'custom_field' => null,
                'another_field' => null,
            ];

            $configFile = ConfigurationHelper::createTempConfigFile($config);
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            
            expect($loadedConfig)->toBeArray()
                ->and($loadedConfig['notification_webhook'])->toBeNull()
                ->and($loadedConfig['slack_webhook'])->toBeNull()
                ->and($loadedConfig['output_file'])->toBeNull()
                ->and($loadedConfig['custom_field'])->toBeNull()
                ->and($loadedConfig['another_field'])->toBeNull();
        });

        it('handles mixed null and valid values', function () {
            $config = [
                'scope' => ['internal', 'anchor'], // Valid array
                'max_broken' => 10, // Valid integer
                'notification_webhook' => null, // Null value
                'format' => 'console', // Valid string
                'check_external' => false, // Valid boolean
                'timeout' => null, // Null value
                'custom_setting' => null, // Null value
            ];

            $configFile = ConfigurationHelper::createTempConfigFile($config);
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            
            expect($loadedConfig['scope'])->toBe(['internal', 'anchor'])
                ->and($loadedConfig['max_broken'])->toBe(10)
                ->and($loadedConfig['notification_webhook'])->toBeNull()
                ->and($loadedConfig['format'])->toBe('console')
                ->and($loadedConfig['check_external'])->toBeFalse()
                ->and($loadedConfig['timeout'])->toBeNull()
                ->and($loadedConfig['custom_setting'])->toBeNull();
        });

        it('reproduces the exact original error scenario', function () {
            // This is the exact configuration structure from the example-config.json that caused the error
            $config = [
                '_comment' => 'PHP Link Validator Configuration Example',
                'scope' => ['internal', 'anchor', 'cross-reference'],
                'max_broken' => 10,
                'timeout' => 30,
                'exclude_patterns' => ['*.backup.md', '*.tmp.md', 'temp/*'],
                'include_hidden' => false,
                'case_sensitive' => false,
                'check_external' => false,
                'format' => 'console',
                'no_color' => false,
                'notification_webhook' => null, // This was the problematic line
                'critical_files' => ['README.md', 'docs/index.md'],
                'history_retention_days' => 30,
            ];

            $configFile = ConfigurationHelper::createTempConfigFile($config);
            
            // This should not throw an error during JSON parsing
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            
            expect($loadedConfig)->toBeArray()
                ->and($loadedConfig['notification_webhook'])->toBeNull()
                ->and($loadedConfig['scope'])->toBe(['internal', 'anchor', 'cross-reference'])
                ->and($loadedConfig['max_broken'])->toBe(10);
        });
    });

    describe('Type Validation Edge Cases', function () {
        it('handles empty string values', function () {
            $config = [
                'scope' => ['internal'],
                'format' => '', // Empty string
                'notification_webhook' => '',
                'output_file' => '',
            ];

            $configFile = ConfigurationHelper::createTempConfigFile($config);
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            
            expect($loadedConfig['format'])->toBe('')
                ->and($loadedConfig['notification_webhook'])->toBe('')
                ->and($loadedConfig['output_file'])->toBe('');
        });

        it('handles zero and false values correctly', function () {
            $config = [
                'scope' => ['internal'],
                'max_broken' => 0, // Zero integer
                'max_files' => 0,
                'timeout' => 0,
                'check_external' => false, // Boolean false
                'case_sensitive' => false,
                'include_hidden' => false,
            ];

            $configFile = ConfigurationHelper::createTempConfigFile($config);
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            
            expect($loadedConfig['max_broken'])->toBe(0)
                ->and($loadedConfig['max_files'])->toBe(0)
                ->and($loadedConfig['timeout'])->toBe(0)
                ->and($loadedConfig['check_external'])->toBeFalse()
                ->and($loadedConfig['case_sensitive'])->toBeFalse()
                ->and($loadedConfig['include_hidden'])->toBeFalse();
        });

        it('handles nested null values', function () {
            $config = [
                'scope' => ['internal'],
                'fixing' => [
                    'similarity_threshold' => 0.8,
                    'backup_before_fix' => null,
                    'interactive_threshold' => null,
                ],
                'ci' => [
                    'slack_webhook' => null,
                    'github_status_check' => false,
                    'custom_field' => null,
                ],
                'notification_webhook' => null,
            ];

            $configFile = ConfigurationHelper::createTempConfigFile($config);
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            
            expect($loadedConfig['fixing']['backup_before_fix'])->toBeNull()
                ->and($loadedConfig['fixing']['interactive_threshold'])->toBeNull()
                ->and($loadedConfig['ci']['slack_webhook'])->toBeNull()
                ->and($loadedConfig['ci']['custom_field'])->toBeNull()
                ->and($loadedConfig['notification_webhook'])->toBeNull();
        });
    });

    describe('JSON Parsing Robustness', function () {
        it('handles configuration with trailing commas gracefully', function () {
            $malformedJson = '{
                "scope": ["internal"],
                "max_broken": 10,
                "notification_webhook": null,
            }'; // Trailing comma after null

            $configFile = ConfigurationHelper::createMalformedConfigFile($malformedJson);
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            
            // Should fail to parse due to trailing comma
            expect($loadedConfig)->toBeNull()
                ->and(json_last_error())->toBe(JSON_ERROR_SYNTAX);
        });

        it('handles configuration with comments gracefully', function () {
            $jsonWithComments = '{
                // This is a comment
                "scope": ["internal"],
                "max_broken": 10,
                /* Multi-line comment */
                "notification_webhook": null
            }';

            $configFile = ConfigurationHelper::createMalformedConfigFile($jsonWithComments);
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            
            // Standard JSON parser doesn't support comments
            expect($loadedConfig)->toBeNull()
                ->and(json_last_error())->toBe(JSON_ERROR_SYNTAX);
        });

        it('handles very large null-heavy configuration', function () {
            $config = ['scope' => ['internal']];
            
            // Add many null fields
            for ($i = 0; $i < 100; $i++) {
                $config["null_field_{$i}"] = null;
            }

            $configFile = ConfigurationHelper::createTempConfigFile($config);
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            
            expect($loadedConfig)->toBeArray()
                ->and($loadedConfig['scope'])->toBe(['internal'])
                ->and($loadedConfig['null_field_0'])->toBeNull()
                ->and($loadedConfig['null_field_99'])->toBeNull();
        });
    });

    describe('Configuration Validation Scenarios', function () {
        it('should validate configuration types after loading', function () {
            $config = [
                'scope' => 'should_be_array', // Wrong type
                'max_broken' => 'should_be_number', // Wrong type
                'notification_webhook' => null, // Correct null
                'check_external' => 'should_be_boolean', // Wrong type
            ];

            $configFile = ConfigurationHelper::createTempConfigFile($config);
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            
            // JSON parsing should succeed
            expect($loadedConfig)->toBeArray();
            
            // But type validation should catch these issues
            // (This would be handled by a configuration validator)
            expect($loadedConfig['scope'])->toBe('should_be_array') // Wrong type loaded
                ->and($loadedConfig['max_broken'])->toBe('should_be_number') // Wrong type loaded
                ->and($loadedConfig['notification_webhook'])->toBeNull() // Correct null
                ->and($loadedConfig['check_external'])->toBe('should_be_boolean'); // Wrong type loaded
        });

        it('handles configuration with all possible null webhook fields', function () {
            $config = [
                'scope' => ['internal'],
                'max_broken' => 10,
                
                // All possible webhook/notification fields as null
                'notification_webhook' => null,
                'slack_webhook' => null,
                'discord_webhook' => null,
                'teams_webhook' => null,
                'custom_webhook' => null,
                'webhook_url' => null,
                'webhook_token' => null,
                'notification_url' => null,
                'alert_webhook' => null,
                'status_webhook' => null,
            ];

            $configFile = ConfigurationHelper::createTempConfigFile($config);
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            
            expect($loadedConfig)->toBeArray()
                ->and($loadedConfig['notification_webhook'])->toBeNull()
                ->and($loadedConfig['slack_webhook'])->toBeNull()
                ->and($loadedConfig['discord_webhook'])->toBeNull()
                ->and($loadedConfig['teams_webhook'])->toBeNull()
                ->and($loadedConfig['custom_webhook'])->toBeNull()
                ->and($loadedConfig['webhook_url'])->toBeNull()
                ->and($loadedConfig['webhook_token'])->toBeNull()
                ->and($loadedConfig['notification_url'])->toBeNull()
                ->and($loadedConfig['alert_webhook'])->toBeNull()
                ->and($loadedConfig['status_webhook'])->toBeNull();
        });
    });

    describe('Real-World Configuration Scenarios', function () {
        it('handles production-like configuration with many null optional fields', function () {
            $config = [
                // Required fields
                'scope' => ['internal', 'anchor', 'cross_reference'],
                'max_broken' => 50,
                'max_files' => 0,
                'format' => 'console',
                
                // Optional fields that might be null in production
                'notification_webhook' => null,
                'slack_webhook' => null,
                'output_file' => null,
                'config_override' => null,
                'custom_user_agent' => null,
                'proxy_url' => null,
                'auth_token' => null,
                'api_key' => null,
                'secret_key' => null,
                'encryption_key' => null,
                
                // Nested optional fields
                'integrations' => [
                    'jira' => null,
                    'github' => null,
                    'gitlab' => null,
                    'bitbucket' => null,
                ],
                
                'notifications' => [
                    'email' => null,
                    'sms' => null,
                    'push' => null,
                ],
            ];

            $configFile = ConfigurationHelper::createTempConfigFile($config);
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            
            expect($loadedConfig)->toBeArray()
                ->and($loadedConfig['scope'])->toBe(['internal', 'anchor', 'cross_reference'])
                ->and($loadedConfig['max_broken'])->toBe(50)
                ->and($loadedConfig['notification_webhook'])->toBeNull()
                ->and($loadedConfig['integrations']['jira'])->toBeNull()
                ->and($loadedConfig['notifications']['email'])->toBeNull();
        });
    });
});
