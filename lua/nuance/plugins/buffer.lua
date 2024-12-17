return {
  {
    'moll/vim-bbye',
    config = function()
      require('nuance.core.utils').nmap('<leader>dd', ':Bdelete!<CR>', 'Delete Buffer')
      -- NOTE: Commented out since it breaks nvim-possession for now
      -- vim.api.nvim_create_autocmd('VimEnter', {
      --   desc = 'Delete Empty Buffer at startup',
      --   pattern = '*',
      --   callback = function()
      --     if vim.api.nvim_buf_get_name(0) == '' then
      --       vim.cmd 'Bdelete!'
      --     end
      --   end,
      -- })
    end,
  },

  {
    -- Buffer-Switcher
    'leath-dub/snipe.nvim',
    keys = {
      {
        '<leader>ee',
        '<cmd>lua require("snipe").open_buffer_menu()<CR>',
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
  },

  {
    -- find/replace across multiple files
    'nvim-pack/nvim-spectre',
    enabled = false,
    keys = {
      { 'g/', '<cmd>Spectre<cr>', mode = { 'n' } },
    },
    config = function()
      require('spectre').setup { is_block_ui_break = true }
    end,
  },

  {
    'OXY2DEV/markview.nvim',
    cmd = 'Markview',

    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
  },
}
