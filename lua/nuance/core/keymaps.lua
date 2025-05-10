-- [[ Basic Keymaps ]]

vim.g.mapleader = '\r'
vim.g.maplocalleader = '\r'

local maps = {
  -- Treesitter-based '%' motion
  -- {
  --   { 'n', 'x' },
  --   '%',
  --   function()
  --     local node_on_cursor = vim.treesitter.get_node()
  --     if node_on_cursor == nil then vim.cmd 'execute "normal! %"' return end
  --     local s_row, s_col, _, e_row, e_col, _ = unpack(vim.treesitter.get_range(node_on_cursor))
  --     local start_line = s_row + 1
  --     local start_col = s_col
  --     local end_line = e_row + 1
  --     local end_col = e_col - 1
  --
  --     local curr_line, curr_col = unpack(vim.api.nvim_win_get_cursor(0))
  --
  --     -- Determine if cursor is at either boundary
  --     local at_start = curr_line == start_line and curr_col == start_col
  --     local at_end = curr_line == end_line and curr_col == end_col
  --
  --     -- Jump to opposite boundary
  --     if at_start then
  --       vim.api.nvim_win_set_cursor(0, { end_line, end_col })
  --     elseif at_end then
  --       vim.api.nvim_win_set_cursor(0, { start_line, s_col })
  --     else
  --       -- Default to jumping to start if not at either boundary
  --       vim.api.nvim_win_set_cursor(0, { start_line, s_col })
  --     end
  --   end,
  --   'Treesitter % Motion',
  -- },

  {
    { 'n', 'i' },
    '<C-j>',
    function()
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      line = line - 1
      local node = vim.treesitter.get_node()
      if node ~= nil then
        local row
        row, col = node:end_()
        vim.api.nvim_win_set_cursor(0, { row + 1, col })
      end
    end,
    'Treesitter Jump to Node-End',
  },

  {
    { 'n', 'i' },
    '<C-k>',
    function()
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      line = line + 1
      local node = vim.treesitter.get_node()
      if node ~= nil then
        local row
        row, col = node:start()
        vim.api.nvim_win_set_cursor(0, { row, col })
      end
    end,
    'Treesitter Jump to Node-Start',
  },

  -- {
  --   { 'n', 't' },
  --   '<C-t>',
  --   (function()
  --     vim.cmd 'autocmd TermOpen * startinsert'
  --     local buf, win = nil, nil
  --     local was_insert = false
  --     local cfg = function()
  --       return {
  --         relative = 'editor',
  --         width = math.floor(vim.o.columns * 0.8),
  --         height = math.floor(vim.o.lines * 0.8),
  --         row = math.floor((vim.o.lines * 0.2) / 2),
  --         col = math.floor(vim.o.columns * 0.1),
  --         style = 'minimal',
  --         border = 'single',
  --       }
  --     end
  --     local function toggle()
  --       buf = (buf and vim.api.nvim_buf_is_valid(buf)) and buf or nil
  --       win = (win and vim.api.nvim_win_is_valid(win)) and win or nil
  --       if not buf and not win then
  --         vim.cmd 'split | terminal'
  --         buf = vim.api.nvim_get_current_buf()
  --         vim.api.nvim_win_close(vim.api.nvim_get_current_win(), true)
  --         win = vim.api.nvim_open_win(buf, true, cfg())
  --       elseif not win and buf then
  --         win = vim.api.nvim_open_win(buf, true, cfg())
  --       elseif win then
  --         was_insert = vim.api.nvim_get_mode().mode == 't'
  --         return vim.api.nvim_win_close(win, true)
  --       end
  --       if was_insert then
  --         vim.cmd 'startinsert'
  --       end
  --     end
  --     return toggle
  --   end)(),
  --   'Toggle float terminal',
  -- },

  {
    'n',
    '<C-a>',
    function()
      require('nuance.core.lsp_dial').lsp_dial(true)
    end,
    { noremap = true },
  },

  {
    'n',
    '<C-x>',
    function()
      require('nuance.core.lsp_dial').lsp_dial(false)
    end,
    { noremap = true },
  },

  { 'x', '/', '<Esc>/\\%V', 'Search in Visual Selection' },

  -- NOTE: This won't work in all terminal emulators/tmux/etc. Try other mappings
  -- or just use <C-\><C-n> to exit terminal mode
  { 't', '<C-w>q', '<C-\\><C-n>', 'Exit terminal mode' },
  { 't', '<C-w><C-q>', '<C-\\><C-n>', 'Exit terminal mode' },
  { 't', '<M-r>', [['<C-\><C-N>"'.nr2char(getchar()).'pi']], { desc = 'Vim Register Select in Terminal Mode', expr = true } },

  -- Better Escape
  { 'n', '<Esc>', '<C-c><C-c>', 'Better Escape' },
  { 'i', '<Esc>', '<Esc><Esc>', 'Better Escape' },

  { 'n', '<C-I>', '<C-I>' },

  -- Clear highlights on search when pressing <Esc> in normal mode
  { 'n', '<Esc>', '<cmd>nohlsearch<CR>', 'Clear highlights on search' },

  -- Diagnostic keymaps
  { 'n', '<leader>q', vim.diagnostic.setloclist, 'Open diagnostic [Q]uickfix list' },

  -- Custom Floating Togglable Terminal
  -- { { 'n', 't' }, '<C-w>t', require('nuance.core.utils').toggleterm, '[T]oggle [T]erminal' },
  -- { { 'n', 't' }, '<C-w><C-t>', require('nuance.core.utils').toggleterm, '[T]oggle [T]erminal' },

  -- NOTE: Disable arrow keys in normal mode

  { 'n', '<up>', '<cmd>execute "normal! k" | lua vim.notify("Tip: Use j to move down", vim.log.levels.INFO)<CR>' },
  { 'n', '<down>', '<cmd>execute "normal! j" | lua vim.notify("Tip: Use k to move up", vim.log.levels.INFO)<CR>' },
  { 'n', '<left>', '<cmd>execute "normal! h" | lua vim.notify("Tip: Use l to move right", vim.log.levels.INFO)<CR>' },
  { 'n', '<right>', '<cmd>execute "normal! l" | lua vim.notify("Tip: Use h to move left", vim.log.levels.INFO)<CR>' },

  { 'n', '<M-h>', '<C-w><C-h>', 'Move focus to the left window' },
  { 'n', '<M-l>', '<C-w><C-l>', 'Move focus to the right window' },
  { 'n', '<M-j>', '<C-w><C-j>', 'Move focus to the lower window' },
  { 'n', '<M-k>', '<C-w><C-k>', 'Move focus to the upper window' },

  -- My Keybinds
  { 'i', '<C-U>', '<C-G>u<C-U>' },

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

  { 'n', '<leader>:', ':<Up><CR>', 'Repeat Last Ex Command' },

  -- Smarter Bracket Insertion
  { 'i', '(;', '(<CR>);<Esc>O' },
  { 'i', '(,', '(<CR>),<Esc>O' },
  { 'i', '{;', '{<CR>};<Esc>O' },
  { 'i', '{,', '{<CR>},<Esc>O' },
  { 'i', '[;', '[<CR>];<Esc>O' },
  { 'i', '[,', '[<CR>],<Esc>O' },
  { 'i', '{<CR>', '{<CR>}<Esc>O' },

  -- { 'i', '<C-v>', '<C-r>+', {} },
  { { 'n', 'v' }, '<C-q>', '<C-u>' },

  {
    'n',
    'J',
    function()
      ---@diagnostic disable-next-line: unused-local, unused-function
      _G.operatorJ = function(mode)
        vim.cmd [[ exec "'[,']join" ]]
      end
      vim.o.operatorfunc = 'v:lua.operatorJ'
      return 'g@'
    end,
    { expr = true, silent = true, desc = 'Join Operator' },
  },

  { 'o', 'J', 'j', { desc = 'Join Operator', silent = true } },

  -- { 'n', 'J', 'mzJ`z', 'Join line without moving the cursor' },

  -- { 'v', 'K', ":m '<-2<CR>gv=gv", 'Move selected lines up' },
  -- { 'v', 'J', ":m '>+1<CR>gv=gv", 'Move selected lines down' },

  -- nmap('<leader>gwr', ':%s/\\<<C-r><C-w>\\>//g<Left><Left>', '[G]lobal Current [W]ord [R]eplace')
  -- nmap('<leader>gsr', ':%s//g<left><left>', '[G]lobal [S]earch and [R]eplace')

  -- Search for visually selected text
  -- Better to use the <leader>fv keybind from fzf.lua
  -- { 'v', '<leader>vr', '"hy:%s/<C-r>h//g<left><left>', '[R]eplace [V]isual selection' },
  -- { 'v', '<leader>vs', 'y/<C-r>=escape(@", "/")<CR><CR>', 'Search Visual Selection' },

  -- map('x', '<leader>P', '"_dP', 'Paste without yanking')

  { { 'n', 'v' }, '-', 'g$', 'Move to the first non-blank character of the line' },

  -- Buffer Management
  -- { 'n', '<leader>ed', ':bdelete! %<CR>', { desc = 'Delete Buffer' } },
  { 'n', '<leader>en', '<cmd>enew<CR>', 'New Buffer' },
  { 'n', '<leader>eu', ':update! <CR>', 'Refresh Buffer' },

  {
    'n',
    '<leader>ed',
    function()
      local has_snacks, snacks = pcall(require, 'snacks')
      if has_snacks then
        snacks.bufdelete()
      else
        local bufnr = vim.api.nvim_get_current_buf()
        if vim.api.nvim_buf_is_valid(bufnr) then
          vim.api.nvim_buf_delete(bufnr, { force = true })
        end
      end
    end,
    'Delete Buffer',
  },

  {
    'n',
    '<leader>eD',
    function()
      local has_snacks, snacks = pcall(require, 'snacks')
      if has_snacks then
        snacks.bufdelete.all()
      else
        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(bufnr) then
            vim.api.nvim_buf_delete(bufnr, { force = true })
          end
        end
      end
    end,
    'Delete All Buffers',
  },

  {
    'n',
    'p',
    function()
      local row, col = unpack(vim.api.nvim_win_get_cursor(0))
      vim.cmd 'normal! ]p'
      local new_row = vim.api.nvim_win_get_cursor(0)[1]
      if not (new_row == row) then
        vim.api.nvim_win_set_cursor(0, { new_row, col })
      end
    end,
    'Better Paste Action',
  },
  {
    'n',
    'P',
    function()
      local row, col = unpack(vim.api.nvim_win_get_cursor(0))
      vim.cmd 'normal! [p'
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

  { { 'n', 'i' }, '<M-a>', '<cmd>%y<CR>', 'Select All' },
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
        local ok_list, bufs = pcall(vim.api.nvim_list_bufs)
        if not ok_list then
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
          local ok_set, err = pcall(vim.api.nvim_set_current_buf, target_buf)
          if not ok_set then
            vim.notify('Failed to switch buffer: ' .. err, vim.log.levels.ERROR)
          end
        end
      end,
    }
  end, { 1, 2, 3, 4, 5, 6, 7, 8, 9 })
)

