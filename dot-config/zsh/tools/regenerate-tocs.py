#!/usr/bin/env python3
"""
Documentation TOC Regeneration Script
======================================

This script regenerates Table of Contents for all markdown files in docs/,
replacing any existing TOCs with properly calculated ones.

Features:
- Extracts all headings (H1-H4) from each document
- Generates hierarchical TOC with proper numbering
- Replaces existing TOC sections completely
- Preserves all other content
- Adds navigation footer if missing
- Optional link verification after regeneration

Usage:
    python3 tools/regenerate-tocs.py [--dry-run] [--file FILE] [--verify] [--collapsible] [--dual-anchors]

Options:
    --dry-run       Show what would be changed without modifying files
    --file FILE     Process only the specified file
    --verify        Verify links after regeneration
    --collapsible   Make TOC collapsible using HTML details/summary tags
    --dual-anchors  Include both GitHub and Zed-style anchors for compatibility
    --help          Show this help message

Author: AI Assistant
Date: 2025-10-13
"""

import re
import sys
import argparse
import subprocess
from pathlib import Path
from typing import List, Tuple, Optional
from dataclasses import dataclass


@dataclass
class Heading:
    """Represents a markdown heading"""

    level: int
    text: str
    line_number: int
    number: str = ""
    anchor: str = ""


# Define the logical order of documentation files for navigation
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
    """Convert heading text to URL-safe anchor (GitHub markdown style)

    GitHub's algorithm:
    1. Remove markdown formatting
    2. Convert to lowercase
    3. Remove anything that's not: letter, number, space, hyphen, or underscore
    4. Replace spaces with hyphens
    5. Collapse multiple hyphens
    """
    # Remove markdown formatting
    text = re.sub(r"\*\*(.+?)\*\*", r"\1", text)  # Bold
    text = re.sub(r"\*(.+?)\*", r"\1", text)  # Italic
    text = re.sub(r"`(.+?)`", r"\1", text)  # Code
    text = re.sub(r"\[(.+?)\]\(.+?\)", r"\1", text)  # Links

    # Convert to lowercase first
    text = text.lower()

    # Remove anything that's not: letter, number, space, hyphen, underscore
    # GitHub keeps: a-z, 0-9, space, -, _
    text = re.sub(r"[^a-z0-9\s\-_]", "", text)

    # Replace spaces with hyphens
    text = text.replace(" ", "-")

    # Collapse multiple hyphens into one
    text = re.sub(r"-+", "-", text)

    # Strip leading/trailing hyphens
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

            # Skip "Table of Contents" heading to prevent self-referential TOC entries
            if text.lower() == "table of contents":
                continue

            heading = Heading(level=level, text=text, line_number=i)
            headings.append(heading)

    return headings


def number_headings(headings: List[Heading]) -> List[Heading]:
    """Add hierarchical numbering to headings (skip H1 - document title)"""
    counters = [0, 0, 0, 0]  # For H1, H2, H3, H4

    for heading in headings:
        level = heading.level - 1  # Convert to 0-based index

        # Don't number H1 (document title)
        if level == 0:
            heading.number = ""
            heading.anchor = slugify(heading.text)
            continue

        # Increment current level counter
        counters[level] += 1

        # Reset deeper level counters
        for i in range(level + 1, 4):
            counters[i] = 0

        # Build number string
        number_parts = [str(c) for c in counters[: level + 1] if c > 0]
        heading.number = ".".join(number_parts)

        # Generate anchor - GitHub keeps numbers in anchors
        # So "1.2. My Heading" becomes anchor "#12-my-heading"
        numbered_text = f"{heading.number}. {heading.text}"
        heading.anchor = slugify(numbered_text)

    return headings


