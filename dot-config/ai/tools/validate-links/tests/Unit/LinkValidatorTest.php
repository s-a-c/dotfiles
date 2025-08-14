<?php
/**
 * Link Validator Unit Tests
 *
 * Tests for core link validation functionality, early termination, and progress tracking.
 */

declare(strict_types=1);

use SAC\ValidateLinks\Core\LinkValidator;
use SAC\ValidateLinks\Utils\Logger;
use SAC\ValidateLinks\Utils\SecurityValidator;

describe('LinkValidator', function () {
    beforeEach(function () {
        $this->logger = new Logger();
        $this->securityValidator = new SecurityValidator();
        $this->linkValidator = new LinkValidator($this->logger, $this->securityValidator);
    });

    describe('Statistics Collection', function () {
        it('collects comprehensive pre-validation statistics', function () {
            $testDir = FileSystemHelper::createTestDocumentationStructure();
            $files = glob($testDir . '/*.md');

            $stats = $this->linkValidator->collectStatistics($files, ['all']);

            expect($stats)->toHaveKeys([
                'total_directories',
                'total_files',
                'total_links',
                'links_by_type',
                'scoped_links',
                'directories',
                'file_sizes',
                'average_file_size'
            ])
            ->and($stats['total_files'])->toBe(count($files))
            ->and($stats['total_links'])->toBeGreaterThan(0)
            ->and($stats['links_by_type'])->toHaveKeys(['internal', 'anchor', 'cross_reference', 'external'])
            ->and($stats['scoped_links'])->toBe($stats['total_links']); // All scope includes everything
        });

        it('correctly filters scoped links in statistics', function () {
            $testDir = FileSystemHelper::createTestDocumentationStructure();
            $files = glob($testDir . '/*.md');

            $internalStats = $this->linkValidator->collectStatistics($files, ['internal']);
            $anchorStats = $this->linkValidator->collectStatistics($files, ['anchor']);
            $allStats = $this->linkValidator->collectStatistics($files, ['all']);

            expect($internalStats['scoped_links'])->toBe($internalStats['links_by_type']['internal'])
                ->and($anchorStats['scoped_links'])->toBe($anchorStats['links_by_type']['anchor'])
                ->and($allStats['scoped_links'])->toBe($allStats['total_links']);
        });

        it('handles empty file list gracefully', function () {
            $stats = $this->linkValidator->collectStatistics([], ['all']);

            expect($stats['total_files'])->toBe(0)
                ->and($stats['total_links'])->toBe(0)
                ->and($stats['scoped_links'])->toBe(0);
        });

        it('handles unreadable files gracefully', function () {
            $files = FileSystemHelper::createPermissionTestFiles();
            $fileList = array_values($files);

            $stats = $this->linkValidator->collectStatistics($fileList, ['all']);

            // Should not crash, even with unreadable files
            expect($stats)->toBeArray()
                ->and($stats['total_files'])->toBe(count($fileList));
        });
    });

    describe('Link Validation', function () {
        it('validates internal links correctly', function () {
            $testDir = FileSystemHelper::createTestDocumentationStructure();
            $files = glob($testDir . '/**/*.md', GLOB_BRACE);

            $results = $this->linkValidator->validateFiles(
                $files,
                ['internal'],
                false, // Don't check external
                false, // Case insensitive
                30,    // Timeout
                0,     // No max broken limit
                0      // No max files limit
            );

            expect($results)->toBeValidLinkValidationResult()
                ->and($results['summary'])->toHaveKeys([
                    'total_files', 'total_links', 'broken_links', 'success_rate',
                    'files_processed', 'total_files_available'
                ]);
        });

        it('categorizes links correctly', function () {
            $content = <<<'MD'
# Test Document

## Internal Links
[Same directory](other.md)
[Relative path](../parent.md)

## Anchor Links
[Section](#section)
[File with anchor](other.md#section)

## Cross-Reference Links
[Deep path](path/to/file.md)
[Cross ref with anchor](path/to/file.md#anchor)

## External Links
[Website](https://example.com)
[Email](mailto:test@example.com)

## Section
Content here.
MD;

            $testFile = createTempFile($content);

            $results = $this->linkValidator->validateFiles(
                [$testFile],
                ['all'],
                false,
                false,
                30,
                0,
                0
            );

            $fileResult = $results['results'][$testFile];

            // Should have links of different types
            expect($fileResult['internal_links'])->toBeGreaterThan(0)
                ->and($fileResult['anchor_links'])->toBeGreaterThan(0)
                ->and($fileResult['cross_reference_links'])->toBeGreaterThan(0)
                ->and($fileResult['external_links'])->toBeGreaterThan(0);
        });

        it('respects scope filtering', function () {
            $content = <<<'MD'
# Test Document
[Internal](other.md)
[Anchor](#section)
[Cross-ref](path/file.md)
[External](https://example.com)
## Section
Content.
MD;

            $testFile = createTempFile($content);

            // Test internal scope only
            $internalResults = $this->linkValidator->validateFiles(
                [$testFile], ['internal'], false, false, 30, 0, 0
            );

            // Test anchor scope only
            $anchorResults = $this->linkValidator->validateFiles(
                [$testFile], ['anchor'], false, false, 30, 0, 0
            );

            $internalFile = $internalResults['results'][$testFile];
            $anchorFile = $anchorResults['results'][$testFile];

            // Internal scope should only have internal links
            expect($internalFile['internal_links'])->toBeGreaterThan(0)
                ->and($internalFile['anchor_links'] ?? 0)->toBe(0)
                ->and($internalFile['cross_reference_links'] ?? 0)->toBe(0)
                ->and($internalFile['external_links'] ?? 0)->toBe(0);

            // Anchor scope should only have anchor links
            expect($anchorFile['anchor_links'])->toBeGreaterThan(0)
                ->and($anchorFile['internal_links'] ?? 0)->toBe(0)
                ->and($anchorFile['cross_reference_links'] ?? 0)->toBe(0)
                ->and($anchorFile['external_links'] ?? 0)->toBe(0);
        });
    });

    describe('Early Termination Logic', function () {
        it('terminates early when max_files limit is reached', function () {
            $testDir = FileSystemHelper::createTestDocumentationStructure();
            $files = glob($testDir . '/**/*.md', GLOB_BRACE);

            $maxFiles = 3;
            $results = $this->linkValidator->validateFiles(
                $files,
                ['all'],
                false,
                false,
                30,
                0,        // No broken links limit
                $maxFiles // Limit files
            );

            expect($results['summary']['files_processed'])->toBe($maxFiles)
                ->and($results['summary']['total_files_available'])->toBe(count($files))
                ->and($results['summary']['files_processed'])->toBeLessThan($results['summary']['total_files_available']);
        });

        it('terminates early when max_broken limit is reached', function () {
            // Create files with many broken links
            $brokenContent = <<<'MD'
# Broken Links
[Broken 1](nonexistent1.md)
[Broken 2](nonexistent2.md)
[Broken 3](nonexistent3.md)
[Broken 4](nonexistent4.md)
[Broken 5](nonexistent5.md)
MD;

            $files = [];
            for ($i = 0; $i < 5; $i++) {
                $files[] = createTempFile($brokenContent);
            }

            $maxBroken = 3;
            $results = $this->linkValidator->validateFiles(
                $files,
                ['internal'],
                false,
                false,
                30,
                $maxBroken, // Limit broken links
                0           // No files limit
            );

            // Should stop before processing all files due to broken links limit
            expect($results['summary']['broken_links'])->toBeGreaterThanOrEqual($maxBroken)
                ->and($results['summary']['files_processed'])->toBeLessThan(count($files));
        });

        it('handles both termination conditions independently', function () {
            $testDir = FileSystemHelper::createTestDocumentationStructure();
            $files = glob($testDir . '/**/*.md', GLOB_BRACE);

            $maxFiles = 2;
            $maxBroken = 10;

            $results = $this->linkValidator->validateFiles(
                $files,
                ['all'],
                false,
                false,
                30,
                $maxBroken,
                $maxFiles
            );

            // Should stop at max_files since it's lower
            expect($results['summary']['files_processed'])->toBe($maxFiles)
                ->and($results['summary']['broken_links'])->toBeLessThan($maxBroken);
        });

        it('processes all files when no limits are set', function () {
            $testDir = FileSystemHelper::createTestDocumentationStructure();
            $files = array_slice(glob($testDir . '/*.md'), 0, 3); // Just a few files for speed

            $results = $this->linkValidator->validateFiles(
                $files,
                ['all'],
                false,
                false,
                30,
                0, // No broken links limit
                0  // No files limit
            );

            expect($results['summary']['files_processed'])->toBe(count($files))
                ->and($results['summary']['total_files_available'])->toBe(count($files));
        });
    });

    describe('Progress Tracking', function () {
        it('tracks files and links processed correctly', function () {
            $testDir = FileSystemHelper::createTestDocumentationStructure();
            $files = array_slice(glob($testDir . '/*.md'), 0, 3);

            $results = $this->linkValidator->validateFiles(
                $files,
                ['all'],
                false,
                false,
                30,
                0,
                0
            );

            expect($results['summary']['files_processed'])->toBe(count($files))
                ->and($results['summary']['total_files_available'])->toBe(count($files))
                ->and($results['summary']['total_links'])->toBeGreaterThan(0);
        });

        it('provides accurate execution time', function () {
            $testFile = createTempFile('# Test\n[Link](other.md)\n');

            $startTime = microtime(true);
            $results = $this->linkValidator->validateFiles(
                [$testFile],
                ['all'],
                false,
                false,
                30,
                0,
                0
            );
            $endTime = microtime(true);

            $actualTime = $endTime - $startTime;
            $reportedTime = $results['execution_time'];

            expect($reportedTime)->toBeGreaterThan(0)
                ->and($reportedTime)->toBeLessThanOrEqual($actualTime + 0.1); // Allow small margin
        });
    });

    describe('Error Handling', function () {
        it('handles non-existent files gracefully', function () {
            $nonExistentFile = TEMP_DIR . '/non_existent.md';

            $results = $this->linkValidator->validateFiles(
                [$nonExistentFile],
                ['all'],
                false,
                false,
                30,
                0,
                0
            );

            // Should not crash, but should report the issue
            expect($results)->toBeArray()
                ->and($results['summary']['total_files'])->toBe(1);
        });

        it('handles corrupted files gracefully', function () {
            // Create a file with binary content
            $binaryFile = createTempFile(pack('H*', '89504e470d0a1a0a'), '.md');

            $results = $this->linkValidator->validateFiles(
                [$binaryFile],
                ['all'],
                false,
                false,
                30,
                0,
                0
            );

            // Should handle gracefully without crashing
            expect($results)->toBeArray();
        });

        it('handles very large files', function () {
            $largeContent = str_repeat("# Large File\n[Link](test.md)\n", 1000);
            $largeFile = createTempFile($largeContent);

            $results = $this->linkValidator->validateFiles(
                [$largeFile],
                ['internal'],
                false,
                false,
                30,
                0,
                0
            );

            expect($results)->toBeValidLinkValidationResult()
                ->and($results['summary']['total_links'])->toBe(1000);
        });
    });
});
