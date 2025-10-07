# Top

# Reports Index

This folder contains automated reports produced by the documentation maintenance tooling.

- **[link-existence-map.json](link-existence-map.json)** - Machine-readable JSON map of every link encountered and its status
- **[markdown-lint-report.md](markdown-lint-report.md)** - Human-readable lint-style report summarizing anchor and link issues

Quick checks:

- cat link-existence-map.json | jq '.entries | length'  # number of top-level mapping entries
- less markdown-lint-report.md

- [Previous](../000-index.md) - Back to main documentation index
- [Top](#top)

