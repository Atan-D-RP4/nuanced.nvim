local dropbar = {
  'Bekaboo/dropbar.nvim',
  event = { 'VeryLazy', 'BufRead' },
  keys = {
    { '<leader>;', '<cmd>lua require("dropbar.api").pick()<CR>', desc = 'Pick symbols in Dropbar' },
  },
  opts = { menu = { win_configs = { border = 'rounded' } } },
}

local undotree = {
  -- Undotree
  'mbbill/undotree',
  cmd = 'UndotreeToggle',
  keys = {
    { '<leader>u', '<cmd>UndotreeToggle<CR>', desc = 'Toggle undotree' },
  },

  config = function()
    vim.g.undotree_WindowLayout = 4
  end,
}

local grugfar = {
  -- find/replace across multiple files
  'MagicDuck/grug-far.nvim',
  enabled = true,

  ---@module 'grug-far'
  ---@type GrugFarOptions
  opts = {
    filetypes = {
      ['grug-far'] = true,
      ['grug-far-history'] = false,
      ['grug-far-help'] = false,
    },
  },
  keys = {
    { 'g/', '<cmd>lua require("grug-far").open()<CR>', desc = 'Grug Far Search/Replace', mode = { 'n', 'x' } },
    { 'g/', '<cmd>lua require("grug-far").with_visual_selection()<CR>', desc = 'Grug Far Search/Replace', mode = { 'v' } },
  },
}

return {
  {
    'tpope/vim-sleuth',
    event = 'InsertEnter',
  }, -- For auto-detecting indent settings
  dropbar,
  grugfar,
  -- undotree,
}
