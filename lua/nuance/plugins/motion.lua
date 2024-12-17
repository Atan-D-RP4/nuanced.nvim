return {
  {
    'unblevable/quick-scope',
    -- Load the plugin when fFtT are pressed in normal mode
    enabled = false,
    keys = { 'f', 'F', 't', 'T' },
    init = function()
      vim.cmd [[
      let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']
      let g:qs_max_chars = 150
      let g:qs_lazy_highlight = 1
      let g:qs_buftype_blacklist = ['terminal', 'nofile']

    " Highlight groups Red and Blue
      autocmd ColorScheme * highlight QuickScopeSecondary guifg=#00ff00 gui=underline ctermfg=21 cterm=underline
      autocmd ColorScheme * highlight QuickScopePrimary guifg=#ff3ede gui=underline ctermfg=196 cterm=underline
    ]]
    end,
  },

  {
    'folke/flash.nvim',
    keys = {
      'f', 'F', 't', 'T', ';', ',',
      { '<leader>l', '<cmd>lua require("flash").jump()<CR>', mode = { 'n', 'x', 'o' }, desc = 'Flash' },
      { '<leader>L', '<cmd>lua require("flash").treesitter()<CR>', mode = { 'n', 'x', 'o' }, desc = 'Flash Treesitter' },
      { '<leader>r', '<cmd>lua require("flash").remote()<CR>', mode = 'o', desc = 'Remote Flash' },
      { '<leader>R', '<cmd>lua require("flash").treesitter_search()<CR>', mode = { 'o', 'x' }, desc = 'Treesitter Search' },
      { '<c-s>', mode = { 'c' }, '<cmd>lua require("flash").toggle()<CR>', desc = 'Toggle Flash Search' },
    },

    ---@type Flash.Config
    opts = {
      modes = {
        char = {
          jump_labels = true,
          highlight = { backdrop = false },
        },
      },
    },
  },

  {
    'chrisgrieser/nvim-spider',
    lazy = true,
    keys = vim.tbl_map(function(key)
      local cmd = "<cmd>lua require('spider').motion('%s')<CR>"
      return {
        key,
        cmd:format 'w',
        mode = { 'n', 'o', 'x' },
        desc = ('Spider %s Motion'):format(key),
      }
    end, { 'w', 'e', 'b' }),
  },

  {
    'm4xshen/hardtime.nvim',
    enabled = false,
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    opts = {},
  },
}
