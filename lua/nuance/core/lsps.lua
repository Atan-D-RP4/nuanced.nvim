--- rust-analyzer custom join lines command (reference implementation)
-- local ra_join_lines = function(client_id, visual)
--   local client = vim.lsp.get_client_by_id(client_id)
--   if not client then
--     return
--   end
--   local vis = false or visual
--   local encoding = client.offset_encoding or 'utf-8'

--   local modify_params = function(params)
--     local range = params.range
--     params.range = nil
--     ---@diagnostic disable-next-line: inject-field
--     params.ranges = { range }
--     ---@diagnostic disable-next-line: return-type-mismatch
--     return param
--   end

--   vim.lsp.buf_request(
--     0,
--     'experimental/joinLines',
--     modify_params(vis == true and vim.lsp.util.make_given_range_params(nil, nil, 0, encoding) or vim.lsp.util.make_visual_params(0, encoding)),
--     function(_, result, ctx)
--       if result == nil or vim.tbl_isempty(result) then
--         return
--       end
--       local client = vim.lsp.get_client_by_id(ctx.client_id)
--       if not client then
--         return
--       end
--       vim.lsp.util.apply_text_edits(result, ctx.bufnr, encoding)
--     end
--   )
-- end
-- vim.api.nvim_create_user_command('RustJoinLines', function(args)
--   ra_join_lines(client.id, args.range ~= -1)
-- end, { range = true, nargs = '?' })
---
-- Rust-analyzer custom runnables command (reference implementation)
-- local ra_list_runnables = function(client_id)
--   vim.lsp.buf_request(client_id, 'experimental/runnables', {
--     textDocument = vim.lsp.util.make_text_document_params(0),
--     position = nil, -- get em all
--   }, function(_, runnables)
--     vim.print(runnables)
--   end)
-- end
---

