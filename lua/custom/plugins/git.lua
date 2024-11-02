return {
  'tpope/vim-fugitive',
  cmd = { 'Git', 'Gstatus', 'Gblame', 'Gpush', 'Gpull', 'Gcommit', 'Gdiff' },
  init = function()
    vim.cmd [[
     " Any options I may want to add 
    ]]
  end,
}