vim.tbl_map(function(map)
  require('nuance.core.utils').map(map[1], '<C-w>' .. map[2], function()
    vim.api.nvim_command('wincmd ' .. map[2])
    vim.api.nvim_input '<C-W>'
  end or '', map[3] or {})
end, {
  { 'n', 'j', 'Window: Go down' },
  { 'n', 'k', 'Window: Go up' },
  { 'n', 'h', 'Window: Go left' },
  { 'n', 'l', 'Window: Go right' },

  { 'n', 'w', 'Window: Go to previous' },
  { 'n', 's', 'Window: Split horizontal' },
  { 'n', 'v', 'Window: Split vertical' },

  { 'n', 'q', 'Window: Delete' },
  { 'n', 'o', 'Window: Only (close rest)' },

  { 'n', '_', 'Window: Maximize Height' },
  { 'n', '|', 'Window: Maximize Width' },
  { 'n', '=', 'Window: Equalize' },

  -- move
  { 'n', 'K', 'Window: Move to top' },
  { 'n', 'J', 'Window: Move to bottom' },
  { 'n', 'H', 'Window: Move to left' },
  { 'n', 'L', 'Window: Move to right' },
})

vim.tbl_map(function(map)
  require('nuance.core.utils').map(map[1], '<C-w>' .. map[2][1], function()
    local saved_cmdheight = vim.o.cmdheight
    vim.api.nvim_command(map[2][2])
    vim.o.cmdheight = saved_cmdheight
    vim.api.nvim_input '<C-w>'
  end, map[4] or {})
end, {
  { 'n', { '+', 'resize +5' }, 'Window: Grow vertical' },
  { 'n', { '-', 'resize -5' }, 'Window: Shrink vertical' },
  { 'n', { '<', 'vertical resize +5' }, 'Window: Shrink horizontal' },
  { 'n', { '>', 'vertical resize -5' }, 'Window: Grow horizontal' },
})

-- vim: ts=2 sts=2 sw=2 et
