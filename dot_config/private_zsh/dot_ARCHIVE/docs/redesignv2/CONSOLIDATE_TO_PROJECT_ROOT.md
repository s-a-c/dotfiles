# Consolidation Plan: Move ZSH Redesign Tools and Tests to Project Root

_Compliant with [/Users/s-a-c/.config/ai/guidelines.md](/Users/s-a-c/.config/ai/guidelines.md) v<checksum>_

## Purpose

Consolidate all ZSH redesign migration scripts and test files from the repository root (`~/dotfiles`) into the ZSH project root (`~/.config/zsh`).  
This ensures all logic is self-contained, maintainable, and referenced consistently.

## Scope

- Move all scripts from `~/dotfiles/tools/` to `~/.config/zsh/tools/`
- Move all test files from `~/dotfiles/tests/` to `~/.config/zsh/tests/`
- Preserve subdirectory structure for both scripts and tests
- Update documentation and CI workflow references to use project root paths

## Steps

1. **Audit**: List all scripts and tests in both locations, including subdirectories.
2. **Move**: For each file in repo root not present in project root, move it, preserving subdirectory structure.
3. **Update References**: Change documentation and workflow references to project root.
4. **Cleanup**: Remove redundant files from repo root.
5. **Notify**: Inform team of new canonical locations.

## Checklist

- [ ] All scripts are in `dot-config/zsh/tools/` (with subdirectories preserved)
- [ ] All tests are in `dot-config/zsh/tests/` (with subdirectories preserved)
- [ ] No scripts/tests remain in repo root
- [ ] Docs and workflows reference project root
- [ ] Team notified

## Shell Script

See `dot-config/zsh/tools/consolidate_to_project_root.sh` for automation.  
The script supports dry-run mode and preserves subdirectory structure.

## Example Usage

```sh
zsh ~/.config/zsh/tools/consolidate_to_project_root.sh --dry-run
zsh ~/.config/zsh/tools/consolidate_to_project_root.sh
```

## Notes

- Always run with `--dry-run` first to verify actions.
- After consolidation, update all documentation and CI workflow references to use the new canonical locations.
- Notify all contributors of the change to avoid confusion.
