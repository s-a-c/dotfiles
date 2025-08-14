<?php
/**
 * Report Generation System
 *
 * Generates comprehensive validation reports in multiple formats including
 * JSON, Markdown, HTML, and console output with detailed statistics and
 * compatibility with existing Python toolchain.
 *
 * @package LinkValidator\Core
 */

declare(strict_types=1);

namespace LinkValidator\Core;

use LinkValidator\Utils\Logger;

/**
 * Multi-format report generator for validation results
 *
 * Provides comprehensive reporting capabilities with support for JSON, Markdown,
 * HTML, and console output formats, maintaining compatibility with existing tools.
 */
final class ReportGenerator
{
    private readonly Logger $logger;

    /**
     * Status emoji mapping for different formats
     */
    private const STATUS_EMOJIS = [
        'PASS' => '✅',
        'WARN' => '⚠️',
        'FAIL' => '❌',
    ];

    /**
     * ANSI color codes for console output
     */
    private const COLORS = [
        'red' => "\033[31m",
        'green' => "\033[32m",
        'yellow' => "\033[33m",
        'blue' => "\033[34m",
        'cyan' => "\033[36m",
        'bold' => "\033[1m",
        'reset' => "\033[0m",
    ];

    public function __construct(Logger $logger)
    {
        $this->logger = $logger;
    }

    /**
     * Generate reports in the specified format
     *
     * @param array<string, mixed> $results Validation results
     * @param string $format Output format
     * @param string|null $outputFile Output file path
     * @param bool $noColor Disable colored output
     * @param int $maxBroken Maximum broken links to display (0 = unlimited)
     */
    public function generateReports(
        array $results,
        string $format,
        ?string $outputFile,
        bool $noColor,
        int $maxBroken = 0
    ): void {
        $this->logger->debug("Generating {$format} report");

        $content = match ($format) {
            'json' => $this->generateJsonReport($results, $maxBroken),
            'markdown' => $this->generateMarkdownReport($results, $maxBroken),
            'html' => $this->generateHtmlReport($results, $maxBroken),
            'console' => $this->generateConsoleReport($results, !$noColor, $maxBroken),
            default => throw new \InvalidArgumentException("Unsupported format: {$format}"),
        };

        if ($outputFile !== null) {
            $this->writeToFile($content, $outputFile);
            $this->logger->info("Report saved to: {$outputFile}");
        } else {
            echo $content;
        }

        // Also save to automated reports directory for compatibility
        if ($format === 'json') {
            $this->saveAutomatedReport($results);
        }
    }

