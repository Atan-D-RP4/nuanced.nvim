local tabline = {
  'echasnovski/mini.tabline',
  event = 'VimEnter',
  config = function()
    require('nuance.core.utils').buftab_setup()
    require('mini.tabline').setup {
      format = function(buf_id, label)
        local tabline = MiniTabline.default_format(buf_id, label)
        local tab_idx_map = vim.g.tab_idx_map
        if tab_idx_map == nil then
          return tabline
        end
        local tab_idx = tab_idx_map[buf_id]
        return tabline .. string.format('[%s]', tab_idx)
      end,
      tabpage_section = 'right',
    }
  end,
}

local transparent = {
  'xiyaowong/nvim-transparent',
  event = 'VimEnter',
  config = true,
  init = function()
    -- Decrease mapped sequence wait time
    -- Displays which-key popup sooner
    vim.o.ttimeout = true
    vim.o.ttimeoutlen = 10
    vim.o.timeout = true
    vim.o.timeoutlen = 500
  end,
}

local markview = {
  'OXY2DEV/markview.nvim',
  ft = { 'markdown', 'typst' },

  keys = {
    {
      '<leader>tm',
      function()
        local markview = require 'markview'
        local msg = 'Markview '
        if not vim.g.markview then
          vim.cmd 'Markview attach'
          msg = msg .. 'enabled'
        else
          vim.cmd 'Markview detach'
          msg = msg .. 'disabled'
        end
        vim.notify(msg, vim.g.markview and vim.log.levels.WARN or vim.log.levels.INFO, { title = 'Markview' })
        vim.g.markview = not vim.g.markview
      end,
      desc = '[T]oggle [M]arkview',
    },
  },

  ---@module 'markview.nvim'
  ---@type mkv.config
  opts = {},

  config = function()
    vim.g.markview = false
    vim.cmd 'Markview Stop'
  end,
}
-- Highlight todo, notes, etc in comments
local todo_comments = {
  'folke/todo-comments.nvim',
  lazy = true,
  event = { 'BufRead' },
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = { signs = false },
}

-- Snacks.nvim also has a notifications module
-- So using that instead
local notify = {
  'echasnovski/mini.notify',
  event = 'VeryLazy',
  config = function()
    require('mini.notify').setup {
      -- By default, all notifications are routed to `mini` view.
      -- Here we change it to `notify` view which is more suitable for
      -- this kind of messages.
      integrations = {
        mini = false,
        notify = true,
        snacks = true,
      },
    }
  end,
}

return {
  tabline,
  transparent,
  markview,
  todo_comments,
  notify,
}
