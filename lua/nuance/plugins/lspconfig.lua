local autocmd = vim.api.nvim_create_autocmd
local augroup = require('nuance.core.utils').augroup
local nmap = require('nuance.core.utils').nmap
local log_levels = (vim.lsp.log.levels or vim.log.levels)

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
  desc = 'LSP Attach Mappings',
  group = augroup 'lsp-attach-mappings',
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      vim.notify('LSP client not found for id: ' .. tostring(args.data.client_id), log_levels.WARN, { title = 'LSP' })
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
  desc = 'LSP Attach Highlights and Colors',
  group = augroup 'lsp-attach-highlights-and-colors',
  callback = function(event)
    local bufnr = event.buf
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client then
      vim.notify('LSP client not found for id: ' .. tostring(event.data.client_id), log_levels.WARN, { title = 'LSP' })
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
        callback = function()
          pcall(vim.api.nvim_clear_autocmds, { group = highlight_augroup, buffer = bufnr })
        end,
      })
    end

    if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentColor) then
      local color_augroup = augroup 'lsp-color'

      autocmd('ColorScheme', {
        buffer = bufnr,
        group = color_augroup,
        callback = function()
          vim.lsp.buf.clear_references()
        end,
      })

      autocmd('LspDetach', {
        buffer = bufnr,
        group = color_augroup,
        callback = function()
          pcall(vim.api.nvim_clear_autocmds, { group = color_augroup, buffer = bufnr })
        end,
      })
    end
  end,
})

autocmd('LspProgress', {
  callback = function(ev)
    local value = ev.data.params.value
    vim.api.nvim_echo({ { value.message or 'done' } }, false, {
      id = 'lsp.' .. ev.data.client_id,
      kind = 'progress',
      source = 'vim.lsp',
      title = value.title,
      status = value.kind ~= 'end' and 'running' or 'success',
      percent = value.percentage,
    })
  end,
})

