-- ============================================================================
-- NEOGEN CONFIGURATION
-- ============================================================================
-- Automatic documentation generation for multiple languages

local neogen = require("neogen")

neogen.setup({
    -- Enable Neogen
    enabled = true,
    
    -- Input after generated annotation
    input_after_comment = true,
    
    -- Snippet engine integration
    snippet_engine = "nvim",
    
    -- Enable placeholders
    enable_placeholders = true,
    
    -- Placeholder text
    placeholders_text = {
        ["description"] = "[TODO:description]",
        ["tparam"] = "[TODO:parameter]",
        ["parameter"] = "[TODO:parameter]",
        ["return"] = "[TODO:return]",
        ["class"] = "[TODO:class]",
        ["throw"] = "[TODO:exception]",
        ["varargs"] = "[TODO:varargs]",
        ["type"] = "[TODO:type]",
        ["attribute"] = "[TODO:attribute]",
        ["args"] = "[TODO:arguments]",
        ["kwargs"] = "[TODO:kwargs]",
    },
    
    -- Placeholders highlights
    placeholders_hl = "DiagnosticHint",
    
    -- Languages configuration
    languages = {
        -- PHP configuration for Laravel development
        php = {
            template = {
                annotation_convention = "phpdoc",
                phpdoc = {
                    { nil, "/**", { no_results = true, type = { "class", "func" } } },
                    { nil, " * $1", { no_results = true, type = { "class", "func" } } },
                    { nil, " */", { no_results = true, type = { "class", "func" } } },
                    
                    { nil, "/**", { type = { "func", "file", "class" } } },
                    { "description", " * %s", { type = { "func", "file", "class" } } },
                    { "tparam", " * @param %s $%s %s", { type = { "func" } } },
                    { "return", " * @return %s %s", { type = { "func" } } },
                    { "throw", " * @throws %s %s", { type = { "func" } } },
                    { "class", " * @package %s", { type = { "class" } } },
                    { "author", " * @author %s", { type = { "file", "class" } } },
                    { "since", " * @since %s", { type = { "file", "class" } } },
                    { "version", " * @version %s", { type = { "file", "class" } } },
                    { nil, " */", { type = { "func", "file", "class" } } },
                },
            },
        },
        
        -- JavaScript configuration
        javascript = {
            template = {
                annotation_convention = "jsdoc",
                jsdoc = {
                    { nil, "/**", { no_results = true, type = { "func", "class" } } },
                    { nil, " * $1", { no_results = true, type = { "func", "class" } } },
                    { nil, " */", { no_results = true, type = { "func", "class" } } },
                    
                    { nil, "/**", { type = { "func", "class", "file" } } },
                    { "description", " * %s", { type = { "func", "class", "file" } } },
                    { "tparam", " * @param {%s} %s - %s", { type = { "func" } } },
                    { "return", " * @returns {%s} %s", { type = { "func" } } },
                    { "throw", " * @throws {%s} %s", { type = { "func" } } },
                    { "class", " * @class %s", { type = { "class" } } },
                    { "author", " * @author %s", { type = { "file", "class" } } },
                    { "since", " * @since %s", { type = { "file", "class" } } },
                    { "version", " * @version %s", { type = { "file", "class" } } },
                    { nil, " */", { type = { "func", "class", "file" } } },
                },
            },
        },
        
        -- TypeScript configuration
        typescript = {
            template = {
                annotation_convention = "tsdoc",
                tsdoc = {
                    { nil, "/**", { no_results = true, type = { "func", "class" } } },
                    { nil, " * $1", { no_results = true, type = { "func", "class" } } },
                    { nil, " */", { no_results = true, type = { "func", "class" } } },
                    
                    { nil, "/**", { type = { "func", "class", "file" } } },
                    { "description", " * %s", { type = { "func", "class", "file" } } },
                    { "tparam", " * @param %s - %s", { type = { "func" } } },
                    { "return", " * @returns %s", { type = { "func" } } },
                    { "throw", " * @throws %s", { type = { "func" } } },
                    { "class", " * @class %s", { type = { "class" } } },
                    { "author", " * @author %s", { type = { "file", "class" } } },
                    { "since", " * @since %s", { type = { "file", "class" } } },
                    { "version", " * @version %s", { type = { "file", "class" } } },
                    { nil, " */", { type = { "func", "class", "file" } } },
                },
            },
        },
        
        -- Lua configuration
        lua = {
            template = {
                annotation_convention = "ldoc",
                ldoc = {
                    { nil, "---", { no_results = true, type = { "func", "class" } } },
                    { nil, "-- $1", { no_results = true, type = { "func", "class" } } },
                    
                    { nil, "---", { type = { "func", "class", "file" } } },
                    { "description", "-- %s", { type = { "func", "class", "file" } } },
                    { "tparam", "-- @param %s %s %s", { type = { "func" } } },
                    { "return", "-- @return %s %s", { type = { "func" } } },
                    { "class", "-- @class %s", { type = { "class" } } },
                    { "author", "-- @author %s", { type = { "file", "class" } } },
                    { "since", "-- @since %s", { type = { "file", "class" } } },
                    { "version", "-- @version %s", { type = { "file", "class" } } },
                },
            },
        },
    },
})

