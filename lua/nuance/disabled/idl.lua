return {
  { -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    dependencies = {
      'tpope/vim-sleuth',
    },

    event = { 'BufReadPost', 'BufAdd', 'BufNewFile' },
    -- Enable `lukas-reineke/indent-blankline.nvim`

    main = 'ibl',
    ---@module "ibl"
    ---@type ibl.config
    opts = {
      scope = {
        show_start = false,
        show_end = false,
      },

      exclude = {
        filetypes = {
          'help',
          'lazy',
          'neo-tree',
          'notify',
          'text',
          'startify',
          'dashboard',
          'neogitstatus',
          'NvimTree',
          'Trouble',
          'oil',
        },
        buftypes = { 'terminal', 'nofile' },
      },
    },
  },
}
