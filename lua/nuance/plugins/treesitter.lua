local langs = {
  'bash',
  'c',
  'rust',
  'diff',
  'html',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'query',
  'vim',
  'vimdoc',
}

local treesitter_core_main = {
  'MeanderingProgrammer/treesitter-modules.nvim',
  ft = langs,
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    opts = { install_dir = vim.fn.stdpath 'data' .. '/site' },
  },

  ---@module 'treesitter-modules'
  ---@type ts.mod.UserConfig
  opts = {
    -- list of parser names, or 'all', that must be installed
    -- ensure_installed = langs,
    -- list of parser names, or 'all', to ignore installing
    ignore_install = {},
    -- install parsers in ensure_installed synchronously
    sync_install = false,
    -- automatically install missing parsers when entering buffer
    auto_install = false,
    fold = {
      enable = false,
      disable = false,
    },
    highlight = {
      enable = true,
      disable = function(ctx)
        local buf = ctx.buf
        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
        local max_treesitter_filesize = 300 * 1024

        if not ok then
          vim.notify('Cannot get stats for ' + vim.api.nvim_buf_get_name(buf), vim.log.levels.DEBUG, { title = 'Treesitter' })
          return true
        end

        if stats and stats.size > max_treesitter_filesize then
          return true
        end
        return false
      end,
      additional_vim_regex_highlighting = { 'ruby', 'php' },
    },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = '<C-g>',
        node_incremental = '<C-g>',
        -- scope_incremental = '<C-g>',
        node_decremental = '<BS>',
      },
    },
    indent = {
      enable = true,
    },
  },
}

local treesitter_core_master = {
  -- Highlight, edit, and navigate code
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  event = { 'BufReadPre', 'BufNewFile' },

  main = 'nvim-treesitter.configs',
  init = function()
    if vim.loop.os_uname().sysname == 'Windows_NT' then
      vim.print 'On Windows_NT'
      require('nvim-treesitter.install').compilers = { 'zig' }
    end
  end,

  opts = {
    ensure_installed = langs,
    auto_install = false,

    highlight = {
      enable = true,
      additional_vim_regex_highlighting = { 'ruby', 'php' },

      disable = function(_, buf)
        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
        local max_treesitter_filesize = 300 * 1024

        if not ok then
          vim.notify('Cannot get stats for ' + vim.api.nvim_buf_get_name(buf), vim.log.levels.DEBUG, { title = 'Treesitter' })
          return true
        end

        if stats and stats.size > max_treesitter_filesize then
          return true
        end
      end,
    },

    indent = { enable = true, disable = { 'ruby', 'php' } },

    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = '<C-g>',
        node_incremental = '<C-g>',
        -- scope_incremental = '<C-g>',
        node_decremental = '<BS>',
      },
    },
  },
}

local treesitter_context = {
  'nvim-treesitter/nvim-treesitter-context',
  event = { 'BufRead', 'BufNewFile' },
  keys = {
    {
      '<leader>tc',
      '<cmd>lua require("treesitter-context").toggle()<CR>',
      desc = '[T]oggle Treesitter [C]ontext',
      mode = 'n',
    },
  },
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
  },
  main = 'nvim-treesitter.configs',
}

return {
  treesitter_core_master,
  -- treesitter_context, -- Replaced by dropbar.nvim
}
