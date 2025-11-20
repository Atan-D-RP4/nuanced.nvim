local autocmd = vim.api.nvim_create_autocmd
local augroup = require('nuance.core.utils').augroup
local nmap = require('nuance.core.utils').nmap

local lspconfig = {
  'neovim/nvim-lspconfig',
  cmd = { 'LspStart', 'LspInfo', 'LspLog' },
  event = { 'Filetype' },

  -- stylua: ignore
  ft = {
    -- Web Languages
    'typescript', 'javascript', 'typescriptreact', 'javascriptreact', 'html', 'css',
    'elixir', 'heex',
    -- Script Languages
    'vim', 'lua', 'sh', 'python',
    -- Compiled Languages
    'c', 'cpp', 'rust', 'java',
    -- Document Filetypes
    'tex', 'typst',
    -- Data Filetypes
    'systemd', 'yaml', 'json',
  },

  ---@module 'lspconfig'
  ---@type lspconfig.Config
  opts = {},
}

autocmd('LspAttach', {
  group = augroup 'lsp-attach-mappings',
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      vim.notify('LSP client not found for id: ' .. tostring(args.data.client_id), vim.log.levels.WARN, { title = 'LSP' })
      return
    end

    local mappings = {
      { 'gO', '<cmd>lua Snacks.picker.lsp_symbols()<CR>', 'LSP Document [S]ymbols' },
      { 'gws', '<cmd>lua Snacks.picker.lsp_workspace_symbols()<CR>', 'LSP [W]orkspace [S]ymbols' },

      -- { 'gD', '<cmd>lua Snacks.picker.lsp_type_definitions()<CR>', 'LSP [T]ype [D]efinition' },
      -- { 'gd', '<cmd>lua Snacks.picker.lsp_definitions()<CR>', 'LSP [G]oto [D]efinition' },
      -- { 'grr', '<cmd>lua Snacks.picker.lsp_references()<CR>', 'LSP [G]oto [R]eferences' }, -- override `grr` mapping
      -- { 'gri', '<cmd>lua Snacks.picker.lsp_implementations()<CR>', 'LSP [G]oto [I]mplementation' }, -- override `gri` mapping
      { 'gD', '<cmd>lua require("goto-preview").goto_preview_type_definition()<CR>', 'LSP [T]ype [D]efinition' },
      { 'gd', '<cmd>lua require("goto-preview").goto_preview_definition()<CR>', 'LSP [G]oto [D]efinition' },
      { 'grr', '<cmd>lua require("goto-preview").goto_preview_references()<CR>', 'LSP [G]oto [R]eferences' }, -- override `grr` mapping
      { 'gri', '<cmd>lua require("goto-preview").goto_preview_implementation()<CR>', 'LSP [G]oto [I]mplementation' }, -- override `gri` mapping

      { 'grn', "<cmd>lua vim.lsp.buf.rename() vim.cmd [[ exec 'wa' ]]<CR>", 'LSP [R]ename' }, -- override `grn` mapping
      { 'gwd', '<cmd>lua vim.lsp.buf.workspace_diagnostics { client_id = ' .. client.id .. ' }<CR>', 'LSP [W]orkspace [D]iagnostics' },
    }

    vim.tbl_map(function(map)
      local key, rhs, desc = unpack(map)
      nmap(key, rhs, { desc = desc, buffer = bufnr })
    end, mappings)

    vim.api.nvim_set_hl(0, 'LspReferenceText', {})

    -- vim.opt_local.foldmethod = 'expr'
    -- vim.opt_local.foldexpr = 'v:lua.vim.lsp.foldexpr()'
    -- vim.opt_local.foldtext = 'v:lua.vim.lsp.foldtext()'
  end,
})

