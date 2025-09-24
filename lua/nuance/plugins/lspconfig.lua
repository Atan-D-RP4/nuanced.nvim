local lspconfig = {
  'neovim/nvim-lspconfig',
  cmd = { 'LspStart', 'LspInfo', 'LspLog' },
  event = { 'Filetype', 'LspAttach' },

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
  vim.hl.priorities.semantic_tokens = 95

  vim.lsp.log.set_level(vim.log.levels.INFO)
  vim.lsp.log.set_format_func(function(args)
    local msg = vim.inspect(args)
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
    ---@type vim.keymap.set.Opts
    local opts = map[3] or {}
    if type(opts) == 'string' then
      opts = { desc = opts }
    end
    opts = vim.tbl_deep_extend('force', { buffer = bufnr, noremap = true, silent = true }, opts)
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

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      vim.notify('LSP client not found for id: ' .. tostring(args.data.client_id), vim.log.levels.WARN, { title = 'LSP' })
      return
    end
    local bufnr = args.buf
    on_attach(client, bufnr)
  end,
})

---@param client vim.lsp.Client
local function trigger_workspace_diagnostics(client)
  local supported_fts = client.config.filetypes
  if supported_fts and type(supported_fts) ~= 'table' then
    supported_fts = { supported_fts }
  end
  local ft_set = supported_fts and vim.tbl_add_reverse_lookup(vim.tbl_extend('force', {}, supported_fts)) or nil

  local files = require('nuance.core.utils').get_workspace_files(client)
  files = vim.tbl_filter(function(f)
    local ft = vim.filetype.match { filename = f }
    return not ft_set or ft_set[ft]
  end, files)

  for _, file in ipairs(files) do
    local ft = vim.filetype.match { filename = file }
    if not ft_set or ft_set[ft] then
      local file_handle = vim.uv.fs_open(file, 'r', 438) -- 438 = 0o666
      if not file_handle then
        vim.notify('Failed to open file: ' .. file .. ' for workspace diagnostics', vim.log.levels.WARN, { title = 'LSP' })
        return
      end
      local data = vim.uv.fs_read(file_handle, vim.uv.fs_fstat(file_handle).size, 0)
      vim.uv.fs_close(file_handle)
      if not data then
        vim.notify('Failed to read file: ' .. file .. ' for workspace diagnostics', vim.log.levels.WARN, { title = 'LSP' })
        return
      end
      local params = {
        textDocument = {
          uri = vim.uri_from_fname(file),
          languageId = ft,
          version = 0,
          text = data,
        },
      }
      ---@diagnostic disable-next-line: unused-local
      -- vim.notify('Queued workspace diagnostics for file: ' .. file .. ' to LSP client: ' .. client.name, vim.log.levels.INFO, { title = 'LSP' })
      -- local status = client.notify('textDocument/didOpen', params)
      -- vim.notify(
      --   'Workspace diagnostics request status for file: ' .. file .. ' to LSP client: ' .. client.name .. ' is: ' .. tostring(status),
      --   vim.log.levels.DEBUG,
      --   { title = 'LSP' }
      -- )
    end
  end
  vim.notify('Workspace diagnostics queued for LSP client: ' .. client.name, vim.log.levels.INFO, { title = 'LSP' })
end

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

  vim.lsp.config('*', {
    capabilities = capabilities,
    on_init = function(client, initialize_result)
      local msg = 'Initialized Language Server: ' .. client.name
      msg = msg .. '\n' .. 'In root directory: ' .. client.config.root_dir
      vim.notify(msg, vim.log.levels.INFO, { title = 'LSP' })
      vim.notify(vim.inspect(initialize_result), vim.log.levels.INFO, { title = 'LSP' })
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
