-- ============================================================================
-- HARPOON 2 CONFIGURATION
-- ============================================================================
-- Quick file navigation and project-specific bookmarks

local harpoon = require("harpoon")

-- Initialize Harpoon 2 with default configuration
harpoon:setup()

-- ============================================================================
-- HARPOON KEYMAPS
-- ============================================================================

local function map(mode, lhs, rhs, opts)
    opts = opts or {}
    opts.silent = opts.silent ~= false
    vim.keymap.set(mode, lhs, rhs, opts)
end

-- Core Harpoon functionality
map("n", "<leader>ha", function() harpoon:list():add() end, { desc = "Harpoon Add File" })
map("n", "<leader>hh", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "Harpoon Toggle Menu" })

-- Quick navigation to specific files
map("n", "<leader>h1", function() harpoon:list():select(1) end, { desc = "Harpoon File 1" })
map("n", "<leader>h2", function() harpoon:list():select(2) end, { desc = "Harpoon File 2" })
map("n", "<leader>h3", function() harpoon:list():select(3) end, { desc = "Harpoon File 3" })
map("n", "<leader>h4", function() harpoon:list():select(4) end, { desc = "Harpoon File 4" })
map("n", "<leader>h5", function() harpoon:list():select(5) end, { desc = "Harpoon File 5" })

-- Navigation between harpooned files
map("n", "<C-S-P>", function() harpoon:list():prev() end, { desc = "Harpoon Previous" })
map("n", "<C-S-N>", function() harpoon:list():next() end, { desc = "Harpoon Next" })

-- Alternative navigation with brackets
map("n", "]h", function() harpoon:list():next() end, { desc = "Harpoon Next" })
map("n", "[h", function() harpoon:list():prev() end, { desc = "Harpoon Previous" })

-- File management
map("n", "<leader>hr", function() harpoon:list():remove() end, { desc = "Harpoon Remove File" })
map("n", "<leader>hc", function() harpoon:list():clear() end, { desc = "Harpoon Clear List" })

-- Advanced navigation options
map("n", "<leader>hv", function() 
    harpoon:list():select(vim.v.count1, { vsplit = true })
end, { desc = "Harpoon Open in Vertical Split" })

map("n", "<leader>hs", function() 
    harpoon:list():select(vim.v.count1, { split = true })
end, { desc = "Harpoon Open in Horizontal Split" })

map("n", "<leader>ht", function() 
    harpoon:list():select(vim.v.count1, { tabedit = true })
end, { desc = "Harpoon Open in New Tab" })

-- ============================================================================
-- HARPOON AUTOCOMMANDS
-- ============================================================================

-- Auto-save harpoon list on certain events
local harpoon_group = vim.api.nvim_create_augroup("HarpoonConfig", { clear = true })

-- Note: Harpoon 2 handles saving automatically, no manual sync needed
-- vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
--     group = harpoon_group,
--     callback = function()
--         -- Harpoon 2 auto-saves, no manual sync required
--     end,
-- })

-- Auto-add important files to harpoon
vim.api.nvim_create_autocmd("BufEnter", {
    group = harpoon_group,
    callback = function()
        local filename = vim.api.nvim_buf_get_name(0)
        if filename == "" then return end
        
        -- Auto-add certain important files
        local auto_add_patterns = {
            "README%.md$",
            "package%.json$",
            "composer%.json$",
            "Cargo%.toml$",
            "go%.mod$",
            "requirements%.txt$",
            "Dockerfile$",
            "docker%-compose%.ya?ml$",
            "%.env$",
            "%.env%.example$",
            "artisan$",
            "manage%.py$",
            "Makefile$",
            "CMakeLists%.txt$",
        }
        
        for _, pattern in ipairs(auto_add_patterns) do
            if filename:match(pattern) then
                -- Check if file is already in harpoon list
                local list = harpoon:list()
                local items = list.items or {}
                local already_added = false
                
                for _, item in ipairs(items) do
                    if item.value == filename then
                        already_added = true
                        break
                    end
                end
                
                if not already_added and vim.g.harpoon_auto_add ~= false then
                    vim.schedule(function()
                        list:add()
                        vim.notify("Auto-added to Harpoon: " .. vim.fn.fnamemodify(filename, ":t"), 
                                 vim.log.levels.INFO, { title = "Harpoon" })
                    end)
                end
                break
            end
        end
    end,
})

