-- [[ Basic Keymaps ]]
--  See `:helpvim.keymap.set()`

local map = require("utils").map
local nmap = require("utils").nmap
local tmap = require("utils").tmap
local imap = require("utils").imap
local vmap = require("utils").vmap

-- Better Escape

nmap("<Esc>", "<C-c><C-c>", { noremap = true })
imap("<Esc>", "<Esc><Esc><Right>", { noremap = true, desc = "Better Escape" })
-- Clear highlights on search when pressing <Esc> in normal mode

--  See `:help hlsearch`
nmap("<Esc>", "<cmd>nohlsearch<CR>", { noremap = true, silent = true, desc = "Clear highlights on search" })

-- Diagnostic keymaps
nmap("<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
tmap("<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- NOTE: Disable arrow keys in normal mode
nmap("<left>", '<cmd>echo "Use h to move!!"<CR>')
nmap("<right>", '<cmd>echo "Use l to move!!"<CR>')
nmap("<up>", '<cmd>echo "Use k to move!!"<CR>')
nmap("<down>", '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
nmap("<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
nmap("<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
nmap("<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
nmap("<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- My Keybinds
imap("<C-U>", "<C-G>u<C-U>", { noremap = true })
nmap("<leader>'", ":terminal fish<CR>", { noremap = true, desc = "Open Terminal Buffer" })

-- Buffer Management
nmap("<leader>dd", ":bdelete! %<CR>", { noremap = true, silent = true, desc = "Delete Buffer" })
nmap("<leader>du", ":edit! #<CR>", { noremap = true, silent = true, desc = "Refresh Buffer" })

-- CTRL+S for Save
map({ "n", "v", "i" }, "<C-S>", "<ESC>:update<CR>", { noremap = true, silent = true, desc = "Better Save" })

-- Re-Select Visual Selection on Re-Indent
vmap("<", "<gv", { noremap = true, desc = "Re-Select Visual Selection on Re-Indent" })
vmap(">", ">gv", { noremap = true, desc = "Re-Select Visual Selection on Re-Indent" })

-- Even Smarter J/K to Line movements
map({ "n", "v" }, "j", "v:count ? (v:count > 5 ? 'm' . v:count : '') . 'j' : 'gj'", { expr = true, noremap = true })
map({ "n", "v" }, "k", "v:count ? (v:count > 5 ? 'm' . v:count : '') . 'k' : 'gk'", { expr = true, noremap = true })

map({ "n", "v" }, "<C-q>", "<C-b>", { noremap = true, silent = true })

map({ "n", "v" }, "<S-w>", "b", { noremap = true, silent = true })

nmap("<leader>.", ":<Up><CR>", { noremap = true, silent = true, desc = "Repeat Last Ex Command" })

-- Smarter Bracket Insertion
imap("(;", "(<CR>);<Esc>O", { noremap = true })
imap("(,", "(<CR>),<Esc>O", { noremap = true })
imap("{;", "{<CR>};<Esc>O", { noremap = true })
imap("{,", "{<CR>},<Esc>O", { noremap = true })
imap("[;", "[<CR>];<Esc>O", { noremap = true })
imap("[,", "[<CR>],<Esc>O", { noremap = true })
imap("{<CR>", "{<CR>}<Esc>O", { noremap = true })

-- Have Navigation Keys always center the cursor with zz
nmap("<C-d>", "<C-d>zz", { noremap = true })
nmap("<C-u>", "<C-u>zz", { noremap = true })
nmap("<C-f>", "<C-f>zz", { noremap = true })
nmap("<C-b>", "<C-b>zz", { noremap = true })
nmap("{", "{zz", { noremap = true })
nmap("}", "}zz", { noremap = true })
nmap("n", "nzz", { noremap = true })
nmap("N", "Nzz", { noremap = true })
nmap("[c", "[czz", { noremap = true })
nmap("]c", "]czz", { noremap = true })
nmap("[m", "[mzz", { noremap = true })
nmap("]m", "]mzz", { noremap = true })
nmap("[s", "[szz", { noremap = true })
nmap("]s", "]szz", { noremap = true })

imap("<C-v>", "<C-r>+", { noremap = true })

-- nmap( ":", "q:", { noremap = true })
--
-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

vim.api.nvim_create_autocmd("VimResized", {
	desc = "Resize splits when resizing the window",
	group = vim.api.nvim_create_augroup("kickstart-resize-splits", { clear = true }),
	callback = function()
		vim.cmd("wincmd =")
	end,
})

-- NOTE: Originally tried to put this in FileType event autocmd but it is apparently
-- too early for `set modifiable` to take effect
--
-- vim.api.nvim_create_autocmd('BufWinEnter', {
--   group = vim.api.nvim_create_augroup('YOUR_GROUP_HERE', { clear = true }),
--   desc = 'allow updating quickfix window',
--   pattern = 'quickfix',
--   callback = function(ctx)
--     vim.bo.modifiable = true
--     -- :vimgrep's quickfix window display format now includes start and end column (in vim and nvim) so adding 2nd format to match that
--     vim.bo.errorformat = '%f|%l col %c| %m,%f|%l col %c-%k| %m'
--     vim.keymap.set(
--     'n',
--     '<C-s>',
--     '<Cmd>cgetbuffer|set nomodified|echo "quickfix/location list updated"<CR>',
--     { buffer = true, desc = 'Update quickfix/location list with changes made in quickfix window' }
--     )
--   end,
-- })
-- vim: ts=2 sts=2 sw=2 et
