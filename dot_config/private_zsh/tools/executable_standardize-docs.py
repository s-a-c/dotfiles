#!/usr/bin/env python3
"""
Documentation Standardization Script
=====================================

This script processes all markdown files in the docs/ directory to ensure:
1. All headings are numbered (H1, H2, H3, H4)
2. Each document has a complete Table of Contents
3. Each document has a navigation footer (Previous | Next | Top)

Usage:
    python3 tools/standardize-docs.py [--dry-run] [--file FILE]

Options:
    --dry-run    Show what would be changed without modifying files
    --file FILE  Process only the specified file
    --help       Show this help message

Author: AI Assistant
Date: 2025-10-13
"""

import re
import sys
import argparse
from pathlib import Path
from typing import List, Tuple, Dict, Optional
from dataclasses import dataclass


@dataclass
class Heading:
    """Represents a markdown heading"""

    level: int
    text: str
    original_line: str
    line_number: int
    number: str = ""
    anchor: str = ""


@dataclass
class DocumentMetadata:
    """Metadata about a document"""

    path: Path
    title: str
    headings: List[Heading]
    has_toc: bool
    has_navigation: bool


# Define the logical order of documentation files
DOCUMENTATION_ORDER = [
    "README.md",
    # Core Documentation (000-070)
    "000-index.md",
    "010-overview.md",
    "020-architecture.md",
    "030-activation-flow.md",
    "040-security-system.md",
    "050-performance-monitoring.md",
    "060-plugin-management.md",
    "070-layered-system.md",
    # Feature Documentation (100-165)
    "100-development-tools.md",
    "110-productivity-features.md",
    "120-terminal-integration.md",
    "130-history-management.md",
    "140-completion-system.md",
    "150-troubleshooting-startup-warnings.md",
    "160-option-files-comparison.md",
    "165-options-consolidation-summary.md",
    # Analysis & Assessment (200-230)
    "200-current-state.md",
    "210-issues-inconsistencies.md",
    "220-improvement-recommendations.md",
    "230-naming-convention-analysis.md",
    # Visual Documentation (300-310)
    "300-architecture-diagrams.md",
    "310-flow-diagrams.md",
    # ZSH REDESIGN Project (400-redesign/)
    "400-redesign/000-index.md",
    "400-redesign/010-implementation-plan.md",
    "400-redesign/020-symlink-architecture.md",
    "400-redesign/030-versioned-strategy.md",
    "400-redesign/040-implementation-guide.md",
    "400-redesign/050-testing-framework.md",
    "400-redesign/060-risk-assessment.md",
    "400-redesign/070-maintenance-guide.md",
]


def slugify(text: str) -> str:
    """Convert heading text to URL-safe anchor"""
    # Remove markdown formatting
    text = re.sub(r"\*\*(.+?)\*\*", r"\1", text)  # Bold
    text = re.sub(r"\*(.+?)\*", r"\1", text)  # Italic
    text = re.sub(r"`(.+?)`", r"\1", text)  # Code
    text = re.sub(r"\[(.+?)\]\(.+?\)", r"\1", text)  # Links

    # Convert to lowercase and replace spaces/special chars with hyphens
    text = text.lower()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[-\s]+", "-", text)
    text = text.strip("-")

    return text


def extract_headings(content: str) -> List[Heading]:
    """Extract all headings from markdown content"""
    headings = []
    lines = content.split("\n")

    for i, line in enumerate(lines):
        # Match markdown headings (# Header)
        match = re.match(r"^(#{1,4})\s+(.+)$", line)
        if match:
            level = len(match.group(1))
            text = match.group(2).strip()

            # Remove existing numbering if present
            text = re.sub(r"^\d+(\.\d+)*\.?\s+", "", text)

            heading = Heading(level=level, text=text, original_line=line, line_number=i)
            headings.append(heading)

    return headings


def number_headings(headings: List[Heading]) -> List[Heading]:
    """Add hierarchical numbering to headings"""
    counters = [0, 0, 0, 0]  # For H1, H2, H3, H4

    for heading in headings:
        level = heading.level - 1  # Convert to 0-based index

        # Increment current level counter
        counters[level] += 1

        # Reset deeper level counters
        for i in range(level + 1, 4):
            counters[i] = 0

        # Build number string
        number_parts = [str(c) for c in counters[: level + 1] if c > 0]
        heading.number = ".".join(number_parts)

        # Generate anchor - GitHub/markdown uses numbered heading in anchor
        numbered_text = f"{heading.number} {heading.text}"
        heading.anchor = slugify(numbered_text)

    return headings


