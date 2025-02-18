require('nuance.core.clipboard')
require('nuance.core.keymaps')
require('nuance.core.utils')
require('nuance.core.options')
require('nuance.core.treesitter-diagnostics')


-- NOTE: This is for when I convert the nuance.core directory into a Neovim-Lua plugin
vim.api.nvim_create_autocmd('User', {
  group = vim.api.nvim_create_augroup('nuance-autocmds', { clear = true }),
  desc = 'Setup Core Autocmds',
  pattern = 'VeryLazy',
  callback = function()
    require('nuance.core.autocmds')
  end,
})

-- vim: ts=2 sts=2 sw=2 et
