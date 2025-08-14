<?php
/**
 * Report Generation System
 *
 * Generates comprehensive validation reports in multiple formats including
 * JSON, Markdown, HTML, and console output with detailed statistics and
 * compatibility with existing Python toolchain.
 *
 * @package SAC\ValidateLinks\Core
 */

declare(strict_types=1);

namespace SAC\ValidateLinks\Core;

use SAC\ValidateLinks\Utils\Logger;

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
    private function generateJsonReport(array $results, int $maxBroken): string
    {
        // Limit broken links if specified
        if ($maxBroken > 0) {
            $results = $this->limitBrokenLinks($results, $maxBroken);
        }

        return json_encode($results, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
    }

    /**
     * Generate Markdown report
     *
     * @param array<string, mixed> $results Validation results
     * @param int $maxBroken Maximum broken links to include (0 = unlimited)
     * @return string Markdown report
     */
    private function generateMarkdownReport(array $results, int $maxBroken): string
    {
        $summary = $results['summary'];
        $output = "# Link Validation Report\n\n";

        // Summary section
        $output .= "## Summary\n\n";
        $output .= "| Metric | Value |\n";
        $output .= "|--------|-------|\n";

        // Show files processed information
        if (isset($summary['files_processed']) && isset($summary['total_files_available'])) {
            $filesProcessed = $summary['files_processed'];
            $totalFilesAvailable = $summary['total_files_available'];

            if ($filesProcessed < $totalFilesAvailable) {
                $output .= "| Files Processed | {$filesProcessed} of {$totalFilesAvailable} (validation truncated) |\n";
            } else {
                $output .= "| Files Processed | {$filesProcessed} |\n";
            }
        } else {
            $output .= "| Total Files | {$summary['total_files']} |\n";
        }

        $output .= "| Total Links | {$summary['total_links']} |\n";
        $output .= "| Broken Links | {$summary['broken_links']} |\n";
        $output .= "| Success Rate | {$summary['success_rate']}% |\n";
        $output .= "| Execution Time | {$summary['execution_time']}s |\n\n";

        // Broken links section
        if ($summary['broken_links'] > 0) {
            $output .= "## Broken Links\n\n";

            $brokenCount = 0;
            foreach ($results['results'] as $filePath => $fileResult) {
                if (!empty($fileResult['broken_links'])) {
                    $output .= "### {$filePath}\n\n";

                    foreach ($fileResult['broken_links'] as $link) {
                        if ($maxBroken > 0 && $brokenCount >= $maxBroken) {
                            $remaining = $summary['broken_links'] - $brokenCount;
                            $output .= "\n*... and {$remaining} more broken links (use --max-broken=0 to show all)*\n";
                            break 2;
                        }

                        $output .= "- **Line {$link['line']}**: [{$link['text']}]({$link['url']}) - {$link['status']}\n";
                        $brokenCount++;
                    }
                    $output .= "\n";
                }
            }
        }

        // Add truncation note if validation was limited
        if (isset($summary['files_processed']) && isset($summary['total_files_available'])) {
            $filesProcessed = $summary['files_processed'];
            $totalFilesAvailable = $summary['total_files_available'];

            if ($filesProcessed < $totalFilesAvailable) {
                $remaining = $totalFilesAvailable - $filesProcessed;
                $output .= "## Note\n\n";
                $output .= "⚠️ **Validation was truncated.** {$remaining} files were not processed.\n";
                $output .= "Use `--max-files=0` to process all files.\n\n";
            }
        }

        $output .= "---\n";
        $output .= "*Generated by validate-links on " . date('Y-m-d H:i:s') . "*\n";

        return $output;
    }

    /**
     * Generate HTML report
     *
     * @param array<string, mixed> $results Validation results
     * @param int $maxBroken Maximum broken links to include (0 = unlimited)
     * @return string HTML report
     */
    private function generateHtmlReport(array $results, int $maxBroken): string
    {
        $summary = $results['summary'];
        $timestamp = date('Y-m-d H:i:s');

        $html = <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Link Validation Report</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 40px; }
        .header { border-bottom: 2px solid #e1e4e8; padding-bottom: 20px; margin-bottom: 30px; }
        .summary { background: #f6f8fa; padding: 20px; border-radius: 6px; margin-bottom: 30px; }
        .metric { display: flex; justify-content: space-between; margin: 10px 0; }
        .broken-links { margin-top: 30px; }
        .file-section { margin: 20px 0; padding: 15px; border-left: 4px solid #d73a49; background: #ffeef0; }
        .link-item { margin: 10px 0; padding: 10px; background: white; border-radius: 4px; }
        .success { color: #28a745; }
        .error { color: #d73a49; }
        .warning { color: #ffc107; }
        .footer { margin-top: 40px; padding-top: 20px; border-top: 1px solid #e1e4e8; color: #586069; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🔗 Link Validation Report</h1>
        <p>Generated on {$timestamp}</p>
    </div>

    <div class="summary">
        <h2>📊 Summary</h2>
HTML;

        // Add summary metrics
        if (isset($summary['files_processed']) && isset($summary['total_files_available'])) {
            $filesProcessed = $summary['files_processed'];
            $totalFilesAvailable = $summary['total_files_available'];

            if ($filesProcessed < $totalFilesAvailable) {
                $html .= "<div class='metric'><strong>Files Processed:</strong> <span class='warning'>{$filesProcessed} of {$totalFilesAvailable} (validation truncated)</span></div>";
            } else {
                $html .= "<div class='metric'><strong>Files Processed:</strong> <span>{$filesProcessed}</span></div>";
            }
        } else {
            $html .= "<div class='metric'><strong>Total Files:</strong> <span>{$summary['total_files']}</span></div>";
        }

        $successClass = $summary['broken_links'] > 0 ? 'error' : 'success';
        $html .= "<div class='metric'><strong>Total Links:</strong> <span>{$summary['total_links']}</span></div>";
        $html .= "<div class='metric'><strong>Broken Links:</strong> <span class='{$successClass}'>{$summary['broken_links']}</span></div>";
        $html .= "<div class='metric'><strong>Success Rate:</strong> <span class='{$successClass}'>{$summary['success_rate']}%</span></div>";
        $html .= "<div class='metric'><strong>Execution Time:</strong> <span>{$summary['execution_time']}s</span></div>";
        $html .= "</div>";

        // Add broken links section
        if ($summary['broken_links'] > 0) {
            $html .= "<div class='broken-links'><h2>❌ Broken Links</h2>";

            $brokenCount = 0;
            foreach ($results['results'] as $filePath => $fileResult) {
                if (!empty($fileResult['broken_links'])) {
                    $html .= "<div class='file-section'>";
                    $html .= "<h3>" . htmlspecialchars($filePath) . "</h3>";

                    foreach ($fileResult['broken_links'] as $link) {
                        if ($maxBroken > 0 && $brokenCount >= $maxBroken) {
                            $remaining = $summary['broken_links'] - $brokenCount;
                            $html .= "<p><em>... and {$remaining} more broken links (use --max-broken=0 to show all)</em></p>";
                            break 2;
                        }

                        $html .= "<div class='link-item'>";
                        $html .= "<strong>Line {$link['line']}:</strong> ";
                        $html .= "<code>" . htmlspecialchars($link['url']) . "</code> ";
                        $html .= "<br><em>" . htmlspecialchars($link['status']) . "</em>";
                        $html .= "</div>";
                        $brokenCount++;
                    }
                    $html .= "</div>";
                }
            }
            $html .= "</div>";
        }

        $html .= "<div class='footer'>";
        $html .= "<p>Generated by <strong>validate-links</strong></p>";
        $html .= "</div>";
        $html .= "</body></html>";

        return $html;
    }

    /**
     * Generate console report with colors
     *
     * @param array<string, mixed> $results Validation results
     * @param bool $useColors Whether to use colors
     * @param int $maxBroken Maximum broken links to display (0 = unlimited)
     * @return string Console report
     */
    private function generateConsoleReport(array $results, bool $useColors, int $maxBroken): string
    {
        $summary = $results['summary'];
        $output = '';

        $output .= $this->colorize("Link Validation Report", 'bold', $useColors) . "\n";
        $output .= str_repeat('=', 50) . "\n\n";

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

        // Show broken links
        if ($summary['broken_links'] > 0) {
            $output .= $this->colorize("Broken Links:", 'bold', $useColors) . "\n";
            $output .= str_repeat('-', 30) . "\n";

            $brokenCount = 0;
            foreach ($results['results'] as $filePath => $fileResult) {
                if (!empty($fileResult['broken_links'])) {
                    $output .= "\n" . $this->colorize($filePath, 'cyan', $useColors) . ":\n";

                    foreach ($fileResult['broken_links'] as $link) {
                        if ($maxBroken > 0 && $brokenCount >= $maxBroken) {
                            $remaining = $summary['broken_links'] - $brokenCount;
                            $output .= "\n" . $this->colorize("... and {$remaining} more broken links", 'yellow', $useColors);
                            $output .= " " . $this->colorize("(use --max-broken=0 to show all)", 'yellow', $useColors) . "\n";
                            break 2;
                        }

                        $output .= "  " . $this->colorize("Line {$link['line']}:", 'yellow', $useColors) . " ";
                        $output .= $this->colorize($link['url'], 'red', $useColors) . "\n";
                        $output .= "    " . $link['status'] . "\n";
                        $brokenCount++;
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
     * Apply color to text if colors are enabled
     *
     * @param string $text Text to colorize
     * @param string $color Color name
     * @param bool $useColors Whether to use colors
     * @return string Colorized or plain text
     */
    private function colorize(string $text, string $color, bool $useColors): string
    {
        if (!$useColors || !isset(self::COLORS[$color])) {
            return $text;
        }

        return self::COLORS[$color] . $text . self::COLORS['reset'];
    }

    /**
     * Limit broken links in results
     *
     * @param array<string, mixed> $results Validation results
     * @param int $maxBroken Maximum broken links to include
     * @return array<string, mixed> Limited results
     */
    private function limitBrokenLinks(array $results, int $maxBroken): array
    {
        $brokenCount = 0;

        foreach ($results['results'] as $filePath => &$fileResult) {
            if (!empty($fileResult['broken_links'])) {
                $originalCount = count($fileResult['broken_links']);
                $remainingSlots = $maxBroken - $brokenCount;

                if ($remainingSlots <= 0) {
                    $fileResult['broken_links'] = [];
                } elseif ($originalCount > $remainingSlots) {
                    $fileResult['broken_links'] = array_slice($fileResult['broken_links'], 0, $remainingSlots);
                    $brokenCount += $remainingSlots;
                } else {
                    $brokenCount += $originalCount;
                }
            }
        }

        return $results;
    }

    /**
     * Write content to file
     *
     * @param string $content Content to write
     * @param string $filePath File path
     */
    private function writeToFile(string $content, string $filePath): void
    {
        $directory = dirname($filePath);
        if (!is_dir($directory)) {
            mkdir($directory, 0755, true);
        }

        file_put_contents($filePath, $content);
    }

    /**
     * Save automated report for compatibility
     *
     * @param array<string, mixed> $results Validation results
     */
    private function saveAutomatedReport(array $results): void
    {
        $reportsDir = '.ai/reports';
        if (!is_dir($reportsDir)) {
            mkdir($reportsDir, 0755, true);
        }

        $timestamp = date('Y-m-d_H-i-s');
        $filename = "{$reportsDir}/link-validation-{$timestamp}.json";

        $this->writeToFile(
            json_encode($results, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES),
            $filename
        );

        $this->logger->debug("Automated report saved to: {$filename}");
    }
}
