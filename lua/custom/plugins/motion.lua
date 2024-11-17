return {
  {
    'unblevable/quick-scope',
    -- Load the plugin when fFtT are pressed in normal mode
    keys = { 'f', 'F', 't', 'T' },
    init = function()
      vim.cmd [[
      let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']
      let g:qs_max_chars = 150

    " Highlight groups Red and Blue
      autocmd ColorScheme * highlight QuickScopeSecondary guifg=#00ff00 gui=underline ctermfg=21 cterm=underline
      autocmd ColorScheme * highlight QuickScopePrimary guifg=#ff3ede gui=underline ctermfg=196 cterm=underline
    ]]
    end,
  },

  -- {
  --   "chrisgrieser/nvim-spider",
  --   lazy = true,
  --   -- NOTE: More config is needed - see https://github.com/chrisgrieser/nvim-spider
  --   config = function()
  --     require("spider").setup()
  --   end,
  -- }
}
