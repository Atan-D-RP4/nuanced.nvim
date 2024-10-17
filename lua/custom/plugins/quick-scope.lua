return {
  'unblevable/quick-scope',
  init = function()
    vim.cmd [[
    let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']
    let g:qs_max_chars = 150

  " Highlight groups Red and Blue
    autocmd ColorScheme * highlight QuickScopeSecondary guifg=#00ff00 gui=underline ctermfg=21 cterm=underline
    autocmd ColorScheme * highlight QuickScopePrimary guifg=#ff3ede gui=underline ctermfg=196 cterm=underline
  ]]
  end,
}
