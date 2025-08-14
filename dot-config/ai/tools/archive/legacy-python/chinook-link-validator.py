#!/usr/bin/env python3
"""
Chinook Documentation Link Validator
Comprehensive link validation for educational documentation
"""

import os
import re
import json
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple
from urllib.parse import urlparse
import urllib.request
import urllib.error
from datetime import datetime

class ChinookLinkValidator:
    def __init__(self, base_dir: str = ".ai/guides/chinook"):
        self.base_dir = Path(base_dir)
        self.all_files: Set[str] = set()
        self.broken_links: List[Dict] = []
        self.validation_results: Dict = {}
        
    def scan_markdown_files(self) -> List[Path]:
        """Recursively find all markdown files"""
        md_files = []
        for root, dirs, files in os.walk(self.base_dir):
            for file in files:
                if file.endswith('.md'):
                    md_files.append(Path(root) / file)
        return sorted(md_files)
    
    def extract_links(self, file_path: Path) -> List[Tuple[str, str]]:
        """Extract all markdown links from file"""
        links = []
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Match [text](url) patterns
            link_pattern = r'\[([^\]]*)\]\(([^)]+)\)'
            matches = re.findall(link_pattern, content)
            
            for text, url in matches:
                # Skip empty links and anchors-only
                if url and not url.startswith('#'):
                    links.append((text, url))
                    
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            
        return links
    
    def validate_internal_link(self, source_file: Path, link_url: str) -> Dict:
        """Validate internal markdown link"""
        result = {
            'source': str(source_file.relative_to(self.base_dir)),
            'url': link_url,
            'type': 'internal',
            'status': 'unknown',
            'exists': False
        }
        
        # Handle anchor links
        if '#' in link_url:
            file_part, anchor = link_url.split('#', 1)
            result['anchor'] = anchor
        else:
            file_part = link_url
            result['anchor'] = None
            
        # Resolve relative path
        if file_part.startswith('./'):
            target_path = source_file.parent / file_part[2:]
        elif file_part.startswith('../'):
            target_path = source_file.parent / file_part
        else:
            target_path = self.base_dir / file_part
            
        # Normalize path
        try:
            target_path = target_path.resolve()
        except Exception:
            result['status'] = 'invalid_path'
            return result
            
        # Check if file exists
        if target_path.exists() and target_path.is_file():
            result['exists'] = True
            result['status'] = 'valid'
            
            # Validate anchor if present
            if result['anchor']:
                if self.validate_anchor(target_path, result['anchor']):
                    result['status'] = 'valid'
                else:
                    result['status'] = 'broken_anchor'
        else:
            result['status'] = 'file_not_found'
            result['resolved_path'] = str(target_path)
            
        return result
    
    def validate_anchor(self, file_path: Path, anchor: str) -> bool:
        """Check if anchor exists in target file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Convert anchor to possible heading formats
            anchor_clean = anchor.lower().replace('-', ' ')
            
            # Look for heading that matches anchor
            anchor_patterns = [
                f"#{anchor}",  # Direct anchor
                f"## {anchor_clean}",  # Heading format
                f"### {anchor_clean}",  # Subheading format
                f"#### {anchor_clean}",  # Sub-subheading format
                f"# {anchor_clean}",  # Main heading format
            ]
            
            content_lower = content.lower()
            for pattern in anchor_patterns:
                if pattern.lower() in content_lower:
                    return True
                    
            # Also check for numbered headings
            numbered_patterns = [
                f"## {anchor.replace('-', '.')} ",  # 1.1 format
                f"### {anchor.replace('-', '.')} ",  # 1.1.1 format
            ]
            
            for pattern in numbered_patterns:
                if pattern.lower() in content_lower:
                    return True
                    
        except Exception:
            pass
            
        return False
    
    def run_validation(self) -> Dict:
        """Execute complete validation process"""
        print("🔍 Starting Chinook link validation...")
        
        # Discover all markdown files
        md_files = self.scan_markdown_files()
        print(f"📄 Found {len(md_files)} markdown files")
        
        # Process each file
        total_links = 0
        broken_count = 0
        
        for file_path in md_files:
            file_results = {
                'file': str(file_path.relative_to(self.base_dir)),
                'links': [],
                'broken_links': []
            }
            
            links = self.extract_links(file_path)
            total_links += len(links)
            
            for text, url in links:
                # Skip external links for now
                if url.startswith(('http://', 'https://', 'mailto:')):
                    continue
                    
                # Validate internal link
                result = self.validate_internal_link(file_path, url)
                file_results['links'].append(result)
                
                if result['status'] != 'valid':
                    file_results['broken_links'].append(result)
                    broken_count += 1
                    
            self.validation_results[str(file_path.relative_to(self.base_dir))] = file_results
            
        # Generate summary
        summary = {
            'total_files': len(md_files),
            'total_links': total_links,
            'broken_links': broken_count,
            'success_rate': ((total_links - broken_count) / total_links * 100) if total_links > 0 else 100,
            'timestamp': datetime.now().isoformat()
        }
        
        print(f"✅ Validation complete: {summary['success_rate']:.1f}% success rate")
        print(f"🔗 {total_links} total links, {broken_count} broken")
        
        return {
            'summary': summary,
            'results': self.validation_results
        }
    
    def generate_report(self, results: Dict) -> str:
        """Generate comprehensive validation report"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        report = f"""# Chinook Documentation Link Validation Report