---@type table<string, vim.lsp.ClientConfig>
return {
  emmylua_ls = {
    enabled = vim.fn.executable 'emmylua_ls' == 1,
    filetypes = { 'lua' },

    settings = {
      Lua = {
        runtime = {
          version = 'LuaJIT',
          path = vim.split(package.path, ';'),
        },

        telemetry = { enable = false },
        hint = { enable = true, setType = true },
        codeLens = { enable = true },
        completion = { callSnippet = 'Replace' },

        diagnostics = {
          enable = true,

          disable = {
            'missing-fields',
            'param-type-mismatch',
            'param-type-not-match',
            'assign-type-mismatch',
          },

          globals = { 'vim' },
        },

        workspace = {
          library = {
            vim.fn.expand '$VIMRUNTIME',
            vim.fn.stdpath 'config' .. '/lua',
            vim.fn.stdpath 'data' .. '/lazy/',
            vim.fs.joinpath '${3rd}/luv/library',
          },

          enableReindex = true,
          reindexDuration = 10000,
          ignoreDir = { '.git', 'dist', 'build' },
          checkThirdParty = true,
        },

        format = {
          enable = false,
          -- defaultConfig = {
          --   indent_style = 'space',
          --   indent_size = '2',
          -- },
        },
      },
    },
  },

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
        hint = { enable = true, setType = true },
        codeLens = { enable = true },
        completion = { callSnippet = 'Replace' },

        diagnostics = {
          disable = { 'missing-fields' },
          globals = { 'vim' },
        },

        workspace = {
          ignoreDir = { '.git', 'dist', 'build' },
          checkThirdParty = false,
        },

        format = {
          enable = false,
          -- defaultConfig = {
          --   max_line_length = 180,
          --   indent_style = 'space',
          --   indent_size = '2',
          --   continuation_indent_size = '2',
          --   call_arg_parentheses = 'keep',
          --   space_before_inline_comment = 2,
          --   quote_style = 'single',

          --   align_call_args = false,
          --   align_continuous_line_space = 0,
          --   align_continuous_inline_comment = false,
          --   align_function_params = false,
          --   align_continuous_assign_statement = false,
          --   align_continuous_rect_table_field = 'none',
          --   align_if_branch = false,
          --   align_array_table = false,
          -- },
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

  bashls = {
    enabled = vim.fn.executable 'deno' == 1,
    cmd = { 'deno', 'run', '-A', 'npm:bash-language-server', 'start' },
  },

  html = {
    enabled = vim.fn.executable 'deno' == 1,
    cmd = { 'deno', 'run', '-A', 'npm:vscode-langservers-extracted/vscode-html-language-server', '--stdio' },
  },

  emmet_language_server = {
    enabled = vim.fn.executable 'deno' == 1,
    cmd = { 'deno', 'run', '-A', 'npm:@olrtg/emmet-language-server', '--stdio' },
    filetypes = { 'html', 'css', 'scss', 'less', 'javascriptreact', 'typescriptreact' },
  },

  cssls = {
    enabled = vim.fn.executable 'deno' == 1,
    cmd = { 'deno', 'run', '-A', 'npm:vscode-langservers-extracted/vscode-css-language-server', '--stdio' },
    before_init = function(init_params, _)
      ---@diagnostic disable-next-line: need-check-nil
      init_params.capabilities.textDocument.completion.completionItem.snippetSupport = true
    end,
  },

  jsonls = {
    enabled = vim.fn.executable 'deno' == 1,
    cmd = { 'deno', 'run', '-A', 'npm:vscode-langservers-extracted/vscode-json-language-server', '--stdio' },
    before_init = function(init_params, _)
      ---@diagnostic disable-next-line: need-check-nil
      init_params.capabilities.textDocument.completion.completionItem.snippetSupport = true
    end,
  },

  svelte = {
    enabled = vim.fn.executable 'deno' == 1,
    cmd = { 'deno', 'run', '-A', 'npm:svelte-language-server', '--stdio', '--no-color' },
    filetypes = { 'svelte' },
  },

  vimls = {
    enabled = vim.fn.executable 'deno' == 1,
    cmd = { 'deno', 'run', '-A', 'npm:vim-language-server', '--stdio' },
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

  zuban = {
    enabled = false and vim.fn.executable 'uv' == 1,
    cmd = { 'uv', 'tool', 'run', 'zuban', 'server' },
  },

  ty = {
    enabled = false and vim.fn.executable 'uv' == 1,
    cmd = { 'uv', 'tool', 'run', 'ty', 'server' },
  },

  pyrefly = {
    enabled = true and vim.fn.executable 'uv' == 1,
    cmd = { 'uv', 'tool', 'run', 'pyrefly', 'lsp' },
  },

  ruff = {
    enabled = true and vim.fn.executable 'uv' == 1,
    cmd = { 'uv', 'tool', 'run', 'ruff', 'server' },

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

    on_init = {
      spec = function(client, _)
        client.server_capabilities.hoverProvider = false
        client.settings.python = vim.tbl_extend('force', client.settings.python or {}, {
          pythonPath = require('nuance.core.utils').get_python_path(client.root_dir),
        })
      end,
    },
  },

  jedi_language_server = {
    enabled = false and vim.fn.executable 'uv' == 1,
    cmd = { 'uv', 'tool', 'run', 'jedi-language-server' },

    before_init = function(_, config)
      local pythonPath = require('nuance.core.utils').get_python_path(config.root_dir)
      ---@diagnostic disable-next-line: need-check-nil
      config.init_options.workspace.pythonPath = pythonPath
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
    enabled = vim.fn.executable 'basedpyright-langserver' == 1,

    on_init = {
      spec = function(client, _)
        client.settings.python = vim.tbl_extend('force', client.settings.python or {}, {
          pythonPath = require('nuance.core.utils').get_python_path(client.root_dir),
        })
      end,
    },

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
      fontPaths = { './' },
      formatterPrintWidth = vim.o.textwidth,
      formatterIndentSize = vim.o.shiftwidth,
      exportPdf = 'onType',
      semanticTokens = 'disable',

      preview = { background = { enabled = true } },

      lint = {
        enable = true,
        when = 'onSave',
      },
    },

    on_attach = {
      spec = function(client, bufnr)
        vim.api.nvim_buf_create_user_command(bufnr, 'LspTinymistPreview', function()
          client:exec_cmd({
            title = 'Start Tinymist Preview',
            command = 'tinymist.startDefaultPreview',
            arguments = { vim.api.nvim_buf_get_name(0) },
          }, { bufnr = bufnr })
        end, { desc = 'Start Tinymist Preview', nargs = 0 })
      end,
    },
  },

  denols = {
    enabled = vim.fn.executable 'deno' == 1,
    root_markers = { 'deno.json', 'deno.jsonc', 'deno.lock', 'package.json' },

    root_dir = function(bufnr, on_dir)
      local config = vim.lsp.config.denols
      local root_markers = config.root_markers or { 'deno.json', 'deno.jsonc' }

      -- Lockfiles exclusive to Node.js package managers
      local node_lockfiles = { 'package-lock.json', 'yarn.lock', 'pnpm-lock.yaml', 'bun.lockb', 'bun.lock' }

      -- If user added a node lockfile to root_markers, don't exclude on it
      local root_set = {}
      for _, m in ipairs(root_markers) do
        root_set[m] = true
      end
      local exclude_markers = vim.tbl_filter(function(m)
        return not root_set[m]
      end, node_lockfiles)

      -- Append .git as lowest-priority fallback
      root_markers = vim.fn.has 'nvim-0.11.3' == 1 and { root_markers, { '.git' } } or vim.list_extend(vim.deepcopy(root_markers), { '.git' })

      local project_root = vim.fs.root(bufnr, root_markers)
      local excluded_root = #exclude_markers > 0 and vim.fs.root(bufnr, exclude_markers) or nil

      -- Skip if a Node.js lockfile is found at same or deeper level than project root
      if excluded_root and (not project_root or #excluded_root >= #project_root) then
        return
      end

      on_dir(project_root or vim.fn.getcwd())
    end,
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

        inlayHints = {
          closureCaptureHints = { enable = true },
          closureReturnTypeHints = { enable = true },
          genericParameterHints = {
            lifetimeElisionHints = { enable = true },
            implicitSizedBoundHints = { enable = true },
            type = { enable = true },
            lifetime = { enable = true },
          },
        },

        lens = {
          enable = true,
          references = {
            adt = { enable = true },
            method = { enable = true },
            trait = { enable = true },
            enumVariant = { enable = true },
          },
        },
        -- highlightRelated = { enable = true },

        imports = { granularity = { group = 'module' }, prefix = 'self' },
        checkOnSave = { command = 'clippy' }, -- Add "enabled = false", if you want to disable it
        diagnostics = {}, -- Add "enabled = false", if you want to disable them
      },
    },
  },

  clangd = { enabled = vim.fn.executable 'clangd' == 1 },

  hls = { enabled = vim.fn.executable 'haskell_language_server_wrapper' == 1 },

  elixirls = {
    enabled = vim.fn.executable 'elixir-ls' == 1,
    cmd = { 'elixir-ls' },
    ft = { 'elixir', 'eelixir' },
  },

  systemd_ls = {
    enabled = vim.fn.executable 'uv' == 1,
    cmd = { 'uv', 'tool', 'run', 'systemd-language-server' },
    ft = { 'systemd' },
  },

  yamlls = {
    enabled = vim.fn.executable 'deno' == 1,
    cmd = { 'deno', 'run', '-A', 'npm:yaml-language-server', '--stdio' },
  },
}
