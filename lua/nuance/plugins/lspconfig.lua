local lspconfig = {
  'neovim/nvim-lspconfig',
  cmd = { 'LspStart', 'LspInfo', 'LspLog' },
  event = { 'Filetype', 'LspAttach' },

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
    'systemd',
  },

  dependencies = {
    'artemave/workspace-diagnostics.nvim',
  },

  ---@module 'lspconfig'
  ---@type lspconfig.Config
  opts = {},
}

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      vim.notify('LSP client not found for id: ' .. tostring(args.data.client_id), vim.log.levels.WARN, { title = 'LSP' })
      return
    end
    local bufnr = args.buf
    -- Set the priority of the semantic tokens to be lower than
    -- that of Treesitter, so that Treesitter is always highlighting
    -- over LSP semantic tokens.
    vim.hl.priorities.semantic_tokens = 95

    vim.lsp.log.set_level(vim.log.levels.INFO)
    vim.lsp.log.set_format_func(function(log)
      local msg = vim.inspect(log)
      msg = msg:gsub('\t', '  ')
      return msg:gsub('\n', '\n')[1]
    end)

    local mappings = {
      { 'gws', '<cmd>lua Snacks.picker.lsp_workspace_symbols()<CR>', 'LSP [W]orkspace [S]ymbols' },
      { 'gD', '<cmd>lua Snacks.picker.lsp_type_definitions()<CR>', 'LSP [T]ype [D]efinition' },
      { 'gus', '<cmd>lua Snacks.picker.lsp_symbols()<CR>', 'LSP [D]ocument [S]ymbols' },
      { 'gd', '<cmd>lua Snacks.picker.lsp_definitions()<CR>', 'LSP [G]oto [D]efinition' },
      -- Save all buffers after renaming
      { 'grn', "<cmd>lua vim.lsp.buf.rename() vim.cmd [[ exec 'wa' ]]<CR>", 'LSP [R]ename' }, -- override `grn` mapping
      { 'grr', '<cmd>lua Snacks.picker.lsp_references()<CR>', 'LSP [G]oto [R]eferences' }, -- override `grr` mapping
      { 'gri', '<cmd>lua Snacks.picker.lsp_implementations()<CR>', 'LSP [G]oto [I]mplementation' }, -- override `gri` mapping
      { 'gs', '<cmd>lua Snacks.picker.lsp_symbols({ layout = { preset = "vscode", preview = "main" } })<CR>', 'LSP Document [S]ymbols' },
    }

    local nmap = require('nuance.core.utils').nmap
    vim.tbl_map(function(map)
      local key, rhs, desc = unpack(map)
      nmap(key, rhs, { desc = desc, buffer = bufnr })
    end, mappings)

    if not client or not client.server_capabilities then
      vim.notify('LSP client not found or does not have server capabilities', vim.log.levels.WARN, { title = 'LSP' })
      return
    end

    vim.api.nvim_set_hl(0, 'LspReferenceText', {})

    -- vim.opt_local.foldmethod = 'expr'
    -- vim.opt_local.foldexpr = 'v:lua.vim.lsp.foldexpr()'
    -- vim.opt_local.foldtext = 'v:lua.vim.lsp.foldtext()'
  end,
})