autocmd('LspAttach', {
  callback = function(event)
    local bufnr = event.buf
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client then
      vim.notify('LSP client not found for id: ' .. tostring(event.data.client_id), vim.log.levels.WARN, { title = 'LSP' })
      return
    end

    -- The following two autocommands are used to highlight references of the
    -- word under your cursor when your cursor rests there for a little while.
    -- When you move your cursor, the highlights will be cleared (the second autocommand).
    if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
      local highlight_augroup = augroup 'lsp-highlight'
      autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = bufnr,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = bufnr,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      autocmd('LspDetach', {
        buffer = bufnr,
        group = highlight_augroup,
        callback = function(ev)
          pcall(vim.api.nvim_clear_autocmds, { group = highlight_augroup, buffer = ev.buf })
        end,
      })
    end

    if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentColor) then
      local color_augroup = augroup 'lsp-color'

      autocmd('ColorScheme', {
        buffer = bufnr,
        group = color_augroup,
        callback = function(ev)
          vim.lsp.buf.clear_references()
          vim.lsp.document_color._buf_refresh(ev.buf, client.id)
        end,
      })

      autocmd('LspDetach', {
        buffer = bufnr,
        group = color_augroup,
        callback = function(ev)
          pcall(vim.api.nvim_clear_autocmds, { group = color_augroup, buffer = ev.buf })
        end,
      })
    end
  end,
})

