return {
  {
    -- Detect tabstop and shiftwidth automatically
	"tpope/vim-sleuth",
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
        dictionary = '0123456789',
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
