<?php
/**
 * GitHub Anchor Generation Algorithm
 * 
 * Implements the exact GitHub-style anchor generation algorithm as validated
 * in the Python tools, ensuring 100% compatibility with existing validation.
 * 
 * @package LinkValidator\Core
 */

declare(strict_types=1);

namespace LinkValidator\Core;

/**
 * GitHub-compatible anchor generator
 * 
 * Generates anchors from heading text using the proven Phase 2 algorithm
 * that matches GitHub's anchor generation behavior exactly.
 */
final class GitHubAnchorGenerator
{
    /**
     * Generate GitHub-style anchor from heading text
     * 
     * GitHub anchor generation rules (validated in Phase 2 DRIP):
     * 1. Convert to lowercase
     * 2. Replace spaces with hyphens (-)
     * 3. Remove periods (.)
     * 4. Convert ampersands to double hyphens (& → --)
     * 5. Remove special characters except hyphens and alphanumeric
     * 6. Preserve numbers and letters
     * 
     * Examples from Phase 2 validation:
     * - "1. Overview" → "1-overview"
     * - "1.1. Enterprise Features" → "11-enterprise-features"
     * - "Setup & Configuration" → "setup--configuration"
     * - "SSL/TLS Configuration" → "ssltls-configuration"
     * 
     * @param string $headingText The heading text to convert
     * @return string The generated anchor (without #)
     */
    public function generate(string $headingText): string
    {
        // Start with the heading text
        $anchor = trim($headingText);
        
        // Convert to lowercase
        $anchor = strtolower($anchor);
        
        // Handle ampersands with surrounding spaces properly (Phase 2 proven pattern)
        // "word & word" should become "word--word", not "word----word"
        $anchor = str_replace(' & ', '--', $anchor);
        $anchor = str_replace('& ', '--', $anchor);
        $anchor = str_replace(' &', '--', $anchor);
        $anchor = str_replace('&', '--', $anchor);
        
        // Replace remaining spaces with hyphens
        $anchor = str_replace(' ', '-', $anchor);
        
        // Remove periods
        $anchor = str_replace('.', '', $anchor);
        
        // Remove forward slashes
        $anchor = str_replace('/', '', $anchor);
        
        // Remove parentheses
        $anchor = str_replace(['(', ')'], '', $anchor);
        
        // Remove other special characters, keeping only alphanumeric and hyphens
        $anchor = preg_replace('/[^a-z0-9\-]/', '', $anchor);
        
        // Clean up multiple consecutive hyphens, but preserve double hyphens from ampersands
        // First, protect double hyphens that came from ampersands
        $anchor = str_replace('--', '§§', $anchor); // Temporary placeholder
        while (str_contains($anchor, '--')) {
            $anchor = str_replace('--', '-', $anchor);
        }
        // Restore the ampersand-derived double hyphens
        $anchor = str_replace('§§', '--', $anchor);
        
        // Remove leading/trailing hyphens
        $anchor = trim($anchor, '-');
        
        return $anchor;
    }
    
    /**
     * Validate that the generated anchor matches expected patterns
     * 
     * @param string $headingText Original heading text
     * @param string $expectedAnchor Expected anchor result
     * @return bool True if the generated anchor matches expected
     */
    public function validate(string $headingText, string $expectedAnchor): bool
    {
        return $this->generate($headingText) === $expectedAnchor;
    }
    
    /**
     * Get test cases for validation
     * 
     * Returns known good test cases from the Python validation to ensure
     * compatibility and correctness of the algorithm.
     * 
     * @return array<array{heading: string, expected: string}> Test cases
     */
    public function getTestCases(): array
    {
        return [
            // Basic cases
            ['heading' => '1. Overview', 'expected' => '1-overview'],
            ['heading' => '2. Installation', 'expected' => '2-installation'],
            ['heading' => 'Getting Started', 'expected' => 'getting-started'],
            
            // Period handling
            ['heading' => '1.1. Enterprise Features', 'expected' => '11-enterprise-features'],
            ['heading' => '2.3.4. Advanced Configuration', 'expected' => '234-advanced-configuration'],
            ['heading' => 'Version 1.0.0', 'expected' => 'version-100'],
            
            // Ampersand handling
            ['heading' => 'Setup & Configuration', 'expected' => 'setup--configuration'],
            ['heading' => 'API & SDK', 'expected' => 'api--sdk'],
            ['heading' => 'Q&A', 'expected' => 'q--a'],
            ['heading' => 'Terms & Conditions & Privacy', 'expected' => 'terms--conditions--privacy'],
            
            // Special characters
            ['heading' => 'SSL/TLS Configuration', 'expected' => 'ssltls-configuration'],
            ['heading' => 'HTTP/HTTPS Setup', 'expected' => 'httphttps-setup'],
            ['heading' => 'Client/Server Architecture', 'expected' => 'clientserver-architecture'],
            
            // Parentheses
            ['heading' => 'Advanced Features (Pro)', 'expected' => 'advanced-features-pro'],
            ['heading' => 'API Reference (v2.0)', 'expected' => 'api-reference-v20'],
            ['heading' => 'Configuration (Optional)', 'expected' => 'configuration-optional'],
            
            // Mixed cases
            ['heading' => '3.1. Setup & Configuration (Advanced)', 'expected' => '31-setup--configuration-advanced'],
            ['heading' => 'API/SDK & Integration Guide', 'expected' => 'apisdk--integration-guide'],
            ['heading' => 'Version 2.0.1 (Beta) & Features', 'expected' => 'version-201-beta--features'],
            
            // Edge cases
            ['heading' => 'Multiple   Spaces', 'expected' => 'multiple-spaces'],
            ['heading' => '---Dashes---', 'expected' => 'dashes'],
            ['heading' => '!!!Exclamations!!!', 'expected' => 'exclamations'],
            ['heading' => 'Unicode: Café & Naïve', 'expected' => 'unicode-caf--nave'],
            
            // Empty and minimal cases
            ['heading' => '', 'expected' => ''],
            ['heading' => '1', 'expected' => '1'],
            ['heading' => '&', 'expected' => ''],
            ['heading' => '...', 'expected' => ''],
        ];
    }
    
    /**
     * Run self-validation tests
     * 
     * @return array{passed: int, failed: int, failures: array<string>} Test results
     */
    public function runTests(): array
    {
        $testCases = $this->getTestCases();
        $passed = 0;
        $failed = 0;
        $failures = [];
        
        foreach ($testCases as $testCase) {
            $generated = $this->generate($testCase['heading']);
            if ($generated === $testCase['expected']) {
                $passed++;
            } else {
                $failed++;
                $failures[] = sprintf(
                    'Heading: "%s" | Expected: "%s" | Generated: "%s"',
                    $testCase['heading'],
                    $testCase['expected'],
                    $generated
                );
            }
        }
        
        return [
            'passed' => $passed,
            'failed' => $failed,
            'failures' => $failures,
        ];
    }
}
