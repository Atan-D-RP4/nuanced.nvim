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

  init = function()
    local map = require('nuance.core.utils').map
    map('n', 'gl', '<Plug>(neorg.esupports.hop.hop-link)', '[neorg] ')
    map('n', '<,', '<Plug>(neorg.promo.demote)', '[neorg] ')
    map('n', '>.', '<Plug>(neorg.promo.promote)', '[neorg] ')
    map('v', '<', '<Plug>(neorg.promo.demote.range)gv', '[neorg] ')
    map('v', '>', '<Plug>(neorg.promo.promote.range)gv', '[neorg] ')
    map('n', '>>', '<Plug>(neorg.promo.promote.nested)', '[neorg] ')
    map('n', '<<', '<Plug>(neorg.promo.demote.nested)', '[neorg] ')
  end,
}