def generate_toc(headings: List[Heading], title: str) -> str:
    """Generate table of contents"""
    if not headings:
        return ""

    toc_lines = ["## Table of Contents", ""]

    for heading in headings:
        # Skip the main title (H1)
        if heading.level == 1:
            continue

        indent = "  " * (heading.level - 2)  # H2 = no indent, H3 = 2 spaces, etc.
        link_text = f"{heading.number}. {heading.text}"
        # Anchor uses the numbered heading
        link_anchor = f"#{heading.anchor}"

        toc_lines.append(f"{indent}- [{link_text}]({link_anchor})")

    toc_lines.append("")
    toc_lines.append("---")
    toc_lines.append("")

    return "\n".join(toc_lines)


def get_navigation_links(current_file: str) -> Tuple[Optional[str], Optional[str]]:
    """Get previous and next file paths for navigation"""
    try:
        current_index = DOCUMENTATION_ORDER.index(current_file)
    except ValueError:
        # File not in standard order, no navigation
        return None, None

    prev_file = DOCUMENTATION_ORDER[current_index - 1] if current_index > 0 else None
    next_file = (
        DOCUMENTATION_ORDER[current_index + 1]
        if current_index < len(DOCUMENTATION_ORDER) - 1
        else None
    )

    return prev_file, next_file


def get_file_title(path: Path) -> str:
    """Extract or generate a display title for a file"""
    name = path.stem

    # Special cases
    if name == "README":
        return "Documentation Home"
    if name == "000-index":
        return "Master Index"

    # Remove number prefix
    name = re.sub(r"^\d+-", "", name)

    # Convert hyphens to spaces and title case
    return name.replace("-", " ").title()


def generate_navigation_footer(current_file: str, title_anchor: str) -> str:
    """Generate navigation footer with Previous | Next | Top links"""
    prev_file, next_file = get_navigation_links(current_file)

    nav_parts = []

    # Previous link
    if prev_file:
        prev_title = get_file_title(Path(prev_file))
        nav_parts.append(f"[← {prev_title}]({prev_file})")

    # Top link (always present)
    nav_parts.append(f"[Top ↑]({title_anchor})")

    # Next link
    if next_file:
        next_title = get_file_title(Path(next_file))
        nav_parts.append(f"[{next_title} →]({next_file})")

    footer = [
        "",
        "---",
        "",
        f"**Navigation:** {' | '.join(nav_parts)}",
        "",
        "---",
        "",
        f"*Last updated: {get_timestamp()}*",
        "",
    ]

    return "\n".join(footer)


def get_timestamp() -> str:
    """Get current timestamp for documentation"""
    from datetime import datetime

    return datetime.now().strftime("%Y-%m-%d")


