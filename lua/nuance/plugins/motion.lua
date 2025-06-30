local surround = {
  'echasnovski/mini.surround',
  event = { 'BufEnter', 'BufRead', 'BufNewFile' },

  opts = {
    mappings = {
      add = '<leader>sa', -- Add surrounding in Normal and Visual modes
      delete = '<leader>sd', -- Delete surrounding
      find = '<leader>sf', -- Find surrounding (to the right)
      find_left = '<leader>sF', -- Find surrounding (to the left)
      highlight = '<leader>sh', -- Highlight surrounding
      replace = '<leader>sr', -- Replace surrounding
      update_n_lines = '<leader>sn', -- Update `n_lines`
    },
  },
}

local ai = {
  -- Better Around/Inside textobjects
  'echasnovski/mini.ai',
  lazy = true,
  event = { 'BufRead', 'BufNewFile' },
  branch = 'main',

  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    {
      'nvim-treesitter/nvim-treesitter-textobjects',
      branch = 'main',
      opts = { select = { lookahead = true } },
    },
  },

  config = function()
    require('mini.ai').setup {
      mappings = {
        -- Move cursor to corresponding edge of `a` textobject
        goto_left = '<leader>[',
        goto_right = '<leader>]',
      },

      -- Number of lines within which textobject is searched
      n_lines = 300,

      -- How to search for object (first inside current line, then inside
      -- neighborhood). One of 'cover', 'cover_or_next', 'cover_or_prev',
      -- 'cover_or_nearest', 'next', 'prev', 'nearest'.
      search_method = 'cover_or_next',

      -- Whether to disable showing non-error feedback
      -- This also affects (purely informational) helper messages shown after
      -- idle time if user input is required.
      silent = false,
      custom_textobjects = {
        g = function()
          local from = { line = 1, col = 1 }
          local to = {
            line = vim.fn.line '$',
            col = math.max(vim.fn.getline('$'):len(), 1),
          }
          return { from = from, to = to }
        end,
        o = require('mini.ai').gen_spec.treesitter { -- code block
          a = { '@block.outer', '@conditional.outer', '@loop.outer' },
          i = { '@block.inner', '@conditional.inner', '@loop.inner' },
        },
        f = require('mini.ai').gen_spec.treesitter { a = '@function.outer', i = '@function.inner' }, -- function
        c = require('mini.ai').gen_spec.treesitter { a = '@class.outer', i = '@class.inner' }, -- class
        t = { '<([%p%w]-)%f[^<%w][^<>]->.-</%1>', '^<.->().*()</[^/]->$' }, -- tags
        d = { '%f[%d]%d+' }, -- digits
        e = { -- Word with case
          { '%u[%l%d]+%f[^%l%d]', '%f[%S][%l%d]+%f[^%l%d]', '%f[%P][%l%d]+%f[^%l%d]', '^[%l%d]+%f[^%l%d]' },
          '^().*()$',
        },
        u = require('mini.ai').gen_spec.function_call(), -- u for "Usage"
        U = require('mini.ai').gen_spec.function_call { name_pattern = '[%w_]' }, -- without dot in function name
      },
    }
  end,
}

local spider = {
  'chrisgrieser/nvim-spider',
  lazy = true,
  keys = vim.tbl_map(function(key)
    local cmd = "<cmd>lua require('spider').motion('%s')<CR>"
    return {
      key,
      cmd:format(key),
      mode = { 'n', 'o', 'x' },
      desc = ('Spider %s Motion'):format(key),
    }
  end, { 'w', 'e', 'b' }),
}

local flash = {
  'folke/flash.nvim',
  keys = {
    'f',
    'F',
    't',
    'T',
    ';',
    ',',
    { '<M-f>', '<cmd>lua require("flash").jump()<CR>', mode = { 'n', 'x', 'o' }, desc = 'Flash' },
    { '<M-F>', '<cmd>lua require("flash").treesitter()<CR>', mode = { 'n', 'x', 'o' }, desc = 'Flash Treesitter' },
    { 'r', '<cmd>lua require("flash").remote()<CR>', mode = 'o', desc = 'Remote Flash' },
    { 'R', '<cmd>lua require("flash").treesitter_search()<CR>', mode = { 'o', 'x' }, desc = 'Treesitter Search' },
    { '<c-s>', '<cmd>lua require("flash").toggle()<CR>', mode = { 'c' }, desc = 'Toggle Flash Search in "/" mode' },
  },

  ---@type Flash.Config
  opts = {
    -- labels = 'asdfghjklqwertyuiopzxcvbnm',
    labels = 'dgqftyuzxcvnm1234567890',
    search = { mode = 'search' },
    modes = { char = { jump_labels = true } },
    label = { rainbow = { enabled = true } },
  },
}

local matchup = {
  'andymass/vim-matchup',
  event = 'BufRead',
  config = function()
    vim.g.matchup_matchparen_offscreen = { method = 'popup' }
    require('nvim-treesitter.configs').setup {
      matchup = {
        enable = true, -- mandatory, false will disable the whole extension
        disable = { 'c', 'ruby' }, -- optional, list of language that will be disabled
      },
    }
  end,
}

local operator = {
  'echasnovski/mini.operators',
  lazy = true,
  event = { 'BufRead', 'BufNewFile' },
  config = function()
    -- Set up proper mappings for operators
    require('mini.operators').setup {}
  end,
}

local treewalker = {
  'aaronik/treewalker.nvim',
  keys = {
    { mode = { 'n', 'v' }, '<leader>h', 'Up' },
    { mode = { 'n', 'v' }, '<leader>j', 'Down' },
    { mode = { 'n', 'v' }, '<leader>k', 'Left' },
    { mode = { 'n', 'v' }, '<leader>l', 'Right' },
  },
  ---@module "lazy"
  ---@param plugin LazyPlugin
  config = function(plugin, _)
    vim.tbl_map(function(key)
      require('nuance.core.utils').map({ 'n', 'v' }, key[1], function()
        vim.cmd('Treewalker ' .. key[2])
        vim.api.nvim_input(vim.g.mapleader)
      end, { desc = 'Treewalker ' .. key[2] })
    end, plugin.keys)
  end,
}

local M = {
  surround,
  spider,
  ai,
  flash,
  { 'tpope/vim-rsi', lazy = false },
  -- treewalker,
  -- operator,
  -- matchup,
}

return M
