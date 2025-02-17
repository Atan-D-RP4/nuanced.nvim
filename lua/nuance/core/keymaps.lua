-- [[ Basic Keymaps ]]
--  See `:helpvim.keymap.set()`

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
--
-- vim.g.mapleader = ' '
vim.g.mapleader = '\r'
vim.g.maplocalleader = ' '

local maps = {
  -- Better Escape
  { 'n', '<Esc>', '<C-c><C-c>', 'Better Escape' },
  { 'i', '<Esc>', '<Esc><Esc>', 'Better Escape' },

  -- Clear highlights on search when pressing <Esc> in normal mode
  --  See `:help hlsearch`
  { 'n', '<Esc>', '<cmd>nohlsearch<CR>', 'Clear highlights on search' },

  -- Diagnostic keymaps
  { 'n', '<leader>q', vim.diagnostic.setloclist, 'Open diagnostic [Q]uickfix list' },

  -- NOTE: This won't work in all terminal emulators/tmux/etc. Try other mappings
  -- or just use <C-\><C-n> to exit terminal mode
  { 't', '<Esc><Esc>', '<C-\\><C-n>', 'Exit terminal mode' },
  { 't', '<M-r>', [['<C-\><C-N>"'.nr2char(getchar()).'pi']], { desc = 'Vim Register Select in Terminal Mode', expr = true } },

  -- { { 'n', 't' }, '<C-w>t', require('nuance.core.utils').toggleterm, '[T]oggle [T]erminal' },
  -- { { 'n', 't' }, '<C-w><C-t>', require('nuance.core.utils').toggleterm, '[T]oggle [T]erminal' },

  -- NOTE: Disable arrow keys in normal mode
  --  See `:help nvim-tui-typing`
  { 'n', '<up>', '<cmd>execute "normal! k" | lua vim.notify("Tip: Use j to move down", vim.log.levels.INFO)<CR>' },
  { 'n', '<down>', '<cmd>execute "normal! j" | lua vim.notify("Tip: Use k to move up", vim.log.levels.INFO)<CR>' },
  { 'n', '<left>', '<cmd>execute "normal! h" | lua vim.notify("Tip: Use l to move right", vim.log.levels.INFO)<CR>' },
  { 'n', '<right>', '<cmd>execute "normal! l" | lua vim.notify("Tip: Use h to move left", vim.log.levels.INFO)<CR>' },

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
  -- { 'n', '<leader>dd', ':bdelete! %<CR>', { desc = 'Delete Buffer' } },
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

  { 'n', '<leader>:', ':<Up><CR>', 'Repeat Last Ex Command' },

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

  { { 'n', 'v' }, '-', 'g$', 'Move to the first non-blank character of the line' },

  {
    'n',
    'p',
    function()
      local row, col = unpack(vim.api.nvim_win_get_cursor(0))
      vim.cmd 'normal! p'
      local new_row = vim.api.nvim_win_get_cursor(0)[1]
      if not (new_row == row) then
        vim.api.nvim_win_set_cursor(0, { new_row, col })
      end
    end,
    'Better Paste Action',
  },
  {
    { 'n', 'x' },
    'y',
    function()
      vim.g.cur_yank_pre = vim.api.nvim_win_get_cursor(0)
      vim.api.nvim_feedkeys('y', 'n', true)
    end,
    { desc = 'Set Cursor Pos and Yank', expr = true },
  },
}

vim.tbl_map(function(map)
  require('nuance.core.utils').map(map[1], map[2], map[3] or '', map[4] or {})
end, maps)

vim.tbl_map(
  function(keys)
    require('nuance.core.utils').nmap(keys.cmd, keys.callback, keys.desc)
  end,
  vim.tbl_map(function(index)
    return {
      desc = string.format('Jump to buffer %d', index),
      cmd = string.format('<leader>e%d', index),
      callback = function()
        local ok, bufs = pcall(vim.api.nvim_list_bufs)
        if not ok then
          vim.notify('Failed to list buffers', vim.log.levels.ERROR)
          return
        end

        local valid_bufs = vim.tbl_filter(function(buf)
          return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted
        end, bufs)

        if index > #valid_bufs then
          vim.notify('Buffer index out of range', vim.log.levels.WARN)
          return
        end

        local target_buf = valid_bufs[index]
        if target_buf then
          local ok, err = pcall(vim.api.nvim_set_current_buf, target_buf)
          if not ok then
            vim.notify('Failed to switch buffer: ' .. err, vim.log.levels.ERROR)
          end
        end
      end,
    }
  end, { 1, 2, 3, 4, 5, 6, 7, 8, 9 })
)

vim.tbl_map(function(map)
  local lhs = '<C-w>' .. map[2]
  local rhs = function()
    vim.api.nvim_command('wincmd ' .. map[2])
    vim.api.nvim_input '<C-W>'
  end
  require('nuance.core.utils').map(map[1], lhs, rhs or '', map[3] or {})
end, {
  { 'n', 'w', 'Window: Go to previous' },
  { 'n', 'j', 'Window: Go down' },
  { 'n', 'k', 'Window: Go up' },
  { 'n', 'h', 'Window: Go left' },
  { 'n', 'l', 'Window: Go right' },
  { 'n', 's', 'Window: Split horizontal' },
  { 'n', 'v', 'Window: Split vertical' },
  { 'n', 'q', 'Window: Delete' },
  { 'n', 'o', 'Window: Only (close rest)' },
  { 'n', '=', 'Balance windows' },
  -- move
  { 'n', 'K', 'Window: Move to top' },
  { 'n', 'J', 'Window: Move to bottom' },
  { 'n', 'H', 'Window: Move to left' },
  { 'n', 'L', 'Window: Move to right' },
})

vim.tbl_map(function(map)
  local lhs = '<C-w>' .. map[2]
  local rhs = function()
    local saved_cmdheight = vim.o.cmdheight

    if map[2] == '+' then
      vim.api.nvim_command 'resize +5'
    elseif map[2] == '-' then
      vim.api.nvim_command 'resize -5'
    elseif map[2] == '<' then
      vim.api.nvim_command 'vertical resize -5'
    elseif map[2] == '>' then
      vim.api.nvim_command 'vertical resize +5'
    end

    vim.o.cmdheight = saved_cmdheight
    vim.api.nvim_input '<C-w>'
  end
  require('nuance.core.utils').map(map[1], lhs, rhs, map[4] or {})
end, {
  { 'n', '+', 'Window: Grow vertical' },
  { 'n', '-', 'Window: Shrink vertical' },
  { 'n', '<', 'Window: Shrink horizontal' },
  { 'n', '>', 'Window: Grow horizontal' },
})

-- vim: ts=2 sts=2 sw=2 et
