local treesitter_core_main = {
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
  event = { 'BufReadPre' },

  ---@module 'nvim-treesitter.configs'
  ---@type TSConfig
  opts = {
    -- stylua: ignore
    ensure_installed = {
      'rust', 'python', 'c', 'java',
      'printf', 'query', 'diff', 'regex',
      'html', 'css', 'javascript', 'jsdoc', 'typescript', 'tsx',
      'json', 'jsonc', 'xml', 'yaml', 'toml',
      'lua', 'luadoc', 'luap',
      'markdown', 'markdown_inline',
      'bash', 'vim', 'vimdoc',
      'latex', 'norg', 'scss', 'svelte', 'typst', 'vue'
    },
  },

  ---@param opts TSConfig
  config = function(_, opts)
    local ts = require 'nvim-treesitter'
    local ensure_installed = opts.ensure_installed

    if vim.fn.executable 'tree-sitter' == 0 then
      vim.notify(
        'The `tree-sitter` CLI executable is not installed. Please install it to use the `treesitter-main` plugin.',
        vim.log.levels.ERROR,
        { title = 'Treesitter' }
      )
      return
    end

    -- setup treesitter
    ts.setup(opts)

    -- install missing parsers
    local to_install = vim.tbl_filter(function(lang)
      return not vim.tbl_contains(ts.get_installed(), lang)
    end, ensure_installed or {})

    if #to_install > 0 then
      ts.install(to_install, { summary = true }):await(function()
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

return {
  treesitter_core_main,
}
