local lspconfig = {
  'neovim/nvim-lspconfig',
  cmd = { 'LspStart', 'LspInfo', 'LspLog' },

  ft = {
    -- Web Languages
    'typescript',
    'javascript',
    'html',
    'css',
    -- Script Languages
    'vim',
    'lua',
    'sh',
    'python',
    -- Compiled Languages
    'c',
    'cpp',
    'rust',
    'java',
    -- Document Filetypes
    'tex',
    'typst',
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

  if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentColor, bufnr) then
    local color_augroup = vim.api.nvim_create_augroup('nuance-lsp-color', { clear = true })
    vim.api.nvim_create_autocmd('ColorScheme', {
      group = color_augroup,
      callback = function()
        vim.lsp.buf.clear_references()
        vim.lsp.buf.document_color()
      end,
    })
    vim.api.nvim_create_autocmd('LspDetach', {
      group = color_augroup,
      callback = function(ev)
        vim.lsp.buf.clear_references()
        vim.api.nvim_clear_autocmds { group = 'nuance-lsp-color', buffer = ev.buf }
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

  for name, config in pairs(vim.g.configured_language_servers) do
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

return {
  mason,
  lazydev,
  lspconfig,
}

-- vim: ts=2 sts=2 sw=2 et
