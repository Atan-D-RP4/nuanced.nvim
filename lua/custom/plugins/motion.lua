local mapper = function()
  local keys = { 'e', 'w', 'b' }
  local final = {}

  for _, key in ipairs(keys) do
    table.insert(final, {
      key,
      string.format("<cmd>lua require('spider').motion('%s')<CR>", key),
      mode = { 'n', 'o', 'x' },
      desc = string.format('Spider Motion %s', key),
    })
  end
  return final
end

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

  {
    'chrisgrieser/nvim-spider',
    lazy = true,
    keys = mapper(),
  },
}