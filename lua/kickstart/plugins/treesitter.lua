return {
  {
    -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = { 'BufReadPre', 'BufNewFile' },

    main = 'nvim-treesitter.configs',

    opts = function()
      -- Set Platform specific options
      if vim.loop.os_uname().sysname == 'Windows_NT' then
        print 'On Windows_NT'
        require('nvim-treesitter.install').compilers = { 'clang' }
      end

      -- Return Configuration
      return {
        ensure_installed = {
          'bash',
          'c',
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
        },

        indent = {
          enable = true,
          disable = { 'ruby', 'c' },
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
}
