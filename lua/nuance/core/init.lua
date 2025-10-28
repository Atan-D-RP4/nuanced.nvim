require 'nuance.core.options'
require 'nuance.core.keymaps'

-- NOTE: This is for when I convert the nuance.core directory into a Neovim-Lua plugin
vim.api.nvim_create_autocmd('User', {
  group = vim.api.nvim_create_augroup('nuance-autocmds', { clear = true }),
  desc = 'Setup Core Autocmds',
  pattern = 'VeryLazy',
  callback = function()
    require 'nuance.core.autocmds'
  end,
})

require('nuance.core.promise').async_promise(100, require('nuance.core.diagnostics').setup):catch(function(err)
  vim.notify(err, vim.log.levels.ERROR, { title = 'Treesitter Diagnostics' })
end)

require('nuance.core.bufline').setup()
require('nuance.core.rain').setup()

-- vim: ts=2 sts=2 sw=2 et
