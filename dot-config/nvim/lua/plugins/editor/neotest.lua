-- ============================================================================
-- NEOTEST CONFIGURATION
-- ============================================================================
-- Advanced testing framework with adapter support for multiple languages

local neotest = require("neotest")

neotest.setup({
    -- Test discovery and execution
    discovery = {
        enabled = true,
        concurrent = 1,
    },
    
    -- Test running configuration
    running = {
        concurrent = true,
    },
    
    -- Test output configuration
    output = {
        enabled = true,
        open_on_run = "short",
    },
    
    -- Test output panel configuration
    output_panel = {
        enabled = true,
        open = "botright split | resize 15",
    },
    
    -- Quickfix integration
    quickfix = {
        enabled = true,
        open = false,
    },
    
    -- Status configuration
    status = {
        enabled = true,
        virtual_text = false,
        signs = true,
    },
    
    -- Icons for test status
    icons = {
        child_indent = "│",
        child_prefix = "├",
        collapsed = "─",
        expanded = "╮",
        failed = "✖",
        final_child_indent = " ",
        final_child_prefix = "╰",
        non_collapsible = "─",
        passed = "✓",
        running = "●",
        running_animated = { "/", "|", "\\", "-", "/", "|", "\\", "-" },
        skipped = "○",
        unknown = "?",
        watching = "👁",
    },
    
    -- Floating window configuration
    floating = {
        border = "rounded",
        max_height = 0.6,
        max_width = 0.6,
        options = {},
    },
    
    -- Strategies for different test types
    strategies = {
        integrated = {
            height = 40,
            width = 120,
        },
    },
    
    -- Test adapters configuration
    adapters = {
        -- PHPUnit adapter for Laravel/PHP testing
        require("neotest-phpunit")({
            phpunit_cmd = function()
                -- Try to find vendor/bin/phpunit first (Laravel standard)
                if vim.fn.filereadable("vendor/bin/phpunit") == 1 then
                    return "vendor/bin/phpunit"
                end
                -- Fallback to global phpunit
                return "phpunit"
            end,
            root_files = { "phpunit.xml", "phpunit.xml.dist", "composer.json" },
            filter_dirs = { ".git", "node_modules", "vendor" },
            env = {
                APP_ENV = "testing",
            },
            dap = {
                justMyCode = false,
                stopOnEntry = false,
            },
        }),
        
        -- Jest adapter for JavaScript/TypeScript testing
        require("neotest-jest")({
            jestCommand = function()
                -- Try to find local jest first
                if vim.fn.filereadable("node_modules/.bin/jest") == 1 then
                    return "node_modules/.bin/jest"
                end
                -- Try npm test
                if vim.fn.filereadable("package.json") == 1 then
                    return "npm test --"
                end
                -- Fallback to global jest
                return "jest"
            end,
            jestConfigFile = function()
                local file = vim.fn.glob("jest.config*", 0, 1)[1]
                if file then
                    return file
                end
                return vim.fn.getcwd() .. "/jest.config.js"
            end,
            env = { CI = true },
            cwd = function()
                return vim.fn.getcwd()
            end,
        }),
        
        -- Vitest adapter for modern JavaScript/TypeScript testing
        require("neotest-vitest")({
            vitestCommand = function()
                -- Try to find local vitest first
                if vim.fn.filereadable("node_modules/.bin/vitest") == 1 then
                    return "node_modules/.bin/vitest"
                end
                -- Try npm test
                if vim.fn.filereadable("package.json") == 1 then
                    return "npm test --"
                end
                -- Fallback to global vitest
                return "vitest"
            end,
            vitestConfigFile = function()
                local file = vim.fn.glob("vitest.config*", 0, 1)[1]
                if file then
                    return file
                end
                return vim.fn.getcwd() .. "/vitest.config.js"
            end,
            env = { CI = true },
            cwd = function()
                return vim.fn.getcwd()
            end,
        }),
    },
    
    -- Diagnostic integration
    diagnostic = {
        enabled = true,
        severity = vim.diagnostic.severity.ERROR,
    },
    
    -- Projects configuration
    projects = {
        ["~/projects/laravel"] = {
            discovery = {
                enabled = true,
                filter_dir = function(name, rel_path, root)
                    return name ~= "vendor" and name ~= "node_modules"
                end,
            },
        },
    },
})

-- ============================================================================
-- NEOTEST KEYMAPS
-- ============================================================================

local function map(mode, lhs, rhs, opts)
    opts = opts or {}
    opts.silent = opts.silent ~= false
    vim.keymap.set(mode, lhs, rhs, opts)
end

-- Test execution
map("n", "<leader>tt", function() neotest.run.run() end, { desc = "Run Nearest Test" })
map("n", "<leader>tf", function() neotest.run.run(vim.fn.expand("%")) end, { desc = "Run File Tests" })
map("n", "<leader>ts", function() neotest.run.run({ suite = true }) end, { desc = "Run Test Suite" })
map("n", "<leader>tl", function() neotest.run.run_last() end, { desc = "Run Last Test" })
map("n", "<leader>td", function() neotest.run.run({ strategy = "dap" }) end, { desc = "Debug Nearest Test" })