-- Highlight current file in harpoon menu
vim.api.nvim_create_autocmd("User", {
    pattern = "HarpoonUIOpen",
    callback = function()
        -- Set up highlighting for the current file
        local current_file = vim.api.nvim_buf_get_name(0)
        local list = harpoon:list()
        local items = list.items or {}
        
        for i, item in ipairs(items) do
            if item.value == current_file then
                -- Highlight the current file line
                vim.api.nvim_buf_add_highlight(0, -1, "Search", i - 1, 0, -1)
                break
            end
        end
    end,
})

-- ============================================================================
-- INTEGRATION WITH EXISTING WORKFLOW
-- ============================================================================

-- Integration with Telescope
vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
        local ok, telescope = pcall(require, "telescope")
        if ok then
            -- Register harpoon extension if available
            local harpoon_telescope_ok = pcall(telescope.load_extension, "harpoon")
            if harpoon_telescope_ok then
                map("n", "<leader>fh", function()
                    telescope.extensions.harpoon.marks()
                end, { desc = "Find Harpoon Marks" })
            else
                -- Fallback telescope picker for harpoon files
                map("n", "<leader>fh", function()
                    local pickers = require("telescope.pickers")
                    local finders = require("telescope.finders")
                    local conf = require("telescope.config").values
                    local actions = require("telescope.actions")
                    local action_state = require("telescope.actions.state")
                    
                    local list = harpoon:list()
                    local items = list.items or {}
                    
                    if #items == 0 then
                        vim.notify("No harpooned files", vim.log.levels.INFO, { title = "Harpoon" })
                        return
                    end
                    
                    local results = {}
                    for i, item in ipairs(items) do
                        table.insert(results, {
                            index = i,
                            value = item.value,
                            display = string.format("%d: %s", i, vim.fn.fnamemodify(item.value, ":~:.")),
                        })
                    end
                    
                    pickers.new({}, {
                        prompt_title = "Harpoon Files",
                        finder = finders.new_table({
                            results = results,
                            entry_maker = function(entry)
                                return {
                                    value = entry,
                                    display = entry.display,
                                    ordinal = entry.display,
                                    path = entry.value,
                                }
                            end,
                        }),
                        sorter = conf.generic_sorter({}),
                        attach_mappings = function(prompt_bufnr, map_telescope)
                            actions.select_default:replace(function()
                                actions.close(prompt_bufnr)
                                local selection = action_state.get_selected_entry()
                                harpoon:list():select(selection.value.index)
                            end)
                            
                            -- Add mapping to remove from harpoon
                            map_telescope("i", "<C-d>", function()
                                local selection = action_state.get_selected_entry()
                                harpoon:list():remove_at(selection.value.index)
                                actions.close(prompt_bufnr)
                                vim.notify("Removed from Harpoon", vim.log.levels.INFO, { title = "Harpoon" })
                            end)
                            
                            return true
                        end,
                    }):find()
                end, { desc = "Find Harpoon Files" })
            end
        end
        
        -- Integration with snacks picker if available
        local ok_snacks, snacks = pcall(require, "snacks")
        if ok_snacks and snacks.picker then
            map("n", "<leader>fH", function()
                local list = harpoon:list()
                local items = list.items or {}
                
                if #items == 0 then
                    vim.notify("No harpooned files", vim.log.levels.INFO, { title = "Harpoon" })
                    return
                end
                
                local results = {}
                for i, item in ipairs(items) do
                    table.insert(results, {
                        text = string.format("%d: %s", i, vim.fn.fnamemodify(item.value, ":~:.")),
                        filename = item.value,
                        index = i,
                    })
                end
                
                snacks.picker.pick(results, {
                    prompt = "󰛢 Harpoon Files",
                    format = function(item)
                        local file_name = vim.fn.fnamemodify(item.filename, ":t")
                        local dir_name = vim.fn.fnamemodify(item.filename, ":h:t")
                        return {
                            { "󰛢 ", "Special" },
                            { string.format("%d", item.index), "Number" },
                            { ": ", "Delimiter" },
                            { file_name, "Normal" },
                            { " (" .. dir_name .. ")", "Comment" },
                        }
                    end,
                    preview = {
                        type = "file",
                        file = function(item)
                            return item.filename
                        end,
                    },
                    actions = {
                        ["default"] = function(item)
                            harpoon:list():select(item.index)
                        end,
                        ["ctrl-d"] = function(item)
                            harpoon:list():remove_at(item.index)
                            vim.notify("Removed " .. vim.fn.fnamemodify(item.filename, ":t") .. " from Harpoon",
                                     vim.log.levels.INFO, { title = "Harpoon" })
                        end,
                        ["ctrl-v"] = function(item)
                            harpoon:list():select(item.index, { vsplit = true })
                        end,
                        ["ctrl-x"] = function(item)
                            harpoon:list():select(item.index, { split = true })
                        end,
                        ["ctrl-t"] = function(item)
                            harpoon:list():select(item.index, { tabedit = true })
                        end,
                        ["ctrl-r"] = function(item)
                            -- Refresh harpoon list (Harpoon 2 auto-refreshes)
                            vim.notify("Harpoon list refreshed", vim.log.levels.INFO, { title = "Harpoon" })
                        end,
                    },
                })
            end, { desc = "Find Harpoon Files (Snacks)" })
        end
    end,
})