---@module 'lspconfig'
---@param opts lspconfig.Config
lspconfig.config = function(_, opts) -- The '_' parameter is the entire lazy.nvim context
  -- Set the priority of the semantic tokens to be lower than
  -- that of Treesitter, so that Treesitter is always highlighting
  -- over LSP semantic tokens.
  vim.hl.priorities.semantic_tokens = 95

  if vim.version() >= vim.version { major = 0, minor = 12, patch = 0 } then
    vim.lsp.log.set_format_func(function(level, timestamp, message)
      -- Make message readable (handles tables)
      if vim.lsp.log.levels[level] < vim.lsp.log.levels.WARN then
        return nil
      end
      local msg = type(message) == 'table' and vim.inspect(message) or tostring(message)
      msg = msg:gsub('\t', '  ')
      return string.format('[%s] [%s] %s\n', level, timestamp, msg)
    end)
  end

  -- LSP servers and clients are able to communicate to each other what features they support.
  -- By default, Neovim doesn't support everything that is in the LSP specification.
  -- When you add nvim-cmp, luasnip, blink, etc. Neovim now has *more* capabilities.
  -- So, we create new capabilities with nvim-cmp or blink, and then broadcast that to the servers.

  -- LSP servers and clients are able to communicate to each other what features they support.
  -- By default, Neovim doesn't support everything that is in the LSP specification.
  -- When you add nvim-cmp, luasnip, blink, etc. Neovim now has *more* capabilities.
  -- So, we create new capabilities with nvim-cmp or blink, and then broadcast that to the servers.
  local has_blink, blink = pcall(require, 'blink.cmp')
  local capabilities = vim.tbl_deep_extend(
    'force',
    {},
    vim.lsp.protocol.make_client_capabilities(),
    has_blink and blink.get_lsp_capabilities() or {},
    opts.capabilities or {}
  )

  vim.lsp.config('*', {
    capabilities = capabilities,

    on_init = function(client, _initialize_result)
      local msg = 'Initialized Language Server: ' .. client.name
      if client.config.root_dir then
        msg = msg .. '\n' .. 'In root directory: ' .. client.config.root_dir
      end
      vim.notify(msg, vim.log.levels.INFO, { title = 'LSP' })

      if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_codeLens) then
        local codelens_augroup = augroup 'lsp-codelens'
        vim.b.codelens_enabled = vim.b.codelens_enabled or false

        nmap('<leader>tr', function()
          vim.b.codelens_enabled = not vim.b.codelens_enabled

          if vim.b.codelens_enabled then
            vim.lsp.codelens.refresh()

            autocmd({ 'BufEnter', 'CursorHold', 'InsertLeave' }, {
              group = codelens_augroup,
              callback = function()
                vim.lsp.codelens.refresh()
              end,
            })
          else
            pcall(vim.api.nvim_clear_autocmds, { group = codelens_augroup })
            vim.lsp.codelens.clear()
          end

          vim.notify(
            'LSP CodeLens ' .. (vim.b.codelens_enabled and 'Enabled' or 'Disabled'),
            (vim.b.codelens_enabled and vim.log.levels.INFO or vim.log.levels.WARN),
            { title = 'LSP' }
          )
        end, { desc = 'LSP [T]oggle [R]efresh CodeLens', noremap = false })

        autocmd('LspDetach', {
          group = codelens_augroup,
          callback = function(ev)
            pcall(vim.api.nvim_clear_autocmds, { group = codelens_augroup, buffer = ev.buf })
          end,
        })
      end

      if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
        nmap('<leader>th', function()
          vim.notify(
            'LSP Inlay Hints ' .. (vim.lsp.inlay_hint.is_enabled() and 'Disabled' or 'Enabled'),
            (vim.lsp.inlay_hint.is_enabled() and log_levels.WARN or log_levels.INFO),
            { title = 'LSP' }
          )
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
        end, { desc = 'LSP [T]oggle Inlay [H]ints', noremap = false })
      end

      local cleanup_group = augroup('lsp-detach-cleanup', { clear = false })
      autocmd('LspDetach', {
        group = cleanup_group,
        callback = function(ev)
          pcall(vim.api.nvim_clear_autocmds, { group = cleanup_group, buffer = ev.buf })
          vim.defer_fn(function()
            -- Kill the LS process if no buffers are attached to the client
            local cur_client = vim.lsp.get_client_by_id(ev.data.client_id)
            if cur_client == nil or cur_client.name == 'copilot' then
              return
            end
            if cur_client:is_stopped() then
              return
            end
            local attached_buffers_count = vim.tbl_count(cur_client.attached_buffers)
            if attached_buffers_count == 0 then
              local msg = 'No buffers attached to client: ' .. client.name .. '\n'
              msg = msg .. 'Stopping Server: ' .. client.name
              vim.notify(msg, vim.log.levels.INFO, { title = 'LSP' })
              cur_client:stop(true)
            end
          end, 3000)
        end,
      })
    end,

    -- before_init = function(_params, client_config)
    --   client_config.settings = configured_servers[client_config.name].settings or client_config.settings
    -- end,

    on_exit = function(_code, _signal, client_id)
      local client = vim.lsp.get_client_by_id(client_id)
      if not client then
        vim.notify('LSP client not found for id: ' .. tostring(client_id), vim.log.levels.WARN, { title = 'LSP' })
        return
      end

      for ns_id, ns in pairs(vim.diagnostic.get_namespaces()) do
        if ns.name and ns.name:match(client.name) then
          require('nuance.core.promise').async_promise(100, function()
            vim.diagnostic.reset(ns_id)
          end)
        end
      end

      vim.notify('De-Initialized Language Server: ' .. client.name, vim.log.levels.INFO, { title = 'LSP' })
    end,
  })

  for name, server in pairs(require 'nuance.core.lsps') do
    vim.tbl_map(function(key)
      vim.lsp.config(name, { [key] = server[key] })
    end, vim.tbl_keys(server)) -- just to avoid a warning from luacheck (unused variable '

    if not (server.enabled == nil) and (not server.enabled == false) then
      vim.lsp.enable(name)
    end
  end
end

local _lazydev = {
  -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
  -- used for completion, annotations and signatures of Neovim apis
  'folke/lazydev.nvim',
  ft = 'lua',
  dependencies = {
    -- { 'Bilal2453/luvit-meta', lazy = true },
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
  init = function()
    -- add binaries installed by mason.nvim to path
    local is_windows = vim.fn.has 'win32' ~= 0
    local sep = is_windows and '\\' or '/'
    local delim = is_windows and ';' or ':'
    vim.env.PATH = table.concat({ vim.fn.stdpath 'data', 'mason', 'bin' }, sep) .. delim .. vim.env.PATH
  end,
  config = function(_, opts)
    require('mason').setup(opts)
  end,
  cmd = { 'Mason', 'MasonInstall', 'MasonLog' },
} -- NOTE: Must be loaded before dependants

local rustowl = vim.fn.executable 'rustowl' == 1
    and {
      'cordx56/rustowl',
      -- lazy = false, -- This plugin is already lazy
      enabled = vim.fn.executable 'rustowl' == 1,
      ft = 'rust',
      dependencies = {
        lspconfig,
      },

      opts = {
        client = {
          on_attach = function(_, buffer)
            vim.keymap.set('n', '<C-l>', function()
              vim.cmd [[ exec 'silent! redraw' ]]
              require('rustowl').toggle(buffer)
            end, { buffer = buffer, desc = 'Toggle RustOwl' })
          end,
        },
      },
    }
  or nil

local tiny_inline_diagnostic = {
  'rachartier/tiny-inline-diagnostic.nvim',
  event = 'LspAttach',
  priority = 1000,
  config = function()
    -- Cache frequently used functions
    local buf_is_valid = vim.api.nvim_buf_is_valid
    local win_get_cursor = vim.api.nvim_win_get_cursor
    local diagnostic_get = vim.diagnostic.get
    local diagnostic_config = vim.diagnostic.config

    -- Clear old autocmds
    pcall(vim.api.nvim_clear_autocmds, { group = augroup 'diagnostic-float-or-virtlines-by-count' })

    -- Capture original virtual_text config before modifying
    local og_virt_text = diagnostic_config().virtual_text

    -- Configure diagnostics
    diagnostic_config {
      jump = { on_jump = nil },
      virtual_text = true,
      virtual_lines = false,
    }

    autocmd('CursorHold', {
      group = augroup 'tiny-inline-diagnostic-cursorhold',
      callback = function(ev)
        -- Fast validation
        if not buf_is_valid(ev.buf) or not vim.diagnostic.is_enabled() then
          return
        end

        -- Safely get cursor position
        local ok, cursor = pcall(win_get_cursor, 0)
        if not ok or cursor == nil then
          return
        end

        local lnum = cursor[1]
        if lnum == nil then
          return
        end
        lnum = lnum - 1 -- 0-indexed
        local diagnostic_count = #diagnostic_get(ev.buf, { lnum = lnum })

        if diagnostic_count > 0 then
          pcall(diagnostic_config, { virtual_text = false })
        else
          -- Reset to original virtual_text state
          pcall(diagnostic_config, { virtual_text = og_virt_text })
        end
      end,
    })

    require('tiny-inline-diagnostic').setup {
      preset = 'powerline',
      options = {
        -- Display the source of diagnostics (e.g., "lua_ls", "pyright")
        show_source = { enabled = true }, -- Enable showing source names
        -- Automatically disable diagnostics when opening diagnostic float windows
        override_open_float = true,
        -- Display related diagnostics from LSP related information
        show_related = { enabled = true },
        -- Use icons from vim.diagnostic.config instead of preset icons
        use_icons_from_diagnostic = true,
        -- Color the arrow to match the severity of the first diagnostic
        set_arrow_to_diag_color = true,
        format = function(diag)
          return string.format('[%s] %s', diag.code, diag.message)
        end,
      },
    }
  end,
}

local goto_preview = {
  'rmagatti/goto-preview',
  -- dependencies = { 'rmagatti/logger.nvim' },
  event = 'LspAttach',
  config = true, -- necessary as per https://github.com/rmagatti/goto-preview/issues/88

  opts = {
    references = { -- Configure the UI for slowing the references cycling window.
      provider = 'snacks', -- telescope|fzf_lua|snacks|mini_pick|default
    },

    post_open_hook = function(bufnr, _win_id)
      -- Close the preview window on `q`
      vim.keymap.set('n', 'q', '<cmd>close<CR>', { buffer = bufnr, silent = true })
    end,
  },
}

return {
  mason,
  -- lazydev,
  lspconfig,
  tiny_inline_diagnostic,
  goto_preview,
  rustowl,
}

-- vim: ts=2 sts=2 sw=2 et
