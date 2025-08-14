# MCP Filesystem Access Setup

## Current Issue
MCP filesystem server only allows access to:
- `/Users/s-a-c/Desktop`
- `/Users/s-a-c/Downloads`

Project location: `/Users/s-a-c/Herd/chinook` (NOT ALLOWED)

## Solution
Add project directory to MCP allowed directories:

### Method 1: PHPStorm Settings
1. Open PHPStorm Settings (Cmd+,)
2. Navigate to Tools → MCP
3. Add allowed directory: `/Users/s-a-c/Herd/chinook`
4. Apply and restart PHPStorm

### Method 2: MCP Config File
Location: `~/.config/mcp/config.json`
```json
{
  "filesystem": {
    "allowed_directories": [
      "/Users/s-a-c/Desktop",
      "/Users/s-a-c/Downloads",
      "/Users/s-a-c/Herd/chinook"
    ]
  }
}
```

### Method 3: Environment Variable
```bash
export MCP_ALLOWED_DIRS="/Users/s-a-c/Desktop:/Users/s-a-c/Downloads:/Users/s-a-c/Herd/chinook"
```

## Next Steps
1. Configure using one of the methods above
2. Restart MCP server/PHPStorm
3. Test filesystem access