def process_document(file_path: Path, dry_run: bool = False) -> bool:
    """Process a single markdown document"""
    print(f"\n{'[DRY RUN] ' if dry_run else ''}Processing: {file_path}")

    # Read content
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception as e:
        print(f"  ✗ Error reading file: {e}")
        return False

    # Extract headings
    headings = extract_headings(content)
    if not headings:
        print(f"  ⚠ No headings found, skipping")
        return False

    # Number headings first
    headings = number_headings(headings)

    # Get main title (first H1) - use the numbered version for anchor
    if headings and headings[0].level == 1:
        title = headings[0].text
        # Anchor uses numbered heading as it appears in the document
        numbered_title = f"{headings[0].number} {headings[0].text}"
        title_anchor = f"#{slugify(numbered_title)}"
    else:
        title = file_path.stem
        title_anchor = f"#{slugify(title)}"

    # Generate new content
    lines = content.split("\n")
    new_lines = []

    # Track what we've added
    toc_added = False
    nav_added = False
    current_heading_idx = 0

    i = 0
    while i < len(lines):
        line = lines[i]

        # Check if this is a heading line
        is_heading = False
        if current_heading_idx < len(headings):
            if i == headings[current_heading_idx].line_number:
                is_heading = True
                heading = headings[current_heading_idx]

                # Replace with numbered heading
                prefix = "#" * heading.level
                new_line = f"{prefix} {heading.number}. {heading.text}"
                new_lines.append(new_line)

                # Add TOC after first heading (H1)
                if heading.level == 1 and not toc_added:
                    new_lines.append("")
                    new_lines.append(generate_toc(headings, title))
                    toc_added = True

                current_heading_idx += 1
                i += 1
                continue

        # Check for existing TOC to remove
        if line.strip() == "## Table of Contents":
            # Skip until next heading or blank lines
            while i < len(lines) and not re.match(r"^#{1,4}\s+", lines[i]):
                i += 1
            continue

        # Check for existing navigation footer (last 30 lines)
        if i > len(lines) - 30:
            if "**Navigation:**" in line or "*Last updated:" in line:
                # Part of old navigation, skip
                i += 1
                continue
            if line.strip() == "---" and i > len(lines) - 15:
                # Likely part of old navigation
                i += 1
                continue

        new_lines.append(line)
        i += 1

    # Remove trailing blank lines before adding navigation
    while new_lines and new_lines[-1].strip() == "":
        new_lines.pop()

    # Add navigation footer at the end
    # Get relative path from docs directory
    docs_dir = file_path.parent
    while docs_dir.name != "docs" and docs_dir.parent != docs_dir:
        docs_dir = docs_dir.parent

    if docs_dir.name == "docs":
        relative_path = file_path.relative_to(docs_dir)
    else:
        relative_path = file_path.name

    nav_footer = generate_navigation_footer(str(relative_path), title_anchor)
    new_lines.append(nav_footer)

    # Join and clean up
    new_content = "\n".join(new_lines)

    # Remove excessive blank lines (more than 2 consecutive)
    new_content = re.sub(r"\n{4,}", "\n\n\n", new_content)

    # Ensure file ends with single newline
    new_content = new_content.rstrip() + "\n"

    # Write back
    if not dry_run:
        try:
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(new_content)
            print(f"  ✓ Updated successfully")
            return True
        except Exception as e:
            print(f"  ✗ Error writing file: {e}")
            return False
    else:
        print(f"  ✓ Would update (dry run)")
        print(f"    - Added numbering to {len(headings)} headings")
        print(
            f"    - Generated TOC with {len([h for h in headings if h.level > 1])} entries"
        )
        print(f"    - Added navigation footer")
        return True


def find_markdown_files(docs_dir: Path) -> List[Path]:
    """Find all markdown files in docs directory, excluding archives"""
    md_files = []

    for file_path in docs_dir.rglob("*.md"):
        # Skip archived files
        if ".ARCHIVE" in str(file_path):
            continue

        # Skip hidden files
        if any(part.startswith(".") for part in file_path.parts):
            continue

        md_files.append(file_path)

    return sorted(md_files)


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Standardize markdown documentation files",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Process all files (dry run)
  python3 tools/standardize-docs.py --dry-run

  # Process all files (actual changes)
  python3 tools/standardize-docs.py

  # Process single file
  python3 tools/standardize-docs.py --file docs/010-overview.md
        """,
    )

    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be changed without modifying files",
    )

    parser.add_argument("--file", type=str, help="Process only the specified file")

    parser.add_argument(
        "--yes",
        "-y",
        action="store_true",
        help="Skip confirmation prompt (auto-confirm)",
    )

    args = parser.parse_args()

    # Determine base directory
    script_dir = Path(__file__).parent
    repo_root = script_dir.parent
    docs_dir = repo_root / "docs"

    if not docs_dir.exists():
        print(f"✗ Documentation directory not found: {docs_dir}")
        return 1

    # Get files to process
    if args.file:
        files = [Path(args.file)]
        if not files[0].exists():
            print(f"✗ File not found: {args.file}")
            return 1
    else:
        files = find_markdown_files(docs_dir)

    if not files:
        print("✗ No markdown files found to process")
        return 1

    # Process files
    print(f"\n{'='*60}")
    print(f"Documentation Standardization")
    print(f"{'='*60}")
    print(
        f"\nMode: {'DRY RUN (no changes)' if args.dry_run else 'LIVE (will modify files)'}"
    )
    print(f"Files to process: {len(files)}")

    if not args.dry_run and not args.yes:
        response = input("\nContinue? [y/N]: ")
        if response.lower() != "y":
            print("Cancelled.")
            return 0

    success_count = 0
    fail_count = 0

    for file_path in files:
        if process_document(file_path, dry_run=args.dry_run):
            success_count += 1
        else:
            fail_count += 1

    # Summary
    print(f"\n{'='*60}")
    print(f"Summary")
    print(f"{'='*60}")
    print(f"✓ Successfully processed: {success_count}")
    if fail_count > 0:
        print(f"✗ Failed: {fail_count}")
    print()

    return 0 if fail_count == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
