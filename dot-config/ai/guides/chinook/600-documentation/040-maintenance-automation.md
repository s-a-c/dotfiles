# Documentation Maintenance Automation

**Version:** 1.0  
**Created:** 2025-07-16  
**Last Updated:** 2025-07-16  
**Scope:** Automated quality checks and maintenance for Chinook documentation

## Table of Contents

1. [Overview](#1-overview)
2. [Automated Link Validation](#2-automated-link-validation)
3. [Content Quality Automation](#3-content-quality-automation)
4. [Documentation Synchronization](#4-documentation-synchronization)
5. [CI/CD Integration](#5-cicd-integration)
6. [Maintenance Workflows](#6-maintenance-workflows)

## 1. Overview

This guide establishes automated systems for maintaining documentation quality, consistency, and accuracy across the Chinook project, reducing manual maintenance overhead while ensuring high standards.

### 1.1 Automation Philosophy

- **Proactive Quality:** Catch issues before they impact users
- **Consistent Standards:** Automated enforcement of style guidelines
- **Reduced Overhead:** Minimize manual maintenance tasks
- **Educational Value:** Learn from automated quality processes

### 1.2 Automation Scope

- **Link Validation:** Automated checking of internal and external links
- **Content Synchronization:** Keep documentation in sync with code changes
- **Style Compliance:** Automated style guide enforcement
- **Performance Monitoring:** Track documentation performance metrics

## 2. Automated Link Validation

### 2.1 Link Validation Script

```bash
#!/bin/bash

# Automated Link Validation for Chinook Documentation
# Validates all internal and external links in markdown files

DOCS_DIR=".ai/guides/chinook"
REPORT_DIR="reports/link-validation"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="$REPORT_DIR/link_validation_$TIMESTAMP.json"

mkdir -p "$REPORT_DIR"

echo "Starting automated link validation for Chinook documentation..."

# Initialize report structure
cat > "$REPORT_FILE" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "total_files": 0,
  "total_links": 0,
  "broken_links": 0,
  "files": [],
  "summary": {
    "internal_links": {"total": 0, "broken": 0},
    "external_links": {"total": 0, "broken": 0},
    "anchor_links": {"total": 0, "broken": 0}
  }
}
EOF

# Function to validate a single link
validate_link() {
    local url="$1"
    local file="$2"
    local line="$3"
    
    # Internal file links
    if [[ "$url" =~ ^\./ ]]; then
        local target_file="$(dirname "$file")/$url"
        if [[ ! -f "$target_file" ]]; then
            echo "BROKEN_INTERNAL: $url in $file:$line"
            return 1
        fi
    # Anchor links within same file
    elif [[ "$url" =~ ^# ]]; then
        local anchor="${url#\#}"
        if ! grep -q "^#.*$anchor\|id=\"$anchor\"" "$file"; then
            echo "BROKEN_ANCHOR: $url in $file:$line"
            return 1
        fi
    # External links
    elif [[ "$url" =~ ^https?:// ]]; then
        if ! curl -s --head "$url" | head -n 1 | grep -q "200 OK"; then
            echo "BROKEN_EXTERNAL: $url in $file:$line"
            return 1
        fi
    fi
    
    return 0
}

# Process all markdown files
find "$DOCS_DIR" -name "*.md" -type f | while read -r file; do
    echo "Validating links in: $file"
    
    # Extract all markdown links
    grep -n '\[.*\](.*)' "$file" | while IFS=: read -r line_num line_content; do
        # Extract URL from markdown link
        url=$(echo "$line_content" | sed -n 's/.*\[.*\](\([^)]*\)).*/\1/p')
        
        if [[ -n "$url" ]]; then
            validate_link "$url" "$file" "$line_num"
        fi
    done
done

echo "Link validation complete. Report saved to: $REPORT_FILE"
```

### 2.2 Advanced Link Validation with Node.js

```javascript
// scripts/validate-links.js
// Advanced link validation with detailed reporting

const fs = require('fs').promises;
const path = require('path');
const axios = require('axios');
const cheerio = require('cheerio');

class DocumentationLinkValidator {
    constructor(docsPath = '.ai/guides/chinook') {
        this.docsPath = docsPath;
        this.results = {
            timestamp: new Date().toISOString(),
            totalFiles: 0,
            totalLinks: 0,
            brokenLinks: [],
            warnings: [],
            summary: {
                internal: { total: 0, broken: 0 },
                external: { total: 0, broken: 0 },
                anchors: { total: 0, broken: 0 }
            }
        };
    }

    async validateAllDocuments() {
        console.log('🔍 Starting comprehensive link validation...');
        
        const files = await this.findMarkdownFiles();
        this.results.totalFiles = files.length;
        
        for (const file of files) {
            await this.validateFile(file);
        }
        
        await this.generateReport();
        return this.results;
    }

    async findMarkdownFiles() {
        const files = [];
        
        async function scanDirectory(dir) {
            const entries = await fs.readdir(dir, { withFileTypes: true });
            
            for (const entry of entries) {
                const fullPath = path.join(dir, entry.name);
                
                if (entry.isDirectory()) {
                    await scanDirectory(fullPath);
                } else if (entry.name.endsWith('.md')) {
                    files.push(fullPath);
                }
            }
        }
        
        await scanDirectory(this.docsPath);
        return files;
    }

    async validateFile(filePath) {
        try {
            const content = await fs.readFile(filePath, 'utf-8');
            const lines = content.split('\n');
            
            // Extract all markdown links
            const linkRegex = /\[([^\]]*)\]\(([^)]+)\)/g;
            let match;
            
            while ((match = linkRegex.exec(content)) !== null) {
                const [fullMatch, linkText, url] = match;
                const lineNumber = this.getLineNumber(content, match.index);
                
                this.results.totalLinks++;
                
                await this.validateLink({
                    file: filePath,
                    line: lineNumber,
                    text: linkText,
                    url: url.trim(),
                    fullMatch
                });
            }
            
            // Validate anchor links in headings
            await this.validateAnchors(filePath, content);
            
        } catch (error) {
            this.results.warnings.push({
                file: filePath,
                type: 'FILE_READ_ERROR',
                message: error.message
            });
        }
    }

    async validateLink(linkInfo) {
        const { file, line, url, text } = linkInfo;
        
        try {
            if (url.startsWith('./') || url.startsWith('../')) {
                // Internal file link
                await this.validateInternalLink(linkInfo);
                this.results.summary.internal.total++;
            } else if (url.startsWith('#')) {
                // Anchor link
                await this.validateAnchorLink(linkInfo);
                this.results.summary.anchors.total++;
            } else if (url.startsWith('http')) {
                // External link
                await this.validateExternalLink(linkInfo);
                this.results.summary.external.total++;
            }
        } catch (error) {
            this.addBrokenLink(linkInfo, error.message);
        }
    }

    async validateInternalLink({ file, line, url, text }) {
        const basePath = path.dirname(file);
        const targetPath = path.resolve(basePath, url);
        
        try {
            await fs.access(targetPath);
        } catch (error) {
            this.results.summary.internal.broken++;
            throw new Error(`Internal file not found: ${url}`);
        }
    }

    async validateExternalLink({ file, line, url, text }) {
        try {
            const response = await axios.head(url, {
                timeout: 10000,
                validateStatus: (status) => status < 400
            });
            
            // Check for redirects
            if (response.status >= 300 && response.status < 400) {
                this.results.warnings.push({
                    file,
                    line,
                    type: 'REDIRECT',
                    message: `Link redirects: ${url} -> ${response.headers.location}`
                });
            }
            
        } catch (error) {
            this.results.summary.external.broken++;
            
            if (error.code === 'ENOTFOUND') {
                throw new Error(`Domain not found: ${url}`);
            } else if (error.response) {
                throw new Error(`HTTP ${error.response.status}: ${url}`);
            } else {
                throw new Error(`Network error: ${error.message}`);
            }
        }
    }

    async validateAnchorLink({ file, line, url, text }) {
        const content = await fs.readFile(file, 'utf-8');
        const anchor = url.substring(1); // Remove #
        
        // Check for heading anchors
        const headingRegex = new RegExp(`^#+\\s+.*${anchor}`, 'im');
        const idRegex = new RegExp(`id=["']${anchor}["']`, 'i');
        
        if (!headingRegex.test(content) && !idRegex.test(content)) {
            this.results.summary.anchors.broken++;
            throw new Error(`Anchor not found: ${anchor}`);
        }
    }

    async validateAnchors(filePath, content) {
        // Extract all headings and validate their anchor format
        const headingRegex = /^(#+)\s+(.+)$/gm;
        let match;
        
        while ((match = headingRegex.exec(content)) !== null) {
            const [fullMatch, hashes, headingText] = match;
            const level = hashes.length;
            const lineNumber = this.getLineNumber(content, match.index);
            
            // Check heading hierarchy
            if (level > 3) {
                this.results.warnings.push({
                    file: filePath,
                    line: lineNumber,
                    type: 'HEADING_DEPTH',
                    message: `Heading too deep (level ${level}): ${headingText}`
                });
            }
            
            // Validate anchor format
            const expectedAnchor = this.generateAnchor(headingText);
            const anchorRegex = new RegExp(`\\(#${expectedAnchor}\\)`);
            
            if (!anchorRegex.test(content)) {
                this.results.warnings.push({
                    file: filePath,
                    line: lineNumber,
                    type: 'MISSING_ANCHOR',
                    message: `Heading missing proper anchor: ${headingText}`
                });
            }
        }
    }

    generateAnchor(headingText) {
        return headingText
            .toLowerCase()
            .replace(/[^\w\s-]/g, '')
            .replace(/\s+/g, '-')
            .replace(/-+/g, '-')
            .replace(/^-|-$/g, '');
    }

    getLineNumber(content, index) {
        return content.substring(0, index).split('\n').length;
    }

    addBrokenLink(linkInfo, error) {
        this.results.brokenLinks.push({
            file: linkInfo.file,
            line: linkInfo.line,
            url: linkInfo.url,
            text: linkInfo.text,
            error: error
        });
    }

    async generateReport() {
        const reportPath = `reports/link-validation-${Date.now()}.json`;
        await fs.writeFile(reportPath, JSON.stringify(this.results, null, 2));
        
        // Generate human-readable summary
        console.log('\n📊 Link Validation Summary:');
        console.log(`Files processed: ${this.results.totalFiles}`);
        console.log(`Total links: ${this.results.totalLinks}`);
        console.log(`Broken links: ${this.results.brokenLinks.length}`);
        console.log(`Warnings: ${this.results.warnings.length}`);
        
        if (this.results.brokenLinks.length > 0) {
            console.log('\n❌ Broken Links:');
            this.results.brokenLinks.forEach(link => {
                console.log(`  ${link.file}:${link.line} - ${link.url} (${link.error})`);
            });
        }
        
        if (this.results.warnings.length > 0) {
            console.log('\n⚠️  Warnings:');
            this.results.warnings.forEach(warning => {
                console.log(`  ${warning.file}:${warning.line} - ${warning.message}`);
            });
        }
        
        console.log(`\nDetailed report saved to: ${reportPath}`);
    }
}

// CLI usage
if (require.main === module) {
    const validator = new DocumentationLinkValidator();
    validator.validateAllDocuments()
        .then(results => {
            process.exit(results.brokenLinks.length > 0 ? 1 : 0);
        })
        .catch(error => {
            console.error('Validation failed:', error);
            process.exit(1);
        });
}

module.exports = DocumentationLinkValidator;
```

## 3. Content Quality Automation

### 3.1 Automated Style Guide Enforcement

```python
#!/usr/bin/env python3
"""
Automated Style Guide Enforcement for Chinook Documentation
Validates documentation against established style guide standards
"""

import os
import re
import json
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Any

class DocumentationStyleValidator:
    def __init__(self, docs_path: str = ".ai/guides/chinook"):
        self.docs_path = Path(docs_path)
        self.violations = []
        self.warnings = []
        self.stats = {
            'files_processed': 0,
            'total_violations': 0,
            'total_warnings': 0
        }

        # Style guide rules
        self.rules = {
            'file_naming': r'^[0-9]{3}-[a-z0-9-]+\.md$',
            'max_line_length': 120,
            'required_headers': ['Version', 'Created', 'Last Updated', 'Scope'],
            'heading_hierarchy': True,
            'navigation_footer': True,
            'wcag_compliance': True
        }

    def validate_all_files(self) -> Dict[str, Any]:
        """Validate all markdown files against style guide"""
        print("🔍 Starting style guide validation...")

        for md_file in self.docs_path.rglob("*.md"):
            self.validate_file(md_file)
            self.stats['files_processed'] += 1

        return self.generate_report()

    def validate_file(self, file_path: Path) -> None:
        """Validate a single file against style guide rules"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                lines = content.split('\n')

            # File naming validation
            self.validate_file_naming(file_path)

            # Content structure validation
            self.validate_document_structure(file_path, content, lines)

            # Line length validation
            self.validate_line_lengths(file_path, lines)

            # Heading hierarchy validation
            self.validate_heading_hierarchy(file_path, lines)

            # Navigation footer validation
            self.validate_navigation_footer(file_path, content)

            # WCAG compliance validation
            self.validate_wcag_compliance(file_path, content)

        except Exception as e:
            self.add_violation(file_path, 0, 'FILE_READ_ERROR', f"Cannot read file: {e}")

    def validate_file_naming(self, file_path: Path) -> None:
        """Validate file naming conventions"""
        filename = file_path.name

        if not re.match(self.rules['file_naming'], filename):
            self.add_violation(
                file_path, 0, 'NAMING_CONVENTION',
                f"File name '{filename}' doesn't follow XXX-name.md pattern"
            )

    def validate_document_structure(self, file_path: Path, content: str, lines: List[str]) -> None:
        """Validate required document structure elements"""
        # Check for required headers in first 20 lines
        header_section = '\n'.join(lines[:20])

        for required_header in self.rules['required_headers']:
            pattern = f"\\*\\*{required_header}:\\*\\*"
            if not re.search(pattern, header_section):
                self.add_violation(
                    file_path, 1, 'MISSING_HEADER',
                    f"Required header '{required_header}' not found in document header"
                )

        # Check for Table of Contents
        if '## Table of Contents' not in content:
            self.add_violation(
                file_path, 1, 'MISSING_TOC',
                "Document missing 'Table of Contents' section"
            )

    def validate_line_lengths(self, file_path: Path, lines: List[str]) -> None:
        """Validate line length limits"""
        for i, line in enumerate(lines, 1):
            if len(line) > self.rules['max_line_length']:
                # Skip code blocks and URLs
                if not line.strip().startswith('```') and not re.search(r'https?://', line):
                    self.add_warning(
                        file_path, i, 'LINE_LENGTH',
                        f"Line exceeds {self.rules['max_line_length']} characters ({len(line)} chars)"
                    )

    def validate_heading_hierarchy(self, file_path: Path, lines: List[str]) -> None:
        """Validate proper heading hierarchy"""
        heading_levels = []

        for i, line in enumerate(lines, 1):
            if line.startswith('#'):
                level = len(line) - len(line.lstrip('#'))
                heading_levels.append((i, level, line.strip()))

        # Check for proper hierarchy (no skipping levels)
        for i in range(1, len(heading_levels)):
            current_level = heading_levels[i][1]
            prev_level = heading_levels[i-1][1]

            if current_level > prev_level + 1:
                self.add_violation(
                    file_path, heading_levels[i][0], 'HEADING_HIERARCHY',
                    f"Heading level {current_level} follows level {prev_level} (skipped level)"
                )

        # Check for numbered sections
        for line_num, level, heading in heading_levels:
            if level == 2:  # Main sections should be numbered
                if not re.match(r'^## \d+\.', heading):
                    self.add_warning(
                        file_path, line_num, 'HEADING_NUMBERING',
                        f"Main section not numbered: {heading}"
                    )

    def validate_navigation_footer(self, file_path: Path, content: str) -> None:
        """Validate presence of navigation footer"""
        footer_pattern = r'---\s*\n\s*## Navigation'

        if not re.search(footer_pattern, content):
            self.add_violation(
                file_path, -1, 'MISSING_NAVIGATION',
                "Document missing navigation footer"
            )

        # Check for required navigation elements
        nav_elements = ['Previous', 'Next', 'Index']
        for element in nav_elements:
            if f"**{element}:**" not in content:
                self.add_warning(
                    file_path, -1, 'INCOMPLETE_NAVIGATION',
                    f"Navigation missing '{element}' link"
                )

    def validate_wcag_compliance(self, file_path: Path, content: str) -> None:
        """Validate WCAG 2.1 AA compliance elements"""
        # Check for alt text on images
        img_pattern = r'!\[([^\]]*)\]\([^)]+\)'
        images = re.findall(img_pattern, content)

        for alt_text in images:
            if not alt_text.strip():
                self.add_violation(
                    file_path, -1, 'MISSING_ALT_TEXT',
                    "Image missing alt text for accessibility"
                )

        # Check for proper table headers
        if '|' in content:  # Contains tables
            lines = content.split('\n')
            in_table = False

            for i, line in enumerate(lines):
                if '|' in line and not in_table:
                    # Check if next line contains header separator
                    if i + 1 < len(lines) and '---' in lines[i + 1]:
                        in_table = True
                    else:
                        self.add_warning(
                            file_path, i + 1, 'TABLE_HEADERS',
                            "Table may be missing proper headers"
                        )
                elif '|' not in line:
                    in_table = False

    def add_violation(self, file_path: Path, line: int, rule: str, message: str) -> None:
        """Add a style guide violation"""
        self.violations.append({
            'file': str(file_path),
            'line': line,
            'rule': rule,
            'message': message,
            'severity': 'error'
        })
        self.stats['total_violations'] += 1

    def add_warning(self, file_path: Path, line: int, rule: str, message: str) -> None:
        """Add a style guide warning"""
        self.warnings.append({
            'file': str(file_path),
            'line': line,
            'rule': rule,
            'message': message,
            'severity': 'warning'
        })
        self.stats['total_warnings'] += 1

    def generate_report(self) -> Dict[str, Any]:
        """Generate validation report"""
        report = {
            'timestamp': datetime.now().isoformat(),
            'stats': self.stats,
            'violations': self.violations,
            'warnings': self.warnings,
            'summary': {
                'total_issues': len(self.violations) + len(self.warnings),
                'files_with_issues': len(set(
                    [v['file'] for v in self.violations] +
                    [w['file'] for w in self.warnings]
                ))
            }
        }

        # Save report
        report_path = f"reports/style-validation-{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        os.makedirs('reports', exist_ok=True)

        with open(report_path, 'w') as f:
            json.dump(report, f, indent=2)

        # Print summary
        print(f"\n📊 Style Validation Summary:")
        print(f"Files processed: {self.stats['files_processed']}")
        print(f"Violations: {self.stats['total_violations']}")
        print(f"Warnings: {self.stats['total_warnings']}")

        if self.violations:
            print(f"\n❌ Violations:")
            for violation in self.violations[:10]:  # Show first 10
                print(f"  {violation['file']}:{violation['line']} - {violation['message']}")

        if self.warnings:
            print(f"\n⚠️  Warnings:")
            for warning in self.warnings[:10]:  # Show first 10
                print(f"  {warning['file']}:{warning['line']} - {warning['message']}")

        print(f"\nDetailed report saved to: {report_path}")
        return report

if __name__ == "__main__":
    validator = DocumentationStyleValidator()
    results = validator.validate_all_files()

    # Exit with error code if violations found
    exit(1 if results['stats']['total_violations'] > 0 else 0)
```

## 4. Documentation Synchronization

### 4.1 Code-Documentation Sync Automation

```php
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use ReflectionClass;
use ReflectionMethod;

/**
 * Synchronize Documentation with Code Changes
 *
 * Automatically updates documentation when code structure changes,
 * ensuring documentation stays current with implementation.
 */
class SyncDocumentationCommand extends Command
{
    protected $signature = 'docs:sync {--check : Only check for inconsistencies}';
    protected $description = 'Synchronize documentation with code changes';

    private array $inconsistencies = [];
    private array $updates = [];

    public function handle(): int
    {
        $this->info('🔄 Starting documentation synchronization...');

        // Sync model documentation
        $this->syncModelDocumentation();

        // Sync resource documentation
        $this->syncResourceDocumentation();

        // Sync API documentation
        $this->syncApiDocumentation();

        // Generate report
        $this->generateSyncReport();

        return $this->inconsistencies ? 1 : 0;
    }

    private function syncModelDocumentation(): void
    {
        $this->info('Syncing model documentation...');

        $modelPath = app_path('Models/Chinook');
        $docPath = base_path('.ai/guides/chinook/010-chinook-models-guide.md');

        if (!File::exists($modelPath)) {
            $this->error("Model path not found: {$modelPath}");
            return;
        }

        $models = collect(File::files($modelPath))
            ->filter(fn($file) => $file->getExtension() === 'php')
            ->map(fn($file) => $file->getBasename('.php'));

        $docContent = File::get($docPath);

        foreach ($models as $modelName) {
            $this->syncModelClass($modelName, $docContent, $docPath);
        }
    }

    private function syncModelClass(string $modelName, string $docContent, string $docPath): void
    {
        $className = "App\\Models\\Chinook\\{$modelName}";

        if (!class_exists($className)) {
            $this->inconsistencies[] = [
                'type' => 'missing_class',
                'file' => $docPath,
                'message' => "Class {$className} not found but referenced in documentation"
            ];
            return;
        }

        $reflection = new ReflectionClass($className);

        // Check if model is documented
        if (!str_contains($docContent, "class {$modelName}")) {
            $this->inconsistencies[] = [
                'type' => 'missing_documentation',
                'file' => $docPath,
                'message' => "Model {$modelName} exists but not documented"
            ];

            if (!$this->option('check')) {
                $this->generateModelDocumentation($modelName, $reflection, $docPath);
            }
        }

        // Check methods documentation
        $this->syncModelMethods($modelName, $reflection, $docContent, $docPath);
    }

    private function syncModelMethods(string $modelName, ReflectionClass $reflection, string $docContent, string $docPath): void
    {
        $publicMethods = collect($reflection->getMethods(ReflectionMethod::IS_PUBLIC))
            ->filter(fn($method) => $method->getDeclaringClass()->getName() === $reflection->getName())
            ->filter(fn($method) => !in_array($method->getName(), ['__construct', '__get', '__set']));

        foreach ($publicMethods as $method) {
            $methodName = $method->getName();

            // Check if method is documented
            if (!str_contains($docContent, "public function {$methodName}")) {
                $this->inconsistencies[] = [
                    'type' => 'missing_method_documentation',
                    'file' => $docPath,
                    'message' => "Method {$modelName}::{$methodName}() exists but not documented"
                ];
            }
        }
    }

    private function generateModelDocumentation(string $modelName, ReflectionClass $reflection, string $docPath): void
    {
        $docTemplate = $this->generateModelDocTemplate($modelName, $reflection);

        // Insert documentation into existing file
        $content = File::get($docPath);
        $insertPoint = "## {$modelName} Model";

        if (!str_contains($content, $insertPoint)) {
            // Add new section
            $newSection = "\n\n{$insertPoint}\n\n{$docTemplate}";
            $content .= $newSection;

            File::put($docPath, $content);

            $this->updates[] = [
                'type' => 'model_documentation_added',
                'file' => $docPath,
                'message' => "Added documentation for {$modelName} model"
            ];
        }
    }

    private function generateModelDocTemplate(string $modelName, ReflectionClass $reflection): string
    {
        $template = "### {$modelName} Implementation\n\n";
        $template .= "```php\n";
        $template .= "<?php\n\n";
        $template .= "namespace {$reflection->getNamespaceName()};\n\n";

        // Add class documentation
        $template .= "/**\n";
        $template .= " * {$modelName} Model\n";
        $template .= " * \n";
        $template .= " * Auto-generated documentation from code analysis.\n";
        $template .= " * Last updated: " . date('Y-m-d H:i:s') . "\n";
        $template .= " */\n";
        $template .= "class {$modelName} extends BaseModel\n";
        $template .= "{\n";

        // Add public methods
        $publicMethods = collect($reflection->getMethods(ReflectionMethod::IS_PUBLIC))
            ->filter(fn($method) => $method->getDeclaringClass()->getName() === $reflection->getName());

        foreach ($publicMethods as $method) {
            $template .= "    /**\n";
            $template .= "     * {$method->getName()}\n";
            $template .= "     */\n";
            $template .= "    public function {$method->getName()}()\n";
            $template .= "    {\n";
            $template .= "        // Implementation details...\n";
            $template .= "    }\n\n";
        }

        $template .= "}\n";
        $template .= "```\n\n";

        return $template;
    }

    private function syncResourceDocumentation(): void
    {
        $this->info('Syncing Filament resource documentation...');

        // Similar implementation for Filament resources
        // Check app/Filament/Resources against documentation
    }

    private function syncApiDocumentation(): void
    {
        $this->info('Syncing API documentation...');

        // Check routes against API documentation
        // Validate endpoint documentation completeness
    }

    private function generateSyncReport(): void
    {
        $report = [
            'timestamp' => now()->toISOString(),
            'inconsistencies' => $this->inconsistencies,
            'updates' => $this->updates,
            'summary' => [
                'total_inconsistencies' => count($this->inconsistencies),
                'total_updates' => count($this->updates),
            ]
        ];

        $reportPath = storage_path('logs/doc-sync-' . now()->format('Y-m-d-H-i-s') . '.json');
        File::put($reportPath, json_encode($report, JSON_PRETTY_PRINT));

        // Output summary
        $this->info("\n📊 Documentation Sync Summary:");
        $this->info("Inconsistencies found: " . count($this->inconsistencies));
        $this->info("Updates made: " . count($this->updates));

        if ($this->inconsistencies) {
            $this->warn("\n⚠️  Inconsistencies:");
            foreach ($this->inconsistencies as $issue) {
                $this->warn("  {$issue['type']}: {$issue['message']}");
            }
        }

        if ($this->updates) {
            $this->info("\n✅ Updates made:");
            foreach ($this->updates as $update) {
                $this->info("  {$update['type']}: {$update['message']}");
            }
        }

        $this->info("\nDetailed report saved to: {$reportPath}");
    }
}
```

## 5. CI/CD Integration

### 5.1 GitHub Actions Workflow

```yaml
# .github/workflows/documentation-quality.yml
name: Documentation Quality Assurance

on:
  push:
    branches: [ main, develop ]
    paths: [ '.ai/guides/**', 'docs/**' ]
  pull_request:
    branches: [ main ]
    paths: [ '.ai/guides/**', 'docs/**' ]
  schedule:
    # Run daily at 2 AM UTC
    - cron: '0 2 * * *'

jobs:
  link-validation:
    name: Validate Documentation Links
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'
        cache: 'npm'

    - name: Install dependencies
      run: |
        npm install axios cheerio

    - name: Run link validation
      run: |
        node scripts/validate-links.js

    - name: Upload link validation report
      uses: actions/upload-artifact@v4
      if: always()
      with:
        name: link-validation-report
        path: reports/link-validation-*.json

  style-validation:
    name: Validate Documentation Style
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'

    - name: Run style validation
      run: |
        python scripts/validate-style.py

    - name: Upload style validation report
      uses: actions/upload-artifact@v4
      if: always()
      with:
        name: style-validation-report
        path: reports/style-validation-*.json

  accessibility-check:
    name: Check Documentation Accessibility
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'

    - name: Install accessibility tools
      run: |
        npm install -g @axe-core/cli pa11y-ci

    - name: Build documentation site
      run: |
        # Convert markdown to HTML for testing
        mkdir -p build
        find .ai/guides/chinook -name "*.md" -exec pandoc {} -o build/{}.html \;

    - name: Run accessibility tests
      run: |
        pa11y-ci build/*.html --sitemap false --threshold 10

  documentation-sync:
    name: Check Documentation Synchronization
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup PHP
      uses: shivammathur/setup-php@v2
      with:
        php-version: '8.4'
        extensions: mbstring, xml, ctype, iconv, intl, pdo_sqlite

    - name: Install Composer dependencies
      run: composer install --no-dev --optimize-autoloader

    - name: Check documentation sync
      run: |
        php artisan docs:sync --check

  generate-report:
    name: Generate Quality Report
    runs-on: ubuntu-latest
    needs: [link-validation, style-validation, accessibility-check, documentation-sync]
    if: always()

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Download all artifacts
      uses: actions/download-artifact@v4

    - name: Generate combined report
      run: |
        python scripts/generate-quality-report.py

    - name: Upload combined report
      uses: actions/upload-artifact@v4
      with:
        name: documentation-quality-report
        path: reports/quality-report-*.html

    - name: Comment on PR
      if: github.event_name == 'pull_request'
      uses: actions/github-script@v7
      with:
        script: |
          const fs = require('fs');
          const reportPath = 'reports/quality-summary.md';

          if (fs.existsSync(reportPath)) {
            const report = fs.readFileSync(reportPath, 'utf8');

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## 📋 Documentation Quality Report\n\n${report}`
            });
          }
```

## 6. Maintenance Workflows

### 6.1 Automated Maintenance Tasks

```bash
#!/bin/bash

# Daily Documentation Maintenance Script
# Performs routine maintenance tasks to keep documentation current

DOCS_DIR=".ai/guides/chinook"
LOG_FILE="logs/maintenance-$(date +%Y%m%d).log"
REPORT_DIR="reports/maintenance"

mkdir -p logs reports/maintenance

echo "🔧 Starting daily documentation maintenance..." | tee -a "$LOG_FILE"

# 1. Update last modified dates
echo "Updating last modified dates..." | tee -a "$LOG_FILE"
find "$DOCS_DIR" -name "*.md" -type f | while read -r file; do
    if git log -1 --format="%cd" --date=short -- "$file" > /dev/null 2>&1; then
        last_commit_date=$(git log -1 --format="%cd" --date=short -- "$file")

        # Update the "Last Updated" field in the file
        sed -i.bak "s/\*\*Last Updated:\*\* [0-9-]*/\*\*Last Updated:\*\* $last_commit_date/" "$file"

        if [ $? -eq 0 ]; then
            echo "Updated: $file -> $last_commit_date" | tee -a "$LOG_FILE"
        fi
    fi
done

# 2. Generate table of contents for index files
echo "Updating table of contents..." | tee -a "$LOG_FILE"
python3 scripts/generate-toc.py "$DOCS_DIR" | tee -a "$LOG_FILE"

# 3. Validate and fix internal links
echo "Validating internal links..." | tee -a "$LOG_FILE"
node scripts/validate-links.js --fix | tee -a "$LOG_FILE"

# 4. Check for orphaned files
echo "Checking for orphaned files..." | tee -a "$LOG_FILE"
find "$DOCS_DIR" -name "*.md" -type f | while read -r file; do
    filename=$(basename "$file")

    # Check if file is referenced in any other file
    if ! grep -r "$filename" "$DOCS_DIR" --exclude="$filename" > /dev/null; then
        echo "ORPHANED: $file" | tee -a "$LOG_FILE"
    fi
done

# 5. Update navigation links
echo "Updating navigation links..." | tee -a "$LOG_FILE"
python3 scripts/update-navigation.py "$DOCS_DIR" | tee -a "$LOG_FILE"

# 6. Generate maintenance report
echo "Generating maintenance report..." | tee -a "$LOG_FILE"
cat > "$REPORT_DIR/maintenance-$(date +%Y%m%d).md" << EOF
# Documentation Maintenance Report

**Date:** $(date)
**Status:** Completed

## Tasks Performed

- ✅ Updated last modified dates
- ✅ Generated table of contents
- ✅ Validated internal links
- ✅ Checked for orphaned files
- ✅ Updated navigation links

## Statistics

- Files processed: $(find "$DOCS_DIR" -name "*.md" | wc -l)
- Links validated: $(grep -r '\[.*\](.*)' "$DOCS_DIR" | wc -l)
- Orphaned files: $(grep "ORPHANED:" "$LOG_FILE" | wc -l)

## Issues Found

$(grep "ERROR\|WARNING\|ORPHANED" "$LOG_FILE" || echo "No issues found")

## Next Maintenance

Scheduled for: $(date -d "+1 day" +%Y-%m-%d)
EOF

echo "✅ Daily maintenance completed. Report saved to: $REPORT_DIR/maintenance-$(date +%Y%m%d).md" | tee -a "$LOG_FILE"
```

---

## Navigation

- **Previous:** [Advanced Troubleshooting Guides](./800-advanced-troubleshooting-guides.md)
- **Next:** [Chinook Documentation Index](./000-chinook-index.md)
- **Index:** [Chinook Documentation Index](./000-chinook-index.md)

## Related Documentation

- [Documentation Style Guide](./000-documentation-style-guide.md)
- [Visual Documentation Standards](./500-visual-documentation-standards.md)

---

**Last Updated:** 2025-07-16  
**Maintainer:** Technical Documentation Team  
**Source:** [GitHub Repository](https://github.com/s-a-c/chinook)
