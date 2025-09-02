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

require('nuance.core.diagnostics').conf()
require('nuance.core.utils').async_promise(100, 0, require('nuance.core.diagnostics').setup).catch(function(err)
  vim.notify(err, vim.log.levels.ERROR, { title = 'Treesitter Diagnostics' })
end)

require('nuance.core.bufline').setup()
require('nuance.core.rain').setup()

vim.g.configured_servers = vim.g.configured_servers or {}
require('nuance.core.utils')
  .async_promise(100, 0, require, 'nuance.core.lsps')
  .after(function(res)
    local configured_servers = {}
    for name, server in pairs(res) do
      local server_conf = vim.tbl_deep_extend('force', {}, server)
      configured_servers[name] = server_conf
    end
    vim.g.configured_servers = configured_servers
  end)
  .catch(function(err)
    vim.notify(err, vim.log.levels.ERROR, { title = 'LSP' })
  end)

-- vim: ts=2 sts=2 sw=2 et
