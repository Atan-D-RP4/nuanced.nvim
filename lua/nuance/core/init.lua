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

if vim.version() >= vim.version { major = 0, minor = 12, patch = 0 } then
  require('nuance.core.promise')
    .async_promise(100, function()
      vim.cmd [[ packadd nvim.difftool ]]
      vim.cmd [[ packadd nvim.undotree ]]
    end)
    :catch(function(err)
      vim.notify('Failed to load 0.12 Native plugins: ' .. err, vim.log.levels.ERROR)
    end)
end

require('nuance.core.bufline').setup()
require('nuance.core.rain').setup({
  spawn_interval = 400,
  drop_interval = 35,
  winblend = 100,
  speed_variance = 10,
})

-- vim: ts=2 sts=2 sw=2 et
