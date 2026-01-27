require 'nuance.core.options'
require 'nuance.core.keymaps'

-- NOTE: This is for when I convert the nuance.core directory into a Neovim-Lua plugin
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('nuance-autocmds', { clear = true }),
  desc = 'Setup Core Autocmds',
  callback = vim.schedule_wrap(function()
    require 'nuance.core.autocmds'
  end),
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

  require('vim._extui').enable {
    enable = true, -- Whether to enable or disable the UI.
    msg = { -- Options related to the message module.
      ---@type 'cmd'|'msg' Where to place regular messages, either in the
      ---cmdline or in a separate ephemeral message window.
      target = 'msg',
      timeout = 1000, -- Time a message is visible in the message window.
    },
  }
end

require('nuance.core.bufline').setup()

require('nuance.core.rain').setup {
  spawn_interval = 400,
  drop_interval = 35,
  winblend = 100,
  speed_variance = 10,
  diagonal_chars = { '⋅', '•', '◇', '' },
}

require 'nuance.core.music'
-- vim: ts=2 sts=2 sw=2 et
