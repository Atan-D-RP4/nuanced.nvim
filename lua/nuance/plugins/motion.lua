local surround = {
  'echasnovski/mini.surround',
  event = 'VeryLazy',

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
  event = { 'BufRead', 'BufNewFile' },
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-treesitter/nvim-treesitter-textobjects',
  },
  config = function()
    require('mini.ai').setup { n_lines = 500 }
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
    'f', 'F', 't', 'T', ';', ',',
    { '<leader>l', '<cmd>lua require("flash").jump()<CR>', mode = { 'n', 'x', 'o' }, desc = 'Flash' },
    { '<leader>L', '<cmd>lua require("flash").treesitter()<CR>', mode = { 'n', 'x', 'o' }, desc = 'Flash Treesitter' },
    { '<leader>r', '<cmd>lua require("flash").remote()<CR>', mode = 'o', desc = 'Remote Flash' },
    { '<leader>R', '<cmd>lua require("flash").treesitter_search()<CR>', mode = { 'o', 'x' }, desc = 'Treesitter Search' },
    { '<c-s>', mode = { 'c' }, '<cmd>lua require("flash").toggle()<CR>', desc = 'Toggle Flash Search' },
  },

  ---@type Flash.Config
  opts = {
    labels = 'asdfghjklqwertyuiopzxcvbnm',
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
