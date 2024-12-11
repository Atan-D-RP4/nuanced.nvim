-- [[ Basic Keymaps ]]
--  See `:helpvim.keymap.set()`

local map = require('core.utils').map
local nmap = require('core.utils').nmap
local tmap = require('core.utils').tmap
local imap = require('core.utils').imap
local vmap = require('core.utils').vmap

-- Better Escape
nmap('<Esc>', '<C-c><C-c>')
imap('<Esc>', '<Esc><Esc><Right>', { desc = 'Better Escape' })
-- Clear highlights on search when pressing <Esc> in normal mode

--  See `:help hlsearch`
nmap('<Esc>', '<cmd>nohlsearch<CR>', 'Clear highlights on search')

-- Diagnostic keymaps
nmap('<leader>q', vim.diagnostic.setloclist, 'Open diagnostic [Q]uickfix list')

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
tmap('<Esc><Esc>', '<C-\\><C-n>', 'Exit terminal mode')

-- NOTE: Disable arrow keys in normal mode
nmap('<left>', '<cmd>echo "Use h to move!!"<CR>')
nmap('<right>', '<cmd>echo "Use l to move!!"<CR>')
nmap('<up>', '<cmd>echo "Use k to move!!"<CR>')
nmap('<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
nmap('<C-h>', '<C-w><C-h>', 'Move focus to the left window')
nmap('<C-l>', '<C-w><C-l>', 'Move focus to the right window')
nmap('<C-j>', '<C-w><C-j>', 'Move focus to the lower window')
nmap('<C-k>', '<C-w><C-k>', 'Move focus to the upper window')

-- My Keybinds
imap('<C-U>', '<C-G>u<C-U>')
nmap("<leader>'", ':terminal<CR>', 'Open Terminal Buffer')

-- Buffer Management
-- nmap('<leader>dd', ':bdelete! %<CR>', {  desc = 'Delete Buffer' })
nmap('<leader>du', ':update! <CR>', 'Refresh Buffer')
nmap('<Tab>', ':bnext<CR>', 'Next Buffer')
nmap('<S-Tab>', ':bprevious<CR>', 'Previous Buffer')

-- CTRL+S for Save
map({ 'n', 'v', 'i' }, '<C-S>', '<ESC>:update<CR>', 'Better Save')

-- Re-Select Visual Selection on Re-Indent
vmap('<', '<gv', 'Re-Select Visual Selection on Re-Indent')
vmap('>', '>gv', 'Re-Select Visual Selection on Re-Indent')

-- Even Smarter J/K to Line movements
map({ 'n', 'v' }, 'j', "v:count ? (v:count > 5 ? 'm' . v:count : '') . 'j' : 'gj'", { expr = true, desc = 'Smarter J to Line movements' })
map({ 'n', 'v' }, 'k', "v:count ? (v:count > 5 ? 'm' . v:count : '') . 'k' : 'gk'", { expr = true, desc = 'Smarter K to Line movements' })

map({ 'n', 'v' }, '<C-q>', '<C-b>')

map({ 'n', 'v' }, '<S-w>', 'b')

nmap('<leader>.', ':<Up><CR>', 'Repeat Last Ex Command')

-- Smarter Bracket Insertion
imap('(;', '(<CR>);<Esc>O')
imap('(,', '(<CR>),<Esc>O')
imap('{;', '{<CR>};<Esc>O')
imap('{,', '{<CR>},<Esc>O')
imap('[;', '[<CR>];<Esc>O')
imap('[,', '[<CR>],<Esc>O')
imap('{<CR>', '{<CR>}<Esc>O')

-- Have Navigation Keys always center the cursor with zz
nmap('<C-d>', '<C-d>zz')
nmap('<C-u>', '<C-u>zz')
nmap('<C-f>', '<C-f>zz')
nmap('<C-b>', '<C-b>zz')

-- Continuation
nmap('{', '{zz')
nmap('}', '}zz')

-- Continuation
nmap('n', 'nzz')
nmap('N', 'Nzz')

-- Continuation
nmap('[c', '[czz')
nmap(']c', ']czz')
nmap('[m', '[mzz')
nmap(']m', ']mzz')
nmap('[s', '[szz')
nmap(']s', ']szz')

imap('<C-v>', '<C-r>+', {})

nmap('J', 'mzJ`z', 'Join line without moving the cursor')

vmap('K', ":m '<-2<CR>gv=gv", 'Move selected lines up')
vmap('J', ":m '>+1<CR>gv=gv", 'Move selected lines down')

-- nmap('<leader>gwr', ':%s/\\<<C-r><C-w>\\>//g<Left><Left>', '[G]lobal Current [W]ord [R]eplace')
-- nmap('<leader>gsr', ':%s//g<left><left>', '[G]lobal [S]earch and [R]eplace')
--
-- Search for visually selected text
-- Better to use the <leader>fv keybind from fzf.lua
vmap('<leader>vr', '"hy:%s/<C-r>h//g<left><left>', '[R]eplace [V]isual selection')
vmap('<leader>vs', 'y/<C-r>=escape(@", "/")<CR><CR>', 'Search Visual Selection')

-- map('x', '<leader>P', '"_dP', 'Paste without yanking')

nmap('-', '^', 'Move to the first non-blank character of the line')

-- vim: ts=2 sts=2 sw=2 et
