#!/usr/bin/env zsh
# fix-documentation-issues.zsh - Batch fix documentation issues
# Usage: ./bin/fix-documentation-issues.zsh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOCS_DIR="$(cd "$SCRIPT_DIR/../docs/010-zsh-configuration" && pwd)"

echo "🔧 Documentation Correction Script"
echo "===================================="
echo "Target: $DOCS_DIR"
echo

# Statistics
typeset -i TOTAL_FILES=0
typeset -i FILES_MODIFIED=0
typeset -i MERMAID_FIXES=0
typeset -i LINK_FIXES=0

# Process each markdown file
cd "$DOCS_DIR"

find . -name "*.md" -type f | while read -r file; do
    ((TOTAL_FILES++))
    local modified=0

    # Fix Mermaid colors - use sed for simple replacements
    if grep -q 'style.*fill:#e1f5ff' "$file" 2>/dev/null; then
        sed -i.bak 's/fill:#e1f5ff/fill:#0066cc,stroke:#fff,stroke-width:2px,color:#fff/g' "$file"
        modified=1
    fi

    if grep -q 'fill:#fff3cd' "$file" 2>/dev/null; then
        sed -i.bak 's/fill:#fff3cd\b/fill:#cc7a00,stroke:#000,stroke-width:2px,color:#fff/g' "$file"
        modified=1
    fi

    if grep -q 'fill:#d4edda' "$file" 2>/dev/null; then
        sed -i.bak 's/fill:#d4edda\b/fill:#006600,stroke:#fff,stroke-width:2px,color:#fff/g' "$file"
        modified=1
    fi

    if grep -q 'fill:#cce5ff' "$file" 2>/dev/null; then
        sed -i.bak 's/fill:#cce5ff\b/fill:#0080ff,stroke:#fff,stroke-width:2px,color:#fff/g' "$file"
        modified=1
    fi

    if grep -q 'fill:#f8d7da' "$file" 2>/dev/null; then
        sed -i.bak 's/fill:#f8d7da\b/fill:#cc0066,stroke:#fff,stroke-width:2px,color:#fff/g' "$file"
        modified=1
    fi

    if grep -q 'fill:#e7f3ff' "$file" 2>/dev/null; then
        sed -i.bak 's/fill:#e7f3ff\b/fill:#6600cc,stroke:#fff,stroke-width:2px,color:#fff/g' "$file"
        modified=1
    fi

    if grep -q 'fill:#ffeaa7' "$file" 2>/dev/null; then
        sed -i.bak 's/fill:#ffeaa7\b/fill:#cc6600,stroke:#000,stroke-width:2px,color:#fff/g' "$file"
        modified=1
    fi

    if grep -q 'fill:#d1ecf1' "$file" 2>/dev/null; then
        sed -i.bak 's/fill:#d1ecf1\b/fill:#0099cc,stroke:#fff,stroke-width:2px,color:#fff/g' "$file"
        modified=1
    fi

    if grep -q 'fill:#d1f2eb' "$file" 2>/dev/null; then
        sed -i.bak 's/fill:#d1f2eb\b/fill:#008066,stroke:#fff,stroke-width:3px,color:#fff/g' "$file"
        modified=1
    fi

    if grep -q 'fill:#ffd6e0' "$file" 2>/dev/null; then
        sed -i.bak 's/fill:#ffd6e0\b/fill:#cc0066,stroke:#fff,stroke-width:2px,color:#fff/g' "$file"
        modified=1
    fi

    # Fix folder links
    if grep -q '](140-reference/)' "$file" 2>/dev/null; then
        sed -i.bak 's|](140-reference/)|](140-reference/000-index.md)|g' "$file"
        modified=1
        ((LINK_FIXES++))
    fi

    if grep -q '](150-diagrams/)' "$file" 2>/dev/null; then
        sed -i.bak 's|](150-diagrams/)|](150-diagrams/000-index.md)|g' "$file"
        modified=1
        ((LINK_FIXES++))
    fi

    # Clean up backup files
    if [[ -f "${file}.bak" ]]; then
        rm "${file}.bak"
    fi

    if [[ $modified -eq 1 ]]; then
        ((FILES_MODIFIED++))
        ((MERMAID_FIXES++))
        echo "  ✅ Fixed: $file"
    fi
done

echo
echo "✅ Batch Processing Complete"
echo "============================"
echo "Total files scanned: $TOTAL_FILES"
echo "Files modified: $FILES_MODIFIED"
echo "Mermaid color fixes applied: $MERMAID_FIXES"
echo "Folder link fixes: $LINK_FIXES"
echo
echo "🔍 Manual Review Still Needed:"
echo "   1. Heading numbering consistency"
echo "   2. TOC anchor link verification"
echo "   3. Markdown linting (MD rules)"
echo
echo "Next steps:"
echo "  cd docs/010-zsh-configuration"
echo "  git diff  # Review all changes"
echo

exit 0
