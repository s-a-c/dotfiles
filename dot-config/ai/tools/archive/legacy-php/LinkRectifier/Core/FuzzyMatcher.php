<?php
/**
 * Fuzzy Matching Engine
 * 
 * Implements Levenshtein distance-based fuzzy matching for finding similar
 * filenames and suggesting corrections for broken links.
 * 
 * @package LinkRectifier\Core
 */

declare(strict_types=1);

namespace LinkRectifier\Core;

use LinkValidator\Utils\Logger;

/**
 * Fuzzy matcher for finding similar filenames
 * 
 * Uses Levenshtein distance algorithm with configurable thresholds to find
 * the best matches for broken link targets.
 */
final class FuzzyMatcher
{
    private readonly Logger $logger;
    
    /**
     * Default similarity threshold (0.0 to 1.0)
     */
    private const DEFAULT_THRESHOLD = 0.8;
    
    /**
     * Maximum Levenshtein distance to consider
     */
    private const MAX_DISTANCE = 10;
    
    public function __construct(Logger $logger)
    {
        $this->logger = $logger;
    }
    
    /**
     * Find the best match for a target filename
     * 
     * @param string $target Target filename to match
     * @param array<string> $candidates List of candidate filenames
     * @param float $threshold Similarity threshold (0.0 to 1.0)
     * @return string|null Best match or null if no suitable match found
     */
    public function findBestMatch(
        string $target,
        array $candidates,
        float $threshold = self::DEFAULT_THRESHOLD
    ): ?string {
        if (empty($target) || empty($candidates)) {
            return null;
        }
        
        $this->logger->debug("Finding fuzzy match for: {$target}");
        
        $bestMatch = null;
        $bestSimilarity = 0.0;
        
        foreach ($candidates as $candidate) {
            $similarity = $this->calculateSimilarity($target, $candidate);
            
            if ($similarity > $bestSimilarity && $similarity >= $threshold) {
                $bestSimilarity = $similarity;
                $bestMatch = $candidate;
            }
        }
        
        if ($bestMatch !== null) {
            $this->logger->debug(
                "Best fuzzy match: {$target} → {$bestMatch} (similarity: {$bestSimilarity})"
            );
        } else {
            $this->logger->debug("No fuzzy match found for: {$target}");
        }
        
        return $bestMatch;
    }
    
    /**
     * Find multiple matches above threshold
     * 
     * @param string $target Target filename to match
     * @param array<string> $candidates List of candidate filenames
     * @param float $threshold Similarity threshold (0.0 to 1.0)
     * @param int $maxResults Maximum number of results to return
     * @return array<array{file: string, similarity: float}> Matches sorted by similarity
     */
    public function findMatches(
        string $target,
        array $candidates,
        float $threshold = self::DEFAULT_THRESHOLD,
        int $maxResults = 5
    ): array {
        if (empty($target) || empty($candidates)) {
            return [];
        }
        
        $matches = [];
        
        foreach ($candidates as $candidate) {
            $similarity = $this->calculateSimilarity($target, $candidate);
            
            if ($similarity >= $threshold) {
                $matches[] = [
                    'file' => $candidate,
                    'similarity' => $similarity,
                ];
            }
        }
        
        // Sort by similarity (descending)
        usort($matches, fn($a, $b) => $b['similarity'] <=> $a['similarity']);
        
        return array_slice($matches, 0, $maxResults);
    }
    
    /**
     * Calculate similarity between two strings
     * 
     * Uses a combination of Levenshtein distance and other similarity metrics
     * to provide a comprehensive similarity score.
     * 
     * @param string $str1 First string
     * @param string $str2 Second string
     * @return float Similarity score (0.0 to 1.0)
     */
    public function calculateSimilarity(string $str1, string $str2): float
    {
        if ($str1 === $str2) {
            return 1.0;
        }
        
        if (empty($str1) || empty($str2)) {
            return 0.0;
        }
        
        // Normalize strings for comparison
        $normalized1 = $this->normalizeForComparison($str1);
        $normalized2 = $this->normalizeForComparison($str2);
        
        // Calculate multiple similarity metrics
        $levenshteinSimilarity = $this->calculateLevenshteinSimilarity($normalized1, $normalized2);
        $jaccardSimilarity = $this->calculateJaccardSimilarity($normalized1, $normalized2);
        $substringSimilarity = $this->calculateSubstringSimilarity($normalized1, $normalized2);
        
        // Weighted combination of metrics
        $similarity = (
            $levenshteinSimilarity * 0.5 +
            $jaccardSimilarity * 0.3 +
            $substringSimilarity * 0.2
        );
        
        return min(1.0, max(0.0, $similarity));
    }
    
    /**
     * Calculate Levenshtein-based similarity
     * 
     * @param string $str1 First string
     * @param string $str2 Second string
     * @return float Similarity score (0.0 to 1.0)
     */
    private function calculateLevenshteinSimilarity(string $str1, string $str2): float
    {
        $maxLength = max(strlen($str1), strlen($str2));
        
        if ($maxLength === 0) {
            return 1.0;
        }
        
        $distance = levenshtein($str1, $str2);
        
        // If distance is too large, return 0
        if ($distance > self::MAX_DISTANCE) {
            return 0.0;
        }
        
        return 1.0 - ($distance / $maxLength);
    }
    
