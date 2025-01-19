local surround = {
  'echasnovski/mini.surround',
  event = { 'BufRead', 'BufNewFile' },

  opts = {
    mappings = {
      add = '<leader>sa',
      delete = '<leader>sd',
      find = '<leader>sf',
      find_left = '<leader>sF',
      highlight = '<leader>sh',
      replace = '<leader>sr',
      suffix_last = 'l',
      suffix_next = 'n',
    },
  },
}

local ai = {
  -- Better Around/Inside textobjects
  'echasnovski/mini.ai',
  lazy = true,
  event = { 'BufRead', 'BufNewFile' },
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-treesitter/nvim-treesitter-textobjects',
  },
  opts = {
    -- Table with textobject id as fields, textobject specification as values.
    -- Also use this to disable builtin textobjects. See |MiniAi.config|.
    custom_textobjects = nil,

    -- Module mappings. Use `''` (empty string) to disable one.
    mappings = {
      -- Main textobject prefixes
      around = 'a',
      inside = 'i',

      -- Next/last textobjects
      around_next = 'an',
      inside_next = 'in',
      around_last = 'al',
      inside_last = 'il',

      -- Move cursor to corresponding edge of `a` textobject
      goto_left = '<leader>[',
      goto_right = '<leader>]',
    },

    -- Number of lines within which textobject is searched
    n_lines = 50,

    -- How to search for object (first inside current line, then inside
    -- neighborhood). One of 'cover', 'cover_or_next', 'cover_or_prev',
    -- 'cover_or_nearest', 'next', 'prev', 'nearest'.
    search_method = 'cover_or_next',

    -- Whether to disable showing non-error feedback
    -- This also affects (purely informational) helper messages shown after
    -- idle time if user input is required.
    silent = false,
  },
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
    'f', 'F', 't', 'T', ';', ',',
    { '<leader>l', '<cmd>lua require("flash").jump()<CR>', mode = { 'n', 'x', 'o' }, desc = 'Flash' },
    { '<leader>L', '<cmd>lua require("flash").treesitter()<CR>', mode = { 'n', 'x', 'o' }, desc = 'Flash Treesitter' },
    { '<leader>r', '<cmd>lua require("flash").remote()<CR>', mode = 'o', desc = 'Remote Flash' },
    { '<leader>R', '<cmd>lua require("flash").treesitter_search()<CR>', mode = { 'o', 'x' }, desc = 'Treesitter Search' },
    { '<c-s>', mode = { 'c' }, '<cmd>lua require("flash").toggle()<CR>', desc = 'Toggle Flash Search in "/" mode' },
  },

  ---@type Flash.Config
  opts = {
    -- labels = 'asdfghjklqwertyuiopzxcvbnm',
    labels = 'dgqftyuzxcvbnm1234567890',
    search = {
      mode = 'search',
    },
    modes = {
      char = {
        jump_labels = true,
        highlight = { backdrop = false },
      },
    },
  },
}

local matchup = {
  'andymass/vim-matchup',
  event = 'VeryLazy',
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

local M = {
  surround,
  spider,
  ai,
  flash,
  matchup,
}

return M
