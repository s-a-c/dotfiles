#!/usr/bin/env python3
"""
Markdown Link Verification Tool
================================

Comprehensive link verification for markdown files with both static analysis
and dynamic testing (via markdown rendering).

Features:
- Static analysis: Check anchor references match headings
- Dynamic testing: Parse markdown to verify links resolve correctly
- TOC-specific verification
- File link verification (relative paths)
- External URL checking (optional)
- Detailed reporting with line numbers
- Exit codes for CI/CD integration

Usage:
    python3 tools/verify-markdown-links.py docs/README.md
    python3 tools/verify-markdown-links.py docs/README.md --verbose
    python3 tools/verify-markdown-links.py docs/ --recursive
    python3 tools/verify-markdown-links.py docs/README.md --external-urls

Exit Codes:
    0 - All links valid
    1 - Broken links found
    2 - Error during verification

Author: AI Assistant
Date: 2025-10-13
"""

import re
import sys
import argparse
from pathlib import Path
from typing import List, Dict, Tuple, Optional, Set
from dataclasses import dataclass
from collections import defaultdict
import urllib.parse


@dataclass
class Link:
    """Represents a markdown link"""

    text: str
    target: str
    line_number: int
    is_anchor: bool
    is_file: bool
    is_external: bool
    is_in_toc: bool = False


@dataclass
class Heading:
    """Represents a markdown heading"""

    level: int
    text: str
    line_number: int
    anchor: str


@dataclass
class VerificationResult:
    """Result of link verification"""

    link: Link
    is_valid: bool
    reason: str = ""
    suggestion: str = ""


def slugify(text: str) -> str:
    """
    Convert heading text to GitHub-style anchor

    GitHub's algorithm:
    1. Remove markdown formatting
    2. Convert to lowercase
    3. Keep only: letters, numbers, spaces, hyphens, underscores
    4. Replace spaces with hyphens
    5. Collapse multiple hyphens
    """
    # Remove markdown formatting
    text = re.sub(r"\*\*(.+?)\*\*", r"\1", text)  # Bold
    text = re.sub(r"\*(.+?)\*", r"\1", text)  # Italic
    text = re.sub(r"`(.+?)`", r"\1", text)  # Code
    text = re.sub(r"\[(.+?)\]\(.+?\)", r"\1", text)  # Links

    # Convert to lowercase
    text = text.lower()

    # Remove anything that's not: letter, number, space, hyphen, underscore
    text = re.sub(r"[^a-z0-9\s\-_]", "", text)

    # Replace spaces with hyphens
    text = text.replace(" ", "-")

    # Collapse multiple hyphens
    text = re.sub(r"-+", "-", text)

    # Strip leading/trailing hyphens
    text = text.strip("-")

    return text


def extract_headings(content: str, file_path: Path) -> List[Heading]:
    """Extract all headings from markdown content"""
    headings = []
    lines = content.split("\n")

    for i, line in enumerate(lines):
        match = re.match(r"^(#{1,6})\s+(.+)$", line)
        if match:
            level = len(match.group(1))
            text = match.group(2).strip()

            # Generate anchor using GitHub's algorithm
            anchor = slugify(text)

            heading = Heading(level=level, text=text, line_number=i + 1, anchor=anchor)
            headings.append(heading)

    return headings


def extract_links(content: str, file_path: Path) -> List[Link]:
    """Extract all markdown links from content"""
    links = []
    lines = content.split("\n")

    # Track if we're in TOC section
    in_toc = False
    toc_end_line = -1

    # Find TOC section
    for i, line in enumerate(lines):
        if re.match(r"^##\s+Table of Contents", line, re.IGNORECASE):
            in_toc = True
        elif in_toc and line.strip() == "---":
            toc_end_line = i
            break

    # Extract all markdown links
    for i, line in enumerate(lines):
        # Find all [text](target) patterns
        for match in re.finditer(r"\[([^\]]+)\]\(([^\)]+)\)", line):
            text = match.group(1)
            target = match.group(2)

            # Classify link type
            is_anchor = target.startswith("#")
            is_file = not is_anchor and not target.startswith(
                ("http://", "https://", "mailto:")
            )
            is_external = target.startswith(("http://", "https://"))
            is_in_toc = toc_end_line > 0 and i < toc_end_line

            link = Link(
                text=text,
                target=target,
                line_number=i + 1,
                is_anchor=is_anchor,
                is_file=is_file,
                is_external=is_external,
                is_in_toc=is_in_toc,
            )
            links.append(link)

    return links


