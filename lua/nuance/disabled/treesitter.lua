return {
  -- Highlight, edit, and navigate code
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  event = { 'BufReadPre', 'BufNewFile' },

  main = 'nvim-treesitter.configs',
  init = function()
    if vim.uv.os_uname().sysname == 'Windows_NT' then
      vim.print 'On Windows_NT'
      require('nvim-treesitter.install').compilers = { 'zig' }
    end
  end,

  opts = {
    ensure_installed = treesitter_core_main.opts.ensure_installed,
    auto_install = false,

    highlight = {
      enable = true,
      additional_vim_regex_highlighting = { 'ruby', 'php' },

      disable = function(_, buf)
        local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
        local max_treesitter_filesize = 300 * 1024

        if not ok or stats == nil then
          vim.notify('Cannot get stats for ' + vim.api.nvim_buf_get_name(buf), vim.log.levels.DEBUG, { title = 'Treesitter' })
          return true
        end

        if stats.size > max_treesitter_filesize then
          vim.notify(
            'Disabling treesitter for ' .. vim.api.nvim_buf_get_name(buf) .. ' (file too large: ' .. (stats.size / 1024) .. ' KB)',
            vim.log.levels.WARN,
            { title = 'Treesitter' }
          )
          return true
        end
      end,
    },

    indent = { enable = true, disable = { 'ruby', 'php' } },

    incremental_selection = {
      enable = false,
      keymaps = {
        init_selection = '<C-g>',
        node_incremental = '<C-g>',
        -- scope_incremental = '<C-g>',
        node_decremental = '<BS>',
      },
    },
  },
}
