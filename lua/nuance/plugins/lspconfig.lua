local mason_servers = {
  lua_ls = {
    -- cmd = {...},
    -- capabilities = {},
    enabled = vim.fn.executable 'lua-language-server' == 1,
    filetypes = { 'lua' },
    settings = {
      Lua = {
        telemetry = { enable = false },
        completion = {
          callSnippet = 'Replace',
        },
        diagnostics = {
          disable = { 'missing-fields' },
        },
      },
    },
  },

  harper_ls = {
    enabled = vim.fn.executable 'harper-ls' == 1,
    filetypes = { 'markdown', 'text', 'gitcommit', 'html', 'norg' },
    settings = {
      ['harper-ls'] = {
        userDictPath = vim.fn.stdpath 'config' .. '/user.dict',
      },
    },
  },

  bashls = { enabled = vim.fn.executable 'bash-language-server' == 1 },

  html = {
    enabled = vim.fn.executable 'vscode-html-language-server' == 1,
    filetypes = { 'html', 'htmldjango' },
  },

  emmet_language_server = {
    enabled = vim.fn.executable 'emmet-ls' == 1,
    filetypes = { 'html', 'css', 'scss', 'less', 'javascriptreact', 'typescriptreact' },
  },

  vimls = {
    enabled = vim.fn.executable 'vim-language-server' == 1,
    filetypes = { 'vim' },
    settings = {
      vim = {
        format = {
          enable = true,
          options = {
            tabSize = 2,
            expandtab = true,
            shiftwidth = 2,
          },
        },
      },
    },
  },

  ruff = {
    enabled = vim.fn.executable 'ruff' == 1,
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
    enabled = vim.fn.executable 'jedi-language-server' == 1,

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
    enabled = vim.fn.executable 'basedpyright' == 1,

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

  jdtls = { enabled = vim.fn.executable 'jdtls' == 1 },

  hyprls = { enabled = vim.fn.executable 'hyprls' == 1 },

  texlab = {
    enabled = vim.fn.executable 'texlab' == 1,

    settings = {
      texlab = {
        build = {
          executable = 'tectonic',

          args = {
            '-X',
            'build',
          },

          onSave = true,
          forwardSearchAfter = true,
        },

        forwardSearch = {
          executable = 'zathura', -- or "sioyek", "evince", etc.

          args = {
            '--synctex-forward',
            '%l:1:%f',
            '%p',
          },
        },

        chktex = {
          onEdit = true,
          onOpenAndSave = true,
        },

        diagnosticsDelay = 300,
        latexFormatter = 'latexindent',

        latexindent = {
          modifyLineBreaks = true,
        },
      },
    },
  },

  tinymist = {
    enabled = vim.fn.executable 'tinymist' == 1,

    settings = {
      formatterMode = 'typstyle',
      exportPdf = 'onType',
      semanticTokens = 'disable',
    },
  },

  denols = {
    enabled = vim.fn.executable 'deno' == 1,
    filetypes = { 'typescript', 'javascript' },
  },

  rust_analyzer = {
    enabled = vim.fn.executable 'rust-analyzer' == 1,

    settings = {
      ['rust-analyzer'] = {
        cargo = {
          allFeatures = true,
          loadOutDirsFromCheck = true,
          buildScripts = { enable = true },
        },

        imports = { granularity = { group = 'module' }, prefix = 'self' },
        -- Add "enabled = false", if you want to disable it
        checkOnSave = { command = 'clippy' },
        -- Add "enabled = false", if you want to disable them
        diagnostics = {},
      },
    },
  },

  clangd = { enabled = vim.fn.executable 'clangd' == 1 },
}

local lspconfig = {
  'neovim/nvim-lspconfig',
  cmd = { 'LspStart', 'LspInfo', 'LspLog' },

  ft = {
    -- Web Languages
    'typescript', 'javascript', 'html', 'css',
    -- Script Languages
    'vim', 'lua', 'sh', 'python',
    -- Compiled Languages
    'c', 'cpp', 'rust', 'java',
    -- Document Filetypes
    'tex',
  },

  ---@module 'lspconfig'
  ---@type lspconfig.Config
  opts = {},
}
---@param client vim.lsp.Client
---@param bufnr number
lspconfig.opts.on_attach = function(client, bufnr)
  -- Set the priority of the semantic tokens to be lower than
  -- that of Treesitter, so that Treesitter is always highlighting
  -- over LSP semantic tokens.
  vim.highlight.priorities.semantic_tokens = 95

  vim.lsp.set_log_level(vim.log.levels.INFO)
  vim.lsp.log.set_format_func(function(args)
    local msg = vim.inspect(args)
    msg = msg:gsub('\t', '  ')
    return msg:gsub('\n', '\n')
  end)

  vim.tbl_map(function(map)
    local key = map[1]
    local rhs = '<cmd>lua Snacks.picker.' .. map[2] .. '<CR>'
    local opts = map[3] or {}
    require('nuance.core.utils').nmap(key, rhs, opts)
  end, {
    { 'gws', 'lsp_workspace_symbols()', { buffer = true, desc = 'LSP [W]orkspace [S]ymbols' } },
    { 'gd', 'lsp_type_definitions()', { buffer = true, desc = 'LSP [T]ype [D]efinition' } },
    { 'gus', 'lsp_symbols()', { buffer = true, desc = 'LSP [D]ocument [S]ymbols' } },

    { 'gd', 'lsp_definitions()', { buffer = true, desc = 'LSP [G]oto [D]efinition' } },
    { 'grr', 'lsp_references()', { buffer = true, desc = 'LSP [G]oto [R]eferences' } }, -- override `grr` mapping
    { 'gri', 'lsp_implementations()', { buffer = true, desc = 'LSP [G]oto [I]mplementation' } }, -- override `gri` mapping
  })

  ---@diagnostic disable-next-line: param-type-mismatch
  if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, { bufnr = bufnr }) then
    require('nuance.core.utils').nmap('<leader>th', function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = bufnr })
    end, 'LSP [T]oggle Inlay [H]ints')
  end

  if not client or not client.server_capabilities then
    vim.notify('LSP client not found or does not have server capabilities', vim.log.levels.WARN, { title = 'LSP' })
    return
  end

  -- The following two autocommands are used to highlight references of the
  -- word under your cursor when your cursor rests there for a little while.
  -- When you move your cursor, the highlights will be cleared (the second autocommand).
  if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, bufnr) then
    local highlight_augroup = vim.api.nvim_create_augroup('nuance-lsp-highlight', { clear = true })
    vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
      buffer = bufnr,
      group = highlight_augroup,
      callback = vim.lsp.buf.document_highlight,
    })

    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
      buffer = bufnr,
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

