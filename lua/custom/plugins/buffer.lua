return {
  {
    "moll/vim-bbye",
    keys = {
      {
        "<leader>dd",
        "<cmd>Bdelete!<CR>",
        desc = "Delete buffer",
      },
    }
  },

  {
    -- Bufferswitcher
    'leath-dub/snipe.nvim',
    keys = {
      {
        'E',
        function()
          require('snipe').open_buffer_menu()
        end,
        desc = 'Open Snipe buffer menu',
      },
    },
    opts = {
       hints = {
        dictionary = '1234567890',
      }
    },
  },

  {
    -- Undotree
    'mbbill/undotree',
    cmd = 'UndotreeToggle',
    keys = {
      {
        '<leader>u',
        '<cmd>UndotreeToggle<CR>',
        desc = 'Toggle undotree',
      },
    },
  }
}