**Generated:** {timestamp}  
**Files Scanned:** {results['summary']['total_files']}  
**Links Validated:** {results['summary']['total_links']}  
**Success Rate:** {results['summary']['success_rate']:.1f}%

## Summary

- ✅ **Working Links**: {results['summary']['total_links'] - results['summary']['broken_links']}
- ❌ **Broken Links**: {results['summary']['broken_links']}

"""
        
        if results['summary']['broken_links'] == 0:
            report += "🎉 **All links are working correctly!**\n\n"
        else:
            report += "## Broken Links Detail\n\n"
            
            for file_path, file_results in results['results'].items():
                if file_results['broken_links']:
                    report += f"### {file_path}\n\n"
                    for broken in file_results['broken_links']:
                        status_emoji = {
                            'file_not_found': '📄',
                            'broken_anchor': '⚓',
                            'invalid_path': '🔗'
                        }.get(broken['status'], '❌')
                        
                        report += f"- {status_emoji} `{broken['url']}` - {broken['status']}\n"
                        if 'resolved_path' in broken:
                            report += f"  - Resolved to: `{broken['resolved_path']}`\n"
                    report += "\n"
        
        report += """## Validation Process

This report was generated by the Chinook automated link validation system. The validator:

1. Scans all markdown files in `.ai/guides/chinook/`
2. Extracts all internal links (excluding external URLs)
3. Validates file existence and anchor targets
4. Reports broken links with specific error types

## Next Steps

If broken links are found:
1. Review the broken links listed above
2. Fix file paths or create missing files
3. Update anchor references to match actual headings
4. Re-run validation to confirm fixes

---

**Validation Tool:** Chinook Link Validator v1.0  
**Source:** [GitHub Repository](https://github.com/s-a-c/chinook)
"""
        
        return report

def main():
    """Main execution function"""
    # Create reports directory
    reports_dir = Path('.ai/reports/chinook/2025-07-16/sprint-5')
    reports_dir.mkdir(parents=True, exist_ok=True)
    
    # Run validation
    validator = ChinookLinkValidator()
    results = validator.run_validation()
    
    # Save results
    results_file = reports_dir / 'link-validation-results.json'
    with open(results_file, 'w') as f:
        json.dump(results, f, indent=2)
    
    # Generate report
    report = validator.generate_report(results)
    report_file = reports_dir / 'link-validation-report.md'
    with open(report_file, 'w') as f:
        f.write(report)
    
    print(f"📄 Results saved to: {results_file}")
    print(f"📄 Report saved to: {report_file}")
    
    # Exit with error code if broken links found
    if results['summary']['broken_links'] > 0:
        print(f"\n❌ Found {results['summary']['broken_links']} broken links!")
        sys.exit(1)
    else:
        print("\n✅ All links validated successfully!")
        sys.exit(0)

if __name__ == "__main__":
    main()
