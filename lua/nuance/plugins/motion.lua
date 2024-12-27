return {
  {
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
      modes = {
        char = {
          jump_labels = true,
          highlight = { backdrop = false },
        },
      },
    },
  },

  {
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
  },
}
