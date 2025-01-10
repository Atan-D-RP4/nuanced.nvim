local gitcore = {
  'tpope/vim-fugitive',
  cmd = { 'Git', 'Gstatus', 'Gblame', 'Gpush', 'Gpull', 'Gcommit', 'Gdiff' },
  keys = {
    { '<leader>gg', '<cmd>Git<CR>', desc = '[G]it', mode = 'n' },
  },
}

local gitsigns = { -- Adds git related signs to the gutter, as well as utilities for managing changes
  'lewis6991/gitsigns.nvim',
  opts = {},
}

local gitdiffview = {
  'sindrets/diffview.nvim',
  enabled = false,
  cmd = 'DiffviewOpen',
  opts = {
    use_icons = false, -- Requires nvim-web-devicons
  },
}

-- TODO: Implement integration with fzf-lua
local gitworktree = {
  'ThePrimeagen/git-worktree.nvim',
  event = 'VeryLazy',

  dependencies = {
    'nvim-lua/plenary.nvim',
    -- 'ibhagwan/fzf-lua',
  },
}

local M = {
  gitcore,
  gitsigns,
  -- gitdiffview,
  -- gitworktree,
}

gitsigns.signs = {
  add = { text = '+' },
  change = { text = '~' },
  delete = { text = '_' },
  topdelete = { text = '‾' },
  changedelete = { text = '~' },
}

gitsigns.opts.on_attach = function(bufnr)
  local signs = require 'gitsigns'

  local function map(mode, l, r, opts)
    opts = opts or {}
    opts.buffer = bufnr
    vim.keymap.set(mode, l, r, opts)
  end

  -- Navigation
  map('n', ']c', function()
    if vim.wo.diff then
      vim.cmd.normal { ']c', bang = true }
    else
      signs.nav_hunk 'next'
    end
  end, { desc = 'Jump to next git [c]hange' })

  map('n', '[c', function()
    if vim.wo.diff then
      vim.cmd.normal { '[c', bang = true }
    else
      signs.nav_hunk 'prev'
    end
  end, { desc = 'Jump to previous git [c]hange' })

  -- Actions
  -- visual mode
  map('v', 'gs', function()
    signs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
  end, { desc = 'stage git hunk' })
  map('v', 'gr', function()
    signs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
  end, { desc = 'reset git hunk' })
  -- normal mode
  map('n', '<leader>ga', signs.stage_hunk, { desc = '[G]it [a]dd hunk' })
  map('n', '<leader>gr', signs.reset_hunk, { desc = '[G]it [r]eset hunk' })
  map('n', '<leader>gS', signs.stage_buffer, { desc = '[G]it [S]tage buffer' })
  map('n', '<leader>gu', signs.undo_stage_hunk, { desc = '[G]it [u]ndo stage hunk' })
  map('n', '<leader>gR', signs.reset_buffer, { desc = '[G]it [R]eset buffer' })
  map('n', '<leader>gp', signs.preview_hunk, { desc = '[G]it [p]review hunk' })
  map('n', '<leader>gb', signs.blame_line, { desc = '[G]it [b]lame line' })
  map('n', '<leader>gd', signs.diffthis, { desc = '[G]it [d]iff against index' })
  map('n', '<leader>gD', function()
    signs.diffthis '@'
  end, { desc = 'git [D]iff against last commit' })
  -- Toggles
  map('n', '<leader>tb', signs.toggle_current_line_blame, { desc = '[T]oggle git show [b]lame line' })
  map('n', '<leader>tD', signs.toggle_deleted, { desc = '[T]oggle git show [D]eleted' })
  local state = 1
  map('n', '<leader>tg', function()
    if state == 1 then
      vim.notify('Git signs disabled', vim.log.levels.WARN, { title = 'Gitsigns' })
      state = 0
    else
      vim.notify('Git signs enabled', vim.log.levels.INFO, { title = 'Gitsigns' })
      state = 1
    end
    signs.toggle_signs()
  end, { desc = '[T]oggle [g]it signs' })
end

return M
