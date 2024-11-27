return {
  {
    -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = { 'VeryLazy', 'BufReadPre', 'BufNewFile' },

    main = 'nvim-treesitter.configs',

    opts = function()
      if vim.loop.os_uname().sysname == 'Windows_NT' then
        print 'On Windows_NT'
        require('nvim-treesitter.install').compilers = { 'clang' }
      end

      -- Return Configuration
      return {
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
        auto_install = true,

        highlight = {
          enable = true,
          additional_vim_regex_highlighting = { 'ruby' },

          -- disable = function(_, buf)
          --   local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
          --   local max_treesitter_filesize = 300 * 1024
          --
          --   if not ok then
          --     vim.notify('Cannot get stats for ' + vim.api.nvim_buf_get_name(buf), vim.log.levels.DEBUG)
          --     return true
          --   end
          --
          --   if stats and stats.size > max_treesitter_filesize then
          --     return true
          --   end
          -- end,
        },

        indent = {
          enable = true,
          disable = { 'ruby' },
        },

        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = '<C-g>',
            node_incremental = '<C-g>',
            scope_incremental = '<CR>',
            node_decremental = '<BS>',
          },
        },
      }
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter-context',
    event = { 'VeryLazy', 'BufRead', 'BufNewFile' },

    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
    main = 'nvim-treesitter.configs',
  },
}
