-- Capture checkhealth output
vim.cmd('redir! > checkhealth_complete.txt')
vim.cmd('checkhealth')
vim.cmd('redir END')
vim.cmd('qa!')