-- Integration with project switching
vim.api.nvim_create_autocmd("DirChanged", {
    group = harpoon_group,
    callback = function()
        -- Note: Harpoon 2 handles saving automatically
        -- No manual sync needed

        -- Notify about project change
        local new_project = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
        vim.schedule(function()
            local list = harpoon:list()
            local count = #(list.items or {})
            if count > 0 then
                vim.notify(string.format("Switched to project '%s' with %d harpooned files",
                         new_project, count), vim.log.levels.INFO, { title = "Harpoon" })
            else
                vim.notify(string.format("Switched to project '%s'", new_project),
                         vim.log.levels.INFO, { title = "Harpoon" })
            end
        end)
    end,
})

-- ============================================================================
-- HARPOON COMMANDS
-- ============================================================================

-- Command to show harpoon status
vim.api.nvim_create_user_command("HarpoonStatus", function()
    local list = harpoon:list()
    local items = list.items or {}
    local root_dir = list:config().get_root_dir()
    
    local status = {}
    table.insert(status, "Harpoon Status:")
    table.insert(status, "Project: " .. vim.fn.fnamemodify(root_dir, ":t"))
    table.insert(status, "Root: " .. root_dir)
    table.insert(status, "Files: " .. #items)
    table.insert(status, "")
    
    if #items > 0 then
        table.insert(status, "Harpooned files:")
        for i, item in ipairs(items) do
            local relative_path = item.value:gsub("^" .. vim.pesc(root_dir .. "/"), "")
            local exists = vim.fn.filereadable(item.value) == 1 and "✓" or "✗"
            table.insert(status, string.format("  %d. %s %s", i, exists, relative_path))
        end
    else
        table.insert(status, "No files harpooned in this project.")
    end
    
    vim.notify(table.concat(status, "\n"), vim.log.levels.INFO, { title = "Harpoon" })
end, { desc = "Show Harpoon status and file list" })

-- Command to clean up non-existent files
vim.api.nvim_create_user_command("HarpoonCleanup", function()
    local list = harpoon:list()
    local items = list.items or {}
    local removed_count = 0
    
    for i = #items, 1, -1 do
        if vim.fn.filereadable(items[i].value) == 0 then
            list:remove_at(i)
            removed_count = removed_count + 1
        end
    end
    
    if removed_count > 0 then
        vim.notify(string.format("Removed %d non-existent files from Harpoon", removed_count), 
                 vim.log.levels.INFO, { title = "Harpoon" })
    else
        vim.notify("All harpooned files exist", vim.log.levels.INFO, { title = "Harpoon" })
    end
end, { desc = "Remove non-existent files from Harpoon" })

-- ============================================================================
-- STATUSLINE INTEGRATION
-- ============================================================================

-- Function to get harpoon status for statusline
_G.harpoon_status = function()
    local ok, harpoon_local = pcall(require, "harpoon")
    if not ok then return "" end
    
    local list = harpoon_local:list()
    local items = list.items or {}
    local count = #items
    
    if count == 0 then return "" end
    
    -- Check if current file is harpooned
    local current_file = vim.api.nvim_buf_get_name(0)
    local current_index = nil
    
    for i, item in ipairs(items) do
        if item.value == current_file then
            current_index = i
            break
        end
    end
    
    if current_index then
        return string.format(" [H:%d/%d]", current_index, count)
    else
        return string.format(" [H:%d]", count)
    end
end

-- Function to get current harpoon file indicator
_G.harpoon_indicator = function()
    local ok, harpoon_local = pcall(require, "harpoon")
    if not ok then return "" end
    
    local list = harpoon_local:list()
    local items = list.items or {}
    local current_file = vim.api.nvim_buf_get_name(0)
    
    for i, item in ipairs(items) do
        if item.value == current_file then
            return " 🎯"
        end
    end
    
    return ""
end