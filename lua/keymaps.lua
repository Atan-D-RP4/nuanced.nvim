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
tmap('<Esc><Esc>', '<C-\\><C-n>', { noremap = true, silent = true, desc = 'Exit terminal mode' })

-- NOTE: Disable arrow keys in normal mode
nmap('<left>', '<cmd>echo "Use h to move!!"<CR>', { noremap = true, silent = true })
nmap('<right>', '<cmd>echo "Use l to move!!"<CR>', { noremap = true, silent = true })
nmap('<up>', '<cmd>echo "Use k to move!!"<CR>', { noremap = true, silent = true })
nmap('<down>', '<cmd>echo "Use j to move!!"<CR>', { noremap = true, silent = true })

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
nmap('<C-h>', '<C-w><C-h>', { noremap = true, silent = true, desc = 'Move focus to the left window' })
nmap('<C-l>', '<C-w><C-l>', { noremap = true, silent = true, desc = 'Move focus to the right window' })
nmap('<C-j>', '<C-w><C-j>', { noremap = true, silent = true, desc = 'Move focus to the lower window' })
nmap('<C-k>', '<C-w><C-k>', { noremap = true, silent = true, desc = 'Move focus to the upper window' })

-- My Keybinds
imap('<C-U>', '<C-G>u<C-U>', { noremap = true, silent = true })
nmap("<leader>'", ':terminal fish<CR>', { noremap = true, silent = true, desc = 'Open Terminal Buffer' })

-- Buffer Management
-- nmap('<leader>dd', ':bdelete! %<CR>', { noremap = true, silent = true, desc = 'Delete Buffer' })
nmap('<leader>du', ':update! <CR>', { noremap = true, silent = true, desc = 'Refresh Buffer' })

-- CTRL+S for Save
map({ 'n', 'v', 'i' }, '<C-S>', '<ESC>:update<CR>', { noremap = true, silent = true, desc = 'Better Save' })

-- Re-Select Visual Selection on Re-Indent
vmap('<', '<gv', { noremap = true, silent = true, desc = 'Re-Select Visual Selection on Re-Indent' })
vmap('>', '>gv', { noremap = true, silent = true, desc = 'Re-Select Visual Selection on Re-Indent' })

-- Even Smarter J/K to Line movements
map({ 'n', 'v' }, 'j', "v:count ? (v:count > 5 ? 'm' . v:count : '') . 'j' : 'gj'", { expr = true, noremap = true, silent = true })
map({ 'n', 'v' }, 'k', "v:count ? (v:count > 5 ? 'm' . v:count : '') . 'k' : 'gk'", { expr = true, noremap = true, silent = true })

map({ 'n', 'v' }, '<C-q>', '<C-b>', { noremap = true, silent = true })

map({ 'n', 'v' }, '<S-w>', 'b', { noremap = true, silent = true })

nmap('<leader>.', ':<Up><CR>', { noremap = true, silent = true, desc = 'Repeat Last Ex Command' })

-- Smarter Bracket Insertion
imap('(;', '(<CR>);<Esc>O', { noremap = true, silent = true })
imap('(,', '(<CR>),<Esc>O', { noremap = true, silent = true })
imap('{;', '{<CR>};<Esc>O', { noremap = true, silent = true })
imap('{,', '{<CR>},<Esc>O', { noremap = true, silent = true })
imap('[;', '[<CR>];<Esc>O', { noremap = true, silent = true })
imap('[,', '[<CR>],<Esc>O', { noremap = true, silent = true })
imap('{<CR>', '{<CR>}<Esc>O', { noremap = true, silent = true })

-- Have Navigation Keys always center the cursor with zz
nmap('<C-d>', '<C-d>zz', { noremap = true, silent = true })
nmap('<C-u>', '<C-u>zz', { noremap = true, silent = true })
nmap('<C-f>', '<C-f>zz', { noremap = true, silent = true })
nmap('<C-b>', '<C-b>zz', { noremap = true, silent = true })
nmap('{', '{zz', { noremap = true, silent = true })
nmap('}', '}zz', { noremap = true, silent = true })
nmap('n', 'nzz', { noremap = true, silent = true })
nmap('N', 'Nzz', { noremap = true, silent = true })
nmap('[c', '[czz', { noremap = true, silent = true })
nmap(']c', ']czz', { noremap = true, silent = true })
nmap('[m', '[mzz', { noremap = true, silent = true })
nmap(']m', ']mzz', { noremap = true, silent = true })
nmap('[s', '[szz', { noremap = true, silent = true })
nmap(']s', ']szz', { noremap = true, silent = true })

imap('<C-v>', '<C-r>+', { noremap = true, silent = true })

vim.keymap.set('n', 'J', 'mzJ`z', { noremap = true, silent = true, desc = 'Join line without moving the cursor' })

-- Replace all instances of highlighted words-- nmap( ":", "q:", { noremap = true })
vim.keymap.set('v', '<leader>rv', '"hy:%s/<C-r>h//g<left><left>', { noremap = true, silent = true, desc = 'Replace Highlighted Text' })

-- Search for visually selected text
-- Better to use the <leader>fv keybind from fzf.lua
vim.keymap.set('v', '<leader>v', 'y/<C-r>=escape(@", "/")<CR><CR>', { noremap = true, silent = true, desc = 'Search Visual Selection' })

-- vim: ts=2 sts=2 sw=2 et
