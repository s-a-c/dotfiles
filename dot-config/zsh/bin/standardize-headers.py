#!/usr/bin/env python3
"""
Standardize ZSH configuration file headers.

Standard format:
#!/usr/bin/env zsh
# Filename: NNN-feature-name.zsh
# Purpose:  Brief description
# Phase:    Which phase (.zshrc.d/, .zshrc.pre-plugins.d/, etc.)
# Requires: Dependencies (optional)
# Toggles:  Environment variables (optional)
"""

import os
import re
from pathlib import Path

# Phase mappings based on directory
PHASE_MAP = {
    '.zshrc.add-plugins.d.00': 'Plugin activation (.zshrc.add-plugins.d/)',
    '.zshrc.add-plugins.d.01': 'Plugin activation (.zshrc.add-plugins.d/)',
    '.zshrc.pre-plugins.d.01': 'Pre-plugin (.zshrc.pre-plugins.d/)',
    '.zshrc.d.01': 'Post-plugin (.zshrc.d/)',
}

def extract_purpose(lines):
    """Extract purpose from existing header comments."""
    purpose_lines = []
    in_purpose = False
    
    for line in lines[1:20]:  # Check first 20 lines
        line = line.strip()
        
        # Skip shebang, empty lines, and markers
        if not line or line.startswith('#!') or 'Compliant with' in line:
            continue
            
        # Look for Purpose: or description after filename
        if 'Purpose:' in line or 'purpose:' in line.lower():
            in_purpose = True
            # Extract text after Purpose:
            match = re.search(r'Purpose:\s*(.+)', line, re.IGNORECASE)
            if match:
                purpose_lines.append(match.group(1).strip())
            continue
        
        # If we're in a comment block and haven't hit a blank line
        if line.startswith('#'):
            content = line.lstrip('#').strip()
            # Skip file names, section markers, policy statements
            if content and not any(x in content.lower() for x in ['phase ', 'layer set', 'policy:', 'pre_plugin', 'post_plugin', 'restart_required', 'refactored from', '.zsh']):
                if not in_purpose and not purpose_lines:
                    # This might be the description
                    purpose_lines.append(content)
                elif in_purpose:
                    purpose_lines.append(content)
        elif in_purpose and not line.startswith('#'):
            break
    
    if purpose_lines:
        return ' '.join(purpose_lines)
    return "TODO: Add purpose description"

def extract_requires(lines):
    """Extract dependencies from existing header."""
    for line in lines[1:30]:
        if 'Requires:' in line or 'REQUIRES:' in line:
            match = re.search(r'Requires:\s*(.+)', line, re.IGNORECASE)
            if match:
                return match.group(1).strip()
        if 'must run after' in line.lower():
            match = re.search(r'must run after[:\s]+(.+)', line, re.IGNORECASE)
            if match:
                return f"{match.group(1).strip()} (must run after)"
    return None

def extract_toggles(lines):
    """Extract environment variable toggles from existing header."""
    toggles = []
    for line in lines[1:30]:
        if 'Toggles:' in line or 'TOGGLES:' in line or 'toggle' in line.lower():
            match = re.search(r'(?:Toggles?|Environment variables?):\s*(.+)', line, re.IGNORECASE)
            if match:
                return match.group(1).strip()
        # Look for ZF_ variables
        if 'ZF_' in line or 'NO_SPLASH' in line:
            match = re.findall(r'(`?[A-Z_]+`?)', line)
            if match:
                toggles.extend([v.strip('`') for v in match if v.startswith(('ZF_', 'NO_'))])
    
    if toggles:
        return ', '.join(sorted(set(toggles)))
    return None

def standardize_header(filepath):
    """Standardize header for a single file."""
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    # Get filename
    filename = os.path.basename(filepath)
    
    # Determine phase
    parent_dir = os.path.basename(os.path.dirname(filepath))
    phase = PHASE_MAP.get(parent_dir, 'Configuration')
    
    # Extract metadata
    purpose = extract_purpose(lines)
    requires = extract_requires(lines)
    toggles = extract_toggles(lines)
    
    # Find where the actual code starts (after header comments)
    code_start = 1
    for i, line in enumerate(lines[1:], 1):
        stripped = line.strip()
        # Code starts after comments or blank line following comments
        if stripped and not stripped.startswith('#'):
            code_start = i
            break
        # Also check if we hit a section marker
        if stripped.startswith('# ---'):
            code_start = i
            break
    
    # Build new header
    new_header = ['#!/usr/bin/env zsh\n']
    new_header.append(f'# Filename: {filename}\n')
    new_header.append(f'# Purpose:  {purpose}\n')
    new_header.append(f'# Phase:    {phase}\n')
    if requires:
        new_header.append(f'# Requires: {requires}\n')
    if toggles:
        new_header.append(f'# Toggles:  {toggles}\n')
    new_header.append('\n')
    
    # Combine new header with code
    new_content = ''.join(new_header) + ''.join(lines[code_start:])
    
    # Write back
    with open(filepath, 'w') as f:
        f.write(new_content)
    
    return filename, purpose

def main():
    """Standardize headers in all ZSH config files."""
    base_dir = Path.cwd()
    
    directories = [
        base_dir / '.zshrc.add-plugins.d.00',
        base_dir / '.zshrc.pre-plugins.d.01',
        base_dir / '.zshrc.d.01',
    ]
    
    updated = []
    for directory in directories:
        if not directory.exists():
            continue
        
        for filepath in sorted(directory.glob('*.zsh')):
            filename, purpose = standardize_header(filepath)
            updated.append((str(filepath.relative_to(base_dir)), purpose))
            print(f"✓ {filepath.relative_to(base_dir)}")
    
    print(f"\n✅ Standardized {len(updated)} files")
    return updated

if __name__ == '__main__':
    main()

