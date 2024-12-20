-- Smart Selective Indentation
return {
  'sustech-data/wildfire.nvim',
  enabled = false,
  event = 'VeryLazy',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },

  opts = {
    keymaps = {
      init_selection = '<C-g>',
      node_incremental = '<C-g>',
      scope_incremental = '<CR>',
      node_decremental = '<BS>',
    },
    filetype_exclude = { 'qf' }, --keymaps will be unset in excluding filetypes)
  },
}
