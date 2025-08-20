-- ============================================================================
-- PLUGIN MANAGEMENT AND LOADING
-- ============================================================================
-- This file manages plugin installation and loading using vim.pack

local M = {}

-- ============================================================================
-- MINI.NVIM BOOTSTRAP
-- ============================================================================

local function bootstrap_mini()
    local path_package = vim.fn.stdpath('data') .. '/site'
    local mini_path = path_package .. '/pack/deps/start/mini.nvim'

    if not vim.loop.fs_stat(mini_path) then
        vim.cmd('echo "Installing `mini.nvim`" | redraw')
        local clone_cmd = {
            'git', 'clone', '--filter=blob:none',
            -- Uncomment next line to use 'stable' branch
            -- '--branch', 'stable',
            'https://github.com/echasnovski/mini.nvim', mini_path
        }
        vim.fn.system(clone_cmd)
        vim.cmd('packadd mini.nvim | helptags ALL')
        vim.cmd('echo "Installed `mini.nvim`" | redraw')
    end
end

-- ============================================================================
-- PLUGIN DECLARATIONS
-- ============================================================================

local function setup_plugins()
    vim.pack.add({
        -- Core dependencies
        { src = "https://github.com/nvim-lua/plenary.nvim" },
        { src = "https://github.com/MunifTanjim/nui.nvim" },
        { src = "https://github.com/kevinhwang91/promise-async" },

        -- Mini.nvim suite
        { src = "https://github.com/echasnovski/mini.nvim" },

        -- UI and Dashboard
        { src = "https://github.com/nvim-tree/nvim-web-devicons" },
        { src = "https://github.com/folke/snacks.nvim" },
        { src = "https://github.com/folke/which-key.nvim" },
        { src = "https://github.com/folke/noice.nvim" },

        -- File management and navigation
        { src = "https://github.com/nvim-telescope/telescope.nvim" },
        { src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim" },
        { src = "https://github.com/stevearc/oil.nvim" },
        { src = "https://github.com/nvim-pack/nvim-spectre" },
        { src = "https://github.com/folke/flash.nvim" },

        -- Treesitter and syntax
        { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
        { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects" },

        -- LSP and completion
        { src = "https://github.com/neovim/nvim-lspconfig" },
        { src = "https://github.com/mason-org/mason.nvim" },
        { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
        { src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" },
        { src = "https://github.com/saghen/blink.cmp",                           checkout = "v0.*" },

        -- Git integration
        { src = "https://github.com/tpope/vim-fugitive" },
        { src = "https://github.com/lewis6991/gitsigns.nvim" },

        -- Editor enhancements
        { src = "https://github.com/ThePrimeagen/harpoon",                       checkout = "harpoon2" },
        { src = "https://github.com/mbbill/undotree" },
        { src = "https://github.com/kevinhwang91/nvim-ufo" },
        { src = "https://github.com/karb94/neoscroll.nvim" },
        { src = "https://github.com/folke/smear-cursor.nvim" },
        { src = "https://github.com/rachartier/tiny-inline-diagnostic.nvim" },
        { src = "https://github.com/stevearc/conform.nvim" },
        { src = "https://github.com/numToStr/Comment.nvim" },
        { src = "https://github.com/folke/persistence.nvim" },
        { src = "https://github.com/lukas-reineke/indent-blankline.nvim" },

        -- Testing framework
        { src = "https://github.com/nvim-neotest/nvim-nio" }, -- Required dependency for neotest
        { src = "https://github.com/nvim-neotest/neotest" },
        { src = "https://github.com/olimorris/neotest-phpunit" },
        { src = "https://github.com/nvim-neotest/neotest-jest" },
        { src = "https://github.com/marilari88/neotest-vitest" },

        -- Documentation generation
        { src = "https://github.com/danymat/neogen" },

        -- Time tracking
        { src = "https://github.com/wakatime/vim-wakatime" },

        -- Debugging
        { src = "https://github.com/mfussenegger/nvim-dap" },
        { src = "https://github.com/nvim-telescope/telescope-dap.nvim" },

        -- Themes
        { src = "https://github.com/vague2k/vague.nvim" },
        { src = "https://github.com/catppuccin/nvim" },
        { src = "https://github.com/rebelot/kanagawa.nvim" },
        { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },
        { src = "https://github.com/ellisonleao/gruvbox.nvim" },
        { src = "https://github.com/folke/tokyonight.nvim" },
        { src = "https://github.com/folke/trouble.nvim" },
        { src = "https://github.com/folke/twilight.nvim" },
        { src = "https://github.com/miikanissi/modus-themes.nvim" },

        -- Fun
        { src = "https://github.com/nvzone/volt" },
        { src = "https://github.com/nvzone/typr" },

        -- Learning and productivity training
        { src = "https://github.com/tris203/precognition.nvim" },
        { src = "https://github.com/m4xshen/hardtime.nvim" },
        { src = "https://github.com/ThePrimeagen/vim-be-good" },

        -- Language specific
        { src = "https://github.com/chomosuke/typst-preview.nvim" },

        -- Laravel Development
        { src = "https://github.com/adalessa/laravel.nvim" },
        { src = "https://github.com/ricardoramirezr/blade-nav.nvim" },
        { src = "https://github.com/jwalton512/vim-blade" },

        -- AI Assistance
        { src = "https://github.com/github/copilot.vim" },
        { src = "https://github.com/CopilotC-Nvim/CopilotChat.nvim",             checkout = "canary" },
        { src = "https://github.com/fang2hou/blink-copilot" },
        { src = "https://github.com/augmentcode/augment.vim" },
        { src = "https://github.com/Exafunction/codeium.nvim" },
        { src = "https://github.com/olimorris/codecompanion.nvim" },
        { src = "https://github.com/David-Kunz/gen.nvim" },
        { src = "https://github.com/yetone/avante.nvim" },

        -- MCP (Model Context Protocol) Integration - Placeholder for future implementation
        -- Note: mcphub.nvim is a conceptual plugin for MCP integration
        -- { src = "https://github.com/mcphub/mcphub.nvim" },

        -- Note taking
        { src = "https://github.com/nvim-neorg/neorg" },

        -- Command line enhancement
        { src = "https://github.com/gelguy/wilder.nvim" },

        -- Telescope extensions
        { src = "https://github.com/jvgrootveld/telescope-zoxide" },
        { src = "https://github.com/nvim-neorg/neorg-telescope" },
        { src = "https://github.com/gbirke/telescope-foldmarkers.nvim" },
        { src = "https://github.com/zschreur/telescope-jj.nvim" },
        { src = "https://github.com/nvim-telescope/telescope-github.nvim" },
        { src = "https://github.com/nvim-telescope/telescope-media-files.nvim" },
        { src = "https://github.com/nvim-telescope/telescope-fzf-writer.nvim" },
        { src = "https://github.com/nvim-telescope/telescope-symbols.nvim" },
        { src = "https://github.com/olacin/telescope-cc.nvim" },
        { src = "https://github.com/sudormrfbin/cheatsheet.nvim" },
        { src = "https://github.com/nat-418/telescope-color-names.nvim" },
        { src = "https://github.com/octarect/telescope-menu.nvim" },
        { src = "https://github.com/debugloop/telescope-undo.nvim" },
    })
end

-- ============================================================================
-- PLUGIN CONFIGURATION LOADER
-- ============================================================================

local function load_plugin_configs()
    -- ========================================================================
    -- PHASE 0: PERFORMANCE MONITORING SETUP
    -- ========================================================================
    local start_time = vim.fn.reltime()
    local phase_times = {}

    local function log_phase(phase_name)
        local elapsed = vim.fn.reltimefloat(vim.fn.reltime(start_time)) * 1000
        phase_times[phase_name] = elapsed
        if vim.g.snacks_debug_loading then
            vim.notify(string.format("%s completed in %.2fms", phase_name, elapsed),
                vim.log.levels.DEBUG, { title = "Plugin Loading" })
        end
    end

    -- ========================================================================
    -- PHASE 1: CRITICAL DEPENDENCIES (Load immediately for stability)
    -- ========================================================================
    vim.cmd('packadd plenary.nvim')
    vim.cmd('packadd nui.nvim')
    vim.cmd('packadd promise-async')

    -- Essential UI foundation (many plugins depend on these)
    require("plugins.ui.nvim-web-devicons")
    require("plugins.ui.which-key") -- Load early for keymap registration

    log_phase("Phase 1: Critical Dependencies")

    -- ========================================================================
    -- PHASE 2: CORE FUNCTIONALITY (Essential for basic editing)
    -- ========================================================================

    -- Snacks.nvim (load early for maximum integration)
    require("plugins.ui.dashboard") -- Contains snacks.nvim setup

    -- Treesitter (syntax highlighting foundation)
    require("plugins.editor.treesitter")

    -- LSP and completion (critical for development)
    require("plugins.lsp")

    -- Optimized Mini.nvim suite (lightweight, fast loading)
    require("plugins.editor.mini")

    -- Core editor enhancements
    require("plugins.editor.comment")
    require("plugins.editor.conform")
    require("plugins.editor.persistence")

    log_phase("Phase 2: Core Functionality")

    -- ========================================================================
    -- PHASE 3: UI AND NAVIGATION (Conditional and optimized loading)
    -- ========================================================================

    vim.defer_fn(function()
        -- Check if we're in a large project (optimize loading)
        local file_count = vim.fn.system("find . -type f | wc -l 2>/dev/null"):gsub("%s+", "")
        local is_large_project = tonumber(file_count) and tonumber(file_count) > 1000

        -- Telescope and navigation (essential)
        require("plugins.ui.telescope")
        require("plugins.editor.harpoon")

        -- Essential editor tools
        require("plugins.editor.oil")
        require("plugins.editor.flash")
        require("plugins.editor.spectre")

        -- UI enhancements (conditional loading for large projects)
        if not is_large_project or vim.g.force_ui_plugins then
            require("plugins.ui.noice")
            require("plugins.ui.themes")
            require("plugins.ui.trouble")
            require("plugins.ui.render-markdown")
        end

        -- Advanced editor features
        require("plugins.editor.ufo")
        require("plugins.editor.undotree")
        require("plugins.editor.tiny-inline-diagnostic")
        require("plugins.editor.indent-blankline")

        log_phase("Phase 3: UI and Navigation")
    end, 50) -- 50ms delay

    -- ========================================================================
    -- PHASE 4: DEVELOPMENT TOOLS (Load after core functionality)
    -- ========================================================================

    vim.defer_fn(function()
        -- Git integration (essential for development)
        require("plugins.git.fugitive")
        require("plugins.git.gitsigns")

        -- Testing and documentation (conditional)
        if vim.g.enable_testing_plugins ~= false then
            require("plugins.editor.neotest")
            require("plugins.editor.neogen")
        end

        -- Debug tools (conditional)
        if vim.g.enable_debug_plugins ~= false then
            require("plugins.debug.dap")
        end

        -- Language specific (conditional based on file types)
        local php_files = vim.fn.glob("**/*.php", false, true)
        if #php_files > 0 or vim.g.force_php_plugins then
            require("plugins.lang.php")
        end

        log_phase("Phase 4: Development Tools")
    end, 100) -- 100ms delay

    -- ========================================================================
    -- PHASE 5: AI ASSISTANCE (Load after essential tools are ready)
    -- ========================================================================

    vim.defer_fn(function()
        -- Check if AI features are enabled
        if vim.g.enable_ai_plugins ~= false then
            -- Core AI tools (load in dependency order)
            require("plugins.ai.copilot")
            require("plugins.ai.blink-copilot")
            require("plugins.ai.copilot-chat")

            -- Additional AI tools (conditional)
            if vim.g.enable_extended_ai then
                require("plugins.ai.codeium")
                require("plugins.ai.augment")
                require("plugins.ai.avante")
            end

            -- MCP Integration (conditional loading with enhanced error handling)
            local mcphub_ok, mcphub_err = pcall(require, "plugins.ai.mcphub")
            if not mcphub_ok then
                if mcphub_err:match("module 'mcphub'") then
                    vim.notify("mcphub.nvim not installed - MCP features disabled", vim.log.levels.INFO)
                else
                    vim.notify("mcphub.nvim configuration error: " .. mcphub_err, vim.log.levels.WARN)
                end
            end
        end

        log_phase("Phase 5: AI Assistance")
    end, 200) -- 200ms delay

    -- ========================================================================
    -- PHASE 6: NON-ESSENTIAL FEATURES (Load last for optimal startup)
    -- ========================================================================

    vim.defer_fn(function()
        -- Visual enhancements (conditional)
        if vim.g.enable_visual_plugins ~= false then
            require("plugins.editor.neoscroll")
            require("plugins.editor.smear-cursor")
            require("plugins.editor.twilight")
        end

        -- Learning and productivity tools (conditional)
        if vim.g.enable_learning_plugins ~= false then
            require("plugins.editor.precognition")
            require("plugins.editor.hardtime")
            require("plugins.editor.vim-be-good")
        end

        -- Time tracking (conditional)
        if vim.g.enable_wakatime then
            require("plugins.editor.wakatime")
        end

        -- Fun features (conditional)
        if vim.g.enable_fun_plugins then
            require("plugins.fun.typr")
        end

        log_phase("Phase 6: Non-Essential Features")

        -- Final performance report
        if vim.g.snacks_debug_loading then
            local total_time = vim.fn.reltimefloat(vim.fn.reltime(start_time)) * 1000
            vim.schedule(function()
                vim.notify(string.format("Plugin loading completed in %.2fms", total_time),
                    vim.log.levels.INFO, { title = "Performance" })
            end)
        end
    end, 500) -- 500ms delay
end

-- ============================================================================
-- MAIN SETUP FUNCTION
-- ============================================================================

function M.setup()
    -- Bootstrap mini.nvim first
    bootstrap_mini()

    -- Setup plugins
    setup_plugins()

    -- Load plugin configurations
    load_plugin_configs()
end

return M