    /**
     * Generate JSON report compatible with Python toolchain
     *
     * @param array<string, mixed> $results Validation results
     * @param int $maxBroken Maximum broken links to include (0 = unlimited)
     * @return string JSON report
     */
    private function generateJsonReport(array $results, int $maxBroken = 0): string
    {
        $report = [
            'metadata' => [
                'timestamp' => $results['timestamp'],
                'total_files' => $results['summary']['total_files'],
                'total_links' => $results['summary']['total_links'],
                'broken_links' => $results['summary']['broken_links'],
                'success_rate' => $results['summary']['success_rate'],
                'status' => $this->determineStatus($results['summary']),
                'execution_time' => $results['execution_time'],
                'tool' => 'PHP Link Validator',
                'version' => '1.0.0',
            ],
            'detailed_results' => $results['results'],
            'summary' => $results['summary'],
        ];

        return json_encode($report, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
    }

    /**
     * Generate Markdown report compatible with existing format
     *
     * @param array<string, mixed> $results Validation results
     * @param int $maxBroken Maximum broken links to include (0 = unlimited)
     * @return string Markdown report
     */
    private function generateMarkdownReport(array $results, int $maxBroken = 0): string
    {
        $summary = $results['summary'];
        $status = $this->determineStatus($summary);
        $statusEmoji = self::STATUS_EMOJIS[$status];

        $report = "# Link Validation Report\n\n";
        $report .= "**Status:** {$statusEmoji} {$status}\n";
        $report .= "**Timestamp:** {$results['timestamp']}\n";
        $report .= "**Execution Time:** " . round($results['execution_time'], 2) . " seconds\n\n";

        $report .= "## Summary\n\n";
        $report .= "- **Total Files:** {$summary['total_files']}\n";
        $report .= "- **Total Links:** {$summary['total_links']}\n";
        $report .= "- **Broken Links:** {$summary['broken_links']}\n";
        $report .= "- **Success Rate:** {$summary['success_rate']}%\n\n";

        $report .= "## Link Type Breakdown\n\n";
        $report .= "| Type | Total | Broken | Success Rate |\n";
        $report .= "|------|-------|--------|-------------|\n";

        $linkTypes = [
            'Internal' => ['total' => $summary['internal_links'], 'broken' => $summary['broken_internal']],
            'Anchor' => ['total' => $summary['anchor_links'], 'broken' => $summary['broken_anchors']],
            'Cross-reference' => ['total' => $summary['cross_reference_links'], 'broken' => $summary['broken_cross_references']],
            'External' => ['total' => $summary['external_links'], 'broken' => $summary['broken_external']],
        ];

        foreach ($linkTypes as $type => $stats) {
            $successRate = $stats['total'] > 0
                ? round((($stats['total'] - $stats['broken']) / $stats['total']) * 100, 1)
                : 100.0;
            $report .= "| {$type} | {$stats['total']} | {$stats['broken']} | {$successRate}% |\n";
        }

        // Add broken links details if any
        if ($summary['broken_links'] > 0) {
            $report .= "\n## Broken Links Details\n\n";

            foreach ($results['results'] as $filePath => $fileResult) {
                if (!empty($fileResult['broken_links'])) {
                    $report .= "### {$filePath}\n\n";

                    foreach ($fileResult['broken_links'] as $brokenLink) {
                        $report .= "- **[{$brokenLink['text']}]({$brokenLink['url']})** ({$brokenLink['type']})\n";
                        $report .= "  - Status: {$brokenLink['status']}\n\n";
                    }
                }
            }
        }

        $report .= "\n## Recommendations\n\n";
        $report .= $this->generateRecommendations($status, $summary);

        return $report;
    }

    /**
     * Generate HTML report with interactive features
     *
     * @param array<string, mixed> $results Validation results
     * @param int $maxBroken Maximum broken links to include (0 = unlimited)
     * @return string HTML report
     */
    private function generateHtmlReport(array $results, int $maxBroken = 0): string
    {
        $summary = $results['summary'];
        $status = $this->determineStatus($summary);
        $statusEmoji = self::STATUS_EMOJIS[$status];

        $html = <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Link Validation Report</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 40px; }
        .header { border-bottom: 2px solid #eee; padding-bottom: 20px; margin-bottom: 30px; }
        .status-pass { color: #28a745; }
        .status-warn { color: #ffc107; }
        .status-fail { color: #dc3545; }
        .summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }
        .summary-card { background: #f8f9fa; padding: 20px; border-radius: 8px; text-align: center; }
        .summary-card h3 { margin: 0 0 10px 0; color: #495057; }
        .summary-card .value { font-size: 2em; font-weight: bold; color: #007bff; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f8f9fa; font-weight: 600; }
        .broken-link { background-color: #fff5f5; }
        .file-section { margin: 30px 0; }
        .file-title { background: #e9ecef; padding: 10px; border-radius: 4px; font-weight: bold; }
        .toggle-btn { background: #007bff; color: white; border: none; padding: 5px 10px; border-radius: 4px; cursor: pointer; }
        .collapsible { display: none; }
        .collapsible.show { display: block; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🔗 Link Validation Report</h1>
        <p><strong>Status:</strong> <span class="status-{$status}">{$statusEmoji} {$status}</span></p>
        <p><strong>Timestamp:</strong> {$results['timestamp']}</p>
        <p><strong>Execution Time:</strong> {$results['execution_time']} seconds</p>
    </div>

    <div class="summary-grid">
        <div class="summary-card">
            <h3>Total Files</h3>
            <div class="value">{$summary['total_files']}</div>
        </div>
        <div class="summary-card">
            <h3>Total Links</h3>
            <div class="value">{$summary['total_links']}</div>
        </div>
        <div class="summary-card">
            <h3>Broken Links</h3>
            <div class="value">{$summary['broken_links']}</div>
        </div>
        <div class="summary-card">
            <h3>Success Rate</h3>
            <div class="value">{$summary['success_rate']}%</div>
        </div>
    </div>
HTML;

        // Add broken links table if any
        if ($summary['broken_links'] > 0) {
            $html .= $this->generateHtmlBrokenLinksTable($results['results']);
        }

        $html .= <<<HTML
    <script>
        function toggleSection(id) {
            const element = document.getElementById(id);
            element.classList.toggle('show');
        }
    </script>
</body>
</html>
HTML;

        return $html;
    }

    /**
     * Generate console report with colored output
     *
     * @param array<string, mixed> $results Validation results
     * @param bool $useColors Whether to use colors
     * @param int $maxBroken Maximum broken links to display (0 = unlimited)
     * @return string Console report
     */
    private function generateConsoleReport(array $results, bool $useColors, int $maxBroken = 0): string
    {
        $summary = $results['summary'];
        $status = $this->determineStatus($summary);
        $statusEmoji = self::STATUS_EMOJIS[$status];

        $output = "\n";
        $output .= $this->colorize("🔗 Link Validation Report", 'bold', $useColors) . "\n";
        $output .= str_repeat("=", 50) . "\n\n";

        $statusColor = match ($status) {
            'PASS' => 'green',
            'WARN' => 'yellow',
            'FAIL' => 'red',
        };

        $output .= "Status: " . $this->colorize("{$statusEmoji} {$status}", $statusColor, $useColors) . "\n";
        $output .= "Timestamp: {$results['timestamp']}\n";
        $output .= "Execution Time: " . round($results['execution_time'], 2) . " seconds\n\n";

        $output .= $this->colorize("Summary:", 'bold', $useColors) . "\n";

        // Show files processed information
        if (isset($summary['files_processed']) && isset($summary['total_files_available'])) {
            $filesProcessed = $summary['files_processed'];
            $totalFilesAvailable = $summary['total_files_available'];

            if ($filesProcessed < $totalFilesAvailable) {
                $output .= "  Files Processed: " . $this->colorize("{$filesProcessed} of {$totalFilesAvailable}", 'yellow', $useColors) . " (validation truncated)\n";
            } else {
                $output .= "  Files Processed: {$filesProcessed}\n";
            }
        } else {
            $output .= "  Total Files: {$summary['total_files']}\n";
        }

        $output .= "  Total Links: {$summary['total_links']}\n";
        $output .= "  Broken Links: " . $this->colorize((string)$summary['broken_links'], $summary['broken_links'] > 0 ? 'red' : 'green', $useColors) . "\n";
        $output .= "  Success Rate: {$summary['success_rate']}%\n\n";

        if ($summary['broken_links'] > 0) {
            $output .= $this->colorize("Broken Links:", 'bold', $useColors) . "\n";
            $output .= str_repeat("-", 30) . "\n";

            $displayedCount = 0;
            $totalBroken = $summary['broken_links'];

            foreach ($results['results'] as $filePath => $fileResult) {
                if (!empty($fileResult['broken_links'])) {
                    $output .= "\n" . $this->colorize($filePath, 'cyan', $useColors) . ":\n";

                    foreach ($fileResult['broken_links'] as $brokenLink) {
                        if ($maxBroken > 0 && $displayedCount >= $maxBroken) {
                            $remaining = $totalBroken - $displayedCount;
                            $output .= "  ... and {$remaining} more broken links (use --max-broken=0 to show all)\n";
                            break 2; // Break out of both loops
                        }

                        $output .= "  • [{$brokenLink['text']}]({$brokenLink['url']}) - {$brokenLink['status']}\n";
                        $displayedCount++;
                    }
                }
            }
        }

        // Add truncation note if validation was limited
        if (isset($summary['files_processed']) && isset($summary['total_files_available'])) {
            $filesProcessed = $summary['files_processed'];
            $totalFilesAvailable = $summary['total_files_available'];

            if ($filesProcessed < $totalFilesAvailable) {
                $remaining = $totalFilesAvailable - $filesProcessed;
                $output .= "\n" . $this->colorize("Note:", 'bold', $useColors) . " ";
                $output .= $this->colorize("Validation was truncated. {$remaining} files were not processed.", 'yellow', $useColors) . "\n";
                $output .= "Use --max-files=0 to process all files.\n";
            }
        }

        return $output;
    }

    /**
     * Determine overall status based on summary
     *
     * @param array<string, mixed> $summary Validation summary
     * @return string Status (PASS, WARN, FAIL)
     */
    private function determineStatus(array $summary): string
    {
        $brokenLinks = $summary['broken_links'];
        $successRate = $summary['success_rate'];

        if ($brokenLinks === 0) {
            return 'PASS';
        }

        if ($brokenLinks > 10 || $successRate < 90) {
            return 'FAIL';
        }

        return 'WARN';
    }

    /**
     * Generate recommendations based on status
     *
     * @param string $status Validation status
     * @param array<string, mixed> $summary Validation summary
     * @return string Recommendations text
     */
    private function generateRecommendations(string $status, array $summary): string
    {
        return match ($status) {
            'PASS' => "✅ **Excellent!** All links are working correctly. Your documentation has perfect link integrity.",
            'WARN' => "⚠️ **Attention Needed:** Some broken links were found. Consider reviewing and fixing them to maintain documentation quality.",
            'FAIL' => "❌ **Action Required:** Significant number of broken links detected. Immediate attention needed to fix documentation integrity.",
        };
    }

    /**
     * Apply color to text for console output
     *
     * @param string $text Text to colorize
     * @param string $color Color name
     * @param bool $useColors Whether to use colors
     * @return string Colorized text
     */
    private function colorize(string $text, string $color, bool $useColors): string
    {
        if (!$useColors || !isset(self::COLORS[$color])) {
            return $text;
        }

        return self::COLORS[$color] . $text . self::COLORS['reset'];
    }

    /**
     * Write content to file
     *
     * @param string $content Content to write
     * @param string $filePath File path
     * @throws \RuntimeException If write fails
     */
    private function writeToFile(string $content, string $filePath): void
    {
        $directory = dirname($filePath);
        if (!is_dir($directory)) {
            if (!mkdir($directory, 0755, true)) {
                throw new \RuntimeException("Cannot create directory: {$directory}");
            }
        }

        if (file_put_contents($filePath, $content) === false) {
            throw new \RuntimeException("Cannot write to file: {$filePath}");
        }
    }

    /**
     * Save automated report for compatibility with Python toolchain
     *
     * @param array<string, mixed> $results Validation results
     */
    private function saveAutomatedReport(array $results): void
    {
        $reportsDir = '.ai/reports/automated';
        $timestamp = date('Ymd_His');

        try {
            if (!is_dir($reportsDir)) {
                mkdir($reportsDir, 0755, true);
            }

            $detailedFile = "{$reportsDir}/validation_detailed_{$timestamp}.json";
            $summaryFile = "{$reportsDir}/validation_summary_{$timestamp}.md";

            // Save detailed JSON report
            $this->writeToFile($this->generateJsonReport($results), $detailedFile);

            // Save markdown summary
            $this->writeToFile($this->generateMarkdownReport($results), $summaryFile);

            $this->logger->debug("Automated reports saved to {$reportsDir}");

        } catch (\Throwable $e) {
            $this->logger->warning("Failed to save automated reports: " . $e->getMessage());
        }
    }

    /**
     * Generate HTML table for broken links
     *
     * @param array<string, mixed> $results File results
     * @return string HTML table
     */
    private function generateHtmlBrokenLinksTable(array $results): string
    {
        $html = "<h2>Broken Links Details</h2>\n<table>\n";
        $html .= "<thead><tr><th>File</th><th>Link Text</th><th>URL</th><th>Type</th><th>Status</th></tr></thead>\n<tbody>\n";

        foreach ($results as $filePath => $fileResult) {
            foreach ($fileResult['broken_links'] as $brokenLink) {
                $html .= "<tr class='broken-link'>\n";
                $html .= "<td>" . htmlspecialchars($filePath) . "</td>\n";
                $html .= "<td>" . htmlspecialchars($brokenLink['text']) . "</td>\n";
                $html .= "<td>" . htmlspecialchars($brokenLink['url']) . "</td>\n";
                $html .= "<td>" . htmlspecialchars($brokenLink['type']) . "</td>\n";
                $html .= "<td>" . htmlspecialchars($brokenLink['status']) . "</td>\n";
                $html .= "</tr>\n";
            }
        }

        $html .= "</tbody>\n</table>\n";
        return $html;
    }
}
