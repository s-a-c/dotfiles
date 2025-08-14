-- ============================================================================
-- FUGITIVE GIT CONFIGURATION
-- ============================================================================
-- Git integration configuration

-- Fugitive is loaded automatically, no setup required

-- ============================================================================
-- FUGITIVE KEYMAPS
-- ============================================================================

-- Basic Git operations
vim.keymap.set("n", "<leader>gs", vim.cmd.Git, { desc = "Git status" })
vim.keymap.set("n", "<leader>ga", "<cmd>Git add .<cr>", { desc = "Git add all" })
vim.keymap.set("n", "<leader>gA", "<cmd>Git add %<cr>", { desc = "Git add current file" })
vim.keymap.set("n", "<leader>gc", "<cmd>Git commit<cr>", { desc = "Git commit" })
vim.keymap.set("n", "<leader>gC", "<cmd>Git commit --amend<cr>", { desc = "Git commit amend" })
vim.keymap.set("n", "<leader>gp", "<cmd>Git push<cr>", { desc = "Git push" })
vim.keymap.set("n", "<leader>gP", "<cmd>Git pull<cr>", { desc = "Git pull" })
vim.keymap.set("n", "<leader>gf", "<cmd>Git fetch<cr>", { desc = "Git fetch" })
vim.keymap.set("n", "<leader>gl", "<cmd>Git log --oneline<cr>", { desc = "Git log" })
vim.keymap.set("n", "<leader>gL", "<cmd>Git log<cr>", { desc = "Git log detailed" })
vim.keymap.set("n", "<leader>gd", "<cmd>Gdiffsplit<cr>", { desc = "Git diff split" })
vim.keymap.set("n", "<leader>gD", "<cmd>Gdiffsplit HEAD<cr>", { desc = "Git diff HEAD" })
vim.keymap.set("n", "<leader>gb", "<cmd>Git blame<cr>", { desc = "Git blame" })
vim.keymap.set("n", "<leader>gB", "<cmd>GBrowse<cr>", { desc = "Git browse" })
vim.keymap.set("n", "<leader>gr", "<cmd>Gread<cr>", { desc = "Git read (checkout file)" })
vim.keymap.set("n", "<leader>gw", "<cmd>Gwrite<cr>", { desc = "Git write (stage file)" })
vim.keymap.set("n", "<leader>gx", "<cmd>GDelete<cr>", { desc = "Git delete file" })
vim.keymap.set("n", "<leader>gm", "<cmd>GMove<cr>", { desc = "Git move/rename file" })

-- Git branch operations
vim.keymap.set("n", "<leader>gco", "<cmd>Git checkout<cr>", { desc = "Git checkout" })
vim.keymap.set("n", "<leader>gcb", "<cmd>Git checkout -b ", { desc = "Git checkout new branch" })
vim.keymap.set("n", "<leader>gM", "<cmd>Git merge<cr>", { desc = "Git merge" })

-- Git stash operations
vim.keymap.set("n", "<leader>gss", "<cmd>Git stash<cr>", { desc = "Git stash" })
vim.keymap.set("n", "<leader>gsp", "<cmd>Git stash pop<cr>", { desc = "Git stash pop" })
vim.keymap.set("n", "<leader>gsl", "<cmd>Git stash list<cr>", { desc = "Git stash list" })

-- Conflict resolution
vim.keymap.set("n", "<leader>gh", "<cmd>diffget //2<cr>", { desc = "Get left (HEAD)" })
vim.keymap.set("n", "<leader>gj", "<cmd>diffget //3<cr>", { desc = "Get right (merge)" })
