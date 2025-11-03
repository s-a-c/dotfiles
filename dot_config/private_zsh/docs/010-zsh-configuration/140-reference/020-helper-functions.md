# Helper Functions API Reference

**Core Helper Functions (`zf::*` namespace)**

---

## 🔧 Path Management

### `zf::path_prepend`

**Purpose**: Safely add directory to beginning of PATH

**Signature**:

```bash
zf::path_prepend <directory>

```

**Example**:

```bash
zf::path_prepend "/opt/local/bin"

```

### `zf::path_append`

**Purpose**: Safely add directory to end of PATH

**Signature**:

```bash
zf::path_append <directory>

```

### `zf::path_remove`

**Purpose**: Remove directory from PATH

**Signature**:

```bash
zf::path_remove <directory>

```

---

## 📊 Performance Tracking

### `zf::segment`

**Purpose**: Mark start/end of performance segments

**Signature**:

```bash
zf::segment <module_name> <start|end> [phase]

```

**Example**:

```bash
zf::segment "my-module" "start"

# ... code ...

zf::segment "my-module" "end"

```

---

## 🔍 Debug & Logging

### `zf::debug`

**Purpose**: Conditional debug output

**Signature**:

```bash
zf::debug <message>

```

**Example**:

```bash
zf::debug "Loading module: my-module"

# Only outputs if ZSH_DEBUG=1


```

---

## 🛠️ Utility Functions

### `zf::has_command`

**Purpose**: Check if command exists

**Signature**:

```bash
zf::has_command <command_name>

```

**Returns**: 0 if exists, 1 if not

**Example**:

```bash
if zf::has_command "fzf"; then
    # FZF is available
fi

```

---

## 📂 Path Resolution

### `zf::script_dir`

**Purpose**: Get script's directory (symlink-safe)

**Signature**:

```bash
zf::script_dir

```

**Returns**: Directory path

---

**Navigation:** [← Environment Variables](010-environment-variables.md) | [Top ↑](#helper-functions) | [Available Plugins →](030-available-plugins.md)

---

*Compliant with AI-GUIDELINES.md (v1.0 2025-10-30)*