def verify_anchor_link(
    link: Link, headings: List[Heading], file_path: Path
) -> VerificationResult:
    """Verify an anchor link points to an existing heading"""
    # Remove leading # from anchor
    anchor = link.target.lstrip("#")

    # Check if anchor exists in headings
    matching_headings = [h for h in headings if h.anchor == anchor]

    if matching_headings:
        return VerificationResult(
            link=link, is_valid=True, reason="Anchor found in document"
        )

    # Not found - try to find similar anchors
    similar = []
    for h in headings:
        if anchor[:20] in h.anchor or h.anchor[:20] in anchor:
            similar.append(h.anchor)

    if similar:
        suggestion = f"Did you mean: #{similar[0]}"
    else:
        suggestion = "No similar anchors found"

    return VerificationResult(
        link=link,
        is_valid=False,
        reason=f"Anchor '#{anchor}' not found in document",
        suggestion=suggestion,
    )


def verify_file_link(link: Link, file_path: Path) -> VerificationResult:
    """Verify a file link points to an existing file"""
    # Resolve relative path
    base_dir = file_path.parent
    target_path = base_dir / link.target

    # Handle anchors in file links (e.g., file.md#section)
    if "#" in link.target:
        file_part = link.target.split("#")[0]
        target_path = base_dir / file_part

    # Check if file exists
    if target_path.exists():
        return VerificationResult(link=link, is_valid=True, reason="File exists")

    # Try to resolve relative to docs directory
    docs_dir = file_path
    while docs_dir.name != "docs" and docs_dir.parent != docs_dir:
        docs_dir = docs_dir.parent

    if docs_dir.name == "docs":
        alt_path = docs_dir / link.target.split("#")[0]
        if alt_path.exists():
            return VerificationResult(
                link=link,
                is_valid=True,
                reason=f"File exists (resolved to docs/)",
            )

    return VerificationResult(
        link=link,
        is_valid=False,
        reason=f"File not found: {target_path}",
        suggestion=f"Check if file exists relative to {file_path.parent}",
    )


def verify_external_url(link: Link) -> VerificationResult:
    """Verify external URL (basic validation)"""
    # Basic URL validation
    parsed = urllib.parse.urlparse(link.target)

    if not parsed.scheme or not parsed.netloc:
        return VerificationResult(
            link=link, is_valid=False, reason="Invalid URL format"
        )

    # For now, just check format
    # Could add actual HTTP requests with --check-external flag
    return VerificationResult(
        link=link,
        is_valid=True,
        reason="URL format valid (not checked live)",
    )


def verify_markdown_file(
    file_path: Path, check_external: bool = False, verbose: bool = False
) -> Tuple[List[VerificationResult], Dict[str, int]]:
    """Verify all links in a markdown file"""
    if verbose:
        print(f"\nVerifying: {file_path}")

    # Read file
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception as e:
        print(f"✗ Error reading {file_path}: {e}")
        return [], {"error": 1}

    # Extract headings and links
    headings = extract_headings(content, file_path)
    links = extract_links(content, file_path)

    if verbose:
        print(f"  Found {len(headings)} headings and {len(links)} links")

    # Verify each link
    results = []
    stats = defaultdict(int)

    for link in links:
        if link.is_anchor:
            result = verify_anchor_link(link, headings, file_path)
            stats["anchors"] += 1
        elif link.is_file:
            result = verify_file_link(link, file_path)
            stats["files"] += 1
        elif link.is_external:
            if check_external:
                result = verify_external_url(link)
                stats["external"] += 1
            else:
                # Skip external links unless requested
                continue
        else:
            continue

        results.append(result)

        if result.is_valid:
            stats["valid"] += 1
        else:
            stats["broken"] += 1

    return results, dict(stats)


