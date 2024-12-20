local themes = {
  tokyonight = {
    'folke/tokyonight.nvim',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    init = function()
      vim.cmd.colorscheme 'tokyonight-night'
      vim.cmd.hi 'Comment gui=italic'
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
        hi Comment gui=italic
      ]]
    end,
  },

  witch = {
    'sontungexpt/witch',
    priority = 1000,
    lazy = false,
    config = function(_, opts)
      require('witch').setup(opts)
    end,
  },

  kanagawa = {
    'rebelot/kanagawa.nvim',
    priority = 1000,
    opts = {
      compile = true, -- enable compiling the colorscheme
      undercurl = true, -- enable undercurls
      commentStyle = { italic = true },
      functionStyle = {},
      keywordStyle = { italic = true },
      statementStyle = { bold = true },
      typeStyle = {},
      transparent = false, -- do not set background color
      dimInactive = false, -- dim inactive window `:h hl-NormalNC`
      terminalColors = true, -- define vim.g.terminal_color_{0,17}
      colors = { -- add/modify theme and palette colors
        palette = {},
        theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
      },
      overrides = function(colors) -- add/modify highlights
        return {}
      end,
      theme = 'wave', -- Load "wave" theme when 'background' option is not set
      background = { -- map the value of 'background' option to a theme
        dark = 'dragon', -- try "dragon" !
        light = 'lotus',
      },
    },
    init = function()
      vim.cmd [[
        colorscheme kanagawa
        hi Comment gui=italic
      ]]
    end,
  },

  catpuccin = {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1001,
    init = function()
      vim.cmd [[
        colorscheme catppuccin-mocha
        hi Comment gui=italic
      ]]
    end,
  },
}

return {

  themes.witch,

  {
    'xiyaowong/nvim-transparent',
    event = 'VimEnter',
    config = true,
  },
}
-- vim: ts=2 sts=2 sw=2 et