    /**
     * Calculate Jaccard similarity (character-based)
     * 
     * @param string $str1 First string
     * @param string $str2 Second string
     * @return float Similarity score (0.0 to 1.0)
     */
    private function calculateJaccardSimilarity(string $str1, string $str2): float
    {
        $chars1 = array_unique(str_split($str1));
        $chars2 = array_unique(str_split($str2));
        
        $intersection = array_intersect($chars1, $chars2);
        $union = array_unique(array_merge($chars1, $chars2));
        
        if (empty($union)) {
            return 1.0;
        }
        
        return count($intersection) / count($union);
    }
    
    /**
     * Calculate substring-based similarity
     * 
     * @param string $str1 First string
     * @param string $str2 Second string
     * @return float Similarity score (0.0 to 1.0)
     */
    private function calculateSubstringSimilarity(string $str1, string $str2): float
    {
        $shorter = strlen($str1) <= strlen($str2) ? $str1 : $str2;
        $longer = strlen($str1) > strlen($str2) ? $str1 : $str2;
        
        if (empty($shorter)) {
            return 0.0;
        }
        
        // Check if shorter string is contained in longer string
        if (str_contains($longer, $shorter)) {
            return strlen($shorter) / strlen($longer);
        }
        
        // Find longest common substring
        $longestCommon = $this->findLongestCommonSubstring($str1, $str2);
        $maxLength = max(strlen($str1), strlen($str2));
        
        return strlen($longestCommon) / $maxLength;
    }
    
    /**
     * Find longest common substring
     * 
     * @param string $str1 First string
     * @param string $str2 Second string
     * @return string Longest common substring
     */
    private function findLongestCommonSubstring(string $str1, string $str2): string
    {
        $len1 = strlen($str1);
        $len2 = strlen($str2);
        $longest = '';
        
        for ($i = 0; $i < $len1; $i++) {
            for ($j = 0; $j < $len2; $j++) {
                $k = 0;
                while (
                    ($i + $k) < $len1 &&
                    ($j + $k) < $len2 &&
                    $str1[$i + $k] === $str2[$j + $k]
                ) {
                    $k++;
                }
                
                if ($k > strlen($longest)) {
                    $longest = substr($str1, $i, $k);
                }
            }
        }
        
        return $longest;
    }
    
    /**
     * Normalize string for comparison
     * 
     * @param string $str String to normalize
     * @return string Normalized string
     */
    private function normalizeForComparison(string $str): string
    {
        // Convert to lowercase
        $normalized = strtolower($str);
        
        // Remove file extensions for better matching
        $normalized = preg_replace('/\.(md|html|htm)$/i', '', $normalized);
        
        // Remove path separators
        $normalized = str_replace(['/', '\\'], '', $normalized);
        
        // Remove special characters except hyphens and underscores
        $normalized = preg_replace('/[^a-z0-9\-_]/', '', $normalized);
        
        return $normalized;
    }
    
    /**
     * Get suggestions for a target with explanations
     * 
     * @param string $target Target filename
     * @param array<string> $candidates Candidate filenames
     * @param float $threshold Similarity threshold
     * @param int $maxSuggestions Maximum suggestions to return
     * @return array<array{file: string, similarity: float, reason: string}> Suggestions with reasons
     */
    public function getSuggestions(
        string $target,
        array $candidates,
        float $threshold = self::DEFAULT_THRESHOLD,
        int $maxSuggestions = 3
    ): array {
        $matches = $this->findMatches($target, $candidates, $threshold, $maxSuggestions);
        
        $suggestions = [];
        foreach ($matches as $match) {
            $reason = $this->explainMatch($target, $match['file'], $match['similarity']);
            
            $suggestions[] = [
                'file' => $match['file'],
                'similarity' => $match['similarity'],
                'reason' => $reason,
            ];
        }
        
        return $suggestions;
    }
    
    /**
     * Explain why a match was suggested
     * 
     * @param string $target Target filename
     * @param string $match Matched filename
     * @param float $similarity Similarity score
     * @return string Explanation
     */
    private function explainMatch(string $target, string $match, float $similarity): string
    {
        $targetNorm = $this->normalizeForComparison($target);
        $matchNorm = $this->normalizeForComparison($match);
        
        // Check for exact match after normalization
        if ($targetNorm === $matchNorm) {
            return 'Exact match after normalization';
        }
        
        // Check for substring match
        if (str_contains($matchNorm, $targetNorm) || str_contains($targetNorm, $matchNorm)) {
            return 'Contains target as substring';
        }
        
        // Check for case difference
        if (strtolower($target) === strtolower($match)) {
            return 'Case difference only';
        }
        
        // Check for extension difference
        $targetBase = pathinfo($target, PATHINFO_FILENAME);
        $matchBase = pathinfo($match, PATHINFO_FILENAME);
        if (strtolower($targetBase) === strtolower($matchBase)) {
            return 'Different file extension';
        }
        
        // Generic similarity explanation
        $percentage = round($similarity * 100, 1);
        return "Similar filename ({$percentage}% match)";
    }
}
