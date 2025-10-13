return {
  'nvim-neorg/neorg',
  version = '*', -- Pin Neorg to the latest stable release
  -- event = 'VeryLazy',
  cmd = 'Neorg',
  ft = 'norg',

  dependencies = {
    -- Set 1
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
    --

    -- Set 2
    { 'MunifTanjim/nui.nvim', cmd = 'Neorg' },
    { 'pysan3/pathlib.nvim', cmd = 'Neorg' },
    { 'nvim-neorg/lua-utils.nvim', cmd = 'Neorg' },
    { 'nvim-neotest/nvim-nio', cmd = 'Neorg' },
    --
  },

  keys = {
    { '<leader>nn', '<Plug>(neorg.dirman.new-note)', desc = '[neorg] Create New Note' },
  },

  opts = {
    load = {
      ['core.defaults'] = {},
      ['core.concealer'] = {},
      ['core.dirman'] = {
        config = {
          workspaces = {
            notes = '~/Notes',
          },
          default_workspace = 'notes',
        },
      },
    },
  },
}
