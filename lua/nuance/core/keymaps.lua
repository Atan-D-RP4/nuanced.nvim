-- [[ Basic Keymaps ]]
--  See `:helpvim.keymap.set()`

local map = require('nuance.core.utils').map
local nmap = require('nuance.core.utils').nmap
local tmap = require('nuance.core.utils').tmap
local imap = require('nuance.core.utils').imap
local vmap = require('nuance.core.utils').vmap

vim.tbl_map(function(maps)
  map(maps[1], maps[2], maps[3], maps[4] or {})
end, {
  -- Better Escape
  { 'n', '<Esc>', '<C-c><C-c>', 'Better Escape' },
  { 'i', '<Esc>', '<Esc><Esc><Right>', 'Better Escape' },

  -- Clear highlights on search when pressing <Esc> in normal mode
  --  See `:help hlsearch`
  { 'n', '<Esc>', '<cmd>nohlsearch<CR>', 'Clear highlights on search' },

  -- Diagnostic keymaps
  { 'n', '<leader>q', vim.diagnostic.setloclist, 'Open diagnostic [Q]uickfix list' },

  -- NOTE: This won't work in all terminal emulators/tmux/etc. Try other mappings
  -- or just use <C-\><C-n> to exit terminal mode
  { 't', '<Esc><Esc>', '<C-\\><C-n>', 'Exit terminal mode' },
  { { 'n', 't' }, '<C-w>t', require('nuance.core.utils').toggleterm, '[T]oggle [T]erminal' },
  { { 'n', 't' }, '<C-w><C-t>', require('nuance.core.utils').toggleterm, '[T]oggle [T]erminal' },

  -- NOTE: Disable arrow keys in normal mode
  { 'n', '<left>', '<cmd>echo "Use h to move!!"<CR>' },
  { 'n', '<right>', '<cmd>echo "Use l to move!!"<CR>' },
  { 'n', '<up>', '<cmd>echo "Use k to move!!"<CR>' },
  { 'n', '<down>', '<cmd>echo "Use j to move!!"<CR>' },

  -- Keybinds to make split navigation easier.
  --  Use CTRL+<hjkl> to switch between windows
  --
  --  See `:help wincmd` for a list of all window commands
  { 'n', '<M-h>', '<C-w><C-h>', 'Move focus to the left window' },
  { 'n', '<M-l>', '<C-w><C-l>', 'Move focus to the right window' },
  { 'n', '<M-j>', '<C-w><C-j>', 'Move focus to the lower window' },
  { 'n', '<M-k>', '<C-w><C-k>', 'Move focus to the upper window' },

  -- Keybinds to resize windows
  { 'n', '<M-S-h>', '<C-w>3<', 'Decrease width of window' },
  { 'n', '<M-S-l>', '<C-w>3>', 'Increase width of window' },
  { 'n', '<M-S-j>', '<C-w>-', 'Decrease height of window' },
  { 'n', '<M-S-k>', '<C-w>+', 'Increase height of window' },

  -- My Keybinds
  { 'i', '<C-U>', '<C-G>u<C-U>' },

  -- Buffer Management
  { 'n', '<leader>dd', ':bdelete! %<CR>', { desc = 'Delete Buffer' } },
  { 'n', '<leader>du', ':update! <CR>', 'Refresh Buffer' },
  { 'n', '<Tab>', ':bnext<CR>', 'Next Buffer' },
  { 'n', '<S-Tab>', ':bprevious<CR>', 'Previous Buffer' },

  -- CTRL+S for Save
  { { 'n', 'v', 'i' }, '<C-S>', '<ESC>:update<CR>', 'Better Save' },

  -- Re-Select Visual Selection on Re-Indent
  { 'v', '<', '<gv', 'Re-Select Visual Selection on Re-Indent' },
  { 'v', '>', '>gv', 'Re-Select Visual Selection on Re-Indent' },

  -- Even Smarter J/K to Line movements
  { { 'n', 'v' }, 'j', "v:count ? (v:count > 5 ? 'm' . v:count : '') . 'j' : 'gj'", { expr = true, desc = 'Smarter J to Line movements' } },
  { { 'n', 'v' }, 'k', "v:count ? (v:count > 5 ? 'm' . v:count : '') . 'k' : 'gk'", { expr = true, desc = 'Smarter K to Line movements' } },

  { { 'n', 'v' }, '<C-q>', '<C-u>' },

  { { 'n', 'v' }, '<S-w>', 'b' },

  { 'n', '<leader>.', ':<Up><CR>', 'Repeat Last Ex Command' },

  -- Smarter Bracket Insertion
  { 'i', '(;', '(<CR>);<Esc>O' },
  { 'i', '(,', '(<CR>),<Esc>O' },
  { 'i', '{;', '{<CR>};<Esc>O' },
  { 'i', '{,', '{<CR>},<Esc>O' },
  { 'i', '[;', '[<CR>];<Esc>O' },
  { 'i', '[,', '[<CR>],<Esc>O' },
  { 'i', '{<CR>', '{<CR>}<Esc>O' },

  -- Have Navigation Keys always center the cursor with zz
  { 'n', '<C-d>', '<C-d>zz' },
  { 'n', '<C-u>', '<C-u>zz' },
  { 'n', '<C-f>', '<C-f>zz' },
  { 'n', '<C-b>', '<C-b>zz' },
  { 'n', '{', '{zz' },
  { 'n', '}', '}zz' },
  { 'n', 'n', 'nzz' },
  { 'n', 'N', 'Nzz' },
  { 'n', '[c', '[czz' },
  { 'n', ']c', ']czz' },
  { 'n', '[m', '[mzz' },
  { 'n', ']m', ']mzz' },
  { 'n', '[s', '[szz' },
  { 'n', ']s', ']szz' },

  -- { 'i', '<C-v>', '<C-r>+', {} },

  { 'n', 'J', 'mzJ`z', 'Join line without moving the cursor' },

  { 'v', 'K', ":m '<-2<CR>gv=gv", 'Move selected lines up' },
  { 'v', 'J', ":m '>+1<CR>gv=gv", 'Move selected lines down' },

  -- nmap('<leader>gwr', ':%s/\\<<C-r><C-w>\\>//g<Left><Left>', '[G]lobal Current [W]ord [R]eplace')
  -- nmap('<leader>gsr', ':%s//g<left><left>', '[G]lobal [S]earch and [R]eplace')
  --
  -- Search for visually selected text
  -- Better to use the <leader>fv keybind from fzf.lua
  { 'v', '<leader>vr', '"hy:%s/<C-r>h//g<left><left>', '[R]eplace [V]isual selection' },
  { 'v', '<leader>vs', 'y/<C-r>=escape(@", "/")<CR><CR>', 'Search Visual Selection' },

  -- map('x', '<leader>P', '"_dP', 'Paste without yanking')

  { 'n', '-', 'g$', 'Move to the first non-blank character of the line' },
})