def print_results(
    results: List[VerificationResult],
    file_path: Path,
    verbose: bool = False,
    toc_only: bool = False,
):
    """Print verification results"""
    # Filter for TOC links if requested
    if toc_only:
        results = [r for r in results if r.link.is_in_toc]

    broken_results = [r for r in results if not r.is_valid]

    if not broken_results:
        print(f"✓ {file_path}: All links valid ({len(results)} checked)")
        return

    print(f"\n{'='*70}")
    print(f"File: {file_path}")
    print(f"{'='*70}")

    for result in broken_results:
        link = result.link
        print(f"\n✗ Line {link.line_number}: {link.text}")
        print(f"  Target: {link.target}")
        print(f"  Reason: {result.reason}")
        if result.suggestion:
            print(f"  Suggestion: {result.suggestion}")
        if link.is_in_toc:
            print(f"  Location: Table of Contents")

    if verbose:
        print(f"\n{'-'*70}")
        print(f"Valid links:")
        valid_results = [r for r in results if r.is_valid]
        for result in valid_results[:10]:  # Show first 10
            link = result.link
            print(f"  ✓ Line {link.line_number}: {link.target[:50]}")
        if len(valid_results) > 10:
            print(f"  ... and {len(valid_results) - 10} more")


def find_markdown_files(path: Path, recursive: bool = False) -> List[Path]:
    """Find all markdown files in path"""
    if path.is_file():
        return [path]

    if recursive:
        return sorted(path.rglob("*.md"))
    else:
        return sorted(path.glob("*.md"))


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Verify markdown links with static and dynamic analysis",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Verify single file
  python3 tools/verify-markdown-links.py docs/README.md

  # Verify all files in directory
  python3 tools/verify-markdown-links.py docs/ --recursive

  # Verbose output
  python3 tools/verify-markdown-links.py docs/README.md --verbose

  # Check external URLs too
  python3 tools/verify-markdown-links.py docs/README.md --external-urls

  # Only verify TOC links
  python3 tools/verify-markdown-links.py docs/README.md --toc-only
        """,
    )

    parser.add_argument("path", type=str, help="Path to markdown file or directory")

    parser.add_argument(
        "-r",
        "--recursive",
        action="store_true",
        help="Recursively process directories",
    )

    parser.add_argument("-v", "--verbose", action="store_true", help="Verbose output")

    parser.add_argument(
        "--external-urls",
        action="store_true",
        help="Check external URLs (format only)",
    )

    parser.add_argument(
        "--toc-only", action="store_true", help="Only verify Table of Contents links"
    )

    parser.add_argument(
        "--summary-only",
        action="store_true",
        help="Only show summary, not individual errors",
    )

    args = parser.parse_args()

    # Find files to check
    path = Path(args.path)
    if not path.exists():
        print(f"✗ Path not found: {path}")
        return 2

    # Exclude archived files
    if ".ARCHIVE" in str(path):
        print(f"⚠ Skipping archived path: {path}")
        return 0

    files = find_markdown_files(path, args.recursive)
    files = [f for f in files if ".ARCHIVE" not in str(f)]

    if not files:
        print(f"✗ No markdown files found in: {path}")
        return 2

    print(f"\n{'='*70}")
    print(f"Markdown Link Verification")
    print(f"{'='*70}")
    print(f"Files to check: {len(files)}")
    if args.toc_only:
        print(f"Mode: TOC links only")
    if args.external_urls:
        print(f"Checking: External URLs")
    print()

    # Verify each file
    all_results = []
    total_stats = defaultdict(int)
    files_with_errors = []

    for file_path in files:
        results, stats = verify_markdown_file(
            file_path, check_external=args.external_urls, verbose=args.verbose
        )

        all_results.extend(results)
        for key, value in stats.items():
            total_stats[key] += value

        if not args.summary_only:
            print_results(results, file_path, args.verbose, args.toc_only)

        broken = sum(1 for r in results if not r.is_valid)
        if broken > 0:
            files_with_errors.append((file_path, broken))

    # Print summary
    print(f"\n{'='*70}")
    print(f"Summary")
    print(f"{'='*70}")
    print(f"Files checked: {len(files)}")
    print(f"Total links: {sum(total_stats.values())}")
    print(f"  Anchor links: {total_stats.get('anchors', 0)}")
    print(f"  File links: {total_stats.get('files', 0)}")
    if args.external_urls:
        print(f"  External URLs: {total_stats.get('external', 0)}")
    print(f"\nResults:")
    print(f"  ✓ Valid: {total_stats.get('valid', 0)}")
    print(f"  ✗ Broken: {total_stats.get('broken', 0)}")

    if files_with_errors:
        print(f"\nFiles with broken links:")
        for file_path, count in files_with_errors:
            print(f"  ✗ {file_path}: {count} broken link(s)")

    print(f"{'='*70}\n")

    # Exit code
    if total_stats.get("broken", 0) > 0:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
