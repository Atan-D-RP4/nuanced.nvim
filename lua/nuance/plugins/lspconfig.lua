---@param event vim.api.keyset.create_autocmd.callback_args
local function on_attach(event)
  local nmap = require('nuance.core.utils').nmap

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
  local has_snacks, _ = pcall(require, 'snacks')
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
  elseif has_snacks then
    cmd = '<cmd>lua Snacks.picker.%s<CR>'
    nmap('gws', cmd:format 'lsp_workspace_symbols()', { buffer = true, desc = 'Lsp [W]orkspace [S]ymbols' })
    nmap('gd', cmd:format 'lsp_type_definitions()', { buffer = true, desc = 'Lsp [T]ype [D]efinition' })
    nmap('gus', cmd:format 'lsp_symbols()', { buffer = true, desc = 'Lsp [D]ocument [S]ymbols' })
  end

  nmap('gd', cmd:format 'lsp_definitions()', { buffer = true, desc = 'Lsp [G]oto [D]efinition' })
  nmap('grr', cmd:format 'lsp_references()', { buffer = true, desc = 'Lsp [G]oto [R]eferences' }) -- override `grr` mapping
  nmap('gri', cmd:format 'lsp_implementations()', { buffer = true, desc = 'Lsp [G]oto [I]mplementation' }) -- override `gri` mapping

  local client = vim.lsp.get_client_by_id(event.data.client_id)

  ---@diagnostic disable-next-line: param-type-mismatch
  if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, { bufnr = event.buf }) then
    nmap('<leader>th', function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
    end, '[T]oggle Inlay [H]ints')
  end

  -- The following two autocommands are used to highlight references of the
  -- word under your cursor when your cursor rests there for a little while.
  -- When you move your cursor, the highlights will be cleared (the second autocommand).
  if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
    local highlight_augroup = vim.api.nvim_create_augroup('nuance-lsp-highlight', { clear = true })
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
      group = highlight_augroup,
      callback = function(ev)
        vim.lsp.buf.clear_references()
        vim.api.nvim_clear_autocmds { group = 'nuance-lsp-highlight', buffer = ev.buf }
      end,
    })
  end

  -- vim.opt_local.foldmethod = 'expr'
  -- vim.opt_local.foldexpr = 'v:lua.vim.lsp.foldexpr()'
  -- vim.opt_local.foldtext = 'v:lua.vim.lsp.foldtext()'
end

local mason_servers = {
  -- See `:help lspconfig-all` for a list of all the pre-configured LSPs
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

  ruff = {
    settings = {
      lint = {
        codeAction = { fixViolation = { enable = true } },
        disableRuleComment = { enable = true },
        select = { 'E', 'F', 'W' },
        ignore = { 'F401' },
        enable = true,
      },

      format = { enable = true },
      logLevel = 'debug',

      -- Add organizeImports for better import handling
      organizeImports = { enable = true },
    },

    on_init = function(client, _)
      client.server_capabilities.hoverProvider = false
      client.settings.python = vim.tbl_extend('force', client.settings.python or {}, {
        pythonPath = require('nuance.core.utils').get_python_path(client.root_dir),
      })
    end,
  },

  jedi_language_server = {
    before_init = function(_, config)
      local python_path = require('nuance.core.utils').get_python_path(config.root_dir)
      if python_path then
        config.init_options.workspace.environmentPath = python_path
      end
    end,

    init_options = {
      codeAction = {
        nameExtractVariable = 'jls_extract_var',
        nameExtractFunction = 'jls_extract_def',
      },

      completion = {
        disableSnippets = false,
        resolveEagerly = false,
        ignorePatterns = {},
      },

      diagnostics = {
        enable = true,
        didOpen = true,
        didSave = true,
      },

      hover = {
        enable = true,
        disable = {
          class = { all = false, names = {}, fullNames = {} },
          ['function'] = { all = false, names = {}, fullNames = {} },
          instance = { all = false, names = {}, fullNames = {} },
          keyword = { all = false, names = {}, fullNames = {} },
          module = { all = false, names = {}, fullNames = {} },
          param = { all = false, names = {}, fullNames = {} },
          path = { all = false, names = {}, fullNames = {} },
          property = { all = false, names = {}, fullNames = {} },
          statement = { all = false, names = {}, fullNames = {} },
        },
      },

      jediSettings = {
        autoImportModules = {},
        caseInsensitiveCompletion = true,
        debug = false,
      },

      markupKindPreferred = 'markdown',

      workspace = {
        extraPaths = {},
        symbols = {
          ignoreFolders = { '.nox', '.tox', '.venv', '__pycache__', 'venv' },
          maxSymbols = 20,
        },
      },
    },
  },

  basedpyright = {
    enabled = false,

    on_init = function(client, _)
      client.settings.python = vim.tbl_extend('force', client.settings.python or {}, {
        pythonPath = require('nuance.core.utils').get_python_path(client.root_dir),
      })
    end,

    settings = {
      basedpyright = {
        analysis = {
          typeCheckingMode = 'strict',
          deprecateTypingAliases = true,
          diagnosticSeverityOverrides = {
            reportDeprecated = 'warning',
          },

          inlayHints = {
            variableTypes = true,
            functionReturnTypes = true,
            callArgumentNames = true,
            pytestParameters = true,
          },
        },
      },
    },
  },
}

