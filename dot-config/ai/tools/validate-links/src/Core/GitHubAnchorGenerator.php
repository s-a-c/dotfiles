<?php
/**
 * GitHub-Compatible Anchor Generator
 *
 * Generates anchor links using the same algorithm as GitHub for consistent
 * anchor link validation in Markdown documents.
 *
 * @package SAC\ValidateLinks\Core
 */

declare(strict_types=1);

namespace SAC\ValidateLinks\Core;

/**
 * GitHub-compatible anchor generator
 *
 * Implements the exact algorithm used by GitHub to generate anchor links
 * from headings, ensuring consistent validation of anchor links.
 */
final class GitHubAnchorGenerator
{
    /**
     * Generate GitHub-style anchor from heading text
     *
     * @param string $heading Heading text
     * @return string Generated anchor (without #)
     */
    public function generate(string $heading): string
    {
        // Remove HTML tags
        $anchor = strip_tags($heading);
        
        // Convert to lowercase
        $anchor = strtolower($anchor);
        
        // Replace spaces and special characters with hyphens
        $anchor = preg_replace('/[^\w\- ]/', '', $anchor);
        $anchor = preg_replace('/\s+/', '-', $anchor);
        
        // Remove leading/trailing hyphens
        $anchor = trim($anchor, '-');
        
        // Handle empty anchors
        if (empty($anchor)) {
            return '';
        }
        
        return $anchor;
    }

    /**
     * Generate multiple anchors from an array of headings
     *
     * @param array<string> $headings Array of heading texts
     * @return array<string> Array of generated anchors
     */
    public function generateMultiple(array $headings): array
    {
        $anchors = [];
        $counts = [];
        
        foreach ($headings as $heading) {
            $baseAnchor = $this->generate($heading);
            
            if (empty($baseAnchor)) {
                continue;
            }
            
            // Handle duplicate anchors by adding numbers
            if (!isset($counts[$baseAnchor])) {
                $counts[$baseAnchor] = 0;
                $anchors[] = $baseAnchor;
            } else {
                $counts[$baseAnchor]++;
                $anchors[] = $baseAnchor . '-' . $counts[$baseAnchor];
            }
        }
        
        return $anchors;
    }

    /**
     * Check if an anchor would be generated from a heading
     *
     * @param string $heading Heading text
     * @param string $anchor Anchor to check
     * @return bool True if anchor matches heading
     */
    public function matches(string $heading, string $anchor): bool
    {
        return $this->generate($heading) === $anchor;
    }

    /**
     * Extract and generate anchors from content
     *
     * @param string $content Document content
     * @return array<string> Array of generated anchors
     */
    public function extractFromContent(string $content): array
    {
        $headings = [];
        
        // Extract Markdown headings
        if (preg_match_all('/^(#{1,6})\s+(.+)$/m', $content, $matches)) {
            foreach ($matches[2] as $heading) {
                $headings[] = trim($heading);
            }
        }
        
        // Extract HTML headings
        if (preg_match_all('/<h[1-6][^>]*>([^<]+)<\/h[1-6]>/i', $content, $matches)) {
            foreach ($matches[1] as $heading) {
                $headings[] = trim(strip_tags($heading));
            }
        }
        
        return $this->generateMultiple($headings);
    }
}