vim.tbl_map(
  function(keys)
    nmap(keys.cmd, keys.callback, keys.desc)
  end,
  vim.tbl_map(function(i)
    return {
      desc = string.format('Jump to buffer %d', i),
      cmd = string.format('<leader>e%d', i),
      callback = function()
        local cmd = 'ls'
        local bufs_out = vim.api.nvim_exec2(cmd, { output = true }).output
        local bufs = vim.split(bufs_out, '\n', { trimempty = true })
        local items = vim.tbl_map(function(s)
          local o = {
            id = 0,
            name = '',
            classifiers = '     ', -- see :help ls for more info
          }
          o = setmetatable({}, o)

          o.id = tonumber(vim.split(s, ' ', { trimempty = true })[1])
          o.classifiers = s:sub(4, 8)

          local ss = s:find '"'
          local se = #s - s:reverse():find '"'

          o.name = s:sub(ss + 1, se)

          return o
        end, bufs)

        if i > #items or i == 0 then
          vim.notify('Buffer index out of range', vim.log.levels.ERROR)
          return
        end

        -- Jump to the nth buffer
        vim.api.nvim_set_current_buf(items[i].id)
      end,
    }
  end, { 1, 2, 3, 4, 5, 6, 7, 8, 9 })
)

-- vim: ts=2 sts=2 sw=2 et
