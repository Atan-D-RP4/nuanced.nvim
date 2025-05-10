local gitcore = {
  'tpope/vim-fugitive',
  cmd = { 'Git', 'Gstatus', 'Gblame', 'Gpush', 'Gpull', 'Gcommit', 'Gdiff' },
  keys = {
    { '<leader>gg', '<cmd>Git ++curwin<CR>', desc = '[G]it', mode = 'n' },
    { '<leader>gl', '<cmd>Git ++curwin log<CR>', desc = '[G]it log', mode = 'n' },
    { '<leader>gh', '<cmd>Git ++curwin reflog<CR>', desc = '[G]it log', mode = 'n' },
    { '<leader>gs', '<cmd>Git status -s<CR>', desc = '[G]it log', mode = 'n' },
    { '<leader>gd', '<cmd>Gdiffsplit<CR>', desc = '[G]it [d]iff against index', mode = 'n' },
    { '<leader>gD', '<cmd>Gdiffsplit!<CR>', desc = '[G]it [D]iff against last commit', mode = 'n' },
  },
}

local gitsigns = { -- Adds git related signs to the gutter, as well as utilities for managing changes
  'lewis6991/gitsigns.nvim',
  event = 'VeryLazy',
  ---@type Gitsigns.Config
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

gitsigns.opts = {
  ---@type table<Gitsigns.SignType,Gitsigns.SignConfig>
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
    untracked = { text = '?' },
  },
}

gitsigns.config = function(_, opts)
  require('nuance.core.utils').async_do(100, 0, function()
    require('gitsigns').setup(opts)
  end)
end

gitsigns.opts.on_attach = function(bufnr)
  local signs = require 'gitsigns'

  local map = function(modes, lhs, rhs, opts)
    if opts then
      if type(opts) == 'string' then
        opts = { desc = opts }
      end
      opts.buffer = bufnr
    end
    require('nuance.core.utils').map(modes, lhs, rhs, opts)
  end

  -- Navigation
  map('n', ']c', function()
    if vim.wo.diff then
      vim.cmd.normal { ']c', bang = true }
    else
      signs.nav_hunk 'next'
    end
  end, 'Jump to next git [c]hange')

  map('n', '[c', function()
    if vim.wo.diff then
      vim.cmd.normal { '[c', bang = true }
    else
      signs.nav_hunk 'prev'
    end
  end, 'Jump to previous git [c]hange')

  map({ 'o', 'x' }, 'ih', '<cmd>Gitsigns select_hunk<CR>', 'Select git hunk')

  -- Actions
  -- visual mode
  map('v', '<leader>gs', function()
    signs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
  end, '[G]it stage hunk')
  map('v', '<leader>gr', function()
    signs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
  end, '[G]it rest hunk')

  -- normal mode
  map('n', '<leader>ga', signs.stage_hunk, '[G]it [t]oggle hunk stage status')
  map('n', '<leader>gr', signs.reset_hunk, '[G]it [r]eset hunk')
  map('n', '<leader>gA', signs.stage_buffer, '[G]it [S]tage buffer')
  map('n', '<leader>gR', signs.reset_buffer, '[G]it [R]eset buffer')
  map('n', '<leader>gp', signs.preview_hunk, '[G]it [p]review hunk')
  map('n', '<leader>gb', signs.blame_line, '[G]it [b]lame line')
  -- map('n', '<leader>gD', function()
  --   signs.diffthis '@'
  -- end, 'git [D]iff against last commit')
  -- Toggles
  map('n', '<leader>tb', signs.toggle_current_line_blame, '[T]oggle git show [b]lame line')
  map('n', '<leader>tD', signs.preview_hunk_inline, '[T]oggle git show [D]eleted')
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
  end, '[T]oggle [G]it signs')
end

return {
  gitcore,
  gitsigns,
  -- gitdiffview,
  -- gitworktree,
}
