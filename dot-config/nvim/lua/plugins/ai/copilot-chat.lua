-- ============================================================================
-- COPILOT CHAT CONFIGURATION
-- ============================================================================
-- GitHub Copilot Chat integration for conversational AI assistance

-- Ensure CopilotChat is available
local ok, copilot_chat = pcall(require, "CopilotChat")
if not ok then
    vim.notify("CopilotChat not found", vim.log.levels.WARN)
    return
end

-- ============================================================================
-- COPILOT CHAT SETUP
-- ============================================================================

copilot_chat.setup({
    -- Debug mode (set to true for troubleshooting)
    debug = false,

    -- Model configuration
    model = 'gpt-5', -- Can be 'gpt-3.5-turbo' or 'gpt-4'

    -- Temperature for responses (0.0 to 2.0)
    temperature = 0.1,

    -- Chat window configuration
    window = {
        layout = 'vertical',    -- 'vertical', 'horizontal', 'float', 'replace'
        width = 0.33,           -- Percentage of screen width
        height = 0.5,           -- Percentage of screen height
        relative = 'editor',    -- 'editor', 'win', 'cursor', 'mouse'
        border = 'rounded',     -- 'none', 'single', 'double', 'rounded', 'solid', 'shadow'
        row = nil,              -- Row position (nil for center)
        col = nil,              -- Column position (nil for center)
        title = 'Copilot Chat', -- Window title
        footer = nil,           -- Window footer
        zindex = 1,             -- Window z-index
    },

    -- Chat behavior
    show_help = true,                 -- Show help text in chat
    show_folds = true,                -- Show folds in chat
    auto_follow_cursor = true,        -- Auto scroll to follow cursor
    auto_insert_mode = false,         -- Start in insert mode
    clear_chat_on_new_prompt = false, -- Clear chat when starting new conversation

    -- Context configuration
    context = 'buffer', -- 'buffer', 'buffers', 'visible', or nil

    -- History configuration
    history_path = vim.fn.stdpath('data') .. '/copilotchat_history',

    -- Callback functions
    callback = function(response, source)
        -- Optional: Custom callback for responses
    end,

    -- Selection configuration
    selection = function(source)
        -- Custom selection function
        return require("CopilotChat.select").visual(source) or require("CopilotChat.select").buffer(source)
    end,

    -- Prompts configuration
    prompts = {
        Explain = {
            prompt = '/COPILOT_EXPLAIN Write an explanation for the active selection as paragraphs of text.',
        },
        Review = {
            prompt = '/COPILOT_REVIEW Review the selected code.',
            callback = function(response, source)
                -- Custom callback for review
            end,
        },
        Fix = {
            prompt = '/COPILOT_GENERATE There is a problem in this code. Rewrite the code to show it with the bug fixed.',
        },
        Optimize = {
            prompt = '/COPILOT_GENERATE Optimize the selected code to improve performance and readability.',
        },
        Docs = {
            prompt = '/COPILOT_GENERATE Please add documentation comment for the selection.',
        },
        Tests = {
            prompt = '/COPILOT_GENERATE Please generate tests for my code.',
        },
        FixDiagnostic = {
            prompt = 'Please assist with the following diagnostic issue in file:',
            selection = require("CopilotChat.select").diagnostics,
        },
        Commit = {
            prompt =
            'Write commit message for the change with commitizen convention. Make sure the title has maximum 50 characters and message is wrapped at 72 characters. Wrap the whole message in code block with language gitcommit.',
            selection = require("CopilotChat.select").gitdiff,
        },
        CommitStaged = {
            prompt =
            'Write commit message for the change with commitizen convention. Make sure the title has maximum 50 characters and message is wrapped at 72 characters. Wrap the whole message in code block with language gitcommit.',
            selection = function(source)
                return require("CopilotChat.select").gitdiff(source, true)
            end,
        },
    },

    -- Mappings configuration
    mappings = {
        complete = {
            detail = 'Use @<Tab> or /<Tab> for options.',
            insert = '<Tab>',
        },
        close = {
            normal = 'q',
            insert = '<C-c>'
        },
        reset = {
            normal = '<C-r>',
            insert = '<C-r>'
        },
        submit_prompt = {
            normal = '<CR>',
            insert = '<C-s>'
        },
        accept_diff = {
            normal = '<C-y>',
            insert = '<C-y>'
        },
        yank_diff = {
            normal = 'gy',
            register = '"',
        },
        show_diff = {
            normal = 'gd'
        },
        show_system_prompt = {
            normal = 'gp'
        },
        show_user_selection = {
            normal = 'gs'
        },
    },
})

-- ============================================================================
-- COPILOT CHAT KEYMAPS
-- ============================================================================

local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Main chat operations (using <leader>ch prefix to avoid conflicts with Codeium)
keymap('n', '<leader>cho', '<cmd>CopilotChat<CR>', { desc = 'Open Copilot Chat' })
keymap('n', '<leader>cht', '<cmd>CopilotChatToggle<CR>', { desc = 'Toggle Copilot Chat' })
keymap('n', '<leader>chr', '<cmd>CopilotChatReset<CR>', { desc = 'Reset Copilot Chat' })
keymap('n', '<leader>chs', '<cmd>CopilotChatSave<CR>', { desc = 'Save Copilot Chat' })
keymap('n', '<leader>chl', '<cmd>CopilotChatLoad<CR>', { desc = 'Load Copilot Chat' })

