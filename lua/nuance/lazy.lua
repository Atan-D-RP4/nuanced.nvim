-- [[ Install `lazy.nvim` plugin manager ]]
vim.pack.add { 'https://github.com/folke/lazy.nvim' }

---@diagnostic disable-next-line: undefined-field
---@module 'lazy.nvim'
require('lazy').setup({
  rocks = { hererocks = false, enabled = false },
  performance = {
    rtp = {
      disabled_plugins = {
        '2html_plugin',
        'tohtml',
        'getscript',
        'getscriptPlugin',
        'netrw',
        'netrwPlugin',
        'netrwSettings',
        'netrwFileHandlers',
        'tar',
        'tarPlugin',
        'rrhelper',
        'vimball',
        'vimballPlugin',
        'zip',
        'zipPlugin',
        'tutor',
        'rplugin',
        'bugreport',

        -- 'matchit',
        -- 'matchparen',
        -- 'osc52',
        -- 'ftplugin',
        -- 'gzip',
        -- 'logipat',
        -- 'syntax',
        -- 'synmenu',
        -- 'optwin',
        -- 'compiler',
        -- 'spellfile_plugin',
      },
    },
  },

  spec = {
    -- { 'vuciv/golf', enabled = true },
    { import = 'nuance.plugins' },
  },

  change_detection = {
    enabled = false,
    notify = false,
  },
}, {
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

-- vim: ts=2 sts=2 sw=2 et