---@module 'lspconfig'
---@param opts lspconfig.Config
lspconfig.config = function(_, opts) -- The '_' parameter is the entire lazy.nvim context
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('nuance-lsp-attach', { clear = false }),
    ---@param event vim.api.keyset.create_autocmd.callback_args
    callback = function(event)
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client == nil then
        return
      end
      opts.on_attach(client, event.buf)
    end,
  })

  vim.api.nvim_create_autocmd('LspDetach', {
    group = vim.api.nvim_create_augroup('nuance-lsp-detach', { clear = false }),
    callback = function(event)
      -- vim.api.clear_autocmds { group = detach_augroup, buffer = event.buf }
      vim.defer_fn(function()
        -- Kill the LS process if no buffers are attached to the client
        local cur_client = vim.lsp.get_client_by_id(event.data.client_id)
        if cur_client == nil or cur_client.name == 'copilot' then
          return
        end
        local attached_buffers_count = vim.tbl_count(cur_client.attached_buffers)
        if attached_buffers_count == 0 then
          vim.notify('No attached buffers to client: ' .. cur_client.name, vim.log.levels.INFO, { title = 'LSP' })
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
  local servers = mason_servers
  vim.g.configured_language_servers = servers

  -- Configure the LSP servers with nvim-lspconfig
  for name, config in pairs(servers) do
    local server_conf = vim.tbl_deep_extend('force', {}, config)
    server_conf.on_init = function(client, initialize_result)
      vim.notify('Initialized Language Server: ' .. name, vim.log.levels.INFO, { title = 'LSP' })
      if config.on_init then
        config.on_init(client, initialize_result)
      end
    end
    server_conf.before_init = function(params, client_config)
      if config.before_init then
        config.before_init(params, client_config)
      end
    end
    server_conf.on_exit = function(client, exit_code)
      vim.notify('De-Initialized Language Server: ' .. name, vim.log.levels.INFO, { title = 'LSP' })
      if config.on_exit then
        config.on_exit(client, exit_code)
      end
    end
    server_conf.capabilities = vim.tbl_extend('force', {}, capabilities, config.capabilities or {})
    -- server_conf.on_attach = function(client, bufnr)
    --   if client.server_capabilities.documentSymbolProvider then
    --     require('nvim-navic').attach(client, bufnr)
    --   end
    --   config.on_attach(client, bufnr)
    -- end,
    require('lspconfig')[name].setup(server_conf)
  end
end

local lazydev = {
  -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
  -- used for completion, annotations and signatures of Neovim apis
  'folke/lazydev.nvim',
  ft = 'lua',
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