-- Quick actions (using <leader>ch prefix to avoid conflicts with Codeium)
keymap('n', '<leader>che', '<cmd>CopilotChatExplain<CR>', { desc = 'Explain code' })
keymap('n', '<leader>chf', '<cmd>CopilotChatFix<CR>', { desc = 'Fix code' })
keymap('n', '<leader>chd', '<cmd>CopilotChatDocs<CR>', { desc = 'Generate docs' })
keymap('n', '<leader>chu', '<cmd>CopilotChatTests<CR>', { desc = 'Generate unit tests' })
keymap('n', '<leader>chp', '<cmd>CopilotChatOptimize<CR>', { desc = 'Optimize code' })

-- Visual mode actions (using <leader>ch prefix to avoid conflicts with Codeium)
keymap('v', '<leader>che', '<cmd>CopilotChatExplain<CR>', { desc = 'Explain selection' })
keymap('v', '<leader>chv', '<cmd>CopilotChatReview<CR>', { desc = 'Review selection' })
keymap('v', '<leader>chf', '<cmd>CopilotChatFix<CR>', { desc = 'Fix selection' })
keymap('v', '<leader>chd', '<cmd>CopilotChatDocs<CR>', { desc = 'Document selection' })
keymap('v', '<leader>chu', '<cmd>CopilotChatTests<CR>', { desc = 'Generate tests for selection' })
keymap('v', '<leader>chp', '<cmd>CopilotChatOptimize<CR>', { desc = 'Optimize selection' })

-- Git integration (using <leader>chg prefix for chat git commands)
keymap('n', '<leader>chgc', '<cmd>CopilotChatCommit<CR>', { desc = 'Generate commit message' })
keymap('n', '<leader>chgs', '<cmd>CopilotChatCommitStaged<CR>', { desc = 'Generate commit message for staged' })

-- Diagnostic assistance (using <leader>ch prefix to avoid conflicts with Codeium)
keymap('n', '<leader>chfd', '<cmd>CopilotChatFixDiagnostic<CR>', { desc = 'Fix diagnostic' })

-- Custom prompts (using <leader>ch prefix to avoid conflicts with Codeium)
keymap('n', '<leader>chq', function()
    local input = vim.fn.input("Quick Chat: ")
    if input ~= "" then
        require("CopilotChat").ask(input, { selection = require("CopilotChat.select").buffer })
    end
end, { desc = 'Quick chat' })

-- Buffer-specific chat (using <leader>ch prefix to avoid conflicts with Codeium)
keymap('n', '<leader>chb', function()
    local input = vim.fn.input("Chat about buffer: ")
    if input ~= "" then
        require("CopilotChat").ask(input, { selection = require("CopilotChat.select").buffer })
    end
end, { desc = 'Chat about current buffer' })

-- ============================================================================
-- COPILOT CHAT AUTOCOMMANDS
-- ============================================================================

local augroup = vim.api.nvim_create_augroup("CopilotChat", { clear = true })

-- Auto-resize chat window when Neovim is resized
vim.api.nvim_create_autocmd("VimResized", {
    group = augroup,
    callback = function()
        if require("CopilotChat").buf_is_loaded() then
            require("CopilotChat").close()
            require("CopilotChat").open()
        end
    end,
})

-- Set filetype for better syntax highlighting in chat
vim.api.nvim_create_autocmd("BufEnter", {
    group = augroup,
    pattern = "copilot-chat",
    callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.linebreak = true
        vim.opt_local.breakindent = true
    end,
})

-- ============================================================================
-- WHICH-KEY INTEGRATION
-- ============================================================================

-- Register which-key descriptions if available
local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
    wk.add({
        { "<leader>ch", group = "🤖 Copilot Chat" },
        { "<leader>cho", desc = "Open Chat" },
        { "<leader>cht", desc = "Toggle Chat" },
        { "<leader>chr", desc = "Reset Chat" },
        { "<leader>chs", desc = "Save Chat" },
        { "<leader>chl", desc = "Load Chat" },
        { "<leader>che", desc = "Explain" },
        { "<leader>chf", desc = "Fix" },
        { "<leader>chd", desc = "Docs" },
        { "<leader>chu", desc = "Unit Tests" },
        { "<leader>chp", desc = "Optimize" },
        { "<leader>chv", desc = "Review" },
        { "<leader>chq", desc = "Quick Chat" },
        { "<leader>chb", desc = "Chat Buffer" },
        { "<leader>chg", group = "Git" },
        { "<leader>chgc", desc = "Commit Message" },
        { "<leader>chgs", desc = "Commit Staged" },
        { "<leader>chfd", desc = "Fix Diagnostic" },
    })

    -- Visual mode descriptions
    wk.add({
        { "<leader>ch", group = "🤖 Copilot Chat", mode = "v" },
        { "<leader>che", desc = "Explain Selection", mode = "v" },
        { "<leader>chv", desc = "Review Selection", mode = "v" },
        { "<leader>chf", desc = "Fix Selection", mode = "v" },
        { "<leader>chd", desc = "Document Selection", mode = "v" },
        { "<leader>chu", desc = "Test Selection", mode = "v" },
        { "<leader>chp", desc = "Optimize Selection", mode = "v" },
    })
end
