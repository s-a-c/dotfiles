-- ============================================================================
-- BLINK.CMP COMPLETION CONFIGURATION
-- ============================================================================
-- Modern completion engine configuration

-- Check blink.cmp fuzzy library status
local function check_blink_fuzzy()
    local blink_path = vim.fn.stdpath('data') .. '/site/pack/core/opt/blink.cmp'

    -- Check if blink.cmp directory exists
    if vim.fn.isdirectory(blink_path) == 0 then
        vim.notify("blink.cmp not found at expected path", vim.log.levels.WARN)
        return false
    end

    -- Let blink.cmp handle fuzzy library download/build automatically
    -- The plugin will download prebuilt binaries or fallback to Lua implementation
    vim.notify("blink.cmp found, fuzzy library will be handled automatically", vim.log.levels.INFO)
    return true
end

-- Check blink.cmp status
local blink_available = check_blink_fuzzy()

-- ============================================================================
-- BLINK.CMP CONFIGURATION
-- ============================================================================

-- Setup blink.cmp with comprehensive configuration
local ok, blink = pcall(require, "blink.cmp")
if not ok then
    vim.notify("blink.cmp not found, skipping configuration", vim.log.levels.WARN)
    return
end

blink.setup({
    -- Keymap configuration
    keymap = {
        preset = 'default',
        ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
        ['<C-e>'] = { 'hide' },
        ['<C-y>'] = { 'select_and_accept' },
        ['<C-p>'] = { 'select_prev', 'fallback' },
        ['<C-n>'] = { 'select_next', 'fallback' },
        ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
        ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
        ['<Tab>'] = { 'snippet_forward', 'fallback' },
        ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
    },

    -- Appearance configuration
    appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = 'mono'
    },

    -- Fuzzy matching configuration
    fuzzy = {
        implementation = 'prefer_rust_with_warning',
        max_typos = function(keyword) return math.floor(#keyword / 4) end,
        use_frecency = true,
        use_proximity = true,
        use_unsafe_no_lock = false,
        sorts = { 'score', 'sort_text' },
        prebuilt_binaries = {
            download = true,
            ignore_version_mismatch = false,
            force_version = nil,
            force_system_triple = nil,
            extra_curl_args = {},
            proxy = {
                from_env = true,
                url = nil,
            },
        },
    },

    -- Source configuration
    sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
        providers = {
            lsp = {
                name = 'LSP',
                module = 'blink.cmp.sources.lsp',
                enabled = true,
            },
            path = {
                name = 'Path',
                module = 'blink.cmp.sources.path',
                enabled = true,
                opts = {
                    trailing_slash = false,
                    label_trailing_slash = true,
                    get_cwd = function(context) return vim.fn.expand(('#%d:p:h'):format(context.bufnr)) end,
                    show_hidden_files_by_default = false,
                }
            },
            snippets = {
                name = 'Snippets',
                module = 'blink.cmp.sources.snippets',
                enabled = true,
            },
            buffer = {
                name = 'Buffer',
                module = 'blink.cmp.sources.buffer',
                enabled = true,
            },
        },
    },

    -- Completion configuration
    completion = {
        accept = {
            create_undo_point = true,
            auto_brackets = {
                enabled = true,
                default_brackets = { '(', ')' },
                override_brackets_for_filetypes = {},
                force_allow_filetypes = {},
                blocked_filetypes = {},
            },
        },
        menu = {
            enabled = true,
            min_width = 15,
            max_height = 10,
            border = 'none',
            winblend = vim.o.pumblend,
            winhighlight = 'Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None',
            scrollbar = true,
            direction_priority = { 's', 'n' },
            auto_show = true,
        },
        documentation = {
            auto_show = true,
            auto_show_delay_ms = 500,
            update_delay_ms = 50,
            treesitter_highlighting = true,
            window = {
                min_width = 10,
                max_width = 60,
                max_height = 20,
                border = 'padded',
                winblend = vim.o.pumblend,
                winhighlight = 'Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:BlinkCmpDocCursorLine,Search:None',
                direction_priority = {
                    menu_north = { 'e', 'w', 'n', 's' },
                    menu_south = { 'e', 'w', 's', 'n' },
                },
            },
        },
        ghost_text = {
            enabled = vim.g.ai_cmp == false,
        },
    },

    -- Signature help configuration
    signature = {
        enabled = true,
        trigger = {
            blocked_trigger_characters = {},
            blocked_retrigger_characters = {},
            show_on_insert_on_trigger_character = true,
        },
        window = {
            min_width = 1,
            max_width = 100,
            max_height = 10,
            border = 'padded',
            winblend = vim.o.pumblend,
            winhighlight = 'Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder',
            scrollbar = false,
            direction_priority = { 'n', 's' },
        },
    },
})

-- Add Copilot integration if available
local copilot_ok, _ = pcall(require, "blink-copilot")
if copilot_ok then
    vim.notify("blink-copilot integration available", vim.log.levels.INFO)
end

vim.notify("blink.cmp configured successfully", vim.log.levels.INFO)
