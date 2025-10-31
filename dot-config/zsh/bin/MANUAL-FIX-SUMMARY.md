# Manual Fix Summary for Documentation

## Issues to Fix

1. **Closing code fences with tags** - Remove language tags from closing fences
   - WRONG: ` ```text` or ` ```bash` (closing fence)
   - CORRECT: ` ``` ` (closing fence with no tag)

2. **Indented code fences** - All code fences must start in column 1

   - WRONG: `....```bash` (indented 4 spaces)

   - CORRECT: ````bash` (column 1)

## How to Run the Fix

```bash
# Navigate to project root
cd /Users/s-a-c/dotfiles/dot-config/zsh

# Run the fix script
python3 bin/fix-closing-fences.py
```

## Manual Fix if Script Fails

If the Python script can't run, manually:

1. Search for ` ```text$` and replace with ` ```
2. Search for ` ```bash$` at end of code blocks and replace with ` ```
3. Search for indented fences like `    ```` and move to column 1

## Files Most Likely Affected

- `docs/010-zsh-configuration/900-roadmap.md`
- All files in `docs/010-zsh-configuration/`

## Verification

After fixing, check:

```bash
# Find closing fences with tags
grep -rn "^\`\`\`text$" docs/010-zsh-configuration/
grep -rn "^\`\`\`bash$" docs/010-zsh-configuration/

# Find indented fences
grep -rn "^    \`\`\`" docs/010-zsh-configuration/
```

Should return no results.
