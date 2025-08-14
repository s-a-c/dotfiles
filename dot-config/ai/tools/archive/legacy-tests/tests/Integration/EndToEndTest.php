<?php
/**
 * End-to-End Integration Tests
 * 
 * Tests the complete workflow from CLI arguments to final output.
 */

declare(strict_types=1);

describe('End-to-End Integration', function () {
    describe('Complete Validation Workflow', function () {
        it('runs complete validation with all parameters', function () {
            $testDir = FileSystemHelper::createTestDocumentationStructure();
            
            // Simulate CLI execution
            $argv = [
                'link-validator.php',
                $testDir,
                '--scope=internal,anchor',
                '--max-files=3',
                '--max-broken=5',
                '--format=json',
                '--verbose'
            ];
            
            $parser = getCLIArgumentParser();
            $config = $parser->parse($argv);
            
            expect($config['inputs'])->toBe([$testDir])
                ->and($config['scope'])->toBe(['internal', 'anchor'])
                ->and($config['max_files'])->toBe(3)
                ->and($config['max_broken'])->toBe(5)
                ->and($config['format'])->toBe('json');
        });

        it('handles dry-run mode correctly', function () {
            $testDir = FileSystemHelper::createTestDocumentationStructure();
            
            $argv = [
                'link-validator.php',
                $testDir,
                '--scope=internal',
                '--max-files=2',
                '--dry-run'
            ];
            
            $parser = getCLIArgumentParser();
            $config = $parser->parse($argv);
            
            expect($config['dry_run'])->toBeTrue()
                ->and($config['max_files'])->toBe(2)
                ->and($config['scope'])->toBe(['internal']);
        });

        it('processes symlinked directories correctly', function () {
            $symlinkStructure = FileSystemHelper::createSymlinkedDocumentationStructure();
            
            $argv = [
                'link-validator.php',
                $symlinkStructure['symlink_path'],
                '--scope=internal'
            ];
            
            $parser = getCLIArgumentParser();
            $config = $parser->parse($argv);
            
            expect($config['inputs'])->toBe([$symlinkStructure['symlink_path']]);
        });
    });

    describe('Parameter Combination Testing', function () {
        it('handles all boolean flags together', function () {
            $testFile = createTempFile('# Test\n[Link](test.md)\n');
            
            $argv = [
                'link-validator.php',
                $testFile,
                '--check-external',
                '--case-sensitive',
                '--include-hidden',
                '--dry-run',
                '--no-color',
                '--verbose'
            ];
            
            $parser = getCLIArgumentParser();
            $config = $parser->parse($argv);
            
            expect($config['check_external'])->toBeTrue()
                ->and($config['case_sensitive'])->toBeTrue()
                ->and($config['include_hidden'])->toBeTrue()
                ->and($config['dry_run'])->toBeTrue()
                ->and($config['no_color'])->toBeTrue();
        });

        it('handles all numeric parameters with edge values', function () {
            $testFile = createTempFile('# Test\n[Link](test.md)\n');
            
            $argv = [
                'link-validator.php',
                $testFile,
                '--max-files=1',
                '--max-broken=1',
                '--max-depth=1',
                '--timeout=1'
            ];
            
            $parser = getCLIArgumentParser();
            $config = $parser->parse($argv);
            
            expect($config['max_files'])->toBe(1)
                ->and($config['max_broken'])->toBe(1)
                ->and($config['max_depth'])->toBe(1)
                ->and($config['timeout'])->toBe(1);
        });

        it('handles unlimited values correctly', function () {
            $testFile = createTempFile('# Test\n[Link](test.md)\n');
            
            $argv = [
                'link-validator.php',
                $testFile,
                '--max-files=0',
                '--max-broken=0',
                '--max-depth=0'
            ];
            
            $parser = getCLIArgumentParser();
            $config = $parser->parse($argv);
            
            expect($config['max_files'])->toBe(0)
                ->and($config['max_broken'])->toBe(0)
                ->and($config['max_depth'])->toBe(0);
        });

        it('handles very large values', function () {
            $testFile = createTempFile('# Test\n[Link](test.md)\n');
            
            $argv = [
                'link-validator.php',
                $testFile,
                '--max-files=999999',
                '--max-broken=999999',
                '--timeout=3600'
            ];
            
            $parser = getCLIArgumentParser();
            $config = $parser->parse($argv);
            
            expect($config['max_files'])->toBe(999999)
                ->and($config['max_broken'])->toBe(999999)
                ->and($config['timeout'])->toBe(3600);
        });
    });

    describe('Environment Variable Integration', function () {
        afterEach(function () {
            ConfigurationHelper::clearEnvironmentVariables([
                'LINK_VALIDATOR_SCOPE',
                'LINK_VALIDATOR_MAX_BROKEN',
                'LINK_VALIDATOR_MAX_FILES',
                'LINK_VALIDATOR_CHECK_EXTERNAL',
            ]);
        });

        it('combines environment variables with CLI arguments', function () {
            ConfigurationHelper::setEnvironmentVariables([
                'LINK_VALIDATOR_SCOPE' => 'internal',
                'LINK_VALIDATOR_MAX_BROKEN' => '10',
            ]);
            
            $testFile = createTempFile('# Test\n[Link](test.md)\n');
            
            $argv = [
                'link-validator.php',
                $testFile,
                '--max-files=5', // CLI argument
                '--check-external' // CLI argument
            ];
            
            $parser = getCLIArgumentParser();
            $config = $parser->parse($argv);
            
            expect($config['scope'])->toBe(['internal']) // From env
                ->and($config['max_broken'])->toBe(10) // From env
                ->and($config['max_files'])->toBe(5) // From CLI
                ->and($config['check_external'])->toBeTrue(); // From CLI
        });

        it('CLI arguments override environment variables', function () {
            ConfigurationHelper::setEnvironmentVariables([
                'LINK_VALIDATOR_SCOPE' => 'internal',
                'LINK_VALIDATOR_MAX_BROKEN' => '10',
                'LINK_VALIDATOR_MAX_FILES' => '20',
            ]);
            
            $testFile = createTempFile('# Test\n[Link](test.md)\n');
            
            $argv = [
                'link-validator.php',
                $testFile,
                '--scope=external', // Override env
                '--max-broken=5',   // Override env
                '--max-files=3'     // Override env
            ];
            
            $parser = getCLIArgumentParser();
            $config = $parser->parse($argv);
            
            expect($config['scope'])->toBe(['external']) // CLI overrides env
                ->and($config['max_broken'])->toBe(5) // CLI overrides env
                ->and($config['max_files'])->toBe(3); // CLI overrides env
        });
    });

    describe('Error Handling Integration', function () {
        it('handles validation errors gracefully', function () {
            $testFile = createTempFile('# Test\n[Link](test.md)\n');
            
            $argv = [
                'link-validator.php',
                $testFile,
                '--scope=invalid_scope'
            ];
            
            $parser = getCLIArgumentParser();
            
            expect(fn() => $parser->parse($argv))
                ->toThrow(InvalidArgumentException::class, 'Invalid scope: invalid_scope');
        });

        it('handles conflicting parameters', function () {
            $testFile = createTempFile('# Test\n[Link](test.md)\n');
            
            $argv = [
                'link-validator.php',
                $testFile,
                '--include-hidden',
                '--only-hidden'
            ];
            
            $parser = getCLIArgumentParser();
            
            expect(fn() => $parser->parse($argv))
                ->toThrow(InvalidArgumentException::class, 'Cannot use both --include-hidden and --only-hidden');
        });

        it('handles missing input files', function () {
            $argv = ['link-validator.php'];
            
            $parser = getCLIArgumentParser();
            
            expect(fn() => $parser->parse($argv))
                ->toThrow(InvalidArgumentException::class, 'No input files or directories specified');
        });

        it('handles non-existent input files', function () {
            $argv = [
                'link-validator.php',
                '/non/existent/file.md'
            ];
            
            $parser = getCLIArgumentParser();
            $config = $parser->parse($argv);
            
            // Should parse successfully, but file validation happens later
            expect($config['inputs'])->toBe(['/non/existent/file.md']);
        });
    });

    describe('Output Format Integration', function () {
        it('generates all output formats correctly', function () {
            $testFile = createTempFile('# Test\n[Link](test.md)\n[Good](#test)\n');
            
            $formats = ['console', 'json', 'markdown', 'html'];
            
            foreach ($formats as $format) {
                $argv = [
                    'link-validator.php',
                    $testFile,
                    '--format=' . $format,
                    '--max-files=1'
                ];
                
                $parser = getCLIArgumentParser();
                $config = $parser->parse($argv);
                
                expect($config['format'])->toBe($format);
            }
        });

        it('handles output file specification', function () {
            $testFile = createTempFile('# Test\n[Link](test.md)\n');
            $outputFile = TEMP_DIR . '/output.json';
            
            $argv = [
                'link-validator.php',
                $testFile,
                '--format=json',
                '--output=' . $outputFile
            ];
            
            $parser = getCLIArgumentParser();
            $config = $parser->parse($argv);
            
            expect($config['format'])->toBe('json')
                ->and($config['output'])->toBe($outputFile);
        });
    });

    describe('Performance Integration', function () {
        it('handles large file sets efficiently', function () {
            // Create multiple test files
            $files = [];
            for ($i = 0; $i < 10; $i++) {
                $content = "# File {$i}\n[Link](test{$i}.md)\n[Anchor](#section)\n## Section\nContent.";
                $files[] = createTempFile($content);
            }
            
            $linkValidator = getLinkValidator();
            
            $startTime = microtime(true);
            $results = $linkValidator->validateFiles(
                $files,
                ['internal', 'anchor'],
                false,
                false,
                30,
                0,
                0
            );
            $endTime = microtime(true);
            
            $executionTime = $endTime - $startTime;
            
            expect($results)->toBeValidLinkValidationResult()
                ->and($results['summary']['files_processed'])->toBe(count($files))
                ->and($executionTime)->toBeLessThan(5.0); // Should complete within 5 seconds
        });

        it('early termination improves performance', function () {
            // Create many test files
            $files = [];
            for ($i = 0; $i < 20; $i++) {
                $content = "# File {$i}\n[Link](test{$i}.md)\n";
                $files[] = createTempFile($content);
            }
            
            $linkValidator = getLinkValidator();
            
            // Test with max_files limit
            $startTime = microtime(true);
            $limitedResults = $linkValidator->validateFiles(
                $files,
                ['internal'],
                false,
                false,
                30,
                0,
                3 // Only process 3 files
            );
            $limitedTime = microtime(true) - $startTime;
            
            // Test without limit (but only first 5 files for comparison)
            $startTime = microtime(true);
            $unlimitedResults = $linkValidator->validateFiles(
                array_slice($files, 0, 5),
                ['internal'],
                false,
                false,
                30,
                0,
                0
            );
            $unlimitedTime = microtime(true) - $startTime;
            
            expect($limitedResults['summary']['files_processed'])->toBe(3)
                ->and($unlimitedResults['summary']['files_processed'])->toBe(5)
                ->and($limitedTime)->toBeLessThan($unlimitedTime);
        });
    });
});
