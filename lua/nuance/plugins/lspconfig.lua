-- Enable the following language servers
--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
--
--  Add any additional override configuration in the following tables. Available keys are:
--  - cmd (table): Override the default command used to start the server
--  - filetypes (table): Override the default list of associated filetypes for the server
--  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
--  - settings (table): Override the default settings passed when initializing the server.
--        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
local mason_servers = {
  -- gopls = {},
  -- pyright = {},
  -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
  --
  -- Some languages (like typescript) have entire language plugins that can be useful:
  --    https://github.com/pmizio/typescript-tools.nvim
  --
  -- But for many setups, the LSP (`ts_ls`) will work just fine
  -- ts_ls = {},
  lua_ls = {
    -- cmd = {...},
    -- filetypes = { ...},
    -- capabilities = {},
    settings = {
      Lua = {
        telemetry = { enable = false },
        completion = {
          callSnippet = 'Replace',
        },
        -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
        -- diagnostics = { disable = { 'missing-fields' } },
      },
    },
  },

  harper_ls = {
    filetypes = { 'markdown', 'text', 'gitcommit', 'html', 'norg' },
    settings = {
      ['harper-ls'] = {
        userDictPath = vim.fn.stdpath 'config' .. '/user.dict',
      },
    },
  },
}

local external_servers = {
  rust_analyzer = {
    check = {
      command = 'clippy',
      features = 'all',
    },
  },

  clangd = {
    filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
  },
}
-- LSP Plugins
local M = {}

M.lspconfig = {
  'neovim/nvim-lspconfig',
  cmd = { 'LspStart', 'LspInfo', 'LspInstall', 'LspUninstall' },
  ft = {
    'typescript',
    'javascript',
    'html',
    'css',
    'vim',
    'lua',
    'sh',
    'python',
    'rust',
    'c',
    'cpp',
  },
}
M.lspconfig.dependencies = {
  -- Automatically install LSPs and related tools to stdpath for Neovim
  {
    'williamboman/mason.nvim',
    config = true,
    cmd = { 'Mason', 'MasonLog' },
  }, -- NOTE: Must be loaded before dependants
  'williamboman/mason-lspconfig.nvim',
  'WhoIsSethDaniel/mason-tool-installer.nvim',
}