---@module 'lspconfig'
---@param opts lspconfig.Config
lspconfig.config = function(_, opts) -- The '_' parameter is the entire lazy.nvim context
  -- Set the priority of the semantic tokens to be lower than
  -- that of Treesitter, so that Treesitter is always highlighting
  -- over LSP semantic tokens.
  vim.hl.priorities.semantic_tokens = 95

  if vim.version.ge(vim.version(), { 0, 12 }) then
    vim.lsp.log.set_format_func(function(level, timestamp, msg)
      local curr_log_level = log_levels[level] or log_levels.INFO

      if curr_log_level < vim.lsp.log.get_level() then
        return nil
      end

      if type(msg) == 'table' then
        msg = vim.inspect(msg, {
          newline = ' ',
          indent = '',
        })
      end

      msg = tostring(msg):gsub('\t', '  ')

      return string.format('[%s][%s] %s\n', log_levels[curr_log_level] or curr_log_level, timestamp or '', msg)
    end)
  end

  local orig_open_floating_preview = vim.lsp.util.open_floating_preview

  ---@diagnostic disable-next-line: duplicate-set-field
  vim.lsp.util.open_floating_preview = function(contents, syntax, float_opts)
    opts = vim.tbl_extend('force', {
      border = 'rounded',
    }, float_opts or {})

    local bufnr, winnr = orig_open_floating_preview(contents, syntax, opts)

    -- The critical part: enable concealment so ``` fences are hidden
    -- and markdown_inline TS highlights (bold, italic, code spans) render
    vim.schedule(function()
      if winnr and vim.api.nvim_win_is_valid(winnr) then
        vim.wo[winnr].wrap = true
        vim.wo[winnr].linebreak = true
        vim.wo[winnr].conceallevel = 2
        vim.wo[winnr].linebreak = true
      end

      local ns = vim.api.nvim_create_namespace 'nuance_hover_fence_conceal'
      vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      for i = 1, #lines do
        if lines[i]:match '^%s*```' then
          vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, 0, {
            end_col = #lines[i],
            conceal_lines = '',
            hl_mode = 'combine',
            hl_group = 'Italic',
          })
        end
      end

      vim.treesitter.start(bufnr, syntax or 'markdown')
      vim.bo[bufnr].syntax = 'ON' -- only if additional legacy syntax is needed
    end)

    return bufnr, winnr
  end

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

  local lsps_ok, lsps = pcall(require, 'nuance.core.lsps')
  if not lsps_ok then
    vim.notify('Failed to load LSP configs: ' .. tostring(lsps), log_levels.ERROR, { title = 'LSP' })
    return
  end

  for name, server in pairs(lsps) do
    if server.enabled ~= nil and server.enabled ~= false then
      vim.lsp.enable(name)
    end

    vim.tbl_map(function(cb_name)
      local cb = vim.lsp.config[name][cb_name]
      if cb then
        vim.lsp.config(name, {
          [cb_name] = {
            lspconfig = cb,
          },
        })
      end
    end, { 'on_attach', 'on_init', 'on_exit' })

    vim.tbl_map(function(key)
      vim.lsp.config(name, { [key] = server[key] })
    end, vim.tbl_keys(server))
  end

  vim.lsp.config('*', {
    capabilities = capabilities,

    on_init = {
      ---@param client vim.lsp.Client,
      global = function(client, _initialize_result)
        local msg = 'Initialized Language Server: ' .. client.name
        if client.config.root_dir then
          msg = msg .. '\n' .. 'In root directory: ' .. client.config.root_dir
        end
        vim.notify(msg, log_levels.INFO, { title = 'LSP' })

        if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_codeLens) then
          nmap('<leader>tr', function()
            local enabled = vim.lsp.codelens.is_enabled()
            vim.notify('LSP CodeLens ' .. (not enabled and 'Enabled' or 'Disabled'), (enabled and log_levels.INFO), { title = 'LSP' })
            vim.lsp.codelens.enable(not enabled)
          end, { desc = 'LSP [T]oggle CodeLens', noremap = false })
        end

        if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
          nmap('<leader>th', function()
            vim.notify(
              'LSP Inlay Hints ' .. (vim.lsp.inlay_hint.is_enabled() and 'Disabled' or 'Enabled'),
              (vim.lsp.inlay_hint.is_enabled() and vim.log.levels.WARN or vim.log.levels.INFO),
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
                local _msg = 'No buffers attached to client: ' .. client.name .. '\n'
                _msg = _msg .. 'Stopping Server: ' .. client.name
                vim.notify(_msg, log_levels.INFO, { title = 'LSP' })
                cur_client:stop(true)
              end
            end, 3000)
          end,
        })
      end,
    },

    on_exit = {
      global = function(_code, _signal, client_id)
        vim.schedule(function()
          local client = vim.lsp.get_client_by_id(client_id)
          if not client then
            vim.notify('LSP client not found for id: ' .. tostring(client_id), log_levels.WARN, { title = 'LSP' })
            return
          end

          for ns_id, ns in pairs(vim.diagnostic.get_namespaces()) do
            if ns.name and ns.name:match(client.name) then
              require('nuance.core.promise')
                .async_promise(100, function()
                  vim.schedule_wrap(function()
                    vim.notify('Resetting diagnostics for namespace: ' .. ns.name, log_levels.INFO, { title = 'LSP' })
                    vim.diagnostic.reset(ns_id)
                  end)()
                end)
                :catch(function(err)
                  vim.notify(
                    'Failed to reset diagnostics for namespace: ' .. ns.name .. '\nError: ' .. tostring(err),
                    log_levels.ERROR,
                    { title = 'LSP' }
                  )
                end)
            end
          end

          vim.notify('De-Initialized Language Server: ' .. client.name, log_levels.INFO, { title = 'LSP' })
        end)
      end,
    },
  })
end

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
      build = 'cargo binstall rustowl',

      dependencies = {
        lspconfig,
      },

      opts = {
        client = {
          -- cmd = vim.lsp.rpc.connect('127.0.0.1', 27631),
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
          vim.notify('Cursor line number should not be nil after successful get_cursor', vim.log.levels.ERROR, { title = 'LSP' })
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
  lspconfig,
  tiny_inline_diagnostic,
  goto_preview,
  rustowl,
}

-- vim: ts=2 sts=2 sw=2 et
