local mason_servers = {
  -- gopls = {},
  -- pyright = {},
  -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
  lua_ls = {
    -- cmd = {...},
    -- capabilities = {},
    filetypes = { 'lua' },
    settings = {
      Lua = {
        telemetry = { enable = false },
        completion = {
          callSnippet = 'Replace',
        },
        diagnostics = { disable = { 'missing-fields' } },
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

  bashls = {},
  html = {},
  emmet_language_server = {},
  vimls = {},
}

local external_servers = {
  denols = {},

  rust_analyzer = {
    ['rust-analyzer'] = {
      cargo = { allFeatures = true },
      checkOnSave = { command = 'clippy' },
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
  cmd = { 'LspStart', 'LspInfo', 'LspLog' },
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
    'java',
  },

  ---@module 'lspconfig'
  ---@type lspconfig.Config
  opts = {},
}

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
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = { 'InsertEnter' },
  config = function()
    require('copilot').setup {
      filetypes = {
        markdown = true, -- overrides default
      },
      suggestion = {
        hide_during_completion = false,
        auto_trigger = true,
      },
      copilot_node_command = 'node', -- Node.js version must be > 18.x
    }
  end,
}

M.lspconfig.dependencies = {
  -- Automatically install LSPs and related tools to stdpath for Neovim
  { 'williamboman/mason.nvim', config = true, cmd = { 'Mason', 'MasonLog' } }, -- NOTE: Must be loaded before dependants
  { 'WhoIsSethDaniel/mason-tool-installer.nvim', cmd = { 'MasonToolsInstall', 'MasonToolsClean', 'MasonToolsUpdate' } },
  'williamboman/mason-lspconfig.nvim',

  -- NOTE: This requires configuring of on_attach handlers for the
  -- language servers that are running. See docs.
  --
  -- The Minimalist Navigation Bar
  -- {
  --   'SmiteshP/nvim-navic',
  --   opts = {
  --     click = true,
  --   },
  --   config = function(_, opts)
  --     require('nvim-navic').setup(opts)
  --     vim.o.winbar = "%{%v:lua.require'nvim-navic'.get_location()%}"
  --   end,
  -- },
}

---@param event vim.api.keyset.create_autocmd.callback_args
local function on_attach(event)
  local nmap = require('nuance.core.utils').nmap
  local vmap = require('nuance.core.utils').vmap

  vim.lsp.set_log_level(vim.log.levels.OFF)
  vim.lsp.log.set_format_func(function(a, b)
    vim.inspect(a, b)
    vim.cmd 's/\\n/\\r/g'
  end)

  -- Set the priority of the semantic tokens to be lower than
  -- that of Treesitter, so that Treesitter is always highlighting
  -- over LSP semantic tokens.
  vim.highlight.priorities.semantic_tokens = 95

  local cmd
  local has_fzf, _ = pcall(require, 'fzf-lua')
  local has_telescope, _ = pcall(require, 'telescope')
  if has_fzf then
    cmd = '<cmd>lua require("fzf-lua").%s<CR>'
    nmap('gws', cmd:format 'lsp_live_workspace_symbols()', { buffer = true, desc = 'Lsp [W]orkspace [S]ymbols' })
    nmap('gd', cmd:format 'lsp_typedefs()', { buffer = true, desc = 'Lsp [T]ype [D]efinition' })
    nmap('gus', cmd:format 'lsp_document_symbols()', { buffer = true, desc = 'Lsp [D]ocument [S]ymbols' })
  elseif has_telescope then
    cmd = '<cmd>lua require("telescope.builtin").%s<CR>'
    nmap('gws', cmd:format 'lsp_dynamic_workspace_symbols()', { buffer = true, desc = 'Lsp [W]orkspace [S]ymbols' })
    nmap('gd', cmd:format 'lsp_typedefs()', { buffer = true, desc = 'Lsp [T]ype [D]efinition' })
    nmap('gus', cmd:format 'lsp_document_symbols()', { buffer = true, desc = 'Lsp [D]ocument [S]ymbols' })
  else
    cmd = '<cmd>lua Snacks.picker.%s<CR>'
    nmap('gd', cmd:format 'lsp_type_definitions()', { buffer = true, desc = 'Lsp [T]ype [D]efinition' })
    nmap('gus', cmd:format 'lsp_symbols()', { buffer = true, desc = 'Lsp [D]ocument [S]ymbols' })
  end

  nmap('gd', cmd:format 'lsp_definitions()', { buffer = true, desc = 'Lsp [G]oto [D]efinition' })
  nmap('grr', cmd:format 'lsp_references()', { buffer = true, desc = 'Lsp [G]oto [R]eferences' })          -- override `grr` mapping
  nmap('gri', cmd:format 'lsp_implementations()', { buffer = true, desc = 'Lsp [G]oto [I]mplementation' }) -- override `gri` mapping

  nmap('gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', { buffer = true, desc = '[G]oto [D]eclaration' })
  nmap('gs', '<cmd>lua vim.lsp.buf.signature_help()<CR>', { buffer = true, desc = '[G]et [S]ignature Help' })
  nmap('gra', '<cmd>lua vim.lsp.buf.code_action()<CR>', { buffer = true, desc = '[G]et [C]ode [A]ctions' })
  nmap('grn', '<cmd>lua vim.lsp.buf.rename()<CR>', { buffer = true, desc = '[G]et [C]ode [A]ctions' })
  vmap('gra', '<cmd>lua vim.lsp.buf.code_action()<CR>', { buffer = true, desc = '[G]et [C]ode [A]ctions' })
  nmap('K', '<cmd>lua vim.lsp.buf.hover({ border = "round" })<CR>', { buffer = true, desc = 'LSP Hover Documentation' })

  local client = vim.lsp.get_client_by_id(event.data.client_id)

  ---@diagnostic disable-next-line: param-type-mismatch
  if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
    nmap('<leader>th', function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
    end, '[T]oggle Inlay [H]ints')
  end

  -- The following two autocommands are used to highlight references of the
  -- word under your cursor when your cursor rests there for a little while.
  --    See `:help CursorHold` for information about when this is executed
  --
  -- When you move your cursor, the highlights will be cleared (the second autocommand).
  if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
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
  end

  -- vim.opt_local.foldmethod = 'expr'
  -- vim.opt_local.foldexpr = 'v:lua.vim.lsp.foldexpr()'
  -- vim.opt_local.foldtext = 'v:lua.vim.lsp.foldtext()'
end

M.lspconfig.config = function(_, opts) -- The '_' parameter is the entire lazy.nvim context
  opts.on_attach = on_attach
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('nuance-lsp-attach', { clear = true }),
    callback = on_attach,
  })

  vim.api.nvim_create_autocmd('LspDetach', {
    group = vim.api.nvim_create_augroup('nuance-lsp-detach', { clear = false }),
    callback = function(event)
      vim.lsp.buf.clear_references()
      vim.api.nvim_clear_autocmds { group = 'nuance-lsp-highlight', buffer = event.buf }

      vim.defer_fn(function()
        -- Kill the LS process if no buffers are attached to the client
        local cur_client = vim.lsp.get_client_by_id(event.data.client_id)
        if cur_client == nil or cur_client.name == 'copilot' then
          return
        end
        local attached_buffers_count = vim.tbl_count(cur_client.attached_buffers)
        if attached_buffers_count == 0 then
          local msg = 'No attached buffers to client: ' .. cur_client.name .. '\n'
          msg = msg .. 'Stopping language server: ' .. cur_client.name
          vim.notify(msg, vim.log.levels.INFO, { title = 'LSP' })
          cur_client:stop(true)
        end
      end, 200)
    end,
  })

  vim.diagnostic.config {
    underline = true,
    signs = true,
    update_in_insert = false,
    virtual_lines = { current_line = true },

    virtual_text = {
      spacing = 2,
      ---@param diagnostic vim.Diagnostic
      format = function(diagnostic)
        return string.format('%s - [%s] %s', diagnostic.source, diagnostic.code, diagnostic.message)
      end,
    },
  }

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
  --  When you add nvim-cmp, luasnip, blink, etc. Neovim now has *more* capabilities.
  --  So, we create new capabilities with nvim-cmp or blink, and then broadcast that to the servers.
  --
  local has_cmp, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
  local has_blink, blink = pcall(require, 'blink.cmp')
  local capabilities = vim.tbl_deep_extend(
    'force',
    {},
    vim.lsp.protocol.make_client_capabilities(),
    has_cmp and cmp_nvim_lsp.default_capabilities() or {},
    has_blink and blink.get_lsp_capabilities() or {},
    opts.capabilities or {}
  )

  require('mason').setup()

  -- You can add other tools here that you want Mason to install
  -- for you, so that they are available from within Neovim.
  vim.list_extend(vim.tbl_keys(mason_servers or {}), {})

  require('mason-tool-installer').setup {
    ensure_installed = vim.list_extend(vim.tbl_keys(mason_servers or {}), {}),
    run_on_start = true,
  }

  -- Merge Mason installed servers list with external servers list
  local servers = vim.tbl_deep_extend('force', mason_servers, external_servers)

  -- Adding Mason Installed servers to list of configured servers
  require('mason-lspconfig').setup {
    handlers = {
      function(server_name)
        servers[server_name] = servers[server_name] or {}
      end,
    },
  }

  vim.g.configured_language_servers = servers

  -- Configure the LSP servers with nvim-lspconfig
  for name, config in pairs(servers) do
    require('lspconfig')[name].setup {
      -- on_attach = function(client, bufnr)
      --   if client.server_capabilities.documentSymbolProvider then
      --     require('nvim-navic').attach(client, bufnr)
      --   end
      -- end,
      autostart = config.autostart or true,
      on_init = config.on_init or function()
        vim.notify('Initialized Language Server: ' .. name, vim.log.levels.INFO, { title = 'LSP' })
      end,
      cmd = config.cmd,
      capabilities = vim.tbl_extend('force', {}, capabilities, config.capabilities or {}),
      filetypes = config.filetypes,
      settings = config.settings,
      root_dir = config.root_dir,
    }
  end
end

return {
  M.lazydev,
  M.lspconfig,
  M.copilot,
}

-- vim: ts=2 sts=2 sw=2 et