M.lspconfig.config = function()
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('nuance-lsp-attach', { clear = true }),
    -- NOTE: Remember that Lua is a real programming language, and as such it is possible
    -- to define small helper and utility functions so you don't have to repeat yourself.
    --
    -- In this case, we create a function that lets us more easily define mappings specific
    -- for LSP related items. It sets the mode, buffer and description for us each time.
    callback = function(event)
      local nmap = require('nuance.core.utils').nmap
      vim.lsp.set_log_level(vim.log.levels.OFF)

      local cmd
      local has_fzf, _ = pcall(require, 'fzf-lua')
      if has_fzf then
        cmd = '<cmd>lua require("fzf-lua").%s<CR>'
        nmap('gws', cmd:format 'lsp_live_workspace_symbols()', 'Lsp [W]orkspace [S]ymbols')
      else
        cmd = '<cmd>lua require("telescope.builtin").%s<CR>'

        nmap('gws', cmd:format 'lsp_dynamic_workspace_symbols()', 'Lsp [W]orkspace [S]ymbols')
      end

      nmap('gd', cmd:format 'lsp_definitions()', 'Lsp [G]oto [D]efinition')
      nmap('grr', cmd:format 'lsp_references()', 'Lsp [G]oto [R]eferences') -- override `grr` mapping
      nmap('gri', cmd:format 'lsp_implementations()', 'Lsp [G]oto [I]mplementation') -- override `gri` mapping
      nmap('gtd', cmd:format 'lsp_typedefs()', 'Lsp [T]ype [D]efinition')
      nmap('gus', cmd:format 'lsp_document_symbols()', 'Lsp [D]ocument [S]ymbols')

      nmap('gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', '[G]oto [D]eclaration')
      nmap('gs', '<cmd>lua vim.lsp.buf.signature_help()<CR>', '[G]et [S]ignature Help')
      nmap('gca', '<cmd>lua vim.lsp.buf.code_action()<CR>', '[G]et [C]ode [A]ctions')

      -- The following two autocommands are used to highlight references of the
      -- word under your cursor when your cursor rests there for a little while.
      --    See `:help CursorHold` for information about when this is executed
      --
      -- When you move your cursor, the highlights will be cleared (the second autocommand).
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      ---@diagnostic disable-next-line: param-type-mismatch
      if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
        local highlight_augroup = vim.api.nvim_create_augroup('nuance-lsp-highlight', { clear = false })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })

        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.clear_references,
        })

        vim.api.nvim_create_autocmd('LspDetach', {
          group = vim.api.nvim_create_augroup('nuance-lsp-detach', { clear = true }),
          callback = function(event2)
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds { group = 'nuance-lsp-highlight', buffer = event2.buf }
          end,
        })
      end

      ---@diagnostic disable-next-line: param-type-mismatch
      if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
        nmap('<leader>th', function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
        end, '[T]oggle Inlay [H]ints')
      end
    end,
  })

  -- Change diagnostic symbols in the sign column (gutter)
  -- if vim.g.have_nerd_font then
  --   local signs = { ERROR = '', WARN = '', INFO = '', HINT = '' }
  --   local diagnostic_signs = {}
  --   for type, icon in pairs(signs) do
  --     diagnostic_signs[vim.diagnostic.severity[type]] = icon
  --   end
  --   vim.diagnostic.config { signs = { text = diagnostic_signs } }
  -- end

  vim.api.nvim_set_hl(0, 'LspReferenceText', {})

  -- NOTE: Extend nvim LSP client capabilities for completion
  -- LSP servers and clients are able to communicate to each other what features they support.
  --  By default, Neovim doesn't support everything that is in the LSP specification.
  --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
  --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
  --
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local has_cmp, cmp = pcall(require, 'blink.cmp')
  if has_cmp then
    capabilities = vim.tbl_deep_extend('force', capabilities, cmp.get_lsp_capabilities())
  else
    cmp = require 'cmp'
    capabilities = vim.tbl_deep_extend('force', capabilities, cmp.default_capabilities())
  end

  local servers = vim.tbl_deep_extend('force', mason_servers, external_servers)

  -- Ensure the servers and tools above are installed
  --  To check the current status of installed tools and/or manually install
  --  other tools, you can run
  --    :Mason
  --
  --  You can press `g?` for help in this menu.
  require('mason').setup()

  -- You can add other tools here that you want Mason to install
  -- for you, so that they are available from within Neovim.
  local ensure_installed = vim.tbl_keys(mason_servers or {})

  vim.list_extend(ensure_installed, {
    'lua-language-server', -- Used for Lua
    'vim-language-server', -- Used for Vimscript
    'bashls', -- Used for Bash
    'stylua', -- Used to format Lua code
    'html',
    'harper-ls', -- Used for English grammar checking
    'emmet-language-server',
  })
  require('mason-tool-installer').setup { ensure_installed = ensure_installed }

  require('mason-lspconfig').setup {
    handlers = {
      function(server_name)
        local server = servers[server_name] or {}
        -- This handles overriding only values explicitly passed
        -- by the server configuration above. Useful when disabling
        -- certain features of an LSP (for example, turning off formatting for ts_ls)
        server.capabilities = vim.tbl_extend('force', {}, capabilities, server.capabilities or {})
        require('lspconfig')[server_name].setup(server)
      end,
    },
  }

  local default_handlers = {
    ['textDocument/hover'] = vim.lsp.buf.hover { border = 'rounded' },
    ['textDocument/signatureHelp'] = vim.lsp.buf.signature_help { border = 'rounded' },
  }
  for name, config in pairs(servers) do
    require('lspconfig')[name].setup {
      autostart = config.autostart,
      cmd = config.cmd,
      capabilities = capabilities,
      filetypes = config.filetypes,
      handlers = vim.tbl_deep_extend('force', {}, default_handlers, config.handlers or {}),
      settings = config.settings,
      root_dir = config.root_dir,
    }
  end
end

M.lazydev = {
  -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
  -- used for completion, annotations and signatures of Neovim apis
  'folke/lazydev.nvim',
  ft = 'lua',
  events = 'VeryLazy',
  dependencies = {
    { 'Bilal2453/luvit-meta', lazy = true },
  },
  opts = {
    library = {
      -- Load luvit types when the `vim.uv` word is found
      { path = 'luvit-meta/library', words = { 'vim%.uv' } },
    },
  },
}

M.copilot = {
  {
    'github/copilot.vim',
    events = 'InsertEnter',
    config = function()
      vim.cmd [[
        let g:copilot_node_command = '/usr/sbin/bun'
      ]]
    end,
  },
}

return {
  M.lazydev,
  M.lspconfig,
  M.copilot,
}
-- vim: ts=2 sts=2 sw=2 et