def generate_toc(headings: List[Heading], collapsible: bool = False) -> str:
    """Generate table of contents from headings"""
    if not headings:
        return ""

    if collapsible:
        toc_lines = [
            "## Table of Contents",
            "",
            "<details>",
            "<summary>Click to expand</summary>",
            "",
        ]
    else:
        toc_lines = ["## Table of Contents", ""]

    for heading in headings:
        # Skip the main title (H1)
        if heading.level == 1:
            continue

        # Calculate indent (H2 = no indent, H3 = 2 spaces, H4 = 4 spaces)
        indent = "  " * (heading.level - 2)
        link_text = f"{heading.number}. {heading.text}"
        # Anchor uses the numbered heading
        link_anchor = f"#{heading.anchor}"
        toc_lines.append(f"{indent}- [{link_text}]({link_anchor})")

    toc_lines.append("")

    if collapsible:
        toc_lines.append("</details>")
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
        f"*Last updated: 2025-10-13*",
        "",
    ]

    return "\n".join(footer)


def remove_existing_toc(lines: List[str]) -> Tuple[List[str], int]:
    """
    Remove ALL existing TOC sections from content.
    Returns cleaned lines and the index where first TOC was found (or -1).
    """
    first_toc_position = -1

    while True:
        toc_start = -1
        toc_end = -1

        # Find TOC section
        for i, line in enumerate(lines):
            if re.match(r"^##\s+(\d+\.)?\s*Table of Contents", line, re.IGNORECASE):
                toc_start = i
                if first_toc_position == -1:
                    first_toc_position = i
                # Find the end of TOC (next ## heading or end of separators)
                for j in range(i + 1, len(lines)):
                    # Next heading at same or higher level
                    if (
                        re.match(r"^#{1,2}\s+", lines[j])
                        and "Table of Contents" not in lines[j]
                    ):
                        toc_end = j
                        break
                    # Separator after some content
                    if lines[j].strip() == "---" and j > i + 3:
                        toc_end = j + 1
                        break
                if toc_end == -1:
                    toc_end = len(lines)
                break

        if toc_start == -1:
            # No more TOCs found
            break

        # Remove TOC section
        lines = lines[:toc_start] + lines[toc_end:]

    return lines, first_toc_position


def remove_existing_navigation(lines: List[str]) -> List[str]:
    """Remove existing navigation footer from content"""
    # Navigation is typically in the last 20 lines
    if len(lines) < 20:
        return lines

    # Find navigation section (work backwards from end)
    nav_start = -1
    for i in range(len(lines) - 1, max(len(lines) - 30, 0), -1):
        if "**Navigation:**" in lines[i]:
            # Find the start (usually a --- before it)
            for j in range(i, max(i - 10, 0), -1):
                if lines[j].strip() == "---":
                    nav_start = j
                    break
            if nav_start == -1:
                nav_start = i
            break

    if nav_start == -1:
        return lines

    # Remove from nav_start to end
    return lines[:nav_start]


