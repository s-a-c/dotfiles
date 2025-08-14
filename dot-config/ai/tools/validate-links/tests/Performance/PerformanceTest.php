<?php
/**
 * Performance Tests
 * 
 * Tests for performance benchmarks and scalability.
 */

declare(strict_types=1);

describe('Performance Tests', function () {
    describe('Validation Performance', function () {
        it('handles small file sets efficiently', function () {
            $files = LinkValidationHelper::createPerformanceTestFiles(5, 10);
            $linkValidator = getLinkValidator();
            
            $performance = LinkValidationHelper::measureValidationPerformance(
                $linkValidator,
                array_values($files),
                ['internal', 'anchor']
            );
            
            expect($performance['execution_time'])->toBeLessThan(2.0) // Should complete in under 2 seconds
                ->and($performance['memory_used'])->toBeLessThan(50 * 1024 * 1024) // Under 50MB
                ->and($performance['links_per_second'])->toBeGreaterThan(10); // At least 10 links/second
        });

        it('handles medium file sets efficiently', function () {
            $files = LinkValidationHelper::createPerformanceTestFiles(20, 20);
            $linkValidator = getLinkValidator();
            
            $performance = LinkValidationHelper::measureValidationPerformance(
                $linkValidator,
                array_values($files),
                ['internal', 'anchor']
            );
            
            expect($performance['execution_time'])->toBeLessThan(10.0) // Should complete in under 10 seconds
                ->and($performance['memory_used'])->toBeLessThan(100 * 1024 * 1024) // Under 100MB
                ->and($performance['links_per_second'])->toBeGreaterThan(5); // At least 5 links/second
        });

        it('early termination improves performance significantly', function () {
            $files = LinkValidationHelper::createPerformanceTestFiles(50, 20);
            $linkValidator = getLinkValidator();
            
            // Test with early termination
            $startTime = microtime(true);
            $limitedResults = $linkValidator->validateFiles(
                array_values($files),
                ['internal'],
                false,
                false,
                30,
                0,
                5 // Only process 5 files
            );
            $limitedTime = microtime(true) - $startTime;
            
            // Test without early termination (but limit to 10 files for comparison)
            $startTime = microtime(true);
            $unlimitedResults = $linkValidator->validateFiles(
                array_slice(array_values($files), 0, 10),
                ['internal'],
                false,
                false,
                30,
                0,
                0
            );
            $unlimitedTime = microtime(true) - $startTime;
            
            expect($limitedResults['summary']['files_processed'])->toBe(5)
                ->and($unlimitedResults['summary']['files_processed'])->toBe(10)
                ->and($limitedTime)->toBeLessThan($unlimitedTime); // Early termination should be faster
        });

        it('memory usage scales linearly with file count', function () {
            $smallFiles = LinkValidationHelper::createPerformanceTestFiles(5, 10);
            $largeFiles = LinkValidationHelper::createPerformanceTestFiles(10, 10);
            
            $linkValidator = getLinkValidator();
            
            $smallPerformance = LinkValidationHelper::measureValidationPerformance(
                $linkValidator,
                array_values($smallFiles),
                ['internal']
            );
            
            $largePerformance = LinkValidationHelper::measureValidationPerformance(
                $linkValidator,
                array_values($largeFiles),
                ['internal']
            );
            
            $memoryRatio = $largePerformance['memory_used'] / $smallPerformance['memory_used'];
            $fileRatio = count($largeFiles) / count($smallFiles);
            
            // Memory usage should scale roughly linearly (within 50% tolerance)
            expect($memoryRatio)->toBeLessThan($fileRatio * 1.5)
                ->and($memoryRatio)->toBeGreaterThan($fileRatio * 0.5);
        });
    });

    describe('Statistics Collection Performance', function () {
        it('collects statistics efficiently for large file sets', function () {
            $testDir = FixtureHelper::createCompleteTestProject();
            $files = glob($testDir . '/**/*.md', GLOB_BRACE);
            
            $linkValidator = getLinkValidator();
            
            $startTime = microtime(true);
            $stats = $linkValidator->collectStatistics($files, ['all']);
            $endTime = microtime(true);
            
            $executionTime = $endTime - $startTime;
            
            expect($stats['total_files'])->toBe(count($files))
                ->and($stats['total_links'])->toBeGreaterThan(0)
                ->and($executionTime)->toBeLessThan(5.0); // Should complete in under 5 seconds
        });

        it('statistics collection scales with file count', function () {
            $smallProject = FileSystemHelper::createTestDocumentationStructure();
            $smallFiles = glob($smallProject . '/*.md');
            
            $largeProject = FixtureHelper::createCompleteTestProject();
            $largeFiles = glob($largeProject . '/**/*.md', GLOB_BRACE);
            
            $linkValidator = getLinkValidator();
            
            // Measure small project
            $startTime = microtime(true);
            $smallStats = $linkValidator->collectStatistics($smallFiles, ['all']);
            $smallTime = microtime(true) - $startTime;
            
            // Measure large project
            $startTime = microtime(true);
            $largeStats = $linkValidator->collectStatistics($largeFiles, ['all']);
            $largeTime = microtime(true) - $startTime;
            
            $timeRatio = $largeTime / $smallTime;
            $fileRatio = count($largeFiles) / count($smallFiles);
            
            // Time should scale roughly linearly with file count
            expect($timeRatio)->toBeLessThan($fileRatio * 2.0) // Allow some overhead
                ->and($largeStats['total_files'])->toBe(count($largeFiles))
                ->and($smallStats['total_files'])->toBe(count($smallFiles));
        });
    });

    describe('Configuration Parsing Performance', function () {
        it('parses CLI arguments efficiently', function () {
            $argv = [
                'script.php',
                'file1.md',
                'file2.md',
                'file3.md',
                '--scope=internal,anchor,cross_reference,external',
                '--max-broken=100',
                '--max-files=50',
                '--timeout=60',
                '--format=json',
                '--check-external',
                '--case-sensitive',
                '--verbose'
            ];
            
            $parser = getCLIArgumentParser();
            
            $startTime = microtime(true);
            $config = $parser->parse($argv);
            $endTime = microtime(true);
            
            $executionTime = $endTime - $startTime;
            
            expect($config)->toBeValidConfiguration()
                ->and($executionTime)->toBeLessThan(0.1); // Should parse in under 100ms
        });

        it('handles large configuration files efficiently', function () {
            // Create a large configuration
            $largeConfig = ConfigurationHelper::getValidConfig();
            
            // Add many additional fields
            for ($i = 0; $i < 1000; $i++) {
                $largeConfig["field_{$i}"] = "value_{$i}";
            }
            
            $configFile = ConfigurationHelper::createTempConfigFile($largeConfig);
            
            $startTime = microtime(true);
            $loadedConfig = json_decode(file_get_contents($configFile), true);
            $endTime = microtime(true);
            
            $executionTime = $endTime - $startTime;
            
            expect($loadedConfig)->toBeArray()
                ->and($loadedConfig['scope'])->toBe($largeConfig['scope'])
                ->and($executionTime)->toBeLessThan(0.5); // Should load in under 500ms
        });
    });

    describe('Report Generation Performance', function () {
        it('generates console reports efficiently', function () {
            $testFiles = LinkValidationHelper::createKnownValidationTestFiles();
            $linkValidator = getLinkValidator();
            
            $results = $linkValidator->validateFiles(
                array_values($testFiles),
                ['all'],
                false,
                false,
                30,
                0,
                0
            );
            
            $reportGenerator = getReportGenerator();
            
            $startTime = microtime(true);
            $reportGenerator->generateReports(
                $results,
                'console',
                null,
                false,
                0
            );
            $endTime = microtime(true);
            
            $executionTime = $endTime - $startTime;
            
            expect($executionTime)->toBeLessThan(1.0); // Should generate in under 1 second
        });

        it('generates JSON reports efficiently', function () {
            $testFiles = LinkValidationHelper::createKnownValidationTestFiles();
            $linkValidator = getLinkValidator();
            
            $results = $linkValidator->validateFiles(
                array_values($testFiles),
                ['all'],
                false,
                false,
                30,
                0,
                0
            );
            
            $reportGenerator = getReportGenerator();
            $outputFile = TEMP_DIR . '/performance_test.json';
            
            $startTime = microtime(true);
            $reportGenerator->generateReports(
                $results,
                'json',
                $outputFile,
                false,
                0
            );
            $endTime = microtime(true);
            
            $executionTime = $endTime - $startTime;
            
            expect($executionTime)->toBeLessThan(1.0) // Should generate in under 1 second
                ->and(file_exists($outputFile))->toBeTrue();
            
            // Verify JSON is valid
            $jsonContent = json_decode(file_get_contents($outputFile), true);
            expect($jsonContent)->toBeArray();
        });
    });

    describe('Memory Usage Tests', function () {
        it('maintains reasonable memory usage during validation', function () {
            $files = LinkValidationHelper::createPerformanceTestFiles(10, 50);
            $linkValidator = getLinkValidator();
            
            $initialMemory = memory_get_usage(true);
            
            $results = $linkValidator->validateFiles(
                array_values($files),
                ['all'],
                false,
                false,
                30,
                0,
                0
            );
            
            $finalMemory = memory_get_usage(true);
            $memoryUsed = $finalMemory - $initialMemory;
            
            // Should use less than 100MB for this test
            expect($memoryUsed)->toBeLessThan(100 * 1024 * 1024)
                ->and($results)->toBeValidLinkValidationResult();
        });

        it('memory usage does not grow excessively with file count', function () {
            $linkValidator = getLinkValidator();
            
            // Test with 5 files
            $smallFiles = LinkValidationHelper::createPerformanceTestFiles(5, 10);
            $initialMemory = memory_get_usage(true);
            $linkValidator->validateFiles(array_values($smallFiles), ['internal'], false, false, 30, 0, 0);
            $smallMemory = memory_get_usage(true) - $initialMemory;
            
            // Reset memory baseline
            gc_collect_cycles();
            
            // Test with 15 files (3x more)
            $largeFiles = LinkValidationHelper::createPerformanceTestFiles(15, 10);
            $initialMemory = memory_get_usage(true);
            $linkValidator->validateFiles(array_values($largeFiles), ['internal'], false, false, 30, 0, 0);
            $largeMemory = memory_get_usage(true) - $initialMemory;
            
            $memoryRatio = $largeMemory / $smallMemory;
            
            // Memory usage should not grow more than 5x for 3x more files
            expect($memoryRatio)->toBeLessThan(5.0);
        });
    });
});
