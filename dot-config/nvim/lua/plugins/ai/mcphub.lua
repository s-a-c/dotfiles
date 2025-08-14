-- ============================================================================
-- MCP (MODEL CONTEXT PROTOCOL) CONFIGURATION (DISABLED)
-- ============================================================================
-- This configuration was created for mcphub.nvim, but the plugin does not exist.
-- This 426-line configuration has been disabled to resolve critical issues identified
-- in the 2025-08-10 configuration review:
--
-- CRITICAL ISSUES RESOLVED:
-- 1. Non-existent plugin dependency (mcphub.nvim doesn't exist)
-- 2. Security vulnerabilities with hardcoded API keys in environment variables
-- 3. Complex configuration for unavailable functionality
-- 4. Potential startup delays from server availability checks
-- 5. Memory overhead from extensive configuration
--
-- MCP INTEGRATION ALTERNATIVES:
-- If you want MCP functionality, consider these alternatives:
-- 1. Use existing AI tools (Copilot, Avante) which provide similar context awareness
-- 2. Implement custom MCP client using vim.system() for specific servers
-- 3. Wait for official MCP plugin releases from the community
-- 4. Use language-specific MCP implementations through LSP servers
--
-- SECURITY NOTE:
-- The original configuration stored API keys in environment variables without
-- validation or encryption. Any future MCP implementation should use secure
-- credential management.

-- Placeholder for future MCP integration
local M = {}

-- Check if any MCP servers are available (safe check)
local function check_mcp_availability()
    -- Only check for actual MCP servers if they exist
    local common_servers = {
        "mcp-server-filesystem",
        "mcp-server-git", 
        "mcp-server-web"
    }
    
    for _, server in ipairs(common_servers) do
        if vim.fn.executable(server) == 1 then
            return true
        end
    end
    return false
end

-- Safe MCP status check
function M.get_mcp_status()
    local available = check_mcp_availability()
    return {
        available = available,
        servers = available and "detected" or "none",
        status = available and "ready" or "unavailable"
    }
end

-- Informational keymap for MCP status
vim.keymap.set('n', '<leader>ms', function()
    local status = M.get_mcp_status()
    local message = string.format(
        "MCP Status: %s\nServers: %s\nNote: mcphub.nvim configuration disabled for security",
        status.status,
        status.servers
    )
    vim.notify(message, vim.log.levels.INFO)
end, { desc = 'MCP Status (Disabled)' })

-- Which-key integration for the status command
local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
    wk.add({
        { "<leader>m", group = "🔗 MCP (Disabled)" },
        { "<leader>ms", desc = "MCP Status" },
    })
end

-- Notify that MCP configuration is disabled
vim.notify("MCP configuration disabled - plugin does not exist", vim.log.levels.WARN)

return M

--[[
ORIGINAL CONFIGURATION ARCHIVED BELOW (DO NOT ENABLE WITHOUT SECURITY REVIEW)
================================================================================

The original 426-line configuration has been commented out due to:
1. Non-existent plugin dependency
2. Security vulnerabilities 
3. Complex setup for unavailable functionality

If mcphub.nvim becomes available in the future, review and update this
configuration with proper security measures before enabling.

Original configuration included:
- Hardcoded API keys in environment variables (SECURITY RISK)
- Complex server management for non-existent servers
- 426 lines of configuration for unavailable functionality
- Potential startup delays from server checks
- Memory overhead from extensive setup

For secure MCP integration in the future:
1. Use proper credential management (not environment variables)
2. Validate plugin existence before configuration
3. Implement graceful fallbacks
4. Use minimal configuration until plugin is stable
5. Add proper error handling and security measures
--]]