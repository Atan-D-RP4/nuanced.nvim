local theme_specs = {
  tokyonight = {
    'folke/tokyonight.nvim',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    init = function()
      vim.cmd.colorscheme 'tokyonight-night'
      vim.cmd.hi 'Comment gui=none'
    end,
  },

  shadotheme = {
    'Shadorain/shadotheme',
    priority = 1000,
    init = function()
      vim.cmd [[
        colorscheme shado-legacy
        hi Keyword gui=italic
        hi WinBar guibg=None
        hi WinBarNC guibg=None
        hi Comment gui=none
      ]]
    end,
  },
}

return {

  theme_specs.tokyonight,

  {
    'xiyaowong/nvim-transparent',
    event = 'VimEnter',
    config = true,
  },
}
-- vim: ts=2 sts=2 sw=2 et
