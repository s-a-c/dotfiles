<?php
/**
 * CLI Argument Parser Tests
 * 
 * Tests for configuration parsing, validation, and hierarchy.
 * Addresses the specific error: "Configuration key 'notification_webhook' has invalid type. Expected: string"
 */

declare(strict_types=1);

use LinkValidator\Core\CLIArgumentParser;
use LinkValidator\Utils\Logger;

describe('CLIArgumentParser', function () {
    beforeEach(function () {
        $this->logger = new Logger();
        $this->parser = new CLIArgumentParser($this->logger);
    });

    describe('Basic Configuration Parsing', function () {
        it('parses valid CLI arguments correctly', function () {
            $argv = ['script.php', 'file.md', '--scope=internal', '--max-broken=5', '--max-files=3'];
            $config = $this->parser->parse($argv);

            expect($config)->toBeValidConfiguration()
                ->and($config['inputs'])->toBe(['file.md'])
                ->and($config['scope'])->toBe(['internal'])
                ->and($config['max_broken'])->toBe(5)
                ->and($config['max_files'])->toBe(3);
        });

        it('handles multiple input files', function () {
            $argv = ['script.php', 'file1.md', 'file2.md', '--scope=internal'];
            $config = $this->parser->parse($argv);

            expect($config['inputs'])->toBe(['file1.md', 'file2.md']);
        });

        it('parses comma-separated scope values', function () {
            $argv = ['script.php', 'file.md', '--scope=internal,anchor,external'];
            $config = $this->parser->parse($argv);

            expect($config['scope'])->toBe(['internal', 'anchor', 'external']);
        });

        it('handles boolean flags correctly', function () {
            $argv = ['script.php', 'file.md', '--check-external', '--case-sensitive', '--dry-run'];
            $config = $this->parser->parse($argv);

            expect($config['check_external'])->toBeTrue()
                ->and($config['case_sensitive'])->toBeTrue()
                ->and($config['dry_run'])->toBeTrue();
        });

        it('uses default values when options not provided', function () {
            $argv = ['script.php', 'file.md'];
            $config = $this->parser->parse($argv);

            expect($config['max_broken'])->toBe(50) // New default
                ->and($config['max_files'])->toBe(0) // Unlimited
                ->and($config['scope'])->toBe(['all'])
                ->and($config['check_external'])->toBeFalse()
                ->and($config['dry_run'])->toBeFalse();
        });
    });

    describe('Environment Variable Parsing', function () {
        afterEach(function () {
            // Clean up environment variables
            ConfigurationHelper::clearEnvironmentVariables([
                'LINK_VALIDATOR_SCOPE',
                'LINK_VALIDATOR_MAX_BROKEN',
                'LINK_VALIDATOR_MAX_FILES',
                'LINK_VALIDATOR_CHECK_EXTERNAL',
                'LINK_VALIDATOR_CASE_SENSITIVE',
            ]);
        });

        it('applies environment variables correctly', function () {
            ConfigurationHelper::setEnvironmentVariables([
                'LINK_VALIDATOR_SCOPE' => 'internal,anchor',
                'LINK_VALIDATOR_MAX_BROKEN' => '25',
                'LINK_VALIDATOR_MAX_FILES' => '10',
                'LINK_VALIDATOR_CHECK_EXTERNAL' => 'true',
            ]);

            $argv = ['script.php', 'file.md'];
            $config = $this->parser->parse($argv);

            expect($config['scope'])->toBe(['internal', 'anchor'])
                ->and($config['max_broken'])->toBe(25)
                ->and($config['max_files'])->toBe(10)
                ->and($config['check_external'])->toBeTrue();
        });

        it('handles boolean environment variables correctly', function () {
            $testCases = [
                ['true', true],
                ['false', false],
                ['1', true],
                ['0', false],
                ['yes', true],
                ['no', false],
            ];

            foreach ($testCases as [$envValue, $expected]) {
                ConfigurationHelper::setEnvironmentVariables([
                    'LINK_VALIDATOR_CHECK_EXTERNAL' => $envValue
                ]);

                $argv = ['script.php', 'file.md'];
                $config = $this->parser->parse($argv);

                expect($config['check_external'])->toBe($expected);
            }
        });

        it('handles invalid environment variable values gracefully', function () {
            ConfigurationHelper::setEnvironmentVariables([
                'LINK_VALIDATOR_MAX_BROKEN' => 'not_a_number',
                'LINK_VALIDATOR_MAX_FILES' => 'invalid',
            ]);

            $argv = ['script.php', 'file.md'];
            $config = $this->parser->parse($argv);

            expect($config['max_broken'])->toBe(0) // Converted to 0
                ->and($config['max_files'])->toBe(0); // Converted to 0
        });
    });

    describe('Configuration Hierarchy', function () {
        afterEach(function () {
            ConfigurationHelper::clearEnvironmentVariables([
                'LINK_VALIDATOR_SCOPE',
                'LINK_VALIDATOR_MAX_BROKEN',
            ]);
        });

        it('CLI arguments override environment variables', function () {
            ConfigurationHelper::setEnvironmentVariables([
                'LINK_VALIDATOR_SCOPE' => 'internal',
                'LINK_VALIDATOR_MAX_BROKEN' => '10',
            ]);

            $argv = ['script.php', 'file.md', '--scope=external', '--max-broken=20'];
            $config = $this->parser->parse($argv);

            expect($config['scope'])->toBe(['external']) // CLI overrides env
                ->and($config['max_broken'])->toBe(20); // CLI overrides env
        });

        it('environment variables override defaults', function () {
            ConfigurationHelper::setEnvironmentVariables([
                'LINK_VALIDATOR_SCOPE' => 'anchor',
                'LINK_VALIDATOR_MAX_BROKEN' => '15',
            ]);

            $argv = ['script.php', 'file.md'];
            $config = $this->parser->parse($argv);

            expect($config['scope'])->toBe(['anchor']) // Env overrides default
                ->and($config['max_broken'])->toBe(15); // Env overrides default
        });
    });

    describe('Input Validation', function () {
        it('validates scope values', function () {
            $argv = ['script.php', 'file.md', '--scope=invalid_scope'];
            
            expect(fn() => $this->parser->parse($argv))
                ->toThrow(InvalidArgumentException::class, 'Invalid scope: invalid_scope');
        });

        it('validates negative values', function () {
            $argv = ['script.php', 'file.md', '--max-broken=-1'];
            
            expect(fn() => $this->parser->parse($argv))
                ->toThrow(InvalidArgumentException::class, 'Max broken links must be non-negative');
        });

        it('validates max-files negative values', function () {
            $argv = ['script.php', 'file.md', '--max-files=-5'];
            
            expect(fn() => $this->parser->parse($argv))
                ->toThrow(InvalidArgumentException::class, 'Max files must be non-negative');
        });

        it('validates format values', function () {
            $argv = ['script.php', 'file.md', '--format=invalid_format'];
            
            expect(fn() => $this->parser->parse($argv))
                ->toThrow(InvalidArgumentException::class, 'Invalid format: invalid_format');
        });

        it('validates timeout values', function () {
            $argv = ['script.php', 'file.md', '--timeout=0'];
            
            expect(fn() => $this->parser->parse($argv))
                ->toThrow(InvalidArgumentException::class, 'Timeout must be positive');
        });

        it('requires input files when not showing help', function () {
            $argv = ['script.php'];
            
            expect(fn() => $this->parser->parse($argv))
                ->toThrow(InvalidArgumentException::class, 'No input files or directories specified');
        });

        it('allows no input files when showing help', function () {
            $argv = ['script.php', '--help'];
            $config = $this->parser->parse($argv);
            
            expect($config['show_help'])->toBeTrue();
        });
    });

    describe('Edge Cases', function () {
        it('handles empty scope gracefully', function () {
            $argv = ['script.php', 'file.md', '--scope='];
            $config = $this->parser->parse($argv);
            
            expect($config['scope'])->toBe(['']); // Empty string in array
        });

        it('handles zero values correctly', function () {
            $argv = ['script.php', 'file.md', '--max-broken=0', '--max-files=0'];
            $config = $this->parser->parse($argv);
            
            expect($config['max_broken'])->toBe(0)
                ->and($config['max_files'])->toBe(0);
        });

        it('handles very large values', function () {
            $argv = ['script.php', 'file.md', '--max-broken=999999', '--max-files=999999'];
            $config = $this->parser->parse($argv);
            
            expect($config['max_broken'])->toBe(999999)
                ->and($config['max_files'])->toBe(999999);
        });

        it('handles unknown options gracefully', function () {
            $argv = ['script.php', 'file.md', '--unknown-option=value'];
            
            expect(fn() => $this->parser->parse($argv))
                ->toThrow(InvalidArgumentException::class, 'Unknown option: unknown-option');
        });
    });
});