---@module 'lspconfig'
---@param opts lspconfig.Config
lspconfig.config = function(_, opts) -- The '_' parameter is the entire lazy.nvim context
  -- LSP servers and clients are able to communicate to each other what features they support.nvim-config/blob/main/.luarc.json
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

  local configured_servers = vim.g.configured_servers or {}

  vim.lsp.config('*', {
    capabilities = capabilities,

    on_init = function(client, initialize_result)
      local msg = 'Initialized Language Server: ' .. client.name
      msg = msg .. '\n' .. 'In root directory: ' .. client.config.root_dir
      vim.notify(msg, vim.log.levels.INFO, { title = 'LSP' })

      local augroup = require('nuance.core.utils').augroup

      -- The following two autocommands are used to highlight references of the
      -- word under your cursor when your cursor rests there for a little while.
      -- When you move your cursor, the highlights will be cleared (the second autocommand).
      if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
        local highlight_augroup = augroup('lsp-highlight', { clear = true })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })

        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          group = highlight_augroup,
          callback = vim.lsp.buf.clear_references,
        })

        vim.api.nvim_create_autocmd('LspDetach', {
          group = highlight_augroup,
          callback = function(ev)
            vim.api.nvim_clear_autocmds { group = highlight_augroup, buffer = ev.buf }
          end,
        })
      end

      if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentColor) then
        local color_augroup = augroup('lsp-color', { clear = true })
        vim.api.nvim_create_autocmd('ColorScheme', {
          group = color_augroup,
          callback = function(ev)
            vim.lsp.buf.clear_references()
            vim.lsp.document_color._buf_refresh(ev.buf, client.id)
          end,
        })
        vim.api.nvim_create_autocmd('LspDetach', {
          group = color_augroup,
          callback = function(ev)
            vim.api.nvim_clear_autocmds { group = color_augroup, buffer = ev.buf }
          end,
        })
      end

      if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_codeLens) then
        vim.print('LSP ' .. client.name .. ' supports codeLens')
        local codelens_augroup = augroup('lsp-codelens', { clear = true })
        local state = 0
        require('nuance.core.utils').nmap('<leader>tr', function()
          if state == 0 then
            vim.lsp.codelens.clear()
            vim.notify('LSP CodeLens disabled', vim.log.levels.WARN, { title = 'LSP' })
            state = 1
          else
            vim.lsp.codelens.refresh()
            vim.notify('LSP CodeLens enabled', vim.log.levels.INFO, { title = 'LSP' })
            state = 0
          end
        end, { desc = 'LSP [T]oggle [C]odeLens', noremap = false })
        vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'InsertLeave' }, {
          group = codelens_augroup,
          callback = function()
            if state == 0 then
              vim.lsp.codelens.refresh()
            end
          end,
        })
        vim.api.nvim_create_autocmd('LspDetach', {
          group = codelens_augroup,
          callback = function(ev)
            vim.api.nvim_clear_autocmds { buffer = ev.buf, group = codelens_augroup }
          end,
        })
      end

      local cleanup_group = augroup('lsp-detach-cleanup', { clear = false })
      vim.api.nvim_create_autocmd('LspDetach', {
        group = cleanup_group,
        callback = function(ev)
          vim.api.nvim_clear_autocmds { group = cleanup_group, buffer = ev.buf }
          vim.defer_fn(function()
            -- Kill the LS process if no buffers are attached to the client
            local cur_client = vim.lsp.get_client_by_id(ev.data.client_id)
            if cur_client == nil or cur_client.name == 'copilot' then
              return
            end
            local attached_buffers_count = vim.tbl_count(cur_client.attached_buffers)
            if attached_buffers_count == 0 then
              cur_client:stop(true)
            end
          end, 200)
        end,
      })

      if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
        require('nuance.core.utils').nmap('<leader>th', function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
        end, { desc = 'LSP [T]oggle Inlay [H]ints', noremap = false })
      end

      require('workspace-diagnostics').populate_workspace_diagnostics(client, 0)
    end,

    before_init = function(params, client_config)
      client_config.settings = configured_servers[client_config.name].settings or client_config.settings
    end,

    on_exit = function(code, signal, client_id)
      local name = vim.lsp.get_client_by_id(client_id).name
      local msg = 'No buffers attached to client: ' .. name .. '\n'
      msg = msg .. 'Stopping Server: ' .. name
      vim.notify(msg, vim.log.levels.INFO, { title = 'LSP' })
      vim.notify('De-Initialized Language Server: ' .. name, vim.log.levels.INFO, { title = 'LSP' })
    end,
  })

  for name, server in pairs(configured_servers) do
    vim.lsp.config(name, {
      settings = server.settings or {},
      filetypes = server.filetypes or nil,
      on_init = server.on_init or nil,
      before_init = server.before_init or nil,
      on_exit = server.on_exit or nil,
    })
    if not (server.enabled == nil) and (not server.enabled == false) then
      vim.lsp.enable(name)
    end
  end
end

local lazydev = {
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

local rustowl = {
  'cordx56/rustowl',
  -- lazy = false, -- This plugin is already lazy
  enabled = vim.fn.executable 'rustowl' == 1,
  ft = 'rust',
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

return {
  mason,
  lazydev,
  lspconfig,
  rustowl,
}

-- vim: ts=2 sts=2 sw=2 et
