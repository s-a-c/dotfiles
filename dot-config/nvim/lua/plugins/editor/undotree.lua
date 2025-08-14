-- ============================================================================
-- UNDOTREE CONFIGURATION
-- ============================================================================
-- Visual undo tree configuration

-- Undotree settings
vim.g.undotree_WindowLayout = 2
vim.g.undotree_SplitWidth = 40
vim.g.undotree_SetFocusWhenToggle = 1
vim.g.undotree_ShortIndicators = 1
vim.g.undotree_DiffAutoOpen = 1
vim.g.undotree_DiffpanelHeight = 10
vim.g.undotree_RelativeTimestamp = 1
vim.g.undotree_TreeNodeShape = '*'
vim.g.undotree_TreeVertShape = '|'
vim.g.undotree_TreeSplitShape = '/'
vim.g.undotree_TreeReturnShape = '\\'
vim.g.undotree_DiffCommand = "diff"

-- Undotree keymaps
vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle, { desc = "Toggle undotree" })
vim.keymap.set("n", "<leader>uf", vim.cmd.UndotreeFocus, { desc = "Focus undotree" })
vim.keymap.set("n", "<leader>uh", vim.cmd.UndotreeHide, { desc = "Hide undotree" })
vim.keymap.set("n", "<leader>us", vim.cmd.UndotreeShow, { desc = "Show undotree" })
