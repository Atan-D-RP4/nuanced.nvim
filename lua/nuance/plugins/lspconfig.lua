local lspconfig = {
  'neovim/nvim-lspconfig',
  cmd = { 'LspStart', 'LspInfo', 'LspLog' },

  ft = {
    -- Web Languages
    'typescript', 'javascript', 'typescriptreact', 'javascriptreact', 'html', 'css',
    -- Script Languages
    'vim', 'lua', 'sh', 'python',
    -- Compiled Languages
    'c', 'cpp', 'rust', 'java',
    -- Document Filetypes
    'tex', 'typst',
  },

  ---@module 'lspconfig'
  ---@type lspconfig.Config
  opts = {},
}

---@param client vim.lsp.Client
---@param bufnr number
local on_attach = function(client, bufnr)
  -- Set the priority of the semantic tokens to be lower than
  -- that of Treesitter, so that Treesitter is always highlighting
  -- over LSP semantic tokens.
  vim.highlight.priorities.semantic_tokens = 95

  vim.lsp.set_log_level(vim.log.levels.INFO)
  vim.lsp.log.set_format_func(function(args)
    local msg = vim.inspect(args)
    msg = msg:gsub('\t', '  ')
    return msg:gsub('\n', '\n')[1]
  end)

  local mappings = {
    { 'gws', '<cmd>lua Snacks.picker.lsp_workspace_symbols()<CR>', 'LSP [W]orkspace [S]ymbols' },
    { 'gd', '<cmd>lua Snacks.picker.lsp_type_definitions()<CR>', 'LSP [T]ype [D]efinition' },
    { 'gus', '<cmd>lua Snacks.picker.lsp_symbols()<CR>', 'LSP [D]ocument [S]ymbols' },
    { 'gd', '<cmd>lua Snacks.picker.lsp_definitions()<CR>', 'LSP [G]oto [D]efinition' },
    {
      'grn',
      function()
        vim.lsp.buf.rename()
        -- Save all buffers after renaming
        vim.cmd [[ exec 'wa' ]]
      end,
      'LSP [R]ename',
    }, -- override `grn` mapping
    { 'grr', '<cmd>lua Snacks.picker.lsp_references()<CR>', 'LSP [G]oto [R]eferences' }, -- override `grr` mapping
    { 'gri', '<cmd>lua Snacks.picker.lsp_implementations()<CR>', 'LSP [G]oto [I]mplementation' }, -- override `gri` mapping
    { 'gs', '<cmd>lua Snacks.picker.lsp_symbols({layout = {preset = "vscode", preview = "main"}})<CR>', 'LSP Document [S]ymbols' },
    (client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, bufnr)) and {
      '<leader>th',
      '<cmd>lua vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = vim.api.nvim_get_current_buf() }) <CR>',
      'LSP [T]oggle Inlay [H]ints',
    } or nil,
  }

  local nmap = require('nuance.core.utils').nmap
  vim.tbl_map(function(map)
    local key = map[1]
    local rhs = map[2]
    local opts = map[3] or {}
    if type(opts) == 'string' then
      opts = { desc = opts }
    end
    opts = vim.tbl_deep_extend('force', { buffer = bufnr }, opts)
    nmap(key, rhs, opts)
  end, mappings)

  if not client or not client.server_capabilities then
    vim.notify('LSP client not found or does not have server capabilities', vim.log.levels.WARN, { title = 'LSP' })
    return
  end

  -- The following two autocommands are used to highlight references of the
  -- word under your cursor when your cursor rests there for a little while.
  -- When you move your cursor, the highlights will be cleared (the second autocommand).
  local augroup = require('nuance.core.utils').augroup
  if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, bufnr) then
    local highlight_augroup = augroup('lsp-highlight', { clear = true })
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
        vim.api.nvim_clear_autocmds { group = highlight_augroup, buffer = ev.buf }
      end,
    })
  end

  if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentColor, bufnr) then
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
          local msg = 'No attached buffers to client: ' .. cur_client.name .. '\n'
          msg = msg .. 'Stopping Server: ' .. cur_client.name
          vim.notify(msg, vim.log.levels.INFO, { title = 'LSP' })
          cur_client:stop(true)
        end
      end, 200)
    end,
  })

  vim.api.nvim_set_hl(0, 'LspReferenceText', {})

  -- vim.opt_local.foldmethod = 'expr'
  -- vim.opt_local.foldexpr = 'v:lua.vim.lsp.foldexpr()'
  -- vim.opt_local.foldtext = 'v:lua.vim.lsp.foldtext()'
end

---@param client vim.lsp.Client
local function trigger_workspace_diagnostics(client)
  local supported_fts = client.config.filetypes
  if supported_fts and type(supported_fts) ~= 'table' then
    supported_fts = { supported_fts }
  end
  local ft_set = supported_fts and vim.tbl_add_reverse_lookup(vim.tbl_extend('force', {}, supported_fts)) or nil

  for _, file in ipairs(require('nuance.core.utils').get_workspace_files(client)) do
    local ft = vim.filetype.match { filename = file }
    if not ft_set or ft_set[ft] then
      local params = {
        textDocument = {
          uri = vim.uri_from_fname(file),
          languageId = ft,
          version = 0,
          text = table.concat(vim.fn.readfile(file), '\n'),
        },
      }
      ---@diagnostic disable-next-line: unused-local
      local status = client.notify(vim.lsp.protocol.Methods.textDocument_didOpen, params)
    end
  end
  vim.notify('Workspace diagnostics queued for LSP client: ' .. client.name, vim.log.levels.INFO, { title = 'LSP' })
end

---@module 'lspconfig'
---@param opts lspconfig.Config
lspconfig.config = function(_, opts) -- The '_' parameter is the entire lazy.nvim context
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
  local lsp_conf = require 'lspconfig'
  local configured_servers = vim.g.configured_servers or {}

  for name, server in pairs(configured_servers) do
    ---@type vim.lsp.ClientConfig
    local server_conf = vim.tbl_deep_extend('force', {}, server)
    server_conf = vim.tbl_extend('keep', server_conf, lsp_conf[name].config_def.default_config or {})
    server_conf.on_init = function(client, initialize_result)
      vim.notify('Initialized Language Server: ' .. name, vim.log.levels.INFO, { title = 'LSP' })

      -- Workspeace diagnostics trigger
      trigger_workspace_diagnostics(client)

      if server.on_init then
        server.on_init(client, initialize_result)
      end
    end
    server_conf.before_init = function(params, client_config)
      if server.before_init then
        server.before_init(params, client_config)
      end
    end
    server_conf.on_exit = function(code, signal, client_id)
      vim.notify('De-Initialized Language Server: ' .. name, vim.log.levels.INFO, { title = 'LSP' })
      if server.on_exit then
        server.on_exit(code, signal, client_id)
      end
    end

    server_conf.capabilities = vim.tbl_extend('force', {}, capabilities, server.capabilities or {})
    server_conf.on_attach = on_attach

    -- server_conf.on_attach = function(client, bufnr)
    --   if client.server_capabilities.documentSymbolProvider then
    --     require('nvim-navic').attach(client, bufnr)
    --   end
    --   config.on_attach(client, bufnr)
    -- end,
    lsp_conf[name].setup(server_conf)
  end
end

local lazydev = {
  -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
  -- used for completion, annotations and signatures of Neovim apis
  'folke/lazydev.nvim',
  ft = 'lua',
  -- dependencies = {
  --   { 'Bilal2453/luvit-meta', lazy = true },
  -- },
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
