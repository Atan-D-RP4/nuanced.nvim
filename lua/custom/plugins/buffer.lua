return {
  {
    'moll/vim-bbye',
    config = function()
      require('utils').nmap('<leader>dd', ':Bdelete!<CR>', 'Delete Buffer')
      vim.api.nvim_create_autocmd('VimEnter', {
        desc = "Delete Empty Buffer at startup",
        pattern = '*',
        callback = function()
          vim.cmd('Bdelete!')
        end,
      })
    end,
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
      },
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
  },
}