-- Test navigation
map("n", "<leader>to", function() neotest.output.open({ enter = true, auto_close = true }) end, { desc = "Show Test Output" })
map("n", "<leader>tO", function() neotest.output_panel.toggle() end, { desc = "Toggle Output Panel" })
map("n", "<leader>tS", function() neotest.summary.toggle() end, { desc = "Toggle Test Summary" })

-- Test management
map("n", "<leader>tx", function() neotest.run.stop() end, { desc = "Stop Test" })
map("n", "<leader>ta", function() neotest.run.attach() end, { desc = "Attach to Test" })

-- Test navigation in summary
map("n", "]t", function() neotest.jump.next({ status = "failed" }) end, { desc = "Next Failed Test" })
map("n", "[t", function() neotest.jump.prev({ status = "failed" }) end, { desc = "Previous Failed Test" })

-- Test watching
map("n", "<leader>tw", function() neotest.watch.toggle() end, { desc = "Toggle Test Watch" })
map("n", "<leader>tW", function() neotest.watch.toggle(vim.fn.expand("%")) end, { desc = "Toggle File Watch" })

-- ============================================================================
-- NEOTEST AUTOCOMMANDS
-- ============================================================================

-- Auto-open test results on failure
vim.api.nvim_create_autocmd("User", {
    pattern = "NeotestResult",
    callback = function(args)
        local results = args.data
        if results and results.results then
            for _, result in pairs(results.results) do
                if result.status == "failed" then
                    -- Auto-open output for failed tests
                    vim.schedule(function()
                        neotest.output.open({ enter = false, auto_close = true })
                    end)
                    break
                end
            end
        end
    end,
})

-- Integration with DAP for debugging
vim.api.nvim_create_autocmd("User", {
    pattern = "NeotestAttach",
    callback = function()
        -- Ensure DAP is available for test debugging
        local ok, dap = pcall(require, "dap")
        if ok then
            -- Configure DAP for test debugging if not already configured
            if not dap.configurations.php then
                dap.configurations.php = {
                    {
                        type = "php",
                        request = "launch",
                        name = "Debug PHPUnit Test",
                        program = "${workspaceFolder}/vendor/bin/phpunit",
                        args = { "${file}" },
                        cwd = "${workspaceFolder}",
                        env = {
                            APP_ENV = "testing",
                        },
                    },
                }
            end
        end
    end,
})

-- ============================================================================
-- INTEGRATION WITH EXISTING WORKFLOW
-- ============================================================================

-- Integration with Telescope for test selection
vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
        -- Add telescope integration if available
        local ok, telescope = pcall(require, "telescope")
        if ok then
            -- Register neotest picker
            telescope.load_extension("neotest")
            
            -- Add keymap for test picker
            map("n", "<leader>ft", function()
                require("telescope").extensions.neotest.neotest({})
            end, { desc = "Find Tests" })
        end
        
        -- Integration with snacks picker if available
        local ok_snacks, snacks = pcall(require, "snacks")
        if ok_snacks and snacks.picker then
            map("n", "<leader>fT", function()
                local tests = neotest.state.positions()
                local items = {}
                
                for _, test in pairs(tests) do
                    if test.type == "test" then
                        table.insert(items, {
                            text = test.name,
                            filename = test.path,
                            lnum = test.range and test.range[1] or 1,
                            col = test.range and test.range[2] or 1,
                        })
                    end
                end
                
                snacks.picker.pick(items, {
                    prompt = "Tests",
                    actions = {
                        ["default"] = function(item)
                            vim.cmd("edit " .. item.filename)
                            vim.api.nvim_win_set_cursor(0, { item.lnum, item.col })
                            neotest.run.run()
                        end,
                    },
                })
            end, { desc = "Find Tests (Snacks)" })
        end
    end,
})

-- Integration with trouble.nvim for test diagnostics
vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
        local ok, trouble = pcall(require, "trouble")
        if ok then
            -- Add keymap to show test results in trouble
            map("n", "<leader>xt", function()
                trouble.open("neotest")
            end, { desc = "Test Results (Trouble)" })
        end
    end,
})

-- ============================================================================
-- STATUSLINE INTEGRATION
-- ============================================================================

-- Function to get test status for statusline
_G.neotest_status = function()
    local ok, neotest = pcall(require, "neotest")
    if not ok then return "" end
    
    local status = neotest.state.status_counts()
    if not status or vim.tbl_isempty(status) then return "" end
    
    local parts = {}
    if status.passed and status.passed > 0 then
        table.insert(parts, "✓" .. status.passed)
    end
    if status.failed and status.failed > 0 then
        table.insert(parts, "✖" .. status.failed)
    end
    if status.running and status.running > 0 then
        table.insert(parts, "●" .. status.running)
    end
    
    if #parts > 0 then
        return " [" .. table.concat(parts, " ") .. "]"
    end
    return ""
end