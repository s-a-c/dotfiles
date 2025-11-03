# Zsh Cursor Movement Key Bindings Analysis (2025-10-12)

## Table of Contents

<details>
<summary>Click to expand</summary>

- [1. Standard Keys](#1-standard-keys)
- [2. Keys with Modifiers](#2-keys-with-modifiers)
  - [2.1. Control (`<left-ctrl>`)](#21-control-left-ctrl)
  - [2.2. Alt/Option (`<alt|option>`)](#22-altoption-altoption)
  - [2.3. Shift (`<left-shift>`)](#23-shift-left-shift)
  - [2.4. Command (`<cmd>`)](#24-command-cmd)
  - [2.5. Other Modifiers](#25-other-modifiers)

</details>

---


## 1. Standard Keys

| Key | Behavior | Zsh Widget | Notes |
|---|---|---|---|
| `<ins>` | Default terminal behavior | `undefined` | No explicit binding found. |
| `<home>` | Move to the beginning of the line | `beginning-of-line` | |
| `<page-up>` | Move to the previous history item | `up-line-or-history` | |
| `<del>` | Delete character under the cursor | `delete-char` | |
| `<end>` | Move to the end of the line | `end-of-line` | |
| `<page-down>` | Move to the next history item | `down-line-or-history` | |
| `<cursor-left>` | Move one character backward | `backward-char` | Bound via `^B`. |
| `<cursor-up>` | Fuzzy find history backward | `up-line-or-beginning-search` | |
| `<cursor-down>` | Fuzzy find history forward | `down-line-or-beginning-search` | |
| `<cursor-right>` | Move one character forward | `forward-char` | Bound via `^F`. |

## 2. Keys with Modifiers

### 2.1. Control (`<left-ctrl>`)

| Key | Behavior | Zsh Widget | Notes |
|---|---|---|---|
| `<left-ctrl>`+`<cursor-left>` | Move one word backward | `backward-word` | |
| `<left-ctrl>`+`<cursor-right>` | Move one word forward | `forward-word` | |
| `<left-ctrl>`+`<del>` | Delete the word forward from the cursor | `kill-word` | |

### 2.2. Alt/Option (`<alt|option>`)

| Key | Behavior | Zsh Widget | Notes |
|---|---|---|---|
| `<alt|option>`+`<cursor-left>` | Move one word backward | `backward-word` | Bound via `^[b`. |
| `<alt|option>`+`<cursor-right>` | Move one word forward | `forward-word` | Bound via `^[f`. |

### 2.3. Shift (`<left-shift>`)

No explicit bindings found for `<left-shift>` combined with cursor movement keys. The behavior will be determined by the terminal emulator.

### 2.4. Command (`<cmd>`)

No explicit bindings found for `<cmd>` combined with cursor movement keys. The behavior will be determined by the terminal emulator.

### 2.5. Other Modifiers

No explicit bindings were found for the following modifiers in combination with cursor movement keys:

*   `<alt-gr|right-option>`
*   `<right-cmd>`
*   `<right-ctrl>`
*   `<right-shift>`

The behavior of these key combinations will be determined by the terminal emulator and the operating system.

---

**Navigation:** [Top ↑](#zsh-cursor-movement-key-bindings-analysis-2025-10-12)

---

*Last updated: 2025-10-13*
