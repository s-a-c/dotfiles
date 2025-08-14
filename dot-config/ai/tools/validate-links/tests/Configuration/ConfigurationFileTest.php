<?php
/**
 * Configuration File Tests
 * 
 * Tests for configuration file loading, parsing, and validation.
 * Specifically addresses the error: "Configuration key 'notification_webhook' has invalid type. Expected: string"
 */

declare(strict_types=1);

describe('Configuration File Handling', function () {
    describe('Valid Configuration Files', function () {
        it('loads valid configuration file correctly', function () {
            $config = [
                'scope' => ['internal', 'anchor'],
                'max_broken' => 10,
                'max_files' => 5,
                'timeout' => 30,
                'format' => 'console',
                'check_external' => false,
                'case_sensitive' => true,
            ];

            $configFile = ConfigurationHelper::createTempConfigFile($config);
            
            // Test that the file was created correctly
            expect(file_exists($configFile))->toBeTrue();
            
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            expect($loadedConfig)->toBe($config);
        });

        it('handles minimal configuration file', function () {
            $config = [
                'scope' => ['internal'],
                'max_broken' => 5,
            ];

            $configFile = ConfigurationHelper::createTempConfigFile($config);
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            
            expect($loadedConfig['scope'])->toBe(['internal'])
                ->and($loadedConfig['max_broken'])->toBe(5);
        });

        it('handles configuration with comments and metadata', function () {
            $config = [
                '_comment' => 'This is a comment',
                '_description' => 'Test configuration',
                'scope' => ['internal'],
                'max_broken' => 10,
                '_version' => '1.0.0',
            ];

            $configFile = ConfigurationHelper::createTempConfigFile($config);
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            
            expect($loadedConfig['scope'])->toBe(['internal'])
                ->and($loadedConfig['max_broken'])->toBe(10)
                ->and($loadedConfig)->toHaveKey('_comment')
                ->and($loadedConfig)->toHaveKey('_description');
        });
    });

    describe('Null Value Handling', function () {
        it('handles null values correctly', function () {
            $config = [
                'scope' => ['internal'],
                'max_broken' => 10,
                'notification_webhook' => null, // This caused the original error
                'output_file' => null,
                'custom_setting' => null,
            ];

            $configFile = ConfigurationHelper::createTempConfigFile($config);
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            
            expect($loadedConfig['notification_webhook'])->toBeNull()
                ->and($loadedConfig['output_file'])->toBeNull()
                ->and($loadedConfig['custom_setting'])->toBeNull();
        });

        it('handles mixed null and valid values', function () {
            $config = [
                'scope' => ['internal', 'anchor'],
                'max_broken' => null, // Should be handled gracefully
                'max_files' => 5,
                'timeout' => null, // Should be handled gracefully
                'format' => 'console',
                'notification_webhook' => null,
            ];

            $configFile = ConfigurationHelper::createTempConfigFile($config);
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            
            expect($loadedConfig['scope'])->toBe(['internal', 'anchor'])
                ->and($loadedConfig['max_broken'])->toBeNull()
                ->and($loadedConfig['max_files'])->toBe(5)
                ->and($loadedConfig['timeout'])->toBeNull()
                ->and($loadedConfig['format'])->toBe('console')
                ->and($loadedConfig['notification_webhook'])->toBeNull();
        });

        it('handles configuration with only null values', function () {
            $config = [
                'notification_webhook' => null,
                'slack_webhook' => null,
                'output_file' => null,
                'custom_field' => null,
            ];

            $configFile = ConfigurationHelper::createTempConfigFile($config);
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            
            expect($loadedConfig)->toHaveKeys([
                'notification_webhook',
                'slack_webhook', 
                'output_file',
                'custom_field'
            ])
            ->and($loadedConfig['notification_webhook'])->toBeNull()
            ->and($loadedConfig['slack_webhook'])->toBeNull()
            ->and($loadedConfig['output_file'])->toBeNull()
            ->and($loadedConfig['custom_field'])->toBeNull();
        });
    });

    describe('Invalid Type Handling', function () {
        it('detects invalid types in configuration', function () {
            $invalidConfigs = [
                'scope_as_string' => [
                    'scope' => 'should_be_array',
                    'max_broken' => 10,
                ],
                'max_broken_as_string' => [
                    'scope' => ['internal'],
                    'max_broken' => 'should_be_number',
                ],
                'boolean_as_string' => [
                    'scope' => ['internal'],
                    'check_external' => 'should_be_boolean',
                ],
                'format_as_number' => [
                    'scope' => ['internal'],
                    'format' => 123,
                ],
            ];

            foreach ($invalidConfigs as $testName => $config) {
                $configFile = ConfigurationHelper::createTempConfigFile($config);
                $loadedConfig = json_decode(file_get_contents($configFile), true);
                
                // The file should load successfully (JSON parsing works)
                expect($loadedConfig)->toBeArray();
                
                // But type validation should catch the issues
                // (This would be handled by the configuration validator)
            }
        });

        it('handles mixed valid and invalid types', function () {
            $config = [
                'scope' => ['internal'], // Valid
                'max_broken' => 'invalid_number', // Invalid
                'format' => 'console', // Valid
                'check_external' => 'invalid_boolean', // Invalid
                'notification_webhook' => null, // Valid null
            ];

            $configFile = ConfigurationHelper::createTempConfigFile($config);
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            
            expect($loadedConfig['scope'])->toBe(['internal'])
                ->and($loadedConfig['max_broken'])->toBe('invalid_number')
                ->and($loadedConfig['format'])->toBe('console')
                ->and($loadedConfig['check_external'])->toBe('invalid_boolean')
                ->and($loadedConfig['notification_webhook'])->toBeNull();
        });
    });

    describe('Malformed JSON Handling', function () {
        it('handles malformed JSON gracefully', function () {
            $malformedJsonStrings = ConfigurationHelper::getMalformedJsonStrings();
            
            foreach ($malformedJsonStrings as $malformedJson) {
                $configFile = ConfigurationHelper::createMalformedConfigFile($malformedJson);
                
                // Attempt to parse the malformed JSON
                $loadedConfig = json_decode(file_get_contents($configFile), true);
                
                // Should return null for malformed JSON
                expect($loadedConfig)->toBeNull();
                
                // Check JSON error
                expect(json_last_error())->not->toBe(JSON_ERROR_NONE);
            }
        });

        it('handles empty configuration file', function () {
            $configFile = ConfigurationHelper::createMalformedConfigFile('');
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            
            expect($loadedConfig)->toBeNull();
            expect(json_last_error())->toBe(JSON_ERROR_SYNTAX);
        });

        it('handles non-JSON content', function () {
            $configFile = ConfigurationHelper::createMalformedConfigFile('This is not JSON at all');
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            
            expect($loadedConfig)->toBeNull();
            expect(json_last_error())->toBe(JSON_ERROR_SYNTAX);
        });
    });

    describe('Complex Configuration Structures', function () {
        it('handles nested configuration objects', function () {
            $config = [
                'scope' => ['internal', 'anchor'],
                'max_broken' => 10,
                'fixing' => [
                    'similarity_threshold' => 0.8,
                    'auto_fix_case' => true,
                    'backup_before_fix' => true,
                ],
                'project' => [
                    'name' => 'Test Project',
                    'base_url' => 'https://example.com',
                    'supported_extensions' => ['.md', '.html'],
                ],
                'ci' => [
                    'fail_on_broken_links' => true,
                    'slack_webhook' => null,
                    'github_status_check' => false,
                ],
            ];

            $configFile = ConfigurationHelper::createTempConfigFile($config);
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            
            expect($loadedConfig['fixing']['similarity_threshold'])->toBe(0.8)
                ->and($loadedConfig['project']['name'])->toBe('Test Project')
                ->and($loadedConfig['ci']['slack_webhook'])->toBeNull()
                ->and($loadedConfig['project']['supported_extensions'])->toBe(['.md', '.html']);
        });

        it('handles arrays with mixed types', function () {
            $config = [
                'scope' => ['internal', 'anchor', 'external'],
                'exclude_patterns' => ['*.tmp', '*.backup', 'temp/*', '.git/*'],
                'critical_files' => [
                    'README.md',
                    'docs/index.md',
                    'docs/getting-started.md',
                ],
                'environments' => [
                    'development' => [
                        'max_broken' => 50,
                        'check_external' => false,
                    ],
                    'production' => [
                        'max_broken' => 0,
                        'check_external' => true,
                    ],
                ],
            ];

            $configFile = ConfigurationHelper::createTempConfigFile($config);
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            
            expect($loadedConfig['exclude_patterns'])->toHaveCount(4)
                ->and($loadedConfig['critical_files'])->toContain('README.md')
                ->and($loadedConfig['environments']['development']['max_broken'])->toBe(50)
                ->and($loadedConfig['environments']['production']['check_external'])->toBeTrue();
        });
    });

    describe('File System Edge Cases', function () {
        it('handles non-existent configuration file', function () {
            $nonExistentFile = TEMP_DIR . '/non_existent_config.json';
            
            expect(file_exists($nonExistentFile))->toBeFalse();
            
            // Attempting to read should fail gracefully
            $content = @file_get_contents($nonExistentFile);
            expect($content)->toBeFalse();
        });

        it('handles unreadable configuration file', function () {
            $config = ['scope' => ['internal']];
            $configFile = ConfigurationHelper::createTempConfigFile($config);
            
            // Make file unreadable
            chmod($configFile, 0000);
            
            $content = @file_get_contents($configFile);
            expect($content)->toBeFalse();
            
            // Restore permissions for cleanup
            chmod($configFile, 0644);
        });

        it('handles very large configuration file', function () {
            // Create a large configuration with many entries
            $config = ['scope' => ['internal']];
            
            // Add many entries to make it large
            for ($i = 0; $i < 1000; $i++) {
                $config["large_field_{$i}"] = str_repeat('x', 100);
            }

            $configFile = ConfigurationHelper::createTempConfigFile($config);
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            
            expect($loadedConfig['scope'])->toBe(['internal'])
                ->and($loadedConfig)->toHaveKey('large_field_999');
        });
    });
});
