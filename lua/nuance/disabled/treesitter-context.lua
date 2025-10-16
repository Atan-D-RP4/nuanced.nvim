return {
  'nvim-treesitter/nvim-treesitter-context',
  event = { 'BufRead', 'BufNewFile' },
  keys = {
    {
      '<leader>tc',
      '<cmd>lua require("treesitter-context").toggle()<CR>',
      desc = '[T]oggle Treesitter [C]ontext',
      mode = 'n',
    },
  },
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
  },
  main = 'nvim-treesitter.configs',
}
