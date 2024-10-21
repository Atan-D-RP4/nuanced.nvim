-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Better Escape
vim.keymap.set('n', '<Esc>', '<C-c><C-c>', { noremap = true })
vim.keymap.set('i', '<Esc>', '<Esc><Esc>', { noremap = true, desc = 'Better Escape' })
-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- NOTE: Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- My Keybinds
vim.keymap.set('i', '<C-U>', '<C-G>u<C-U>', { noremap = true })
vim.keymap.set('n', "<leader>'", ':terminal fish<CR>', { noremap = true, desc = 'Open Terminal Buffer' })

-- Buffer Management
vim.keymap.set('n', '<leader>]', ':bnext!<CR>', { noremap = true, silent = true, desc = 'Next Buffer' })
vim.keymap.set('n', '<leader>[', ':bprevious!<CR>', { noremap = true, silent = true, desc = 'Previous Buffer' })
vim.keymap.set('n', '<leader>d', ':bdelete! %<CR>', { noremap = true, silent = true, desc = 'Delete Buffer' })
vim.keymap.set('n', '<leader>u', ':edit! #<CR>', { noremap = true, silent = true, desc = 'Refresh Buffer' })

-- CTRL+S for Save
vim.keymap.set('n', '<C-S>', '<ESC>:update<CR>', { noremap = true, silent = true, desc = 'Better Save' })
vim.keymap.set('i', '<C-S>', '<Esc>:update<CR>', { noremap = true, silent = true, desc = 'Better Save' })
vim.keymap.set('v', '<C-S>', '<Esc>:update<CR>', { noremap = true, silent = true, desc = 'Better Save' })

-- Re-Select Visual Selection on Re-Indent
vim.keymap.set('v', '<', '<gv', { noremap = true, desc = 'Re-Select Visual Selection on Re-Indent' })
vim.keymap.set('v', '>', '>gv', { noremap = true, desc = 'Re-Select Visual Selection on Re-Indent' })

vim.keymap.set('n', 'j', 'gj', { noremap = false, desc = 'Better j for wrapping text lines - Normal' })
vim.keymap.set('n', 'k', 'gk', { noremap = false, desc = 'Better k for wrapping text lines - Normal' })
vim.keymap.set('v', 'j', 'gj', { noremap = false, desc = 'Better j for wrapping text lines - Visual' })
vim.keymap.set('v', 'k', 'gk', { noremap = false, desc = 'Better k for wrapping text lines - Visual' })

vim.keymap.set('n', '<C-q>', '<C-b>', { noremap = true, silent = true })
vim.keymap.set('v', '<C-q>', '<C-b>', { noremap = true, silent = true })

vim.keymap.set('n', '<S-w>', 'b', { noremap = true, silent = true })
vim.keymap.set('v', '<S-w>', 'b', { noremap = true, silent = true })

vim.keymap.set('n', '<leader>.', ':<Up><CR>', { noremap = true, silent = true, desc = 'Repeat Last Ex Command' })

-- Smarter Bracket Insertion
vim.keymap.set('i', '(;', '(<CR>);<Esc>O', { noremap = true })
vim.keymap.set('i', '(,', '(<CR>),<Esc>O', { noremap = true })
vim.keymap.set('i', '{;', '{<CR>};<Esc>O', { noremap = true })
vim.keymap.set('i', '{,', '{<CR>},<Esc>O', { noremap = true })
vim.keymap.set('i', '[;', '[<CR>];<Esc>O', { noremap = true })
vim.keymap.set('i', '[,', '[<CR>],<Esc>O', { noremap = true })
vim.keymap.set('i', '{<CR>', '{<CR>}<Esc>O', { noremap = true })

-- vim.keymap.set("n", ":", "q:", { noremap = true })
-- vim: ts=2 sts=2 sw=2 et