local external_servers = {
  denols = {},

  rust_analyzer = {
    settings = {
      ['rust-analyzer'] = {
        cargo = {
          allFeatures = true,
          loadOutDirsFromCheck = true,
          buildScripts = {
            enable = true,
          },
        },
        imports = { granularity = { group = 'module' }, prefix = 'self' },
        checkOnSave = {
          -- enabled = false,
          command = 'clippy',
        },
        diagnostics = {
          -- enabled = false,
        },
      },
    },
  },

  clangd = {
    filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
  },
}

local lspconfig = {
  'neovim/nvim-lspconfig',
  cmd = { 'LspStart', 'LspInfo', 'LspLog' },
  ft = {
    'typescript', 'javascript',
    'html', 'css',
    'vim', 'lua',
    'sh', 'python',
    'c', 'cpp',
    'rust', 'java',
  },

  ---@module 'lspconfig'
  ---@type lspconfig.Config
  opts = {},
}

lspconfig.config = function(_, opts) -- The '_' parameter is the entire lazy.nvim context
  opts.on_attach = on_attach

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('nuance-lsp-attach', { clear = false }),
    callback = on_attach,
  })

  vim.api.nvim_create_autocmd('LspDetach', {
    group = vim.api.nvim_create_augroup('nuance-lsp-detach', { clear = false }),
    callback = function(event)
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

  -- Merge Mason installed servers list with external servers list
  local servers = vim.tbl_deep_extend('force', mason_servers, external_servers)
  vim.g.configured_language_servers = servers

  -- Configure the LSP servers with nvim-lspconfig
  for name, config in pairs(servers) do
    require('lspconfig')[name].setup {
      -- on_attach = function(client, bufnr)
      --   if client.server_capabilities.documentSymbolProvider then
      --     require('nvim-navic').attach(client, bufnr)
      --   end
      -- end,
      enabled = config.enabled ~= false,
      autostart = config.autostart or true,
      on_init = function(client, initialize_result)
        vim.notify('Initialized Language Server: ' .. name, vim.log.levels.INFO, { title = 'LSP' })
        if config.on_init then
          config.on_init(client, initialize_result)
        end
      end,
      before_init = false or function(params, client_config)
        if config.before_init then
          config.before_init(params, client_config)
        end
      end,
      cmd = config.cmd,
      capabilities = vim.tbl_extend('force', {}, capabilities, config.capabilities or {}),
      filetypes = config.filetypes,
      settings = config.settings,
      root_dir = config.root_dir,
      init_options = config.init_options or {},
    }
  end
end

local lazydev = {
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

local mason = {
  'williamboman/mason.nvim',
  config = function()
    require('mason').setup()
  end,
  cmd = { 'Mason', 'MasonLog' },
} -- NOTE: Must be loaded before dependants

return {
  mason,
  lazydev,
  lspconfig,
}

-- vim: ts=2 sts=2 sw=2 et
