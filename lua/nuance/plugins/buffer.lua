return {
  'tpope/vim-sleuth', -- For auto-detecting indent settings
  -- { 'wurli/contextindent.nvim', dependencies = { 'nvim-treesitter/nvim-treesitter' } },
  -- The Very Featureful Navigation Bar
  {
    'Bekaboo/dropbar.nvim',
    event = { 'VeryLazy', 'BufRead' },
    keys = {
      { '<leader>;', '<cmd>lua require("dropbar.api").pick()<CR>', desc = 'Pick symbols in Dropbar' },
    },
    opts = {
      menu = {
        win_configs = { border = 'rounded' },
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

    config = function()
      vim.g.undotree_WindowLayout = 4
    end,
  },

  {
    -- find/replace across multiple files
    'nvim-pack/nvim-spectre',
    enabled = true,
    keys = {
      { 'g/', '<cmd>Spectre<cr>', mode = { 'n' } },
    },
    config = function()
      require('spectre').setup { is_block_ui_break = true }
    end,
  },
}
