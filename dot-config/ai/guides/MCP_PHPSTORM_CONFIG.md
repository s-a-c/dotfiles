# Configure PHPStorm MCP Access to tests/

## Problem
MCP currently only allows access to:
- `/Users/s-a-c/Desktop`
- `/Users/s-a-c/Downloads`

Your project is at `/Users/s-a-c/Herd/validate-links` (outside allowed directories).

## Solution

### Method 1: PHPStorm Settings
1. Open PHPStorm → Preferences (Cmd+,)
2. Navigate to Tools → MCP Servers
3. Add allowed directory: `/Users/s-a-c/Herd/validate-links`
4. Restart PHPStorm

### Method 2: Environment Variable
```bash
export ALLOWED_DIRECTORIES="/Users/s-a-c/Desktop,/Users/s-a-c/Downloads,/Users/s-a-c/Herd/validate-links"
```

### Method 3: MCP Config File
Add to MCP configuration:
```json
{
  "filesystem": {
    "env": {
      "ALLOWED_DIRECTORIES": "/Users/s-a-c/Desktop,/Users/s-a-c/Downloads,/Users/s-a-c/Herd/validate-links"
    }
  }
}
```

After configuration, restart PHPStorm and test MCP access to tests/ directory.
