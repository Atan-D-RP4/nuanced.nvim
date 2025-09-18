local langs = {
  unpack { 'rust', 'python', 'c', 'java' },
  unpack { 'printf', 'query', 'regex' },
  unpack { 'diff' },
  unpack { 'html', 'css', 'javascript', 'jsdoc', 'typescript', 'tsx' },
  unpack { 'json', 'jsonc', 'xml', 'yaml', 'toml' },
  unpack { 'lua', 'luadoc', 'luap' },
  unpack { 'markdown', 'markdown_inline' },
  unpack { 'bash', 'vim', 'vimdoc' },
}

local treesitter_core_main = {
  ft = langs,
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  build = function()
    local ts = require 'nvim-treesitter'
    if not ts.get_installed then
      vim.notify(
        'Please restart Neovim and run `:TSUpdate` to use the `nvim-treesitter` **main** branch.',
        vim.log.levels.ERROR,
        { title = 'Treesitter' }
      )
      return
    end
    ts.update(nil, { summary = true })
  end,

  version = false,
  lazy = vim.fn.argc(-1) == 0, -- load treesitter early when opening a file from the cmdline

  opts_extend = { 'ensure_installed' },

  opts = {
    -- LazyVim config for treesitter
    ensure_installed = langs,
    -- install_dir = vim.fn.stdpath 'data' .. '/site',
  },

  ---@param opts TSConfig
  config = function(_, opts)
    local ts = require 'nvim-treesitter'

    -- some quick sanity checks
    if not ts.get_installed then
      vim.notify('Please use `:Lazy` and update `nvim-treesitter` to the **main** branch.', vim.log.levels.ERROR, { title = 'Treesitter' })
      return
    elseif vim.fn.executable 'tree-sitter' == 0 then
      vim.notify(
        'The `tree-sitter` CLI executable is not installed. Please install it to use the `treesitter-main` plugin.',
        vim.log.levels.ERROR,
        { title = 'Treesitter' }
      )
      return
    elseif type(opts.ensure_installed) ~= 'table' then
      vim.notify(
        '`nvim-treesitter` opts.ensure_installed must be a table, but got ' .. type(opts.ensure_installed),
        vim.log.levels.ERROR,
        { title = 'Treesitter' }
      )
      return
    end

    -- setup treesitter
    ts.setup(opts)

    -- install missing parsers
    local install = vim.tbl_filter(function(lang)
      return not vim.tbl_contains(ts.get_installed(), lang)
    end, opts.ensure_installed or {})
    if #install > 0 then
      ts.install(install, { summary = true }):await(function()
        ts.get_installed(true) -- refresh the installed langs
      end)
    end

    -- treesitter highlighting
    vim.api.nvim_create_autocmd('FileType', {
      callback = function(ev)
        if vim.tbl_contains(ts.get_installed(), ev.match) then
          pcall(vim.treesitter.start)
        end
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
    if vim.uv.os_uname().sysname == 'Windows_NT' then
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
        local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
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
  treesitter_core_main,
  -- treesitter_context, -- Replaced by dropbar.nvim
}
