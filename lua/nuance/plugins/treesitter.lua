local treesitter_core_main = {
  -- Highlight, edit, and navigate code
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  event = { 'BufReadPre', 'BufNewFile' },
  branch = 'main',
  lazy = false,

  config = function(_, _)
    local ts = require 'nvim-treesitter'

    local to_install = vim.tbl_filter(function(parser)
      return not vim.tbl_contains(ts.get_installed(), parser)
    end, {
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
    })
    ts.install(to_install)

    vim.api.nvim_create_autocmd('FileType', {
      pattern = { '<filetype>' },
      callback = function(ev)
        vim.print('Filetype: ' .. ev.match)
        if vim.tbl_contains({ 'ruby', 'php' }, ev.match) or not vim.tbl_contains(ts.get_installed(), ev.match) then
          return
        end

        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(ev.buf))
        local max_treesitter_filesize = 300 * 1024

        if not ok then
          vim.notify('Cannot get stats for ' + vim.api.nvim_buf_get_name(ev.buf), vim.log.levels.DEBUG, { title = 'Treesitter' })
          return
        end

        if stats and stats.size > max_treesitter_filesize then
          return
        end

        vim.treesitter.start()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
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
    ensure_installed = {
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
    },
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
