local treesitter_core = {
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

local treewalker = {
  'aaronik/treewalker.nvim',
  keys = {
    { mode = { 'n', 'v' }, '<leader>h', 'Up' },
    { mode = { 'n', 'v' }, '<leader>j', 'Down' },
    { mode = { 'n', 'v' }, '<leader>k', 'Left' },
    { mode = { 'n', 'v' }, '<leader>l', 'Right' },
  },
  ---@module "lazy"
  ---@param plugin LazyPlugin
  config = function(plugin, _)
    vim.tbl_map(function(key)
      require('nuance.core.utils').map({ 'n', 'v' }, key[1], function()
        vim.cmd('Treewalker ' .. key[2])
        vim.api.nvim_input(vim.g.mapleader)
      end, { desc = 'Treewalker ' .. key[2] })
    end, plugin.keys)
  end,
}

return {
  treesitter_core,
  -- treesitter_context, -- Replaced by dropbar.nvim
  treewalker,
}