-- ============================================================================
-- NEOGEN KEYMAPS
-- ============================================================================

local function map(mode, lhs, rhs, opts)
    opts = opts or {}
    opts.silent = opts.silent ~= false
    vim.keymap.set(mode, lhs, rhs, opts)
end

-- Generate documentation for different contexts
map("n", "<leader>nf", function() neogen.generate({ type = "func" }) end, { desc = "Generate Function Docs" })
map("n", "<leader>nc", function() neogen.generate({ type = "class" }) end, { desc = "Generate Class Docs" })
map("n", "<leader>nt", function() neogen.generate({ type = "type" }) end, { desc = "Generate Type Docs" })
map("n", "<leader>nF", function() neogen.generate({ type = "file" }) end, { desc = "Generate File Docs" })

-- Generate documentation with automatic detection
map("n", "<leader>ng", function() neogen.generate() end, { desc = "Generate Docs (Auto)" })

-- Jump between placeholders
map("n", "<leader>n]", function()
    require("neogen.utilities").jump_next()
end, { desc = "Next Placeholder" })

map("n", "<leader>n[", function()
    require("neogen.utilities").jump_prev()
end, { desc = "Previous Placeholder" })

-- ============================================================================
-- NEOGEN AUTOCOMMANDS
-- ============================================================================

-- Auto-generate documentation on function creation
vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("NeogenAutoDoc", { clear = true }),
    pattern = { "*.php", "*.js", "*.ts", "*.lua" },
    callback = function()
        -- Only auto-generate if enabled via global variable
        if vim.g.neogen_auto_generate then
            local cursor_pos = vim.api.nvim_win_get_cursor(0)
            local line = vim.api.nvim_get_current_line()
            
            -- Check if we're on a function line without documentation
            if line:match("function") or line:match("def ") or line:match("class ") then
                local prev_line = vim.api.nvim_buf_get_lines(0, cursor_pos[1] - 2, cursor_pos[1] - 1, false)[1]
                if prev_line and not prev_line:match("^%s*/%*") and not prev_line:match("^%s*//") and not prev_line:match("^%s*#") then
                    neogen.generate({ type = "func" })
                end
            end
        end
    end,
})

-- Integration with treesitter for better context detection
vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
        -- Enhance neogen with treesitter context
        local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
        if ok then
            -- Custom function to get better context for documentation
            _G.neogen_get_context = function()
                local node = ts_utils.get_node_at_cursor()
                if not node then return nil end
                
                local context = {
                    type = node:type(),
                    text = vim.treesitter.get_node_text(node, 0),
                    start_row = node:start(),
                    end_row = node:end_(),
                }
                
                return context
            end
        end
    end,
})

-- ============================================================================
-- LANGUAGE-SPECIFIC CONFIGURATIONS
-- ============================================================================

-- PHP/Laravel specific enhancements
vim.api.nvim_create_autocmd("FileType", {
    pattern = "php",
    callback = function()
        -- Laravel-specific documentation templates
        local laravel_templates = {
            controller = {
                { nil, "/**", { type = { "func" } } },
                { "description", " * %s", { type = { "func" } } },
                { nil, " *", { type = { "func" } } },
                { "tparam", " * @param %s $%s %s", { type = { "func" } } },
                { "return", " * @return %s %s", { type = { "func" } } },
                { "throw", " * @throws %s %s", { type = { "func" } } },
                { nil, " */", { type = { "func" } } },
            },
            model = {
                { nil, "/**", { type = { "class" } } },
                { "description", " * %s", { type = { "class" } } },
                { nil, " *", { type = { "class" } } },
                { "class", " * @package %s", { type = { "class" } } },
                { "author", " * @author %s", { type = { "class" } } },
                { nil, " */", { type = { "class" } } },
            },
        }
        
        -- Detect Laravel context and adjust templates
        local filename = vim.fn.expand("%:t")
        if filename:match("Controller%.php$") then
            -- Use controller template
            map("n", "<leader>nL", function()
                neogen.generate({ type = "func", template = laravel_templates.controller })
            end, { desc = "Generate Laravel Controller Docs", buffer = true })
        elseif filename:match("%.php$") and vim.fn.search("extends Model", "n") > 0 then
            -- Use model template
            map("n", "<leader>nL", function()
                neogen.generate({ type = "class", template = laravel_templates.model })
            end, { desc = "Generate Laravel Model Docs", buffer = true })
        end
    end,
})

