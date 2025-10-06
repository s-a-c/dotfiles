# ZSH Configuration Redesign v3

This documentation set provides a comprehensive architectural analysis of the ZSH configuration system as implemented in this repository, building on the prior work in `docs/redesignv2/` and advancing it to Version 3 (v3).

Primary goals of this version:
- Consolidate the understanding of the full startup architecture (zshenv → zshrc → pre-plugins → plugin manager → post-plugins)
- Catalog functions and establish module responsibilities and boundaries
- Visualize flows and dependencies with high-contrast Mermaid diagrams
- Provide targeted recommendations for correctness, resilience, maintainability, performance, and native ZSH efficiency
- Reference and integrate relevant artifacts from redesign v2 (migration tracking, ADRs, testing standards)

## How to Use This Documentation
- Start with ARCHITECTURE.md for the big picture and startup sequence
- See FUNCTION_CATALOG.md for a cross-referenced inventory of helper functions
- Use DIAGRAMS.md for visualizations of flows and dependencies
- Review IMPROVEMENTS.md for prioritized recommendations and quick wins
- Consult MIGRATION_NOTES.md for deltas vs v2 and Stage 3 alignment

## Scope and Source of Truth
- Code analyzed:
  - `.zshenv` (environment/bootstrap, ZDOTDIR/XDG, PATH, helpers)
  - `.zshrc` (entry point, settings system, loader, update logic)
  - `.zshrc.pre-plugins.d/` (pre-plugin modules)
  - `.zgen-setup` (zgenom plugin manager and plugin lists)
  - `.zshrc.d/` (post-plugin modules)
- v2 documentation considered for context (not duplicated):
  - STAGE3_STATUS_ASSESSMENT.md, ARCHITECTURE.md, REFERENCE.md
  - Testing standards and tracking files

## Color Coding Used in Diagrams
- Security: red
- Performance: blue
- Plugins/Plugin Manager: green
- Core boot/Environment/Path: yellow
- UI/Prompt: purple
- Misc/Utilities: gray

## Status at a Glance
- Pre-plugin redesign: enabled and present (.zshrc.pre-plugins.d)
- Post-plugin redesign: present as `.zshrc.d/` and `.zshrc.d/POSTPLUGIN/` modules
- Settings system: ZDOTDIR-aware; files under `_ZQS_SETTINGS_DIR` (XDG-aware)
- Plugin manager: zgenom; localized under ZDOTDIR if available

See the individual documents for details and recommendations.

