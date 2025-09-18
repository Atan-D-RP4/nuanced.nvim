return {
  lua_ls = {
    enabled = vim.fn.executable 'lua-language-server' == 1,
    filetypes = { 'lua' },
    settings = {
      Lua = {
        runtime = {
          version = 'LuaJIT',
          path = vim.split(package.path, ';'),
        },
        telemetry = { enable = false },
        completion = { callSnippet = 'Replace' },
        diagnostics = {
          disable = { 'missing-fields' },
          globals = { 'vim' },
        },
        workspace = {
          ignoreDir = { '.git', 'dist', 'build' },
          library = {
            vim.fs.joinpath '${3rd}/luv/library',
            vim.fn.expand '$VIMRUNTIME',
            vim.fn.stdpath 'config' .. '/lua',
            vim.fn.stdpath 'data' .. '/lazy/',
          },
          checkThirdParty = false,
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
          autoSearchPaths = true,
          diagnosticMode = 'openFilesOnly',
          useLibraryCodeForTypes = true,

          typeCheckingMode = 'strict',
          deprecateTypingAliases = true,
          diagnosticSeverityOverrides = { reportDeprecated = 'warning' },

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
            '--keep-logs',
            '--keep-intermediates',
          },

          onSave = true,
        },

        chktex = {
          onEdit = true,
          onOpenAndSave = true,
        },

        diagnosticsDelay = 300,
        latexFormatter = 'tex-fmt',
      },
    },
  },

  tinymist = {
    enabled = vim.fn.executable 'tinymist' == 1,

    settings = {
      formatterMode = 'typstyle',
      compileStatus = 'enable',
      fontPaths = { './' },
      exportPdf = 'onSave',
      semanticTokens = 'disable',
    },
  },

  denols = {
    enabled = vim.fn.executable 'deno' == 1,
    filetypes = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' },
  },

  rust_analyzer = {
    enabled = vim.fn.executable 'rust-analyzer' == 1,

    settings = {
      ['rust-analyzer'] = {
        cargo = {
          allFeatures = true,
          loadOutDirsFromCheck = true,
          buildScripts = { enable = true },
          targetDir = 'target/rust_analyzer',
        },

        imports = { granularity = { group = 'module' }, prefix = 'self' },
        checkOnSave = { command = 'clippy' }, -- Add "enabled = false", if you want to disable it
        diagnostics = {}, -- Add "enabled = false", if you want to disable them
      },
    },
  },

  clangd = { enabled = vim.fn.executable 'clangd' == 1 },

  hls = { enabled = vim.fn.executable 'haskell_language_server_wrapper' == 1 },

  elixirls = {
    cmd = { 'elixir-ls' },
    enabled = vim.fn.executable 'elixir-ls' == 1,
    ft = { 'elixir', 'eelixir' },
  },

  systemd_ls = {
    enabled = vim.fn.executable 'systemd-language-server' == 1,
    ft = { 'systemd' },
  },
}