-- JavaScript/TypeScript specific enhancements
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
    callback = function()
        -- React component documentation
        local react_template = {
            { nil, "/**", { type = { "func" } } },
            { "description", " * %s", { type = { "func" } } },
            { nil, " *", { type = { "func" } } },
            { "tparam", " * @param {%s} props.%s - %s", { type = { "func" } } },
            { "return", " * @returns {JSX.Element} %s", { type = { "func" } } },
            { nil, " */", { type = { "func" } } },
        }
        
        -- Detect React components
        if vim.fn.search("React", "n") > 0 or vim.fn.search("jsx", "n") > 0 then
            map("n", "<leader>nR", function()
                neogen.generate({ type = "func", template = react_template })
            end, { desc = "Generate React Component Docs", buffer = true })
        end
    end,
})

-- ============================================================================
-- INTEGRATION WITH EXISTING WORKFLOW
-- ============================================================================

-- Integration with Telescope for documentation search
vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
        local ok, telescope = pcall(require, "telescope")
        if ok then
            -- Custom picker for undocumented functions
            map("n", "<leader>fnd", function()
                local pickers = require("telescope.pickers")
                local finders = require("telescope.finders")
                local conf = require("telescope.config").values
                local actions = require("telescope.actions")
                local action_state = require("telescope.actions.state")
                
                -- Find functions without documentation
                local undocumented = {}
                local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                
                for i, line in ipairs(lines) do
                    if line:match("function") or line:match("def ") or line:match("class ") then
                        local prev_line = lines[i - 1] or ""
                        if not prev_line:match("^%s*/%*") and not prev_line:match("^%s*//") then
                            table.insert(undocumented, {
                                lnum = i,
                                text = line:gsub("^%s+", ""),
                                filename = vim.api.nvim_buf_get_name(0),
                            })
                        end
                    end
                end
                
                pickers.new({}, {
                    prompt_title = "Undocumented Functions",
                    finder = finders.new_table({
                        results = undocumented,
                        entry_maker = function(entry)
                            return {
                                value = entry,
                                display = entry.text,
                                ordinal = entry.text,
                                lnum = entry.lnum,
                                filename = entry.filename,
                            }
                        end,
                    }),
                    sorter = conf.generic_sorter({}),
                    attach_mappings = function(prompt_bufnr, map)
                        actions.select_default:replace(function()
                            actions.close(prompt_bufnr)
                            local selection = action_state.get_selected_entry()
                            vim.api.nvim_win_set_cursor(0, { selection.lnum, 0 })
                            neogen.generate()
                        end)
                        return true
                    end,
                }):find()
            end, { desc = "Find Undocumented Functions" })
        end
    end,
})

-- Integration with LSP for better type detection
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client.supports_method("textDocument/hover") then
            -- Enhance neogen with LSP type information using modern API
            _G.neogen_get_lsp_types = function()
                local params = vim.lsp.util.make_position_params()
                -- Use the modern vim.lsp.buf_request_sync for better compatibility
                local result, err = vim.lsp.buf_request_sync(0, "textDocument/hover", params, 1000)
                if not err and result then
                    for _, res in pairs(result) do
                        if res.result and res.result.contents then
                            -- Extract type information from LSP hover
                            local content = res.result.contents.value or res.result.contents
                            if type(content) == "string" then
                                -- Parse type information and enhance neogen templates
                                local types = content:match("```%w+\n(.-)```")
                                if types then
                                    vim.g.neogen_lsp_types = types
                                end
                            end
                            break
                        end
                    end
                end
            end
        end
    end,
})

-- ============================================================================
-- STATUSLINE INTEGRATION
-- ============================================================================

-- Function to show documentation coverage
_G.neogen_coverage = function()
    local total_functions = 0
    local documented_functions = 0
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    
    for i, line in ipairs(lines) do
        if line:match("function") or line:match("def ") or line:match("class ") then
            total_functions = total_functions + 1
            local prev_line = lines[i - 1] or ""
            if prev_line:match("^%s*/%*") or prev_line:match("^%s*//") or prev_line:match("^%s*#") then
                documented_functions = documented_functions + 1
            end
        end
    end
    
    if total_functions > 0 then
        local percentage = math.floor((documented_functions / total_functions) * 100)
        return string.format(" [Doc: %d%%]", percentage)
    end
    return ""
end