def process_document(
    file_path: Path,
    dry_run: bool = False,
    collapsible: bool = False,
) -> bool:
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

    # Number headings
    headings = number_headings(headings)

    # Get main title for navigation (H1 is not numbered)
    if headings and headings[0].level == 1:
        title_anchor = f"#{slugify(headings[0].text)}"
    else:
        title_anchor = f"#{slugify(file_path.stem)}"

    # Generate new TOC
    new_toc = generate_toc(headings, collapsible=collapsible)

    # Split content into lines
    lines = content.split("\n")

    # Remove existing TOC
    lines, toc_position = remove_existing_toc(lines)

    # Remove existing navigation
    lines = remove_existing_navigation(lines)

    # Find where to insert TOC (after first H1 heading only)
    insert_position = -1
    for i, line in enumerate(lines):
        if re.match(r"^#\s+[^#]", line):  # H1 only (single #)
            insert_position = i + 1
            break

    if insert_position == -1:
        print(f"  ⚠ Could not find main heading (H1), skipping")
        return False

    # Insert new TOC with blank line before it
    toc_lines = new_toc.split("\n")
    lines = lines[:insert_position] + [""] + toc_lines + lines[insert_position:]

    # Update heading numbering in content
    # Track which headings we've used to handle duplicates
    heading_usage_count = {}
    new_lines = []

    for i, line in enumerate(lines):
        # Check if this line is a heading we need to renumber
        match = re.match(r"^(#{1,4})\s+(.+)$", line)
        if match:
            level = len(match.group(1))
            text = match.group(2).strip()
            # Remove existing numbering
            text = re.sub(r"^\d+(\.\d+)*\.?\s+", "", text)

            # Skip TOC heading - don't number it
            if "Table of Contents" in text:
                new_lines.append(line)
                continue

            # Find matching heading by level and text, accounting for duplicates
            # Use a key that tracks how many times we've seen this level+text combo
            key = (level, text)
            current_usage = heading_usage_count.get(key, 0)

            matching_heading = None
            usage_count = 0
            for h in headings:
                if h.level == level and h.text == text:
                    if usage_count == current_usage:
                        matching_heading = h
                        heading_usage_count[key] = current_usage + 1
                        break
                    usage_count += 1

            if matching_heading:
                # H1 doesn't get numbered
                if matching_heading.number:
                    new_line = f"{'#' * level} {matching_heading.number}. {matching_heading.text}"
                else:
                    new_line = f"{'#' * level} {matching_heading.text}"
                new_lines.append(new_line)
            else:
                new_lines.append(line)
        else:
            new_lines.append(line)

    # Remove trailing blank lines
    while new_lines and new_lines[-1].strip() == "":
        new_lines.pop()

    # Add navigation footer
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
            print(
                f"    - Regenerated TOC with {len([h for h in headings if h.level > 1])} entries"
            )
            print(f"    - Updated {len(headings)} heading numbers")
            return True
        except Exception as e:
            print(f"  ✗ Error writing file: {e}")
            return False
    else:
        print(f"  ✓ Would update (dry run)")
        print(
            f"    - Would regenerate TOC with {len([h for h in headings if h.level > 1])} entries"
        )
        print(f"    - Would update {len(headings)} heading numbers")
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
        description="Regenerate TOCs for markdown documentation files",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Process all files (dry run)
  python3 tools/regenerate-tocs.py --dry-run

  # Process all files (actual changes)
  python3 tools/regenerate-tocs.py --yes

  # Process single file
  python3 tools/regenerate-tocs.py --file docs/010-overview.md --yes

  # Generate collapsible TOCs
  python3 tools/regenerate-tocs.py --yes --collapsible


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

    parser.add_argument(
        "--verify",
        action="store_true",
        help="Verify all links after regeneration",
    )

    parser.add_argument(
        "--collapsible",
        action="store_true",
        help="Make TOC collapsible using HTML details/summary tags",
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
    print(f"Documentation TOC Regeneration")
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
        if process_document(
            file_path,
            dry_run=args.dry_run,
            collapsible=args.collapsible,
        ):
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

    # Verify links if requested
    if args.verify and success_count > 0:
        print(f"\n{'='*60}")
        print(f"Verifying Links")
        print(f"{'='*60}\n")

        verify_script = script_dir / "verify-markdown-links.py"
        if not verify_script.exists():
            print(f"⚠ Warning: verify-markdown-links.py not found at {verify_script}")
            print(f"  Skipping link verification")
        else:
            # Build verification command
            verify_cmd = ["python3", str(verify_script)]

            if args.file:
                verify_cmd.append(str(files[0]))
            else:
                verify_cmd.extend([str(docs_dir), "--recursive"])

            # Run verification
            try:
                result = subprocess.run(verify_cmd, capture_output=False)
                if result.returncode != 0:
                    print(f"\n⚠ Link verification found issues")
                    return result.returncode
            except Exception as e:
                print(f"✗ Error running link verification: {e}")
                return 2

    return 0 if fail_count == 0 else 1
    # Verify links if requested
    if not args.dry_run and not args.skip_verify:
        print(f"\n{'='*60}")
        print(f"Verifying TOC Links")
        print(f"{'='*60}")
        verify_count = 0
        broken_count = 0

        for file_path in files:
            broken = verify_toc_links(file_path)
            verify_count += 1
            broken_count += len(broken)

        print(f"\n✓ Verified {verify_count} files")
        if broken_count > 0:
            print(f"⚠ Found {broken_count} broken links")


if __name__ == "__main__":
    sys.exit(main())
