# Top

## Table of Contents

<details>
<summary>Click to expand</summary>


</details>

---


---


# Reports Index

This folder contains automated reports produced by the documentation maintenance tooling.

- **[link-existence-map.json](link-existence-map.json)** - Machine-readable JSON map of every link encountered and its status
- **[markdown-lint-report.md](markdown-lint-report.md)** - Human-readable lint-style report summarizing anchor and link issues
- **[final-markdown-lint-report.md](final-markdown-lint-report.md)** - Final human-readable lint report after auto-fix and manual edits (2025-10-07)


Quick checks:

- cat link-existence-map.json | jq '.entries | length'  # number of top-level mapping entries
- less markdown-lint-report.md

- [Previous](../010-zsh-configuration/000-index.md) - Back to main documentation index
- [Top](#top)

---

**Navigation:** [Top ↑](#top)

---

*Last updated: 2025-10-13*
